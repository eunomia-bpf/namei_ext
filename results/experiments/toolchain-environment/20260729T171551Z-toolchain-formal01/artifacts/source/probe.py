#!/usr/bin/env python3

import argparse
import json
import os
import pathlib
import sqlite3
import ssl
import sys
import sysconfig
import venv

import pip


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--major", type=int, required=True)
    parser.add_argument("--minor", type=int, required=True)
    parser.add_argument("--prefix", required=True)
    args = parser.parse_args()

    expected_prefix = os.path.abspath(args.prefix)
    expected_soabi = f"cpython-{args.major}{args.minor}-x86_64-linux-gnu"
    executable = os.path.abspath(sys.executable)
    prefix = os.path.abspath(sys.prefix)
    pip_path = os.path.abspath(pip.__file__)
    pyvenv = pathlib.Path(expected_prefix, "pyvenv.cfg")

    checks = {
        "version": list(sys.version_info[:2]) == [args.major, args.minor],
        "executable": executable == os.path.join(expected_prefix, "bin", "python"),
        "prefix": prefix == expected_prefix,
        "base_prefix": os.path.abspath(sys.base_prefix) == "/usr",
        "soabi": sysconfig.get_config_var("SOABI") == expected_soabi,
        "pip_path": os.path.commonpath([expected_prefix, pip_path]) == expected_prefix,
        "pyvenv": pyvenv.is_file(),
        "venv_import": hasattr(venv, "EnvBuilder"),
        "ssl_import": bool(ssl.OPENSSL_VERSION),
        "sqlite_import": bool(sqlite3.sqlite_version),
    }
    record = {
        "schema": "namei_ext.toolchain_environment.probe.v1",
        "expected": {
            "major": args.major,
            "minor": args.minor,
            "prefix": expected_prefix,
            "soabi": expected_soabi,
        },
        "observed": {
            "version": list(sys.version_info[:3]),
            "executable": executable,
            "prefix": prefix,
            "base_prefix": os.path.abspath(sys.base_prefix),
            "soabi": sysconfig.get_config_var("SOABI"),
            "pip_version": pip.__version__,
            "pip_path": pip_path,
            "openssl": ssl.OPENSSL_VERSION,
            "sqlite": sqlite3.sqlite_version,
        },
        "checks": checks,
        "pass": all(checks.values()),
    }
    print(json.dumps(record, sort_keys=True))
    return 0 if record["pass"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
