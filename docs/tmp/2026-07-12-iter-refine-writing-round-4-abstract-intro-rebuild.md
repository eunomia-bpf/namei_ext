# Iter-Refine-Writing Round 4: Abstract And Introduction Rebuild Check

Date: 2026-07-12
Skill: `iter-refine-writing`
Round: 4, Abstract/Introduction Rebuild

## Objective

Check whether the abstract and introduction need another full rebuild after the
logic-flow fixes. Preserve the restored scope: `namei_ext` is a
`sched_ext`-style VFS extension point between bind/Overlay/materialization and
FUSE/custom filesystems.

## Inputs

- `docs/user-instruction.md`
- `docs/idea-story.md`
- `docs/paper/main.tex`
- `docs/paper/sections/01-introduction.tex`
- `docs/paper/sections/05-evaluation.tex`
- `docs/paper/sections/08-conclusion.tex`
- `iter-refine-writing/SKILL.md`
- `check-paper-structure-flow/SKILL.md`

## Reviewer Findings

The read-only reviewer concluded that the abstract and introduction no longer
need a full rebuild. The mainline is restored and reads as a `sched_ext`-style
VFS extension point between materialized namespaces and FUSE/custom
filesystems. Remaining issues were evidence-status wording and contribution
wording:

1. `supports/establishes workload taxonomy` was too strong relative to the
   Evaluation section's partially answered RQ1 status.
2. Contribution 1 should say source-derived characterization with explicit
   evidence status, not completed characterization.
3. Contribution 3 should not present a protocol as if it were a completed
   evaluation result.
4. Contribution 4 should classify source-system effects rather than claim the
   boundary has already been proven sufficient.

## Applied Fixes

- Changed workload-taxonomy language to `preliminary` in abstract and
  conclusion.
- Mapped the introduction evidence paragraph to characterization, KVM
  sufficiency, same-oracle boundary value, and scope classification.
- Reworded contribution 1 as a source-derived characterization with explicit
  evidence status.
- Reworded contribution 3 as a correctness-first evaluation protocol and
  pending KVM workload plan.
- Reworded contribution 4 as scope classification between path-view policy and
  broader mechanisms.
- Clarified that the abstract describes a KVM evaluation protocol, not completed
  KVM results.

## Scope Preservation

No claim was narrowed. The edits make the paper honest about current evidence
status while keeping the abstraction and workload families broad.

## Validation

Validation is run after this round in the main workflow.
