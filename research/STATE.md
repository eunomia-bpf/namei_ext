# Research State

Last updated: 2026-07-30

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
- The contribution is the design and Linux implementation of a VFS mechanism
  that selects existing objects during pathname resolution without transferring
  filesystem ownership to policy. It integrates one bounded decision contract
  across component lookup, final lookup, and directory iteration, preserves
  registered-target lifetime across RCU/ref-walk, resumes normal VFS
  permission/open completion, and bypasses unattached or unmanaged parents
  before policy-context construction. eBPF is the policy vehicle, not the
  novelty by itself.
- RQ1 asks expressiveness/sufficiency for source-derived state-dependent
  path-view policies. RQ2 measures cost versus feature-equivalent FUSE. RQ3
  evaluates the verifier-bounded, fail-closed ownership boundary versus custom
  or stackable filesystem ownership.
- The source-derived portfolio contains seven non-overlapping industrial
  workflows. W1 application file sharing, W2 Agent workspaces, W3 build action
  sandboxing, W4's Kubernetes `AtomicWriter` payload-view subset, and W7
  toolchain/environment selection have reviewed formal KVM correctness
  evidence. W5--W6 and full service reload remain motivating or
  dependency-limited rows, not completed paper evidence.
- Do not reopen table-only, materialized-view, or scattered-baseline side
  experiments as the novelty line.

## Current Evidence State

- Paper draft: `docs/paper/main.tex` and `docs/paper/sections/*.tex`.
- Agent workspace RQ1 lifecycle: three terminal reviewed KVM runs under
  `results/experiments/agent-workspace-matrix/20260722T020120Z-rq1run1/`,
  `20260722T020210Z-rq1run2/`, and `20260722T020245Z-rq1run3/`.
- Agent workspace RQ1 released source task: three fresh KVM boots, 12/12
  policy-backed task states, 6/6 physical source controls, three overlapping
  completed/base view pairs, switch, rollback, and withdrawal under
  `results/experiments/agent-workspace-source-task-rq1/20260729T-agent-source-task-formal01/`.
- Application file sharing RQ1 source control: three fresh KVM boots ran
  official `xdg-document-portal` 1.18.4 before the matched `namei_ext` arm.
  All 15 official-source and 15 `namei_ext` grant/isolation/revoke states
  agreed operation by operation, with lower-object preservation and clean
  midpoint isolation, under
  `results/experiments/application-file-sharing-source-oracle-rq1/20260730T-xdg-source-formal01/`.
- Bazel build action RQ1: three fresh KVM boots, six completed Bazel actions,
  six logical/lower object matches, and 12 preserved lower objects under
  `results/experiments/build-action-sandboxing-rq1/20260729T180121Z-w3-formal02/`.
- Toolchain/environment RQ1: three fresh KVM boots, 18/18 physical or logical
  states, and 24/24 Python probes under
  `results/experiments/toolchain-environment/20260729T171551Z-toolchain-formal01/`.
- Kubernetes ConfigMap publication RQ1: three fresh KVM boots, 12/12 official
  `AtomicWriter` states, 12/12 `namei_ext` states, 6/6 direct controls, 24/24
  stable-root descriptor checks, 12/12 old-descriptor checks, and 36/36
  lower-object checks under
  `results/experiments/kubernetes-configmap-publication-rq1/20260729T-kubernetes-configmap-publication-rq1-01/`.
- Agent workspace RQ2: 20 fresh KVM boots and 960/960 required oracles under
  `results/experiments/agent-workspace-rq2/20260727T-agent-workspace-rq2-formal-v3/`;
  paired FUSE/namei_ext lifecycle ratio `11.32x [11.24, 11.64]`.
- FxMark RQ2: the clean 50-boot active-path matrix and separate 60-boot
  unused-fast-path confirmation live under
  `results/experiments/fxmark-rq2/20260728T-rq2-rcu-target-formal-v3/` and
  `results/experiments/fxmark-fast-path/20260728T-fxmark-fast-path-formal-v1/`.
- Corrected FxMark directory enumeration: the reviewed 50-boot, 300-cell
  formal matrix lives under
  `results/experiments/fxmark-readdir/20260729T082800Z-fxmark-readdir-formal-v1/`.
  Five of six `SELECT/FUSE` cells have paired 95% intervals above one; the
  four-worker shared-directory cell is inconclusive, so the frozen verdict is
  `mixed`.
- Agent workspace RQ3: three independent boots passed 37/37 pairwise
  `namei_ext`/Wrapfs-derived oracles and 21/21 fault cells under
  `results/experiments/agent-workspace-rq3-formal/20260728-rq3-formal-v3/`.
- Traditional build/cache: KVM release runs
  `results/experiments/build-cache/20260723T-build-cache-state-release-v1/`
  (hot cache + trace-derived state row) and
  `results/phase1/20260724T-epoch-switch-release-v2/` (real compile epoch
  switch). Observed FUSE/namei_ext compile-time ratio is about 2.1x.
- Open evidence gaps: cache-cold lookup or broader metadata operations for RQ2
  and a second source-derived RQ3 boundary row. W5 DMTCP and W6 Spindle remain
  optional RQ1 breadth extensions rather than prerequisites for the current
  five-workflow RQ1 answer. The ccache
  matrix is supporting macro evidence, not a headline workload.

Complete current inventory:
`docs/tmp/2026-07-28-complete-experiment-status.md`.

Do not perform Git mutation unless explicitly requested after status/diff
inspection.
