# Iter-Refine-Writing Round 3: Logic Flow

Date: 2026-07-12
Skill: `iter-refine-writing`
Round: 3, Logic Flow

## Objective

Check section-to-section and paragraph-to-paragraph logic flow after the
section-convention fixes. Preserve the restored scientific scope:
`namei_ext` is a `sched_ext`-style VFS extension point between
bind/Overlay/materialization and FUSE/custom filesystems.

## Inputs

- `docs/user-instruction.md`
- `docs/idea-story.md`
- `docs/paper/main.tex`
- `docs/paper/sections/*.tex`
- `iter-refine-writing/SKILL.md`
- `check-paper-structure-flow/SKILL.md`
- `check-paper-structure-flow/references/full-paper-12p.md`

## Reviewer Findings

The read-only reviewer found that the idea remained restored, but the paper had
several logic-flow gaps:

1. The abstract, introduction, and conclusion blurred the distinction between
   source characterization, design/prototype boundary, and unresolved KVM
   mechanism-value evidence.
2. Evaluation introduced protocol/evidence status before defining RQs.
3. RQ1 did not directly reference the characterization tables as the evidence.
4. Workload characterization observations did not explicitly derive the design
   invariants.
5. RQ4 implied that out-of-model scope classification requires negative KVM
   runs, even though many effects can be classified from source oracles and the
   design boundary.
6. Contribution 3 read like a protocol-only contribution without clarifying the
   current evidence status.
7. Some related-work wording remained defensive rather than ownership-axis
   comparative.

## Applied Fixes

- Split evidence language into three parts: characterization supports workload
  taxonomy; design/prototype establish the proposed ownership boundary; KVM
  runs decide mechanism sufficiency and boundary value.
- Moved Evaluation research questions before protocol/evidence status.
- Made RQ1 explicitly point to the characterization tables and their answer.
- Added a bridge from characterization observations to design invariants.
- Clarified that RQ4 can classify out-of-model effects from source oracles and
  design boundary; KVM validates attempted path-view slices.
- Rephrased contribution 3 as a correctness-first evidence plan rather than a
  completed result.
- Clarified `deny` as an optional attachment-mode result rather than the core
  path-view claim.
- Rewrote related-work wording around ownership points instead of defensive
  non-replacement language.

## Scope Preservation

The edits preserve the larger abstraction. They only prevent evidence-status
overclaiming and make the chain from workload characterization to design,
evaluation, and conclusion explicit.

## Validation

Validation is run after this round in the main workflow.
