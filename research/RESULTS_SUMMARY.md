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
| Reviewer-facing interpretation, source-use verdicts, novelty risk, comparisons | `docs/background-related-work.md` |
| Paper idea, claim scope, non-goals, and next action | `docs/idea-story.md` |
| Source and artifact entry points | `docs/reference/CODE_SOURCES.md` |
| Current handoff pointer | `research/STATE.md` |

Current high-level result state:

- The prototype and many source-system reproductions exist. The paper framing
  is being restored to the larger idea: `namei_ext` as a `sched_ext`-style VFS
  extension point in the sequence bind/Overlay/materialization < eBPF LSM <
  `namei_ext` < FUSE/custom filesystems. Make-owned KVM complete experiments
  from selected agent and environment/cache sources are required to establish
  expressiveness, overhead versus FUSE, and custom-filesystem boundary claims.
  Service/config belongs in the main evaluation only after a real source oracle
  is selected.
- AgentFS official SDK/CLI/integration/examples and Mirage Python
  conformance/integration/examples now provide strong source-backed workload
  seeds.
- SWE-agent official tests provide deterministic agent-loop, replay,
  run-single, and run-batch workload evidence.
- Terminal-Bench and environment-construction sources provide task/oracle
  seeds, but selected-task evidence is not full benchmark reproduction.
- Discarded counterfactual diagnostics are archived provenance and should not
  drive the next experiments or shrink the paper's core idea.

Historical detailed result summaries are available through Git history, raw
result roots under `results/`, and dated records under `docs/tmp/`.
