# Canonical Frontier Alignment

Timestamp: 2026-07-13T00:46:18-07:00
Phase: BOOTSTRAP
Step: 0002
Gate: recovery/frontier alignment
Status: complete

## Question And Entry

After BOOTSTRAP re-entry, several canonical docs still described the project as
having a frozen BUILD_AND_EVALUATE contract or an active Agent workspace Loop
002. This node aligns the current frontier with the latest user instruction and
the recovery decision.

## Inputs And Method

Inputs read:

- `docs/idea-story.md`
- `docs/design.md`
- `docs/evaluation.md`
- `docs/implementation.md`
- `docs/background-related-work.md`
- `docs/questions-for-author.md`
- `research/STATE.md`
- `docs/tmp/build-and-evaluate/step-0002-20260713T002404-0700/step-report.md`

Method: preserve historical claims and raw results, but change current-status
fields and next-action routing so no current document tells a later agent to
continue BUILD_AND_EVALUATE before the renewed BOOTSTRAP step finishes.

## Results And Raw Evidence

Updated current-frontier docs:

- `docs/idea-story.md`: current phase is BOOTSTRAP, current step root is
  `docs/tmp/bootstrap/step-0002-20260713T004618-0700/`, and hypotheses are
  BOOTSTRAP candidates rather than frozen BUILD_AND_EVALUATE claims.
- `docs/design.md`: current design status is an active BOOTSTRAP candidate.
- `docs/evaluation.md`: the experiment set is a candidate evaluation promise;
  current Make experiment entrypoints are paused as final-result commands.
- `docs/implementation.md`: implementation artifacts are feasibility,
  dependency, or prototype evidence until a renewed freeze and later result
  review.
- `docs/background-related-work.md`: related-work frontier is reopened for
  BOOTSTRAP pressure.
- `docs/questions-for-author.md`: the default action points to BOOTSTRAP step
  0002 before BUILD_AND_EVALUATE resumes.
- `research/STATE.md`: handoff pointer now names BOOTSTRAP as current.
- `docs/tmp/build-and-evaluate/step-0002-20260713T002404-0700/step-report.md`:
  marked paused/superseded by BOOTSTRAP re-entry.

The consistency scan still finds `BUILD_AND_EVALUATE` and `frozen` in
historical contexts, previous-step reports, and future-routing conditions. That
is expected and preserves provenance.

## Scientific Impact And Decision

The active scientific contract is now explicitly unfrozen. The strong
`sched_ext`-style VFS name-resolution story remains the leading candidate, but
the next research action is BOOTSTRAP pressure, not Agent workspace Loop 002
implementation.

This avoids a repeated drift pattern: treating an incomplete implementation run
as a reason to continue a frozen experiment route before the paper-level story
and evidence promise have been re-accepted.

## Completion And Next Action

This alignment node is complete. The current active node remains
`01-experiment-gate/000-gate-entry-20260713T004618-0700.md`. The next action is
to run BOOTSTRAP-level pressure on the candidate story, workload coverage,
closest work, and baseline families before any renewed freeze.
