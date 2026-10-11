## Phase 1 early runs, 2026-06-13 to 2026-06-15 (`results/phase1/2026061[345]*`)

Scope: 101 run roots (about 106 MB, about 20,200 files) under `results/phase1/` whose names start with
2026-06-13, -14 or -15. The CSV `p1-phase1-early.csv` has one row per root. This section groups the roots
into 10 families (A to J). All numbers below come from the raw files (`summary.md` gate blocks, JSONL
`pass` fields, `bench.jsonl` rows, `metadata.json`, `bench-status.txt`). For each family it compares those
numbers with the dated records in `docs/tmp/`.

### Provenance and producers (all families)

- Everything was produced through the top-level Makefile's Phase 1 targets. `PHASE1_RESULT_DIR ?= $(RESULT_ROOT)/phase1/$(RUN_ID)`
  is set in `mk/kvm.mk`. Raw KVM rows come from `__phase1_guest_*` recipes run in a virtme-ng guest.
  `summary.md` is written by the `report` target in `mk/report.mk`.
- Code history. `4918f88` (the initial plan) has no Makefile. The 2026-06-13 07:47Z smoke roots therefore
  predate any committed producer. `b3f3e45` ("Implement phase1 redirect artifact", 2026-06-13 12:13 PDT)
  first committed `phase1: phase1-smoke kvm-functional kvm-bench docker-smoke report`, along with
  `mk/kvm.mk`, `mk/report.mk` and `mk/docker.mk`.
- The 2026-06-14/15 roots record main HEAD `6fe308a` with `dirty: true`. The run-time targets they used
  (`kvm-policy-load`, `kvm-policy-semantic`, `table-conformance`, `kvm-w1-oracle` ... `kvm-w4-ccache-*`,
  `kvm-w2-nginx-macrobench`, `kvm-w3-redis-counterfactual`, `table-budget`, and the larger `report`
  hard gate) were first committed in `5c0b1f9` (2026-06-27).
- Most `kvm-w*` targets and `table-conformance` were removed in `0f6b731` (2026-07-25). `report` was last
  touched in `1f5d0c9` (2026-07-28).
- These targets still exist at HEAD `eba72a6`: `phase1`, `phase1-smoke`, `abi`, `kvm-smoke`,
  `kvm-policy-load`, `kvm-policy-semantic`, `kvm-functional`, `kvm-bench` and `docker-smoke`.
- No root in this slice is cited by `docs/paper/sections/*.tex`, `docs/evaluation.md` or
  `research/STATE.md`. Citations are only in `docs/tmp/*.md` (dated implementation records) and in
  `workloads/legacy/*/evidence.md`. `docs/tmp/2026-06-14-paper-review-revision-1.md` records that
  `20260614T045335Z-a476f6e2` was once put into a paper artifact-evidence table. The current paper text
  does not cite it.
- Dmesg: none of the 316 `dmesg-*.log` files in the slice contain `WARNING:`, `Oops`, `BUG:`,
  `Kernel panic` or `Call Trace`. The only hits for the looser words "panic/oops" are the guest kernel
  command line (`panic=30 oops=panic`).
- Status counts: 89 completed, 6 failed, 3 incomplete, 2 aborted, 1 empty.

### A. 2026-06-13 KVM guest-smoke bring-up (6 roots, about 2 KB)

What and why: these are the first `kvm-smoke` boots of the modified kernel, taken before any producer was
committed. Guest `uname` is `7.1.0-rc7-g062871f1371b-dirty #2` (built Jun 13 00:46 PDT), with
`CONFIG_NAMEI_EXT=y`.

| Root | Files | Result |
|---|---:|---|
| `20260613T074741Z-8d27826f` | 0 | empty root, created in the same second as `...074741Z-f1d10be9` |
| `...074741Z-f1d10be9`, `...074802Z-08f17688`, `...074932Z-cfa348d7`, `...075009Z-2719c429` | 4 each | `guest-smoke.jsonl` has start and done events |
| `...074946Z-ba6d467d` | 5 | same, plus `summary.md` "Phase 1 Smoke Report" (scope: "current smoke infrastructure, not full Phase 1 evaluation yet", samples 1) |

Tracked summary: none. This section is the only record. Outcome: all five non-empty roots booted and
completed the smoke.

### B. 2026-06-13 functional/benchmark/ABI/Docker gate bring-up (12 roots, 1.25 MB)

What and why: this is when the functional suite (visible/hidden/denied stat, open and readdir), the
microbenchmark runner, the ABI layout test, `docker-smoke` and the `summary.md` gates were added
(`docs/tmp/2026-06-13-functional-and-benchmark-implementation.md`,
`docs/tmp/2026-06-13-namei-ext-bpf-abi-implementation.md`,
`docs/tmp/2026-06-13-phase1-validation-and-artifact-gates-implementation.md`). Some roots contain a
single target's output (`make abi`, `make kvm-bench`, `make docker-smoke`).

| Root | Contents | Gates / outcome | Policy/baseline median ns/op (lookup_visible_hot) |
|---|---|---|---:|
| `20260613T154631Z-104213e4` | functional | 10/10 cases pass | - |
| `20260613T155042Z-1e46f9aa` | bench | fail=0 | 1.48 |
| `20260613T155148Z-611a3836` | smoke+func+bench+summary | 3 gates, all 0 | 1.46 |
| `20260613T155621Z-a6740670` | + dmesg logs | **dmesg gate = 6** (false positive, see below); func 10/10, bench fail=0 | 1.46 |
| `20260613T160435Z-7055f407`, `...160551Z-c977a272`, `...162354Z-e0f1f2a1` | abi only | 3/3 (ctx_size 88, name_offset 24, name_max 64) | - |
| `20260613T160551Z-446fcdf2` | docker only | pass, image tar sha `86bd1c4a...` | - |
| `20260613T160442Z-7d7ed18e` / `...160622Z-e1b62cb3` | phase1 (+docker in e1b6) | 5 / 6 gates, all 0 | 1.58 / 1.47 |
| `20260613T160802Z-0b358e2c` | smoke+func+bench, no abi/docker/summary | incomplete; recorded rows pass | 1.38 |
| `20260613T161016Z-0effa4f9` | `make clean && make phase1` | 6 gates, all 0; kernel sha `55ef9d0c...` | 1.46 |

Benchmark detail (samples=1, iterations=2000, median ns/op, baseline -> policy). For
`611a3836`: lookup_visible_hot 230.2 -> 335.7, lookup_hidden 220.8 -> 250.6, open_denied 441.2 -> 307.3
(denied open is cheaper under the policy), readdir_filter 174.5 -> 269.0, build_tree_stat_walk
306.8 -> 464.2. `0effa4f9` measured every benchmark about 1.5x slower in absolute terms (for example
lookup_visible_hot 359.8 -> 524.1), with similar ratios.

The `a6740670` dmesg gate counted 6 lines. They are 2 per log (the `Command line:` and
`Kernel command line:` lines carrying `panic=30 oops=panic`) across 3 logs. None of them is a real kernel
warning. Later roots report this gate as 0.

Tracked comparison:
- `611a3836`: the doc's gates (smoke 2, functional 0, bench 0) match the raw data.
- `104213e4`: the doc says "All functional cases passed" (10/10 in raw).
- `0effa4f9`: the doc lists 6 gates all 0 and the same raw file list.
- The other 9 roots have no tracked summary.

### C. 2026-06-13 attach-ABI hardening, provenance sidecars, PASS/REDIRECT (9 roots, 1.71 MB)

What and why, in time order:
1. Attach-ABI hardening: one attach type, and rejection of multi, override, replace and cgroup-link
   attach (`docs/tmp/2026-06-13-namei-ext-attach-abi-hardening.md`).
2. Provenance sidecars: `metadata.json`, repo HEAD/status, config hashes and kernel command line
   (`docs/tmp/2026-06-13-phase1-provenance-artifacts.md`).
3. The PASS/REDIRECT action with tool-redirect benchmarks (`docs/tmp/2026-06-13-pass-redirect-implementation.md`).
   These benchmarks replace the hide/deny ones.

| Root | Kernel sha | Functional | Bench rows | Gates | Notes |
|---|---|---:|---:|---|---|
| `20260613T180909Z-d82e6c0b` | `2885791b` | 19/19 | 14 (7 benches x 2) | 6, all 0 | docker tar `fbfdd7b3` |
| `20260613T182029Z-e91efd97` | `21b551c2` | 21/21 | 14 | 6, all 0 | main `4918f88` dirty |
| `20260613T182237Z-e34d8cfa` | `21b551c2` | 21/21 | 14 | 6, all 0 | docker tar `78b09e81` |
| `20260613T185711Z-9c3953f9`, `...190051Z-4eee6ceb` | - | - | - | abi 3/3 | PASS/REDIRECT ABI: ctx_size 160, redirect_name_offset 96 |
| `20260613T190454Z-eddd2fd9` | - | **9/11** | - | failed | `attach_policy` errno 13 "load or attach failed"; no functional-done, bench or summary |
| `20260613T190520Z-f0ac9710` | `0b465b88` | 24/24 | 14 | 6, all 0 | main `4918f88` dirty |
| `20260613T191426Z-c00b979c` | `0b465b88` | 24/24 | 14 | **no summary.md** | clean tree (main `b3f3e45`, kernel `31a33d22`), empty repo-status sidecars |
| `20260613T191523Z-28aebdb8` | `0b465b88` | 24/24 | 14 | 6, all 0 | clean tree (main `006b05e`, kernel `31a33d22`); docker tar `4c1779f3` |

PASS/REDIRECT benchmarks in `28aebdb8` (median ns/op, baseline -> policy): lookup_native_hot
236.1 -> 375.9, lookup_tool_redirect 236.9 -> 368.9, access_tool_redirect 194.0 -> 327.6,
open_tool_redirect 475.4 -> 638.3, exec_tool_redirect 70,467 -> 56,351, readdir_alias_view
213.1 -> 266.0, build_tree_stat_walk 347.3 -> 542.1. The largest policy/baseline ratio is 1.69x
(access). Both variants report 0 failed operations.

Tracked comparison:
- `d82e6c0b` and `e34d8cfa`: the docs' 19 and 21 passing functional cases, 14 bench rows with fail=0,
  kernel hashes `2885791b...` and `21b551c2...`, and Docker tar hashes `fbfdd7b3...` and `78b09e81...`
  all match the raw data.
- `28aebdb8`: the docs' 24 functional passes, clean HEADs `006b05e`/`31a33d22` and kernel sha
  `0b465b88...` match.
- `c00b979c`: the validation doc ("Later Clean-Provenance Report Fix") says a clean-tree `make phase1`
  failed because the report required a non-empty kernel status sidecar (`test -s`). It does not name the
  run. `c00b979c` is the only clean-tree root without `summary.md` and has 0-byte status sidecars, so it is
  very likely that run. This is inferred.
- `eddd2fd9`, `e91efd97`, `f0ac9710` and the two ABI-only roots: no tracked summary.

### D. 2026-06-14 policy-load, policy-semantic and table-conformance gates (8 roots, 0.67 MB)

What and why:
- KVM gates that load, attach and detach every shipped BPF policy:
  `build_graph_view`, `cache_locality_view`, `checkpoint_restore_view`, `pass_only`, `redirect_alias`,
  `sandbox_fixture_view` and `table_redirect` (7 policies, 14 rows).
- Semantic branch tests per policy family.
- A static table-redirect conformance check.

Records: `docs/tmp/2026-06-14-policy-load-kvm-gate-implementation.md`, `...-policy-semantic-kvm-gate-implementation.md`,
`...-policy-report-gate-implementation.md`, `...-table-conformance-gate-implementation.md`.

| Root | Target | Result |
|---|---|---|
| `20260614T044641Z-4b962c22` | kvm-policy-load | 14/14 rows pass (7 policies x load+detach) |
| `20260614T044722Z-c16d7dc9` | phase1-smoke | abi 3/3, guest smoke done |
| `20260614T044732Z-1d2c6a72` | kvm-functional | 24/24 |
| `20260614T044739Z-8e65771d` | kvm-bench | fail=0; outlier: lookup_native_hot policy 900.8 vs baseline 245.5 ns/op (3.67x, 1 sample); other benchmarks 0.87-1.68x |
| `20260614T045249Z-156c3470` | kvm-policy-semantic | 77/77 pass rows (build_graph 18, cache_locality 16, checkpoint_restore 22, sandbox_fixture 20, plus summary); summary families=4 failures=0 |
| `20260614T045335Z-a476f6e2` | make phase1 (+ report/table-conformance rerun) | 10 gates, all 0; abi 3/3, functional 24/24, policy-load 14/14, semantic 77/77, table-conformance 16/16 |
| `20260614T-table-conformance-dev` / `-final` | table-conformance (host) | 16/16 (15 cases + summary); the two files are byte-identical |

Tracked comparison: every claim in the four docs matches the raw data. That covers the policy-load row
set, `functional_summary` pass, `bench_summary fail:0`, the semantic summary `pass:true families:4
failures:0`, the conformance summary `pass=true failures=0`, and "no `pass:false` rows" for `a476f6e2`.
`-final` has no tracked mention.

### E. 2026-06-14 aborted W2/W3 path-oracle starts (2 roots, 210 B)

`20260614T185900Z-80db64e7` (`w2-oracle.jsonl`) and `20260614T191951Z-b9d7e2e8` (`w3-oracle.jsonl`) each
hold a single `*-oracle-start` event. There are no rows, no done event and no dmesg. These are aborted
development runs of `kvm-w2-oracle`/`kvm-w3-oracle` (removed in `0f6b731`). No tracked record exists.

### F. 2026-06-14 workload path-oracle Phase 1 roots (7 roots, 4.94 MB)

What and why: full `make phase1` roots and single-target runs that add trace-derived per-workload
path oracles to the Phase 1 report. In each family the programmable policy and the `table_redirect`
baseline both run the oracle in KVM:
- W1 build graph: 9 entries.
- W2 sandbox fixture: 6 entries.
- W3 checkpoint/restore: 7 entries.
- W4 cache locality: 4 entries.

Further additions:
- W2 real nginx health and fixture-content probes.
- W4 cache-content oracle: branches `verified_hit`, `stale_fallback`, `corrupt_reject`, `miss_canonical`.
- In `w2-nginx-probes-phase1`, W1 KVM policy build replay and table-budget accounting.

Records: `docs/tmp/2026-06-14-w1-kvm-path-oracle-implementation.md`,
`...-w2-nginx-real-app-health-oracle.md`, `...-w2-nginx-fixture-content-probes.md`,
`...-w4-cache-content-oracle.md` (+ review), `...-table-budget-accounting-implementation.md`, and
`workloads/legacy/{w2-nginx-fixture,w4-buildkit-prometheus-go-cache,...}/evidence.md`.

| Root | Type | Gates | Pass rows | Highlights |
|---|---|---:|---|---|
| `20260614T-workloads-git-ceiling` | phase1 | 20, all 0 | 413/413 over 11 JSONL | W1/W2/W3/W4 oracles pass for both policies (86/62/70/46 pass rows); nginx health oracle 13 ops |
| `20260614T-w2-nginx-probes` | kvm-w2-nginx-real | - | 19/19 | 18 ops incl. 5 fixture probes (config, endpoint, fake cert, fake secret, poison) |
| `20260614T-w2-nginx-probes-phase1` | phase1 | 27, all 0 | 459/459 over 14 | adds W1 build replay (9 entries, 2 workloads, policy-replay output hash oracle true) and table-budget (4 families, `table_current_oracle_passes=4`, over-materialization 1.0, `qualified_for_c8=false`) |
| `20260614T-w4-cache-content` | kvm-w4-cache-content v1 | - | 25/25 | 4 branches pass |
| `20260614T-w4-cache-content-map` | kvm-w4-cache-content (map) | - | 27/27 | adds cgroup id + map_update; pre_attach_absent 4, attached_expected_match 4, attached_forbidden_mismatch 3, readdir_alias 4, post_detach_absent 4 |
| `20260614T-w4-cache-content-phase1` / `-map-phase1` | phase1 | 22 each, all 0 | 438/438 and 440/440 | v1 vs map variant of the W4 content oracle |

Microbenchmarks in these roots are smoke-scale (1 sample, baseline/policy). Policy/baseline
lookup_tool_redirect is 1.53-1.61x.

Tracked comparison:
- W2 probes doc: `pass=true failures=0` and `fixture_content_probe_count=5` match.
- W4 content doc: the gates `pre_attach_absent=4, attached_expected_match=4, attached_forbidden_mismatch=3,
  readdir_alias=4, post_detach_absent=4` and `branches=4` match the `-map` root.
- W1 oracle doc (`workloads-git-ceiling`): 9 entries and failures 0 match.
- `w4-cache-content-phase1` and `w4-cache-content` (v1) are not cited by exact run id. The W4 docs cite only the
  `-map` runs. `units.tsv` gives v1 two citations, but those come from substring matches on `-map`.

### G. 2026-06-15 full Phase 1 roots and partial eval/ABI roots (10 roots, 78.8 MB)

What and why: complete `make phase1` roots taken while each new hard gate landed. In run order:
1. `parent-key-poc`: parent-aware ABI. `ctx_size` 184, `parent_dev` at 160, `parent_ino` at 168.
2. `full-phase1-gatefix`: W4 parent/table/release-counterfactual report gates.
3. `full-phase1-bench-variants`: five benchmark variants (baseline, pass_only, policy,
   table_redirect_empty, table_redirect_hit).
4. `full-phase1-b12-refresh-v1`: adds W3 table replay/counterfactual and W4 table-content comparators.
5. `full-phase1-c2-setup-update-v1`: adds namei_ext setup/update raw rows.
6. `full-phase1-c2-release-sample-v1`: SAMPLES=20.

About 88-90% of the bytes are payload, not results (11.6 of 13.2 MB in `b12-refresh-v1`, 11.0 of
12.2 MB in `parent-key-poc`). The payload is `w1-release-build-replay/` (Redis/nginx release build
outputs), `w1-build-replay/` and the `*-work/` trees. Those include four or five ccache directories of
about 290 small files each, which account for most of the about 1,600 files per root.

| Root | Kernel sha | Gates | Pass rows | Bench | Notes |
|---|---|---:|---|---|---|
| `20260615T-parent-key-poc` | `a312a2bc` | 43, all 0 | 621/621 (22 JSONL) | 1 sample, base/policy | no parent-compile or release-cf yet |
| `20260615T-full-phase1-gatefix` | `a312a2bc` | 44, all 0 | 668/668 (24) | 1 sample, base/policy | W4 relcf: trace ops 40, objects 4, rule writes parent 4 / readdir 4 / table 8, sampled hit rate 0.4 |
| `20260615T-full-phase1-bench-variants` | `a312a2bc` | 47, all 0 | 668/668 (24) | 1 sample, 5 variants | table_redirect_hit map updates 66, attach successes 4 |
| `20260615T-full-phase1-b12-refresh-v1` | `8a5351a8` | 53, all 0 | 710/710 (27) | 1 sample, 5 variants; bench-status 0 | W3 table replay loads via table_redirect; W4 table content passes |
| `20260615T-full-phase1-c2-setup-update-v1` | `8a5351a8` | 53, all 0 | 710/710 (27) | 1 sample; setup 695,187 ns; source update 142,531 ns; table update 152,728 ns | summary dated 2026-06-16 |
| `20260615T-full-phase1-c2-release-sample-v1` | `8a5351a8` | 53, all 0 | 710/710 (27) | **20 samples**, 5 variants; bench-status 0 | summary dated 2026-06-16 |
| `20260615T014355Z-db92cd9f`, `20260615T-bench-variants-abi` | - | abi 3/3 | - | - | parent-aware ABI layout (ctx 184) |
| `20260615T-eval-dryrun` (03:46 PDT), `20260615T-eval-paper-parse-v1` (18:26 PDT) | - | none | policy-load 14/14, semantic 77/77 | - | incomplete: only kvm-smoke, kvm-policy-load and kvm-policy-semantic outputs (the first stages of `phase1`); no w1-oracle onward, no summary; producer not recorded |

Shared workload results in all six full roots (`parent-key-poc` has no parent-compile or
release-counterfactual step, and its policy/table compile rows lack the attached-optrace fields):
- W1 branch probes: 2 poison + 2 negative, pass. Candidate trace-witness hit rate is
  11,330 / about 3.03M host file-op lines = 0.00374.
- W1 release replay: `release_binary_hash_match=true` for Redis and nginx.
- W3 Redis replay loads checkpoint state through `checkpoint_restore`; `podman_criu_restore_executed=false`.
- W4 real ccache trace: 40 cache-path file ops (Redis 20, nginx 20 out of 134/602 traced file ops);
  trace stats cache_miss 2 / direct_cache_hit 2.
- W4 compile witnesses: policy, parent-scoped and table-only each redirected 4 objects, output hash match
  true, attached sampled operation hit rate 16/40 = 0.4. `operation_weighted_policy_hit_rate_is_release=false`
  and `qualified_for_c8=false` throughout.

Microbenchmark medians for `c2-release-sample-v1` (20 samples x 2000 iterations, ns/op; no latency
rows because BENCH_LATENCY_SAMPLES=0). This table exists nowhere in tracked docs.

| Benchmark | baseline | pass_only | policy | table_redirect_empty | table_redirect_hit |
|---|---:|---:|---:|---:|---:|
| lookup_native_hot | 243.9 | 398.4 | 405.7 | 488.5 | 481.7 |
| lookup_tool_redirect | 242.9 | 400.8 | 417.5 | 487.0 | 509.2 |
| access_tool_redirect | 203.5 | 353.1 | 368.3 | 446.9 | 458.5 |
| open_tool_redirect | 471.6 | 660.4 | 679.2 | 750.1 | 768.4 |
| exec_tool_redirect | 62,205 | 63,591 | 67,317 | 65,401 | 70,752 |
| readdir_alias_view | 209.2 | 292.7 | 296.1 | 344.3 | 360.4 |
| build_tree_stat_walk | 330.5 | 579.1 | 600.9 | 755.6 | 777.1 |

Setup/update rows in the same root (20 samples):
- Backing-tree setup: median 395,596 ns. Each setup creates 67 dirs and 66 files and writes 132 bytes.
- Source update: median 84,332 ns (65 writes, 845 bytes).
- Table update: median 61,889 ns (66 policy writes).

Tracked comparison:
- `full-phase1-gatefix-run.md`: the gate list and W4 numbers (40, 4, 4/4/8, 0.4) match.
- `full-phase1-bench-variants-run.md` and `kvm-bench-policy-baseline-variants.md`: 0 failing ops,
  4 attach successes and 66 map updates match.
- `namei-ext-setup-update-raw-rows.md`: setup 67/66/132 and update 65 writes / 845 bytes / 66 policy
  writes match.
- `c2-setup-update-release-repetition-implementation.md`: 20 samples and benchmark failure rows 0 match.
- `parent-aware-namei-abi-implementation.md`: ctx 184 / parent_dev 160 and all failing-case gates 0 match.
- The ledger verdicts those docs quote (`release_gate_pass=false`, `qualified_families=0`) come from
  separate eval roots outside this slice. They were not re-checked here.
- `eval-dryrun`, `eval-paper-parse-v1`, `db92cd9f`: no tracked record.

### H. 2026-06-15 `kvm-bench` microbenchmark pilots and variants (23 roots, 9.9 MB)

What and why: these runs develop the B2/B8 performance evidence:
- Batch latency sampling (`kvm-bench-latency-sampling.md`).
- Randomized variant order plus system metrics. v1 hit a lost-exit-status bug that left
  `"status":}` (invalid JSON) as the last line, so it is marked failed. v2/v3 write `bench-status.txt`
  (`eval-osdi-run-order-system-metrics-implementation.md`).
- Release-scale 20-sample runs (`eval-osdi-release-sample-pilot.md`, `eval-osdi-batch64-release-run.md`).
- Three kernel fast-path experiments: an RCU-walk PASS fast path, RCU REDIRECT "unlazy", and a ctx-init
  split (`rcu-pass-fastpath-negative-result.md`, `ctx-init-split-poc-implementation.md`).
- getrusage, no-hook baseline and variant-selector diagnostics (`bench-rusage-diagnostic-implementation.md`,
  `kvm-bench-variant-selector-implementation.md`, `rusage-nohook-tail-diagnostic.md`,
  `tail-sample-density-diagnostic.md`).
- C2 setup/update repetition smokes.

Every root has `fail=0` for every bench and latency row. Every root that has `bench-status.txt` reads 0.

How to read the ratios:
- Release-style roots use 20 samples x 2000 iterations.
- p99 is computed over the batch-latency rows of one (benchmark, variant) cell, as nearest rank. With 20
  rows that equals the maximum. Tail10 runs have 200 rows per cell.
- "med lookup" is the ratio of medians, variant / baseline, for lookup_tool_redirect.

| Root | Kernel sha | Config (samples x iters, latency samples x batch) | med lookup pass / pol / table-hit | max p99 ratio pass_only/base | max p99 ratio policy/base |
|---|---|---|---|---|---|
| `bench-variants-smoke` | (no metadata) | 1x2000 | 1.56 / 1.59 / 1.98 | - | - |
| `kvm-bench-latency-pilot` | (no metadata) | 1x200, 2x4 | 1.73 / 1.66 / 2.15 | (n=2) | (n=2) |
| `kvm-bench-order-metrics-pilot` (v1, failed) | - | 1x200, 2x4 | 1.49 / 1.49 / 1.75 | - | - |
| `...-order-metrics-pilot-v2` / `-v3` | - / `77134a80` | 1x200, 2x4 | 0.94 / 1.55 / 1.81 and 1.56 / 1.60 / 1.99 | - | - |
| `kvm-bench-release-sample-pilot` | `77134a80` | 20x2000, 1x4 | 1.56 / 1.62 / 2.02 | 4.365 (access) | 8.178 (readdir) |
| `kvm-bench-release-batch64-v1` | `77134a80` | 20x2000, 1x64 | 1.58 / 1.63 / 2.02 | 1.712 (tree walk) | 1.770 (tree walk) |
| `kvm-bench-rcu-pass-smoke-v1` / `-batch64-v1` | `fd0bb367` | 1x500 / 20x2000, 1x64 | 1.23 / 2.10 / 2.76 (batch64) | 1.484 (lookup_native) | 2.489 (tree walk) |
| `kvm-bench-rcu-redirect-unlazy-smoke-v1` / `-batch64-v1` | `7b0a7dbe` | 1x500 / 20x2000, 1x64 | 1.26 / 1.41 / 1.76 (batch64) | 1.375 (tree walk) | 2.430 (access) |
| `kvm-bench-post-rcu-experiment-stable-smoke-v1` | `7d00f7cc` | 1x500, 1x64 | 1.73 / 1.64 / 2.02 | - | - |
| `kvm-bench-ctx-init-split-smoke-v1` / `-batch64-v1` | `8a5351a8` | 1x500 / 20x2000, 1x64 | 1.57 / 1.59 / 2.02 (batch64) | 1.095 (access) | 1.812 (lookup_native) |
| `kvm-bench-ctx-init-split-tail10-v1` | `8a5351a8` | 20x2000, 10x64 | 1.58 / 1.64 / 2.03 | 2.624 (tree walk) | 4.374 (readdir) |
| `kvm-bench-rusage-smoke-v1` / `-tail10-v1` | `8a5351a8` | 1x500 / 20x2000, 10x64 | 1.64 / 1.66 / 2.07 (tail10) | 1.773 (tree walk) | 1.804 (tree walk) |
| `kvm-bench-variant-selector-full-smoke-v1` | `8a5351a8` | 1x500, 5 variants | 2.53 / 2.60 / 3.08 | - | - |
| `kvm-bench-nohook-baseline-smoke-v1` / `-tail10-v1` | `8a5351a8` | baseline only, 1x500 / 20x2000, 10x64 | - | - | - |
| `kvm-bench-baseline-passonly-tail10-v1` | `8a5351a8` | baseline+pass_only, 20x2000, 10x64 | 1.62 (pass) | 1.323 (open) | - |
| `kvm-bench-namei-ext-setup-update-smoke-v1` | `8a5351a8` | 1x200; setup 832,421 ns, src update 139,898 ns, table update 95,598 ns | 2.46 / 1.63 / 2.17 | - | - |
| `kvm-bench-c2-repetition-smoke-v1` | `8a5351a8` | 2x100, 0 latency; setup median 735,686 ns, src update 142,207 ns | 1.48 / 1.58 / 1.82 | - | - |

Release-batch64 detail (`kvm-bench-release-batch64-v1`, 20 samples): median ns/op, with p99 of 20
batch-64 rows in brackets.

| Benchmark | baseline | pass_only | policy | table_redirect_hit |
|---|---|---|---|---|
| lookup_native_hot | 242.9 [309.0] | 379.1 [436.2] | 382.5 [398.4] | 473.7 [528.0] |
| lookup_tool_redirect | 243.7 [300.2] | 384.0 [438.5] | 396.3 [454.3] | 491.8 [531.4] |
| access_tool_redirect | 197.1 [252.2] | 344.8 [405.4] | 356.8 [377.3] | 445.9 [486.7] |
| open_tool_redirect | 478.1 [650.3] | 655.6 [682.1] | 661.5 [720.4] | 754.9 [998.9] |
| exec_tool_redirect | 57,728 [62,117] | 71,032 [69,473] | 61,118 [67,236] | 61,184 [61,737] |
| readdir_alias_view | 203.3 [234.3] | 271.0 [286.9] | 281.6 [287.1] | 338.4 [361.4] |
| build_tree_stat_walk | 334.0 [329.8] | 566.4 [564.5] | 583.0 [583.9] | 770.3 [772.0] |

Rusage (tail10 run): median per-op system CPU per variant is baseline 251.5 ns, pass_only 403.5,
policy 405.0, table_redirect_empty 491.2, table_redirect_hit 506.0. No-hook tail10 baseline medians
are within 4% of the rusage-tail10 baselines for six benchmarks and 6.7% for exec (for example
lookup_tool_redirect 243.3 vs 244.8, open_tool_redirect 474.3 vs 478.5 ns/op).

Three tail10 `bench.jsonl` files are larger than 1 MB (`ctx-init-split-tail10-v1` 1.31 MB,
`rusage-tail10-v1` 3.45 MB, `baseline-passonly-tail10-v1` 1.37 MB), so they are not on the keep-list.
Their per-cell latency statistics, which the docs' tail ratios depend on, are recorded here:

`20260615T-kvm-bench-ctx-init-split-tail10-v1` (p50 / p99 ns/op, 200 batch-64 rows per cell):

| Benchmark | base | pass_only | policy | t_empty | t_hit |
|---|---|---|---|---|---|
| lookup_native_hot | 253.7 / 296.1 | 400.5 / 633.4 | 400.4 / 451.9 | 487.4 / 576.0 | 489.0 / 557.3 |
| lookup_tool_redirect | 255.0 / 420.9 | 401.0 / 695.5 | 409.0 / 459.7 | 486.4 / 557.8 | 506.3 / 563.7 |
| access_tool_redirect | 212.1 / 389.8 | 360.8 / 570.0 | 368.0 / 419.2 | 444.3 / 520.6 | 463.1 / 530.8 |
| open_tool_redirect | 484.9 / 546.3 | 665.2 / 1,066.0 | 673.1 / 730.8 | 746.3 / 818.2 | 760.5 / 828.3 |
| exec_tool_redirect | 50,740 / 64,882 | 51,176 / 59,254 | 50,952 / 55,501 | 51,182 / 65,782 | 51,578 / 65,416 |
| readdir_alias_view | 192.2 / 209.1 | 270.0 / 432.8 | 269.7 / 914.7 | 333.2 / 374.2 | 334.9 / 473.8 |
| build_tree_stat_walk | 325.1 / 341.5 | 570.0 / 896.1 | 583.8 / 597.6 | 743.5 / 758.6 | 775.3 / 791.4 |

`20260615T-kvm-bench-rusage-tail10-v1` (p50 / p99 ns/op, 200 batch-64 rows per cell):

| Benchmark | base | pass_only | policy | t_empty | t_hit |
|---|---|---|---|---|---|
| lookup_native_hot | 253.9 / 304.5 | 398.9 / 448.3 | 400.4 / 450.5 | 487.6 / 561.7 | 488.3 / 575.2 |
| lookup_tool_redirect | 254.8 / 302.2 | 401.3 / 456.8 | 409.8 / 475.3 | 488.0 / 556.4 | 505.8 / 564.2 |
| access_tool_redirect | 209.8 / 274.5 | 355.8 / 429.1 | 362.4 / 408.5 | 441.8 / 530.5 | 456.0 / 498.9 |
| open_tool_redirect | 485.2 / 526.8 | 664.0 / 723.8 | 671.0 / 756.2 | 748.7 / 1,168.0 | 759.1 / 832.9 |
| exec_tool_redirect | 51,938 / 57,465 | 53,509 / 57,894 | 52,924 / 58,774 | 53,764 / 64,744 | 52,301 / 61,799 |
| readdir_alias_view | 192.7 / 211.2 | 268.8 / 297.8 | 270.3 / 300.3 | 333.8 / 372.2 | 335.1 / 371.4 |
| build_tree_stat_walk | 322.6 / 330.6 | 568.4 / 586.1 | 581.6 / 596.5 | 748.8 / 765.6 | 771.8 / 797.4 |

`20260615T-kvm-bench-baseline-passonly-tail10-v1` (p50 / p99 ns/op, 200 batch-64 rows per cell):

| Benchmark | base | pass_only |
|---|---|---|
| lookup_native_hot | 255.2 / 416.9 | 403.6 / 481.6 |
| lookup_tool_redirect | 254.7 / 1,485.2 | 404.8 / 466.4 |
| access_tool_redirect | 212.9 / 349.0 | 365.3 / 447.9 |
| open_tool_redirect | 487.5 / 564.8 | 669.0 / 747.2 |
| exec_tool_redirect | 52,826 / 65,537 | 52,803 / 59,401 |
| readdir_alias_view | 194.4 / 294.3 | 270.8 / 305.4 |
| build_tree_stat_walk | 327.0 / 580.1 | 573.5 / 600.4 |

Single-sample smokes (`*-smoke-v1`, `variant-selector`, `setup-update-smoke`) show variant/baseline
median ratios up to 7.6x on single cells (the maximum is variant-selector table_redirect_hit
readdir_alias_view). They are noisy order effects at 1x500 and should not be read as
results. The tracked docs use them only as pass/fail plumbing checks.

Tracked comparison: the p99 ratios recomputed from raw rows match every number the docs report.
- `eval-osdi-batch64-release-run.md`: max policy/native 1.77x and pass-only 1.71x (tree walk);
  lookup_tool_redirect above 1.5x (raw 1.51).
- `eval-osdi-performance-comparison-verdict.md` (release-sample-pilot): `max_policy_to_native_p99_ratio=8.179`
  and pass-only 4.365.
- `rcu-pass-fastpath-negative-result.md`: 2.49x/1.48x (RCU PASS) and 2.43x/1.38x (unlazy); the unlazy
  lookup_native_hot is 1.56x.
- `ctx-init-split-poc-implementation.md`: 1.8124 / 1.0946.
- `tail-sample-density-diagnostic.md`: 4.374 (readdir) / 2.624 (tree walk).
- `rusage-nohook-tail-diagnostic.md` and `2026-06-17-c5-rusage-nohook-ablation-ledger.md`: matched
  pass-only 1.323 (open), 1.284 (access), lookup_tool 0.314; full pass-only/native 1.7728; pass-only/no-hook 1.306.
- Row counts: latency-pilot 35/70, release-sample-pilot 700/700, rusage and variant-selector 35/35,
  no-hook 7/7.

The FUSE speedup figures in these docs (for example 1.33x and 1.64x) use external-baseline roots outside
this slice and were not checked. `order-metrics-pilot-v2` is not cited.

### I. 2026-06-15 W4 ccache parent-scoped policy PoCs (20 roots, 8.7 MB)

What and why: these roots iterate on a parent-scoped `cache_locality_view` rule. One eBPF rule per cache
leaf parent rewrites `component` to `component.local`, replacing one exact entry per object. It is
exercised during real ccache hot compiles of Redis and nginx in KVM
(`kvm-w4-ccache-parent-compile`, removed in `0f6b731`). Each `*-poc` also reruns `kvm-w4-ccache-trace` and
`kvm-w4-ccache-policy-bridge`, and both pass in all 14 non-load roots (trace: 40 cache-path ops,
4 objects). Each `*-load` root is a `kvm-policy-load` gate (14/14) for that policy build.

Most of each PoC root's about 600 files are payload: the `w4-ccache-parent-compile-work/ccache` tree has
289 small files (about 100 KB in `final-poc`), plus the trace and bridge work trees.

| Root | Result | Key evidence |
|---|---|---|
| `w4-parent-debug-poc` | **failed**: 4 failures | `attached_visible_match` failed 4/4 ("visible cache object did not resolve to backing"); debug counters after attached checks: lookup_events 184, parent_key_hits 8, parent_redirects 8; after compile: 9,661 lookups, 24 hits/redirects |
| `w4-parent-rule-poc`, `w4-parent-wildcard-poc` | **failed**: 4 failures each | same `attached_visible_match` 0/4 failure; no done event |
| `w4-parent-final-poc` | pass | 4 redirected objects; ccache stats cache_miss 0, direct_cache_hit 2, local_storage_hit 2; rule updates parent 4 / readdir 4 / table-equivalent 8; output hash match |
| `w4-parent-suffixguard-poc` | pass | same stats; debug parent_redirects 4 (attached checks) / 20 (compile) out of 8 / 24 parent-key hits |
| `w4-parent-shape-poc`, `w4-parent-shape-hardgate` | pass | adds object-shape guard and negative sibling probe; `parent_sibling_pass_count=1` |
| `w4-valid-sibling-witness`, `-backing-absent`, `-content-pass`, `-structured-oracle` | pass | valid-shape non-witness sibling is not redirected; structured oracle has `valid_shape_sibling_{prepare,backing_absent,content_pass}_count=1` |
| `w4-release-counterfactual` | pass (negative C8 evidence) | same-run table-only compile also passes; trace ops 40, objects 4; parent rule writes 4 + readdir 4 vs table writes 8 (ratio 2); `eligible_object_policy_hit_rate=1`, `cache_path_policy_coverage=0.1`, `table_budget_failure=false` |
| `w4-attach-window-optrace`, `-gatefix` | pass | adds strace of the attached compile: attached cache-path ops 40 (20+20), policy object ops 16, sampled op hit rate 0.4 (`_is_release=false`) |
| `w4-parent-{debug,rule,wildcard,final,suffixguard,shape}-load` | pass | 14/14 policy-load rows each |

Tracked comparison:
- `w4-parent-scoped-cache-policy-implementation.md`: debug `parent_key_hits=8`/`parent_redirects=8`;
  the failure explained as the backing `.local` path being redirected again; the final/shape stats
  2/2/0 and 4/4/4/8 all match.
- `w4-parent-object-shape-negative-implementation.md`: sibling pass, count 1.
- `w4-release-counterfactual-accounting-implementation.md`: 40/4/4/4/8, hit rate 1, coverage 0.1.
- `w4-attach-window-optrace-implementation.md`: 20/20/40, 8/8/16, 0.4.
- `w4-attach-window-report-gate-fix.md`: the `-gatefix` rerun exists because the report gate expected 4
  instead of 6 lines in the output sha files. Raw JSONL in both roots is identical in outcome.
- No tracked record: the `rule`, `wildcard` and `suffixguard` PoCs and loads, the `debug-load`, and the
  `witness`, `backing-absent` and `content-pass` sibling iterations. For those, this table is the record.

### J. 2026-06-15 W2/W3/W4 workload smokes (4 roots, 0.31 MB)

| Root | Target | Result |
|---|---|---|
| `20260615T-w2-nginx-c2-macrobench-smoke-v1` | kvm-w2-nginx-macrobench, 2 samples | pass; setup_ns 11,799,476 / 8,402,519; update_ns 12,160 / 15,237; all correctness probes pass; `c2_supported=false` |
| `20260615T-w2-nginx-c2-macrobench-release-sample-v1` | same, 20 samples | pass, 20/20 correctness rows. Setup median 7,283,162 ns (min 6,935,363, max 9,311,575; 5 dirs, 12 files, 293 B written, 5,638 B copied). Update median 12,538 ns (min 10,829, max 32,387; 3 source writes, 0 policy writes). `release_gate_pass=false` |
| `20260615T-w3-redis-counterfactual-smoke-v1` | kvm-w3-redis-counterfactual | pass. Redis checkpoint replay passes via both `checkpoint_restore` (12/12) and `table_redirect` (13/13); `table_rule_writes=2`, `table_budget_failure=false`. The table-only replay also passing is negative C8 evidence |
| `20260615T-w4-cache-table-content-smoke-v1` | kvm-w4-cache-table-content | pass. 26/26 oracle rows, 4 branches, `content_equivalent_table_oracle=true`. This is negative C8 evidence: table-only reproduces the W4 content oracle |

Tracked comparison:
- `w2-nginx-c2-kvm-macrobench-implementation.md`: per-sample setup/update ns match.
- `...-release-sample-run.md`: min/max setup and update ns and row counts match.
- `w3-table-replay-counterfactual-implementation.md`: policy/table replay pass and `table_rule_writes=2`
  match.
- `w4-cache-table-content-counterfactual-implementation.md`: branches 4 and table baseline pass match.

### Doc vs raw mismatches

None found. No tracked doc states a number that the raw files contradict.

Checked statements (doc:line, what the doc says, what the raw data shows):
- `docs/tmp/2026-06-13-phase1-validation-and-artifact-gates-implementation.md:91-96`: 6 gates for
  `0effa4f9`, smoke 2 and the others 0. Raw summary.md is identical.
- `docs/tmp/2026-06-13-namei-ext-attach-abi-hardening.md:138,151,157,180,184,192,198`: 19 and 21 functional
  passes, 14 bench rows, kernel sha `2885791b`/`21b551c2`, Docker tar `fbfdd7b3`/`78b09e81`. Raw is
  identical.
- `docs/tmp/2026-06-13-pass-redirect-implementation.md:119,131,137`: 24 functional passes, clean HEADs, and
  kernel sha `0b465b88`. Raw is identical.
- `docs/tmp/2026-06-14-policy-semantic-kvm-gate-implementation.md:93`: summary `families:4 failures:0`.
  Raw is identical.
- `docs/tmp/2026-06-14-w2-nginx-fixture-content-probes.md:153`: `fixture_content_probe_count=5`. Raw
  has 5 probe ops.
- `docs/tmp/2026-06-14-w4-cache-content-oracle.md:115-116`: gates 4/4/3/4/4. Raw `-map` op counts are
  identical.
- `docs/tmp/2026-06-15-eval-osdi-batch64-release-run.md:90-92`: 1.77x / 1.71x. Raw computes to
  1.770 / 1.712.
- `docs/tmp/2026-06-15-rcu-pass-fastpath-negative-result.md:75-77,133-135`: 2.49x / 1.48x and 2.43x /
  1.38x. Raw computes to 2.489 / 1.484 and 2.430 / 1.375.
- `docs/tmp/2026-06-15-ctx-init-split-poc-implementation.md:116-118`: 1.8124 / 1.0946. Raw is
  identical.
- `docs/tmp/2026-06-15-tail-sample-density-diagnostic.md:94-96,114-115`: 4.374 / 2.624, and
  lookup_native policy p99 756 vs 452 ns. Raw is identical.
- `docs/tmp/2026-06-15-eval-osdi-performance-comparison-verdict.md:155-157`: 8.179 / 4.365. Raw is
  identical.
- `docs/tmp/2026-06-15-rusage-nohook-tail-diagnostic.md:101-119`: 0.981, 1.306, 1.244 and
  1.323/1.284/1.155/1.038/1.035/0.906/0.314. Raw is identical.
- `docs/tmp/2026-06-15-kvm-bench-latency-sampling.md:150-162`: 35 bench and 70 latency rows, 66 map
  updates. Raw is identical.
- `docs/tmp/2026-06-15-eval-osdi-release-sample-pilot.md:47-49`: 700/700/700 rows. Raw is identical.
- `docs/tmp/2026-06-15-namei-ext-setup-update-raw-rows.md:33-37`: setup 67/66/132, update 65/845 and
  66. Raw is identical.
- `docs/tmp/2026-06-15-c2-setup-update-release-repetition-implementation.md:72-78`: 2 setup rows, 2+2
  update rows, 70 bench rows. Raw is identical.
- `docs/tmp/2026-06-15-w4-parent-scoped-cache-policy-implementation.md:52,94-106`: debug hits and
  redirects 8/8, stats 2/2/0, rule updates 4/4/4/8. Raw is identical.
- `docs/tmp/2026-06-15-w4-release-counterfactual-accounting-implementation.md:96-104` and
  `...-w4-attach-window-optrace-implementation.md:67-74`: 40/4/4/4/8/1/0.1 and 20/20/40, 8/8/16, 0.4.
  Raw is identical.
- `docs/tmp/2026-06-15-w2-nginx-c2-kvm-macrobench-release-sample-run.md:57-69` and
  `...-implementation.md:126-134`: setup/update min/max and per-sample ns. Raw is identical.

Not checked: ratios against FUSE and other external baselines, and the `eval-osdi` ledger verdicts. They
depend on `results/eval-osdi/...` roots outside this slice.

Information that exists only in the raw roots (not a mismatch):
- The 6-line dmesg false positive in `20260613T155621Z-a6740670`.
- The `20260613T190454Z-eddd2fd9` attach failure (errno 13).
- The failed W4 parent `rule`/`wildcard` PoCs.

Inferred, not evidenced:
- `20260613T191426Z-c00b979c` as the clean-tree run whose report failed.
- `eval-dryrun` and `eval-paper-parse-v1` as runs stopped after policy-semantic.

Keep-list: `p1-phase1-early-keep.tsv` lists 52 small aggregate/raw-row files (3.56 MB in total). Each is
either the run's `summary.md` or the single JSONL holding the cited numbers. It covers every run whose
numbers the docs state, except the three tail10 `bench.jsonl` files above 1 MB. Their per-cell
statistics are in section H.
