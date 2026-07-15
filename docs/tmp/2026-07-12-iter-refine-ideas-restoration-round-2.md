# Iter-Refine-Ideas Restoration Round 2

Date: 2026-07-12
Skill: `iter-refine-ideas`
Round: 2, Academic Architecture And System Direction

## Objective

Check whether the restored position derives a coherent academic architecture
and system direction rather than merely placing existing `namei_ext` code under
a broader story.

## Discussant Finding

The discussant agreed that the project no longer reads as table-only novelty
or a two-workload proposal. The main gap was academic structure: Motivation
did not explicitly derive solution-independent requirements, and Design did
not show how those requirements constrain the ABI and invariants.

## Main-Agent Response

Accepted and applied:

- Added R1--R6 requirements in Motivation: state-conditioned lookup/readdir,
  lower-FS preservation, lookup/readdir coherence, bounded/verifiable policy,
  per-workload attachment/update, and observable provenance.
- Replaced Design's process-oriented G1/G4 framing with a
  requirement-to-design-to-invariant table.
- Clarified lower-object registration, lifetime, permission checks,
  dcache/namei invariants, and visible failure semantics.
- Changed abstract and RQ1/RQ2 wording to distinguish source-derived evidence
  status from reproduced KVM transitions.
- Made service/config a required characterization family and a recommended
  third KVM deep dive for full OSDI/SOSP scope.
- Added ownership-boundary metrics to RQ3.

Deferred:

- A polished architecture figure is left for `paper-figures`.
- More namespace/name-resolution related work such as mount namespaces,
  idmapped mounts, autofs, and `openat2` is left for a later literature pass.

## Preservation Check

The edits preserve the user's original target: `namei_ext` as a
`sched_ext`-style VFS extension point between materialized namespace
construction and FUSE/custom filesystem ownership. The changes make the larger
idea more defensible without shrinking it into a workload-specific proposal.

## Validation

Validation is run after the corresponding paper edits in this turn.

## Next Action

Run Round 3 on novelty, experiments, and result expectations.
