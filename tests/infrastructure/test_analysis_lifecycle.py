#!/usr/bin/env python3

import hashlib
import json
import os
import re
import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]


class AnalysisLifecycleTest(unittest.TestCase):
    def run_make(self, cwd: Path, target: str, *variables: str, env=None):
        return subprocess.run(
            [
                "make",
                "--no-print-directory",
                "-C",
                str(cwd),
                target,
                *variables,
            ],
            check=False,
            env=env,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )

    def target_block(self, path: Path, target: str) -> str:
        text = path.read_text(encoding="utf-8")
        match = re.search(
            rf"(?ms)^{re.escape(target)}:.*?(?=^[A-Za-z0-9_.%/+()-]+:|\Z)",
            text,
        )
        self.assertIsNotNone(match, f"missing Make target {target}")
        return match.group(0)

    def write_completed_run(self, root: Path) -> bytes:
        run = {
            "schema": "namei_ext.run.v2",
            "run_id": root.name,
            "status": "completed",
            "completed_at": "2026-07-28T00:00:00Z",
            "observations": "observations.jsonl",
            "source": {"commit": "a" * 40, "dirty": False},
            "kernel": {"commit": "b" * 40, "dirty": False},
            "kernel_commit": "b" * 40,
        }
        encoded = (json.dumps(run, sort_keys=True) + "\n").encode()
        (root / "run.json").write_bytes(encoded)
        (root / "observations.jsonl").write_text("{}\n", encoding="utf-8")

        evidence = root / "evidence.txt"
        evidence.write_text("fixture\n", encoding="utf-8")
        checksum = hashlib.sha256(evidence.read_bytes()).hexdigest()
        manifest = f"{checksum}  {evidence}\n"
        (root / "inputs.sha256").write_text(manifest, encoding="utf-8")
        (root / "artifacts.sha256").write_text(manifest, encoding="utf-8")
        return encoded

    def test_failed_analysis_does_not_rewrite_completed_run(self):
        cases = (
            (
                "agent-workspace-rq2-report",
                "AGENT_WORKSPACE_RQ2_RESULT_DIR",
                "AGENT_WORKSPACE_RQ2_ANALYSIS",
            ),
            (
                "fxmark-fast-path-analyze",
                "FXMARK_FAST_PATH_ACTIVE_DIR",
                "FXMARK_FAST_PATH_ANALYSIS",
            ),
            (
                "fxmark-rq2-report",
                "FXMARK_RESULT_DIR",
                "FXMARK_ANALYSIS",
            ),
            (
                "service-config-rotation-analyze",
                "SERVICE_CONFIG_ROTATION_ACTIVE_DIR",
                "SERVICE_CONFIG_ROTATION_ANALYSIS",
            ),
            (
                "checkpoint-restore-analyze",
                "CHECKPOINT_RESTORE_ACTIVE_DIR",
                "CHECKPOINT_RESTORE_ANALYSIS",
            ),
        )
        with tempfile.TemporaryDirectory(prefix="namei-ext-analysis-lifecycle-") as temp:
            temp_root = Path(temp)
            analyzer = temp_root / "fail_analysis.py"
            analyzer.write_text(
                "import os\n"
                "import sys\n"
                "from pathlib import Path\n"
                "output = Path(sys.argv[sys.argv.index('--output') + 1])\n"
                "output.mkdir(parents=True)\n"
                "(output / 'partial').write_text('partial\\n', encoding='utf-8')\n"
                "Path(os.environ['NAMEI_EXT_TEST_ANALYSIS_MARKER']).write_text(\n"
                "    os.environ['NAMEI_EXT_TEST_ANALYSIS_TARGET'], encoding='utf-8')\n"
                "raise SystemExit(7)\n",
                encoding="utf-8",
            )

            for target, result_variable, analysis_variable in cases:
                with self.subTest(target=target):
                    result = temp_root / target
                    result.mkdir()
                    original = self.write_completed_run(result)
                    analysis = result / "analysis"
                    interrupted = result / "analysis.old"
                    interrupted.mkdir()
                    (interrupted / "previous").write_text(
                        "complete\n", encoding="utf-8"
                    )
                    stale = result / "analysis.tmp"
                    stale.mkdir()
                    (stale / "stale").write_text("stale\n", encoding="utf-8")
                    marker = temp_root / f"{target}.marker"
                    environment = os.environ.copy()
                    environment["NAMEI_EXT_TEST_ANALYSIS_MARKER"] = str(marker)
                    environment["NAMEI_EXT_TEST_ANALYSIS_TARGET"] = target
                    completed = self.run_make(
                        ROOT,
                        target,
                        f"{result_variable}={result}",
                        f"{analysis_variable}={analyzer}",
                        env=environment,
                    )
                    self.assertNotEqual(completed.returncode, 0)
                    self.assertEqual(marker.read_text(encoding="utf-8"), target)
                    self.assertEqual((result / "run.json").read_bytes(), original)
                    self.assertEqual(
                        (analysis / "previous").read_text(encoding="utf-8"),
                        "complete\n",
                    )
                    self.assertEqual(
                        (result / "analysis.tmp/partial").read_text(
                            encoding="utf-8"
                        ),
                        "partial\n",
                    )
                    self.assertFalse(interrupted.exists())

    def test_analysis_publish_replaces_or_restores(self):
        with tempfile.TemporaryDirectory(
            prefix="namei-ext-analysis-publish-"
        ) as temp:
            analysis = Path(temp) / "analysis"
            analysis.mkdir()
            (analysis / "previous").write_text("complete\n", encoding="utf-8")
            staged = Path(f"{analysis}.tmp")
            staged.mkdir()
            (staged / "current").write_text("complete\n", encoding="utf-8")

            variables = (f"ROOT_DIR={ROOT}", f"ANALYSIS_PATH={analysis}")
            published = self.run_make(
                ROOT / "tests/infrastructure",
                "analysis-publish-only",
                *variables,
            )
            self.assertEqual(published.returncode, 0, published.stderr)
            self.assertFalse((analysis / "previous").exists())
            self.assertEqual(
                (analysis / "current").read_text(encoding="utf-8"),
                "complete\n",
            )
            self.assertFalse(Path(f"{analysis}.old").exists())

            failed = self.run_make(
                ROOT / "tests/infrastructure",
                "analysis-publish-only",
                *variables,
            )
            self.assertNotEqual(failed.returncode, 0)
            self.assertEqual(
                (analysis / "current").read_text(encoding="utf-8"),
                "complete\n",
            )
            self.assertFalse(Path(f"{analysis}.old").exists())

    def test_collection_completes_before_analysis(self):
        cases = (
            (
                ROOT / "mk/experiments/agent_workspace_rq2.mk",
                "kvm-agent-workspace-rq2",
                "agent-workspace-rq2-finalize",
                "agent-workspace-rq2-mark-complete",
                "agent-workspace-rq2-report",
            ),
            (
                ROOT / "mk/experiments/fxmark_fast_path.mk",
                "kvm-fxmark-fast-path-preflight",
                "FXMARK_FAST_PATH_FINALIZE",
                "NAMEI_EXT_RUN_COMPLETE",
                "fxmark-fast-path-analyze",
            ),
            (
                ROOT / "mk/experiments/fxmark_fast_path.mk",
                "kvm-fxmark-fast-path",
                "FXMARK_FAST_PATH_FINALIZE",
                "NAMEI_EXT_RUN_COMPLETE",
                "fxmark-fast-path-analyze",
            ),
            (
                ROOT / "mk/experiments/service_config_rotation.mk",
                "kvm-service-config-rotation-preflight",
                "service-config-rotation-finalize",
                "NAMEI_EXT_RUN_COMPLETE",
                "service-config-rotation-analyze",
            ),
            (
                ROOT / "mk/experiments/service_config_rotation.mk",
                "kvm-service-config-rotation",
                "service-config-rotation-finalize",
                "NAMEI_EXT_RUN_COMPLETE",
                "service-config-rotation-analyze",
            ),
            (
                ROOT / "mk/experiments/checkpoint_restore.mk",
                "kvm-checkpoint-restore-preflight",
                "checkpoint-restore-finalize",
                "NAMEI_EXT_RUN_COMPLETE",
                "checkpoint-restore-analyze",
            ),
            (
                ROOT / "mk/experiments/checkpoint_restore.mk",
                "kvm-checkpoint-restore-rq1",
                "checkpoint-restore-finalize",
                "NAMEI_EXT_RUN_COMPLETE",
                "checkpoint-restore-analyze",
            ),
        )
        for path, target, *ordered_steps in cases:
            with self.subTest(target=target):
                block = self.target_block(path, target)
                positions = [block.index(step) for step in ordered_steps]
                self.assertEqual(positions, sorted(positions))

    def test_checkpoint_path_has_no_checksum_evidence_gate(self):
        paths = (
            ROOT / "experiments/checkpoint_restore/Makefile",
            ROOT / "experiments/checkpoint_restore/namei_ext_checkpoint_restore.c",
            ROOT / "mk/experiments/checkpoint_restore.mk",
            ROOT / "analysis/checkpoint_restore/analyze.py",
        )
        for path in paths:
            with self.subTest(path=path):
                source = path.read_text(encoding="utf-8").lower()
                self.assertNotIn("sha256", source)
                self.assertNotIn("checksum", source)

    def test_checkpoint_upstream_identity_is_computed_in_setpriv_recipe(self):
        block = self.target_block(
            ROOT / "mk/experiments/checkpoint_restore.mk",
            "__checkpoint_restore_guest",
        )
        self.assertIn("runtime-identity-probe.txt", block)
        probe = block[block.index("runtime_uid="):block.index("upstream_status=0")]
        self.assertIn(
            '--reuid="$$runtime_uid" --regid="$$runtime_gid" --clear-groups',
            probe,
        )
        self.assertIn(
            "sh -c 'id -u; id -g'",
            probe,
        )
        upstream = block[block.index("upstream_status=0"):]
        self.assertIn(
            '--reuid="$$(stat -c %u "$(CHECKPOINT_RESTORE_BOOT_DIR)")"',
            upstream,
        )
        self.assertIn(
            '--regid="$$(stat -c %g "$(CHECKPOINT_RESTORE_BOOT_DIR)")"',
            upstream,
        )

    def test_checkpoint_runtime_directories_are_owned_by_application_user(self):
        suite = (
            ROOT / "mk/experiments/checkpoint_restore.mk"
        ).read_text(encoding="utf-8")
        runner = (
            ROOT / "experiments/checkpoint_restore/"
            "namei_ext_checkpoint_restore.c"
        ).read_text(encoding="utf-8")
        run_block = self.target_block(
            ROOT / "mk/experiments/checkpoint_restore.mk",
            "checkpoint-restore-run",
        )
        self.assertIn(
            'mkdir "$$boot_dir/conditions/$$condition"', run_block
        )
        guest_block = self.target_block(
            ROOT / "mk/experiments/checkpoint_restore.mk",
            "__checkpoint_restore_guest",
        )
        self.assertNotIn('mkdir "$$result"', guest_block)
        self.assertIn('test -d "$$result"', guest_block)
        self.assertIn("chown(directories[index].path, config->runtime_uid,", runner)
        self.assertIn("config->runtime_gid)", runner)
        self.assertIn("CHECKPOINT_RESTORE_GUEST_RUNNER", suite)


if __name__ == "__main__":
    unittest.main()
