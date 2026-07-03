# Historical Case Studies And Baseline Matrix

Status: historical provenance only.
Last routing update: 2026-07-02.

This file no longer owns the active case-study matrix. The current workload
selection and baseline implications are intentionally consolidated under the
skill-compatible layout:

| Current question | Canonical file |
| --- | --- |
| Current workload story and claim scope | `docs/idea-story.md` |
| Related work, closest work, workload-source verdicts, and mandatory baselines | `docs/background-related-work.md` |
| Source repositories, datasets, artifacts, and reproduction-record index | `docs/reference/CODE_SOURCES.md` |
| Standalone case-study or reproduction evidence | `docs/tmp/YYYY-MM-DD-*.md` |
| Raw result artifacts | `results/` |

Current case-study route:

1. AI agent workspace lifecycle is the first main workload candidate.
2. Content-verified cache/environment reuse is the second main workload
   candidate.
3. Service fixture sandbox remains a scoped positive slice and should only be
   upgraded with real reload/update or secret/config rotation evidence.

Do not use this file to argue that a workload requires eBPF or that static
tables are impossible. Future case-study updates should go to the canonical
files above.
