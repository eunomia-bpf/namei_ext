# Unified Experiment Infrastructure Audit

## Decision

The repository should consolidate experiment infrastructure before adding more
formal workloads, but it should not copy the sibling `bpf-benchmark` layout or
perform a directory reshuffle. `namei_ext` already has the correct major
boundaries:

```text
root Make entrypoint
  -> suite Makefile
  -> shared KVM launcher and guest preparation
  -> shared run/result lifecycle
  -> suite-owned raw collector
  -> analysis-only aggregation
```

The consolidation target is repeated lifecycle code, not the directory tree.

## Existing Shared Infrastructure

- `mk/kvm.mk` owns modified-kernel KVM execution, launcher capture, timeout,
  CPU-affinity verification, guest mounts, and dmesg failure gates.
- `mk/results.mk` owns immutable result creation, source/kernel identity,
  clean-tree enforcement, `namei_ext.run.v2`, and completion validation.
- `mk/workload.mk` owns pinned source acquisition and build provenance.
- `runner/` owns common cgroup, BPF load/attach, target registry, and bounded
  child-process helpers.
- `configs/benchmarks/` freezes experiment parameters.
- `analysis/` computes summaries from raw observations.
- `.build/`, `.cache/`, and `results/` are already distinct.
- current and historical suites are explicitly separated.

These controls are at least as disciplined as the relevant
`bpf-benchmark` paths. In particular, `namei_ext` has a stronger common result
schema, clean source/kernel gates, immutable `RUN_ID` roots, and separate input
and artifact hashes. Copying `bpf-benchmark` wholesale would import unrelated
platform, container, and Python-runner complexity.

## Concrete Defects

### 1. Suite Registration Has Multiple Sources of Truth

The root `Makefile` separately maintains current targets, clean-source targets,
includes, phony declarations, help text, component build targets, and cleanup.
A new suite can be present in one list but absent from another. This is a
maintenance and correctness risk because `make experiments`, clean-tree gates,
help, and cleanup can disagree.

### 2. Multi-Boot Lifecycle Code Is Repeated

`agent_workspace_rq2.mk`, `fxmark.mk`, `fxmark_fast_path.mk`, and
`service_config_rotation.mk` each implement variants of artifact capture,
guest Makefile generation, expected/observed matrix comparison, boot metadata,
hash validation, and finalization. The suite files range from roughly 300 to
620 lines. Fixes such as timeout handling or kernel identity can therefore land
in one suite and not another.

### 3. Positional KVM Macro Arguments Are Fragile

`NAMEI_EXT_KVM_RUN_CAPTURE` has seven positional arguments, including optional
CPU pinning and timeout fields. Empty argument positions are hard to review and
have no schema-level validation. Suite authors can accidentally shift a value
while producing syntactically valid Make.

### 4. Current Aggregate Mixes Evidence Levels

`CURRENT_EXPERIMENT_TARGETS` combines a formal Agent workspace matrix with
dependency preflights for other case studies. `make experiments` therefore
means "all currently implemented gates," not "all formal experiments." That is
documented, but the target name can still be misread when collecting paper
evidence.

### 5. Phase-1 And Formal Result Paths Are Not Fully Unified

Formal suites use `namei_ext.run.v2`; older Phase-1 smoke, policy, functional,
and microbenchmark paths retain bespoke metadata and result layouts. They
should not be rewritten during the immediate consolidation, but the split must
remain explicit so Phase-1 diagnostics are not mistaken for formal evidence.

## Minimal Consolidation Plan

### Stage A: One Suite Registry

Add one Make-owned registry that classifies targets as:

```text
dependency preflight
formal case study
formal performance benchmark
historical reproduction
```

Derive aggregate targets and clean-source gates from that registry. Keep suite
Makefiles and public target names unchanged.

### Stage B: Shared Multi-Boot Contract

Extract only the repeated mechanics:

- boot-directory and guest-Makefile creation;
- launcher invocation and boot timestamps;
- exact expected/observed boot-key comparison;
- common per-boot artifact requirements;
- input/artifact hash verification; and
- failure/completion state transitions.

Suite files must continue to own workload commands, correctness oracles,
mechanism-engagement gates, matrices, and analysis.

### Stage C: Migrate One Stable Suite

Migrate the completed Agent workspace RQ2 suite first. Require byte-equivalent
matrix keys, preserved raw files, passing analyzer tests, and one existing
formal result bundle that still validates. Only then migrate FxMark and future
case studies.

### Stage D: Clarify Public Aggregates

Expose separate aggregates for dependency preflights and formal experiments.
Keep `make experiments` only as a documented umbrella if needed for developer
convenience; paper result collection must invoke explicit formal targets.

## Non-Goals

- no directory moves;
- no new project-owned shell scripts;
- no replacement of Make with a Python orchestrator;
- no result-schema rewrite;
- no deletion or rewriting of historical results;
- no merging of workload-specific correctness logic into shared code; and
- no infrastructure refactor mixed with a new scientific claim.

## Current Status

Stage A is implemented by `mk/suites.mk`. The existing `make experiments`
dependency set is unchanged, while separate formal case-study and performance
aggregates are now derived from the same registry. Implemented formal targets
whose dependency gate is closed remain clean-source-gated but are excluded
from aggregate evidence collection. Make parsing and the shared result-contract
tests pass.

The next infrastructure change is the smallest Stage B interface. It must be
validated against the stable Agent workspace suite before resuming Service
Configuration Rotation or adding another case study.

## Follow-Up Status

Stages B and C are complete:

- `mk/multi_boot.mk` owns direct boot-tree initialization, deterministic raw
  observation collection, guest-Makefile sealing, and required per-boot file
  validation.
- The stable Agent workspace RQ2 suite was migrated first. Its preserved
  20-boot formal raw result regenerated byte-identical summaries, and a fresh
  paired modified-kernel KVM preflight passed.
- Service Configuration Rotation V2 is the second migrated case study. Its
  suite keeps nginx-specific lifecycle and correctness logic while reusing the
  same multi-boot mechanics.
- Required boot evidence must now be a direct regular non-symlink file; shared
  negative tests reject missing, directory, symlink, nested, and moved
  evidence.

The repository now has the intended common foundation without a directory
reshuffle or a second orchestrator. Positional KVM invocation and migration of
the two FxMark suites remain bounded follow-up infrastructure work. They should
be done when those suites are next changed, not used to delay the current
highest-value service experiment.
