#!/usr/bin/env python3

import json
import tempfile
import unittest
from pathlib import Path

import analyze


class AgentWorkspaceAnalysisTests(unittest.TestCase):
    def build_complete_rows(self, repetitions):
        root = Path(__file__).resolve().parents[2]
        required = analyze.load_required_oracles(
            root / "experiments/agent_workspace/rq2_required_oracles.txt")
        rows = []
        for repetition in range(1, repetitions + 1):
            for condition in analyze.CONDITIONS:
                for oracle_condition, kind, name in required:
                    if oracle_condition != condition:
                        continue
                    row = {
                        "event": "agent-workspace-rq2",
                        "condition": condition,
                        "repetition": repetition,
                        kind: name,
                        "pass": True,
                    }
                    if name == "fuse_options_recorded":
                        row["detail"] = (
                            "attr_timeout=3600,entry_timeout=3600,"
                            "negative_timeout=3600,"
                            "default_permissions=true,kernel_cache=false")
                    rows.append(row)
                for metric in analyze.METRICS:
                    event = "agent-workspace-lifecycle-sample" \
                        if metric == "lifecycle" \
                        else "agent-workspace-sample"
                    for iteration in range(analyze.SAMPLE_COUNTS[metric]):
                        rows.append({
                            "event": event,
                            "condition": condition,
                            "repetition": repetition,
                            "metric":
                                analyze.METRIC_NAMES[(condition, metric)],
                            "iteration": iteration,
                            "value": 100 + iteration,
                            "pass": True,
                        })
                for metric in analyze.CONTROL_METRICS:
                    for iteration in range(
                            analyze.CONTROL_SAMPLE_COUNTS[metric]):
                        rows.append({
                            "event": "agent-workspace-sample",
                            "condition": condition,
                            "repetition": repetition,
                            "metric":
                                analyze.CONTROL_NAMES[(condition, metric)],
                            "iteration": iteration,
                            "value": 100 + iteration,
                            "pass": True,
                        })
                if condition != "fuse":
                    continue
                rows.append({
                    "event": "agent-workspace-fuse-resource",
                    "condition": condition,
                    "repetition": repetition,
                    "callback_requests": 100,
                    "cpu_runtime_ns": 1000,
                    "runqueue_wait_ns": 10,
                    "timeslices": 5,
                    "voluntary_context_switches": 5,
                    "involuntary_context_switches": 0,
                    "threads_before": 2,
                    "threads_after": 2,
                    "pass": True,
                })
                callback_values = {
                    counter: 1
                    for counter in analyze.FUSE_CALLBACK_COUNTERS
                }
                callback_values["mknod"] = 0
                callback_values["truncate"] = 0
                counter_values = {
                    **callback_values,
                    "request_total": sum(callback_values.values()),
                    "handle_opened": callback_values["release"],
                    "release_completed": callback_values["release"],
                    "hidden_lookup": 1,
                    "hidden_readdir": 1,
                    "invalidate_attempt": 6,
                    "invalidate_error": 0,
                }
                for counter, value in counter_values.items():
                    rows.append({
                        "event": "agent-workspace-fuse-counter",
                        "condition": condition,
                        "repetition": repetition,
                        "counter": counter,
                        "value": value,
                        "pass": True,
                    })
        return rows, required

    def test_paired_boot_quantiles_drive_ratio(self):
        indexed = {}
        for repetition in range(1, 4):
            for metric in analyze.METRICS:
                indexed[(repetition, "namei_ext", metric)] = [
                    repetition * 10,
                    repetition * 20,
                    repetition * 30,
                ]
                indexed[(repetition, "fuse", metric)] = [
                    repetition * 20,
                    repetition * 40,
                    repetition * 60,
                ]
        first_conditions = {
            1: "namei_ext",
            2: "fuse",
            3: "namei_ext",
        }
        summaries = analyze.summarize(indexed, 3, 7, first_conditions)
        for row in summaries:
            for result in row["quantiles"].values():
                self.assertEqual(result["paired_ratios"], [2.0, 2.0, 2.0])
                self.assertEqual(result["ratio_median"], 2.0)
                self.assertEqual(result["ci_low"], 2.0)
                self.assertEqual(result["ci_high"], 2.0)

    def test_interval_containing_one_is_inconclusive(self):
        summaries = [{
            "metric": "lifecycle",
            "quantiles": {
                "p50": {
                    "ci_low": 0.9,
                    "ci_high": 1.1,
                },
            },
        }]
        verdict = analyze.classify(summaries)
        self.assertEqual(verdict["tested_hypothesis"], "inconclusive")
        self.assertFalse(verdict["equivalence_claimed"])

    def test_interval_wholly_below_one_is_contradicted(self):
        summaries = [{
            "metric": "lifecycle",
            "quantiles": {
                "p50": {
                    "ci_low": 0.6,
                    "ci_high": 0.9,
                },
            },
        }]
        verdict = analyze.classify(summaries)
        self.assertEqual(verdict["tested_hypothesis"], "contradicted")

    def test_field_summary_preserves_boot_values_and_range(self):
        rows = {
            1: {"cpu_runtime_ns": 10},
            2: {"cpu_runtime_ns": 30},
            3: {"cpu_runtime_ns": 20},
        }
        summary = analyze.summarize_fields(rows, ("cpu_runtime_ns",))
        self.assertEqual(
            summary["cpu_runtime_ns"]["per_boot"], [10, 30, 20])
        self.assertEqual(summary["cpu_runtime_ns"]["median"], 20)
        self.assertEqual(summary["cpu_runtime_ns"]["minimum"], 10)
        self.assertEqual(summary["cpu_runtime_ns"]["maximum"], 30)

    def test_complete_matrix_contract_validates(self):
        rows, required = self.build_complete_rows(2)
        _, _, resources, counters, correctness = analyze.validate(
            rows, 2, required)
        self.assertEqual(correctness["boots_expected"], 4)
        self.assertEqual(correctness["failed_observations"], 0)
        self.assertEqual(
            correctness["required_oracles_observed"],
            correctness["required_oracles_per_matrix"])
        self.assertEqual(resources[1]["threads_before"], 2)
        self.assertEqual(
            counters[2]["request_total"],
            sum(counters[2][name]
                for name in analyze.FUSE_CALLBACK_COUNTERS))

    def test_missing_pass_is_rejected(self):
        rows, required = self.build_complete_rows(2)
        sample = next(row for row in rows
                      if row["event"] == "agent-workspace-sample")
        del sample["pass"]
        with self.assertRaises(ValueError):
            analyze.validate(rows, 2, required)

    def test_complete_matrix_generates_full_report(self):
        rows, required = self.build_complete_rows(2)
        indexed, controls, resources, counters, correctness = \
            analyze.validate(rows, 2, required)
        first_conditions = {1: "namei_ext", 2: "fuse"}
        summaries = analyze.summarize(
            indexed, 2, 17, first_conditions)
        control_summaries = analyze.summarize_controls(
            controls, 2, 17, first_conditions)
        resource_summaries = analyze.summarize_fields(
            resources, analyze.FUSE_RESOURCE_FIELDS)
        counter_summaries = analyze.summarize_fields(
            counters, analyze.FUSE_COUNTERS)
        verdict = analyze.classify(summaries)
        with tempfile.TemporaryDirectory() as directory:
            report = Path(directory) / "report.md"
            analyze.write_report(
                report, summaries, control_summaries, resource_summaries,
                counter_summaries, correctness, verdict, 2, 17)
            text = report.read_text(encoding="utf-8")
        for heading in (
                "## Correctness Gate",
                "## Latency",
                "## Lower-Filesystem Controls",
                "## Order Diagnostic",
                "## FUSE Daemon Resource Window",
                "## Operation And Callback Counts"):
            self.assertIn(heading, text)
        self.assertIn("| lifecycle | p99 |", text)
        self.assertIn("| request_total |", text)

    def test_launch_order_schema_and_sequence(self):
        rows = [
            {
                "schema":
                    "namei_ext.agent_workspace_rq2.launch_order.v1",
                "order_index": 1,
                "repetition": 1,
                "condition": "namei_ext",
                "host_started_at": "start-1",
                "host_completed_at": "end-1",
            },
            {
                "schema":
                    "namei_ext.agent_workspace_rq2.launch_order.v1",
                "order_index": 2,
                "repetition": 1,
                "condition": "fuse",
                "host_started_at": "start-2",
                "host_completed_at": "end-2",
            },
            {
                "schema":
                    "namei_ext.agent_workspace_rq2.launch_order.v1",
                "order_index": 3,
                "repetition": 2,
                "condition": "fuse",
                "host_started_at": "start-3",
                "host_completed_at": "end-3",
            },
            {
                "schema":
                    "namei_ext.agent_workspace_rq2.launch_order.v1",
                "order_index": 4,
                "repetition": 2,
                "condition": "namei_ext",
                "host_started_at": "start-4",
                "host_completed_at": "end-4",
            },
        ]
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "launch-order.jsonl"
            path.write_text(
                "".join(f"{json.dumps(row)}\n" for row in rows),
                encoding="utf-8")
            first = analyze.load_launch_order(path, 2)
        self.assertEqual(first, {1: "namei_ext", 2: "fuse"})


if __name__ == "__main__":
    unittest.main()
