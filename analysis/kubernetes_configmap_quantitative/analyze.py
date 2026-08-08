#!/usr/bin/env python3

import argparse
import json
import math
import random
import statistics
from collections import defaultdict
from pathlib import Path


EVENT = "kubernetes-configmap-quantitative-lifecycle"
MECHANISMS = ("atomicwriter", "namei_ext")
PRIMARY_METRIC = "wall_span_ns"


def load_json(path):
    with path.open(encoding="utf-8") as source:
        return json.load(source)


def load_jsonl(path):
    rows = []
    with path.open(encoding="utf-8") as source:
        for line_number, line in enumerate(source, 1):
            if not line.strip():
                continue
            try:
                rows.append(json.loads(line))
            except json.JSONDecodeError as error:
                raise ValueError(f"{path}:{line_number}: {error}") from error
    return rows


def percentile(values, probability):
    ordered = sorted(values)
    if not ordered:
        raise ValueError("cannot take percentile of an empty sequence")
    position = probability * (len(ordered) - 1)
    lower = math.floor(position)
    upper = math.ceil(position)
    if lower == upper:
        return ordered[lower]
    fraction = position - lower
    return ordered[lower] * (1.0 - fraction) + ordered[upper] * fraction


def bootstrap_median_ci(values, seed=20260807, samples=10000):
    generator = random.Random(seed)
    draws = []
    for _ in range(samples):
        resample = [values[generator.randrange(len(values))]
                    for _ in values]
        draws.append(statistics.median(resample))
    return percentile(draws, 0.025), percentile(draws, 0.975)


def validate(rows, run):
    matrix = run["matrix"]
    boots = int(matrix["boots"])
    pairs = int(matrix["pairs_per_scale_per_boot"])
    scales = [int(value) for value in matrix["scales"]]
    expected = boots * pairs * len(scales) * 2
    if len(rows) != expected:
        raise ValueError(f"expected {expected} lifecycle rows, found {len(rows)}")
    grouped = defaultdict(list)
    for row in rows:
        if row.get("event") != EVENT or row.get("mechanism") not in MECHANISMS:
            raise ValueError("unexpected lifecycle event or mechanism")
        if row.get("pass") is not True or row.get("cleanup_pass") is not True:
            raise ValueError("failed lifecycle row present")
        if row.get(PRIMARY_METRIC, 0) <= 0:
            raise ValueError("non-positive complete lifecycle time")
        if row.get("width") not in scales:
            raise ValueError("undeclared payload width")
        grouped[(row["boot"], row["width"], row["pair"])].append(row)
    expected_groups = boots * pairs * len(scales)
    if len(grouped) != expected_groups:
        raise ValueError("missing or duplicate boot/width/pair groups")
    for key, group in grouped.items():
        if sorted(row["mechanism"] for row in group) != list(MECHANISMS):
            raise ValueError(f"unpaired mechanisms for {key}")
        if sorted(row["order"] for row in group) != [1, 2]:
            raise ValueError(f"invalid condition order for {key}")
    return boots, pairs, scales, grouped


def summarize(rows, run):
    boots, pairs, scales, grouped = validate(rows, run)
    boot_scale_logs = defaultdict(list)
    boot_scale_method = defaultdict(lambda: defaultdict(list))
    pair_rows = []
    for (boot, width, pair), group in sorted(grouped.items()):
        by_mechanism = {row["mechanism"]: row for row in group}
        atomic = by_mechanism["atomicwriter"][PRIMARY_METRIC]
        namei = by_mechanism["namei_ext"][PRIMARY_METRIC]
        ratio = namei / atomic
        boot_scale_logs[(boot, width)].append(math.log(ratio))
        for mechanism, row in by_mechanism.items():
            boot_scale_method[(boot, width)][mechanism].append(
                row[PRIMARY_METRIC])
        pair_rows.append({
            "boot": boot,
            "width": width,
            "pair": pair,
            "atomicwriter_ns": atomic,
            "namei_ext_ns": namei,
            "ratio": ratio,
        })
    per_boot = []
    for (boot, width), logs in sorted(boot_scale_logs.items()):
        methods = boot_scale_method[(boot, width)]
        per_boot.append({
            "boot": boot,
            "width": width,
            "pairs": len(logs),
            "median_log_ratio": statistics.median(logs),
            "ratio": math.exp(statistics.median(logs)),
            "atomicwriter_median_ns": statistics.median(
                methods["atomicwriter"]),
            "namei_ext_median_ns": statistics.median(methods["namei_ext"]),
        })
    scales_summary = []
    for width in scales:
        boot_rows = [row for row in per_boot if row["width"] == width]
        logs = [row["median_log_ratio"] for row in boot_rows]
        center = statistics.median(logs)
        entry = {
            "width": width,
            "boots": len(boot_rows),
            "ratio": math.exp(center),
            "atomicwriter_median_ns": statistics.median(
                row["atomicwriter_median_ns"] for row in boot_rows),
            "namei_ext_median_ns": statistics.median(
                row["namei_ext_median_ns"] for row in boot_rows),
        }
        if boots >= 20:
            lower, upper = bootstrap_median_ci(logs)
            entry["ratio_ci95_lower"] = math.exp(lower)
            entry["ratio_ci95_upper"] = math.exp(upper)
            entry["supports_lower_cost"] = entry["ratio_ci95_upper"] < 1.0
        else:
            entry["ratio_ci95_lower"] = None
            entry["ratio_ci95_upper"] = None
            entry["supports_lower_cost"] = None
        scales_summary.append(entry)
    primary = next(entry for entry in scales_summary
                   if entry["width"] == max(scales))
    if boots < 20:
        verdict = "preflight-complete"
    elif primary["supports_lower_cost"]:
        verdict = "supports-lower-cost-at-primary-scale"
    else:
        verdict = "does-not-support-lower-cost-at-primary-scale"
    return {
        "event": "kubernetes-configmap-quantitative-analysis",
        "boots": boots,
        "pairs_per_scale_per_boot": pairs,
        "lifecycle_rows": len(rows),
        "scales": scales_summary,
        "primary_width": max(scales),
        "primary_metric": PRIMARY_METRIC,
        "verdict": verdict,
    }, per_boot, pair_rows


def write_json(path, value):
    with path.open("w", encoding="utf-8") as output:
        json.dump(value, output, indent=2, sort_keys=True)
        output.write("\n")


def write_jsonl(path, values):
    with path.open("w", encoding="utf-8") as output:
        for value in values:
            output.write(json.dumps(value, sort_keys=True) + "\n")


def write_report(path, summary):
    lines = [
        "# Kubernetes ConfigMap Quantitative Result",
        "",
        f"Boots: {summary['boots']}",
        f"Lifecycle rows: {summary['lifecycle_rows']}",
        f"Primary metric: {summary['primary_metric']}",
        f"Verdict: {summary['verdict']}",
        "",
        "| Width | AtomicWriter median (ms) | namei_ext median (ms) | Ratio | 95% CI |",
        "| ---: | ---: | ---: | ---: | ---: |",
    ]
    for entry in summary["scales"]:
        if entry["ratio_ci95_lower"] is None:
            interval = "preflight only"
        else:
            interval = (f"[{entry['ratio_ci95_lower']:.3f}, "
                        f"{entry['ratio_ci95_upper']:.3f}]")
        lines.append(
            f"| {entry['width']} | "
            f"{entry['atomicwriter_median_ns'] / 1_000_000:.3f} | "
            f"{entry['namei_ext_median_ns'] / 1_000_000:.3f} | "
            f"{entry['ratio']:.3f} | {interval} |")
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def analyze(run_dir):
    run = load_json(run_dir / "run.json")
    raw_rows = load_jsonl(run_dir / "observations.jsonl")
    allowed = {
        EVENT,
        "kubernetes-configmap-quantitative-identity",
        "kubernetes-configmap-quantitative-lower",
        "kubernetes-configmap-quantitative-unmanaged-directory",
        "kubernetes-configmap-quantitative-materialization-audit",
    }
    for row in raw_rows:
        if row.get("event") not in allowed or row.get("pass") is not True:
            raise ValueError("unexpected or failed raw observation")
    rows = [row for row in raw_rows if row["event"] == EVENT]
    summary, per_boot, pairs = summarize(rows, run)
    analysis = run_dir / "analysis"
    analysis.mkdir()
    write_json(analysis / "summary.json", summary)
    write_jsonl(analysis / "per-boot.jsonl", per_boot)
    write_jsonl(analysis / "pairs.jsonl", pairs)
    write_report(analysis / "report.md", summary)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--run-dir", required=True, type=Path)
    arguments = parser.parse_args()
    analyze(arguments.run_dir)


if __name__ == "__main__":
    main()
