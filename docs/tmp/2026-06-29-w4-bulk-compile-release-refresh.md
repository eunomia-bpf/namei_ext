# W4 bulk ccache compile release refresh

## Motivation

The earlier W4 bulk ccache compile witness was a single-sample smoke run. That was not enough for an OSDI-grade
workload comparison because the proposed system had no release-sample compile-through-policy input, and the native
and FUSE compile baselines were stale. This refresh closes that input gap while preserving the C8 boundary: it proves
that the real ccache hot compile workload can run through the attached policy and through feature-equivalent native
and FUSE compile baselines, but it does not prove that table-only is insufficient under real stale/corrupt/update
conditions.

## Files changed

- `mk/kvm.mk`: `kvm-w4-ccache-bulk-policy-compile` now runs release samples, validates inputs with
  `sha256sum -c`, preserves per-sample stats, hashes all outputs, and emits a
  `w4-ccache-bulk-policy-compile-release-summary` row.
- `configs/eval-osdi/w4-ccache-workload-macrobench.jq`: the W4 ledger now prefers the release summary over the old
  smoke summary and requires release-sample policy compile input.
- `mk/eval_osdi.mk`: the W4 summary markdown prints the new
  `bulk_policy_compile_release_input_pass` field.
- `tests/w1_oracle/namei_ext_w1_oracle.c`: large W4 ccache source/entry arrays in policy/native/FUSE bulk compile
  paths were moved off the stack and zeroed explicitly before each run. The previous native compile attempt crashed
  at function entry due a multi-megabyte stack frame.

## Validation commands

```sh
make w1-oracle
make kvm-w4-ccache-bulk-policy-compile \
  RUN_ID=20260629T-w4-ccache-bulk-policy-compile-release-v1 \
  W4_CCACHE_BULK_POLICY_COMPILE_SAMPLES=20
make kvm-w4-ccache-bulk-native-compile \
  RUN_ID=20260629T-w4-ccache-bulk-native-compile-release-v2 \
  W4_CCACHE_BULK_NATIVE_COMPILE_SAMPLES=20
make kvm-w4-ccache-bulk-fuse-compile \
  RUN_ID=20260629T-w4-ccache-bulk-fuse-compile-release-v2 \
  W4_CCACHE_BULK_FUSE_COMPILE_SAMPLES=20
make eval-osdi-w4-ccache-workload-macrobench-ledger \
  RUN_ID=20260629T-eval-w4-ccache-workload-macrobench-ledger-v10 \
  EVAL_OSDI_W4_CCACHE_RULE_RUN_ID=20260616T-w4-ccache-rule-macrobench-release-v1 \
  EVAL_OSDI_W4_CCACHE_MATERIALIZED_RUN_ID=20260616T-w4-ccache-materialized-baseline-release-v1 \
  EVAL_OSDI_W4_CCACHE_BULK_POLICY_RUN_ID=20260629T-w4-ccache-bulk-policy-compile-release-v1 \
  EVAL_OSDI_W4_CCACHE_BULK_POLICY_MACROBENCH_RUN_ID=20260616T-w4-ccache-bulk-policy-macrobench-release-v1 \
  EVAL_OSDI_W4_CCACHE_BULK_MATERIALIZED_RUN_ID=20260616T-w4-ccache-bulk-materialized-release-v1 \
  EVAL_OSDI_W4_CCACHE_BULK_FUSE_RUN_ID=20260616T-w4-ccache-bulk-fuse-baseline-release-v1 \
  EVAL_OSDI_W4_CCACHE_BULK_FUSE_COMPILE_RUN_ID=20260629T-w4-ccache-bulk-fuse-compile-release-v2 \
  EVAL_OSDI_W4_CCACHE_BULK_NATIVE_RUN_ID=20260629T-w4-ccache-bulk-native-compile-release-v2
```

Input hashes were rechecked for the three compile runs and the final ledger. The dmesg issue scans for policy,
native, and FUSE compile runs all reported zero matching `BUG`, `WARNING`, `Oops`, panic, hung-task, or kernel-BUG
patterns.

## Results

Policy-attached compile:

- result: `results/phase1/20260629T-w4-ccache-bulk-policy-compile-release-v1/w4-ccache-bulk-policy-compile.jsonl`
- `samples=20`
- `compile_rows=20`
- `attached_compile_jobs=400`
- `attached_compile_output_matches=400`
- `policy_executed=true`
- `ccache_compile_policy_executed=true`
- `output_hash_match=true`
- `policy_redirected_cache_objects=800`
- `attached_cache_path_file_ops=8000`
- `attached_policy_cache_object_ops=3200`
- `attached_sampled_operation_hit_rate=0.4`
- `pass=true`
- `failures=0`

Native ccache compile baseline:

- result: `results/phase1/20260629T-w4-ccache-bulk-native-compile-release-v2/w4-ccache-bulk-native-compile.jsonl`
- `samples=20`
- `compile_rows=20`
- `total_compile_jobs=400`
- `total_compile_output_matches=400`
- `compile_ns_avg=7562011642.3500004`
- `cache_path_file_ops=8000`
- `cache_object_ops=3200`
- `direct_cache_hit=400`
- `pass=true`
- `failures=0`

FUSE ccache compile baseline:

- result: `results/phase1/20260629T-w4-ccache-bulk-fuse-compile-release-v2/w4-ccache-bulk-fuse-compile.jsonl`
- `samples=20`
- `compile_rows=20`
- `total_compile_jobs=400`
- `total_compile_output_matches=400`
- `compile_ns_avg=14030225541.1`
- `cache_path_file_ops=6000`
- `cache_object_ops=3200`
- `direct_cache_hit=400`
- `fuse_mounts=20`
- `pass=true`
- `failures=0`

W4 ledger:

- result: `results/eval-osdi/paper/20260629T-eval-w4-ccache-workload-macrobench-ledger-v10/b3-macrobench/w4-ccache-workload-macrobench.jsonl`
- `bulk_policy_compile_release_input_pass=true`
- `bulk_native_compile_baseline_pass=true`
- `bulk_fuse_compile_baseline_pass=true`
- `bulk_external_baseline_release_input_pass=true`
- `bulk_release_comparison_pass=false`
- `w4_c2_slice_supported=false`
- `c2_supported=false`
- `release_gate_pass=false`

## Interpretation

This refresh closes a real W4 workload input gap: all three compile paths now have 20-sample KVM evidence, output-hash
oracles, input hashes, and dmesg checks. It also quantifies a same-workload FUSE compile baseline rather than only a
read-oriented FUSE cache-view baseline.

It does not prove C8. The compile runs exercise hot-cache correctness and operation-weighted cache-path activity, but
they do not inject stale/corrupt cache state, measure stale windows, or force a table-only implementation to update
many exact rows while operations are in flight. The separate W4 cache-epoch counterfactual remains the current targeted
update-budget mechanism evidence; this compile refresh only makes the real ccache workload side of the evaluation more
credible.

## Follow-up result

The follow-up trace-derived cache-epoch counterfactual is recorded in
`docs/tmp/2026-06-29-w4-trace-derived-cache-epoch-counterfactual.md` and
`results/phase1/20260629T-w4-ccache-bulk-cache-epoch-c8-release-v1/w4-ccache-bulk-cache-epoch-counterfactual.jsonl`.
It reuses the Redis/nginx bulk ccache trace-derived object set and reports `real_ccache_trace=true`,
`trace_derived_counterfactual=true`, `table_update_write_ratio=16`,
`materialized_update_write_ratio=16`, and `fuse_update_write_ratio=16`.

That result strengthens the exact-table boundary evidence, but it is still not a live stale/corrupt compile workload.
The C8 release boundary therefore remains unchanged.

## Remaining risk

- The W4 ledger still mixes current compile runs with 2026-06-16 setup/update release inputs. The ledger records input
  hashes and is valid as a derived artifact, but a clean final paper run should refresh all W4 inputs under one run
  family.
- C8 still needs a real ccache or BuildKit dynamic-state run: hit/miss/stale/corrupt/update-epoch branches with a
  correctness oracle, stale-window budget, and exact-table/materialized/FUSE counterfactuals under the same workload.
