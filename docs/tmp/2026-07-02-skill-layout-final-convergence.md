# Skill Layout Final Convergence

Date: 2026-07-02

## Motivation

The repository already had routing notes, but several long-lived files still
contained detailed current-looking claim, experiment, and result text. That made
them easy to mistake for canonical verdict stores, contrary to the
`research-literature-novelty` skill layout.

## Files Changed

- `research/CLAIM_LEDGER.md`
- `research/CLAIM_VERDICT.md`
- `research/EXPERIMENT_PLAN.md`
- `research/EXPERIMENT_TRACKER.md`
- `research/FOLLOWUP_PLAN.md`
- `research/RESULTS_SUMMARY.md`
- `research/STATE.md`
- `docs/research_plan.md`
- `docs/case_studies.md`
- `docs/experiment-plans/osdi-evaluation.md`
- `docs/experiment-plans/phase1.md`
- `docs/phase1_design.md`
- `docs/paper/evaluation.md`
- `docs/paper/main.tex`
- `docs/reference/INDEX.md`

## Decision

The non-canonical planning files above are now short provenance stubs or a
short handoff pointer. They no longer duplicate current source-use, novelty,
baseline, claim-verdict, experiment-plan, or result-summary decisions.

The paper draft files were subsequently compressed into routing stubs in
`docs/tmp/2026-07-02-skill-layout-paper-draft-compression.md`. They should not
be used as current claim-verdict, workload-selection, baseline, or result
stores.

Canonical ownership is:

- `docs/idea-story.md` for current story, claim scope, non-goals, and next
  action.
- `docs/background-related-work.md` for related work, closest work, novelty
  risk, workload-source verdicts, mandatory baselines, and reviewer-facing
  next actions.
- `docs/reference/CODE_SOURCES.md` for source repository, dataset, artifact,
  workload-role, and evidence-record indexing.
- `docs/reference/INDEX.md` for PDF inventory.
- `docs/tmp/YYYY-MM-DD-*.md` for standalone dated evidence records.
- `results/` for raw logs, JSON/JSONL, benchmark outputs, and generated
  summaries.
- `research/STATE.md` only for a short current handoff pointer.

## Current Boundary

The current story is not a table-only proof and not an interface-necessity
claim. The paper should not claim that all selected workloads require eBPF,
`namei_ext`, or dynamic policy logic. The next claim-moving step is to
implement a Make-owned, KVM-validated real workload from the already reproduced
agent workspace or environment/cache source pool.

## Validation

After this edit, validation should check Markdown routing and formatting only:

- `git diff --check` on touched documentation files.
- `find docs/tmp -maxdepth 1 -type f ! -name '????-??-??-*.md'`.
- `find docs/tmp -mindepth 2 -type f`.
