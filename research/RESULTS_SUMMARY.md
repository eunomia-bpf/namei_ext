# Historical Results Summary

Status: historical provenance only.
Last routing update: 2026-07-02.

This file no longer owns current result interpretation. It is intentionally
kept short so it does not compete with the skill-compatible documentation
layout.

Current routing:

| Evidence type | Canonical location |
| --- | --- |
| Raw observations, logs, JSON/JSONL, dmesg, hashes, generated reports | `results/` |
| Standalone research or implementation records | `docs/tmp/YYYY-MM-DD-*.md` |
| Reviewer-facing interpretation, source-use verdicts, novelty risk, baselines | `docs/background-related-work.md` |
| Paper idea, claim scope, non-goals, and next action | `docs/idea-story.md` |
| Source and artifact entry points | `docs/reference/CODE_SOURCES.md` |
| Current handoff pointer | `research/STATE.md` |

Current high-level result state:

- The prototype and many source-system reproductions exist, but the paper still
  needs a Make-owned KVM workload derived from the selected real agent or
  environment/cache sources.
- AgentFS official SDK/CLI/integration/examples and Mirage Python
  conformance/integration/examples now provide strong source-backed workload
  seeds.
- SWE-agent official tests provide deterministic agent-loop, replay,
  run-single, and run-batch workload evidence.
- Terminal-Bench and environment-construction sources provide task/oracle
  seeds, but selected-task evidence is not full benchmark reproduction.
- Table/exact-map counterfactuals are archived boundary evidence and should not
  drive the next experiments.

Historical detailed result summaries are available through Git history, raw
result roots under `results/`, and dated records under `docs/tmp/`.
