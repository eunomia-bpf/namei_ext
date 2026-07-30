#!/usr/bin/env python3

import copy
import json
import random
import tempfile
import unittest
from pathlib import Path

import analyze


def run_manifest(mode):
    config = analyze.make_config(mode)
    return {
        "status": "completed",
        "matrix": {
            "event": analyze.EVENT,
            "mode": mode,
            "conditions": list(analyze.CONDITIONS),
            "ranks": list(analyze.RANKS),
            "operations": list(analyze.OPERATIONS),
            "repetitions": config["repetitions"],
            "items_per_rank": config["items_per_rank"],
        },
    }


def rows_for(mode="preflight", rates=None):
    config = analyze.make_config(mode)
    rates = rates or {
        "stock": 900.0,
        "unattached": 1000.0,
        "pass": 950.0,
        "select": 2000.0,
        "fuse": 1000.0,
    }
    rows = []
    for repetition in range(1, config["repetitions"] + 1):
        scale = 1.0 + repetition / 100.0
        for condition in analyze.CONDITIONS:
            attached = condition in analyze.ATTACHED_CONDITIONS
            for ranks in analyze.RANKS:
                for operation in analyze.OPERATIONS:
                    rate = rates[condition] * scale * ranks
                    cache_drop = operation in ("stat", "remove")
                    rows.append({
                        "event": analyze.EVENT,
                        "schema": analyze.PHASE_SCHEMA,
                        "repetition": repetition,
                        "condition": condition,
                        "ranks": ranks,
                        "items_per_rank": config["items_per_rank"],
                        "operation": operation,
                        "phase_status": 0,
                        "ops_per_second": rate,
                        "summary_max": rate,
                        "summary_min": rate,
                        "summary_mean": rate,
                        "summary_stddev": 0.0,
                        "pass": True,
                        "warning_as_errors": True,
                        "warnings_or_errors_absent": True,
                        "tree_correct": True,
                        "cache_drop_value": 3 if cache_drop else 0,
                        "cache_drop_bytes_written": 2 if cache_drop else 0,
                        "cache_drop_errno": 0,
                        "leader_cgroup_verified": True,
                        "mpi_ranks_cgroup_verified": True,
                        "mpi_bindings_reported": True,
                        "attachment_stable": attached,
                        "attached_program_id_before": 7 if attached else 0,
                        "attached_program_id_after": 7 if attached else 0,
                        "untimed_policy_runs": 2 if attached else 0,
                        "selected_identity": condition == "select",
                        "fuse_f_type": analyze.FUSE_SUPER_MAGIC
                        if condition == "fuse" else 0,
                        "fuse_daemon_live": condition == "fuse",
                        "fuse_dev_fd_verified": condition == "fuse",
                        "ext4_f_type": analyze.EXT4_SUPER_MAGIC,
                        "cleanup_complete": True,
                        "actual_files": ranks * config["items_per_rank"]
                        if operation != "remove" else 0,
                        "expected_files": ranks * config["items_per_rank"]
                        if operation != "remove" else 0,
                        "actual_directories": ranks + 2
                        if operation != "remove" else 1,
                        "expected_directories": ranks + 2
                        if operation != "remove" else 1,
                        "actual_other": 0,
                    })
    return rows


class ValidationTests(unittest.TestCase):
    def assert_rejects(self, field, value, condition="stock",
                       operation="create"):
        rows = rows_for()
        row = next(
            item for item in rows
            if item["condition"] == condition
            and item["operation"] == operation)
        row[field] = value
        with self.assertRaises(ValueError):
            analyze.validate(rows, analyze.make_config("preflight"))

    def test_valid_complete_matrix_and_no_mutation(self):
        rows = rows_for()
        original = copy.deepcopy(rows)
        indexed = analyze.validate(
            rows, analyze.make_config("preflight"))
        self.assertEqual(len(indexed), 30)
        self.assertEqual(rows, original)

    def test_rejects_missing_and_duplicate_rows(self):
        rows = rows_for()
        with self.assertRaises(ValueError):
            analyze.validate(
                rows[:-1], analyze.make_config("preflight"))
        rows.append(copy.deepcopy(rows[0]))
        with self.assertRaises(ValueError):
            analyze.validate(
                rows, analyze.make_config("preflight"))

    def test_common_correctness_gates(self):
        cases = (
            ("pass", False),
            ("phase_status", 1),
            ("ops_per_second", 0.0),
            ("warning_as_errors", False),
            ("warnings_or_errors_absent", False),
            ("tree_correct", False),
            ("mpi_bindings_reported", False),
            ("ext4_f_type", 0),
            ("cleanup_complete", False),
        )
        for field, value in cases:
            with self.subTest(field=field):
                self.assert_rejects(field, value)

    def test_rejects_wrong_phase_schema(self):
        self.assert_rejects("schema", "namei_ext.mdtest_cold_metadata.phase.v0")

    def test_summary_columns_must_describe_the_recorded_rate(self):
        for field, value in (
                ("summary_max", 999.0),
                ("summary_min", 999.0),
                ("summary_mean", 999.0),
                ("summary_stddev", 0.1)):
            with self.subTest(field=field):
                self.assert_rejects(field, value)

    def test_attached_condition_gates(self):
        cases = (
            ("leader_cgroup_verified", False),
            ("mpi_ranks_cgroup_verified", False),
            ("attachment_stable", False),
            ("attached_program_id_before", 0),
            ("attached_program_id_after", 8),
            ("untimed_policy_runs", 0),
        )
        for condition in analyze.ATTACHED_CONDITIONS:
            for field, value in cases:
                with self.subTest(condition=condition, field=field):
                    self.assert_rejects(field, value, condition)

    def test_nonattached_conditions_reject_attachment_evidence(self):
        for condition in ("stock", "unattached", "fuse"):
            with self.subTest(condition=condition):
                self.assert_rejects(
                    "attached_program_id_before", 7, condition)

    def test_every_condition_requires_process_cgroup_evidence(self):
        for condition in analyze.CONDITIONS:
            with self.subTest(condition=condition):
                self.assert_rejects(
                    "leader_cgroup_verified", False, condition)
                self.assert_rejects(
                    "mpi_ranks_cgroup_verified", False, condition)

    def test_tree_cardinality_is_recomputed(self):
        for operation in analyze.OPERATIONS:
            with self.subTest(operation=operation):
                self.assert_rejects(
                    "actual_files", 999, operation=operation)
                self.assert_rejects(
                    "expected_directories", 999, operation=operation)
                self.assert_rejects(
                    "actual_other", 1, operation=operation)

    def test_selected_identity_is_select_only(self):
        self.assert_rejects("selected_identity", False, "select")
        self.assert_rejects("selected_identity", True, "pass")

    def test_fuse_engagement_is_fuse_only(self):
        for field, value in (
                ("fuse_f_type", 0),
                ("fuse_daemon_live", False),
                ("fuse_dev_fd_verified", False)):
            with self.subTest(field=field):
                self.assert_rejects(field, value, "fuse")
        self.assert_rejects(
            "fuse_f_type", analyze.FUSE_SUPER_MAGIC, "stock")
        self.assert_rejects("fuse_daemon_live", True, "unattached")
        self.assert_rejects("fuse_dev_fd_verified", True, "pass")

    def test_cache_drop_is_required_only_for_stat_and_remove(self):
        for operation in ("stat", "remove"):
            for field, value in (
                    ("cache_drop_value", 0),
                    ("cache_drop_bytes_written", 0),
                    ("cache_drop_errno", 5)):
                with self.subTest(operation=operation, field=field):
                    self.assert_rejects(field, value, operation=operation)
        for field, value in (
                ("cache_drop_value", 3),
                ("cache_drop_bytes_written", 2),
                ("cache_drop_errno", 5)):
            with self.subTest(operation="create", field=field):
                self.assert_rejects(field, value, operation="create")

    def test_rejects_missing_required_field_and_boolean_integer(self):
        rows = rows_for()
        del rows[0]["tree_correct"]
        with self.assertRaises(ValueError):
            analyze.validate(
                rows, analyze.make_config("preflight"))
        self.assert_rejects("ranks", True)


class AnalysisTests(unittest.TestCase):
    def test_paired_bootstrap_is_deterministic_and_preserves_pairs(self):
        numerators = [2.0, 200.0, 20.0]
        denominators = [1.0, 100.0, 10.0]
        first = analyze.paired_bootstrap_median_ci(
            numerators, denominators,
            random.Random(analyze.FROZEN_SEED), samples=500)
        second = analyze.paired_bootstrap_median_ci(
            numerators, denominators,
            random.Random(analyze.FROZEN_SEED), samples=500)
        self.assertEqual(first, second)
        self.assertEqual(first, (2.0, 2.0))

    @staticmethod
    def verdict_cells(low, high):
        return [
            {
                "select_over_fuse": {
                    "ci_low": low,
                    "ci_high": high,
                },
            }
            for _ in range(len(analyze.OPERATIONS) * len(analyze.RANKS))
        ]

    def test_all_three_formal_verdicts(self):
        positive = self.verdict_cells(1.01, 1.20)
        self.assertEqual(
            analyze.classify(positive, "formal")["verdict"], "positive")

        contradicted = self.verdict_cells(1.01, 1.20)
        contradicted[2]["select_over_fuse"] = {
            "ci_low": 0.70, "ci_high": 0.99}
        self.assertEqual(
            analyze.classify(contradicted, "formal")["verdict"],
            "contradicted")

        mixed = self.verdict_cells(1.01, 1.20)
        mixed[4]["select_over_fuse"] = {
            "ci_low": 0.90, "ci_high": 1.00}
        self.assertEqual(
            analyze.classify(mixed, "formal")["verdict"], "mixed")

    def test_preflight_has_diagnostic_ratios_without_inference(self):
        config = analyze.make_config("preflight")
        indexed = analyze.validate(rows_for(), config)
        cells = analyze.summarize(indexed, config)
        verdict = analyze.classify(cells, config["mode"])
        self.assertEqual(verdict["verdict"], "diagnostic-only")
        self.assertFalse(verdict["inferential"])
        for cell in cells:
            ratio = cell["select_over_fuse"]
            self.assertEqual(ratio["median"], 2.0)
            self.assertFalse(ratio["inferential"])
            self.assertIsNone(ratio["ci_low"])
            self.assertIsNone(ratio["ci_high"])

    def test_formal_summary_uses_ten_paired_blocks(self):
        config = analyze.make_config("formal")
        indexed = analyze.validate(rows_for("formal"), config)
        cells = analyze.summarize(indexed, config)
        self.assertEqual(len(cells), 6)
        for cell in cells:
            ratio = cell["select_over_fuse"]
            self.assertEqual(len(ratio["values"]), 10)
            self.assertTrue(ratio["inferential"])
            self.assertEqual(ratio["ci_low"], 2.0)
            self.assertEqual(ratio["ci_high"], 2.0)
        self.assertEqual(
            analyze.classify(cells, "formal")["verdict"], "positive")


class ManifestAndOutputTests(unittest.TestCase):
    def write_manifest(self, root, manifest):
        path = root / "run.json"
        path.write_text(
            json.dumps(manifest) + "\n", encoding="utf-8")
        return path

    def test_run_manifest_accepts_only_frozen_matrices(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for mode in ("preflight", "formal"):
                for status in ("running", "completed"):
                    manifest = run_manifest(mode)
                    manifest["status"] = status
                    path = self.write_manifest(root, manifest)
                    self.assertEqual(
                        analyze.config_from_run(path)["mode"], mode)

            bad_manifests = []
            for field, value in (
                    ("conditions", list(reversed(analyze.CONDITIONS))),
                    ("ranks", [1]),
                    ("operations", ["create", "stat"]),
                    ("repetitions", 2),
                    ("items_per_rank", 8192),
                    ("event", "wrong-event")):
                manifest = run_manifest("preflight")
                manifest["matrix"][field] = value
                bad_manifests.append(manifest)
            failed = run_manifest("preflight")
            failed["status"] = "failed"
            bad_manifests.append(failed)

            for index, manifest in enumerate(bad_manifests):
                with self.subTest(index=index):
                    path = self.write_manifest(root, manifest)
                    with self.assertRaises(ValueError):
                        analyze.config_from_run(path)

    def test_writes_all_outputs(self):
        rows = rows_for()
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            observations = root / "observations.jsonl"
            observations.write_text(
                "\n".join(json.dumps(row) for row in rows) + "\n",
                encoding="utf-8")
            run = self.write_manifest(root, run_manifest("preflight"))
            output = root / "analysis"
            analyze.main([
                "--input", str(observations),
                "--run", str(run),
                "--output", str(output),
            ])

            expected = {
                "summary.json",
                "summary.csv",
                "report.md",
                "normalized-throughput.png",
                "normalized-throughput.pdf",
            }
            self.assertEqual(
                {path.name for path in output.iterdir()}, expected)
            for name in expected:
                self.assertGreater((output / name).stat().st_size, 0)

            summary = json.loads(
                (output / "summary.json").read_text(encoding="utf-8"))
            self.assertEqual(summary["config"]["mode"], "preflight")
            self.assertEqual(
                summary["verdict"]["verdict"], "diagnostic-only")
            self.assertEqual(summary["bootstrap_samples"], 0)
            report = (output / "report.md").read_text(encoding="utf-8")
            self.assertIn("diagnostics only", report)
            self.assertNotIn("95% CI", report)


if __name__ == "__main__":
    unittest.main()
