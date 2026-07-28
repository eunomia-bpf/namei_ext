# FxMark Fast-Path Result

- Paired repetitions: 30
- Bootstrap resamples: 10000
- Bootstrap seed: 20260728
- Overall verdict: **supported**

| Workload | Workers | Unattached / stock (95% CI) | Verdict |
| --- | ---: | ---: | --- |
| MRPL | 1 | 1.001 [0.992, 1.004] | supported |
| MRPL | 2 | 1.008 [0.995, 1.018] | supported |
| MRPL | 4 | 1.001 [0.992, 1.014] | supported |

A cell is supported when its median ratio is at least 0.98 and its 95% confidence-interval lower bound is at least 0.97. A cell is contradicted when its upper bound is below 0.98. Other outcomes are inconclusive.

The analysis covers paired, host-ordered MRPL throughput for the stock kernel and the patched kernel with no BPF program attached. The runner separately gates direct pre/post BPF-program, cgroup-attachment, FUSE-mount, and /dev/fuse-open-file inventories. It does not measure active-policy cost.
