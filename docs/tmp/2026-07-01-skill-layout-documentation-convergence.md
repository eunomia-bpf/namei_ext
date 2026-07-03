# Skill Layout Documentation Convergence

Date: 2026-07-01
Updated: 2026-07-02

## Motivation

The related-work and workload-reproduction notes had accumulated across
several dated records. The documentation needed to converge on the
`research-literature-novelty` skill layout while still obeying this repository's
Phase 1 rule that standalone records live directly under
`docs/tmp/YYYY-MM-DD-*.md`.

## Layout Decision

Canonical durable state now lives in:

- `docs/idea-story.md`: current project story, claims, scope, and next action;
- `docs/background-related-work.md`: claim-oriented novelty map, closest work,
  mandatory baselines, absorbable ideas, and novelty verdict;
- `docs/reference/CODE_SOURCES.md`: source/code catalog and artifact roles;
- `docs/reference/INDEX.md`: PDF inventory and checksums;
- `research/STATE.md`: current handoff state and next implementation step.

Dated records remain under `docs/tmp/YYYY-MM-DD-*.md` because AGENTS.md is
stricter than the skill's optional `docs/tmp/phase-1-related-work/` location.
Raw logs and JSON summaries remain under `results/`, not `docs/tmp/`.
Long-lived planning files such as `docs/research_plan.md` and
`docs/case_studies.md` remain as provenance but are no longer the canonical
home for workload-source, related-work, novelty, or baseline verdicts.

## Update Rules

- Put thesis, claim scope, non-goals, and next paper action in
  `docs/idea-story.md`.
- Put closest work, same-claim risk, mandatory baselines, workload-source
  verdicts, and venue implications in `docs/background-related-work.md`.
- Put cumulative reproduction counts and reviewer-facing workload-family
  conclusions in `docs/background-related-work.md`; do not duplicate those
  counts as independent verdicts in source catalogs or historical planning
  files.
- Put repository URLs, artifact locations, source roles, and reproducibility
  entry points in `docs/reference/CODE_SOURCES.md`.
- Put PDF filenames, source labels, relevance, and checksums in
  `docs/reference/INDEX.md`.
- Put each new Phase 1 research or implementation record in a standalone
  `docs/tmp/YYYY-MM-DD-*.md` file.
- Put command logs, JSON/JSONL, generated summaries, benchmark outputs, and raw
  observations under `results/` or the owning result root.
- Do not create new per-paper note folders, novelty ledgers, bibliography
  reports, or raw-result dumps under `docs/tmp/`.
- Do not resume the static-table proof thread as the mainline. Existing table
  counterfactuals are historical boundary evidence; current workload selection
  should be driven by real source-backed agent workspace and environment/cache
  workloads.

## Edits Made

- Added ownership notes to `docs/idea-story.md`,
  `docs/background-related-work.md`, `docs/reference/CODE_SOURCES.md`,
  `docs/research_plan.md`, `docs/case_studies.md`, and `research/STATE.md`.
- On 2026-07-02, added routing notes to `research/CLAIM_LEDGER.md`,
  `research/CLAIM_VERDICT.md`, `research/EXPERIMENT_PLAN.md`,
  `research/EXPERIMENT_TRACKER.md`, `research/FOLLOWUP_PLAN.md`, and
  `research/RESULTS_SUMMARY.md` so they remain historical/working provenance
  rather than parallel novelty, source-use, or baseline verdict stores.
- Restricted `docs/reference/CODE_SOURCES.md` to stable source facts,
  repository/artifact entry points, workload roles, and an evidence-record
  index. Reproduction verdicts and source-use decisions now route to
  `docs/background-related-work.md` and dated `docs/tmp/YYYY-MM-DD-*.md`
  records instead of living in the source catalog.
- Updated `docs/background-related-work.md` to name the
  `research-literature-novelty` skill layout, define canonical ownership, and
  record the 2026-07-01 layout convergence in the search log.
- Kept historical planning files as provenance rather than rewriting their
  long evidence history.
- Added the service/API Terminal-Bench suite to the dated evidence records and
  updated the canonical cumulative count in `docs/background-related-work.md`
  to 63 resolved selected official tasks, seven unresolved/boundary tasks, and
  two attempted tasks without upstream result summaries.
- On 2026-07-02, compressed the per-suite Terminal-Bench search-log rows in
  `docs/background-related-work.md` into one cumulative selected-task row. The
  detailed suite list remains in `docs/reference/CODE_SOURCES.md` as an
  evidence-record index and in dated `docs/tmp/YYYY-MM-DD-*.md` records.
- On 2026-07-02, compressed duplicated Terminal-Bench suite details in
  `research/STATE.md` into one cumulative handoff paragraph. `research/STATE.md`
  remains a handoff pointer, not the canonical related-work or workload-source
  verdict.
- On 2026-07-02, replaced current-looking duplicated claim, experiment,
  follow-up, result, research-plan, and case-study text in non-canonical files
  with short provenance stubs. The detailed historical content remains
  recoverable through Git history and dated evidence records; current verdicts
  now route only through the canonical files named below.

## Current Routing Contract

When adding new related-work or workload-reproduction evidence:

1. Update `docs/background-related-work.md` only when the evidence changes a
   reviewer-facing verdict, baseline requirement, novelty risk, or next
   experiment choice.
2. Update `docs/reference/CODE_SOURCES.md` only when a new source, repository,
   artifact, or dated evidence-record link needs indexing.
3. Add a standalone dated record under `docs/tmp/YYYY-MM-DD-*.md` for the
   reproduction attempt, design decision, negative result, or implementation
   step.
4. Put raw logs, JSON/JSONL summaries, downloaded datasets, benchmark outputs,
   and generated reports under `results/` or another documented result root.
5. Do not add new source-status tables to `research/STATE.md`,
   `docs/research_plan.md`, or `docs/case_studies.md`; those files may point to
   the canonical docs but should not become parallel verdict stores.

## Source-Role Clarification

AgentFS should be reused for session lifecycle, COW overlay behavior, mount
behavior, cache invalidation, symlink/git-visible behavior, SDK tests, and an
npm-like path-operation mix. Its `pjdfstest` and `xfstests` evidence should be
cited as full-filesystem conformance caveats. They should not define the main
`namei_ext` workload because `namei_ext` does not own create/write/chown/mknod
or full filesystem semantics.

## Remaining Risks

The canonical docs are now aligned on layout and source roles, but the paper
still needs a Make-owned, KVM-validated `namei_ext` workload derived from the
selected agent/workspace or environment/cache sources. A full uninterrupted
adapted AgentFS `xfstests` run remains optional appendix work.
