# Result Review: Build/Cache Real Compile Epoch Switch

Date: 2026-07-24
Run ID: `20260724T-epoch-switch-release-v2`
Raw root: `results/phase1/20260724T-epoch-switch-release-v2/`
Plan: `docs/tmp/2026-07-24-build-cache-real-compile-epoch-plan.md`

## Reviewed Artifacts

- `results/phase1/20260724T-epoch-switch-release-v2/w4-ccache-bulk-compile-epoch-switch.jsonl`
- `results/phase1/20260724T-epoch-switch-release-v2/host-make.log`
- `results/phase1/20260724T-epoch-switch-release-v2/host-make.exit`
- `results/phase1/20260724T-epoch-switch-release-v2/dmesg-w4-ccache-bulk-compile-epoch-switch.log`
- `results/phase1/20260724T-epoch-switch-release-v2/w4-ccache-bulk-compile-epoch-switch-inputs.sha256`
- `results/phase1/20260724T-epoch-switch-release-v2/w4-ccache-bulk-compile-epoch-switch-outputs.sha256`

## Verdict

| Field | Judgment |
| --- | --- |
| Run status | valid |
| Tested hypothesis | supported for the planned narrow hypothesis |
| Research value | supporting |
| Paper impact | additional Experiment B RQ evidence and mechanism-boundary evidence |

The run is valid evidence that the Redis/nginx ccache compile oracle passes
across an epoch switch under `namei_ext`, with a matched feature-equivalent FUSE
row. It connects the prior trace-derived state mechanism to real compiler
output. It is not by itself a decisive build/cache result and does not close
miss/stale/corrupt compile cells.

## Checks

- Host command reached terminal success with exit code 0.
- JSONL has 40/40 passing sample rows, one passing summary row, one done row,
  and zero failed rows.
- The dmesg gate found no BUG/WARNING/Oops/panic/hung-task signatures.
- `namei_ext` has 400/400 epoch 1 output matches and 400/400 epoch 2 output
  matches.
- FUSE has 400/400 epoch 1 output matches and 400/400 epoch 2 output matches.
- Both systems show direct cache-hit evidence in both epochs.
- `namei_ext` records 20 policy session updates.
- FUSE records 20 mounts.
- Input hashes verify.
- Output hash manifest contains 3280 entries.

## Required Claim Boundary

- This run supports real compiler-output coverage for the epoch-switch cell.
- This run does not support real compiler-output miss, stale, or corrupt
  rejection claims.
- The FUSE comparison is adequate for feature-equivalent correctness and scoped
  timing observation, not for a broad statement that `namei_ext` is faster than
  all optimized FUSE designs.
- The run validates the selected 20-source Redis/nginx manifest, not every
  build/cache workload.

## Recorded Deviation

The approved plan said the new row should be integrated under
`make experiment-env-cache`. The validated run used the standalone Make target:

```sh
make kvm-w4-ccache-bulk-compile-epoch-switch \
  W4_CCACHE_BULK_COMPILE_EPOCH_SWITCH_SAMPLES=20 \
  RUN_ID=20260724T-epoch-switch-release-v2
```

This deviation does not invalidate the result because the target still runs the
real KVM attach path, depends on the same Redis/nginx ccache trace and policy
bridge, preserves raw artifacts, and runs the matched `namei_ext` and FUSE rows
under the same oracle. It should be folded into `make experiment-env-cache`
before presenting a single integrated build/cache release package.

## Reviewer Summary

A fresh read-only reviewer classified the run as valid, the tested hypothesis as
supported for the planned narrow scope, the research value as supporting, and
the paper impact as additional RQ evidence. The reviewer caveats are preserved
above: standalone-target deviation, timing-ratio scope, FUSE fairness limited to
feature-equivalent correctness, and the selected-manifest boundary.
