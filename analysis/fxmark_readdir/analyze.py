#!/usr/bin/env python3

"""Analyze the corrected FxMark MRDL/MRDM directory-enumeration matrix.

The input is an immutable JSONL stream with one ``fxmark-cell`` row
per (repetition, condition, test, workers) cell.  Validation is deliberately
strict because a throughput result without the directory and attribution
oracles is not evidence for the experiment.
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


CONDITIONS = ("stock", "unattached", "pass", "select", "fuse")
TYPES = ("MRDL", "MRDM")
WORKERS = (1, 2, 4)
BOOTSTRAP_SAMPLES = 10000
FROZEN_SEED = 20260728
FILES_PER_WORKER = 8192
FUSE_SUPER_MAGIC = 0x65735546
EVENT = "fxmark-cell"

MODE_DEFAULTS = {
    "preflight": {"repetitions": 1, "types": TYPES, "workers": (1, 4),
                   "duration_seconds": 2},
    "formal": {"repetitions": 10, "types": TYPES, "workers": WORKERS,
               "duration_seconds": 30},
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


def expected_tree(test, workers):
    files = FILES_PER_WORKER * workers
    directories = 1 + workers if test == "MRDL" else 1
    if test not in TYPES:
        raise ValueError(f"unknown test: {test}")
    return files, directories


def expected_attribution(test, workers):
    files, _ = expected_tree(test, workers)
    return workers * (FILES_PER_WORKER + 2) if test == "MRDL" else files + 2


def expected_directory_streams(test, workers):
    if test not in TYPES:
        raise ValueError(f"unknown test: {test}")
    return workers if test == "MRDL" else 1


def make_config(mode="formal", repetitions=None, types=None, workers=None,
                duration_seconds=None):
    if mode not in MODE_DEFAULTS:
        raise ValueError(f"unknown mode: {mode}")
    defaults = MODE_DEFAULTS[mode]
    config = {
        "mode": mode,
        "repetitions": defaults["repetitions"] if repetitions is None
        else repetitions,
        "types": defaults["types"] if types is None else tuple(types),
        "workers": defaults["workers"] if workers is None else tuple(workers),
        "duration_seconds": defaults["duration_seconds"] if
        duration_seconds is None else duration_seconds,
    }
    if type(config["repetitions"]) is not int or config["repetitions"] < 1:
        raise ValueError("expected repetitions must be a positive integer")
    if not config["types"] or any(test not in TYPES for test in config["types"]):
        raise ValueError("expected types must be a non-empty subset of MRDL/MRDM")
    if len(set(config["types"])) != len(config["types"]):
        raise ValueError("expected types contain duplicates")
    if not config["workers"] or any(worker not in WORKERS
                                     for worker in config["workers"]):
        raise ValueError("expected workers must be a non-empty subset of 1/2/4")
    if len(set(config["workers"])) != len(config["workers"]):
        raise ValueError("expected workers contain duplicates")
    if type(config["duration_seconds"]) is not int or \
            config["duration_seconds"] < 1:
        raise ValueError("expected duration must be a positive integer")
    return config


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


def _validate_common(row, config, key):
    if _bool(row, "pass", key) is not True:
        raise ValueError(f"failed cell: {key}")
    if _int(row, "repetition", key, True) not in range(1, config["repetitions"] + 1):
        raise ValueError(f"unexpected repetition: {key}")
    workers = _int(row, "workers", key, True)
    if row.get("condition") not in CONDITIONS or row.get("type") not in config["types"] \
            or workers not in config["workers"]:
        raise ValueError(f"unplanned cell: {key}")
    if row.get("event") != EVENT:
        raise ValueError(f"unexpected event: {key}")
    if _int(row, "fxmark_status", key) != 0:
        raise ValueError(f"failed FxMark process: {key}")
    if row.get("duration_seconds") != config["duration_seconds"]:
        raise ValueError(f"wrong declared duration: {key}")
    seconds = _number(row, "seconds", key, True)
    duration = config["duration_seconds"]
    if seconds < duration * 0.9 or seconds > duration * 1.2:
        raise ValueError(f"out-of-bounds measured duration: {key}")
    works = _int(row, "works", key, True)
    rate = _number(row, "works_per_second", key, True)
    if not math.isclose(rate, works / seconds, rel_tol=1e-6, abs_tol=1e-12):
        raise ValueError(f"throughput arithmetic mismatch: {key}")
    _bool(row, "leader_cgroup_verified", key)
    if row["leader_cgroup_verified"] is not True:
        raise ValueError(f"unverified benchmark cgroup: {key}")

    expected_files, expected_directories = expected_tree(row["type"], row["workers"])
    for name, expected in (("actual_files", expected_files),
                           ("expected_files", expected_files),
                           ("actual_directories", expected_directories),
                           ("expected_directories", expected_directories)):
        if _int(row, name, key) != expected:
            raise ValueError(f"tree cardinality mismatch: {key}")
    expected_entries = expected_attribution(row["type"], row["workers"])
    if _bool(row, "readdir_validation_required", key) is not True or \
            _int(row, "logical_directory_entries", key) != expected_entries or \
            _int(row, "expected_directory_entries", key) != expected_entries:
        raise ValueError(f"logical entry-count mismatch: {key}")
    if _bool(row, "logical_names_complete", key) is not True:
        raise ValueError(f"incomplete logical names: {key}")
    directory_streams = expected_directory_streams(row["type"], workers)
    getdents_calls = _int(row, "validation_getdents_nonempty_calls", key,
                          True)
    retry_runs = _int(row, "validation_readdir_retry_runs", key)
    if getdents_calls < directory_streams or \
            retry_runs != getdents_calls - directory_streams:
        raise ValueError(f"invalid getdents retry attribution: {key}")
    identity = _bool(row, "selected_directory_identity", key)
    if row["condition"] != "fuse" and not identity:
        raise ValueError(f"logical/physical identity mismatch: {key}")
    if row["condition"] == "select" and not identity:
        raise ValueError(f"SELECT identity failure: {key}")
    select_required = _bool(row, "select_required_for_logical_path", key)
    if select_required != (row["condition"] == "select"):
        raise ValueError(f"unverified SELECT view: {key}")


def _validate_bpf(row, key):
    attached = row["condition"] in ("pass", "select")
    if _bool(row, "attachment_stable", key) != attached:
        raise ValueError(f"invalid BPF attachment stability: {key}")
    before = _int(row, "attached_program_id_before", key)
    after = _int(row, "attached_program_id_after", key)
    if attached and (before <= 0 or after != before):
        raise ValueError(f"invalid BPF program identity: {key}")
    if not attached and (before != 0 or after != 0):
        raise ValueError(f"unexpected BPF attachment: {key}")
    before_count = _int(row, "policy_run_count_before", key)
    after_count = _int(row, "policy_run_count_after", key)
    if before_count < 0 or after_count < before_count:
        raise ValueError(f"invalid BPF run count: {key}")
    lookup_runs = _int(row, "validation_lookup_runs", key)
    readdir_runs = _int(row, "validation_readdir_runs", key)
    expected = expected_attribution(row["type"], row["workers"])
    retry_runs = _int(row, "validation_readdir_retry_runs", key)
    if attached:
        if lookup_runs <= 0 or readdir_runs != expected + retry_runs or \
                after_count - before_count != lookup_runs + readdir_runs:
            raise ValueError(f"BPF attribution mismatch: {key}")
    elif lookup_runs != 0 or readdir_runs != 0:
        raise ValueError(f"unexpected BPF attribution: {key}")
    if _bool(row, "bpf_stats_post_timing_only", key) is not True:
        raise ValueError(f"BPF statistics timing gate failed: {key}")


def _validate_fuse(row, key):
    if row["condition"] == "fuse":
        if _int(row, "fuse_status", key) != 0:
            raise ValueError(f"failed FUSE process: {key}")
        if _int(row, "fuse_setup_requests", key, True) <= 0:
            raise ValueError(f"unverified FUSE setup: {key}")
        if _int(row, "fuse_measured_requests", key, True) <= 0:
            raise ValueError(f"unverified measured FUSE requests: {key}")
        if _int(row, "fuse_f_type_before", key) != FUSE_SUPER_MAGIC or \
                _int(row, "fuse_f_type_after", key) != FUSE_SUPER_MAGIC:
            raise ValueError(f"unverified FUSE mount identity: {key}")
        for operation in ("opendir", "readdir", "releasedir"):
            if _int(row, f"fuse_measured_{operation}", key, True) <= 0:
                raise ValueError(f"zero measured FUSE {operation}: {key}")
        if _int(row, "fuse_phase_measured_acks", key) != 1 or \
                _int(row, "fuse_phase_after_acks", key) != 1 or \
                _int(row, "fuse_phase_invalid_commands", key) != 0:
            raise ValueError(f"invalid FUSE phase handshake: {key}")
    else:
        if _int(row, "fuse_status", key) != -1:
            raise ValueError(f"unexpected FUSE process: {key}")
        if _int(row, "fuse_setup_requests", key) != 0:
            raise ValueError(f"unexpected FUSE setup: {key}")
        if _int(row, "fuse_measured_requests", key) != 0:
            raise ValueError(f"unexpected measured FUSE requests: {key}")
        if _int(row, "fuse_f_type_before", key) != 0 or \
                _int(row, "fuse_f_type_after", key) != 0:
            raise ValueError(f"unexpected FUSE mount identity: {key}")
        for operation in ("opendir", "readdir", "releasedir"):
            if _int(row, f"fuse_measured_{operation}", key) != 0:
                raise ValueError(f"unexpected FUSE request: {key}")
        for field in ("fuse_phase_measured_acks", "fuse_phase_after_acks",
                      "fuse_phase_invalid_commands"):
            if _int(row, field, key) != 0:
                raise ValueError(f"unexpected FUSE phase handshake: {key}")


def validate(rows, config):
    expected_count = config["repetitions"] * len(CONDITIONS) * \
        len(config["types"]) * len(config["workers"])
    if len(rows) != expected_count:
        raise ValueError(f"expected {expected_count} rows, found {len(rows)}")
    indexed = {}
    for row in rows:
        key = (row.get("repetition"), row.get("condition"), row.get("type"),
               row.get("workers"))
        try:
            already_indexed = key in indexed
        except TypeError as error:
            raise ValueError(f"malformed cell key: {key}") from error
        if already_indexed:
            raise ValueError(f"duplicate cell: {key}")
        _validate_common(row, config, key)
        _validate_bpf(row, key)
        _validate_fuse(row, key)
        indexed[key] = row
    for repetition in range(1, config["repetitions"] + 1):
        for condition in CONDITIONS:
            for test in config["types"]:
                for workers in config["workers"]:
                    key = (repetition, condition, test, workers)
                    if key not in indexed:
                        raise ValueError(f"missing cell: {key}")
    return indexed


def _percentile(values, probability):
    position = (len(values) - 1) * probability
    lower = math.floor(position)
    upper = math.ceil(position)
    if lower == upper:
        return values[lower]
    weight = position - lower
    return values[lower] * (1 - weight) + values[upper] * weight


def paired_bootstrap_median_ci(numerators, denominators, rng):
    if len(numerators) != len(denominators) or not numerators:
        raise ValueError("paired bootstrap requires a non-empty equal-length pair")
    estimates = []
    for _ in range(BOOTSTRAP_SAMPLES):
        ratios = []
        for _ in range(len(numerators)):
            index = rng.randrange(len(numerators))
            ratios.append(numerators[index] / denominators[index])
        estimates.append(statistics.median(ratios))
    estimates.sort()
    return _percentile(estimates, 0.025), _percentile(estimates, 0.975)


def bootstrap_median_ci(values, rng):
    if not values:
        raise ValueError("bootstrap requires a non-empty sample")
    estimates = []
    for _ in range(BOOTSTRAP_SAMPLES):
        sample = [values[rng.randrange(len(values))]
                  for _ in range(len(values))]
        estimates.append(statistics.median(sample))
    estimates.sort()
    return _percentile(estimates, 0.025), _percentile(estimates, 0.975)


def _metric(indexed, repetitions, test, workers, numerator, denominator):
    nums = [indexed[(rep, numerator, test, workers)]["works_per_second"]
            for rep in range(1, repetitions + 1)]
    dens = [indexed[(rep, denominator, test, workers)]["works_per_second"]
            for rep in range(1, repetitions + 1)]
    return nums, dens


def _ratio_summary(nums, dens, rng):
    ratios = [num / den for num, den in zip(nums, dens)]
    low, high = paired_bootstrap_median_ci(nums, dens, rng)
    return {"median": statistics.median(ratios), "ci_low": low,
            "ci_high": high, "values": ratios}


def summarize(indexed, config, seed=FROZEN_SEED):
    rng = random.Random(seed)
    cells = []
    for test in config["types"]:
        for workers in config["workers"]:
            throughput = {}
            for condition in CONDITIONS:
                values = [indexed[(rep, condition, test, workers)]["works_per_second"]
                          for rep in range(1, config["repetitions"] + 1)]
                low, high = bootstrap_median_ci(values, rng)
                throughput[condition] = {
                    "median": statistics.median(values), "ci_low": low,
                    "ci_high": high, "values": values,
                }
            ratios = {}
            for numerator, denominator in (
                    ("unattached", "stock"), ("pass", "unattached"),
                    ("select", "pass"), ("select", "unattached"),
                    ("select", "fuse")):
                nums, dens = _metric(indexed, config["repetitions"], test,
                                     workers, numerator, denominator)
                ratios[f"{numerator}_over_{denominator}"] = \
                    _ratio_summary(nums, dens, rng)
            fuse_rows = [indexed[(rep, "fuse", test, workers)]
                         for rep in range(1, config["repetitions"] + 1)]
            cells.append({
                "type": test,
                "workers": workers,
                "throughput": throughput,
                "ratios": ratios,
                "fuse_measured_requests": {
                    operation: statistics.median(
                        [row[f"fuse_measured_{operation}"] for row in fuse_rows])
                    for operation in ("opendir", "readdir", "releasedir")
                },
            })
    return cells


def classify(cells):
    primary = [cell["ratios"]["select_over_fuse"] for cell in cells]
    supported = bool(primary) and all(item["ci_low"] > 1 for item in primary)
    contradicted = any(item["ci_high"] <= 1 for item in primary)
    verdict = "supported" if supported else "contradicted" if contradicted else "mixed"
    return {
        "primary_metric": "paired per-block SELECT/FUSE entry-throughput ratio",
        "supported": supported,
        "contradicted": contradicted,
        "verdict": verdict,
        "cells_with_ci_low_above_one": sum(item["ci_low"] > 1 for item in primary),
        "cells_with_ci_high_at_or_below_one": sum(item["ci_high"] <= 1 for item in primary),
    }


def _flat_summary(cell):
    result = {"type": cell["type"], "workers": cell["workers"]}
    for condition in CONDITIONS:
        entry = cell["throughput"][condition]
        for field in ("median", "ci_low", "ci_high"):
            result[f"{condition}_ops_s_{field}"] = entry[field]
    for name, entry in cell["ratios"].items():
        for field in ("median", "ci_low", "ci_high"):
            result[f"{name}_{field}"] = entry[field]
    result.update({f"fuse_measured_{name}": value
                   for name, value in cell["fuse_measured_requests"].items()})
    return result


def write_csv(path, cells):
    rows = [_flat_summary(cell) for cell in cells]
    fields = list(rows[0]) if rows else ["type", "workers"]
    with path.open("w", newline="", encoding="utf-8") as output:
        writer = csv.DictWriter(output, fieldnames=fields)
        writer.writeheader()
        writer.writerows(rows)


def write_report(path, cells, verdict, config, seed):
    lines = [
        "# Corrected FxMark readdir analysis", "",
        f"- Mode: {config['mode']}",
        f"- Paired blocks: {config['repetitions']}",
        f"- Tests: {', '.join(config['types'])}",
        f"- Workers: {', '.join(str(worker) for worker in config['workers'])}",
        f"- Bootstrap: {BOOTSTRAP_SAMPLES} paired resamples, seed {seed}",
        f"- Primary verdict: **{verdict['verdict']}**", "",
        "The primary gate requires every SELECT/FUSE 95% CI lower bound to "
        "exceed 1. Any upper bound at or below 1 is contradictory; all "
        "other complete outcomes are mixed.", "",
        "| Test | Workers | SELECT/FUSE ratio (95% CI) | "
        "FUSE opendir | FUSE readdir | FUSE releasedir |",
        "| --- | ---: | ---: | ---: | ---: | ---: |",
    ]
    for cell in cells:
        ratio = cell["ratios"]["select_over_fuse"]
        requests = cell["fuse_measured_requests"]
        lines.append(
            f"| {cell['type']} | {cell['workers']} | "
            f"{ratio['median']:.3f} [{ratio['ci_low']:.3f}, "
            f"{ratio['ci_high']:.3f}] | {requests['opendir']:.0f} | "
            f"{requests['readdir']:.0f} | {requests['releasedir']:.0f} |"
        )
    lines.extend(["", "## Throughput", "",
                   "| Test | Workers | Stock | Unattached | PASS | SELECT | FUSE |",
                   "| --- | ---: | ---: | ---: | ---: | ---: | ---: |"])
    for cell in cells:
        values = [f"{cell['throughput'][condition]['median']:.3f}"
                  for condition in CONDITIONS]
        lines.append(f"| {cell['type']} | {cell['workers']} | " +
                     " | ".join(values) + " |")
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def write_figure(output, cells):
    colors = {"stock": "#1f2937", "unattached": "#4b5563", "pass": "#0072b2",
              "select": "#009e73", "fuse": "#d55e00"}
    grouped = {(cell["type"], cell["workers"]): cell for cell in cells}
    tests = tuple(dict.fromkeys(cell["type"] for cell in cells))
    workers = tuple(dict.fromkeys(cell["workers"] for cell in cells))
    figure, axes = plt.subplots(1, len(tests), squeeze=False,
                                figsize=(5.2 * len(tests), 3.5))
    axes = axes[0]
    for axis, test in zip(axes, tests):
        for condition in CONDITIONS:
            medians = [grouped[(test, worker)]["throughput"][condition]["median"]
                       for worker in workers]
            lows = [max(0.0, grouped[(test, worker)]["throughput"][condition]["median"] -
                    grouped[(test, worker)]["throughput"][condition]["ci_low"])
                    for worker in workers]
            highs = [max(0.0, grouped[(test, worker)]["throughput"][condition]["ci_high"] -
                     grouped[(test, worker)]["throughput"][condition]["median"])
                     for worker in workers]
            axis.errorbar(workers, medians, yerr=[lows, highs], marker="o",
                          linewidth=1.4, capsize=2.5, color=colors[condition],
                          label=condition)
        axis.set_title(test)
        axis.set_xlabel("Workers")
        axis.set_xticks(workers)
        axis.set_ylabel("Returned entries / second")
        axis.grid(axis="y", color="#d1d5db", linewidth=0.6)
        axis.ticklabel_format(axis="y", style="sci", scilimits=(0, 0))
    handles, labels = axes[0].get_legend_handles_labels()
    figure.legend(handles, labels, loc="upper center", ncol=len(CONDITIONS),
                  frameon=False, bbox_to_anchor=(0.5, 1.03))
    figure.tight_layout(rect=(0, 0, 1, 0.91))
    figure.savefig(output / "throughput.png", dpi=220)
    figure.savefig(output / "throughput.pdf")
    plt.close(figure)


def _csv_values(value, parser):
    values = tuple(parser(item.strip()) for item in value.split(",") if item.strip())
    if not values:
        raise argparse.ArgumentTypeError("comma-separated value cannot be empty")
    return values


def config_from_run(path):
    try:
        run = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise ValueError(f"{path}: invalid run manifest") from error
    if type(run) is not dict or run.get("status") != "completed" or \
            run.get("layout") != "latin-square-boot-matrix":
        raise ValueError(f"{path}: run is not complete")
    matrix = run.get("matrix")
    if type(matrix) is not dict or matrix.get("conditions") != list(CONDITIONS) \
            or matrix.get("types") != list(TYPES) \
            or type(matrix.get("files_per_worker")) is not int \
            or matrix.get("files_per_worker") != FILES_PER_WORKER \
            or type(matrix.get("bpf_stats")) is not int \
            or matrix.get("bpf_stats") != 0 \
            or matrix.get("order") != "rotating-latin-square" \
            or type(matrix.get("kvm_cpus")) is not int \
            or matrix.get("kvm_cpus") != 4 \
            or matrix.get("host_cpu_pin") != "4-7" \
            or matrix.get("affinity") != "exact-vcpu-index-mapping" \
            or matrix.get("external_inventory_gate") is not True:
        raise ValueError(f"{path}: incompatible readdir matrix")
    repetitions = matrix.get("repetitions")
    types = matrix.get("types")
    workers = matrix.get("workers")
    duration = matrix.get("duration_seconds")
    if type(repetitions) is not int or type(duration) is not int or \
            type(workers) is not list or \
            any(type(worker) is not int for worker in workers):
        raise ValueError(f"{path}: invalid readdir matrix types")
    if repetitions == 1 and workers == [1, 4] and duration == 2:
        mode = "preflight"
    elif repetitions == 10 and workers == [1, 2, 4] and duration == 30:
        mode = "formal"
    else:
        raise ValueError(f"{path}: matrix is neither frozen preflight nor formal")
    return make_config(mode, repetitions, types, workers, duration)


def main(argv=None):
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", "--observations", dest="input", required=True,
                        type=Path)
    parser.add_argument("--run", type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--mode", choices=tuple(MODE_DEFAULTS), default="formal")
    parser.add_argument("--expected-repetitions", type=int)
    parser.add_argument("--expected-types",
                        type=lambda value: _csv_values(value, str))
    parser.add_argument("--expected-workers",
                        type=lambda value: _csv_values(value, int))
    parser.add_argument("--duration-seconds", type=int)
    parser.add_argument("--seed", type=int, default=FROZEN_SEED)
    args = parser.parse_args(argv)
    explicit = (args.expected_repetitions, args.expected_types,
                args.expected_workers, args.duration_seconds)
    if args.run and any(value is not None for value in explicit):
        parser.error("--run cannot be combined with explicit matrix arguments")
    config = config_from_run(args.run) if args.run else make_config(
        args.mode, args.expected_repetitions, args.expected_types,
        args.expected_workers, args.duration_seconds)
    if args.run and args.seed != FROZEN_SEED:
        parser.error("--run requires the frozen analysis seed")
    rows = load_rows(args.input)
    indexed = validate(rows, config)
    cells = summarize(indexed, config, args.seed)
    verdict = classify(cells)
    args.output.mkdir(parents=True, exist_ok=True)
    result = {
        "schema": "namei_ext.fxmark_readdir.analysis.v1",
        "input": str(args.input),
        "config": config,
        "bootstrap_samples": BOOTSTRAP_SAMPLES,
        "bootstrap_seed": args.seed,
        "verdict": verdict,
        "cells": cells,
    }
    (args.output / "summary.json").write_text(json.dumps(result, indent=2) + "\n",
                                               encoding="utf-8")
    write_csv(args.output / "summary.csv", cells)
    write_report(args.output / "report.md", cells, verdict, config, args.seed)
    write_figure(args.output, cells)


if __name__ == "__main__":
    main()
