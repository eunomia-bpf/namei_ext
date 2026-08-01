#!/usr/bin/env python3

import argparse
import bisect
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


def parse_controlled_rcu_trace(path):
    entries_buffered = None
    entries_written = None
    returns = []
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
        if "resolve_target_return:" not in line:
            continue
        fields = re.search(r"rcu_walk=(\d+)\s+result=(-?\d+)\b", line)
        if not fields or int(fields.group(1)) not in {0, 1}:
            raise AnalysisError(f"{path}:{line_number}: malformed target probe")
        returns.append(
            {
                "rcu_walk": bool(int(fields.group(1))),
                "result": int(fields.group(2)),
            }
        )
    if entries_buffered is None or entries_written is None:
        raise AnalysisError(f"{path}: missing trace entry header")
    if entries_written <= 0 or entries_buffered != entries_written:
        raise AnalysisError(
            f"{path}: trace buffer lost entries "
            f"({entries_buffered}/{entries_written})"
        )
    if not returns or not any(
        returned["rcu_walk"] and returned["result"] == 0
        for returned in returns
    ):
        raise AnalysisError(f"{path}: no successful controlled RCU target resolution")
    return {
        "entries_buffered": entries_buffered,
        "entries_written": entries_written,
        "returns": returns,
    }


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
    if not successful_under_update:
        raise AnalysisError(
            f"{path}: no successful RCU target resolution during kernel update"
        )
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
        "rcu_under_update": len(successful_under_update),
    }


def validate_rcu_update_classes(raw, updates, cell):
    replacement_sequences = {
        int(current["writer_seq"])
        for previous, current in zip(updates, updates[1:])
        if previous["operation"] == "SET" and current["operation"] == "SET"
    }
    clear_sequences = {
        int(operation["writer_seq"])
        for operation in updates
        if operation["operation"] == "CLEAR"
    }
    overlapped_sequences = {
        branch["writer_seq"]
        for branch in raw["branches"]
        if branch["under_update"] and branch["result"] == 0
    }
    if not replacement_sequences or not (
        replacement_sequences & overlapped_sequences
    ):
        raise AnalysisError(
            f"{cell}: no RCU target resolution during target replacement"
        )
    if not clear_sequences or not (clear_sequences & overlapped_sequences):
        raise AnalysisError(
            f"{cell}: no RCU target resolution during target retirement"
        )
    return {
        "rcu_under_replacement": sum(
            branch["under_update"]
            and branch["result"] == 0
            and branch["writer_seq"] in replacement_sequences
            for branch in raw["branches"]
        ),
        "rcu_under_retirement": sum(
            branch["under_update"]
            and branch["result"] == 0
            and branch["writer_seq"] in clear_sequences
            for branch in raw["branches"]
        ),
    }


def validate_rcu_proof(
    records, cell, definitions, operations=None, history_dir=None
):
    proofs = [
        record
        for record in records
        if record.get("event") == "target-lifetime-rcu-proof"
        and record.get("cell") == cell
    ]
    if len(proofs) != 1:
        raise AnalysisError(f"{cell}: expected one RCU target proof")
    branches = [
        record
        for record in records
        if record.get("event") == "target-lifetime-rcu-branch"
        and record.get("cell") == cell
        and record.get("phase") == "controlled"
    ]
    if not branches or not any(
        record.get("rcu_walk") is True and int(record.get("result", 1)) == 0
        for record in branches
    ):
        raise AnalysisError(f"{cell}: no observed RCU-walk target resolution")
    if any(
        record.get("source")
        != "kretprobe:namei_ext_resolve_target:arg2+retval"
        or not isinstance(record.get("rcu_walk"), bool)
        or not isinstance(record.get("result"), int)
        or record.get("under_update") is not False
        or int(record.get("writer_seq", -1)) != 0
        for record in branches
    ):
        raise AnalysisError(f"{cell}: malformed RCU branch evidence")
    proof = proofs[0]
    state = proof.get("state")
    if state not in definitions:
        raise AnalysisError(f"{cell}: RCU proof names undefined state {state!r}")
    definition = definitions[state]
    if history_dir is None:
        raise AnalysisError(f"{cell}: controlled RCU evidence lacks raw trace")
    expected_controlled_trace = f"{cell}-controlled-rcu-trace.txt"
    if proof.get("raw_trace") != expected_controlled_trace:
        raise AnalysisError(f"{cell}: unexpected controlled raw trace path")
    controlled_raw = parse_controlled_rcu_trace(
        Path(history_dir) / expected_controlled_trace
    )
    observed_controlled = [
        {"rcu_walk": record["rcu_walk"], "result": int(record["result"])}
        for record in branches
    ]
    if observed_controlled != controlled_raw["returns"]:
        raise AnalysisError(
            f"{cell}: controlled returns do not match raw trace"
        )
    rcu_hits = sum(
        returned["rcu_walk"] and returned["result"] == 0
        for returned in controlled_raw["returns"]
    )
    ref_hits = sum(
        not returned["rcu_walk"] and returned["result"] == 0
        for returned in controlled_raw["returns"]
    )
    resolve_failures = sum(
        returned["result"] != 0 for returned in controlled_raw["returns"]
    )
    if (
        proof.get("pass") is not True
        or int(proof.get("resolve_cached_result", -1)) != 0
        or int(proof.get("rcu_walk_hits", -1)) != rcu_hits
        or int(proof.get("ref_walk_hits", -1)) != ref_hits
        or int(proof.get("resolve_failures", -1)) != resolve_failures
        or resolve_failures
        or int(proof.get("expected_device", 0)) != definition["device"]
        or int(proof.get("observed_device", 0)) != definition["device"]
        or int(proof.get("expected_inode", 0)) != definition["inode"]
        or int(proof.get("observed_inode", 0)) != definition["inode"]
    ):
        raise AnalysisError(f"{cell}: RCU proof does not match raw branch events")
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
    summary = summaries[0]
    expected_trace = f"{cell}-concurrent-rcu-trace.txt"
    if summary.get("raw_trace") != expected_trace:
        raise AnalysisError(f"{cell}: unexpected raw trace path")
    raw = parse_concurrent_rcu_trace(Path(history_dir) / expected_trace)

    markers = [
        (record.get("phase"), int(record.get("writer_seq", 0)))
        for record in records
        if record.get("event") == "target-lifetime-rcu-marker"
        and record.get("cell") == cell
    ]
    if markers != raw["markers"]:
        raise AnalysisError(f"{cell}: emitted markers do not match raw trace")
    concurrent = [
        record
        for record in records
        if record.get("event") == "target-lifetime-rcu-branch"
        and record.get("cell") == cell
        and record.get("phase") == "concurrent"
    ]
    if any(
        record.get("source")
        != "kretprobe:namei_ext_resolve_target:arg2+retval"
        or record.get("rcu_walk") is not True
        or not isinstance(record.get("result"), int)
        or not isinstance(record.get("under_update"), bool)
        or (record.get("under_update") is True)
        != (int(record.get("writer_seq", 0)) > 0)
        for record in concurrent
    ):
        raise AnalysisError(f"{cell}: malformed concurrent RCU branch evidence")
    observed_branches = [
        {
            "under_update": record["under_update"],
            "writer_seq": int(record["writer_seq"]),
            "result": int(record["result"]),
        }
        for record in concurrent
    ]
    if observed_branches != raw["branches"]:
        raise AnalysisError(f"{cell}: emitted branches do not match raw trace")

    emitted_updates = [
        {
            "phase": record.get("phase"),
            "writer_seq": int(record.get("writer_seq", 0)),
            **(
                {"result": int(record.get("result", 0))}
                if record.get("phase") == "return"
                else {}
            ),
        }
        for record in records
        if record.get("event") == "target-lifetime-rcu-update"
        and record.get("cell") == cell
    ]
    if emitted_updates != raw["updates"]:
        raise AnalysisError(f"{cell}: emitted kernel update events do not match raw trace")

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
    if not marked_sequences.issubset(update_sequences):
        raise AnalysisError(f"{cell}: trace marker lacks paired update history")
    if any(
        branch["writer_seq"] not in marked_sequences
        for branch in raw["branches"]
        if branch["under_update"]
    ):
        raise AnalysisError(f"{cell}: RCU branch names an unmarked update")
    overlap_classes = validate_rcu_update_classes(raw, updates, cell)

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
    concurrent_result = {
        **expected_summary,
        **overlap_classes,
    }
    return {
        "controlled": {
            "rcu_walk_hits": rcu_hits,
            "ref_walk_hits": ref_hits,
        },
        "concurrent": concurrent_result,
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
    ]
    if failed:
        raise AnalysisError(f"{cell}: {len(failed)} reader engagement failures")
    if len({int(record["reader"]) for record in readers}) != len(readers):
        raise AnalysisError(f"{cell}: duplicate reader summaries")

    observed = defaultdict(lambda: {"opens": 0, "successful_opens": 0,
                                    "absent_opens": 0})
    for operation in operations:
        if operation["operation"] != "OPEN" or operation["actor"] != "reader":
            continue
        summary = observed[operation["actor_id"]]
        summary["opens"] += 1
        summary["successful_opens"] += operation["result"] == 0
        summary["absent_opens"] += operation["result"] == -2
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
    return len(readers)


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
    for line in Path(path).read_text(encoding="utf-8").splitlines():
        match = re.fullmatch(r"([a-z_]+):\s+(-?\d+)", line.strip())
        if match:
            counters[match.group(1)] = int(match.group(2))
    for required in (
        "enabled",
        "used_watchpoints",
        "setup_watchpoints",
        "data_races",
    ):
        if required not in counters:
            raise AnalysisError(f"{path}: missing KCSAN counter {required}")
    return counters


def validate_kcsan_engagement(before_path, after_path):
    before = parse_kcsan_counters(before_path)
    after = parse_kcsan_counters(after_path)
    if before["enabled"] != 1 or after["enabled"] != 1:
        raise AnalysisError("KCSAN was not enabled throughout the stress")
    deltas = {
        key: after[key] - before.get(key, 0)
        for key in ("used_watchpoints", "setup_watchpoints", "data_races")
        if key in after
    }
    if before["used_watchpoints"] < 0 or after["used_watchpoints"] < 0:
        raise AnalysisError("KCSAN used-watchpoint gauge is invalid")
    if deltas["setup_watchpoints"] <= 0:
        raise AnalysisError(f"KCSAN watchpoints did not engage: {deltas}")
    if deltas["data_races"] != 0:
        raise AnalysisError(f"KCSAN observed data races during stress: {deltas}")
    return deltas


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
        rcu_proof = (
            validate_rcu_proof(
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
            "rcu_proof": rcu_proof,
            "descriptor_checks": descriptors,
            "target_definitions": target_definitions,
            "lower_object_checks": lower_objects,
            "cleanup": cleanup,
            "readers": readers,
            "runner_summary": summary,
        }
    lifecycle_cycles = validate_lifecycle(
        records, run_config["lifecycle_cycles"]
    )
    config = validate_kernel_config(args.kernel_config, args.kernel_kind)
    dmesg = classify_dmesg(args.dmesg)
    if dmesg["status"] != "clean":
        raise AnalysisError(
            f"kernel diagnostics make boot {dmesg['status']}: "
            f"{dmesg['diagnostics']} block(s)"
        )

    kcsan = None
    if args.kernel_kind == "kcsan":
        if not args.kcsan_before or not args.kcsan_after:
            raise AnalysisError("KCSAN boot lacks before/after counters")
        kcsan = validate_kcsan_engagement(args.kcsan_before, args.kcsan_after)
    elif args.kcsan_before or args.kcsan_after:
        raise AnalysisError("non-KCSAN boot unexpectedly supplied counters")

    control_rows = None
    if args.control:
        control_rows = validate_control(args.control)
    elif args.require_control:
        raise AnalysisError("formal boot lacks current 37-row namei control")

    result = {
        "schema": "namei_ext.target_lifetime.boot.v1",
        "kernel_kind": args.kernel_kind,
        "status": "positive",
        "run_config": run_config,
        "cells": cells,
        "lifecycle_cycles": lifecycle_cycles,
        "kernel_config_checked": sorted(config),
        "kcsan_deltas": kcsan,
        "dmesg": dmesg,
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
        "duration_seconds_per_publication_cell": FORMAL_CONFIG[
            "duration_seconds"
        ],
        "readers": FORMAL_CONFIG["readers"],
        "minimum_updates": FORMAL_CONFIG["minimum_updates"],
        "minimum_opens_per_reader": FORMAL_CONFIG[
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
        "schema": "namei_ext.target_lifetime.formal.v1",
        "status": "positive",
        "repetitions_per_kernel": args.repetitions,
        "boots": len(summaries),
        "kernel_kinds": {
            kind: sum(1 for summary in summaries if summary["kernel_kind"] == kind)
            for kind in ("normal", "kasan", "kcsan")
        },
        "history_violations": 0,
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
