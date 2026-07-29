#!/usr/bin/env python3

import argparse
import hashlib
import json
import os
import shutil
import subprocess
from pathlib import Path


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def load_manifest(path: Path, verify: bool = True) -> list[tuple[str, Path]]:
    rows = []
    for line_number, line in enumerate(
        path.read_text(encoding="utf-8").splitlines(), 1
    ):
        fields = line.split(maxsplit=1)
        if len(fields) != 2 or len(fields[0]) != 64:
            raise ValueError(f"{path}:{line_number}: malformed SHA-256 row")
        source = Path(fields[1].lstrip("*"))
        if not source.is_absolute():
            raise ValueError(f"{path}:{line_number}: source is not absolute")
        if verify:
            if not source.is_file():
                raise ValueError(f"{path}:{line_number}: missing source")
            if sha256(source) != fields[0]:
                raise ValueError(f"{path}:{line_number}: source hash mismatch")
        rows.append((fields[0], source))
    if not rows:
        raise ValueError(f"{path}: empty SHA-256 manifest")
    return rows


def under(path: Path, parent: Path) -> Path:
    try:
        return path.resolve().relative_to(parent.resolve())
    except ValueError as error:
        raise ValueError(f"{path}: outside {parent}") from error


def copy_verified(
    digest: str,
    source: Path,
    destination: Path,
    copied: dict[Path, str],
) -> None:
    prior = copied.get(destination)
    if prior is not None:
        if prior != digest:
            raise ValueError(f"{destination}: conflicting source hashes")
        return
    destination.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, destination)
    if sha256(destination) != digest:
        raise ValueError(f"{destination}: copied hash mismatch")
    copied[destination] = digest


def copy_bytes_verified(
    digest: str,
    content: bytes,
    destination: Path,
    copied: dict[Path, str],
) -> None:
    prior = copied.get(destination)
    if prior is not None:
        if prior != digest:
            raise ValueError(f"{destination}: conflicting source hashes")
        return
    if hashlib.sha256(content).hexdigest() != digest:
        raise ValueError(f"{destination}: repository blob hash mismatch")
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_bytes(content)
    copied[destination] = digest


def repository_blob(
    root: Path,
    relative: Path,
    project_commit: str,
    kernel_commit: str,
) -> bytes:
    if relative.parts and relative.parts[0] == "kernel":
        repository = root / "kernel"
        commit = kernel_commit
        git_path = Path(*relative.parts[1:])
    else:
        repository = root
        commit = project_commit
        git_path = relative
    result = subprocess.run(
        ["git", "-C", str(repository), "show", f"{commit}:{git_path.as_posix()}"],
        check=True,
        capture_output=True,
    )
    return result.stdout


def portable_input_manifest(
    boot_dir: Path,
    rows: list[tuple[str, Path]],
    destination_root: Path,
    root: Path,
    project_commit: str,
    kernel_commit: str,
    copied: dict[Path, str],
) -> tuple[str, list[str]]:
    output = []
    paths = []
    for digest, source in rows:
        relative = under(source, root)
        destination = destination_root / "source" / relative
        if source.is_file() and sha256(source) == digest:
            copy_verified(digest, source, destination, copied)
        else:
            copy_bytes_verified(
                digest,
                repository_blob(
                    root,
                    relative,
                    project_commit,
                    kernel_commit,
                ),
                destination,
                copied,
            )
        portable = Path(os.path.relpath(destination, boot_dir))
        output.append(f"{digest}  {portable.as_posix()}")
        paths.append(destination.relative_to(destination_root.parent).as_posix())
    return "\n".join(output) + "\n", paths


def portable_manifest(
    boot_dir: Path,
    rows: list[tuple[str, Path]],
    destination_root: Path,
    prefix: str,
    parent: Path,
    copied: dict[Path, str],
) -> tuple[str, list[str]]:
    output = []
    paths = []
    for digest, source in rows:
        relative = under(source, parent)
        destination = destination_root / prefix / relative
        copy_verified(digest, source, destination, copied)
        portable = Path(os.path.relpath(destination, boot_dir))
        output.append(f"{digest}  {portable.as_posix()}")
        paths.append(destination.relative_to(destination_root.parent).as_posix())
    return "\n".join(output) + "\n", paths


def write_hashes(root: Path, paths: list[Path], output: Path) -> None:
    rows = []
    for path in sorted(set(paths)):
        rows.append(f"{sha256(path)}  {path.relative_to(root).as_posix()}")
    if not rows:
        raise ValueError(f"{output}: no files to hash")
    output.write_text("\n".join(rows) + "\n", encoding="utf-8")


def package(formal_dir: Path, root: Path, build_root: Path) -> None:
    summary_path = formal_dir / "formal-summary.json"
    summary = json.loads(summary_path.read_text(encoding="utf-8"))
    if (
        summary.get("schema") != "namei_ext.agent_workspace_rq3.formal.v2"
        or summary.get("pass") is not True
        or summary.get("boots") != 3
        or summary.get("completed_boots") != 3
        or summary.get("run_id") != formal_dir.name
    ):
        raise ValueError(f"{summary_path}: not a complete formal result")

    boot_dirs = sorted(path for path in formal_dir.glob("boot-*") if path.is_dir())
    if len(boot_dirs) != 3:
        raise ValueError(f"{formal_dir}: expected three boot directories")

    provenances = [
        json.loads((boot / "provenance.json").read_text(encoding="utf-8"))
        for boot in boot_dirs
    ]
    if any(item.get("project_dirty") or item.get("kernel_dirty")
           for item in provenances):
        raise ValueError("formal result has dirty source provenance")
    stable_keys = (
        "project_commit",
        "kernel_commit",
        "kernel_submodule_commit",
        "wrapfs_upstream_commit",
    )
    for key in stable_keys:
        if len({item.get(key) for item in provenances}) != 1:
            raise ValueError(f"formal boots disagree on {key}")
    provenance = provenances[0]

    artifacts_root = formal_dir / "artifacts"
    if artifacts_root.exists():
        shutil.rmtree(artifacts_root)
    artifacts_root.mkdir()
    copied: dict[Path, str] = {}
    source_paths: set[str] = set()
    runtime_paths: set[str] = set()
    observations = []

    for boot in boot_dirs:
        input_text, inputs = portable_input_manifest(
            boot,
            load_manifest(boot / "inputs.sha256", verify=False),
            artifacts_root,
            root,
            provenance["project_commit"],
            provenance["kernel_commit"],
            copied,
        )
        artifact_text, runtime = portable_manifest(
            boot,
            load_manifest(boot / "artifacts.sha256"),
            artifacts_root,
            "runtime",
            build_root,
            copied,
        )
        (boot / "publication-inputs.sha256").write_text(
            input_text, encoding="utf-8"
        )
        (boot / "publication-artifacts.sha256").write_text(
            artifact_text, encoding="utf-8"
        )
        source_paths.update(inputs)
        runtime_paths.update(runtime)
        observations.append(
            (boot / "observations.jsonl").read_text(encoding="utf-8")
        )

    (formal_dir / "observations.jsonl").write_text(
        "".join(observations), encoding="utf-8"
    )
    (formal_dir / "source-commit.txt").write_text(
        provenance["project_commit"] + "\n", encoding="utf-8"
    )
    (formal_dir / "kernel-commit.txt").write_text(
        provenance["kernel_commit"] + "\n", encoding="utf-8"
    )
    (formal_dir / "source-status.txt").write_text("", encoding="utf-8")
    (formal_dir / "kernel-status.txt").write_text("", encoding="utf-8")

    manifest = {
        "schema": "namei_ext.agent_workspace_rq3.artifacts.v1",
        "source_commit": provenance["project_commit"],
        "kernel_commit": provenance["kernel_commit"],
        "wrapfs_upstream_commit": provenance["wrapfs_upstream_commit"],
        "source": sorted(source_paths),
        "runtime": sorted(runtime_paths),
    }
    manifest_path = artifacts_root / "manifest.json"
    manifest_path.write_text(
        json.dumps(manifest, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )

    artifact_files = [
        path for path in artifacts_root.rglob("*") if path.is_file()
    ]
    write_hashes(formal_dir, artifact_files, formal_dir / "artifacts.sha256")
    source_files = [formal_dir / path for path in manifest["source"]]
    write_hashes(formal_dir, source_files, formal_dir / "inputs.sha256")

    run = {
        "schema": "namei_ext.run.v2",
        "run_id": summary["run_id"],
        "suite": "agent-workspace-rq3",
        "source_system": "agentfs-wrapfs",
        "result_level": "formal-kvm-boundary-matrix",
        "status": "completed",
        "started_at": summary["generated_at"],
        "completed_at": summary["generated_at"],
        "observations": "observations.jsonl",
        "source": {
            "commit": provenance["project_commit"],
            "dirty": False,
        },
        "kernel": {
            "commit": provenance["kernel_commit"],
            "dirty": False,
        },
        "kernel_commit": provenance["kernel_commit"],
        "policy": "agent_workspace_view.bpf.c",
        "runner": "namei_ext_agent_workspace+wrapfs",
        "layout": "three-boot-boundary-matrix",
        "artifacts": manifest,
    }
    (formal_dir / "run.json").write_text(
        json.dumps(run, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--formal-dir", type=Path, required=True)
    parser.add_argument("--root", type=Path, required=True)
    parser.add_argument("--build-root", type=Path, required=True)
    args = parser.parse_args()
    package(
        args.formal_dir.resolve(),
        args.root.resolve(),
        args.build_root.resolve(),
    )


if __name__ == "__main__":
    main()
