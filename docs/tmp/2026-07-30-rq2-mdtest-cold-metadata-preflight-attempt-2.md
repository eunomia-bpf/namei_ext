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

## Root Cause

Installed virtme-ng 1.40 enables one TCP QMP server for `--pin`, starts an
asynchronous pin worker, and sends both `qmp_capabilities` and
`query-cpus-fast` as JSON without the newline required by QMP's line-oriented
protocol. The worker then waits with `readline()`.

Attempt 1 and attempt 2 expose the two sides of that race:

- in attempt 1, the independent verifier connected first and observed all
  eight unpinned vCPU TIDs with host-wide CPU masks;
- after the added delay in attempt 2, virtme-ng's worker connected first,
  blocked during capability negotiation, and occupied the QMP endpoint, so the
  independent verifier could not connect.

The three-second delay was therefore a false diagnosis repair. It did not
weaken the gate or create a false pass, but it cannot make the installed
virtme-ng pin implementation complete its QMP protocol.

## Next Step

The final allowed real preflight must not call virtme-ng `--pin`. The repaired
Make path will expose QMP explicitly, run a project-owned controller that maps
each QEMU vCPU TID to one declared host CPU, close that connection, and then run
the existing read-only verifier as an independent exact-singleton read-back
gate. The guest remains blocked until the verifier publishes its atomic
artifact.
