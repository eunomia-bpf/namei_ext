# vCPU Affinity Controller Repair Review

## Purpose

This record captures the independent read-only review required before the
third and final real KVM preflight for the RQ2 mdtest cold and mutating metadata
experiment. It does not approve a formal run.

## Evidence Reviewed

The reviewer inspected:

- both immutable failed preflight roots;
- installed virtme-ng 1.40 QMP and `--pin` code;
- `mk/kvm.mk`;
- the new affinity controller and its tests;
- the independent verifier and its tests;
- the mdtest finalizer and guest barrier;
- the attempt-2 and controller-repair records; and
- the frozen experiment plan and plan review.

The reviewer also checked the vng and Make dry-run expansion and reran static
tests without launching a VM.

## Initial Findings

The reviewer found no P0/P1 issue or path by which an incorrect vCPU mapping
could receive final success. It confirmed:

1. The missing-newline diagnosis follows from the installed virtme-ng source
   and the two different failed QMP observations.
2. vng receives an explicit local QMP option and no `--pin`.
3. The controller requires contiguous vCPU indexes, the exact vCPU count,
   valid TIDs, singleton `sched_setaffinity()` calls, and successful read-back.
4. The verifier is a separate process that reconnects, rediscovers TIDs, reads
   `/proc/TID/status`, and requires the exact ordered singleton mapping.
5. The guest cannot cross its barrier before the verifier atomically publishes
   `status=verified`.
6. The finalizer independently requires exact controller and verifier
   artifacts, and launcher, controller, or verifier failure fails the run.
7. The workload and performance protocol is unchanged.

Two nonblocking findings remained:

- a failed controller artifact could lose the latest before/after masks; and
- the repair document placed QMP close after pinning although the implementation
  closes QMP immediately after querying TIDs.

## Corrections

The controller now raises `PinningError` with the latest available before/after
masks, and a unit test verifies that failed output preserves them. The repair
document now states the exact connection order. The mdtest finalizer also
requires the complete expected mapping, endpoint, and timestamp in both
affinity artifacts, and the protocol freezes the local QMP host and port.

## Follow-Up

The same reviewer inspected the corrected worktree and returned:

```text
No remaining P0/P1/P2 issues affecting attempt-3 safety or diagnosability.

Follow-up repair verdict: GO
```

The verdict approves committing this repair and launching preflight attempt 3
under a new result root. It does not reuse either failed root and does not
approve formal execution.
