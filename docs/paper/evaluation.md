# Historical Evaluation Draft

Status: historical provenance only.
Last routing update: 2026-07-02.

This Markdown file no longer owns the current evaluation plan, workload
matrix, claim verdicts, or baseline requirements. It was compressed during the
skill-layout convergence because the old text duplicated current-looking C1-C8
and table-centered material outside the canonical documents.

Use the skill-compatible layout instead:

| Need | Canonical location |
| --- | --- |
| Current paper idea, claim scope, non-goals, and next action | `docs/idea-story.md` |
| Related work, novelty risk, source-use verdicts, mandatory baselines | `docs/background-related-work.md` |
| Source repositories, datasets, artifacts, and reproduction-record links | `docs/reference/CODE_SOURCES.md` |
| PDF inventory | `docs/reference/INDEX.md` |
| Standalone research or implementation records | `docs/tmp/YYYY-MM-DD-*.md` |
| Raw logs, JSON/JSONL, benchmark outputs, generated summaries | `results/` |
| Current handoff pointer | `research/STATE.md` |

Current boundary:

- Do not use this file to revive table-centered C8, workload-necessity, or
  interface-exclusivity claims.
- Do not claim that selected workloads require eBPF, `namei_ext`, dynamic
  policy logic, or that static tables are impossible.
- Exact-map/table rows are archived diagnostics only when a precomputed mapping
  is the relevant workload-specific comparison.

Historical detailed text remains recoverable through Git history and dated
records under `docs/tmp/`.
