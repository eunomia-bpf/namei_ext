# Unified Experiment Infrastructure Implementation

Date: 2026-07-26

## Motivation

The repository had working mechanism tests and several case-study prototypes,
but it did not have one experiment infrastructure. Industrial case studies
lived under `tests/`, privileged runner plumbing was copied between cases, one
815-line KVM Makefile owned unrelated suites, old workload numbers conflicted
with the current W1--W7 taxonomy, and result roots used similar but different
provenance contracts. Adding W4--W7 directly would have multiplied these
problems.

The implementation follows the useful ownership boundaries in the local
`bpf-benchmark` repository while retaining the stricter `namei_ext` rules:
Make remains the control plane, raw observations remain separate from analysis,
and Phase 1 evidence must exercise the real `cgroup/namei_ext` path in the
modified-kernel KVM.

## Inspected Paths

The audit covered:

- the top-level `Makefile`, `mk/kvm.mk`, `mk/workload.mk`, and KVM
  configuration;
- case-study, ABI, functional, load, and semantic code under `tests/`;
- custom VFS workloads under `bench/`;
- policy implementations under `bpf/policies/`;
- the historical 24,286-line multi-workload oracle;
- source evidence under the former `workload/` directory;
- recent W1, W3, Agent workspace, build-cache, and Phase 1 result roots; and
- the local `bpf-benchmark` runner, suite, artifact, and report boundaries.

The research audit and rejected alternatives are recorded in
`2026-07-26-unified-experiment-infrastructure-audit.md`.

## Implemented Structure

Formal industrial cases moved to:

```text
experiments/agent_workspace/
experiments/application_file_sharing/
experiments/build_action_sandboxing/
```

`tests/` now owns ABI, functional, policy-load, and policy-semantic regressions.
The old multi-workload runner moved to `experiments/legacy_oracle/`, with its
compatibility `make w1-oracle` target retained. Old source-evidence directories
moved to `workloads/legacy/`; their superseded identifiers are no longer
presented as the current formal W1--W7 taxonomy.

Per-case KVM ownership moved to:

```text
mk/experiments/agent_workspace.mk
mk/experiments/application_file_sharing.mk
mk/experiments/build_action_sandboxing.mk
```

The public Make targets and existing raw result roots were preserved.
`mk/kvm.mk` now owns common KVM execution, guest mounts, mechanism suites, and
only the core functional and performance entrypoints. The 535-line historical
ccache body moved without semantic changes to
`mk/experiments/legacy_build_cache.mk`; after adding ownership declarations,
the isolated file is 570 lines and common `mk/kvm.mk` is 168 lines.

## Shared C Harness

The new `runner/libnamei_ext_harness.a` provides only reusable mechanism
lifecycle:

- path, text-file, copy, and cleanup helpers;
- process waiting and cgroup movement/identity;
- target registration and registry clearing;
- BPF object load, `cgroup/namei_ext` attach, and cleanup;
- exact component-map updates and deletes; and
- policy counter reads.

It does not implement workload state machines, Bazel or portal semantics,
correctness oracles, fallback behavior, or paper analysis.

Sandboxed Application File Sharing shrank from 735 to 397 runner lines and
Build Action Sandboxing from 949 to 550 lines. The shared implementation is 467
lines plus a 48-line public header. These counts describe code organization,
not kernel patch size.

## Raw Artifact Contract

Canonical case-study KVM result roots now require:

```text
run.json
observations.jsonl
command.txt
inputs.sha256
artifacts.sha256
stdout.log
stderr.log
kernel.config
uname.txt
proc-version.txt
kernel-cmdline.txt
dmesg.log
```

Suites may add output hashes, workload versions, traces, or responses. Source
inputs and built artifacts have separate hash manifests. `run.json` uses
schema `namei_ext.run.v1` and records run ID, suite, source system, result
level, status, timestamps, policy, runner, observations file, and kernel
commit.

The kernel commit is captured on the host by `make kernel-provenance` into
`.build/kernel-commit.txt`. The guest validates a nonempty 40-character
lowercase hexadecimal value before creating `run.json`. All public KVM
entrypoints depend on this host step.

## Provenance Failure And Fix

The first infrastructure W1 run,
`results/experiments/application-file-sharing/20260726T-infra-application-file-sharing-v1/`,
passed its workload oracle but is not canonical. The guest attempted
`git -C kernel rev-parse HEAD`; Git rejected the root-owned guest process
because the shared worktree has a different owner. Shell command substitution
left `kernel_commit` empty without failing the Make target.

The raw result is retained as failure evidence. The Git call was removed from
the guest, the host provenance target and guest validation were added, and the
suite was rerun. No global `safe.directory` exception or warning-and-continue
path was introduced.

## Validation

All validation used kernel commit
`6641100ef13462121bf8d8bea9392d77532c86d5`.

### Sandboxed Application File Sharing

Command:

```text
make kvm-application-file-sharing-preflight \
  RUN_ID=20260726T-infra-application-file-sharing-v2
```

Result:

- 21 JSONL records;
- zero `pass == false` records;
- two-application grant, revoke, isolation, lookup, readdir, and lower-object
  preservation oracle passed;
- source and artifact hash manifests revalidated;
- `run.json` completed with the expected kernel commit; and
- no configured dmesg failure pattern was present.

### Build Action Sandboxing

Command:

```text
make kvm-build-action-sandboxing-preflight \
  RUN_ID=20260726T-infra-build-action-v1
```

Result:

- 23 JSONL records and zero failures;
- two concurrent Bazel 6.5.0 actions completed with expected 17-byte outputs;
- policy counters recorded 57,164 lookup events, 8,042 readdir events, four
  SELECT actions, two lookup HIDE actions, and two readdir HIDE actions;
- source, artifact, and output hashes revalidated; and
- dmesg passed the failure-pattern gate.

### Agent Workspace Matrix

The first post-move matrix run passed but still used the old artifact names.
After converting the matrix to the common contract, the canonical command was:

```text
make kvm-agent-workspace-matrix \
  RUN_ID=20260726T-infra-agent-workspace-v2
```

Result:

- 1,176 raw records and zero failures;
- 94 functional case rows;
- 16 metric rows;
- three mechanism-boundary rows; and
- both the namei_ext and feature-equivalent FUSE matrix summaries passed.

The source system is explicitly recorded as `agentfs-derived`; the result does
not claim to reproduce the AgentFS implementation.

### Phase 1 Regression

Command:

```text
make phase1 RUN_ID=20260726T-infra-phase1-v2
```

Result:

- three ABI records, zero failures;
- ten policy-load records, zero failures;
- 51 functional records, zero failures;
- touched kernel objects built successfully;
- KVM smoke, policy load/attach, and functional execution passed; and
- smoke, load, and functional dmesg logs contained none of the configured
  failure patterns.

## Remaining Work

This change establishes the experiment substrate; it does not complete the
paper evaluation. The Agent runner still contains older local mechanism
helpers and can migrate to the shared harness when its workload code is next
changed. The isolated legacy ccache matrix still depends on the legacy oracle;
it must not define the shape of W4--W7.

The next work is:

1. add source-pinned RQ2 FxMark/VFS suites with stock, patched-unattached,
   attached PASS, SELECT, and optimized FUSE conditions;
2. implement Service Configuration and Secret Rotation from the nginx
   AtomicWriter-style lifecycle;
3. implement DMTCP checkpoint/restart path remapping;
4. implement Spindle/Pynamic HPC file staging; and
5. implement Spack/HDF5 per-job toolchain environments.

Each addition must use a focused `experiments/` runner, a per-suite Makefile,
the common raw artifact contract, real KVM attachment, and correctness-first
gates.
