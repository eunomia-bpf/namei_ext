# FxMark Fast-Path Preflight v1 Failure

## Attempt

Command:

```text
make kvm-fxmark-fast-path-preflight \
  RUN_ID=20260728T-fxmark-fast-path-preflight-v1
```

Result root:
`results/experiments/fxmark-fast-path-preflight/20260728T-fxmark-fast-path-preflight-v1/`.

The run failed during the first, stock-kernel boot. The runner stopped
immediately and did not launch the patched condition or analyze the partial
result.

## Evidence

The QMP verifier succeeded before the guest failure. Its record shows the exact
requested mapping:

```text
vCPU0 -> host CPU 4
vCPU1 -> host CPU 5
vCPU2 -> host CPU 6
vCPU3 -> host CPU 7
```

The guest crossed the affinity barrier and then failed at the first direct BPF
inventory command. `launcher.stderr.log` reports that the invoked `bpftool` was
the distribution wrapper, which searched for a package matching guest release
`7.1.0-rc7` and exited because that package is not installed. The redirected
`bpf-programs-before.json` is empty because the wrapper failed before producing
JSON.

## Root Cause

The implementation invoked `bpftool` through the guest `PATH`. The host shell
resolves `/usr/local/sbin/bpftool`, a real ELF binary, while the guest login
environment resolves `/usr/sbin/bpftool`, a release-selecting wrapper. The
preflight therefore depended on environment-specific command resolution
instead of the frozen runtime artifact set.

## Repair

The real `/usr/local/sbin/bpftool` binary is now copied into each FxMark result
root under `artifacts/runtime/bpftool`, included in the artifact manifest and
hashes, passed explicitly through `guest.mk`, and invoked by path. Existing
fail-fast inventory checks remain unchanged.

The failed v1 root remains preserved. The repair requires a fresh commit and a
new v2 preflight result root; v1 is not resumed or overwritten.
