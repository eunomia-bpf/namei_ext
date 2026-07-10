# Iter Refine Writing Idea Round 4: Cross-Alignment

Date: 2026-07-09

## What Was Checked

Target: `docs/idea-story.md`

Scope: alignment from problem framing to key insight, design goals,
contributions, claim ledger, workload selection, and evaluation promise.

Checklist: `iter-refine-writing-idea/references/idea-quality-checklist.md`
Sections 1-3, with emphasis on whether the story can be read as one coherent
argument.

## Findings

Subagent finding summary:

- Service reload/secret-rotation was simultaneously treated as current scope
  and stretch scope.
- The document used "current claim" language before the two required KVM
  workload families have passed.
- G1 needed a per-transition completeness test, not only a statement that a
  workload is lookup/readdir dominated.
- Lower-object consistency and path-view freshness needed to be separated.
- The comparison goal needed an executable baseline matrix rather than a broad
  promise to compare against FUSE/custom filesystems/materialization.
- AgentFS should be the first official agent workload target, with other agent
  systems used as supporting evidence rather than mixed into one target.
- The root-cause statement needed to distinguish materialization outside lookup
  from implementing a filesystem/server method inside lookup.
- Evidence dependencies mixed primary executable evidence with motivation and
  related-work evidence.

## What Changed

- `docs/idea-story.md:30-32`
  - Split primary executable evidence from motivating and related evidence.
  - Made AgentFS-derived workspace lifecycle the first workload target.

- `docs/idea-story.md:73-78`
  - Removed service workload from the current evaluation promise.
  - Added a G1 gate: every oracle-relevant transition must be classifiable as
    lookup/readdir object selection or hiding; transitions requiring
    workload-specific data-path interposition fail the model.

- `docs/idea-story.md:84-90`
  - Kept the three contribution structure but marked Contribution 3 as a
    candidate until two KVM workload families pass.

- `docs/idea-story.md:103-107`
  - Rewrote the problem anchor to name pain, root cause, status quo gap, scope,
    and release gate separately.

- `docs/idea-story.md:121-126`
  - Strengthened G1-G4 so each goal has a concrete evaluation mapping.
  - Separated lower-object consistency from path-view freshness.
  - Added required baseline-matrix fields for G4.

- `docs/idea-story.md:134-138`
  - Changed the dominant claim to a target claim that only activates after two
    KVM workload families pass.
  - Moved service reload/secret-rotation to stretch opportunity.

- `docs/idea-story.md:159-180`
  - Reframed the largest plausible claim as a policy-only middle point.
  - Made AgentFS-derived COW workspace lifecycle the first probe.
  - Kept Redis AFS, Mirage, BranchFS, Sandlock, YoloFS, OpenHands, SWE-agent,
    and SWE-ReX as supporting motivation, checklist, or baseline sources.

## Verification

`git diff --check` passed before this log was written.

No LaTeX compile was run because the active idea layer is Markdown and the
LaTeX tree is a historical routing stub.

## Remaining Concerns

Round 5 should test whether a skeptical OSDI/SOSP reviewer can still reject the
idea story as "just FUSE", "just eBPF in lookup", or unsupported by current
evidence. If that reject argument is easy, the target claim and contribution
language need one more tightening pass.
