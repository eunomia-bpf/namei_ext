# Build Action RQ2 Infrastructure Implementation

## Motivation

The existing Build Action Sandboxing preflight establishes that `namei_ext`
can give two concurrent Bazel actions distinct views and hide undeclared
inputs. It does not answer RQ2 because it has no feature-equivalent FUSE arm,
paired repetition matrix, or uncertainty analysis.

This step implements the frozen Build Action RQ2 plan. It also checks whether
the repository must be reorganized before another experiment is added.

## Repository Organization Decision

The repository was compared with `/home/yunwei37/workspace/bpf-benchmark`.
The reusable property of that repository is not its exact directory names or
Python suite runner. It is the separation between:

1. a top-level Make entrypoint;
2. a shared execution boundary;
3. suite-owned workload semantics; and
4. raw collection followed by separate analysis.

`namei_ext` already has the corresponding layers:

- `Makefile` and `mk/suites.mk` own public entrypoints and suite membership;
- `mk/kvm.mk`, `mk/results.mk`, and `mk/multi_boot.mk` own KVM launch, run
  lifecycle, pinned-host capture, artifact validation, and multi-boot
  collection;
- `mk/experiments/*.mk` owns condition order, workload-specific correctness,
  and completion rules;
- `experiments/` and `runner/` execute real policies and workloads; and
- `analysis/` reads raw observations and produces summaries and figures.

A directory migration would not improve the execution contract and would
create churn across long-lived experiment records. The implementation
therefore extends the existing shared layers. It does not add a shell control
plane, a second experiment runner, or a generic policy language.

The remaining organization debt is repetition inside older suite Makefiles.
External BPF/FUSE inventory is already shared in `mk/multi_boot.mk`. Further
deduplication should occur only after another exact repeated lifecycle block
is identified; Bazel, sandboxfs, policy-map, and matrix semantics remain
suite-owned.

## Files Inspected

- `Makefile`
- `mk/suites.mk`
- `mk/kvm.mk`
- `mk/results.mk`
- `mk/multi_boot.mk`
- `mk/workload.mk`
- `mk/experiments/agent_workspace_rq2.mk`
- `mk/benchmarks/fxmark.mk`
- `experiments/build_action_sandboxing/`
- `bpf/policies/build_action_sandboxing.bpf.c`
- `runner/include/namei_ext_harness.h`
- `runner/src/namei_ext_harness.c`
- sandboxfs 0.2.0 source at commit
  `2305d34fe764a64cf4783b43315e6eb5322310d6`
- `/home/yunwei37/workspace/bpf-benchmark/Makefile`
- `/home/yunwei37/workspace/bpf-benchmark/runner/suites/`

## Implementation

### Official sandboxfs build

`mk/workload.mk` now acquires the exact sandboxfs 0.2.0 source archive,
validates its SHA-256, installs a repository-tracked generated `Cargo.lock`,
and builds with `cargo build --release --locked`. The target checks exact
Rust/Cargo/libfuse identities and records the archive, lock, build log,
runtime linkage, binary hash, and toolchain in
`results/workloads/provenance/build/`.

The upstream archive has no `Cargo.lock`; the build explicitly verifies that
fact before installing the tracked lock. This avoids silently resolving a new
dependency graph.

### Matched runner

`namei_ext_build_action_rq2.c` runs the same two concurrent Bazel genrules for
both conditions. Each lifecycle sample creates:

- `N` declared and `N` physically existing undeclared files per action;
- fresh Bazel workspaces and output bases;
- unique started, ready, release, finished, and output records; and
- independently computed aggregate output hashes.

The `namei_ext` arm installs one selected lower root and `N` declared-name
allowlist entries per action. The sandboxfs arm creates two unique sandbox IDs
with the same `N` declared mappings. Both expose the same logical action path.
An unknown lower file is created after setup and must remain hidden.

The runner records raw setup, barrier-to-finish action, and lifecycle times.
It also records sandboxfs process statistics, output hashes, correctness
booleans, policy counters, and the preflight capacity probe. Partial map setup
is rolled back, timed-out children are terminated and reaped, every successful
sandbox ID is destroyed, and the daemon is unmounted and required to exit.

### Paired KVM suite

`mk/experiments/build_action_rq2.mk` adds:

- `make kvm-build-action-rq2-preflight`;
- `make kvm-build-action-rq2`;
- `make build-action-rq2-report`; and
- `make experiment-build-action-rq2`.

The preflight is one paired block at 64 inputs plus a 4,096-entry map
fill/read/clear gate. The formal matrix is ten paired alternating blocks,
three samples at 64, 512, and 2,048 inputs per boot. Scale order rotates by
block.

Each boot archives the exact kernel identity, runner, BPF object, Bazel,
sandboxfs, libfuse, bpftool, source archive, dependency lock, and build
provenance. Shared external inventory captures BPF programs, cgroup
attachments, FUSE mounts, and `/dev/fuse` owners before, during, and after the
runner.

The formal target is intentionally absent from aggregate formal-suite
membership until the real paired preflight passes.

### Analysis

`analysis/build_action_rq2/analyze.py` rejects failed, missing, duplicate,
misordered, or ungraded rows. It reduces the three samples in each boot cell
to a median, computes the paired `sandboxfs/namei_ext` ratio for every block,
and reports a deterministic 10,000-resample percentile-bootstrap 95%
confidence interval.

The predeclared verdict uses the 2,048-input action-time cell:

- CI lower bound above one: supported;
- CI upper bound at or below one: contradicted;
- otherwise: inconclusive.

The analyzer writes `summary.json`, `summary.csv`, `report.md`, and PDF/PNG
figures. Raw collectors do not compute these paper summaries.

## Alternatives Rejected

- Moving the repository into the exact bpf-benchmark directory layout: the
  shared execution boundary already exists, and such a move would not remove
  suite semantics.
- Adding symlink forest, OverlayFS, or another table baseline: the frozen
  experiment asks one matched RQ2 question against the official source-system
  FUSE mechanism. Published construction comparisons are cited.
- Reusing the old negative hide list: an unknown file created after setup
  would make the two conditions semantically unequal.
- Using read-only sandboxfs mappings: that would add a sandboxfs-only
  permission policy. Writable mappings leave permissions to the same lower
  objects; the action itself remains read-only.
- Treating a host smoke test as preflight: the declared preflight remains a
  real modified-kernel KVM run through `cgroup/namei_ext`.

## Validation Performed

- clean C runner rebuild with `-Wall -Wextra`;
- exact sandboxfs archive, lock, binary, version, toolchain, and libfuse
  provenance checks;
- eight Build Action analysis unit tests, including complete report/figure
  generation;
- infrastructure tests for the shared KVM capture interface, shared
  BPF/FUSE inventory, and locked sandboxfs build contract;
- dry expansion of the finalize target and direct inspection of the expanded
  launch-order `jq` expression;
- `python3 -m py_compile`; and
- `git diff --check`.

## Remaining Risks And Follow-up

- No host-side validation substitutes for the official real preflight. The
  next action after a clean commit is one paired KVM preflight.
- The preflight must confirm sandboxfs 0.2.0's live protocol, mount identity,
  root access, Bazel BUILD quoting, and the modified-kernel policy path.
- A failed preflight is preserved as raw evidence and counts toward the
  three-attempt limit. The formal matrix remains blocked until preflight and
  independent result review pass.
- Older large suite Makefiles still contain repeated lifecycle structure.
  Refactor only a proven common block, with contract tests, rather than
  introducing a second generic experiment framework.

## Independent-Review Addendum

The first read-only implementation review returned `NO GO` with two
high-severity validity findings: `setup_ns` excluded sandboxfs's required
per-action mount namespace and bind mount, and runtime artifact capture did
not independently revalidate the Bazel and libfuse files used by the run. It
also identified three evidence-quality issues: polling-based action completion,
cleanup failures hidden behind a primary failure, and output rows containing
only expected hashes.

All findings were repaired without changing the frozen experiment question or
matrix. The detailed implementation and validation record is
`docs/tmp/2026-07-28-build-action-rq2-review-repairs.md`. The same reviewer
returned `FINAL GO`. The real paired KVM preflight remains unrun until this
repaired tree is committed and passes the clean-tree gate.
