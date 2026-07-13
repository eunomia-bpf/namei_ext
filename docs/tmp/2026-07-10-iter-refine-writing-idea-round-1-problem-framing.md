# Iter Refine Writing Idea Round 1: Problem Framing

Date: 2026-07-10

## What Was Checked

Target: `docs/idea-story.md`

Scope: problem statement, root-cause paragraph, status quo gap, scope, and
whether the problem can be stated without naming `namei_ext`.

Checklist: `iter-refine-writing-idea/references/idea-quality-checklist.md`
Section 1.

## Findings

Subagent finding summary:

- The pain was still category-level and should name concrete failed operations:
  validating the wrong revision, leaking writes into a parent workspace, and
  feeding stale cache inputs into a build.
- The root cause was too solution-led. It should be stated as a structural
  mismatch between workspace/branch/cache-epoch state changes and namespace
  ownership or update granularity.
- The status quo was too uniform. The text should acknowledge that FUSE can
  compute dynamic views and OverlayFS selects layers during lookup, then
  distinguish their ownership and model boundaries.
- The scope overgeneralized. Until KVM evidence exists, the claim should be
  bounded to the studied AgentFS-derived transition and one environment/cache
  transition.
- "Why now" should emphasize reproducibility and measurability rather than
  claiming existing approaches are newly insufficient.
- Checkpoint/commit wording could imply transactional guarantees; atomic
  multi-object commits and transactional snapshots should stay out of scope.
- "Request state" should be removed unless a request-scoped workload exists.

## What Changed

- `docs/idea-story.md:27-34`
  - Rewrote P1 around concrete failures: wrong revision validation, parent
    workspace write leakage, and stale cache inputs.
  - Removed request-state wording from the problem statement.

- `docs/idea-story.md:40-45`
  - Reframed the status quo around ownership boundaries.
  - Added explicit acknowledgments that FUSE/NFS-like designs can compute
    dynamic views and OverlayFS selects among layers during lookup.
  - Reframed the gap as changing pathname-to-object bindings or visibility
    while leaving ordinary filesystem ownership and semantics unchanged.

- `docs/idea-story.md:92-93` and `docs/idea-story.md:146-148`
  - Added cross-path transactional snapshots and atomic multi-object commits to
    non-goals and out-of-scope items.

- `docs/idea-story.md:101-113`
  - Rewrote the Problem Anchor around concrete pain, structural root cause,
    status quo gap, and why the question is now measurable.

- `docs/idea-story.md:134-138`
  - Bounded the target claim to the examined AgentFS-derived workspace
    transition and one examined environment/cache transition.

- `docs/idea-story.md:152-162`
  - Narrowed C1 and the thesis candidate from a broad recurring-subproblem
    claim to studied workflow effects.

## Verification

No LaTeX compile was run because Round 1 edited the Markdown idea layer.

`git diff --check` is run after each edit round and before the next review
round.

## Remaining Concerns

Round 2 should stress-test whether the narrowed, studied-transition framing is
still novel enough, or whether it now becomes too small to support a systems
paper claim.
