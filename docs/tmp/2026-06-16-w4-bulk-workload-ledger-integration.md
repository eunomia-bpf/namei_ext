# W4 bulk workload ledger integration

Date: 2026-06-16

## Motivation

W4 bulk ccache now has three separate KVM evidence roots for the same
20-source/40-object trace shape:

- a policy-attached ccache hot-compile smoke witness;
- a 20-sample materialized cache-view external baseline;
- a 20-sample FUSE cache-view external baseline.

Those raw inputs are useful only if the evaluation ledger can distinguish
their evidence levels. This step integrates them into the existing
`eval-osdi-w4-ccache-workload-macrobench-ledger` target while preserving the
negative verdict: the bulk policy compile is still smoke-level and does not
provide release setup/update rows, while the two bulk baselines are external
baseline release inputs.

## Code paths inspected

- `mk/eval_osdi.mk`
  - W4 ccache workload macrobench target, manifest generation, and summary
    generation.
- `configs/eval-osdi/w4-ccache-workload-macrobench.jq`
  - Existing parent-rule/table/materialized W4 ledger filter.
- Bulk W4 result roots:
  - `results/phase1/20260616T-w4-ccache-bulk-policy-compile-smoke-v1/`
  - `results/phase1/20260616T-w4-ccache-bulk-materialized-release-v1/`
  - `results/phase1/20260616T-w4-ccache-bulk-fuse-baseline-release-v1/`

## Design

The existing W4 ledger target is extended rather than adding a separate
top-level target. The target now requires explicit run IDs for the original W4
rule/materialized runs and the three bulk runs, hashes all inputs, and passes
the bulk JSONL files into the jq filter.

The jq filter emits:

- the existing parent-rule proposed-system row;
- the existing table_redirect internal ablation row;
- the existing non-bulk materialized external baseline row;
- a bulk policy-attached compile row marked `smoke_input_pass`;
- a bulk materialized external baseline row;
- a bulk FUSE cache-view external baseline row;
- one summary row.

The summary intentionally keeps `c2_supported=false` and
`release_gate_pass=false`. It records `bulk_policy_compile_smoke_pass=true`
when the attached compile witness is valid, but also records
`bulk_policy_release_input_pass=false` and `bulk_release_comparison_pass=false`
until a release-level proposed-system setup/update comparison exists.

## Alternatives rejected

- Adding a new top-level W4 bulk ledger target was rejected because it would
  split one workload family across two claim ledgers.
- Treating 20 compile jobs as 20 release samples was rejected because those jobs
  are one attached compile witness, not independent setup/update repetitions.
- Treating the current FUSE cache-view baseline as a full ccache-through-FUSE
  baseline was rejected because the FUSE layer is read-oriented and does not
  implement ccache create/write/rename/unlink behavior.

## Validation plan

1. Run the existing W4 ledger target with all five required W4 run IDs.
2. Check that exactly two proposed-system rows, one table row, two
   materialized rows, one FUSE row, and one summary row are emitted.
3. Check that the summary records the bulk smoke/baseline inputs as present
   while preserving `c2_supported=false`.
4. Run `make -C docs/paper check`.

## Validation performed

Ran:

```text
make eval-osdi-w4-ccache-workload-macrobench-ledger \
  RUN_ID=20260616T-eval-w4-ccache-workload-macrobench-ledger-v5 \
  EVAL_OSDI_W4_CCACHE_RULE_RUN_ID=20260616T-w4-ccache-rule-macrobench-release-v1 \
  EVAL_OSDI_W4_CCACHE_MATERIALIZED_RUN_ID=20260616T-w4-ccache-materialized-baseline-release-v1 \
  EVAL_OSDI_W4_CCACHE_BULK_POLICY_RUN_ID=20260616T-w4-ccache-bulk-policy-compile-smoke-v1 \
  EVAL_OSDI_W4_CCACHE_BULK_MATERIALIZED_RUN_ID=20260616T-w4-ccache-bulk-materialized-release-v1 \
  EVAL_OSDI_W4_CCACHE_BULK_FUSE_RUN_ID=20260616T-w4-ccache-bulk-fuse-baseline-release-v1
```

The target completed successfully and wrote:

- `results/eval-osdi/paper/20260616T-eval-w4-ccache-workload-macrobench-ledger-v5/b3-macrobench/w4-ccache-workload-macrobench.jsonl`
- `results/eval-osdi/paper/20260616T-eval-w4-ccache-workload-macrobench-ledger-v5/b3-macrobench/w4-ccache-workload-macrobench-inputs.sha256`
- `results/eval-osdi/paper/20260616T-eval-w4-ccache-workload-macrobench-ledger-v5/b3-macrobench/w4-ccache-workload-macrobench-summary.md`
- `results/eval-osdi/paper/20260616T-eval-w4-ccache-workload-macrobench-ledger-v5/b3-macrobench/w4-ccache-workload-macrobench-manifest.json`

The ledger emitted six detail rows and one summary object:

- non-bulk `cache_locality_view.bpf.c` proposed-system release row;
- non-bulk `table_redirect` feature-baseline row;
- non-bulk `materialized_cache_view` external-baseline row;
- bulk policy-attached compile smoke row;
- bulk `materialized_cache_view` external-baseline row;
- bulk `fuse_redirect` external-baseline row.

The summary records `bulk_policy_compile_smoke_pass=true`,
`bulk_policy_release_input_pass=false`,
`bulk_materialized_baseline_pass=true`, `bulk_fuse_baseline_pass=true`,
`bulk_external_baseline_release_input_pass=true`,
`bulk_release_comparison_pass=false`, `w4_c2_slice_supported=false`,
`c2_supported=false`, and `release_gate_pass=false`.

It also records the bulk facts used by the next evaluation step:
20 policy-attached compile jobs, 40 redirected cache objects, 400 cache-path
file operations, 160 policy cache-object operations, bulk materialized
setup/update averages of 484.83 ms/3.12 ms, and bulk FUSE cache-view
setup/update averages of 794.16 ms/2.28 ms with one FUSE mount per setup
sample.

`sha256sum -c` passed for all ledger inputs listed in
`w4-ccache-workload-macrobench-inputs.sha256`.

## Remaining risks

- This integration does not create a release-level W4 bulk comparison. It only
  prevents raw bulk evidence from remaining invisible to the claim ledger.
- W4 still needs release proposed-system setup/update repetitions,
  operation-weighted metrics, cache-remap/native ccache or BuildKit baselines,
  complete compile-through-FUSE behavior if FUSE is used as a full tool
  baseline, stale/corrupt/update-window checks, and table-only budget failure
  evidence.

## Update: v6 bulk policy macrobench

A follow-up implementation added
`kvm-w4-ccache-bulk-policy-macrobench`, which runs the proposed-system
`cache_locality_view.bpf.c` setup/update path on the same 20-source/40-object
bulk trace shape. The release run
`20260616T-w4-ccache-bulk-policy-macrobench-release-v1` completed in the
modified-kernel KVM guest with 20 setup rows, 20 update rows, 20 correctness
rows, `policy_executed=true`, and `pass=true`. The compile output oracle remains
in the separate `w4-ccache-bulk-policy-compile-smoke-v1` witness.

The v6 W4 ledger was generated with:

```text
make eval-osdi-w4-ccache-workload-macrobench-ledger \
  RUN_ID=20260616T-eval-w4-ccache-workload-macrobench-ledger-v6 \
  EVAL_OSDI_W4_CCACHE_RULE_RUN_ID=20260616T-w4-ccache-rule-macrobench-release-v1 \
  EVAL_OSDI_W4_CCACHE_MATERIALIZED_RUN_ID=20260616T-w4-ccache-materialized-baseline-release-v1 \
  EVAL_OSDI_W4_CCACHE_BULK_POLICY_RUN_ID=20260616T-w4-ccache-bulk-policy-compile-smoke-v1 \
  EVAL_OSDI_W4_CCACHE_BULK_POLICY_MACROBENCH_RUN_ID=20260616T-w4-ccache-bulk-policy-macrobench-release-v1 \
  EVAL_OSDI_W4_CCACHE_BULK_MATERIALIZED_RUN_ID=20260616T-w4-ccache-bulk-materialized-release-v1 \
  EVAL_OSDI_W4_CCACHE_BULK_FUSE_RUN_ID=20260616T-w4-ccache-bulk-fuse-baseline-release-v1
```

The new artifact root is:

- `results/eval-osdi/paper/20260616T-eval-w4-ccache-workload-macrobench-ledger-v6/b3-macrobench/`

The v6 summary now records `bulk_policy_release_input_pass=true` in addition
to `bulk_policy_compile_smoke_pass=true`, `bulk_materialized_baseline_pass=true`,
`bulk_fuse_baseline_pass=true`, and
`bulk_external_baseline_release_input_pass=true`. The verdict is still
negative: `bulk_release_comparison_pass=false`, `w4_c2_slice_supported=false`,
`c2_supported=false`, and `release_gate_pass=false`. The proposed-system bulk
setup average is 336.19 ms, which is faster than the best external setup
average of 484.83 ms, but the proposed-system bulk update average is 4.99 ms,
which is slower than the best external update average of 2.28 ms. The ledger
also still lacks a complete compile-through-FUSE or native/cache-remap/BuildKit
baseline, so this closes the missing release setup/update input but not the W4
C2 claim.
