# Story Drift Audit

Date: 2026-07-13

## Question

Compare the current story with the previous shrunken story and check whether
the project has drifted again.

## Previous Shrunken Story

The archived July 10 route reduced the project to:

- table/exact-map insufficiency as the novelty gate;
- two selected upstream transitions as the main scientific scope;
- "both transitions must pass" as the boundary-validity condition;
- defensive proposal-style language where characterization and complete
  experiments were future work.

That version was safer but too small. It risked turning `namei_ext` into a
collection of feasibility checks rather than a systems abstraction.

## Current Story

The current canonical story is:

- `namei_ext` is a `sched_ext`-style VFS extension point;
- it sits in the sequence
  bind/Overlay/materialization < eBPF LSM < `namei_ext` < FUSE/custom FS;
- the programmable part is bounded VFS name-resolution policy, while the
  kernel and lower filesystem keep VFS object, data-path, write, permission,
  page-cache, persistence, and consistency ownership;
- the paper-facing RQs are expressiveness/sufficiency, cost versus
  feature-equivalent FUSE, and safety/boundary versus custom or stackable
  filesystems;
- source-system characterization motivates workload selection, but
  claim-moving evidence must come from Make-owned, KVM-validated, same-oracle
  complete experiments;
- the first two admitted experiments are AgentFS-derived workspace lifecycle
  and environment/cache transition. Service/config remains conditional.

## Drift Verdict

No major story drift is visible in the canonical docs. The current story is
larger and more interesting than the archived shrunken route, and it matches
the durable user instructions in `docs/user-instruction.md`.

The current docs avoid the earlier failure modes:

- table-only and `table_redirect` are not the central novelty proof;
- materialized namespace mechanisms are related-work/background, not the RQ3
  center;
- RQ2 explicitly compares against feature-equivalent FUSE;
- RQ3 is a custom/stackable filesystem boundary and containment claim;
- `make phase1` is prototype validation, not the paper experiment route;
- complete experiments are defined as integrated matrices with source oracle,
  `namei_ext`, FUSE comparison, controls, boundary evidence, raw results, and
  result review.

## Remaining Drift Risks

1. **Preflight-to-paper-result drift.**
   The Agent workspace preflight being implemented is useful dependency work,
   but it is not the full AgentFS-derived Experiment A. If it is reported as a
   paper result before the FUSE cell, operation-weighted traces, lower-FS audit,
   and result review exist, the story will shrink again.

2. **Prototype-subset drift.**
   Current `HIDE` and intermediate `SELECT_TARGET` evidence is real KVM
   prototype evidence. It must not redefine the workload to only what those
   actions already support. Missing directory aliasing, final-object semantics,
   and full workspace lifecycle support remain implementation gates.

3. **Legacy-target discoverability drift.**
   Old W1-W4/table targets still exist for provenance. They are no longer in
   default `phase1`, but their visibility can confuse future agents unless
   docs and help keep marking them as legacy diagnostics.

4. **Negative-result narrative drift.**
   Failed or incomplete preflights should repair the experiment or identify a
   boundary. They should not automatically weaken the hypothesis or turn the
   paper into a negative-results story.

## Guardrail

Future work should compare every proposed edit against:

- `docs/user-instruction.md`;
- `docs/idea-story.md`;
- `docs/evaluation.md`;
- `docs/tmp/2026-07-13-agent-workspace-complete-experiment-plan.md`;
- `docs/tmp/2026-07-13-environment-cache-complete-experiment-plan.md`.

If a change makes `namei_ext` look like a table experiment, a two-transition
proposal, a smoke-test artifact, or a materialization-baseline shootout, it is
drifting away from the current story.
