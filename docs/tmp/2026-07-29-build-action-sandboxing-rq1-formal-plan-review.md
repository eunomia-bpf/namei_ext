# Plan Review: RQ1 Build Action Sandboxing

## Review Input

- Plan:
  `docs/tmp/2026-07-29-build-action-sandboxing-rq1-formal-plan.md`
- Current policy:
  `bpf/policies/build_action_sandboxing.bpf.c`
- Current controller:
  `experiments/build_action_sandboxing/namei_ext_build_action_sandboxing.c`
- Historical raw result:
  `results/experiments/build-action-sandboxing/20260726T-build-action-sandboxing-preflight-v3/`
- Selected RQ: Can a narrow VFS name-resolution extension express real
  state-dependent path-view policies without taking over filesystem semantics?

## Round 1

Verdict: NO-GO until two executable blockers are repaired.

The workload and its supporting RQ1 role are admitted. It uses an unmodified
Bazel release, two concurrent native genrules, two cgroup-specific views of the
same logical pathname, and both lookup and directory-enumeration checks. Three
fresh boots are sufficient for this deterministic correctness experiment. The
experiment is deliberately scoped to Bazel's existing-object action-view
subset, not a complete Bazel sandbox.

The first blocker is that the planned formal command does not exist. The
current suite implements only one old preflight boot and lacks the three-boot
orchestration, per-boot completion checks, and external BPF/FUSE cleanup
checks.

The second blocker is that the controller does not yet produce all raw
observations required by the lower-object oracle. It checks only declared-input
metadata and private-file bytes. It must also record declared-input bytes,
private-file metadata, and the logical input pathname's device/inode
correspondence with the selected registered lower input.

The active path must also avoid the checksum operations in the historical
suite and Bazel acquisition target. These operations do not test the selected
hypothesis.

Formal execution is approved only after the Make path and raw lower-object
oracle are implemented and the unchanged path passes local build validation
and one real KVM preflight.

## Round 2

Verdict: GO for the real KVM preflight.

The follow-up review confirmed that both blockers are repaired:

- the preflight and three-fresh-boot formal targets exist and use the shared
  Make/KVM lifecycle;
- the finalizer requires exact per-boot lifecycle, action-view, lower-object,
  and policy-counter records;
- each action records matching logical and selected-lower device/inode values
  and `ENOENT` for the hidden child;
- all four lower objects record before/after device, inode, mode, size, and
  direct expected-byte checks, with independent saved-file comparisons;
- detach, target clearing, cgroup removal, external BPF/FUSE inventory, and
  dmesg checks cover cleanup;
- the active W3 path uses the official Bazel URL and executable version check
  without an unrelated artifact-integrity operation;
- the controller links successfully and the Make database parses the formal
  entrypoints.

No new baseline or broader sandbox claim is required. The approved next step
is one fresh modified-kernel KVM preflight with the frozen oracle.
