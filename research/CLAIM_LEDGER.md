# Historical Claim Ledger

Status: historical provenance only.
Last routing update: 2026-07-02.

This file is intentionally no longer a current claim ledger. The project now
uses the `research-literature-novelty` skill layout:

| Current question | Canonical file |
| --- | --- |
| Paper story, claim scope, non-goals, and next action | `docs/idea-story.md` |
| Related work, novelty risk, source-use verdicts, and mandatory baselines | `docs/background-related-work.md` |
| Source repositories, datasets, artifacts, and evidence-record links | `docs/reference/CODE_SOURCES.md` |
| PDF inventory | `docs/reference/INDEX.md` |
| Current handoff pointer | `research/STATE.md` |
| Standalone evidence records | `docs/tmp/YYYY-MM-DD-*.md` |
| Raw logs, JSON/JSONL, benchmark outputs | `results/` |

Current claim boundary:

- Do not claim that the selected workloads require eBPF, `namei_ext`, dynamic
  policy logic, or that static tables are impossible.
- Do not use `table_redirect.bpf.c` as the paper center. Existing exact-map
  rows are archived boundary evidence only.
- The active paper direction is a narrow VFS name-resolution hook for
  path-view policies, evaluated on real source-backed agent workspace and
  environment/cache workloads with natural baselines.

Historical detailed claim rows are available through Git history and the dated
records under `docs/tmp/`. Do not add new source-role, novelty, or baseline
verdicts here.
