## Phase 1 roots of 2026-07-12 .. 2026-08-08 (`results/phase1/202607*`, `results/phase1/202608*`)

Slice: 83 untracked units, 405,080,372 bytes, 84,160 files. 98% of the bytes (396.6 MB) sit in
nine W4 ccache roots (2026-07-23/24): compile work directories with object files,
strace logs and ccache trees. The other 74 units are small JSONL/dmesg/kernel-config
roots, under 300 KB each, written by the Phase 1 KVM suites. Eight roots are empty
(0 bytes). Per-unit rows are in `p3-phase1-late.csv`. All numbers below were
recomputed from the raw files on 2026-10-10 with read-only scripts.

### Producers (common to the whole slice)

- **Phase 1 suites.** The top-level `Makefile` defines `phase1: phase1-smoke kvm-policy-load kvm-functional`, and `phase1-smoke` includes `abi` and `kvm-smoke`. The KVM recipes are in `mk/kvm.mk`: `kvm-smoke`/`__phase1_guest_smoke` write `guest-smoke.jsonl`, `uname.txt`, `proc-version.txt`, `kernel-cmdline.txt`, `config-namei-ext.txt`, `kernel.config` and `dmesg-smoke.log`. `kvm-policy-load` writes `policy-load.jsonl`, `kvm-functional` writes `functional.jsonl`, `kvm-policy-semantic` writes `policy-semantic.jsonl`, and `kvm-bench` writes `bench.jsonl` and `metadata.json`. `abi` (`tests/abi`) writes `abi.jsonl` on the host. `PHASE1_RESULT_DIR = results/phase1/$(RUN_ID)`, and the default `RUN_ID` is `<UTC timestamp>Z-<8 hex>`, which is how the hash-named roots got their names. The file set therefore shows which targets ran:
  - 1 file (`abi.jsonl`): `make abi`
  - 2 files (`functional` or `policy-semantic` plus dmesg): `make kvm-functional` or `make kvm-policy-semantic`
  - 7 files: `kvm-smoke`
  - 8 files: `phase1-smoke`
  - 12 files: `make phase1`
  - 14 files: `make phase1` plus `make kvm-policy-semantic` with the same `RUN_ID`
- Git history of the `Makefile` starts at `179e642` (2026-07-15). The 2026-07-13 recipes are known only from `docs/tmp/2026-07-13-*.md`.
- **W4 ccache.** `make experiment-env-cache BUILD_CACHE_SAMPLES=N` was added in `ce87d81` (2026-07-23). Commit `cc8415d` (2026-07-27) renamed it to `legacy-build-cache`/`kvm-build-cache-matrix` in `mk/experiments/legacy_build_cache.mk`. It runs the `__phase1_guest_w4_ccache_bulk_*` sub-targets into `results/phase1/<RUN_ID>/` (a staging root) and then copies the JSONL, sha256 and dmesg files into `results/experiments/build-cache/<RUN_ID>/`. Two other targets were added on 2026-07-23 in `mk/kvm.mk` and moved to `mk/experiments/legacy_build_cache.mk` in `cd2461d`: `make kvm-w4-ccache-bulk-compile-epoch-switch` (`16c5ee6`) and `make kvm-w4-ccache-bulk-bad-local-fallback` (`766206a`). Neither one copies its results anywhere, so their `results/phase1` roots are the only raw roots.
- Every dmesg log was scanned for `BUG|WARNING|Oops|Call Trace|Kernel panic|hung_task|lockdep|KASAN|UBSAN`. Every log that exists is clean. The only `namei_ext` kernel lines are the informational "used greatest stack depth" messages in four semantic logs.

### Key findings

1. **The `docs/evaluation.md:306` epoch-switch claim matches the raw data in `20260724T-epoch-switch-release-v2`.** That root is untracked, but `docs/evaluation.md:306` and `research/STATE.md:100` cite it as the evidence root, so deleting it removes the cited path. The surviving records are this file and the totals table in `docs/tmp/2026-07-24-build-cache-real-compile-epoch-implementation.md`. Details are in the epoch-switch section below.
2. **The `docs/evaluation.md:307` bad-local claim holds.** Both one-sample probes passed for `namei_ext` and FUSE, with 80/80 non-use checks on each side.
3. **Attribution mismatch.** `docs/evaluation.md:304` gives "FUSE/namei_ext 2.18x, native/namei_ext 0.945x" with raw root `.../20260723T-build-cache-release-v1/`. The raw data for release-v1 gives **1.758x / 1.034x**, and the doc's own LPC report agrees. The 2.18x / 0.945x numbers come from **`20260723T-build-cache-state-release-v1`**, which also feeds the hot-cache sentence in `docs/paper/sections/05-evaluation.tex:296`. `docs/tmp/2026-08-02-workload-evidence-audit.md:79` repeats the numbers without naming a root. The paper numbers are correct for state-release-v1. Only the raw-root column in `docs/evaluation.md` points at the wrong run.
4. **Kernel provenance caveats.** Several runs booted a different kernel from the one their docs name:
   - The `parent-fast-path-8fd1fb52f-*` runs booted `7.1.0-rc7-gc7af99f67609-dirty #10`. The docs say "committed kernel `8fd1fb52fa8d`".
   - The RCU stage-2 runs booted `g83d52c2168e2-dirty`. `docs/evaluation.md:367` names kernel `bdc9a83e3`, and the only `bdc9a83e3` functional runs in this slice are `provenance-tsc-functional-v1/v2` (74/74 passed).
   - In the `current-bench-variants-*` runs, `metadata.json` records `kernel_repo.head = c7af99f67609` (clean), but the guest booted `gc28220593eb0-dirty #8`.
5. **Failed, incomplete and empty runs.**
   - `20260713T020031Z-271dea14` failed: `select_register_target` errno 9.
   - `20260727T125403Z-2a5cc032` is incomplete: the functional run wrote only its start event.
   - `20260724T-epoch-switch-smoke-v1` aborted at the trace stage.
   - The eight `20260727T-runlocal-stock-*` roots are 0-byte: the stock kernel image did not boot (see the provenance/boot section).
   - Every other unit passed every recorded check.

### Group A: 2026-07-13 HIDE / SELECT_TARGET bring-up (14 units)

These runs validated the `HIDE` action and the registered-target `SELECT_TARGET` action on kernel `7.1.0-rc7-g9f6695adf237-dirty` (builds #9 to #14). They are recorded in `docs/tmp/2026-07-13-namei-ext-hide-action-implementation.md`, `-select-target-implementation.md`, `-select-target-final-dir-implementation.md`, `-phase1-make-routing-cleanup.md` and `-osdi-sosp-readiness-audit.md`, and summarized in `docs/implementation.md:275-288`.

| Unit | Target | Kernel build | Result | Tracked |
| --- | --- | --- | --- | --- |
| `20260713T014606Z-009425cc` | abi | host | 3/3; enum without SELECT_TARGET | none |
| `20260713T014740Z-efb9dc00` | kvm-functional | #9 | 35/35 (HIDE stat/open/access ENOENT, readdir hide, detach restore) | hide-action doc, implementation.md: agree |
| `20260713T020000Z-df78145a`, `020026Z-7e196a49`, `020946Z-1bca35dc` | abi | host | 3/3 each; SELECT_TARGET enum present | none |
| `20260713T020031Z-271dea14` | kvm-functional | n/a (no dmesg) | **FAILED** 21/23: `select_register_target` errno 9, `functional_summary` false; no `functional-done`, no dmesg | none |
| `20260713T020334Z-fd2184f7` | kvm-functional | #11 | 44/44 | none |
| `20260713T021039Z-a5adda84` | kvm-functional | #12 | 44/44 incl. 9 select cases (final lookup rejected EOPNOTSUPP) | select-target doc, design doc, implementation.md: agree |
| `20260713T022434Z-709a5df7` | smoke + policy-load | #12 | 18/18 load+detach over all 9 BPF objects (pre-routing-cleanup set) | none |
| `20260713T022917Z-d2fd7174` | make phase1 | #12 | ABI 3/3, load 8/8 (4 policies), functional 44/44 (46 rows) | routing-cleanup, readiness audit: agree (doc says 46 functional rows) |
| `20260713T024221Z-8d9cb9a5` | make phase1 | #12 | same as above | same docs: agree |
| `20260713T030241Z-42b2c8b6` | kvm-functional | #13 | 45/45 (adds selected-root final stat/readdir) | none |
| `20260713T031516Z-997cf1c7` | kvm-functional | #14 | 49/49 (adds registry clear and unregistered-after-clear) | final-dir doc, implementation.md: agree (51 rows) |
| `20260713T052750Z-e4d3b198` | smoke + load + policy-semantic | #14 | load 8/8; semantic 76/76 (build_graph 18, sandbox_fixture 20, checkpoint_restore 22, cache_locality 16) | none |

Tracked docs cite `014740Z`, `021039Z`, `022917Z`, `024221Z` and `031516Z`, and their claims agree with the raw data. These are implementation-validation records. No paper section cites them.

### Group B: W4 ccache build-cache matrix staging roots (5 units, 2026-07-23/24)

`make experiment-env-cache` ran the Redis/nginx ccache experiment on kernel `7.1.0-rc7-g6641100ef134`. The setup is a 20-source manifest, the `cache_locality_view.bpf.c` policy, a native hot-ccache baseline and a feature-equivalent FUSE baseline. The JSONL in these staging roots is byte-identical to the tracked copies in `results/experiments/build-cache/20260723T-build-cache-{release,state-release}-v1/`, including the outputs/inputs sha256 files. The tracked release-v1 dmesg copies differ only by stripped trailing whitespace; the state-release-v1 dmesg copies are identical. The raw-only content is payload: compile work directories of about 79 MB per mechanism (`*.o`, per-object strace logs, ccache dirs), trace strace logs (about 1.2 MB), ccache stats and the source manifest. Totals below are summed per-sample `compile_ns`; the ratios are total-time ratios.

| Unit | Samples | Output matches (policy / native / FUSE) | namei_ext s | native s | FUSE s | FUSE/ne | native/ne | Extra rows |
| --- | ---: | --- | ---: | ---: | ---: | ---: | ---: | --- |
| `20260723T-build-cache-smoke-v1` | 1 | 20/20 each | 7.327 | 7.380 | 13.897 | 1.90 | 1.007 | bridge 40 objects |
| `20260723T-build-cache-release-v1` | 20 | 400/400 each | 152.263 | 157.443 | 267.749 | **1.758** | **1.034** | median per-sample s 7.07/7.05/13.17 |
| `20260723T-build-cache-state-smoke-v1` | 1 | 20/20 each | 6.504 | 6.846 | 12.954 | 1.99 | 1.052 | state row pass |
| `20260723T-build-cache-state-release-v1` | 20 | 400/400 each | 145.877 | 137.824 | 317.995 | **2.180** | **0.945** | state row: 40 setup / 80 correctness / 40 update rows; writes ne 1940 setup + 20 update, FUSE 320 + 320, 20 mounts |
| `20260724T-build-cache-bfs-integrated-smoke-v1` | 1 | 20/20 each; epoch 40/40 each | 6.388 | 7.186 | 13.574 | 2.12 | 1.125 | integrated epoch row: ne 7.19+6.36 s, FUSE 13.58+12.93 s (1.96x) |

Every sub-row reports `pass=true` and `failures=0`. All 20 per-sample policy-compile summaries pass in both release runs.

Comparison with tracked docs:

- `docs/tmp/2026-07-23-build-cache-lpc-result-report.md` (release-v1) gives a namei_ext total of 152,263,433,153 ns, 1.758x and 1.034x. These match the raw data.
- `docs/tmp/2026-07-23-build-cache-state-row-result-report.md` (state-release-v1) gives a total of 145,877,006,283 ns, 2.180x, 0.945x, and setup/update writes 1,940/20 versus 320/320. These match.
- `docs/evaluation.md:304` attaches 2.18x/0.945x to the release-v1 root. **This is wrong:** those numbers belong to state-release-v1 (key finding 3).
- `docs/tmp/2026-07-24-build-cache-real-compile-epoch-implementation.md:236-251` says the integrated smoke passed with zero failed rows. This matches.
- The smoke docs record only the commands.

The paper cites the hot-cache ratios (`05-evaluation.tex:296`) from state-release-v1, and its tracked copy survives.

### Group C: W4 real-compile epoch switch (3 units), evidence cited by `docs/evaluation.md:306`

`make kvm-w4-ccache-bulk-compile-epoch-switch` compiles the same 20 sources through ccache in two cache epochs. The `namei_ext` side switches epochs with a BPF policy-session update. The FUSE baseline uses a feature-equivalent epoch view. The plan is in `docs/tmp/2026-07-24-build-cache-real-compile-epoch-plan.md`, and the review is in `docs/tmp/2026-07-24-build-cache-real-compile-epoch-result-review.md` (verdict: valid, supporting evidence).

| Unit | Status | Evidence |
| --- | --- | --- |
| `20260724T-epoch-switch-smoke-v1` | aborted | 6 files, 1,003 B. `w4-ccache-bulk-trace.jsonl` holds only the start event. `w4-ccache-bulk-source-manifest.tsv` is 0 bytes. There is no epoch JSONL and no dmesg. Not cited. |
| `20260724T-epoch-switch-smoke-v2` | pass (1 sample) | ne epoch1/epoch2 8.045/21.455 s; FUSE 17.764/13.278 s (FUSE/ne 1.05; ne epoch 2 is the slow outlier); 40/40 outputs per system; 1 session update; 40 invalidations each |
| `20260724T-epoch-switch-release-v2` | pass (20 samples) | Below. `host-make.exit` = 0; the dmesg gate found 0 issues |

Raw numbers for `20260724T-epoch-switch-release-v2`, from the `w4-ccache-bulk-compile-epoch-switch-summary` row and 40 sample rows (all `pass=true`):

| Metric | namei_ext (`cache_locality_epoch_policy`) | FUSE (`fuse_cache_epoch_view`) |
| --- | ---: | ---: |
| Epoch 1 compile jobs / output matches / direct hits | 400 / 400 / 400 | 400 / 400 / 400 |
| Epoch 2 compile jobs / output matches / direct hits | 400 / 400 / 400 | 400 / 400 / 400 |
| Epoch 1 compile ns | 142,918,676,763 | 285,034,552,484 |
| Epoch 2 compile ns | 140,874,419,542 | 309,449,913,726 |
| Total epoch compile s | 283.793 | 594.484 |
| Cache path file ops / cache object ops | 16,000 / 6,400 | 12,000 / 6,400 |
| Policy session updates | 20 (1 per sample) | n/a |
| Update writes | 20 (1 per sample) | 800 (40 per sample) |
| Backing invalidations | 800 | 800 |
| Setup writes / FUSE mounts | 6,420 / n/a | n/a / 20 |

Derived: the total-time FUSE/namei_ext ratio is **2.0948**. The epoch-1 ratio is 1.994 and the epoch-2 ratio is 2.197. Per-sample ratios have a median of 2.017 and a mean of 2.088, with a range of 1.558 to 2.632. Per-sample medians are 13.40 s for namei_ext and 27.40 s for FUSE. `w4-ccache-bulk-compile-epoch-switch-outputs.sha256` has 3,280 entries, and the source manifest has 20 rows.

Verification of `docs/evaluation.md:306` ("Passed in KVM; 800/800 output matches; observed FUSE/namei_ext ratio 2.10x; policy session updates 20 vs 800 backing invalidations"):

- **Passed / 20 samples / 2 epochs:** confirmed (40/40 sample rows; the summary reports `pass=true` and `failures=0`).
- **800/800 output matches:** confirmed per mechanism (400 + 400 for each of namei_ext and FUSE).
- **2.10x:** the raw ratio is 2.0948. The implementation doc reports it as 2.095x, and evaluation.md rounds that up to 2.10x. Rounding the raw value to two decimals gives 2.09x. The difference is cosmetic.
- **"20 vs 800":** both numbers appear in the raw data. namei_ext makes 20 policy-session updates, while FUSE makes 800 update writes. Both systems record 800 backing invalidations, so the 800 is not a FUSE-only cost.
- `research/STATE.md:100` ("about 2.1x") agrees.
- The implementation-doc table matches every raw total above.

### Group D: W4 bad-local fallback probes (2 units), evidence cited by `docs/evaluation.md:307`

`make kvm-w4-ccache-bulk-bad-local-fallback W4_CCACHE_BULK_BAD_LOCAL_FALLBACK_MODE={stale,corrupt-hidden}` plants 40 bad local cache objects. It then checks, during a real 20-source ccache compile, that neither `namei_ext` nor FUSE uses any of them (lookup-time fallback). The design is in `docs/tmp/2026-07-24-stale-corrupt-fallback-probe-design.md`, and the implementation and results are in `docs/tmp/2026-07-24-bad-local-fallback-probe-implementation.md`.

| Unit | Mode | Samples | Output matches ne / FUSE | Non-use checks ne / FUSE | Direct hits | ne compile s | FUSE compile s | FUSE/ne |
| --- | --- | ---: | --- | --- | --- | ---: | ---: | ---: |
| `20260724T-bad-local-stale-smoke-v1` | stale | 1 | 20/20 / 20/20 | 80/80 / 80/80 | 20 / 20 | 7.838 | 13.627 | 1.74 |
| `20260724T-bad-local-corrupt-hidden-smoke-v1` | corrupt-hidden | 1 | 20/20 / 20/20 | 80/80 / 80/80 | 20 / 20 | 7.983 | 13.235 | 1.66 |

In both summaries, `pass=true`, `failures=0`, `lookup_time_fallback=true`, `bfs_probe=true`, `complete_miss_stale_corrupt_compile_state_machine=false` and `release_gate_pass=false`. The trace and policy-bridge sub-rows pass (40 trace objects), and the dmesg logs are clean.

Verification of `docs/evaluation.md:307` ("one-sample probes passed in KVM for both mechanisms"): **confirmed.** The implementation doc's "80/80 bad-local non-use checks passed in each row; dmesg gate passed" also matches. Both roots are untracked and cited.

### Group E: Phase 1 regression runs, 2026-07-25 .. 07-27 (9 units)

These are regression gates run after infrastructure and policy changes. The 07-25/26 roots ran on clean kernel `g6641100ef134`, and the 07-27 roots on `gc28220593eb0-dirty #8`.

| Unit | Target | ABI | Load | Functional | Tracked / consistency |
| --- | --- | --- | --- | --- | --- |
| `20260725T-application-file-sharing-regression-v1` | phase1 | 3/3 | 8/8 | 49/49 | none |
| `20260725T-application-file-sharing-regression-v2` | phase1 | 3/3 | 8/8 | 49/49 | `2026-07-25-sandboxed-application-file-sharing-preflight-implementation.md`: agrees |
| `20260726T-infra-phase1-v1` | phase1 | 3/3 | 8/8 | 49/49 | none |
| `20260726T-infra-phase1-v2` | phase1 | 3/3 | 8/8 | 49/49 | `2026-07-26-unified-experiment-infrastructure-{implementation,audit}.md`: agrees ("three ABI, ten policy-load records, 51 functional records", counting lifecycle rows) |
| `20260726T-unified-suite-phase1-v1` | phase1 | 3/3 | 8/8 | 49/49 | `2026-07-26-unified-suite-contract-convergence.md`: agrees |
| `20260727T-infra-followup-phase1-v1` | phase1-smoke | 3/3 | n/a | n/a | `2026-07-27-unified-infrastructure-followup-audit.md`: agrees |
| `20260727T-suite-catalog-phase1-smoke-v1` | phase1-smoke | 3/3 | n/a | n/a | `2026-07-27-formal-suite-catalog-cleanup.md`: agrees |
| `20260727T125353Z-9e09c808` | phase1 (default id) | 3/3 | 8/8 | 67/67 (18 new `scope_*` cases) | none |
| `20260727T125403Z-2a5cc032` | phase1 (default id, 10 s after the previous run) | 3/3 | 8/8 | **0: only `functional-start`, no `dmesg-functional.log`** | none. Incomplete: the functional stage never wrote a case. The cause is not recorded. |

### Group F: `kvm-bench` current-variant smoke (4 units, 2026-07-27)

These came from `make kvm-bench RUN_ID=20260727T-current-bench-variants-vN SAMPLES=1 BENCH_ITERS=1000 BENCH_LATENCY_SAMPLES=0`, with variants `baseline pass_only policy`, randomized order, 4 vCPU and 8 GB. Each run has `bench-status.txt` = 0, `bench-done status=0`, 21 bench rows with `fail=0` and a clean dmesg. The main repo is `2009f8cab`, dirty with Makefile/bench edits. `metadata.json` records the kernel repo as `c7af99f67609` (clean), but the guest booted `gc28220593eb0-dirty #8`. These are single-sample infrastructure checks, not performance results.

| ns/op (baseline / pass_only / policy) | v1 | v2 | v3 | v4 |
| --- | --- | --- | --- | --- |
| lookup_native_hot | 522 / 744 / 739 | 328 / 527 / 450 | 514 / 729 / 726 | 326 / 450 / 455 |
| lookup_tool_redirect | 525 / 735 / 835 | 330 / 447 / 509 | 517 / 733 / 821 | 333 / 506 / 570 |
| access_tool_redirect | 402 / 610 / 692 | 293 / 431 / 442 | 393 / 618 / 677 | 269 / 386 / 441 |
| open_tool_redirect | 1016 / 1248 / 1328 | 675 / 797 / 850 | 1028 / 1266 / 1292 | 672 / 806 / 921 |
| readdir_alias_view | 434 / 604 / 639 | 292 / 404 / 405 | 447 / 597 / 609 | 326 / 410 / 421 |
| build_tree_stat_walk | 713 / 1128 / 1247 | 461 / 717 / 763 | 691 / 1174 / 1213 | 478 / 691 / 774 |
| exec_tool_redirect (10 ops) | 98324 / 117558 / 95034 | 99562 / 111945 / 89538 | 111373 / 117056 / 102177 | 89705 / 94245 / 113157 |

v1 and v3 are about 1.5x slower across the board than v2 and v4. With one sample each, that is run-to-run noise. Tracked: `docs/tmp/2026-07-27-unified-infrastructure-followup-audit.md` cites only v4 ("only backing_tree/baseline/pass_only/policy records, no table record, `policy_variants=["pass_only","policy"]`"). The raw data agrees: v4's `bench-start` row carries `policy_variants`, and v1 to v3 do not.

### Group G: 2026-07-27 fast-path redesign and RCU decision (5 units)

These are the correctness gates for the FxMark fast-path alternatives in `docs/tmp/2026-07-27-namei-ext-fast-path-redesign.md`: out-of-line slow path, in-place `try_to_unlazy`, and RCU-walk decision. Each root is `make phase1` plus `make kvm-policy-semantic` and has 145 JSONL records.

| Unit | Kernel | ABI | Load | Functional | Semantic | Tracked |
| --- | --- | --- | --- | --- | --- | --- |
| `20260727T-out-of-line-fastpath-v1` | g6641100ef134-dirty #3 | 3/3 | 8/8 | 49/49 | 76/76 | redesign doc describes the variant; no run id |
| `20260727T-in-place-unlazy-v1` | g309a05d87e98-dirty #4 | 3/3 | 8/8 | 49/49 | 76/76 | redesign doc: "passed all correctness gates", agrees |
| `20260727T-rcu-decision-v1` | g309a05d87e98-dirty #5 | 3/3 | 8/8 | 49/49 | 76/76 | none |
| `20260727T-rcu-decision-v2` | g309a05d87e98-dirty #6 | 3/3 | 8/8 | 49/49 | 76/76 | none |
| `20260727T-rcu-decision-final` | g309a05d87e98-dirty #7 | 3/3 | 8/8 | 49/49 | 76/76 | `2026-07-27-namei-ext-rcu-decision-implementation.md`: agrees (3/3, 8/8, 49/49, 76/76) |

The redesign doc's throughput figures (for example, PASS 0.97M to 1.01M to 1.25M ops/s) come from FxMark preflights under `results/experiments/fxmark-rq2-preflight/`, not from these roots.

### Group H: 2026-07-27 parent/global fast path and policy-parent dispatch (7 units)

These validate the parent-scope (`EXACT`/`GLOBAL`/inherit) dispatch. The functional suite has 67 cases, including 18 `scope_*` cases.

| Unit | Target | Kernel | Result | Tracked |
| --- | --- | --- | --- | --- |
| `20260727T-global-parent-fast-path-phase1-v1` | phase1 | gc7af99f67609-dirty #9 | 3/3, 8/8, 67/67 | none |
| `20260727T-global-parent-fast-path-phase1-v2` | phase1 | gc7af99f67609-dirty #10 | 3/3, 8/8, 67/67 | none |
| `20260727T-global-parent-fast-path-semantic-v1` | kvm-policy-semantic | #9 | 76/76 | none |
| `20260727T-global-parent-fast-path-semantic-v2` | kvm-policy-semantic | #10 | 76/76 | none |
| `20260727T-parent-fast-path-8fd1fb52f-phase1` | phase1 | gc7af99f67609-dirty #10 | 3/3, 8/8, 67/67 | `...-global-parent-fast-path-{design,implementation}.md`: pass counts agree; **kernel differs** |
| `20260727T-parent-fast-path-8fd1fb52f-semantic` | kvm-policy-semantic | gc7af99f67609-dirty #10 | 76/76 | same docs: agree; same kernel caveat |
| `20260727T-policy-parent-v1` | phase1 + semantic | gc28220593eb0-dirty #8 | 3/3, 8/8, 67/67, 76/76 (163 records) | `2026-07-27-namei-ext-policy-parent-dispatch.md`: agrees exactly (163 records) |

Kernel caveat: the docs say "Kernel commit `8fd1fb52fa8d...` passed ... results/phase1/20260727T-parent-fast-path-8fd1fb52f-phase1". The guest's `Linux version` line in all three dmesg logs is `7.1.0-rc7-gc7af99f67609-dirty #10`, the same build as `global-parent-fast-path-phase1-v2`. The first `g8fd1fb52fa8d` build (#11) appears in Group I. The tested source was probably the uncommitted change that later became `8fd1fb52f`, but the root does not prove that.

### Group I: 2026-07-27 RCU target registry (stage 1) and borrowed target (stage 2) (9 units)

These are the correctness gates for `docs/tmp/2026-07-27-namei-ext-rcu-target-selection-{design,implementation}.md`. Functional-case growth across the runs:

- 67 cases to start.
- 71: adds `select_replace_target`, `select_restore_target` and the replacement/restored reads.
- 72: adds `select_concurrent_replacement`, where each read observed exactly one complete target.
- 74: adds `select_portal_final_cached` and `select_portal_payload_cached` (`openat2 RESOLVE_CACHED`).

| Unit | Target | Kernel | Result | Tracked |
| --- | --- | --- | --- | --- |
| `20260727T-rcu-target-registry-stage1-phase1` | phase1 | g8fd1fb52fa8d-dirty #11 | 3/3, 8/8, 67/67 | design doc stage-1 text (no run id) |
| `20260727T-rcu-target-registry-stage1-semantic` | semantic | #11 | 76/76 | same |
| `20260727T-rcu-target-registry-stage1-v2-functional` | functional | g8fd1fb52fa8d-dirty #12 | 71/71 | none |
| `20260727T-rcu-target-registry-stage1-v2-semantic` | semantic | #12 | 76/76 | none |
| `20260727T-rcu-borrowed-target-stage2-functional-v1` | functional | g83d52c2168e2-dirty #13 | 71/71 | none |
| `20260727T-rcu-borrowed-target-stage2-concurrent-v1` | functional | #13 | 72/72 | none |
| `20260727T-rcu-borrowed-target-stage2-semantic-v1` | semantic | #13 | 76/76 | none |
| `20260727T-rcu-borrowed-target-stage2-forced-rcu-v1` | functional | g83d52c2168e2-dirty #14 | 74/74 | none |
| `20260727T-rcu-borrowed-target-stage2-phase1-v1` | phase1 + semantic | #14 | 3/3, 8/8, 74/74, 76/76 (170 records) | implementation doc: agrees (3/8/74/76, clean dmesg) |

The design doc says stage 1 used kernel commit `83d52c216`, but the stage-1 roots booted `g8fd1fb52fa8d-dirty`, and `g83d52c2168e2` first appears in the stage-2 roots. `docs/evaluation.md:367` ("RCU borrowed-target repair: kernel `bdc9a83e3`; forced RESOLVE_CACHED, concurrent replacement, complete Phase 1 ... passed") cites the implementation doc. Its forced/concurrent/Phase-1 evidence here booted dirty `83d52c2168e2` builds. The same 74-case suite passed on clean `gbdc9a83e3dfb` in `provenance-tsc-functional-v1/v2` (Group J).

### Group J: 2026-07-27 kernel provenance and KVM boot diagnostics (15 units)

`docs/tmp/2026-07-27-repository-infrastructure-and-kernel-build-identity.md` gives the context but no run ids. Two overlapping kernel builds corrupted the stock image's exception table, and the image panicked at boot on an unsupported MSR read. "CPU-model changes did not repair the image"; a clean serial rebuild did. The roots match that account, in this order (all times PDT, 2026-07-27):

| Unit | Time | Kernel / CPU | Result |
| --- | --- | --- | --- |
| `20260727T-kvm-host-diagnostic-v1` | 21:04 | patched gbdc9a83e3dfb #16, host CPU (Core Ultra 9 285K) | smoke start/done |
| `20260727T-runlocal-patched-smoke-v1` | 21:04 | run-local patched gbdc9a83e3dfb #16, host CPU | smoke start/done |
| `20260727T-runlocal-stock-{smoke,verbose,novmx,novmx-verbose,qemu64,qemu64-verbose,kvm64,broadwell}-v1` (8 units) | 21:04-21:12 (dir mtimes) | run-local stock image; CPU model per name | **empty**: 0 files; the guest never reached `__phase1_guest_smoke` |
| `20260727T-runlocal-patched-qemu64-v1` | 21:18 | patched gbdc9a83e3dfb #16, "QEMU Virtual CPU version 2.5+" | smoke start/done |
| `20260727T-stock-clean-smoke-v1` | 21:30 | rebuilt stock `7.1.0-rc7 #1` (built 21:28:50) | smoke start/done |
| `20260727T-stock-snapshot-diagnostic-v1` | 21:39 | same stock build; cmdline `debug` | smoke start/done |
| `20260727T-provenance-tsc-functional-v1` | 07-27 | gbdc9a83e3dfb #16 (clean) | functional 74/74 |
| `20260727T-provenance-tsc-functional-v2` | 07-27 | gbdc9a83e3dfb #16 (clean) | functional 74/74. Cited by `2026-07-27-kernel-binary-provenance-and-rq2-analysis.md` ("All 74 functional cases passed, guest 7.1.0-rc7-gbdc9a83e3dfb"); agrees |

The producer for the smoke-only roots is the `__phase1_guest_smoke` guest target. The exact host invocation, run-local image path and QEMU CPU flags were not recorded. The empty roots are evidence only by their names and timestamps.

### Group K: 2026-07-29 final file selection (3 units)

Recorded in `docs/tmp/2026-07-29-namei-ext-final-file-selection-implementation.md`, kernel `7.1.0-rc7-g621aff8d1bb5 #1` (clean).

| Unit | Command (from doc) | Result | Consistency |
| --- | --- | --- | --- |
| `20260729T-final-file-select-host-v1` | `make abi bpf functional policy-load policy-semantic kernel-objects RUN_ID=...` (only `abi` writes results) | ABI 3/3 | agrees |
| `20260729T-final-file-select-preflight-v2` | `make kvm-functional` | 117/117 (44 new `select_file_*`, `select_pinned_*`, `select_exec_*`, cross-mount and permission cases; `select_concurrent_replacement` renamed to `select_directory_concurrent_replacement`) | agrees (117/117) |
| `20260729T220000Z-f1e5e1e1` | `make phase1` | ABI 3/3, load 8/8, functional 117/117 (134 records) | agrees (3/3, 8/8, 117/117, guest g621aff8d1bb5) |

### Group L: 2026-08-01 host ABI checks (6 units)

`20260801T124624Z-27b199c4`, `130350Z-f6a81377`, `131351Z-567f9eb2`, `133748Z-3eca2454`, `183743Z-9ffc8d72` and `184724Z-0b5b0386` each hold one `abi.jsonl` with 3/3 passing rows: the uapi/bpf layout (ctx 184 B, `parent_dev` offset 160, SELECT_TARGET enum) and uapi header sync. These are default-`RUN_ID` side effects of `make abi`, or of builds that depend on it, during the 2026-08-01 work. For example, `docs/tmp/2026-08-01-semantic-continuation-implementation.md` records `make abi runner semantic-continuation bpf`. No tracked document names these ids. They carry no information beyond "ABI check passed at that time".

### Group M: 2026-08-08 target-registration batch functional (1 unit)

`20260808T140941Z-target-batch-functional` came from `make kvm-functional` on kernel `7.1.0-rc7-gb07117a3cb41 #2` (clean) and has 168 JSONL rows. All 150 functional cases pass, including 33 new `target_batch_*` and `target-batch-*` cases (partial failure, partial clear, ID reuse, cgroup leave/remove). A diagnostic then registered 64 targets in five AB/BA pairs:

| Pair | First | Scalar ms | Batch ms | Batch/scalar |
| --- | --- | ---: | ---: | ---: |
| 1 | scalar | 649.99 | 10.16 | 0.01563 |
| 2 | batch | 656.12 | 10.13 | 0.01544 |
| 3 | scalar | 633.44 | 13.76 | 0.02172 |
| 4 | batch | 618.76 | 10.12 | 0.01635 |
| 5 | scalar | 648.19 | 10.12 | 0.01561 |

Summary: batch won 5/5, with a median ratio of 0.015632935. All register, clear and cgroup-remove error counts are 0. `docs/tmp/2026-08-08-target-registration-batch-functional.md` reports 168 rows, 150 cases, scalar 618.8 to 656.1 ms, batch 10.12 to 13.76 ms and median 0.015632935, all of which agree. The doc calls this a diagnostic, not a paper result.

### Evidence cited by tracked docs and paper (slice summary)

- **Cited by `docs/evaluation.md`, raw root untracked:** `20260724T-epoch-switch-release-v2` (also `research/STATE.md`), `20260724T-bad-local-stale-smoke-v1` and `20260724T-bad-local-corrupt-hidden-smoke-v1`. The claims are verified above. After deletion, this file plus the tables in `docs/tmp/2026-07-24-build-cache-real-compile-epoch-implementation.md` and `...-bad-local-fallback-probe-implementation.md` are the only record.
- **Paper (`05-evaluation.tex:296`, hot-cache 2.18x / 0.945x):** derived from `20260723T-build-cache-state-release-v1`. A byte-identical tracked JSONL copy exists under `results/experiments/build-cache/`, so deleting the phase1 staging root loses only payload (object files, strace, ccache trees).
- **Cited in docs/tmp or `docs/implementation.md` as implementation validation** (counts verified in groups A, E, G to M): `014740Z`, `021039Z`, `022917Z`, `024221Z`, `031516Z`, `application-file-sharing-regression-v2`, `infra-phase1-v2`, `unified-suite-phase1-v1`, `infra-followup-phase1-v1`, `suite-catalog-phase1-smoke-v1`, `current-bench-variants-v4`, `parent-fast-path-8fd1fb52f-*`, `policy-parent-v1`, `provenance-tsc-functional-v2`, `rcu-borrowed-target-stage2-phase1-v1`, `rcu-decision-final`, `final-file-select-*`, `20260729T220000Z-f1e5e1e1` and `20260808T140941Z-target-batch-functional`.

### Doc vs raw mismatches

- `docs/evaluation.md:304`. The doc says the hot-cache compile in raw root `results/experiments/build-cache/20260723T-build-cache-release-v1/` gives FUSE/namei_ext 2.18x and native/namei_ext 0.945x. The raw data for release-v1 gives **1.758x and 1.034x**, in both the phase1 staging root and the identical tracked copy. 2.18x and 0.945x are the `20260723T-build-cache-state-release-v1` values (2.180x and 0.945x). The paper's `05-evaluation.tex:296` numbers are therefore correct for state-release-v1, but evaluation.md points at the wrong root.
- `docs/evaluation.md:306`, repeated in `docs/tmp/2026-08-02-workload-evidence-audit.md:80`. The doc says "FUSE/namei_ext ratio 2.10x". The raw ratio is **2.0948**: 594,484,466,210 / 283,793,096,305 ns. The implementation doc reports 2.095x, and rounding the raw value to two decimals gives 2.09x. The difference is cosmetic.
- `docs/evaluation.md:306`. The doc says "policy session updates 20 vs 800 backing invalidations". In the raw summary, namei_ext has `policy_session_updates=20` and `backing_invalidations=800`, and FUSE has `update_writes=800` and `backing_invalidations=800`. Both systems invalidate 800 times. The 20-vs-800 contrast is namei_ext's 20 session updates against FUSE's 800 update writes. The wording mismatch is minor.
- `docs/tmp/2026-07-27-namei-ext-global-parent-fast-path-implementation.md:13,59-67` and `...-design.md:140`. The docs say "Kernel commit `8fd1fb52fa8d` ... passed" for `results/phase1/20260727T-parent-fast-path-8fd1fb52f-{phase1,semantic}/`. In all three dmesg logs the guest booted **`7.1.0-rc7-gc7af99f67609-dirty #10`**, the same build as `global-parent-fast-path-phase1-v2`. The first `g8fd1fb52fa8d` build is #11, in the stage-1 roots.
- `docs/tmp/2026-07-27-namei-ext-rcu-target-selection-design.md:64`. The doc says "Kernel commit `83d52c216` ... passed the complete Phase 1 correctness path" for stage 1. The stage-1 roots (`rcu-target-registry-stage1-*`) booted **`g8fd1fb52fa8d-dirty` #11/#12**. `g83d52c2168e2` first appears in the stage-2 roots.
- `docs/evaluation.md:367`. The doc says "RCU borrowed-target repair: kernel `bdc9a83e3`; forced `RESOLVE_CACHED`, concurrent atomic replacement, complete Phase 1 ... passed". The forced-RCU, concurrent and Phase-1 roots in this slice booted **`g83d52c2168e2-dirty` #13/#14**. The only `gbdc9a83e3dfb` functional evidence is `provenance-tsc-functional-v1/v2`, which passed 74/74 with the same case set, including the RESOLVE_CACHED and concurrent cases. No `bdc9a83e3` policy-semantic run is in this slice.
- Raw-internal provenance gap, not a doc claim. `results/phase1/20260727T-current-bench-variants-v{1..4}/metadata.json` records `kernel_repo.head=c7af99f67609` with `dirty=false`, but the guest booted `gc28220593eb0-dirty #8`. `docs/tmp/2026-07-27-unified-infrastructure-followup-audit.md:81` cites v4 only for variant selection, so its statements are unaffected.

All other tracked numbers checked in this slice match the raw data.

### Keep list (`p3-phase1-late-keep.tsv`)

Six small aggregate files, 86,194 bytes in total, are the only raw source of numbers stated in `docs/evaluation.md:306-307`, `research/STATE.md:100`, the epoch-switch implementation and result-review docs, the bad-local implementation doc, `docs/tmp/2026-07-24-current-state-lpc-and-experiment-status.md`, and `docs/tmp/2026-08-08-target-registration-batch-functional.md`:

- the epoch-switch release JSONL (holds the summary row) and `host-make.exit`;
- the epoch-switch smoke-v2 JSONL;
- the two bad-local fallback JSONLs;
- the target-batch `functional.jsonl`.

Not listed:

- The build-cache release and state-release aggregates, because byte-identical tracked copies exist.
- The 848 KB `w4-ccache-bulk-compile-epoch-switch-outputs.sha256` behind the review's "3280 entries", because it is a hash manifest rather than an aggregate. Its count is recorded above.
- Phase-1 pass-count JSONLs, because their counts survive in this file and the CSV, and tracked docs state only pass counts.
