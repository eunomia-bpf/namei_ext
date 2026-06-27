# B2/B8 Performance Comparison Verdict

Last updated: 2026-06-15
Stage at update: implementation/execute/gate
Source/command: Descartes subagent review plus local Make targets
Completeness: complete for this implementation step

## Motivation

The previous B2/B8 performance ledger correctly refused to pass the release gate,
but it only recorded input evidence:

- 20-sample KVM microbench rows.
- Tail latency and CI artifacts.
- Randomized microbench run order.
- Before/after system metrics.
- Five external baseline release rows.

That was too weak for an OSDI-style performance claim. A reviewer could still say
the project had input artifacts but no head-to-head verdict. Descartes reviewed
the gate and gave a scoped weak accept for the smoke-vs-release baseline fix, but
a weak reject for B2/B8 overall until a comparison/claim-verdict ledger exists.

## Subagent Review Input

The review identified three concrete issues:

1. B2/B8 still lacked head-to-head comparison and claim verdict.
2. External baseline release qualification did not force a fixed benchmark set;
   it used the observed benchmark names, so a future regression could omit a case
   and still pass if remaining cases had enough rows.
3. The performance row used `result_level:"phase1_kvm_microbench_smoke"` even
   when release-sample input evidence existed.

## Implementation

### Baseline Expected-Set Hardening

`mk/eval_osdi.mk` now defines the fixed external baseline benchmark set:

```text
lookup_native_hot lookup_tool_redirect access_tool_redirect open_tool_redirect
read_tool_content exec_tool_redirect readdir_alias_view build_tree_stat_walk
```

Each `eval-osdi-baseline` row now records:

- `expected_bench_cases`
- `expected_bench_case_count`
- `bench_cases_observed`
- `latency_bench_cases_observed`
- `missing_bench_cases`
- `missing_latency_bench_cases`
- `has_expected_bench_set`
- `has_expected_latency_bench_set`

Baseline smoke qualification requires the expected aggregate benchmark set.
Baseline release qualification additionally requires the expected latency set and
the release sample budget for every expected case.

### Result-Level Clarification

The B2/B8 input row result level changed from:

```text
phase1_kvm_microbench_smoke
```

to:

```text
release_input_evidence_no_claim_verdict
```

This prevents release-scale input artifacts from being confused with a supported
performance claim.

### Comparison Target

Added:

```text
make eval-osdi-performance-comparison
```

The target depends on `eval-osdi-performance-ledger`, then writes:

- `external-baseline-latency-tail.jsonl`
- `performance-comparison.jsonl`
- `performance-comparison-inputs.sha256`
- `performance-comparison-manifest.json`
- `performance-comparison-summary.md`

The target computes p50/p95/p99 and CI for external baseline latency rows and
then compares the 7 shared internal/external benchmark cases:

```text
lookup_native_hot lookup_tool_redirect access_tool_redirect open_tool_redirect
exec_tool_redirect readdir_alias_view build_tree_stat_walk
```

The non-shared external-only case is `read_tool_content`; it remains part of
external baseline feature-equivalence and update-content checking, but not the
internal/external p99 comparison.

For each shared case the target computes:

- `policy_to_native_p99_ratio`
- `policy_to_fuse_p99_speedup`
- `pass_only_to_native_p99_ratio`
- `policy_to_pass_only_p99_ratio`
- `policy_to_table_hit_p99_ratio`

The threshold verdict uses the committed OSDI evaluation thresholds:

- `policy/native p99 <= 1.5x`
- `policy/FUSE p99 speedup >= 2x`
- `pass_only/native p99 <= 1.1x`

`eval-osdi-performance` now hard-gates on
`performance-comparison.jsonl`, not on the older input-only ledger.

## Validation

### Comparison Pilot

Command:

```text
make eval-osdi-performance-comparison \
  RUN_ID=20260615T-eval-comparison-pilot-v1 \
  EVAL_OSDI_PHASE1_RUN_ID=20260615T-kvm-bench-release-sample-pilot \
  EVAL_OSDI_PERFORMANCE_BASELINE_RUN_ID=20260615T-kvm-external-baselines-release-pilot
```

Result:

- `results/eval-osdi/paper/20260615T-eval-comparison-pilot-v1/b2-performance/performance-comparison.jsonl`
- `input_gate_pass=true`
- `comparison_rows_complete=true`
- `has_internal_release_samples=true`
- `has_internal_ci=true`
- `has_randomized_order=true`
- `has_system_metrics=true`
- `baseline_release_gate_pass=true`
- `has_external_tail=true`
- `has_external_ci=true`
- `has_external_release_samples=true`

The threshold verdict is negative:

- `kernel_p99_threshold_pass=false`
- `fuse_speedup_threshold_pass=false`
- `pass_only_threshold_pass=false`
- `max_policy_to_native_p99_ratio=8.179414951245938`
- `min_policy_to_fuse_p99_speedup=1.448044680537433`
- `max_pass_only_to_native_p99_ratio=4.364632237871675`
- `c2_supported=false`
- `c3_supported=false`
- `c5_supported=false`
- `release_gate_pass=false`

### Hard Gate Expected Failure

Command:

```text
if make eval-osdi-performance \
  RUN_ID=20260615T-eval-comparison-hardgate-v1 \
  EVAL_OSDI_PHASE1_RUN_ID=20260615T-kvm-bench-release-sample-pilot \
  EVAL_OSDI_PERFORMANCE_BASELINE_RUN_ID=20260615T-kvm-external-baselines-release-pilot; \
then exit 1; else exit 0; fi
```

Result: wrapper exited 0 because the inner `make eval-osdi-performance`
failed as expected on the negative comparison verdict.

### Baseline Expected-Set Smoke

Command:

```text
make eval-osdi-baselines \
  RUN_ID=20260615T-kvm-external-baselines-expected-set-smoke-v1 \
  BASELINE_SAMPLES=1 \
  BASELINE_ITERS=50 \
  BASELINE_LATENCY_SAMPLES=1 \
  BASELINE_LATENCY_BATCH=2
```

Result:

- `baseline_smoke_gate_pass=true`
- `baseline_release_gate_pass=false`
- all five baselines have `has_expected_bench_set=true`
- all five baselines have `has_expected_latency_bench_set=true`
- all five baselines have empty `missing_bench_cases`
- all five baselines have empty `missing_latency_bench_cases`
- per-case rows are 1, so no row can pass release qualification

## Current Interpretation

This implementation improves the gate in two ways:

1. It prevents missing-case external baseline runs from passing release
   qualification.
2. It turns release input evidence into a falsifiable C2/C3/C5 verdict.

The verdict is currently negative. This is not a test infrastructure failure.
It means the current prototype and benchmark configuration do not support the
paper's performance/mechanism claims under the committed thresholds.

## Remaining Risks

- C2 remains unsupported because there is no `namei_ext` release macrobench
  setup/storage/update comparison against materialization baselines.
- C3 remains unsupported because several policy p99 ratios exceed the 1.5x
  native threshold, and `exec_tool_redirect` does not reach the 2x FUSE speedup
  threshold.
- C5 remains unsupported because pass-only/native p99 overhead is too high to
  attribute performance to the redirect logic or lower-filesystem ownership.
- External baseline runner still lacks randomized baseline/case order and its
  own before/after system metrics. It is acceptable as an input gate, but not
  yet a final fairness story.
- Main repo and kernel repo remain dirty, so none of these pilots are final
  artifact evidence.
