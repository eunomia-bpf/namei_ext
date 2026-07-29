#!/usr/bin/env python3

import json
import subprocess
import tempfile
import unittest
from pathlib import Path

from validate_published_results import validate_repository


class PublishedResultTest(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.repo = Path(self.temporary.name)
        subprocess.run(["git", "init", "-q", str(self.repo)], check=True)
        self.root = self.repo / "results/experiments/example/formal-v1"
        self.index = self.repo / "configs/publication/published-formal.json"
        (self.root / "analysis").mkdir(parents=True)
        (self.root / "artifacts/source").mkdir(parents=True)
        run = {
            "schema": "namei_ext.run.v2",
            "run_id": "formal-v1",
            "status": "completed",
            "completed_at": "2026-07-28T00:00:00Z",
            "observations": "observations.jsonl",
            "source": {"commit": "1" * 40, "dirty": False},
            "kernel": {"commit": "2" * 40, "dirty": False},
            "artifacts": {
                "source": {"oracle": "artifacts/source/oracle.txt"},
                "runtime": ["artifacts/runtime/runner"],
            },
        }
        self.write("run.json", json.dumps(run))
        self.write("command.txt", "make experiment-example\n")
        self.write("inputs.sha256", f"{'3' * 64}  input\n")
        self.write("artifacts.sha256", f"{'4' * 64}  artifact\n")
        self.write("artifacts/manifest.json", "{}\n")
        self.write("artifacts/source/oracle.txt", "oracle\n")
        self.write("artifacts/runtime/runner", "runner\n")
        self.write("source-commit.txt", f"{'1' * 40}\n")
        self.write("kernel-commit.txt", f"{'2' * 40}\n")
        self.write(
            "analysis/summary.json",
            '{"input":"stored","run":"stored","records":1,"seed":7}\n',
        )
        self.write("observations.jsonl", '{"pass":true}\n')
        analyzer = self.repo / "analysis/example.py"
        analyzer.parent.mkdir(parents=True)
        analyzer.write_text(
            "import argparse, json\n"
            "from pathlib import Path\n"
            "p = argparse.ArgumentParser()\n"
            "p.add_argument('--input', required=True)\n"
            "p.add_argument('--run', required=True)\n"
            "p.add_argument('--output', type=Path, required=True)\n"
            "p.add_argument('--seed', type=int, required=True)\n"
            "p.add_argument('--oracle', required=True)\n"
            "a = p.parse_args()\n"
            "a.output.mkdir()\n"
            "records = len(Path(a.input).read_text().splitlines())\n"
            "(a.output / 'summary.json').write_text(json.dumps({"
            "'input': a.input, 'run': a.run, 'records': records, "
            "'seed': a.seed}) + '\\n')\n",
            encoding="utf-8",
        )
        self.index.parent.mkdir(parents=True)
        self.index.write_text(
            json.dumps(
                {
                    "schema": "namei_ext.published_formal.v1",
                    "runs": [
                        {
                            "run": (
                                "results/experiments/example/formal-v1/run.json"
                            ),
                            "analyzer": "analysis/example.py",
                            "seed": 7,
                            "require_all_artifacts": True,
                            "analysis_args": {
                                "oracle": "artifacts/source/oracle.txt"
                            },
                        }
                    ],
                }
            ),
            encoding="utf-8",
        )
        subprocess.run(["git", "-C", str(self.repo), "add", "."], check=True)

    def tearDown(self):
        self.temporary.cleanup()

    def write(self, relative: str, value: str):
        path = self.root / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(value, encoding="utf-8")

    def test_complete_bundle_passes(self):
        self.assertEqual(validate_repository(self.repo, self.index), [])

    def test_untracked_observations_fail(self):
        subprocess.run(
            [
                "git",
                "-C",
                str(self.repo),
                "rm",
                "--cached",
                "results/experiments/example/formal-v1/observations.jsonl",
            ],
            check=True,
            capture_output=True,
        )
        errors = validate_repository(self.repo, self.index)
        self.assertTrue(any("observations.jsonl" in error for error in errors))

    def test_commit_mismatch_fails(self):
        self.write("source-commit.txt", f"{'5' * 40}\n")
        errors = validate_repository(self.repo, self.index)
        self.assertTrue(any("commit does not match" in error for error in errors))

    def test_invalid_jsonl_fails(self):
        self.write("observations.jsonl", "not-json\n")
        errors = validate_repository(self.repo, self.index)
        self.assertTrue(any("invalid JSON" in error for error in errors))

    def test_summary_mismatch_fails(self):
        self.write("analysis/summary.json", '{"records":2,"seed":7}\n')
        errors = validate_repository(self.repo, self.index)
        self.assertTrue(any("does not reproduce" in error for error in errors))

    def test_untracked_analyzer_is_not_executed(self):
        analyzer = self.repo / "analysis/example.py"
        subprocess.run(
            ["git", "-C", str(self.repo), "rm", "--cached", "analysis/example.py"],
            check=True,
            capture_output=True,
        )
        analyzer.write_text("raise RuntimeError('executed')\n", encoding="utf-8")
        errors = validate_repository(self.repo, self.index)
        self.assertTrue(
            any(
                "analysis/example.py" in error and "not tracked" in error
                for error in errors
            )
        )
        self.assertFalse(any("analyzer replay failed" in error for error in errors))

    def test_symlink_analyzer_is_not_executed(self):
        analyzer = self.repo / "analysis/example.py"
        subprocess.run(
            ["git", "-C", str(self.repo), "rm", "-f", "analysis/example.py"],
            check=True,
            capture_output=True,
        )
        target = self.repo / "analysis/target.py"
        target.parent.mkdir()
        target.write_text("raise RuntimeError('executed')\n", encoding="utf-8")
        analyzer.symlink_to("target.py")
        subprocess.run(
            ["git", "-C", str(self.repo), "add", "analysis/example.py"],
            check=True,
        )
        errors = validate_repository(self.repo, self.index)
        self.assertTrue(
            any(
                "analysis/example.py" in error and "regular file" in error
                for error in errors
            )
        )
        self.assertFalse(any("analyzer replay failed" in error for error in errors))

    def test_untracked_analysis_input_is_not_executed(self):
        run_path = self.root / "run.json"
        run = json.loads(run_path.read_text(encoding="utf-8"))
        run["artifacts"]["source"] = {}
        run_path.write_text(json.dumps(run), encoding="utf-8")
        subprocess.run(
            [
                "git",
                "-C",
                str(self.repo),
                "rm",
                "--cached",
                "results/experiments/example/formal-v1/artifacts/source/oracle.txt",
            ],
            check=True,
            capture_output=True,
        )
        (self.repo / "analysis/example.py").write_text(
            "raise RuntimeError('executed')\n", encoding="utf-8"
        )
        errors = validate_repository(self.repo, self.index)
        self.assertTrue(
            any(
                "oracle.txt" in error and "not tracked" in error
                for error in errors
            )
        )
        self.assertFalse(any("analyzer replay failed" in error for error in errors))

    def test_untracked_declared_runtime_artifact_fails(self):
        subprocess.run(
            [
                "git",
                "-C",
                str(self.repo),
                "rm",
                "--cached",
                "results/experiments/example/formal-v1/artifacts/runtime/runner",
            ],
            check=True,
            capture_output=True,
        )
        errors = validate_repository(self.repo, self.index)
        self.assertTrue(
            any("artifacts/runtime/runner" in error for error in errors)
        )

    def test_unlisted_failed_result_is_allowed(self):
        failed = self.repo / "results/experiments/example/failed-v1/run.json"
        failed.parent.mkdir(parents=True)
        failed.write_text('{"status":"failed"}\n', encoding="utf-8")
        subprocess.run(
            ["git", "-C", str(self.repo), "add", str(failed.relative_to(self.repo))],
            check=True,
        )
        self.assertEqual(validate_repository(self.repo, self.index), [])


if __name__ == "__main__":
    unittest.main()
