## Phase 1 KVM runs 2026-06-16..06-30: W1-W4 macrobench baselines, ccache compile, cache transition, C8 epoch counterfactuals

Slice: the 90 units under `results/phase1/` named `20260616T-*`, `20260617T-*`,
`20260629T-*` and `20260630T-*` (27.9 GB, 1.15 M files; 27.7 GB of that is the
W1 build units). One row per unit is in `p2-phase1-mid.csv`.

### Common facts (apply to every group below)

- **Producer.** Every unit came from a `make kvm-<name> RUN_ID=<unit>` target in
  `mk/kvm.mk`. Each target boots a virtme-ng KVM guest, runs
  `tests/w1_oracle/namei_ext_w1_oracle.c` against the `bpf/policies/*.bpf.c`
  policy, and writes `results/phase1/<RUN_ID>/`. All of these targets were deleted
  from `mk/kvm.mk` in `0f6b731` (2026-07-25, "Remove retired claim-verdict
  machinery and archive process docs"). The epoch-counterfactual targets first
  appear in history in `762741e` and the rest in `5c0b1f9`. Five W4 bulk ccache
  targets are still present at HEAD in `mk/experiments/legacy_build_cache.mk`:
  `kvm-w4-ccache-bulk-{trace,policy-bridge,native-compile,fuse-compile,policy-compile}`.
- **Unit layout.**
  - `<name>.jsonl`: an event stream of start, input, per-sample setup/update/correctness or oracle rows, summary, and done.
  - `<name>-inputs.sha256`: hashes of the policy sources and objects, runner, `mk/kvm.mk`, budget config and workload manifests.
  - `dmesg-<name>.log`
  - `<name>-work/`: payload. For W1 this holds full per-sample copies of the redis and nginx source trees plus outputs, about 6.8 GB per 5-baseline 20-sample run. For W4 it holds ccache dirs, objects and strace logs; for the epoch runs, per-sample shadow files.
  - W4 bulk units also contain the prerequisite `w4-ccache-bulk-trace*` and `w4-ccache-bulk-policy-bridge*` outputs and a source manifest.
  - Only the JSONL, summary, dmesg and stats files were analysed. The work trees are payload.
- **Kernel and dmesg.**
  - 87 units have dmesg logs. All of them boot `Linux 7.1.0-rc7-g31a33d22c212-dirty #8 SMP PREEMPT_DYNAMIC Mon Jun 15 13:38:43`, so every run used the same guest kernel.
  - No log contains `BUG:`, `WARNING: CPU`, `Oops`, `Call Trace`, `panic` or `segfault`. The only matches for "error" or "warning" are 6 benign boot lines that appear in every log.
  - The 3 units without dmesg are the ones that died early.
- **Status.** 81 units completed with summary `pass=true`. 6 failed (summary
  `pass=false`, no done row). 3 aborted (JSONL truncated after the start/input
  rows). Every completed run has `release_gate_pass=false` and
  `qualified_for_c8=false` by design: these are inputs to ledgers, not gates.
- **Citations.**
  - No unit is cited by `docs/paper/`, `docs/evaluation.md`, `research/STATE.md` or any tracked `results/` file.
  - 71 units are cited by dated `docs/tmp/2026-06-1[67]*` and `2026-06-29/30*` records. Three of them are also cited by `workloads/legacy/{w1-nginx-build,w1-redis-build,w2-nginx-fixture}/evidence.md`.
  - 19 units have no tracked mention. For those, the numbers below are the only record.
  - The downstream ledgers that consumed these runs (`results/eval-osdi/paper/...`) are not tracked.
- **Comparison method.** The figures quoted in the docs were recomputed from the raw rows. Every quoted mean, min/max range and write count matches exactly, with one exception: the W4 transition run in §8.

---

### 1. W1 build graph: feature-baseline macrobench, FUSE baseline test, policy macrobench (18 units)

**What and why.** These runs are the C2 macrobench for W1, a Redis+nginx preprocessing build graph with 9 path entries.

- `kvm-w1-build-baseline-macrobench` runs the feature-equivalent baselines (`copy_tree`, `symlink_forest`, `bind_mount`, `projected_volume`, `fuse_redirect`), chosen with `W1_BUILD_BASELINES` and `W1_BUILD_BASELINE_MACROBENCH_SAMPLES`.
- `kvm-w1-build-macrobench` runs the proposed `build_graph_view.bpf.c` policy.
- Each sample does the following:
  1. Copies the redis and nginx source trees (`source_copy_ns`, about 20-23 s; a preparation step not counted in `setup_ns`).
  2. Materialises or attaches the view (`setup_ns`).
  3. Replays preprocessing with an output-hash compare.
  4. Updates backing files (`update_ns`) and replays again.

Design, implementation and run records:
- `docs/tmp/2026-06-16-w1-build-feature-baseline-{design,implementation}.md`
- `...-w1-build-baseline-release-run.md`
- `...-w1-build-projected-fuse-baseline-implementation.md`
- `...-w1-build-macrobench-implementation.md`
- `...-w1-build-release-repetition-run.md`
- `docs/tmp/2026-06-17-w1-fuse-baseline-test-integration.md`, which adds a per-row FUSE oracle and a dmesg hard gate

**Runs.**
- Smokes:
  - `baseline-smoke-v1` **failed**. The `bind_mount` setup returned errno 16 (EBUSY, "failed to materialize W1 build baseline view"); the doc attributes this to a runner de-duplication bug.
  - `baseline-smoke-v2` passed after the fix.
  - `baseline-all-smoke-v1` (all 5 baselines) and `fuse-baseline-smoke-v1` (projected+FUSE) passed.
  - `macrobench-smoke-v1` **failed**. A replay `output_compare` returned errno 22 ("Redis policy output differed from baseline"), with replay rows 3/4 and no update row.
  - `macrobench-smoke-v2` and `-v3` passed.
- Releases, all 20 samples and all passing:
  - Baseline releases: `baseline-release-sample-v1` (3 baselines), `-v2` (5 baselines) and `20260617T-...-v3` (5 baselines, a rerun).
  - Policy macrobench releases: `macrobench-release-sample-v1` and `20260617T-...-v2` (a rerun).
  - FUSE-only releases: `fuse-baseline-test-release-v1` and `fuse-baseline-test-hardgate-release-v1..v4`, all 20/20/20 rows passing. The FUSE setup rows record 4 FUSE mounts per sample.

Median setup / update latency in ms (20 samples per system; correctness rows all pass; replay rows 120 per system, all pass):

| run | copy_tree | symlink_forest | bind_mount | projected_volume | fuse_redirect | build_graph policy |
|---|---|---|---|---|---|---|
| 0616 baseline-release-sample-v1 | 17.8 / 45.3 | 76.9 / 44.8 | 50.2 / 35.1 | - | - | - |
| 0616 baseline-release-sample-v2 | 16.9 / 45.0 | 87.2 / 45.9 | 54.9 / 35.0 | 178.7 / 131.8 | 304.7 / 41.7 | - |
| 0617 baseline-release-sample-v3 (untracked) | 15.9 / 43.6 | 77.2 / 46.2 | 56.3 / 38.9 | 154.2 / 127.4 | 305.5 / 41.1 | - |
| 0617 fuse test-release-v1 / hardgate v1 / v2 / v3 / v4 | - | - | - | - | 301.6/41.1, 306.6/41.5, 306.3/39.5, 307.8/46.7, 301.1/41.0 | - |
| 0616 macrobench-release-sample-v1 | - | - | - | - | - | 63.4 / 48.5 (mean 66.09 / 52.42) |
| 0617 macrobench-release-sample-v2 (untracked) | - | - | - | - | - | 64.0 / 50.9 (mean 65.26 / 52.11) |

Policy compared with the baselines, using medians from the v2 baseline run and the v1 policy run:
- Setup: the policy (63.4 ms) is 3.8x slower than `copy_tree` (16.9 ms), but 2.8x faster than `projected_volume` and 4.8x faster than `fuse_redirect`.
- Update: the policy (48.5 ms) is 1.4x slower than the best baseline, `bind_mount` (35.0 ms).

**Tracked comparison.** The tracked docs agree with the raw data:
- `2026-06-16-w1-build-baseline-release-run.md` gives v1 setup means of 18.33 / 79.19 / 55.48 ms and update means of 48.84 / 46.22 / 40.17 ms (copy / symlink / bind). The raw data reproduce these exactly.
- `...-projected-fuse-baseline-implementation.md` gives the v2 per-baseline means (for example copy `setup_ns_avg=17324797.3`, fuse `306513512.25`), the policy means `66090011.6` / `52416038.25` and a 100/100/100 row count. All reproduce.
- `...-w1-build-macrobench-implementation.md` gives the smoke-v3 values `setup_ns=57973895`, `source_copy_ns=20927589150` and `update_ns=66338828`. These are exact, and the smoke-v1 errno 22 detail also matches.
- The fuse-test doc reports hardgate v1/v3 as 20 passing rows with a dmesg scan of 0, which matches.
- The tracked conclusion is that W1 is threshold-negative for C2 (`w1_c2_slice_supported=false`), because the fastest baselines beat the policy on setup and update. The raw medians are consistent with that.
- Five runs have no tracked mention: `release-sample-v3`, `macrobench-release-sample-v2`, `fuse-baseline-test-release-v1` and `hardgate-release-v2` / `-v4`. They are 06-17 reruns whose numbers fall within a few percent of the cited runs.

### 2. W2 nginx fixture: feature-baseline macrobench and policy/real-app hard gates (12 units)

**What and why.** These runs are the C2 baseline inputs for the nginx sandbox-fixture workload.

- `kvm-w2-nginx-baseline-macrobench` materialises a 17-file nginx prefix for each baseline and checks the following with `nginx -t`:
  - endpoint, config, cert, secret and poison probes
  - post-update probes
- `kvm-w2-nginx-macrobench` runs the `sandbox_fixture_view.bpf.c` policy.
- `kvm-w2-nginx-real` runs a real nginx binary with the policy attached and checks that the fixture is rejected before attach and after detach.
- `kvm-w2-nginx-real-trace` runs the same check under strace and asserts that no production decoy is opened.

Records:
- `docs/tmp/2026-06-16-w2-nginx-{feature,bind,projected-volume,fuse}-baseline-implementation.md`
- `...-w2-nginx-storage-threshold-*.md`
- `docs/tmp/2026-06-17-w2-nginx-hardgate-provenance.md`
- `...-w2-nginx-real-trace-gate.md`

**Runs.** All 12 runs passed with failures=0:
- 4 single-baseline or 2-baseline smokes
- release samples v1 to v4, which add one baseline at a time (2, 3, 4 and then 5 baselines; 20 samples each)
- the 06-17 dmesg-hard-gated smokes for the baselines (5 baselines, 2 samples), the policy (2 samples) and the real app (18/18 probes)
- `real-trace-release-v1`, which recorded 9 fixture alias opens (6 config, 3 endpoint), 0 production-decoy opens, pre-attach and post-detach rejection, `w2_real_trace_gate_pass=true` and 0 dmesg issues

Median setup in ms / update in µs (20 samples; correctness 40, 60, 80 and 100 of 40, 60, 80 and 100):

| run | copy_tree | symlink_forest | bind_mount | projected_volume | fuse_redirect |
|---|---|---|---|---|---|
| release-sample-v1 | 9.2 / 22.3 | 11.3 / 10.1 | - | - | - |
| release-sample-v2 | 9.4 / 22.2 | 9.6 / 10.2 | 8.7 / 7.2 | - | - |
| release-sample-v3 | 7.2 / 21.2 | 7.2 / 10.5 | 9.7 / 10.6 | 10.6 / 65.5 | - |
| release-sample-v4 | 9.7 / 20.6 | 11.0 / 11.3 | 12.4 / 13.1 | 11.2 / 52.0 | 61.1 / 12.2 |
| 0617 baseline-hardgate-smoke (2 samples) | 10.0 / 170.9 | 11.0 / 10.2 | 10.8 / 10.5 | 10.4 / 52.5 | 61.3 / 12.3 |

The policy `w2-nginx-macrobench-hardgate-smoke` (2 samples) took 8.0 ms to set up and 74.0 µs to update. The FUSE smoke took 59.2 ms to set up.

**Tracked comparison.** The tracked docs agree with the raw data:
- The implementation docs give min-max ranges, and the raw data reproduce every one. Examples:
  - v1 copy setup 7.90-13.83 ms and update 15.5-91.4 µs
  - v4 fuse setup 58.50-64.18 ms and update 11.3-44.9 µs
  - v4 projected update 38.2-231.2 µs
  - fuse smoke setup 58.98-59.39 ms
- The row counts and baseline_count values in the hardgate provenance doc also match.
- `workloads/legacy/w2-nginx-fixture/evidence.md` cites release-sample-v4.
- The 20-sample proposed-system W2 run is not in this slice.

### 3. W3 Redis checkpoint macrobench (3 units)

**What and why.** These runs are the C2 setup/update rows for Redis checkpoint replay.

- `kvm-w3-redis-policy-macrobench` runs the `checkpoint_restore_view.bpf.c` policy.
- `kvm-w3-redis-baseline-macrobench` runs the `materialized_checkpoint_view` and `fuse_redirect` baselines.
- Correctness covers the initial GET, readdir (dump.rdb visible, dump.ckpt hidden), the post-update GET, and absence before attach and after detach.
- Record: `docs/tmp/2026-06-16-w3-redis-policy-fuse-macrobench-implementation.md`.

**Runs.** There were two 1-sample smokes and `w3-redis-macrobench-release-v1`, which ran 20 samples per system. All passed.

| system (release-v1, 20 samples) | setup median (mean) | update median (mean) | correctness |
|---|---|---|---|
| checkpoint_restore_policy | 22.8 ms (22.96) | 5.153 s (5.158) | 20/20 |
| materialized_checkpoint_view | 6.5 ms (6.52) | 5.155 s (5.154) | 20/20 |
| fuse_redirect | 61.2 ms (61.21) | 5.167 s (5.168) | 20/20 |

**Tracked comparison.** `2026-06-16-w3-w4-fuse-baseline-status-audit.md` states policy averages of 22.96 ms / 5.16 s against the best external averages of 6.52 ms / 5.15 s. The raw data match. The update latency is 5.15-5.17 s for all three systems, so update cost does not separate them.

### 4. W4 ccache, small 4-object set: rule and materialized macrobench (4 units)

**What and why.** `kvm-w4-ccache-rule-macrobench` compares the `parent_rule_policy` exact policy (`cache_locality_view.bpf.c`) with a `table_redirect` baseline on 4 trace-derived ccache objects (2 Redis, 2 nginx). It also runs a manifest content oracle per sample.

`kvm-w4-ccache-materialized-baseline-macrobench` runs a `materialized_cache_view` baseline. Each unit also contains its prerequisites:
- `w4-ccache-trace`, a real ccache cache-path trace whose ccache stats show cache_miss 2 and direct_cache_hit 2
- `w4-ccache-policy-bridge`, 4 entries with a content oracle that passes

Records: `docs/tmp/2026-06-16-w4-ccache-rule-macrobench-implementation.md`, `...-w4-materialized-cache-baseline-implementation.md` and the W4 ledger-integration notes.

| run | system | setup / update median (ms) | rule writes setup+update | correctness |
|---|---|---|---|---|
| rule release-v1 (20 samples) | parent_rule_policy | 108.5 / 6.44 | 8+2 | 20/20 |
| | table_redirect | 102.1 / 5.97 | 8+2 | 20/20 |
| materialized release-v1 (20 samples) | materialized_cache_view | 59.3 / 3.91 | 0 | 20/20 |

The content-oracle rows in rule release-v1 were 600/600, and both smokes passed.

**Tracked comparison.** The tracked docs agree with the raw data:
- Rule release means: `setup_ns_avg=110545949.3` / `104058982.65` and `update_ns_avg=6518131.3` / `6308357.65` (policy / table). These reproduce.
- Rule smoke: `setup_ns` 102802203 / 90480593 and `update_ns` 5662438 / 5057563. These are exact.
- Materialized release means: 57.95 / 3.82 ms. These are exact.

The table baseline is within about 7% of the policy on setup and update, with identical write counts. This is the evidence the docs use to say the 4-object W4 slice does not separate the policy from a table.

### 5. W4 ccache bulk (20 sources, 40 objects): setup/update macrobench (7 units)

**What and why.** The bulk Redis+nginx ccache workload has 20 compiled sources and 40 trace-derived cache objects (20 Redis, 20 nginx).

- `w4-ccache-bulk-smoke-v1` holds only the prerequisites (`kvm-w4-ccache-bulk-trace` and `kvm-w4-ccache-bulk-policy-bridge`):
  - trace with 20 sources; ccache stats show direct_cache_hit 20, cache_miss 20 and 40 files
  - bridge content oracle rows 207/207
  - Every bulk unit re-ran these prerequisites, and all of those runs passed with 40 trace objects.
- `kvm-w4-ccache-bulk-fuse-baseline-macrobench` is a read-oriented FUSE cache view with 1 mount per sample.
- `kvm-w4-ccache-bulk-materialized-baseline-macrobench`
- `kvm-w4-ccache-bulk-policy-macrobench` runs `cache_locality_exact_policy`, with 80 setup rule writes and 2 update rule writes.

Records: `docs/tmp/2026-06-16-w4-bulk-{ccache-workload,fuse-cache-baseline,materialized-cache-baseline,policy-macrobench}-implementation.md`.

| system (release-v1, 20 samples) | setup median (mean), min-max ms | update median (mean), min-max ms | correctness |
|---|---|---|---|
| fuse_redirect | 794.5 (794.16), 636.59-1006.38 | 2.30 (2.28), 1.61-3.23 | 20/20 |
| materialized_cache_view | 481.6 (484.83), 425.40-573.99 | 3.00 (3.12), 2.83-3.77 | 20/20 |
| cache_locality_exact_policy | 334.9 (336.19) | 4.88 (4.99) | 20/20 |

Policy compared with the baselines, by median:
- Setup: the policy is faster, at 0.42x the FUSE time and 0.70x the materialized time.
- Update: the policy is slower, at 2.1x the FUSE time and 1.6x the materialized time.

All smokes passed.

**Tracked comparison.** The FUSE and materialized min/avg/max values in the implementation docs match exactly. The status audit's policy averages of 336.19 / 4.99 ms also match.

### 6. W4 ccache bulk hot compile: native, FUSE and policy-attached (12 units)

**What and why.** These runs perform a real hot-cache ccache compile of the 20 bulk sources, checking output-object hashes against native output and counting cache-path operations with strace.

- `kvm-w4-ccache-bulk-native-compile` uses a native cache dir.
- `kvm-w4-ccache-bulk-fuse-compile` reads the cache through FUSE, with ccache read-only and stats disabled; hits are counted from `CCACHE_LOGFILE`.
- `kvm-w4-ccache-bulk-policy-compile` compiles with the `cache_locality` policy attached, which redirects visible cache objects to renamed backing objects.

Records:
- `docs/tmp/2026-06-16-w4-bulk-{native-ccache,fuse-compile,policy-compile}-*implementation.md`
- `...-w4-{native,fuse}-compile-ledger-integration.md`
- `docs/tmp/2026-06-29-w4-bulk-compile-release-refresh.md`
- `2026-06-29-c8-killer-experiment-update.md`

**Runs.**
- `fuse-compile-smoke-v1` **failed**. Its summary has `ccache_log_direct_cache_hit=0` against 20 sources. The doc explains that the log parser counted only `Result: direct_cache_hit`; smoke-v2 passed after the fix.
- `20260629T-native-compile-release-v1` **aborted**. Its JSONL holds only start+input rows (samples=20), the work dir is empty and there is no compile dmesg. It was rerun as `-v2` 5 minutes later (17:08 → 17:13).
- `policy-compile-release-shakeout-v1` **aborted**. Its JSONL holds only start+input rows, and the two `.gdb*.jsonl` files are 0 bytes. `shakeout-v2` (2 samples) passed a few minutes later (16:46-16:48 → 16:51).
- All other runs passed.

| run (20 samples x 20 sources) | compile time per sample median (mean) | jobs / output matches / direct hits | cache-path ops / cache-object ops / sampled hit rate |
|---|---|---|---|
| 0616 native-compile-release-v1 | 4.95 s (5.06) | 400 / 400 / 400, miss 0 | 8000 / 3200 / 0.400 |
| 0616 fuse-compile-release-v1 | 9.46 s (9.68) | 400 / 400 / 400 (20 FUSE mounts) | 6000 / 3200 / 0.533 |
| 0629 native-compile-release-v2 | 7.42 s (7.56) | 400 / 400 / 400, miss 0 | 8000 / 3200 / 0.400 |
| 0629 fuse-compile-release-v2 | 13.98 s (14.03) | 400 / 400 / 400 (20 FUSE mounts) | 6000 / 3200 / 0.533 |
| 0629 policy-compile-release-v1 | not recorded | 400 / 400; 800 redirected objects | 8000 / 3200 / 0.4 |

- **FUSE versus native.** By mean, FUSE takes 1.91x the native compile time on 06-16 and 1.86x on 06-29.
- **Between days.** Both systems are about 1.45-1.5x slower on 06-29 than on 06-16, so absolute compile times are not comparable across the two days.
- **Policy compile oracles.** The policy compile JSONL has no latency field. The visible-match, readdir-alias, pre-attach-absent and post-detach-absent oracles were each 800/800 in the release run, 80/80 in shakeout-v2 and 40/40 in the 06-16 smoke (20 jobs).
- **Direct-hit count.** The policy `release-summary` reports `direct_cache_hit=380` for 400 jobs with cache_miss 0; shakeout-v2 reports 20 for 40 jobs. The per-sample stats file shows 20/20 hits. In both runs the summary value equals (samples-1) x 20. The tracked docs do not quote this field.

**Tracked comparison.** The tracked docs agree with the raw data:
- `compile_ns_avg=7562011642.35` (native, 06-29) and `14030225541.1` (FUSE, 06-29) are exact.
- The counts 400 / 400 / 400, 8000 / 3200 and 6000 / 3200, and the hit rates 0.40 / 0.533, all match.
- The 06-16 smoke-v1 failure explanation matches the raw summary.

### 7. W4 cache content and table-content hard gates (5 units, 2026-06-17)

**What and why.** These runs repeat the W4 cache content oracle under the dmesg hard gate.

- `kvm-w4-cache-content` runs `cache_locality_view.bpf.c`.
- `kvm-w4-cache-table-content` runs `table_redirect.bpf.c`.
- Each run checks 4 manifest-derived branches (ccache and BuildKit manifests) with lookup, readdir, forbidden-mismatch, pre-attach and post-detach checks.
- Records: `docs/tmp/2026-06-17-w4-cache-content-hardgate-provenance.md` and `...-claim-verdict-ledger-implementation.md`. The ledger used `table-content-hardgate-smoke-v2`, then `-v3`, as its W4 cache-table input.

**Result.** All 5 runs have oracle rows 26/26.
- The policy runs (content-hardgate v1 and v2) pass.
- The table runs (v1 to v3) also pass, with `content_equivalent_table_oracle=true` and `table_baseline_current_oracle_pass=true`. The summary itself labels this "negative C8 evidence": a static table reproduces the content oracle.

The docs agree. `content-hardgate-smoke-v2` has no tracked mention; it is an identical-size rerun of v1.

### 8. W4 cache state-transition counterfactual (8 units)

**What and why.** `kvm-w4-cache-transition-counterfactual` uses 4 entries, 2 of them stateful (stale and corrupt). It compares 3 systems:
- `cache_locality_state_policy`
- `table_redirect_static_verified`
- `table_redirect_updated_exact`, an externally updated exact table

The question is whether only the policy survives the stale→verified transitions. Records: `docs/tmp/2026-06-17-w4-cache-transition-counterfactual.md` and `2026-06-29-c8-killer-experiment-update.md`.

**Result, consistent across every completed run.**
- The static table fails the current oracle with wrong local hits.
- The updated table passes every transition, using the same number of update writes as the policy (`table_update_write_ratio=1`, `table_update_budget_failure=false`).
- The result is therefore a **negative** C8 result, as the summaries say.

| run | samples | rows setup/corr/update | static wrong hits | update writes policy/table | median observed window, policy/table |
|---|---|---|---|---|---|
| 0617 smoke-v2, hardgate-smoke-v1, 0629 c8-smoke-v1 | 1 | 3/12/8 | 2 | 8/8 | 6.6/6.8, 8.0/7.9, 12.4/12.2 ms |
| 0617 hardgate-release-v1 (surviving JSONL), hardgate-release-v2 | 2 | 6/24/16 | 4 | 16/16 | 6.2/6.5, 7.1/7.7 ms |
| 0617 release-v1 (untracked) | 20 | 60/240/160 | 40 | 160/160 | 9.5/9.9 ms |
| 0629 transition-c8-release-v1 | 20 | 60/240/160 | 40 | 160/160 | 10.2/10.2 ms |

In every completed run, all transition rows pass for both the policy and the updated table (80/80 each in the 20-sample runs). `release_sample_budget_pass` is true only for the two 20-sample runs. `0617 smoke-v1` **aborted**: its JSONL is 159 bytes and holds only the start row, with an empty work dir and no dmesg or input hash. It was rerun as smoke-v2 within a minute (23:50 → 23:51 on 06-16).

**Discrepancy.** `docs/tmp/2026-06-17-w4-cache-transition-counterfactual.md` runs `RUN_ID=20260617T-w4-cache-transition-hardgate-release-v1 W4_CACHE_TRANSITION_SAMPLES=20`, then cites that directory's JSONL with a "release summary" of:
- samples=20
- setup / correctness / update rows 60/240/160
- static_wrong_local_hits=40
- policy/table update writes 160/160
- release_sample_budget_pass=true

The JSONL now in that directory says otherwise:
- samples=2, rows 6/24/16, hits 4, writes 16/16, release_sample_budget_pass=false
- It was written at 03:31, while the directory and its `-work/` tree, with 60 sample subdirectories (= 20 samples x 3 systems), date from 00:11.

So the 20-sample JSONL the doc describes was overwritten by a later 2-sample run under the same RUN_ID. The 20-sample numbers the doc quotes are, however, identical to the surviving untracked `20260617T-w4-cache-transition-release-v1` (23:51 on 06-16) and to the cited `20260629T-w4-cache-transition-c8-release-v1`. The claim-verdict ledger doc used `hardgate-release-v1`, and later `-v2`, as its W4 transition input. Both directories now hold only 2-sample JSONLs. The 06-29 c8 release numbers match the c8-killer doc exactly.

### 9. C8 epoch counterfactuals: W1 build, W2 fixture, W3 checkpoint, W4 cache, W4 ccache-bulk (20 units, 2026-06-29/30)

**What and why.** These are the "C8 killer" experiments, produced by `kvm-{w1-build,w2-fixture,w3-checkpoint,w4-cache,w4-ccache-bulk-cache}-epoch-counterfactual` with `*_SAMPLES` and `*_OBJECTS=16`. Each sample switches 16 objects from epoch 1 to epoch 2 under 5 systems:

| system | how it reaches epoch 2 |
|---|---|
| the workload's epoch policy | a 1-write session update |
| static exact table | never; it is expected to fail epoch 2 |
| externally updated exact table | 16 lookup rewrites |
| materialized view | 16 copies |
| FUSE view | 16 shadow rewrites |

The budget is `max_table_update_write_ratio=10`.

The W3 and W4-cache series were built up in steps:
1. policy + tables only (`release-v1`)
2. + materialized (`materialized-v*`)
3. + FUSE (`fuse-v*`)

The W4 ccache-bulk variant uses the 40 real ccache trace entries.

Records: `docs/tmp/2026-06-29-c8-killer-experiment-update.md` and one doc per workload:
- `2026-06-30-w1-build-epoch-counterfactual.md`
- `2026-06-30-w2-fixture-epoch-counterfactual.md`
- `2026-06-29-w3-checkpoint-epoch-{counterfactual,materialized-baseline,fuse-baseline}.md`
- `2026-06-29-w4-cache-epoch-{counterfactual,materialized-baseline,fuse-baseline}.md`
- `2026-06-29-w4-trace-derived-cache-epoch-counterfactual.md`

**Result in every completed run.**
- Static-table hits on the wrong epoch: 16 per sample (320 at 20 samples).
- Policy update writes: 1 per sample.
- Table, materialized and FUSE update writes: 16 per sample each, so `*_update_write_ratio=16` > 10 and `targeted_c8_budget_failure=true`.
- All other systems pass the current oracle.
- Setup writes at 20 samples: policy 1940, table 1920, materialized and FUSE 320 each.
- All correctness rows pass (200/200 with 5 systems, 160/160 with 4, 120/120 with 3). The static table's expected failure at epoch 2 is counted as a pass.

Medians at 20 samples, in ms. The policy update itself is a single map write of less than 0.01 ms; table / materialized / FUSE updates take about 11-14 / 68-86 / 53-66 ms.

| run | setup: policy / static / updated tbl / mat / fuse | observed update window: policy / updated tbl / mat / fuse | update_ns: tbl / mat / fuse |
|---|---|---|---|
| W1 build-epoch-c8-release-v1 | 90.3 / 44.3 / 42.8 / 83.9 / 175.8 | 134.3 / 148.1 / 245.8 / 333.6 | 14.3 / 86.0 / 66.5 |
| W2 fixture-epoch-c8-release-v1 | 77.2 / 36.9 / 36.9 / 75.9 / 167.7 | 120.2 / 139.5 / 229.9 / 272.2 | 12.8 / 77.4 / 54.0 |
| W3 checkpoint-epoch-c8-release-v1 | 73.5 / 37.3 / 37.7 / - / - | 116.4 / 129.3 / - / - | 12.2 / - / - |
| W3 ...-materialized-v1 | 70.8 / 35.2 / 34.4 / 70.8 / - | 109.5 / 121.9 / 215.5 / - | 11.2 / 72.0 / - |
| W3 ...-fuse-v1 (untracked) | 83.9 / 39.5 / 41.7 / 78.0 / 164.7 | 125.8 / 140.4 / 217.5 / 293.7 | 13.9 / 78.4 / 57.2 |
| W3 ...-fuse-v2 | 80.1 / 37.3 / 36.8 / 76.9 / 173.9 | 126.1 / 130.1 / 220.1 / 302.5 | 12.3 / 74.2 / 58.3 |
| W4 cache-epoch-c8-release-v1 | 85.9 / 40.0 / 41.5 / - / - | 178.5 / 190.3 / - / - | 13.4 / - / - |
| W4 ...-materialized-v1 / v2 / v3 (v1, v2 untracked) | 82.3, 81.1, 66.1 / ... / 76.1, 82.7, 70.5 / - | 171.0, 169.7, 147.2 / 175.9, 197.3, 160.8 / 232.1, 238.7, 199.4 / - | 12.8, 13.3, 11.3 / 81.3, 85.3, 68.4 / - |
| W4 ...-fuse-v1 | 76.7 / 37.2 / 36.5 / 75.9 / 165.0 | 161.1 / 174.0 / 220.3 / 272.2 | 11.8 / 76.8 / 53.3 |
| W4 ccache-bulk-cache-epoch-c8-release-v1 | 71.6 / 35.4 / 36.6 / 70.3 / 163.2 | 152.6 / 166.9 / 213.2 / 283.6 | 12.2 / 73.3 / 56.8 |

The smokes (1-2 samples) give the same write counts and similar latencies (see CSV). The observed window for the policy (110-180 ms) is only somewhat shorter than the updated table's (122-197 ms), even though the policy's update write takes less than 0.01 ms. Most of the measured window therefore comes from something other than the write itself. The tracked docs report only write counts and ratios, not these windows.

**Failures (none recorded in the tracked docs).** `w4-ccache-bulk-cache-epoch-c8-smoke-v1` and `-smoke-v2` (2 samples) and `-diagnose-v1` (1 sample, 1 object) **failed**. Every setup row returned errno -38 (ENOSYS): 10, 10 and 5 setup rows respectively, with correctness_rows=0 and no done row. The diagnose run's detail reads "trace-derived cache epoch prepare failed at component_copy errno 38 path 4e8ftngmn1sfqe8ao5efe3o34h6ufm0R". `smoke-v3` then passed (20/20) and `release-v1` passed (200/200, `real_ccache_trace=true`, `trace_derived_targeted_c8_pass=true`).

**Tracked comparison.** Every write count, hit count, ratio and pass flag quoted in the c8-killer doc and the per-workload docs matches the raw summaries. Among the cited runs these are: W1 release, W2 release, W3 fuse-v2 and materialized-v1, W4 fuse-v1 and materialized-v3, and the ccache-bulk release. Untracked duplicates: W3 `fuse-v1` and W4 `materialized-v1` / `-v2` give the same counts.

### 10. C4 lookup/readdir phase-1 oracle run (1 unit, untracked)

`20260617T-c4-lookup-readdir-kvm-v1` holds `w1..w4-oracle.jsonl` from the `kvm-w1-oracle`, `kvm-w2-oracle`, `kvm-w3-oracle` and `kvm-w4-oracle` targets, all written into one RUN_ID. It is the kind of "phase1 run with W1-W4 oracles" that `docs/tmp/2026-06-17-c4-lookup-readdir-matrix-ledger.md` asks for as `EVAL_OSDI_C4_PHASE1_RUN_ID`, but no tracked file names this run.

Each workload's policy and the `table_redirect` baseline are checked for lookup, readdir, pre-attach-absent and post-detach-absent:

| workload | policy | entries |
|---|---|---|
| W1 | build_graph | 9 |
| W2 | sandbox_fixture | 6 |
| W3 | checkpoint_restore | 7 |
| W4 | cache_locality | 4 |

All 240 oracle rows pass (80 / 56 / 64 / 40), all 4 run-summaries report failures=0, and dmesg is clean. A table baseline passes every lookup/readdir oracle here too, so the run supports no claim that separates the policy from a table.

### Doc vs raw mismatches

- **`docs/tmp/2026-06-17-w4-cache-transition-counterfactual.md:80,87,104-123`**
  - *The doc says:* it ran `20260617T-w4-cache-transition-hardgate-release-v1` with `W4_CACHE_TRANSITION_SAMPLES=20` and that this directory's JSONL reports samples=20, setup/correctness/update rows 60/240/160, `static_wrong_local_hits=40`, policy/table update writes 160/160 and `release_sample_budget_pass=true`.
  - *The raw data shows:* `results/phase1/20260617T-w4-cache-transition-hardgate-release-v1/w4-cache-transition-counterfactual.jsonl`, written at 03:31, has samples=2, rows 6/24/16, hits 4, writes 16/16 and `release_sample_budget_pass=false`.
  - *Likely cause:* the directory and its `-work/` tree, with 60 sample dirs, date from 00:11. The 20-sample JSONL was overwritten by a 2-sample rerun under the same RUN_ID.
  - *Where the doc's numbers survive:* exactly in the untracked `20260617T-w4-cache-transition-release-v1` and in `20260629T-w4-cache-transition-c8-release-v1`.
- **`docs/tmp/2026-06-17-claim-verdict-ledger-implementation.md:80,115,213`**
  - *The doc says:* it feeds `EVAL_OSDI_CLAIM_W4_TRANSITION_RUN_ID=...-hardgate-release-v1`, and in one variant `...-v2`, as the W4 transition release input.
  - *The raw data shows:* both directories now hold 2-sample JSONLs (`samples=2`, `release_sample_budget_pass=false`), not 20-sample release inputs.
- No other mismatch was found. Every other number checked in the cited docs reproduces from the raw rows. The checks are listed per group above.

The raw summary files that are the only source of the numbers the docs state (55 files, 5.76 MB, all JSONL or one `.release-summary`) are listed in `p2-phase1-mid-keep.tsv`.

### Summary of notable findings

1. **Doc/raw mismatch.** `20260617T-w4-cache-transition-hardgate-release-v1` is documented as a 20-sample release, but its surviving JSONL is a 2-sample rerun (§8). Identical 20-sample numbers survive in `20260617T-w4-cache-transition-release-v1` and `20260629T-w4-cache-transition-c8-release-v1`.
2. **Other numbers.** Every other figure quoted in the tracked docs reproduces from the raw rows: W1/W2/W3/W4 setup and update means and ranges, compile averages, and write counts and ratios.
3. **Failures and aborts the docs do not record.** W4 ccache-bulk cache-epoch smoke-v1/v2 and diagnose-v1 hit ENOSYS during setup. Native-compile-release-v1 (06-29), policy-compile shakeout-v1 and transition smoke-v1 aborted.
4. **Paper citations.** None of these runs is cited by the paper or `docs/evaluation.md`. 19 of the 90 have no tracked mention at all. Most are 06-17 reruns plus the C4 oracle run.
