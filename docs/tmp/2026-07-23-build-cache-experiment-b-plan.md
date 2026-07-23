# Experiment Plan: RQ1/RQ2 Traditional Build/Cache

## Research Question

- RQ exactly as written in the paper: RQ1 asks whether a narrow VFS
  name-resolution extension can express real state-dependent path-view policies
  without taking over filesystem semantics. RQ2 asks what the cost is compared
  with a feature-equivalent FUSE policy implementation.
- Specific uncertainty tested here: whether the traditional ccache build/cache
  workload can run through the real KVM `cgroup/namei_ext` attach path and pass
  the same object-output oracle as a FUSE cache-view implementation.
- Why the answer matters: this is the decisive non-agent workload. A passing
  run shows the paper is not only an agent-workspace story.

## Paper-Value Admission

- Planned role: decisive.
- Largest credible paper story this experiment could unlock: `namei_ext`
  expresses traditional build/cache cache-object selection with lower-FS
  ownership preserved, while avoiding a FUSE daemon owning filesystem methods
  for the same path-policy behavior.
- Strongest reviewer reject argument or load-bearing uncertainty addressed:
  build caches and FUSE cache views already exist, so the proposed VFS boundary
  must show a real build/cache oracle, not a toy metadata benchmark.
- Independent evidence added beyond existing runs and published results: the
  run executes Redis/nginx ccache hot compiles under the modified kernel, an
  attached `cache_locality_view.bpf.c` policy, and a compile-through-FUSE
  baseline with output-object equality and operation traces.
- Why the result is not tautological, already settled, or dominated: success is
  gated by real ccache compile success, output object hash equality, cache-path
  file-operation traces, policy/FUSE mechanism engagement, and KVM dmesg gates.
- Paper decision if positive: Experiment B becomes the main non-agent evidence
  for RQ1 and the primary RQ2 comparison against FUSE.
- Paper decision if contradictory, mixed, or inconclusive: if the ccache oracle
  fails under `namei_ext`, the workload needs a broader cache/filesystem owner
  than name resolution. If FUSE passes and is not materially more expensive,
  RQ2 is bounded by this workload rather than turned into a performance win.
- Best alternative experiment and why this one has higher decision value:
  a synthetic hit/miss/stale/corrupt header-selection project would cover more
  labels, but Redis/nginx ccache is a stronger traditional workload and already
  has source, cache, strace, FUSE, native, and output-oracle assets.

## Expected And Alternative Outcomes

- Current expected answer: `namei_ext` can run the ccache cache-object path
  policy under KVM and produce output objects identical to native hot ccache,
  while FUSE also passes but pays the cost of a filesystem daemon boundary.
- Strongest competing explanation: the important behavior is ccache's own cache
  service and not the VFS path-policy boundary.
- Result that would contradict the expectation: attached policy compiles do not
  hit redirected cache objects, output objects diverge from the hot baseline, or
  the FUSE baseline is the only feature-equivalent mechanism that passes.

## Published Precedent And Real Assets

- Closest published protocol: build-cache and FUSE filesystem evaluations that
  use real application compiles and cache hit/miss counters rather than generic
  metadata loops.
- Official system/model/data/benchmark/tool and version: local Redis and nginx
  source trees already used by the repository workload targets, `ccache`,
  `strace`, libfuse, and the modified Phase 1 kernel.
- What is reused: existing Make-owned W4 bulk ccache trace, policy-bridge,
  policy-attached compile, native compile, and FUSE compile targets.
- Necessary deviations or custom glue: current paper-facing target
  `experiment-env-cache` collects and validates the non-table subset as
  Experiment B under `results/experiments/build-cache/<RUN_ID>/`.

## Comparison

- Proposed system or method: `cache_locality_view.bpf.c` attached through
  `cgroup/namei_ext` in KVM.
- Main baselines and the competing position each represents: feature-equivalent
  FUSE compile-through cache view represents the filesystem-daemon alternative
  for the same path-policy view.
- Why each main baseline needs a matched run instead of citation alone: RQ2 is
  about the measured cost and mechanism engagement of this exact policy and
  oracle; FUSE performance literature cannot substitute for the matched
  Redis/nginx ccache run.
- Controls or ablations, labeled separately: native hot ccache compile is an
  oracle/control row, not a competing policy mechanism.
- Conclusion if each main baseline matches or wins: if FUSE matches or wins
  under the same oracle and fair cache configuration, the performance claim is
  narrowed to boundary value rather than speed.
- Information, tuning, and compute fairness: all rows use the same source
  manifest, trace-derived cache objects, hot baseline objects, sample count, and
  KVM kernel; FUSE uses the repository's feature-equivalent compile-through
  cache view.
- Split or leakage rule when relevant: no training/evaluation split applies;
  the trace-derived cache object list is recorded and hashed before policy and
  baseline compile rows consume it.

## Workloads And Metrics

- Real workloads or tasks: Redis and nginx C source compiles through ccache.
- Primary metrics: compile success, output-object equality, compile runtime,
  cache-path file operations, policy/FUSE cache-object operations,
  operation-weighted hit rate, FUSE mount count, ccache direct hits, dmesg gate.
- Correctness check or ground truth: each policy/FUSE/native output object must
  match the hot native ccache object for the same source; all declared summary
  rows must pass with zero failures.
- Repetitions, seeds, and uncertainty: release runs use
  `BUILD_CACHE_SAMPLES` samples, defaulting to 20 unless overridden.
- Cost estimate when material: one full run executes 20 Redis/nginx source rows
  across policy, native, and FUSE compile groups for each sample.

## Planned Runs

| Run group | Role | Workload | System/method | Repetitions | Decision consequence |
|---|---|---|---|---:|---|
| main | proposed | Redis/nginx ccache hot compile | `namei_ext` `cache_locality_view.bpf.c` | `BUILD_CACHE_SAMPLES` | Supports RQ1 only if output equality, object redirection, op traces, and KVM gates pass. |
| main | baseline | same source manifest and cache objects | feature-equivalent FUSE cache view | `BUILD_CACHE_SAMPLES` | Supports RQ2 only if the same oracle passes and FUSE mechanism engagement is recorded. |
| control | oracle | same source manifest and cache objects | native hot ccache | `BUILD_CACHE_SAMPLES` | Establishes source/cache oracle and lower-bound runtime; not a policy baseline. |
| boundary | RQ3 support | same behavior | boundary evidence rows | 1 | Records daemon, FS method, data-path, and lower-FS ownership differences. |

## Execution

- Authoritative command or workflow: `make experiment-env-cache`.
- Real preflight case: the existing trace and policy-bridge prerequisites must
  pass before policy, native, and FUSE compile rows run.
- Full completion rule: every summary row for policy, native, and FUSE passes;
  the collector writes a build-cache matrix JSONL, input hash file, command
  file, copied raw JSONLs, and boundary rows; every dmesg scan passes.
- Raw-result path: `results/experiments/build-cache/<RUN_ID>/`.
- Checkpoint or recovery approach: the underlying raw W4 bulk result root stays
  under `results/phase1/<RUN_ID>/`; the Experiment B root records hashes and
  copies the paper-facing JSONLs for review.

## Interpretation

- Positive result: Redis/nginx ccache compiles pass under attached `namei_ext`
  policy, native, and FUSE; output hashes match; operation traces show cache
  object operations; FUSE has a filesystem-daemon boundary for the same oracle.
- Negative or contradictory result: any failed oracle row, missing mechanism
  engagement, missing dmesg gate, or missing FUSE parity blocks paper claims.
- Mixed or inconclusive result: passing policy without FUSE, or compile success
  without operation traces, is implementation evidence only.
- Target paper figure or table: one build/cache correctness and mechanism
  table, one RQ2 overhead table versus FUSE, and one boundary table.

## Reproducibility Notes

- Software and data versions: captured in the experiment command file, ccache
  version files, source manifest, input SHA files, kernel config, and dmesg logs.
- Config and seed notes: default sample count is `BUILD_CACHE_SAMPLES=20`.
- Known deviations: this admitted run focuses on real verified-hit ccache hot
  compiles. The broader hit/miss/stale/corrupt/epoch state labels remain part
  of the design scope, but this run is the paper-facing real-workload row.
