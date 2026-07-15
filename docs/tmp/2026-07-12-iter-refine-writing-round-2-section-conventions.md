# Iter-Refine-Writing Round 2: Section Conventions

Date: 2026-07-12
Skill: `iter-refine-writing`
Round: 2, Section Conventions

## Objective

Check whether the active paper follows systems-paper section conventions while
preserving the restored scientific scope: `namei_ext` is a `sched_ext`-style
VFS extension point between bind/Overlay/materialization and FUSE/custom
filesystems.

## Inputs

- `docs/user-instruction.md`
- `docs/idea-story.md`
- `docs/paper/main.tex`
- `docs/paper/sections/*.tex`
- `iter-refine-writing/SKILL.md`
- `check-paper-structure-flow/SKILL.md`
- `check-paper-structure-flow/references/full-paper-12p.md`

## Reviewer Findings

The read-only reviewer found that the idea was not shrinking, but the paper
still read like a recovered research draft or experiment plan rather than a
systems-paper draft. Must-fix items were:

1. Expand the abstract to include methodology, evidence status, and result
   boundary.
2. Split the Introduction into the standard background, problem, root cause,
   existing approaches, insight, system/method/evidence, and contributions
   chain.
3. Remove repo-maintenance wording from Workload Characterization.
4. Move requirements/design goals out of Workload Characterization and into
   Design.
5. Add Evaluation protocol/setup before RQ evidence blocks.
6. Replace `Current answer` plan language with formal evidence status.
7. Move evidence limits into Evaluation and leave Discussion for implications.
8. Rewrite Conclusion as a thesis and evidence-status summary.

Should-fix items were:

1. Put System Overview before design invariants.
2. Add an implementation summary.
3. Split agent workspace filesystem related work from agent/evaluation
   environment related work.

## Applied Fixes

- Removed the draft-synchronization date from the paper title block.
- Expanded the abstract to around full-paper convention length and added
  method/evidence-status language.
- Rebuilt the Introduction around the standard systems-paper logic chain.
- Replaced Workload Characterization repo wording with formal evidence table
  wording.
- Replaced the motivation-side R1--R6 requirements list with characterization
  observations.
- Reordered Design so System Overview precedes Design Goals and Invariants.
- Kept the R1--R6 requirement mapping in Design as the design contract.
- Added an Implementation summary paragraph.
- Added Evaluation `Protocol And Evidence Status`.
- Converted RQ blocks from `Current answer` to `Evidence status`.
- Added Evaluation `Limitations And Interpretation`.
- Simplified Discussion to implications, negative-result use, and extension
  path.
- Split Related Work into agent workspace filesystems and agent/evaluation
  environments.
- Rewrote the Conclusion as a thesis plus current evidence boundary.

## Scope Preservation

No claim was narrowed. The edits make the restored abstraction read like a
formal systems paper while preserving the distinction between path-view policy,
namespace construction, filesystem-service ownership, and out-of-model runtime
or metadata effects.

## Validation

Validation is run after this round in the main workflow.
