# Iter Refine Writing Idea Round 1: Problem Framing

Date: 2026-07-09

## What Was Checked

Target: `docs/idea-story.md`

Scope: problem framing only, especially Intro P1, Intro P2, and the
Supporting Research State problem anchor.

Checklist: `iter-refine-writing-idea/references/idea-quality-checklist.md`
Section 1.

## Findings

Subagent finding summary:

- Blocker: Intro P1 named scenarios but did not make the concrete pain visible.
  It said systems need different filesystem views, but did not say what bad
  result occurs when the view is wrong.
- Major: the root cause sounded like a solution assertion. The stronger
  diagnosis is a granularity mismatch between per-lookup state changes and
  whole-filesystem, mount-tree, or materialized-namespace mechanisms.
- Major: the status-quo discussion risked sounding unfair to FUSE and
  NFS-like agent filesystems. The fix is to say those mechanisms are valid
  when a system owns filesystem semantics, but are broader than path-view-only
  policy.
- Major: the framing spread across agents, services, and environment/cache
  workloads without making the main scope clear enough.
- Minor: the internal problem anchor mixed problem definition with evaluation
  readiness.

## What Changed

- `docs/idea-story.md:27-28`
  - Before: P1 opened with the abstract need to present different filesystem
    views.
  - After: P1 opens with concrete failures: wrong workspace branch, stale or
    corrupt cached artifact, hidden files visible before commit, and side
    effects leaking into the host workspace.

- `docs/idea-story.md:38-39`
  - Before: P2 said status-quo mechanisms were powerful but coarse and that
    FUSE/NFS-like systems put the whole path into a user-space service.
  - After: P2 frames status quo more fairly: FUSE/NFS-like systems are natural
    when they own filesystem semantics, custom filesystems and metadata
    services are appropriate when they own metadata/storage, and materialized
    views are useful but precompute/update the namespace outside the current
    lookup.

- `docs/idea-story.md:91-97`
  - Before: Problem Anchor listed bottom-line problem, bottleneck, and success
    condition.
  - After: Problem Anchor now separates pain, root cause, status-quo gap,
    scope, and release gate.

## Verification

`git diff --check` passed after the edit.

No LaTeX compile was run in this round because the current paper LaTeX tree is
a historical routing stub; the active idea layer is `docs/idea-story.md`.

## Remaining Concerns

Round 2 should attack whether the insight is still too obvious: "a narrow
lookup/readdir hook for path-view-only policies" may be read as simply moving
FUSE logic into an eBPF hook unless the framing explains the structural
decomposition more sharply.
