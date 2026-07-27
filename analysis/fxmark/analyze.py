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


CONDITIONS = ("stock", "unattached", "pass", "select", "fuse")
TYPES = ("MRPL", "MRPM", "MRPH")
WORKERS = (1, 2, 4)
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


def bootstrap_median_ci(values, rng):
    if not values:
        raise ValueError("cannot bootstrap an empty sample")
    estimates = []
    for _ in range(BOOTSTRAP_SAMPLES):
        sample = [values[rng.randrange(len(values))]
                  for _ in range(len(values))]
        estimates.append(statistics.median(sample))
    estimates.sort()
    return percentile(estimates, 0.025), percentile(estimates, 0.975)


def load_rows(path):
    rows = []
    with path.open(encoding="utf-8") as source:
        for line_number, line in enumerate(source, 1):
            try:
                row = json.loads(line)
            except json.JSONDecodeError as error:
                raise ValueError(
                    f"{path}:{line_number}: invalid JSON: {error}") from error
            if row.get("event") != "fxmark-cell":
                raise ValueError(
                    f"{path}:{line_number}: unexpected event")
            rows.append(row)
    return rows


def validate(rows, repetitions):
    expected_count = repetitions * len(CONDITIONS) * len(TYPES) * len(WORKERS)
    if len(rows) != expected_count:
        raise ValueError(f"expected {expected_count} rows, found {len(rows)}")
    indexed = {}
    for row in rows:
        key = (row["repetition"], row["condition"], row["type"],
               row["workers"])
        if key in indexed:
            raise ValueError(f"duplicate cell: {key}")
        if not row["pass"]:
            raise ValueError(f"failed cell: {key}")
        if row["condition"] not in CONDITIONS:
            raise ValueError(f"unknown condition: {key}")
        if row["type"] not in TYPES or row["workers"] not in WORKERS:
            raise ValueError(f"unplanned workload: {key}")
        if row.get("leader_cgroup_verified") is not True:
            raise ValueError(f"unverified benchmark cgroup: {key}")
        if row["condition"] in ("pass", "select"):
            if row.get("attachment_stable") is not True:
                raise ValueError(f"unstable BPF attachment: {key}")
            if row.get("attached_program_id_before", 0) <= 0 or \
                    row.get("attached_program_id_after", 0) != \
                    row["attached_program_id_before"]:
                raise ValueError(f"invalid BPF program identity: {key}")
        if row["condition"] == "select" and \
                row.get("select_required_for_logical_path") is not True:
            raise ValueError(f"unverified SELECT view: {key}")
        if not math.isfinite(row["works_per_second"]) or \
                row["works_per_second"] <= 0:
            raise ValueError(f"invalid throughput: {key}")
        indexed[key] = row
    for repetition in range(1, repetitions + 1):
        for condition in CONDITIONS:
            for benchmark in TYPES:
                for workers in WORKERS:
                    key = (repetition, condition, benchmark, workers)
                    if key not in indexed:
                        raise ValueError(f"missing cell: {key}")
    return indexed


def summarize(indexed, repetitions, seed):
    rng = random.Random(seed)
    summaries = []
    for benchmark in TYPES:
        for workers in WORKERS:
            condition_values = {}
            for condition in CONDITIONS:
                values = [
                    indexed[(repetition, condition, benchmark, workers)]
                    ["works_per_second"]
                    for repetition in range(1, repetitions + 1)
                ]
                low, high = bootstrap_median_ci(values, rng)
                condition_values[condition] = {
                    "median": statistics.median(values),
                    "ci_low": low,
                    "ci_high": high,
                    "values": values,
                }

            normalized = {}
            for condition in CONDITIONS[1:]:
                ratios = [
                    indexed[(repetition, condition, benchmark, workers)]
                    ["works_per_second"] /
                    indexed[(repetition, "stock", benchmark, workers)]
                    ["works_per_second"]
                    for repetition in range(1, repetitions + 1)
                ]
                low, high = bootstrap_median_ci(ratios, rng)
                normalized[condition] = {
                    "median": statistics.median(ratios),
                    "ci_low": low,
                    "ci_high": high,
                }

            select_fuse = [
                indexed[(repetition, "select", benchmark, workers)]
                ["works_per_second"] /
                indexed[(repetition, "fuse", benchmark, workers)]
                ["works_per_second"]
                for repetition in range(1, repetitions + 1)
            ]
            sf_low, sf_high = bootstrap_median_ci(select_fuse, rng)
            fuse_setup = [
                indexed[(repetition, "fuse", benchmark, workers)]
                ["fuse_setup_requests"]
                for repetition in range(1, repetitions + 1)
            ]
            fuse_measured = [
                indexed[(repetition, "fuse", benchmark, workers)]
                ["fuse_measured_requests"]
                for repetition in range(1, repetitions + 1)
            ]
            summaries.append({
                "type": benchmark,
                "workers": workers,
                "throughput": condition_values,
                "normalized_to_stock": normalized,
                "select_over_fuse": {
                    "median": statistics.median(select_fuse),
                    "ci_low": sf_low,
                    "ci_high": sf_high,
                },
                "fuse_setup_requests_median":
                    statistics.median(fuse_setup),
                "fuse_measured_requests_median":
                    statistics.median(fuse_measured),
            })
    return summaries


def classify(summaries):
    fast_path_positive = all(
        row["normalized_to_stock"]["unattached"]["median"] >= 0.98 and
        row["normalized_to_stock"]["unattached"]["ci_low"] >= 0.97
        for row in summaries
    )
    select_positive = all(
        row["select_over_fuse"]["ci_low"] > 1
        for row in summaries
    )
    fast_path_contradicted = any(
        row["normalized_to_stock"]["unattached"]["ci_high"] < 0.98
        for row in summaries
    )
    select_contradicted = any(
        row["select_over_fuse"]["ci_high"] <= 1
        for row in summaries
    )
    if fast_path_positive and select_positive:
        hypothesis = "supported"
    elif fast_path_contradicted or select_contradicted:
        hypothesis = "contradicted"
    else:
        hypothesis = "inconclusive_or_mixed"
    return {
        "tested_hypothesis": hypothesis,
        "fast_path_positive_all_cells": fast_path_positive,
        "select_over_fuse_positive_all_cells": select_positive,
        "fast_path_confidently_contradicted_any_cell":
            fast_path_contradicted,
        "select_over_fuse_confidently_contradicted_any_cell":
            select_contradicted,
    }


def write_csv(path, summaries):
    fields = [
        "type", "workers",
        "stock_median_ops_s", "unattached_median_ops_s",
        "pass_median_ops_s", "select_median_ops_s", "fuse_median_ops_s",
        "unattached_over_stock_median",
        "unattached_over_stock_ci_low",
        "unattached_over_stock_ci_high",
        "select_over_fuse_median", "select_over_fuse_ci_low",
        "select_over_fuse_ci_high",
        "fuse_setup_requests_median", "fuse_measured_requests_median",
    ]
    with path.open("w", newline="", encoding="utf-8") as output:
        writer = csv.DictWriter(output, fieldnames=fields)
        writer.writeheader()
        for row in summaries:
            writer.writerow({
                "type": row["type"],
                "workers": row["workers"],
                **{
                    f"{condition}_median_ops_s":
                        row["throughput"][condition]["median"]
                    for condition in CONDITIONS
                },
                "unattached_over_stock_median":
                    row["normalized_to_stock"]["unattached"]["median"],
                "unattached_over_stock_ci_low":
                    row["normalized_to_stock"]["unattached"]["ci_low"],
                "unattached_over_stock_ci_high":
                    row["normalized_to_stock"]["unattached"]["ci_high"],
                "select_over_fuse_median":
                    row["select_over_fuse"]["median"],
                "select_over_fuse_ci_low":
                    row["select_over_fuse"]["ci_low"],
                "select_over_fuse_ci_high":
                    row["select_over_fuse"]["ci_high"],
                "fuse_setup_requests_median":
                    row["fuse_setup_requests_median"],
                "fuse_measured_requests_median":
                    row["fuse_measured_requests_median"],
            })


def write_markdown(path, summaries, verdict, repetitions, seed):
    lines = [
        "# FxMark RQ2 Result",
        "",
        f"- Repetitions: {repetitions} paired five-boot blocks",
        f"- Bootstrap samples: {BOOTSTRAP_SAMPLES}",
        f"- Bootstrap seed: {seed}",
        f"- Tested hypothesis: **{verdict['tested_hypothesis']}**",
        "",
        "| Test | Workers | Unattached / stock (95% CI) | "
        "SELECT / FUSE (95% CI) | FUSE measured requests |",
        "| --- | ---: | ---: | ---: | ---: |",
    ]
    for row in summaries:
        unattached = row["normalized_to_stock"]["unattached"]
        select_fuse = row["select_over_fuse"]
        lines.append(
            f"| {row['type']} | {row['workers']} | "
            f"{unattached['median']:.3f} "
            f"[{unattached['ci_low']:.3f}, "
            f"{unattached['ci_high']:.3f}] | "
            f"{select_fuse['median']:.3f} "
            f"[{select_fuse['ci_low']:.3f}, "
            f"{select_fuse['ci_high']:.3f}] | "
            f"{row['fuse_measured_requests_median']:.0f} |"
        )
    lines.extend([
        "",
        "This report is generated from the complete raw JSONL matrix. "
        "It is scoped to cache-hot `stat()` path resolution in the pinned "
        "FxMark source and does not establish open, readdir, cache-cold, or "
        "tail-latency behavior.",
        "",
    ])
    path.write_text("\n".join(lines), encoding="utf-8")


def write_figure(output_root, summaries):
    colors = {
        "stock": "#1f2937",
        "unattached": "#4b5563",
        "pass": "#0072b2",
        "select": "#009e73",
        "fuse": "#d55e00",
    }
    markers = {
        "stock": "o",
        "unattached": "s",
        "pass": "^",
        "select": "D",
        "fuse": "X",
    }
    grouped = defaultdict(dict)
    for row in summaries:
        grouped[row["type"]][row["workers"]] = row

    figure, axes = plt.subplots(1, 3, figsize=(10.5, 3.2), sharey=False)
    for axis, benchmark in zip(axes, TYPES):
        for condition in CONDITIONS:
            medians = [
                grouped[benchmark][workers]["throughput"][condition]["median"]
                for workers in WORKERS
            ]
            lows = [
                median - grouped[benchmark][workers]["throughput"][condition]
                ["ci_low"]
                for workers, median in zip(WORKERS, medians)
            ]
            highs = [
                grouped[benchmark][workers]["throughput"][condition]
                ["ci_high"] - median
                for workers, median in zip(WORKERS, medians)
            ]
            axis.errorbar(
                WORKERS, medians, yerr=[lows, highs],
                color=colors[condition], marker=markers[condition],
                linewidth=1.5, capsize=2.5, label=condition,
            )
        axis.set_title(benchmark)
        axis.set_xlabel("FxMark workers")
        axis.set_xticks(WORKERS)
        axis.grid(axis="y", color="#d1d5db", linewidth=0.6)
        axis.ticklabel_format(axis="y", style="sci", scilimits=(0, 0))
    axes[0].set_ylabel("Operations / second")
    handles, labels = axes[0].get_legend_handles_labels()
    figure.legend(handles, labels, loc="upper center", ncol=5,
                  frameon=False, bbox_to_anchor=(0.5, 1.04))
    figure.tight_layout(rect=(0, 0, 1, 0.91))
    figure.savefig(output_root / "throughput.png", dpi=220)
    figure.savefig(output_root / "throughput.pdf")
    plt.close(figure)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--repetitions", required=True, type=int)
    parser.add_argument("--seed", required=True, type=int)
    args = parser.parse_args()

    args.output.mkdir(parents=True, exist_ok=True)
    rows = load_rows(args.input)
    indexed = validate(rows, args.repetitions)
    summaries = summarize(indexed, args.repetitions, args.seed)
    verdict = classify(summaries)
    result = {
        "input": str(args.input),
        "repetitions": args.repetitions,
        "bootstrap_samples": BOOTSTRAP_SAMPLES,
        "bootstrap_seed": args.seed,
        "verdict": verdict,
        "cells": summaries,
    }
    with (args.output / "summary.json").open("w", encoding="utf-8") as output:
        json.dump(result, output, indent=2)
        output.write("\n")
    write_csv(args.output / "summary.csv", summaries)
    write_markdown(args.output / "report.md", summaries, verdict,
                   args.repetitions, args.seed)
    write_figure(args.output, summaries)


if __name__ == "__main__":
    main()
