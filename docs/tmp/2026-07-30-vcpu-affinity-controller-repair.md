# vCPU Affinity Controller Repair

## Motivation

The second mdtest preflight proved that delaying the independent verifier cannot
repair the installed virtme-ng 1.40 `--pin` path. Its asynchronous worker failed
QMP capability negotiation and prevented the independent verifier from
connecting. The last permitted preflight therefore needs a deterministic
controller path that does not use that worker.

## Design

The common Make-owned KVM capture path now separates affinity control from
affinity evidence:

```text
launch vng without --pin and expose QMP explicitly
run pin_vcpu_affinity.py
  query QMP for ordered vCPU TIDs
  close the controller QMP connection
  require exactly one TID per declared host CPU
  set each TID to one singleton CPU
  read back and publish vcpu-affinity-pin.json
run verify_vcpu_affinity.py as a separate read-only process
  reconnect to QMP
  rediscover every TID
  read /proc/TID/status
  require the exact ordered singleton mapping
  atomically publish vcpu-affinity.json
allow the guest workload to cross its existing barrier
```

The controller and verifier use newline-terminated QMP requests. The controller
closes QMP after obtaining the ordered TIDs; affinity setting and read-back use
the corresponding host `/proc` records. It rejects missing, duplicate, or
non-contiguous vCPU indexes, a vCPU-count mismatch, syscall failure, and any
failed read-back. A failed controller artifact retains the latest available
before/after masks. The verifier then reconnects independently and retains the
exact ordered-singleton condition.

## Files

- `mk/kvm.mk`
- `tools/kvm/pin_vcpu_affinity.py`
- `tools/kvm/test_pin_vcpu_affinity.py`
- `tools/kvm/verify_vcpu_affinity.py`
- `tools/kvm/test_verify_vcpu_affinity.py`
- `mk/experiments/mdtest_cold_metadata.mk`

## Protocol Preservation

The repair does not change:

- eight guest vCPUs;
- host CPUs 8--15;
- vCPU index `i` mapped to host CPU `8+i`;
- guest-side affinity barrier ordering;
- mdtest conditions, rank counts, operations, item counts, cache protocol, or
  fresh-ext4 lifecycle;
- FUSE allocation to guest CPUs 4--7; or
- the maximum of three real preflight attempts.

The mdtest finalizer now requires both the controller artifact and the
independent verifier artifact to contain the exact mapping.

## Validation Plan

Before the third KVM attempt:

1. unit-test contiguous-index and vCPU-count validation;
2. unit-test one `sched_setaffinity()` call per ordered vCPU;
3. unit-test failed read-back and QMP retry behavior;
4. retain all existing read-only verifier tests;
5. inspect a vng dry run to confirm explicit QMP is present and `--pin` is
   absent;
6. inspect Make expansion and run `git diff --check`; and
7. obtain a fresh independent review of the raw attempt-2 evidence, controller,
   verifier, Make lifecycle, and false-pass risk.

No additional real KVM probe is permitted before the reviewed third preflight.

## Validation Performed

- 6 controller unit tests passed.
- 10 independent verifier unit tests passed, including two sequential QMP
  clients reconnecting to one endpoint.
- 19 mdtest analyzer tests passed.
- Python bytecode compilation passed for the controller, verifier, and tests.
- Make dry-run expansion contained exactly one explicit local QMP endpoint,
  one controller invocation, and one verifier invocation; it contained no
  virtme-ng `--pin`.
- The finalizer's full expected-map expressions passed a synthetic `jq` check.
- `git diff --check` passed.

A fresh independent read-only review found no P0/P1 false-pass or lifecycle
blocker. It requested better failed-controller observations and exact
documentation of QMP connection lifetime. `PinningError` now carries the latest
available before/after masks into the failed artifact, and the document now
states that the controller closes QMP after obtaining TIDs. The same reviewer
then returned:

```text
Follow-up repair verdict: GO
```

This verdict approves committing the repair and launching only the third
mdtest preflight. It does not approve formal execution.

## Post-Run Correction

The controller and independent verifier both succeeded in attempt 3, so this
repair closed the affinity defect. A later inspection of upstream virtme-ng
corrected the initial explanation: absence of an explicit newline in the old
client is not a proven cause because the upstream repaired client uses the same
complete-JSON send form. The evidence supports an asynchronous QMP lifecycle
failure, not a missing-newline conclusion. Upstream subsequently moved the
pinning thread into `virtme-run` immediately before QEMU launch in commit
`8f74cceecb163a5d5b08e70c101de85920eb624c`.
