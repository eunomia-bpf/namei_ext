## Agent workspace, application file sharing, build action/cache, and toolchain experiment roots (`results/experiments/{agent*,application*,build*,toolchain*}`)

Scope: the 137 ignored units under `results/experiments/` whose family starts with
`agent`, `application`, `build`, or `toolchain`. The per-unit CSV is
`p6-experiments-a.csv`. All numbers below come from read-only aggregation of the
raw JSONL, `run.json`, `boot.json`, summary and dmesg files on the lab host
(HEAD `eba72a6`), and were compared against tracked docs.

Conventions:

- "rows" means JSONL records. "pass rows" means records that carry a `pass`
  field. "fail" means records whose `pass` is not `true`. "done row" means the
  terminal `*-done` event.
- dmesg was scanned with the current `NAMEI_EXT_DMESG_FAILURE_PATTERN` from
  `mk/kvm.mk`. That pattern gained `clocksource: Watchdog .*read timed out` and
  `Marking clocksource .* unstable` only in commit `c1004ce`
  (2026-07-27 20:57 PDT). Several earlier runs contain exactly one
  `clocksource: Watchdog remote CPU N read timed out` boot line. Each such run
  passed the gate that was in force when it ran. In this slice, no run has any
  BUG/WARNING/Oops/Call Trace/KASAN/UBSAN/hung-task hit.
- Units of kind (b) are ignored sub-paths of run roots whose analysis is
  tracked. For those, the tracked files in the same root are named as the
  summary, and the text says what the ignored path held.

### Paper/evaluation-cited roots that are entirely ignored (verified against raw)

| Raw root | Tracked claim | Raw verification |
|---|---|---|
| `agent-workspace-matrix/20260722T020120Z-rq1run1`, `…020210Z-rq1run2`, `…020245Z-rq1run3` | `docs/evaluation.md`: 3 terminal KVM runs, 1,170 pass-bearing records with zero failed oracles plus 6 metadata records each, clean dmesg | Confirmed: each run has 1,176 rows, 1,170 pass-bearing rows (all true), and 6 metadata rows (start, provenance, 3 boundary, done). Each run has 94/94 matrix cases, 2/2 manifests, 7/7 policy and 11/11 FUSE counters, and 1,040 samples. Policy counters are identical in all 3 runs. **One nuance:** run2's dmesg has one clocksource-watchdog timeout line at 3.08 s. The result review notes it, but `evaluation.md` says "clean dmesg". It was not a gate pattern on 2026-07-22. |
| `application-file-sharing-source-oracle-rq1/20260730T-xdg-source-formal01` | `docs/evaluation.md`: official xdg-document-portal 1.18.4 and `namei_ext` each passed 15/15 states; 24 hidden ENOENT states; 6 granted states; counters 210/30/3/12/4 per boot; 5 upstream subtests | Confirmed exactly (details in group 12) |
| `application-file-sharing-rq2-official-preflight/20260801T113049Z-3ee783a` | `docs/evaluation.md`: closed without a result; a changing portal thread set invalidated the resource analysis | Confirmed: `run.json` has status=failed, failure=`analysis-unstable-portal-thread-set`. The portal daemon PID 262 had 9 threads before and 10 after. All 4×100 measured samples passed. |

No unit in this slice is cited by `docs/paper/sections/*.tex`. Tracked
`evaluation.md` evidence roots whose ignored sub-paths are in this slice:
`agent-workspace-rq2/…formal-v3`, `agent-workspace-source-task-rq1/…formal01`,
`build-action-sandboxing-rq1/…w3-formal02`, and
`toolchain-environment/…toolchain-formal01`. All four keep their tracked
`analysis/summary.json`, `observations.jsonl`, and review. The ignored parts are
payloads (details below).

---

### 1. Agent workspace dependency preflight, 2026-07-13 (`agent-workspace/`, 9 units)

Producer: `make kvm-agent-workspace-preflight`. At the time, the target lived in
`mk/kvm.mk` and wrote to `results/experiments/agent-workspace/<RUN_ID>`. It is
now in `mk/experiments/agent_workspace.mk`. The first runner attached
`agent_workspace_view.bpf.c` through the real `cgroup/namei_ext` path. It
switched `view/ws` between registered base and upper targets, hid
`deleted.txt`, and checked symlink metadata and lower-FS write placement. Later
iterations added a FUSE runner with the same oracle
(`docs/tmp/2026-07-13-agent-workspace-preflight-implementation.md`). These runs
are dependency evidence only.

| Run | Rows | Pass rows | Fail | Cases | Note |
|---|---:|---:|---:|---:|---|
| 20260713T024001Z-4994edb0 | 21 | 19 | 0 | 19 | first namei_ext-only slice |
| 20260713T024042Z-dc2e2cef | 22 | 20 | 0 | 20 | + view_root_native, selected_root_final_rejected |
| 20260713T025004Z-eb8ab4cd | 37 | 35 | 0 | 35 | + FUSE same-oracle runner |
| review-dryrun (mtime 19:53 PDT 07-12) | 37 | 35 | 0 | 35 | same shape as eb8ab4cd |
| 20260713T030420Z-a954a709 | 43 | 41 | 0 | 41 | + readdir before/after write |
| 20260713T031638Z-46918d26 | 45 | 43 | 0 | 43 | cited "previous passing root" |
| 20260713T032434Z-8cbbac1b | 61 | 59 | 0 | 43 + 16 counters | cited latest passing root |
| 20260713T052750Z-f573767d | 61 | 59 | 0 | 43 + 16 | uncited rerun |
| 20260713T053112Z-880b8b4e | 61 | 59 | 0 | 43 + 16 | uncited rerun |

8cbbac1b policy counters: total 111, lookup 82, readdir 29, select_ws 12, hide
lookup 2, hide readdir 3, pass 94. These match `docs/implementation.md` and the
2026-07-13 implementation doc exactly. 8cbbac1b and f573767d each have one
clocksource-watchdog dmesg line. All runs ended with a done row.

### 2. Agent workspace lifecycle matrix prototypes and repairs, 2026-07-13..15 (`agent-workspace-matrix/`, 7 units)

Producer: `make kvm-agent-workspace-matrix` / `experiment-agent-workspace`
(guest target `__experiment_agent_workspace_matrix`, then in `mk/kvm.mk`, now in
`mk/experiments/agent_workspace.mk`, output dir `agent-workspace-matrix/`). The
matrix runs `namei_ext` and a feature-equivalent FUSE filesystem on the same
oracle, then appends 3 boundary rows. Each root was reviewed as
prototype/supporting evidence only.

| Run | Rows | Fail | namei stat / readdir ns | FUSE stat / readdir ns | Tracked verdict |
|---|---:|---:|---|---|---|
| 77bb2b4d, e2d462d9 | 64 each | 0 | n/a | n/a | prototype, "no pass==false rows" (`docs/implementation.md`) |
| 5be906d9 | 83 | 0 | 927 / 2,786 | 24,089 / 42,230 | step-0002 review: incomplete, inconclusive, supporting |
| 9b4f6dec | 396 | 0 | 97,930 / 141,065 | 158,263 / 201,719 | aggregate timer included sample serialization; fixed in the next run (`2026-07-14-agent-workspace-matrix-rq2-hard-gates.md`) |
| deaf17c0 | 396 | 0 | 1,088 / 3,031 | 23,314 / 40,807 | matches hard-gates doc exactly (300 samples: 100/50/100/50) |
| 7e0cc0e8 | 702 | 0 | 1,065 / 2,966 (no-hook 611 / 2,026) | 22,824 / 39,807 | provenance and no-hook-control repair; kernel `7.1.0-rc7-g9f6695adf237-dirty` |
| a12b8555 | 724 | 0 | 1,032 / 3,044 (no-hook 1,175 / 1,875) | 28,488 / 50,920 | source-lifecycle review: incomplete, inconclusive, supporting |

5be906d9 and 7e0cc0e8 each have one clocksource-watchdog dmesg line. These
latencies are single-boot per-operation means. No tracked doc uses them as
results.

### 3. Agent workspace RQ1 formal matrix, 2026-07-22 (`agent-workspace-matrix/`, 4 units, evaluation-cited)

Same producer, run with `JOBS=1` after the first preflight hit a pahole BTF
segfault (`docs/tmp/build-and-evaluate/step-0004-20260721T175447-0700/step-report.md`).
Kernel `7.1.0-rc7-g6641100ef134`. Tracked summaries:
`docs/evaluation.md` (RQ1 row), the step-0004 `experiment-001/result-review.md`,
and `research/STATE.md`. None of the raw roots are tracked, so the table below
is the surviving raw record.

| Run | Rows | Pass rows | Meta | Fail | Cases | Samples | Metrics | dmesg pattern hits | namei / FUSE macro lifecycle ns |
|---|---:|---:|---:|---:|---:|---:|---:|---|---|
| rq1preflight2 | 1,176 | 1,170 | 6 | 0 | 94 | 1,040 | 16 | 0 | 587,774 / 1,783,399 |
| rq1run1 | 1,176 | 1,170 | 6 | 0 | 94 | 1,040 | 16 | 0 | 555,134 / 3,865,796 |
| rq1run2 | 1,176 | 1,170 | 6 | 0 | 94 | 1,040 | 16 | 1 clocksource line | 675,857 / 2,008,448 |
| rq1run3 | 1,176 | 1,170 | 6 | 0 | 94 | 1,040 | 16 | 0 | 583,673 / 1,225,804 |

All three formal runs record the same counters:

- `namei_ext` policy counters: total 3,484, lookup 2,581, readdir 903,
  select_ws 419, hide lookup 3, hide readdir 53, pass 3,009.
- FUSE counters: getattr 1,013, readdir 54, open 148, create 2, read 48,
  write 2, readlink 2, unlink 1, rename 2, hidden lookup 3, hidden readdir 53.

Other per-run single-shot metrics, run1/run2/run3, in ns:

| Metric | run1 | run2 | run3 |
|---|---:|---:|---:|
| `namei_ext` stat | 727 | 728 | 1,253 |
| `namei_ext` open | 1,051 | 1,067 | 1,982 |
| `namei_ext` exec | 3,916,428 | 5,189,223 | 4,054,400 |
| FUSE stat | 15,827 | 20,337 | 16,205 |
| FUSE open | 16,632 | 22,062 | 17,340 |

The RQ1 review excludes timing.

Comparison: the raw data agree with every count in the review and in
`evaluation.md`: 1,170 + 6, 0 failed, 94/94, 2/2 manifests, 7/7 and 11/11
counters, and identical counters across runs. The only difference is the
"clean dmesg" wording for run2, described above.

### 4. Matrix reruns under the unified result contract, 2026-07-26 (2 units)

`agent-workspace-matrix/20260726T-infra-agent-workspace-v1` (old artifact names)
and `agent-workspace/20260726T-infra-agent-workspace-v2` (canonical
`run.json`/`observations.jsonl`, status completed, kernel `6641100e`) both have
1,176 rows, 1,170 pass rows, 0 fail, 94 cases, 16 metrics, and 3 boundary rows.
`docs/tmp/2026-07-26-unified-experiment-infrastructure-implementation.md`
reports exactly this for v2. It describes v1 only as "the first post-move matrix
run passed but still used the old artifact names". v2 has one
clocksource-watchdog dmesg line.

### 5. Agent workspace RQ2 preflights, `namei_ext` vs libfuse 3.14.0 (`agent-workspace-rq2-preflight/`, 5 units)

Producer: `make kvm-agent-workspace-rq2-preflight`
(`mk/experiments/agent_workspace_rq2.mk`). It runs one paired block, meaning one
`namei_ext` boot and one FUSE boot. Kernel `bdc9a83e`. The ratio below is
FUSE/namei_ext of per-boot p50s, recomputed from raw samples. These are single
pairs and are not estimates.

| Run | Status | Rows | Fail | Lifecycle p50 ns (namei / FUSE) | Ratio | Tracked |
|---|---|---:|---:|---|---:|---|
| rq2-preflight-v1 | failed (`kvm-launch-or-guest-command`) | 615 raw-runner rows, first boot only | 2 | n/a | n/a | `2026-07-27-agent-workspace-rq2-preflight-v1.md`: `base_deleted_preserved` errno 2 because the policy had global parent scope. Matches. |
| rq2-preflight-v2 | failed | `namei_ext` boot 620 rows OK; FUSE raw 616 rows | 2 (FUSE) | n/a | n/a | `…-v2.md`: FUSE `mknod` counter stayed 0 (regular files go through `.create`=22). Matches. |
| rq2-preflight-v3 | completed | 1,236 | 0 | 9,259 / 82,816.5 (20 samples/boot) | 8.94 | uncited |
| control-preflight-v1 | completed | 16,169 | 0 | 5,577 / 61,614.5 (1,000 samples/op) | 11.05 | `2026-07-27-agent-workspace-rq2-control-preflight.md`: 16,169 rows, 16,000 samples, 49+47 oracles. Matches. |
| multi-boot-agent-rq2-preflight-v1 | completed | 16,169 | 0 | 5,508 / 62,960 | 11.43 | `2026-07-28-unified-multi-boot-agent-rq2-preflight.md`: 2,000 lifecycle samples, 16,169 rows. Matches. |

Other control-preflight ratios: open 8.21×, readdir 13.74×, stat 0.754×, access
0.744×, exec 0.98×, lower-FS stat 1.006×.

### 6. Agent workspace RQ2 formal v1 and v2, superseded by the tracked formal-v3 (`agent-workspace-rq2/`, 2 units)

Producer: `make kvm-agent-workspace-rq2`, analysis by
`analysis/agent_workspace/analyze.py`. Both runs use 10 paired independent-boot
blocks (20 KVM boots).

**formal-v1** (completed; source `d488578`; vCPUs not pinned; 20 lifecycle
samples per boot). The root's own analysis exists but is ignored. I recomputed
it from raw: 12,360 rows, 0 fail, 20/20 boots, no dmesg hits.

| Metric (p50) | namei_ext | FUSE | FUSE/namei paired median [95% CI] |
|---|---:|---:|---|
| lifecycle | 6,321.25 ns | 72,814 ns | 10.84× [8.14, 12.89] (paired range 7.09–13.26) |
| stat | 753.75 | 555.75 | 0.73× [0.59, 0.97] |
| open | 1,173.25 | 10,903 | 8.64× [5.49, 9.57] |
| access | 654.75 | 493.5 | 0.74× [0.58, 0.94] |
| readdir | 2,699 | 39,529 | 14.23× [10.24, 14.65] |
| exec | 5.53 ms | 5.74 ms | 1.08× [0.85, 1.17] |

This matches `docs/tmp/2026-07-27-agent-workspace-rq2-formal-v1-review.md`
exactly. The review keeps v1 as supporting evidence only, because the vCPUs were
unpinned, FUSE request accounting omitted truncate/release, and the report
omitted controls.

**formal-v2** has `run.json` status=failed, failure=`launch-order-jsonl-contract`.
`launch-order.jsonl` was written pretty-printed, so it had multiple lines per
object. All 20 boots completed, with 161,690 rows, 0 fail, 20,000 lifecycle
samples, and no dmesg hits. No analysis was accepted
(`docs/tmp/2026-07-27-agent-workspace-rq2-formal-v2-analysis-failure.md`, which
matches). The figures below are my p50 recomputation, for the record only and
not admitted:

- lifecycle: 5,462.8 vs 62,844.8 ns, median paired ratio 11.52× (range
  11.16–12.46)
- open 8.34×, readdir 13.66×, stat 0.765×, access 0.736×, exec 1.08×
- lower-FS stat control 1.002×

These agree in direction and magnitude with formal-v3's 11.32×.

### 7. Agent workspace RQ2 formal-v3, ignored sub-paths (12 units, evaluation-cited root)

Root: `agent-workspace-rq2/20260727T-agent-workspace-rq2-formal-v3`. Its
tracked summaries are `analysis/summary.json`, `analysis/report.md`, the
aggregate `observations.jsonl`, `artifacts.sha256`,
`docs/tmp/2026-07-27-agent-workspace-rq2-formal-v3-result-review.md`,
`docs/evaluation.md`, and `configs/publication/published-formal.json`.

The ignored parts are:

- **`analysis/summary.csv`**: 18 rows of paired per-boot quantile ratios. It is
  derived from the same analysis as the tracked `summary.json`, and the values
  are identical. Key values:
  - lifecycle p50: 5,508.0 vs 62,642.25 ns, 11.318× [11.241, 11.637]
  - lifecycle p95: 10.877× [10.660, 11.041]
  - lifecycle p99: 8.528× [8.181, 9.094]
  - stat 0.759×, open 8.347×, access 0.736×, readdir 13.585×, exec 1.105×
    [0.998, 1.171]

  My independent recomputation of the lifecycle p50 ratio from raw samples also
  gives 11.318. This agrees with `evaluation.md` (5.51 vs 62.64 µs,
  11.32× [11.24, 11.64]).
- **`boots/`** (20 dirs, 500 files, 65.7 MB): per-boot `observations.jsonl`,
  `raw-runner.jsonl`, `dmesg.log`, `boot.json`, `vcpu-affinity.json`,
  `clocksource-*`, `proc-stat-*`, `guest.mk`, launcher logs, and
  `kernel.config`. All 20 `boot.json` files have status completed, 0 rows have
  pass=false, and there are 0 dmesg pattern hits. The per-boot observation row
  counts sum to 161,690, which equals the tracked aggregate
  `observations.jsonl`. The tracked analysis was computed from that aggregate.
- **`artifacts/kernel`**: bzImage, vmlinux.btf, config, vmlinux.notes for
  `7.1.0-rc7-gbdc9a83e3dfb`.
- **`artifacts/runtime`**: both runners, `agent_workspace_view.bpf.o`, and
  `libfuse3.so.3`.
- **`artifacts/source/agentfs-tests`**: 6 upstream AgentFS test scripts.
- **`artifacts/source/archives`**: AgentFS `0a014ebd` and libfuse 3.14.0
  tarballs.

  The tracked `artifacts.sha256` records the SHA-256 of every file in these
  four `artifacts/` paths.
- **`host-proc-{interrupts,stat}-{before,after}.txt`**: host `/proc` snapshots
  taken around the matrix. They are not analyzer inputs.
- **`kernel-status.txt`, `source-status.txt`**: 0 bytes, meaning
  `git status --porcelain` was empty and both trees were clean, as the review
  states.

### 8. Agent workspace RQ3 development: Wrapfs-derived stackable FS vs `namei_ext` (26 units)

Producers are in `mk/experiments/agent_workspace_rq3.mk`:
`kvm-agent-workspace-rq3-module-smoke`, `kvm-agent-workspace-rq3-faults`,
`kvm-agent-workspace-rq3-preflight`, and `experiment-agent-workspace-rq3`. The
regression preflights used `kvm-agent-workspace-preflight`. The tracked formal
result is `agent-workspace-rq3-formal/20260728-rq3-formal-v3` (37/37 paired
oracles, 19 fault cells, 13 kprobe classes). It is outside this slice. All runs
listed here happened on 2026-07-28 between 20:45 and 22:17 PDT, before commit
`1f5d0c9` at 22:18.

**Wrapfs module smoke** (5):

| Run | Result |
|---|---|
| attempt1 | Failed: start row only, no dmesg |
| attempt2 | Failed: start row only; dmesg "Registering wrapfs 0.1" |
| attempt3 | Failed: start row only; dmesg `wrapfs: get_tree failed: -22` with the lower dir under `/tmp` |
| tmpfs-validation1 | Passed 6/6 oracles over a `/dev/shm` tmpfs lower: lookup visible/hidden, readdir hidden, write/rename/unlink through |
| tmpfs-validation2 | Passed 6/6 oracles; `readdir.txt` lists `mount main.txt` |

tmpfs-validation2 is cited in `2026-07-28-wrapfs-rq3-port-implementation.md`,
and the raw data match it.

**Fault-matrix preflights** (2): faults-preflight1 passed 20/20 fault oracles.
faults-preflight2 passed 26/26 fault oracles. Its verifier logs show the
action-4 program rejected ("R0 … should have been in [0, 3]") and the ctx-write
program rejected. faults-preflight2 matches
`2026-07-28-namei-ext-rq3-fault-matrix-implementation.md` ("all declared
preflight cells passed").

**Full preflights** (14; ext4 loop lower in `/dev/shm`; kernel `1e81d479`;
from preflight6 on, `provenance.json` has project_dirty=true):

| Preflight | Status | Rows | Fail | Notes |
|---|---|---:|---:|---|
| 1 | empty | 0 | n/a | empty directory |
| 2 | incomplete | 328 | 0 | no done row; ended after Wrapfs cases, before the fault phase |
| 3 | completed | 356 | 0 | 26 fault oracles |
| 4 | completed | 363 | 0 | 28 fault oracles |
| 5 | failed | none | n/a | only config, uname, lower-fs, and empty mkfs logs |
| 6 | failed | 237 | 39 | policy-parent commands failed errno 2 and cascaded |
| 7 | completed | 1,005 | 0 | 30 fault oracles, 592 lower-object rows, 19 containment, 18 lifecycles; cited in the fault-matrix doc, matches |
| 8, 9 | completed | 1,153 each | 0 | + 148 directory-manifest rows |
| 10, 11 | failed | 288 each | 3 | lower-tree manifest `base_deleted_preserved=false`; `final_tree_manifest` errno 22 |
| 12 | failed | 1,270 | 0 | no done row; 118 semantic rows |
| 13 | failed | 1,227 | 0 | no done row; 75 semantic rows (the final Wrapfs row appears twice) |
| 14 | completed | 1,227 | 0 | 74 semantic rows (37×2), 19 containment, 18 lifecycles |

`2026-07-28-agent-workspace-rq3-oracle-accounting-repair.md` matches the raw
data for 10/11 (policy scope hid the direct `deleted.txt` checks), 12 (strict
harness gate, slurped jq), 13 (duplicate final Wrapfs row), and 14 (37/37, 19
fault cells, 18 lifecycles, zero false). `units.tsv` gives preflight1 one
citation, but that is a substring false positive from preflight10–14.

**RQ3 formal v1 and v2** (uncited; superseded by the tracked v3). Both are
`make experiment-agent-workspace-rq3` runs with 3 boots on an ext4 lower. Their
own `formal-summary.json` says pass with 3/3 completed boots and 11 Wrapfs
kprobes engaged in 3/3 boots. Every boot completed with 0 fail and a done row.
They used the pre-repair contract, with no 37-row semantic oracle and no
containment manifests.

| Run | Rows per boot | Fault oracles | Kprobe lookup / open / read_iter |
|---|---:|---:|---|
| v1 | 356 | 26 | 24 / 18 / 11 |
| v2 | 363 | 28 | 28 / 22 / 15 |

Verifier rejection errnos were 13 (ctx write) and 22 (action 4).

**Regression preflights after RQ3 changes**
(`agent-workspace-preflight/20260728-agent-workspace-regression-rq3-*`; the
existing `namei_ext` + FUSE agent matrix):

| Run | Rows | Pass rows | Fail | Policy total |
|---|---:|---:|---:|---:|
| mode | 1,202 | 1,200 | 0 | 1,338 |
| final | 1,205 | 1,203 | 0 | 1,356 |
| contract | 1,205 | 1,203 | 0 | 1,356 |

The repair doc cites `contract` as passed, which matches.

### 9. Agent workspace released source task RQ1, SWE-Factory-Gym `pallets__click-2622` (27 units)

Producers: `make kvm-agent-workspace-source-task-rq1-preflight` and
`kvm-agent-workspace-source-task-rq1`
(`mk/experiments/agent_workspace_source_task.mk`). Kernel `621aff8d`.

| Preflight | Status | Rows | Fail | Evidence | Tracked doc |
|---|---|---:|---:|---|---|
| 01 | failed | 7 | 2 | physical-base state `pytest_exit=1`, `parser_exit=1` (JUnit parser), before policy attach | attempt-1 doc. Matches. |
| 02 | failed | 17 | 4 | both concurrent states `probe_exit=1`; overlap true | attempt-2 doc and review. Matches. |
| 03 | completed | 31 | 0 | 6 states, 4 visibility, 1 concurrent pair; overlap recomputed from raw = 1,581,848,496 ns | `…preflight-03-review.md`. Matches, GO. |

The formal01 root is tracked, including `analysis/summary.json` and
`report.md`: 3 boots, 18 passing pytest states, 3 overlapping pairs, 12
visibility states. It is cited in `docs/evaluation.md`. Its 24 ignored
sub-paths are payload:

- `artifacts/kernel/bzImage`
- `artifacts/runtime`: runner, bpftool, BPF object
- `artifacts/source/click-source.tar`: 1.06 MB Click source. Commit and patches
  are tracked.
- for each of `boots/repetition-01..03`:
  - `lower/`: the registered `base/` and `completed/` Click trees, 290 files
    and 1.88 MB each. They are inventoried by the tracked
    `lower-before.tsv`/`lower-after.tsv`.
  - six `*-tmp` dirs: pytest `tmp_path` leftovers (symlink and surrogate test
    dirs, one empty file each).

The tracked verdicts come from the tracked per-boot observations, JUnit, and
import JSON, not from these payload files.

### 10. W1 sandboxed application file sharing, early preflights 2026-07-25..27 (`application-file-sharing/`, 9 units)

Producer: `make kvm-application-file-sharing-preflight`. The guest target is
`__experiment_application_file_sharing_preflight`, in
`mk/experiments/application_file_sharing.mk`. It runs the two-application
grant/revoke oracle derived from the portal documentation, in one boot.

| Run | Rows | Fail | Policy counters (lookup/readdir/select/hide) | Notes |
|---|---:|---:|---|---|
| preflight-v1 | 20 | 0 | 89/26/2/8+4 | uncited; clocksource line |
| preflight-v2 | 21 | 0 | 123/30/2/8+4 | uncited; clocksource line |
| preflight-v3 | 21 | 0 | 123/30/2/8+4 | Cited in the 2026-07-25 implementation doc (A hidden→visible→hidden, B hidden). Matches. |
| infra-v1 | 21 | 0 | same | `kernel_commit` empty (guest `git rev-parse` rejected). The doc keeps it as failure evidence. Matches. |
| infra-v2 | 21 | 0 | same | Doc reports 21 records and zero false. Matches. |
| unified-suite-contract-v1 | 21 | 0 | same | uncited; clocksource line |
| unified-suite-contract-v2 | 21 | 0 | same | Doc reports schema `run.v1` and 21 observations. Matches. |
| source-provenance-v2 | n/a | n/a | n/a | aborted: `run.json` status=running, no observations; launcher killed by an external 1 s timeout. The doc excludes it. |
| source-provenance-v2-rerun | 21 | 0 | same | source `0f02d6e`, kernel `8fd1fb52`, both clean; clocksource line. The doc says the dmesg gate passed, which was true under the pattern then in force. |

### 11. W1 RQ1 with the documentation-derived oracle (3 units)

- `application-file-sharing-rq1-preflight/20260729T-w1-rq1-preflight01`:
  completed, 1 boot, 25 rows, 0 fail, 5/5 states, 13 cases. It also includes
  kernel and runtime artifacts. Cited in
  `2026-07-29-application-file-sharing-rq1-formal01-result-review.md`, which
  matches.
- `application-file-sharing-rq1/20260729T1824Z-w1-formal01/artifacts/{kernel/bzImage,runtime}`:
  payload, namely the kernel image, the runner, `application_file_sharing.bpf.o`,
  and bpftool. The tracked `analysis/summary.json` records 3 boots and 15
  states (3 visible, 12 hidden), 3 lower objects, and 6 cgroup removals.

### 12. W1 source-oracle RQ1 against official xdg-document-portal 1.18.4 (2 units, evaluation-cited)

Producers: `make kvm-application-file-sharing-source-oracle-preflight` and
`kvm-application-file-sharing-source-oracle-rq1`
(`mk/experiments/application_file_sharing.mk`). Each boot runs the official
portal arm first, then requires an empty BPF/FUSE inventory, then runs the
`namei_ext` arm.

- **xdg-source-preflight01**: completed, 1 boot, 45 rows, 0 fail. Official
  5/5 states and `namei_ext` 5/5 states. Matches
  `2026-07-30-application-file-sharing-source-oracle-rq1-preflight.md`.
- **xdg-source-formal01**: entirely ignored, so this is the only surviving
  record.
  - Run identity: `run.json` completed, 2026-07-30 20:48:15–20:48:39Z. Source
    `6836ea6`, kernel `621aff8d`, both clean. Portal `xdg-desktop-portal 1.18.4`,
    commit `11c8a96b`.
  - 135 rows (45 per boot × 3), 0 fail, no dmesg hits.
  - Official portal: 15/15 states passed. `namei_ext`: 15/15 states passed.
    The five states, per boot, are A before grant, B without grant, A after
    grant, B during A's grant, and A after revoke.
  - Hidden states: 24 in total. Each returned ENOENT for the document stat,
    payload stat, and payload read; opendir/readdir/closedir succeeded, and the
    document was not listed.
  - Granted states: 6 in total. Each listed the document and read the full
    27-byte payload.
  - Object identity: in the `namei_ext` granted states, the logical device/inode
    equals the lower one (document 49/17, payload 50/477).
  - Lower objects: metadata was unchanged in 3+3 checks.
  - Policy counters, the same in every boot: lookup 210, readdir 30, select 3,
    hide lookup 12, hide readdir 4.
  - Upstream `test-doc-portal`: 5/5 ok, with 0 failures, skips, or timeouts.
  - Portal processes: `xdg-document-portal` exited 0; `xdg-permission-store`
    stopped by SIGTERM.
  - `analysis/summary.json`: boots 3, source_states 15, namei_ext_states 15,
    lower preservation 3+3.

  The raw data agree with every number in `docs/evaluation.md` (lines 188 and
  200–204) and in `2026-07-30-…-formal01-result-review.md`.

### 13. W1 RQ2 official-portal timing preflights, closed without a result (3 units)

Producer: `make kvm-application-file-sharing-rq2-official-preflight`. Each run
has one pair of boots in alternating order. Each arm does 10 warmup
transactions, 100 measured transactions, and 100 direct-ext4 control
transactions. Tracked summaries:
`2026-08-01-rq2-official-xdg-portal-implementation-review.md`,
`2026-08-01-parent-device-encoding-fix.md`,
`2026-08-01-rq2-official-xdg-portal-preflight-review.md` (verdict NO-GO), and
`docs/evaluation.md`.

- **b3eb222**: failed (`kvm-launch-or-guest-command`). The observation stream is
  empty. The doc says `install -d /mnt/namei-ext-rq2` failed in the virtme
  root, which matches.
- **d8c1654**: failed.
  - Portal arm: completed; 100/100 measured and 100/100 direct samples passed;
    FUSE engagement delta 1,326.
  - `namei_ext` arm: 12 failing rows. Three hidden states were visible,
    `rq2_namei_measurement` failed with errno 2, and `rq2_namei_post_revoke`
    failed with errno 22.
  - The doc attributes this to zero SELECT/HIDE caused by the parent `st_dev`
    encoding bug, which matches.
- **3ee783a**: evaluation-cited and entirely ignored.
  - `run.json`: failed, failure `analysis-unstable-portal-thread-set`. Kernel
    `b07117a3`, source `3ee783a` clean, portal source `1d20fad`.
  - Rows: 646 aggregate, 0 pass=false. The four measured streams each have
    samples 0–99, all passing.
  - Portal daemon PID 262 had 9 threads before and 10 after. The client
    thread counts were stable.
  - `namei_ext` BPF counters: select 33→333, visible_readdir 11→111.
  - FUSE engagement delta: 1,400.

  These match the preflight review.
  - Descriptive p50 transaction totals, recorded here only and **not
    admitted**:

    | Stream | p50 total |
    |---|---:|
    | portal policy-view | 224,587.5 ns |
    | `namei_ext` policy-view | 3,063 ns |
    | direct ext4 (portal boot) | 2,165.5 ns |
    | direct ext4 (`namei_ext` boot) | 2,132.5 ns |

    The review forbids reporting any latency or ratio from this root.

### 14. W3 build-action sandboxing, early preflights 2026-07-26 (`build-action-sandboxing/`, 5 units)

Producer: `make kvm-build-action-sandboxing-preflight`. The guest target is
`__experiment_build_action_sandboxing_preflight`, in
`mk/experiments/build_action_sandboxing.mk`. It runs two concurrent Bazel
genrule actions in separate cgroups, each with its own declared-input view.

| Run | Status | Rows | Fail | Policy counters (lookup/readdir/select/hide) | Evidence vs tracked |
|---|---|---:|---:|---|---|
| build-action-dry-run | incomplete | 7 | 0 | n/a | Bazel 8.7.0 stderr: "Both --enable_bzlmod and --enable_workspace are disabled". Uncited. |
| preflight-v1 | failed | 22 | 9 | 59,594/8,988/0/0 | Bazel 8.7 needed external `rules_cc` offline. Matches the doc. |
| preflight-v2 | failed | 22 | 5 | 58,429/8,388/4/2+2 | Runner used Bazel's relative output path. Matches. |
| preflight-v3 | completed | 23 | 0 | 57,737/8,082/4/2+2 | Matches `2026-07-26-build-action-sandboxing-preflight-implementation.md` exactly. |
| infra-build-action-v1 | completed | 23 | 0 | 57,164/8,042/4/2+2 | Matches the unified-infrastructure doc exactly. |

v3 and infra-v1 each have one clocksource-watchdog dmesg line.

### 15. W3 build-action sandboxing RQ1 with Bazel 6.5.0 (7 units)

Producers: `make kvm-build-action-sandboxing-preflight` and
`kvm-build-action-sandboxing-rq1`. Kernel `621aff8d`.

- **w3-preflight01**: failed, 30 rows, 8 failing. The Bazel children never
  reached the barrier because the executable path was relative after `chdir`.
- **w3-preflight02**: completed, 30 rows, 0 fail.
- **w3-preflight03**: completed, 32 rows, 0 fail, 18 cases including cgroup
  removal.

All three match `2026-07-29-build-action-sandboxing-rq1-formal-implementation.md`.

**w3-formal01** (entirely ignored): `run.json` completed. 3 boots, 90 rows,
0 fail. Its summary records 6 Bazel actions, 6 action views, 12 lower objects,
and verdict "supported". However,
`2026-07-29-build-action-sandboxing-rq1-formal01-result-review.md` judged it
**invalid**, because the per-cgroup `rmdir` results were not emitted as raw
rows. The raw data match the review's counts (16 cases, 2 views, 4 lower
objects, and 7 counters per boot).

**w3-formal02** is the tracked evaluation root. Its ignored parts are:

- `artifacts/kernel`: bzImage and config.
- `artifacts/runtime`: Bazel 6.5.0 binary (54.8 MB), bpftool,
  `build_action_sandboxing.bpf.o`, runner.
- `artifacts/manifest.json` (792 B): lists the kernel `621aff8d` image and
  config (release `7.1.0-rc7-g621aff8d1bb5`), the four runtime files, the
  Bazel 6.5.0 release URL, and the expected action A, action B, and private
  files.

The tracked `analysis/summary.json` records 3 boots, 6 actions, 6 views, 12
lower objects, and 6 cgroup removals.

### 16. W3 build-action RQ2 preflights against official sandboxfs 0.2.0 (4 units)

Producer: `make kvm-build-action-rq2-preflight` (`mk/experiments/build_action_rq2.mk`).

- **v1** (kernel `bdc9a83e`): failed. The capacity probe passed (4,096 entries
  inserted and removed). The run then failed at the external cgroup-attach
  inventory because system bpftool 7.7.0 did not know
  `BPF_CGROUP_NAMEI_EXT`.
- **v2**: failed. It had one sample, which failed with errno EIO (5), and no
  Bazel action evidence.
- **v3**: failed on the sample oracle. Per the doc, Bazel A and B ran in 4.232
  and 4.281 s, and the cause was a marker-file newline mismatch. This used up
  the 3 permitted attempts.

All three match the attempt-1/2/3 docs and `docs/evaluation.md`. None reached
the sandboxfs boot.

**w3-rq2-reentry-preflight01** (2026-08-08): `run.json` completed, but
`2026-08-07-build-action-rq2-reentry-preflight-result.md` says it is not
admitted. The reason is that `unknown.txt` readdir hiding was never actually
checked.

- Setup: kernel `b07117a3`, source `6700791` clean. One `namei_ext` boot and
  one sandboxfs boot (libfuse 2.9.9), at a scale of 64 files with 1 sample.
- 14 rows, 0 fail. Each output was 2,007 bytes, exact.
- `action_ns`: 538,326,752 (`namei_ext`) vs 555,108,703 (sandboxfs). The
  ratio is about 1.031, which the doc explicitly says is not evidence.
- Policy counters: total 147,726, lookup 136,645, readdir 11,081, select 4.
- sandboxfs: 899 voluntary context switches.

All of these match the doc.

### 17. Legacy W4 build-cache smoke runs, ccache over Redis and nginx (`build-cache/`, 3 units)

Producer: the removed target `make experiment-env-cache`. Entrypoints were split
in `cc8415d`; the target is now `make legacy-build-cache` →
`kvm-build-cache-matrix` in `mk/experiments/legacy_build_cache.mk`. The guest
target is `__experiment_build_cache_matrix` with `BUILD_CACHE_SAMPLES=1`. The
20-sample results are the tracked roots `20260723T-build-cache-release-v1` and
`…-state-release-v1`.

All three smoke runs:

- completed with a matrix summary pass, a done row, and 0 failing rows in any
  per-target JSONL;
- produced 20/20 output matches for every system;
- passed 207 cache-content rows;
- have one clocksource-watchdog line in each dmesg copy.

| Run | namei_ext compile (20 jobs) | native ccache | FUSE redirect | FUSE/namei | native/namei | Extra rows |
|---|---:|---:|---:|---:|---:|---|
| build-cache-smoke-v1 | 7.33 s | 7.38 s | 13.90 s | 1.897 | 1.007 | none |
| build-cache-state-smoke-v1 | 6.50 s | 6.85 s | 12.95 s | 1.99 | 1.05 | cache-state row: 16 objects, 40 trace entries; setup writes 97 (`namei_ext`) vs 16 (FUSE); update writes 1 vs 16 |
| bfs-integrated-smoke-v1 | 6.39 s | 7.19 s | 13.57 s | 2.12 | 1.12 | compile epoch switch: `namei_ext` 7.19 s then 6.36 s, FUSE 13.58 s then 12.93 s; `miss_stale_corrupt_compile_cells_closed=false` |

Tracked docs:

- `2026-07-23-build-cache-lpc-result-report.md` gives only the smoke command.
- `2026-07-23-build-cache-state-row-implementation.md` says both KVM runs
  passed.
- `2026-07-24-build-cache-real-compile-epoch-implementation.md` reports a pass
  with zero failed rows at smoke scale only.

These agree with the raw data. Single-sample timings are not results.

### 18. Toolchain environment RQ1, CPython 3.10/3.12 virtualenvs (7 units)

Producers: `make kvm-toolchain-environment-preflight` and
`kvm-toolchain-environment` (`mk/experiments/toolchain_environment.mk`).
Kernel `621aff8d`.

- **toolchain01 preflight** (96.5 MB): completed, 1 boot, 22 rows, 0 fail.
  - 6 states and 1 paired start; both children exited 0 with empty stderr.
  - Permission control returned EACCES; the withdrawn control returned ENOENT.
  - Counters: lookup 159,162, select 6,739; target a-310 3,380, a-312 1,659,
    b-312 1,700.
  - Summary verdict: supported.
  - Most of its size is the 75 MB `lower/` venv payload plus kernel and runtime
    artifacts.
  - Cited in `2026-07-29-toolchain-environment-implementation.md`, which
    matches.
- **toolchain-formal01** is the tracked evaluation root. Its ignored parts are:
  - `artifacts/kernel`
  - `artifacts/runtime`: runner, `toolchain_environment.bpf.o`, bpftool
  - `artifacts/manifest.json` (705 B): kernel `621aff8d`, the three runtime
    files, `probe.py`, `/usr/bin/python3.10` and `/usr/bin/python3.12`, version
    files, and `packages.txt`
  - `boots/repetition-01..03/lower`: the registered `python310/` and
    `python312/` virtualenv trees, 2,896 files and 72.5 MB each, inventoried by
    the tracked 3,270-row `lower-before.tsv`/`lower-after.tsv`.

  The tracked `analysis/summary.json` and
  `2026-07-29-toolchain-environment-formal-result-review.md` record 3 boots,
  18/18 states, 3 pairs, 3 EACCES and 3 ENOENT controls, and 159,162 lookup and
  6,739 SELECT per boot. The per-boot counters are identical to the
  preflight's.

### Doc vs raw mismatches

1. `docs/evaluation.md:215` says the three RQ1 formal matrix runs had "clean
   dmesg". In the raw data, `agent-workspace-matrix/20260722T020210Z-rq1run2`
   has one `clocksource: Watchdog remote CPU 1 read timed out` line at 3.08 s.
   rq1run1 and rq1run3 have no hits. The step-0004 result review
   (`…/experiment-001/result-review.md:123`) reports this line correctly. The
   counts in line 215 are all exact.
2. The following docs make dmesg-clean statements that are correct under the
   gate pattern in force when each run happened. Each of these runs does contain
   one clocksource-watchdog line that the current `mk/kvm.mk` pattern (from
   `c1004ce`) would flag:
   - `docs/tmp/2026-07-24-build-cache-real-compile-epoch-implementation.md:246`
     ("clean dmesg gate") for `build-cache/20260724T-build-cache-bfs-integrated-smoke-v1`
   - `docs/tmp/2026-07-27-unified-source-provenance-infrastructure.md:92-93`
     for `application-file-sharing/20260727T-source-provenance-v2-rerun`
   - `docs/tmp/2026-07-26-build-action-sandboxing-preflight-implementation.md:81`
     for `build-action-sandboxing/20260726T-build-action-sandboxing-preflight-v3`

   None of these is a numeric mismatch.
3. Status fields that a later review overrides:
   - `build-action-sandboxing-rq1/20260729T175251Z-w3-formal01/analysis/summary.json`
     says `"verdict": "supported"`, but its result review rates the run invalid.
   - The reentry preflight's `run.json` says `completed`, but its result doc
     says it is not admitted.
   - The 3ee783a failure label was set manually, per its preflight review.

   The raw data do not contradict the reviews; the reviews override the
   mechanical status.
4. No numeric mismatch was found in any other doc checked:
   - the RQ1, RQ2 v1/v2/v3, RQ3 preflight and repair, source-task, W1, W3, and
     toolchain reviews;
   - the implementation records;
   - `docs/implementation.md`.

### Keep-list

`p6-experiments-a-keep.tsv` lists 22 small aggregate files, 1.27 MB in total.
They are the only remaining source of numbers stated in `docs/evaluation.md`,
`research/STATE.md`, or docs/tmp result reviews:

- the three rq1run JSONL files;
- for xdg-source-formal01: `observations.jsonl`, `analysis/summary.json`,
  `run.json`, and `artifacts/source/source-metadata.json`;
- for 3ee783a: `observations.jsonl` and `run.json`;
- RQ2 formal-v1's `analysis/summary.json`;
- W3 formal01's `observations.jsonl` and `analysis/summary.json`;
- the remaining per-run aggregates that individual reviews cite.

The ignored `agent-workspace-rq2/…formal-v3/analysis/summary.csv` is excluded
because the tracked `summary.json` holds identical numbers. Some cited numbers
live only in files over 1 MB, so they could not be kept:

- RQ2 control and multi-boot preflight `observations.jsonl` (3.4 MB each)
- formal-v1 `observations.jsonl` (2.5 MB)
- formal-v2 `observations.jsonl` (33.8 MB)

Their key counts and ratios are recorded in this section and in the CSV.

### Notable findings for the coordinator

1. The agent-workspace RQ1 formal counts in `docs/evaluation.md` are exactly
   right. Its "clean dmesg" phrase is slightly imprecise for rq1run2, which has
   one clocksource-watchdog timeout line. The result review already notes it,
   and it was not a gate pattern on 2026-07-22.
2. The three ignored, evaluation-cited roots (RQ1 matrix runs,
   xdg-source-formal01, and the official RQ2 preflight 3ee783a) are fully
   summarized above. All tracked numbers were verified against raw data.
3. Several superseded runs are uncited and survive only here: agent-workspace
   RQ2 formal-v1 and formal-v2, RQ3 formal-v1 and v2, and W3 formal01 (which
   was reviewed invalid). formal-v2's recomputed lifecycle ratio, 11.52×, is
   consistent with the admitted 11.32× but is not admitted.
4. For every ignored sub-path of a tracked evaluation root (RQ2 formal-v3,
   source-task formal01, W1 formal01, W3 formal02, toolchain formal01), the
   tracked analysis came from tracked observations and is unaffected by
   deleting the payload. The SHA-256 of the RQ2 formal-v3 artifacts are kept in
   the tracked `artifacts.sha256`.
