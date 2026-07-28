#!/usr/bin/env python3

import copy
import unittest

import analyze


class ServiceConfigRotationAnalysisTests(unittest.TestCase):
    def complete_rows(self, repetitions=2):
        rows = []
        for repetition in range(1, repetitions + 1):
            master = 1000 + repetition
            workers = {
                "current": 2000 + repetition,
                "canary": 3000 + repetition,
                "invalid": 3000 + repetition,
                "rollback": 4000 + repetition,
            }
            before = {
                "current": 0,
                "canary": workers["current"],
                "invalid": workers["canary"],
                "rollback": workers["canary"],
            }
            for index, state in enumerate(analyze.STATES, 1):
                digest = f"{repetition * 10 + index:064x}"
                rows.append({
                    "event": "service-config-rotation-state",
                    "result_level": "kvm_service_config_rotation",
                    "repetition": repetition,
                    "state": state,
                    "target_id": analyze.EXPECTED[state]["target_id"],
                    "logical_sha256": digest,
                    "physical_sha256": digest,
                    "http_body": analyze.EXPECTED[state]["http_body"],
                    "master_pid": master,
                    "worker_before": before[state],
                    "worker_after": workers[state],
                    "latency_ns": 1000 * index,
                    "poll_attempts": index,
                    "reload_error_observed":
                        analyze.EXPECTED[state]["reload_error_observed"],
                    "pass": True,
                })
            for case in analyze.REQUIRED_CASES:
                rows.append({
                    "event": "service-config-rotation-case",
                    "result_level": "kvm_service_config_rotation",
                    "repetition": repetition,
                    "case": case,
                    "pass": True,
                })
            for counter in analyze.REQUIRED_COUNTERS:
                rows.append({
                    "event": "service-config-rotation-policy-counter",
                    "result_level": "kvm_service_config_rotation",
                    "repetition": repetition,
                    "counter": counter,
                    "value": 10,
                    "pass": True,
                })
            rows.append({
                "event": "service-config-rotation-summary",
                "result_level": "kvm_service_config_rotation",
                "repetition": repetition,
                "source_system": "kubernetes-atomic-writer+nginx",
                "states": 4,
                "master_pid": master,
                "failures": 0,
                "pass": True,
            })
        return rows

    def test_complete_matrix_passes(self):
        correctness, latency, _, _ = analyze.validate(
            self.complete_rows(), 2)
        self.assertTrue(correctness["all_boots_passed"])
        self.assertEqual(correctness["states_completed"], 8)
        self.assertEqual(latency["rollback"]["median_ns"], 4000)

    def test_preflight_is_not_hypothesis_evidence(self):
        verdict = analyze.classify(1)
        self.assertEqual(verdict["tested_hypothesis"], "not_tested")
        self.assertEqual(verdict["evidence_role"], "dependency_preflight")

    def test_ten_boot_run_is_formal_evidence(self):
        verdict = analyze.classify(10)
        self.assertEqual(verdict["tested_hypothesis"], "supported")
        self.assertEqual(verdict["evidence_role"], "formal")

    def test_wrong_logical_hash_is_rejected(self):
        rows = self.complete_rows()
        rows[0]["logical_sha256"] = "f" * 64
        with self.assertRaises(ValueError):
            analyze.validate(rows, 2)

    def test_wrong_result_level_is_rejected(self):
        rows = self.complete_rows()
        rows[0]["result_level"] = "host_probe"
        with self.assertRaises(ValueError):
            analyze.validate(rows, 2)

    def test_invalid_reload_worker_change_is_rejected(self):
        rows = self.complete_rows()
        invalid = next(
            row for row in rows
            if row.get("event") == "service-config-rotation-state" and
            row.get("repetition") == 1 and row.get("state") == "invalid")
        invalid["worker_after"] += 1
        with self.assertRaises(ValueError):
            analyze.validate(rows, 2)

    def test_missing_required_case_is_rejected(self):
        rows = self.complete_rows()
        rows.remove(next(
            row for row in rows
            if row.get("event") == "service-config-rotation-case" and
            row.get("repetition") == 1 and
            row.get("case") == "lower_objects_unchanged"))
        with self.assertRaises(ValueError):
            analyze.validate(rows, 2)

    def test_failed_observation_is_rejected(self):
        rows = self.complete_rows()
        failed = copy.deepcopy(rows[0])
        failed["pass"] = False
        rows.append(failed)
        with self.assertRaises(ValueError):
            analyze.validate(rows, 2)

    def test_extra_successful_case_is_rejected(self):
        rows = self.complete_rows()
        extra = copy.deepcopy(next(
            row for row in rows
            if row.get("event") == "service-config-rotation-case"))
        extra["repetition"] = 3
        rows.append(extra)
        with self.assertRaises(ValueError):
            analyze.validate(rows, 2)


if __name__ == "__main__":
    unittest.main()
