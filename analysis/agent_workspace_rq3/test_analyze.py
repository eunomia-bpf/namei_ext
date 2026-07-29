import importlib.util
import json
import tempfile
import unittest
from pathlib import Path


MODULE_PATH = Path(__file__).with_name("analyze.py")
SPEC = importlib.util.spec_from_file_location("rq3_analyze", MODULE_PATH)
ANALYZE = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(ANALYZE)


class AgentWorkspaceRq3AnalysisTest(unittest.TestCase):
    @staticmethod
    def semantic_records():
        records = []
        for index, (_, namei_case, wrapfs_case) in enumerate(
            ANALYZE.PAIRWISE_CASES
        ):
            oracle_id = f"oracle-{index:02d}"
            for condition, case in (
                ("namei_ext", namei_case),
                ("wrapfs", wrapfs_case),
            ):
                records.append({
                    "event": "rq3-semantic-oracle",
                    "condition": condition,
                    "oracle_id": oracle_id,
                    "case": case,
                    "operation": "operation",
                    "expected": f"expected-{index}",
                    "pass": True,
                    "errno": 0,
                })
        manifest = {
            field: field not in {
                "visible_deleted", "visible_cached_negative"
            }
            for field in ANALYZE.LOWER_TREE_MANIFEST_FIELDS
        }
        for condition in ("namei_ext", "wrapfs"):
            records.append({
                "event": "rq3-lower-tree-manifest",
                "result_level": "test",
                "condition": condition,
                "pass": True,
                **manifest,
            })
        return records

    def test_count_kprobes_requires_every_declared_method(self):
        with tempfile.TemporaryDirectory() as directory:
            trace = Path(directory) / "trace"
            trace.write_text(
                "".join(
                    f"task-1 [000] .... 1.0: {event}: "
                    f"({symbol}+0x4/0x20 [wrapfs])\n"
                    for event, symbol in ANALYZE.KPROBE_SYMBOLS.items()
                ),
                encoding="utf-8",
            )
            counts = ANALYZE.count_kprobes(trace)
            self.assertEqual(set(counts), set(ANALYZE.KPROBE_EVENTS))
            self.assertTrue(all(value == 1 for value in counts.values()))

    def test_count_kprobes_rejects_unattributed_event_name(self):
        with tempfile.TemporaryDirectory() as directory:
            trace = Path(directory) / "trace"
            trace.write_text(
                "".join(
                    f"task-1 [000] .... 1.0: {event}: "
                    "(some_other_symbol+0x4/0x20)\n"
                    for event in ANALYZE.KPROBE_EVENTS
                ),
                encoding="utf-8",
            )
            with self.assertRaises(ValueError):
                ANALYZE.count_kprobes(trace)

    def test_read_jsonl_rejects_malformed_observation(self):
        with tempfile.TemporaryDirectory() as directory:
            observations = Path(directory) / "observations.jsonl"
            observations.write_text('{"pass":true}\nnot-json\n', encoding="utf-8")
            with self.assertRaises(ValueError):
                ANALYZE.read_jsonl(observations)

    def test_one_record_rejects_duplicate_case(self):
        records = [
            {"case": "same", "pass": True},
            {"case": "same", "pass": True},
        ]
        with self.assertRaises(ValueError):
            ANALYZE.one_record(records, case="same")

    def test_formal_summary_must_be_three_boots(self):
        with tempfile.TemporaryDirectory() as directory:
            formal = Path(directory)
            (formal / "formal-summary.json").write_text(
                json.dumps({"pass": True, "boots": 2}),
                encoding="utf-8",
            )
            with self.assertRaises(ValueError):
                ANALYZE.summarize(formal)

    def test_comparable_object_ignores_only_observation_metadata(self):
        before = {
            "event": "rq3-fault-lower-object",
            "fault_case": "select_create",
            "phase": "before",
            "pass": True,
            "role": "select_create_path",
            "exists": False,
        }
        after = dict(before, phase="after")
        self.assertEqual(
            ANALYZE.comparable_object(before),
            ANALYZE.comparable_object(after),
        )
        after["exists"] = True
        self.assertNotEqual(
            ANALYZE.comparable_object(before),
            ANALYZE.comparable_object(after),
        )

    def test_pairwise_oracles_require_identical_contracts_and_manifest(self):
        records = self.semantic_records()
        pairs = ANALYZE.validate_pairwise_oracles(records)
        self.assertEqual(len(pairs), len(ANALYZE.PAIRWISE_CASES))

        records[1]["expected"] = "different"
        with self.assertRaises(ValueError):
            ANALYZE.validate_pairwise_oracles(records)

    def test_pairwise_oracles_reject_manifest_difference(self):
        records = self.semantic_records()
        wrapfs_manifest = next(
            record for record in records
            if record.get("event") == "rq3-lower-tree-manifest"
            and record.get("condition") == "wrapfs"
        )
        wrapfs_manifest["upper_main_preserved"] = False
        with self.assertRaises(ValueError):
            ANALYZE.validate_pairwise_oracles(records)


if __name__ == "__main__":
    unittest.main()
