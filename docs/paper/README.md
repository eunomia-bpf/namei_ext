# Historical Paper Draft Routing

Status: historical draft area.
Last routing update: 2026-07-02.

The files in this directory are not the canonical owners for current claims,
related-work verdicts, workload selection, baseline requirements, or
reproduction status.

Use the skill-compatible layout instead:

| Need | Canonical location |
| --- | --- |
| Current paper idea, claim scope, non-goals, and next action | `../idea-story.md` |
| Related work, novelty risk, closest work, source-use verdicts, and mandatory baselines | `../background-related-work.md` |
| Source repositories, datasets, artifacts, and evidence-record links | `../reference/CODE_SOURCES.md` |
| PDF inventory | `../reference/INDEX.md` |
| Standalone research or implementation records | `../tmp/YYYY-MM-DD-*.md` |
| Raw logs, JSON/JSONL, generated summaries, benchmark outputs | `../../results/` |
| Current handoff pointer | `../../research/STATE.md` |

## Update Rule

Do not add new novelty verdicts, source-role decisions, baseline decisions, or
workload-necessity claims directly to the paper draft. First update the
canonical document above, then make the paper draft follow that scope.

The old C1-C8, table-centered, and workload-necessity wording in historical
draft text is provenance only. It must not be used to revive claims that
workloads require eBPF, require `namei_ext`, require dynamic policy logic, or
that static tables are impossible.
