# Skill Layout Paper Draft Compression

Date: 2026-07-02

## Motivation

The `research-literature-novelty` layout says durable novelty, related-work,
source-use, and baseline conclusions should live in
`docs/background-related-work.md`, with source entry points in
`docs/reference/CODE_SOURCES.md`, PDFs in `docs/reference/INDEX.md`, dated
evidence records in `docs/tmp/YYYY-MM-DD-*.md`, and raw artifacts in
`results/`.

The paper draft tree still contained old detailed C1-C8, exact-map/table, and
workload-verdict prose. Even with routing comments, those sections were easy to
misread as current claims.

## Files Changed

- `docs/paper/evaluation.md`
- `docs/paper/main.tex`
- `docs/paper/sections/01-introduction.tex`
- `docs/paper/sections/02-motivation.tex`
- `docs/paper/sections/03-design.tex`
- `docs/paper/sections/04-implementation.tex`
- `docs/paper/sections/05-evaluation.tex`
- `docs/paper/sections/06-related-work.tex`
- `docs/paper/sections/07-limitations.tex`
- `docs/background-related-work.md`
- `research/STATE.md`

## Decision

The paper draft tree is now a routing-only historical draft area. It no longer
contains detailed current-looking claim verdicts, workload matrices,
implementation-evidence tables, or table-centered evaluation text.

Current ownership is:

- `docs/idea-story.md`: current idea, claim scope, non-goals, and next action.
- `docs/background-related-work.md`: related work, novelty risk, closest work,
  workload-source verdicts, mandatory baselines, and reviewer-facing next
  actions.
- `docs/reference/CODE_SOURCES.md`: source repositories, datasets, artifacts,
  workload roles, and evidence-record links.
- `docs/reference/INDEX.md`: PDF inventory.
- `docs/tmp/YYYY-MM-DD-*.md`: standalone dated records.
- `results/`: raw logs, JSON/JSONL, benchmark outputs, and generated summaries.
- `research/STATE.md`: short handoff pointer only.

## Boundary

This is a documentation-layout cleanup, not a new experiment. It does not
change any workload result. It also does not prove or claim that any workload
requires eBPF, `namei_ext`, dynamic policy logic, or that table-based
approaches are impossible.

Historical detailed paper text remains recoverable through Git history and the
dated evidence/provenance records already under `docs/tmp/`.

## Validation Plan

Validation after this edit should check:

- no non-Markdown files or subdirectories under `docs/tmp/`;
- `docs/tmp` records keep the `YYYY-MM-DD-` prefix;
- no old paper draft file remains as a long current-looking verdict store;
- `git diff --check` on the touched documentation files.
