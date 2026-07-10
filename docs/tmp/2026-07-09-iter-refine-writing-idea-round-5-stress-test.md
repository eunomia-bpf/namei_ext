# Iter Refine Writing Idea Round 5: Reviewer Stress Test

Date: 2026-07-09

## What Was Checked

Target: `docs/idea-story.md`

Scope: final skeptical OSDI/SOSP review of the idea layer: problem framing,
insight, novelty, contributions, design goals, claim scope, workload framing,
and whether an easy reject argument remains.

Checklist: `iter-refine-writing-idea/references/idea-quality-checklist.md`,
Round 5.

## Findings

First stress-test verdict:

- Easy rejection was still available.
- The strongest reject was not table-only, nor whether workloads are dynamic.
  The risk was circular framing: the document defined the success domain as
  workloads expressible by lookup/readdir object selection, then claimed that
  selected workloads fit that model.
- The value over FUSE/custom filesystems/materialization was also too weak when
  stated only as "narrower"; the document needed to state what narrowness buys:
  lower-FS ownership, no filesystem-method ownership, no daemon dependency, or
  less per-transition materialization.

Second stress-test verdict after edits:

- Easy rejection still available: no.
- Remaining non-easy risks:
  - Evidence risk: source-derived workload classification must show the class
    is real, not handpicked.
  - Baseline risk: FUSE/source-system/materialized baselines need the same
    oracle and fair setup/update/runtime accounting.
  - Novelty risk: related work must distinguish this from stackable filesystems,
    passthrough filesystems, and prior programmable path mechanisms.
  - Scope risk: the paper must show that "narrower" yields concrete value:
    preserved lower-FS semantics, no filesystem-method ownership, no daemon
    dependency, or less materialization work.

## What Changed

- `docs/idea-story.md:4`
  - Updated the stage from round 4 cross-alignment to round 5 stress-test
    refinement.

- `docs/idea-story.md:52-56`
  - Replaced the circular "model applies when selected behavior is
    lookup/readdir expressible" framing with an independent workload class:
    state-transition path views.
  - Defined that class as state changes that alter pathname-to-object binding
    or visibility while lower filesystem responsibilities remain unchanged.

- `docs/idea-story.md:74-78`
  - Required the evaluation to start from upstream state transitions and
    classify each oracle-relevant filesystem effect as object selection,
    visibility, lower-filesystem behavior, or out-of-model behavior.
  - Stated that out-of-model transitions are excluded from the current claim
    rather than counted as successes.

- `docs/idea-story.md:85-90`
  - Rewrote Contribution 1 as a state-transition path-view abstraction.
  - Rewrote Contribution 3 so source-derived transitions instantiate the
    abstraction instead of selected workloads merely fitting it.

- `docs/idea-story.md:103-113`
  - Reframed the status quo gap and "why now" text around state changes that
    affect pathname binding or visibility.

- `docs/idea-story.md:123-136`
  - Updated G1, G3, the thesis sentence, mechanism hypothesis, and dominant
    target claim to use source-derived state-transition path views.
  - Made the positive value explicit: `namei_ext` preserves lower-filesystem
    ownership while avoiding a separate filesystem server or per-transition
    materialized namespace.

- `docs/idea-story.md:154-162`
  - Rewrote the claim ledger so C1 names a recurring filesystem subproblem,
    C3 requires correctness through the policy-only object-selection boundary,
    and C4 names the concrete comparison value rather than only claiming a
    narrower mechanism.

## Verification

`git diff --check` passed after the edit.

The second Round 5 reviewer stress test reported that no easy rejection remains.

No LaTeX compile was run because the active idea layer is Markdown and the
LaTeX tree is a historical routing stub.

## Remaining Concerns

The idea framing is now past the easy-reject gate, but the research still needs
evidence: AgentFS-derived workspace lifecycle and a W4 environment/cache
workload must pass G1 classification, KVM correctness, operation-weighted trace
collection, and natural baseline comparison before the target claim can become
a paper result.
