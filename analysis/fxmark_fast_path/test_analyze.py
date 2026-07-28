#!/usr/bin/env python3

import copy
import json
import tempfile
import unittest
from pathlib import Path

import analyze


REPETITIONS = 2
DURATION = 30


def make_run():
    return {
        "schema": analyze.RUN_SCHEMA,
        "suite": analyze.SUITE,
        "layout": analyze.LAYOUT,
        "status": "running",
        "matrix": {
            "conditions": list(analyze.CONDITIONS),
            "types": list(analyze.TYPES),
            "workers": list(analyze.WORKERS),
            "repetitions": REPETITIONS,
            "duration_seconds": DURATION,
            "bpf_stats": 0,
            "external_inventory_gate": True,
        },
    }


def make_launches():
    entries = []
    sequence = 0
    for repetition in range(1, REPETITIONS + 1):
        conditions = ("stock", "unattached") if repetition % 2 == 1 else \
            ("unattached", "stock")
        for condition in conditions:
            sequence += 1
            entries.append({
                "schema": analyze.LAUNCH_SCHEMA,
                "order_index": sequence,
                "repetition": repetition,
                "condition": condition,
                "host_started_at": f"2026-07-28T00:00:{sequence:02d}Z",
                "host_completed_at": f"2026-07-28T00:01:{sequence:02d}Z",
            })
    return entries


def make_rows(ratios=None):
    ratios = ratios or {worker: [1.0] * REPETITIONS
                        for worker in analyze.WORKERS}
    rows = []
    for repetition in range(1, REPETITIONS + 1):
        for condition in analyze.CONDITIONS:
            for workers in analyze.WORKERS:
                stock_works = 1_000_000 * workers
                works = stock_works if condition == "stock" else \
                    stock_works * ratios[workers][repetition - 1]
                rows.append({
                    "event": analyze.OBSERVATION_EVENT,
                    "repetition": repetition,
                    "condition": condition,
                    "type": "MRPL",
                    "workers": workers,
                    "duration_seconds": DURATION,
                    "seconds": float(DURATION),
                    "works": works,
                    "works_per_second": works / DURATION,
                    "actual_files": workers,
                    "expected_files": workers,
                    "actual_directories": 1 + 4 * workers,
                    "expected_directories": 1 + 4 * workers,
                    "attached_program_id_before": 0,
                    "attached_program_id_after": 0,
                    "policy_run_time_ns_before": 0,
                    "policy_run_time_ns_after": 0,
                    "policy_run_count_before": 0,
                    "policy_run_count_after": 0,
                    "attachment_stable": False,
                    "leader_cgroup_verified": True,
                    "fuse_status": -1,
                    "fuse_setup_requests": 0,
                    "fuse_measured_requests": 0,
                    "fuse_f_type_before": 0,
                    "fuse_f_type_after": 0,
                    "fxmark_status": 0,
                    "pass": True,
                })
    return rows


def write_jsonl(path, rows):
    path.write_text(
        "".join(json.dumps(row) + "\n" for row in rows),
        encoding="utf-8")


class AnalysisTest(unittest.TestCase):
    def plan(self):
        return {
            "conditions": analyze.CONDITIONS,
            "types": analyze.TYPES,
            "workers": analyze.WORKERS,
            "repetitions": REPETITIONS,
            "duration_seconds": DURATION,
            "bpf_stats": 0,
            "external_inventory_gate": True,
        }

    def test_complete_data_emits_all_outputs(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            run_path = root / "run.json"
            observations = root / "observations.jsonl"
            launches = root / "launch-order.jsonl"
            output = root / "analysis"
            run_path.write_text(json.dumps(make_run()), encoding="utf-8")
            write_jsonl(observations, make_rows())
            write_jsonl(launches, make_launches())

            result = analyze.analyze_run(
                observations, launches, run_path, output, seed=20260728)

            self.assertEqual(result["schema"], analyze.SUMMARY_SCHEMA)
            self.assertEqual(result["verdict"], "supported")
            self.assertEqual(len(result["cells"]), 3)
            for name in (
                    "summary.json", "summary.csv", "report.md",
                    "fast-path.png", "fast-path.pdf"):
                self.assertGreater((output / name).stat().st_size, 0)

    def test_rejects_missing_and_failed_rows(self):
        rows = make_rows()
        with self.subTest("missing"):
            with self.assertRaisesRegex(ValueError, "expected 12"):
                analyze.validate_observations(rows[:-1], self.plan())
        with self.subTest("failed"):
            failed = copy.deepcopy(rows)
            failed[0]["pass"] = False
            with self.assertRaisesRegex(ValueError, "correctness oracle"):
                analyze.validate_observations(failed, self.plan())

    def test_rejects_bpf_and_fuse_activity(self):
        for field, value in (
                ("attached_program_id_before", 7),
                ("fuse_status", 0)):
            with self.subTest(field):
                rows = make_rows()
                rows[0][field] = value
                with self.assertRaises(ValueError):
                    analyze.validate_observations(rows, self.plan())

    def test_rejects_bad_launch_order(self):
        with self.subTest("wrong condition"):
            entries = make_launches()
            entries[0]["condition"] = "unattached"
            with self.assertRaisesRegex(ValueError, "unexpected launch"):
                analyze.validate_launch_order(entries, REPETITIONS)
        with self.subTest("empty timestamp"):
            entries = make_launches()
            entries[0]["host_completed_at"] = ""
            with self.assertRaisesRegex(ValueError, "empty host_completed_at"):
                analyze.validate_launch_order(entries, REPETITIONS)
        with self.subTest("non-sequential"):
            entries = make_launches()
            entries[1]["order_index"] = 1
            with self.assertRaisesRegex(ValueError, "non-sequential"):
                analyze.validate_launch_order(entries, REPETITIONS)

    def test_all_verdict_classes(self):
        supported = [
            {"verdict": "supported"} for _ in analyze.WORKERS]
        contradicted = copy.deepcopy(supported)
        contradicted[1]["verdict"] = "contradicted"
        inconclusive = copy.deepcopy(supported)
        inconclusive[2]["verdict"] = "inconclusive"
        self.assertEqual(analyze.classify(supported), "supported")
        self.assertEqual(analyze.classify(contradicted), "contradicted")
        self.assertEqual(analyze.classify(inconclusive), "inconclusive")
        self.assertEqual(
            analyze.classify_cell(0.98, 0.97, 1.01), "supported")
        self.assertEqual(
            analyze.classify_cell(0.96, 0.95, 0.979), "contradicted")
        self.assertEqual(
            analyze.classify_cell(0.98, 0.96, 1.01), "inconclusive")


if __name__ == "__main__":
    unittest.main()
