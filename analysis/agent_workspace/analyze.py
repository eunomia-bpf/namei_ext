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
    "lifecycle": 20,
    "stat": 100,
    "open": 100,
    "access": 100,
    "readdir": 50,
    "exec": 20,
}
BOOTSTRAP_SAMPLES = 10000
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
SUMMARY_CASES = {
    "namei_ext": "agent_workspace_rq2_summary",
    "fuse": "fuse_agent_workspace_rq2_summary",
}


def percentile(sorted_values, probability):
    position = (len(sorted_values) - 1) * probability
    lower = math.floor(position)
    upper = math.ceil(position)
    if lower == upper:
        return sorted_values[lower]
    weight = position - lower
    return (sorted_values[lower] * (1 - weight) +
            sorted_values[upper] * weight)


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


def load_plan(path):
    run = load_json(path)
    if run.get("schema") != "namei_ext.run.v2" or \
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
    return repetitions


def validate(rows, repetitions):
    grouped = defaultdict(list)
    expected_boots = {
        (repetition, condition)
        for repetition in range(1, repetitions + 1)
        for condition in CONDITIONS
    }
    observed_boots = {(row["repetition"], row["condition"]) for row in rows}
    if observed_boots != expected_boots:
        raise ValueError("observed boot keys do not match the declared matrix")

    for row in rows:
        if row.get("pass") is False:
            raise ValueError(
                f"failed observation in boot "
                f"{row['repetition']}:{row['condition']}")
        if row.get("event") in (
                "agent-workspace-sample",
                "agent-workspace-lifecycle-sample"):
            grouped[(row["repetition"], row["condition"],
                     row.get("metric"))].append(row)

    indexed = {}
    for repetition in range(1, repetitions + 1):
        for condition in CONDITIONS:
            boot_rows = [
                row for row in rows
                if row["repetition"] == repetition and
                row["condition"] == condition
            ]
            summaries = [
                row for row in boot_rows
                if row.get("case") ==
                SUMMARY_CASES[condition]
            ]
            if len(summaries) != 1 or summaries[0].get("pass") is not True:
                raise ValueError(
                    f"missing passing summary: {repetition}:{condition}")
            for metric in METRICS:
                metric_name = METRIC_NAMES[(condition, metric)]
                samples = grouped[(repetition, condition, metric_name)]
                if len(samples) != SAMPLE_COUNTS[metric]:
                    raise ValueError(
                        f"wrong {metric} sample count for "
                        f"{repetition}:{condition}")
                iterations = sorted(row.get("iteration") for row in samples)
                if iterations != list(range(SAMPLE_COUNTS[metric])):
                    raise ValueError(
                        f"non-contiguous {metric} iterations for "
                        f"{repetition}:{condition}")
                values = [row.get("value") for row in samples]
                if any(type(value) is not int or value <= 0
                       for value in values):
                    raise ValueError(
                        f"invalid {metric} value for "
                        f"{repetition}:{condition}")
                indexed[(repetition, condition, metric)] = values

            if condition == "fuse":
                resources = [
                    row for row in boot_rows
                    if row.get("event") ==
                    "agent-workspace-fuse-resource"
                ]
                if len(resources) != 1 or \
                        resources[0].get("pass") is not True or \
                        resources[0].get("requests", 0) <= 0:
                    raise ValueError(
                        f"invalid FUSE resource window: {repetition}")
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
                    raise ValueError(
                        f"wrong FUSE options: {repetition}")
                attempts = [
                    row for row in boot_rows
                    if row.get("counter") == "invalidate_attempt"
                ]
                errors = [
                    row for row in boot_rows
                    if row.get("counter") == "invalidate_error"
                ]
                if len(attempts) != 1 or attempts[0].get("value") != 5 or \
                        len(errors) != 1 or errors[0].get("value") != 0:
                    raise ValueError(
                        f"invalid FUSE invalidation counters: {repetition}")
    return indexed


def summarize(indexed, repetitions, seed):
    rng = random.Random(seed)
    summaries = []
    for metric in METRICS:
        boot_medians = {condition: [] for condition in CONDITIONS}
        ratios = []
        for repetition in range(1, repetitions + 1):
            for condition in CONDITIONS:
                boot_medians[condition].append(statistics.median(
                    indexed[(repetition, condition, metric)]))
            ratios.append(
                boot_medians["fuse"][-1] /
                boot_medians["namei_ext"][-1])
        low, high = bootstrap_median_ci(ratios, rng)
        summaries.append({
            "metric": metric,
            "namei_ext_boot_medians_ns": boot_medians["namei_ext"],
            "fuse_boot_medians_ns": boot_medians["fuse"],
            "paired_ratios": ratios,
            "fuse_over_namei_ext_median": statistics.median(ratios),
            "ci_low": low,
            "ci_high": high,
        })
    return summaries


def classify(summaries):
    lifecycle = next(row for row in summaries
                     if row["metric"] == "lifecycle")
    if lifecycle["ci_low"] > 1:
        verdict = "supported"
    elif lifecycle["ci_high"] < 1:
        verdict = "contradicted"
    else:
        verdict = "inconclusive"
    return {
        "tested_hypothesis": verdict,
        "decision_metric": "complete workspace lifecycle",
        "equivalence_claimed": False,
        "decision_rule":
            "supported iff CI is wholly above 1; contradicted iff wholly "
            "below 1; otherwise inconclusive",
    }


def write_csv(path, summaries):
    fields = (
        "metric",
        "namei_ext_median_ns",
        "fuse_median_ns",
        "fuse_over_namei_ext_median",
        "ci_low",
        "ci_high",
        "paired_ratios",
    )
    with path.open("w", newline="", encoding="utf-8") as output:
        writer = csv.DictWriter(output, fieldnames=fields)
        writer.writeheader()
        for row in summaries:
            writer.writerow({
                "metric": row["metric"],
                "namei_ext_median_ns": statistics.median(
                    row["namei_ext_boot_medians_ns"]),
                "fuse_median_ns": statistics.median(
                    row["fuse_boot_medians_ns"]),
                "fuse_over_namei_ext_median":
                    row["fuse_over_namei_ext_median"],
                "ci_low": row["ci_low"],
                "ci_high": row["ci_high"],
                "paired_ratios": json.dumps(row["paired_ratios"]),
            })


def write_report(path, summaries, verdict, repetitions, seed):
    lines = [
        "# Agent Workspace RQ2 Result",
        "",
        f"- Paired independent-boot blocks: {repetitions}",
        f"- Bootstrap resamples: {BOOTSTRAP_SAMPLES}",
        f"- Bootstrap seed: {seed}",
        f"- Predeclared lifecycle verdict: "
        f"**{verdict['tested_hypothesis']}**",
        "",
        "| Metric | namei_ext median | FUSE median | "
        "FUSE / namei_ext (95% CI) |",
        "| --- | ---: | ---: | ---: |",
    ]
    for row in summaries:
        lines.append(
            f"| {row['metric']} | "
            f"{statistics.median(row['namei_ext_boot_medians_ns']) / 1000:.2f} us | "
            f"{statistics.median(row['fuse_boot_medians_ns']) / 1000:.2f} us | "
            f"{row['fuse_over_namei_ext_median']:.2f}x "
            f"[{row['ci_low']:.2f}, {row['ci_high']:.2f}] |")
    lines.extend([
        "",
        "The lifecycle row is the predeclared decision metric. The remaining "
        "rows decompose the mechanism and do not redefine the verdict. An "
        "interval containing one is inconclusive because no equivalence "
        "margin was registered.",
        "",
    ])
    path.write_text("\n".join(lines), encoding="utf-8")


def write_plot(output_prefix, summaries):
    visible = [row for row in summaries if row["metric"] != "exec"]
    figure, axis = plt.subplots(figsize=(7.2, 3.8))
    positions = list(range(len(visible)))
    for position, row in zip(positions, visible):
        axis.scatter(row["paired_ratios"],
                     [position] * len(row["paired_ratios"]),
                     color="#5B6770", alpha=0.65, s=20, zorder=2)
        estimate = row["fuse_over_namei_ext_median"]
        axis.errorbar(
            estimate, position,
            xerr=[[estimate - row["ci_low"]],
                  [row["ci_high"] - estimate]],
            fmt="o", color="#B13A2F", capsize=4, linewidth=2, zorder=3)
    axis.axvline(1, color="#222222", linestyle="--", linewidth=1)
    axis.set_yticks(positions, [row["metric"] for row in visible])
    axis.set_xlabel("FUSE / namei_ext latency ratio")
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
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--seed", type=int, required=True)
    args = parser.parse_args()

    repetitions = load_plan(args.run)
    rows = load_rows(args.input)
    indexed = validate(rows, repetitions)
    summaries = summarize(indexed, repetitions, args.seed)
    verdict = classify(summaries)

    args.output.mkdir(parents=True, exist_ok=False)
    payload = {
        "repetitions": repetitions,
        "bootstrap_samples": BOOTSTRAP_SAMPLES,
        "bootstrap_seed": args.seed,
        "verdict": verdict,
        "metrics": summaries,
    }
    (args.output / "summary.json").write_text(
        json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    write_csv(args.output / "summary.csv", summaries)
    write_report(args.output / "report.md", summaries, verdict,
                 repetitions, args.seed)
    write_plot(args.output / "latency-ratios", summaries)


if __name__ == "__main__":
    main()
