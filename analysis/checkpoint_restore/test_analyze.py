#!/usr/bin/env python3

import copy
import hashlib
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

    def run_record(self):
        return {
            "schema": "namei_ext.run.v2",
            "run_id": "checkpoint-test",
            "protocol_schema": "namei_ext.checkpoint_restore.protocol.v1",
            "suite": "checkpoint-restore",
            "source_system": "dmtcp-pathtranslator",
            "result_level": "kvm_checkpoint_restore_preflight",
            "observations": "observations.jsonl",
            "policy": "checkpoint_restore_migration.bpf.c",
            "runner": "namei_ext_checkpoint_restore+dmtcp",
            "source": {"commit": "a" * 40, "dirty": False},
            "kernel": {"commit": "b" * 40, "dirty": False},
            "kernel_commit": "b" * 40,
            "layout": "single-modified-kernel-boot",
            "status": "completed",
            "matrix": {
                "conditions": list(analyze.CONDITIONS),
                "baseline": (
                    "patched DMTCP PathTranslator with a disclosed "
                    "one-line restart-environment scan-bound fix"
                ),
                "control": "withdrawn",
                "timeout_seconds": 120,
                "upstream_timeout_seconds": 120,
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
        rows = []
        for generation, name in (
            ("a", "state.txt"),
            ("a", "shared.txt"),
            ("a", "stale.txt"),
            ("b", "state.txt"),
            ("b", "shared.txt"),
            ("b", "new.txt"),
        ):
            value = f"{generation}/{name}"
            rows.append({
                "event": "checkpoint-restore-lower",
                "phase": phase,
                "path": (
                    f"/result/fixture/generation-{generation}/"
                    f"workspace/{name}"
                ),
                "dev": 1,
                "ino": int(hashlib.sha256(value.encode()).hexdigest()[:8], 16),
                "mode": 33152,
                "size": len(value),
                "mtime_sec": 1,
                "mtime_nsec": 2,
                "sha256": hashlib.sha256(value.encode()).hexdigest(),
            })
        return rows

    def fixture(self, root):
        root = Path(root)
        run = self.run_record()
        (root / "run.json").write_text(
            json.dumps(run), encoding="utf-8"
        )
        boot = root / "boots/preflight"
        boot.mkdir(parents=True)
        (boot / "boot.json").write_text(
            json.dumps({
                "schema": "namei_ext.checkpoint_restore.boot.v1",
                "status": "completed",
                "conditions": list(analyze.CONDITIONS),
            }),
            encoding="utf-8",
        )
        (boot / "runtime-identity.json").write_text(
            json.dumps({"uid": 1000, "gid": 1000}), encoding="utf-8"
        )
        for name in (
            "bpf-programs-before.json",
            "bpf-programs-after.json",
            "bpf-cgroup-before.json",
            "bpf-cgroup-after.json",
        ):
            (boot / name).write_text("[]\n", encoding="utf-8")
        for name in (
            "fuse-mounts-before.txt",
            "fuse-mounts-after.txt",
            "fuse-open-fds-before.txt",
            "fuse-open-fds-after.txt",
        ):
            (boot / name).write_bytes(b"")
        (boot / "upstream-autotest.stdout.log").write_text(
            "test groups: pass=1 fail=0 skipped=0 total=1\n",
            encoding="utf-8",
        )
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
                result / "lower-before.jsonl",
                self.lower_rows("before"),
            )
            self.write_jsonl(
                result / "lower-after.jsonl",
                self.lower_rows("after"),
            )
            checkpoint = result / "checkpoint/image.dmtcp"
            checkpoint.parent.mkdir()
            checkpoint.write_bytes(b"checkpoint")
            (result / "checkpoint-images.txt").write_text(
                "checkpoint/image.dmtcp\n", encoding="utf-8"
            )
            if condition == "pathvirt":
                (result / "bpf-programs-after.json").write_text(
                    "[]\n", encoding="utf-8"
                )
                (result / "bpf-cgroup-after.json").write_text(
                    "[]\n", encoding="utf-8"
                )
        self.write_jsonl(root / "observations.jsonl", controller)
        return root

    def test_complete_preflight_passes(self):
        with tempfile.TemporaryDirectory() as directory:
            summary = analyze.analyze_result(self.fixture(directory))
        self.assertTrue(summary["correctness"]["all_conditions_passed"])
        self.assertEqual(
            summary["verdict"]["evidence_role"], "dependency_preflight"
        )

    def test_dirty_run_is_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            root = self.fixture(directory)
            run = json.loads((root / "run.json").read_text(encoding="utf-8"))
            run["source"]["dirty"] = True
            (root / "run.json").write_text(
                json.dumps(run), encoding="utf-8"
            )
            with self.assertRaisesRegex(ValueError, "not clean"):
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
            path = root / "observations.jsonl"
            rows = analyze.load_jsonl(path)
            post = next(
                row for row in rows
                if row.get("event") ==
                "checkpoint-restore-policy-counter"
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

    def test_withdrawn_without_restart_cgroup_is_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            root = self.fixture(directory)
            path = (
                root / "boots/preflight/conditions/withdrawn/"
                "application-observations.jsonl"
            )
            rows = analyze.load_jsonl(path)
            rows[1]["cgroup"] = ""
            self.write_jsonl(path, rows)
            with self.assertRaisesRegex(ValueError, "cgroup attribution"):
                analyze.analyze_result(root)

    def test_application_runtime_identity_mismatch_is_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            root = self.fixture(directory)
            path = (
                root / "boots/preflight/conditions/namei_ext/"
                "application-observations.jsonl"
            )
            rows = analyze.load_jsonl(path)
            rows[1]["uid"] = 0
            self.write_jsonl(path, rows)
            with self.assertRaisesRegex(ValueError, "runtime identity"):
                analyze.analyze_result(root)

    def test_changed_lower_object_is_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            root = self.fixture(directory)
            path = (
                root / "boots/preflight/conditions/namei_ext/"
                "lower-after.jsonl"
            )
            rows = analyze.load_jsonl(path)
            rows[0]["size"] += 1
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


if __name__ == "__main__":
    unittest.main()
