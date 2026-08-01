import importlib.util
import json
import tempfile
import unittest
from pathlib import Path


MODULE_PATH = Path(__file__).with_name("analyze.py")
SPEC = importlib.util.spec_from_file_location("afs_rq2_analyze", MODULE_PATH)
assert SPEC and SPEC.loader
ANALYZE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(ANALYZE)


def transaction(mechanism: str, stream: str, sample: int, total: int) -> dict:
    return {
        "event": "application-file-sharing-rq2-sample",
        "mechanism": mechanism,
        "stream": stream,
        "phase": "measured",
        "sample": sample,
        "total_ns": total,
        "document_stat_ns": total // 5,
        "payload_stat_ns": total // 5,
        "open_read_close_ns": total // 5,
        "readdir_ns": total - 3 * (total // 5),
        "pass": True,
    }


def thread(mechanism: str, role: str, phase: str, tid: int, value: int) -> dict:
    return {
        "event": "application-file-sharing-rq2-thread",
        "mechanism": mechanism,
        "role": role,
        "phase": phase,
        "pid": tid,
        "tid": tid,
        "runtime_ns": value,
        "runqueue_wait_ns": value,
        "timeslices": value,
        "voluntary_context_switches": value,
        "involuntary_context_switches": value,
    }


class AnalysisTest(unittest.TestCase):
    def write_boot(
        self, root: Path, pair: int, order: int, mechanism: str, total: int
    ) -> None:
        boot = root / "boots" / (
            f"pair-{pair:02d}-order-{order:02d}-{mechanism}"
        )
        boot.mkdir(parents=True)
        rows = []
        for sample in range(3):
            rows.append(transaction(mechanism, "policy-view", sample, total + sample))
            rows.append(transaction(mechanism, "direct-ext4", sample, 100 + sample))
        rows.extend(
            [
                {
                    "event": "application-file-sharing-rq2-summary",
                    "mechanism": mechanism,
                    "document_id_bytes": 22,
                    "payload_bytes": 27,
                    "warmup_transactions": 2,
                    "measured_transactions": 3,
                    "direct_transactions": 3,
                    "pass": True,
                },
                {
                    "event": "application-file-sharing-rq2-control",
                    "mechanism": mechanism,
                    "operation": "grant",
                    "latency_ns": 10,
                    "pass": True,
                },
                {
                    "event": "application-file-sharing-rq2-control",
                    "mechanism": mechanism,
                    "operation": "revoke",
                    "latency_ns": 11,
                    "pass": True,
                },
                thread(mechanism, "client", "before", 10, 100),
                thread(mechanism, "client", "after", 10, 120),
            ]
        )
        if mechanism == "xdg-document-portal":
            rows.extend(
                [
                    thread(mechanism, "portal-daemon", "before", 20, 100),
                    thread(mechanism, "portal-daemon", "after", 20, 150),
                    *[
                        {
                            "event": "application-file-sharing-rq2-fuse-counter",
                            "mechanism": mechanism,
                            "phase": phase,
                            "opcode": opcode,
                            "value": value,
                        }
                        for phase, value in (("before", 5), ("after", 9))
                        for opcode in (14, 27)
                    ],
                ]
            )
        else:
            for counter in ("select", "visible_readdir"):
                rows.extend(
                    [
                        {
                            "event": "application-file-sharing-rq2-bpf-counter",
                            "mechanism": mechanism,
                            "phase": "before",
                            "counter": counter,
                            "value": 5,
                        },
                        {
                            "event": "application-file-sharing-rq2-bpf-counter",
                            "mechanism": mechanism,
                            "phase": "after",
                            "counter": counter,
                            "value": 9,
                        },
                    ]
                )
        with (boot / "observations.jsonl").open("w", encoding="utf-8") as output:
            for row in rows:
                output.write(json.dumps(row) + "\n")

    def test_pair_is_statistical_unit(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            (root / "run.json").write_text(
                json.dumps({"matrix": {"pairs": 2, "warmup": 2, "samples": 3}}),
                encoding="utf-8",
            )
            self.write_boot(root, 1, 1, "xdg-document-portal", 200)
            self.write_boot(root, 1, 2, "namei_ext", 100)
            self.write_boot(root, 2, 1, "namei_ext", 100)
            self.write_boot(root, 2, 2, "xdg-document-portal", 200)
            summary = ANALYZE.analyze_run(root, seed=20260801, bootstrap=100)
            self.assertEqual(summary["pairs"], 2)
            self.assertAlmostEqual(
                summary["primary"]["portal_over_namei_ext_geomean"],
                201.0 / 101.0,
            )
            self.assertAlmostEqual(
                summary["direct_total_ratio"][
                    "portal_boot_over_namei_ext_boot_geomean"
                ],
                1.0,
            )
            self.assertEqual(
                summary["arm_order_sensitivity"]["portal_first"]["pairs"], 1
            )
            self.assertEqual(
                summary["arm_order_sensitivity"]["namei_ext_first"]["pairs"], 1
            )
            ANALYZE.write_outputs(root, summary)
            for name in (
                "summary.json",
                "pairs.csv",
                "decomposition.csv",
                "resources.csv",
                "counters.csv",
                "controls.csv",
                "latency-decomposition.pdf",
                "latency-decomposition.png",
                "report.md",
            ):
                output = root / "analysis" / name
                self.assertTrue(output.is_file(), name)
                self.assertGreater(output.stat().st_size, 0, name)

    def test_duplicate_sample_identity_fails(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            (root / "run.json").write_text(
                json.dumps({"matrix": {"pairs": 1, "warmup": 2, "samples": 3}}),
                encoding="utf-8",
            )
            self.write_boot(root, 1, 1, "xdg-document-portal", 200)
            self.write_boot(root, 1, 2, "namei_ext", 100)
            observations = (
                root
                / "boots"
                / "pair-01-order-02-namei_ext"
                / "observations.jsonl"
            )
            rows = [json.loads(line) for line in observations.read_text().splitlines()]
            for row in rows:
                if (
                    row.get("event") == "application-file-sharing-rq2-sample"
                    and row.get("stream") == "policy-view"
                    and row.get("sample") == 2
                ):
                    row["sample"] = 1
                    break
            observations.write_text(
                "".join(json.dumps(row) + "\n" for row in rows), encoding="utf-8"
            )
            with self.assertRaisesRegex(ValueError, "sample identity"):
                ANALYZE.analyze_run(root, seed=1, bootstrap=10)

    def test_missing_mechanism_fails(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            (root / "run.json").write_text(
                json.dumps({"matrix": {"pairs": 1, "warmup": 2, "samples": 3}}),
                encoding="utf-8",
            )
            self.write_boot(root, 1, 1, "namei_ext", 100)
            with self.assertRaises(ValueError):
                ANALYZE.analyze_run(root, seed=1, bootstrap=10)


if __name__ == "__main__":
    unittest.main()
