import json
import tempfile
import unittest
from pathlib import Path

import analyze


def lifecycle(boot, width, pair, mechanism, order, elapsed):
    return {
        "event": analyze.EVENT,
        "mechanism": mechanism,
        "boot": boot,
        "width": width,
        "pair": pair,
        "order": order,
        "active_total_ns": elapsed,
        "wall_span_ns": elapsed,
        "cleanup_pass": True,
        "pass": True,
    }


class AnalyzeTest(unittest.TestCase):
    def test_formal_boot_clustering_supports_primary_ratio(self):
        rows = []
        for boot in range(1, 21):
            for pair in range(1, 6):
                rows.append(lifecycle(boot, 256, pair, "atomicwriter", 1,
                                      2_000_000 + boot))
                rows.append(lifecycle(boot, 256, pair, "namei_ext", 2,
                                      1_000_000 + boot))
        run = {"matrix": {"boots": 20, "pairs_per_scale_per_boot": 5,
                           "scales": [256]}}
        summary, per_boot, pairs = analyze.summarize(rows, run)
        self.assertEqual(summary["lifecycle_rows"], 200)
        self.assertEqual(len(per_boot), 20)
        self.assertEqual(len(pairs), 100)
        self.assertLess(summary["scales"][0]["ratio_ci95_upper"], 1.0)
        self.assertEqual(summary["verdict"],
                         "supports-lower-cost-at-primary-scale")

    def test_preflight_has_no_confidence_claim(self):
        rows = [
            lifecycle(1, 16, 1, "atomicwriter", 1, 100),
            lifecycle(1, 16, 1, "namei_ext", 2, 90),
            lifecycle(1, 16, 2, "namei_ext", 1, 95),
            lifecycle(1, 16, 2, "atomicwriter", 2, 105),
        ]
        run = {"matrix": {"boots": 1, "pairs_per_scale_per_boot": 2,
                           "scales": [16]}}
        summary, _, _ = analyze.summarize(rows, run)
        self.assertIsNone(summary["scales"][0]["ratio_ci95_upper"])
        self.assertEqual(summary["verdict"], "preflight-complete")

    def test_primary_uses_begin_to_end_wall_span(self):
        atomic = lifecycle(1, 16, 1, "atomicwriter", 1, 100)
        namei = lifecycle(1, 16, 1, "namei_ext", 2, 50)
        atomic["wall_span_ns"] = 200
        namei["wall_span_ns"] = 300
        run = {"matrix": {"boots": 1, "pairs_per_scale_per_boot": 1,
                           "scales": [16]}}
        summary, _, _ = analyze.summarize([atomic, namei], run)
        self.assertEqual(summary["primary_metric"], "wall_span_ns")
        self.assertAlmostEqual(summary["scales"][0]["ratio"], 1.5)

    def test_rejects_unpaired_rows(self):
        rows = [lifecycle(1, 16, 1, "atomicwriter", 1, 100)] * 4
        run = {"matrix": {"boots": 1, "pairs_per_scale_per_boot": 2,
                           "scales": [16]}}
        with self.assertRaises(ValueError):
            analyze.summarize(rows, run)

    def test_writes_analysis_artifacts(self):
        rows = [
            lifecycle(1, 16, 1, "atomicwriter", 1, 100),
            lifecycle(1, 16, 1, "namei_ext", 2, 90),
            lifecycle(1, 16, 2, "namei_ext", 1, 95),
            lifecycle(1, 16, 2, "atomicwriter", 2, 105),
        ]
        run = {"matrix": {"boots": 1, "pairs_per_scale_per_boot": 2,
                           "scales": [16]}}
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "run.json").write_text(json.dumps(run), encoding="utf-8")
            with (root / "observations.jsonl").open("w", encoding="utf-8") as output:
                for row in rows:
                    output.write(json.dumps(row) + "\n")
            analyze.analyze(root)
            self.assertTrue((root / "analysis" / "summary.json").is_file())
            self.assertTrue((root / "analysis" / "report.md").is_file())


if __name__ == "__main__":
    unittest.main()
