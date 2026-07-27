# RQ2 FxMark Real Preflight

## Purpose

The preflight tests the smallest real end-to-end path from matched kernel image
through KVM, tmpfs, cgroup, BPF or FUSE mechanism, official FxMark operation,
raw metric, correctness oracle, and dmesg. It is not a paper result.

## Attempts

### Attempt 1

Run ID: `20260726T-rq2-fxmark-preflight-v1`.

The outer command runner was mistakenly configured with a one-second timeout
and terminated Make before a VM completed boot. Only `command.txt` and
`artifacts.sha256` were created. No observation exists.

### Attempt 2

Run ID: `20260726T-rq2-fxmark-preflight-v2`.

The matched stock VM booted and entered the real guest Make target. The guest's
minimal root did not provide `/mnt`, so `install -d
/mnt/namei-ext-fxmark-rq2` failed before mounting tmpfs or launching FxMark.
No observation exists.

The runner was repaired to use `/tmp/namei-ext-fxmark-rq2`, which vng
explicitly exposes as a writable overlay. No condition, operation, metric,
correctness gate, or interpretation rule changed.

### Attempt 3

Run ID: `20260726T-rq2-fxmark-preflight-v3`.

Command:

```text
make kvm-fxmark-rq2-preflight \
  RUN_ID=20260726T-rq2-fxmark-preflight-v3
```

All five isolated boots completed:

| Condition | Kernel commit | MRPL result | Mechanism evidence |
| --- | --- | ---: | --- |
| stock | `062871f1371b2e02a272ff5279c6479aff0a37ef` | 2.358M ops/s | no policy |
| patched-unattached | `6641100ef13462121bf8d8bea9392d77532c86d5` | 2.130M ops/s | no policy |
| attached `PASS` | patched | 0.763M ops/s | 15,259,260 measured lookups; zero selects |
| attached `SELECT` | patched | 0.762M ops/s | 1,523,684 measured selects for 1,523,684 reported works |
| optimized FUSE | stock | 1.938M ops/s | FUSE mount; 28 setup and 1 measured request |

Each cell used one worker for two measured seconds. Every cell produced exactly
one file and five directories, exited successfully, reported a valid duration,
and passed its mechanism-engagement gate. All five boot dmesg files passed the
declared failure-signature check.

Raw root:

```text
results/experiments/fxmark-rq2-preflight/
  20260726T-rq2-fxmark-preflight-v3/
```

## Interpretation

The preflight establishes executability only. The single short sample suggests
two potentially contradictory effects:

- patched-unattached was about 9.7% below stock;
- optimized cache-hot FUSE was about 2.54 times the `SELECT` throughput.

These are not paper numbers because they come from one two-second boot per
condition. They justify, rather than replace, the fixed ten-block full run.
The plan and hypothesis remain unchanged.

## Full-Run Gate

The real path, baseline path, metric, raw-result path, correctness oracle,
timeout, measured-phase counters, and stock/patched image selection all ran
successfully by the third and final allowed preflight attempt. The experiment
may proceed to the complete matrix.

## Later Validity Correction

The preflight remains evidence that all five real KVM conditions could build,
boot, attach or mount, run FxMark, satisfy their then-current oracles, and
preserve artifacts. It is **not** valid performance evidence for attached
`PASS` or `SELECT`: the first full run showed that their per-component BPF map
lookups and atomic counter updates materially perturbed the measured path.

The corrected implementation removes those policy counters. It verifies the
attached program ID before and after the cell, records and verifies the stopped
FxMark leader's exact cgroup membership before timing, and makes `SELECT`
self-validating through a nonexistent logical path and exact lower-tree
oracle. A fresh full run is required for all performance interpretation.
