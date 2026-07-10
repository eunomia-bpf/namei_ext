# Iter Refine Writing Idea Round 3: Contributions And Goals

Date: 2026-07-09

## What Was Checked

Target: `docs/idea-story.md`

Scope: contribution statements, design goals, dominant claim, claim ledger,
and expansion agenda.

Checklist: `iter-refine-writing-idea/references/idea-quality-checklist.md`
Section 3.

## Findings

Subagent finding summary:

- Intro P6 was a compound paragraph mixing abstraction, prototype, non-goals,
  and evaluation purpose.
- Design goals were implicit rather than explicit and testable.
- Dominant Claim mixed current claims and future service workload stretch.
- Claim Ledger mixed design goals, evidence claims, and novelty claims.
- "one BPF decision function" was too assertive as a claim and should become a
  mechanism hypothesis mapped to evaluation.
- Expansion Agenda included too many candidate row IDs for the idea layer.

## What Changed

- `docs/idea-story.md:82-88`
  - Replaced the compound contribution paragraph with three ordered
    contributions: model, system, and evidence plan.
  - Moved non-goals into a separate paragraph.

- `docs/idea-story.md:114-121`
  - Added explicit G1-G4 design goals with evaluation mapping:
    path-view completeness, lower-FS ownership preservation, narrow
    programmable interface, and practical comparison boundary.

- `docs/idea-story.md:123-133`
  - Reframed the "one BPF decision function" as a mechanism hypothesis.
  - Split current claim from service reload/secret-rotation stretch
    opportunity.

- `docs/idea-story.md:145-152`
  - Rewrote Claim Ledger as Model/System/Evidence/Comparison claims.

- `docs/idea-story.md:174-175`
  - Simplified W4 Expansion Agenda to point to SWE-Factory-Gym or
    MEnvData-SWE, with instance-level candidates left in the evidence
    inventory.

## Verification

`git diff --check` passed after the edit.

No LaTeX compile was run because the active idea layer is Markdown and the
LaTeX tree is a historical routing stub.

## Remaining Concerns

Round 4 should check whether problem -> insight -> design goals ->
contributions -> evaluation now tells one coherent story, especially whether
service workload language is consistently treated as stretch rather than a
current claim.
