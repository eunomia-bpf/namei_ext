# RQ2 FxMark Readdir Preflight Result Review

Date: 2026-07-29

## Scope

This review covers the final allowed real KVM preflight:

```text
results/experiments/fxmark-readdir-preflight/
  20260729T081348Z-fxmark-readdir-preflight-v3/
```

The preflight checks whether the frozen corrected-FxMark protocol can execute
the stock, patched-unattached, attached `PASS`, attached `SELECT`, and
feature-equivalent FUSE paths with valid correctness and attribution evidence.
It is not the formal performance experiment.

## Completion And Validity

An independent read-only reviewer recomputed the run from the raw result root.
No protocol defect blocks the preflight or the frozen formal matrix.

- All five fresh KVM boots completed.
- All 20 declared cells passed, covering corrected FxMark `MRDL` and `MRDM`
  with one and four workers under all five conditions.
- Expected and observed boot and cell inventories match exactly.
- The run used clean source commit
  `fff520e07c5614c068e3c9e2f4ceb43693c4ff47` and clean kernel commit
  `1e81d4793c78b7667d0798248c70c0b15a2c3877`.
- Stock and patched kernel configurations differ only by
  `CONFIG_NAMEI_EXT=y`.
- Source, kernel, runtime, raw-input, analysis, and packaged-artifact hashes
  revalidate.
- All boots used the required vCPU-to-host-CPU mapping on CPUs 4--7, retained
  TSC, passed timestamp ordering and frequency gates, had empty external BPF
  and FUSE inventories, and passed the frozen dmesg failure scan.
- Every cell passed exact directory cardinality, logical-name bitmap,
  cgroup-membership, process-status, duration, and lower-object identity
  checks.
- Every FUSE cell recorded exactly one measured-phase acknowledgement, one
  after-phase acknowledgement, zero invalid transitions, and positive
  measured `opendir`, `readdir`, and `releasedir` counts.

For the fixed 4 KiB `getdents64` validator over the current tmpfs iterator, the
predeclared BPF attribution equation held exactly in every attached cell. For
example, `PASS` `MRDM` with four workers returned 32,770 entries and observed
377 candidate-entry retries, 33,147 readdir policy runs, two lookup policy
runs, and a total BPF delta of 33,149.

Preflight validity: GO

## Observed Direction

The independently recomputed one-block `SELECT/FUSE` ratios are:

| Test | Workers | Ratio |
| --- | ---: | ---: |
| `MRDL` | 1 | 2.153 |
| `MRDL` | 4 | 3.607 |
| `MRDM` | 1 | 2.919 |
| `MRDM` | 4 | 0.967 |

The analyzer's `contradicted` verdict is the correct result under the frozen
rule because the `MRDM` four-worker value is at or below one. It must not be
relabeled positive or mixed.

Each preflight cell has only one observation. Bootstrap resampling therefore
repeats the same observation and produces a degenerate interval, such as
`[0.967, 0.967]`; it does not estimate cross-run uncertainty. The unfavorable
direction is real, but the preflight cannot decide whether it persists across
the ten paired formal blocks.

## Formal Authorization

The formal protocol was frozen before this result: ten paired five-condition
blocks, 50 fresh KVM boots, 30-second cells, one/two/four workers, and rotating
Latin-square order. The preflight exposed no correctness, attribution,
baseline-engagement, isolation, or collector failure that requires a protocol
change.

The formal run should proceed unchanged. Its scientific purpose includes
determining whether the `MRDM` four-worker ratio remains at or below one under
independent paired repetitions. Stopping after one unfavorable preflight
observation would be selective stopping. If the formal interval remains below
the predeclared boundary, the final result must be reported as contradicted or
mixed rather than changing the hypothesis or metric.

Formal authorization: GO

Final verdict: GO
