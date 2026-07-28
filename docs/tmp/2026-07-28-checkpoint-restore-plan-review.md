# Checkpoint/Restore Experiment Plan Review

## Scope

This review covers
`docs/tmp/2026-07-28-checkpoint-restore-experiment-plan.md` and the pinned DMTCP
source at commit `068559d9b14c5f96a57869753bba7c066cbf9653`.

The reviewer was read-only and independent of the plan implementation.

## Admission Verdict

The reviewer returned `GO with repairs` for a supporting RQ1 case study.
Checkpoint/Restore and Migration should precede Toolchain and Dependency
Environments because it already has:

- a fixed upstream source and paper;
- a source-native checkpoint/restart implementation;
- an upstream pathvirt integration test;
- a direct natural baseline; and
- a narrow responsibility that the current `namei_ext` directory target can
  express.

The priority reflects execution readiness and causal clarity, not a claim that
checkpoint/restart has broader industrial demand than software environments.

## Blocking Findings

### Restart Invocation

The original plan said launch and restart would both use `--pathvirt`.
`dmtcp_restart` has no such option. Upstream launches with `--pathvirt`, stores
the plugin in the checkpoint image, then invokes ordinary `dmtcp_restart`.
During the restart event, `src/plugin_pathtranslator.cpp` reads the new
`DMTCP_PATH_MAPPING` from the restart environment.

Resolution: the plan now freezes that source-native behavior exactly.

### Fair Pathname Oracle

The upstream application repeatedly uses `fopen` and closes the file. The
experiment must not broaden the claim to arbitrary direct syscalls or static
applications that bypass DMTCP's pathname wrappers.

Resolution: both conditions now use the same `fopen`, `fstat`,
`opendir`/`readdir`, and close-before-checkpoint sequence. The plan explicitly
limits the resulting claim to those tested pathname operations.

### Directory Selection

The current kernel mechanism accepts a registered lookup-capable directory as
the selected target. A regular file cannot be substituted as the final open
target by this prototype.

Resolution: the BPF policy selects the `workspace` directory component, not
`state.txt`.

### State Update

The existing target registry already supports atomically replacing a target
under one ID. A second BPF state map and two target IDs would add unnecessary
mechanism to this workload.

Resolution: target ID 1 points to generation A before checkpoint and is
replaced with generation B before restart.

### Cgroup Attribution

BPF dispatch and target registration use the current task's default cgroup.
DMTCP restart therefore must be launched inside the managed cgroup, and the
restored application's cgroup must be recorded before its oracle is accepted.

Resolution: this is a hard correctness gate. The controller and coordinator
remain outside the managed cgroup, while launch and restart workers enter it.
The existing shared harness performs cgroup-scoped target registration.

### Process Identity

DMTCP virtualizes application-visible process IDs.

Resolution: the external controller records separate launch and restart
instances, while the restored application proves `num_restarts > 0`. PID
inequality observed through application `getpid()` is not an oracle.

### Replication Budget

The original ten paired blocks had no statistical hypothesis. This case study
primarily contributes replicated correctness and boundary evidence.

Resolution: the formal protocol uses three independent paired blocks, six
fresh KVM boots, alternating condition order. Durations remain descriptive.

### Negative Control

Without either mechanism, the application could not reach generation A before
checkpoint, so the original negative-control wording was underspecified.

Resolution: the control starts with the A mapping, checkpoints, withdraws the
mapping, and verifies that ordinary restart fails the post-restart path oracle.

## Residual Risks

- The upstream autotest keeps one mapping across restart; this experiment must
  prove a real A-to-B change.
- DMTCP may fail on the modified 7.1.0-rc7 kernel despite passing on the host.
- Restarted cgroup membership may not match normal exec inheritance.
- Every pathname-derived descriptor must be closed before checkpoint.
- The policy link and target registry must survive the controller's complete
  launch/checkpoint/restart lifecycle.
- DMTCP pathvirt has no per-wrapper invocation counter; enablement, command,
  environment, application identity, and output artifacts must provide source
  attribution.

## Execution Gate

The repaired plan is suitable for implementation, but a real preflight remains
blocked until:

1. the DMTCP source is acquired and built through committed Make targets;
2. the focused runner, directory-selection policy, analyzer, and tests exist;
3. all formal/preflight parameter overrides fail closed;
4. a Make dry-run resolves the complete artifact dependency graph; and
5. an independent implementation review returns `GO`.

No formal run is authorized before a valid KVM preflight and independent result
review.

## Baseline-Amendment Review

After the initial A-to-B failure was attributed to
`dmtcp_get_restart_env()`, an independent read-only reviewer inspected the
patch, original archive, acquisition/build Make paths, host result contract,
and all checkpoint/restore planning records.

The reviewer confirmed:

- the patch changes only the flattened restart-environment scan bound from
  pointer size to bytes read;
- `plugin_pathtranslator.cpp`, `test/pathvirt1.c`, and the controller and
  application oracles are unchanged;
- the patch does not implement pathname remapping or create an artificial
  advantage for `namei_ext`;
- the baseline is fair only when labeled patched DMTCP PathTranslator at
  commit `068559d9b14c`, with a disclosed one-line restart-environment
  scan-bound fix; and
- the resulting claim remains limited to the exact A-to-B,
  closed-descriptor, `fopen`/`fstat`/`opendir`/`readdir` oracle and observed
  responsibility boundary.

The first verdict was `GO-with-repairs`. It identified four repairs:

1. verify `inputs.sha256` and `artifacts.sha256` before the shared run enters
   `completed`;
2. include the actually used `mtcp_restart`, complete install manifest,
   source archive, patch, relevant source, and complete runtime tree in the
   result-owned provenance boundary;
3. use one patched-baseline name throughout; and
4. state explicitly that the upstream test covers an unchanged mapping.

All four repairs are implemented. The repaired host run is
`20260728T-dmtcp-pathvirt-contract-v4`; both manifests, the complete install
tree, runtime evidence, and checkpoint image validate before completion.

The second read-only review found no remaining submission blocker and returned
`GO`. It independently verified that the restart script and controller execute
the result-owned DMTCP runtime, the five checksum layers pass, the A-to-B oracle
holds, and the result remains labeled dirty-source host dependency evidence.
The suite may proceed to modified-kernel KVM preflight integration. This is not
authorization for a formal run.
