# Historical Research Plan

Status: historical provenance only.
Last routing update: 2026-07-02.

This file used to carry a long research plan. The current project now follows
the skill-compatible documentation layout:

| Current question | Canonical file |
| --- | --- |
| What is the idea, claim scope, and next paper action? | `docs/idea-story.md` |
| What is the related-work map, novelty risk, source-use verdict, and baseline set? | `docs/background-related-work.md` |
| Which source repositories, datasets, PDFs, and reproduction records exist? | `docs/reference/CODE_SOURCES.md` and `docs/reference/INDEX.md` |
| What is the current handoff state? | `research/STATE.md` |
| Where are standalone research/implementation records? | `docs/tmp/YYYY-MM-DD-*.md` |
| Where are raw logs and generated result artifacts? | `results/` |

Current research direction:

- `namei_ext` is not a BPF filesystem. It is a narrow VFS name-resolution hook
  for path-view decisions.
- The active workload route is AI agent workspace lifecycle, W4
  environment/cache transition, and optionally W2 service reload/update.
- Existing table/exact-map rows are archived boundary evidence only.
- DeltaFS, IndexFS, and TableFS are related-work or appendix workload-shape
  sources, not the main next experiments.

Historical detailed planning text is available through Git history and dated
records under `docs/tmp/`.
