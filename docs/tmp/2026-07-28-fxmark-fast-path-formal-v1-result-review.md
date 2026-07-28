# FxMark Fast-Path Formal-v1 Result Review

## Scope

This review covers:

```text
results/experiments/fxmark-fast-path/
  20260728T-fxmark-fast-path-formal-v1/
```

The run tests the predeclared unused-fast-path criterion for cache-hot FxMark
MRPL throughput. It compares the stock kernel with the patched kernel while no
`namei_ext` program is attached. It does not measure active-policy or FUSE
cost.

## Independent Review

A fresh read-only reviewer recomputed the result from the 180 raw
`MRPL-*.stdout` files without trusting `analysis/summary.json`. The reviewer
used the frozen 10,000-resample percentile bootstrap with seed `20260728`.
Every recomputed paired ratio, median, and confidence interval matched the
generated summary exactly.

The review verdict is `GO` for the scoped confirmatory claim.

## Completion And Validity

- 60 of 60 fresh KVM boots completed.
- 180 of 180 declared cells passed, forming 30 complete paired blocks at each
  worker count.
- Expected and observed boot and cell inventories are byte-identical.
- Odd blocks launched stock first; even blocks launched unattached first.
- Every boot recorded the exact mapping
  `vCPU0->4`, `vCPU1->5`, `vCPU2->6`, `vCPU3->7`.
- Every host-start, affinity-verification, guest-barrier, guest-completion, and
  host-completion timestamp chain is ordered.
- Direct pre/post BPF-program and cgroup-attachment inventories are empty and
  byte-identical in all boots.
- Direct pre/post FUSE mount and `/dev/fuse` open-file inventories are empty
  and byte-identical in all boots.
- Every cell has zero exit status, empty stderr, positive work, the expected
  tree cardinality, and verified non-root cgroup membership.
- Measured cell durations are 30.000004--30.000013 seconds.
- The patched and stock kernel identities are immutable within their arms.
  Their configurations differ only by `CONFIG_NAMEI_EXT=y`.
- Source and kernel worktrees were clean. No failed, partial, excluded,
  duplicated, or replacement sample exists.
- All 20 input, 15 packaged-artifact, five analysis-output, and 60 guest
  Makefile hash checks pass.

## Independently Recomputed Result

| Workers | Stock median ops/s | Unattached median ops/s | Unattached / stock median | 95% CI | Verdict |
| ---: | ---: | ---: | ---: | ---: | --- |
| 1 | 2,426,690.63 | 2,416,122.31 | 1.0009 | [0.9921, 1.0036] | supported |
| 2 | 4,801,144.91 | 4,823,899.68 | 1.0083 | [0.9950, 1.0179] | supported |
| 4 | 9,624,102.37 | 9,638,688.24 | 1.0007 | [0.9918, 1.0139] | supported |

The frozen gate requires a median of at least `0.98` and a confidence-interval
lower bound of at least `0.97` in every cell. All three cells pass. The
smallest lower-bound margin above the gate is 0.0218.

## Interpretation

The result supports this claim:

> On one host, for cache-hot FxMark MRPL `stat()` throughput at one, two, and
> four workers, the patched kernel with no attached `namei_ext` program
> satisfies the predeclared unused-fast-path criterion relative to the matched
> stock kernel.

The paper should report the ratios and confidence intervals instead of saying
that the unused path has "zero overhead." The result is an implementation
control, not the RQ2 comparison against feature-equivalent FUSE. The clean
formal-v3 matrix remains the active-path and FUSE result.

## Residual Scope

- One host, one cache-hot operation family, three worker counts, and throughput
  are covered. Cold-cache behavior, tail latency, other machines, and other
  operations are not.
- Affinity and frequency policy are verified before execution, not sampled
  continuously during each 30-second cell.
- Symmetric early-boot ACPI, regulatory-database, and virtme permission
  messages remain in dmesg, but they precede the workloads and trigger none of
  the declared failure patterns.
- The result tree hashes inputs, packaged artifacts, analysis outputs, and
  per-boot guest Makefiles. The raw aggregate is not in that committed
  manifest; its review-time SHA-256 is
  `f2d1d78c3e3359cdc43930faf374a26a7f155d16a25e7230d4e64574b705fae1`.

## Research Judgment

- run status: valid
- tested hypothesis: supported
- research value: decisive implementation control
- paper impact: closes the unused-fast-path uncertainty that remained after
  formal-v3
- next paper decision: report this result beside, but separate from, the
  active-policy/FUSE matrix; spend the next experiment budget on a
  source-derived workload rather than another FxMark replication
