# RQ2 FxMark Formal-v3 Result Review

## Scope

This review covers the completed clean-provenance run:

`results/experiments/fxmark-rq2/20260728T-rq2-rcu-target-formal-v3/`

It applies the unchanged protocol in
`docs/tmp/2026-07-26-rq2-fxmark-experiment-plan.md`. The matrix measures
cache-hot `stat()` path resolution using the pinned FxMark source. It does not
measure `open`, `readdir`, cache-cold behavior, data-path throughput, or tail
latency.

## Run Identity And Completion

- Repository commit:
  `41d10aadc583db01229aa4b53962ddb4e20f4ae3`
- Patched kernel:
  `bdc9a83e3dfbef8ff2017f9188c7c86025962183`,
  release `7.1.0-rc7-gbdc9a83e3dfb`
- Stock kernel:
  `062871f1371b2e02a272ff5279c6479aff0a37ef`,
  release `7.1.0-rc7`
- Source and kernel trees at run start: clean
- Matrix: 10 five-condition Latin-square blocks, 50 fresh KVM boots
- Cells: three FxMark tests, 1/2/4 workers, five conditions, 30 seconds each
- Completed observations: 450/450 unique cells, all `pass=true`
- Analysis: paired per-block ratios and 10,000 fixed-seed bootstrap resamples

Expected and observed boot and cell tuples are identical. All stock and
patched boots use one consistent commit, release, build ID, BTF hash, notes
hash, and matching kernel configuration. All 50 boots retained TSC before and
after measurement. No boot recorded the previous run's clocksource watchdog
failure or a declared dmesg failure signature.

All cells passed process status, duration, positive work, exact cgroup
membership, and tree-cardinality checks. All 90 `SELECT` cells recorded a
stable BPF program ID and depended on the selected logical path. All FUSE cells
recorded the FUSE superblock identity, setup requests, and nonnegative
measured-phase request counts.

## Predeclared Verdict

The overall verdict is **inconclusive or mixed** because the two predeclared
gates have different outcomes.

### Patched-Unattached Fast Path

The positive gate required every cell to have median
`unattached / stock >= 0.98` and 95% confidence-interval lower bound at least
0.97.

| Test | Workers | Unattached / stock, median [95% CI] | Gate |
| --- | ---: | ---: | --- |
| MRPL | 1 | 0.982 [0.978, 1.005] | pass |
| MRPL | 2 | 0.983 [0.966, 0.997] | inconclusive |
| MRPL | 4 | 0.981 [0.958, 1.012] | inconclusive |
| MRPM | 1 | 1.000 [0.987, 1.005] | pass |
| MRPM | 2 | 1.003 [0.982, 1.009] | pass |
| MRPM | 4 | 1.003 [0.990, 1.009] | pass |
| MRPH | 1 | 1.010 [0.985, 1.015] | pass |
| MRPH | 2 | 1.013 [1.000, 1.023] | pass |
| MRPH | 4 | 1.013 [1.006, 1.020] | pass |

All medians remain within the predeclared 2% margin, but two MRPL interval
lower bounds miss 0.97. Their intervals also cross the positive boundary, so
the fast path is not contradicted. It remains inconclusive under the
predeclared rule.

### SELECT Versus Optimized FUSE

The `SELECT / FUSE` gate passes in all nine cells:

| Test | Workers | SELECT / FUSE, median [95% CI] |
| --- | ---: | ---: |
| MRPL | 1 | 1.084 [1.040, 1.099] |
| MRPL | 2 | 1.075 [1.064, 1.102] |
| MRPL | 4 | 1.088 [1.049, 1.115] |
| MRPM | 1 | 1.068 [1.051, 1.079] |
| MRPM | 2 | 1.064 [1.048, 1.072] |
| MRPM | 4 | 1.058 [1.035, 1.075] |
| MRPH | 1 | 1.058 [1.039, 1.081] |
| MRPH | 2 | 1.052 [1.034, 1.070] |
| MRPH | 4 | 1.066 [1.049, 1.077] |

The median throughput advantage is 5.2%--8.8%, and every cell's paired
bootstrap interval is wholly above one. `SELECT` exceeds FUSE in 89/90
individual paired observations; block 8 MRPL-4 is the single exception at
0.9976. The predeclared gate concerns the per-cell median confidence interval,
not unanimous individual pairs, and is supported.

The baseline is libfuse 2.9.9's high-level API, multithreaded, with
`kernel_cache`, `default_permissions`, and one-hour entry, attribute, and
negative-cache timeouts. Its measured phase has only 0--19 daemon requests per
cell. The result therefore does not depend on forcing one userspace round trip
per `stat()`, but it remains scoped to this committed FUSE implementation.

## Active Policy Cost

The mechanism decomposition must compare adjacent conditions:

- `PASS / unattached` medians are 0.901--0.934: attached dispatch and BPF
  execution cost 6.6%--9.9% throughput.
- `SELECT / PASS` medians are 0.981--0.999: target selection adds
  0.1%--1.9% median cost beyond `PASS`.
- Complete `SELECT / unattached` medians are 0.895--0.931.

An attached policy is therefore not free or negligible. Most active-path cost
in this matrix is policy dispatch and BPF execution; same-filesystem selected
target resolution adds relatively little beyond `PASS`.

## Independent Review

An independent reviewer recomputed every paired median and bootstrap interval
from raw JSONL with maximum absolute difference zero from `summary.json`. The
review found no P0 validity defect and judged the result publication-usable
OSDI/EuroSys-level RQ2 mechanism evidence.

One artifact-quality defect remains: `boots/block-08-fuse/boot.json` has an
empty `completed_at` value. Its nine cells, status, kernel identity, dmesg,
clocksource, and all numerical inputs are complete, so this does not invalidate
the run. Future finalization must require every terminal boot timestamp to be
a nonempty string.

The QEMU vCPU host threads were not positively pinned as in the Agent
Workspace formal matrix. The Latin-square design remains valid, but host
scheduling variance may explain the wider MRPL intervals.

## Paper Decision

Admit formal-v3 as the primary cache-hot FxMark RQ2 result:

> Across nine FxMark test/worker cells, same-filesystem `SELECT` retained
> 5.2%--8.8% more median throughput than the committed cache-coherent libfuse
> 2.9.9 view, with every paired bootstrap interval above one. Attaching `PASS`
> cost 6.6%--9.9% throughput relative to the patched-unattached kernel, while
> `SELECT` added 0.1%--1.9% beyond `PASS`.

Do not claim zero or negligible unattached cost, an overall supported
composite hypothesis, universal superiority to FUSE, unanimous paired wins,
near-native performance, or results for operations outside this cache-hot
`stat()` matrix.

Do not rerun the complete 450-cell matrix. The exact next experiment is an
independent confirmatory replication restricted to stock and
patched-unattached MRPL at 1/2/4 workers, with 20 paired fresh-boot blocks,
alternating condition order, positive QMP host-vCPU pinning, and the unchanged
`median >= 0.98` and `CI low >= 0.97` gate. Formal-v3 data must not be pooled
into that replication.
