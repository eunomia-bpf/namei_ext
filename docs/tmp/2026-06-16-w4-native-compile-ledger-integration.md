# W4 Native Compile Ledger Integration

Date: 2026-06-16

## Motivation

The W4 bulk ccache ledger already integrated materialized cache-view, FUSE
cache-view, and compile-through-FUSE baselines. The remaining external-baseline
gap was a native ccache hot-compile baseline that exercises the same Redis/nginx
source set without `namei_ext` policy attachment. This step promotes the KVM
native baseline from a standalone raw result into the claim-level W4 workload
ledger.

## Code Paths Inspected

- `mk/eval_osdi.mk`
  - `eval-osdi-w4-ccache-workload-macrobench-ledger`
  - W4 ledger input hashing, structural checks, and Markdown summary emission.
- `configs/eval-osdi/w4-ccache-workload-macrobench.jq`
  - W4 bulk release-input gates.
  - External-baseline row generation.
  - Claim-level summary fields and failure strings.
- `results/phase1/20260616T-w4-ccache-bulk-native-compile-release-v1/w4-ccache-bulk-native-compile.jsonl`
  - Native ccache hot-compile release input.

## Design Choices

The ledger now requires `EVAL_OSDI_W4_CCACHE_BULK_NATIVE_RUN_ID` and verifies
both the native JSONL and native input-hash artifact. The native baseline JSONL
and its input hash are included in the ledger sha256 manifest, so the generated
ledger records the exact raw evidence used for the W4 comparison.

The JQ ledger adds an `external_baseline` row named
`native_ccache_hot_compile`. It is classified as
`bulk_external_compile_baseline` because it executes the real ccache compile
path rather than only materializing or exposing a cache view. Its release-input
gate requires:

- KVM release sample budget.
- One compile row per sample.
- 400 total compile jobs for 20 samples and 20 source objects.
- Output hash match for every compile job.
- Direct ccache hits covering all compile jobs.
- `policy_executed=false`.
- `operation_weighted_native_hit_rate_is_release=true`.

The full bulk external-baseline gate now requires materialized cache-view, FUSE
cache-view, compile-through-FUSE, and native hot-compile release inputs. This
keeps the W4 ledger fail-fast: missing native input becomes a failed Make target
or a negative release-input gate, not an informational warning.

## Alternatives Rejected

- Treating native ccache as an optional note in the summary was rejected because
  OSDI-level comparison evidence must be in the same claim-level artifact.
- Folding native ccache into the FUSE compile row was rejected because the two
  baselines exercise different kernel/user-space paths.
- Marking W4 C2/C8 positive after adding native ccache was rejected because the
  current evidence still lacks release stale/corrupt transitions and table/update
  budget failure, and W4 setup/update thresholds remain negative.

## Validation Plan

Regenerate the W4 workload ledger with:

```text
make eval-osdi-w4-ccache-workload-macrobench-ledger \
  RUN_ID=20260616T-eval-w4-ccache-workload-macrobench-ledger-v10 \
  EVAL_OSDI_W4_CCACHE_RULE_RUN_ID=20260616T-w4-ccache-rule-macrobench-release-v1 \
  EVAL_OSDI_W4_CCACHE_MATERIALIZED_RUN_ID=20260616T-w4-ccache-materialized-baseline-release-v1 \
  EVAL_OSDI_W4_CCACHE_BULK_POLICY_RUN_ID=20260616T-w4-ccache-bulk-policy-compile-smoke-v1 \
  EVAL_OSDI_W4_CCACHE_BULK_POLICY_MACROBENCH_RUN_ID=20260616T-w4-ccache-bulk-policy-macrobench-release-v1 \
  EVAL_OSDI_W4_CCACHE_BULK_MATERIALIZED_RUN_ID=20260616T-w4-ccache-bulk-materialized-release-v1 \
  EVAL_OSDI_W4_CCACHE_BULK_FUSE_RUN_ID=20260616T-w4-ccache-bulk-fuse-baseline-release-v1 \
  EVAL_OSDI_W4_CCACHE_BULK_FUSE_COMPILE_RUN_ID=20260616T-w4-ccache-bulk-fuse-compile-release-v1 \
  EVAL_OSDI_W4_CCACHE_BULK_NATIVE_RUN_ID=20260616T-w4-ccache-bulk-native-compile-release-v1
```

Expected validation checks:

- The generated ledger has one `native_ccache_hot_compile` external-baseline
  row.
- `bulk_native_compile_baseline_pass=true`.
- `bulk_external_baseline_release_input_pass=true`.
- `release_gate_pass=false`, because the ledger still should not overclaim W4.

## Validation Performed

The v10 ledger command completed successfully and wrote:

```text
results/eval-osdi/paper/20260616T-eval-w4-ccache-workload-macrobench-ledger-v10/b3-macrobench/w4-ccache-workload-macrobench.jsonl
```

The Make structural check verified exactly one
`native_ccache_hot_compile` external-baseline row. The summary row records
`bulk_native_compile_baseline_pass=true`,
`bulk_external_baseline_release_input_pass=true`, `missing_inputs=[]`,
`bulk_release_comparison_pass=false`, `c2_supported=false`, and
`release_gate_pass=false`.

The native row records 20 samples, 20 compile rows, 400 total compile jobs, 400
output-object matches, 400 direct ccache hits, zero ccache misses, 8000
cache-path file operations, 3200 cache object operations, 0.40 sampled operation
hit rate, and `operation_weighted_native_hit_rate_is_release=true`.

## Remaining Risks

The native baseline closes an external-baseline input gap, not the central W4
C8 mechanism gap. The next W4 steps still need release-level policy hit-rate
evidence, stale/corrupt transitions, and a stronger table/update budget failure
that explains why a table-only or native-cache approach cannot provide the same
semantics.
