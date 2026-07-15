# Round 5: Consistency, Terminology, And Information Flow

## Skill Route

- `iter-refine-writing`, round 5.
- Reviewer scope: `check-terminology-infoflow`, `paper-consistency`.
- Files reviewed: `docs/paper/main.tex`, `docs/paper/sections/*.tex`,
  `docs/paper/refs.bib`, and the paper build output.

## Findings

The consistency review found no build-level citation or reference failures. It
did find three paper-consistency issues that would weaken the BOOTSTRAP story:

1. The paper described generic registered-target selection, while the current
   prototype implements registered directory-target selection and treats
   final-file target selection as future support.
2. The RQ3 evidence basis mixed source-system responsibilities with
   custom/stackable filesystem boundary ownership.
3. The environment/cache workload wording implied that `namei_ext` regenerates
   objects, which would violate the lower-object boundary.

The review also flagged three wording issues:

1. RQ2 treated inability to build a feature-equivalent FUSE row as overhead
   evidence instead of a methodology gap.
2. The introduction implied that custom/stackable comparisons operationally use
   the same lower objects, even though RQ3 is a boundary/accounting comparison
   unless a same-oracle row is admitted.
3. Service/config appeared in the abstract and introduction without a matching
   primary evaluation matrix.

## Fixes Applied

- Updated the abstract to say the prototype supports `registered
  directory-target selection`, and to state that service/config remains
  motivating scope unless a concrete lookup-time oracle is admitted.
- Updated the introduction so lower-object equality applies to executed FUSE
  rows and to the objects referenced by the custom/stackable boundary account.
- Clarified that service/config is not one of the two primary matrices unless
  a concrete source-system correctness condition admits it.
- Rewrote the environment/cache workload to choose existing verified local or
  canonical objects, and to select regenerated objects only after the source
  evaluator has materialized them.
- Reworded the design action set around the current prototype's registered
  directory-target selection.
- Rewrote the RQ2 closure so missing feature-equivalent FUSE is a methodology
  gap, not an overhead result.
- Rewrote the RQ3 bridge and table headers so source systems define required
  responsibilities, while the custom/stackable account asks which of those
  responsibilities would move into the filesystem boundary.
- Marked AgentFS, BranchFS, YoloFS, and custom/stackable filesystems as boundary
  exemplars unless a same-oracle executed row is explicitly admitted.

## Validation

- Ran `make -C docs/paper paper`.
- Result: build succeeded and produced `.build/paper/main.pdf`.
- Known warnings: fontspec CJK warnings and underfull hbox warnings.
- Page count after this round: 16 pages.

## Carry Forward

- Later language rounds should tighten the paper back toward the target length
  without changing the BOOTSTRAP claim structure.
- Final submission-form conclusion must replace explicit result slots with
  filled evidence once reviewed KVM runs exist.
