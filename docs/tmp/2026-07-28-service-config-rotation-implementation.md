# Service Configuration Rotation Implementation

## Motivation

The approved W4 plan needs one traditional live-service case for RQ1. It
tests whether one logical nginx configuration pathname can select distinct
existing generations while nginx still owns configuration validation, worker
replacement, failed-reload behavior, and HTTP service semantics. This is not a
FUSE performance comparison and does not test whether other mechanisms are
incapable of implementing rotation.

## Files Inspected

The implementation reused:

- `runner/include/namei_ext_harness.h` and
  `runner/src/namei_ext_harness.c` for cgroup, target-registry, BPF attach,
  component-map, child-wait, and policy-counter operations;
- `mk/kvm.mk` for modified-kernel KVM execution and dmesg gates;
- `mk/results.mk` for the immutable run root and source/kernel identity;
- `mk/workload.mk` and `configs/benchmarks/workload-sources.mk` for the pinned
  nginx 1.26.3 archive and build;
- the Agent Workspace RQ2 suite for fresh-boot artifact and guest Makefile
  patterns; and
- Kubernetes `AtomicWriter` source at commit
  `20c07aa8699e1431e0c9056003670ba862934f87` plus official nginx reload
  behavior for the source-system oracle.

The approved experiment and three-round review are recorded in
`2026-07-28-service-config-rotation-experiment-plan.md` and
`2026-07-28-service-config-rotation-plan-review.md`.

## Design Choices

The fixture has four immutable configuration directories:

```text
generation-current/
generation-canary/
generation-invalid/
generation-rollback/
```

The service always opens `<fixture>/view/live/nginx.conf`. The BPF policy maps
only the `live` component to one pre-registered directory. Current and
rollback configurations refer to one static-content tree; canary and invalid
refer to another. Both content trees are outside the selected path, so HTTP
behavior cannot change merely because the BPF target changed.

The state machine is:

1. select current, start one live nginx master, and observe the current body;
2. select canary, send `SIGHUP`, require a new worker and canary body;
3. select the physically invalid generation, prove the logical hash changed,
   send `SIGHUP`, require nginx's directive error, the same worker, and the
   retained canary body;
4. select a distinct rollback generation, send `SIGHUP`, require another new
   worker and the restored current body.

Each transition has a five-second monotonic deadline. Every run snapshots all
four configuration files and both content files before execution and checks
their bytes, device, inode, mode, size, mtime, and ctime afterward.

## Implementation

- `bpf/policies/service_config_rotation.bpf.c` implements one exact-component
  map and lookup/readdir/select/pass counters.
- `experiments/service_config_rotation/namei_ext_service_config_rotation.c`
  owns the nginx fixture and state machine. It performs physical `nginx -t`
  controls, cgroup-scoped logical hash and readdir probes, direct master
  signals, worker-PID checks, HTTP polling, lower-object checks, counter
  collection, graceful shutdown, policy detach, target clearing, and cgroup
  removal. State rows contain the separately observed HTTP body rather than a
  copy of the expected value.
- `mk/experiments/service_config_rotation.mk` owns one-boot preflight and
  ten-boot formal entrypoints. It packages the exact kernel, policy, runner,
  nginx binary, source archive, build records, and hashes into the result root,
  writes one guest Makefile per boot, fails on the first bad boot, and
  validates the declared boot/state matrix before analysis.
- `mk/kvm.mk` accepts an optional outer timeout in the shared KVM capture
  helper. W4 fixes this guard at 120 seconds; existing callers that omit the
  argument retain their current behavior.
- `analysis/service_config_rotation/analyze.py` reads the combined raw JSONL,
  rejects missing, duplicated, extra, malformed, or failed rows, validates
  master/worker histories and distinct hashes, and produces a correctness
  summary plus descriptive transition latencies.
- `analysis/service_config_rotation/test_analyze.py` covers the complete
  matrix and false-pass cases for hashes, invalid-reload workers, missing
  oracles, failed rows, and extra repetitions.

## Rejected Alternatives

- No feature-equivalent FUSE implementation was added. This case contributes
  RQ1 breadth and makes no cost or superiority claim; Agent Workspace and the
  RQ2 benchmarks already own the matched FUSE comparison.
- The invalid generation is not hidden by BPF. Kubernetes AtomicWriter does
  not validate nginx semantics. The experiment publishes the candidate and
  observes nginx's native failed-reload behavior.
- Static response files are not placed below the selected directory. That
  would let policy selection change the HTTP body without proving nginx
  accepted and installed a new configuration.
- No shell control script or configuration DSL was added. Public execution
  remains Make-only and policy logic remains an eBPF C program.

## Validation

Completed before the real KVM preflight:

- `make service-config-rotation-analysis-test`: six analyzer contract tests
  initially passed, then nine passed after adding explicit preflight/formal
  evidence-role and result-level tests;
- `make service-config-rotation`: the runner rebuilt with `-Wall -Wextra`
  without warnings;
- `make bpf`: the policy compiled for the BPF target;
- GCC `-fanalyzer -fsyntax-only` reported no runner finding;
- a synthetic one-boot analyzer invocation produced
  `summary.json`, `summary.csv`, and `report.md` with the required
  `not_tested` preflight verdict; and
- `git diff --check` passed.

These are implementation checks only. They do not count as Phase 1 validation
or paper evidence.

An independent implementation review initially returned `NO-GO`. The repair
made one-boot analysis explicitly `not_tested`, recorded actual HTTP bodies,
added runner-child and outer-KVM deadlines, checked readdir errors, scoped
policy counters to the service cgroup, widened nginx failure-level checks, and
prevented an already-exited or zombie master from passing graceful shutdown.
The shared harness now bounds the short target-register, target-clear, and
policy-parent control children without changing the unbounded public wait used
by real long-running workloads such as Bazel. Log-tail helpers propagate I/O
errors instead of interpreting them as an absent error record.
The detailed review record is
`2026-07-28-service-config-rotation-implementation-review.md`.

## Remaining Work

1. Commit the implementation so the clean-source experiment gate can run.
2. Run one real modified-kernel KVM preflight with the pinned nginx binary.
3. Repair only implementation defects exposed by preflight, with at most three
   attempts under the approved plan.
4. After a passing preflight and clean commit, run ten fresh KVM boots.
5. Preserve raw results, run a fresh independent result review, and only then
   update the paper-facing evidence status.
