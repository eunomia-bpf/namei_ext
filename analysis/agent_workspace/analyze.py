#!/usr/bin/env python3

import argparse
import csv
import json
import math
import random
import statistics
from collections import defaultdict
from pathlib import Path

import matplotlib.pyplot as plt


CONDITIONS = ("namei_ext", "fuse")
METRICS = (
    "lifecycle",
    "stat",
    "open",
    "access",
    "readdir",
    "exec",
)
SAMPLE_COUNTS = {
    "lifecycle": 1000,
    "stat": 1000,
    "open": 1000,
    "access": 1000,
    "readdir": 1000,
    "exec": 1000,
}
METRIC_NAMES = {
    ("namei_ext", "lifecycle"): "namei_ext_lifecycle_ns",
    ("namei_ext", "stat"): "namei_ext_stat_main_ns",
    ("namei_ext", "open"): "namei_ext_open_main_ns",
    ("namei_ext", "access"): "namei_ext_access_main_ns",
    ("namei_ext", "readdir"): "namei_ext_readdir_ws_ns",
    ("namei_ext", "exec"): "namei_ext_exec_tool_ns",
    ("fuse", "lifecycle"): "fuse_lifecycle_ns",
    ("fuse", "stat"): "fuse_stat_main_ns",
    ("fuse", "open"): "fuse_open_main_ns",
    ("fuse", "access"): "fuse_access_main_ns",
    ("fuse", "readdir"): "fuse_readdir_ws_ns",
    ("fuse", "exec"): "fuse_exec_tool_ns",
}
CONTROL_METRICS = ("lower_stat", "lower_readdir")
CONTROL_SAMPLE_COUNTS = {
    "lower_stat": 1000,
    "lower_readdir": 1000,
}
CONTROL_NAMES = {
    ("namei_ext", "lower_stat"): "nohook_stat_base_main_ns",
    ("namei_ext", "lower_readdir"): "nohook_readdir_base_ns",
    ("fuse", "lower_stat"): "fuse_nohook_stat_base_main_ns",
    ("fuse", "lower_readdir"): "fuse_nohook_readdir_base_ns",
}
SUMMARY_CASES = {
    "namei_ext": "agent_workspace_rq2_summary",
    "fuse": "fuse_agent_workspace_rq2_summary",
}
QUANTILES = {
    "p50": 0.50,
    "p95": 0.95,
    "p99": 0.99,
}
FUSE_RESOURCE_FIELDS = (
    "callback_requests",
    "cpu_runtime_ns",
    "runqueue_wait_ns",
    "timeslices",
    "voluntary_context_switches",
    "involuntary_context_switches",
    "threads_before",
    "threads_after",
)
FUSE_CALLBACK_COUNTERS = (
    "getattr",
    "readdir",
    "open",
    "create",
    "read",
    "write",
    "readlink",
    "unlink",
    "rename",
    "mknod",
    "truncate",
    "release",
)
FUSE_COUNTERS = FUSE_CALLBACK_COUNTERS + (
    "request_total",
    "handle_opened",
    "release_completed",
    "hidden_lookup",
    "hidden_readdir",
    "invalidate_attempt",
    "invalidate_error",
)
BOOTSTRAP_SAMPLES = 10000


def percentile(sorted_values, probability):
    position = (len(sorted_values) - 1) * probability
    lower = math.floor(position)
    upper = math.ceil(position)
    if lower == upper:
        return sorted_values[lower]
    weight = position - lower
    return (sorted_values[lower] * (1 - weight) +
            sorted_values[upper] * weight)


def sample_quantile(values, probability):
    return percentile(sorted(values), probability)


def bootstrap_median_ci(values, rng):
    estimates = []
    if not values:
        raise ValueError("cannot bootstrap an empty sample")
    for _ in range(BOOTSTRAP_SAMPLES):
        sample = [values[rng.randrange(len(values))]
                  for _ in range(len(values))]
        estimates.append(statistics.median(sample))
    estimates.sort()
    return percentile(estimates, 0.025), percentile(estimates, 0.975)


def load_json(path):
    with path.open(encoding="utf-8") as source:
        return json.load(source)


def load_rows(path):
    rows = []
    with path.open(encoding="utf-8") as source:
        for line_number, line in enumerate(source, 1):
            try:
                row = json.loads(line)
            except json.JSONDecodeError as error:
                raise ValueError(
                    f"{path}:{line_number}: invalid JSON: {error}") from error
            if row.get("condition") not in CONDITIONS:
                raise ValueError(
                    f"{path}:{line_number}: missing or invalid condition")
            if type(row.get("repetition")) is not int:
                raise ValueError(
                    f"{path}:{line_number}: missing repetition")
            rows.append(row)
    return rows


def load_required_oracles(path):
    oracles = []
    with path.open(encoding="utf-8") as source:
        for line_number, line in enumerate(source, 1):
            text = line.strip()
            if not text or text.startswith("#"):
                continue
            fields = text.split()
            if len(fields) != 3 or fields[0] not in CONDITIONS or \
                    fields[1] not in ("case", "manifest"):
                raise ValueError(
                    f"{path}:{line_number}: invalid required oracle")
            oracle = tuple(fields)
            if oracle in oracles:
                raise ValueError(
                    f"{path}:{line_number}: duplicate required oracle")
            oracles.append(oracle)
    if not oracles:
        raise ValueError("required oracle list is empty")
    return tuple(oracles)


def load_launch_order(path, repetitions):
    rows = []
    with path.open(encoding="utf-8") as source:
        for line_number, line in enumerate(source, 1):
            try:
                row = json.loads(line)
            except json.JSONDecodeError as error:
                raise ValueError(
                    f"{path}:{line_number}: invalid JSON: {error}") from error
            rows.append(row)
    if len(rows) != 2 * repetitions:
        raise ValueError("launch-order row count does not match matrix")
    first_conditions = {}
    for index, row in enumerate(rows):
        repetition = index // 2 + 1
        expected = ("namei_ext", "fuse") if repetition % 2 else \
            ("fuse", "namei_ext")
        if row.get("schema") != \
                "namei_ext.agent_workspace_rq2.launch_order.v1" or \
                row.get("order_index") != index + 1 or \
                row.get("repetition") != repetition or \
                row.get("condition") != expected[index % 2] or \
                not row.get("host_started_at") or \
                not row.get("host_completed_at"):
            raise ValueError(f"invalid launch-order row {index + 1}")
        if index % 2 == 0:
            first_conditions[repetition] = row["condition"]
    return first_conditions


def load_plan(path):
    run = load_json(path)
    if run.get("schema") != "namei_ext.run.v2" or \
            run.get("protocol_schema") != \
            "namei_ext.agent_workspace_rq2.protocol.v2" or \
            run.get("suite") != "agent-workspace-rq2" or \
            run.get("layout") != "paired-boot-matrix" or \
            run.get("status") not in ("running", "completed") or \
            run.get("failed_at") is not None:
        raise ValueError("run is not a valid Agent workspace RQ2 matrix")
    matrix = run.get("matrix", {})
    if tuple(matrix.get("conditions", ())) != CONDITIONS:
        raise ValueError("unexpected condition matrix")
    repetitions = matrix.get("repetitions")
    lifecycle_samples = matrix.get("lifecycle_samples")
    if type(repetitions) is not int or repetitions < 1:
        raise ValueError("invalid repetition count")
    if lifecycle_samples != SAMPLE_COUNTS["lifecycle"]:
        raise ValueError("unexpected lifecycle sample count")
    if matrix.get("sample_counts") != SAMPLE_COUNTS:
        raise ValueError("unexpected per-boot sample counts")
    if matrix.get("order") != "alternating":
        raise ValueError("unexpected condition order")
    if type(matrix.get("kvm_cpus")) is not int or \
            matrix.get("kvm_cpus") < 1 or \
            not matrix.get("host_cpu_pin"):
        raise ValueError("missing KVM CPU pin declaration")
    return repetitions


def validate_samples(grouped, indexed, repetition, condition, metric,
                     metric_name, expected):
    samples = grouped[(repetition, condition, metric_name)]
    if len(samples) != expected:
        raise ValueError(
            f"wrong {metric} sample count for {repetition}:{condition}")
    iterations = sorted(row.get("iteration") for row in samples)
    if iterations != list(range(expected)):
        raise ValueError(
            f"non-contiguous {metric} iterations for "
            f"{repetition}:{condition}")
    values = [row.get("value") for row in samples]
    if any(row.get("pass") is not True for row in samples) or \
            any(type(value) is not int or value <= 0 for value in values):
        raise ValueError(
            f"invalid {metric} value for {repetition}:{condition}")
    indexed[(repetition, condition, metric)] = values


def validate_oracles(boot_rows, condition, required_oracles, repetition):
    expected = [
        (kind, name)
        for oracle_condition, kind, name in required_oracles
        if oracle_condition == condition
    ]
    for kind, name in expected:
        matches = [
            row for row in boot_rows
            if row.get(kind) == name
        ]
        if len(matches) != 1 or matches[0].get("pass") is not True:
            raise ValueError(
                f"missing required {kind} {name}: "
                f"{repetition}:{condition}")
    return len(expected)


def validate(rows, repetitions, required_oracles):
    grouped = defaultdict(list)
    expected_boots = {
        (repetition, condition)
        for repetition in range(1, repetitions + 1)
        for condition in CONDITIONS
    }
    observed_boots = {(row["repetition"], row["condition"]) for row in rows}
    if observed_boots != expected_boots:
        raise ValueError("observed boot keys do not match the declared matrix")

    failed_rows = [row for row in rows if row.get("pass") is not True]
    if failed_rows:
        row = failed_rows[0]
        raise ValueError(
            f"failed observation in boot "
            f"{row['repetition']}:{row['condition']}")
    for row in rows:
        if row.get("event") in (
                "agent-workspace-sample",
                "agent-workspace-lifecycle-sample"):
            grouped[(row["repetition"], row["condition"],
                     row.get("metric"))].append(row)

    indexed = {}
    controls = {}
    fuse_resources = {}
    fuse_counters = {}
    required_oracle_observations = 0
    passing_summaries = 0
    for repetition in range(1, repetitions + 1):
        for condition in CONDITIONS:
            boot_rows = [
                row for row in rows
                if row["repetition"] == repetition and
                row["condition"] == condition
            ]
            summaries = [
                row for row in boot_rows
                if row.get("case") == SUMMARY_CASES[condition]
            ]
            if len(summaries) != 1 or summaries[0].get("pass") is not True:
                raise ValueError(
                    f"missing passing summary: {repetition}:{condition}")
            passing_summaries += 1
            required_oracle_observations += validate_oracles(
                boot_rows, condition, required_oracles, repetition)

            for metric in METRICS:
                validate_samples(
                    grouped, indexed, repetition, condition, metric,
                    METRIC_NAMES[(condition, metric)],
                    SAMPLE_COUNTS[metric])
            for metric in CONTROL_METRICS:
                validate_samples(
                    grouped, controls, repetition, condition, metric,
                    CONTROL_NAMES[(condition, metric)],
                    CONTROL_SAMPLE_COUNTS[metric])

            if condition != "fuse":
                continue
            resources = [
                row for row in boot_rows
                if row.get("event") == "agent-workspace-fuse-resource"
            ]
            if len(resources) != 1 or \
                    resources[0].get("pass") is not True:
                raise ValueError(
                    f"invalid FUSE resource window: {repetition}")
            resource = resources[0]
            for field in FUSE_RESOURCE_FIELDS:
                if type(resource.get(field)) is not int or \
                        resource[field] < 0:
                    raise ValueError(
                        f"invalid FUSE resource {field}: {repetition}")
            if resource["callback_requests"] <= 0 or \
                    resource["cpu_runtime_ns"] <= 0 or \
                    resource.get("threads_before", 0) < 2 or \
                    resource.get("threads_before") != \
                    resource.get("threads_after"):
                raise ValueError(
                    f"incomplete FUSE resource window: {repetition}")
            fuse_resources[repetition] = resource

            options = [
                row for row in boot_rows
                if row.get("case") == "fuse_options_recorded"
            ]
            required = (
                "attr_timeout=3600",
                "entry_timeout=3600",
                "negative_timeout=3600",
                "default_permissions=true",
                "kernel_cache=false",
            )
            if len(options) != 1 or not all(
                    token in options[0].get("detail", "")
                    for token in required):
                raise ValueError(f"wrong FUSE options: {repetition}")

            counter_rows = [
                row for row in boot_rows
                if row.get("event") == "agent-workspace-fuse-counter"
            ]
            counter_values = {}
            for counter in FUSE_COUNTERS:
                matches = [
                    row for row in counter_rows
                    if row.get("counter") == counter
                ]
                if len(matches) != 1 or \
                        matches[0].get("pass") is not True or \
                        type(matches[0].get("value")) is not int or \
                        matches[0]["value"] < 0:
                    raise ValueError(
                        f"invalid FUSE counter {counter}: {repetition}")
                counter_values[counter] = matches[0]["value"]
            if counter_values["request_total"] <= 0 or \
                    counter_values["request_total"] != sum(
                        counter_values[counter]
                        for counter in FUSE_CALLBACK_COUNTERS) or \
                    counter_values["release"] <= 0 or \
                    counter_values["release"] != \
                    counter_values["handle_opened"] or \
                    counter_values["release_completed"] != \
                    counter_values["handle_opened"] or \
                    counter_values["invalidate_attempt"] != 6 or \
                    counter_values["invalidate_error"] != 0:
                raise ValueError(
                    f"invalid FUSE engagement counters: {repetition}")
            fuse_counters[repetition] = counter_values

    correctness = {
        "boots_expected": 2 * repetitions,
        "boots_with_passing_summary": passing_summaries,
        "failed_observations": 0,
        "lifecycle_samples_expected":
            2 * repetitions * SAMPLE_COUNTS["lifecycle"],
        "lifecycle_samples_observed": sum(
            len(indexed[(repetition, condition, "lifecycle")])
            for repetition in range(1, repetitions + 1)
            for condition in CONDITIONS),
        "required_oracles_per_matrix":
            repetitions * len(required_oracles),
        "required_oracles_observed": required_oracle_observations,
        "fuse_epoch_invalidations_expected": 6 * repetitions,
        "fuse_epoch_invalidations_observed": sum(
            counters["invalidate_attempt"]
            for counters in fuse_counters.values()),
        "fuse_epoch_invalidation_errors": sum(
            counters["invalidate_error"]
            for counters in fuse_counters.values()),
    }
    if correctness["required_oracles_per_matrix"] != \
            correctness["required_oracles_observed"]:
        raise ValueError("required oracle accounting mismatch")
    return indexed, controls, fuse_resources, fuse_counters, correctness


def summarize_metric(indexed, repetitions, metric, rng, first_conditions):
    quantiles = {}
    for quantile_name, probability in QUANTILES.items():
        boot_values = {condition: [] for condition in CONDITIONS}
        ratios = []
        for repetition in range(1, repetitions + 1):
            for condition in CONDITIONS:
                boot_values[condition].append(sample_quantile(
                    indexed[(repetition, condition, metric)],
                    probability))
            ratios.append(
                boot_values["fuse"][-1] /
                boot_values["namei_ext"][-1])
        low, high = bootstrap_median_ci(ratios, rng)
        quantiles[quantile_name] = {
            "namei_ext_boot_ns": boot_values["namei_ext"],
            "fuse_boot_ns": boot_values["fuse"],
            "paired_ratios": ratios,
            "ratio_median": statistics.median(ratios),
            "ci_low": low,
            "ci_high": high,
        }
    p50_ratios = quantiles["p50"]["paired_ratios"]
    order_groups = {
        "namei_ext_first": [],
        "fuse_first": [],
    }
    for repetition, ratio in enumerate(p50_ratios, 1):
        order_groups[
            f"{first_conditions[repetition]}_first"].append(ratio)
    quantiles["p50"]["order_effect"] = {
        name: {
            "paired_ratios": values,
            "median": statistics.median(values),
        }
        for name, values in order_groups.items()
    }
    return {"metric": metric, "quantiles": quantiles}


def summarize(indexed, repetitions, seed, first_conditions):
    rng = random.Random(seed)
    return [
        summarize_metric(
            indexed, repetitions, metric, rng, first_conditions)
        for metric in METRICS
    ]


def summarize_controls(controls, repetitions, seed, first_conditions):
    rng = random.Random(seed ^ 0x5A17)
    summaries = []
    for metric in CONTROL_METRICS:
        row = summarize_metric(
            controls, repetitions, metric, rng, first_conditions)
        summaries.append(row)
    return summaries


def summarize_fields(rows_by_repetition, fields):
    summaries = {}
    for field in fields:
        values = [
            rows_by_repetition[repetition][field]
            for repetition in sorted(rows_by_repetition)
        ]
        summaries[field] = {
            "per_boot": values,
            "median": statistics.median(values),
            "minimum": min(values),
            "maximum": max(values),
        }
    return summaries


def classify(summaries):
    lifecycle = next(row for row in summaries
                     if row["metric"] == "lifecycle")
    decision = lifecycle["quantiles"]["p50"]
    if decision["ci_low"] > 1:
        verdict = "supported"
    elif decision["ci_high"] < 1:
        verdict = "contradicted"
    else:
        verdict = "inconclusive"
    return {
        "tested_hypothesis": verdict,
        "decision_metric": "complete workspace lifecycle p50",
        "equivalence_claimed": False,
        "decision_rule":
            "supported iff CI is wholly above 1; contradicted iff wholly "
            "below 1; otherwise inconclusive",
    }


def write_csv(path, summaries):
    fields = (
        "metric",
        "quantile",
        "namei_ext_median_boot_ns",
        "fuse_median_boot_ns",
        "fuse_over_namei_ext_median",
        "ci_low",
        "ci_high",
        "paired_ratios",
    )
    with path.open("w", newline="", encoding="utf-8") as output:
        writer = csv.DictWriter(output, fieldnames=fields)
        writer.writeheader()
        for row in summaries:
            for quantile_name, result in row["quantiles"].items():
                writer.writerow({
                    "metric": row["metric"],
                    "quantile": quantile_name,
                    "namei_ext_median_boot_ns": statistics.median(
                        result["namei_ext_boot_ns"]),
                    "fuse_median_boot_ns": statistics.median(
                        result["fuse_boot_ns"]),
                    "fuse_over_namei_ext_median":
                        result["ratio_median"],
                    "ci_low": result["ci_low"],
                    "ci_high": result["ci_high"],
                    "paired_ratios": json.dumps(result["paired_ratios"]),
                })


def format_latency(value):
    if value >= 1_000_000:
        return f"{value / 1_000_000:.2f} ms"
    if value >= 1_000:
        return f"{value / 1_000:.2f} us"
    return f"{value:.0f} ns"


def append_latency_table(lines, summaries):
    lines.extend([
        "| Metric | Quantile | namei_ext | FUSE | "
        "FUSE / namei_ext (95% CI) |",
        "| --- | --- | ---: | ---: | ---: |",
    ])
    for row in summaries:
        for quantile_name in QUANTILES:
            result = row["quantiles"][quantile_name]
            lines.append(
                f"| {row['metric']} | {quantile_name} | "
                f"{format_latency(statistics.median(result['namei_ext_boot_ns']))} | "
                f"{format_latency(statistics.median(result['fuse_boot_ns']))} | "
                f"{result['ratio_median']:.2f}x "
                f"[{result['ci_low']:.2f}, {result['ci_high']:.2f}] |")


def write_report(path, summaries, controls, resources, counters, correctness,
                 verdict, repetitions, seed):
    lines = [
        "# Agent Workspace RQ2 Result",
        "",
        f"- Paired independent-boot blocks: {repetitions}",
        f"- Bootstrap resamples: {BOOTSTRAP_SAMPLES}",
        f"- Bootstrap seed: {seed}",
        f"- Predeclared lifecycle verdict: "
        f"**{verdict['tested_hypothesis']}**",
        "",
        "## Correctness Gate",
        "",
        "| Gate | Expected | Observed |",
        "| --- | ---: | ---: |",
        f"| completed boots | {correctness['boots_expected']} | "
        f"{correctness['boots_with_passing_summary']} |",
        f"| passing lifecycle samples | "
        f"{correctness['lifecycle_samples_expected']} | "
        f"{correctness['lifecycle_samples_observed']} |",
        f"| required source-derived oracles | "
        f"{correctness['required_oracles_per_matrix']} | "
        f"{correctness['required_oracles_observed']} |",
        f"| FUSE epoch invalidations | "
        f"{correctness['fuse_epoch_invalidations_expected']} | "
        f"{correctness['fuse_epoch_invalidations_observed']} |",
        f"| FUSE invalidation errors | 0 | "
        f"{correctness['fuse_epoch_invalidation_errors']} |",
        f"| failed observations | 0 | "
        f"{correctness['failed_observations']} |",
        "",
        "## Latency",
        "",
    ]
    append_latency_table(lines, summaries)
    lines.extend([
        "",
        "The lifecycle p50 row is the predeclared decision metric. Other "
        "quantiles and operations decompose the mechanism and do not redefine "
        "the verdict. An interval containing one is inconclusive because no "
        "equivalence margin was registered.",
        "",
        "## Lower-Filesystem Controls",
        "",
    ])
    append_latency_table(lines, controls)
    lines.extend([
        "",
        "These controls bypass both namei_ext and FUSE. Their paired ratios "
        "show host/guest drift between the two independent boots in each "
        "block.",
        "",
        "## Order Diagnostic",
        "",
        "| Metric | namei_ext-first blocks | FUSE-first blocks |",
        "| --- | ---: | ---: |",
    ])
    for row in summaries:
        order = row["quantiles"]["p50"]["order_effect"]
        lines.append(
            f"| {row['metric']} | "
            f"{order['namei_ext_first']['median']:.2f}x | "
            f"{order['fuse_first']['median']:.2f}x |")
    lines.extend([
        "",
        "These are descriptive medians of the paired p50 ratios for the five "
        "odd and five even blocks. They diagnose a condition-order effect; "
        "they are not an additional hypothesis test.",
        "",
        "## FUSE Daemon Resource Window",
        "",
        "| Field | Median per boot | Range |",
        "| --- | ---: | ---: |",
    ])
    for field in FUSE_RESOURCE_FIELDS:
        result = resources[field]
        unit = " ns" if field.endswith("_ns") else ""
        lines.append(
            f"| {field} | {result['median']:.0f}{unit} | "
            f"{result['minimum']}{unit}--{result['maximum']}{unit} |")
    lines.extend([
        "",
        "CPU runtime and run-queue wait are high-resolution sums across all "
        "FUSE daemon threads from `/proc/PID/task/*/schedstat`. Callback "
        "requests count every implemented high-level FUSE operation in the "
        "measurement window.",
        "",
        "## Operation And Callback Counts",
        "",
        "| Timed operation | Samples per boot | Samples in matrix |",
        "| --- | ---: | ---: |",
    ])
    for metric in METRICS:
        lines.append(
            f"| {metric} | {SAMPLE_COUNTS[metric]} | "
            f"{SAMPLE_COUNTS[metric] * 2 * repetitions} |")
    lines.extend([
        "",
        "| FUSE counter | Median per boot | Range |",
        "| --- | ---: | ---: |",
    ])
    for counter in FUSE_COUNTERS:
        result = counters[counter]
        lines.append(
            f"| {counter} | {result['median']:.0f} | "
            f"{result['minimum']}--{result['maximum']} |")
    lines.extend([
        "",
        "The operation-level result is intentionally mixed: cache-hit "
        "`stat` or `access` may be served from FUSE kernel caches, while "
        "operations that engage the daemon carry a larger cost. The paper "
        "claim must therefore use the complete lifecycle decision metric and "
        "show this decomposition, not claim that namei_ext wins every "
        "individual operation.",
        "",
    ])
    path.write_text("\n".join(lines), encoding="utf-8")


def write_plot(output_prefix, summaries):
    visible = [row for row in summaries if row["metric"] != "exec"]
    figure, axis = plt.subplots(figsize=(7.2, 3.8))
    positions = list(range(len(visible)))
    for position, row in zip(positions, visible):
        result = row["quantiles"]["p50"]
        axis.scatter(result["paired_ratios"],
                     [position] * len(result["paired_ratios"]),
                     color="#5B6770", alpha=0.65, s=20, zorder=2)
        estimate = result["ratio_median"]
        axis.errorbar(
            estimate, position,
            xerr=[[estimate - result["ci_low"]],
                  [result["ci_high"] - estimate]],
            fmt="o", color="#B13A2F", capsize=4, linewidth=2, zorder=3)
    axis.axvline(1, color="#222222", linestyle="--", linewidth=1)
    axis.set_yticks(positions, [row["metric"] for row in visible])
    axis.set_xlabel("FUSE / namei_ext p50 latency ratio")
    axis.set_title("Agent workspace: paired per-boot medians")
    axis.grid(axis="x", color="#D9D9D9", linewidth=0.8)
    axis.invert_yaxis()
    figure.tight_layout()
    figure.savefig(output_prefix.with_suffix(".png"), dpi=200)
    figure.savefig(output_prefix.with_suffix(".pdf"))
    plt.close(figure)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", type=Path, required=True)
    parser.add_argument("--run", type=Path, required=True)
    parser.add_argument("--launch-order", type=Path, required=True)
    parser.add_argument("--required-oracles", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--seed", type=int, required=True)
    args = parser.parse_args()

    repetitions = load_plan(args.run)
    first_conditions = load_launch_order(args.launch_order, repetitions)
    rows = load_rows(args.input)
    required_oracles = load_required_oracles(args.required_oracles)
    indexed, controls, fuse_resources, fuse_counters, correctness = validate(
        rows, repetitions, required_oracles)
    summaries = summarize(
        indexed, repetitions, args.seed, first_conditions)
    control_summaries = summarize_controls(
        controls, repetitions, args.seed, first_conditions)
    resource_summaries = summarize_fields(
        fuse_resources, FUSE_RESOURCE_FIELDS)
    counter_summaries = summarize_fields(
        fuse_counters, FUSE_COUNTERS)
    verdict = classify(summaries)

    args.output.mkdir(parents=True, exist_ok=False)
    payload = {
        "schema": "namei_ext.agent_workspace_rq2.summary.v2",
        "repetitions": repetitions,
        "bootstrap_samples": BOOTSTRAP_SAMPLES,
        "bootstrap_seed": args.seed,
        "first_condition_by_repetition": first_conditions,
        "verdict": verdict,
        "correctness": correctness,
        "metrics": summaries,
        "lower_filesystem_controls": control_summaries,
        "fuse_resources": resource_summaries,
        "fuse_counters": counter_summaries,
    }
    (args.output / "summary.json").write_text(
        json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    write_csv(args.output / "summary.csv", summaries)
    write_report(
        args.output / "report.md", summaries, control_summaries,
        resource_summaries, counter_summaries, correctness, verdict,
        repetitions, args.seed)
    write_plot(args.output / "latency-ratios", summaries)


if __name__ == "__main__":
    main()
