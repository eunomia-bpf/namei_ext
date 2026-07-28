# Agent Workspace RQ2 Formal v1 Result Review

## Purpose

This record reviews the first complete formal run of the predeclared Agent
Workspace RQ2 experiment. The run compares the real KVM
`cgroup/namei_ext` attach path with a feature-equivalent libfuse 3.14.0
implementation under the same AgentFS-derived correctness oracle.

The result root is:

```text
results/experiments/agent-workspace-rq2/20260727T-agent-workspace-rq2-formal-v1
```

## Execution

The matrix completed ten paired independent-boot blocks, or twenty KVM boots.
Condition order alternated by block. Each boot ran twenty complete workspace
lifecycle samples, one hundred `stat`, one hundred `open`, one hundred
`access`, twenty `exec`, and fifty `readdir` samples. All 400 lifecycle
samples and every required correctness oracle passed. Kernel identity, runtime
artifact hashes, input hashes, clocksource checks, and dmesg gates also passed.

The source commit was `d488578`, and the modified kernel commit was
`bdc9a83e3dfbef8ff2017f9188c7c86025962183`.

## Primary Result

The predeclared complete lifecycle metric was 6.32 us for `namei_ext` and
72.81 us for FUSE. The median paired FUSE/namei_ext ratio was 10.84x with a
10,000-resample bootstrap 95% confidence interval of [8.14, 12.89]. The
predeclared hypothesis is therefore supported by this run.

The mechanism decomposition was mixed:

| Operation | namei_ext | FUSE | Paired FUSE/namei_ext ratio |
| --- | ---: | ---: | ---: |
| complete lifecycle | 6.32 us | 72.81 us | 10.84x [8.14, 12.89] |
| stat | 0.75 us | 0.56 us | 0.73x [0.59, 0.97] |
| open | 1.17 us | 10.90 us | 8.64x [5.49, 9.57] |
| access | 0.65 us | 0.49 us | 0.74x [0.58, 0.94] |
| readdir | 2.70 us | 39.53 us | 14.23x [10.24, 14.65] |
| exec | 5532.09 us | 5738.59 us | 1.08x [0.85, 1.17] |

The cached `stat` and `access` rows favor FUSE because its long-lived entry and
attribute caches can answer those operations without a daemon round trip. The
result therefore does not support a blanket claim that `namei_ext` is cheaper
for every operation.

## Independent Review

An independent result review found no P0 correctness defect and judged the run
valid, the tested hypothesis supported, and the research value supporting. It
identified three P1 deficiencies that prevent using the exact 10.84x ratio as
a publication-grade constant:

1. The four QEMU vCPUs were not pinned on the heterogeneous Core Ultra 9 285K
   host. Native lower-filesystem `stat` medians varied from 511 ns to 924 ns,
   and namei lifecycle time correlated with the lower-filesystem control.
   Every paired lifecycle ratio nevertheless remained above 7.09x, so the
   direction of the result is robust.
2. The emitted FUSE `requests` count omitted `truncate` and `release`
   callbacks. Daemon CPU time used 100 Hz `/proc/PID/stat` ticks, which were
   all zero over this short measurement window. Those resource fields cannot
   support a daemon-cost claim.
3. The generated report omitted the predeclared p95/p99 values,
   lower-filesystem drift controls, FUSE resource measurements, operation
   counts, and an explicit correctness table.

The review also found that FUSE cache invalidation covered five primed paths
but omitted the primed `denied.txt` inode. The existing access-control oracle
passed before the epoch switch, but the run did not recheck it after switching
to the upper workspace.

## Decision

Formal v1 remains preserved as valid supporting evidence. It is not the final
paper result. The same hypothesis, workload, correctness oracle, baseline,
sample counts, and statistical decision rule will be retained while repairing
measurement control:

- pin four KVM vCPUs to homogeneous host CPUs;
- count every implemented FUSE callback;
- aggregate high-resolution per-thread daemon `schedstat` and context-switch
  counters;
- invalidate and recheck every primed epoch-dependent path; and
- generate the complete secondary analysis declared by the experiment plan.

After one passing two-boot preflight, the unchanged ten-block formal matrix
will be rerun as formal v2.
