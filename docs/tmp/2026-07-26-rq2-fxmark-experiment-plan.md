# Experiment Plan: RQ2 FxMark Path-Resolution Cost

## Research Question

- RQ exactly as written in the paper: What is the cost of putting programmable
  policy on the VFS name-resolution path compared with a feature-equivalent
  FUSE policy implementation?
- Specific uncertainty tested here: whether the patched kernel imposes a
  measurable cost when no policy is attached, what one attached policy
  invocation and one same-filesystem `SELECT` cost, and whether those paths
  retain more path-resolution throughput than a correctly cached,
  feature-equivalent FUSE passthrough view.
- Why the answer matters: an unattractive unattached fast path is a kernel
  integration objection, while a comparison only against an intentionally
  uncached or single-threaded FUSE daemon would not establish a credible RQ2
  result.

## Paper-Value Admission

- Planned role: decisive.
- Largest credible paper story this experiment could unlock: the extension has
  negligible cost for workloads that do not use it, exposes the incremental
  cost of `PASS` and `SELECT`, and avoids the userspace-filesystem request path
  of an optimized FUSE implementation for the same existing-object view.
- Strongest reviewer reject argument or load-bearing uncertainty addressed:
  the existing compile macrobenchmark is compiler-bound, lacks a matched stock
  kernel, and may compare against a weak FUSE setup; it cannot establish VFS
  fast-path cost.
- Independent evidence added beyond existing runs and published results: a
  matched stock/patched kernel comparison and a standard, lookup-intensive
  benchmark matrix on the real KVM attach path.
- Why the result is not tautological, already settled, or dominated: published
  FxMark and FUSE results do not measure this kernel patch, BPF policy, target
  registry, or matched feature-equivalent implementation.
- Paper decision if positive: use this as the primary RQ2 path-resolution
  result and retain compile time only as macro corroboration.
- Paper decision if contradictory, mixed, or inconclusive: keep the measured
  cost, identify whether it comes from the patched fast path, BPF invocation,
  target selection, or FUSE comparison, and redesign the affected mechanism
  before rerunning the same matrix. Do not weaken RQ2 to fit the result.
- Best alternative experiment and why this one has higher decision value:
  mdtest or Filebench would broaden operation mix, but neither answers the
  maintainer-critical unattached path question as directly as FxMark's
  lookup-intensive tests.

## Expected And Alternative Outcomes

- Current expected answer: patched-unattached throughput remains within a
  small practical margin of matched stock; `PASS` and `SELECT` have bounded
  incremental costs; optimized FUSE retains less throughput for the same
  cache-hot pathname workload.
- Strongest competing explanation: the new hook changes the common path enough
  to hurt unattached workloads, or FUSE entry/attribute caching removes most
  daemon interaction and matches `namei_ext` for cache-hot `stat()`.
- Result that would contradict the expectation: patched-unattached has a
  reproducible overhead above the declared margin, or optimized FUSE matches
  or exceeds `SELECT` while satisfying the same correctness and mechanism
  engagement checks.

## Published Precedent And Real Assets

- Closest published protocol: Min et al., "Understanding Manycore Scalability
  of File Systems," USENIX ATC 2016, and its official FxMark repository.
- Official system/model/data/benchmark/tool and version: FxMark commit
  `3f29552ce7ba6be24c4172e6e2c2c1f603209953`, archive SHA-256
  `b8887b7ef5fe9cedaeed35ab12801aa8b7534d9e16ec40124af788dfd85f46ae`.
- What is reused: official `fxmark`, `bench`, utility, and
  `MRPL`/`MRPM`/`MRPH` C sources; works/second reporting; 30-second measured
  duration; per-worker CPU affinity; and tmpfs as a VFS upper-bound medium.
- Necessary deviations or custom glue: upstream topology generation requires
  Python 2 and host `sudo`, so the build adapter supplies a four-vCPU
  `cpupol.h` without changing benchmark operations. The repository version's
  three selected tests execute `stat()`, although the 2016 paper describes
  path-resolution tests using open/close; results are explicitly scoped to the
  pinned source behavior. A minimal recorded correctness patch makes affinity,
  fork, pre-work, and worker errors terminate the benchmark instead of being
  silently reported as success; it does not change a successful measured
  operation. A driver creates cgroups/views, invokes the patched official
  binary with a hard timeout, verifies the FxMark leader's exact cgroup
  membership before timing, checks the attached BPF program ID before and after
  each attached cell, checks exact tree cardinality, and records raw JSONL. A
  passthrough FUSE implementation supplies the competing view.

## Comparison

- Proposed system or method: patched kernel with a cgroup-attached
  `namei_ext` policy selecting a pre-registered existing tmpfs directory.
- Main baseline and the competing position it represents: optimized
  feature-equivalent FUSE passthrough, representing the current expressive
  userspace-filesystem solution. It runs multithreaded with
  `default_permissions`, `kernel_cache`, and one-hour entry, attribute, and
  negative-cache timeouts. Its daemon may run on all four guest vCPUs.
- Why the main baseline needs a matched run instead of citation alone: FUSE
  cost depends on kernel version, cache options, operation stream, lower
  filesystem, daemon implementation, and VM resources; no published number
  matches this policy and environment.
- Controls or ablations, labeled separately:
  - matched stock kernel is the null/lower-bound control;
  - patched-unattached isolates the globally visible patch fast path;
  - attached `PASS` isolates BPF invocation without object selection.
- Conclusion if the main baseline matches or wins: the experiment does not
  support a path-resolution performance advantage over FUSE for this
  cache-hot existing-directory view, even if other ownership or failure-domain
  arguments remain.
- Information, tuning, and compute fairness: all conditions use the same
  1-GiB tmpfs lower store, path depth, benchmark source and duration. FxMark
  workers use vCPUs `0..n-1` in a fixed four-vCPU guest; this is worker scaling,
  not vCPU scaling. The FUSE daemon may use all four guest vCPUs, including
  otherwise idle vCPUs at one and two workers, which favors the baseline rather
  than the proposed mechanism. Both mechanisms know only the same logical-view
  to existing-directory mapping. The FUSE row uses stable-policy caching
  intentionally; measured-phase request counters may be zero when the kernel
  cache serves every `stat()`, but setup request counters and the mount identity
  must prove that the FUSE view was used.
- Split or leakage rule when relevant: no data-dependent tuning. FUSE options,
  condition order, correctness gates, and interpretation thresholds are fixed
  before preflight.

## Workloads And Metrics

- Real workloads or tasks: official FxMark `MRPL` (private five-component
  paths), `MRPM` (random files in a five-level, eight-way tree), and `MRPH`
  (one shared five-level path), using 1, 2, and 4 foreground workers.
- Primary metric: official FxMark aggregate works/second. Report normalized
  throughput versus matched stock and the direct `SELECT`/FUSE throughput
  ratio.
- Secondary measurements: FUSE daemon CPU/resource use and operation request
  counts, attached BPF program IDs, raw FxMark-leader cgroup membership, and
  guest CPU snapshots around each cell. FxMark forks workers without reaping
  them, so a parent `wait4` record does not cover all clients and is not used as
  a paper metric.
- Correctness check or ground truth: every process exits zero; FxMark reports
  the requested worker count, at least 90% of the requested measured duration,
  and finite positive work. The correctness-patched binary propagates every
  worker and affinity failure. `MRPL` produces exactly one file and four
  directories per worker; `MRPM`/`MRPH` produce exactly 32,768 files and 4,681
  directories below the benchmark root. Before FxMark starts, its stopped
  leader must be recorded in and verified against the exact experiment cgroup;
  workers inherit that membership. Attached cells must report the same queried
  BPF program ID before and after measurement. The logical `view` component in
  a `SELECT` cell does not exist in the physical upper tree, so completing the
  full-duration `stat()` workload through that path and matching the lower-tree
  oracle requires the registered selection action. FUSE must record setup
  requests and a FUSE mount identity; measured daemon requests may be zero with
  valid caching. Each cell has a hard timeout, and dmesg contains no declared
  failure signature.
- Repetitions, seeds, and uncertainty: ten independent KVM boots. Report median
  and a paired nonparametric 95% bootstrap confidence interval across ten
  five-condition boot blocks for each cell, using committed analysis seed
  `20260726`. `MRPM` retains the source's deterministic pseudo-random sequence.
- Cost estimate when material: 450 measured cells at 30 seconds each, 3.75
  hours of timed workload plus large-tree setup and 50 VM boots. The observed
  setup/boot cost implies roughly 7--9 hours of wall time.

## Planned Runs

| Run group | Role | Workload | System/method | Repetitions | Decision consequence |
|---|---|---|---|---:|---|
| control | null control | MRPL/MRPM/MRPH, 1/2/4 workers | matched stock kernel | 10 fresh boots | Defines unmodified throughput |
| control | patch fast-path control | same matrix | patched, no attached policy | 10 fresh boots | Tests globally visible patch cost |
| ablation | invocation control | same matrix | patched, attached `PASS` | 10 fresh boots | Isolates BPF invocation |
| main | proposed | same matrix | patched, same-filesystem directory `SELECT` | 10 fresh boots | Measures complete proposed lookup action |
| main | external baseline | same matrix | optimized feature-equivalent FUSE on matched stock | 10 fresh boots | Tests the strongest matched userspace-FS alternative |

One repetition is a block of five fresh boots, one per condition. The condition
order rotates as a predeclared five-way Latin square across blocks. Every boot
runs nine cells, with identical workload and worker-count order. No policy is
attached before or after the measured condition in an unattached or FUSE boot,
so the system-wide cgroup-BPF static key cannot contaminate those controls.

## Execution

- Authoritative command or workflow: `make kvm-fxmark-rq2`.
- Real preflight case: `make kvm-fxmark-rq2-preflight`, running `MRPL`, one
  worker, two seconds, once under six fresh boots using the actual stock image
  for stock/FUSE and the patched image for unattached/empty/PASS/SELECT.
- Full completion rule: all 450 planned observations and 50 boot records exist;
  all correctness and engagement gates pass; every raw stdout/stderr, kernel
  config, dmesg, source/artifact hash, command record, and resource record is
  present; every boot uses the immutable run-local artifact snapshot; the
  analysis target reads the formal matrix from `run.json` and recomputes every
  reported value from raw data.
- Raw-result path: `results/experiments/fxmark-rq2/<RUN_ID>/`.
- Checkpoint or recovery approach: one immutable result directory per full run,
  with one raw file per boot and condition. A failed or interrupted full run
  remains preserved and is not interpreted as complete; affected cells rerun
  under a new run ID.

## Interpretation

- Positive result: patched-unattached median throughput is no more than 2%
  below stock and the lower end of normalized throughput's 95% confidence
  interval is at least 0.97 in all nine cells; `SELECT` exceeds optimized FUSE
  in all nine cells with each bootstrap confidence interval for the
  `SELECT`/FUSE ratio above 1; all correctness and engagement checks pass.
- Negative or contradictory result: any correctness/fairness failure
  invalidates the affected comparison. Otherwise a reproducible
  patched-unattached cost outside the declared bound contradicts the fast-path
  expectation; FUSE matching or winning any cell contradicts a uniform
  performance-advantage claim and bounds RQ2 to the observed operation/scale
  region.
- Mixed or inconclusive result: confidence intervals crossing either declared
  boundary, or advantages that depend on operation/core count, are reported as
  a scaling-dependent result rather than collapsed into one ratio.
- Target paper figure or table: three panels (`MRPL`, `MRPM`, `MRPH`) showing
  works/second versus worker count for all five conditions, plus a compact
  table of patched-unattached normalized throughput, `SELECT`/FUSE ratio,
  daemon CPU, and mechanism-engagement evidence.

## Reproducibility Notes

- Software and data versions: FxMark commit and archive hash above; the
  post-mechanism-repair rerun uses patched kernel commit
  `bdc9a83e3dfbef8ff2017f9188c7c86025962183`;
  matched stock ancestor `062871f1371b2e02a272ff5279c6479aff0a37ef`.
- Config and seed notes: four-vCPU, 8-GiB KVM guest; identical committed kernel
  config except that stock omits `CONFIG_NAMEI_EXT`, enforced before execution;
  each five-boot block shares one repetition ID; 1-GiB tmpfs mounted `noatime`;
  guest TSC is marked reliable and remote-clocksource watchdog timeouts are a
  hard dmesg failure; `current_clocksource` must remain `tsc`; official
  deterministic benchmark sequence; 30-second
  duration; BPF run-time statistics accounting disabled; bootstrap seed
  `20260726`. Every patched guest release must contain
  the recorded kernel commit and must not contain `-dirty`; the linked libfuse
  version is recorded with the run.
  Both kernel identities and all measured binaries/policies are frozen under
  the result root before the first boot and rehashed at finalization.
- Known deviations: source-version `stat()` semantics and build-only CPU-policy
  adapter described above. Cache-cold path walks, directory enumeration,
  mdtest, Filebench, and perf hardware counters are not part of this experiment
  and cannot be inferred from it.
