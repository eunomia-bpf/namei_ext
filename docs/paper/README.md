# Paper Draft

Status: active restored draft.
Last routing update: 2026-07-12.

The LaTeX files in this directory are the current paper draft for the restored
idea: `namei_ext` as a `sched_ext`-style VFS extension point in the sequence
bind/Overlay/materialization < eBPF LSM < `namei_ext` < FUSE/custom
filesystems. The broader project state is still owned by the skill-compatible
layout below, so paper changes should follow those canonical documents instead
of inventing new scope locally.

Use the skill-compatible layout instead:

| Need | Canonical location |
| --- | --- |
| Current paper idea, claim scope, non-goals, and next action | `../idea-story.md` |
| Related work, novelty risk, closest work, source-use verdicts, and mandatory comparisons | `../background-related-work.md` |
| Source repositories, datasets, artifacts, and evidence-record links | `../reference/CODE_SOURCES.md` |
| PDF inventory | `../reference/INDEX.md` |
| Standalone research or implementation records | `../tmp/YYYY-MM-DD-*.md` |
| Raw logs, JSON/JSONL, generated summaries, benchmark outputs | `../../results/` |
| Current handoff pointer | `../../research/STATE.md` |

## Update Rule

Do not add new novelty verdicts, source-role decisions, comparison decisions, or
workload-necessity claims only in the paper draft. First update the
canonical document above, then make the paper draft follow that scope.

The old narrow-baseline and exclusive-necessity wording in historical draft
text is provenance only. It must not be used to revive claims that workloads
require only eBPF or only `namei_ext`, or that alternative namespace mechanisms
are impossible. It also must not be used to suppress the restored core idea:
`namei_ext` is a `sched_ext`-style VFS extension point in the sequence
bind/Overlay/materialization < eBPF LSM < `namei_ext` < FUSE/custom
filesystems.
