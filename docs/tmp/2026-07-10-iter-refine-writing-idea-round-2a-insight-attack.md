# Iter Refine Writing Idea Round 2a: Insight Attack

Date: 2026-07-10

## What Was Checked

Target: `docs/idea-story.md`

Scope: adversarial novelty review of the key insight and mechanism framing.

Checklist: `iter-refine-writing-idea/references/idea-quality-checklist.md`
Section 2.

## Findings

Subagent finding summary:

- A strong novelty attack was still possible, though not fatal.
- The paper could be read as observing that some workloads need
  state-dependent pathname-to-object binding and then placing a programmable
  hook at VFS name resolution.
- FUSE, stackable filesystems, OverlayFS, union mounts, and VFS interposition
  already treat pathname lookup as the point where names become objects.
- The distinction risked reading as implementation placement and narrower
  scope rather than a new systems insight.
- The key weak wording was the state-indexed mapping from event, pathname, and
  state to lower object, because it sounded like generic path rewrite or
  stackable filesystem policy.
- The positive value in C4 was still phrased like an engineering benefit list
  rather than the actual insight.

## What Changed

No edits were made in this attack sub-round.

## Remaining Concerns

Round 2b should reframe the insight away from "lookup can choose objects" and
toward a missing decomposition: state-transition object selection should be
separable from namespace materialization and filesystem-service ownership.
