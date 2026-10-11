## Experiments slice B: checkpoint, FxMark, Kubernetes, mdtest, target lifetime, semantic continuation, service rotation, Spindle

This section covers 143 inventory units under `results/experiments/`, about 19.5 GB in total.
The families are:
- `checkpoint-restore-*`
- `fxmark-*`
- `kubernetes-configmap-*`
- `mdtest-cold-metadata-rq2-preflight`
- `namei-ext-target-lifetime-preflight`
- `semantic-continuation*`
- `service-config-rotation-preflight`
- `spindle-staging*`

The units are of two kinds:
- **Whole ignored run roots.** Nothing in them is tracked.
- **Ignored sub-paths inside tracked run roots.** These are kernel images, runtime binaries, source trees, checkpoint images, per-boot raw directories, and a few small files. The roots are `checkpoint-restore-rq1/...w5-formal01`, `fxmark-fast-path/...formal-v1`, `fxmark-readdir/...formal-v1`, `fxmark-rq2/...formal-v3` and `spindle-staging/...w6-formal01`.

Every number below was extracted read-only from the raw files at repo HEAD `eba72a6`. Where a tracked doc exists, its numbers were compared with the raw data. The companion CSV `p7-experiments-b.csv` has one row per unit.

Summary of the slice:

| Family (units) | Status of units | Tracked coverage |
| --- | --- | --- |
| checkpoint-restore (29) | 8 preflights: 7 failed, attempt06c completed; 21 formal01 payload sub-paths | formal01 analysis tracked; preflights documented in docs/tmp except attempt06c |
| fxmark (58) | 39 whole roots (35 preflights, 4 full matrices) + 19 sub-paths of the 3 tracked formal runs | every formal result tracked; 8 preflight roots have no tracked doc |
| kubernetes-configmap (6) | 2 publication preflights, 3 quantitative preflights, quantitative formal01 | formal01 is cited by `docs/evaluation.md`; its raw data and analysis are entirely untracked |
| mdtest-cold-metadata (6) | all failed | per-attempt docs; ops/s from the 2 partial preflights recorded only here |
| target-lifetime (10) | all failed, no formal run | per-attempt docs |
| semantic-continuation (5) | 3 preflights failed, formal-v1 superseded, formal-v2 valid | formal-v2 backs a paper table row, but no file of its root is tracked |
| service-config-rotation (6) | all failed, no formal run | per-attempt docs |
| spindle-staging (23) | 6 RQ1 preflights, 7 RQ2 preflights, RQ2 formal01-04, 6 RQ1 formal01 payload sub-paths | RQ1 formal01 tracked; RQ2 runs documented only in docs/tmp reviews |

Main findings:

1. **No tracked headline result disagrees with the raw data.** This covers:
   - FxMark formal-v3, fast-path formal-v1 and readdir formal-v1, whose per-boot observations are md5-identical to the tracked `observations.jsonl`;
   - checkpoint formal01 and Spindle RQ1 formal01;
   - Kubernetes quantitative formal01: 238,800/238,800 rows pass, counts 800 / 170,000 / 67,200 / 400 / 400, ratios 1.742 / 1.614 / 1.237 / 0.720 [0.680, 0.731];
   - semantic-continuation formal-v2: 48/48 direct, 48/48 selected, 240 engagements, 6 identity checks, 96 residual checks;
   - Spindle RQ2 formal04: 1.0104 [0.9668, 1.0491].
2. **Numbers that survive only here and in the keep-list files:**
   - Kubernetes formal01 per-width tables;
   - Spindle RQ2 formal01-04 per-pair numbers;
   - mdtest reconsideration ops/s;
   - FxMark full-v2 per-cell ratios;
   - checkpoint attempt06c, which gated formal01 and is cited by no doc;
   - 8 FxMark preflights that no tracked doc names.
3. **Paper:**
   - It embeds the tracked `fxmark-readdir/...formal-v1/analysis/throughput.pdf`.
   - Its W5, W6 and semantic-preservation rows restate checkpoint formal01, Spindle formal01 and semantic formal-v2 numbers without giving paths.
   - It cites no preflight from this slice.

**Keep list** (`p7-experiments-b-keep.tsv`): 46 files, 1.21 MB in total. These are the analysis summaries or sole small observation files behind numbers stated in the paper, `docs/evaluation.md`, or docs/tmp result records. Files deliberately left out:

| File or number | Why excluded |
| --- | --- |
| `fxmark-rq2/...formal-v3/analysis/summary.csv` | all 279 values are already in the tracked `summary.json` |
| semantic formal-v2 `artifacts/runtime/semantic_continuation_operations.tsv` | byte-identical to tracked `configs/benchmarks/semantic_continuation_operations.tsv` |
| Kubernetes formal01 evidence counts (170,000 etc.) | they exist only in the 175 MB `observations.jsonl`; the keep list has its `summary.json`, and this file records the counts |
| `docs/evaluation.md:163` "99 KCSAN report blocks" (target-lifetime pf10) | its source is a launcher log |
| `docs/evaluation.md:355` "33/50 boots" (rcu-target-full-v1) | its source is per-boot directories |
| mdtest pf03 and Kubernetes quantitative pf03 observations | 2.9 MB, too large; their numbers are kept in this file |

**Doc vs raw mismatches.** Raw data were read at HEAD `eba72a6`.

| Doc:line | Doc says | Raw shows |
| --- | --- | --- |
| `docs/tmp/2026-08-07-spindle-rq2-formal02-failure.md:23` | namei_ext pooled median 98.129 ms | the 50-sample median is 96.912 ms; 98.129 is the 26th sorted value |
| same `:12` | source `2475071dc410334d33b590ffaaaeaf4fbbfaff` | run.json `2475071dc410334d33b590ffaaaeafaf4fbbfaff` (doc drops 2 hex chars) |
| `docs/tmp/2026-08-02-spindle-rq2-preflight-attempt-1.md:20-21` | FUSE boot passed its warmup and five measured launches | the FUSE boot has no sample or launch rows; it stopped after the permission step |
| `docs/tmp/2026-08-07-spindle-rq2-preflight-affinity-abort.md:18` | "QMP was reachable" | QEMU stderr: QMP socket "Failed to create a socket: Operation not permitted"; empty vCPU lists |
| `docs/tmp/2026-07-27-policy-parent-dispatch-preflight-review.md:28-29` | both runs used patched kernel c7af99f6 | guests booted `7.1.0-rc7-gc28220593eb0-dirty #8` (the exact-empty runs booted the same build) |
| `docs/tmp/2026-07-27-namei-ext-global-parent-fast-path-implementation.md:73`; `docs/evaluation.md:363` | "committed" preflight on kernel 8fd1fb52f | `parent-fast-path-8fd1fb52f-normal/-stats` booted `gc7af99f67609-dirty #10`, the same build as the uncited global-parent-fast-path-preflight-v2 |
| `docs/tmp/2026-07-27-namei-ext-rcu-target-selection-design.md:5` | "committed-tree" preflight rq2-post-parent-fastpath-v2 | booted `gc7af99f67609-dirty #10` |
| same `:70` | "clean-tree" preflight rcu-target-registry-stage1-v1 (83d52c216) | booted `g8fd1fb52fa8d-dirty #12` |
| no doc | rcu-borrowed-target-stage2-v2 records bdc9a83e3 | booted `g83d52c2168e2-dirty #14`, the defective binary that `docs/evaluation.md:353` notes only for rcu-target-full-v2 |
| `docs/tmp/2026-07-28-checkpoint-restore-kvm-preflight-attempt-2.md:33` | checkpoint image in the host-shared result tree | `restart-1.out` shows it under host-shared `.build/workloads/dmtcp-068559d9b14c/` (minor) |
| `docs/tmp/2026-07-31-rq3-target-lifetime-preflight08-selection-coverage-failure.md:25` | 312 KiB bounded histories | 312,337 B = 305 KiB (rounding) |
| `docs/tmp/2026-08-08-kubernetes-configmap-quantitative-formal01-result-review.md:21` | `make kvm-kubernetes-configmap-quantitative` | `command.txt` has the `experiment-` alias of the same rule (cosmetic) |
| `docs/evaluation.md:193,420`; `research/STATE.md:102` | W6 matched-FUSE run is "separate RQ2 work"; open question about a W6 "cost advantage"; W6 listed as an open RQ1 gap | Spindle RQ2 formal01-04 exist. formal04 is valid with FUSE/namei 1.0104 [0.9668, 1.0491] (no advantage), and W6 RQ1 formal01 passed |

Omissions with no contradiction:
- `2026-08-02-w5-attempt-5-result-and-attempt-6-repair.md` omits the 120 s / errno 110 timeout.
- The mdtest attempt-1 doc omits the final `ECONNREFUSED`.
- The Spindle formal04 review omits that namei_ext has the heavier tail: pooled p95 145.5 vs 106.2 ms.


### Checkpoint/restore (W5)

W5 is the DMTCP checkpoint/restore RQ1 case study. A checkpointed application remembers a logical pathname, under three conditions:
- `pathvirt`: DMTCP PathTranslator;
- `namei_ext`: bounded existing-directory selection;
- `withdrawn`: the causal control.

The oracle requires generation A before the checkpoint and generation B after a real DMTCP restart, both through the same pathname; `withdrawn` must get `ENOENT` instead. Lower objects must stay unchanged, and no BPF program may remain attached.

Producers: `make kvm-checkpoint-restore-preflight` (1 boot) and `make kvm-checkpoint-restore-rq1` (3 boots), both in `mk/experiments/checkpoint_restore.mk`, with `analysis/checkpoint_restore/`. DMTCP is pinned at `068559d9b14c` and carries a one-line `restart-env-scan-count.patch`.

The slice has 8 whole preflight roots (2.55 GB) and 21 payload sub-paths of the tracked formal run (0.59 GB). The paper cites none of them by path; its `05-evaluation.tex` W5 row restates formal01 numbers.

#### Preflight, July protocol: attempts 1-3 (`checkpoint-restore-preflight/20260728T232936Z`, `20260728T233617Z`, `20260729T001040Z`)

These were the first clean-source, modified-kernel dependency preflights. Each ran DMTCP's official upstream `pathvirt` autotest inside the guest as a gate before the three focal conditions. In all three, the run stopped at that gate, `run.json.status=failed`, and `failure=kvm-launch-or-guest-command`.

All three used kernel `bdc9a83` (release `7.1.0-rc7-gbdc9a83e3dfb`, identical bzImage) and DMTCP `068559d` with the patch. Each root is about 99-103 MB and is mostly payload: bzImage 18 MB, runtime/DMTCP install 76 MB, and a DMTCP source archive of 1.7 MB.

| Attempt | Src commit | Elapsed | What failed (raw evidence) | Focal conditions |
| --- | --- | --- | --- | --- |
| 1 `232936Z` | `1a56580` | 45 s | `upstream-autotest.stdout.log`: `pathvirt ckpt:PASSED; rstr:FAILED ... worker1 exited:99`, peer timeout after 31.7 s; non-verbose run kept no assertion text | 0 run |
| 2 `233617Z` | `47a2907` | 44 s | verbose artifacts copied in: `restart-1.out` = DMTCP ASSERT "Process uid doesn't match uid of checkpoint image" (process uid 0, checkpoint uid 1000); checkpoint image 4,045,550 B; worker1 exit 99 | 0 run |
| 3 `001040Z` | `3a2ad6e` | 8 s | `upstream-autotest.stderr.log`: `setpriv: failed to parse reuid: ''` (empty uid/gid); `runtime-identity.json` = 1000/1000 | 0 run |

Tracked summaries exist for each attempt:
- `docs/tmp/2026-07-28-checkpoint-restore-kvm-preflight-attempt-1.md`
- `docs/tmp/2026-07-28-checkpoint-restore-kvm-preflight-attempt-2.md`
- `docs/tmp/2026-07-29-checkpoint-restore-kvm-preflight-attempt-3.md`
- `docs/tmp/2026-07-28-checkpoint-restore-implementation-status.md` (all three)
- `docs/tmp/2026-07-29-checkpoint-restore-requalification-plan.md` (lists all three roots as closed)

The raw data agree with the docs on the commits, kernel release, failure phase, exit code 99, the uid 0 vs 1000 assertion and the empty-`setpriv` defect. One minor wording difference: the attempt-2 doc says the checkpoint image "lived in the virtme host-shared result tree". The raw `restart-1.out` shows it under the host-shared `.build/workloads/dmtcp-068559d9b14c/...` tree, not under `results/`. Both are host-shared mounts owned by uid 1000, so the diagnosis still holds.

After attempt 3, the docs declared the three-attempt budget exhausted. The requalification plan was "Rejected before implementation".

#### Preflight, August W5 lineage: attempts 4, 5, 6, 6b, 6c (`checkpoint-restore-preflight/20260802T*-w5-attempt*`)

On 2026-08-02, W5 was resumed as "attempt 4 in the original W5 lineage" (`docs/tmp/2026-08-02-w5-checkpoint-restore-attempt-4-implementation.md`). The new setup builds DMTCP through Make and uses a source-derived application/runner. All five attempts used kernel `b07117a` (release `7.1.0-rc7-gb07117a3cb41`; the bzImage is sha256-identical to formal01's) and DMTCP `068559d` with the patch. Every root carries about 359 MB of artifacts: a 266 MB DMTCP source/build tree, a 72 MB DMTCP install, and a 17 MB bzImage.

The RUN_ID timestamps do not follow execution order. By `run.json.started_at`, the order was 04 (09:52Z), 05 (10:22Z, despite RUN_ID `114500Z`), 06 (10:38Z), 06b (10:42Z), 06c (10:54Z), then formal01 (11:03Z).

| Attempt | Src | Status | Failure / outcome (raw) | Key numbers |
| --- | --- | --- | --- | --- |
| 04 | `cd8aa2d` | failed | In-guest upstream autotest: `ckpt:PASSED; rstr:PASSED`, then `run:FAILED phase=cleanup msg=leftover processes in group 969: [980]`; stopped before the BPF inventory and all focal conditions | autotest 2.0 s; uid/gid probe 1000/1000; 656 MB (a 272 MB DMTCP source copy under `boots/preflight/dmtcp-source`) |
| 05 | `d831e02` | failed | Autotest gate removed. `pathvirt` setup, lower capture and coordinator passed; `dmtcp-launch.stderr.log`: `ASSERT at shareddata.cpp:230 ... Unable to find shared area ... errno=22 (EINVAL)`; `pre_checkpoint_oracle` errno 110 | `total_ns`=120,174,115,890 (hit the 120 s timeout); initial BPF inventory empty; 0 conditions completed |
| 06 | `44a421b` | failed | Launcher stdout/stderr empty; the boot dir has only `guest.mk` and empty condition dirs; the guest command never ran | 253 s until failure; no observations |
| 06b | `44a421b` | failed | `pathvirt` passed the full A-to-B oracle (11/11 events). `namei_ext` `configure_policy` returned errno 5 (EIO) before the application ran. `withdrawn` did not run. | pathvirt checkpoint 20.2 ms, restart 1043.3 ms, total 2983.0 ms; image 24,391,680 B; namei_ext stopped after 63.3 ms |
| 06c | `b0ac416` | **completed** | All 3 conditions passed (43/43 case events, 55 observations); analyzer verdict `evidence_role=dependency_preflight`, `tested_hypothesis=not_tested` | See below |

Tracked docs cover 04 (`2026-08-02-w5-attempt-4-result-and-attempt-5-plan.md`, `...-attempt-4-implementation.md`), 05 (`2026-08-02-w5-attempt-5-result-and-attempt-6-repair.md`), and 06 and 06b (`2026-08-02-w5-attempt-6b-result-and-policy-attribution.md`). The raw data match the docs on the commits, PID 980 in pgid 969, the EINVAL shared-area assert, the empty initial BPF inventory, the pathvirt pass and the `namei_ext` EIO in 06b.

The doc attributes attempt 06's failure to PTY/job-control. That cause cannot be seen in the raw data, which shows only empty launcher logs. The doc for 05 does not mention the 110/120 s timeout that the raw observations record.

**Attempt 06c has no tracked summary.** No doc, commit message or paper text cites `20260802T105500Z-w5-attempt06c`. It is the passing one-boot preflight that gated formal01. Its runner (`7137b552808c`), application, `.bpf.o`, `libdmtcp.so` and bzImage are byte-identical to formal01's. The only commit between them, `b0ac416..dcc525c`, touches only `analysis/checkpoint_restore/{analyze.py,test_analyze.py}` ("enforce checkpoint withdrawal attribution").

Its own untracked `analysis/{report.md,summary.csv,summary.json}` agree with `observations.jsonl`. This record will be the only surviving copy of these numbers:

| 06c condition | checkpoint ms | update | restart ms | total ms | Oracle |
| --- | --- | --- | --- | --- | --- |
| pathvirt | 30.2 | 51 ns | 1196.1 | 3457.5 | A to B, 9/9 cases |
| namei_ext | 20.2 | 20.18 ms | 1191.0 | 3195.1 | A to B; SELECT 12 to 24; program id 5, cgroup 21; 17/17 cases |
| withdrawn | 30.2 | 275.7 µs | 1150.9 | 3230.7 | failure=`expected-post-enoent`; SELECT 12 to 12; 17/17 cases |

The 06c boot also recorded:
- Lower-object rows: 36 (18 before, 18 after), unchanged.
- Application observations: 6.
- Runtime identity: 1000/1000.
- BPF programs before/after: 0/0.
- `dmesg`: 3 `__vm_enough_memory` lines (one per restart) and no BUG/WARNING/Oops.
- Checkpoint images: 24.39 MB each (about 22 MiB each in `du`), one in each of the three `boots/preflight/conditions/*/checkpoint` dirs.

#### formal01 ignored sub-paths (`checkpoint-restore-rq1/20260802T111000Z-w5-formal01/...`)

The formal run (`make kvm-checkpoint-restore-rq1`) has three boots, source `dcc525c` (clean), kernel `b07117a`, and status `completed` (11:03:25Z-11:04:08Z). These stay tracked:
- `analysis/{summary.csv,summary.json,report.md}`, with `tested_hypothesis=supported`;
- per-condition logs and observations, `checkpoint-images.txt` and `lower-{before,after}.jsonl`;
- the manifest, the kernel config, and the DMTCP patch and logs.

The run is cited by its review `docs/tmp/2026-08-02-w5-checkpoint-restore-formal01-result-review.md`, `docs/evaluation.md` and `research/STATE.md`.

The headline numbers, from the tracked `summary.csv`, give the median across 3 boots with the range in brackets. All timings are diagnostic only.

| Condition | checkpoint ms | update | restart ms | total ms |
| --- | --- | --- | --- | --- |
| pathvirt | 30.3 [30.2-30.4] | 40-308 ns | 1158.5 [1131.3-1226.5] | 3594.4 [3304.5-3638.9] |
| namei_ext | 20.2 [20.18-20.19] | 20.2 ms | 1166.4 [1031.0-1177.3] | 3172.8 [2890.7-3190.4] |
| withdrawn | 30.3 [20.2-30.4] | 222-292 µs | 1145.6 [1048.2-1184.0] | 3232.6 [2807.8-3388.7] |

I re-checked the review doc's claims against tracked files and the ignored payload. All of them agree:
- Observations: 165 controller and 18 application observations, all passed.
- Inode transitions: the A-to-B inodes match the review table exactly, for example block-01 namei_ext 36497357 to 36497363. Each withdrawn restart returned errno 2.
- SELECT counts: 12 to 24 with the rule installed, 12 to 12 after withdrawal, in every boot.
- Lower objects: 54/54 before/after rows with 0 mismatches.
- Checkpoint images: nine images of 24,387,584-24,395,776 B, each starting with `DMTCP_CHECKPOINT_IMAGE_v4.0`.

The ignored sub-paths are pure payload (status n/a(payload)):
- `artifacts/kernel/bzImage`: 17,699,840 B, sha256 `79a1bc65f0f8...` (full hash in the CSV). Identical to the bzImage in the five August preflights. Rebuildable from `b07117a` plus the tracked config.
- `artifacts/runtime`: 27 files, 79 MB. Contains the runner (sha `7137b552808c`), app (`b34fd139c76b`), `checkpoint_restore_migration.bpf.o` (`6598069e6e5a`), bpftool (`042322ac211a`) and the DMTCP install (`libdmtcp.so` `003f3cd29db4`). The tracked `manifest.json` has the paths but no hashes.
- `artifacts/source/dmtcp/worktree`: 786 files, 277 MB. A git-archive of DMTCP `068559d` with the patch applied and built in place (108 `.o` files). Upstream is public, and the patch and logs are tracked.
- `boots/block-0{1,2,3}/conditions/{namei_ext,pathvirt,withdrawn}/checkpoint`: one DMTCP image plus restart script per condition, 24.39-24.40 MB each. They are named in the tracked `checkpoint-images.txt`, and their timings are in `summary.csv`.
- `.../fixture`: 6 files, 74 B per condition (generation-a `shared/stale/state.txt`, generation-b `new/shared/state.txt`). They are fully reproduced in the tracked `lower-before.jsonl` and `lower-after.jsonl`, which record dev, inode, mode, size, mtime and full content.

Deleting these payloads loses only the binary images and build trees. Every correctness claim in the tracked analysis stays verifiable from the tracked JSONL files.

### FxMark RQ2: stat matrix, unused fast path, readdir (58 units)

Producers:
- `kvm-fxmark-rq2-preflight` and `kvm-fxmark-rq2` (`mk/benchmarks/fxmark.mk`, `analysis/fxmark/`)
- `kvm-fxmark-fast-path-preflight` and `experiment-fxmark-fast-path` (`mk/experiments/fxmark_fast_path.mk`)
- `kvm-fxmark-readdir-preflight` and `experiment-fxmark-readdir` (`mk/experiments/fxmark_readdir.mk`)

Each cell is one pinned FxMark microbenchmark running in a fresh virtme-ng KVM guest over tmpfs. The conditions are:
- stock kernel 062871f13
- patched kernel, unattached
- attached `PASS` and `SELECT` BPF policies
- cache-hot FUSE on the stock kernel
- `empty` (diagnostic preflights only): the PASS program with an empty exact-parent set

Throughput is in works/s. All numbers were recomputed from the per-boot `observations.jsonl` files. **No tracked number disagreed with the raw data.**

#### RQ2 stat-matrix preflights (`fxmark-rq2-preflight/`, 30 whole roots, 0.33 GB)

These are one-block runs: MRPL, one worker, 2 s. They track the mechanism redesign on 2026-07-26/27 and the infrastructure hardening on 07-28. None of them is paper evidence. Outcomes:
- 21 completed.
- 7 failed (table below).
- 1 aborted: `exact-empty-run-count-v1`, whose run.json was stuck at `running` with empty logs; v2 replaced it 9 s later.
- 1 incomplete: `dry-run`, from 2026-07-27T02:36Z, with no run.json. Its stock boot passed with MRPL-1 at 2,347,723 ops/s. Its unattached boot (6641100ef) left no boot.json and no observations. The tracked docs that contain the word "dry-run" do not refer to it.

| Failed run | Raw evidence | Tracked cause |
| --- | --- | --- |
| rq2-fxmark-preflight-v1 / -v2 (07-26) | only `command.txt` and `artifacts.sha256`, no logs | v1: 1 s outer timeout; v2: guest lacked `/mnt` (`2026-07-26-rq2-fxmark-preflight.md`) |
| unified-fxmark-preflight-v2 | stock boot: `readelf: Error: Not an ELF file` (fxmark.mk:280) | none |
| clean-artifact-preflight-v2 | failed in 1 s, empty logs | concurrent kernel-build mutation (`2026-07-27-repository-infrastructure-and-kernel-build-identity.md`) |
| locked-kernel-preflight-v1 / -v2 | v1 empty logs; v2: truncated cmdline, `VFS: Unable to mount root fs`, panic | overlong `vng --exec` command; fixed by `guest.mk` (same doc; v2 is its unnamed "verbose repeat") |
| guest-config-preflight-v1 | stock guest failed the `clocksource == tsc` gate (fxmark.mk:439) | missing `clocksource=tsc` (same doc) |

Completed preflights, in run order (tracked docs per run are in the CSV `tracked_summary` column). Values are MRPL-1 throughput in M ops/s, one sample each. "S" marks runs with BPF stats on; their throughput is only for counting invocations.

| Run | Guest patched release | S | stock | unatt | empty | PASS | SELECT | FUSE |
| --- | --- | :-: | ---: | ---: | ---: | ---: | ---: | ---: |
| rq2-fxmark-preflight-v3 | g6641100ef134 (counters in policy) | | 2.358 | 2.130 | | 0.763 | 0.762 | 1.938 |
| unified-fxmark-preflight-v1 | g6641100ef134 | | 2.204 | 2.132 | | 0.996 | 0.996 | 1.993 |
| unified-fxmark-preflight-v3 | g6641100ef134 | | 2.453 | 2.132 | | 0.999 | 0.996 | 1.843 |
| out-of-line-fastpath-preflight-v1 | g6641100ef134-dirty #3 | | 2.412 | 2.394 | | 0.974 | 0.972 | 2.025 |
| in-place-unlazy-preflight-v1 | g309a05d87e98-dirty #4 | | 2.459 | 2.417 | | 1.007 | 1.006 | 2.041 |
| rcu-decision-preflight-v1 | g309a05d87e98-dirty #5 | | 2.426 | 2.455 | | 1.245 | 1.099 | 1.854 |
| rcu-run-count-v1 | g309a05d87e98-dirty #6 | S | 2.455 | 2.370 | | 0.774 | 0.723 | 1.997 |
| policy-parent-run-count-v1 | gc28220593eb0-dirty #8 | S | 2.373 | 2.306 | | 1.170 | 1.047 | 2.009 |
| policy-parent-preflight-v1 | gc28220593eb0-dirty #8 | | 2.471 | 2.332 | | 1.235 | 1.085 | 2.041 |
| exact-empty-run-count-v2 | gc28220593eb0-dirty #8 | S | 2.456 | 2.404 | 1.265 | 1.179 | 1.052 | 2.020 |
| exact-empty-preflight-v1 | gc28220593eb0-dirty #8 | | 2.247 | 2.424 | 1.251 | 1.222 | 1.109 | 2.000 |
| global-parent-fast-path-preflight-v1 | gc7af99f67609-dirty #9 | | 2.467 | 2.404 | 2.431 | 2.163 | 1.698 | 2.006 |
| global-parent-fast-path-stats-v1 | gc7af99f67609-dirty #9 | S | 2.389 | 2.221 | 2.412 | 1.912 | 1.569 | 2.045 |
| global-parent-fast-path-preflight-v2 | gc7af99f67609-dirty #10 | | 2.449 | 2.422 | 2.423 | 2.166 | 1.679 | 1.914 |
| parent-fast-path-8fd1fb52f-normal | gc7af99f67609-dirty #10 | | 2.463 | 2.356 | 2.403 | 2.166 | 1.698 | 1.938 |
| parent-fast-path-8fd1fb52f-stats | gc7af99f67609-dirty #10 | S | 2.394 | 2.389 | 2.445 | 1.892 | 1.537 | 2.033 |
| rq2-post-parent-fastpath-v2 | gc7af99f67609-dirty #10 | | 2.268 | 2.442 | 2.398 | 2.166 | 1.619 | 2.002 |
| rcu-target-registry-stage1-v1 | g8fd1fb52fa8d-dirty #12 | | 2.448 | 2.465 | 2.406 | 2.155 | 1.715 | 2.016 |
| rcu-borrowed-target-stage2-v2 | g83d52c2168e2-dirty #14 | | 2.390 | 2.421 | 2.331 | 2.204 | 2.154 | 2.042 |
| guest-config-preflight-v2 (07-28) | gbdc9a83e3dfb (clean) | | 2.449 | 2.466 | 2.410 | 2.192 | 2.172 | 2.037 |
| guest-config-preflight-v3 (07-28) | gbdc9a83e3dfb (clean) | | 2.468 | 2.386 | 2.432 | 2.144 | 2.175 | 2.025 |

BPF invocation attribution, recomputed from the raw before/after counters. Each entry gives PASS, then SELECT, as policy runs / measured works and ns per run:

| Run | PASS | SELECT | empty runs |
| --- | --- | --- | --- |
| rcu-run-count-v1 | 15,483,415 / 1,548,321 (10.0001 per work), 24.10 ns | 14,465,635 / 1,446,543, 23.54 ns | n/a |
| policy-parent-run-count-v1 | 2,340,381 / 2,340,379, 25.06 ns | 2,093,739 / 2,093,737, 25.10 ns | n/a |
| exact-empty-run-count-v2 | 2,357,299 / 2,357,297, 25.09 ns | 2,103,401 / 2,103,399, 25.09 ns | 0 |
| global-parent-fast-path-stats-v1 | 3,823,962 / 3,823,960, 25.1 ns | 3,137,110 / 3,137,108, 25.1 ns | 0 |
| parent-fast-path-8fd1fb52f-stats | 3,784,018 / 3,784,016, 25.09 ns | 3,074,714 / 3,074,712, 25.2 ns | 0 |

Every doc-stated preflight number matches the raw data. That includes:
- the 15,259,260 PASS lookups in preflight-v3;
- empty/unattached = 0.516;
- SELECT 1.62M against FUSE 2.00M;
- stage1's 1.715M SELECT, +5.9%, 0.85x FUSE.

`docs/evaluation.md` cites six of these roots as directional evidence: the policy-parent pair, the exact-empty pair and the 8fd1fb52f pair. The table above preserves their values.

**Provenance.** Several diagnostic preflights booted dirty builds whose release differs from `kernel-commit.txt`; see the guest-release column above and the mismatch table at the top of this section. stage2-v2 (14:18Z) booted the same `g83d52c2168e2-dirty` binary as rcu-target-full-v1, which started at 14:19Z.

#### RQ2 full stat matrices (`fxmark-rq2/`, 4 whole roots)

Each matrix covers 5 conditions x MRPL/MRPM/MRPH x 1/2/4 workers x 10 paired five-boot blocks, with 30 s cells: 450 cells and 50 boots in total. The plan is `docs/tmp/2026-07-26-rq2-fxmark-experiment-plan.md`.

| Run | Kernel (guest) | Status | Boots / obs | unatt/stock | SELECT/FUSE | Other paired medians |
| --- | --- | --- | --- | --- | --- | --- |
| 20260726T-rq2-fxmark-full-v1 | 6641100ef with per-lookup BPF counters | invalidated (run.json reason) | 12 complete + 1 partial / 113 pass | 0.868-0.960 | 0.111-0.465 | PASS/unatt 0.109-0.433 |
| 20260726T-rq2-fxmark-full-v2 | g6641100ef134 | completed, hypothesis contradicted | 50 / 450 pass | 0.867-0.942 (unatt<stock 89/90 pairs) | 0.314-0.570 (90/90 <1) | PASS/unatt 0.298-0.547; SELECT/PASS 0.980-1.004 |
| 20260727T-rq2-rcu-target-full-v1 | records bdc9a83e3, boots g83d52c2168e2-dirty | killed after ~5 h, run.json `running` | 33 complete + 1 partial / 300 pass | 0.992-1.012 | 1.044-1.097 | excluded from results |
| 20260727T-rq2-rcu-target-full-v2 | records bdc9a83e3, all 30 patched boots g83d52c2168e2-dirty | complete, invalid provenance | 50 / 450 pass | 0.993-1.015 | 1.040-1.082 (0/90 <1) | PASS/unatt 0.900-0.930; SELECT/PASS 0.969-0.997 |

The clocksource watchdog line appears in 12/13, 50/50, 33/34 and 50/50 boots of these runs, and in 0/50 boots of formal-v3.

Tracked reviews:
- `2026-07-26-rq2-fxmark-instrumentation-invalidation.md`
- `2026-07-27-rq2-fxmark-result-review.md`
- `2026-07-27-rq2-fxmark-rcu-target-rerun-review.md`, which holds the full rcu-target-full-v2 per-cell table

`docs/evaluation.md` labels these runs "superseded", "interrupted" and "provenance-defective ... g83d52c2168e2-dirty". The raw data agree with every stated count, release string, watchdog statement and ratio range.

full-v2's per-cell table exists only in its ignored `analysis/report.md`, so it is reproduced here. Values are paired medians with bootstrap 95% CIs (seed 20260726):

| Test | W | unatt/stock | SELECT/FUSE | FUSE measured req |
| --- | ---: | ---: | ---: | ---: |
| MRPL | 1 | 0.870 [0.858, 0.918] | 0.497 [0.493, 0.510] | 1 |
| MRPL | 2 | 0.869 [0.838, 0.885] | 0.388 [0.379, 0.394] | 2 |
| MRPL | 4 | 0.867 [0.851, 0.892] | 0.314 [0.308, 0.322] | 4 |
| MRPM | 1 | 0.921 [0.904, 0.951] | 0.570 [0.569, 0.574] | 8 |
| MRPM | 2 | 0.942 [0.930, 0.954] | 0.431 [0.424, 0.440] | 15 |
| MRPM | 4 | 0.930 [0.923, 0.954] | 0.383 [0.375, 0.394] | 18 |
| MRPH | 1 | 0.894 [0.880, 0.904] | 0.556 [0.550, 0.567] | 1 |
| MRPH | 2 | 0.922 [0.912, 0.950] | 0.430 [0.415, 0.455] | 2 |
| MRPH | 4 | 0.925 [0.910, 0.953] | 0.388 [0.382, 0.394] | 1 |

full-v2 raw medians in M ops/s at 1/2/4 workers:

| Condition | MRPL | MRPM | MRPH |
| --- | --- | --- | --- |
| stock | 2.423/4.815/9.535 | 1.657/3.115/6.241 | 1.747/3.189/6.189 |
| SELECT | 0.995/1.549/2.498 | 0.834/1.196/2.094 | 0.844/1.204/2.092 |
| FUSE | 1.996/4.001/8.029 | 1.460/2.775/5.528 | 1.505/2.814/5.397 |

#### Ignored sub-paths of the three tracked formal runs

All three runs are tracked: `run.json`, `observations.jsonl`, `analysis/summary.json`, `report.md`, figures, `artifacts.sha256` and a docs/tmp review. In every case the ignored `boots/` holds raw per-boot logs, and the concatenated per-boot observations are **md5-identical** to the tracked `observations.jsonl`. The ignored `artifacts/kernel` (8 files, 49 MB) and `artifacts/runtime` are all listed in the tracked `artifacts.sha256`. The zero-byte `kernel-status.txt`/`source-status.txt` files are clean `git status` captures.

- **`fxmark-rq2/...formal-v3`** (6 units). `analysis/summary.csv` is 9x32, and all 279 of its values appear in the tracked `summary.json`. `boots/` has 50 dirs and 2,580 files. All 30 patched guests ran `gbdc9a83e3dfb`, tsc appears in 100/100 snapshots and there are 0 watchdog lines. Recomputed paired medians: unattached/stock 0.981-1.013, SELECT/FUSE 1.052-1.088 (SELECT>FUSE in 89/90 pairs), PASS/unattached 0.901-0.934, SELECT/PASS 0.981-0.999. The verdict is `inconclusive_or_mixed`, because the MRPL-2 and MRPL-4 CI lower bounds (0.966 and 0.958) are below 0.97. All of this matches `2026-07-28-rq2-fxmark-formal-v3-result-review.md`.
- **`fxmark-fast-path/...formal-v1`** (9 units). `boots/` has 60 dirs and 2,460 files. Paired medians are 1.001-1.008; the tracked ratios are 1.0009 [0.9921, 1.0036], 1.0083 [0.9950, 1.0179] and 1.0007 [0.9918, 1.0139], verdict supported. The run also leaves four host `/proc/stat` and `/proc/interrupts` snapshots. No analysis reads them and no hash list includes them; the readdir run tracks its equivalents.
- **`fxmark-readdir/...formal-v1`** (4 units). The paper embeds its tracked `throughput.pdf`. `boots/` has 50 dirs and 2,720 files. `artifacts/source` holds the pinned FxMark `source.tar.gz` (2.08 MB), `MRDL.c`/`MRDM.c` and two patches; the patches are also in `bench/fxmark/`. Recomputed SELECT/FUSE medians are 1.018-3.663, with SELECT<FUSE in 5/60 pairs, all in MRDM-4. Other ratios: unattached/stock 0.996-1.014, PASS/unattached 0.774-1.278, SELECT/PASS 0.936-1.001. The review `2026-07-29-rq2-fxmark-readdir-formal-v1-result-review.md` reports 2.314/2.200/3.663 for MRDL, 2.909/2.450/1.018 [0.907, 1.135] for MRDM, and verdict mixed; these agree with the raw data.

#### Fast-path and readdir preflights (5 whole roots)

| Run | Outcome | Raw numbers | Tracked doc (agrees) |
| --- | --- | --- | --- |
| fast-path-preflight-v1 | failed in the first stock boot: guest `PATH` `bpftool` was the distro wrapper | 0 observations | 2026-07-28-fxmark-fast-path-preflight-v1-failure |
| fast-path-preflight-v2 | completed, 2/2 boots, 6/6 cells | unatt/stock 0.9781/0.9964/0.9810 at w1/2/4; stock 2.453/4.903/9.806 M ops/s | 2026-07-28-fxmark-fast-path-preflight-v2 |
| readdir-preflight-v1 (075043Z) | failed at the first PASS cell | 9 obs (8 pass); PASS MRDL-1 8,204 readdir BPF runs vs 8,194 entries (getdents retries); stock/unatt/PASS 15.11/14.64/11.60 M entries/s | 2026-07-29-...-kvm-preflight-attempt-1 |
| readdir-preflight-v2 (080444Z) | 20/20 cells passed; host finalizer nested-count bug; run.json `running` | PASS MRDL-1: 8,194 entries, 81 getdents, 80 retries, 8,274 readdir runs | ...-attempt-2 |
| readdir-preflight-v3 (081348Z) | completed, GO; 1-sample verdict "contradicted" | SELECT/FUSE MRDL-1 2.153, MRDL-4 3.607, MRDM-1 2.919, MRDM-4 0.967; PASS MRDM-4 33,147 readdir runs | 2026-07-28-rq2-fxmark-readdir-preflight-result-review |

### Kubernetes ConfigMap publication and quantitative (W4)

All six W4 roots below are in git-ignored families. No tracked file keeps their raw data.

#### W4 publication RQ1 preflights (2 roots)

These came from `make kvm-kubernetes-configmap-publication-rq1-preflight` (`mk/experiments/kubernetes_configmap_publication.mk`). Each is a one-boot comparison of official Kubernetes v1.30.0 `AtomicWriter` with `namei_ext` across four states (initial, update, no-op, rollback), on kernel `621aff8`. They gated the tracked 3-boot formal root `kubernetes-configmap-publication-rq1/20260729T-...-rq1-01`, which is outside this slice and is the run the paper's W4 row cites.

| Run | Source | run.json | Obs (failed) | src/namei states | direct | dirfd | old-fd | lower | Policy counters (total/lookup/readdir/select/pass/hide) |
| --- | --- | --- | ---: | --- | ---: | ---: | ---: | ---: | --- |
| preflight01 | `6c85584` | `running` (never finalized) | 68 (0) | 4/4 | 2 | 8 | 4 | 12 | 850/798/52/35/803/12 |
| preflight02 | `fd63add` | `completed`, verdict `supported` | 68 (0) | 4/4 | 2 | 8 | 4 | 12 | 990/938/52/39/939/12 |

- **preflight01.** All 24 case rows passed. The Make finalizer then rejected the payload because the files are owned by 1000:1000 (the virtme `--rwdir` owner) and it expected uid/gid 0, so the root has no `analysis/`. This matches `docs/tmp/2026-07-29-kubernetes-configmap-publication-rq1-preflight-01.md` and its `-review.md` on every stated count.
- **preflight02.** `analysis/summary.json` has verdict `supported`, and `runtime_uid/gid` is 1000:1000 in 10/10 state records. No tracked file cites this run ID. The only reference is the narrative line "Preflight 02 passed ..." in `2026-07-29-kubernetes-configmap-publication-rq1-implementation.md`, and the raw data are consistent with it.

#### W4 quantitative preflights (3 roots)

These came from `make kvm-kubernetes-configmap-quantitative-preflight` (`mk/experiments/kubernetes_configmap_quantitative.mk`): one boot, two AB/BA pairs, kernel `b07117a`. Plan: `docs/tmp/2026-08-07-kubernetes-configmap-quantitative-plan.md`.

| Run | Source | Matrix | run.json | Raw rows (failed) | Outcome |
| --- | --- | --- | --- | --- | --- |
| preflight01 `124612Z` | `5657e57` | w16 | `failed`, `kvm-launch-or-guest-command` | 0 | Launcher ran under a PTY and QEMU stopped, so the guest command never ran; 0 B logs |
| preflight02 `125047Z` | `8ea984f` | w16 | `completed`, `preflight-complete` | 228 (0): lifecycle 4, identity 160, lower 60, unmanaged 2, audit 2 | Correctness passed; timing inadmissible because sample parents were on host 9p |
| preflight03 `133403Z` | `0b2f127` | w16, w256; fresh 1 GiB ext4 virtio disk; vCPUs pinned 4-7 | `failed`, `kvm-launch-or-guest-command` | 3,816 (0): lifecycle 8, identity 2,720, lower 1,080, unmanaged 4, audit 4 | All workload rows passed. Two finalizer predicates gave false negatives: ext4 `lost+found` gave `mechanism.status=2`, and cleanup reported `mountpoint_status=32` |

Diagnostic per-pair timings in ms (pair 1 / pair 2). These are not admissible results.

| Run | Width | Mechanism | wall_span | publication | consumer | setup | attach |
| --- | ---: | --- | --- | --- | --- | --- | --- |
| pf02 | 16 | AtomicWriter | 2956.237 / 2985.057 | 2300.973 / 2248.548 | 640.868 / 722.552 | 12.625 / 12.415 | - |
| pf02 | 16 | namei_ext | 1782.243 / 1281.205 | 0.025 / 0.022 | 346.160 / 272.674 | 1436.039 / 1008.495 | 19.608 / 21.692 |
| pf03 | 16 | AtomicWriter | 8.762 / 8.466 | 3.778 / 4.393 | 3.207 / 2.574 | 0.233 / 0.189 | - |
| pf03 | 16 | namei_ext | 307.213 / 307.635 | 0.003 / 0.003 | 0.417 / 1.056 | 306.792 / 306.573 | 17.529 / 21.291 |
| pf03 | 256 | AtomicWriter | 54.493 / 38.518 | 43.576 / 29.854 | 9.290 / 7.202 | 0.218 / 0.200 | - |
| pf03 | 256 | namei_ext | 5349.227 / 5231.644 | 0.010 / 0.006 | 6.630 / 6.412 | 5342.581 / 5225.222 | 20.297 / 50.662 |

**pf02.** The analyzer medians are 2970.647 ms for AtomicWriter and 1531.724 ms for namei_ext, a ratio of 0.509. Per namei_ext pair:
- 945 policy decisions: 849 lookup, 96 readdir, 120 select, 813 pass, 12 hide;
- 30 lower files, 328 B.

Each AtomicWriter audit saw 45 new files, 493 B.

**pf03 at w256.** namei_ext kept 510 lower files (5,608 B). AtomicWriter audits saw 765 new files (8,413 B). There were 7,280 counter events per pair, 2,040 of them select. Per-target registration made up about 5.3 s of setup, which led to the setup-batching change (`2026-08-08-kubernetes-configmap-setup-batching-plan.md`, commit `1f529c3`) used by formal01.

Tracked docs agree with the raw data on every stated number:
- `2026-08-08-kubernetes-configmap-quantitative-preflight-attempt-01.md`: the pf01 status, empty logs and no rows.
- `-preflight.md` (pf02): 228 rows, 945 counters, 30/328, 45/493, 2970.647/1531.724/0.509, attach 19.608/21.692.
- `-preflight-03.md`: 3,816 rows, status 2, and the cleanup fields. This doc gives no timings, so the table above is the only numeric record of pf03.

#### W4 quantitative formal01 (`kubernetes-configmap-quantitative/20260808T142207Z-w4-quantitative-formal01`, 0.44 GB, entirely untracked)

**Run setup:**
- Command: `make experiment-kubernetes-configmap-quantitative`, an alias of the `kvm-` target that the review names.
- Source `1f529c3` and kernel `b07117a` (guest `7.1.0-rc7-gb07117a3cb41`), both clean. virtme-ng 1.40.
- Each guest has 4 vCPUs, QMP-pinned to host CPUs 4-7 and verified, and 8 GB.
- Host CPU: intel_pstate with no_turbo=1 and the performance governor.
- Each boot gets a fresh 1 GB raw ext4 virtio disk with `cache=none`.
- Matrix: 20 boots x 5 AB/BA pairs x widths 4/16/64/256 x 2 mechanisms.
- Primary metric: `wall_span_ns`, with `attach_ns` measured separately.
- `run.json` is `completed`, 14:22:21Z-14:30:51Z.

**Analyzer check.** The run's `artifacts/source/analyze.py` is byte-identical to HEAD `analysis/kubernetes_configmap_quantitative/analyze.py`. Running its `summarize()` in memory on the raw 175 MB `observations.jsonl` reproduced `analysis/summary.json` and `per-boot.jsonl` exactly.

**Correctness counts.** All verified against the raw data; all 238,800 rows have `pass=true`.

| Evidence | Raw count | Derivation | Tracked claim |
| --- | ---: | --- | --- |
| Lifecycle rows | 800 | 20 boots x 4 widths x 5 pairs x 2 mechanisms; AB/BA 200/200 per mechanism; all `cleanup_pass`; consumer exit 0 | 800/800 ✔ |
| Identity rows | 170,000 | per width 2,000 / 8,000 / 32,000 / 128,000 | 170,000 ✔ |
| Lower-preservation rows | 67,200 | 2(w−1) per pair x 100 pairs: 600 / 3,000 / 12,600 / 51,000 | 67,200 ✔ |
| AtomicWriter materialization audits | 400 | 100 per width | 400 ✔ |
| Unmanaged-directory rows | 400 | 100 per width | 400 ✔ |
| Fresh KVM boots | 20 | 11,940 rows each | 20 ✔ |

**Per-boot checks**, in 20/20 boots:
- mechanism, guest-inner, inventory and dmesg statuses are all 0, and vCPU affinity is `verified`;
- host block cleanup is 0 with the image gone, and guest cleanup is 0 with mountpoint 32;
- the post-boot BPF program, cgroup and FUSE inventories are empty;
- all 1,220 `*.stderr.log` files are 0 B.

**namei_ext counter sums:** managed identity checks 134,400, managed hidden checks 1,600, unmanaged checks 34,000.

**Primary scaling result.** The ratio is boot-clustered paired namei_ext/AtomicWriter `wall_span`: the median over boots of the per-boot median log ratio, with a bootstrap 95% CI (seed 20260807, 10,000 resamples).

| Width | AW median (ms) | namei_ext median (ms) | Ratio [95% CI] | Publication ratio [95% CI] | Per-boot ratio range (boots <1) | Pairs with namei faster | Attach-inclusive ratio [95% CI]* |
| ---: | ---: | ---: | --- | --- | --- | ---: | --- |
| 4 | 6.122 | 10.655 | 1.742 [1.725, 1.771] | 0.000966 [0.000919, 0.001009] | 1.625-1.898 (0/20) | 2/100 | 3.867 [3.807, 3.939] |
| 16 | 6.891 | 11.015 | 1.614 [1.565, 1.651] | 0.000783 [0.000735, 0.000825] | 1.445-1.783 (0/20) | 0/100 | 3.499 [3.381, 3.626] |
| 64 | 10.387 | 12.743 | 1.237 [1.220, 1.269] | 0.000419 [0.000406, 0.000431] | 0.984-1.367 (1/20) | 18/100 | 2.588 [2.471, 2.605] |
| 256 | 33.708 | 23.472 | **0.720 [0.680, 0.731]** | 0.000151 [0.000144, 0.000164] | 0.647-0.772 (20/20) | 96/100 | 1.099 [1.039, 1.136] |

\* (namei `wall_span` + `attach_ns`) / AW `wall_span`, with the same clustering and bootstrap. The review gives only the w256 value, and it matches; the w4-w64 values appear only here.

`supports_lower_cost` is true only at w256, while `supports_lower_publication_cost` is true at every width. The verdict is `supports-lower-cost-at-primary-scale`. Medians of the raw pooled pair ratios are 1.768 / 1.625 / 1.233 / 0.707.

**Timing per width and mechanism.** Medians of per-boot medians in ms, with 95% CIs:

| Width | Mechanism | wall_span | active_total | publication_only | consumer_only | setup | attach |
| ---: | --- | --- | --- | --- | --- | --- | --- |
| 4 | AW | 6.122 [5.998, 6.200] | 4.834 [4.770, 5.017] | 2.563 [2.528, 2.669] | 2.052 [1.986, 2.122] | 0.181 [0.169, 0.187] | - |
| 4 | namei | 10.655 [10.640, 10.666] | 10.654 [10.639, 10.662] | 0.003 [0.002, 0.003] | 0.211 [0.206, 0.222] | 10.428 [10.417, 10.434] | 12.824 [12.615, 13.054] |
| 16 | AW | 6.891 [6.705, 7.069] | 5.657 [5.475, 5.843] | 3.394 [3.292, 3.471] | 1.945 [1.819, 2.098] | 0.173 [0.168, 0.189] | - |
| 16 | namei | 11.015 [11.010, 11.038] | 11.014 [11.009, 11.037] | 0.003 [0.003, 0.003] | 0.304 [0.298, 0.312] | 10.706 [10.698, 10.709] | 13.029 [12.780, 13.383] |
| 64 | AW | 10.387 [10.142, 10.517] | 9.144 [8.822, 9.242] | 6.775 [6.594, 6.930] | 1.891 [1.871, 2.031] | 0.175 [0.167, 0.187] | - |
| 64 | namei | 12.743 [12.724, 12.772] | 12.739 [12.723, 12.771] | 0.003 [0.003, 0.003] | 0.857 [0.842, 0.871] | 11.854 [11.842, 11.874] | 13.112 [12.723, 13.503] |
| 256 | AW | 33.708 [32.398, 35.750] | 32.432 [31.101, 34.396] | 25.517 [24.421, 27.604] | 6.615 [6.549, 6.696] | 0.181 [0.168, 0.190] | - |
| 256 | namei | 23.472 [23.371, 23.756] | 23.469 [23.368, 23.754] | 0.004 [0.004, 0.004] | 6.325 [6.295, 6.391] | 17.141 [17.044, 17.232] | 12.937 [12.597, 13.177] |

**Per-state phases.** The per-state publish and consumer medians with CIs are in the kept `analysis/summary.json` (`timing_ci95_ns`). For example, at w256 the AW update publish takes 9665.1 µs vs 1.2 µs for namei, and initial consumer time is 1813.7 vs 1674.3 µs.

**namei_ext setup attribution (ms) and materialization** (medians, identical in every pair):

| Width | Object prep | Target registration | Map population | cgroup move | Registered targets | AW new files / bytes | AW live files per state | namei lower files / bytes |
| ---: | ---: | ---: | ---: | ---: | ---: | --- | ---: | --- |
| 4 | 0.226 | 10.158 | 0.024 | 0.015 | 6 | 9 / 97 | 3 | 6 / 64 |
| 16 | 0.445 | 10.195 | 0.046 | 0.015 | 30 | 45 / 493 | 15 | 30 / 328 |
| 64 | 1.379 | 10.314 | 0.131 | 0.016 | 126 | 189 / 2,077 | 63 | 126 / 1,384 |
| 256 | 5.820 | 10.786 | 0.471 | 0.017 | 510 | 765 / 8,413 | 255 | 510 / 5,608 |

namei_ext also adds w placeholders and 3w−2 prepared regular files per pair: 10/46/190/766. Its visible files equal the AW live files. AW live bytes per state (initial/update/no-op/rollback) are 33/31/31/33, 165/163/163/165, 693/691/691/693 and 2805/2803/2803/2805.

**Pooled raw distributions.** These were computed for this record and are not part of the analysis: n=100 rows per width/mechanism, in ms. The namei_ext tail comes from setup (target registration).

| Width | Mechanism | wall p50 | wall p95 | wall p99 | wall mean | wall min-max | publication p50 / p95 / max | attach p50 / p95 / max |
| ---: | --- | ---: | ---: | ---: | ---: | --- | --- | --- |
| 4 | AW | 6.088 | 7.756 | 13.467 | 6.341 | 4.692-14.298 | 2.598 / 3.331 / 4.334 | - |
| 4 | namei | 10.655 | 23.965 | 24.616 | 11.534 | 10.548-24.759 | 0.0025 / 0.0040 / 0.0096 | 12.894 / 17.864 / 28.139 |
| 16 | AW | 6.818 | 8.637 | 9.189 | 7.024 | 6.050-9.204 | 3.448 / 4.132 / 6.100 | - |
| 16 | namei | 11.037 | 21.294 | 24.817 | 12.068 | 10.937-24.893 | 0.0026 / 0.0039 / 0.0108 | 12.970 / 15.104 / 18.359 |
| 64 | AW | 10.392 | 16.274 | 19.014 | 11.200 | 8.895-22.004 | 6.851 / 12.518 / 18.839 | - |
| 64 | namei | 12.740 | 22.774 | 26.513 | 13.620 | 12.609-30.167 | 0.0029 / 0.0040 / 0.0630 | 13.264 / 16.107 / 31.918 |
| 256 | AW | 34.013 | 44.443 | 53.264 | 35.159 | 28.783-63.178 | 25.788 / 34.969 / 54.588 | - |
| 256 | namei | 23.551 | 31.231 | 37.038 | 24.799 | 22.934-37.234 | 0.0040 / 0.0061 / 0.0273 | 13.079 / 17.192 / 19.915 |

**Comparison with tracked docs.**
- `docs/tmp/2026-08-08-kubernetes-configmap-quantitative-formal01-result-review.md`: every number agrees with the raw data. This covers:
  - the commits and the 20 boots;
  - the five evidence counts, which total 238,800;
  - all four ratios and CIs;
  - the w256 decomposition: setup 0.181 vs 17.141, publication 25.517 vs 0.004, consumer 6.615 vs 6.325, attach 12.937 ms;
  - the setup components 5.820 / 10.786 / 0.471 / 0.017;
  - "28.0% lower" (1 − 0.720);
  - "33.3% fewer bytes" (5,608 / 8,413);
  - the attach-inclusive 1.099 [1.039, 1.136].

  The only mismatch is cosmetic: the review uses the `kvm-` target name.
- `docs/evaluation.md` (lines 34, 77, 191, 251-254) agrees on the counts, the ratios and CIs, the w256 decomposition, and w4 setup 10.428 / publication 2.563 ms.
- **Paper:** no formal01 number appears in `docs/paper/sections/*.tex`. The W4 row cites only the 3-boot publication-rq1 correctness run.

### mdtest cold metadata (RQ2)

All six roots came from `make kvm-mdtest-cold-metadata-preflight` (`mk/experiments/mdtest_cold_metadata.mk`, `analysis/mdtest_cold_metadata/`). Plan: `docs/tmp/2026-07-29-rq2-mdtest-cold-metadata-experiment-plan.md`. The goal was to extend RQ2 to file create, cache-cold stat and cache-cold remove, hypothesizing that SELECT beats FUSE with a paired CI above 1.

Protocol:
- Official IOR/mdtest 4.0.0 (`967a9f6`).
- Five conditions: stock, unattached, PASS, SELECT, and official libfuse 3.18.2 `passthrough_ll`.
- Stock kernel `062871f`. Patched kernel `621aff8` in the original protocol, `b07117a` in the reconsideration.
- Ranks 1 and 4, 4,096 items per rank, fresh ext4 per cell.
- One block of 5 boots; 8 vCPUs pinned to host CPUs 8-15.

No root reached analysis, and every `run.json` is `failed`. `docs/evaluation.md` (lines 377-386) records the branch as closed. No mdtest number is in the paper.

**Original protocol (2026-07-30/31, virtme-ng 1.40).**

| Run | Source | Change | run.json failure | Raw evidence | Workload obs |
| --- | --- | --- | --- | --- | --- |
| preflight01 `233331Z` | `a64bc81` | vng `--pin` | `vcpu-affinity-verification` | verifier failed after 199 attempts (`ECONNREFUSED`); 8 vCPU TIDs all at `cpus_allowed` 0-23; 0 B launcher logs | 0 |
| preflight02 `235638Z` | `2e28e52` | 3 s verifier delay | `vcpu-affinity-verification` | 200 attempts, 0 vCPU records, `ECONNREFUSED`; "QMP capabilities negotiation failed / Failed to pin vCPUs" | 0 |
| preflight03 `20260731T002221Z` | `28432e4` | project pin controller + verifier | `kvm-launch-or-guest-command` | pin `pinned` (3 attempts), verifier `verified` (masks [8]..[15]); 0 B launcher logs, no exit status | 0 |

These agree with the attempt-1/2/3 docs and `2026-07-30-rq2-mdtest-cold-metadata-preflight-result-review.md` (NO-GO, incomplete). One omission: the attempt-1 doc does not mention the final `ECONNREFUSED`.

**Reconsideration protocol (2026-08-02).** This used official virtme-ng `1.41+18.g8f74cce` with native pinning and kernel `b07117a`; plan `2026-08-02-rq2-mdtest-cold-metadata-reconsideration-plan.md`.

| Run | Source | run.json failure | Raw evidence |
| --- | --- | --- | --- |
| recon-preflight01 `013000Z` | `1075fb3` | `vcpu-affinity-verification` | launcher 255; guest cmdline truncated, so "Kernel panic - not syncing: VFS: Unable to mount root fs"; verifier 200 x `ECONNREFUSED`; 0 obs |
| recon-preflight02 `084214Z` | `08c4f6b` | `kvm-launch-or-guest-command` | stock/unattached/PASS/SELECT all passed 6/6 cells (24/24). FUSE: launcher 2; r1 create `phase_status=255`, 0 ops/s, daemon live; mdtest "ERROR: close(14) failed", MPI_ABORT |
| recon-preflight03 `090648Z` | `aa77dad` | `kvm-launch-or-guest-command` | 24/24 non-FUSE cells passed. FUSE: launcher 2, one placeholder row (`pass=false`, engagement fields zero), no daemon logs; ext4 scratch unmounted after the 30 s mount wait |

mdtest aggregate throughput, in thousands of ops/s, one sample per cell. All non-FUSE rows have `tree_correct` and `cleanup_complete`; SELECT rows have `selected_identity`. FUSE has no valid cell.

| Ranks | Op | stock pf02 | unatt pf02 | PASS pf02 | SELECT pf02 | stock pf03 | unatt pf03 | PASS pf03 | SELECT pf03 |
| ---: | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 1 | create | 123.7 | 137.7 | 135.5 | 133.8 | 137.6 | 137.2 | 135.1 | 135.4 |
| 1 | stat (cold) | 352.5 | 346.2 | 343.3 | 340.9 | 353.0 | 352.5 | 335.5 | 342.7 |
| 1 | remove (cold) | 166.3 | 154.9 | 149.8 | 151.4 | 162.8 | 157.3 | 156.8 | 155.0 |
| 4 | create | 324.1 | 398.6 | 392.6 | 387.0 | 394.7 | 391.1 | 390.2 | 387.7 |
| 4 | stat (cold) | 996.2 | 1318.7 | 1185.9 | 1225.6 | 1297.9 | 1310.5 | 1250.3 | 1224.7 |
| 4 | remove (cold) | 520.7 | 519.5 | 496.2 | 488.8 | 521.6 | 491.4 | 495.5 | 512.9 |

The spread between runs is large: stock r4 stat was 996.2 in pf02 and 1297.9 in pf03. These values cannot support any RQ2 claim, and no tracked doc records them; this table is their only record.

The reconsideration attempt-1/2/3 docs and `docs/evaluation.md` agree with the raw data on statuses, the panic, 24/24 cells, the FUSE `close(14)` failure and the placeholder row. The host RLIMIT diagnostic in the attempt-2 doc was a separate host experiment and is not in the root.

### Concurrent target lifetime preflights (RQ3)

**Producer and purpose.** All ten roots came from `make kvm-namei-ext-target-lifetime-preflight` (`mk/experiments/namei_ext_target_lifetime.mk`, `analysis/namei_ext_target_lifetime/`). The experiment tests whether a registered target `struct path` stays valid while an RCU walk borrows it and a writer replaces or clears the registration. It has three cells (final-file, directory, pinned-object) plus a four-row borrower/updater RCU litmus, and runs on normal, KASAN and KCSAN kernels. Plan: `docs/tmp/2026-07-30-rq3-concurrent-target-lifetime-experiment-plan.md`. The kernel is `621aff8`. Project commits run from `1c76c01` to `3c06c34`, one per repair.

**No formal run exists.** All ten `run.json` files are `failed` (`kvm-launch-or-guest-command`). The closing commit is `78344cd`. `docs/evaluation.md` calls the matrix "closed without a formal result", with a final preflight of 99 KCSAN blocks. The paper's registered-target lifetime row (128 replacements) comes from an earlier Phase 1 check, not from these roots.

**Bulk content.** None of the roots contains a kernel image. The size comes from two things:
- a 512 MiB ext4 `lower.img` loop image left in pf01, pf03 and pf04, because the guest failed before its `rm -f`;
- a 457 MiB `observations.jsonl` in pf07.

| Run | Src | Boots reached | Failure evidence | Key raw numbers |
| --- | --- | --- | --- | --- |
| pf01 | 1c76c01 | normal (runner rc 0) | `analysis failed: final-file: no RCU target resolution during target retirement` | updates 41/27 (file/dir); RCU resolves inside update windows: success-in-replace 198/133, ENOENT-in-clear 213/134; ftrace 13885/13885, 13569/13569 retained |
| pf02 | 2f2e6a1 | none | 180 s launcher timeout (04:55:46 to 04:58:46), empty logs | none |
| pf03 | 2f2e6a1 | normal (runner rc 1) | `libbpf: prog 'hold_borrowed_target': failed to attach: -EBUSY` | run-summary failures 4; 0 litmus rows; pinned-object 4 cycles pass |
| pf04 | 0908b3f | normal, KASAN, KCSAN | KCSAN: `kernel diagnostics make boot negative: 160 block(s)` | normal and KASAN analysis `positive`; 4/4 litmus pass in all 3 boots; KCSAN data_races 223 to 255 (early-enabled), top headlines set_nlink, v9fs, tick, GUP |
| pf05 | edfeeca | none | 180 s launcher timeout (06:08:57 to 06:11:57), empty logs | none |
| pf06 | edfeeca | normal (guest body) | `install: cannot change permissions of '/mnt/namei-ext-target-lifetime'` | runner never started |
| pf07 | f18926e | normal (runner rc 1) | artifact status failed (mk line 291); `run-summary failures=426` | `observations.jsonl` 2,241,443 lines / 479,026,976 B; final-file ftrace 94,519 of 137,000 written; 2 litmus rows |
| pf08 | cd21c29 | normal (runner rc 0, 0 failures) | `analysis failed: final-file: fewer than two selected target states observed` | 4/4 litmus pass; history 33 ms; ftrace 163/163 and 168/168; final-file readers 63+1 absent and 66+1 absent; stress 1612/1630 updates |
| pf09 | af6498e | normal, KASAN, KCSAN | KCSAN: `179 block(s)` (178 `init_file / init_file`, 1 `acct_account_cputime / stop_this_handle`) | normal stress 9,038,845 / 8,453,726 opens and 1584/1621 updates; KASAN 360,534 / 353,428 opens and 673/796 updates; KCSAN watchpoints 237,077, races 0 to 248; 4/4 litmus pass in all boots |
| pf10 | 3c06c34 | normal, KASAN, KCSAN | KCSAN: `99 block(s)` (97 `init_file`, 1 `folio_mark_accessed / workingset_activation`, 1 `link_path_walk / v9fs_stat2inode_dotl`) | normal stress 8,485,868 / 8,121,267 opens; KASAN 850/805 updates; KCSAN stress 86,935 / 82,958 opens and 958/955 updates; watchpoints 247,452; races 99; asserts 0; 4/4 litmus pass in all boots |

(Pairs are final-file/directory. In pf09 and pf10, the normal and KASAN `analysis.json` both report `status=positive`, dmesg `clean`, four observed target states per publication cell, 160 trace entries per cell, and pinned-object lifecycle pass. No KCSAN boot has an `analysis.json`, because the analyzer failed on the diagnostics gate.)

**Comparison with the tracked docs.** Each run has a dated record in `docs/tmp/2026-07-31-rq3-target-lifetime-preflight*.md`. I spot-checked them against the raw data and found no disagreements:
- **pf01:** I recomputed the doc's 198/213 and 133/134 RCU resolve counts from the raw ftrace by counting `resolve_return` (with rcu_walk=1) between `update_enter` and `update_return`. Both pairs match, as do the 41/27 updates.
- **pf04:** 160 blocks and 223 to 255 races match.
- **pf07:** 2,241,443 lines, 457 MiB, 94,519/137,000 and 426 failures all match.
- **pf08:** reader counts and the 163/168 trace counts match. The doc's "312 KiB" history size is 312,337 bytes (305 KiB), a unit rounding only.
- **pf09:** stress counts, 237,077 watchpoints, 248 races and 179 blocks match.
- **pf10:** the 86,935/82,958 opens, 958/955 updates, 247,452 watchpoints, 99 races and the 97/1/1 block split all match. The `docs/evaluation.md` statement that the matrix closed with 99 blocks also matches.
- **pf02 and pf05:** the PTY job-control stop is an operator observation. The roots record only the 180 s timeout and empty logs.

The pf03 and pf06 errors match the docs verbatim.

### pjdfstest semantic continuation (RQ1)

**Producer and purpose.** The preflights came from `make kvm-semantic-continuation-preflight` and the formal runs from `make kvm-semantic-continuation` (`mk/experiments/semantic_continuation.mk`; producer commits `8478642`, `021c016`, `99f0c74`, `f9aa34b`). The experiment checks whether a policy-selected existing object goes through ordinary VFS operations with the same outcomes as direct use of the lower object. It is a paired direct/selected matrix of pjdfstest-derived operation families, using pjd/pjdfstest commit `ededbeb` with `reuse=operation-families-not-unmodified-suite`. The pjdfstest suite itself is not run, so pjdfstest pass/fail counts do not exist. The matrix has 16 cases (S01–S16) and 80 operations on ext4 and tmpfs, run on kernel `b07117a` (plan: `docs/tmp/2026-08-01-rq1-pjdfstest-semantic-continuation-plan.md`). Each root is about 20 MB, mostly a copy of the 17.7 MB `bzImage` plus the 2.1 MB static runner.

| Run | Status | Evidence | Key numbers |
| --- | --- | --- | --- |
| preflight-v1 (src 8478642, PTY) | failed `kvm-launch-or-guest-command` | 300 s launcher timeout (12:52:39 to 12:57:39), empty launcher logs, no observations | none |
| preflight-v2 (8478642) | failed | `configure-policy errno=5 pass=false`; `boot.json` inner_status 2, cleanup 0, dmesg 0; runner.status 1 | 3 setup events, 1 failed; no case ran |
| preflight-v3 (021c016) | failed `host-finalize` | guest `boot.json` completed, all 51 events pass; the finalizer grep for `FSTYPE ext4` does not match the `findmnt` table, where ext4 is the third data column | 14 setup, 26 operations, 4 cases, 4 residual, 2 engagement; S02 target-A delta 7; S11 A/B 3/3 |
| formal-v1 (99f0c74, protocol v1) | completed; `summary.json` verdict `supported-for-frozen-matrix` | 3 boots (direct-selected, selected-direct, direct-selected order), all runner, cleanup and dmesg statuses 0 | 255 events/boot (160 operations, 32 cases, 32 residual, 16 engagement, 14 setup, 1 summary), 0 false; direct 48, selected 48, engagement 48, residual 96; errno per boot: ENOENT 12, EEXIST 2, EACCES 2, EXDEV 4 |
| formal-v2 (f9aa34b, protocol v2) | completed; verdict `supported-for-frozen-matrix` | 3 boots, all statuses 0; `semantic_continuation_operations.tsv` lists 80 operations (S01–S16) | 337 events/boot (+80 per-operation engagement, +2 identity), 0 false; direct 48/48, selected 48/48, case engagement 48, operation engagement 240, identity 6, residual 96 |

**Comparison with the tracked docs.**
- **Preflights:** `docs/tmp/2026-08-01-semantic-continuation-preflight-v1-v2.md` and `-preflight-v3.md` match the raw data: the 3 v2 setup events are verbatim, and v3 has 51 events, 26 operations and the 7 / 3+3 engagement counts.
- **formal-v1:** `docs/tmp/2026-08-01-semantic-continuation-formal-v1-review.md` matches. The raw data has 255 events/boot, 48/48/48/96, and 2 EACCES and 4 EXDEV per boot, which gives the doc's totals of 6 EACCES and 12 EXDEV. An independent audit rejected formal-v1 as a paper result: S16 identity was not kept in the raw data, the counters were case-level, returns were reduced to success/error class, and S15 shared a physical file. It is superseded but kept immutable.
- **formal-v2:** `docs/tmp/2026-08-01-semantic-continuation-formal-v2-result.md` matches the raw data:
  - 337 events per boot and 160/80/32/16/32/14/2/1 per type;
  - S15: the selected arm `read-unmanaged` returns 14 bytes in both arms, with `pass_delta=1` and zero target deltas;
  - S16: identity records show dev 1792, ino 47 (direct) and 79 (selected), with actual equal to expected; `open-directory` has target-A delta 1, and the five post-teardown operations have all-zero deltas.

**Paper use.** formal-v2 is the source of the "Selected-object semantic preservation" row in `docs/paper/sections/05-evaluation.tex` (Table `tab:mechanism-validation`), and of the matching row in `docs/evaluation.md`. Both cite "48/48 direct and 48/48 selected cases, 240/240 per-operation engagements, six raw identity checks, and 96/96 residual checks", which agrees with the raw data. `docs/idea-story.md:126` cites the root path. The inventory shows `cite_paper=0` only because the paper text does not name the directory. No raw or summary file of this root is tracked: `analysis/summary.json` is 341 B, `report.md` 359 B and the operations TSV 2.6 KB. **This root is the only machine-readable record behind a paper table row.**

### Service config rotation preflights

**Producer and purpose.** All six roots came from `make kvm-service-config-rotation-preflight` (`mk/experiments/service_config_rotation.mk`, analysis `analysis/service_config_rotation/`). W4 was meant to show lookup-time generation selection for a Kubernetes-AtomicWriter-style config tree served by a live nginx 1.26.3 through the states current, canary, invalid reload and rollback. A 10-boot formal run was gated on a passing preflight (plan: `docs/tmp/2026-07-28-service-config-rotation-experiment-plan.md`). Every root uses kernel `bdc9a83` (7.1.0-rc7) and is about 25 MB: a copy of the 17.7 MB `bzImage`, the 3.8 MB nginx binary, the 2.1 MB runner and the 1.3 MB nginx source tarball. All six `run.json` files are `failed`, `kvm-launch-or-guest-command`.

| Run | Src | Raw-runner outcome | Failure evidence |
| --- | --- | --- | --- |
| v1 preflight-v1 | 86697b9 | 4 events; `current` physical control fails; nginx never started | nginx opened `<prefix>/results/.../generation-current/nginx.conf` (relative `-c` under `-p`), and `logs/` was missing |
| v1 preflight-v2 | 46f471d | same 4 events | `chown(.../client_body_temp, 65534) failed (1: Operation not permitted)` |
| v1 preflight-v3 | 07c6372 | same 4 events | `chown(..., 0) failed (1: Operation not permitted)`, after adding `user root;` |
| v2 preflight-v1 | 7edc34a | 13 events; runtime boundary pass; 4/4 physical `nginx -t` controls pass (invalid correctly rejected); `attach_policy` errno 13; 2 failures | verifier: `dereference of modified ctx ptr R2 off=16 disallowed` |
| v2 preflight-v2 | 4372726 | 16 events; attach and scope pass; nginx master 191 / worker 192; `current` state fail with `http_body=""`, `poll_attempts=0`, logical sha256 = physical sha256; cleanup all pass | readiness timeout (5 s) |
| v2 preflight-v3 | ac916d6 | 16 events; 13 case rows; 1 of 4 state rows (failed); 0 counter rows; master 195 / worker 196; cleanup all pass; no `boot.json`, `observations.jsonl` or `dmesg.log` | same timeout; captured `kernel.config` has `# CONFIG_PROC_CHILDREN is not set` |

**Comparison with the tracked docs.** The per-attempt records `docs/tmp/2026-07-28-service-config-rotation-preflight-attempt-{1,2,3}.md` and `-v2-preflight-attempt-{1,2,3}.md` agree with the raw data on every quoted error, PID and count. `-v2-result-review.md` recomputes 16 events, 0/4 completed states, 13/15 case rows and 0/3 policy-counter rows, and these match the raw stream. The v2 attempt-2 doc attributes the timeout to content-directory permissions. The attempt-3 doc refutes this: the timeout repeated after the content was moved, and the doc names the missing `/proc/<pid>/task/<pid>/children` (CONFIG_PROC_CHILDREN) as the strongest, inferred cause. The raw data only supports that this option is unset in the captured kernel config; no errno was recorded. The review's verdict is "dependency evidence; paper value: none".

**No formal service-config-rotation run exists**, and no root of this family is tracked. `docs/evaluation.md` says the nginx live-reload protocol "remains closed after three failed preflights". W4 now rests on the `kubernetes-configmap-publication-rq1` root, which is tracked and outside this slice, and on the `kubernetes-configmap-quantitative` runs. These six roots are the only raw record of the nginx-based W4 attempts, and the paper does not cite them.

### Spindle HPC staging preflights and formal01 payload (W6)

W6 "HPC File Staging" is an RQ1 source-derived case study. Pinned LLNL Spindle (`8853636`) runs its unchanged `test_driver --dlopen --pull --nompi` loader slice and populates 47 node-local cache objects on tmpfs. Two further conditions run against that cache:
- `namei_ext` selects those exact objects for the same loader.
- A withdrawn-target control removes `libtest10.so`.

The producers are `make kvm-spindle-staging-preflight` (1 boot) and `make kvm-spindle-staging` (3 boots), both in `mk/experiments/spindle_staging.mk`. The records are `docs/tmp/2026-07-29-spindle-hpc-staging-*.md` and `2026-08-02-w6-spindle-*.md`. Each preflight root is about 230 MB, mostly payload: a 158-165 MB extracted Spindle runtime tree in `boots/repetition-01/runtime` plus about 64 MB of artifacts (bzImage, runner, BPF object, bpftool, source and runtime tarballs).

| Run | Project / kernel | Status | First failed gate (raw evidence) | Doc |
|---|---|---|---|---|
| `20260729T142246Z-spindle01` | 88f8b25 / 621aff8 | failed | inner guest target exit 2: `sha256sum: .../runtime-inputs.sha256: No such file` (path resolved after `cd`); no condition ran; 1,050 sealed evidence entries | preflight-attempt-1 |
| `20260729T143220Z-spindle02` | e336f4f / 621aff8 | failed | source Spindle control `exit 0, pass=false` (2.622 s): `readlink(hello_.py) expected error 22. Got error 2` (unpackaged fixture). `boot.json` was later rewritten by `make -n`, as the doc states | preflight-attempt-2 |
| `20260729T164002Z-spindle03` | 233688d / 621aff8 | failed | Spindle exit 0, but the runner returned `runner_errno=16` (EBUSY) after a process-group wait (12.324 s) | preflight-attempt-3, attempt-4-repair |
| `20260802T114500Z-spindle04` | 4563b2f / b07117a | failed | no `boot.json`, 0 B launcher logs, about 600 s KVM timeout. The doc's PTY cause is not visible in the raw files | preflight-attempt-5 |
| `20260802T113300Z-spindle05` | 4563b2f / b07117a | failed | 47/47 mappings; source 2.237 s; namei_ext loader exit 0 in 0.182 s but `diagnostic_ok=false`, because the harness required empty stderr while the loader prints 44 `dlstart` lines | preflight-attempt-5 |
| `20260802T113854Z-spindle06` | 85f6932 / b07117a | completed | all gates passed | preflight-attempt-6 |

spindle06, the authorization preflight:
- 209 observations, all `pass`.
- 47 mappings, selections, identity rows and preservation rows. There were 68 SELECT hits (1-3 per target).
- Source 2.280 s; namei_ext 0.162 s with the exact 44-line transcript.
- Withdrawn: exit 255 in 0.060 s, target-1 hits 5 -> 5.
- Mode-000 probe: `EACCES`.
- Verdict `supported`. The empty fields in its `report.md` are the jq-escaping defect that the doc describes.

All six docs agree with the raw data on every number checked.

**Formal01 payload sub-paths** (`spindle-staging/20260802T114220Z-w6-formal01/`). The run used `make kvm-spindle-staging`, project `4673c1f` (clean), kernel `b07117a` and 3 boots. 184 files are tracked: the analysis, `observations.jsonl`, `run.json`, the manifest, the kernel config, build logs, fixtures, and every per-boot boot/observation/raw-runner/status/log/inventory file. The six ignored sub-paths are pure payload:

| Ignored sub-path | Bytes / files | Contents |
|---|---|---|
| `artifacts/kernel/bzImage` | 17,699,840 / 1 | guest kernel `7.1.0-rc7-gb07117a3cb41` (config tracked) |
| `artifacts/runtime` | 4,371,040 / 3 | `bpftool`, runner `namei_ext_spindle_staging`, `spindle_staging.bpf.o` |
| `artifacts/source/spindle-runtime-tree.tar.gz` | 42,023,523 / 1 | packaged Spindle 8853636 runtime (1,195 entries) |
| `boots/repetition-0{1,2,3}/runtime` | about 164.65 MB / 1,034 files each | per-boot extracted runtime worktree (`prefix/`, `build/testsuite/libtest*.so`) |

The tracked analysis fully covers the run. The headline numbers below were recomputed from the tracked `observations.jsonl` and are identical to `summary.json`:

| Boot | Source Spindle (exit, s) | namei_ext (exit, s) | Withdrawn (exit, s) | SELECT hits | Mapping/selection/identity/preservation |
|---|---|---|---|---|---|
| 1 | 0, 2.275 | 0, 0.212 | 255, 0.091 | 68 | 47/47/47/47 |
| 2 | 0, 2.137 | 0, 0.182 | 255, 0.071 | 68 | 47/47/47/47 |
| 3 | 0, 2.196 | 0, 0.141 | 255, 0.050 | 68 | 47/47/47/47 |

There are 627 observations, all `pass`, with 204 SELECT events in total. The verdict is `supported`. The raw data agree with the formal01 review, the W6 rows in `docs/evaluation.md`, and the paper's `05-evaluation.tex`: three boots, 141 rows, 204 SELECT events and three withdrawn controls.

### Spindle staging RQ2 FUSE comparison (W6 RQ2)

This RQ2 cost comparison uses the same Spindle loader slice. Each boot first repeats source population (47 mappings). One fresh boot then serves the target through `namei_ext`. The paired fresh boot serves it through an optimized FUSE baseline:
- libfuse 3.18.2, low-level, 8 threads;
- 3600 s entry and attribute timeouts;
- `allow_other` and `default_permissions`;
- kernel passthrough.

Both arms run the same identity, target, permission (`EACCES`), withdrawal and preservation oracles. The primary metric is the geometric mean over boots of the per-boot median FUSE/namei_ext loader latency, with a paired bootstrap 95% CI (seed 20260802). The hypothesis is that this ratio is above 1. Plan: `docs/tmp/2026-08-02-spindle-rq2-fuse-comparison-plan.md`.

Producers (`mk/experiments/spindle_staging_rq2.mk`, analyzer `analysis/spindle_staging_rq2/`):
- `make kvm-spindle-staging-rq2-preflight`: 1 pair, 1 warmup + 5 measured launches.
- `make kvm-spindle-staging-rq2`: 10 alternating pairs (20 boots), 3 warmups + 50 measured launches per boot.

Every run uses host CPUs 4-7 and kernel `b07117a`, and none is tracked. Most of the bytes are payload: each boot directory holds a ~162 MB runtime copy, which accounts for about 3.29 GB of formal01 and 3.24 GB of formal04.

| Run | Project | Lower fs | Outcome | First failed gate (raw) | Doc |
|---|---|---|---|---|---|
| `20260802T134059Z-w6-rq2-preflight02` | 82e1fcb | 9p | failed | FUSE `mode_zero`/`mode_restore` invalidation status -2 (inode 0, entry -2); permission `observed_errno=0`; namei boot completed | 2026-08-02-spindle-rq2-preflight-attempt-1 |
| `20260808T060045Z-w6-rq2-preflight03` | a6409b8 | - | aborted | `vcpu-affinity-pinning`: 200 x `Operation not permitted`; QEMU could not create its QMP socket; no observations | ...-preflight-affinity-abort |
| `20260808T060509Z-w6-rq2-preflight04` | 5b475ad | 9p | failed | FUSE withdrawal: loader exit 0, `expected_diagnostic=false`, target opens 20 -> 23 | ...-preflight-attempt-2 |
| `20260808T062934Z-w6-rq2-preflight05` | 16722b1 | 9p | failed | FUSE daemon threads 6 -> 7 under a constant-thread gate | ...-preflight-attempt-3 |
| `20260808T065224Z-w6-rq2-formal01` | d17a80d | 9p | completed, rejected in review | no raw gate failed; rejected for the 9p confound and entry `-ENOENT` | ...-formal01-result-review |
| `20260808T073352Z-w6-rq2-formal02` | 2475071 | tmpfs | failed, 1/20 boots | block-1 FUSE invalidation status -2 (inode 0, entry -2) under a strict gate | ...-formal02-failure, -formal02-repair |
| `20260808T074422Z-w6-rq2-formal03` | 06c1a36 | tmpfs | failed, 1/20 boots | same statuses with entry-first order | ...-formal03-failure, -invalidation-order-repair |
| `20260808T081532Z-w6-rq2-preflight04` | 2812ef3 | tmpfs | failed | namei withdrawal `fstatat observed_errno=0` (expected 2); FUSE boot did not run | ...-preflight04-failure |
| `20260808T082417Z-w6-rq2-preflight05` | f73adc7 | tmpfs | failed | FUSE withdrawal `fstatat` errno 0 (stale dentry); namei HIDE passed (ENOENT, hide 0 -> 4) | ...-preflight05-failure, -explicit-hide-repair |
| `20260808T083250Z-w6-rq2-preflight06` | c764e37 | tmpfs | completed | all oracles pass; 3/3 epoch fallbacks `epoch_status=0` | ...-preflight06-result-review, -fuse-epoch-fallback |
| `20260808T084214Z-w6-rq2-formal04` | 2483ad4 | tmpfs | completed, valid | none | ...-formal04-result-review |

The names `preflight04` and `preflight05` were reused on 2026-08-08; the timestamps keep them distinct.

Preflight timing, from one pair each and diagnostic only. p50 is over the 5 measured launches.

| Run | namei p50 / FUSE p50 (ms) | Major faults/launch (namei / FUSE) | FUSE window: callbacks, passthrough opens, read fallback | namei SELECT |
|---|---|---|---|---|
| preflight02 (08-02) | 126.019 / none | 31 / none | none | 340 |
| preflight04 (060509Z) | 233.260 / 181.449 | 31 / 4 | 1,325, 400, 0 | 340 |
| preflight05 (062934Z) | 268.373 / 236.800 | 31 / 4 | 1,325, 400, 0 | 340 |
| preflight04 (081532Z) | 171.140 / none | 0 / none | none | 340 |
| preflight05 (082417Z) | 83.822 / 97.366 | 0 / 0 | 1,325, 400, 0 | 340 |
| preflight06 | 79.120 / 82.217 (ratio 1.039) | 0 / 0 | 1,325, 400, 0 | 340 |

#### Formal01 (rejected; 9p lower filesystem)

20 boots; 5,380 events, all `pass`.

| Metric | namei_ext | FUSE |
|---|---|---|
| Measured / warmup launches (exit 0) | 500/500, 30/30 | 500/500, 30/30 |
| Pooled p50 / mean / p95 (ms) | 247.756 / 256.012 / 298.921 | 211.926 / 219.992 / 270.647 |
| Min / max (ms) | 214.243 / 880.584 | 186.991 / 667.897 |
| Major faults per launch | 31 | 4 |
| Mean client CPU per launch (ms) | 30.380 | 29.013; 32.949 with daemon |
| Mechanism per boot | 3,400 SELECT (68/launch) | 13,250 callbacks; 4,000 passthrough opens (3,400 focal); 0 read fallback |
| Daemon CPU per window, median (range) | n/a | 191.425 ms (174.0-239.3) |
| Oracles | EACCES 10/10, withdrawal exit 255 10/10, hits 162 -> 162 | EACCES 10/10, exit 255 10/10; 30/30 invalidations inode 0 / entry -ENOENT |

Per-pair median FUSE/namei latency ratios, pairs 1-10: 0.8527, 0.8558, 0.8687, 0.8353, 0.8789, 0.8828, 0.8444, 0.8804, 0.7917, 0.9187. Per-pair namei medians ranged from 237.4 to 263.0 ms and FUSE medians from 206.3 to 224.8 ms.

The primary ratio is **0.860333 [0.839555, 0.879792]**, with 0/10 pairs above 1. The stored v1 `summary.json` labels this `contradicted`.

A total-CPU geomean of 1.0847 [1.0470, 1.1224] was recomputed for this record with the current formula. The stored summary does not contain it, and it uses the daemon-thread snapshot method that the formal04 review later excluded.

#### Formal02 / formal03 (tmpfs; only the block-1 namei_ext boot completed)

| Run | Measured (exit 0) | p50 / mean / p95 (ms) | Min-max (ms) | Major faults | SELECT | Setup / teardown (ms) |
|---|---|---|---|---|---|---|
| formal02 | 50/50 | 96.912 / 100.762 / 122.819 | 80.967-188.067 | 0 | 3,400 | 540.8 / 41.0 |
| formal03 | 50/50 | 79.632 / 84.276 / 104.934 | 73.679-171.768 | 0 | 3,400 | 534.5 / 41.0 |

#### Formal04 (valid; latency inconclusive; tmpfs, FUSE epoch fallback, explicit namei HIDE)

20 boots, all with status 0 and tmpfs lower; 5,460 events, all `pass`.

| Metric | namei_ext | FUSE |
|---|---|---|
| Measured / warmup launches (exit 0) | 500/500, 30/30 | 500/500, 30/30 |
| Pooled p50 / mean / p95 (ms) | 81.658 / 94.648 / 145.518 | 84.524 / 89.047 / 106.150 |
| Min / max (ms) | 71.432 / 633.811 | 73.787 / 617.231 |
| Per-boot medians min / median / max (ms) | 77.250 / 82.882 / 102.981 | 80.899 / 84.763 / 90.608 |
| Major faults; mean minor faults | 0; 1,190.38 | 0; 1,190.80 |
| Mean client CPU per launch (ms) | 27.582 (21.429 user + 6.153 sys) | 26.265; 28.639 with daemon |
| Mean voluntary context switches per launch | 251.0 | 436.6 |
| Median setup / teardown (ms) | 537.232 / 35.989 | 4.261 / 4.249 |
| Source population median (ms) | 1,431 | 1,378 |
| Mechanism per boot | 3,400 SELECT (68/launch) | 13,250 callbacks (265/launch); 4,000 passthrough opens; 0 read fallback |
| Daemon CPU per window, median (range) | n/a | 114.190 ms (110.6-141.2) |
| Correctness, 10 boots each | 470 x 4 object rows; EACCES, fstatat ENOENT and exit 255 each 10/10; hits 162 -> 162; hide 0 -> 4 | 470 x 4; EACCES, ENOENT and exit 255 each 10/10; 30/30 invalidations entry -2 with epoch fallback 0 |

| Pair | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 |
|---|---|---|---|---|---|---|---|---|---|---|
| namei median (ms) | 80.687 | 85.754 | 85.077 | 77.893 | 90.570 | 77.250 | 102.981 | 86.869 | 80.571 | 78.269 |
| FUSE median (ms) | 82.671 | 85.516 | 86.695 | 87.048 | 90.608 | 80.899 | 88.378 | 83.360 | 84.009 | 82.938 |
| FUSE/namei | 1.0246 | 0.9972 | 1.0190 | 1.1175 | 1.0004 | 1.0472 | 0.8582 | 0.9596 | 1.0427 | 1.0597 |
| Total-CPU ratio | 1.0089 | 0.9796 | 0.9157 | 1.1209 | 1.1921 | 1.0895 | 0.9447 | 0.9937 | 1.0865 | 1.0945 |

The primary FUSE/namei_ext geomean is **1.010416 [0.966844, 1.049126]**, verdict `inconclusive`, with 7/10 pairs above 1. The total-CPU geomean is 1.039334 [0.989787, 1.090889], and the review excludes it from the paper. A read-only recomputation reproduces the stored `analysis/summary.json`, `summary.csv` and `report.md` exactly, and the analyzer is unchanged between 2483ad4 and HEAD.

#### Comparison with tracked docs

- **Formal04.** `2026-08-07-spindle-rq2-formal04-result-review.md` agrees with the raw data on every number it states:
  - 1.0104 [0.9668, 1.0491];
  - 1,000 measured and 60 warmup launches;
  - 940 x 4 object rows;
  - 20/20 oracles, hide 0 -> 4, and the 30 entry `-ENOENT` with epoch fallback;
  - 68 selections and 265 callbacks per launch;
  - 114.190 ms daemon CPU;
  - total CPU 1.0393 [0.9898, 1.0909];
  - setup 537.232 vs 4.261 ms.

  The review does not mention that namei_ext has the heavier tail (pooled p95 145.5 vs 106.2 ms), which pair 7 drives.
- **Formal01.** The review agrees on 0.860333 [0.839555, 0.879792], 13.97% lower FUSE wall time, 5,380 events, 31 vs 4 major faults, the 80 FUSE opens per launch (68 focal), and CPU 30.380 vs 32.949 ms.
- **Formal03, both preflight04/05 runs and preflight06.** These agree, including preflight06's 452 rows, 12 launches and 79.120 / 82.217 ms.
- **Formal02, preflight02 and preflight03 docs, and the stale W6 statements in `docs/evaluation.md` / `research/STATE.md`.** See the mismatch table at the top of this section.
- **HEAD analyzer.** Judging from the code, without running it, the current analyzer would reject formal01, because formal01 lacks the lower-filesystem, withdrawal-lookup and lifecycle events.
