#!/usr/bin/env python3

import argparse
import csv
import json
import math
import statistics
from collections import defaultdict
from pathlib import Path


STATES = ("current", "canary", "invalid", "rollback")
EXPECTED = {
    "current": {
        "target_id": 1,
        "http_body": "current-generation",
        "reload_error_observed": False,
    },
    "canary": {
        "target_id": 2,
        "http_body": "canary-generation",
        "reload_error_observed": False,
    },
    "invalid": {
        "target_id": 3,
        "http_body": "canary-generation",
        "reload_error_observed": True,
    },
    "rollback": {
        "target_id": 4,
        "http_body": "current-generation",
        "reload_error_observed": False,
    },
}
REQUIRED_CASES = (
    "current",
    "canary",
    "invalid",
    "rollback",
    "runtime_boundary",
    "attach_policy",
    "scope_policy",
    "worker_runtime_io",
    "lower_objects_unchanged",
    "graceful_shutdown",
    "capture_error_log",
    "remove_runtime",
    "detach_policy",
    "clear_targets",
    "remove_cgroup",
)
REQUIRED_COUNTERS = ("lookup", "readdir", "select")


def load_jsonl(path):
    rows = []
    with path.open(encoding="utf-8") as source:
        for line_number, line in enumerate(source, 1):
            if not line.strip():
                continue
            try:
                row = json.loads(line)
            except json.JSONDecodeError as error:
                raise ValueError(
                    f"invalid JSON at {path}:{line_number}: {error}") from error
            if not isinstance(row, dict):
                raise ValueError(f"non-object JSON at {path}:{line_number}")
            rows.append(row)
    if not rows:
        raise ValueError("observation file is empty")
    return rows


def percentile(values, quantile):
    ordered = sorted(values)
    if not ordered:
        raise ValueError("cannot summarize an empty value list")
    if len(ordered) == 1:
        return float(ordered[0])
    position = (len(ordered) - 1) * quantile
    lower = math.floor(position)
    upper = math.ceil(position)
    if lower == upper:
        return float(ordered[lower])
    weight = position - lower
    return ordered[lower] * (1 - weight) + ordered[upper] * weight


def validate_run(run, repetitions):
    if run.get("schema") != "namei_ext.run.v2":
        raise ValueError("unexpected run schema")
    if run.get("protocol_schema") != \
            "namei_ext.service_config_rotation.protocol.v2":
        raise ValueError("unexpected protocol schema")
    if run.get("layout") != "fresh-boot-matrix":
        raise ValueError("unexpected run layout")
    expected_identity = {
        "suite": "service-config-rotation",
        "source_system": "kubernetes-atomic-writer+nginx",
        "result_level": "kvm_service_config_rotation",
        "observations": "observations.jsonl",
        "policy": "service_config_rotation.bpf.c",
        "runner": "namei_ext_service_config_rotation+nginx",
    }
    for field, expected in expected_identity.items():
        if run.get(field) != expected:
            raise ValueError(f"unexpected run {field}")
    run_id = run.get("run_id")
    if not isinstance(run_id, str) or not run_id:
        raise ValueError("invalid run id")
    for field in ("source", "kernel"):
        identity = run.get(field)
        if not isinstance(identity, dict) or identity.get("dirty") is not False:
            raise ValueError(f"invalid {field} cleanliness")
        commit = identity.get("commit")
        if not isinstance(commit, str) or len(commit) != 40 or \
                any(character not in "0123456789abcdef"
                    for character in commit):
            raise ValueError(f"invalid {field} commit")
    if run.get("kernel_commit") != run["kernel"]["commit"]:
        raise ValueError("kernel commit mismatch")
    if run.get("status") not in ("running", "completed"):
        raise ValueError("run is not analyzable")
    matrix = run.get("matrix")
    if not isinstance(matrix, dict):
        raise ValueError("missing matrix")
    if matrix.get("repetitions") != repetitions:
        raise ValueError("run repetition count mismatch")
    if repetitions not in (1, 10):
        raise ValueError("only one-boot preflight or ten-boot formal runs are valid")
    if matrix.get("states") != list(STATES):
        raise ValueError("unexpected state sequence")
    if matrix.get("all_boots_must_pass") is not True:
        raise ValueError("missing all-pass gate")
    if matrix.get("timeout_seconds") != 5:
        raise ValueError("unexpected transition timeout")
    if matrix.get("kvm_timeout") != "120s":
        raise ValueError("unexpected KVM timeout")


def one(rows, event, repetition, field, value):
    matches = [
        row for row in rows
        if row.get("event") == event and
        row.get("repetition") == repetition and
        row.get(field) == value
    ]
    if len(matches) != 1:
        raise ValueError(
            f"expected one {event} {field}={value} in repetition "
            f"{repetition}, got {len(matches)}")
    return matches[0]


def validate(rows, repetitions):
    expected_counts = {
        "service-config-rotation-start": repetitions,
        "service-config-rotation-state": repetitions * len(STATES),
        "service-config-rotation-case": repetitions * len(REQUIRED_CASES),
        "service-config-rotation-policy-counter":
            repetitions * len(REQUIRED_COUNTERS),
        "service-config-rotation-summary": repetitions,
    }
    unexpected = [
        row for row in rows if row.get("event") not in expected_counts
    ]
    if unexpected:
        raise ValueError(f"{len(unexpected)} unexpected observations")
    failed = [row for row in rows if row.get("pass") is not True]
    if failed:
        raise ValueError(f"{len(failed)} failed or malformed observations")

    expected_repetitions = set(range(1, repetitions + 1))
    for event, expected_count in expected_counts.items():
        event_rows = [row for row in rows if row.get("event") == event]
        if len(event_rows) != expected_count:
            raise ValueError(
                f"expected {expected_count} {event} rows, "
                f"got {len(event_rows)}")
        if any(row.get("result_level") != "kvm_service_config_rotation"
               for row in event_rows):
            raise ValueError(f"unexpected result_level for {event}")
        if {row.get("repetition") for row in event_rows} != \
                expected_repetitions:
            raise ValueError(f"unexpected repetition set for {event}")

    latency_by_state = defaultdict(list)
    state_rows = {}
    counter_rows = {}
    for repetition in range(1, repetitions + 1):
        states = {}
        physical_hashes = set()
        for state in STATES:
            row = one(
                rows, "service-config-rotation-state",
                repetition, "state", state)
            expected = EXPECTED[state]
            for field, value in expected.items():
                if row.get(field) != value:
                    raise ValueError(
                        f"unexpected {field} for {repetition}:{state}")
            for field in ("logical_sha256", "physical_sha256"):
                digest = row.get(field)
                if not isinstance(digest, str) or len(digest) != 64 or \
                        any(character not in "0123456789abcdef"
                            for character in digest):
                    raise ValueError(
                        f"invalid {field} for {repetition}:{state}")
            if row["logical_sha256"] != row["physical_sha256"]:
                raise ValueError(
                    f"logical/physical hash mismatch for "
                    f"{repetition}:{state}")
            physical_hashes.add(row["physical_sha256"])
            for field in ("master_pid", "worker_before", "worker_after",
                          "latency_ns", "poll_attempts"):
                if type(row.get(field)) is not int:
                    raise ValueError(
                        f"invalid {field} for {repetition}:{state}")
            if row["master_pid"] <= 0 or row["worker_after"] <= 0 or \
                    row["latency_ns"] <= 0 or row["poll_attempts"] <= 0:
                raise ValueError(
                    f"non-positive runtime field for {repetition}:{state}")
            latency_by_state[state].append(row["latency_ns"])
            states[state] = row
            state_rows[(repetition, state)] = row

        if len(physical_hashes) != len(STATES):
            raise ValueError(
                f"physical generations are not distinct in repetition "
                f"{repetition}")
        master_pids = {states[state]["master_pid"] for state in STATES}
        if len(master_pids) != 1:
            raise ValueError(
                f"nginx master changed in repetition {repetition}")
        if states["current"]["worker_before"] != 0:
            raise ValueError("current state must start without an old worker")
        current_worker = states["current"]["worker_after"]
        canary_worker = states["canary"]["worker_after"]
        rollback_worker = states["rollback"]["worker_after"]
        if states["canary"]["worker_before"] != current_worker or \
                canary_worker == current_worker:
            raise ValueError(
                f"canary did not replace the worker in repetition "
                f"{repetition}")
        if states["invalid"]["worker_before"] != canary_worker or \
                states["invalid"]["worker_after"] != canary_worker:
            raise ValueError(
                f"invalid reload changed the live worker in repetition "
                f"{repetition}")
        if states["rollback"]["worker_before"] != canary_worker or \
                rollback_worker == canary_worker:
            raise ValueError(
                f"rollback did not replace the worker in repetition "
                f"{repetition}")

        for case in REQUIRED_CASES:
            row = one(
                rows, "service-config-rotation-case",
                repetition, "case", case)
            if row.get("pass") is not True:
                raise ValueError(
                    f"required case failed: {repetition}:{case}")
        counters = {}
        for counter in REQUIRED_COUNTERS:
            row = one(
                rows, "service-config-rotation-policy-counter",
                repetition, "counter", counter)
            value = row.get("value")
            if type(value) is not int or value <= 0 or \
                    row.get("pass") is not True:
                raise ValueError(
                    f"invalid counter: {repetition}:{counter}")
            counters[counter] = value
            counter_rows[(repetition, counter)] = row
        summary = one(
            rows, "service-config-rotation-summary",
            repetition, "source_system", "kubernetes-atomic-writer+nginx")
        if summary.get("pass") is not True or summary.get("states") != 4 or \
                summary.get("failures") != 0 or \
                summary.get("master_pid") != states["current"]["master_pid"]:
            raise ValueError(
                f"invalid summary in repetition {repetition}")

    expected_state_rows = expected_counts["service-config-rotation-state"]
    observed_state_rows = expected_state_rows

    latency = {}
    for state in STATES:
        values = latency_by_state[state]
        latency[state] = {
            "values_ns": values,
            "minimum_ns": min(values),
            "median_ns": statistics.median(values),
            "p95_ns": percentile(values, 0.95),
            "maximum_ns": max(values),
        }
    correctness = {
        "boots_expected": repetitions,
        "boots_completed": repetitions,
        "states_expected": expected_state_rows,
        "states_completed": observed_state_rows,
        "failed_observations": 0,
        "all_boots_passed": True,
    }
    return correctness, latency, state_rows, counter_rows


def write_csv(path, latency):
    with path.open("w", newline="", encoding="utf-8") as output:
        writer = csv.writer(output)
        writer.writerow(
            ("state", "minimum_ns", "median_ns", "p95_ns", "maximum_ns"))
        for state in STATES:
            row = latency[state]
            writer.writerow((
                state,
                row["minimum_ns"],
                row["median_ns"],
                row["p95_ns"],
                row["maximum_ns"],
            ))


def classify(repetitions):
    if repetitions == 10:
        return {
            "tested_hypothesis": "supported",
            "evidence_role": "formal",
            "scope": "existing-object service configuration generation switch",
        }
    return {
        "tested_hypothesis": "not_tested",
        "evidence_role": "dependency_preflight",
        "scope": "real-path executability only",
    }


def write_report(path, summary):
    correctness = summary["correctness"]
    lines = [
        "# Service Configuration Rotation Result",
        "",
        "## Correctness Gate",
        "",
        f"- Fresh KVM boots: {correctness['boots_completed']}/"
        f"{correctness['boots_expected']}.",
        f"- State transitions: {correctness['states_completed']}/"
        f"{correctness['states_expected']}.",
        "- Current, canary, invalid reload, rollback, default-worker runtime, "
        "lower-object, policy, evidence-capture, and cleanup oracles passed "
        "in every boot.",
        "",
        "## Transition Latency",
        "",
        "Latency is descriptive and is not used for an RQ2 performance claim.",
        "",
        "| State | Min (ms) | Median (ms) | p95 (ms) | Max (ms) |",
        "| --- | ---: | ---: | ---: | ---: |",
    ]
    for state in STATES:
        row = summary["latency"][state]
        values = [
            row["minimum_ns"], row["median_ns"],
            row["p95_ns"], row["maximum_ns"],
        ]
        lines.append(
            f"| {state} | " +
            " | ".join(f"{value / 1_000_000:.3f}" for value in values) +
            " |")
    lines.extend(["", "## Interpretation", ""])
    if summary["verdict"]["evidence_role"] == "formal":
        lines.append(
            "The tested existing-object generation-switch subset is "
            "supported: one logical nginx configuration path selected four "
            "distinct physical generations, nginx retained responsibility "
            "for validation and worker replacement, and the lower objects "
            "remained unchanged.")
    else:
        lines.append(
            "The one-boot preflight establishes only that the real KVM, "
            "policy, nginx, and result path execute. It is not paper evidence "
            "and does not test the formal hypothesis.")
    lines.append("")
    path.write_text("\n".join(lines), encoding="utf-8")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", type=Path, required=True)
    parser.add_argument("--run", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    arguments = parser.parse_args()

    run = json.loads(arguments.run.read_text(encoding="utf-8"))
    matrix = run.get("matrix", {})
    repetitions = matrix.get("repetitions")
    if type(repetitions) is not int or repetitions <= 0:
        raise ValueError("invalid repetition count")
    validate_run(run, repetitions)
    rows = load_jsonl(arguments.input)
    correctness, latency, _, _ = validate(rows, repetitions)
    summary = {
        "schema": "namei_ext.service_config_rotation.summary.v2",
        "source_system": "kubernetes-atomic-writer+nginx",
        "verdict": classify(repetitions),
        "correctness": correctness,
        "latency": latency,
    }
    arguments.output.mkdir(parents=True, exist_ok=False)
    (arguments.output / "summary.json").write_text(
        json.dumps(summary, indent=2, sort_keys=True) + "\n",
        encoding="utf-8")
    write_csv(arguments.output / "summary.csv", latency)
    write_report(arguments.output / "report.md", summary)


if __name__ == "__main__":
    main()
