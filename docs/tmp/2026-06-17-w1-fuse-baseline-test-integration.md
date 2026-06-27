# W1 FUSE Baseline Test Integration

Date: 2026-06-17

Stage: Phase 1 implementation / W1 feature-baseline evidence hardening

## Motivation

The W1 build workload already had a release baseline run with
`fuse_redirect`, but the raw correctness rows only recorded aggregate replay
booleans. That was enough to see that the baseline passed, but not enough for a
reviewer to audit whether the FUSE path actually mounted the expected alias
parents and preserved materialized/post-update output equivalence.

This step strengthens the W1 FUSE baseline as a test artifact without rerunning
the full five-baseline performance matrix.

## Code Paths

- `tests/w1_oracle/namei_ext_w1_oracle.c`
  - Added alias-parent counting for W1 alias specs.
  - Extended `w1-build-baseline-correctness` rows with:
    `entries`, `visible_aliases`, `alias_parent_dirs`, `fuse_mounts`,
    `baseline_preprocess_pass`, `materialized_output_hash_match`, and
    `post_update_output_hash_match`.
- `mk/kvm.mk`
  - Strengthened `kvm-w1-build-baseline-macrobench` guest-side jq hard gate.
  - When `fuse_redirect` is selected, every FUSE correctness row must have
    alias coverage, matching FUSE mount count, and both materialized and
    post-update output hash oracles.
  - Post-review hardening now also fails the target on dmesg kernel diagnostics
    covered by the Phase 1 `BUG`/`WARNING`/`Oops`/panic awk gate pattern.
- `configs/eval-osdi/w1-build-workload-macrobench.jq`
  - Added a separate FUSE correctness-test input.
  - `fuse_baseline_pass` now requires both the full baseline matrix to include
    `fuse_redirect` and the FUSE test run to pass the new per-row oracle.
- `mk/eval_osdi.mk`
  - Added `EVAL_OSDI_W1_BUILD_FUSE_TEST_RUN_ID` and corresponding JSON/input
    hash variables.
  - Included the FUSE test run and this implementation record in the W1 ledger
    input hash.

## Validation

Smoke KVM run:

```sh
make kvm-w1-build-baseline-macrobench \
  RUN_ID=20260617T-w1-build-fuse-baseline-test-smoke-v1 \
  W1_BUILD_BASELINE_MACROBENCH_SAMPLES=1 \
  W1_BUILD_BASELINES=fuse_redirect
```

The single FUSE correctness row passed with 9 entries, 8 visible aliases, 4
alias parent directories, 4 FUSE mounts, and true materialized/post-update
output hash oracles.

Release FUSE-only KVM run:

```sh
make kvm-w1-build-baseline-macrobench \
  RUN_ID=20260617T-w1-build-fuse-baseline-test-hardgate-release-v1 \
  W1_BUILD_BASELINE_MACROBENCH_SAMPLES=20 \
  W1_BUILD_BASELINES=fuse_redirect
```

The release run produced 20 setup rows, 20 update rows, and 20 correctness rows.
All 20 FUSE correctness rows satisfy the new alias/mount/hash gate. The input
hash file verifies with `sha256sum -c`; the updated target also hard-gates
dmesg diagnostics before emitting the done row.

The refreshed W1 ledger
`20260617T-eval-w1-build-workload-macrobench-ledger-fuse-test-hardgate-v1`
uses this hardgate release run as `fuse_test_run_id`. It preserves the negative
W1 C2 verdict: `w1_c2_slice_supported=false` and `release_gate_pass=false`.

Post-review refresh:

```sh
make kvm-w1-build-baseline-macrobench \
  RUN_ID=20260617T-w1-build-fuse-baseline-test-hardgate-release-v3 \
  W1_BUILD_BASELINE_MACROBENCH_SAMPLES=20 \
  W1_BUILD_BASELINES=fuse_redirect

make eval-osdi-w1-build-workload-macrobench-ledger \
  RUN_ID=20260617T-eval-w1-build-workload-macrobench-ledger-fuse-test-hardgate-v2 \
  EVAL_OSDI_W1_BUILD_POLICY_RUN_ID=20260616T-w1-build-macrobench-release-sample-v1 \
  EVAL_OSDI_W1_BUILD_BASELINE_RUN_ID=20260616T-w1-build-baseline-release-sample-v2 \
  EVAL_OSDI_W1_BUILD_FUSE_TEST_RUN_ID=20260617T-w1-build-fuse-baseline-test-hardgate-release-v3
```

The v3 KVM run uses the current `mk/kvm.mk` dmesg pattern, including
`INFO: task ... blocked for more than` hung-task diagnostics. Its input manifest
verifies with `sha256sum -c`, the dmesg scan is 0, and the 20 FUSE correctness
rows still pass with 8 visible aliases, 4 alias parent directories, 4 FUSE
mounts, and true materialized/post-update hash oracles. The v2 W1 ledger points
to v3 as `fuse_test_run_id` and keeps `w1_c2_slice_supported=false` and
`release_gate_pass=false`.

## Remaining Risks

This step hardens W1 FUSE correctness evidence. It does not change the W1
performance conclusion: the W1 C2 slice remains threshold-negative against the
full feature-baseline matrix. It also does not address the separate W4 C8 gap,
where table-only still passes the current sampled comparator.
