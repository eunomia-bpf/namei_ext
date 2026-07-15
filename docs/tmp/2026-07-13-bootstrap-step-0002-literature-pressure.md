# BOOTSTRAP Step 0002 Literature Pressure

Timestamp: 2026-07-13T00:56:32-07:00
Phase: BOOTSTRAP
Step: `docs/tmp/bootstrap/step-0002-20260713T004618-0700/`
Detailed node:
`docs/tmp/bootstrap/step-0002-20260713T004618-0700/01-experiment-gate/literature-20260713T005632-0700/001-claim-novelty-workload-baseline-pressure-20260713T005632-0700.md`

## Motivation

The project re-entered BOOTSTRAP after the user instructed the workflow to
return to the new skill hierarchy before continuing experiments. The immediate
risk was that the story could drift back into table-only diagnostics, a long
list of weak baselines, or a shrunken prototype-driven claim.

This record captures the literature and novelty pressure applied to the active
candidate story.

## Candidate Under Review

`namei_ext` is a `sched_ext`-style VFS name-resolution extension point. A
bounded eBPF policy decides lookup and directory-enumeration actions. The
kernel and lower filesystem continue to own VFS objects, permissions, file
methods, data path, page cache, persistence, and ordinary consistency.

The intended RQs are:

- RQ1: expressiveness/sufficiency for real state-dependent path-view policies;
- RQ2: cost/overhead compared with feature-equivalent FUSE;
- RQ3: safety/boundary compared with custom or stackable filesystem ownership.

## Evidence Checked

Local documents checked included `docs/user-instruction.md`,
`docs/idea-story.md`, `docs/design.md`, `docs/evaluation.md`,
`docs/implementation.md`, `docs/background-related-work.md`, and the local PDF
and source catalogs under `docs/reference/`.

External checks included primary or near-primary sources for Linux `sched_ext`,
BPF LSM, FUSE, FUSE passthrough, ExtFUSE, FUSE-BPF, AgentFS, BranchFS, YoloFS,
Mirage, Redis Agent Filesystem, SWE-Factory, MEnvAgent/MEnvData-SWE,
SWE-rebench V2, and Multi-Docker-Eval.

## Findings

No checked source already claims the same narrow boundary: verified BPF policy
at VFS name resolution for bounded pathname-to-object selection while lower
filesystems retain object and data semantics. Nearby work is close and must be
handled explicitly:

- `sched_ext` supports the extension-point analogy, but in the scheduler.
- BPF LSM and fanotify are mediation/security mechanisms, not object-selection
  mechanisms.
- FUSE, FUSE passthrough, ExtFUSE, and FUSE-BPF are the closest cost/mechanism
  pressure, but they remain FUSE or stacked-filesystem boundaries.
- Bento, Wrapfs, DeltaFS, IndexFS, and TableFS are boundary and non-goal
  context, not the main workload.
- AgentFS, BranchFS, YoloFS, Mirage, Redis AFS, and related agent systems are
  strong source/workload assets, not proof that only `namei_ext` can work.
- SWE-Factory, MEnvAgent/MEnvData-SWE, SWE-rebench V2, and Multi-Docker-Eval
  provide environment/cache oracles if the experiment uses real source rows.

## Decision

The candidate story is strong enough to continue BOOTSTRAP pressure. It is not
yet frozen. The next gate must verify the updated canonical docs and decide
whether to proceed to WRITE_GATE.

The evaluation should be organized around two complete experiments:

1. Agent workspace lifecycle.
2. Environment/cache transition.

Service/config remains conditional. Table-only diagnostics, bind/Overlay/copy
shootouts, and materialized-view comparisons should not be mainline baselines
unless a source oracle makes one directly load-bearing.

## Remaining Risks

- The final paper must not overclaim that workloads require eBPF or require
  `namei_ext` uniquely.
- The FUSE baseline must be feature-equivalent and fair, including relevant
  caching/passthrough considerations.
- RQ3 must be concrete boundary accounting, not a prose-only related-work
  assertion.
- The strongest workload oracles must be admitted before BUILD_AND_EVALUATE
  resumes.
