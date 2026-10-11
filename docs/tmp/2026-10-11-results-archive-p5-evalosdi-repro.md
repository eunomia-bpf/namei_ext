## Eval-OSDI baseline/paper report runs, 2026-06-30..07-03 workload reproductions, trajectory probe

Slice `p5-evalosdi-repro`: 190 untracked units = `results/eval-osdi/baselines/` (19),
`results/eval-osdi/paper/` (166), `results/reproduction/` (4), `results/research-probes/` (1).
Per-unit rows are in `p5-evalosdi-repro.csv` (190 rows, one per unit).

### Provenance common to all `results/eval-osdi/` units

- Producer: `mk/eval_osdi.mk` (targets `eval-osdi-*`) plus `kvm-eval-osdi-baselines` in `mk/kvm.mk`.
  The runs were made on 2026-06-15..06-17 (one on 06-29/30) from an uncommitted working tree:
  every manifest that records repo state says main `6fe308aa` (dirty) and kernel `31a33d22`
  (dirty); `mk/eval_osdi.mk` first entered git in `5c0b1f9` (2026-06-27) and was deleted with the
  whole C1-C8 claim-verdict machinery in `0f6b731` (2026-07-25, rationale in
  `docs/tmp/2026-07-25-repository-cleanup-claim-gate-rescope.md`). The plan these runs served is
  archived as `docs/tmp/2026-07-12-archived-osdi-evaluation-plan.md` ("historical provenance only")
  and `docs/tmp/2026-07-25-archived-process-docs/evaluation.md`.
- Naming: `*-ledger*` / plain run ids came from the non-failing ledger target; `*-hardgate*` ids
  came from the matching hard-gate target (`eval-osdi-performance`, `eval-osdi-policy-family`,
  `eval-osdi-w1-build-workload-macrobench`, ...), which re-runs the same ledger and then exits
  non-zero when the gate is false. Hard-gate dirs therefore hold the same report as the ledger
  dir; W1/W4 hard-gate dirs also hold `*-hardgate-status.json` with `status=4, pass=false`.
- Gate thresholds in `mk/eval_osdi.mk` (git `0f6b731^`): 20 paper samples, latency batch >= 64,
  policy p99 <= 1.50x native, policy p99 >= 2.00x faster than FUSE, pass-only p99 <= 1.10x native.
- Citations: no tracked paper section (`docs/paper/sections/*.tex`, last changed 2026-08-02) cites
  any unit in this slice. The only paper that did is the 2026-06-17 snapshot *inside*
  `20260617T-eval-c7-artifact-audit-v{5..11}/artifact-audit/package-root/docs/paper/` (untracked
  payload, includes `main.pdf`), whose `05-evaluation.tex` cites the final-round runs:
  claim-verdict v17, c7 v11, c3 v3, c4 v4, c5 v2, tool-redirect-scope v7, W1 fuse-test-hardgate v7,
  W2 hardgate v11, W2 tool-redirect paper-release v6, W3 ledger v7, W4 ledger v15.
- Consistency: every tracked `docs/tmp` number spot-checked below agrees with the raw report
  files. No disagreement was found anywhere in this slice.

### 1. KVM external baselines (`results/eval-osdi/baselines/`, 19 units)

Why: OSDI evaluation needed copy/symlink/bind/OverlayFS/FUSE baselines measured in the same KVM
guest as the namei_ext microbenchmarks (`docs/tmp/2026-06-15-eval-osdi-external-baselines-implementation.md`,
`...-fuse-baseline-implementation.md`, `...-baseline-release-gate.md`, `...-batch64-release-run.md`).
Producer `make eval-osdi-baselines` (or `kvm-eval-osdi-baselines` for raw-only runs). Each run: 64-file
tree, 8 benches (lookup_native_hot, lookup/access/open/exec_tool_redirect, read_tool_content,
readdir_alias_view, build_tree_stat_walk), setup/update/cleanup timing per baseline.

| Run | Config (samples/iters/lat_samples/batch) | Status / outcome |
| --- | --- | --- |
| baseline-dryrun, kvm-external-baselines-smoke | 1/20 or 1/50, 4 baselines | failed: overlayfs setup errno=22 (`summary pass=false`, failures=1) |
| kvm-overlayfs-diagnose | overlay only, 1/10 | failed: errno=22; doc: dmesg "upperdir not supported" |
| kvm-overlayfs-tmpfs | overlay only, 1/10 | pass after moving scratch root to guest tmpfs (raw only, no ledger) |
| smoke-v2, smoke-v3 | 1/50/1/2, 4 baselines | incomplete: guest raw pass (0 failures) but `baseline-ledger.jsonl.tmp` is 0 bytes, no summary; uncited |
| smoke-v4, content-v1 | 1/50/1/2, 4 baselines | pass smoke; release gate false (1 sample) |
| fuse-smoke-v1 | 1/50/1/2, 5 baselines | failed: fuse_redirect setup errno=5 (guest kernel had no CONFIG_FUSE_FS) |
| fuse-smoke-v2, ledger-schema-smoke-v1, expected-set-smoke-v1 | 1/50/1/2, 5 | pass smoke; release false |
| unique-sample-smoke-v1 | 1/50/1/4, 5 | pass smoke; release false, `unique_sample_budget_pass=false` (intended) |
| release-pilot | 20/500/1/4, 5 | pass smoke+release; later rejected by the batch>=64 rule |
| batch64-v1, rcu-pass-batch64-v1, rcu-redirect-unlazy-batch64-v1, ctx-init-split-batch64-v1 | 20/500/1/64, 5 | pass smoke+release+unique budget; 800 bench + 800 latency rows each |
| ctx-init-split-tail10-v1 | 20/500/10/64, 5 | pass; 800 bench + 8000 latency rows |

Setup / update cost (ms / us) from the release runs (same tree, varies run to run):

| Run | copy | symlink | bind | overlay | fuse |
| --- | --- | --- | --- | --- | --- |
| release-pilot | 0.52 / 7.6 | 0.30 / 2.3 | 0.42 / 2.3 | 0.46 / 5.0 | 51.21 / 10.2 |
| batch64-v1 | 0.70 / 9.2 | 0.49 / 5.4 | 0.48 / 4.0 | 0.77 / 11.7 | 51.28 / 27.0 |
| ctx-init-split-tail10-v1 | 0.83 / 13.3 | 0.34 / 2.5 | 0.66 / 5.5 | 0.51 / 5.7 | 51.36 / 21.7 |

Median throughput-loop cost per op (ns) in `batch64-v1` (the baseline set behind the batch64
verdict; release-pilot and tail10 runs are within ~10% except exec, which varies 58-150 us):

| Baseline | lookup_native_hot | lookup_redirect | access_redirect | open_redirect | read_content | exec_redirect | readdir_alias | stat_walk |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| copy_tree | 250 | 254 | 211 | 331 | 439 | 96463 | 244 | 402 |
| symlink_forest | 252 | 383 | 358 | 472 | 579 | 104565 | 238 | 612 |
| bind_mount | 342 | 340 | 222 | 349 | 475 | 103977 | 321 | 580 |
| overlayfs | 285 | 283 | 243 | 518 | 650 | 115174 | 364 | 465 |
| fuse_redirect | 15494 | 15345 | 15309 | 21315 | 26607 | 141102 | 5206 | 44953 |

Tracked summaries: the docs above restate the same failures (errno 22 / FUSE missing) and gates
(`baselines_release_passed=5` for release-pilot, `=0` for ledger-schema smoke,
`unique_sample_budget_pass=false`); raw data agree. dryrun, smoke, smoke-v2, smoke-v3 are uncited.

### 2. B12 policy-family ledger and early "contract" runs (9 units)

Why: B12 asked whether each of the four policy families (build_graph, sandbox_fixture,
checkpoint_restore, cache_locality) had two qualifying workload rows with release metric and
table counterfactual (C1/C8). `eval-contract*` (06-15 11:08-11:42) were the first B12+B2 contract
runs on phase1 `20260615T-full-phase1-gatefix` / `-bench-variants`; `b12-refresh` (input
`20260615T-full-phase1-b12-refresh-v1`) and `b12-c2-setup-update` (input
`20260615T-full-phase1-c2-setup-update-v1`) refreshed it.

All 9: `qualified_families=0/4`, `release_gate_pass=false`, `c1_supported=false`,
`c8_supported=false`; observed rows build_graph=2, sandbox=1, checkpoint=1, cache=2, all
`semantic=true, release_metric=false, table_counterfactual=false`. The b12 refresh adds the blocker
text "Redis table-only replay passes = C8 negative evidence; W4 table comparator passes = C8
negative evidence". Contract B2 parts: 1 sample of 20, no external baselines/tail/order/metrics.
Tracked: `docs/tmp/2026-06-15-full-phase1-b12-refresh-run.md`,
`...-namei-ext-setup-update-raw-rows.md`, `...-eval-osdi-policy-family-gate-implementation.md`,
`...-eval-osdi-performance-gate-implementation.md` (all say `qualified_families=0`, hard gate
fails as expected) - agree.

### 3. B2 performance-ledger development (21 units, 2026-06-15)

Why: incremental build-out of the B2/B8 performance ledger (`eval-osdi-performance-ledger`,
`eval-osdi-performance-tail`): latency rows, tail/CI artifact, external baselines, randomized order
and system metrics, release sample budget (docs `2026-06-15-kvm-bench-latency-sampling.md`,
`...-eval-osdi-tail-latency-artifact.md`, `...-run-order-system-metrics-implementation.md`,
`...-release-sample-pilot.md`, `...-baseline-release-gate.md`). Every ledger run has
`release_gate_pass=false`; the point of each was which "missing evidence" flags flipped.

| Runs (input phase1) | samples | tail rows / min per group | missing after run |
| --- | --- | --- | --- |
| ledger-after-latency-code, -p2fix (bench-variants) | 1 | 0 | 5 baselines, tail, order, metrics |
| ledger-tail-artifact(+hardgate) (bench-variants) | 1 | 0 | same; tail artifact still false |
| tail-artifact-pilot (kvm-bench-latency-pilot) | - | 70 / 2 | tail ok, below 20-sample budget |
| ledger-with-baselines-smoke(+hardgate), content-baselines(+hardgate) | 1 | 0 | fuse_redirect, tail, order, metrics |
| ledger-fuse-baselines-smoke/-hardgate, order-metrics-compat | 1 | 0 | tail, release samples, order, metrics |
| ledger-order-metrics-pilot (v2 input) | - | 70 / 2 | incomplete: only tail files, no ledger summary |
| ledger-order-metrics-pilot-v2, -hardgate-pilot (order-metrics-pilot-v3) | 1 | 70 / 2 | release sample budget only |
| ledger-release-sample-pilot/-hardgate, release-baselines-pilot/-hardgate (kvm-bench-release-sample-pilot) | 20 | 700 / 20 | nothing; gate still false pending comparison verdict |
| tail-incomplete-negative | synthetic `/tmp` input, 69/70 rows | - | negative test: `has_tail_latency_artifact=false` (intended) |
| eval-latency-pilot | - | - | empty dir (0 files) |

Tracked docs cite 17 of 21 (uncited: order-metrics-compat, order-metrics-pilot, tail-incomplete-negative,
eval-latency-pilot); gate flags agree with the docs.

### 4. B2/B8 performance comparison verdicts (18 units)

Why: head-to-head p99 verdict of namei_ext policy vs native, pass-only vs native, and policy vs
FUSE (`eval-osdi-performance-comparison`; docs `2026-06-15-eval-osdi-performance-comparison-verdict.md`,
`...-latency-batch-gate.md`, `...-batch64-release-run.md`, `...-ctx-init-split-poc-implementation.md`,
`...-rcu-pass-fastpath-negative-result.md`, `...-tail-sample-density-diagnostic.md`). Seven bench rows
each (read_tool_content excluded). All 18 have `c2/c3/c5_supported=false`, `release_gate_pass=false`.

| Run(s) | Internal / external input | Verdict | max pol/native p99 | min pol/FUSE | max passonly/native | kernel / fuse / passonly pass |
| --- | --- | --- | --- | --- | --- | --- |
| comparison-pilot-v1, -hardgate-v1 | kvm-bench-release-sample-pilot / release-pilot | unsupported_by_thresholds | 8.18x | 1.45x | 4.36x | 3/7, 6/7, 0/7 |
| latency-batch-gate-v1, -hardgate-v1, -v2 | same inputs, batch>=64 rule added | blocked_by_missing_inputs | 8.18x | 1.45x | 4.36x | (input gate false) |
| batch64-v1, -hardgate-v1 | kvm-bench-release-batch64-v1 / batch64-v1 | unsupported | 1.77x | 1.33x | 1.71x | 5/7, 6/7, 1/7 |
| rcu-pass-batch64-v1 | rcu-pass PoC | unsupported | 2.49x | 1.62x | 1.48x | 3/7, 6/7, 2/7 |
| rcu-redirect-unlazy-batch64-v1 | rcu redirect-unlazy PoC | unsupported | 2.43x | 1.70x | 1.38x | 5/7, 6/7, 4/7 |
| ctx-init-split-batch64-v1, -hardgate-v1 | ctx-init-split PoC, batch64 | unsupported | 1.81x | 1.64x | 1.09x | 6/7, 6/7, 7/7 |
| ctx-init-split-tail10-v1, -hardgate-v1, 20260617T -hardgate-v2..v6 | ctx-init-split, 10 latency samples (7000 tail rows) | unsupported | 4.37x | 2.26x | 2.62x | 4/7, 7/7, 1/7 |

Per-bench detail of the final tail10 input (identical in all 7 tail10 dirs): policy/native p99
lookup_native_hot 1.53, lookup_redirect 1.09, access 1.08, open 1.34, exec 0.86, readdir_alias 4.37
(p99/p95 = 3.12, tail outlier), build_tree_stat_walk 1.75; policy/FUSE speedup 51.1, 46.3, 50.1,
39.9, 2.26, 7.35, 99.0. Tracked docs restate the headline ratios (1.77/1.33/1.71, 8.18/1.45/4.36,
2.49/1.62/1.48, 2.43/1.70/1.38, 1.81/1.64/1.09, 4.37/2.26/2.62) verbatim - agree.
`20260615T-...-tail10-hardgate-v1` was regenerated in place on 06-17 10:31 (manifest time) and the
five `20260617T` tail10 dirs are refresh-round re-runs with identical inputs (see section 10).

### 5. C5 pass-only residual: tail10 inputs and ablation (5 units)

`eval-rusage-tail10-v1` (7000 tail rows, 35 groups, >=200 rows/group),
`eval-nohook-baseline-tail10-v1` (1400 rows, 7 groups), `eval-baseline-passonly-tail10-v1`
(2800 rows, 14 groups): all complete tail artifacts (batch 64, 20 samples, CI present).
`20260617T-eval-c5-rusage-nohook-ablation-v1/-v2` (identical): `c5_supported=false`;
max matched pass-only/native p99 1.32 (open_tool_redirect), max full-run pass-only/native 1.77
(build_tree_stat_walk), max full pass-only/no-hook 1.31 (access); matched failures access, lookup_native_hot,
open; full-run failures 6/7; pass-only CPU 274-675 ns/op (exec 22.6 us), ctx switches ~0 except exec
(1.0/op). Tracked `docs/tmp/2026-06-15-rusage-nohook-tail-diagnostic.md` and
`2026-06-17-c5-rusage-nohook-ablation-ledger.md:100-102` restate the three maxima verbatim - agree.
Result: C5 (VFS-placement residual) negative and later scoped out.

### 6. C3 residual diagnostic and tool-redirect scope (10 units)

- `c3-full-suite-residual-diagnostic-v1/v2` (source tail10-hardgate-v4) and `-v3` (source v5):
  identical; `full_suite_c3_supported=false`, `fuse_baseline_threshold_pass=true`; failed kernel
  benches lookup_native_hot (near threshold, 1.53x), readdir_alias_view (p99 tail outlier 4.37x),
  build_tree_stat_walk (common hook residual, pass-only 2.62x); 6/7 benches fail pass-only.
  Tracked `docs/tmp/2026-06-17-c3-full-suite-residual-diagnostic.md:101-103` (1.526x, 4.374x, 3.116x, 2.624x) - agrees.
- `performance-tool-redirect-scope-v1..v7` (sources tail10-hardgate-v1..v6): identical;
  `scoped_c3_supported=true` for lookup/access/open/exec_tool_redirect, max scoped policy/native
  p99 1.338x, min scoped FUSE speedup 2.258x; full suite still false. Tracked
  `docs/tmp/2026-06-17-tool-redirect-performance-scope-ledger.md:80-81` restates both verbatim - agrees.

### 7. C2 setup/update macrobench ledgers (7 units, 2026-06-16 00:48-01:27)

| Run(s) | Input | namei_ext setup / src update / policy update | Verdict |
| --- | --- | --- | --- |
| c2-macrobench-ledger-v1, -hardgate-v1, -ledger-unique-sample-compat-v1 | full-phase1-c2-setup-update-v1 (1 sample) + baselines batch64-v1 | 695.2 / 142.5 / 152.7 us | blocked_by_missing_inputs (namei_ext 1 sample < 20) |
| c2-release-sample-ledger-v1, -hardgate-v1 | full-phase1-c2-release-sample-v1 (20 samples) | 528.4 / 101.9 / 92.4 us | blocked_by_missing_thresholds (no workload-equivalent macrobench / thresholds) |
| c2-workload-derived-ledger-v1, -hardgate-v1 | c2-release-sample-v1 | - | derived_contract_only: 8 workload rows, 5 correctness oracles + KVM policy rows, 0 C2-eligible |

Baseline/namei setup ratios in the release-sample ledger: copy 1.33, symlink 0.93, bind 0.90,
overlay 1.46, fuse 97.0 (update ratios 0.04-0.26, i.e. baselines update faster on this synthetic
tree). Tracked `docs/tmp/2026-06-15-c2-*` docs restate verdict strings and 5/8 oracle counts - agree.

### 8. Workload macrobench ledgers W1-W4 and the W2 + tool-redirect paper-release gate (64 units)

All W1-W4 ledgers have `c2_supported=false` and `release_gate_pass=false` (global C2 needs all four
slices). Versions mostly add baselines; numeric results only change when the input run changes.

**W1 build graph (17 units; docs `2026-06-16-w1-build-workload-ledger-*`, `...-w1-build-projected-fuse-baseline-implementation.md`, `2026-06-17-w1-fuse-baseline-test-integration.md`).**
Policy input `20260616T-w1-build-macrobench-release-sample-v1` (later `20260617T-...-v2`).

| Runs | Baseline input | Feature baselines | policy vs best baseline setup | update | setup bytes |
| --- | --- | --- | --- | --- | --- |
| ledger-smoke-v1..v3, hardgate-smoke-v1 | w1-build-baseline-smoke-v2 | copy/symlink/bind only; baseline release input false | 66.1 vs 13.4 ms | 52.4 vs 37.5 ms | 457356 vs 69298 |
| ledger-release-v1, hardgate-release-v1 | ...release-sample-v1 | no projected/FUSE | 66.1 vs 18.3 ms | 52.4 vs 40.2 ms | same |
| ledger-release-v2, hardgate-release-v2, fuse-test-v1/v2, fuse-test-hardgate-v1..v3 | ...release-sample-v2 | all 5 incl. projected + FUSE (20 FUSE correctness rows) | 66.1 vs 17.3 ms | 52.4 vs 37.5 ms | same |
| fuse-test-hardgate-v4..v7 | 20260617T policy v2 / baseline v3 | all 5 | 65.3 vs 16.5 ms | 52.1 vs 40.4 ms | same |

Every run fails storage, setup, update and update-materialization thresholds
(`w1_c2_slice_supported=false`; the hardgate-release dirs record make exit status 4). Docs restate 66090011.6/18326753.1/52416038.25/
40165924.95 and 17324797.3/37528990.95 verbatim - agree.

**W2 nginx fixture (16 units; docs `2026-06-16-w2-nginx-*`).** Policy input
`20260615T-w2-nginx-c2-macrobench-release-sample-v1`; ledger/hardgate v1-v4 add bind, projected-volume
and FUSE baselines (baseline inputs `...baseline-macrobench-release-sample-v1..v4`); v5 adds storage and
threshold aggregation: `w2_c2_slice_supported=true` - policy setup 7.50 ms vs best baseline 9.96 ms,
update 13.9 us vs 14.0 us, 17 vs 19 setup objects, equal bytes (5931). Hardgate v5 (regenerated 06-17
10:30) through v11 are identical refreshes. `docs/tmp/2026-06-16-w2-nginx-storage-threshold-implementation.md`
restates 7500337.5/9959036.45/13914.8/14044.7 - agrees.

**W2 + tool-redirect paper-release gate (6 units, `eval-osdi-w2-tool-redirect-paper-release-gate`).**
v1..v6 (W2 hardgate v6..v11 + scope v2..v7 + trace `20260617T-w2-nginx-real-trace-release-v1`): all
`paper_release_gate_pass=true`, scope `w2_nginx_fixture_plus_tool_redirect_metadata`, real-trace
gate, no-real-production-open, endpoint health, W2 thresholds and scoped p99/FUSE thresholds true;
declared boundaries: not global C2, not full-suite C3, not release-wide C4, not C8. Tracked
`docs/tmp/2026-06-17-w2-nginx-real-trace-gate.md` - agrees.

**W3 redis checkpoint (7 units; doc `2026-06-16-w3-redis-policy-fuse-macrobench-implementation.md`).**
Inputs `20260616T-w3-redis-macrobench-release-v1` (policy and baselines). Materialized and FUSE
baselines pass; policy setup 22.96 ms vs best baseline 6.52 ms (fails), update 5157.9 ms vs
5154.5 ms (fails threshold); `w3_c2_slice_supported=false`. v2..v7 are identical refreshes. Doc says
"policy setup around 22 ms, materialized around 7 ms" - agrees.

**W4 ccache cache-locality (18 units; docs `2026-06-16-w4-*`, `2026-06-29-w4-bulk-compile-release-refresh.md`).**

| Runs | Added input | Key numbers |
| --- | --- | --- |
| ledger-v1, hardgate-v1 | rule macrobench release-v1 vs table baseline | setup 110.5 vs 104.1 ms, update 6.52 vs 6.31 ms; storage + rule-materialization pass, latency thresholds fail |
| ledger-v2, hardgate-v2 | materialized external baseline | materialized setup 58.0 ms, update 3.82 ms; storage/rule thresholds now fail too |
| ledger-v3..v5 | bulk materialized/FUSE baselines + policy compile smoke (20 jobs) | bulk materialized setup 484.8 ms, FUSE setup 794.2 ms; bulk policy release input false |
| ledger-v6 | bulk policy macrobench release | bulk policy release input true; comparison still false |
| ledger-v7..v9 | bulk FUSE compile baseline | FUSE compile 9.68 s, 400 direct cache hits |
| 20260616T ledger-v10, 20260617T v11..v15 | native ccache compile baseline | native compile 5.06 s; sampled op hit rate 0.40 |
| 20260629T ledger-v10 | release-sample compile runs (policy 400 jobs, FUSE v2, native v2) | FUSE compile 14.03 s, native 7.56 s, `bulk_policy_compile_release_input_pass=true`, `bulk_release_comparison_pass=false` |

All: `w4_c2_slice_supported=false`. Docs restate 110545949.3/104058982.65, 7562011642.35 and
14030225541.1 - agree. `20260629T...-v10` is cited by `docs/tmp/2026-06-29-c8-killer-experiment-update.md`.

### 9. C4 matrix, C7 artifact audit, C1-C8 claim verdict (32 units, 2026-06-17)

- **C4** `c4-lookup-readdir-matrix-v1..v4` (input `20260617T-c4-lookup-readdir-kvm-v1`): all pass,
  4/4 families, 26 entries, 26 lookup + 26 readdir rows, 0 failed (build_graph 9, sandbox 6,
  checkpoint 7, cache 4); v2+ relabel W3 workloads as `*-checkpoint-fixture`. Scope: declared Phase 1
  oracle entries only.
- **C7** `c7-artifact-audit-v1..v11`: `c7_supported=false` throughout (clean-checkout reproduction
  never run). v1/v2: package gate false, 207/208 dirty main-repo entries, 4 dirty kernel files
  (`fs/namei_ext.c`, `include/uapi/linux/bpf.h`, `kernel/bpf/cgroup.c`, ...). v3: 16-file package,
  anonymization fails (72 absolute paths). v4: anonymization passes (0). v5..v11: 17-file package,
  `artifact_package_replay_pass=true` (paper rebuild log ~155 KB). v3+ dirs carry payload: a 972800-byte
  evidence tar and `package-root/` (copies of the claim-verdict v11, c3 v3 and c5 v2 ledgers,
  `mk/eval_osdi.mk`, paper sources + `main.pdf` as of 06-17). Tracked `docs/tmp/2026-06-17-c7-artifact-reproducibility-audit.md` (cites
  v11 by run id, v5 by version) - agrees.
- **Claim verdict** `claim-verdict-ledger-v1..v17` (aggregates the round's W1-W4, comparison/scope,
  C3/C4/C5/C7 runs; doc `docs/tmp/2026-06-17-claim-verdict-ledger-implementation.md`):

| Version(s) | weak_accept_ready / paper gate | supported / partial / unsupported / scoped out | Change |
| --- | --- | --- | --- |
| v1, v2 | false / - | 0 / 5 / 3 / - | C2 partial (W2 slice only), C3/C5/C8 unsupported |
| v3 | false / - | 0 / 6 / 2 / - | C3 partial via tool-redirect scope |
| v4 | false / - | 0 / 6 / 0 / 2 | C5, C8 scoped out |
| v5 | false / - | 0 / 4 / 0 / 4 | C6, C7 scoped out |
| v6 | false / - | 3 / 1 / 0 / 4 | C1, C2, C3 supported as slices (per-claim paper gate false) |
| v7, v8 | true / true | 3 / 1 / 0 / 4 | paper-release gate (W2 + tool-redirect) passes |
| v9..v17 | true / true | 4 / 0 / 0 / 4 | C4 supported via matrix; v12+ C7 missing evidence narrowed to clean checkout |

Final (v17, 06-17 14:10): `weak_accept_ready=true`, `paper_release_gate_pass=true`,
`release_gate_pass=false`, C1-C4 supported (slice-scoped), C5-C8 scoped out; doc restates exactly
these counts - agrees. This whole C1-C8 framework was later retired (`0f6b731`).

### 10. 2026-06-17 refresh rounds (why so many near-duplicates)

Manifest times show the chain W1 fuse-test-hardgate / W2 hardgate / W3 ledger / W4 ledger ->
tail10 comparison hardgate -> tool-redirect scope -> W2 paper-release -> claim verdict being re-run as a
unit at 10:30, 10:56-11:01, 12:15, 12:46-12:56, 13:20-13:22 and 13:54-13:55, then C7+claim verdict
alone at 13:59, 14:02, 14:05, 14:07 and 14:10. Only the claim-verdict/C7 outputs and the W1/W4 inputs
change between rounds. 72 of the 190 units are cited by no tracked file; apart from the failed/empty/
incomplete units listed at the end they are near-duplicates numerically identical to a cited sibling:
claim-verdict v1-v5, v8-v10, v12-v16; c7 v1-v10; W1 ledger-smoke v2/v3, fuse-test v1/v2, fuse-test-hardgate
v3-v6; W2 hardgate v4, v7-v10; W2 paper-release v2-v5; W3 v3-v6; W4 ledger v3, v4, v8, v11-v14; tail10
hardgate v2, v3, v5; comparison-latency-batch-hardgate-v1; scope v3-v6; c3 v2; c4 v1-v3; plus the B2 ledger
runs order-metrics-compat and tail-incomplete-negative. Several dirs named `20260615T`/`20260616T` were regenerated in place on 06-17
(tail10-hardgate-v1, W2 hardgate-v5, W3 ledger-v2, W4 ledger-v10).

### 11. Workload reproductions (`results/reproduction/`, 4 units) and trajectory probe (1 unit)

Why: 2026-06-30..07-03 source/workload survey reproducing related systems' official workloads to
pick agent-workspace/environment workloads (manual runs on `.cache/source-inspection` checkouts and
Docker images; no Make target). Each sub-run has a dated `docs/tmp` record; spot-checked numbers agree.

- **2026-06-30-fs-workload-repro** (1.5 MB, 78 files; `docs/tmp/2026-06-30-filesystem-workload-reproduction-report.md`):
  AgentFS CLI/FUSE write-read smoke ok; Redis Agent Filesystem workspace/mount/sync/checkpoint/
  bookmark/fork smokes ok; Mirage import + RAM/disk cross-mount ok, conformance with Redis extra ran;
  DeltaFS `vpic_io`/`large_dir` single-rank POSIX ok (2-4 ops, 0 fail), first cmake attempt failed;
  IndexFS original `make` Error 2 (thrift API drift), reimplementation builds `indexfs-common` only;
  TableFS original builds with no-PIE/old-ABI flags, FUSE smoke ok, fsbench blocked by
  `drop_caches` EPERM; YoloFS-like hidden-side-effect oracle prints `ORACLE_FAIL missing protected
  docs/guide.md` (the intended detection). Small workdir trees (agentfs DB, tablefs, redis-afs) are payload.
- **2026-07-01-official-workloads** (75.9 MB, 1348 files; 37 citing docs, index
  `docs/tmp/2026-07-01-official-workload-reproduction-extension.md`). 54 MB is two DeltaFS strace files.

| Workload | Result |
| --- | --- |
| Terminal-Bench oracle, 16 suites (official tasks, oracle agent) | 64 resolved / 7 unresolved; per suite acl 1/1, build-env 3/4, compile 4/4, data-file-debug 6/6, data-log 5/5, data-sql-log 6/6, env-debug 2/3, file-security 4/4, file-service-pipeline 7/8, filesystem 3/3, forensics 7/8, git-service 5/5, package-data 3/4, security-network 4/6, service-api 3/3, shell-deobfuscation (adapted) 1/1; harness unit tests 93 passed |
| AgentFS pjdfstest | FAIL: 8798 tests, ok 3085, not ok 5713, 75 failed files |
| AgentFS xfstests | unadapted: ran 0; adapted smoke 10 (4 pass-ish); adapted partial 50 with artifacts: 25 failed/out.bad, 18 notrun, 17 mountfail, 7 pass-ish (interrupted at generic/067) |
| Sandlock | partial: CLI 5+22+6 pass, core serial 271 pass / 9 fail, full core 270/10, Python 354/2, manual COW smoke ok |
| MEnvData-SWE | go-task-1814 pass, attrs-586 pass (21 passed), color-eyre-114 fail (test patch apply) |
| Multi-Docker-Eval | synthetic docker_res probe uber-go/atomic-90 resolved (evaluator works only with supplied docker_res) |
| Redis AFS markdown bench | upstream CLI fails (stale ws import); adapted no-search small/medium runs exit 0; adapted indexed path fails; redis:8 (8.8.0 + RediSearch) indexed runs exit 0 but the public CLI markdown workload does not use indexed grep |
| DeltaFS POSIX/mpirank | shell np2 and direct fixed-env runs exit 0; MPI np2/np4 workload runs time out (124) or exit 127; server np2 exits 1; minimal 2-rank diagnostics all 124 |
| IndexFS extension | mdtest-posix np2 files/dirs pass; RPC server/io driver builds fail (status 2) |
| TableFS fsbench individual | 6/12 workload groups pass |
| YoloFS | main-branch make/kmod builds exit 2 and e2e VM fails (guest deps 255); unit tests pass on main and compat; compat kmod build exit 0; e2e VM retry not reproduced |
| other logs | deltafs ctest 10/10 after build; openhands-sdk targeted 195 passed; swe-rex 68 passed + 1 auth-drift fail; swe-minisandbox 4 passed; agentcgroup 43 unit + 14/14 wrapper; redis-afs make test Error 1; HF dataset metadata probes |

- **2026-07-02-official-workloads** (26.5 MB, 769 files; 32 citing docs): AgentCgroup 43+14+4 tests pass;
  AgentFS official 545 unit/SDK pass, CLI integration 10/10 after `umask 022` (fails with 0077);
  BranchFS shell suites + 8 ioctl + 22 integration pass, branch creation 102/113/161 ms for
  100/1000/10000 files, switch 1.8 ms; Docksmith build/run smoke pass (no F2P oracle); MEnvData-SWE 2/3,
  language extension 5/8, positive retry 3/3, second sample 5/5; Mirage 468 pytest + 13 integration +
  11 examples pass, Mirage TypeScript build/tests/15 examples/FUSE pass; Multi-Docker-Eval manual
  docker_res flask-wtf-512: v1/v2 unresolved, v3 resolved; OpenHands docker workspace pass on v3
  (v1 API error, v2 permission fail), SDK 195/195; Redis AFS lifecycle smokes pass except v3;
  SWE-agent 122 pass + 3 xfail / 125; SWE-Factory gym 1 + 3 + 3 instances resolved; SWE-minisandbox
  4/4; SWE-rebench-V2 sample 1/1 and HF batches 18/19 evaluator-positive (alibaba/fescar-382 mismatch,
  24/25 F2P), `hf-remaining-8` interrupted after 4/8 with no report; SWE-ReX 68 pass + 1 auth-status
  drift, Docker backend 6/6; YoloFS compat e2e VM 593/593 pass. Docs restate 545, 468/13/11, 593,
  102370/112724/160922 us, 122/125 and the java-remaining 3/4 - agree.
- **2026-07-03-official-workloads/yolofs-submodule-access-check**: the four YoloFS submodules
  (agent-eval, perf-eval, agent-results, perf-results) all `git ls-remote` exit 128 "Repository not
  found" - original benchmark/results not public. Cited by
  `docs/tmp/2026-07-03-workload-inventory-and-reuse-decision.md` - agrees.
- **research-probes/20260620T-agent-trace-download-probe** (2.9 MB, 54 files, 06-20..06-29):
  Docent dashboard HTML has no transcript data, Python SDK needs an API key, but the DQL REST endpoint
  answered no-auth POSTs (`COUNT transcripts = COUNT agent_runs = 9729`, sample transcript JSON);
  HF `nvidia/Open-SWE-Traces` exposes 4 public splits (openhands/sweagent x minimax_m25/qwen35_122b),
  plus nebius SWE-agent/OpenHands first-row probes. Decision in
  `docs/tmp/2026-06-29-agent-trajectory-export-probe.md`: Open-SWE-Traces primary, nebius OpenHands
  secondary, Docent for provenance only. Doc counts match the raw JSON.

### Doc vs raw mismatches

None found. Checks: (a) headline numbers above compared by hand against each citing `docs/tmp` record;
(b) an automated scan of every `key=value` within 20 lines of a run-id mention in citing docs against the
report summaries flagged 4 lines, all false positives on reading the context
(`2026-06-15-c2-setup-update-release-repetition-implementation.md:130` says the summary *lacks*
`release_gate_pass=true`/`c2_supported=true`; `2026-06-15-eval-osdi-latency-batch-gate.md:11` describes the
*old* target's `input_gate_pass=true`; `2026-06-16-w4-native-compile-ledger-integration.md:100`
`missing_inputs=[]` equals the empty raw value). Rounded doc values (1.77x, "~22 ms vs ~7 ms") match raw.

### Keep list

`p5-evalosdi-repro-keep.tsv` lists 111 small summary files (~455 KB total, largest 59 KB): one report
summary per eval-osdi run whose numbers a `docs/tmp` record restates (24 files; hardgate twins and identical
refresh-round copies omitted), every cited `summary*.json` / `run-summary.json` / SWE-rebench `eval_report*.json`
of the 2026-07-01/02/03 reproductions, three cited top-level 07-01 JSONs, and the Docent count and Open-SWE
split JSONs of the trajectory probe, plus the W2 ledger-v5 JSONL that
`workloads/legacy/w2-nginx-fixture/evidence.md:49,162` cites by path (its lines 131-138 restate the v5 gate
booleans). No `docs/paper` section, `docs/evaluation.md` or `research/STATE.md` cites this slice.

### Units with problems

- failed: `baselines/20260615T-baseline-dryrun`, `...-kvm-external-baselines-smoke`,
  `...-kvm-overlayfs-diagnose` (overlayfs errno 22), `...-kvm-external-baselines-fuse-smoke-v1` (errno 5).
- incomplete: `baselines/...-smoke-v2`, `...-smoke-v3` (empty ledger tmp), `paper/20260615T-eval-ledger-order-metrics-pilot`
  (tail only).
- empty: `paper/20260615T-eval-latency-pilot` (0 files).
- All other report runs completed; their "fail" outcomes are gate verdicts recorded by design.
