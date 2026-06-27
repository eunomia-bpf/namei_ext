# OSDI Subagent Review And Native Baseline Revision

Date: 2026-06-16

## Motivation

The active goal requires the evaluation and paper to move toward OSDI weak
accept quality under strict reviewer scrutiny. This turn used the latest
subagent review results to choose the next high-value evidence gap and then
implemented the native ccache baseline integration for W4.

## Review Inputs

Two completed reviewer-style subagent audits agreed that the current paper is
not weak-accept ready:

- The paper-logic review found C1/C8 unclosed, W2 positive evidence too narrow,
  W3 diagnostic evidence mixed with release evidence, and W4 missing
  release-level hit-rate/stale/corrupt/table-budget evidence.
- The OSDI-evaluation audit classified the current evaluation as a technical
  report with OSDI scaffolding, not an OSDI-ready evaluation. It ranked W4/C8
  counterfactuals and external baselines as the highest-risk next area.

A third W4/C8 route scout could not be recovered after context compaction, so
this revision proceeded from the completed audits and local artifact inspection.

## Design Choice

The immediate gap selected was the W4 native ccache hot-compile baseline. FUSE
compile-through and FUSE cache-view inputs were already present, but the W4
claim-level ledger still lacked a native-tool baseline in the same artifact.
Adding this baseline is useful even if it does not make W4 positive, because it
removes one external-baseline objection and makes the remaining negative gates
more precise.

## Implementation Details

- Added W4 native baseline variables to `mk/eval_osdi.mk`.
- Made `eval-osdi-w4-ccache-workload-macrobench-ledger` require
  `EVAL_OSDI_W4_CCACHE_BULK_NATIVE_RUN_ID`.
- Added the native JSONL and input hash to the ledger sha256 manifest.
- Passed the native JSONL into
  `configs/eval-osdi/w4-ccache-workload-macrobench.jq`.
- Added one `external_baseline` row named `native_ccache_hot_compile`.
- Added summary fields for native compile latency, direct hits, cache-path
  operations, cache-object operations, and sampled operation hit rate.
- Updated the Chinese paper to cite the v10 W4 workload ledger and to state that
  native ccache closes an input gap but does not support C2/C8.

## Validation Performed

The native release baseline passed in modified-kernel KVM:

```text
make kvm-w4-ccache-bulk-native-compile \
  RUN_ID=20260616T-w4-ccache-bulk-native-compile-release-v1 \
  W4_CCACHE_BULK_NATIVE_COMPILE_SAMPLES=20
```

The v10 W4 ledger generation passed:

```text
make eval-osdi-w4-ccache-workload-macrobench-ledger \
  RUN_ID=20260616T-eval-w4-ccache-workload-macrobench-ledger-v10 \
  EVAL_OSDI_W4_CCACHE_BULK_NATIVE_RUN_ID=20260616T-w4-ccache-bulk-native-compile-release-v1
```

The v10 summary records `bulk_native_compile_baseline_pass=true`,
`bulk_external_baseline_release_input_pass=true`, `missing_inputs=[]`,
`bulk_release_comparison_pass=false`, and `release_gate_pass=false`.

Additional checks:

- `git diff --check` on the touched files passed.
- `make -C docs/paper check` passed.
- `make -C docs/paper paper` passed.

## Remaining Risks

This revision closes the W4 native external-baseline input gap but does not
change the paper's negative verdict. The next weak-accept blockers remain:

- W4 needs release-level operation-weighted policy hit-rate evidence.
- W4 needs real stale/corrupt/update-window transitions.
- C8 needs a table/update budget counterfactual that fails under release-level
  workload semantics rather than passing sampled oracles.
- C1 needs qualifying family evidence, not only runnable policy fixtures.
