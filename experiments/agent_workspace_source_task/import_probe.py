#!/usr/bin/env python3

import argparse
import importlib
import json
import os
from pathlib import Path


def identity(path: Path) -> dict[str, int | str]:
    stat = path.stat()
    return {
        "path": str(path),
        "device": stat.st_dev,
        "inode": stat.st_ino,
    }


def same_object(left: dict[str, int | str], right: dict[str, int | str]) -> bool:
    return left["device"] == right["device"] and left["inode"] == right["inode"]


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--logical-root", required=True)
    parser.add_argument("--expected-root", required=True)
    parser.add_argument("--output", required=True)
    args = parser.parse_args()

    logical_root = Path(args.logical_root)
    expected_root = Path(args.expected_root)
    logical_src = logical_root / "src"
    expected_sys_path = str(logical_src)

    click = importlib.import_module("click")
    click_types = importlib.import_module("click.types")

    logical_types = logical_src / "click" / "types.py"
    expected_types = expected_root / "src" / "click" / "types.py"
    logical_test = logical_root / "tests" / "test_types.py"
    expected_test = expected_root / "tests" / "test_types.py"
    click_file = Path(click.__file__).resolve(strict=False)
    click_types_file = Path(click_types.__file__).resolve(strict=False)

    logical_types_id = identity(logical_types)
    expected_types_id = identity(expected_types)
    logical_test_id = identity(logical_test)
    expected_test_id = identity(expected_test)
    cwd = Path.cwd()
    cwd_id = identity(cwd)
    logical_root_id = identity(logical_root)
    expected_root_id = identity(expected_root)
    checks = {
        "cwd_identity_matches": same_object(cwd_id, expected_root_id),
        "logical_root_identity_matches": same_object(
            logical_root_id, expected_root_id
        ),
        "sys_path_has_exact_logical_src": expected_sys_path in os.sys.path,
        "click_file_is_logical": str(click_file) == str(
            logical_src / "click" / "__init__.py"
        ),
        "click_types_file_is_logical": str(click_types_file) == str(logical_types),
        "types_identity_matches": same_object(logical_types_id, expected_types_id),
        "test_identity_matches": same_object(logical_test_id, expected_test_id),
    }
    record = {
        "schema": "namei_ext.agent_source_task.import.v2",
        "logical_root": str(logical_root),
        "expected_root": str(expected_root),
        "cwd": str(cwd),
        "cwd_identity": cwd_id,
        "logical_root_identity": logical_root_id,
        "expected_root_identity": expected_root_id,
        "effective_sys_path": os.sys.path,
        "required_sys_path": expected_sys_path,
        "click_file": str(click_file),
        "click_types_file": str(click_types_file),
        "logical_types": logical_types_id,
        "expected_types": expected_types_id,
        "logical_test": logical_test_id,
        "expected_test": expected_test_id,
        "checks": checks,
        "pass": all(checks.values()),
    }
    with open(args.output, "w", encoding="utf-8") as output:
        json.dump(record, output, indent=2, sort_keys=True)
        output.write("\n")
    return 0 if record["pass"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
