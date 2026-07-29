# Research State

Last updated: 2026-07-28

This file is only a handoff pointer. Research process state, gates, and
orchestration belong to the orchestrator skill, not to this repository.

## Canonical Layout

| Need | Read/update |
| --- | --- |
| Paper idea, claim scope, non-goals | `docs/idea-story.md` |
| Mechanism boundary | `docs/design.md` |
| Implementation and validation boundary | `docs/implementation.md` |
| Evaluation state: use cases, matrices, results, open questions | `docs/evaluation.md` |
| Related work, novelty risk, closest work, source-use verdicts, central comparisons | `docs/background-related-work.md` |
| Source repositories, datasets, artifacts, and evidence-record links | `docs/reference/CODE_SOURCES.md` |
| PDF inventory | `docs/reference/INDEX.md` |
| Standalone research, reproduction, and implementation records | `docs/tmp/YYYY-MM-DD-*.md` |
| Raw logs, JSON/JSONL, generated summaries, benchmark outputs | `results/` |
| Archived process docs (old evaluation plan, research plan, experiment plans, claim/gate ledgers, full idea-story history) | `docs/tmp/2026-07-25-archived-process-docs/`, `docs/tmp/2026-07-25-deprecated-research-stubs/` |

## Current Story

- `namei_ext` is a `sched_ext`-style VFS name-resolution extension point, not a
  BPF filesystem.
- The contribution is the design and Linux implementation of that extension
  point as one systems boundary. eBPF chooses bounded lookup/readdir policy;
  the kernel and lower filesystem keep VFS object ownership, path walking,
  permissions, data path, writes, page cache, persistence, and consistency.
- RQ1 asks expressiveness/sufficiency for source-derived state-dependent
  path-view policies. RQ2 measures cost versus feature-equivalent FUSE. RQ3
  evaluates the verifier-bounded, fail-closed ownership boundary versus custom
  or stackable filesystem ownership.
- The source-derived portfolio contains seven non-overlapping industrial
  workflows. W1 application file sharing, W2 Agent workspaces, and W3 build
  action sandboxing currently have KVM correctness evidence. W4 remains behind
  a closed dependency protocol; W5--W7 are not yet executed.
- Do not reopen table-only, materialized-view, or scattered-baseline side
  experiments as the novelty line.

## Current Evidence State

- Paper draft: `docs/paper/main.tex` and `docs/paper/sections/*.tex`.
- Agent workspace RQ1: three terminal reviewed KVM runs under
  `results/experiments/agent-workspace-matrix/20260722T020120Z-rq1run1/`,
  `20260722T020210Z-rq1run2/`, and `20260722T020245Z-rq1run3/`.
- Agent workspace RQ2: 20 fresh KVM boots and 960/960 required oracles under
  `results/experiments/agent-workspace-rq2/20260727T-agent-workspace-rq2-formal-v3/`;
  paired FUSE/namei_ext lifecycle ratio `11.32x [11.24, 11.64]`.
- FxMark RQ2: the clean 50-boot active-path matrix and separate 60-boot
  unused-fast-path confirmation live under
  `results/experiments/fxmark-rq2/20260728T-rq2-rcu-target-formal-v3/` and
  `results/experiments/fxmark-fast-path/20260728T-fxmark-fast-path-formal-v1/`.
- Agent workspace RQ3: three independent boots passed 37/37 pairwise
  `namei_ext`/Wrapfs-derived oracles and 21/21 fault cells under
  `results/experiments/agent-workspace-rq3-formal/20260728-rq3-formal-v3/`.
- Traditional build/cache: KVM release runs
  `results/experiments/build-cache/20260723T-build-cache-state-release-v1/`
  (hot cache + trace-derived state row) and
  `results/phase1/20260724T-epoch-switch-release-v2/` (real compile epoch
  switch). Observed FUSE/namei_ext compile-time ratio is about 2.1x.
- Open evidence gaps: a second deep traditional correctness case, cache-cold
  and directory/metadata benchmark breadth, and a second source-derived RQ3
  boundary row. The ccache matrix is supporting macro evidence, not a headline
  workload.

Complete current inventory:
`docs/tmp/2026-07-28-complete-experiment-status.md`.

Do not perform Git mutation unless explicitly requested after status/diff
inspection.
