# Iter Refine Writing Idea Round 2a: Insight Attack

Date: 2026-07-09

## What Was Checked

Target: `docs/idea-story.md`

Scope: adversarial attack on insight and novelty framing, especially Intro P3,
Intro P4, Intro P6, Method Thesis, Dominant Claim, and Largest Plausible
Claim.

Checklist: `iter-refine-writing-idea/references/idea-quality-checklist.md`
Section 2.

## Findings

Subagent strongest rejection argument:

> The paper's claimed insight is that some workloads only need dynamic path
> selection, not a new filesystem. But that is not surprising: stackable
> filesystems, union/overlay filesystems, bind mounts, FUSE passthrough
> filesystems, namespace construction tools, and VFS interposition already
> exist because systems remap pathnames while preserving lower filesystem
> semantics. The paper appears to move an already-known policy point into an
> eBPF hook at lookup/readdir time.

Specific weaknesses:

- The prior P3 looked like the implementation answer, not the insight.
- The common structure across workspace, branch, cache epoch, and service
  state was under-defined.
- The "one decision function" was framed as ABI shape rather than a
  decomposition.
- The non-goal-heavy contribution paragraph made the positive contribution
  sound like kernel engineering.
- The phrase "general programmable filesystem abstraction" conflicted with
  the claim that the mechanism is narrower than FUSE/custom filesystems.

## What Was Changed

No files were changed by the subagent. This attack informed the Round 2b
defense edit.

## Remaining Concerns

The defense must make the transferable idea explicit: state-indexed path-view
policy can be separated from filesystem ownership. The insight cannot be "put
eBPF in VFS lookup."
