# RQ2 FxMark RCU-Target Rerun Review

## Scope

This review covers the completed clean-source run
`results/experiments/fxmark-rq2/20260727T-rq2-rcu-target-full-v2/`.
It applies the unchanged protocol in
`docs/tmp/2026-07-26-rq2-fxmark-experiment-plan.md` after the global
parent-filter, RCU target-registry, and RCU borrowed-target mechanism repairs.

The research question remains:

> What is the cost of putting programmable policy on the VFS name-resolution
> path compared with a feature-equivalent FUSE policy implementation?

## Completion And Provenance Finding

- The run completed 50 fresh KVM boots and 450 unique observations: five
  conditions, three pinned FxMark tests, three worker counts, and ten paired
  blocks.
- All 450 observations passed. No cell was filtered, excluded, or rerun inside
  the result root.
- Expected and observed boot and cell tuple files are byte-for-byte equal.
- Every boot records the expected kernel commit, build ID, notes and BTF
  hashes, kernel configuration, CPU snapshots, launcher logs, and dmesg.
- The root records clean parent commit
  `1bb7eb922fee76d8e6cc87e3af1df3b55763bdbd` and kernel commit
  `bdc9a83e3dfbef8ff2017f9188c7c86025962183`; the matched stock kernel is
  `062871f1371b2e02a272ff5279c6479aff0a37ef`.
- Attached program identity, exact cgroup membership, logical-path dependence
  on `SELECT`, FUSE mount/request engagement, tree cardinality, and all
  declared dmesg failure gates passed.
- The recorded patched binary does not correspond to the recorded kernel
  commit. All 30 patched boots report
  `7.1.0-rc7-g83d52c2168e2-dirty`, built before `bdc9a83e3` was committed.
  Binary hashes identify the tested artifact but do not prove that it came
  from the clean source recorded by the root.
- All 50 boots contain a pre-measurement
  `clocksource: Watchdog remote CPU ... read timed out` line that the original
  dmesg pattern did not reject.

The first attempt,
`20260727T-rq2-rcu-target-full-v1`, was externally terminated after five
hours with 33 complete boots. It remains an interrupted raw run and is not
combined with or cited as part of the completed result.

## Numerical Result

The numbers support the predeclared hypothesis in all nine test/worker cells,
but the provenance defect prevents treating them as publication-grade
evidence until a clean committed-kernel rebuild reproduces them.

| Test | Workers | Unattached / stock, median [95% CI] | SELECT / FUSE, median [95% CI] |
| --- | ---: | ---: | ---: |
| MRPL | 1 | 0.993 [0.975, 1.025] | 1.067 [1.056, 1.092] |
| MRPL | 2 | 0.997 [0.985, 1.034] | 1.074 [1.064, 1.090] |
| MRPL | 4 | 1.001 [0.984, 1.032] | 1.082 [1.070, 1.088] |
| MRPM | 1 | 1.015 [1.004, 1.031] | 1.058 [1.043, 1.079] |
| MRPM | 2 | 1.001 [0.987, 1.016] | 1.040 [1.032, 1.061] |
| MRPM | 4 | 1.010 [0.995, 1.021] | 1.050 [1.030, 1.073] |
| MRPH | 1 | 1.008 [1.004, 1.022] | 1.059 [1.047, 1.068] |
| MRPH | 2 | 1.014 [1.001, 1.024] | 1.064 [1.024, 1.075] |
| MRPH | 4 | 1.001 [0.989, 1.035] | 1.064 [1.044, 1.072] |

Patched-unattached median throughput is within 0.7% below to 1.5% above stock
across the matrix. Every cell satisfies the predeclared median and confidence
interval thresholds for the unused fast path.

`SELECT` exceeds optimized FUSE by 4.0--8.2% in median throughput. Every
bootstrap confidence interval is wholly above one, and `SELECT` exceeds FUSE
in all 90 paired observations.

## Active-Path Cost

Independent paired recalculation over the same raw observations separates the
active cost:

- attached `PASS` retains 90.0--93.0% of patched-unattached throughput;
- `SELECT` retains 96.9--99.7% of `PASS` throughput; and
- complete `SELECT` retains 87.3--91.9% of patched-unattached throughput.

The dominant active cost is therefore policy dispatch and BPF execution.
After the RCU target-registry and borrowed-target changes, object selection
adds only about 0.3--3.1% median cost beyond `PASS` in this matrix.

This decomposition also bounds the result honestly: an attached policy is not
free. The supported claim is a negligible unused fast path, a measured
7--10% attached `PASS` cost, and a small incremental same-filesystem
`SELECT` cost for cache-hot `stat()` path resolution.

## FUSE Baseline

The FUSE implementation is deliberately optimized for this stable view. It is
multithreaded, runs on the matched stock kernel, enables
`default_permissions` and `kernel_cache`, uses one-hour entry, attribute, and
negative-cache timeouts, and may use all four guest vCPUs. Median measured
daemon requests are only 1--18 per 30-second cell.

The result therefore does not win by forcing a userspace round trip on every
FUSE lookup. It compares `namei_ext` with a cache-hot FUSE view whose pathname
metadata is already retained by the VFS. This is the appropriate strong
baseline for the frozen stable-view experiment.

The run does not establish update-to-visible latency, post-invalidation
throughput, cache-cold behavior, daemon failure behavior, or FUSE passthrough
data-path performance.

## Supported And Unsupported Claims

Supported:

- enabling the patched kernel without an attached policy has negligible
  throughput cost under the predeclared threshold;
- an attached policy has a reproducible 7--10% throughput cost in these
  cache-hot `stat()` workloads;
- same-filesystem selected-target resolution adds little cost beyond `PASS`;
- `SELECT` retains 4--8% more throughput than the feature-equivalent optimized
  FUSE view in all nine tested cells.

Not supported by this run:

- open, access, exec, readdir, cache-cold, or tail-latency performance;
- arbitrary BPF policy complexity;
- cross-filesystem target performance;
- dynamic update or invalidation behavior;
- data-path throughput or daemon CPU claims; and
- a generic claim that `namei_ext` is always faster than FUSE.

## Verdict And Required Rerun

```text
run status: complete matrix, invalid publication provenance
tested hypothesis: numerically supported, pending clean reproduction
research value: decisive if reproduced
paper use: none until the clean fixed-protocol rerun completes
```

The kernel build must be tied to its source commit, guest `uname -r` must match
the expected clean release, the clocksource watchdog record must be eliminated
or fail the run, all boots must consume one frozen artifact set, and the
unchanged 450-cell matrix must be rerun under a fresh result ID. The numerical
ranges above are diagnostic expectations only.
