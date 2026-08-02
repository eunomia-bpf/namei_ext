#!/usr/bin/env python3

import argparse
import csv
import json
import math
import random
import statistics
from pathlib import Path


CONDITIONS = ("namei_ext", "fuse")


def read_jsonl(path):
    rows = []
    with Path(path).open(encoding="utf-8") as source:
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
    position = (len(ordered) - 1) * probability
    lower = math.floor(position)
    upper = math.ceil(position)
    if lower == upper:
        return ordered[lower]
    fraction = position - lower
    return ordered[lower] * (1.0 - fraction) + ordered[upper] * fraction


def bootstrap_geomean_ci(log_ratios, seed, iterations=10000):
    random_source = random.Random(seed)
    count = len(log_ratios)
    estimates = []
    for _ in range(iterations):
        sample = [log_ratios[random_source.randrange(count)] for _ in range(count)]
        estimates.append(math.exp(statistics.fmean(sample)))
    return percentile(estimates, 0.025), percentile(estimates, 0.975)


def analyze(observations, run, launches, seed):
    matrix = run.get("matrix", {})
    repetitions = matrix.get("repetitions")
    samples_per_boot = matrix.get("measured_samples_per_boot")
    if not isinstance(repetitions, int) or repetitions < 1:
        raise ValueError("run matrix has no positive repetition count")
    if not isinstance(samples_per_boot, int) or samples_per_boot < 1:
        raise ValueError("run matrix has no positive measured sample count")
    if matrix.get("conditions") != list(CONDITIONS):
        raise ValueError("run matrix conditions do not match the frozen protocol")
    if any(row.get("pass") is not True for row in observations):
        raise ValueError("correctness or engagement oracle failed")

    expected_launches = repetitions * len(CONDITIONS)
    if len(launches) != expected_launches:
        raise ValueError("launch-order row count does not match the run matrix")
    expected_order = []
    for repetition in range(1, repetitions + 1):
        order = CONDITIONS if repetition % 2 else tuple(reversed(CONDITIONS))
        expected_order.extend((repetition, condition) for condition in order)
    observed_order = [
        (row.get("repetition"), row.get("condition")) for row in launches
    ]
    if observed_order != expected_order:
        raise ValueError("launch order does not match alternating paired boots")

    measured = {}
    for row in observations:
        if row.get("event") != "spindle-staging-rq2-sample":
            continue
        if row.get("phase") != "measured":
            continue
        key = (row.get("repetition"), row.get("condition"))
        duration_ns = row.get("duration_ns")
        iteration = row.get("iteration")
        if (
            key[0] not in range(1, repetitions + 1)
            or key[1] not in CONDITIONS
            or not isinstance(duration_ns, int)
            or duration_ns <= 0
            or not isinstance(iteration, int)
            or iteration < 1
        ):
            raise ValueError("invalid measured sample")
        bucket = measured.setdefault(key, {})
        if iteration in bucket:
            raise ValueError(f"duplicate iteration {iteration} for {key}")
        bucket[iteration] = duration_ns

    boot_rows = []
    pair_rows = []
    log_ratios = []
    for repetition in range(1, repetitions + 1):
        medians = {}
        for condition in CONDITIONS:
            values_by_iteration = measured.get((repetition, condition), {})
            if len(values_by_iteration) != samples_per_boot:
                raise ValueError(
                    f"block {repetition} {condition} has "
                    f"{len(values_by_iteration)} samples; "
                    f"expected {samples_per_boot}"
                )
            expected_iterations = set(range(1, samples_per_boot + 1))
            if set(values_by_iteration) != expected_iterations:
                raise ValueError(
                    f"block {repetition} {condition} iterations are not 1.."
                    f"{samples_per_boot}"
                )
            values = [
                values_by_iteration[iteration]
                for iteration in range(1, samples_per_boot + 1)
            ]
            median_ns = statistics.median(values)
            medians[condition] = median_ns
            boot_rows.append(
                {
                    "repetition": repetition,
                    "condition": condition,
                    "samples": len(values),
                    "median_ns": median_ns,
                    "minimum_ns": min(values),
                    "maximum_ns": max(values),
                }
            )
        ratio = medians["fuse"] / medians["namei_ext"]
        log_ratios.append(math.log(ratio))
        pair_rows.append(
            {
                "repetition": repetition,
                "namei_ext_median_ns": medians["namei_ext"],
                "fuse_median_ns": medians["fuse"],
                "fuse_over_namei_ext": ratio,
            }
        )

    point = math.exp(statistics.fmean(log_ratios))
    lower, upper = bootstrap_geomean_ci(log_ratios, seed)
    if lower > 1.0:
        verdict = "supported"
    elif upper < 1.0:
        verdict = "contradicted"
    else:
        verdict = "inconclusive"

    fuse_resources = [
        row
        for row in observations
        if row.get("event") == "spindle-staging-rq2-fuse-resource"
    ]
    if len(fuse_resources) != repetitions:
        raise ValueError("one FUSE resource window is required per FUSE boot")

    return {
        "schema": "namei_ext.spindle_staging_rq2.summary.v1",
        "unit": "fresh-boot median of measured loader launches",
        "repetitions": repetitions,
        "measured_samples_per_boot": samples_per_boot,
        "boot_rows": boot_rows,
        "pair_rows": pair_rows,
        "primary": {
            "metric": "fuse_over_namei_ext_loader_latency",
            "geometric_mean_ratio": point,
            "paired_bootstrap_95_ci": [lower, upper],
            "bootstrap_iterations": 10000,
            "seed": seed,
            "verdict": verdict,
        },
        "fuse_daemon": {
            "median_cpu_runtime_ns": statistics.median(
                row["cpu_runtime_ns"] for row in fuse_resources
            ),
            "median_voluntary_context_switches": statistics.median(
                row["voluntary_context_switches"] for row in fuse_resources
            ),
            "median_involuntary_context_switches": statistics.median(
                row["involuntary_context_switches"] for row in fuse_resources
            ),
        },
        "scope": (
            "One-node Spindle source-derived final-object selection; no claim "
            "about Spindle distribution, cache population scalability, or MPI scale."
        ),
    }


def write_outputs(summary, output):
    output = Path(output)
    output.mkdir(parents=True, exist_ok=False)
    (output / "summary.json").write_text(
        json.dumps(summary, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    with (output / "summary.csv").open("w", newline="", encoding="utf-8") as target:
        writer = csv.DictWriter(
            target,
            fieldnames=(
                "repetition",
                "namei_ext_median_ns",
                "fuse_median_ns",
                "fuse_over_namei_ext",
            ),
        )
        writer.writeheader()
        writer.writerows(summary["pair_rows"])
    primary = summary["primary"]
    lower, upper = primary["paired_bootstrap_95_ci"]
    report = [
        "# Spindle Final-Object Selection: namei_ext vs FUSE",
        "",
        f"Fresh boot pairs: {summary['repetitions']}",
        f"Measured loader launches per boot: {summary['measured_samples_per_boot']}",
        (
            "FUSE/namei_ext geometric-mean latency ratio: "
            f"{primary['geometric_mean_ratio']:.3f}x "
            f"(paired-bootstrap 95% CI {lower:.3f}--{upper:.3f})"
        ),
        f"Hypothesis verdict: {primary['verdict']}",
        (
            "Median FUSE daemon CPU time in the matched measurement window: "
            f"{summary['fuse_daemon']['median_cpu_runtime_ns'] / 1e6:.3f} ms"
        ),
        "",
        f"Scope: {summary['scope']}",
    ]
    (output / "report.md").write_text("\n".join(report) + "\n", encoding="utf-8")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True)
    parser.add_argument("--run", required=True)
    parser.add_argument("--launch-order", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--seed", required=True, type=int)
    arguments = parser.parse_args()

    observations = read_jsonl(arguments.input)
    launches = read_jsonl(arguments.launch_order)
    with Path(arguments.run).open(encoding="utf-8") as source:
        run = json.load(source)
    summary = analyze(observations, run, launches, arguments.seed)
    write_outputs(summary, arguments.output)


if __name__ == "__main__":
    main()
