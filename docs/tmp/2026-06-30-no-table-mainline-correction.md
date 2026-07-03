# Evidence-target correction

## Motivation

This record corrects two misleading planning directions introduced while
selecting new workloads. The next AI-agent workload is not a static-table
argument, and workload selection is not an interface-exclusivity argument. Both
frames overstate the evaluation goal.

## Current Rule

The mainline evidence target is:

> Can a narrow eBPF VFS name-resolution hook implement useful path-view policies
> for real workloads while keeping lower-filesystem semantics owned by the
> kernel?

Each main workload therefore needs real source provenance, a workload oracle,
operations during the relevant transition, operation-weighted path signal,
natural baseline comparison, and a verdict that can narrow the claim.

## Documentation Updates

The current planning documents now follow this rule:

- `docs/reference/CODE_SOURCES.md` says source selection is not a
  table-insufficiency checklist.
- `docs/tmp/2026-06-30-reproducible-workload-source-survey.md` says
  code-backed workload selection should produce real workload evidence, not
  exclusion arguments.
- `docs/tmp/2026-06-30-formal-workload-selection.md` marks prior exact-map
  rows as archived boundary evidence and records the current evidence target.
- `docs/case_studies.md` removes table-failure language from current
  case-study status text.
- `research/STATE.md`, `research/EXPERIMENT_PLAN.md`,
  `research/CLAIM_LEDGER.md`, `research/CLAIM_VERDICT.md`,
  `research/FOLLOWUP_PLAN.md`, and `research/EXPERIMENT_TRACKER.md` now point
  future work at real agent lifecycle, service reload/rotation, and
  cache/environment transition workloads.

## What To Keep

Historical table counterfactual runs should remain in `results/` and in
historical `docs/tmp/` records as provenance. They may be cited only as
appendix or boundary evidence. They should not drive the next experiments and
should not appear as the novelty core. Likewise, no current planning document
should claim that the selected workloads can only be handled by `namei_ext`.

## Next Experiments

1. AI agent workspace lifecycle from BranchFS, Sandlock, AgentFS, Redis Agent
   Filesystem, Mirage, SWE-agent/SWE-ReX, OpenHands, Terminal-Bench, or
   SWE-MiniSandbox traces.
2. W4 live cache/environment transition from ccache, BuildKit, DockSmith,
   SWE-Factory, MEnvAgent, Multi-Docker-Eval, or SWE-rebench V2 sources.
3. W2 real service reload/update or secret/config rotation.

Each experiment needs a real workload source, Make-owned KVM execution,
operation-weighted path signal, a correctness oracle, and natural mechanism
comparisons. None should be scoped as an exclusion argument.
