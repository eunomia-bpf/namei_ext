# Historical Claim Ledger

Status: historical provenance only.
Last routing update: 2026-07-02.

This file is intentionally no longer a current claim ledger. The project now
uses the `research-literature-novelty` skill layout:

| Current question | Canonical file |
| --- | --- |
| Paper story, claim scope, non-goals, and next action | `docs/idea-story.md` |
| Related work, novelty risk, source-use verdicts, and mandatory comparisons | `docs/background-related-work.md` |
| Source repositories, datasets, artifacts, and evidence-record links | `docs/reference/CODE_SOURCES.md` |
| PDF inventory | `docs/reference/INDEX.md` |
| Current handoff pointer | `research/STATE.md` |
| Standalone evidence records | `docs/tmp/YYYY-MM-DD-*.md` |
| Raw logs, JSON/JSONL, benchmark outputs | `results/` |

Current claim boundary:

- Do not claim exclusive necessity: the selected workloads should not be
  framed as requiring only eBPF or only `namei_ext`, and diagnostic-baseline
  impossibility is not the paper center. It is valid to claim, when supported
  by source characterization, that the workloads exercise dynamic
  state-dependent path-view policy.
- Discarded diagnostic rows are archived provenance only.
- The active paper direction is a `sched_ext`-style VFS extension point for
  programmable path-resolution policy, positioned between
  bind/Overlay/materialization and FUSE/custom filesystems, evaluated on real
  source-backed workloads for expressiveness, overhead versus FUSE, and
  safety/boundary versus custom or stackable filesystems.

Historical detailed claim rows are available through Git history and the dated
records under `docs/tmp/`. Do not add new source-role, novelty, or baseline
verdicts here.
