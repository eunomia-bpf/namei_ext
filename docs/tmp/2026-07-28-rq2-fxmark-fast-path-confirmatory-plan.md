# Experiment Plan: RQ2 FxMark Fast-Path Confirmatory Replication

## Research Question

- Paper RQ: What is the cost of putting programmable policy on the VFS
  name-resolution path compared with a feature-equivalent FUSE policy
  implementation?
- Exact uncertainty tested here: whether the two inconclusive MRPL
  patched-unattached cells in formal-v3 reflect host scheduling variance or a
  reproducible common-path throughput cost.
- Why this matters: formal-v3 decisively answers the `SELECT` versus cached
  FUSE comparison, but its composite verdict remains mixed until the
  maintainer-critical unused fast path has confirmatory evidence.

## Admission And Independence

- Planned role: decisive confirmatory evidence for the unused-fast-path part
  of RQ2.
- Source result motivating replication:
  `results/experiments/fxmark-rq2/20260728T-rq2-rcu-target-formal-v3/`.
- Formal-v3 remains frozen and publication-usable. This replication uses a
  new result root and must not pool, average, or replace formal-v3 samples.
- The original threshold is unchanged. The experiment does not weaken the
  hypothesis in response to the mixed result.
- A repeated 450-cell matrix has lower decision value: the `SELECT`/FUSE gate
  is already supported, while only stock versus patched-unattached MRPL
  remains uncertain.

## Expected And Alternative Outcomes

- Expected: host-vCPU pinning reduces paired-boot variance and all three MRPL
  worker cells satisfy the original fast-path threshold.
- Competing explanation: the patch adds a repeatable common-path cost or MRPL
  remains variable enough that the strict confidence bound cannot be met.
- A positive result closes the fast-path confirmatory gate.
- A confidence interval crossing the threshold remains inconclusive.
- An interval wholly below the practical boundary is contradictory evidence
  and requires mechanism diagnosis rather than a weaker claim.

## Reused Published Assets

- FxMark commit:
  `3f29552ce7ba6be24c4172e6e2c2c1f603209953`.
- Benchmark source, correctness patch, tmpfs setup, worker affinity,
  process/tree/cgroup oracles, kernel pair, and 30-second measured duration are
  unchanged from the formal-v3 protocol.
- The patched kernel remains
  `bdc9a83e3dfbef8ff2017f9188c7c86025962183`; matched stock remains
  `062871f1371b2e02a272ff5279c6479aff0a37ef`.

## Comparison

- Proposed/control condition: patched kernel with no policy attached.
- Null baseline: matched stock kernel.
- Both conditions use the same FxMark binary, 1-GiB tmpfs, guest configuration,
  operation order, path topology, and four-vCPU VM.
- No BPF program is loaded or attached in either condition.
- Conditions alternate by paired block: stock first in odd blocks,
  patched-unattached first in even blocks.
- Four QEMU vCPU threads are pinned one-to-one to host CPUs 4--7. The guest
  workload waits until the host QMP verifier has atomically written a positive
  singleton-affinity record.
- Host CPUs 4--7 must be online, use the performance governor, share one
  maximum-frequency setting, and run with turbo disabled.

## Workload And Metrics

- Workload: source-pinned FxMark `MRPL` at 1, 2, and 4 workers.
- Primary metric: paired per-block `unattached / stock` throughput ratio for
  each worker count.
- Secondary metrics: raw works/second, boot/order diagnostics, clocksource,
  kernel identity, QMP vCPU mapping, and host frequency policy.
- Correctness: process exit zero, measured duration within the frozen bounds,
  positive work, exact worker-specific tree cardinality, exact cgroup
  membership, empty and unchanged direct pre/post BPF program and cgroup
  attachment inventories, empty and unchanged FUSE mount and `/dev/fuse`
  open-file inventories, stable TSC, and clean dmesg.

## Statistical Protocol

- 30 independent paired blocks, 60 fresh KVM boots, 180 measured cells.
- Each boot runs MRPL with 1, 2, and 4 workers for 30 seconds per cell.
- Report the median paired ratio and a 95% nonparametric bootstrap interval
  over 30 ratios using 10,000 fixed-seed resamples.
- Analysis seed: `20260728`.
- Positive iff every worker cell has ratio median at least 0.98 and confidence
  interval lower bound at least 0.97.
- Contradicted for a worker cell iff its confidence interval upper bound is
  below 0.98.
- Otherwise the result is inconclusive.

### Prospective Sensitivity

The block count is frozen before preflight and must not be extended after
observing formal results. The design calculation uses only the ten paired
MRPL ratio vectors from formal-v3; those observations are not pooled into this
replication. For each worker count, the calculation centers the formal-v3
log-ratio residuals at a true ratio of 0.99, resamples complete three-worker
block vectors to preserve their cross-worker dependence, and applies the
planned median and percentile-bootstrap decision rule. This deliberately
reuses the noisier unpinned dispersion rather than assuming a variance
reduction from host pinning.

With fixed seed `20260728`, 1,200 simulated experiments, and 1,500 inner
bootstrap resamples per cell, the estimated probability that all three cells
meet the positive rule is 65.8% at 20 blocks, 75.6% at 24 blocks, and 83.3% at
30 blocks. Therefore the formal replication freezes 30 blocks, the smallest
tested count above 80% sensitivity under the stated 1% true-cost assumption.
This is a design calculation, not evidence about the new run's effect.

## Execution And Completion

- Preflight: one paired block, two seconds per cell, through the same KVM,
  artifact, host-affinity, and analysis paths.
- Formal command:
  `make experiment-fxmark-fast-path RUN_ID=<fresh-id>`.
- Raw root:
  `results/experiments/fxmark-fast-path/<RUN_ID>/`.
- Completion requires:
  - 60 unique terminal boot records and 180 unique passing cells;
  - byte-identical expected and observed boot/cell tuples;
  - nonempty guest and host completion timestamps;
  - recorded actual alternating launch order;
  - positive QMP singleton mapping 0->4, 1->5, 2->6, 3->7 for every boot;
  - timestamp order
    `host start <= QMP verify <= guest barrier <= guest completion <= host completion`;
  - one immutable stock and patched artifact identity;
  - clean source/kernel state, stable TSC, clean dmesg, and passing hashes;
  - generated JSON, Markdown, PNG, and PDF analysis artifacts.

Any failed boot or gate fails the result root. No failed or partial boot is
replaced inside the run. Formal parameters are hard assertions: 30 blocks,
30-second cells, four vCPUs, host CPUs 4--7, 1-GiB tmpfs, fixed kernel commits,
and analysis seed `20260728`. The run remains `running` through raw validation
and analysis and becomes `completed` only after all analysis artifacts and
their hashes pass.

## Paper Decision

- Positive: report the independent host-pinned confirmation beside formal-v3
  and close the unused-fast-path gate.
- Inconclusive: report the strict threshold was not established and retain the
  measured interval; do not say zero or negligible cost.
- Contradictory: diagnose and redesign the common path before another
  confirmation; do not change the threshold to fit the result.

The result remains scoped to cache-hot FxMark `stat()` on this machine and does
not establish other operations, cache-cold behavior, tail latency, or
cross-machine generality.

## Execution Result

Formal-v1 completed from clean source commit `3372997` with all 60 boots and
180 cells. All three worker counts passed the predeclared positive rule. The
raw root is
`results/experiments/fxmark-fast-path/20260728T-fxmark-fast-path-formal-v1/`;
the independent result review is
`2026-07-28-fxmark-fast-path-formal-v1-result-review.md`.
