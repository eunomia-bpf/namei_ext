import tempfile
import unittest
from pathlib import Path

from analyze import analyze, write_outputs


def fixture(repetitions=3, samples=5, fuse_ratio=2.0):
    run = {
        "matrix": {
            "conditions": ["namei_ext", "fuse"],
            "repetitions": repetitions,
            "measured_samples_per_boot": samples,
        }
    }
    launches = []
    observations = []
    order_index = 0
    for repetition in range(1, repetitions + 1):
        order = ("namei_ext", "fuse") if repetition % 2 else ("fuse", "namei_ext")
        for condition in order:
            order_index += 1
            launches.append(
                {
                    "order_index": order_index,
                    "repetition": repetition,
                    "condition": condition,
                }
            )
        for condition in ("namei_ext", "fuse"):
            multiplier = fuse_ratio if condition == "fuse" else 1.0
            for iteration in range(1, samples + 1):
                observations.append(
                    {
                        "event": "spindle-staging-rq2-sample",
                        "phase": "measured",
                        "condition": condition,
                        "repetition": repetition,
                        "iteration": iteration,
                        "duration_ns": int((1000 + repetition + iteration) * multiplier),
                        "pass": True,
                    }
                )
        observations.append(
            {
                "event": "spindle-staging-rq2-fuse-resource",
                "condition": "fuse",
                "repetition": repetition,
                "cpu_runtime_ns": 10000 + repetition,
                "voluntary_context_switches": 2,
                "involuntary_context_switches": 1,
                "pass": True,
            }
        )
    return observations, run, launches


class AnalyzeTest(unittest.TestCase):
    def test_supported_ratio_uses_boot_pairs(self):
        observations, run, launches = fixture()
        summary = analyze(observations, run, launches, seed=7)
        self.assertEqual(summary["primary"]["verdict"], "supported")
        self.assertAlmostEqual(
            summary["primary"]["geometric_mean_ratio"], 2.0, places=3
        )
        self.assertEqual(len(summary["pair_rows"]), 3)

    def test_missing_boot_samples_are_rejected(self):
        observations, run, launches = fixture()
        observations.pop(0)
        with self.assertRaisesRegex(ValueError, "has 4 samples"):
            analyze(observations, run, launches, seed=7)

    def test_failed_oracle_is_rejected_before_timing(self):
        observations, run, launches = fixture()
        observations[0]["pass"] = False
        with self.assertRaisesRegex(ValueError, "oracle failed"):
            analyze(observations, run, launches, seed=7)

    def test_duplicate_iteration_is_rejected(self):
        observations, run, launches = fixture()
        observations[1]["iteration"] = observations[0]["iteration"]
        with self.assertRaisesRegex(ValueError, "duplicate iteration"):
            analyze(observations, run, launches, seed=7)

    def test_writes_required_artifacts(self):
        observations, run, launches = fixture()
        summary = analyze(observations, run, launches, seed=7)
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "analysis"
            write_outputs(summary, output)
            self.assertTrue((output / "summary.json").is_file())
            self.assertTrue((output / "summary.csv").is_file())
            self.assertIn("paired-bootstrap", (output / "report.md").read_text())


if __name__ == "__main__":
    unittest.main()
