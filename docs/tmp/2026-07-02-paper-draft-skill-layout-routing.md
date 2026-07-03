# Paper Draft Skill-Layout Routing

Date: 2026-07-02.
Stage: documentation layout convergence.
Source/command: `research-literature-novelty` skill output policy and local
inspection of `docs/paper/*`, `docs/idea-story.md`,
`docs/background-related-work.md`, `docs/reference/`, and `research/STATE.md`.

## Motivation

The repository already had canonical skill outputs for idea/story, related
work, code-source catalog, PDF inventory, dated records, and raw results. The
remaining ambiguity was the paper draft directory: several LaTeX sections still
contained older C1-C8, table-centered, and workload-necessity language. The
main paper file had a draft-status box, but individual section files could
still look like current claim owners when opened directly.

## Files Inspected

- `docs/idea-story.md`
- `docs/background-related-work.md`
- `docs/reference/CODE_SOURCES.md`
- `docs/reference/INDEX.md`
- `research/STATE.md`
- `docs/paper/main.tex`
- `docs/paper/evaluation.md`
- `docs/paper/sections/*.tex`

## Changes

- Added `docs/paper/README.md` as the paper-draft routing entry point.
- Added source-level routing comments to each LaTeX section under
  `docs/paper/sections/`.
- Updated `docs/background-related-work.md` search log with this routing step.
- Updated `research/STATE.md` so the historical paper-draft entry points name
  `docs/paper/README.md`.

## Current Layout Contract

Durable related-work, novelty-risk, closest-work, source-use, and baseline
verdicts belong only in `docs/background-related-work.md`. Current paper story,
claim scope, non-goals, and next action belong in `docs/idea-story.md`. Source
repositories and artifact entry points belong in
`docs/reference/CODE_SOURCES.md`; PDFs belong in `docs/reference/INDEX.md`.
Standalone records belong directly under dated `docs/tmp/YYYY-MM-DD-*.md`
files, and raw logs or generated JSON artifacts belong under `results/`.

Because this repository's `AGENTS.md` is stricter than the generic skill path,
dated records are kept directly under `docs/tmp/` rather than under
`docs/tmp/phase-1-related-work/`.

## Boundary

This change does not rewrite the historical paper draft or remove old
provenance. It only prevents `docs/paper/*` from acting as a parallel current
claim store. Future paper edits should first update the canonical documents and
then make the draft follow that scope.
