# Agent Workspace RQ2 Publication-Control Repair

## Motivation

The first formal Agent Workspace RQ2 matrix passed its correctness gates and
supported the predeclared lifecycle hypothesis. An independent result review
found that the exact ratio and daemon-resource fields were not yet
publication-grade. This implementation step repairs measurement control
without changing the hypothesis, workload, baseline, correctness oracle,
sample counts, or statistical decision rule.

## Files Inspected

- `mk/kvm.mk`
- `mk/experiments/agent_workspace_rq2.mk`
- `configs/benchmarks/agent_workspace.mk`
- `experiments/agent_workspace/namei_ext_agent_workspace.c`
- `experiments/agent_workspace/namei_ext_agent_workspace_fuse.c`
- `experiments/agent_workspace/rq2_required_oracles.txt`
- `analysis/agent_workspace/analyze.py`
- `analysis/agent_workspace/test_analyze.py`
- all raw and generated artifacts under the formal-v1 result root

## Implementation

### Homogeneous vCPU Placement

The common KVM launch macro now accepts an optional `vng --pin` CPU list. The
Agent Workspace RQ2 protocol declares four vCPUs pinned to host CPUs 4-7. These
are homogeneous performance cores and have lower accumulated softirq and
non-idle time than CPUs 0-3 on the experiment host. The
owning Make target fails before creating a result root unless the requested
list is one contiguous online range with exactly four CPUs and identical
`cpuinfo_max_freq` values. It also requires the `performance` governor and
disabled Intel turbo. The run manifest, command, pin list, frequency policy,
normal `lscpu` output, and extended CPU topology are preserved in the result
root. Host `/proc/stat` and `/proc/interrupts` snapshots bracket the full
matrix.
The parsed CPU set is stored as `host-cpu-pin.json`; every per-boot affinity
artifact must match that set and the declared vCPU count.

The optional argument leaves every other KVM caller unchanged.

The installed virtme-ng implementation obtains each QEMU vCPU host thread ID
through QMP and calls `sched_setaffinity` on distinct requested CPUs. Because
virtme-ng emits warnings rather than failing for some affinity errors, the
Make finalizer treats every known pin failure message as a hard failure. The
virtme-ng version and executable hash are also preserved. A host-side verifier
independently connects to QMP while each VM is running, records every vCPU host
TID, reads its actual `Cpus_allowed_list`, and requires four distinct singleton
affinities whose set is exactly CPUs 4-7. This per-boot JSON is the positive
pinning proof; warning filtering is only a secondary failure gate.
Both the small `vng` entrypoint and the imported `virtme_ng.run` implementation
are hashed.

The verifier writes its result atomically. The guest Make target waits for a
`verified` result before collecting controls or starting either runner; a
failed result terminates the guest. The verification timestamp is preserved in
both `affinity-barrier.txt` and `boot.json`, so affinity verification is a
workload-start barrier rather than a concurrent observation.

### Complete FUSE Callback Accounting

The FUSE implementation now increments one total counter at entry to every
implemented high-level callback:

```text
getattr readdir open create mknod read write truncate readlink unlink rename release
```

Internal hidden-entry and invalidation counters remain separate. The analyzer
requires `request_total` to equal the sum of all callback counters, so future
callback additions cannot silently disappear from the reported total.

### High-Resolution Daemon Resources

The runner retains raw `/proc/PID/stat` ticks for diagnosis but no longer
depends on them for short-window CPU accounting. Before and after the timed
window it enumerates every stable FUSE daemon thread and sums:

- CPU runtime, run-queue wait, and timeslices from
  `/proc/PID/task/TID/schedstat`; and
- voluntary and involuntary context switches from each task status file.

The observation records raw deltas, callback requests, and thread counts. Any
counter regression, task-count change, missing task file, zero CPU runtime, or
empty callback window fails the experiment.

Because FUSE `release` is a background request, each resource snapshot follows
an explicit quiescence gate. The gate requires the cumulative `release` count
completed after closing the backing file to equal a separate counter
incremented only after `open` or `create` successfully returns a file handle,
and the complete callback count to remain stable for 20 ms. The pre-window
gate excludes older release work; the post-window gate includes every timed
release before the after snapshot. Entry, successful-handle, and completed
release counters are all preserved and must agree.

### Complete Epoch-Coherence Oracle

The base-epoch permission check primes `denied.txt`. FUSE epoch switching now
invalidates that path in addition to the five existing paths, and both
implementations recheck denied access after selecting the upper workspace.
The base file has mode 0000 and the upper file mode 0100, so a separate mode
oracle proves that the cached attributes changed while both objects continue
to reject unprivileged reads.
The required-oracle manifest and Make gates now require six successful FUSE
invalidations with zero errors.

### Complete Analysis

The analyzer validates every source-derived required oracle itself and emits:

- per-boot p50, p95, and p99 latency and paired bootstrap intervals;
- lower-filesystem `stat` and `readdir` drift controls;
- complete callback and daemon-resource summaries;
- fixed operation counts and observed callback counts;
- a correctness-gate table; and
- a descriptive condition-order diagnostic driven by a host-recorded launch
sequence.

The base `namei_ext.run.v2` envelope remains shared across suites. This suite
adds `namei_ext.agent_workspace_rq2.protocol.v2`; launch-order, boot, affinity,
and analysis-summary artifacts each carry their own schema identifiers.

Each successful boot appends its actual order index, condition, repetition,
and host start/end timestamps to `launch-order.jsonl`; the same index is added
to `boot.json`. Make validates the unsorted sequence against the alternating
protocol, and the analyzer uses this artifact rather than inferring order from
block numbers.

The report explicitly preserves mixed operation-level results. Only the
predeclared complete-lifecycle p50 confidence interval determines the
hypothesis verdict.

### Sample-Count Amendment

Formal v1 used 20 lifecycle and exec samples, 100 `stat`, `open`, and `access`
samples, and 50 `readdir` samples per boot. Those counts are adequate for the
predeclared p50 decision but not for a defensible p99. Before formal v2, every
timed operation and each lower-filesystem control is increased to 1,000
samples per boot. The Make target hard-gates these counts, compiles them into
both runners, records them in `run.json`, and makes the analyzer reject any
different matrix. The ten paired boots and p50 decision rule remain unchanged.

## Alternatives Rejected

- Host `taskset` around the entire VM process was rejected because it would
  not express one distinct homogeneous host CPU per QEMU vCPU as directly as
  `vng --pin`.
- Extending the timed window merely to make 100 Hz CPU ticks nonzero was
  rejected because it would change the workload and still provide coarse
  accounting.
- Summing selected FUSE callbacks in the analyzer was rejected because that
  repeats the omission risk; the runner now owns an explicit callback-total
  counter and the analyzer checks it against the full callback set.
- Dropping the cached `stat` and `access` rows was rejected. They are valid
  evidence about FUSE kernel caching and must remain visible.

## Local Validation

- Both Agent Workspace runners compile with `-Wall -Wextra`.
- Eight analyzer and five vCPU-affinity verifier unit tests pass, including a
  complete synthetic-matrix report generation test.
- Python byte-code compilation succeeds.
- A dry run confirms that the generated KVM command contains
  `vng --pin 4-7`, and that pin metadata and the required-oracle input reach
  the run manifest and analyzer.
- `git diff --check` passes.

## Remaining Validation

The next gate is one real two-boot KVM control preflight. It must demonstrate
nonzero high-resolution daemon CPU time, complete callback accounting, six
successful epoch invalidations, both post-switch permission oracles, stable
thread counts, host pin metadata, and clean dmesg. A passing preflight permits
the unchanged ten-block formal-v2 matrix.
