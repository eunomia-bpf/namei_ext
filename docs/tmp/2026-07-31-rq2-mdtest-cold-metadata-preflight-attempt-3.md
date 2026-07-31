# RQ2 mdtest Cold Metadata Preflight Attempt 3

## Purpose

This record preserves the third and final real KVM preflight attempt for the
reviewed mdtest cold and mutating metadata experiment. The immutable result root
is:

```text
results/experiments/mdtest-cold-metadata-rq2-preflight/20260731T002221Z-mdtest-preflight03/
```

No fourth preflight is permitted under the experiment plan.

## Preconditions

- Source commit `28432e4f79fb1950820edb32421b7b4fffed5339` was
  pushed to `origin/main`.
- Repository and kernel trees were clean.
- No unrelated QEMU, mdtest, MPI, or FUSE process was running.
- Host CPUs 8--15 were 100% idle in three consecutive one-second samples.
- The controller repair had passed 6 controller tests, 10 verifier tests, 19
  analyzer tests, Make expansion checks, and independent follow-up review.
- The workload, condition, rank, operation, cache, filesystem, and correctness
  protocol was unchanged.

## Outcome

The first stock boot failed before any mdtest phase:

```text
status: failed
failure: kvm-launch-or-guest-command
```

The affinity repair itself succeeded:

- the controller discovered eight QEMU vCPU TIDs;
- every TID initially had the host-wide `0-23` mask;
- it set the exact mapping vCPU 0--7 to host CPUs 8--15;
- controller read-back recorded eight singleton masks;
- the independent verifier reconnected, rediscovered the same TIDs, and
  confirmed all eight singleton masks in one attempt.

The controller published at `00:22:43.686432Z` and the independent verifier at
`00:22:43.725458Z`. Both artifacts are complete and passing.

The vng/QEMU launcher then exited nonzero before the guest created its affinity
barrier record. Both launcher logs are empty, the launch-order file is empty,
and no guest, mdtest, MPI, FUSE, BPF, ext4, or phase observation exists. Host
journal, dmesg, and coredump inspection contain no QEMU failure record for the
interval. The old common launcher did not preserve its numeric exit status, so
this immutable root cannot distinguish QEMU startup failure from an immediate
guest-command failure.

## Upstream Check

The host has virtme-ng 1.40. Upstream contains two relevant fixes from different
revisions:

- `3beedfe9f86e1cf34335282c4f7df4156748b83d`, included in v1.41,
  enables QMP whenever `--pin` is used; and
- `8f74cceecb163a5d5b08e70c101de85920eb624c`, dated after v1.41,
  later moves pinning from the vng-side background thread into `virtme-run`
  immediately before QEMU launch to address QMP connection timing.

The latter commit is:

```text
https://github.com/arighi/virtme-ng/commit/8f74cceecb163a5d5b08e70c101de85920eb624c
```

This source check also disproves the earlier assertion that missing command
newlines were the QMP failure's established cause. Upstream's repaired client
uses the same complete-JSON send form. The first two roots support only an
asynchronous QMP lifecycle failure.

## Preflight Decision

```text
run status: incomplete
claim verdict: unresolved
artifact validity: valid failure evidence, no workload observations
next paper decision: do not run formal and do not cite this experiment
```

All three allowed real preflight attempts are exhausted. This experiment closes
without RQ2 evidence. A future reconsideration requires a newly reviewed plan
that pins an official virtme-ng version with upstream pinning, enables verbose
launcher evidence, and preserves launcher, controller, verifier, QEMU, and guest
statuses separately before any new KVM execution.
