# User Instruction And Complete Experiment Audit

Date: 2026-07-13

## Motivation

The active goal is to analyze the repo's prior user instructions and dialogue,
record durable instructions in `docs/user-instruction.md`, and check whether the
system and experiment design are organized well enough for an OSDI/SOSP-style
paper. The latest instruction is explicit: experiments must not be scattered
small checks or a shifting baseline list; they must be complete experiments.

## Instructions Added

`docs/user-instruction.md` now records two additional durable constraints:

- Main experiments must be integrated, same-oracle, Make-owned, KVM-validated
  matrices with `namei_ext`, feature-equivalent FUSE comparison,
  custom/stackable-FS boundary evidence, controls/ablations, repetitions or
  uncertainty, raw results, and result review.
- Weak/redundant/proxy-only baselines, smoke tests, source reproduction, and
  dependency setup are not paper results. Prior work that already establishes a
  background fact should be cited rather than rerun.
- `table_redirect`, table-only insufficiency, and "prove this workload cannot be
  a static table" are not the main novelty or experiment target.
- Source-system characterization selects workloads and oracles; it is not
  claim-moving evidence by itself.

## Current Design Status

System design is now organized around a clear mechanism sequence:

```text
bind/Overlay/materialization < eBPF LSM < namei_ext < FUSE/custom FS
```

`docs/design.md` now connects mechanism choices to proof obligations:

- `namei_ext` must remain a VFS name-resolution extension point, not a
  filesystem.
- eBPF policy must be expressive enough for path views.
- eBPF LSM must be positioned as neighboring security/access mediation, not as
  the same abstraction.
- FUSE must be measured as the central programmable-policy cost comparison.
- custom/stackable filesystems must be compared as broader ownership boundaries.
- paper results must be complete experiments, not proxy checks.

This is a plausible OSDI/SOSP system-design shape, but final acceptance-quality
evidence still requires KVM workload implementation and results.

## Current Experiment Status

Before this audit, `docs/evaluation.md` had the right RQs but still read like a
workload matrix. It now defines paper-value admission and complete experiments:

1. Headline complete experiment: AgentFS-derived workspace lifecycle.
2. Decisive complete experiment: environment/cache transition from
   SWE-Factory-Gym, MEnvData-SWE, or SWE-rebench V2.
3. Conditional supporting experiment: service/config transition only after a
   real source oracle is selected.

The detailed plan for the headline experiment is
`docs/tmp/2026-07-13-agent-workspace-complete-experiment-plan.md`. The detailed
plan for the decisive environment/cache experiment is
`docs/tmp/2026-07-13-environment-cache-complete-experiment-plan.md`.

Each admitted experiment must include:

- source-derived correctness oracle;
- real `cgroup/namei_ext` KVM attach path;
- feature-equivalent FUSE comparison when used for RQ2;
- custom/stackable-FS boundary evidence for RQ3;
- lower-FS semantic checks;
- controls/ablations labeled separately from baselines;
- raw artifacts under `results/`;
- a result-review report before paper interpretation.

The plan now rejects standalone smoke tests, partial reproductions, weak
comparisons, and constantly changing baselines as paper experiments.

## OSDI/SOSP Readiness Judgment

Current status: organized but not experimentally complete.

The story, RQs, system boundary, and experiment admission rules are now much
closer to a strong OSDI/SOSP systems paper. The missing work is implementation
and execution:

- implement the headline AgentFS-derived complete experiment;
- implement the feature-equivalent FUSE policy comparison;
- collect operation-weighted lookup/readdir traces and lower-FS semantic checks;
- produce raw results and a result-review report;
- then repeat the same discipline for the environment/cache complete experiment.

The paper should not claim final expressiveness, overhead, or boundary results
until those complete experiments run through KVM and pass result review.
