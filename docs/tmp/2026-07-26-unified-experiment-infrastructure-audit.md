# Unified Experiment Infrastructure Audit

Date: 2026-07-26

## Purpose

This audit decides whether to continue adding W4--W7 experiments directly or
first consolidate the repository into one experiment infrastructure. The
reference is the local `bpf-benchmark` repository's separation among build
inputs, runner contracts, suites, raw artifacts, and analysis. `namei_ext`
keeps its stricter Make-only orchestration rule and does not copy
`bpf-benchmark`'s Python control plane.

## Current Strengths

The repository already has several correct foundations:

- the top-level Makefile is the public entrypoint;
- the modified kernel is a pinned submodule;
- KVM is the Phase 1 validation boundary;
- BPF policies are C programs under `bpf/policies/`;
- downloaded inputs, build outputs, and raw results use `.cache/`, `.build/`,
  and `results/`;
- recent W1 and W3 experiments preserve commands, hashes, kernel identity,
  logs, JSONL records, and dmesg;
- failures are terminal rather than silently downgraded.

These properties should survive the reorganization.

## Structural Problems

### Tests, benchmarks, and case studies are mixed

`tests/` contains ABI and mechanism tests, but also the Agent workspace,
Sandboxed Application File Sharing, and Build Action Sandboxing case studies.
Their lifecycle, source provenance, raw artifacts, and baselines are different
from unit or functional tests.

The intended ownership is:

```text
tests/         kernel/BPF ABI, load, semantic, and regression tests
experiments/   source-derived industrial case studies
bench/         standard and custom performance suites
```

### Runner plumbing is copied into every case

The W1 and W3 runners independently implement path construction, text-file
I/O, child waiting, cgroup movement and identity lookup, target registration,
BPF load/attach/detach, component-key construction, map updates, and counter
reads. The same functions also appear in the Agent runner, functional tests,
policy tests, and custom benchmarks.

The two most recent case runners are 735 and 949 lines even though their
workload-specific state machines are much smaller. Adding W4--W7 in this form
would create four more copies of privileged lifecycle code and make fixes
diverge.

### One Makefile owns unrelated KVM suites

`mk/kvm.mk` is 815 lines and contains Phase 1 smoke/load/semantic tests, three
case studies, the build-cache matrix, historical ccache targets, functional
tests, and microbenchmarks. Variables and target names from unrelated suites
share one namespace. The old `kvm-w4-*` ccache names now conflict with the
formal W4 Service Configuration and Secret Rotation name.

### Historical workload IDs conflict with the formal case taxonomy

Tracked directories such as `workloads/legacy/w1-redis-build`,
`workloads/legacy/w2-nginx-fixture`, and `workloads/legacy/w4-ccache-redis-nginx` use an older
numbering scheme. The current paper uses W1--W7 for industrial workflows. The
same identifier therefore refers to different concepts depending on the file.

`workload/README.md` also lists targets and paths that no longer exist, such as
`configs/eval-osdi/workload-sources.mk`.

### The legacy oracle is a second control plane

`experiments/legacy_oracle/namei_ext_w1_oracle.c` is 24,286 lines and contains several
historical workloads, baselines, collectors, and policy helpers. It remains
wired into current ccache targets. It is not a reusable suite interface and
must not become the implementation pattern for W4--W7.

### Result contracts are similar but not uniform

Recent case studies usually preserve:

```text
command
input hashes
artifact hashes
JSONL observations
stdout/stderr
kernel config and identity
dmesg
```

However names, required files, summary records, and validation gates differ
per target. Some earlier targets lack an explicit provenance record or use
collector-generated interpretation. A paper-scale matrix needs one minimum
raw artifact contract before per-suite additions.

## Reference Lessons From bpf-benchmark

Useful patterns to retain:

- one reusable runner library rather than suite-local privileged plumbing;
- explicit suite identity and target/executor contracts;
- source/build/run artifacts separated by root;
- raw detail files written before derived summaries;
- suite-specific code owns workload semantics, while shared code owns runtime
  lifecycle;
- public Make targets remain stable while internal implementation moves.

Patterns not to copy:

- Python as the project-owned orchestration layer;
- broad target matrices unrelated to this prototype;
- generated build trees inside source directories;
- a large top-level Makefile that merely moves the monolith.

## Target Layout

```text
Makefile
mk/
  build.mk
  kernel.mk
  runtime.mk
  workloads.mk
  tests.mk
  experiments/
    agent_workspace.mk
    application_file_sharing.mk
    build_action_sandboxing.mk
    service_configuration.mk
    checkpoint_restore.mk
    hpc_file_staging.mk
    toolchain_environments.mk
  benchmarks/
    vfs.mk
    fxmark.mk
runner/
  include/namei_ext_harness.h
  src/namei_ext_harness.c
  Makefile
experiments/
  agent_workspace/
  application_file_sharing/
  build_action_sandboxing/
  ...
tests/
  abi/
  functional/
  policy_load/
  policy_semantic/
bench/
  fxmark/
  vfs/
workloads/
  sources/
  fixtures/
  legacy/
analysis/
results/
```

Policies remain under `bpf/policies/`; moving them into suite directories
would blur the kernel-facing policy ABI.

## Shared C Harness Boundary

The harness should own only mechanism lifecycle:

- safe path and text-file helpers;
- cgroup creation/movement/identity primitives;
- target registration and clearing;
- BPF object load, attach, detach, map lookup, and exact component updates;
- child process and cleanup helpers;
- common raw result primitives where the schema is identical.

It must not own:

- workload state machines or oracles;
- Bazel, nginx, DMTCP, Spindle, or Spack semantics;
- paper ratios or interpretation;
- fallback behavior;
- policy logic.

This boundary lets W4--W7 share the privileged path without becoming one giant
runner.

## Minimum Raw Artifact Contract

Every canonical KVM experiment result root must contain:

```text
run.json
observations.jsonl
command.txt
inputs.sha256
artifacts.sha256
stdout*.log
stderr*.log
kernel.config
uname.txt
proc-version.txt
kernel-cmdline.txt
dmesg.log
```

`run.json` records schema version, run ID, suite, source system, kernel commit,
policy, runner, workload versions, status, start/end time, and the relative
paths of all required artifacts. A suite may add checkpoint images, output
hashes, HTTP responses, lockfiles, or traces. Missing required files or a false
oracle fails the Make target.

Collectors write observations and status. Ratios, confidence intervals,
tables, and paper prose remain analysis outputs.

## Migration Order

1. Add the shared C harness and refactor the already passing W1 and W3 runners.
2. Move the three formal case studies from `tests/` to `experiments/` without
   changing public Make targets or result paths.
3. Split case-study targets out of `mk/kvm.mk`; keep a small common KVM runner
   and guest preparation target.
4. Add and validate the minimum artifact contract on W1 and W3.
5. Move the Agent workspace case and its FUSE baseline onto the same contract.
6. Quarantine `w1_oracle` and old numbered workload directories as legacy;
   current experiments must not import from them.
7. Add RQ2 FxMark and VFS suites under `bench/`.
8. Implement W4--W7 only through the shared harness and per-suite Makefiles.

## Non-Goals

This reorganization must not:

- change the kernel ABI or policy behavior;
- rewrite existing raw results;
- rename public experiment claims;
- turn Make into a thin wrapper around a new script control plane;
- refactor the 24,286-line legacy oracle before isolating it;
- combine all case studies into another monolithic binary.

## Go/No-Go Gate

The infrastructure phase is complete only when:

- W1 and W3 build from the shared harness;
- their existing public Make targets still pass in the modified-kernel KVM;
- case-study sources no longer live under `tests/`;
- KVM case recipes are split from mechanism-test recipes;
- every new case has the same required provenance and raw artifact gate;
- no current W1--W7 document uses the legacy workload numbering as the formal
  case identity;
- `make phase1` still passes.

Until this gate passes, new W4--W7 code should not be added.

## Outcome

The migration gate passed on 2026-07-26:

- W1 Sandboxed Application File Sharing and W3 Build Action Sandboxing build
  against the shared C harness;
- formal case sources moved from `tests/` to `experiments/`;
- their KVM recipes moved from the common KVM file to per-case Makefiles;
- the historical ccache matrix moved to
  `mk/experiments/legacy_build_cache.mk`, reducing common `mk/kvm.mk` from 815
  to 168 lines;
- Agent workspace, W1, and W3 use the minimum raw artifact contract;
- the historical multi-workload oracle and superseded workload numbering are
  isolated under explicitly named legacy directories;
- W1, W3, and the Agent namei_ext/FUSE matrix passed in the modified-kernel
  KVM; and
- `make phase1 RUN_ID=20260726T-infra-phase1-v2` passed after the final
  Makefile split.

The detailed implementation record, including the rejected first provenance
run, is `2026-07-26-unified-experiment-infrastructure-implementation.md`.
