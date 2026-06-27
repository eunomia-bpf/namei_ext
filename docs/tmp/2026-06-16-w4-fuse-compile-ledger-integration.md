# W4 FUSE Compile Ledger Integration

## Motivation

The W4 ccache workload ledger previously carried a hard missing input for a
complete compile-through-FUSE or native/cache-remap/BuildKit baseline. The
read-oriented FUSE cache-view baseline was not enough because it did not run
ccache with `CCACHE_DIR` served through the FUSE mount.

This step integrates the new KVM-validated FUSE compile baseline into the W4
workload ledger while preserving the negative W4 C2/C8 verdicts.

## Code Paths

- `mk/eval_osdi.mk`
  - Added `EVAL_OSDI_W4_CCACHE_BULK_FUSE_COMPILE_*` inputs.
  - Added the FUSE compile JSONL and input hash to the W4 ledger hash
    manifest.
  - Added the FUSE compile implementation record to the ledger input set.
  - Added a structural check that the generated ledger includes one
    `fuse_redirect_compile` external-baseline row.
- `configs/eval-osdi/w4-ccache-workload-macrobench.jq`
  - Slurps `w4-ccache-bulk-fuse-compile.jsonl`.
  - Requires release samples, complete compile jobs, output matches, ccache log
    cached-result hits, FUSE mounts, and operation-weighted FUSE evidence.
  - Emits a `fuse_redirect_compile` external-baseline row.
  - Converts the compile-through-FUSE missing input from unconditional to
    conditional on the release FUSE compile baseline.

## Design Choices

The FUSE compile row is an external baseline row, not a proposed-system row.
It records compile latency, direct cached-result hits, FUSE mount count,
cache-path file operations, and cache-object operations from raw KVM JSONL.

The W4 summary now treats the full bulk external-baseline input as the
materialized cache baseline, the read-oriented FUSE cache-view baseline, and the
complete compile-through-FUSE baseline. This removes only the missing external
baseline evidence item; it does not override failed setup/update/materialization
thresholds.

## Validation Performed

The release FUSE compile run passed in KVM:

```text
make kvm-w4-ccache-bulk-fuse-compile RUN_ID=20260616T-w4-ccache-bulk-fuse-compile-release-v1 W4_CCACHE_BULK_FUSE_COMPILE_SAMPLES=20
```

The raw summary reported 20 samples, 400 compile jobs, 400 output matches, 400
ccache cached-result hits, 20 FUSE mounts, 6000 cache-path file operations, and
3200 cache-object operations.

The W4 ledger was regenerated with the FUSE compile run:

```text
make eval-osdi-w4-ccache-workload-macrobench-ledger RUN_ID=20260616T-eval-w4-ccache-workload-macrobench-ledger-v7 EVAL_OSDI_W4_CCACHE_RULE_RUN_ID=20260616T-w4-ccache-rule-macrobench-release-v1 EVAL_OSDI_W4_CCACHE_MATERIALIZED_RUN_ID=20260616T-w4-ccache-materialized-baseline-release-v1 EVAL_OSDI_W4_CCACHE_BULK_POLICY_RUN_ID=20260616T-w4-ccache-bulk-policy-compile-smoke-v1 EVAL_OSDI_W4_CCACHE_BULK_POLICY_MACROBENCH_RUN_ID=20260616T-w4-ccache-bulk-policy-macrobench-release-v1 EVAL_OSDI_W4_CCACHE_BULK_MATERIALIZED_RUN_ID=20260616T-w4-ccache-bulk-materialized-release-v1 EVAL_OSDI_W4_CCACHE_BULK_FUSE_RUN_ID=20260616T-w4-ccache-bulk-fuse-baseline-release-v1 EVAL_OSDI_W4_CCACHE_BULK_FUSE_COMPILE_RUN_ID=20260616T-w4-ccache-bulk-fuse-compile-release-v1
```

The first regenerated ledger recorded
`bulk_fuse_compile_baseline_pass=true`,
`bulk_external_baseline_release_input_pass=true`, and removed the unconditional
compile-through-FUSE missing-input entry. A follow-up cleanup removed the stale
global W3 reminder from W4 `missing_inputs` because W3 has its own release
workload macrobench ledger; W4 should report W4 inputs and W4 gates only.

W4 remained negative because setup latency, update latency, rule
materialization, and the bulk comparison gate still failed.

Follow-up v9 refresh:

```text
make eval-osdi-w4-ccache-workload-macrobench-ledger RUN_ID=20260616T-eval-w4-ccache-workload-macrobench-ledger-v9 EVAL_OSDI_W4_CCACHE_RULE_RUN_ID=20260616T-w4-ccache-rule-macrobench-release-v1 EVAL_OSDI_W4_CCACHE_MATERIALIZED_RUN_ID=20260616T-w4-ccache-materialized-baseline-release-v1 EVAL_OSDI_W4_CCACHE_BULK_POLICY_RUN_ID=20260616T-w4-ccache-bulk-policy-compile-smoke-v1 EVAL_OSDI_W4_CCACHE_BULK_POLICY_MACROBENCH_RUN_ID=20260616T-w4-ccache-bulk-policy-macrobench-release-v1 EVAL_OSDI_W4_CCACHE_BULK_MATERIALIZED_RUN_ID=20260616T-w4-ccache-bulk-materialized-release-v1 EVAL_OSDI_W4_CCACHE_BULK_FUSE_RUN_ID=20260616T-w4-ccache-bulk-fuse-baseline-release-v1 EVAL_OSDI_W4_CCACHE_BULK_FUSE_COMPILE_RUN_ID=20260616T-w4-ccache-bulk-fuse-compile-release-v1
```

The v9 ledger is the current canonical W4 workload ledger. It records
`missing_inputs=` and keeps
`bulk_fuse_compile_baseline_pass=true`,
`bulk_external_baseline_release_input_pass=true`,
`bulk_release_comparison_pass=false`, and `release_gate_pass=false`.

Follow-up native refresh:

The v9 ledger was superseded by
`20260616T-eval-w4-ccache-workload-macrobench-ledger-v10` after adding the native
ccache hot-compile baseline. The FUSE compile row remains unchanged and still
passes; v10 additionally records `bulk_native_compile_baseline_pass=true` and
keeps `release_gate_pass=false`.

## Remaining Risks

This ledger integration closes the W4 compile-through-FUSE baseline evidence
gap, but it does not make W4 positive. The remaining W4 problem is comparative:
the proposed policy still loses the setup/update/materialization gates against
the stronger external baselines on this trace shape. Global C2 is now blocked
by negative W1/W3/W4 workload ledger outcomes rather than by a missing W4 FUSE
compile baseline input.
