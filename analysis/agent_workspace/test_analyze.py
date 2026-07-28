#!/usr/bin/env python3

import unittest

import analyze


class AgentWorkspaceAnalysisTests(unittest.TestCase):
    def test_paired_boot_medians_drive_ratio(self):
        indexed = {}
        for repetition in range(1, 4):
            for metric in analyze.METRICS:
                indexed[(repetition, "namei_ext", metric)] = [
                    repetition * 10,
                    repetition * 20,
                    repetition * 30,
                ]
                indexed[(repetition, "fuse", metric)] = [
                    repetition * 20,
                    repetition * 40,
                    repetition * 60,
                ]
        summaries = analyze.summarize(indexed, 3, 7)
        for row in summaries:
            self.assertEqual(row["paired_ratios"], [2.0, 2.0, 2.0])
            self.assertEqual(row["fuse_over_namei_ext_median"], 2.0)
            self.assertEqual(row["ci_low"], 2.0)
            self.assertEqual(row["ci_high"], 2.0)

    def test_interval_containing_one_is_inconclusive(self):
        summaries = [{
            "metric": "lifecycle",
            "ci_low": 0.9,
            "ci_high": 1.1,
        }]
        verdict = analyze.classify(summaries)
        self.assertEqual(verdict["tested_hypothesis"], "inconclusive")
        self.assertFalse(verdict["equivalence_claimed"])

    def test_interval_wholly_below_one_is_contradicted(self):
        summaries = [{
            "metric": "lifecycle",
            "ci_low": 0.6,
            "ci_high": 0.9,
        }]
        verdict = analyze.classify(summaries)
        self.assertEqual(verdict["tested_hypothesis"], "contradicted")


if __name__ == "__main__":
    unittest.main()
