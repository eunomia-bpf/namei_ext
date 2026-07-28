#!/usr/bin/env python3

import argparse
import csv
import json
import math
import random
import statistics
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt


RUN_SCHEMA = "namei_ext.run.v2"
SUMMARY_SCHEMA = "namei_ext.fxmark-fast-path.analysis.v1"
SUITE = "fxmark-fast-path"
LAYOUT = "paired-boot-matrix"
LAUNCH_SCHEMA = "namei_ext.fxmark_fast_path.launch_order.v1"
OBSERVATION_EVENT = "fxmark-cell"
CONDITIONS = ("stock", "unattached")
TYPES = ("MRPL",)
WORKERS = (1, 2, 4)
BOOTSTRAP_SAMPLES = 10000
SUPPORTED_MEDIAN = 0.98
SUPPORTED_CI_LOW = 0.97


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


def load_jsonl(path, expected_event=None, expected_schema=None):
    rows = []
    with path.open(encoding="utf-8") as source:
        for line_number, line in enumerate(source, 1):
            try:
                row = json.loads(line)
            except json.JSONDecodeError as error:
                raise ValueError(
                    f"{path}:{line_number}: invalid JSON: {error}") from error
            if expected_event is not None and \
                    row.get("event") != expected_event:
                raise ValueError(
                    f"{path}:{line_number}: unexpected event")
            if expected_schema is not None and \
                    row.get("schema") != expected_schema:
                raise ValueError(
                    f"{path}:{line_number}: unexpected schema")
            rows.append(row)
    return rows


def load_plan(path):
    with path.open(encoding="utf-8") as source:
        run = json.load(source)
    if run.get("schema") != RUN_SCHEMA:
        raise ValueError("unsupported run schema")
    if run.get("suite") != SUITE or run.get("layout") != LAYOUT or \
            run.get("status") not in ("running", "completed"):
        raise ValueError("run is not a valid FxMark fast-path matrix")
    matrix = run.get("matrix")
    if not isinstance(matrix, dict):
        raise ValueError("missing run matrix")
    plan = {
        "conditions": tuple(matrix.get("conditions", ())),
        "types": tuple(matrix.get("types", ())),
        "workers": tuple(matrix.get("workers", ())),
        "repetitions": matrix.get("repetitions"),
        "duration_seconds": matrix.get("duration_seconds"),
        "bpf_stats": matrix.get("bpf_stats", 0),
        "external_inventory_gate": matrix.get("external_inventory_gate"),
    }
    if plan["conditions"] != CONDITIONS or plan["types"] != TYPES or \
            plan["workers"] != WORKERS:
        raise ValueError("run matrix does not match the fast-path protocol")
    if type(plan["repetitions"]) is not int or plan["repetitions"] < 1:
        raise ValueError("invalid repetition count")
    if type(plan["duration_seconds"]) is not int or \
            plan["duration_seconds"] < 1:
        raise ValueError("invalid measured duration")
    if plan["bpf_stats"] != 0:
        raise ValueError("fast-path analysis requires bpf_stats=0")
    if plan["external_inventory_gate"] is not True:
        raise ValueError("missing external BPF/FUSE inventory gate")
    return plan


def validate_launch_order(entries, repetitions):
    expected_count = 2 * repetitions
    if len(entries) != expected_count:
        raise ValueError(
            f"expected {expected_count} launch entries, found {len(entries)}")
    identities = set()
    for position, entry in enumerate(entries, 1):
        repetition = (position - 1) // 2 + 1
        within_pair = (position - 1) % 2
        first = "stock" if repetition % 2 == 1 else "unattached"
        second = "unattached" if first == "stock" else "stock"
        expected_condition = (first, second)[within_pair]
        identity = (entry.get("repetition"), entry.get("condition"))
        if entry.get("order_index") != position:
            raise ValueError(f"non-sequential launch entry at position {position}")
        if identity != (repetition, expected_condition):
            raise ValueError(
                f"unexpected launch entry at position {position}: {identity}")
        if identity in identities:
            raise ValueError(f"duplicate launch entry: {identity}")
        identities.add(identity)
        for field in ("host_started_at", "host_completed_at"):
            value = entry.get(field)
            if not isinstance(value, str) or not value.strip():
                raise ValueError(
                    f"launch entry {position} has empty {field}")
    return entries


def _require_zero(row, fields, key, description):
    for field in fields:
        if field not in row or row[field] != 0:
            raise ValueError(f"{description} in {key}: {field}")


def validate_observations(rows, plan):
    repetitions = plan["repetitions"]
    duration = plan["duration_seconds"]
    expected_count = repetitions * len(CONDITIONS) * len(WORKERS)
    if len(rows) != expected_count:
        raise ValueError(
            f"expected {expected_count} observations, found {len(rows)}")

    indexed = {}
    for row in rows:
        try:
            key = (row["repetition"], row["condition"], row["type"],
                   row["workers"])
        except KeyError as error:
            raise ValueError(f"observation missing {error.args[0]}") from error
        if key in indexed:
            raise ValueError(f"duplicate cell: {key}")
        repetition, condition, benchmark, workers = key
        if type(repetition) is not int or not 1 <= repetition <= repetitions:
            raise ValueError(f"invalid repetition: {key}")
        if condition not in CONDITIONS or benchmark not in TYPES or \
                workers not in WORKERS:
            raise ValueError(f"unplanned cell: {key}")
        if row.get("pass") is not True:
            raise ValueError(f"failed correctness oracle: {key}")
        if row.get("fxmark_status") != 0:
            raise ValueError(f"failed FxMark process: {key}")
        if row.get("leader_cgroup_verified") is not True:
            raise ValueError(f"unverified benchmark cgroup: {key}")
        if row.get("duration_seconds") != duration:
            raise ValueError(f"wrong declared duration: {key}")

        seconds = row.get("seconds")
        works = row.get("works")
        rate = row.get("works_per_second")
        if not isinstance(seconds, (int, float)) or \
                not duration * 0.9 <= seconds <= duration * 1.2:
            raise ValueError(f"out-of-bounds measured duration: {key}")
        if not isinstance(works, (int, float)) or works <= 0:
            raise ValueError(f"invalid completed work: {key}")
        if not isinstance(rate, (int, float)) or \
                not math.isfinite(rate) or rate <= 0:
            raise ValueError(f"invalid throughput: {key}")
        if not math.isclose(works / seconds, rate, rel_tol=1e-6):
            raise ValueError(f"throughput arithmetic mismatch: {key}")

        expected_files = workers
        expected_directories = 1 + 4 * workers
        if row.get("expected_files") != expected_files or \
                row.get("actual_files") != expected_files or \
                row.get("expected_directories") != expected_directories or \
                row.get("actual_directories") != expected_directories:
            raise ValueError(f"tree cardinality mismatch: {key}")

        _require_zero(
            row,
            ("attached_program_id_before", "attached_program_id_after",
             "policy_run_count_before", "policy_run_count_after",
             "policy_run_time_ns_before", "policy_run_time_ns_after"),
            key, "unexpected BPF activity")
        if row.get("attachment_stable") is not False:
            raise ValueError(f"unexpected BPF attachment state: {key}")
        _require_zero(
            row,
            ("fuse_setup_requests", "fuse_measured_requests",
             "fuse_f_type_before", "fuse_f_type_after"),
            key, "unexpected FUSE activity")
        if row.get("fuse_status") != -1:
            raise ValueError(f"unexpected FUSE process: {key}")
        indexed[key] = row

    for repetition in range(1, repetitions + 1):
        for condition in CONDITIONS:
            for workers in WORKERS:
                key = (repetition, condition, "MRPL", workers)
                if key not in indexed:
                    raise ValueError(f"missing cell: {key}")
    return indexed


def classify_cell(median, ci_low, ci_high):
    if median >= SUPPORTED_MEDIAN and ci_low >= SUPPORTED_CI_LOW:
        return "supported"
    if ci_high < SUPPORTED_MEDIAN:
        return "contradicted"
    return "inconclusive"


def classify(cells):
    verdicts = [cell["verdict"] for cell in cells]
    if all(verdict == "supported" for verdict in verdicts):
        return "supported"
    if any(verdict == "contradicted" for verdict in verdicts):
        return "contradicted"
    return "inconclusive"


def summarize(indexed, repetitions, seed):
    rng = random.Random(seed)
    cells = []
    for workers in WORKERS:
        stock = []
        unattached = []
        ratios = []
        for repetition in range(1, repetitions + 1):
            stock_rate = indexed[
                (repetition, "stock", "MRPL", workers)]["works_per_second"]
            unattached_rate = indexed[
                (repetition, "unattached", "MRPL", workers)
            ]["works_per_second"]
            stock.append(stock_rate)
            unattached.append(unattached_rate)
            ratios.append(unattached_rate / stock_rate)
        ci_low, ci_high = bootstrap_median_ci(ratios, rng)
        median = statistics.median(ratios)
        cells.append({
            "type": "MRPL",
            "workers": workers,
            "stock_median_ops_s": statistics.median(stock),
            "unattached_median_ops_s": statistics.median(unattached),
            "unattached_over_stock": {
                "median": median,
                "ci_low": ci_low,
                "ci_high": ci_high,
                "paired_ratios": ratios,
            },
            "verdict": classify_cell(median, ci_low, ci_high),
        })
    return cells


def write_csv(path, cells):
    fields = [
        "type", "workers", "stock_median_ops_s",
        "unattached_median_ops_s", "unattached_over_stock_median",
        "unattached_over_stock_ci_low", "unattached_over_stock_ci_high",
        "verdict",
    ]
    with path.open("w", newline="", encoding="utf-8") as output:
        writer = csv.DictWriter(
            output, fieldnames=fields, lineterminator="\n")
        writer.writeheader()
        for cell in cells:
            ratio = cell["unattached_over_stock"]
            writer.writerow({
                "type": cell["type"],
                "workers": cell["workers"],
                "stock_median_ops_s": cell["stock_median_ops_s"],
                "unattached_median_ops_s":
                    cell["unattached_median_ops_s"],
                "unattached_over_stock_median": ratio["median"],
                "unattached_over_stock_ci_low": ratio["ci_low"],
                "unattached_over_stock_ci_high": ratio["ci_high"],
                "verdict": cell["verdict"],
            })


def write_report(path, cells, overall, repetitions, seed):
    lines = [
        "# FxMark Fast-Path Result",
        "",
        f"- Paired repetitions: {repetitions}",
        f"- Bootstrap resamples: {BOOTSTRAP_SAMPLES}",
        f"- Bootstrap seed: {seed}",
        f"- Overall verdict: **{overall}**",
        "",
        "| Workload | Workers | Unattached / stock (95% CI) | Verdict |",
        "| --- | ---: | ---: | --- |",
    ]
    for cell in cells:
        ratio = cell["unattached_over_stock"]
        lines.append(
            f"| {cell['type']} | {cell['workers']} | "
            f"{ratio['median']:.3f} "
            f"[{ratio['ci_low']:.3f}, {ratio['ci_high']:.3f}] | "
            f"{cell['verdict']} |")
    lines.extend([
        "",
        "A cell is supported when its median ratio is at least 0.98 and "
        "its 95% confidence-interval lower bound is at least 0.97. A cell "
        "is contradicted when its upper bound is below 0.98. Other outcomes "
        "are inconclusive.",
        "",
        "The analysis covers paired, host-ordered MRPL throughput for the "
        "stock kernel and the patched kernel with no BPF program attached. "
        "The runner separately gates direct pre/post BPF-program, cgroup-"
        "attachment, FUSE-mount, and /dev/fuse-open-file inventories. It "
        "does not measure active-policy cost.",
        "",
    ])
    path.write_text("\n".join(lines), encoding="utf-8")


def write_figure(output, cells):
    figure, axis = plt.subplots(figsize=(7.2, 4.2))
    x_positions = list(range(1, len(cells) + 1))
    raw_label_used = False
    for x, cell in zip(x_positions, cells):
        ratio = cell["unattached_over_stock"]
        values = ratio["paired_ratios"]
        if len(values) == 1:
            offsets = [0]
        else:
            offsets = [
                -0.15 + 0.30 * index / (len(values) - 1)
                for index in range(len(values))
            ]
        axis.scatter(
            [x + offset for offset in offsets], values,
            color="#6b7280", alpha=0.65, s=22,
            label="paired repetition" if not raw_label_used else None,
            zorder=2)
        raw_label_used = True
        axis.errorbar(
            x, ratio["median"],
            yerr=[[ratio["median"] - ratio["ci_low"]],
                  [ratio["ci_high"] - ratio["median"]]],
            fmt="o", color="#0072b2", capsize=5, linewidth=2,
            markersize=6, label="median and 95% CI" if x == 1 else None,
            zorder=3)
    axis.axhline(
        SUPPORTED_MEDIAN, color="#009e73", linewidth=1.5,
        label="median threshold (0.98)")
    axis.axhline(
        SUPPORTED_CI_LOW, color="#d55e00", linewidth=1.5,
        linestyle="--", label="CI lower-bound threshold (0.97)")
    axis.set_xticks(
        x_positions,
        [f"MRPL\n{cell['workers']} worker"
         f"{'s' if cell['workers'] != 1 else ''}" for cell in cells])
    axis.set_ylabel("Unattached / stock throughput")
    axis.grid(axis="y", color="#d1d5db", linewidth=0.6)
    axis.legend(frameon=False, fontsize=8)
    figure.tight_layout()
    figure.savefig(output / "fast-path.png", dpi=220)
    figure.savefig(output / "fast-path.pdf")
    plt.close(figure)


def analyze_run(input_path, launch_path, run_path, output, seed):
    plan = load_plan(run_path)
    launches = load_jsonl(launch_path, expected_schema=LAUNCH_SCHEMA)
    validate_launch_order(launches, plan["repetitions"])
    rows = load_jsonl(input_path, OBSERVATION_EVENT)
    indexed = validate_observations(rows, plan)
    cells = summarize(indexed, plan["repetitions"], seed)
    overall = classify(cells)
    result = {
        "schema": SUMMARY_SCHEMA,
        "input": str(input_path),
        "launch_order": str(launch_path),
        "run": str(run_path),
        "repetitions": plan["repetitions"],
        "duration_seconds": plan["duration_seconds"],
        "bootstrap_samples": BOOTSTRAP_SAMPLES,
        "bootstrap_seed": seed,
        "external_bpf_fuse_inventory_gate": True,
        "thresholds": {
            "supported_median": SUPPORTED_MEDIAN,
            "supported_ci_low": SUPPORTED_CI_LOW,
            "contradicted_ci_high_below": SUPPORTED_MEDIAN,
        },
        "verdict": overall,
        "cells": cells,
    }
    output.mkdir(parents=True, exist_ok=True)
    with (output / "summary.json").open("w", encoding="utf-8") as destination:
        json.dump(result, destination, indent=2)
        destination.write("\n")
    write_csv(output / "summary.csv", cells)
    write_report(
        output / "report.md", cells, overall, plan["repetitions"], seed)
    write_figure(output, cells)
    return result


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True, type=Path)
    parser.add_argument("--launch-order", required=True, type=Path)
    parser.add_argument("--run", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--seed", required=True, type=int)
    args = parser.parse_args()
    analyze_run(
        args.input, args.launch_order, args.run, args.output, args.seed)


if __name__ == "__main__":
    main()
