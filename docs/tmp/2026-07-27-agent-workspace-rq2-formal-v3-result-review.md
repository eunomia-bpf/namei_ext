# Agent Workspace RQ2 Formal-v3 Result Review

## Scope

This review covers the completed result root:

`results/experiments/agent-workspace-rq2/20260727T-agent-workspace-rq2-formal-v3/`

The experiment compares `namei_ext` with a cache-coherent libfuse 3.14.0
implementation for the same fixed AgentFS-derived path-view oracle. It is a
controlled mechanism experiment over the AgentFS path-view slice, not a full
AgentFS reproduction or an end-to-end agent task.

## Run Identity

- Repository commit:
  `ed4aa13d232ee83a5272fc190c4a89ccd2f735b8`
- Kernel commit:
  `bdc9a83e3dfbef8ff2017f9188c7c86025962183`
- Source and kernel trees at run start: clean
- Layout: 10 paired independent-boot blocks, 20 KVM boots total
- Order: alternating, recorded from actual launch events
- Samples per boot and condition: 1,000 each for lifecycle, `stat`, `open`,
  `access`, `readdir`, and `exec`
- Host control: four guest vCPUs positively verified as singleton host CPU
  assignments 4--7; performance governor; turbo disabled
- Analysis: paired per-boot quantiles, 10,000 fixed-seed bootstrap resamples

## Completion And Correctness

All predeclared completion gates passed:

| Gate | Expected | Observed |
| --- | ---: | ---: |
| completed boots | 20 | 20 |
| passing lifecycle samples | 20,000 | 20,000 |
| required source-derived oracles | 960 | 960 |
| FUSE epoch invalidations | 60 | 60 |
| FUSE invalidation errors | 0 | 0 |
| failed observations | 0 | 0 |

Every boot passed kernel identity, artifact hash, clocksource, vCPU-affinity,
dmesg, policy-engagement, and FUSE-quiescence checks. For each FUSE boot,
`release`, `handle_opened`, and `release_completed` were all 4,012. The
namei_ext runner recorded 17,038 selected lookups per boot.

## Primary Result

The predeclared decision metric was complete workspace lifecycle p50. The
lifecycle is negative `stat`, create, rename, and unlink under the fixed
path-view state.

| Metric | namei_ext | FUSE | FUSE / namei_ext, paired 95% CI |
| --- | ---: | ---: | ---: |
| lifecycle p50 | 5.51 us | 62.64 us | 11.32x [11.24, 11.64] |
| lifecycle p95 | 6.33 us | 68.74 us | 10.88x [10.66, 11.04] |
| lifecycle p99 | 8.63 us | 73.39 us | 8.53x [8.18, 9.09] |

The predeclared hypothesis is **supported**. An independent reviewer
recomputed the p50 ratio and interval from raw JSONL as 11.3184x
[11.2413, 11.6372], matching `analysis/summary.json`.

## Operation Decomposition

The operation-level result is intentionally mixed:

| Operation, p50 | namei_ext | FUSE | FUSE / namei_ext, paired 95% CI |
| --- | ---: | ---: | ---: |
| `stat` | 692 ns | 528 ns | 0.76x [0.75, 0.78] |
| `open` | 1.10 us | 9.15 us | 8.35x [8.15, 8.53] |
| `access` | 628 ns | 462 ns | 0.74x [0.72, 0.77] |
| `readdir` | 2.49 us | 33.67 us | 13.59x [13.34, 13.67] |
| `exec` | 5.24 ms | 5.58 ms | 1.10x [1.00, 1.17] |

FUSE kernel caches can serve cache-hit `stat` and `access` without engaging
the daemon. `open`, `readdir`, and the complete mutation lifecycle engage more
FUSE filesystem methods and show substantially higher latency. The `exec`
result is inconclusive because its interval includes one.

## Controls And Resource Evidence

- Lower-filesystem `readdir` p50 ratio was 1.00x [0.99, 1.03].
- Lower-filesystem `stat` p50 ratio was 1.02x [1.01, 1.04]. This small boot
  drift cannot explain the lifecycle ratio and must remain visible beside it.
- Lifecycle p50 ratios were 11.28x for namei_ext-first blocks and 11.32x for
  FUSE-first blocks.
- The FUSE daemon processed 22,003 callbacks in each measured resource window,
  used a median 85.2 ms of CPU time, and incurred a median 23,002 voluntary
  context switches. These are absolute FUSE-daemon measurements, not a
  two-system total-resource comparison.

## Independent Review Findings

The independent result review found no P0 validity defect. It classified the
result as an OSDI/EuroSys-quality controlled mechanism experiment with
supporting paper value.

Two scope constraints remain:

1. The measured baseline is the committed high-level, single-threaded
   libfuse 3.14.0 implementation. It uses long metadata and negative-cache
   timeouts plus explicit invalidation, so it is not intentionally uncached,
   but the result does not establish performance against every low-level,
   passthrough, or newer FUSE implementation.
2. The timed lifecycle is a fixed AgentFS-derived path-view slice. It does not
   measure a complete AgentFS deployment, a real coding-agent task, concurrent
   workspaces, or a large workspace tree.

## Paper Decision

Admit this result as scoped RQ2 evidence:

> Across 10 paired independent KVM boot blocks, the fixed AgentFS-derived
> negative-lookup/create/rename/unlink lifecycle took 5.51 us with namei_ext
> and 62.64 us with the cache-coherent libfuse 3.14.0 implementation, a median
> paired ratio of 11.32x [11.24, 11.64], while both passed the same correctness
> oracle.

Do not claim a generic 11x advantage over FUSE, that every path operation is
faster, an end-to-end agent-task speedup, near-native performance, or a
two-system total CPU/context-switch reduction.

No formal-v3 rerun is required. The next Agent Workspace strengthening step is
an end-to-end source workflow at realistic tree size and concurrency against
an optimized low-level FUSE implementation, with application-plus-daemon
resource accounting.
