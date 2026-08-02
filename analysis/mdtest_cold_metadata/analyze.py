#!/usr/bin/env python3

"""Validate and analyze the mdtest cold/mutating-metadata experiment.

The immutable input stream contains one ``mdtest-cold-metadata-phase`` event
for every repetition, condition, rank count, and operation.  Performance is
interpreted only after the complete matrix passes the workload, attachment,
filesystem-identity, cache-drop, and cleanup gates.
"""

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


EVENT = "mdtest-cold-metadata-phase"
PHASE_SCHEMA = "namei_ext.mdtest_cold_metadata.phase.v1"
CONDITIONS = ("stock", "unattached", "pass", "select", "fuse")
RANKS = (1, 4)
OPERATIONS = ("create", "stat", "remove")
ATTACHED_CONDITIONS = ("pass", "select")
BOOTSTRAP_SAMPLES = 10000
FROZEN_SEED = 20260729
FUSE_SUPER_MAGIC = 0x65735546
EXT4_SUPER_MAGIC = 0xEF53
FUSE_NOFILE_SOFT = 262144

MODE_DEFAULTS = {
    "preflight": {"repetitions": 1, "items_per_rank": 4096},
    "formal": {"repetitions": 10, "items_per_rank": 32768},
}


def make_config(mode):
    if mode not in MODE_DEFAULTS:
        raise ValueError(f"unknown mode: {mode}")
    return {
        "mode": mode,
        "conditions": CONDITIONS,
        "ranks": RANKS,
        "operations": OPERATIONS,
        **MODE_DEFAULTS[mode],
    }


def _require(row, name, key):
    if name not in row:
        raise ValueError(f"missing {name}: {key}")
    return row[name]


def _bool(row, name, key):
    value = _require(row, name, key)
    if type(value) is not bool:
        raise ValueError(f"{name} is not boolean: {key}")
    return value


def _int(row, name, key, positive=False):
    value = _require(row, name, key)
    if type(value) is not int or (positive and value <= 0):
        raise ValueError(f"invalid {name}: {key}")
    return value


def _number(row, name, key, positive=False):
    value = _require(row, name, key)
    if type(value) not in (int, float) or not math.isfinite(value) or \
            (positive and value <= 0):
        raise ValueError(f"invalid {name}: {key}")
    return float(value)


def load_rows(path):
    rows = []
    with path.open(encoding="utf-8") as source:
        for line_number, line in enumerate(source, 1):
            try:
                row = json.loads(line)
            except json.JSONDecodeError as error:
                raise ValueError(f"{path}:{line_number}: invalid JSON") from error
            if type(row) is not dict or row.get("event") != EVENT:
                raise ValueError(f"{path}:{line_number}: unexpected event")
            rows.append(row)
    if not rows:
        raise ValueError(f"{path}: no observations")
    return rows


def _validate_summary(row, key):
    maximum = _number(row, "summary_max", key, True)
    minimum = _number(row, "summary_min", key, True)
    mean = _number(row, "summary_mean", key, True)
    stddev = _number(row, "summary_stddev", key)
    throughput = _number(row, "ops_per_second", key, True)

    for name, value in (("summary_max", maximum), ("summary_min", minimum),
                        ("ops_per_second", throughput)):
        if not math.isclose(value, mean, rel_tol=1e-9, abs_tol=1e-9):
            raise ValueError(f"{name}/summary_mean mismatch: {key}")
    if not math.isclose(stddev, 0.0, rel_tol=0.0, abs_tol=1e-12):
        raise ValueError(f"nonzero one-iteration summary stddev: {key}")


def _validate_attachment(row, key):
    attached = row["condition"] in ATTACHED_CONDITIONS
    if not _bool(row, "leader_cgroup_verified", key) or \
            not _bool(row, "mpi_ranks_cgroup_verified", key):
        raise ValueError(f"invalid process cgroup evidence: {key}")
    if _bool(row, "attachment_stable", key) != attached:
        raise ValueError(f"invalid attachment stability: {key}")

    before = _int(row, "attached_program_id_before", key)
    after = _int(row, "attached_program_id_after", key)
    policy_runs = _int(row, "untimed_policy_runs", key)
    if attached:
        if before <= 0 or after != before:
            raise ValueError(f"invalid attached program identity: {key}")
        if policy_runs <= 0:
            raise ValueError(f"missing untimed policy attribution: {key}")
    elif before != 0 or after != 0 or policy_runs != 0:
        raise ValueError(f"unexpected BPF attachment evidence: {key}")


def _validate_selected_identity(row, key):
    required = row["condition"] == "select"
    if _bool(row, "selected_identity", key) != required:
        raise ValueError(f"invalid selected-target identity evidence: {key}")


def _validate_fuse(row, key):
    is_fuse = row["condition"] == "fuse"
    f_type = _int(row, "fuse_f_type", key)
    daemon_live = _bool(row, "fuse_daemon_live", key)
    dev_fd_verified = _bool(row, "fuse_dev_fd_verified", key)
    nofile_soft = _int(row, "fuse_nofile_soft", key)
    if is_fuse:
        if f_type != FUSE_SUPER_MAGIC or not daemon_live or \
                not dev_fd_verified or nofile_soft != FUSE_NOFILE_SOFT:
            raise ValueError(f"invalid FUSE engagement evidence: {key}")
    elif f_type != 0 or daemon_live or dev_fd_verified or nofile_soft != 0:
        raise ValueError(f"unexpected FUSE engagement evidence: {key}")


def _validate_cache_drop(row, key):
    required = row["operation"] in ("stat", "remove")
    expected_value = 3 if required else 0
    expected_bytes = 2 if required else 0
    if _int(row, "cache_drop_value", key) != expected_value or \
            _int(row, "cache_drop_bytes_written", key) != expected_bytes or \
            _int(row, "cache_drop_errno", key) != 0:
        raise ValueError(f"invalid cache-drop evidence: {key}")


def _validate_tree(row, key):
    ranks = row["ranks"]
    items = row["items_per_rank"]
    if row["operation"] in ("create", "stat"):
        expected_files = ranks * items
        expected_directories = ranks + 2
    else:
        expected_files = 0
        expected_directories = 1
    for field, expected in (
            ("expected_files", expected_files),
            ("actual_files", expected_files),
            ("expected_directories", expected_directories),
            ("actual_directories", expected_directories),
            ("actual_other", 0)):
        if _int(row, field, key) != expected:
            raise ValueError(f"invalid {field}: {key}")


def _validate_row(row, config, key):
    if row.get("event") != EVENT or row.get("schema") != PHASE_SCHEMA:
        raise ValueError(f"unexpected event: {key}")
    repetition = _int(row, "repetition", key, True)
    ranks = _int(row, "ranks", key, True)
    if repetition not in range(1, config["repetitions"] + 1) or \
            row.get("condition") not in config["conditions"] or \
            ranks not in config["ranks"] or \
            row.get("operation") not in config["operations"]:
        raise ValueError(f"unplanned phase: {key}")
    if _int(row, "items_per_rank", key, True) != config["items_per_rank"]:
        raise ValueError(f"wrong items_per_rank: {key}")
    if _int(row, "phase_status", key) != 0:
        raise ValueError(f"failed mdtest phase: {key}")
    for field in ("pass", "warning_as_errors", "warnings_or_errors_absent",
                  "tree_correct", "mpi_bindings_reported",
                  "cleanup_complete"):
        if _bool(row, field, key) is not True:
            raise ValueError(f"{field} gate failed: {key}")
    if _int(row, "ext4_f_type", key) != EXT4_SUPER_MAGIC:
        raise ValueError(f"unverified lower ext4 filesystem: {key}")

    _validate_summary(row, key)
    _validate_attachment(row, key)
    _validate_selected_identity(row, key)
    _validate_fuse(row, key)
    _validate_cache_drop(row, key)
    _validate_tree(row, key)


def validate(rows, config):
    expected_count = config["repetitions"] * len(config["conditions"]) * \
        len(config["ranks"]) * len(config["operations"])
    if len(rows) != expected_count:
        raise ValueError(f"expected {expected_count} rows, found {len(rows)}")

    indexed = {}
    for row in rows:
        key = (row.get("repetition"), row.get("condition"), row.get("ranks"),
               row.get("operation"))
        try:
            duplicate = key in indexed
        except TypeError as error:
            raise ValueError(f"malformed phase key: {key}") from error
        if duplicate:
            raise ValueError(f"duplicate phase: {key}")
        _validate_row(row, config, key)
        indexed[key] = row

    for repetition in range(1, config["repetitions"] + 1):
        for condition in config["conditions"]:
            for ranks in config["ranks"]:
                for operation in config["operations"]:
                    key = (repetition, condition, ranks, operation)
                    if key not in indexed:
                        raise ValueError(f"missing phase: {key}")
    return indexed


def _percentile(values, probability):
    position = (len(values) - 1) * probability
    lower = math.floor(position)
    upper = math.ceil(position)
    if lower == upper:
        return values[lower]
    weight = position - lower
    return values[lower] * (1.0 - weight) + values[upper] * weight


def paired_bootstrap_median_ci(numerators, denominators, rng,
                               samples=BOOTSTRAP_SAMPLES):
    if len(numerators) != len(denominators) or not numerators:
        raise ValueError("paired bootstrap requires a non-empty equal-length pair")
    if any(type(value) not in (int, float) or not math.isfinite(value) or
           value <= 0 for value in (*numerators, *denominators)):
        raise ValueError("paired bootstrap requires positive finite values")

    estimates = []
    for _ in range(samples):
        ratios = []
        for _ in range(len(numerators)):
            index = rng.randrange(len(numerators))
            ratios.append(numerators[index] / denominators[index])
        estimates.append(statistics.median(ratios))
    estimates.sort()
    return _percentile(estimates, 0.025), _percentile(estimates, 0.975)


def _values(indexed, config, condition, operation, ranks):
    return [
        indexed[(repetition, condition, ranks, operation)]["ops_per_second"]
        for repetition in range(1, config["repetitions"] + 1)
    ]


def _ratio_summary(numerators, denominators, mode, rng):
    ratios = [numerator / denominator
              for numerator, denominator in zip(numerators, denominators)]
    result = {
        "median": statistics.median(ratios),
        "values": ratios,
        "inferential": mode == "formal",
        "ci_low": None,
        "ci_high": None,
    }
    if mode == "formal":
        result["ci_low"], result["ci_high"] = paired_bootstrap_median_ci(
            numerators, denominators, rng)
    return result


def summarize(indexed, config, seed=FROZEN_SEED):
    rng = random.Random(seed)
    cells = []
    for operation in config["operations"]:
        for ranks in config["ranks"]:
            fuse_values = _values(indexed, config, "fuse", operation, ranks)
            throughput = {}
            normalized = {}
            for condition in config["conditions"]:
                condition_values = _values(
                    indexed, config, condition, operation, ranks)
                throughput[condition] = {
                    "median": statistics.median(condition_values),
                    "values": condition_values,
                }
                normalized[condition] = _ratio_summary(
                    condition_values, fuse_values, config["mode"], rng)
            cells.append({
                "operation": operation,
                "ranks": ranks,
                "throughput": throughput,
                "normalized_to_fuse": normalized,
                "select_over_fuse": normalized["select"],
            })
    return cells


def classify(cells, mode):
    if mode == "preflight":
        return {
            "verdict": "diagnostic-only",
            "inferential": False,
            "reason": "one paired block validates execution but cannot support "
                      "a confidence interval or paper verdict",
        }

    primary = [cell["select_over_fuse"] for cell in cells]
    if len(primary) != len(OPERATIONS) * len(RANKS) or \
            any(item["ci_low"] is None or item["ci_high"] is None
                for item in primary):
        raise ValueError("formal verdict requires all six inferential cells")
    positive = all(item["ci_low"] > 1.0 for item in primary)
    contradicted = any(item["ci_high"] < 1.0 for item in primary)
    verdict = "positive" if positive else \
        "contradicted" if contradicted else "mixed"
    return {
        "verdict": verdict,
        "inferential": True,
        "positive": positive,
        "contradicted": contradicted,
        "cells_with_ci_low_above_one":
            sum(item["ci_low"] > 1.0 for item in primary),
        "cells_with_ci_high_strictly_below_one":
            sum(item["ci_high"] < 1.0 for item in primary),
    }


def config_from_run(path):
    try:
        run = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise ValueError(f"{path}: invalid run manifest") from error
    if type(run) is not dict or run.get("status") not in ("running", "completed"):
        raise ValueError(f"{path}: run has no analyzable state")
    matrix = run.get("matrix")
    if type(matrix) is not dict:
        raise ValueError(f"{path}: missing matrix")
    if matrix.get("conditions") != list(CONDITIONS) or \
            matrix.get("ranks") != list(RANKS) or \
            matrix.get("operations") != list(OPERATIONS):
        raise ValueError(f"{path}: incompatible mdtest matrix")
    if "event" in matrix and matrix["event"] != EVENT:
        raise ValueError(f"{path}: incompatible mdtest event")

    repetitions = matrix.get("repetitions")
    items_per_rank = matrix.get("items_per_rank")
    if type(repetitions) is not int or type(items_per_rank) is not int:
        raise ValueError(f"{path}: invalid mdtest matrix types")
    if repetitions == MODE_DEFAULTS["preflight"]["repetitions"] and \
            items_per_rank == MODE_DEFAULTS["preflight"]["items_per_rank"]:
        mode = "preflight"
    elif repetitions == MODE_DEFAULTS["formal"]["repetitions"] and \
            items_per_rank == MODE_DEFAULTS["formal"]["items_per_rank"]:
        mode = "formal"
    else:
        raise ValueError(
            f"{path}: matrix is neither frozen preflight nor formal")
    if "mode" in matrix and matrix["mode"] != mode:
        raise ValueError(f"{path}: matrix mode does not match its dimensions")
    return make_config(mode)


def write_csv(path, cells):
    fields = (
        "operation", "ranks", "condition", "throughput_median_ops_s",
        "normalized_to_fuse_median", "normalized_ci_low",
        "normalized_ci_high", "inferential",
    )
    with path.open("w", newline="", encoding="utf-8") as output:
        writer = csv.DictWriter(output, fieldnames=fields)
        writer.writeheader()
        for cell in cells:
            for condition in CONDITIONS:
                normalized = cell["normalized_to_fuse"][condition]
                writer.writerow({
                    "operation": cell["operation"],
                    "ranks": cell["ranks"],
                    "condition": condition,
                    "throughput_median_ops_s":
                        cell["throughput"][condition]["median"],
                    "normalized_to_fuse_median": normalized["median"],
                    "normalized_ci_low": normalized["ci_low"]
                    if normalized["ci_low"] is not None else "",
                    "normalized_ci_high": normalized["ci_high"]
                    if normalized["ci_high"] is not None else "",
                    "inferential": str(normalized["inferential"]).lower(),
                })


def write_report(path, cells, verdict, config, seed):
    lines = [
        "# mdtest cold/mutating-metadata analysis",
        "",
        f"- Mode: {config['mode']}",
        f"- Paired blocks: {config['repetitions']}",
        f"- Items per rank: {config['items_per_rank']}",
        f"- Ranks: {', '.join(str(value) for value in config['ranks'])}",
        f"- Operations: {', '.join(config['operations'])}",
    ]
    if config["mode"] == "formal":
        lines.extend([
            f"- Bootstrap: {BOOTSTRAP_SAMPLES} paired resamples, seed {seed}",
            f"- Primary verdict: **{verdict['verdict']}**",
            "",
            "The formal gate is positive only when every SELECT/FUSE 95% CI "
            "lower bound exceeds 1. It is contradicted when any upper bound "
            "is strictly below 1; all other complete outcomes are mixed.",
            "",
            "| Operation | Ranks | SELECT/FUSE median (95% CI) |",
            "| --- | ---: | ---: |",
        ])
        for cell in cells:
            ratio = cell["select_over_fuse"]
            lines.append(
                f"| {cell['operation']} | {cell['ranks']} | "
                f"{ratio['median']:.3f} [{ratio['ci_low']:.3f}, "
                f"{ratio['ci_high']:.3f}] |")
    else:
        lines.extend([
            "- Primary verdict: **diagnostic-only**",
            "",
            "This one-block preflight validates the complete execution and "
            "correctness matrix. Ratios below are diagnostics only; no "
            "confidence interval or paper-level performance verdict is "
            "computed.",
            "",
            "| Operation | Ranks | Diagnostic SELECT/FUSE ratio |",
            "| --- | ---: | ---: |",
        ])
        for cell in cells:
            lines.append(
                f"| {cell['operation']} | {cell['ranks']} | "
                f"{cell['select_over_fuse']['median']:.3f} |")

    lines.extend([
        "",
        "## Median throughput",
        "",
        "| Operation | Ranks | Stock | Unattached | PASS | SELECT | FUSE |",
        "| --- | ---: | ---: | ---: | ---: | ---: | ---: |",
    ])
    for cell in cells:
        values = [
            f"{cell['throughput'][condition]['median']:.3f}"
            for condition in CONDITIONS
        ]
        lines.append(
            f"| {cell['operation']} | {cell['ranks']} | "
            + " | ".join(values) + " |")
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def write_figure(output, cells, mode):
    colors = {
        "stock": "#374151",
        "unattached": "#6b7280",
        "pass": "#0072b2",
        "select": "#009e73",
        "fuse": "#d55e00",
    }
    grouped = {
        (cell["operation"], cell["ranks"]): cell
        for cell in cells
    }
    figure, axes = plt.subplots(
        1, len(OPERATIONS), squeeze=False, figsize=(11.4, 3.6),
        sharey=True)
    axes = axes[0]
    width = 0.15
    centers = list(range(len(RANKS)))
    offsets = {
        condition: (index - (len(CONDITIONS) - 1) / 2) * width
        for index, condition in enumerate(CONDITIONS)
    }
    for axis, operation in zip(axes, OPERATIONS):
        for condition in CONDITIONS:
            entries = [
                grouped[(operation, ranks)]["normalized_to_fuse"][condition]
                for ranks in RANKS
            ]
            positions = [center + offsets[condition] for center in centers]
            medians = [entry["median"] for entry in entries]
            error = None
            if mode == "formal":
                error = [
                    [max(0.0, entry["median"] - entry["ci_low"])
                     for entry in entries],
                    [max(0.0, entry["ci_high"] - entry["median"])
                     for entry in entries],
                ]
            axis.bar(
                positions, medians, width=width, color=colors[condition],
                label=condition, yerr=error, capsize=2.0 if error else 0,
                linewidth=0)
        axis.axhline(1.0, color="#111827", linewidth=0.8, linestyle="--")
        axis.set_title(operation.capitalize())
        axis.set_xlabel("MPI ranks")
        axis.set_xticks(centers, [str(ranks) for ranks in RANKS])
        axis.grid(axis="y", color="#d1d5db", linewidth=0.6)
        axis.set_axisbelow(True)
    axes[0].set_ylabel("Throughput normalized to FUSE")
    handles, labels = axes[0].get_legend_handles_labels()
    figure.legend(
        handles, labels, loc="upper center", ncol=len(CONDITIONS),
        frameon=False, bbox_to_anchor=(0.5, 1.04))
    figure.tight_layout(rect=(0, 0, 1, 0.91))
    figure.savefig(output / "normalized-throughput.png", dpi=220)
    figure.savefig(output / "normalized-throughput.pdf")
    plt.close(figure)


def main(argv=None):
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", "--observations", dest="input",
                        required=True, type=Path)
    parser.add_argument("--run", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--seed", type=int, default=FROZEN_SEED)
    args = parser.parse_args(argv)
    if args.seed != FROZEN_SEED:
        parser.error("--run requires the frozen analysis seed")

    config = config_from_run(args.run)
    rows = load_rows(args.input)
    indexed = validate(rows, config)
    cells = summarize(indexed, config, args.seed)
    verdict = classify(cells, config["mode"])

    args.output.mkdir(parents=True, exist_ok=True)
    result = {
        "schema": "namei_ext.mdtest_cold_metadata.analysis.v1",
        "input": str(args.input),
        "run": str(args.run),
        "config": config,
        "bootstrap_samples":
            BOOTSTRAP_SAMPLES if config["mode"] == "formal" else 0,
        "bootstrap_seed":
            args.seed if config["mode"] == "formal" else None,
        "verdict": verdict,
        "cells": cells,
    }
    (args.output / "summary.json").write_text(
        json.dumps(result, indent=2) + "\n", encoding="utf-8")
    write_csv(args.output / "summary.csv", cells)
    write_report(
        args.output / "report.md", cells, verdict, config, args.seed)
    write_figure(args.output, cells, config["mode"])


if __name__ == "__main__":
    main()
