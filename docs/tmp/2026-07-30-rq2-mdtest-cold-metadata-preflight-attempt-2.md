# RQ2 mdtest Cold Metadata Preflight Attempt 2

## Purpose

This record preserves the second real KVM preflight attempt for the reviewed
mdtest cold and mutating metadata experiment. The result root is immutable:

```text
results/experiments/mdtest-cold-metadata-rq2-preflight/20260730T235638Z-mdtest-preflight02/
```

The attempt counts as attempt 2 of the three-attempt real-preflight limit.

## Preconditions

- Repository and kernel trees were clean.
- Commit `2e28e52` containing the reviewed three-second affinity-verifier delay
  was pushed to `origin/main`.
- The unrelated `bpf-benchmark` KVM workload exited naturally before launch.
- Host CPUs 8--15 were 97--100% idle over three one-second samples.
- The experiment protocol, workloads, conditions, rank counts, operation
  phases, and correctness gates were unchanged.

## Outcome

The Make target failed in the first stock boot before any mdtest phase:

```text
status: failed
failure: vcpu-affinity-verification
```

The independent affinity artifact records:

- `initial_delay_seconds: 3.0`;
- 200 QMP attempts;
- no observed vCPU records; and
- final error `[Errno 111] Connection refused`.

The launcher log records:

```text
QMP capabilities negotiation failed
WARNING: Failed to pin vCPUs
```

No lookup policy, FUSE process, MPI rank, or mdtest phase executed. This attempt
therefore supplies no RQ2 workload or performance result.

## QMP Failure And Later Correction

Installed virtme-ng 1.40 enables one TCP QMP server for `--pin`, starts an
asynchronous pin worker, and failed while waiting for the QMP capability
response in this attempt.

Attempts 1 and 2 are consistent with a failure in the installed asynchronous
QMP pinning path:

- attempt 1 observed eight unpinned vCPU TIDs with host-wide CPU masks; and
- attempt 2 recorded a QMP capability-negotiation failure while the independent
  verifier received connection refusals.

The artifacts do not establish client connection order, endpoint ownership, or
why the QMP server closed.

The three-second delay was therefore a failed synchronization repair. It did
not weaken the gate or create a false pass, but it did not make the installed
virtme-ng pin implementation complete.

A later source check after attempt 3 corrected an over-attribution in the
initial diagnosis. Upstream virtme-ng's repaired pin implementation also sends
complete JSON objects without an explicit newline before reading QMP replies.
The missing newline is therefore not established as the cause. The immutable
artifacts prove only that the installed asynchronous worker failed capability
negotiation while the independent verifier could not connect; they do not
contain enough QMP or process-lifecycle evidence to identify why the server
closed. Upstream commit `8f74cceecb163a5d5b08e70c101de85920eb624c`
moves pinning into `virtme-run` immediately before QEMU launch to repair QMP
connection timing:

```text
https://github.com/arighi/virtme-ng/commit/8f74cceecb163a5d5b08e70c101de85920eb624c
```

## Next Step

The final allowed real preflight must not call virtme-ng `--pin`. The repaired
Make path will expose QMP explicitly, run a project-owned controller that maps
each QEMU vCPU TID to one declared host CPU, close that connection, and then run
the existing read-only verifier as an independent exact-singleton read-back
gate. The guest remains blocked until the verifier publishes its atomic
artifact.
