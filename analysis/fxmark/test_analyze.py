#!/usr/bin/env python3

import copy
import json
import tempfile
import unittest
from pathlib import Path

import analyze


def make_plan():
    return {
        "conditions": analyze.CONDITIONS,
        "types": analyze.TYPES,
        "workers": analyze.WORKERS,
        "repetitions": 1,
        "duration_seconds": 30,
        "bpf_stats": 0,
    }


def make_rows():
    rows = []
    for condition in analyze.CONDITIONS:
        for benchmark in analyze.TYPES:
            for workers in analyze.WORKERS:
                attached = condition in ("pass", "select")
                expected_files, expected_directories = \
                    analyze.expected_tree(benchmark, workers)
                rows.append({
                    "event": "fxmark-cell",
                    "repetition": 1,
                    "condition": condition,
                    "type": benchmark,
                    "workers": workers,
                    "duration_seconds": 30,
                    "seconds": 30.0,
                    "works": 300,
                    "works_per_second": 10.0,
                    "pass": True,
                    "fxmark_status": 0,
                    "fuse_status": 0 if condition == "fuse" else -1,
                    "actual_files": expected_files,
                    "expected_files": expected_files,
                    "actual_directories": expected_directories,
                    "expected_directories": expected_directories,
                    "leader_cgroup_verified": True,
                    "attachment_stable": attached,
                    "attached_program_id_before": 7 if attached else 0,
                    "attached_program_id_after": 7 if attached else 0,
                    "select_required_for_logical_path":
                        condition == "select",
                    "fuse_setup_requests": 1 if condition == "fuse" else 0,
                    "fuse_measured_requests": 0,
                    "fuse_f_type_before":
                        analyze.FUSE_SUPER_MAGIC if condition == "fuse" else 0,
                    "fuse_f_type_after":
                        analyze.FUSE_SUPER_MAGIC if condition == "fuse" else 0,
                })
    return rows


class ValidateTest(unittest.TestCase):
    def test_loads_declared_plan(self):
        run = {
            "schema": "namei_ext.run.v2",
            "suite": "fxmark-rq2",
            "layout": "boot-matrix",
            "status": "completed",
            "matrix": {
                "conditions": list(analyze.CONDITIONS),
                "types": list(analyze.TYPES),
                "workers": list(analyze.WORKERS),
                "repetitions": 1,
                "duration_seconds": 30,
                "bpf_stats": 0,
            },
        }
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "run.json"
            path.write_text(json.dumps(run), encoding="utf-8")
            self.assertEqual(analyze.load_plan(path), make_plan())

    def test_rejects_incomplete_run_plan(self):
        run = {
            "schema": "namei_ext.run.v2",
            "suite": "fxmark-rq2",
            "layout": "boot-matrix",
            "status": "running",
            "matrix": {},
        }
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "run.json"
            path.write_text(json.dumps(run), encoding="utf-8")
            with self.assertRaises(ValueError):
                analyze.load_plan(path)

    def test_rejects_bpf_stats_run_plan(self):
        run = {
            "schema": "namei_ext.run.v2",
            "suite": "fxmark-rq2",
            "layout": "boot-matrix",
            "status": "completed",
            "matrix": {
                "conditions": list(analyze.CONDITIONS),
                "types": list(analyze.TYPES),
                "workers": list(analyze.WORKERS),
                "repetitions": 1,
                "duration_seconds": 30,
                "bpf_stats": 1,
            },
        }
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "run.json"
            path.write_text(json.dumps(run), encoding="utf-8")
            with self.assertRaises(ValueError):
                analyze.load_plan(path)

    def test_valid_matrix(self):
        indexed = analyze.validate(make_rows(), make_plan())
        self.assertEqual(len(indexed), 45)

    def assert_rejects(self, field, value, condition="stock"):
        rows = make_rows()
        row = next(item for item in rows if item["condition"] == condition)
        row[field] = value
        with self.assertRaises(ValueError):
            analyze.validate(rows, make_plan())

    def test_rejects_harness_failure(self):
        self.assert_rejects("pass", False)

    def test_rejects_process_failure(self):
        self.assert_rejects("fxmark_status", 1)

    def test_rejects_short_measurement(self):
        self.assert_rejects("seconds", 20.0)

    def test_rejects_long_measurement(self):
        self.assert_rejects("seconds", 40.0)

    def test_rejects_wrong_declared_duration(self):
        self.assert_rejects("duration_seconds", 1)

    def test_rejects_cardinality_mismatch(self):
        self.assert_rejects("actual_files", 2)

    def test_rejects_self_consistent_false_cardinality(self):
        rows = make_rows()
        row = next(item for item in rows if item["condition"] == "stock")
        row["actual_files"] = 0
        row["expected_files"] = 0
        row["actual_directories"] = 0
        row["expected_directories"] = 0
        with self.assertRaises(ValueError):
            analyze.validate(rows, make_plan())

    def test_rejects_rate_mismatch(self):
        self.assert_rejects("works_per_second", 11.0)

    def test_rejects_unexpected_attachment(self):
        self.assert_rejects("attached_program_id_before", 7)

    def test_rejects_unstable_attachment(self):
        self.assert_rejects("attachment_stable", False, "pass")

    def test_rejects_unverified_select(self):
        self.assert_rejects(
            "select_required_for_logical_path", False, "select")

    def test_rejects_fuse_failure(self):
        self.assert_rejects("fuse_status", 1, "fuse")

    def test_rejects_unverified_fuse_setup(self):
        self.assert_rejects("fuse_setup_requests", 0, "fuse")

    def test_rejects_unverified_fuse_mount(self):
        self.assert_rejects("fuse_f_type_before", 0, "fuse")

    def test_input_is_not_mutated(self):
        rows = make_rows()
        original = copy.deepcopy(rows)
        analyze.validate(rows, make_plan())
        self.assertEqual(rows, original)


if __name__ == "__main__":
    unittest.main()
