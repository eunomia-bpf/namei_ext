#!/usr/bin/env python3

import argparse
import json
import re
import subprocess
import sys
import tempfile
from pathlib import Path, PurePosixPath


COMMIT_RE = re.compile(r"^[0-9a-f]{40}$")
BASE_REQUIRED = (
    "run.json",
    "command.txt",
    "inputs.sha256",
    "artifacts.sha256",
    "artifacts/manifest.json",
    "source-commit.txt",
    "kernel-commit.txt",
    "analysis/summary.json",
)


def tracked_files(repo: Path) -> set[str]:
    result = subprocess.run(
        ["git", "-C", str(repo), "ls-files", "-z"],
        check=True,
        capture_output=True,
    )
    return {
        item.decode("utf-8")
        for item in result.stdout.split(b"\0")
        if item
    }


def load_json(path: Path, errors: list[str]):
    try:
        with path.open(encoding="utf-8") as source:
            return json.load(source)
    except (OSError, json.JSONDecodeError) as error:
        errors.append(f"{path}: invalid JSON: {error}")
        return None


def safe_relative_path(value: object, label: str, errors: list[str]):
    if not isinstance(value, str) or not value:
        errors.append(f"{label}: expected a non-empty relative path")
        return None
    path = PurePosixPath(value)
    if path.is_absolute() or ".." in path.parts:
        errors.append(f"{label}: path escapes the result root: {value}")
        return None
    return path


def validate_observations(path: Path, errors: list[str]):
    records = 0
    try:
        with path.open(encoding="utf-8") as source:
            for line_number, line in enumerate(source, start=1):
                if not line.strip():
                    errors.append(f"{path}:{line_number}: empty JSONL record")
                    continue
                try:
                    json.loads(line)
                except json.JSONDecodeError as error:
                    errors.append(f"{path}:{line_number}: invalid JSON: {error}")
                records += 1
    except OSError as error:
        errors.append(f"{path}: cannot read observations: {error}")
        return
    if records == 0:
        errors.append(f"{path}: no observation records")


def artifact_paths(value: object):
    if isinstance(value, dict):
        for child in value.values():
            yield from artifact_paths(child)
    elif isinstance(value, list):
        for child in value:
            yield from artifact_paths(child)
    elif isinstance(value, str) and value.startswith("artifacts/"):
        yield value


def require_tracked_file(
    repo: Path,
    relative: PurePosixPath,
    tracked: set[str],
    errors: list[str],
) -> bool:
    value = relative.as_posix()
    path = repo / value
    if value not in tracked:
        errors.append(f"{value}: required publication file is not tracked")
        return False
    if not path.is_file() or path.is_symlink():
        errors.append(f"{value}: required publication file is not a regular file")
        return False
    if path.stat().st_size == 0:
        errors.append(f"{value}: required publication file is empty")
        return False
    return True


def replay_analysis(
    repo: Path,
    root: Path,
    run: dict,
    entry: dict,
    tracked: set[str],
    errors: list[str],
):
    analyzer = safe_relative_path(
        entry.get("analyzer"), f"{root}: analyzer", errors
    )
    if analyzer is None:
        return
    if not require_tracked_file(repo, analyzer, tracked, errors):
        return
    analyzer_path = repo / analyzer

    seed = entry.get("seed")
    if not isinstance(seed, int):
        errors.append(f"{root}: analysis seed is not an integer")
        return
    analysis_args = entry.get("analysis_args", {})
    if not isinstance(analysis_args, dict):
        errors.append(f"{root}: analysis_args is not an object")
        return

    extra_arguments: list[str] = []
    dynamic_keys = {"input", "run"}
    for name, value in sorted(analysis_args.items()):
        if not re.fullmatch(r"[a-z][a-z0-9_]*", name):
            errors.append(f"{root}: invalid analyzer argument name: {name}")
            return
        relative = safe_relative_path(
            value, f"{root}: analyzer argument {name}", errors
        )
        if relative is None:
            return
        if not require_tracked_file(
            repo,
            PurePosixPath(root.relative_to(repo).as_posix()) / relative,
            tracked,
            errors,
        ):
            return
        extra_arguments.extend(
            (f"--{name.replace('_', '-')}", str(root / relative))
        )
        dynamic_keys.add(name)

    with tempfile.TemporaryDirectory(prefix="namei-ext-analysis-replay-") as temp:
        output = Path(temp) / "analysis"
        command = [
            sys.executable,
            str(analyzer_path),
            "--input",
            str(root / run["observations"]),
            "--run",
            str(root / "run.json"),
            "--output",
            str(output),
            "--seed",
            str(seed),
            *extra_arguments,
        ]
        result = subprocess.run(command, capture_output=True, text=True)
        if result.returncode:
            errors.append(
                f"{root}: analyzer replay failed: "
                f"{result.stderr.strip() or result.stdout.strip()}"
            )
            return
        generated = load_json(output / "summary.json", errors)
        expected = load_json(root / "analysis/summary.json", errors)
        if generated is None or expected is None:
            return
        for summary in (generated, expected):
            for key in dynamic_keys:
                summary.pop(key, None)
        if generated != expected:
            errors.append(f"{root}: analyzer replay does not reproduce summary.json")


def validate_result(
    repo: Path, run_relative: str, entry: dict, tracked: set[str]
) -> list[str]:
    errors: list[str] = []
    run_path = repo / run_relative
    root_relative = PurePosixPath(run_relative).parent
    root = repo / root_relative
    run = load_json(run_path, errors)
    if run is None:
        return errors
    if not isinstance(run, dict):
        errors.append(f"{run_relative}: run.json is not an object")
        return errors

    if run.get("schema") != "namei_ext.run.v2":
        errors.append(f"{run_relative}: unsupported run schema")
    if run.get("status") != "completed" or not run.get("completed_at"):
        errors.append(f"{run_relative}: published run is not completed")
    if run.get("run_id") != root.name:
        errors.append(f"{run_relative}: run_id does not match result directory")
    source = run.get("source")
    kernel = run.get("kernel")
    if not isinstance(source, dict) or source.get("dirty") is not False:
        errors.append(f"{run_relative}: published source tree was dirty")
    if not isinstance(kernel, dict) or kernel.get("dirty") is not False:
        errors.append(f"{run_relative}: published kernel tree was dirty")

    observations = safe_relative_path(
        run.get("observations"), f"{run_relative}: observations", errors
    )
    required = [PurePosixPath(item) for item in BASE_REQUIRED]
    if observations is not None:
        required.append(observations)

    artifacts = run.get("artifacts")
    if entry.get("require_all_artifacts") is True:
        declared_artifacts = artifact_paths(artifacts)
    else:
        source_artifacts = (
            artifacts.get("source", {}) if isinstance(artifacts, dict) else {}
        )
        declared_artifacts = artifact_paths(source_artifacts)
    for value in declared_artifacts:
        relative = safe_relative_path(
            value, f"{run_relative}: declared artifact", errors
        )
        if relative is not None:
            required.append(relative)

    for relative in required:
        require_tracked_file(repo, root_relative / relative, tracked, errors)

    source_commit = source.get("commit") if isinstance(source, dict) else None
    kernel_commit = kernel.get("commit") if isinstance(kernel, dict) else None
    for label, value in (("source", source_commit), ("kernel", kernel_commit)):
        if not isinstance(value, str) or not COMMIT_RE.fullmatch(value):
            errors.append(f"{run_relative}: invalid {label} commit")
    for filename, expected in (
        ("source-commit.txt", source_commit),
        ("kernel-commit.txt", kernel_commit),
    ):
        path = root / filename
        if path.is_file() and path.read_text(encoding="utf-8").strip() != expected:
            errors.append(f"{path}: commit does not match run.json")

    if observations is not None and (root / observations).is_file():
        validate_observations(root / observations, errors)
    for filename in ("artifacts/manifest.json", "analysis/summary.json"):
        path = root / filename
        if path.is_file():
            load_json(path, errors)
    if not errors:
        replay_analysis(repo, root, run, entry, tracked, errors)
    return errors


def published_entries(
    repo: Path, index: Path, tracked: set[str], errors: list[str]
) -> list[dict]:
    try:
        index_relative = index.resolve().relative_to(repo.resolve()).as_posix()
    except ValueError:
        errors.append(f"{index}: publication index is outside the repository")
        return []
    if index_relative not in tracked:
        errors.append(f"{index_relative}: publication index is not tracked")
        return []
    document = load_json(index, errors)
    if document is None:
        return []
    if not isinstance(document, dict):
        errors.append(f"{index_relative}: publication index is not an object")
        return []
    if document.get("schema") != "namei_ext.published_formal.v1":
        errors.append(f"{index_relative}: unsupported publication schema")
        return []
    entries = document.get("runs")
    if not isinstance(entries, list) or not entries:
        errors.append(f"{index_relative}: no published formal runs")
        return []

    validated: list[dict] = []
    run_files: list[str] = []
    for entry_number, entry in enumerate(entries, start=1):
        if not isinstance(entry, dict):
            errors.append(f"{index_relative}: run {entry_number} is not an object")
            continue
        value = entry.get("run")
        relative = safe_relative_path(
            value, f"{index_relative}: run {entry_number}", errors
        )
        if relative is None:
            continue
        run_file = relative.as_posix()
        if not re.fullmatch(
            r"results/experiments/[^/]+/[^/]+/run\.json", run_file
        ):
            errors.append(
                f"{index_relative}: run {entry_number} has invalid formal path"
            )
            continue
        run_files.append(run_file)
        validated.append(entry)
    if len(run_files) != len(set(run_files)):
        errors.append(f"{index_relative}: duplicate formal run path")
    return validated


def validate_repository(repo: Path, index: Path) -> list[str]:
    tracked = tracked_files(repo)
    errors: list[str] = []
    entries = published_entries(repo, index, tracked, errors)
    for entry in entries:
        run_file = entry["run"]
        if run_file not in tracked:
            errors.append(f"{run_file}: published run.json is not tracked")
            continue
        errors.extend(validate_result(repo, run_file, entry, tracked))
    return errors


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo", type=Path, required=True)
    parser.add_argument("--index", type=Path, required=True)
    args = parser.parse_args()

    errors = validate_repository(args.repo.resolve(), args.index.resolve())
    if errors:
        for error in errors:
            print(error, file=sys.stderr)
        return 1
    print("published formal analysis bundles: valid")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
