# Environment/Cache Complete Experiment Plan

Date: 2026-07-13
Status: planned complete experiment; not yet implemented or run

## Research Question

- RQ exactly as written in the paper: RQ1 asks whether a narrow VFS
  name-resolution extension can express real state-dependent path-view policies
  without taking over filesystem semantics. RQ2 asks what the VFS policy path
  costs compared with a feature-equivalent FUSE policy. RQ3 asks whether the
  boundary is narrower and safer than a custom or stackable filesystem when the
  needed policy is only name resolution.
- Specific uncertainty tested here: whether a build/test environment can use
  lookup-time policy to select verified local cache objects, canonical backing
  objects, or absence for stale/corrupt objects while preserving the source
  evaluator and lower-filesystem data semantics.
- Why the answer matters: this is the decisive non-agent workload family. It
  tests whether the `sched_ext`-style VFS extension point is useful beyond agent
  workspaces and whether the mechanism can cover cache/environment state without
  becoming a FUSE/custom filesystem.

## Paper-Value Admission

- Planned role: decisive.
- Largest credible paper story this experiment could unlock: `namei_ext`
  supports source-derived build/test environment path-view transitions, not just
  agent workspace views, while staying in the middle point
  bind/Overlay/materialization < eBPF LSM < `namei_ext` < FUSE/custom FS.
- Strongest reviewer reject argument or load-bearing uncertainty addressed:
  cache and environment systems already have native mechanisms, FUSE wrappers,
  and materialized directories; a VFS name-resolution hook must show that it can
  satisfy the same build/test oracle with lower policy-path cost than FUSE and
  less filesystem ownership than a custom filesystem.
- Independent evidence added beyond existing runs and published results:
  selected source evaluators already establish real task oracles, but they do
  not run the cache-state policy through the modified-kernel
  `cgroup/namei_ext` attach path or compare the same policy against FUSE.
- Why the result is not tautological, already settled, or dominated: success
  requires the unchanged source build/test oracle, stale/corrupt rejection,
  operation-weighted lookup/readdir traces, and a feature-equivalent FUSE
  comparison. A ccache smoke, Docker image replay, or source evaluator pass
  alone would remain dependency work.
- Paper decision if positive: Experiment B becomes the decisive evidence that
  the abstraction is not agent-specific; the paper can report RQ1
  expressiveness on environment/cache state and RQ2 overhead versus FUSE.
- Paper decision if contradictory, mixed, or inconclusive: if the source oracle
  requires synthetic contents, data-path mediation, custom metadata
  persistence, or cache-coherence ownership, the workload belongs to FUSE/custom
  FS or native environment tooling; if only FUSE is incomplete or unfair, rerun
  the comparison rather than count a `namei_ext` win.
- Best alternative experiment and why this one has higher decision value:
  adding a service/config breadth row is weaker until a concrete source oracle
  is selected. Environment/cache is higher value because reproduced
  SWE-Factory-Gym, MEnvData-SWE, and SWE-rebench V2 rows already provide
  executable build/test oracles.

## Expected And Alternative Outcomes

- Current expected answer: for a fixed suite of clean source rows,
  `namei_ext` can express cache hit, miss, stale, corrupt, and epoch-update
  path selection using bounded lookup/readdir policy and registered targets,
  while the lower filesystem owns file data and writes.
- Strongest competing explanation: the useful behavior is really cache-service
  or environment-builder ownership, not name-resolution policy; a FUSE daemon or
  custom filesystem may be necessary to own metadata, writes, or validation.
- Result that would contradict the expectation: the same build/test oracle
  cannot pass without synthesizing file contents, mediating post-open reads or
  writes, persisting custom cache metadata in the hook, or moving evaluator
  logic into a filesystem service.

## Published Precedent And Real Assets

- Closest published protocol: SWE-Factory-Gym, MEnvData-SWE, and SWE-rebench V2
  source evaluators; ccache/BuildKit-style cache traces for real build cache
  pressure; FUSE studies and ExtFUSE for filesystem-service comparison
  methodology.
- Official system/model/data/benchmark/tool and version: choose the final suite
  before the run from reproduced rows already indexed in
  `docs/background-related-work.md` and `docs/reference/CODE_SOURCES.md`.
- What is reused: official repository/task inputs, Docker or image/eval rows,
  eval scripts, test patches, source oracle reports, and clean raw-result
  candidates.
- Necessary deviations or custom glue: the cache-policy layer is the
  experimental mechanism. It may wrap cache directory selection and
  instrumentation, but it must not weaken or replace the source build/test
  oracle.

## Candidate Workload Suite

Primary source candidates:

- MEnvData-SWE rows with clean selected reproductions across languages, using
  exact image/eval row metadata and raw logs from the dated records.
- SWE-Factory-Gym rows with released Dockerfiles, eval scripts, gold patches,
  `OMNIGRIL_EXIT_CODE=0`, and resolved reports.
- SWE-rebench V2 clean raw-exit rows with official evaluator reports.

Pre-register one small but real suite before the full run. A starting suite is:

| Source family | Candidate row | Why useful |
| --- | --- | --- |
| MEnvData-SWE | `python-attrs__attrs-586` | clean Python image/eval oracle and small preflight candidate |
| MEnvData-SWE | `go-task__task-1814` | clean Go image/eval oracle |
| MEnvData-SWE | `sindresorhus__type-fest-818` | TypeScript row that closed a prior artifact gap |
| MEnvData-SWE | `CLIUtils__CLI11-926` | C++ row that closed a prior artifact gap |
| MEnvData-SWE | `cobalt-org__liquid-rust-403` | Rust row that closed a prior artifact gap |
| SWE-Factory-Gym | `pallets__click-2622` | released Docker/eval row with resolved report |

The final suite may replace a row only before preflight if KVM/Docker
compatibility blocks the authoritative source evaluator. Replacing rows after
seeing policy results is a plan deviation and reruns the affected comparison
matrix.

## Path-View Admission

A source row is not admitted merely because its Docker image or build/test
oracle works. Before the full run, preflight must produce a
`path-view-manifest.jsonl` for each admitted row with:

- the logical path prefix where the build/test command observes the policy;
- the exact verified-local, canonical-backing, stale, and corrupt objects;
- trace evidence that the source evaluator opened, stated, executed, or
  enumerated those paths during the oracle run;
- the cache-state transition sequence and epoch labels;
- the oracle evidence proving stale or corrupt objects were not consumed;
- the lower-FS paths that remain responsible for data, writes, permissions,
  page cache, and persistence.

If no candidate row yields this manifest, the row is dependency-only source
reproduction and cannot appear in the paper-result matrix.

## Policy State Machine

The workload exposes a logical cache/environment namespace used by the build or
test command. The exact path prefix is an implementation detail, but the policy
state machine is fixed:

| State | Policy decision | Correctness oracle |
| --- | --- | --- |
| hit | select verified local cache target | build/test output hash and source oracle match canonical run |
| miss | select canonical backing target | source oracle passes without reading unverified local object |
| stale | hide or reject stale local target, then select canonical target | stale object is not read; source oracle passes |
| corrupt | hide or reject corrupt local target, then select canonical target | corrupt object is not read; source oracle passes |
| epoch update | switch registered target or policy state for the next epoch | old epoch does not leak into new source oracle |

The state machine must be implemented with bounded `namei_ext` actions. If the
admitted oracle requires final-object target selection or synthetic directory
aliases, those actions must be implemented and KVM-validated before this
experiment can count as a paper result.

## Comparison

- Proposed system or method: `namei_ext` policy in KVM, attached through the
  real `cgroup/namei_ext` path, implementing the fixed cache state machine.
- Main baseline for RQ2: feature-equivalent FUSE policy with the same state
  machine, same path prefix, same source inputs, same build/test oracle, and
  equal information about cache validity and epochs.
- Main RQ3 comparison: source-backed custom/stackable filesystem boundary
  evidence for the same policy responsibilities: required methods, daemon or
  privileged code surface, state ownership, invalid-policy containment, and
  data/write-path responsibilities.
- Controls or ablations: native source evaluator or no-policy lower-FS run for
  correctness and lower-bound overhead; invalid-policy control for malformed
  target IDs, stale registrations, unsupported final-object selection, and
  corrupt object visibility.
- Not main baselines: copy/symlink/bind/Overlay/projected views and exact-table
  diagnostics. These are related-work/background mechanisms unless they change
  an RQ under the same oracle.
- Conclusion if FUSE matches or wins: RQ2 cost is contradicted or bounded for
  this workload, but RQ3 may still report narrower ownership if the boundary
  evidence is strong.
- Information, tuning, and compute fairness: `namei_ext` and FUSE receive the
  same cache-validity labels, epoch changes, warmup policy, row suite, and
  repetition count.

## Workloads And Metrics

- Real workloads or tasks: the pre-registered source row suite plus one
  preflight row.
- Primary correctness metrics: source evaluator pass/fail, output/test oracle,
  output hash or manifest where available, stale/corrupt object non-use,
  cache-state transition log, and lower-FS preservation checks.
- Primary performance metrics: lookup/open/stat/access/exec/readdir latency,
  macro build/test runtime, operation-weighted policy invocation rate, FUSE
  request count, FUSE daemon CPU/context-switch cost, and action-specific
  overhead for hit/miss/stale/corrupt/epoch cases.
- Repetitions and uncertainty: at least one correctness run per state per row;
  performance rows need enough repetitions to report median and dispersion
  before numbers appear in the paper. The exact repetition count is a Make
  variable committed before the full run.
- Cost estimate: full suite cost is dominated by Docker/image/eval execution;
  the preflight must confirm whether nested Docker in the KVM workflow is
  viable or whether the source evaluator must run in an explicitly documented
  guest image.

## Planned Runs

| Run group | Role | Workload | System/method | Repetitions | Decision consequence |
| --- | --- | --- | --- | ---: | --- |
| preflight | dependency | one clean source row, one hit and one stale/corrupt transition | `namei_ext` in KVM | 1 | Establishes runner, source evaluator, attach path, and raw-result shape; not a paper result. |
| main | proposed | full fixed row suite and all cache states | `namei_ext` policy in KVM | committed Make variable | Supports RQ1 only if every row passes the source oracle and lower-FS checks. |
| main | baseline | same suite and states | feature-equivalent FUSE policy | same as proposed | Supports RQ2 only if FUSE engages the same state machine and passes the same oracle. |
| control | correctness/lower bound | same suite where meaningful | native source evaluator or no-policy lower-FS path | same correctness rows | Confirms source oracle and lower-bound overhead; not a competing mechanism. |
| ablation | safety/control | malformed target IDs, stale registrations, unsupported decisions | `namei_ext` validation path | 1 per failure class | Supports RQ3 containment only if failures are visible and do not silently pass. |
| boundary evidence | RQ3 comparison | same policy requirements | source/custom/stackable FS evidence | n/a | Shows which filesystem methods, daemon state, metadata, and data semantics broader mechanisms own. |
| review | paper gate | all raw outputs | independent result review | n/a | Determines valid/invalid/incomplete status before paper claims. |

## Execution

- Authoritative command or workflow: add Make-owned targets for preflight, full
  `namei_ext`, FUSE, controls, raw collection, and analysis. Do not introduce
  project-owned shell scripts as the control plane.
- Real preflight case: one selected clean source row with one cache-hit and one
  stale/corrupt transition through the KVM `cgroup/namei_ext` attach path.
- Full completion rule: every planned row, state, comparison, control,
  repetition, and failure case reaches terminal status; correctness gates pass
  before performance interpretation; dmesg has no BUG/WARNING/Oops/panic or
  hung-task signal; raw artifacts include source row identity, image/eval
  identity, policy object hash, kernel identity, stdout/stderr, per-operation
  traces, and oracle outputs.
- Raw-result path: `results/experiments/environment-cache/<RUN_ID>/` or an
  equivalent documented result root.
- Checkpoint or recovery approach: preserve per-row raw artifacts as each row
  finishes; systematic runner or source-evaluator defects require rerunning
  affected cells across both `namei_ext` and FUSE.

## Interpretation

- Positive result: `namei_ext` passes the source oracle for all states and rows,
  stale/corrupt objects are rejected or bypassed correctly, lower-FS semantics
  are preserved, FUSE passes the same oracle with a higher or clearly
  characterized policy-path cost, and RQ3 boundary evidence shows narrower
  ownership.
- Negative or contradictory result: if the oracle requires synthetic content,
  cache metadata ownership, post-open data-path mediation, or custom write
  conflict handling, this workload belongs outside `namei_ext`'s boundary. If
  FUSE is feature-equivalent and equal or better on cost without a meaningful
  boundary tradeoff, RQ2 is contradicted for this workload.
- Mixed or inconclusive result: incomplete FUSE, missing operation-weighted
  traces, missing stale/corrupt states, host-only execution, or preflight-only
  results do not support the paper claim.
- Target paper figure or table: one correctness/state table; one RQ2 overhead
  figure comparing `namei_ext` and FUSE; one RQ3 ownership-boundary table.

## Reproducibility Notes

- Software and data versions: record exact source checkout, dataset row ID,
  Docker image digest, eval script hash, test patch hash, kernel commit, BPF
  policy object hash, and FUSE implementation commit.
- Config and seed notes: row suite, cache state sequence, repetitions, warmup,
  CPU/memory, and KVM image identity must be committed or recorded before the
  full run.
- Known deviations: Docker/eval rows are source workload oracles, not claims of
  full benchmark reproduction. The cache-policy layer is experimental glue and
  must not replace the source evaluator's correctness oracle.
