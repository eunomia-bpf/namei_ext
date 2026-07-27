# RQ2 FxMark Result Review

## Scope

This review covers the completed run
`results/experiments/fxmark-rq2/20260726T-rq2-fxmark-full-v2/` against the
predeclared plan in
`docs/tmp/2026-07-26-rq2-fxmark-experiment-plan.md`.

The selected research question remains:

> What is the cost of putting programmable policy on the VFS name-resolution
> path compared with a feature-equivalent FUSE policy implementation?

The review does not change that RQ or weaken the approved hypothesis.

## Completion And Recalculation

- The run contains 50 completed KVM boot records and 450 unique observations:
  five conditions, three FxMark tests, three worker counts, and ten paired
  blocks.
- All 450 observations have `pass=true`; no row was excluded.
- Expected and observed boot/cell tuple files are byte-for-byte equal.
- Kernel notes, BTF, GNU build ID, kernel flavor, cgroup membership, attached
  program IDs, `SELECT`-required logical paths, FUSE mount/request engagement,
  lower-tree cardinality, and dmesg gates all passed.
- Patched and stock kernel configs differ only by `CONFIG_NAMEI_EXT`.
- Re-running `analysis/fxmark/analyze.py` with seed `20260726` reproduced the
  committed summary values. The CSV and Markdown report were byte-identical;
  JSON differed only in the spelling of the input path.

The acquisition target initially stopped after all boots because a Make shell
variable was not continued across three recipe lines. The per-boot data were
already complete. The repaired `make fxmark-rq2-finalize` reran every
post-collection gate and completed the still-running root without changing or
rerunning a raw boot. A second finalizer invocation on the completed root
failed before writing, with unchanged root hashes.

## Findings

### The Predeclared Hypothesis Is Contradicted

Across the nine test/worker cells:

- patched-unattached/stock median throughput is `0.867--0.942`; every 95%
  confidence-interval upper bound is below the predeclared `0.98` threshold;
- attached `SELECT`/FUSE median throughput is `0.314--0.570`; every confidence
  interval is wholly below `1`;
- unattached is slower in 89 of 90 paired observations; and
- `SELECT` is slower than FUSE in all 90 paired observations.

This is not a mixed or inconclusive result.

### The Main Active Cost Precedes The SELECT Action

Across the matrix, paired `PASS`/unattached medians are `0.298--0.547`, while
`SELECT`/`PASS` medians are `0.980--1.004`. The dominant attached cost is
therefore shared policy-path work, not target selection itself.

The current implementation exits RCU walk whenever the global namei_ext
cgroup-BPF key is active, then initializes and invokes the policy for every
ordinary path component. This is consistent with the measured result, but the
run alone does not separate RCU fallback, context initialization, cgroup
dispatch, and BPF execution.

### The Unattached Cost Has A Concrete Code-Generation Lead

In the matched objects, patched `link_path_walk` is 2,372 bytes versus 1,605
bytes in stock, and its stack allocation is `0x88` versus `0x18`. The current
inline `walk_component` declares redirect state and routes the normal path
through restore labels even when the static key is false. This is a direct
mechanism lead for the 6--13% inactive-path loss and motivates isolating the
extension path out of line.

### The FUSE Baseline Is Fair For The Approved Scope

The FUSE condition is a strong baseline for the approved stable, cache-hot
view: it runs multithreaded on the matched stock kernel with one-hour entry,
attribute, and negative TTLs. Setup produces 28--195,433 requests per cell,
while the measured phase has a median of only 1--18 requests. The result
therefore compares a policy executed on every namei_ext lookup with a FUSE view
already cached in the VFS.

That comparison is valid for the fixed plan. It does not answer behavior after
a policy update or FUSE invalidation, and it must not be generalized to
update-to-visible latency or dynamic-state throughput.

## Secondary-Metric Limits

- Recorded FUSE CPU covers setup as well as measurement, so it cannot support a
  measured-phase daemon-CPU claim.
- Every boot records a pre-measurement KVM clocksource watchdog timeout, and
  the host governor file is empty. The paired effects are large and
  consistent, but these records preclude fine-grained environment-stability
  or daemon-CPU claims.
- The selected pinned FxMark tests perform cache-hot `stat()`. The result does
  not cover open, readdir, cache-cold walks, or tail latency.

## Required Judgments

```text
run status: valid
tested hypothesis: contradicted
research value: decisive
paper impact: mechanism or workload boundary
next paper decision: Do not claim negligible unattached cost or a SELECT
performance advantage over optimized FUSE. Diagnose and redesign the inactive
path code generation and active RCU/cgroup policy path, then rerun the same
approved matrix under a new run ID. Do not rerun the unchanged implementation
or weaken the hypothesis.
```

## Next Work

1. Move attached-only redirect state and control flow out of the normal
   `walk_component` and final-open paths; verify stock-like code size and stack
   use before KVM timing.
2. Separate RCU fallback, BPF context/dispatch, and action costs with the
   existing PASS/SELECT controls rather than adding a new baseline.
3. Preserve optimized cached FUSE as the strongest static-view competitor.
   Treat dynamic update/invalidation as a separate same-RQ experiment only
   when both mechanisms implement the same update-to-visible oracle.
4. After mechanism repair and real preflight, rerun the unchanged 450-cell
   matrix under a fresh immutable result root and obtain one fresh result
   review.
