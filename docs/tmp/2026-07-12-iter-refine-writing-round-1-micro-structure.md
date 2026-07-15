# Iter-Refine-Writing Round 1: Micro Structure

Date: 2026-07-12
Skill: `iter-refine-writing`
Round: 1, Micro Structure

## Objective

Check paragraph roles, section-local flow, repeated text, unclear claims, and
wording that could accidentally shrink the restored idea. This round preserves
the scientific scope: `namei_ext` is a `sched_ext`-style VFS extension point
between bind/Overlay/materialization and FUSE/custom filesystems.

## Inputs

- `docs/user-instruction.md`
- `docs/idea-story.md`
- `docs/paper/main.tex`
- `docs/paper/sections/*.tex`
- `iter-refine-writing/SKILL.md`
- `check-paper-structure-flow/SKILL.md`
- `check-paper-structure-flow/references/full-paper-12p.md`

## Reviewer Findings

The read-only reviewer found that the idea was restored, but the paper body
still exposed internal route-repair language. Must-fix findings were:

1. Reorder the introduction around problem, gap, positive thesis, system,
   method, and contributions.
2. Replace defensive `central claim is not exclusivity` topic wording with a
   positive thesis.
3. Remove paper-body phrases such as `restored idea`, `two-case feasibility`,
   venue/process language, `conceptual shrinkage`, and historical diagnostic
   baseline notes.
4. Restate the conclusion directly rather than saying the project returns to a
   previous question.

Should-fix findings were:

1. Split and clarify the abstract.
2. Split workload characterization into source evidence, requirements, and
   representative workloads.
3. Add service/config representative workload prose so the body does not read
   as only two workloads.
4. Change design boundary wording from whole workloads to transitions/effects.
5. Split the policy model paragraph into state, target registration, and
   kernel validation.
6. Keep Background neutral and move argumentation to later sections.

## Applied Fixes

- Rewrote the abstract around the positive missing-middle insight.
- Reordered the introduction so the positive thesis precedes the system
  description.
- Expanded the contribution text to include service/config systems.
- Neutralized the Background ending.
- Added `Requirements` and `Representative Workloads` subsections.
- Added service/config representative workload prose.
- Revised the Design table caption to talk about transitions/effects rather
  than whole workloads.
- Split the Policy Model paragraph into separate policy-state, target, and
  validation paragraphs.
- Replaced internal route-repair language in Evaluation, Discussion, and
  Conclusion.
- Tightened Related Work wording for DeltaFS/IndexFS/TableFS as baselines only
  when metadata-service ownership is required.

## Scope Preservation

No scientific scope was narrowed. The paper remains about a `sched_ext`-style
VFS name-resolution extension point between namespace construction and
filesystem ownership. FUSE, materialized views, source systems, and metadata
services remain natural same-oracle baselines rather than mechanisms to dismiss.

## Validation

Validation is run after this round in the main workflow.
