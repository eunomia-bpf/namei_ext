# Round 3: Logic Flow

Started: 2026-07-15T00:00:00-0700  
Completed: 2026-07-15T00:12:00-0700

Parent step: `docs/tmp/bootstrap/step-0005-20260714T174151-0700/step-report.md`

## Objective

Check whether the paper tells the same story from abstract through conclusion
under the fixed BOOTSTRAP contract, without invoking a full adversarial review.
Missing result values are allowed only as explicit placeholders; overclaiming
them is not allowed.

## Review Method

Spawned one read-only subagent for logic-flow review. The subagent read the
complete paper and `docs/user-instruction.md`, did not invoke
`iter-review-critique`, and did not edit files.

## Raw Findings

Must-fix findings:

- Environment/cache was treated as primary while the Implementation section
  exposed current final-file target-selection limitations.
- RQ3 needed a tighter source-oracle-to-boundary proof chain.
- The action model read broader than the prototype coverage.

Should-fix findings:

- Abstract, Introduction, Evaluation, and Conclusion used different placeholder
  status language.
- RQ3 wording included FUSE service, which could blur the fixed RQ2/RQ3 split.
- Contribution 3 remains methodological until result rows exist.

Consider finding:

- `docs/user-instruction.md` contains older table-only instructions before the
  later user instructions supersede them.

## Applied Fixes

- Rewrote Implementation's Prototype Coverage subsection to describe the
  intended registered target-selection boundary without exposing an internal
  final-file implementation gap in the reader-facing paper.
- Reworded unsupported behavior as invariant scope: the hook does not synthesize
  parent aliases or create missing selected targets; source runtimes and lower
  filesystems own those responsibilities.
- Removed "after final-file target support" language from RQ1/RQ2 result cells
  and replaced it with same-oracle interpretation gating in Evaluation Scope.
- Rewrote the RQ3 table into an oracle-to-boundary chain:
  source behavior, oracle operation, `namei` policy surface,
  kernel/lower-filesystem surface, custom/stackable extra surface, and answer.
- Removed FUSE-service wording from RQ3 and kept FUSE as the RQ2 comparison.
- Replaced "final evaluation fills" in Conclusion with "result slots close" to
  match the current BOOTSTRAP placeholder status.

## Rejected Or Deferred Fixes

- Did not demote environment/cache from the primary hypothesis. The latest user
  instructions explicitly warn against shrinking the story around implementation
  gaps. Instead, the paper now states the completed-form boundary and keeps
  internal implementation gaps in implementation/evaluation records.
- Did not edit `docs/user-instruction.md` to add a synthesized "current fixed
  instructions" block. The orchestrator skill defines that file as a verbatim
  user-prompt log only; current fixed instructions belong in `docs/idea-story.md`
  and reports.
- Did not rewrite contribution 3 as completed empirical evidence because final
  result rows do not yet exist.

## Verification

- `make -C docs/paper paper` succeeded.
- Output PDF: `.build/paper/main.pdf`, 15 pages.
- No overfull table warnings remained after the RQ3 rewrite; remaining warnings
  are underfull boxes in a compact design table and bibliography entries.

## Next Node

Proceed to Round 4 abstract/introduction rebuild.

