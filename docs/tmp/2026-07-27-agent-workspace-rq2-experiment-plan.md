# Experiment Plan: RQ2 Agent Workspace Cost Versus FUSE

## Research Question

- RQ exactly as written in the paper: What is the cost of putting programmable
  policy on the VFS name-resolution path compared with a feature-equivalent
  FUSE policy implementation?
- Specific uncertainty tested here: whether `namei_ext` retains a measurable
  path-operation and lifecycle cost advantage on the AgentFS-derived workspace
  oracle after giving FUSE the strongest cache configuration that preserves
  this workload's epoch switch, create, rename, unlink, and cached-negative
  semantics.
- Why the answer matters: Agent workspaces are the headline workload. Existing
  runs establish correctness but use one boot per run and an all-zero FUSE
  timeout configuration, so they cannot support a publication-quality RQ2
  comparison.

## Paper-Value Admission

- Planned role: headline.
- Largest credible paper story this experiment could unlock: a narrow VFS
  policy hook can implement the source-derived workspace path-view slice while
  avoiding the per-operation and daemon costs of a cache-coherent FUSE
  filesystem on the same lifecycle.
- Strongest reviewer reject argument or load-bearing uncertainty addressed:
  the existing FUSE row may lose only because metadata caching was disabled,
  and the existing timing rows lack independent-boot uncertainty.
- Independent evidence added beyond existing runs and published results:
  matched current-kernel runs, one mechanism per KVM boot, rotated condition
  order, raw operation samples, lifecycle samples across boots, FUSE request
  and resource accounting, and confidence intervals.
- Why the result is not tautological, already settled, or dominated: FUSE can
  cache dentries and attributes, and compiler- or FxMark-level results do not
  determine the cost of this state-changing workspace lifecycle.
- Paper decision if positive: use Agent workspace as the headline same-oracle
  RQ2 result, alongside its existing RQ1 correctness evidence.
- Paper decision if contradictory, mixed, or inconclusive: keep the valid
  measurements, identify which operations or lifecycle phases eliminate the
  advantage, and redesign the mechanism only if the result exposes a
  `namei_ext` cost rather than baseline or harness failure. Do not weaken the
  RQ.
- Best alternative experiment and why this one has higher decision value:
  completing W1 or W3 FUSE timing would add breadth, but neither is the
  headline workload and neither closes the current strongest FUSE-fairness
  objection.

## Expected And Alternative Outcomes

- Current expected answer: `namei_ext` will have lower median `stat`, `open`,
  `access`, and `readdir` latency and lower complete create/rename/unlink
  lifecycle time than cache-coherent FUSE. `exec` may be similar because
  process creation dominates.
- Strongest competing explanation: a correctly cached FUSE view eliminates
  most path-resolution crossings, leaving no consequential cost difference.
- Result that would contradict the expectation: the FUSE lifecycle and
  path-operation confidence intervals match or beat `namei_ext` while both
  mechanisms pass the same oracle and FUSE mechanism engagement is verified.

## Published Precedent And Real Assets

- Closest published protocol: AgentFS workspace lifecycle and cache
  invalidation behavior, plus the standard FUSE request/caching model.
- Official system and version: AgentFS commit
  `0a014ebd4918615baff589ed17486e557e7c6a23`; official libfuse 3.14.0
  headers matched to the installed 3.14.0 runtime; current committed
  `namei_ext` kernel and policy.
- What is reused: the fixed `agentfs-bash-git-workspace-v1` trace, existing
  `namei_ext` and FUSE runners, current lower-object oracle, and real
  `cgroup/namei_ext` attachment.
- Necessary deviations or custom glue: Make-owned multi-boot orchestration,
  run-local immutable artifacts, condition/repetition tags, FUSE request and
  daemon resource instrumentation, and analysis. This remains an
  AgentFS-derived path-view workload, not a full AgentFS reproduction.

## Comparison

- Proposed system: `namei_ext` with `agent_workspace_view.bpf.c`.
- Main baseline: the feature-equivalent libfuse workspace implementation. It
  represents the current programmable filesystem answer and must pass the same
  source trace and final-tree oracle.
- Why the baseline needs a matched run: published FUSE overhead does not
  establish costs for this exact state machine, operation mix, backing tree,
  kernel, cache policy, or correctness oracle.
- FUSE cache policy: use `entry_timeout=3600`, `attr_timeout=3600`, and
  `negative_timeout=3600`, with `default_permissions` and without
  `kernel_cache`. The FUSE process changes the active epoch, calls libfuse
  3.14.0 `fuse_invalidate_path()` for every primed logical inode whose backing
  object changes, and acknowledges the transition only after every
  invalidation succeeds. Long negative caching remains enabled: create,
  rename, and unlink performed through FUSE must defeat affected cached
  dentries as part of the same oracle. Invalidation attempt and error counters
  are hard gates, not optional diagnostics.
- Controls: direct lower-filesystem `stat` and `readdir` measurements already
  emitted by each runner; invalid registered-target containment remains a
  correctness/safety control, not a performance baseline.
- Conclusion if FUSE matches or wins: the Agent workspace performance
  prediction is contradicted for the matched slice; the boundary argument must
  stand independently and no speedup may be claimed.
- Information, tuning, and compute fairness: both mechanisms receive the same
  base/upper objects, active epoch, trace, logical path set, operation counts,
  vCPU/memory allocation, TSC clocksource, and kernel build. Each mechanism
  runs alone in a fresh boot. Condition order alternates by repetition.

## Workloads And Metrics

- Real workload: the fixed AgentFS-derived base-to-upper workspace transition,
  whiteout, symlink, cached-negative creation, generated-file create/rename,
  unlink, final-tree check, and subsequent hot-path operations.
- Claim-matched primary metric: per-boot median of 20 complete
  cached-negative lookup, create, rename, and unlink lifecycle samples.
- Mechanism-decomposition metrics: per-boot median `stat`, `open`, `access`,
  and `readdir` latency. The report shows their paired ratios but does not
  require all four to support the lifecycle claim.
- Effect estimate: the median of ten paired FUSE/`namei_ext` per-boot median
  ratios, with a 95% bootstrap confidence interval.
- Secondary metrics: `exec` latency, p95/p99 operation latency, FUSE request
  counts, daemon CPU time, and voluntary/involuntary context switches.
- Correctness ground truth: every source-trace row; selected base/upper object
  content and metadata after the epoch change; whiteout; symlink;
  cached-negative lookup followed by create, stat, and read through the
  logical path; rename old-name absence and new-name visibility; unlink
  `ENOENT`; final tree; lower/base-object preservation; attachment/counter
  check; FUSE invalidation and permission-mode gates; and clean dmesg.
- Repetitions and uncertainty: one real two-boot preflight, then 10 independent
  repetition blocks with one `namei_ext` and one FUSE boot per block. Condition
  order alternates by block. Each boot records exactly 20 lifecycle, 100
  `stat`, 100 `open`, 100 `access`, 20 `exec`, and 50 `readdir` raw samples.
  The analysis resamples all ten boot pairs together 10,000 times with a fixed
  seed and recomputes the median paired ratio on each resample.
- Cost estimate: 20 formal KVM boots and less than 1 GB of run-local artifacts.

## Planned Runs

| Run group | Role | Workload | System/method | Repetitions | Decision consequence |
| --- | --- | --- | --- | ---: | --- |
| preflight | dependency | Full fixed trace and oracle | `namei_ext`, cached FUSE | 1 each | Establishes only that both real paths and artifacts work |
| main | proposed | Full fixed trace and operation samples | `namei_ext` | 10 boots | Supplies proposed-system correctness and timing |
| main | baseline | Identical trace, objects, and operation samples | cached feature-equivalent FUSE | 10 boots | Supplies the strongest matched competing result |
| control | lower-FS control | Direct base-object stat/readdir emitted in each boot | lower filesystem | 20 embedded rows | Detects gross boot/environment drift; not a headline baseline |

## Execution

- Authoritative workflow:
  `make experiment-agent-workspace-rq2 RUN_ID=<fresh-id>`.
- Real preflight:
  `make kvm-agent-workspace-rq2-preflight RUN_ID=<fresh-id>`.
- Full completion rule: exactly 20 completed boot directories, every declared
  condition/repetition key present once, all correctness rows true, every
  kernel and artifact identity verified, stable TSC, clean dmesg, complete raw
  samples, and a successfully regenerated analysis report.
- Raw-result paths:
  `results/experiments/agent-workspace-rq2-preflight/<RUN_ID>/` and
  `results/experiments/agent-workspace-rq2/<RUN_ID>/`.
- Checkpoint/recovery: each boot has an immutable directory and launcher logs,
  but a failed formal run is preserved and rerun under a new ID; partial
  prefixes are never analyzed as the experiment.

## Interpretation

- Positive result: both mechanisms pass and the lifecycle FUSE/`namei_ext`
  ratio exceeds one with a 95% confidence interval wholly above one.
- Negative or contradictory result: both mechanisms pass and the lifecycle
  interval is wholly below one.
- Inconclusive result: the lifecycle interval contains one or environmental
  variation invalidates pairing. This experiment does not use an equivalence
  margin, so an interval containing one is not evidence that the mechanisms
  match. Operation-level disagreement is reported as mechanism
  decomposition, not used to redefine the lifecycle result.
- Target paper figure: one compact forest plot of FUSE/`namei_ext` ratios for
  lifecycle, stat, open, access, and readdir, with 95% confidence intervals;
  one table row for correctness, FUSE requests/CPU, and operation counts.

## Reproducibility Notes

- Software and data versions are copied into `run.json`, `command.txt`,
  `inputs.sha256`, the run-local artifact manifest, per-boot kernel identity,
  and FUSE version records.
- The bootstrap seed is fixed in committed analysis code. Measurement
  collectors preserve raw samples and do not compute paper ratios.
- The existing lifecycle timer includes correctness-record emission and is not
  a paper metric. The formal runner uses a separate repeated lifecycle whose
  timed region contains only cached-negative lookup, create, rename, and
  unlink. Before and after every iteration it restores and verifies the same
  empty path state. Setup, reset, JSON writing, `fflush`, and oracle reporting
  occur outside the timer. Every raw elapsed value and operation error is
  recorded only after the timed region.
- The all-zero-timeout historical FUSE runs remain correctness evidence only
  and are not combined with this experiment.

## Source Trace Binding

Every trace phase records the fixed AgentFS commit, upstream file, and source
operation. The binding uses:

- `cli/tests/test-run-bash.sh` for sandbox create/read and host
  non-materialization;
- `cli/tests/test-run-git.sh` and
  `cli/tests/test-overlay-delta-in-base-dir.sh` for `.git`-visible base and
  per-agent changes;
- `cli/tests/test-overlay-whiteout.sh` for hidden lower objects and untouched
  base state;
- `cli/tests/test-symlinks.sh` for lower and sandbox-created symlink behavior;
- `cli/tests/test-fuse-cache-invalidation.sh` for cached-negative create,
  rename, unlink, and subsequent `stat`/`readdir` visibility.

These bindings establish source provenance for the reduced path-view slice.
They do not claim a full AgentFS reimplementation.

## Primary References

- AgentFS fixed source:
  `https://github.com/tursodatabase/agentfs/tree/0a014ebd4918615baff589ed17486e557e7c6a23`
- Libfuse 3.14.0:
  `https://github.com/libfuse/libfuse/tree/fuse-3.14.0`
- Libfuse invalidation API:
  `https://github.com/libfuse/libfuse/blob/fuse-3.14.0/include/fuse.h`
