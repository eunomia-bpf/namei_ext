#!/usr/bin/env python3

import importlib.util
import itertools
import tempfile
import unittest
from pathlib import Path
from unittest import mock


MODULE_PATH = Path(__file__).with_name("analyze.py")
SPEC = importlib.util.spec_from_file_location("target_lifetime_analyze", MODULE_PATH)
ANALYZE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(ANALYZE)


def operation(op_id, operation, invoke, response, state, result=0, writer_seq=0):
    return {
        "op_id": op_id,
        "operation": operation,
        "subtype": "",
        "actor": "writer" if operation in {"SET", "CLEAR"} else "reader",
        "actor_id": 0,
        "writer_seq": writer_seq,
        "invoke": (invoke, op_id * 2),
        "response": (response, op_id * 2 + 1),
        "state": state,
        "result": result,
        "device": 1 if result == 0 and operation == "OPEN" else 0,
        "inode": op_id if result == 0 and operation == "OPEN" else 0,
    }


def target_definition(state, device, inode, directory=False, child=(0, 0)):
    return {
        "event": "target-lifetime-target",
        "cell": "cell",
        "state": state,
        "directory": directory,
        "device": device,
        "inode": inode,
        "mode": 33188,
        "uid": 0,
        "gid": 0,
        "size": 2,
        "child_device": child[0],
        "child_inode": child[1],
        "child_mode": 0,
        "child_uid": 0,
        "child_gid": 0,
        "child_size": 0,
    }


def litmus_record(operation, cookie, mount=100, dentry=200):
    replace = operation == "replace"
    record = {
        "event": "target-lifetime-rcu-litmus",
        "cell": "final-file",
        "operation": operation,
        "source": "tracing-bpf-kprobe-kretprobe",
        "version": 2,
        "cookie": cookie,
        "mode": 1 if replace else 2,
        "state": 4,
        "event_seq": 5 if replace else 7,
        "reader_tid": 101,
        "observed_reader_tid": 101,
        "writer_tid": 100,
        "observed_writer_tid": 100,
        "writer_cpu": 0,
        "observed_writer_cpu": 0,
        "reader_cpu": 1,
        "observed_reader_cpu": 1,
        "expected_cgroup_id": 55,
        "observed_cgroup_id": 55,
        "expected_target_id": 1,
        "observed_target_id": 1,
        "observed_mount": mount,
        "observed_dentry": dentry,
        "resolve_redirect": 300,
        "resolve_rcu_walk": 1,
        "hold_seq": 1,
        "update_entry_seq": 2,
        "clear_entry_seq": 0 if replace else 3,
        "grace_entry_seq": 3 if replace else 4,
        "reader_release_seq": 4 if replace else 5,
        "clear_exit_seq": 0 if replace else 6,
        "update_exit_seq": 5 if replace else 7,
        "hold_ns": 10,
        "update_entry_ns": 20,
        "clear_entry_ns": 0 if replace else 30,
        "grace_entry_ns": 30 if replace else 40,
        "reader_release_ns": 40 if replace else 50,
        "clear_exit_ns": 0 if replace else 60,
        "update_exit_ns": 50 if replace else 70,
        "hold_cookie": cookie,
        "update_cookie": cookie,
        "grace_cookie": cookie,
        "release_cookie": cookie,
        "exit_cookie": cookie,
        "resolve_attempts": 1,
        "resolve_matches": 1,
        "update_entries": 1,
        "clear_entries": 0 if replace else 1,
        "grace_entries": 1,
        "clear_exits": 0 if replace else 1,
        "update_exits": 1,
        "error_flags": 0,
        "timeout_reason": 0,
        "update_result": 0,
        "reader_open_result": 0,
        "reader_validation_result": 0,
        "old_state": "A",
        "fresh_state": "B" if replace else "absent",
        "expected_old_device": 7,
        "observed_old_device": 7,
        "expected_old_inode": 11,
        "observed_old_inode": 11,
        "fresh_result": 0 if replace else -2,
        "expected_fresh_device": 8 if replace else 0,
        "observed_fresh_device": 8 if replace else 0,
        "expected_fresh_inode": 12 if replace else 0,
        "observed_fresh_inode": 12 if replace else 0,
        "pass": True,
    }
    return record


def brute_linearizable(history):
    edges = {
        (left, right)
        for left, first in enumerate(history)
        for right, second in enumerate(history)
        if left != right and first["response"] < second["invoke"]
    }
    updates = sorted(
        (
            index
            for index, item in enumerate(history)
            if item["operation"] in {"SET", "CLEAR"}
        ),
        key=lambda index: history[index]["writer_seq"],
    )
    edges.update(zip(updates, updates[1:]))
    for order in itertools.permutations(range(len(history))):
        position = {item: index for index, item in enumerate(order)}
        if any(position[left] >= position[right] for left, right in edges):
            continue
        state = "absent"
        valid = True
        for index in order:
            item = history[index]
            if item["operation"] == "SET":
                state = item["state"]
            elif item["operation"] == "CLEAR":
                state = "absent"
            elif item["state"] != state:
                valid = False
                break
        if valid:
            return True
    return False


class LinearizabilityTests(unittest.TestCase):
    def test_accepts_explicit_history_and_stress_run_configuration(self):
        record = {
            "event": "target-lifetime-run-start",
            "duration_seconds": 5,
            "history_timeout_seconds": 5,
            "stress_duration_seconds": 5,
            "readers": 2,
            "minimum_updates": 8,
            "target_updates": 8,
            "minimum_opens_per_reader": 64,
            "target_opens_per_reader": 64,
            "lifecycle_cycles": 4,
        }
        observed = ANALYZE.validate_run_start([record])
        self.assertEqual(observed["minimum_updates"], 8)

    def test_rejects_inconsistent_history_timeout_alias(self):
        record = {
            "event": "target-lifetime-run-start",
            "duration_seconds": 5,
            "history_timeout_seconds": 4,
            "stress_duration_seconds": 5,
            "readers": 2,
            "minimum_updates": 8,
            "target_updates": 8,
            "minimum_opens_per_reader": 64,
            "target_opens_per_reader": 64,
            "lifecycle_cycles": 4,
        }
        with self.assertRaisesRegex(ANALYZE.AnalysisError, "history_timeout"):
            ANALYZE.validate_run_start([record])

    def test_valid_overlapping_history(self):
        history = [
            operation(1, "SET", 1, 4, "A", writer_seq=1),
            operation(2, "OPEN", 2, 3, "A"),
            operation(3, "CLEAR", 5, 8, "absent", writer_seq=2),
            operation(4, "OPEN", 6, 7, "absent", result=-2),
        ]
        result = ANALYZE.check_linearizable(history)
        self.assertEqual(result["updates"], 2)
        self.assertEqual(result["opens"], 2)
        self.assertEqual(result["successful_opens"], 1)
        self.assertEqual(result["absent_opens"], 1)
        self.assertEqual(result["overlap_opens"], 2)

    def test_rejects_history_without_update_reader_overlap(self):
        history = [
            operation(1, "SET", 1, 2, "A", writer_seq=1),
            operation(2, "OPEN", 3, 4, "A"),
            operation(3, "CLEAR", 5, 6, "absent", writer_seq=2),
            operation(4, "OPEN", 7, 8, "absent", result=-2),
        ]
        result = ANALYZE.check_linearizable(history)
        self.assertEqual(result["overlap_opens"], 0)
        with self.assertRaisesRegex(ANALYZE.AnalysisError, "overlap"):
            ANALYZE.validate_overlap(result, {"readers": 1}, "final-file")

    def test_event_sequence_orders_equal_timestamp_boundaries(self):
        def event(phase, operation_name, op_id, event_seq, writer_seq=0):
            return {
                "event": "target-lifetime-history",
                "cell": "final-file",
                "phase": phase,
                "operation": operation_name,
                "subtype": "",
                "actor": "writer" if operation_name == "SET" else "reader",
                "actor_id": 0,
                "op_id": op_id,
                "writer_seq": writer_seq,
                "event_seq": event_seq,
                "time_ns": 100,
                "state": "A",
                "device": 1,
                "inode": 1,
                "result": 0,
            }

        records = [
            event("invoke", "SET", 1, 1, 1),
            event("response", "SET", 1, 2, 1),
            event("invoke", "OPEN", 2, 3),
            {
                "event": "target-lifetime-open-return",
                "cell": "final-file",
                "actor": "reader",
                "actor_id": 0,
                "op_id": 2,
                "event_seq": 4,
                "time_ns": 100,
                "result": 0,
            },
            event("response", "OPEN", 2, 5),
        ]
        operations = ANALYZE.pair_history(records, "final-file")
        update = next(item for item in operations if item["operation"] == "SET")
        read = next(item for item in operations if item["operation"] == "OPEN")
        self.assertLess(update["response"], read["invoke"])
        self.assertEqual(read["response"], 4)

    def test_rejects_open_history_without_syscall_return_boundary(self):
        def event(phase, event_seq):
            return {
                "event": "target-lifetime-history",
                "cell": "final-file",
                "phase": phase,
                "operation": "OPEN",
                "subtype": "file",
                "actor": "reader",
                "actor_id": 0,
                "op_id": 1,
                "writer_seq": 0,
                "event_seq": event_seq,
                "time_ns": 100,
                "state": "A",
                "device": 1,
                "inode": 2,
                "result": 0,
            }

        with self.assertRaisesRegex(ANALYZE.AnalysisError, "lacks syscall return"):
            ANALYZE.pair_history(
                [event("invoke", 1), event("response", 2)], "final-file"
            )

    def test_rejects_stale_after_clear_response(self):
        history = [
            operation(1, "SET", 1, 2, "A", writer_seq=1),
            operation(2, "CLEAR", 3, 4, "absent", writer_seq=2),
            operation(3, "OPEN", 5, 6, "A"),
        ]
        with self.assertRaisesRegex(ANALYZE.AnalysisError, "no global"):
            ANALYZE.check_linearizable(history)

    def test_rejects_old_object_after_set_b_response(self):
        history = [
            operation(1, "SET", 1, 2, "A", writer_seq=1),
            operation(2, "SET", 3, 4, "B", writer_seq=2),
            operation(3, "OPEN", 5, 6, "A"),
        ]
        with self.assertRaisesRegex(ANALYZE.AnalysisError, "no global"):
            ANALYZE.check_linearizable(history)

    def test_rejects_locally_valid_but_globally_impossible(self):
        history = [
            operation(1, "SET", 0, 1, "A", writer_seq=1),
            operation(2, "SET", 2, 10, "B", writer_seq=2),
            operation(3, "OPEN", 3, 4, "B"),
            operation(4, "OPEN", 5, 6, "A"),
        ]
        with self.assertRaisesRegex(ANALYZE.AnalysisError, "no global"):
            ANALYZE.check_linearizable(history)

    def test_rejects_unexpected_open_errno(self):
        history = [
            operation(1, "SET", 1, 2, "A", writer_seq=1),
            operation(2, "OPEN", 3, 4, "error", result=-5),
        ]
        with self.assertRaisesRegex(ANALYZE.AnalysisError, "unexpected"):
            ANALYZE.check_linearizable(history)

    def test_rejects_state_identity_mismatch(self):
        records = [target_definition("A", 7, 11)]
        records[0]["cell"] = "final-file"
        history = [operation(1, "OPEN", 1, 2, "A")]
        history[0]["device"] = 7
        history[0]["inode"] = 12
        history[0]["subtype"] = "file"
        with self.assertRaisesRegex(ANALYZE.AnalysisError, "does not match"):
            ANALYZE.validate_open_identities(records, "final-file", history)

    def test_rejects_lower_object_metadata_mismatch(self):
        records = [target_definition("A", 7, 11)]
        definitions = ANALYZE.load_target_definitions(records, "cell")
        records.append(
            {
                "event": "target-lifetime-lower-object",
                "cell": "cell",
                "state": "A",
                "object": "target",
                "expected_device": 7,
                "observed_device": 7,
                "expected_inode": 11,
                "observed_inode": 11,
                "expected_mode": 33152,
                "observed_mode": 33152,
                "expected_uid": 0,
                "observed_uid": 0,
                "expected_gid": 0,
                "observed_gid": 0,
                "expected_size": 2,
                "observed_size": 2,
                "bytes_match": True,
                "result": 0,
                "pass": True,
            }
        )
        with self.assertRaisesRegex(ANALYZE.AnalysisError, "lower-object"):
            ANALYZE.validate_lower_objects(records, "cell", definitions)

    def test_rejects_kcsan_race_counter_delta(self):
        with tempfile.TemporaryDirectory() as directory:
            before = Path(directory) / "before"
            after = Path(directory) / "after"
            before.write_text(
                "enabled: 0\nused_watchpoints: 0\n"
                "setup_watchpoints: 20\ndata_races: 0\nassert_failures: 0\n"
                "\nblacklisted functions: none\n"
            )
            after.write_text(
                "enabled: 0\nused_watchpoints: 0\n"
                "setup_watchpoints: 22\ndata_races: 1\nassert_failures: 0\n"
                "\nblacklisted functions: none\n"
            )
            with self.assertRaisesRegex(ANALYZE.AnalysisError, "data races"):
                ANALYZE.validate_kcsan_engagement(before, after)

    def test_accepts_kcsan_engagement_with_quiescent_used_gauge(self):
        with tempfile.TemporaryDirectory() as directory:
            before = Path(directory) / "before"
            after = Path(directory) / "after"
            before.write_text(
                "enabled: 0\nused_watchpoints: 0\n"
                "setup_watchpoints: 20\ndata_races: 0\nassert_failures: 0\n"
                "\nblacklisted functions: none\n"
            )
            after.write_text(
                "enabled: 0\nused_watchpoints: 0\n"
                "setup_watchpoints: 22\ndata_races: 0\nassert_failures: 0\n"
                "\nblacklisted functions: none\n"
            )
            deltas = ANALYZE.validate_kcsan_engagement(before, after)
            self.assertEqual(deltas["used_watchpoints"], 0)
            self.assertEqual(deltas["setup_watchpoints"], 2)

    def test_rejects_kcsan_left_enabled_outside_workload(self):
        with tempfile.TemporaryDirectory() as directory:
            before = Path(directory) / "before"
            after = Path(directory) / "after"
            before.write_text(
                "enabled: 1\nused_watchpoints: 0\n"
                "setup_watchpoints: 20\ndata_races: 0\nassert_failures: 0\n"
                "\nblacklisted functions: none\n"
            )
            after.write_text(
                "enabled: 0\nused_watchpoints: 0\n"
                "setup_watchpoints: 22\ndata_races: 0\nassert_failures: 0\n"
                "\nblacklisted functions: none\n"
            )
            with self.assertRaisesRegex(ANALYZE.AnalysisError, "workload windows"):
                ANALYZE.validate_kcsan_engagement(before, after)

    def test_rejects_kcsan_without_watchpoint_engagement(self):
        with tempfile.TemporaryDirectory() as directory:
            before = Path(directory) / "before"
            after = Path(directory) / "after"
            contents = (
                "enabled: 0\nused_watchpoints: 0\n"
                "setup_watchpoints: 20\ndata_races: 0\nassert_failures: 0\n"
                "\nblacklisted functions: none\n"
            )
            before.write_text(contents)
            after.write_text(contents)
            with self.assertRaisesRegex(ANALYZE.AnalysisError, "did not engage"):
                ANALYZE.validate_kcsan_engagement(before, after)

    def test_rejects_kcsan_report_filtering(self):
        with tempfile.TemporaryDirectory() as directory:
            counters = Path(directory) / "counters"
            counters.write_text(
                "enabled: 0\nused_watchpoints: 0\nsetup_watchpoints: 20\n"
                "data_races: 0\nassert_failures: 0\n"
                "\nwhitelisted functions:\n namei_ext_resolve_target\n"
            )
            with self.assertRaisesRegex(ANALYZE.AnalysisError, "filtering"):
                ANALYZE.parse_kcsan_counters(counters)

    def test_requires_kcsan_engagement_for_every_cell(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for index, cell in enumerate(ANALYZE.KCSAN_CELLS):
                before = (
                    "enabled: 0\nused_watchpoints: 0\n"
                    f"setup_watchpoints: {20 + index * 2}\n"
                    "data_races: 0\nassert_failures: 0\n"
                    "\nblacklisted functions: none\n"
                )
                after = (
                    "enabled: 0\nused_watchpoints: 0\n"
                    f"setup_watchpoints: {21 + index * 2}\n"
                    "data_races: 0\nassert_failures: 0\n"
                    "\nblacklisted functions: none\n"
                )
                (root / f"{cell}-kcsan-before.txt").write_text(before)
                (root / f"{cell}-kcsan-after.txt").write_text(after)
            results = ANALYZE.validate_kcsan_cells(root)
            self.assertEqual(set(results), set(ANALYZE.KCSAN_CELLS))

            total = {
                "used_watchpoints": 0,
                "setup_watchpoints": 3,
                "data_races": 0,
                "assert_failures": 0,
            }
            ANALYZE.validate_kcsan_partition(total, results)

            (root / "directory-kcsan-after.txt").write_text(
                (root / "directory-kcsan-before.txt").read_text()
            )
            with self.assertRaisesRegex(ANALYZE.AnalysisError, "did not engage"):
                ANALYZE.validate_kcsan_cells(root)

            (root / "directory-kcsan-after.txt").unlink()
            with self.assertRaisesRegex(ANALYZE.AnalysisError, "directory"):
                ANALYZE.validate_kcsan_cells(root)

    def test_rejects_kcsan_activity_outside_cell_windows(self):
        cells = {
            cell: {"setup_watchpoints": 2} for cell in ANALYZE.KCSAN_CELLS
        }
        with self.assertRaisesRegex(ANALYZE.AnalysisError, "outside"):
            ANALYZE.validate_kcsan_partition(
                {"setup_watchpoints": 7}, cells
            )

    def test_kcsan_config_disables_early_instrumentation(self):
        config = Path("configs/kernel/x86_64_phase1_kcsan.config")
        checked = ANALYZE.validate_kernel_config(config, "kcsan")
        self.assertEqual(checked["CONFIG_KCSAN_EARLY_ENABLE"], "n")

    def test_rejects_kcsan_config_with_early_instrumentation(self):
        source = Path("configs/kernel/x86_64_phase1_kcsan.config").read_text()
        with tempfile.TemporaryDirectory() as directory:
            config = Path(directory) / "kernel.config"
            config.write_text(
                source.replace(
                    "# CONFIG_KCSAN_EARLY_ENABLE is not set",
                    "CONFIG_KCSAN_EARLY_ENABLE=y",
                )
            )
            with self.assertRaisesRegex(
                ANALYZE.AnalysisError, "CONFIG_KCSAN_EARLY_ENABLE"
            ):
                ANALYZE.validate_kernel_config(config, "kcsan")

    def test_ignores_informational_rcu_lockdep_boot_line(self):
        with tempfile.TemporaryDirectory() as directory:
            dmesg = Path(directory) / "dmesg"
            dmesg.write_text("RCU lockdep checking is enabled.\n")
            self.assertEqual(ANALYZE.classify_dmesg(dmesg)["status"], "clean")

    def test_ignores_informational_kcsan_boot_lines(self):
        with tempfile.TemporaryDirectory() as directory:
            dmesg = Path(directory) / "dmesg"
            dmesg.write_text(
                "kcsan: enabled early\n"
                "kcsan: strict mode configured\n"
            )
            self.assertEqual(ANALYZE.classify_dmesg(dmesg)["status"], "clean")

    def test_classifies_kcsan_data_race(self):
        with tempfile.TemporaryDirectory() as directory:
            dmesg = Path(directory) / "dmesg"
            dmesg.write_text(
                "BUG: KCSAN: data-race in namei_ext_resolve_target / "
                "namei_ext_clear_targets\n"
            )
            self.assertEqual(ANALYZE.classify_dmesg(dmesg)["status"], "negative")

    def test_rejects_tracing_config_without_kernel_btf(self):
        with tempfile.TemporaryDirectory() as directory:
            config = Path(directory) / "kernel.config"
            config.write_text(
                "CONFIG_NAMEI_EXT=y\n"
                "CONFIG_DEBUG_FS=y\n"
                "CONFIG_TRACING=y\n"
                "CONFIG_KPROBE_EVENTS=y\n"
                "CONFIG_KPROBES=y\n"
                "CONFIG_BPF_EVENTS=y\n"
                "CONFIG_BPF_JIT=y\n"
                "# CONFIG_DEBUG_INFO_BTF is not set\n"
                "# CONFIG_KASAN is not set\n"
                "# CONFIG_KCSAN is not set\n"
            )
            with self.assertRaisesRegex(
                ANALYZE.AnalysisError, "CONFIG_DEBUG_INFO_BTF"
            ):
                ANALYZE.validate_kernel_config(config, "normal")

    def test_rejects_summary_pass_below_reader_minimum(self):
        records = [
            {
                "event": "target-lifetime-reader-summary",
                "cell": "final-file",
                "reader": 0,
                "opens": 7,
                "successful_opens": 3,
                "absent_opens": 4,
                "pass": True,
            }
        ]
        config = {"readers": 1, "minimum_opens_per_reader": 8}
        with self.assertRaisesRegex(ANALYZE.AnalysisError, "engagement"):
            ANALYZE.validate_reader_summaries(
                records, "final-file", config, []
            )

    def test_rejects_reader_summary_not_backed_by_history(self):
        records = [
            {
                "event": "target-lifetime-reader-summary",
                "cell": "final-file",
                "reader": 0,
                "opens": 3,
                "successful_opens": 2,
                "absent_opens": 1,
                "distinct_selected_states": 2,
                "unexpected_errors": 0,
                "target_opens": 1,
                "maximum_opens": 18,
                "pass": True,
            }
        ]
        history = [
            operation(1, "OPEN", 1, 2, "A"),
            operation(2, "OPEN", 3, 4, "absent", result=-2),
        ]
        with self.assertRaisesRegex(ANALYZE.AnalysisError, "summary"):
            ANALYZE.validate_reader_summaries(
                records,
                "final-file",
                {
                    "readers": 1,
                    "minimum_updates": 1,
                    "minimum_opens_per_reader": 1,
                },
                history,
            )

    def test_accepts_reader_summary_with_two_selected_states(self):
        records = [
            {
                "event": "target-lifetime-reader-summary",
                "cell": "final-file",
                "reader": 0,
                "opens": 3,
                "successful_opens": 2,
                "absent_opens": 1,
                "distinct_selected_states": 2,
                "unexpected_errors": 0,
                "target_opens": 1,
                "maximum_opens": 18,
                "pass": True,
            }
        ]
        history = [
            operation(1, "OPEN", 1, 2, "A"),
            operation(2, "OPEN", 3, 4, "B"),
            operation(3, "OPEN", 5, 6, "absent", result=-2),
        ]
        observed = ANALYZE.validate_reader_summaries(
            records,
            "final-file",
            {
                "readers": 1,
                "minimum_updates": 1,
                "minimum_opens_per_reader": 1,
            },
            history,
        )
        self.assertEqual(observed, 1)

    def test_accepts_bounded_history_and_duration_stress_phases(self):
        config = {
            "duration_seconds": 5,
            "readers": 1,
            "minimum_updates": 1,
            "minimum_opens_per_reader": 1,
        }
        records = [
            {
                "event": "target-lifetime-phase-summary",
                "cell": "final-file",
                "phase": "history",
                "duration_seconds": 5,
                "elapsed_ns": 1000,
                "readers": 1,
                "updates": 1,
                "target_updates": 1,
                "target_opens_per_reader": 1,
                "maximum_history_opens_per_reader": 18,
                "timed_out": False,
                "failures": 0,
                "pass": True,
            },
            {
                "event": "target-lifetime-phase-summary",
                "cell": "final-file",
                "phase": "stress",
                "duration_seconds": 5,
                "elapsed_ns": 5_000_000_001,
                "readers": 1,
                "updates": 9,
                "target_updates": 1,
                "target_opens_per_reader": 1,
                "maximum_history_opens_per_reader": 0,
                "timed_out": False,
                "failures": 0,
                "pass": True,
            },
            {
                "event": "target-lifetime-stress-reader-summary",
                "cell": "final-file",
                "reader": 0,
                "opens": 20,
                "successful_opens": 12,
                "absent_opens": 8,
                "unexpected_errors": 0,
                "target_opens": 1,
                "maximum_opens": 0,
                "pass": True,
            },
        ]
        history = [operation(1, "SET", 1, 2, "A", writer_seq=1)]
        observed = ANALYZE.validate_publication_phases(
            records, "final-file", config, history
        )
        self.assertEqual(observed["stress_updates"], 9)
        self.assertEqual(observed["stress_opens"], 20)

    def test_rejects_history_completion_after_deadline(self):
        config = {
            "duration_seconds": 1,
            "readers": 1,
            "minimum_updates": 1,
            "minimum_opens_per_reader": 1,
        }
        records = [
            {
                "event": "target-lifetime-phase-summary",
                "cell": "final-file",
                "phase": phase,
                "duration_seconds": 1,
                "elapsed_ns": 1_000_000_001,
                "readers": 1,
                "updates": 1,
                "target_updates": 1,
                "target_opens_per_reader": 1,
                "maximum_history_opens_per_reader": 18
                if phase == "history"
                else 0,
                "timed_out": False,
                "failures": 0,
                "pass": True,
            }
            for phase in ("history", "stress")
        ]
        records.append(
            {
                "event": "target-lifetime-stress-reader-summary",
                "cell": "final-file",
                "reader": 0,
                "opens": 2,
                "successful_opens": 1,
                "absent_opens": 1,
                "unexpected_errors": 0,
                "target_opens": 1,
                "maximum_opens": 0,
                "pass": True,
            }
        )
        with self.assertRaisesRegex(ANALYZE.AnalysisError, "exceeded"):
            ANALYZE.validate_publication_phases(
                records,
                "final-file",
                config,
                [operation(1, "SET", 1, 2, "A", writer_seq=1)],
            )

    def test_rejects_short_stress_phase(self):
        config = {
            "duration_seconds": 5,
            "readers": 1,
            "minimum_updates": 1,
            "minimum_opens_per_reader": 1,
        }
        records = [
            {
                "event": "target-lifetime-phase-summary",
                "cell": "final-file",
                "phase": phase,
                "duration_seconds": 5,
                "elapsed_ns": 1000,
                "readers": 1,
                "updates": 1,
                "target_updates": 1,
                "target_opens_per_reader": 1,
                "maximum_history_opens_per_reader": 18
                if phase == "history"
                else 0,
                "timed_out": False,
                "failures": 0,
                "pass": True,
            }
            for phase in ("history", "stress")
        ]
        records.append(
            {
                "event": "target-lifetime-stress-reader-summary",
                "cell": "final-file",
                "reader": 0,
                "opens": 2,
                "successful_opens": 1,
                "absent_opens": 1,
                "unexpected_errors": 0,
                "target_opens": 1,
                "maximum_opens": 0,
                "pass": True,
            }
        )
        with self.assertRaisesRegex(ANALYZE.AnalysisError, "deadline"):
            ANALYZE.validate_publication_phases(
                records,
                "final-file",
                config,
                [operation(1, "SET", 1, 2, "A", writer_seq=1)],
            )

    def test_rejects_stress_operation_failure_record(self):
        config = {
            "duration_seconds": 1,
            "readers": 1,
            "minimum_updates": 1,
            "minimum_opens_per_reader": 1,
        }
        records = [
            {
                "event": "target-lifetime-phase-summary",
                "cell": "final-file",
                "phase": phase,
                "duration_seconds": 1,
                "elapsed_ns": 1000
                if phase == "history"
                else 1_000_000_001,
                "readers": 1,
                "updates": 1,
                "target_updates": 1,
                "target_opens_per_reader": 1,
                "maximum_history_opens_per_reader": 18
                if phase == "history"
                else 0,
                "timed_out": False,
                "failures": 0,
                "pass": True,
            }
            for phase in ("history", "stress")
        ]
        records.extend(
            [
                {
                    "event": "target-lifetime-stress-reader-summary",
                    "cell": "final-file",
                    "reader": 0,
                    "opens": 2,
                    "successful_opens": 1,
                    "absent_opens": 1,
                    "unexpected_errors": 0,
                    "target_opens": 1,
                    "maximum_opens": 0,
                    "pass": True,
                },
                {
                    "event": "target-lifetime-operation-failure",
                    "cell": "final-file",
                    "phase": "stress",
                    "pass": False,
                },
            ]
        )
        with self.assertRaisesRegex(ANALYZE.AnalysisError, "operation"):
            ANALYZE.validate_publication_phases(
                records,
                "final-file",
                config,
                [operation(1, "SET", 1, 2, "A", writer_seq=1)],
            )

    def test_rejects_missing_descriptor_for_successful_open(self):
        history = [operation(1, "OPEN", 1, 2, "A")]
        history[0]["subtype"] = "file"
        with self.assertRaisesRegex(ANALYZE.AnalysisError, "descriptor"):
            ANALYZE.validate_descriptors([], "final-file", history)

    def test_rejects_target_retirement_without_litmus_rows(self):
        definitions = {
            "A": {"device": 7, "inode": 11},
        }
        with self.assertRaisesRegex(ANALYZE.AnalysisError, "litmus rows"):
            ANALYZE.validate_target_retirement([], "final-file", definitions)

    def test_accepts_deterministic_litmus_and_stress_engagement(self):
        definitions = {
            "A": {"device": 7, "inode": 11},
            "B": {"device": 8, "inode": 12},
        }
        records = [
            litmus_record("replace", 1),
            litmus_record("clear", 2),
            {
                "event": "target-lifetime-rcu-marker",
                "cell": "final-file",
                "phase": "begin",
                "writer_seq": 1,
            },
            {
                "event": "target-lifetime-rcu-update",
                "cell": "final-file",
                "phase": "enter",
                "writer_seq": 1,
            },
            {
                "event": "target-lifetime-rcu-update",
                "cell": "final-file",
                "phase": "return",
                "writer_seq": 1,
                "result": 5,
            },
            {
                "event": "target-lifetime-rcu-marker",
                "cell": "final-file",
                "phase": "end",
                "writer_seq": 1,
            },
            {
                "event": "target-lifetime-rcu-marker",
                "cell": "final-file",
                "phase": "begin",
                "writer_seq": 2,
            },
            {
                "event": "target-lifetime-rcu-update",
                "cell": "final-file",
                "phase": "enter",
                "writer_seq": 2,
            },
            {
                "event": "target-lifetime-rcu-branch",
                "cell": "final-file",
                "source": "kretprobe:namei_ext_resolve_target:arg2+retval",
                "phase": "concurrent",
                "rcu_walk": True,
                "result": 0,
                "under_update": True,
                "writer_seq": 2,
            },
            {
                "event": "target-lifetime-rcu-update",
                "cell": "final-file",
                "phase": "return",
                "writer_seq": 2,
                "result": 5,
            },
            {
                "event": "target-lifetime-rcu-marker",
                "cell": "final-file",
                "phase": "end",
                "writer_seq": 2,
            },
            {
                "event": "target-lifetime-rcu-marker",
                "cell": "final-file",
                "phase": "begin",
                "writer_seq": 3,
            },
            {
                "event": "target-lifetime-rcu-update",
                "cell": "final-file",
                "phase": "enter",
                "writer_seq": 3,
            },
            {
                "event": "target-lifetime-rcu-branch",
                "cell": "final-file",
                "source": "kretprobe:namei_ext_resolve_target:arg2+retval",
                "phase": "concurrent",
                "rcu_walk": True,
                "result": -2,
                "under_update": True,
                "writer_seq": 3,
            },
            {
                "event": "target-lifetime-rcu-update",
                "cell": "final-file",
                "phase": "return",
                "writer_seq": 3,
                "result": 6,
            },
            {
                "event": "target-lifetime-rcu-marker",
                "cell": "final-file",
                "phase": "end",
                "writer_seq": 3,
            },
            {
                "event": "target-lifetime-rcu-stress",
                "cell": "final-file",
                "raw_trace": "final-file-concurrent-rcu-trace.txt",
                "trace_clock": "counter",
                "trace_entries": 14,
                "trace_entries_written": 14,
                "begin_markers": 3,
                "end_markers": 3,
                "update_windows": 3,
                "kernel_update_enters": 3,
                "kernel_update_returns": 3,
                "rcu_walk_hits": 1,
                "rcu_resolve_failures": 1,
                "rcu_absent_results": 1,
                "rcu_under_update": 1,
                "result": 0,
                "pass": True,
            },
        ]
        updates = [
            operation(1, "SET", 1, 2, "A", writer_seq=1),
            operation(2, "SET", 3, 4, "B", writer_seq=2),
            operation(3, "CLEAR", 5, 6, "absent", writer_seq=3),
        ]
        with tempfile.TemporaryDirectory() as directory:
            Path(directory, "final-file-concurrent-rcu-trace.txt").write_text(
                "# entries-in-buffer/entries-written: 14/14   #P:4\n"
                "writer-1 [000] .... 1.000: tracing_mark_write: "
                "namei_ext-update-begin-1\n"
                "writer-1 [000] .... 1.001: update_enter: (0)\n"
                "writer-1 [000] .... 1.002: update_return: result=5\n"
                "writer-1 [000] .... 1.003: tracing_mark_write: "
                "namei_ext-update-end-1\n"
                "writer-1 [000] .... 1.004: tracing_mark_write: "
                "namei_ext-update-begin-2\n"
                "writer-1 [000] .... 1.005: update_enter: (0)\n"
                "reader-2 [001] .... 1.006: resolve_return: "
                "rcu_walk=1 result=0\n"
                "writer-1 [000] .... 1.007: update_return: result=5\n"
                "writer-1 [000] .... 1.008: tracing_mark_write: "
                "namei_ext-update-end-2\n"
                "writer-1 [000] .... 1.009: tracing_mark_write: "
                "namei_ext-update-begin-3\n"
                "writer-1 [000] .... 1.010: update_enter: (0)\n"
                "reader-2 [001] .... 1.011: resolve_return: "
                "rcu_walk=1 result=-2\n"
                "writer-1 [000] .... 1.012: update_return: result=6\n"
                "writer-1 [000] .... 1.013: tracing_mark_write: "
                "namei_ext-update-end-3\n"
            )
            result = ANALYZE.validate_target_retirement(
                records, "final-file", definitions, updates, Path(directory)
            )
        self.assertEqual(result["concurrent"]["rcu_walk_hits"], 1)
        self.assertEqual(result["concurrent"]["rcu_resolve_failures"], 1)
        self.assertEqual(result["concurrent"]["rcu_absent_results"], 1)

    def test_rejects_trace_missing_bounded_history_update(self):
        definitions = {
            "A": {"device": 7, "inode": 11},
            "B": {"device": 8, "inode": 12},
        }
        records = [
            litmus_record("replace", 1),
            litmus_record("clear", 2),
            {
                "event": "target-lifetime-rcu-stress",
                "cell": "final-file",
                "raw_trace": "final-file-concurrent-rcu-trace.txt",
            },
        ]
        updates = [
            operation(1, "SET", 1, 2, "A", writer_seq=1),
            operation(2, "CLEAR", 3, 4, "absent", writer_seq=2),
        ]
        raw = {
            "markers": [("begin", 1), ("end", 1)],
            "branches": [],
        }
        with mock.patch.object(
            ANALYZE, "parse_concurrent_rcu_trace", return_value=raw
        ):
            with self.assertRaisesRegex(ANALYZE.AnalysisError, "complete bounded"):
                ANALYZE.validate_target_retirement(
                    records, "final-file", definitions, updates, Path(".")
                )

    def test_rejects_litmus_cookie_mismatch(self):
        records = [litmus_record("replace", 1), litmus_record("clear", 2)]
        records[0]["grace_cookie"] = 9
        definitions = {
            "A": {"device": 7, "inode": 11},
            "B": {"device": 8, "inode": 12},
        }
        with self.assertRaisesRegex(ANALYZE.AnalysisError, "cookie mismatch"):
            ANALYZE.validate_retirement_litmus(
                records, "final-file", definitions
            )

    def test_rejects_litmus_reader_tid_mismatch(self):
        records = [litmus_record("replace", 1), litmus_record("clear", 2)]
        records[0]["observed_reader_tid"] = 999
        definitions = {
            "A": {"device": 7, "inode": 11},
            "B": {"device": 8, "inode": 12},
        }
        with self.assertRaisesRegex(ANALYZE.AnalysisError, "fields are invalid"):
            ANALYZE.validate_retirement_litmus(
                records, "final-file", definitions
            )

    def test_rejects_litmus_without_entry_probe_evidence(self):
        definitions = {
            "A": {"device": 7, "inode": 11},
            "B": {"device": 8, "inode": 12},
        }
        for field, value in (("resolve_redirect", 0), ("resolve_rcu_walk", 0)):
            with self.subTest(field=field):
                records = [litmus_record("replace", 1), litmus_record("clear", 2)]
                records[0][field] = value
                with self.assertRaisesRegex(
                    ANALYZE.AnalysisError, "fields are invalid"
                ):
                    ANALYZE.validate_retirement_litmus(
                        records, "final-file", definitions
                    )

    def test_rejects_old_fexit_litmus_schema(self):
        records = [litmus_record("replace", 1), litmus_record("clear", 2)]
        records[0]["source"] = "tracing-bpf-fexit-kprobe"
        records[0]["version"] = 1
        definitions = {
            "A": {"device": 7, "inode": 11},
            "B": {"device": 8, "inode": 12},
        }
        with self.assertRaisesRegex(ANALYZE.AnalysisError, "fields are invalid"):
            ANALYZE.validate_retirement_litmus(
                records, "final-file", definitions
            )

    def test_rejects_litmus_same_reader_and_writer_tid(self):
        records = [litmus_record("replace", 1), litmus_record("clear", 2)]
        records[0]["writer_tid"] = records[0]["reader_tid"]
        records[0]["observed_writer_tid"] = records[0]["reader_tid"]
        definitions = {
            "A": {"device": 7, "inode": 11},
            "B": {"device": 8, "inode": 12},
        }
        with self.assertRaisesRegex(ANALYZE.AnalysisError, "fields are invalid"):
            ANALYZE.validate_retirement_litmus(
                records, "final-file", definitions
            )

    def test_rejects_litmus_replacement_with_old_object_identity(self):
        records = [litmus_record("replace", 1), litmus_record("clear", 2)]
        records[0]["expected_fresh_device"] = 7
        records[0]["observed_fresh_device"] = 7
        records[0]["expected_fresh_inode"] = 11
        records[0]["observed_fresh_inode"] = 11
        definitions = {
            "A": {"device": 7, "inode": 11},
            "B": {"device": 7, "inode": 11},
        }
        with self.assertRaisesRegex(
            ANALYZE.AnalysisError, "replacement postcondition"
        ):
            ANALYZE.validate_retirement_litmus(
                records, "final-file", definitions
            )

    def test_rejects_litmus_grace_before_update(self):
        records = [litmus_record("replace", 1), litmus_record("clear", 2)]
        records[0]["grace_entry_seq"] = 2
        definitions = {
            "A": {"device": 7, "inode": 11},
            "B": {"device": 8, "inode": 12},
        }
        with self.assertRaisesRegex(ANALYZE.AnalysisError, "event order"):
            ANALYZE.validate_retirement_litmus(
                records, "final-file", definitions
            )

    def test_rejects_litmus_timeout(self):
        records = [litmus_record("replace", 1), litmus_record("clear", 2)]
        records[1]["timeout_reason"] = 1
        definitions = {
            "A": {"device": 7, "inode": 11},
            "B": {"device": 8, "inode": 12},
        }
        with self.assertRaisesRegex(ANALYZE.AnalysisError, "fields are invalid"):
            ANALYZE.validate_retirement_litmus(
                records, "final-file", definitions
            )

    def test_rejects_litmus_borrowing_different_old_object(self):
        records = [litmus_record("replace", 1), litmus_record("clear", 2)]
        records[1]["observed_dentry"] = 201
        definitions = {
            "A": {"device": 7, "inode": 11},
            "B": {"device": 8, "inode": 12},
        }
        with self.assertRaisesRegex(ANALYZE.AnalysisError, "same old target"):
            ANALYZE.validate_retirement_litmus(
                records, "final-file", definitions
            )

    def test_rejects_litmus_wrong_post_clear_result(self):
        records = [litmus_record("replace", 1), litmus_record("clear", 2)]
        records[1]["fresh_result"] = 0
        definitions = {
            "A": {"device": 7, "inode": 11},
            "B": {"device": 8, "inode": 12},
        }
        with self.assertRaisesRegex(ANALYZE.AnalysisError, "clear postcondition"):
            ANALYZE.validate_retirement_litmus(
                records, "final-file", definitions
            )

    def test_accepts_rcu_engagement_outside_update_window(self):
        with tempfile.TemporaryDirectory() as directory:
            trace = Path(directory, "trace.txt")
            trace.write_text(
                "# entries-in-buffer/entries-written: 6/6   #P:4\n"
                "writer-1: namei_ext-update-begin-1\n"
                "writer-1: update_enter: (0)\n"
                "writer-1: update_return: result=5\n"
                "writer-1: namei_ext-update-end-1\n"
                "reader-2: resolve_return: rcu_walk=1 result=0\n"
                "reader-2: resolve_return: rcu_walk=1 result=-2\n"
            )
            observed = ANALYZE.parse_concurrent_rcu_trace(trace)
        self.assertEqual(observed["rcu_walk_hits"], 1)
        self.assertEqual(observed["rcu_resolve_failures"], 1)
        self.assertEqual(observed["rcu_absent_results"], 1)
        self.assertEqual(observed["rcu_under_update"], 0)

    def test_rejects_rcu_trace_without_absent_lookup(self):
        with tempfile.TemporaryDirectory() as directory:
            trace = Path(directory, "trace.txt")
            trace.write_text(
                "# entries-in-buffer/entries-written: 5/5   #P:4\n"
                "writer-1: namei_ext-update-begin-1\n"
                "reader-2: resolve_return: rcu_walk=1 result=0\n"
                "writer-1: update_enter: (0)\n"
                "writer-1: update_return: result=5\n"
                "writer-1: namei_ext-update-end-1\n"
            )
            with self.assertRaisesRegex(
                ANALYZE.AnalysisError,
                "no absent RCU target resolution",
            ):
                ANALYZE.parse_concurrent_rcu_trace(trace)

    def test_rejects_other_rcu_failure_as_absent_evidence(self):
        with tempfile.TemporaryDirectory() as directory:
            trace = Path(directory, "trace.txt")
            trace.write_text(
                "# entries-in-buffer/entries-written: 6/6   #P:4\n"
                "writer-1: namei_ext-update-begin-1\n"
                "reader-2: resolve_return: rcu_walk=1 result=0\n"
                "reader-2: resolve_return: rcu_walk=1 result=-116\n"
                "writer-1: update_enter: (0)\n"
                "writer-1: update_return: result=5\n"
                "writer-1: namei_ext-update-end-1\n"
            )
            with self.assertRaisesRegex(
                ANALYZE.AnalysisError,
                "no absent RCU target resolution",
            ):
                ANALYZE.parse_concurrent_rcu_trace(trace)

    def test_rejects_rcu_trace_without_successful_lookup(self):
        with tempfile.TemporaryDirectory() as directory:
            trace = Path(directory, "trace.txt")
            trace.write_text(
                "# entries-in-buffer/entries-written: 5/5   #P:4\n"
                "writer-1: namei_ext-update-begin-1\n"
                "writer-1: update_enter: (0)\n"
                "reader-2: resolve_return: rcu_walk=1 result=-2\n"
                "writer-1: update_return: result=5\n"
                "writer-1: namei_ext-update-end-1\n"
            )
            with self.assertRaisesRegex(
                ANALYZE.AnalysisError,
                "no successful RCU target resolution",
            ):
                ANALYZE.parse_concurrent_rcu_trace(trace)

    def test_rejects_lifecycle_aggregate_without_step_evidence(self):
        records = [
            {
                "event": "target-lifetime-lifecycle",
                "case": case,
                "cycle": 0,
                "result": 0,
                "pass": True,
            }
            for case in ("file-rename-unlink-clear", "directory-rename-clear")
        ]
        with self.assertRaisesRegex(ANALYZE.AnalysisError, "step cycles"):
            ANALYZE.validate_lifecycle(records, 1)

    def test_greedy_matches_exhaustive_small_histories(self):
        intervals = list(itertools.combinations(range(11), 2))
        for first_interval in intervals:
            for second_interval in intervals:
                for first_state in ("absent", "A"):
                    for second_state in ("absent", "A"):
                        history = [
                            operation(1, "SET", 2, 4, "A", writer_seq=1),
                            operation(
                                2, "CLEAR", 6, 8, "absent", writer_seq=2
                            ),
                            operation(
                                3,
                                "OPEN",
                                first_interval[0],
                                first_interval[1],
                                first_state,
                                result=-2 if first_state == "absent" else 0,
                            ),
                            operation(
                                4,
                                "OPEN",
                                second_interval[0],
                                second_interval[1],
                                second_state,
                                result=-2 if second_state == "absent" else 0,
                            ),
                        ]
                        expected = brute_linearizable(history)
                        try:
                            ANALYZE.check_linearizable(
                                [dict(item) for item in history]
                            )
                            observed = True
                        except ANALYZE.AnalysisError:
                            observed = False
                        self.assertEqual(expected, observed, history)


if __name__ == "__main__":
    unittest.main()
