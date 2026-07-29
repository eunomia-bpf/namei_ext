# RQ2 FxMark Readdir Formal-v1 Result Review

## Scope

This review covers:

```text
results/experiments/fxmark-readdir/
  20260729T082800Z-fxmark-readdir-formal-v1/
```

The run executes the frozen corrected-FxMark `MRDL`/`MRDM` protocol from
`docs/tmp/2026-07-28-rq2-fxmark-readdir-experiment-plan.md`. It tests
private- and shared-directory enumeration at one, two, and four workers under
stock, patched-unattached, attached `PASS`, attached same-filesystem `SELECT`,
and a matched libfuse 2.9.9 view.

## Independent Validity Review

A fresh read-only reviewer recomputed the result without trusting the generated
summary and executed 4,223 raw assertions with zero failures.

- 50/50 fresh KVM boots and 300/300 planned cells completed.
- The top-level observations match the 50 direct boot observation streams.
- Source commit `121ed2dcd2294a35f9be5347a043295c4ec3657c` and kernel
  commit `1e81d4793c78b7667d0798248c70c0b15a2c3877` were clean.
- Stock and patched configurations differ only by `CONFIG_NAMEI_EXT=y`.
- All input, source, packaged-artifact, and analysis/raw-input hashes pass.
- The ten five-condition blocks preserve the frozen rotating Latin-square
  order; no failed boot was replaced.
- Every boot fixed vCPU 0--3 to host CPU 4--7, retained TSC, and passed the
  declared CPU-frequency, external-inventory, timestamp, and dmesg gates.
- Every cell passed exact tree cardinality, complete logical names, cgroup,
  duration, and process-status checks.
- All 60 `SELECT` cells proved that the logical path required target selection
  and resolved to the expected lower-directory identity.
- All 60 FUSE cells retained a real FUSE superblock, positive measured
  `opendir`/`readdir`/`releasedir` requests, exact phase acknowledgements, and
  daemon exit status zero.
- Every attached cell passed the post-timing fixed-buffer BPF attribution
  equation. BPF run statistics remained disabled during timing.

Run status: valid.

## Primary Result

The independent review repeated the frozen 10,000-resample paired percentile
bootstrap with seed `20260728`.

| Cell | `SELECT/FUSE` median | 95% CI | Individual wins |
| --- | ---: | ---: | ---: |
| `MRDL`, 1 worker | 2.314x | [2.223, 2.355] | 10/10 |
| `MRDL`, 2 workers | 2.200x | [2.178, 2.212] | 10/10 |
| `MRDL`, 4 workers | 3.663x | [3.505, 3.789] | 10/10 |
| `MRDM`, 1 worker | 2.909x | [2.833, 2.968] | 10/10 |
| `MRDM`, 2 workers | 2.450x | [2.332, 2.586] | 10/10 |
| `MRDM`, 4 workers | 1.018x | [0.907, 1.135] | 5/10 |

Five cells have a confidence-interval lower bound above one. The `MRDM`
four-worker interval crosses one, and no cell has an upper bound at or below
one. The frozen overall verdict is therefore **mixed**, not supported or
contradicted.

## Mechanism Decomposition

| Cell | unattached/stock | `PASS`/unattached | `SELECT`/`PASS` |
| --- | ---: | ---: | ---: |
| `MRDL`, 1 | 0.999 | 0.774 | 1.001 |
| `MRDL`, 2 | 0.996 | 0.797 | 0.999 |
| `MRDL`, 4 | 1.000 | 0.790 | 0.997 |
| `MRDM`, 1 | 1.000 | 0.775 | 0.998 |
| `MRDM`, 2 | 1.006 | 1.278 | 0.999 |
| `MRDM`, 4 | 1.014 | 0.934 | 0.936 |

The patched-unattached path is statistically indistinguishable from stock in
these cells; this is not a literal zero-overhead claim. For private-directory
enumeration and one-worker shared-directory enumeration, per-entry `PASS`
dispatch reduces throughput by about 20--23%, while `SELECT` adds little beyond
`PASS`. The shared-directory two- and four-worker cells are contention
regimes, so their adjacent-condition ratios do not estimate an isolated BPF
invocation cost.

`MRDL` `SELECT` scales 3.844x from one to four workers, compared with 2.411x
for FUSE. In `MRDM`, stock, `SELECT`, and FUSE converge near five million
entries/s at four workers. The shared lower-directory contention masks any
additional FUSE cost there and explains why the primary comparison is
inconclusive in that cell.

All FUSE cells have equal `opendir` and `releasedir` counts and serve about
585--655 entries per userspace `readdir` request. This confirms sustained
FUSE directory-path engagement rather than a setup-only baseline. CPU and
context-switch counts are useful explanatory measurements but are not part of
the frozen primary verdict.

## Paper Decision

- tested hypothesis: mixed
- research value: decisive RQ2 breadth and scaling-boundary evidence
- paper impact: admit as the standard directory-enumeration result
- publication usability: yes, with the `MRDM` four-worker cell retained

Supported wording:

> On one four-vCPU KVM with tmpfs, `namei_ext` `SELECT` achieved 2.20--3.66x
> the throughput of the matched libfuse 2.9.9 view for corrected FxMark
> private-directory enumeration, and 2.45--2.91x for shared-directory
> enumeration at one and two workers. At four shared-directory workers, the
> ratio was 1.018x [0.907, 1.135], so the experiment establishes no throughput
> advantage in that contention regime.

The paper must not claim that all readdir workloads or all six cells favor
`namei_ext`. Scope remains one host, four KVM vCPUs, tmpfs, static cache-hot
directories, and the committed high-level libfuse 2.9.9 implementation.

Final verdict: GO
