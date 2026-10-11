# Archive of the untracked raw results deleted on 2026-10-11

## Why

The lab host's work disk reached about 90% on 2026-10-10 and Kubernetes evicted
Pods. Under `results/`, git tracked about 166 MB; about 65 GB more was ignored
by `.gitignore` and existed only on lab. The operator asked: "数据分析一下删掉,
不需要移动" (analyze the data, then delete it; do not move or copy it).

## What was deleted

Every path that `git status --ignored -- results` listed (142 entries, 878
run units), on 2026-10-11:

| Tree | Bytes before deletion (whole tree, tracked files included) |
| --- | ---: |
| `results/phase1/` | 28,439,519,205 |
| `results/experiments/` | 21,501,513,730 |
| `results/workloads/` | 14,854,659,200 |
| `results/reproduction/` | 103,851,060 |
| `results/eval-osdi/` | 36,661,519 |
| `results/research-probes/` | 2,896,690 |

Tracked files under `results/` were not touched. The raw data is not kept
anywhere else; it cannot be recovered except for the files listed below.

## What was kept

- 339 small raw files (12,489,254 bytes in total, none over 700 KB) that are the
  only aggregate source of a number or provenance fact stated in the paper, in
  `docs/evaluation.md`, in `research/STATE.md`, in a `docs/tmp` record or in a
  `workloads/legacy/*/evidence.md`. They stay at their original paths and are
  now tracked. `results/archive-index/2026-10-11/keep-list.tsv` gives each path,
  its size and the document lines that depend on it. For example,
  `results/experiments/semantic-continuation/20260801T190000Z-semantic-formal-v2/analysis/summary.json`
  is the source of the paper's "Selected-object semantic preservation" row.
- `results/archive-index/2026-10-11/inventory.csv`: one row per run unit (878):
  path, group, producer, configuration, status, outcome, key metrics, tracked
  summary and consistency with tracked documents.
- `results/archive-index/2026-10-11/units-exact.tsv`: size, file count, date
  range and the tracked documents that cite each unit, matched on the exact run
  id. The "tracked_summary" column of the inventory came from a prefix search
  in some slices and can over-count; use this file for citations.
- Seven Markdown analyses, one per slice, in `docs/tmp/`:
  - `2026-10-11-results-archive-p1-phase1-early.md` (101 units)
  - `2026-10-11-results-archive-p2-phase1-mid.md` (90 units)
  - `2026-10-11-results-archive-p3-phase1-late.md` (83 units)
  - `2026-10-11-results-archive-p4-workloads.md` (134 units)
  - `2026-10-11-results-archive-p5-evalosdi-repro.md` (190 units)
  - `2026-10-11-results-archive-p6-experiments-a.md` (137 units)
  - `2026-10-11-results-archive-p7-experiments-b.md` (143 units)
  Each lists its run groups, the results that matter, the failed, aborted and
  empty units, a keep list, and the places where a tracked document disagrees
  with the raw data. Where a raw file was over 1 MB but its numbers are cited,
  the numbers are quoted in the analysis instead.

## Method

Seven independent read-only analyses each covered one slice and read manifests,
summaries, result JSON/JSONL, logs and the producing scripts and documents, then
compared every number a tracked document states with the raw rows. The slices
together cover all 878 units with no gap or overlap (checked against the unit
list before deletion).

## Tracked documents that disagree with the raw data

These documents were not edited; the disagreement is recorded here.

- `docs/evaluation.md:304` attributes 2.18x / 0.945x to
  `20260723T-build-cache-release-v1`, which gives 1.758x / 1.034x. The numbers,
  also used at `docs/paper/sections/05-evaluation.tex:296`, come from
  `20260723T-build-cache-state-release-v1`. Both have tracked JSONL copies under
  `results/experiments/build-cache/`.
- `docs/evaluation.md:215` says "clean dmesg"; rq1run2 has one clocksource
  watchdog line (not a gate failure at the time; the result review notes it).
- `docs/evaluation.md:367` names kernel `bdc9a83e3` for the RCU stage-2 runs,
  which booted `83d52c2168e2-dirty`; the stage-1 runs booted
  `8fd1fb52fa8d-dirty` where the design document says `83d52c216`; the
  `parent-fast-path-8fd1fb52f-*` runs booted a dirty `c7af99f67609`; the
  bench-variant `metadata.json` records a kernel repository head that differs
  from the booted kernel; several FxMark diagnostic preflights booted dirty
  kernels that differ from their recorded commit.
- `docs/tmp/2026-06-17-w4-cache-transition-counterfactual.md` describes
  `20260617T-w4-cache-transition-hardgate-release-v1` as a 20-sample run; a later
  2-sample run under the same id overwrote it. The 20-sample numbers survive in
  `20260617T-w4-cache-transition-release-v1` and
  `20260629T-w4-cache-transition-c8-release-v1`.
- The Spindle formal02 failure record gives the median as 98.129 ms; the raw
  rows give 96.912 ms. The Spindle RQ2 preflight attempt-1 record claims FUSE
  launches the raw data does not contain. `docs/evaluation.md` and
  `research/STATE.md` omit the Spindle RQ2 runs.
- The affinity-abort record says QMP was reachable; QEMU's stderr shows it could
  not create the QMP socket.
- `docs/tmp/2026-07-28-build-action-rq2-infrastructure-implementation.md:69-74`
  says the sandboxfs archive and binary SHA-256 are recorded under
  `results/workloads/provenance/build/`; the raw `build.json`, rewritten on
  2026-08-08 after commit `6700791`, contains neither.
- `docs/tmp/2026-06-15-w1-release-binary-replay-gap-analysis.md:71-72` quotes
  hit rates without a run id; they match `20260614T-workloads-git-ceiling`, not
  `20260615T-parent-key-poc`.
- Undocumented failures: three ccache-bulk cache-epoch runs failed with ENOSYS
  during setup, and the W4 parent `rule` and `wildcard` PoCs failed 4/4; only the
  `debug` PoC failure is described in tracked documents.

Every other number that a tracked document states and that these analyses
checked matches the raw data.

## Paths now dangling

Tracked documents that cite a deleted raw path now point to nothing, unless the
path is in the keep list. `units-exact.tsv` lists, for each unit, the documents
that cite it.
