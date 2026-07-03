# Historical OSDI Evaluation Plan

Status: historical provenance only.
Last routing update: 2026-07-02.

This file used to contain the detailed OSDI evaluation plan, including older
C1-C8 gates and table-centered diagnostics. It is intentionally no longer a
current specification. Keeping the full old plan here made the repository look
as if multiple files owned the paper claims, which conflicts with the
`research-literature-novelty` documentation layout.

## Current Routing

| Current question | Canonical file |
| --- | --- |
| Paper idea, claim scope, non-goals, and next action | `docs/idea-story.md` |
| Related work, closest work, novelty risk, workload-source verdicts, and mandatory baselines | `docs/background-related-work.md` |
| Source repositories, datasets, artifacts, and evidence-record links | `docs/reference/CODE_SOURCES.md` |
| PDF inventory | `docs/reference/INDEX.md` |
| Current handoff pointer | `research/STATE.md` |
| Standalone research/implementation records | `docs/tmp/YYYY-MM-DD-*.md` |
| Raw logs, JSON/JSONL, generated summaries, benchmark outputs | `results/` |

## Current Boundary

- Do not use this historical plan to revive table-centered C8,
  workload-necessity, or interface-exclusivity claims.
- `table_redirect.bpf.c` and exact-map rows are archived boundary diagnostics
  only when a precomputed mapping is the relevant comparison.
- The active next experiment is one Make-owned, KVM-validated AI agent
  workspace lifecycle workload, followed by one W4 environment/cache transition
  workload.

Historical detailed planning text is recoverable through Git history and dated
records under `docs/tmp/`.
