# Round 2: Section Conventions

Started: 2026-07-14T18:13:00-0700  
Completed: 2026-07-14T18:25:00-0700

Parent step: `docs/tmp/bootstrap/step-0005-20260714T174151-0700/step-report.md`

## Objective

Check section-specific conventions: abstract structure, introduction roles,
design-goal paragraph, explicit RQ evaluation overview, one evidence block per
RQ, related-work grouping, conclusion structure, and absence of orphan
experiments.

## Review Method

Spawned one read-only subagent to invoke `check-paper-structure-flow` with
section-conventions focus. The subagent did not edit files.

## Raw Findings

Must-fix findings:

- Abstract still ended with plan/status language rather than final result
  wording.
- Evaluation still looked like a BOOTSTRAP plan because result cells remain
  placeholders.
- Introduction contribution 3 did not yet name actual completed evidence.
- RQ blocks still include answer criteria and explicit unanswered statements.
- Environment/cache primary evaluation conflicts with current prototype text
  saying final-file target selection is not yet implemented.
- Conclusion still used planned-evaluation language.

Should-fix findings:

- Page budget is still 15 pages.
- RQ2 baseline discipline should keep no-hook/lower-FS rows out of the RQ2
  comparison table.
- RQ3 table should bind each row to source behavior and fail-closed evidence.
- Motivation still includes some workload-admission protocol.

## Applied Fixes

- Shortened the abstract by merging the mechanism and prototype sentences.
- Reworded the abstract ending to use explicit result slots rather than claiming
  final results.
- Moved no-hook/lower-FS calibration out of the RQ2 comparison rows and into
  the setup paragraph.
- Reworked the RQ3 table to include source behavior, `namei`-owned surface,
  custom/stackable-owned surface, containment evidence, and answer.
- Added Evaluation Scope wording that environment/cache result rows are not
  interpreted until final-file target selection exists and the same source
  oracle passes.
- Fixed a small RQ3 table overfull warning by narrowing columns and replacing
  `hit/miss/stale/corrupt` with `cache-state`.

## Rejected Or Deferred Fixes

- Did not add actual completed result numbers. This is a BOOTSTRAP pass; the
  final result claims must be filled by reviewed BUILD_AND_EVALUATE KVM/FUSE/RQ3
  evidence.
- Did not move environment/cache to future work. The user explicitly instructed
  not to shrink the hypothesis around current implementation gaps unless the
  hypothesis itself is impossible. The paper now states the implementation gate
  instead.
- Did not remove the explicit unanswered answer endings. They are required to
  keep BOOTSTRAP placeholders honest until results exist.

## Verification

- `make -C docs/paper paper` succeeded.
- Output PDF: `.build/paper/main.pdf`, 15 pages.
- The previous RQ3 table overfull warning is gone. Remaining warnings are
  underfull boxes in a compact design table and bibliography entries.

## Next Node

Proceed to Round 3 logic-flow review.

