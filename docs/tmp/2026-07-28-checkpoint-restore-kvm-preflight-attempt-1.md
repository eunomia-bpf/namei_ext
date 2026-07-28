# Checkpoint/Restore KVM Preflight Attempt 1

## Purpose

This record captures the first clean-source modified-kernel preflight for the
DMTCP-derived Checkpoint/Restore and Migration experiment. The run is
dependency evidence, not a formal paper result.

## Run Identity

- Result root:
  `results/experiments/checkpoint-restore-preflight/20260728T232936Z/`
- Main repository commit:
  `1a56580b4edec946598d4bf3eaa28c8bd0e34ca0`
- Kernel commit:
  `bdc9a83e3dfbef8ff2017f9188c7c86025962183`
- Kernel release:
  `7.1.0-rc7-gbdc9a83e3dfb`
- DMTCP commit:
  `068559d9b14c5f96a57869753bba7c066cbf9653`
- DMTCP patch SHA-256:
  `7c945ba6f4bfc375b3c83f5714ed9546660a164a4c9e235999f1e9e55ca3c127`

Both the main repository and kernel source were clean. Kernel construction,
artifact capture, DMTCP install-manifest validation, and guest kernel identity
all passed.

## Failure

The guest failed at DMTCP's official unchanged-mapping `pathvirt` integration
test before the focused three-condition experiment began. Checkpoint completed,
but the restored worker exited with DMTCP assertion code 99. The harness then
timed out waiting for one peer:

```text
pathvirt ckpt:PASSED; rstr:FAILED
worker1=pid:422,state:exited:99
```

The test ran in non-verbose mode, which set `JALIB_STDERR_PATH=/dev/null`.
Consequently, the raw result preserved the worker exit and timeout but not the
specific DMTCP assertion. The failed run is retained with
`run.json.status = "failed"` and was not analyzed or promoted.

## Diagnosis

The modified kernel booted correctly and exposed `namei_ext_lookup`. The
failure was not a source-clean, kernel build, artifact checksum, guest mount, or
KVM launch failure. It occurred inside the upstream DMTCP restart control.

The upstream artifact directory showed:

- one completed checkpoint image;
- a successful original worker;
- a restored worker exiting with assertion code 99;
- an empty coordinator peer set after the exit; and
- a loader warning for `libdmtcp_pathvirt.so`.

The loader warning is not yet established as the assertion cause.

## Repair

The next attempt keeps the upstream control and its oracle unchanged. It runs
the same test with `--verbose` so DMTCP assertion diagnostics are preserved.
On failure, the guest copies the complete upstream harness artifact directory
into the immutable result root before returning failure.

No condition, correctness oracle, timeout, baseline, or claim was weakened.
