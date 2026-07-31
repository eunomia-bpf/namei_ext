#!/usr/bin/env python3

import argparse
import datetime
import json
import socket
import time
from pathlib import Path


def parse_cpu_list(expression):
    cpus = []
    for item in expression.split(","):
        item = item.strip()
        if not item:
            raise ValueError("empty CPU-list item")
        if "-" in item:
            start_text, end_text = item.split("-", 1)
            start = int(start_text)
            end = int(end_text)
            if end < start:
                raise ValueError("descending CPU range")
            cpus.extend(range(start, end + 1))
        else:
            cpus.append(int(item))
    if len(cpus) != len(set(cpus)) or any(cpu < 0 for cpu in cpus):
        raise ValueError("duplicate or negative CPU")
    return cpus


def qmp_response(stream):
    while True:
        line = stream.readline()
        if not line:
            raise RuntimeError("QMP connection closed")
        response = json.loads(line)
        if "event" in response:
            continue
        return response


def query_vcpus(host, port):
    with socket.create_connection((host, port), timeout=1.0) as connection:
        connection.settimeout(1.0)
        with connection.makefile("r", encoding="utf-8") as stream:
            greeting = qmp_response(stream)
            if "QMP" not in greeting:
                raise RuntimeError("missing QMP greeting")
            for command in ("qmp_capabilities", "query-cpus-fast"):
                request = json.dumps({"execute": command}) + "\n"
                connection.sendall(request.encode("utf-8"))
                response = qmp_response(stream)
                if "error" in response:
                    raise RuntimeError(
                        f"QMP {command} failed: {response['error']}")
                if "return" not in response:
                    raise RuntimeError(f"QMP {command} returned no result")
            return response["return"]


def read_allowed_cpus(tid):
    status = Path(f"/proc/{tid}/status").read_text(encoding="utf-8")
    for line in status.splitlines():
        if line.startswith("Cpus_allowed_list:"):
            return parse_cpu_list(line.split(":", 1)[1].strip())
    raise RuntimeError(f"TID {tid} has no Cpus_allowed_list")


def observe_affinity(host, port):
    observations = []
    for cpu in sorted(query_vcpus(host, port),
                      key=lambda item: item["cpu-index"]):
        tid = cpu.get("thread-id")
        if type(tid) is not int or tid <= 0:
            raise RuntimeError("QMP returned an invalid vCPU TID")
        observations.append({
            "vcpu_index": cpu["cpu-index"],
            "host_tid": tid,
            "cpus_allowed": read_allowed_cpus(tid),
        })
    if not observations:
        raise RuntimeError("QMP returned no vCPUs")
    return observations


def affinity_matches(observations, expected):
    if len(observations) != len(expected):
        return False
    for index, (observation, host_cpu) in enumerate(
            zip(observations, expected)):
        if observation.get("vcpu_index") != index or \
                observation.get("cpus_allowed") != [host_cpu]:
            return False
    return True


def utc_now():
    return datetime.datetime.now(datetime.timezone.utc).isoformat()


def write_result(path, payload):
    temporary = path.with_name(f"{path.name}.tmp")
    temporary.write_text(
        json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    temporary.replace(path)


def verify_until(host, port, expected, timeout_seconds, poll_seconds=0.1,
                 initial_delay_seconds=0.0):
    if initial_delay_seconds < 0:
        raise ValueError("initial delay must be nonnegative")
    time.sleep(initial_delay_seconds)
    deadline = time.monotonic() + timeout_seconds
    last_error = "QMP not observed"
    last_observations = []
    attempts = 0
    while time.monotonic() < deadline:
        attempts += 1
        try:
            last_observations = observe_affinity(host, port)
            if affinity_matches(last_observations, expected):
                return True, {
                    "schema": "namei_ext.vcpu_affinity.v1",
                    "status": "verified",
                    "verified_at": utc_now(),
                    "qmp": {"host": host, "port": port},
                    "initial_delay_seconds": initial_delay_seconds,
                    "expected_host_cpus": expected,
                    "expected_vcpu_mapping": [
                        {"vcpu_index": index, "host_cpu": host_cpu}
                        for index, host_cpu in enumerate(expected)
                    ],
                    "vcpus": last_observations,
                    "attempts": attempts,
                }
            last_error = "vCPU affinities do not match expected CPUs"
        except (OSError, RuntimeError, ValueError, KeyError,
                json.JSONDecodeError) as error:
            last_error = str(error)
        time.sleep(poll_seconds)

    return False, {
        "schema": "namei_ext.vcpu_affinity.v1",
        "status": "failed",
        "failed_at": utc_now(),
        "qmp": {"host": host, "port": port},
        "initial_delay_seconds": initial_delay_seconds,
        "expected_host_cpus": expected,
        "expected_vcpu_mapping": [
            {"vcpu_index": index, "host_cpu": host_cpu}
            for index, host_cpu in enumerate(expected)
        ],
        "last_vcpus": last_observations,
        "attempts": attempts,
        "error": last_error,
    }


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=3636)
    parser.add_argument("--expected", required=True)
    parser.add_argument("--timeout-seconds", type=float, default=20.0)
    parser.add_argument("--initial-delay-seconds", type=float, default=0.0)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()

    expected = parse_cpu_list(args.expected)
    verified, payload = verify_until(
        args.host, args.port, expected, args.timeout_seconds,
        initial_delay_seconds=args.initial_delay_seconds)
    write_result(args.output, payload)
    return 0 if verified else 1


if __name__ == "__main__":
    raise SystemExit(main())
