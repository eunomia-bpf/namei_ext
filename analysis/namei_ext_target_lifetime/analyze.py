#!/usr/bin/env python3

import argparse
import bisect
import errno
import heapq
import json
import re
import sys
from collections import defaultdict
from pathlib import Path


DIAGNOSTIC_START = re.compile(
    r"(BUG:|WARNING:|Oops:|KASAN:|possible circular locking|"
    r"possible recursive locking|inconsistent lock state|held lock freed|"
    r"bad unlock balance|suspicious RCU|rcu: INFO:|"
    r"RCU-list traversed|Voluntary context switch within RCU|hung task|"
    r"INFO: task .* blocked for more than|"
    r"general protection fault|"
    r"kernel panic|Kernel panic)",
    re.IGNORECASE,
)
RELATED_DIAGNOSTIC = re.compile(
    r"(fs/namei_ext\.c|namei_ext_(?:apply_target|register_target|"
    r"clear_targets|find_target|get_target|resolve_target)|"
    r"namei_ext_target_lifetime|namei_ext_targ)",
    re.IGNORECASE,
)
PUBLICATION_TARGETS = 16
HISTORY_OPEN_SLACK = 16
KCSAN_CELLS = ("final-file", "directory", "pinned-object")
FORMAL_CONFIG = {
    "duration_seconds": 60,
    "readers": 4,
    "minimum_updates": 256,
    "minimum_opens_per_reader": 2000,
    "lifecycle_cycles": 64,
}


class AnalysisError(RuntimeError):
    pass


def load_jsonl(path):
    records = []
    with Path(path).open(encoding="utf-8") as source:
        for line_number, line in enumerate(source, 1):
            if not line.strip():
                continue
            try:
                record = json.loads(line)
            except json.JSONDecodeError as error:
                raise AnalysisError(f"{path}:{line_number}: {error}") from error
            records.append(record)
    return records


def event_key(event):
    return int(event["event_seq"])


def pair_history(records, cell):
    pairs = {}
    open_returns = {}
    event_sequences = set()
    for record in records:
        event = record.get("event")
        if event not in {
            "target-lifetime-history",
            "target-lifetime-open-return",
        }:
            continue
        if record.get("cell") != cell:
            continue
        event_sequence = event_key(record)
        if event_sequence <= 0 or event_sequence in event_sequences:
            raise AnalysisError(
                f"{cell}: duplicate or invalid event sequence {event_sequence}"
            )
        if int(record.get("time_ns", 0)) <= 0:
            raise AnalysisError(f"{cell}: history event lacks a timestamp")
        event_sequences.add(event_sequence)
        op_id = int(record["op_id"])
        if event == "target-lifetime-open-return":
            if op_id in open_returns:
                raise AnalysisError(f"{cell}: duplicate open return for op {op_id}")
            open_returns[op_id] = record
            continue
        phase = record.get("phase")
        if phase not in {"invoke", "response"}:
            raise AnalysisError(f"{cell}: invalid history phase {phase!r}")
        pair = pairs.setdefault(op_id, {})
        if phase in pair:
            raise AnalysisError(f"{cell}: duplicate {phase} for op {op_id}")
        pair[phase] = record

    if not pairs:
        raise AnalysisError(f"{cell}: no history operations")
    operations = []
    for op_id, pair in pairs.items():
        if set(pair) != {"invoke", "response"}:
            raise AnalysisError(f"{cell}: incomplete operation {op_id}")
        invoke = pair["invoke"]
        response = pair["response"]
        for field in ("operation", "subtype", "actor", "actor_id", "writer_seq"):
            if invoke.get(field) != response.get(field):
                raise AnalysisError(
                    f"{cell}: operation {op_id} changes {field}"
                )
        if invoke.get("operation") in {"SET", "CLEAR"}:
            for field in ("state", "device", "inode"):
                if invoke.get(field) != response.get(field):
                    raise AnalysisError(
                        f"{cell}: update {op_id} changes {field}"
                    )
        if event_key(invoke) >= event_key(response):
            raise AnalysisError(f"{cell}: operation {op_id} has empty interval")
        interval_response = event_key(response)
        if invoke.get("operation") == "OPEN":
            open_return = open_returns.pop(op_id, None)
            if open_return is None:
                raise AnalysisError(f"{cell}: OPEN {op_id} lacks syscall return")
            if (
                open_return.get("actor") != invoke.get("actor")
                or int(open_return.get("actor_id", -1))
                != int(invoke.get("actor_id", 0))
                or int(open_return.get("result", 1))
                != int(response.get("result", 0))
                or event_key(invoke) >= event_key(open_return)
                or event_key(open_return) >= event_key(response)
            ):
                raise AnalysisError(
                    f"{cell}: OPEN {op_id} has inconsistent syscall return"
                )
            interval_response = event_key(open_return)
        operations.append(
            {
                "op_id": op_id,
                "operation": invoke["operation"],
                "subtype": invoke.get("subtype", ""),
                "actor": invoke.get("actor", ""),
                "actor_id": int(invoke.get("actor_id", 0)),
                "writer_seq": int(invoke.get("writer_seq", 0)),
                "invoke": event_key(invoke),
                "response": interval_response,
                "state": response.get("state", ""),
                "result": int(response["result"]),
                "device": int(response.get("device", 0)),
                "inode": int(response.get("inode", 0)),
            }
        )
    if open_returns:
        raise AnalysisError(f"{cell}: open return lacks history operation")
    return operations


def load_target_definitions(records, cell):
    definitions = {}
    for record in records:
        if record.get("event") != "target-lifetime-target":
            continue
        if record.get("cell") != cell:
            continue
        state = record.get("state", "")
        if not state or state in definitions:
            raise AnalysisError(f"{cell}: duplicate or empty target state {state!r}")
        definition = {
            "directory": record.get("directory") is True,
            "device": int(record.get("device", 0)),
            "inode": int(record.get("inode", 0)),
            "mode": int(record.get("mode", 0)),
            "uid": int(record.get("uid", -1)),
            "gid": int(record.get("gid", -1)),
            "size": int(record.get("size", -1)),
            "child_device": int(record.get("child_device", 0)),
            "child_inode": int(record.get("child_inode", 0)),
            "child_mode": int(record.get("child_mode", 0)),
            "child_uid": int(record.get("child_uid", -1)),
            "child_gid": int(record.get("child_gid", -1)),
            "child_size": int(record.get("child_size", -1)),
        }
        if not definition["device"] or not definition["inode"]:
            raise AnalysisError(f"{cell}: target {state} lacks object identity")
        if definition["directory"] and (
            not definition["child_device"] or not definition["child_inode"]
        ):
            raise AnalysisError(f"{cell}: directory target {state} lacks child identity")
        definitions[state] = definition
    if not definitions:
        raise AnalysisError(f"{cell}: no target definitions")
    return definitions


def validate_open_identities(records, cell, operations):
    definitions = load_target_definitions(records, cell)
    for operation in operations:
        if operation["operation"] == "SET":
            state = operation["state"]
            if state not in definitions:
                raise AnalysisError(
                    f"{cell}: SET {operation['op_id']} names undefined state {state}"
                )
            expected = (
                definitions[state]["device"],
                definitions[state]["inode"],
            )
            observed = (operation["device"], operation["inode"])
            if observed != expected:
                raise AnalysisError(
                    f"{cell}: SET {operation['op_id']} identity {observed} "
                    f"does not match state {state} identity {expected}"
                )
            if operation["actor"] != "writer":
                raise AnalysisError(f"{cell}: SET is not attributed to writer")
            continue
        if operation["operation"] == "CLEAR":
            if operation["device"] or operation["inode"]:
                raise AnalysisError(f"{cell}: CLEAR has object identity")
            if operation["actor"] != "writer":
                raise AnalysisError(f"{cell}: CLEAR is not attributed to writer")
            continue
        if operation["operation"] != "OPEN":
            continue
        expected_actor = "reader" if cell in {"final-file", "directory"} else "lifecycle"
        if operation["actor"] != expected_actor:
            raise AnalysisError(
                f"{cell}: OPEN is attributed to {operation['actor']!r}, "
                f"expected {expected_actor!r}"
            )
        if operation["result"] == -2:
            if operation["device"] or operation["inode"]:
                raise AnalysisError(
                    f"{cell}: absent open {operation['op_id']} has object identity"
                )
            continue
        if operation["result"]:
            continue
        state = operation["state"]
        if state not in definitions:
            raise AnalysisError(
                f"{cell}: open {operation['op_id']} names undefined state {state}"
            )
        definition = definitions[state]
        if operation["subtype"] == "directory-child":
            expected = (definition["child_device"], definition["child_inode"])
        elif operation["subtype"] in {"file", "directory"}:
            expected = (definition["device"], definition["inode"])
        else:
            raise AnalysisError(
                f"{cell}: open {operation['op_id']} has unknown subtype "
                f"{operation['subtype']!r}"
            )
        observed = (operation["device"], operation["inode"])
        if observed != expected:
            raise AnalysisError(
                f"{cell}: open {operation['op_id']} identity {observed} "
                f"does not match state {state} identity {expected}"
            )
    return len(definitions)


def check_linearizable(operations):
    updates = [op for op in operations if op["operation"] in {"SET", "CLEAR"}]
    reads = [op for op in operations if op["operation"] == "OPEN"]
    unknown = [
        op
        for op in operations
        if op["operation"] not in {"SET", "CLEAR", "OPEN"}
    ]
    if unknown:
        raise AnalysisError(f"unknown history operations: {unknown[:3]}")
    if not updates or not reads:
        raise AnalysisError("history must contain updates and opens")

    updates.sort(key=lambda op: op["writer_seq"])
    expected_writer_seq = list(range(1, len(updates) + 1))
    observed_writer_seq = [op["writer_seq"] for op in updates]
    if observed_writer_seq != expected_writer_seq:
        raise AnalysisError(
            f"writer sequence is not contiguous: {observed_writer_seq[:8]}"
        )
    for previous, current in zip(updates, updates[1:]):
        if previous["response"] >= current["invoke"]:
            raise AnalysisError("single-writer updates overlap or reorder")
    for update in updates:
        if update["result"] != 0:
            raise AnalysisError(
                f"update {update['op_id']} failed with {update['result']}"
            )
        if update["operation"] == "CLEAR" and update["state"] != "absent":
            raise AnalysisError("CLEAR does not publish absent")
        if update["operation"] == "SET" and update["state"] in {"", "absent"}:
            raise AnalysisError("SET does not publish a target state")

    states = ["absent"]
    for update in updates:
        states.append(
            "absent" if update["operation"] == "CLEAR" else update["state"]
        )
    positions_by_state = defaultdict(list)
    for position, state in enumerate(states):
        positions_by_state[state].append(position)

    update_invocations = [update["invoke"] for update in updates]
    update_responses = [update["response"] for update in updates]
    for read in reads:
        if read["result"] == 0:
            if read["state"] in {"", "absent", "error"}:
                raise AnalysisError(
                    f"successful open {read['op_id']} has state {read['state']}"
                )
            if not read["device"] or not read["inode"]:
                raise AnalysisError(
                    f"successful open {read['op_id']} lacks object identity"
                )
        elif read["result"] == -2:
            if read["state"] != "absent":
                raise AnalysisError(
                    f"ENOENT open {read['op_id']} is not absent"
                )
        else:
            raise AnalysisError(
                f"open {read['op_id']} failed with unexpected {read['result']}"
            )

    # Greedy is exact for this single-writer register. Every read selects a
    # position in the totally ordered update sequence. Choosing the earliest
    # legal position can only relax the lower bound imposed on future reads.
    reads.sort(key=lambda op: op["invoke"])
    completed_reads = []
    max_completed_position = 0
    assignments = {}
    overlap_opens = 0
    overlap_reader_ids = set()
    for read in reads:
        while completed_reads and completed_reads[0][0] < read["invoke"]:
            _, _, completed_position = heapq.heappop(completed_reads)
            max_completed_position = max(
                max_completed_position, completed_position
            )
        update_lower = bisect.bisect_left(update_responses, read["invoke"])
        upper = bisect.bisect_left(update_invocations, read["response"])
        if update_lower < upper:
            overlap_opens += 1
            overlap_reader_ids.add(read["actor_id"])
        lower = max(update_lower, max_completed_position)
        candidates = positions_by_state.get(read["state"], [])
        candidate_index = bisect.bisect_left(candidates, lower)
        if candidate_index >= len(candidates) or candidates[candidate_index] > upper:
            raise AnalysisError(
                "no global linearization for open "
                f"{read['op_id']}: state={read['state']} "
                f"allowed=[{lower},{upper}]"
            )
        position = candidates[candidate_index]
        assignments[read["op_id"]] = position
        heapq.heappush(
            completed_reads, (read["response"], read["op_id"], position)
        )

    return {
        "updates": len(updates),
        "opens": len(reads),
        "successful_opens": sum(read["result"] == 0 for read in reads),
        "absent_opens": sum(read["result"] == -2 for read in reads),
        "overlap_opens": overlap_opens,
        "overlap_reader_ids": sorted(overlap_reader_ids),
        "states": len(states),
        "observed_target_states": sorted(
            {read["state"] for read in reads if read["result"] == 0}
        ),
        "assignments": assignments,
    }


def validate_overlap(linear, run_config, cell):
    expected_readers = set(range(run_config["readers"]))
    if linear["overlap_opens"] <= 0 or set(
        linear["overlap_reader_ids"]
    ) != expected_readers:
        raise AnalysisError(
            f"{cell}: update/open overlap does not cover every reader"
        )


def validate_descriptors(records, cell, operations):
    checks = [
        record
        for record in records
        if record.get("event") == "target-lifetime-descriptor"
        and record.get("cell") == cell
    ]
    if not checks:
        raise AnalysisError(f"{cell}: no descriptor checks")
    expected = {
        operation["op_id"]: operation
        for operation in operations
        if operation["operation"] == "OPEN" and operation["result"] == 0
    }
    observed_ids = [int(record.get("op_id", 0)) for record in checks]
    if len(observed_ids) != len(set(observed_ids)):
        raise AnalysisError(f"{cell}: duplicate descriptor checks")
    if set(observed_ids) != set(expected):
        raise AnalysisError(
            f"{cell}: descriptor coverage does not match successful opens"
        )
    failed = [record for record in checks if record.get("pass") is not True]
    if failed:
        raise AnalysisError(f"{cell}: {len(failed)} descriptor failures")
    for record in checks:
        operation = expected[int(record["op_id"])]
        if int(record.get("result", -1)) != 0:
            raise AnalysisError(f"{cell}: descriptor result is nonzero")
        if record.get("state") != operation["state"]:
            raise AnalysisError(f"{cell}: descriptor state changed after open")
        if record.get("subtype") != operation["subtype"]:
            raise AnalysisError(f"{cell}: descriptor subtype changed after open")
    return len(checks)


def parse_concurrent_rcu_trace(path):
    entries_buffered = None
    entries_written = None
    armed_writer_seq = 0
    active_writer_seq = 0
    update_returned = False
    markers = []
    updates = []
    branches = []
    for line_number, line in enumerate(
        Path(path).read_text(encoding="utf-8", errors="replace").splitlines(), 1
    ):
        header = re.search(
            r"entries-in-buffer/entries-written:\s*(\d+)\s*/\s*(\d+)",
            line,
        )
        if header:
            if entries_buffered is not None:
                raise AnalysisError(f"{path}: duplicate trace entry header")
            entries_buffered = int(header.group(1))
            entries_written = int(header.group(2))
            continue
        begin = re.search(r"namei_ext-update-begin-(\d+)\b", line)
        if begin:
            writer_seq = int(begin.group(1))
            if writer_seq <= 0 or armed_writer_seq or active_writer_seq:
                raise AnalysisError(
                    f"{path}:{line_number}: nested or invalid update begin"
                )
            armed_writer_seq = writer_seq
            update_returned = False
            markers.append(("begin", writer_seq))
            continue
        if "update_enter:" in line:
            if not armed_writer_seq or active_writer_seq or update_returned:
                raise AnalysisError(
                    f"{path}:{line_number}: update entry is not paired with a marker"
                )
            active_writer_seq = armed_writer_seq
            updates.append(
                {"phase": "enter", "writer_seq": active_writer_seq}
            )
            continue
        if "resolve_return:" in line:
            fields = re.search(r"rcu_walk=(\d+)\s+result=(-?\d+)\b", line)
            if not fields or int(fields.group(1)) != 1:
                raise AnalysisError(
                    f"{path}:{line_number}: unfiltered or malformed target return"
                )
            branches.append(
                {
                    "result": int(fields.group(2)),
                    "under_update": active_writer_seq != 0,
                    "writer_seq": active_writer_seq,
                }
            )
            continue
        if "update_return:" in line:
            result = re.search(r"result=(-?\d+)\b", line)
            if (
                not result
                or not armed_writer_seq
                or active_writer_seq != armed_writer_seq
                or update_returned
            ):
                raise AnalysisError(
                    f"{path}:{line_number}: update return is not paired with entry"
                )
            updates.append(
                {
                    "phase": "return",
                    "writer_seq": active_writer_seq,
                    "result": int(result.group(1)),
                }
            )
            active_writer_seq = 0
            update_returned = True
            continue
        end = re.search(r"namei_ext-update-end-(\d+)\b", line)
        if end:
            writer_seq = int(end.group(1))
            if (
                writer_seq != armed_writer_seq
                or active_writer_seq
                or not update_returned
            ):
                raise AnalysisError(
                    f"{path}:{line_number}: unmatched update end"
                )
            markers.append(("end", writer_seq))
            armed_writer_seq = 0
            update_returned = False
            continue
    if entries_buffered is None or entries_written is None:
        raise AnalysisError(f"{path}: missing trace entry header")
    if entries_written <= 0 or entries_buffered != entries_written:
        raise AnalysisError(
            f"{path}: trace buffer lost entries "
            f"({entries_buffered}/{entries_written})"
        )
    if armed_writer_seq or active_writer_seq:
        raise AnalysisError(f"{path}: incomplete update marker window")
    begins = [seq for phase, seq in markers if phase == "begin"]
    ends = [seq for phase, seq in markers if phase == "end"]
    if not begins or begins != ends:
        raise AnalysisError(f"{path}: update marker windows do not pair")
    if len(begins) != len(set(begins)):
        raise AnalysisError(f"{path}: duplicate update marker window")
    enters = [update for update in updates if update["phase"] == "enter"]
    returns = [update for update in updates if update["phase"] == "return"]
    if len(enters) != len(begins) or len(returns) != len(begins):
        raise AnalysisError(f"{path}: update kernel intervals do not pair")
    if any(update["result"] < 0 for update in returns):
        raise AnalysisError(f"{path}: traced target update failed")
    successful_under_update = [
        branch
        for branch in branches
        if branch["under_update"] and branch["result"] == 0
    ]
    if not any(branch["result"] == 0 for branch in branches):
        raise AnalysisError(f"{path}: no successful RCU target resolution")
    if not any(branch["result"] == -errno.ENOENT for branch in branches):
        raise AnalysisError(f"{path}: no absent RCU target resolution")
    return {
        "entries_buffered": entries_buffered,
        "entries_written": entries_written,
        "markers": markers,
        "updates": updates,
        "branches": branches,
        "update_windows": len(begins),
        "kernel_update_enters": len(enters),
        "kernel_update_returns": len(returns),
        "rcu_walk_hits": sum(branch["result"] == 0 for branch in branches),
        "rcu_resolve_failures": sum(
            branch["result"] != 0 for branch in branches
        ),
        "rcu_absent_results": sum(
            branch["result"] == -errno.ENOENT for branch in branches
        ),
        "rcu_under_update": len(successful_under_update),
    }


def validate_retirement_litmus(records, cell, definitions):
    rows = [
        record
        for record in records
        if record.get("event") == "target-lifetime-rcu-litmus"
        and record.get("cell") == cell
    ]
    if len(rows) != 2:
        raise AnalysisError(f"{cell}: expected replace and clear RCU litmus rows")
    by_operation = {record.get("operation"): record for record in rows}
    if set(by_operation) != {"replace", "clear"} or len(by_operation) != 2:
        raise AnalysisError(f"{cell}: RCU litmus operation coverage is incomplete")

    identities = set()
    cookies = set()
    result = {}
    for operation, mode in (("replace", 1), ("clear", 2)):
        row = by_operation[operation]
        cookie = int(row.get("cookie", 0))
        reader_tid = int(row.get("reader_tid", 0))
        writer_tid = int(row.get("writer_tid", 0))
        writer_cpu = int(row.get("writer_cpu", -1))
        reader_cpu = int(row.get("reader_cpu", -1))
        old_state = row.get("old_state")
        fresh_state = row.get("fresh_state")
        if old_state not in definitions:
            raise AnalysisError(f"{cell}: RCU litmus old state is undefined")
        old = definitions[old_state]
        if (
            row.get("pass") is not True
            or row.get("source") != "tracing-bpf-kprobe-kretprobe"
            or int(row.get("version", 0)) != 2
            or not cookie
            or int(row.get("mode", 0)) != mode
            or int(row.get("state", -1)) != 4
            or int(row.get("event_seq", 0)) != (5 if operation == "replace" else 7)
            or reader_tid <= 0
            or writer_tid <= 0
            or reader_tid == writer_tid
            or int(row.get("observed_reader_tid", 0)) != reader_tid
            or int(row.get("observed_writer_tid", 0)) != writer_tid
            or writer_cpu < 0
            or reader_cpu < 0
            or writer_cpu == reader_cpu
            or int(row.get("observed_writer_cpu", -1)) != writer_cpu
            or int(row.get("observed_reader_cpu", -1)) != reader_cpu
            or int(row.get("expected_cgroup_id", 0)) <= 0
            or int(row.get("observed_cgroup_id", 0))
            != int(row.get("expected_cgroup_id", -1))
            or int(row.get("expected_target_id", 0)) != 1
            or int(row.get("observed_target_id", 0)) != 1
            or int(row.get("observed_mount", 0)) <= 0
            or int(row.get("observed_dentry", 0)) <= 0
            or int(row.get("resolve_redirect", 0)) <= 0
            or int(row.get("resolve_rcu_walk", 0)) != 1
            or int(row.get("resolve_attempts", 0)) != 1
            or int(row.get("resolve_matches", 0)) != 1
            or int(row.get("update_entries", 0)) != 1
            or int(row.get("grace_entries", 0)) != 1
            or int(row.get("update_exits", 0)) != 1
            or int(row.get("error_flags", -1)) != 0
            or int(row.get("timeout_reason", -1)) != 0
            or int(row.get("update_result", -1)) != 0
            or int(row.get("reader_open_result", -1)) != 0
            or int(row.get("reader_validation_result", -1)) != 0
            or int(row.get("expected_old_device", 0)) != old["device"]
            or int(row.get("observed_old_device", 0)) != old["device"]
            or int(row.get("expected_old_inode", 0)) != old["inode"]
            or int(row.get("observed_old_inode", 0)) != old["inode"]
        ):
            raise AnalysisError(f"{cell}: {operation} RCU litmus fields are invalid")

        for field in (
            "hold_cookie",
            "update_cookie",
            "grace_cookie",
            "release_cookie",
            "exit_cookie",
        ):
            if int(row.get(field, 0)) != cookie:
                raise AnalysisError(
                    f"{cell}: {operation} RCU litmus cookie mismatch at {field}"
                )
        common_order = [
            int(row.get(field, 0))
            for field in (
                "hold_seq",
                "update_entry_seq",
                "grace_entry_seq",
                "reader_release_seq",
                "update_exit_seq",
            )
        ]
        if any(value <= 0 for value in common_order) or any(
            left >= right for left, right in zip(common_order, common_order[1:])
        ):
            raise AnalysisError(
                f"{cell}: {operation} RCU litmus event order is invalid"
            )
        for field in (
            "hold_ns",
            "update_entry_ns",
            "grace_entry_ns",
            "reader_release_ns",
            "update_exit_ns",
        ):
            if int(row.get(field, 0)) <= 0:
                raise AnalysisError(
                    f"{cell}: {operation} RCU litmus lacks {field}"
                )

        if operation == "replace":
            if fresh_state not in definitions:
                raise AnalysisError(f"{cell}: replacement state is undefined")
            fresh = definitions[fresh_state]
            if (
                int(row.get("clear_entries", -1)) != 0
                or int(row.get("clear_exits", -1)) != 0
                or int(row.get("clear_entry_seq", -1)) != 0
                or int(row.get("clear_exit_seq", -1)) != 0
                or int(row.get("fresh_result", -1)) != 0
                or int(row.get("expected_fresh_device", 0)) != fresh["device"]
                or int(row.get("observed_fresh_device", 0)) != fresh["device"]
                or int(row.get("expected_fresh_inode", 0)) != fresh["inode"]
                or int(row.get("observed_fresh_inode", 0)) != fresh["inode"]
                or (
                    fresh["device"] == old["device"]
                    and fresh["inode"] == old["inode"]
                )
                or common_order != [1, 2, 3, 4, 5]
            ):
                raise AnalysisError(f"{cell}: replacement postcondition failed")
        else:
            clear_order = [
                int(row.get(field, 0))
                for field in (
                    "update_entry_seq",
                    "clear_entry_seq",
                    "grace_entry_seq",
                    "reader_release_seq",
                    "clear_exit_seq",
                    "update_exit_seq",
                )
            ]
            if (
                fresh_state != "absent"
                or int(row.get("clear_entries", 0)) != 1
                or int(row.get("clear_exits", 0)) != 1
                or any(value <= 0 for value in clear_order)
                or any(
                    left >= right
                    for left, right in zip(clear_order, clear_order[1:])
                )
                or int(row.get("clear_entry_ns", 0)) <= 0
                or int(row.get("clear_exit_ns", 0)) <= 0
                or int(row.get("fresh_result", 0)) != -2
                or int(row.get("expected_fresh_device", -1)) != 0
                or int(row.get("observed_fresh_device", -1)) != 0
                or int(row.get("expected_fresh_inode", -1)) != 0
                or int(row.get("observed_fresh_inode", -1)) != 0
                or clear_order != [2, 3, 4, 5, 6, 7]
            ):
                raise AnalysisError(f"{cell}: clear postcondition failed")

        identity = (
            int(row["observed_mount"]),
            int(row["observed_dentry"]),
            int(row["observed_old_device"]),
            int(row["observed_old_inode"]),
        )
        identities.add(identity)
        cookies.add(cookie)
        result[operation] = {
            "cookie": cookie,
            "reader_tid": reader_tid,
            "writer_tid": writer_tid,
            "writer_cpu": writer_cpu,
            "reader_cpu": reader_cpu,
            "borrowed_mount": identity[0],
            "borrowed_dentry": identity[1],
            "old_state": old_state,
            "fresh_state": fresh_state,
            "event_order": common_order,
        }
    if len(cookies) != 2:
        raise AnalysisError(f"{cell}: RCU litmus cookies were reused")
    if len(identities) != 1:
        raise AnalysisError(
            f"{cell}: replace and clear did not borrow the same old target"
        )
    return result


def validate_target_retirement(
    records, cell, definitions, operations=None, history_dir=None
):
    litmus = validate_retirement_litmus(records, cell, definitions)
    summaries = [
        record
        for record in records
        if record.get("event") == "target-lifetime-rcu-stress"
        and record.get("cell") == cell
    ]
    if len(summaries) != 1:
        raise AnalysisError(f"{cell}: expected one concurrent RCU summary")
    if operations is None:
        raise AnalysisError(f"{cell}: concurrent RCU evidence lacks history context")
    if history_dir is None:
        raise AnalysisError(f"{cell}: concurrent RCU evidence lacks raw trace")
    summary = summaries[0]
    expected_trace = f"{cell}-concurrent-rcu-trace.txt"
    if summary.get("raw_trace") != expected_trace:
        raise AnalysisError(f"{cell}: unexpected raw trace path")
    raw = parse_concurrent_rcu_trace(Path(history_dir) / expected_trace)

    updates = sorted(
        (
            operation
            for operation in operations
            if operation["operation"] in {"SET", "CLEAR"}
        ),
        key=lambda operation: int(operation["writer_seq"]),
    )
    update_sequences = {int(operation["writer_seq"]) for operation in updates}
    marked_sequences = {
        writer_seq for phase, writer_seq in raw["markers"] if phase == "begin"
    }
    if marked_sequences != update_sequences:
        raise AnalysisError(
            f"{cell}: raw trace does not cover the complete bounded update history"
        )
    if any(
        branch["writer_seq"] not in marked_sequences
        for branch in raw["branches"]
        if branch["under_update"]
    ):
        raise AnalysisError(f"{cell}: RCU branch names an unmarked update")
    expected_summary = {
        "trace_entries": raw["entries_buffered"],
        "trace_entries_written": raw["entries_written"],
        "begin_markers": raw["update_windows"],
        "end_markers": raw["update_windows"],
        "update_windows": raw["update_windows"],
        "kernel_update_enters": raw["kernel_update_enters"],
        "kernel_update_returns": raw["kernel_update_returns"],
        "rcu_walk_hits": raw["rcu_walk_hits"],
        "rcu_resolve_failures": raw["rcu_resolve_failures"],
        "rcu_absent_results": raw["rcu_absent_results"],
        "rcu_under_update": raw["rcu_under_update"],
    }
    if (
        summary.get("pass") is not True
        or summary.get("trace_clock") != "counter"
        or int(summary.get("result", -1)) != 0
        or any(int(summary.get(field, -1)) != value
               for field, value in expected_summary.items())
    ):
        raise AnalysisError(f"{cell}: concurrent RCU summary is not raw-backed")
    return {
        "litmus": litmus,
        "concurrent": expected_summary,
    }


def validate_run_start(records):
    starts = [
        record
        for record in records
        if record.get("event") == "target-lifetime-run-start"
    ]
    if len(starts) != 1:
        raise AnalysisError("expected one target-lifetime run-start record")
    start = starts[0]
    fields = (
        "duration_seconds",
        "readers",
        "minimum_updates",
        "minimum_opens_per_reader",
        "lifecycle_cycles",
    )
    for field in fields:
        if int(start.get(field, 0)) <= 0:
            raise AnalysisError(f"run-start has invalid {field}")
    aliases = {
        "history_timeout_seconds": start["duration_seconds"],
        "stress_duration_seconds": start["duration_seconds"],
        "target_updates": start["minimum_updates"],
        "target_opens_per_reader": start["minimum_opens_per_reader"],
    }
    for field, value in aliases.items():
        if int(start.get(field, 0)) != int(value):
            raise AnalysisError(f"run-start has inconsistent {field}")
    return {field: int(start[field]) for field in fields}


def validate_cell_summary(records, cell, run_config):
    summaries = [
        record
        for record in records
        if record.get("event") == "target-lifetime-cell-summary"
        and record.get("cell") == cell
    ]
    if len(summaries) != 1:
        raise AnalysisError(f"{cell}: expected one cell summary")
    summary = summaries[0]
    if summary.get("pass") is not True or int(summary.get("failures", -1)):
        raise AnalysisError(f"{cell}: runner summary failed")
    if cell in {"final-file", "directory"}:
        expected = {
            "duration_seconds": run_config["duration_seconds"],
            "readers": run_config["readers"],
            "minimum_updates": run_config["minimum_updates"],
            "minimum_opens_per_reader": run_config[
                "minimum_opens_per_reader"
            ],
        }
        for field, value in expected.items():
            if int(summary.get(field, -1)) != value:
                raise AnalysisError(
                    f"{cell}: summary {field} does not match run-start"
                )
        if int(summary.get("updates", 0)) < run_config["minimum_updates"]:
            raise AnalysisError(f"{cell}: update minimum was not met")
        if int(summary.get("history_elapsed_ns", 0)) <= 0:
            raise AnalysisError(f"{cell}: history phase did not execute")
        if int(summary.get("history_elapsed_ns", 0)) >= (
            run_config["duration_seconds"] * 1_000_000_000
        ):
            raise AnalysisError(f"{cell}: history phase exceeded its deadline")
        if int(summary.get("stress_updates", 0)) < run_config["minimum_updates"]:
            raise AnalysisError(f"{cell}: stress update minimum was not met")
        if int(summary.get("stress_elapsed_ns", 0)) < (
            run_config["duration_seconds"] * 1_000_000_000
        ):
            raise AnalysisError(f"{cell}: stress duration was not met")
        if int(summary.get("history_failures", -1)) or int(
            summary.get("stress_failures", -1)
        ):
            raise AnalysisError(f"{cell}: publication phase reported failures")
    elif int(summary.get("lifecycle_cycles", -1)) != run_config[
        "lifecycle_cycles"
    ]:
        raise AnalysisError("pinned-object lifecycle count does not match run-start")
    return summary


def validate_reader_summaries(records, cell, run_config, operations):
    readers = [
        record
        for record in records
        if record.get("event") == "target-lifetime-reader-summary"
        and record.get("cell") == cell
    ]
    if not readers:
        raise AnalysisError(f"{cell}: no reader summaries")
    if len(readers) != run_config["readers"]:
        raise AnalysisError(
            f"{cell}: expected {run_config['readers']} reader summaries, "
            f"got {len(readers)}"
        )
    failed = [
        record
        for record in readers
        if record.get("pass") is not True
        or int(record.get("opens", 0))
        < run_config["minimum_opens_per_reader"]
        or int(record.get("successful_opens", 0)) <= 0
        or int(record.get("absent_opens", 0)) <= 0
        or int(record.get("distinct_selected_states", 0)) < 2
        or int(record.get("unexpected_errors", -1)) != 0
        or int(record.get("target_opens", -1))
        != run_config["minimum_opens_per_reader"]
        or int(record.get("maximum_opens", -1))
        != run_config["minimum_opens_per_reader"]
        + run_config["minimum_updates"]
        + HISTORY_OPEN_SLACK
        or int(record.get("opens", 0)) > int(record.get("maximum_opens", -1))
    ]
    if failed:
        raise AnalysisError(f"{cell}: {len(failed)} reader engagement failures")
    if len({int(record["reader"]) for record in readers}) != len(readers):
        raise AnalysisError(f"{cell}: duplicate reader summaries")

    observed = defaultdict(
        lambda: {
            "opens": 0,
            "successful_opens": 0,
            "absent_opens": 0,
            "selected_states": set(),
        }
    )
    for operation in operations:
        if operation["operation"] != "OPEN" or operation["actor"] != "reader":
            continue
        summary = observed[operation["actor_id"]]
        summary["opens"] += 1
        summary["successful_opens"] += operation["result"] == 0
        summary["absent_opens"] += operation["result"] == -2
        if operation["result"] == 0:
            summary["selected_states"].add(operation["state"])
    if set(observed) != set(range(run_config["readers"])):
        raise AnalysisError(f"{cell}: reader history coverage is incomplete")
    for record in readers:
        reader = int(record["reader"])
        for field in ("opens", "successful_opens", "absent_opens"):
            if int(record.get(field, -1)) != observed[reader][field]:
                raise AnalysisError(
                    f"{cell}: reader {reader} {field} summary does not "
                    "match paired history"
                )
        if int(record.get("distinct_selected_states", -1)) != len(
            observed[reader]["selected_states"]
        ):
            raise AnalysisError(
                f"{cell}: reader {reader} distinct target summary does not "
                "match paired history"
            )
    return len(readers)


def validate_publication_phases(records, cell, run_config, operations):
    summaries = [
        record
        for record in records
        if record.get("event") == "target-lifetime-phase-summary"
        and record.get("cell") == cell
    ]
    if len(summaries) != 2 or {record.get("phase") for record in summaries} != {
        "history",
        "stress",
    }:
        raise AnalysisError(f"{cell}: publication phase summaries are incomplete")
    by_phase = {record["phase"]: record for record in summaries}
    for phase, summary in by_phase.items():
        if summary.get("pass") is not True or int(summary.get("failures", -1)):
            raise AnalysisError(f"{cell}: {phase} phase failed")
        expected = {
            "duration_seconds": run_config["duration_seconds"],
            "readers": run_config["readers"],
            "target_updates": run_config["minimum_updates"],
            "target_opens_per_reader": run_config["minimum_opens_per_reader"],
            "maximum_history_opens_per_reader": (
                run_config["minimum_opens_per_reader"]
                + run_config["minimum_updates"]
                + HISTORY_OPEN_SLACK
                if phase == "history"
                else 0
            ),
        }
        for field, value in expected.items():
            if int(summary.get(field, -1)) != value:
                raise AnalysisError(
                    f"{cell}: {phase} phase {field} does not match run-start"
                )
        updates = int(summary.get("updates", 0))
        if (phase == "history" and updates != run_config["minimum_updates"]) or (
            phase == "stress" and updates < run_config["minimum_updates"]
        ):
            raise AnalysisError(f"{cell}: {phase} phase update minimum was not met")
        if int(summary.get("elapsed_ns", 0)) <= 0:
            raise AnalysisError(f"{cell}: {phase} phase did not execute")
        if phase == "history" and int(summary.get("elapsed_ns", 0)) >= (
            run_config["duration_seconds"] * 1_000_000_000
        ):
            raise AnalysisError(f"{cell}: history phase exceeded its deadline")
        if summary.get("timed_out") is not False:
            raise AnalysisError(f"{cell}: {phase} phase timed out")

    history_updates = sum(
        operation["operation"] in {"SET", "CLEAR"} for operation in operations
    )
    if int(by_phase["history"].get("updates", -1)) != history_updates:
        raise AnalysisError(f"{cell}: history phase summary does not match history")
    if int(by_phase["stress"].get("elapsed_ns", 0)) < (
        run_config["duration_seconds"] * 1_000_000_000
    ):
        raise AnalysisError(f"{cell}: stress phase ended before its deadline")

    stress_readers = [
        record
        for record in records
        if record.get("event") == "target-lifetime-stress-reader-summary"
        and record.get("cell") == cell
    ]
    if len(stress_readers) != run_config["readers"]:
        raise AnalysisError(
            f"{cell}: expected {run_config['readers']} stress reader summaries"
        )
    reader_ids = {int(record.get("reader", -1)) for record in stress_readers}
    if reader_ids != set(range(run_config["readers"])):
        raise AnalysisError(f"{cell}: stress reader coverage is incomplete")
    failed = [
        record
        for record in stress_readers
        if record.get("pass") is not True
        or int(record.get("opens", 0))
        < run_config["minimum_opens_per_reader"]
        or int(record.get("successful_opens", 0)) <= 0
        or int(record.get("absent_opens", 0)) <= 0
        or int(record.get("unexpected_errors", -1)) != 0
        or int(record.get("target_opens", -1))
        != run_config["minimum_opens_per_reader"]
        or int(record.get("maximum_opens", -1)) != 0
    ]
    if failed:
        raise AnalysisError(f"{cell}: {len(failed)} stress reader failures")
    operation_failures = [
        record
        for record in records
        if record.get("event") == "target-lifetime-operation-failure"
        and record.get("cell") == cell
        and record.get("phase") == "stress"
    ]
    if operation_failures:
        raise AnalysisError(
            f"{cell}: {len(operation_failures)} stress operation failures"
        )
    return {
        "history_elapsed_ns": int(by_phase["history"]["elapsed_ns"]),
        "stress_elapsed_ns": int(by_phase["stress"]["elapsed_ns"]),
        "stress_updates": int(by_phase["stress"]["updates"]),
        "stress_opens": sum(int(record["opens"]) for record in stress_readers),
        "stress_successful_opens": sum(
            int(record["successful_opens"]) for record in stress_readers
        ),
        "stress_absent_opens": sum(
            int(record["absent_opens"]) for record in stress_readers
        ),
    }


def validate_lifecycle(records, expected_cycles):
    lifecycle = [
        record
        for record in records
        if record.get("event") == "target-lifetime-lifecycle"
    ]
    if not lifecycle:
        raise AnalysisError("missing pinned-object lifecycle checks")
    failed = [record for record in lifecycle if record.get("pass") is not True]
    if failed:
        raise AnalysisError(f"{len(failed)} pinned-object lifecycle failures")
    cases = defaultdict(set)
    for record in lifecycle:
        cases[record["case"]].add(int(record["cycle"]))
    if set(cases) != {"file-rename-unlink-clear", "directory-rename-clear"}:
        raise AnalysisError("pinned-object lifecycle cases are incomplete")
    if cases["file-rename-unlink-clear"] != cases["directory-rename-clear"]:
        raise AnalysisError("pinned-object lifecycle cycle sets disagree")
    if cases["file-rename-unlink-clear"] != set(range(expected_cycles)):
        raise AnalysisError("pinned-object lifecycle cycle coverage is incomplete")

    expected_steps = {
        "file-rename-unlink-clear": {
            "register",
            "open-held-logical",
            "rename-target",
            "open-after-rename",
            "unlink-target",
            "open-after-unlink",
            "clear-registration",
            "open-after-clear",
            "held-logical-after-clear",
            "held-physical-after-clear",
        },
        "directory-rename-clear": {
            "register",
            "open-held-logical",
            "rename-target",
            "open-child-after-rename",
            "clear-registration",
            "open-after-clear",
            "held-directory-after-clear",
        },
    }
    steps = [
        record
        for record in records
        if record.get("event") == "target-lifetime-lifecycle-step"
    ]
    observed_steps = defaultdict(set)
    identities_required = {
        "held-logical-after-clear",
        "held-physical-after-clear",
        "held-directory-after-clear",
    }
    for record in steps:
        key = (record.get("case"), int(record.get("cycle", -1)))
        step = record.get("step")
        if step in observed_steps[key]:
            raise AnalysisError(f"duplicate lifecycle step {key} {step}")
        observed_steps[key].add(step)
        if record.get("cell") != "pinned-object" or record.get("pass") is not True:
            raise AnalysisError(f"failed lifecycle step {key} {step}")
        if int(record.get("observed_result", 1)) != int(
            record.get("expected_result", 0)
        ):
            raise AnalysisError(f"lifecycle result mismatch {key} {step}")
        if step in identities_required and (
            int(record.get("expected_device", 0)) <= 0
            or int(record.get("expected_inode", 0)) <= 0
            or int(record.get("observed_device", 0))
            != int(record.get("expected_device", -1))
            or int(record.get("observed_inode", 0))
            != int(record.get("expected_inode", -1))
        ):
            raise AnalysisError(f"lifecycle identity mismatch {key} {step}")
    expected_keys = {
        (case, cycle)
        for case in expected_steps
        for cycle in range(expected_cycles)
    }
    if set(observed_steps) != expected_keys:
        raise AnalysisError("pinned-object lifecycle step cycles are incomplete")
    for (case, cycle), observed in observed_steps.items():
        if observed != expected_steps[case]:
            raise AnalysisError(
                f"pinned-object lifecycle steps incomplete for {case} {cycle}"
            )
    return len(cases["file-rename-unlink-clear"])


def validate_cleanup(records, cell):
    checks = [
        record
        for record in records
        if record.get("event") == "target-lifetime-cleanup"
        and record.get("cell") == cell
    ]
    if len(checks) != 1:
        raise AnalysisError(f"{cell}: expected one cleanup record")
    check = checks[0]
    fields = (
        "target_clear",
        "scope_clear",
        "detach",
        "cgroup_remove",
        "tree_remove",
    )
    if check.get("pass") is not True or any(
        int(check.get(field, -1)) != 0 for field in fields
    ):
        raise AnalysisError(f"{cell}: cleanup failed: {check}")
    return check


def validate_lower_objects(records, cell, definitions):
    checks = [
        record
        for record in records
        if record.get("event") == "target-lifetime-lower-object"
        and record.get("cell") == cell
    ]
    expected = {
        (state, object_kind)
        for state, definition in definitions.items()
        for object_kind in (
            ("target", "child") if definition["directory"] else ("target",)
        )
    }
    observed = [(record.get("state"), record.get("object")) for record in checks]
    if len(observed) != len(set(observed)):
        raise AnalysisError(f"{cell}: duplicate lower-object checks")
    if set(observed) != expected:
        missing = sorted(expected - set(observed))
        extra = sorted(set(observed) - expected)
        raise AnalysisError(
            f"{cell}: lower-object coverage mismatch: missing={missing[:3]} "
            f"extra={extra[:3]}"
        )
    failed = [
        record
        for record in checks
        if record.get("pass") is not True
        or int(record.get("result", -1)) != 0
        or record.get("bytes_match") is not True
        or int(record.get("expected_device", 0))
        != int(record.get("observed_device", -1))
        or int(record.get("expected_inode", 0))
        != int(record.get("observed_inode", -1))
        or int(record.get("expected_mode", 0))
        != int(record.get("observed_mode", -1))
        or int(record.get("expected_uid", 0))
        != int(record.get("observed_uid", -1))
        or int(record.get("expected_gid", 0))
        != int(record.get("observed_gid", -1))
        or int(record.get("expected_size", 0))
        != int(record.get("observed_size", -1))
        or any(
            int(record.get(f"expected_{field}", -1))
            != int(
                definitions[record["state"]][
                    f"child_{field}"
                    if record["object"] == "child"
                    else field
                ]
            )
            for field in ("device", "inode", "mode", "uid", "gid", "size")
        )
    ]
    if failed:
        raise AnalysisError(f"{cell}: {len(failed)} lower-object failures")
    return len(checks)


def parse_config(path):
    values = {}
    for raw_line in Path(path).read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if line.startswith("CONFIG_") and "=" in line:
            key, value = line.split("=", 1)
            values[key] = value
        elif line.startswith("# CONFIG_") and line.endswith(" is not set"):
            values[line.split()[1]] = "n"
    return values


def require_config(config, expected):
    missing = {
        key: (config.get(key, "n"), value)
        for key, value in expected.items()
        if config.get(key, "n") != value
    }
    if missing:
        raise AnalysisError(f"kernel config mismatch: {missing}")


def validate_kernel_config(path, kernel_kind):
    config = parse_config(path)
    common = {
        "CONFIG_NAMEI_EXT": "y",
        "CONFIG_DEBUG_FS": "y",
        "CONFIG_TRACING": "y",
        "CONFIG_KPROBE_EVENTS": "y",
        "CONFIG_KPROBES": "y",
        "CONFIG_BPF_EVENTS": "y",
        "CONFIG_BPF_JIT": "y",
        "CONFIG_DEBUG_INFO_BTF": "y",
    }
    if kernel_kind == "normal":
        expected = {
            **common,
            "CONFIG_KASAN": "n",
            "CONFIG_KCSAN": "n",
        }
    elif kernel_kind == "kasan":
        expected = {
            **common,
            "CONFIG_KASAN": "y",
            "CONFIG_KASAN_GENERIC": "y",
            "CONFIG_KASAN_INLINE": "y",
            "CONFIG_KASAN_VMALLOC": "y",
            "CONFIG_KCSAN": "n",
            "CONFIG_PROVE_LOCKING": "y",
            "CONFIG_DEBUG_LOCK_ALLOC": "y",
            "CONFIG_DEBUG_ATOMIC_SLEEP": "y",
            "CONFIG_PROVE_RCU": "y",
            "CONFIG_RCU_EXPERT": "y",
            "CONFIG_PROVE_RCU_LIST": "y",
            "CONFIG_DETECT_HUNG_TASK": "y",
            "CONFIG_DEFAULT_HUNG_TASK_TIMEOUT": "120",
        }
    elif kernel_kind == "kcsan":
        expected = {
            **common,
            "CONFIG_KASAN": "n",
            "CONFIG_KCSAN": "y",
            "CONFIG_KCSAN_EARLY_ENABLE": "n",
            "CONFIG_KCSAN_STRICT": "y",
            "CONFIG_KCSAN_WEAK_MEMORY": "y",
            "CONFIG_KCSAN_NUM_WATCHPOINTS": "64",
            "CONFIG_KCSAN_UDELAY_TASK": "80",
            "CONFIG_KCSAN_UDELAY_INTERRUPT": "20",
            "CONFIG_KCSAN_DELAY_RANDOMIZE": "n",
            "CONFIG_KCSAN_SKIP_WATCH": "1000",
            "CONFIG_KCSAN_SKIP_WATCH_RANDOMIZE": "n",
            "CONFIG_KCSAN_REPORT_ONCE_IN_MS": "0",
            "CONFIG_KCSAN_REPORT_RACE_UNKNOWN_ORIGIN": "y",
            "CONFIG_PROVE_LOCKING": "y",
            "CONFIG_DEBUG_LOCK_ALLOC": "y",
            "CONFIG_DEBUG_ATOMIC_SLEEP": "y",
            "CONFIG_PROVE_RCU": "y",
            "CONFIG_RCU_EXPERT": "y",
            "CONFIG_PROVE_RCU_LIST": "y",
            "CONFIG_DETECT_HUNG_TASK": "y",
            "CONFIG_DEFAULT_HUNG_TASK_TIMEOUT": "120",
        }
    else:
        raise AnalysisError(f"unknown kernel kind {kernel_kind}")
    require_config(config, expected)
    return expected


def parse_kcsan_counters(path):
    counters = {}
    lines = Path(path).read_text(encoding="utf-8").splitlines()
    for line in lines:
        match = re.fullmatch(r"([a-z_]+):\s+(-?\d+)", line.strip())
        if match:
            counters[match.group(1)] = int(match.group(2))
    for required in (
        "enabled",
        "used_watchpoints",
        "setup_watchpoints",
        "data_races",
        "assert_failures",
    ):
        if required not in counters:
            raise AnalysisError(f"{path}: missing KCSAN counter {required}")
    if "blacklisted functions: none" not in {line.strip() for line in lines}:
        raise AnalysisError(f"{path}: KCSAN report filtering is active or unknown")
    return counters


def validate_kcsan_engagement(before_path, after_path):
    before = parse_kcsan_counters(before_path)
    after = parse_kcsan_counters(after_path)
    if before["enabled"] != 0 or after["enabled"] != 0:
        raise AnalysisError("KCSAN was not confined to the workload windows")
    if before["data_races"] != 0 or before["assert_failures"] != 0:
        raise AnalysisError("KCSAN counters were not clean before the workload")
    deltas = {
        key: after[key] - before.get(key, 0)
        for key in (
            "used_watchpoints",
            "setup_watchpoints",
            "data_races",
            "assert_failures",
        )
        if key in after
    }
    if before["used_watchpoints"] < 0 or after["used_watchpoints"] < 0:
        raise AnalysisError("KCSAN used-watchpoint gauge is invalid")
    if deltas["setup_watchpoints"] <= 0:
        raise AnalysisError(f"KCSAN watchpoints did not engage: {deltas}")
    if deltas["data_races"] != 0:
        raise AnalysisError(f"KCSAN observed data races during stress: {deltas}")
    if deltas["assert_failures"] != 0:
        raise AnalysisError(f"KCSAN observed assertion failures: {deltas}")
    return deltas


def validate_kcsan_cells(directory):
    root = Path(directory)
    results = {}
    for cell in KCSAN_CELLS:
        before = root / f"{cell}-kcsan-before.txt"
        after = root / f"{cell}-kcsan-after.txt"
        if not before.is_file() or not after.is_file():
            raise AnalysisError(f"{cell}: missing per-cell KCSAN snapshots")
        results[cell] = validate_kcsan_engagement(before, after)
    return results


def validate_kcsan_partition(total, cells):
    cell_setups = sum(cell["setup_watchpoints"] for cell in cells.values())
    if total["setup_watchpoints"] != cell_setups:
        raise AnalysisError(
            "KCSAN setup-watchpoint delta extends outside the per-cell windows: "
            f"total={total['setup_watchpoints']} cells={cell_setups}"
        )


def classify_dmesg(path):
    lines = Path(path).read_text(
        encoding="utf-8", errors="replace"
    ).splitlines()
    starts = [index for index, line in enumerate(lines) if DIAGNOSTIC_START.search(line)]
    blocks = []
    for start in starts:
        begin = max(0, start - 8)
        end = min(len(lines), start + 81)
        text = "\n".join(lines[begin:end])
        blocks.append(
            {
                "line": start + 1,
                "related": bool(RELATED_DIAGNOSTIC.search(text)),
                "headline": lines[start],
            }
        )
    related = [block for block in blocks if block["related"]]
    unrelated = [block for block in blocks if not block["related"]]
    status = "negative" if related else "inconclusive" if unrelated else "clean"
    return {
        "status": status,
        "diagnostics": len(blocks),
        "related": related,
        "unrelated": unrelated,
    }


def validate_control(path):
    records = load_jsonl(path)
    rows = [
        record
        for record in records
        if record.get("event") == "rq3-semantic-oracle"
        and record.get("condition") == "namei_ext"
    ]
    if len(rows) != 37:
        raise AnalysisError(f"current namei control has {len(rows)} rows")
    if len({record.get("oracle_id") for record in rows}) != 37:
        raise AnalysisError("current namei control oracle IDs are not unique")
    failed = [record for record in rows if record.get("pass") is not True]
    if failed:
        raise AnalysisError(f"current namei control has {len(failed)} failures")
    summaries = [
        record
        for record in records
        if record.get("case") == "agent_workspace_rq3_summary"
        and record.get("pass") is True
    ]
    if len(summaries) != 1:
        raise AnalysisError("current namei control summary is missing")
    return 37


def analyze_boot(args):
    records = load_jsonl(args.history)
    run_config = validate_run_start(records)
    run_summaries = [
        record
        for record in records
        if record.get("event") == "target-lifetime-run-summary"
    ]
    if (
        len(run_summaries) != 1
        or run_summaries[0].get("pass") is not True
        or int(run_summaries[0].get("failures", -1)) != 0
    ):
        raise AnalysisError("runner did not report one passing run summary")

    cells = {}
    for cell in ("final-file", "directory", "pinned-object"):
        operations = pair_history(records, cell)
        definitions = load_target_definitions(records, cell)
        target_definitions = validate_open_identities(records, cell, operations)
        expected_definitions = (
            PUBLICATION_TARGETS
            if cell in {"final-file", "directory"}
            else 2 * run_config["lifecycle_cycles"]
        )
        if target_definitions != expected_definitions:
            raise AnalysisError(
                f"{cell}: expected {expected_definitions} target definitions, "
                f"got {target_definitions}"
            )
        linear = check_linearizable(operations)
        if cell in {"final-file", "directory"}:
            if len(linear["observed_target_states"]) < 2:
                raise AnalysisError(
                    f"{cell}: fewer than two selected target states observed"
                )
            validate_overlap(linear, run_config, cell)
        descriptors = validate_descriptors(records, cell, operations)
        summary = validate_cell_summary(records, cell, run_config)
        if cell in {"final-file", "directory"} and int(
            summary.get("updates", -1)
        ) != linear["updates"]:
            raise AnalysisError(f"{cell}: update summary does not match history")
        readers = (
            validate_reader_summaries(records, cell, run_config, operations)
            if cell in {"final-file", "directory"}
            else None
        )
        publication_phases = (
            validate_publication_phases(records, cell, run_config, operations)
            if cell in {"final-file", "directory"}
            else None
        )
        target_retirement = (
            validate_target_retirement(
                records,
                cell,
                definitions,
                operations,
                Path(args.history).parent,
            )
            if cell in {"final-file", "directory"}
            else None
        )
        lower_objects = (
            validate_lower_objects(records, cell, definitions)
            if cell in {"final-file", "directory"}
            else None
        )
        cleanup = validate_cleanup(records, cell)
        cells[cell] = {
            "updates": linear["updates"],
            "opens": linear["opens"],
            "successful_opens": linear["successful_opens"],
            "absent_opens": linear["absent_opens"],
            "overlap_opens": linear["overlap_opens"],
            "overlap_reader_ids": linear["overlap_reader_ids"],
            "observed_target_states": linear["observed_target_states"],
            "target_retirement": target_retirement,
            "descriptor_checks": descriptors,
            "target_definitions": target_definitions,
            "lower_object_checks": lower_objects,
            "cleanup": cleanup,
            "readers": readers,
            "publication_phases": publication_phases,
            "runner_summary": summary,
        }
    lifecycle_cycles = validate_lifecycle(
        records, run_config["lifecycle_cycles"]
    )
    litmus_cookies = [
        proof["cookie"]
        for cell in ("final-file", "directory")
        for proof in cells[cell]["target_retirement"]["litmus"].values()
    ]
    if len(litmus_cookies) != 4 or len(set(litmus_cookies)) != 4:
        raise AnalysisError("RCU litmus cookies are not unique across the boot")
    config = validate_kernel_config(args.kernel_config, args.kernel_kind)
    dmesg = classify_dmesg(args.dmesg)
    if dmesg["status"] != "clean":
        raise AnalysisError(
            f"kernel diagnostics make boot {dmesg['status']}: "
            f"{dmesg['diagnostics']} block(s)"
        )

    boot_dmesg = None
    if args.kernel_kind == "kcsan":
        if not args.boot_dmesg:
            raise AnalysisError("KCSAN boot lacks pre-workload dmesg")
        boot_dmesg = classify_dmesg(args.boot_dmesg)
        if boot_dmesg["status"] != "clean":
            raise AnalysisError(
                f"pre-workload kernel diagnostics make boot "
                f"{boot_dmesg['status']}: {boot_dmesg['diagnostics']} block(s)"
            )
    elif args.boot_dmesg:
        raise AnalysisError("non-KCSAN boot unexpectedly supplied pre-workload dmesg")

    kcsan = None
    kcsan_cells = None
    if args.kernel_kind == "kcsan":
        if not args.kcsan_before or not args.kcsan_after:
            raise AnalysisError("KCSAN boot lacks before/after counters")
        kcsan = validate_kcsan_engagement(args.kcsan_before, args.kcsan_after)
        kcsan_cells = validate_kcsan_cells(Path(args.history).parent)
        validate_kcsan_partition(kcsan, kcsan_cells)
    elif args.kcsan_before or args.kcsan_after:
        raise AnalysisError("non-KCSAN boot unexpectedly supplied counters")

    control_rows = None
    if args.control:
        control_rows = validate_control(args.control)
    elif args.require_control:
        raise AnalysisError("formal boot lacks current 37-row namei control")

    result = {
        "schema": "namei_ext.target_lifetime.boot.v2",
        "kernel_kind": args.kernel_kind,
        "status": "positive",
        "run_config": run_config,
        "cells": cells,
        "lifecycle_cycles": lifecycle_cycles,
        "rcu_litmus_cells": 4,
        "kernel_config_checked": sorted(config),
        "kcsan_deltas": kcsan,
        "kcsan_cell_deltas": kcsan_cells,
        "dmesg": dmesg,
        "pre_workload_dmesg": boot_dmesg,
        "current_namei_control_rows": control_rows,
    }
    output = Path(args.output)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n")
    return result


def analyze_formal(args):
    root = Path(args.root)
    if args.repetitions != 3:
        raise AnalysisError("formal analysis requires exactly three repetitions")
    run = json.loads((root / "run.json").read_text(encoding="utf-8"))
    expected_matrix = {
        "kernel_kinds": ["normal", "kasan", "kcsan"],
        "repetitions_per_kernel": 3,
        "history_timeout_seconds": FORMAL_CONFIG[
            "duration_seconds"
        ],
        "stress_duration_seconds": FORMAL_CONFIG["duration_seconds"],
        "readers": FORMAL_CONFIG["readers"],
        "target_updates": FORMAL_CONFIG["minimum_updates"],
        "target_opens_per_reader": FORMAL_CONFIG[
            "minimum_opens_per_reader"
        ],
        "lifecycle_cycles": FORMAL_CONFIG["lifecycle_cycles"],
    }
    if (
        run.get("role") != "formal"
        or run.get("status") != "running"
        or run.get("matrix") != expected_matrix
    ):
        raise AnalysisError("formal run metadata does not match the frozen matrix")
    summaries = []
    for kind in ("normal", "kasan", "kcsan"):
        paths = sorted((root / "boots").glob(f"{kind}-*/analysis.json"))
        if len(paths) != args.repetitions:
            raise AnalysisError(
                f"{kind}: expected {args.repetitions} boot analyses, got {len(paths)}"
            )
        for path in paths:
            summary = json.loads(path.read_text(encoding="utf-8"))
            if summary.get("status") != "positive":
                raise AnalysisError(f"{path}: boot is not positive")
            if summary.get("run_config") != FORMAL_CONFIG:
                raise AnalysisError(f"{path}: boot did not use formal scale")
            if summary.get("current_namei_control_rows") != 37:
                raise AnalysisError(f"{path}: formal control coverage is incomplete")
            summaries.append(summary)
    result = {
        "schema": "namei_ext.target_lifetime.formal.v2",
        "status": "positive",
        "repetitions_per_kernel": args.repetitions,
        "boots": len(summaries),
        "kernel_kinds": {
            kind: sum(1 for summary in summaries if summary["kernel_kind"] == kind)
            for kind in ("normal", "kasan", "kcsan")
        },
        "history_violations": 0,
        "rcu_litmus_cells": 4 * len(summaries),
        "descriptor_violations": 0,
        "kernel_diagnostics": 0,
        "current_namei_control_rows_per_boot": 37,
        "totals": {
            key: sum(
                int(cell.get(key) or 0)
                for summary in summaries
                for cell in summary["cells"].values()
            )
            for key in (
                "updates",
                "opens",
                "successful_opens",
                "absent_opens",
                "overlap_opens",
                "descriptor_checks",
                "lower_object_checks",
            )
        },
        "stress_totals": {
            key: sum(
                int(cell.get("publication_phases", {}).get(key, 0))
                for summary in summaries
                for cell in summary["cells"].values()
                if cell.get("publication_phases")
            )
            for key in (
                "stress_updates",
                "stress_opens",
                "stress_successful_opens",
                "stress_absent_opens",
            )
        },
        "lifecycle_cycles": sum(
            int(summary["lifecycle_cycles"]) for summary in summaries
        ),
    }
    output = Path(args.output)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n")
    return result


def build_parser():
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest="command", required=True)

    boot = subparsers.add_parser("boot")
    boot.add_argument("--history", required=True)
    boot.add_argument("--dmesg", required=True)
    boot.add_argument("--boot-dmesg")
    boot.add_argument("--kernel-config", required=True)
    boot.add_argument("--kernel-kind", choices=("normal", "kasan", "kcsan"), required=True)
    boot.add_argument("--kcsan-before")
    boot.add_argument("--kcsan-after")
    boot.add_argument("--control")
    boot.add_argument("--require-control", action="store_true")
    boot.add_argument("--output", required=True)
    boot.set_defaults(handler=analyze_boot)

    formal = subparsers.add_parser("formal")
    formal.add_argument("--root", required=True)
    formal.add_argument("--repetitions", type=int, required=True)
    formal.add_argument("--output", required=True)
    formal.set_defaults(handler=analyze_formal)
    return parser


def main():
    args = build_parser().parse_args()
    try:
        args.handler(args)
    except AnalysisError as error:
        print(f"analysis failed: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
