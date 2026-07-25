# Research State

Last updated: 2026-07-25

This file is only a handoff pointer. Research process state, gates, and
orchestration belong to the orchestrator skill, not to this repository.

## Canonical Layout

| Need | Read/update |
| --- | --- |
| Paper idea, claim scope, non-goals | `docs/idea-story.md` |
| Mechanism boundary | `docs/design.md` |
| Implementation and validation boundary | `docs/implementation.md` |
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
- The two primary workload families are Agent workspace and traditional
  build/cache. Service/config and checkpoint/restart path remapping remain
  conditional on concrete lookup-time source oracles.
- Do not reopen table-only, materialized-view, or scattered-baseline side
  experiments as the novelty line.

## Current Evidence State

- Paper draft: `docs/paper/main.tex` and `docs/paper/sections/*.tex`.
- Agent workspace RQ1: three terminal reviewed KVM runs under
  `results/experiments/agent-workspace-matrix/20260722T0201*-rq1run{1,2,3}/`.
- Traditional build/cache: KVM release runs
  `results/experiments/build-cache/20260723T-build-cache-state-release-v1/`
  (hot cache + trace-derived state row) and
  `results/phase1/20260724T-epoch-switch-release-v2/` (real compile epoch
  switch). Observed FUSE/namei_ext compile-time ratio is about 2.1x.
- Open evidence gaps: release-scale real-compile miss/stale/corrupt cells
  (one-sample stale/corrupt-hidden probes passed on 2026-07-24), timing
  uncertainty modeling for RQ2, and RQ3 boundary write-ups per workload.

Do not perform Git mutation unless explicitly requested after status/diff
inspection.
