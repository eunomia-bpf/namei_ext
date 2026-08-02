#!/usr/bin/env python3

import copy
import json
import tempfile
import unittest
from pathlib import Path

import analyze


class CheckpointRestoreAnalysisTests(unittest.TestCase):
    def write_jsonl(self, path, rows):
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(
            "".join(json.dumps(row) + "\n" for row in rows),
            encoding="utf-8",
        )

    def run_record(self, formal=False):
        return {
            "schema": "namei_ext.run.v2",
            "run_id": "checkpoint-test",
            "protocol_schema": "namei_ext.checkpoint_restore.protocol.v3",
            "suite": "checkpoint-restore",
            "source_system": "dmtcp-pathtranslator",
            "result_level": (
                "kvm_checkpoint_restore_rq1" if formal else
                "kvm_checkpoint_restore_preflight"
            ),
            "observations": "observations.jsonl",
            "policy": "checkpoint_restore_migration.bpf.c",
            "runner": "namei_ext_checkpoint_restore+dmtcp",
            "source": {"commit": "a" * 40, "dirty": False},
            "kernel": {"commit": "b" * 40, "dirty": False},
            "kernel_commit": "b" * 40,
            "layout": (
                "three-modified-kernel-boots" if formal else
                "single-modified-kernel-boot"
            ),
            "attempt": 6,
            "status": "completed",
            "matrix": {
                "conditions": list(analyze.CONDITIONS),
                "repetitions": 3 if formal else 1,
                "baseline": (
                    "DMTCP PathTranslator with a disclosed "
                    "restart-environment scan-bound fix"
                ),
                "control": "withdrawn",
                "pathtranslator_activation": (
                    "DMTCP_PATHVIRT_PLUGIN=1; "
                    "DMTCP_PATH_MAPPING generation A to B"
                ),
                "dmtcp_tmpdir": "guest-local /tmp",
                "timeout_seconds": 120,
                "kvm_timeout": "600s",
                "all_conditions_must_pass": True,
            },
        }

    def controller_rows(self, condition):
        cases = set(analyze.COMMON_CASES)
        if condition != "pathvirt":
            cases |= analyze.POLICY_CASES
        rows = [
            {
                "event": "checkpoint-restore-case",
                "condition": condition,
                "case": case,
                "pass": True,
            }
            for case in sorted(cases)
        ]
        if condition != "pathvirt":
            rows.append({
                "event": "checkpoint-restore-policy",
                "condition": condition,
                "program_id": 7,
                "cgroup_id": 9,
                "target_id": 1,
                "pass": True,
            })
            rows.extend([
                {
                    "event": "checkpoint-restore-policy-counter",
                    "condition": condition,
                    "phase": "pre-checkpoint",
                    "counter": "select",
                    "value": 2,
                    "pass": True,
                },
                {
                    "event": "checkpoint-restore-policy-counter",
                    "condition": condition,
                    "phase": "post-restart",
                    "counter": "select",
                    "value": 4 if condition == "namei_ext" else 2,
                    "pass": True,
                },
            ])
        rows.extend([
            {
                "event": "checkpoint-restore-lifecycle",
                "condition": condition,
                "checkpoint_ns": 10,
                "update_ns": 2,
                "restart_ns": 20,
                "total_ns": 40,
                "pass": True,
            },
            {
                "event": "checkpoint-restore-summary",
                "condition": condition,
                "failures": 0,
                "pass": True,
            },
        ])
        return rows

    def application_rows(self, condition):
        logical = f"/result/{condition}/fixture/logical/workspace/state.txt"
        cgroup = (
            f"0::/{condition} " if condition != "pathvirt" else "0::/ "
        )
        pre = {
            "event": "checkpoint-restore-application",
            "stage": "pre-checkpoint",
            "generation": "a",
            "logical_path": logical,
            "restarts": 0,
            "uid": 1000,
            "gid": 1000,
            "logical_dev": 1,
            "logical_ino": 10,
            "physical_dev": 1,
            "physical_ino": 10,
            "saw_stale": True,
            "saw_new": False,
            "cgroup": cgroup,
            "errno": 0,
            "restart_env_status": -1,
            "restart_mapping": "",
            "checkpoint_mapping": "generation-a/workspace",
            "expected_failure": False,
            "pass": True,
        }
        post = copy.deepcopy(pre)
        post.update({
            "stage": "post-restart",
            "generation": "b",
            "restarts": 1,
            "logical_ino": 20,
            "physical_ino": 20,
            "saw_stale": False,
            "saw_new": True,
        })
        if condition == "pathvirt":
            post["restart_env_status"] = 0
            post["restart_mapping"] = "generation-b/workspace"
        if condition == "withdrawn":
            post.update({
                "logical_dev": 0,
                "logical_ino": 0,
                "physical_dev": 0,
                "physical_ino": 0,
                "saw_new": False,
                "errno": 2,
                "expected_failure": True,
            })
        return [pre, post]

    def lower_rows(self, phase):
        fixtures = (
            ("a", "state.txt", "generation-a"),
            ("a", "shared.txt", "shared-common"),
            ("a", "stale.txt", "stale-only"),
            ("b", "state.txt", "generation-b"),
            ("b", "shared.txt", "shared-common"),
            ("b", "new.txt", "new-only"),
        )
        rows = []
        for index, (generation, name, content) in enumerate(fixtures, 1):
            rows.append({
                "event": "checkpoint-restore-lower",
                "phase": phase,
                "path": (
                    f"/result/fixture/generation-{generation}/"
                    f"workspace/{name}"
                ),
                "dev": 1,
                "ino": index,
                "mode": 33152,
                "size": len(content) + 1,
                "mtime_sec": 1,
                "mtime_nsec": 2,
                "content": content,
                "final_newline": True,
            })
        return rows

    def add_boot(self, root, boot_name):
        boot = root / "boots" / boot_name
        boot.mkdir(parents=True)
        (boot / "boot.json").write_text(
            json.dumps({
                "schema": "namei_ext.checkpoint_restore.boot.v3",
                "status": "completed",
                "conditions": list(analyze.CONDITIONS),
                "pathtranslator_activation": "DMTCP_PATHVIRT_PLUGIN=1",
            }),
            encoding="utf-8",
        )
        (boot / "runtime-identity.json").write_text(
            json.dumps({"uid": 1000, "gid": 1000}), encoding="utf-8"
        )
        (boot / "runtime-identity-probe.txt").write_text(
            "1000\n1000\n", encoding="utf-8"
        )
        for name in (
            "bpf-programs-before.json",
            "bpf-programs-after.json",
            "bpf-cgroup-before.json",
            "bpf-cgroup-after.json",
        ):
            (boot / name).write_text("[]\n", encoding="utf-8")
        controller = []
        for condition in analyze.CONDITIONS:
            result = boot / "conditions" / condition
            rows = self.controller_rows(condition)
            controller.extend(rows)
            self.write_jsonl(result / "observations.jsonl", rows)
            self.write_jsonl(
                result / "application-observations.jsonl",
                self.application_rows(condition),
            )
            self.write_jsonl(
                result / "lower-before.jsonl", self.lower_rows("before")
            )
            self.write_jsonl(
                result / "lower-after.jsonl", self.lower_rows("after")
            )
            checkpoint = result / "checkpoint/image.dmtcp"
            checkpoint.parent.mkdir()
            checkpoint.write_bytes(b"checkpoint")
            (result / "checkpoint-images.txt").write_text(
                "checkpoint/image.dmtcp\n", encoding="utf-8"
            )
            (result / "bpf-programs-after.json").write_text(
                "[]\n", encoding="utf-8"
            )
            (result / "bpf-cgroup-after.json").write_text(
                "[]\n", encoding="utf-8"
            )
        self.write_jsonl(boot / "observations.jsonl", controller)
        return controller

    def fixture(self, root, formal=False):
        root = Path(root)
        root.mkdir(parents=True, exist_ok=True)
        (root / "run.json").write_text(
            json.dumps(self.run_record(formal)), encoding="utf-8"
        )
        boot_names = (
            ["block-01", "block-02", "block-03"]
            if formal else ["preflight"]
        )
        all_rows = []
        for boot_name in boot_names:
            all_rows.extend(self.add_boot(root, boot_name))
        (root / "expected-boots.txt").write_text(
            "".join(f"{name}\n" for name in boot_names), encoding="utf-8"
        )
        self.write_jsonl(root / "observations.jsonl", all_rows)
        return root

    def test_complete_preflight_passes(self):
        with tempfile.TemporaryDirectory() as directory:
            summary = analyze.analyze_result(self.fixture(directory))
        self.assertTrue(summary["correctness"]["all_boots_passed"])
        self.assertEqual(
            summary["verdict"]["evidence_role"], "dependency_preflight"
        )

    def test_complete_formal_three_boot_result_passes(self):
        with tempfile.TemporaryDirectory() as directory:
            summary = analyze.analyze_result(
                self.fixture(directory, formal=True)
            )
        self.assertEqual(summary["correctness"]["boot_count"], 3)
        self.assertEqual(summary["verdict"]["tested_hypothesis"], "supported")
        self.assertEqual(summary["verdict"]["evidence_role"], "formal_rq1_evidence")

    def test_dirty_run_is_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            root = self.fixture(directory)
            run = json.loads((root / "run.json").read_text(encoding="utf-8"))
            run["source"]["dirty"] = True
            (root / "run.json").write_text(json.dumps(run), encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "not clean"):
                analyze.analyze_result(root)

    def test_wrong_pathtranslator_activation_is_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            root = self.fixture(directory)
            run = json.loads((root / "run.json").read_text(encoding="utf-8"))
            run["matrix"]["pathtranslator_activation"] = "--pathvirt"
            (root / "run.json").write_text(json.dumps(run), encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "PathTranslator activation"):
                analyze.analyze_result(root)

    def test_pathvirt_without_restart_mapping_is_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            root = self.fixture(directory)
            path = (
                root / "boots/preflight/conditions/pathvirt/"
                "application-observations.jsonl"
            )
            rows = analyze.load_jsonl(path)
            rows[1]["restart_mapping"] = ""
            self.write_jsonl(path, rows)
            with self.assertRaisesRegex(ValueError, "attribution"):
                analyze.analyze_result(root)

    def test_namei_without_select_increase_is_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            root = self.fixture(directory)
            path = root / "boots/preflight/observations.jsonl"
            rows = analyze.load_jsonl(path)
            post = next(
                row for row in rows
                if row.get("event") == "checkpoint-restore-policy-counter"
                and row.get("condition") == "namei_ext"
                and row.get("phase") == "post-restart"
            )
            post["value"] = 2
            self.write_jsonl(path, rows)
            with self.assertRaisesRegex(ValueError, "did not increase"):
                analyze.analyze_result(root)

    def test_withdrawn_success_is_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            root = self.fixture(directory)
            path = (
                root / "boots/preflight/conditions/withdrawn/"
                "application-observations.jsonl"
            )
            rows = analyze.load_jsonl(path)
            rows[1]["expected_failure"] = False
            self.write_jsonl(path, rows)
            with self.assertRaisesRegex(ValueError, "fail closed"):
                analyze.analyze_result(root)

    def test_runtime_identity_probe_mismatch_is_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            root = self.fixture(directory)
            path = root / "boots/preflight/runtime-identity-probe.txt"
            path.write_text("0\n0\n", encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "identity probe"):
                analyze.analyze_result(root)

    def test_changed_lower_contents_are_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            root = self.fixture(directory)
            path = (
                root / "boots/preflight/conditions/namei_ext/"
                "lower-after.jsonl"
            )
            rows = analyze.load_jsonl(path)
            rows[0]["content"] = "unexpected"
            self.write_jsonl(path, rows)
            with self.assertRaisesRegex(ValueError, "lower object changed"):
                analyze.analyze_result(root)

    def test_absolute_checkpoint_path_is_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            root = self.fixture(directory)
            path = (
                root / "boots/preflight/conditions/pathvirt/"
                "checkpoint-images.txt"
            )
            path.write_text("/tmp/image.dmtcp\n", encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "non-relocatable"):
                analyze.analyze_result(root)

    def test_nonempty_bpf_inventory_is_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            root = self.fixture(directory)
            path = root / "boots/preflight/bpf-programs-after.json"
            path.write_text('[{"id":1}]\n', encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "nonempty BPF"):
                analyze.analyze_result(root)

    def test_residual_condition_bpf_program_is_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            root = self.fixture(directory)
            path = (
                root / "boots/preflight/conditions/pathvirt/"
                "bpf-programs-after.json"
            )
            path.write_text('[{"id":7}]\n', encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "after pathvirt"):
                analyze.analyze_result(root)


if __name__ == "__main__":
    unittest.main()
