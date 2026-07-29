# Build Action Sandboxing RQ1 Formal Implementation

## Motivation

The only prior KVM result for W3 predates the current declared-input allowlist.
It therefore does not exercise the policy's allow-lookup or allow-readdir
branches. The formal RQ1 experiment needs to run the current policy with real
Bazel actions and preserve enough raw evidence to distinguish path selection,
input visibility, lower-filesystem preservation, and cleanup.

## Files Changed

- `experiments/build_action_sandboxing/namei_ext_build_action_sandboxing.c`
- `mk/experiments/build_action_sandboxing.mk`
- `configs/benchmarks/build_action_sandboxing.mk`
- `mk/workload.mk`
- `mk/suites.mk`
- `Makefile`

## Controller Changes

The controller still runs two unmodified Bazel 6.5.0 native genrules
concurrently. Each action runs in a different cgroup, uses the same logical
`view/action/input.txt` pathname, and receives a different registered lower
root.

The controller now records:

- one action-view event per cgroup, including the device and inode observed
  through the logical input pathname and through the selected lower pathname;
- `ENOENT` for direct lookup of the physically existing but undeclared
  `private.txt`;
- one lower-object event for each declared and undeclared file, with
  before/after device, inode, mode, size, and a direct expected-byte result;
- copies of both Bazel outputs and all four lower files for independent direct
  comparisons by the host finalizer;
- positive lookup, readdir, select, allow-lookup, allow-readdir, hide-lookup,
  and hide-readdir policy counters.

The genrules continue to test undeclared-input lookup and directory
enumeration themselves before reading the declared input.

## Experiment Lifecycle

The old one-boot target was replaced with a shared lifecycle:

- `make kvm-build-action-sandboxing-preflight RUN_ID=<id>` runs one fresh
  modified-kernel KVM boot;
- `make experiment-build-action-sandboxing-rq1 RUN_ID=<id>` runs three fresh
  boots and produces one aggregate analysis.

Each boot captures kernel identity, Bazel version, controller and Bazel logs,
raw JSONL observations, dmesg, and external BPF/FUSE inventory before and after
the workload. The host finalizer requires exactly one summary, two action-view
events, four lower-object events, every declared lifecycle case, and every
policy counter per boot. It independently compares the six saved files with
the fixed expected bytes.

The suite records the official Bazel release URL and verifies the executable's
reported version. It does not add an artifact-integrity gate unrelated to the
RQ1 oracle.

## Design Choices

- W3 remains a supporting RQ1 case study. It is not described as a complete
  process, syscall, network, or writable-output Bazel sandbox.
- No FUSE or sandboxfs baseline is run here. The separately planned RQ2
  experiment owns the matched mechanism comparison.
- Three boots are used to repeat deterministic correctness behavior. No
  performance distribution is inferred from these runs.
- External FUSE inventory is a contamination check, not an experimental
  baseline.

## Alternatives Rejected

- Reusing the historical result was rejected because it cannot engage policy
  branches added after that run.
- Keeping only the Bazel output oracle was rejected because it cannot prove
  that the logical pathname selected the registered lower inode or that hidden
  lower objects remained unchanged.
- Adding a table, symlink forest, or materialized-view row was rejected because
  it would not answer the selected RQ1 sufficiency question.
- Describing the result as complete Bazel sandboxing was rejected because
  `namei_ext` controls only the tested existing-object pathname view.

## Validation Performed

- `make build-action-sandboxing bpf workload-bazel`
  - rebuilt the controller with `-Wall -Wextra`;
  - confirmed the BPF object builds;
  - confirmed the cached official Bazel executable reports version 6.5.0.
- `make -pn help`
  - confirmed the preflight and three-boot formal entrypoints exist.
- `git diff --check`
  - reported no whitespace errors.

## Remaining Validation

The implementation still requires:

1. one real clean-source modified-kernel KVM preflight;
2. three unchanged fresh KVM boots;
3. an independent review of the complete raw result.

Until those steps pass, this implementation is not current W3 evidence.

## Preflight Attempt 1

Raw result:
`results/experiments/build-action-sandboxing-rq1-preflight/20260729T175002Z-w3-preflight01/`.

The first real boot reached the current policy and passed both action-view
device/inode checks, hidden-child lookup, all four lower-object preservation
checks, detach, target clearing, external inventory, and dmesg. The Bazel
children did not reach the barrier. Their executable path was relative to the
repository when the controller spawned them, but each child changed to its
temporary workspace before `exec`.

This is a runner path-resolution defect, not a policy or oracle result. The
guest invocation now passes absolute controller, policy, observation, Bazel,
and result paths. The frozen workload and correctness checks are unchanged.

## Preflight Attempt 2

Raw result:
`results/experiments/build-action-sandboxing-rq1-preflight/20260729T175205Z-w3-preflight02/`.

The unchanged one-boot workload passed end to end. Both Bazel actions reached
the common barrier, completed, and produced their distinct expected bytes.
Both action-view records matched the selected lower device/inode, the hidden
child returned `ENOENT`, all four lower-object records passed, all seven policy
counters were positive, teardown left no external BPF/FUSE state, and dmesg
passed the declared failure scan.

## Formal Run

Raw result:
`results/experiments/build-action-sandboxing-rq1/20260729T175251Z-w3-formal01/`.

The formal command completed three fresh boots from clean source commit
`eee4d5d95d844d5a1045f5f9773301fbb94a89fa` and clean kernel commit
`621aff8d1bb52fad718f11fd882c956d6a5686ae`. The generated summary records:

- 3 passing boots;
- 6 passing Bazel actions;
- 6 matching action-specific logical/lower views;
- 12 preserved lower objects.

Per-boot policy counters were:

- lookup: 57,383; 57,485; 57,613;
- readdir: 8,048; 8,042; 8,048;
- select: 8 in every boot;
- allow lookup/readdir: 6/2 in every boot;
- hide lookup/readdir: 4/6 in every boot.

The raw result now requires an independent result review before W3 is promoted
to current paper evidence.

## Formal 01 Result Review

The independent review classified formal 01 as invalid with one evidence
blocker. Both cgroup removals affected the controller's final failure count but
did not have individual raw case records. The remaining workload, path-view,
lower-object, policy-engagement, teardown, inventory, and kernel-health
observations were complete and passing.

The controller now emits `remove_action_a_cgroup` and
`remove_action_b_cgroup`, and the host finalizer requires each event exactly
once per boot. The analyzer reports observed counts without a hard-coded
scientific verdict. This is an instrumentation repair; the workload, oracle,
policy, and three-boot matrix are unchanged.
