# Skill Layout Research File Routing

Date: 2026-07-02

## Motivation

The `research-literature-novelty` skill requires durable related-work,
novelty, baseline, and source-use conclusions to converge in
`docs/background-related-work.md`, with source/code entry points in
`docs/reference/CODE_SOURCES.md` and raw artifacts under `results/`. Older
files under `research/` still contained useful history, but their titles made
them easy to mistake for current canonical verdicts.

## Files Inspected

- `docs/background-related-work.md`
- `docs/reference/CODE_SOURCES.md`
- `docs/idea-story.md`
- `docs/research_plan.md`
- `docs/case_studies.md`
- `research/STATE.md`
- `research/CLAIM_LEDGER.md`
- `research/CLAIM_VERDICT.md`
- `research/EXPERIMENT_PLAN.md`
- `research/EXPERIMENT_TRACKER.md`
- `research/FOLLOWUP_PLAN.md`
- `research/RESULTS_SUMMARY.md`

## Decision

The current routing contract is:

- `docs/idea-story.md` owns current story, claim scope, non-goals, and paper
  direction.
- `docs/background-related-work.md` owns novelty risk, closest work,
  workload-source verdicts, mandatory baselines, and reviewer-facing next
  actions.
- `docs/reference/CODE_SOURCES.md` owns stable repository, artifact, and
  source-entry-point facts.
- `docs/reference/INDEX.md` owns the PDF inventory.
- `research/STATE.md` is a handoff pointer only.
- `research/CLAIM_LEDGER.md`, `research/CLAIM_VERDICT.md`,
  `research/EXPERIMENT_PLAN.md`, `research/EXPERIMENT_TRACKER.md`,
  `research/FOLLOWUP_PLAN.md`, and `research/RESULTS_SUMMARY.md` are retained
  as historical or working provenance, not as current canonical verdict stores.
- Raw logs, JSON/JSONL, generated summaries, and benchmark output belong under
  `results/`.

## Edits Made

Added explicit 2026-07-02 routing notes to the six `research/*.md` files above
so later agents do not treat stale source-role, table-only, or result-verdict
text as the current paper route.

Updated `docs/background-related-work.md` search log and the earlier
`docs/tmp/2026-07-01-skill-layout-documentation-convergence.md` record to
capture this cleanup.

Follow-up on the same date: `docs/tmp/2026-07-02-skill-layout-final-convergence.md`
records the stronger convergence pass that replaced current-looking duplicated
content in `research/*.md`, `docs/research_plan.md`, and `docs/case_studies.md`
with short provenance stubs or a short handoff pointer.

## Remaining Risk

The documentation now has a clear skill-compatible ownership layout. The
remaining research risk is not documentation layout; it is building a
Make-owned, KVM-validated real workload from the source-backed agent workspace
or environment/cache systems already indexed in the canonical docs.
