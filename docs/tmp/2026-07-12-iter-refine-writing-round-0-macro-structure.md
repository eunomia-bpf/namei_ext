# Iter-Refine-Writing Round 0: Macro Structure

Date: 2026-07-12
Skill: `iter-refine-writing`
Round: 0, Macro Structure

## Objective

Run the first writing-refinement round after restoring the idea. This round
checks section order, required full-paper sections, design/implementation
separation, architecture overview, and RQ-organized evaluation while preserving
the restored scientific position.

## Inputs

- `docs/user-instruction.md`
- `docs/idea-story.md`
- `docs/paper/main.tex`
- `docs/paper/sections/*.tex`
- `check-paper-structure-flow/SKILL.md`
- `check-paper-structure-flow/references/full-paper-12p.md`

## Reviewer Findings

The read-only reviewer found that the scientific position stayed restored, but
the macro structure still looked like a proposal draft. Must-fix items were:

1. Add a neutral Background section before workload characterization.
2. Add a Design overview/architecture figure and typical operation walkthrough.
3. Change `Evaluation Plan` into an RQ-organized Evaluation section.
4. Remove proposal language such as `This draft targets`, `should come from`,
   and `next step`.
5. Add Discussion before Related Work and move limitations there.

Should-fix items were:

1. Move implementation-specific `cgroup/namei_ext` attachment wording out of
   the design table.
2. Add a transition from workload requirements to design.
3. Expand Implementation's concrete mapping.
4. Make Related Work continue using the ownership-boundary axis.

## Applied Fixes

- Added `docs/paper/sections/02-background.tex`.
- Updated `docs/paper/main.tex` section order to include Background and place
  Discussion before Related Work.
- Added a Design system overview and ownership-boundary figure.
- Replaced `cgroup/namei_ext` in the design table with workload-scoped
  attachment.
- Expanded Implementation with call-site mapping, ABI fields, lower-object
  registration, permission preservation, failure handling, and KVM validation
  boundary.
- Reorganized Evaluation into RQ1--RQ4 evidence blocks with explicit current
  answers or `unanswered` status.
- Renamed Limitations to Discussion, preserving scope limits and adding an
  extension path that rejects future shrinkage.
- Removed proposal phrasing from Introduction, Motivation, and Conclusion.

## Rejected Or Deferred Fixes

- A polished graphical architecture figure is deferred to `paper-figures`. The
  current LaTeX figure is enough to satisfy the macro structure check without
  introducing external assets.

## Scope Preservation

All edits preserve the restored claim: `namei_ext` is a `sched_ext`-style VFS
extension point between bind/Overlay/materialization and FUSE/custom
filesystems. The round explicitly avoided converting the paper back into a
table-only or two-transition claim.

## Validation

Validation is run after this round in the main workflow.
