# W3/W4 FUSE Baseline Status Audit

## Motivation

After adding W4 compile-through-FUSE baseline support, I rechecked whether the
current paper and claim ledgers still treat FUSE as missing evidence. This is a
Phase 1 research audit, not a new benchmark run.

## Code Paths And Artifacts Inspected

- `results/eval-osdi/paper/20260616T-eval-w3-redis-workload-macrobench-ledger-v2/b3-macrobench/w3-redis-workload-macrobench-summary.md`
- `results/eval-osdi/paper/20260616T-eval-w4-ccache-workload-macrobench-ledger-v9/b3-macrobench/w4-ccache-workload-macrobench-summary.md`
- `results/phase1/20260616T-w4-ccache-bulk-fuse-compile-release-v1/w4-ccache-bulk-fuse-compile.jsonl`
- `docs/paper/main.tex`
- `docs/paper/sections/01-introduction.tex`
- `docs/paper/sections/05-evaluation.tex`
- `docs/paper/sections/07-limitations.tex`
- `docs/tmp/2026-06-16-w4-fuse-compile-ledger-integration.md`

## Findings

W3 is no longer blocked on a same-workload FUSE baseline. The refreshed W3
ledger records `policy_release_input_pass=true`,
`baseline_release_input_pass=true`, `materialized_baseline_pass=true`,
`fuse_baseline_pass=true`, and `storage_footprint_pass=true`. The remaining W3
C2 blocker is threshold failure: policy setup/update averages are
`22.96 ms`/`5.16 s`, while the best external setup/update averages are
`6.52 ms`/`5.15 s`.

W4 is no longer blocked on a complete compile-through-FUSE baseline input. The
W4 v9 ledger records `bulk_fuse_compile_baseline_pass=true`,
`bulk_external_baseline_release_input_pass=true`, and `missing_inputs=`. The
FUSE compile release run records 20 samples, 400 compile jobs, 400 output
matches, 400 ccache direct hits, 20 FUSE mounts, 6000 cache-path file
operations, and 3200 cache-object operations.

W4 remains a negative C2 result. The v9 ledger records
`bulk_release_comparison_pass=false`, `threshold_pass=false`, and
`release_gate_pass=false`. Bulk policy setup is faster than the best external
setup, but bulk policy update is slower than the best external update.

The paper mostly reflected this state, but two version references were stale:
the W3 evidence paragraph pointed at `ledger-v1`, and the W4 bulk policy
paragraph named `v6 ledger` even though the current canonical W4 ledger is v9.

## Edits Made

- Updated `docs/paper/sections/05-evaluation.tex` to point the W3 Redis ledger
  path at `20260616T-eval-w3-redis-workload-macrobench-ledger-v2`.
- Updated the W4 bulk policy paragraph in
  `docs/paper/sections/05-evaluation.tex` to say the v9 ledger computes the
  336.19 ms/4.99 ms setup/update averages.
- Appended a v9 follow-up note to
  `docs/tmp/2026-06-16-w4-fuse-compile-ledger-integration.md`.

## Follow-up Native Baseline Supersession

The W4 v9 ledger was superseded by
`20260616T-eval-w4-ccache-workload-macrobench-ledger-v10` after the native
ccache hot-compile baseline was integrated. The v10 ledger keeps the W3/W4
status conclusion intact: W4 no longer has a FUSE compile input gap or a native
compile input gap, but `release_gate_pass=false` because setup/update and C8
mechanism gates remain negative.

## Validation Performed

Before editing, I checked the W3 and W4 ledger summaries and the W4 FUSE
compile JSONL summary row. I also ran the paper-review mechanical grep set for
`~number`, em dashes, semicolon clause joins, stale figure references,
e.g. punctuation, percentages/rates, and money or magnitude claims. The
mechanical checks found no em dash, semicolon-join, `~number`, stale figure, or
money findings. Rate hits remain expected because W4 explicitly discusses
hit-rate blockers and thresholds.

## Remaining Risks

The FUSE baseline gap is closed for W3 and W4, but the paper is still not a
weak-accept OSDI paper. C2 is supported only for the W2 nginx fixture slice,
and C8 remains unsupported because current W3/W4 table-only comparators still
pass sampled or replay oracles. The next high-value experiment work is to
create release-level table/update budget failures or strengthen W4 real
cache-workload evidence enough to change the C8 and C2 verdicts.
