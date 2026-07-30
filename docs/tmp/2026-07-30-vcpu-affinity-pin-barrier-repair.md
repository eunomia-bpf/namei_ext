# vCPU Affinity Pin Barrier Repair

## Motivation

The first mdtest KVM preflight exposed an unsynchronized common vCPU affinity
barrier. Virtme-ng launches its `--pin` QMP worker asynchronously, while the
independent verifier previously began QMP polling immediately. Eight vCPU
threads were observed without the required pinning, and the verifier correctly
failed because all retained the host-wide CPU mask. Competition between the
two QMP clients is the evidence-supported diagnosis from this state and the
installed control flow; the failed artifact does not contain a per-connection
QMP timeline.

## Files Inspected

- `mk/kvm.mk`
- `tools/kvm/verify_vcpu_affinity.py`
- `tools/kvm/test_verify_vcpu_affinity.py`
- the installed virtme-ng 1.40 `pin_vcpus()` and `set_affinity()` paths
- the attempt 1 `run.json` and `vcpu-affinity.json`
- prior successful four-vCPU affinity artifacts

## Design

The guest already waits for an atomic `verified` affinity artifact before
starting a workload. The missing ordering was on the host:

```text
launch virtme-ng with --pin
wait for its asynchronous QMP pin worker
independently query QMP and /proc/TID/status
publish verified or failed artifact
allow or reject guest workload start
```

The verifier now supports a nonnegative initial delay. The common capture path
sets it to three seconds, covering virtme-ng's one-second QMP retry cadence
without reducing the existing 20-second independent verification window.

The verifier remains read-only. It does not set affinity or repair a failed
mapping. Success still requires one distinct singleton host CPU for every vCPU
in the declared order.

## Alternatives Rejected

- Accepting host CPUs 8--15 as one shared mask was rejected because it would
  weaken the reviewed one-vCPU-per-core protocol.
- Moving affinity setting into the verifier was rejected because the verifier
  must remain independent read-back evidence.
- Retrying the mdtest preflight without a synchronization repair was rejected
  because it would repeat the same uncontrolled QMP ordering.
- Reducing the guest to four vCPUs was rejected because it would starve either
  the four mdtest ranks or the four-core FUSE daemon and change the reviewed
  comparison.

## Validation

Local validation must cover CPU-list parsing, exact ordered singleton matching,
the initial-delay call, negative-delay rejection, QMP handshake, and timeout
failure. A real KVM result is deliberately deferred until the repair passes
independent review and is committed so the clean-tree gate captures it.

## Remaining Risk

The three-second interval is derived from virtme-ng 1.40's one-second retry
cadence and the host's prior QMP readiness. Only a real eight-vCPU KVM preflight
can prove that pinning completes before independent verification on this path.
