# Agent Workspace RQ2 Result

- Paired independent-boot blocks: 10
- Bootstrap resamples: 10000
- Bootstrap seed: 20260727
- Predeclared lifecycle verdict: **supported**

## Correctness Gate

| Gate | Expected | Observed |
| --- | ---: | ---: |
| completed boots | 20 | 20 |
| passing lifecycle samples | 20000 | 20000 |
| required source-derived oracles | 960 | 960 |
| FUSE epoch invalidations | 60 | 60 |
| FUSE invalidation errors | 0 | 0 |
| failed observations | 0 | 0 |

## Latency

| Metric | Quantile | namei_ext | FUSE | FUSE / namei_ext (95% CI) |
| --- | --- | ---: | ---: | ---: |
| lifecycle | p50 | 5.51 us | 62.64 us | 11.32x [11.24, 11.64] |
| lifecycle | p95 | 6.33 us | 68.74 us | 10.88x [10.66, 11.04] |
| lifecycle | p99 | 8.63 us | 73.39 us | 8.53x [8.18, 9.09] |
| stat | p50 | 692 ns | 528 ns | 0.76x [0.75, 0.78] |
| stat | p95 | 767 ns | 626 ns | 0.83x [0.76, 0.88] |
| stat | p99 | 833 ns | 747 ns | 0.88x [0.77, 0.97] |
| open | p50 | 1.10 us | 9.15 us | 8.35x [8.15, 8.53] |
| open | p95 | 1.22 us | 10.48 us | 8.74x [8.12, 9.44] |
| open | p99 | 1.32 us | 12.63 us | 9.42x [8.75, 10.04] |
| access | p50 | 628 ns | 462 ns | 0.74x [0.72, 0.77] |
| access | p95 | 707 ns | 535 ns | 0.77x [0.74, 0.82] |
| access | p99 | 785 ns | 652 ns | 0.84x [0.73, 0.90] |
| readdir | p50 | 2.49 us | 33.67 us | 13.59x [13.34, 13.67] |
| readdir | p95 | 2.67 us | 36.30 us | 13.53x [12.62, 13.86] |
| readdir | p99 | 3.37 us | 38.80 us | 11.64x [9.97, 13.61] |
| exec | p50 | 5.24 ms | 5.58 ms | 1.10x [1.00, 1.17] |
| exec | p95 | 6.24 ms | 6.48 ms | 1.09x [0.90, 1.16] |
| exec | p99 | 6.78 ms | 6.88 ms | 1.08x [0.90, 1.14] |

The lifecycle p50 row is the predeclared decision metric. Other quantiles and operations decompose the mechanism and do not redefine the verdict. An interval containing one is inconclusive because no equivalence margin was registered.

## Lower-Filesystem Controls

| Metric | Quantile | namei_ext | FUSE | FUSE / namei_ext (95% CI) |
| --- | --- | ---: | ---: | ---: |
| lower_stat | p50 | 505 ns | 518 ns | 1.02x [1.01, 1.04] |
| lower_stat | p95 | 573 ns | 590 ns | 1.04x [0.99, 1.07] |
| lower_stat | p99 | 641 ns | 659 ns | 1.06x [0.90, 1.10] |
| lower_readdir | p50 | 1.87 us | 1.87 us | 1.00x [0.99, 1.03] |
| lower_readdir | p95 | 2.05 us | 2.06 us | 1.02x [0.95, 1.08] |
| lower_readdir | p99 | 2.20 us | 2.20 us | 0.99x [0.93, 1.09] |

These controls bypass both namei_ext and FUSE. Their paired ratios show host/guest drift between the two independent boots in each block.

## Order Diagnostic

| Metric | namei_ext-first blocks | FUSE-first blocks |
| --- | ---: | ---: |
| lifecycle | 11.28x | 11.32x |
| stat | 0.76x | 0.75x |
| open | 8.34x | 8.35x |
| access | 0.75x | 0.73x |
| readdir | 13.37x | 13.60x |
| exec | 1.08x | 1.17x |

These are descriptive medians of the paired p50 ratios for the five odd and five even blocks. They diagnose a condition-order effect; they are not an additional hypothesis test.

## FUSE Daemon Resource Window

| Field | Median per boot | Range |
| --- | ---: | ---: |
| callback_requests | 22003 | 22003--22003 |
| cpu_runtime_ns | 85161960 ns | 83207440 ns--87012690 ns |
| runqueue_wait_ns | 219659 ns | 183836 ns--272889 ns |
| timeslices | 23006 | 23003--23012 |
| voluntary_context_switches | 23002 | 23000--23003 |
| involuntary_context_switches | 4 | 3--10 |
| threads_before | 2 | 2--2 |
| threads_after | 2 | 2--2 |

CPU runtime and run-queue wait are high-resolution sums across all FUSE daemon threads from `/proc/PID/task/*/schedstat`. Callback requests count every implemented high-level FUSE operation in the measurement window.

## Operation And Callback Counts

| Timed operation | Samples per boot | Samples in matrix |
| --- | ---: | ---: |
| lifecycle | 1000 | 20000 |
| stat | 1000 | 20000 |
| open | 1000 | 20000 |
| access | 1000 | 20000 |
| readdir | 1000 | 20000 |
| exec | 1000 | 20000 |

| FUSE counter | Median per boot | Range |
| --- | ---: | ---: |
| getattr | 9035 | 9035--9035 |
| readdir | 1004 | 1004--1004 |
| open | 3010 | 3010--3010 |
| create | 1002 | 1002--1002 |
| read | 2010 | 2010--2010 |
| write | 2 | 2--2 |
| readlink | 2 | 2--2 |
| unlink | 1001 | 1001--1001 |
| rename | 1002 | 1002--1002 |
| mknod | 0 | 0--0 |
| truncate | 0 | 0--0 |
| release | 4012 | 4012--4012 |
| request_total | 22080 | 22080--22080 |
| handle_opened | 4012 | 4012--4012 |
| release_completed | 4012 | 4012--4012 |
| hidden_lookup | 1 | 1--1 |
| hidden_readdir | 1003 | 1003--1003 |
| invalidate_attempt | 6 | 6--6 |
| invalidate_error | 0 | 0--0 |

The operation-level result is intentionally mixed: cache-hit `stat` or `access` may be served from FUSE kernel caches, while operations that engage the daemon carry a larger cost. The paper claim must therefore use the complete lifecycle decision metric and show this decomposition, not claim that namei_ext wins every individual operation.
