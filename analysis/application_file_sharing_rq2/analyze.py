#!/usr/bin/env python3
"""Analyze paired official-portal/namei_ext RQ2 boots."""

from __future__ import annotations

import argparse
import csv
import json
import math
import random
import re
import statistics
from pathlib import Path
from typing import Any


BOOT_RE = re.compile(
    r"^pair-(?P<pair>[0-9]{2})-order-(?P<order>[0-9]{2})-"
    r"(?P<mechanism>xdg-document-portal|namei_ext)$"
)
OPERATIONS = (
    "total_ns",
    "document_stat_ns",
    "payload_stat_ns",
    "open_read_close_ns",
    "readdir_ns",
)
RESOURCE_FIELDS = (
    "runtime_ns",
    "runqueue_wait_ns",
    "timeslices",
    "voluntary_context_switches",
    "involuntary_context_switches",
)
FUSE_OPCODE_NAMES = {
    1: "LOOKUP",
    3: "GETATTR",
    14: "OPEN",
    15: "READ",
    18: "RELEASE",
    27: "OPENDIR",
    28: "READDIR",
    29: "RELEASEDIR",
    44: "READDIRPLUS",
    52: "STATX",
}


def load_json(path: Path) -> Any:
    with path.open(encoding="utf-8") as source:
        return json.load(source)


def load_jsonl(path: Path) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    with path.open(encoding="utf-8") as source:
        for line_number, line in enumerate(source, 1):
            if not line.strip():
                continue
            try:
                row = json.loads(line)
            except json.JSONDecodeError as error:
                raise ValueError(f"{path}:{line_number}: {error}") from error
            if not isinstance(row, dict):
                raise ValueError(f"{path}:{line_number}: expected object")
            rows.append(row)
    return rows


def percentile(values: list[int], quantile: float) -> int:
    if not values:
        raise ValueError("percentile of empty values")
    ordered = sorted(values)
    index = max(0, math.ceil(quantile * len(ordered)) - 1)
    return ordered[index]


def median(values: list[int]) -> float:
    if not values:
        raise ValueError("median of empty values")
    return float(statistics.median(values))


def snapshot_delta(
    rows: list[dict[str, Any]], mechanism: str, role: str
) -> dict[str, int]:
    snapshots: dict[str, dict[int, dict[str, Any]]] = {"before": {}, "after": {}}
    for row in rows:
        if (
            row.get("event") != "application-file-sharing-rq2-thread"
            or row.get("mechanism") != mechanism
            or row.get("role") != role
        ):
            continue
        phase = row.get("phase")
        if phase not in snapshots:
            continue
        tid = int(row["tid"])
        if tid in snapshots[phase]:
            raise ValueError(f"duplicate {role} {phase} tid {tid}")
        snapshots[phase][tid] = row
    if not snapshots["before"] or snapshots["before"].keys() != snapshots["after"].keys():
        raise ValueError(f"unstable or missing {mechanism}/{role} thread snapshot")
    result = {"threads": len(snapshots["before"])}
    for field in RESOURCE_FIELDS:
        before = sum(int(row[field]) for row in snapshots["before"].values())
        after = sum(int(row[field]) for row in snapshots["after"].values())
        if after < before:
            raise ValueError(f"counter regressed: {mechanism}/{role}/{field}")
        result[field] = after - before
    return result


def counter_delta(
    rows: list[dict[str, Any]], event: str, key_field: str
) -> dict[str, int]:
    snapshots: dict[str, dict[str, int]] = {"before": {}, "after": {}}
    for row in rows:
        if row.get("event") != event:
            continue
        phase = row.get("phase")
        if phase not in snapshots:
            continue
        key = str(row[key_field])
        if key in snapshots[phase]:
            raise ValueError(f"duplicate {event} {phase} key {key}")
        snapshots[phase][key] = int(row["value"])
    if not snapshots["before"] or snapshots["before"].keys() != snapshots["after"].keys():
        raise ValueError(f"incomplete {event} snapshots")
    deltas: dict[str, int] = {}
    for key in snapshots["before"]:
        before = snapshots["before"][key]
        after = snapshots["after"][key]
        if after < before:
            raise ValueError(f"counter regressed: {event}/{key}")
        deltas[key] = after - before
    return deltas


def analyze_boot(
    boot: Path,
    pair: int,
    order: int,
    mechanism: str,
    expected_warmup: int,
    expected_samples: int,
) -> dict[str, Any]:
    rows = load_jsonl(boot / "observations.jsonl")
    failed = [row for row in rows if "pass" in row and row["pass"] is not True]
    if failed:
        raise ValueError(f"{boot}: contains failed observations")
    samples = [
        row
        for row in rows
        if row.get("event") == "application-file-sharing-rq2-sample"
        and row.get("mechanism") == mechanism
        and row.get("stream") == "policy-view"
    ]
    direct = [
        row
        for row in rows
        if row.get("event") == "application-file-sharing-rq2-sample"
        and row.get("mechanism") == mechanism
        and row.get("stream") == "direct-ext4"
    ]
    if len(samples) != expected_samples or len(direct) != expected_samples:
        raise ValueError(
            f"{boot}: expected {expected_samples} policy/direct samples, "
            f"found {len(samples)}/{len(direct)}"
        )
    for stream_name, stream_rows in (("policy-view", samples), ("direct-ext4", direct)):
        indices = sorted(int(row.get("sample", -1)) for row in stream_rows)
        if indices != list(range(expected_samples)):
            raise ValueError(f"{boot}: invalid {stream_name} sample identity")
        if any(row.get("phase") != "measured" for row in stream_rows):
            raise ValueError(f"{boot}: invalid {stream_name} phase")
    summary = [
        row
        for row in rows
        if row.get("event") == "application-file-sharing-rq2-summary"
        and row.get("mechanism") == mechanism
    ]
    if (
        len(summary) != 1
        or summary[0].get("pass") is not True
        or int(summary[0].get("document_id_bytes", -1)) != 22
        or int(summary[0].get("payload_bytes", -1)) != 27
        or int(summary[0].get("warmup_transactions", -1)) != expected_warmup
        or int(summary[0].get("measured_transactions", -1)) != expected_samples
        or int(summary[0].get("direct_transactions", -1)) != expected_samples
    ):
        raise ValueError(f"{boot}: missing passing RQ2 summary")
    operation_summary: dict[str, dict[str, float | int]] = {}
    direct_summary: dict[str, dict[str, float | int]] = {}
    for operation in OPERATIONS:
        values = [int(row[operation]) for row in samples]
        direct_values = [int(row[operation]) for row in direct]
        operation_summary[operation] = {
            "median": median(values),
            "p95": percentile(values, 0.95),
            "p99": percentile(values, 0.99),
        }
        direct_summary[operation] = {
            "median": median(direct_values),
            "p95": percentile(direct_values, 0.95),
            "p99": percentile(direct_values, 0.99),
        }
    controls: dict[str, int] = {}
    for row in rows:
        if (
            row.get("event") == "application-file-sharing-rq2-control"
            and row.get("mechanism") == mechanism
        ):
            controls[str(row["operation"])] = int(row["latency_ns"])
    if controls.keys() != {"grant", "revoke"}:
        raise ValueError(f"{boot}: missing grant/revoke observations")
    resources = {"client": snapshot_delta(rows, mechanism, "client")}
    counters: dict[str, dict[str, int]] = {}
    if mechanism == "xdg-document-portal":
        resources["portal-daemon"] = snapshot_delta(
            rows, mechanism, "portal-daemon"
        )
        counters["fuse_opcode"] = counter_delta(
            rows,
            "application-file-sharing-rq2-fuse-counter",
            "opcode",
        )
        file_requests = sum(
            counters["fuse_opcode"].get(str(opcode), 0) for opcode in (14, 15)
        )
        directory_requests = sum(
            counters["fuse_opcode"].get(str(opcode), 0)
            for opcode in (27, 28, 44)
        )
        if file_requests <= 0 or directory_requests <= 0:
            raise ValueError(
                f"{boot}: missing measured FUSE file or directory request"
            )
    else:
        counters["bpf"] = counter_delta(
            rows,
            "application-file-sharing-rq2-bpf-counter",
            "counter",
        )
        if counters["bpf"].get("select", 0) <= 0 or counters["bpf"].get(
            "visible_readdir", 0
        ) <= 0:
            raise ValueError(
                f"{boot}: missing select/visible_readdir BPF engagement"
            )
    return {
        "pair": pair,
        "order": order,
        "mechanism": mechanism,
        "boot": str(boot),
        "samples": expected_samples,
        "operations": operation_summary,
        "direct": direct_summary,
        "controls": controls,
        "resources": resources,
        "counters": counters,
    }


def geometric_mean(log_values: list[float]) -> float:
    if not log_values:
        raise ValueError("geometric mean of empty values")
    return math.exp(statistics.fmean(log_values))


def bootstrap_ci(
    log_values: list[float], seed: int, repetitions: int
) -> tuple[float, float]:
    if repetitions <= 0:
        raise ValueError("bootstrap repetitions must be positive")
    random_source = random.Random(seed)
    estimates = []
    for _ in range(repetitions):
        sample = [random_source.choice(log_values) for _ in log_values]
        estimates.append(geometric_mean(sample))
    estimates.sort()
    lower = estimates[max(0, math.floor(0.025 * repetitions))]
    upper = estimates[min(repetitions - 1, math.ceil(0.975 * repetitions) - 1)]
    return lower, upper


def ratio_summary(
    log_values: list[float], seed: int, bootstrap: int
) -> dict[str, float]:
    lower, upper = bootstrap_ci(log_values, seed, bootstrap)
    return {
        "portal_over_namei_ext_geomean": geometric_mean(log_values),
        "bootstrap_95_lower": lower,
        "bootstrap_95_upper": upper,
    }


def scalar_summary(values: list[float]) -> dict[str, float]:
    if not values:
        raise ValueError("summary of empty values")
    ordered = sorted(values)
    p95_index = max(0, math.ceil(0.95 * len(ordered)) - 1)
    return {
        "median": float(statistics.median(values)),
        "p95": ordered[p95_index],
        "minimum": min(values),
        "maximum": max(values),
    }


def analyze_run(run_dir: Path, seed: int, bootstrap: int) -> dict[str, Any]:
    run = load_json(run_dir / "run.json")
    matrix = run.get("matrix", {})
    expected_pairs = int(matrix["pairs"])
    expected_warmup = int(matrix["warmup"])
    expected_samples = int(matrix["samples"])
    boots: list[dict[str, Any]] = []
    for boot in sorted((run_dir / "boots").iterdir()):
        if not boot.is_dir():
            continue
        match = BOOT_RE.fullmatch(boot.name)
        if not match:
            raise ValueError(f"unexpected boot directory: {boot.name}")
        boots.append(
            analyze_boot(
                boot,
                int(match.group("pair")),
                int(match.group("order")),
                match.group("mechanism"),
                expected_warmup,
                expected_samples,
            )
        )
    if len(boots) != 2 * expected_pairs:
        raise ValueError(f"expected {2 * expected_pairs} boots, found {len(boots)}")
    by_pair: dict[int, dict[str, dict[str, Any]]] = {}
    for boot in boots:
        pair = by_pair.setdefault(int(boot["pair"]), {})
        mechanism = str(boot["mechanism"])
        if mechanism in pair:
            raise ValueError(f"duplicate pair {boot['pair']} mechanism {mechanism}")
        pair[mechanism] = boot
    if sorted(by_pair) != list(range(1, expected_pairs + 1)):
        raise ValueError("pair numbers are not contiguous")
    pairs: list[dict[str, Any]] = []
    operation_logs: dict[str, list[float]] = {operation: [] for operation in OPERATIONS}
    tail_logs: dict[str, list[float]] = {"p95": [], "p99": []}
    direct_logs: list[float] = []
    for pair_number, mechanisms in sorted(by_pair.items()):
        if mechanisms.keys() != {"xdg-document-portal", "namei_ext"}:
            raise ValueError(f"pair {pair_number}: incomplete mechanisms")
        portal = mechanisms["xdg-document-portal"]
        namei = mechanisms["namei_ext"]
        ratios: dict[str, float] = {}
        for operation in OPERATIONS:
            portal_value = float(portal["operations"][operation]["median"])
            namei_value = float(namei["operations"][operation]["median"])
            ratio = portal_value / namei_value
            ratios[operation] = ratio
            operation_logs[operation].append(math.log(ratio))
        tail_ratios = {}
        for percentile_name in tail_logs:
            tail_ratio = float(
                portal["operations"]["total_ns"][percentile_name]
            ) / float(namei["operations"]["total_ns"][percentile_name])
            tail_ratios[percentile_name] = tail_ratio
            tail_logs[percentile_name].append(math.log(tail_ratio))
        direct_ratio = float(portal["direct"]["total_ns"]["median"]) / float(
            namei["direct"]["total_ns"]["median"]
        )
        direct_logs.append(math.log(direct_ratio))
        pairs.append(
            {
                "pair": pair_number,
                "portal_order": portal["order"],
                "namei_ext_order": namei["order"],
                "ratios": ratios,
                "tail_ratios": tail_ratios,
                "direct_total_ratio": direct_ratio,
            }
        )
    ratios_summary: dict[str, dict[str, float]] = {}
    for index, operation in enumerate(OPERATIONS):
        ratios_summary[operation] = ratio_summary(
            operation_logs[operation], seed + index, bootstrap
        )
    tail_summary = {
        name: ratio_summary(values, seed + 100 + index, bootstrap)
        for index, (name, values) in enumerate(tail_logs.items())
    }
    direct_summary = ratio_summary(
        direct_logs, seed + len(OPERATIONS), bootstrap
    )
    direct_summary["portal_boot_over_namei_ext_boot_geomean"] = (
        direct_summary.pop("portal_over_namei_ext_geomean")
    )

    resource_summary: dict[str, dict[str, dict[str, dict[str, float]]]] = {}
    for mechanism in ("xdg-document-portal", "namei_ext"):
        mechanism_boots = [boot for boot in boots if boot["mechanism"] == mechanism]
        roles = sorted(
            {
                role
                for boot in mechanism_boots
                for role in boot["resources"].keys()
            }
        )
        resource_summary[mechanism] = {}
        for role in roles:
            resource_summary[mechanism][role] = {}
            for field in RESOURCE_FIELDS:
                per_transaction = [
                    float(boot["resources"][role][field]) / expected_samples
                    for boot in mechanism_boots
                ]
                resource_summary[mechanism][role][field] = scalar_summary(
                    per_transaction
                )

    control_summary: dict[str, dict[str, dict[str, float]]] = {}
    for mechanism in ("xdg-document-portal", "namei_ext"):
        mechanism_boots = [boot for boot in boots if boot["mechanism"] == mechanism]
        control_summary[mechanism] = {
            operation: scalar_summary(
                [float(boot["controls"][operation]) for boot in mechanism_boots]
            )
            for operation in ("grant", "revoke")
        }

    counter_summary: dict[str, dict[str, dict[str, float] | str]] = {
        "xdg-document-portal": {},
        "namei_ext": {},
    }
    portal_boots = [boot for boot in boots if boot["mechanism"] == "xdg-document-portal"]
    for opcode in sorted(
        {
            int(opcode)
            for boot in portal_boots
            for opcode in boot["counters"]["fuse_opcode"]
        }
    ):
        values = [
            float(boot["counters"]["fuse_opcode"].get(str(opcode), 0))
            / expected_samples
            for boot in portal_boots
        ]
        if any(values):
            counter_summary["xdg-document-portal"][str(opcode)] = {
                "name": FUSE_OPCODE_NAMES.get(opcode, f"OPCODE_{opcode}"),
                **scalar_summary(values),
            }
    namei_boots = [boot for boot in boots if boot["mechanism"] == "namei_ext"]
    for counter in sorted(
        {
            counter
            for boot in namei_boots
            for counter in boot["counters"]["bpf"]
        }
    ):
        values = [
            float(boot["counters"]["bpf"].get(counter, 0)) / expected_samples
            for boot in namei_boots
        ]
        if any(values):
            counter_summary["namei_ext"][counter] = scalar_summary(values)

    arm_order: dict[str, dict[str, float | int] | None] = {}
    for portal_order in (1, 2):
        values = [
            math.log(float(pair["ratios"]["total_ns"]))
            for pair in pairs
            if int(pair["portal_order"]) == portal_order
        ]
        arm_order["portal_first" if portal_order == 1 else "namei_ext_first"] = (
            {
                "pairs": len(values),
                "portal_over_namei_ext_geomean": geometric_mean(values),
            }
            if values
            else None
        )
    return {
        "schema": "namei_ext.application_file_sharing_rq2_official.summary.v1",
        "pairs": expected_pairs,
        "samples_per_boot": expected_samples,
        "bootstrap_repetitions": bootstrap,
        "bootstrap_seed": seed,
        "primary": ratios_summary["total_ns"],
        "operation_ratios": ratios_summary,
        "transaction_tail_ratios": tail_summary,
        "direct_total_ratio": direct_summary,
        "resources_per_transaction": resource_summary,
        "controls_ns": control_summary,
        "counters_per_transaction": counter_summary,
        "arm_order_sensitivity": arm_order,
        "paired_observations": pairs,
        "boots": boots,
    }


def write_outputs(run_dir: Path, summary: dict[str, Any]) -> None:
    output = run_dir / "analysis"
    output.mkdir(parents=True, exist_ok=True)
    with (output / "summary.json").open("w", encoding="utf-8") as destination:
        json.dump(summary, destination, indent=2, sort_keys=True)
        destination.write("\n")
    with (output / "pairs.csv").open("w", encoding="utf-8", newline="") as destination:
        writer = csv.writer(destination)
        writer.writerow(
            [
                "pair",
                "portal_order",
                "namei_ext_order",
                "portal_over_namei_ext_total",
                "portal_over_namei_ext_p95",
                "portal_over_namei_ext_p99",
                "direct_total_ratio",
            ]
        )
        for pair in summary["paired_observations"]:
            writer.writerow(
                [
                    pair["pair"],
                    pair["portal_order"],
                    pair["namei_ext_order"],
                    pair["ratios"]["total_ns"],
                    pair["tail_ratios"]["p95"],
                    pair["tail_ratios"]["p99"],
                    pair["direct_total_ratio"],
                ]
            )
    with (output / "decomposition.csv").open(
        "w", encoding="utf-8", newline=""
    ) as destination:
        writer = csv.writer(destination)
        writer.writerow(["metric", "ratio", "ci95_lower", "ci95_upper"])
        for operation in OPERATIONS:
            result = summary["operation_ratios"][operation]
            writer.writerow(
                [
                    operation,
                    result["portal_over_namei_ext_geomean"],
                    result["bootstrap_95_lower"],
                    result["bootstrap_95_upper"],
                ]
            )
        for tail in ("p95", "p99"):
            result = summary["transaction_tail_ratios"][tail]
            writer.writerow(
                [
                    f"total_ns_{tail}",
                    result["portal_over_namei_ext_geomean"],
                    result["bootstrap_95_lower"],
                    result["bootstrap_95_upper"],
                ]
            )
    with (output / "resources.csv").open(
        "w", encoding="utf-8", newline=""
    ) as destination:
        writer = csv.writer(destination)
        writer.writerow(
            ["mechanism", "role", "metric", "median_per_transaction", "p95"]
        )
        for mechanism, roles in summary["resources_per_transaction"].items():
            for role, metrics in roles.items():
                for metric, result in metrics.items():
                    writer.writerow(
                        [mechanism, role, metric, result["median"], result["p95"]]
                    )
    with (output / "counters.csv").open(
        "w", encoding="utf-8", newline=""
    ) as destination:
        writer = csv.writer(destination)
        writer.writerow(
            ["mechanism", "counter", "name", "median_per_transaction", "p95"]
        )
        for mechanism, counters in summary["counters_per_transaction"].items():
            for counter, result in counters.items():
                writer.writerow(
                    [
                        mechanism,
                        counter,
                        result.get("name", counter),
                        result["median"],
                        result["p95"],
                    ]
                )
    with (output / "controls.csv").open(
        "w", encoding="utf-8", newline=""
    ) as destination:
        writer = csv.writer(destination)
        writer.writerow(["mechanism", "operation", "median_ns", "p95_ns"])
        for mechanism, controls in summary["controls_ns"].items():
            for operation, result in controls.items():
                writer.writerow(
                    [mechanism, operation, result["median"], result["p95"]]
                )

    import matplotlib

    matplotlib.use("Agg")
    import matplotlib.pyplot as plt

    labels = [
        "Total",
        "Doc stat",
        "Payload stat",
        "Open/read",
        "Readdir",
    ]
    results = [summary["operation_ratios"][operation] for operation in OPERATIONS]
    values = [result["portal_over_namei_ext_geomean"] for result in results]
    lower = [
        value - result["bootstrap_95_lower"]
        for value, result in zip(values, results)
    ]
    upper = [
        result["bootstrap_95_upper"] - value
        for value, result in zip(values, results)
    ]
    figure, axis = plt.subplots(figsize=(6.8, 3.2))
    positions = list(range(len(labels)))
    axis.errorbar(
        positions,
        values,
        yerr=[lower, upper],
        fmt="o",
        color="#1f4e79",
        ecolor="#555555",
        capsize=3,
        linewidth=1.2,
    )
    axis.axhline(1.0, color="#a33a2b", linewidth=1.0, linestyle="--")
    axis.set_xticks(positions, labels)
    axis.set_ylabel("Portal / namei_ext latency")
    axis.grid(axis="y", color="#d9d9d9", linewidth=0.7)
    axis.spines[["top", "right"]].set_visible(False)
    figure.tight_layout()
    figure.savefig(output / "latency-decomposition.pdf")
    figure.savefig(output / "latency-decomposition.png", dpi=180)
    plt.close(figure)

    primary = summary["primary"]
    direct = summary["direct_total_ratio"]
    p95 = summary["transaction_tail_ratios"]["p95"]
    p99 = summary["transaction_tail_ratios"]["p99"]
    order = summary["arm_order_sensitivity"]
    operation_lines = [
        "| Operation | Portal/namei_ext | 95% CI |",
        "|---|---:|---:|",
    ]
    for operation in OPERATIONS:
        result = summary["operation_ratios"][operation]
        operation_lines.append(
            f"| {operation} | {result['portal_over_namei_ext_geomean']:.4f} | "
            f"{result['bootstrap_95_lower']:.4f}-{result['bootstrap_95_upper']:.4f} |"
        )
    report = (
        "# Official Documents Portal RQ2 Result\n\n"
        f"Fresh-boot pairs: {summary['pairs']}\n\n"
        f"Samples per boot: {summary['samples_per_boot']}\n\n"
        "Primary portal/namei_ext transaction-latency ratio: "
        f"{primary['portal_over_namei_ext_geomean']:.4f} "
        f"(pair-bootstrap 95% CI {primary['bootstrap_95_lower']:.4f}-"
        f"{primary['bootstrap_95_upper']:.4f}).\n\n"
        f"Transaction p95 ratio: {p95['portal_over_namei_ext_geomean']:.4f} "
        f"(95% CI {p95['bootstrap_95_lower']:.4f}-"
        f"{p95['bootstrap_95_upper']:.4f}).\n\n"
        f"Transaction p99 ratio: {p99['portal_over_namei_ext_geomean']:.4f} "
        f"(95% CI {p99['bootstrap_95_lower']:.4f}-"
        f"{p99['bootstrap_95_upper']:.4f}).\n\n"
        "Direct-ext4 portal-boot/namei_ext-boot sensitivity ratio: "
        f"{direct['portal_boot_over_namei_ext_boot_geomean']:.4f} "
        f"(95% CI {direct['bootstrap_95_lower']:.4f}-"
        f"{direct['bootstrap_95_upper']:.4f}).\n\n"
        + "\n".join(operation_lines)
        + "\n\n"
        + f"Arm-order sensitivity: {json.dumps(order, sort_keys=True)}.\n\n"
        + "Detailed per-transaction resources, opcode/action counts, and "
        "grant/revoke observations are in `resources.csv`, `counters.csv`, "
        "and `controls.csv`.\n\n"
        "Interpretation scope: this official-source row tests W1 external "
        "validity. Placement causality remains limited to the separate "
        "feature-equivalent FUSE experiments.\n"
    )
    (output / "report.md").write_text(report, encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--run-dir", required=True, type=Path)
    parser.add_argument("--seed", required=True, type=int)
    parser.add_argument("--bootstrap", type=int, default=10_000)
    arguments = parser.parse_args()
    summary = analyze_run(arguments.run_dir.resolve(), arguments.seed, arguments.bootstrap)
    write_outputs(arguments.run_dir.resolve(), summary)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
