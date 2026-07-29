# Build Action RQ2 Independent-Review Repairs

## Motivation

The initial implementation review found two high-severity validity defects in
the paired Bazel/sandboxfs experiment:

1. the reported view-setup interval excluded the sandboxfs child mount
   namespace and bind mount; and
2. artifact capture could trust stale build provenance instead of validating
   the Bazel and libfuse files used by the run.

The reviewer also identified completion-timestamp quantization, incomplete
cleanup evidence, and the absence of separate expected and observed output
hashes. This implementation step repairs those findings before any real KVM
preflight. It does not change the research question, workload, baseline,
sample matrix, primary scale, or statistical decision rule.

## Files Inspected And Changed

- `experiments/build_action_sandboxing/namei_ext_build_action_rq2.c`
- `analysis/build_action_rq2/analyze.py`
- `analysis/build_action_rq2/test_analyze.py`
- `mk/workload.mk`
- `mk/experiments/build_action_rq2.mk`
- `tests/infrastructure/test_kvm_capture_interface.py`
- `docs/tmp/2026-07-29-build-action-rq2-experiment-plan.md`
- `docs/tmp/2026-07-28-sandboxfs-0.2.0-protocol-audit.md`

## Setup-Time Boundary

Each action child now moves into its assigned cgroup and, for the sandboxfs
condition, creates a private mount namespace, makes the mount tree private,
and bind-mounts its sandbox view at the common logical action path. The child
then signals a setup-ready pipe and waits on a separate release pipe.

The parent starts the setup timer before installing the two views. It stops
the timer only after both children report that cgroup placement and any
sandboxfs-specific namespace/bind setup have completed. Consequently
`setup_ns` covers:

- both `namei_ext` policy-view installations or both sandboxfs create
  requests;
- the two action forks and cgroup moves; and
- the sandboxfs private namespace and bind setup required before Bazel can
  consume the view.

Unknown lower files and lower-object manifests are created after this setup
barrier while both children remain blocked. Those operations remain outside
view setup and action execution in both conditions.

## Runtime Identity Gates

`workload-bazel` now verifies the executable, expected SHA-256, and exact
`bazel 6.5.0` version on every invocation. `workload-sandboxfs-build` now
rechecks the current libfuse version and runtime-library SHA-256 in addition
to the archive, Cargo lock, sandboxfs binary, and recorded build provenance.

The suite repeats direct Bazel, sandboxfs, and libfuse SHA-256 checks
immediately before copying artifacts into a result root. The manifest records
the observed Bazel version and observed binary hash rather than copying
configuration constants into evidence.

## Completion And Correctness Evidence

The parent establishes an inotify watch before releasing the two action
barriers. The action interval ends when both unique action-finished files are
closed, eliminating the previous zero-to-ten-millisecond polling interval from
the primary measurement. A child exit before its corresponding completion
marker is an error; a normal exit after its marker remains eligible for the
normal reap and exit-status check.

The runner parses each Bazel output file and emits four fields:

- `expected_hash_a`;
- `expected_hash_b`;
- `observed_hash_a`; and
- `observed_hash_b`.

It requires the unique sample identity, exactly one lowercase 64-character
SHA-256 value, and equality between expected and observed hashes. The analyzer
independently rejects malformed or unequal values.

Action reaping, view removal, sandbox destruction, daemon-stat capture,
policy destruction, sandboxfs shutdown, and cgroup removal failures now emit
stage-specific failure rows. A pre-existing workload failure no longer hides
a simultaneous cleanup failure. Setup rollback records the first map/target
cleanup error separately from the primary setup error, and a failed forced
termination after an action-reap timeout receives its own failure stage.

## Validation

The repaired implementation passed:

- a clean runner rebuild with `-Wall -Wextra` and no warnings;
- nine Build Action analyzer tests, including expected/observed mismatch
  rejection;
- 22 shared infrastructure tests;
- 19 FxMark analyzer tests;
- eight Agent Workspace analyzer tests;
- publication-bundle replay;
- the complete `make result-contract` negative and positive contract suite;
  and
- `git diff --check`.

The first local validation attempt failed at compile time because a
marker-aware condition was applied to the ready-barrier helper rather than
the completion helper. The code was corrected before any KVM command ran, and
the complete validation above then passed.

## Remaining Gate

The same independent reviewer rechecked the repaired diff and found no
blocker or high-severity issue. It confirmed that setup timing now includes
the sandboxfs namespace/bind work, runtime identities are checked from actual
artifacts, inotify removes the completion polling interval, and expected and
observed hashes are independently retained. The final verdict was
`FINAL GO` for one real paired KVM preflight.

The reviewer noted two medium diagnostic omissions in failure-only paths:
partial `namei_ext` setup rollback and forced termination after a reap
timeout. Both were subsequently made explicit as stage-specific failure
evidence. No KVM preflight has yet been run. A clean source and kernel tree
and a fresh result ID remain required before the first attempt.
