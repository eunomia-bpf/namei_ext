# Paper Claim Scope Integration

> 2026-06-29 baseline scope update: this historical record preserves prior reasoning and results. Current C8/B12 guidance is claim-driven baseline selection; exact-map diagnostics are optional boundary evidence only when precomputed mapping is the competing claim.

Date: 2026-06-16

## Motivation

The W3 Redis materialized and FUSE baseline supplement closed the previous
baseline-input gap, but the resulting W3 ledger is threshold-negative. Current
Phase 1 evidence now shows one positive C2 slice, W2 nginx fixture, and three
negative or unsupported workload slices, W1 build graph, W3 Redis checkpoint
replay, and W4 ccache bulk. The paper needed to expose that verdict earlier so
the abstract and introduction do not imply a completed global C2 or C8 claim.

## Files Inspected

- `research/STATE.md`
- `research/CLAIM_LEDGER.md`
- `research/CLAIM_VERDICT.md`
- `research/FOLLOWUP_PLAN.md`
- `docs/paper/main.tex`
- `docs/paper/sections/01-introduction.tex`
- `docs/paper/sections/05-evaluation.tex`
- `docs/paper/sections/07-limitations.tex`

## Design Choice

The edit preserves the current negative evidence rather than hiding it behind
future-work language. The paper now states the current verdict in the abstract,
introduction, evaluation opening, and limitations:

- W2 nginx fixture is the only C2 storage/threshold-supported slice.
- W1 build graph remains negative after copy, symlink, bind, projected-volume,
  and FUSE baselines.
- W3 Redis checkpoint replay remains negative after materialized checkpoint-view
  and FUSE checkpoint-view baselines.
- W4 bulk ccache remains negative after materialized and FUSE cache-view
  baselines plus proposed-system setup/update release input.
- C8 remains unsupported because current W3/W4 table-only comparators pass the
  sampled oracle.

This is a paper-integration change, not a new experimental result.

## Alternatives Rejected

- Do not remove W1, W3, or W4 from the paper. They are useful negative evidence
  and define the current scope boundary.
- Do not claim W3 is blocked by a missing FUSE baseline. The FUSE baseline now
  exists, and the remaining issue is setup/update threshold failure.
- Do not turn W4 FUSE cache-view input into a complete compile-through-FUSE
  baseline. The current artifact is read-oriented cache-view baseline input.

## Validation Plan

Run the paper checks and whitespace checks after the prose edit. No KVM run is
required because no code, result parser, input hash, or raw artifact changed.

## Subagent Review Follow-up

An OSDI-style read-only review reported that the draft is not weak-accept ready
because C1/C8 remain blocked and C2/C3/C5 remain unsupported. The review also
flagged five paper-level overclaim risks. This step addressed them as follows:

- The abstract and introduction now distinguish W4 bulk materialized/FUSE
  cache-view input from a complete compile-through-FUSE or native/cache-remap
  baseline.
- The claim quick table now reports the latest tail10 C3 result and no-hook
  C5 residual instead of the older ctx-split shorthand.
- The claim-gate paragraph now states that the current draft has not met the
  submission-level main-figure requirements.
- The related-work comparison now treats OverlayFS, bind mount, symlink forest,
  and copy tree as necessary baselines whose insufficiency is not yet proved
  outside the supported W2 slice.
- The limitations section now restates W1, W3, and W4 negative C2 values so
  the paper closes with the same scope as the abstract and evaluation.

## Remaining Risks

The draft is still not OSDI weak-accept ready. The current paper-level story is
honest, but it is mostly an evaluation contract with mixed or negative evidence.
The next high-value action is either to narrow the thesis around the supported
W2 slice and artifact discipline, or to add a new W4 workload/baseline that can
change the C2/C8 verdict.
