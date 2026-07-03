# Historical Phase 1 Experiment Plan

Status: historical provenance only.
Last routing update: 2026-07-02.

This file used to contain the early smoke-scale PASS/REDIRECT Phase 1
experiment plan. It predates the current parent-aware ABI, source-backed
workload selection, and skill-compatible documentation layout. It is not the
current Phase 1 or OSDI evaluation specification.

## Current Routing

| Current question | Canonical file |
| --- | --- |
| Paper idea, claim scope, non-goals, and next action | `docs/idea-story.md` |
| Related work, novelty risk, source-use verdicts, and mandatory baselines | `docs/background-related-work.md` |
| Source repositories, datasets, artifacts, and evidence-record links | `docs/reference/CODE_SOURCES.md` |
| Current handoff pointer | `research/STATE.md` |
| Standalone Phase 1 records | `docs/tmp/YYYY-MM-DD-*.md` |
| Raw result artifacts | `results/` |

## Current Boundary

- `namei_ext` is a narrow VFS name-resolution extension point, not a BPF
  filesystem.
- Current source-backed workload direction is AI agent workspace lifecycle,
  then W4 environment/cache transition, then optional W2 reload/update.
- Older exact-map/table diagnostics are archived boundary evidence only.

Historical detailed planning text is recoverable through Git history and dated
records under `docs/tmp/`.
