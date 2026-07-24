# Experiment Plan: RQ1/RQ2 Build/Cache Real Compile Epoch Switch

Date: 2026-07-24
Status: implementation plan for Experiment B extension

## Research Question

- RQ exactly as written in the paper: RQ1 asks whether a narrow VFS
  name-resolution extension can express real state-dependent path-view policies
  without taking over filesystem semantics. RQ2 asks what the cost is compared
  with a feature-equivalent FUSE policy implementation.
- Specific uncertainty tested here: whether the existing Redis/nginx ccache
  compile oracle still passes when the cache-object view changes from one
  lookup-time epoch to another during the same KVM run.
- Why the answer matters: the current release row covers real verified hot-cache
  compiles and a separate trace-derived lookup/readdir state row. This extension
  connects the state transition to real compiler output without reviving
  table-only or materialization as the paper story.

## Paper-Value Admission

- Planned role: supporting extension to decisive Experiment B.
- Largest credible paper story this experiment could unlock: build/cache is not
  only a static hot-cache redirect; the real compile path can observe a
  stateful name-resolution policy update and still pass the source output
  oracle while lower filesystem and ccache semantics remain owned outside BPF.
- Strongest reviewer reject argument or load-bearing uncertainty addressed:
  the current state row is only lookup/readdir over ccache-derived object names,
  so a reviewer can say it is disconnected from real compiler behavior.
- Independent evidence added beyond existing runs and published results: the
  same Redis/nginx source manifest and hot-object oracle are compiled twice
  under a live `cache_locality_epoch` BPF program, with an epoch-session update
  between rounds, plus a matched FUSE cache-view update for the same oracle.
- Why the result is not tautological, already settled, or dominated: success is
  gated by real ccache direct-hit compiles, output-object equality, strace cache
  object engagement, cgroup/namei_ext KVM attach, and the FUSE matched row.
- Paper decision if positive: Experiment B can claim real compiler-output
  coverage for the epoch-switch transition in addition to verified hot-cache
  object selection.
- Paper decision if contradictory, mixed, or inconclusive: if output equality or
  direct-hit evidence fails, the build/cache state-machine claim remains limited
  to the existing hot-cache compile and trace-derived state row.
- Best alternative experiment and why this one has higher decision value:
  service/config or checkpoint/remap would add breadth, but this repairs the
  strongest known gap in the already-admitted traditional workload.

## Expected And Alternative Outcomes

- Current expected answer: both `namei_ext` and feature-equivalent FUSE pass
  epoch1 and epoch2 real ccache compiles; `namei_ext` changes state with a
  session update while FUSE changes state by updating daemon/backing-file state.
- Strongest competing explanation: the compile still succeeds because ccache
  never exercises the redirected objects after the epoch switch.
- Result that would contradict the expectation: direct-hit counts or strace
  object operations do not cover the source manifest after the epoch switch, or
  output objects diverge from the hot native baseline.

## Published Precedent And Real Assets

- Closest published protocol: build-cache and FUSE filesystem evaluations using
  real application compile workloads and cache hit/miss counters.
- Official system/model/data/benchmark/tool and version: repository Redis/nginx
  source trees, `ccache`, `strace`, libfuse, and the modified Phase 1 kernel.
- What is reused: W4 bulk trace, policy bridge, `cache_locality_epoch` policy
  rules, bulk ccache source manifest, hot output directory, and existing FUSE
  cache-view daemon.
- Necessary deviations or custom glue: a new Make-owned runner creates two
  backing names for each visible ccache object, compiles under epoch 1, updates
  the policy session or FUSE backing state, then compiles under epoch 2.

## Comparison

- Proposed system or method: `cache_locality_view.bpf.c` loaded as
  `cache_locality_epoch` through the real KVM `cgroup/namei_ext` attach path.
- Main baselines and the competing position each represents:
  feature-equivalent FUSE cache view represents the filesystem-daemon
  alternative for the same path-policy transition.
- Why each main baseline needs a matched run instead of citation alone: RQ2 is
  about this exact ccache/source/object oracle and policy update path.
- Controls or ablations, labeled separately: native hot ccache output objects
  remain the correctness oracle/control and are not a policy baseline.
- Conclusion if each main baseline matches or wins: if FUSE matches or wins,
  RQ2 is narrowed to boundary and ownership value for this workload.
- Information, tuning, and compute fairness: both systems use the same source
  manifest, trace-derived cache objects, hot output baseline, sample count, and
  KVM kernel.

## Workloads And Metrics

- Real workloads or tasks: Redis and nginx C source compiles through ccache.
- Primary metrics: epoch1/epoch2 compile success, output-object equality,
  ccache direct hits, cache-path file operations, cache-object operations,
  compile runtime, policy session updates, FUSE mount/update count, and dmesg
  gate.
- Correctness check or ground truth: every epoch output object must match the
  hot native ccache object for the same source; both systems must show direct
  cache-hit evidence for both epochs.
- Repetitions, seeds, and uncertainty: default full run uses
  `BUILD_CACHE_SAMPLES`; the first real preflight uses one sample.
- Cost estimate when material: one sample performs two compile rounds for
  `namei_ext` and two compile rounds for FUSE over the fixed source manifest.

## Planned Runs

| Run group | Role | Workload | System/method | Repetitions | Decision consequence |
|---|---|---|---|---:|---|
| main | proposed | Redis/nginx ccache compile, epoch1 then epoch2 | `namei_ext` `cache_locality_epoch` | `BUILD_CACHE_SAMPLES` | Supports real epoch-switch compiler-output coverage only if both epochs pass output and direct-hit gates. |
| main | baseline | same source manifest and backing objects | feature-equivalent FUSE cache view | `BUILD_CACHE_SAMPLES` | Supports RQ2 comparison only if the same oracle passes and FUSE update/mount engagement is recorded. |
| control | oracle | hot output objects from existing trace | native hot ccache | inherited | Supplies output equality target, not a policy baseline. |

## Execution

- Authoritative command or workflow: new Make target integrated under
  `make experiment-env-cache` after the policy bridge and before release
  interpretation.
- Real preflight case: run the new KVM target with one sample against the
  existing bulk trace and policy bridge.
- Full completion rule: summary row passes for all samples; both
  `namei_ext` and FUSE have epoch1 and epoch2 compile jobs equal to the source
  count, output matches equal jobs, direct-hit evidence for both epochs, and a
  clean dmesg gate.
- Raw-result path: `results/phase1/<RUN_ID>/w4-ccache-bulk-compile-epoch-switch.jsonl`,
  then copied into `results/experiments/build-cache/<RUN_ID>/` when integrated.
- Checkpoint or recovery approach: all raw output, strace logs, ccache logs, and
  SHA files stay under the Phase 1 result root and build-cache result root.

## Interpretation

- Positive result: Experiment B can say the real compile path has covered
  epoch-switch object selection, while still leaving miss/stale/corrupt compile
  cells open.
- Negative or contradictory result: the broad state-machine claim remains
  limited; the failed row is recorded as an implementation or workload-boundary
  issue, not as a reason to weaken the hypothesis.
- Mixed or inconclusive result: passing one mechanism without matched FUSE, or
  passing output equality without direct-hit/object-operation evidence, is
  implementation evidence only.
- Target paper figure or table: add one row to the build/cache correctness and
  mechanism table: "real compile epoch switch".

## Reproducibility Notes

- Software and data versions: captured by ccache version, source manifest,
  kernel config, input SHA files, command record, and dmesg logs.
- Config and seed notes: no random seed; sample count is controlled by Make.
- Known deviations: this plan does not claim real compiler-output coverage for
  miss, stale, or corrupt rejection. Those remain P2.
