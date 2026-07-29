#!/usr/bin/env python3

import copy
import json
import random
import tempfile
import unittest
from pathlib import Path

import analyze


def config(repetitions=2, types=analyze.TYPES, workers=analyze.WORKERS):
    return analyze.make_config("formal", repetitions=repetitions, types=types,
                               workers=workers, duration_seconds=1)


def rows_for(plan=None):
    plan = plan or config()
    rows = []
    for repetition in range(1, plan["repetitions"] + 1):
        for condition in analyze.CONDITIONS:
            for test in plan["types"]:
                for workers in plan["workers"]:
                    files, directories = analyze.expected_tree(test, workers)
                    attached = condition in ("pass", "select")
                    returned_entries = analyze.expected_attribution(
                        test, workers)
                    directory_streams = analyze.expected_directory_streams(
                        test, workers)
                    getdents_calls = directory_streams + 2
                    retry_runs = getdents_calls - directory_streams
                    attribution = returned_entries + retry_runs \
                        if attached else 0
                    base_work_count = 120 if condition == "select" else 100
                    work_count = base_work_count * plan["duration_seconds"]
                    rows.append({
                        "event": analyze.EVENT,
                        "repetition": repetition,
                        "condition": condition,
                        "type": test,
                        "workers": workers,
                        "duration_seconds": plan["duration_seconds"],
                        "seconds": float(plan["duration_seconds"]),
                        "works": work_count,
                        "works_per_second": float(base_work_count),
                        "pass": True,
                        "fxmark_status": 0,
                        "leader_cgroup_verified": True,
                        "actual_files": files,
                        "expected_files": files,
                        "actual_directories": directories,
                        "expected_directories": directories,
                        "readdir_validation_required": True,
                        "logical_directory_entries":
                        returned_entries,
                        "expected_directory_entries":
                        returned_entries,
                        "logical_names_complete": True,
                        "selected_directory_identity": condition != "fuse",
                        "select_required_for_logical_path": condition == "select",
                        "attachment_stable": attached,
                        "attached_program_id_before": 7 if attached else 0,
                        "attached_program_id_after": 7 if attached else 0,
                        "policy_run_count_before": 0,
                        "policy_run_count_after":
                        attribution + (1 if attached else 0),
                        "validation_lookup_runs": 1 if attached else 0,
                        "validation_readdir_runs": attribution,
                        "validation_getdents_nonempty_calls": getdents_calls,
                        "validation_readdir_retry_runs": retry_runs,
                        "bpf_stats_post_timing_only": True,
                        "fuse_status": 0 if condition == "fuse" else -1,
                        "fuse_setup_requests": 1 if condition == "fuse" else 0,
                        "fuse_measured_requests":
                        3 if condition == "fuse" else 0,
                        "fuse_f_type_before": analyze.FUSE_SUPER_MAGIC
                        if condition == "fuse" else 0,
                        "fuse_f_type_after": analyze.FUSE_SUPER_MAGIC
                        if condition == "fuse" else 0,
                        "fuse_measured_opendir": 1 if condition == "fuse" else 0,
                        "fuse_measured_readdir": 1 if condition == "fuse" else 0,
                        "fuse_measured_releasedir": 1 if condition == "fuse" else 0,
                        "fuse_phase_measured_acks":
                        1 if condition == "fuse" else 0,
                        "fuse_phase_after_acks":
                        1 if condition == "fuse" else 0,
                        "fuse_phase_invalid_commands": 0,
                    })
    return rows


class ValidationTests(unittest.TestCase):
    def assert_rejects(self, field, value, condition="stock"):
        rows = rows_for()
        row = next(item for item in rows if item["condition"] == condition)
        row[field] = value
        with self.assertRaises(ValueError):
            analyze.validate(rows, config())

    def test_valid_matrix_and_no_mutation(self):
        rows = rows_for()
        original = copy.deepcopy(rows)
        indexed = analyze.validate(rows, config())
        self.assertEqual(len(indexed), 60)
        self.assertEqual(rows, original)

    def test_rejects_missing_cell(self):
        rows = rows_for()[:-1]
        with self.assertRaises(ValueError):
            analyze.validate(rows, config())

    def test_rejects_duplicate_cell(self):
        rows = rows_for()
        rows.append(copy.deepcopy(rows[0]))
        with self.assertRaises(ValueError):
            analyze.validate(rows, config())

    def test_rejects_pass_false(self):
        self.assert_rejects("pass", False)

    def test_rejects_wrong_tree(self):
        self.assert_rejects("actual_files", 1)

    def test_rejects_logical_cardinality(self):
        self.assert_rejects("logical_directory_entries", 1)

    def test_rejects_incomplete_names(self):
        self.assert_rejects("logical_names_complete", False)

    def test_rejects_getdents_retry_mismatch(self):
        self.assert_rejects("validation_readdir_retry_runs", 1)

    def test_rejects_select_identity_failure(self):
        self.assert_rejects("selected_directory_identity", False, "select")

    def test_rejects_pass_bpf_attribution_mismatch(self):
        self.assert_rejects("validation_readdir_runs", 1, "pass")

    def test_rejects_select_bpf_attribution_mismatch(self):
        self.assert_rejects("validation_lookup_runs", 0, "select")

    def test_rejects_zero_fuse_opendir(self):
        self.assert_rejects("fuse_measured_opendir", 0, "fuse")

    def test_rejects_zero_fuse_readdir(self):
        self.assert_rejects("fuse_measured_readdir", 0, "fuse")

    def test_rejects_zero_fuse_releasedir(self):
        self.assert_rejects("fuse_measured_releasedir", 0, "fuse")

    def test_rejects_missing_fuse_phase_ack(self):
        self.assert_rejects("fuse_phase_after_acks", 0, "fuse")

    def test_rejects_invalid_fuse_phase_command(self):
        self.assert_rejects("fuse_phase_invalid_commands", 1, "fuse")

    def test_rejects_boolean_worker(self):
        self.assert_rejects("workers", True)


class SummaryTests(unittest.TestCase):
    def test_mode_defaults_and_overrides(self):
        preflight = analyze.make_config("preflight")
        self.assertEqual(preflight["repetitions"], 1)
        self.assertEqual(preflight["types"], analyze.TYPES)
        self.assertEqual(preflight["workers"], (1, 4))
        formal = analyze.make_config("formal", repetitions=3,
                                     types=("MRDM",), workers=(2,))
        self.assertEqual(formal["repetitions"], 3)
        self.assertEqual(formal["types"], ("MRDM",))
        self.assertEqual(formal["workers"], (2,))

    def test_bootstrap_is_frozen_and_paired(self):
        plan = config(repetitions=3, types=("MRDL",), workers=(1,))
        indexed = analyze.validate(rows_for(plan), plan)
        first = analyze.summarize(indexed, plan, analyze.FROZEN_SEED)
        second = analyze.summarize(indexed, plan, analyze.FROZEN_SEED)
        self.assertEqual(first, second)
        self.assertEqual(len(first[0]["ratios"]["select_over_fuse"]["values"]), 3)

    def test_throughput_bootstrap_is_not_a_self_ratio(self):
        rng = random.Random(analyze.FROZEN_SEED)
        low, high = analyze.bootstrap_median_ci([10.0, 20.0, 40.0], rng)
        self.assertLess(low, high)
        self.assertGreater(high, 1.0)

    def test_supported_verdict(self):
        plan = config(repetitions=2, types=("MRDL",), workers=(1,))
        indexed = analyze.validate(rows_for(plan), plan)
        cells = analyze.summarize(indexed, plan, analyze.FROZEN_SEED)
        self.assertEqual(analyze.classify(cells)["verdict"], "supported")

    def test_contradicted_verdict(self):
        plan = config(repetitions=2, types=("MRDL",), workers=(1,))
        rows = rows_for(plan)
        for row in rows:
            if row["condition"] == "select":
                row["works"] = 80
                row["works_per_second"] = 80.0
        indexed = analyze.validate(rows, plan)
        cells = analyze.summarize(indexed, plan, analyze.FROZEN_SEED)
        self.assertEqual(analyze.classify(cells)["verdict"], "contradicted")

    def test_mixed_verdict(self):
        plan = config(repetitions=2, types=("MRDL",), workers=(1,))
        rows = rows_for(plan)
        for row in rows:
            if row["condition"] == "select":
                work_count = 90 if row["repetition"] == 1 else 130
                row["works"] = work_count
                row["works_per_second"] = float(work_count)
        indexed = analyze.validate(rows, plan)
        cells = analyze.summarize(indexed, plan, analyze.FROZEN_SEED)
        self.assertEqual(analyze.classify(cells)["verdict"], "mixed")

    def test_writes_all_outputs(self):
        plan = analyze.make_config("preflight")
        rows = rows_for(plan)
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            observations = root / "observations.jsonl"
            observations.write_text(
                "\n".join(json.dumps(row) for row in rows) + "\n",
                encoding="utf-8")
            run = root / "run.json"
            run.write_text(json.dumps({
                "status": "completed",
                "layout": "latin-square-boot-matrix",
                "matrix": {
                    "conditions": list(analyze.CONDITIONS),
                    "types": list(analyze.TYPES),
                    "workers": [1, 4],
                    "repetitions": 1,
                    "duration_seconds": 2,
                    "files_per_worker": analyze.FILES_PER_WORKER,
                    "bpf_stats": 0,
                    "order": "rotating-latin-square",
                    "kvm_cpus": 4,
                    "host_cpu_pin": "4-7",
                    "affinity": "exact-vcpu-index-mapping",
                    "external_inventory_gate": True,
                },
            }) + "\n", encoding="utf-8")
            output = root / "output"
            analyze.main([
                "--input", str(observations), "--output", str(output),
                "--run", str(run),
            ])
            self.assertEqual({path.name for path in root.iterdir()}, {
                "observations.jsonl", "run.json", "output",
            })
            self.assertEqual(
                {path.name for path in output.iterdir()},
                {"summary.json", "summary.csv", "report.md", "throughput.png",
                 "throughput.pdf"},
            )
            summary = json.loads((output / "summary.json").read_text(
                encoding="utf-8"))
            self.assertEqual(summary["config"]["types"], ["MRDL", "MRDM"])
            self.assertEqual(summary["verdict"]["verdict"], "supported")

    def test_run_manifest_rejects_non_frozen_matrix(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "run.json"
            path.write_text(json.dumps({
                "status": "completed",
                "layout": "latin-square-boot-matrix",
                "matrix": {
                    "conditions": list(analyze.CONDITIONS),
                    "types": list(analyze.TYPES),
                    "workers": [1, 4],
                    "repetitions": 2,
                    "duration_seconds": 2,
                    "files_per_worker": analyze.FILES_PER_WORKER,
                    "bpf_stats": 0,
                    "order": "rotating-latin-square",
                    "kvm_cpus": 4,
                    "host_cpu_pin": "4-7",
                    "affinity": "exact-vcpu-index-mapping",
                    "external_inventory_gate": True,
                },
            }) + "\n", encoding="utf-8")
            with self.assertRaises(ValueError):
                analyze.config_from_run(path)


if __name__ == "__main__":
    unittest.main()
