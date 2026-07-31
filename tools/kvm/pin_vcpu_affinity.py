#!/usr/bin/env python3

import argparse
import os
import time
from pathlib import Path

from verify_vcpu_affinity import (
    affinity_matches,
    parse_cpu_list,
    query_vcpus,
    read_allowed_cpus,
    utc_now,
    write_result,
)


class PinningError(RuntimeError):
    def __init__(self, message, before=None, after=None):
        super().__init__(message)
        self.before = before or []
        self.after = after or []


def query_vcpu_records(host, port):
    records = []
    for expected_index, cpu in enumerate(
            sorted(query_vcpus(host, port),
                   key=lambda item: item["cpu-index"])):
        index = cpu.get("cpu-index")
        tid = cpu.get("thread-id")
        if type(index) is not int or index != expected_index:
            raise RuntimeError("QMP returned non-contiguous vCPU indexes")
        if type(tid) is not int or tid <= 0:
            raise RuntimeError("QMP returned an invalid vCPU TID")
        records.append({"vcpu_index": index, "host_tid": tid})
    if not records:
        raise RuntimeError("QMP returned no vCPUs")
    return records


def observe_records(records):
    return [
        {
            **record,
            "cpus_allowed": read_allowed_cpus(record["host_tid"]),
        }
        for record in records
    ]


def pin_once(host, port, expected):
    records = query_vcpu_records(host, port)
    if len(records) != len(expected):
        raise RuntimeError(
            f"QMP returned {len(records)} vCPUs, expected {len(expected)}")

    before = observe_records(records)
    try:
        for record, host_cpu in zip(records, expected):
            os.sched_setaffinity(record["host_tid"], {host_cpu})
    except OSError as error:
        try:
            after = observe_records(records)
        except (OSError, RuntimeError, ValueError):
            after = []
        raise PinningError(
            f"sched_setaffinity failed: {error}", before, after) from error

    try:
        after = observe_records(records)
    except (OSError, RuntimeError, ValueError) as error:
        raise PinningError(
            f"affinity read-back failed: {error}", before) from error
    if not affinity_matches(after, expected):
        raise PinningError(
            "vCPU affinities do not match after pinning", before, after)
    return before, after


def expected_mapping(expected):
    return [
        {"vcpu_index": index, "host_cpu": host_cpu}
        for index, host_cpu in enumerate(expected)
    ]


def pin_until(host, port, expected, timeout_seconds, poll_seconds=0.1):
    deadline = time.monotonic() + timeout_seconds
    attempts = 0
    last_error = "QMP not observed"
    last_before = []
    last_after = []
    while time.monotonic() < deadline:
        attempts += 1
        try:
            last_before, last_after = pin_once(host, port, expected)
            return True, {
                "schema": "namei_ext.vcpu_affinity_pin.v1",
                "status": "pinned",
                "pinned_at": utc_now(),
                "qmp": {"host": host, "port": port},
                "expected_host_cpus": expected,
                "expected_vcpu_mapping": expected_mapping(expected),
                "before": last_before,
                "vcpus": last_after,
                "attempts": attempts,
            }
        except PinningError as error:
            last_before = error.before
            last_after = error.after
            last_error = str(error)
        except (OSError, RuntimeError, ValueError, KeyError) as error:
            last_error = str(error)
        time.sleep(poll_seconds)

    return False, {
        "schema": "namei_ext.vcpu_affinity_pin.v1",
        "status": "failed",
        "failed_at": utc_now(),
        "qmp": {"host": host, "port": port},
        "expected_host_cpus": expected,
        "expected_vcpu_mapping": expected_mapping(expected),
        "last_before": last_before,
        "last_vcpus": last_after,
        "attempts": attempts,
        "error": last_error,
    }


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=3636)
    parser.add_argument("--expected", required=True)
    parser.add_argument("--timeout-seconds", type=float, default=20.0)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()

    expected = parse_cpu_list(args.expected)
    pinned, payload = pin_until(
        args.host, args.port, expected, args.timeout_seconds)
    write_result(args.output, payload)
    return 0 if pinned else 1


if __name__ == "__main__":
    raise SystemExit(main())
