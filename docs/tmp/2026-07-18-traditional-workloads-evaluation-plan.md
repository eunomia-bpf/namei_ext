# Traditional Workloads Evaluation Plan

Date: 2026-07-18
Status: planning record; no experiment result is claimed here
Skill basis: `research-experiment-design`

## Purpose

This record fixes the non-agent workload direction for the next evaluation
iteration. The main paper should not look agent-only, and it should not use
Filebench, Postmark, fsbench, TableFS, IndexFS, or DeltaFS metadata workloads as
primary RQ1 workloads. Those workloads mainly measure metadata scalability or
traditional filesystem request overhead; they do not naturally expose the
state-dependent path-view policy that `namei_ext` is designed to test.

The current evaluation should have two primary workload families:

1. Agent workspace lifecycle.
2. Traditional build/cache.

Service/config rotation and checkpoint/restart path remapping are conditional
third-workload candidates. They are useful only if they provide a real
lookup-time object-selection oracle. They should not displace the traditional
build/cache experiment before it runs.

## Current Research Questions

| RQ | Question | Evidence expected from these workloads |
| --- | --- | --- |
| RQ1 Expressiveness / sufficiency | Can a narrow VFS name-resolution extension express real state-dependent path-view policies without taking over filesystem semantics? | A real workload oracle passes through the KVM `cgroup/namei_ext` attach path, with coherent lookup/readdir/open/stat behavior and lower-FS semantic preservation. |
| RQ2 Cost / overhead versus FUSE | What is the cost of putting programmable policy on the VFS name-resolution path compared with a feature-equivalent FUSE policy implementation? | Same-oracle `namei_ext` and FUSE policy rows, with correctness gating latency, macro runtime, and operation-weighted branch counts. |
| RQ3 Safety / boundary versus custom or stackable FS | Does `namei_ext` provide a narrower verifier-bounded, fail-closed ownership boundary than building a custom or stackable filesystem when the needed policy is only name resolution? | Workload-specific ownership evidence after the oracle passes: filesystem methods owned, daemon/state responsibility, privileged code surface, invalid-policy containment, and lower-FS preservation. |

## Admission Summary

| Candidate workload | Role | Admission decision | Reason |
| --- | --- | --- | --- |
| Traditional build/cache | Decisive primary workload | Admit for planning; implement next after required target-selection support | It is traditional, reproducible, and has a concrete build/test correctness oracle plus cache-state transitions that exercise path selection. |
| Service/config rotation | Conditional supporting workload | Keep after build/cache | Strong only when service-visible behavior depends on lookup-time config/secret/cert object selection, not just projected-volume materialization or app reload. |
| Checkpoint/restart path remapping | Conditional supporting or OS-breadth workload | Keep as backup after build/cache | More OS-flavored than service/config, but requires more glue and a concrete restart/path-virtualization oracle. |
| Filebench/Postmark/fsbench | RQ2 control or appendix only | Do not use as primary workload | They measure generic metadata behavior, not source-derived state-dependent path-view policy. |
| DeltaFS/IndexFS/TableFS workloads | Related work or appendix only | Do not use as primary workload | They are metadata-service or stacked-metadata filesystem workloads; useful for boundary discussion, not the main `namei_ext` workload claim. |

## Experiment B: Traditional Build/Cache

### Research Question

- RQ exactly as written in the paper: RQ1 asks whether a narrow VFS
  name-resolution extension can express real state-dependent path-view policies
  without taking over filesystem semantics. RQ2 asks what this policy path costs
  compared with feature-equivalent FUSE. RQ3 asks whether the ownership boundary
  is narrower than custom or stackable filesystem implementation when the policy
  only needs name resolution.
- Specific uncertainty tested here: whether traditional build/test workloads
  can use lookup-time policy to choose verified local cache objects, canonical
  backing objects, or fallback objects across hit, miss, stale, corrupt, and
  epoch-update states.
- Why the answer matters: this is the strongest non-agent workload. A positive
  result prevents the paper from being framed as only an agent-workspace story.

### Paper-Value Admission

- Planned role: decisive.
- Largest credible paper story this experiment could unlock: `namei_ext`
  supports a traditional build/cache path policy while preserving ordinary
  lower-filesystem semantics and avoiding FUSE filesystem-service ownership.
- Strongest reviewer reject argument addressed: build caches, Docker cache
  mounts, and source-native environment tools already exist; a VFS hook must
  show it can satisfy the same build/test oracle with a meaningful boundary and
  cost story.
- Independent evidence added beyond existing runs and published results:
  existing source systems provide build/test oracles, but they do not run the
  cache-state policy through the modified kernel or compare the same policy
  against FUSE.
- Why the result is not tautological: success requires unchanged build/test
  correctness, stale/corrupt non-use, cache-state transition evidence,
  operation-weighted path-operation traces, feature-equivalent FUSE, and RQ3
  ownership evidence.
- Paper decision if positive: Experiment B becomes the main non-agent result
  and the decisive evidence that the abstraction covers traditional
  build/cache policy, not only agent workspace lifecycle.
- Paper decision if contradictory, mixed, or inconclusive: if the oracle
  requires data-path mediation, synthetic contents, cache metadata ownership, or
  custom write conflict handling, the workload is outside the current
  `namei_ext` boundary. If FUSE is feature-equivalent and equal or better on
  cost, RQ2 is bounded for this workload rather than converted into a
  `namei_ext` win.

### Expected And Alternative Outcomes

- Current expected answer: `namei_ext` can express the fixed build/cache state
  machine with bounded lookup/readdir/open/stat-visible policy and registered
  targets.
- Strongest competing explanation: the important behavior is really a cache
  service, BuildKit/ccache/environment manager, or custom filesystem ownership
  problem rather than name-resolution policy.
- Contradictory result: the oracle cannot pass without file-content synthesis,
  post-open data-path checks, persistent cache metadata in the hook, or source
  evaluator changes.

### Published Precedent And Real Assets

Use real build/test workloads, not synthetic metadata loops.

Candidate sources:

- Redis, nginx, or PostgreSQL small build/test rows.
- `ccache` with a C/C++ project.
- BuildKit cache-mount style workload.
- MEnvData-SWE, SWE-Factory-Gym, or SWE-rebench rows selected as sources of
  real repository build/test oracles. These rows must be framed as build/test
  oracles, not as agent workloads.

Necessary custom glue is limited to path-policy instrumentation, cache-state
setup, and KVM/FUSE adapters. It must not replace the build/test oracle.

### State Machine

The policy state machine is fixed:

```text
hit          -> select verified local cache object
miss         -> select canonical backing object
stale        -> reject/hide local, fallback canonical
corrupt      -> reject/hide local, fallback canonical
epoch update -> switch selected backing/cache generation
```

The state machine must be driven by predeclared cache-state inputs. Changing the
oracle or state definitions after seeing results is a plan deviation that
requires rerunning affected rows.

### Comparison

- Proposed system: `namei_ext` policy in KVM through the real
  `cgroup/namei_ext` attach path.
- Main RQ2 baseline: feature-equivalent FUSE policy with the same cache state
  labels, target objects, path prefix, update schedule, and build/test oracle.
- Controls: native/no-policy build/test row for oracle validity and lower-bound
  overhead; no-hook KVM row where meaningful; invalid-policy containment rows
  for malformed targets and stale registrations.
- RQ3 boundary comparison: source-native cache manager, FUSE filesystem
  service, or custom/stackable filesystem boundary evidence for the same
  policy. Record which filesystem methods, daemon state, cache metadata,
  privileged code, and data/write semantics each alternative owns.
- Not main baselines: table redirects, copy/symlink/bind/Overlay/projected
  views, Filebench, Postmark, fsbench, TableFS, IndexFS, and DeltaFS. Cite or
  classify them unless a selected source oracle makes one a direct competing
  mechanism under the same correctness condition.

### Workloads And Metrics

Correctness oracle:

- build/test pass;
- output hash, binary hash, or source evaluator result where available;
- stale/corrupt cache object is not consumed;
- cache-state transition trace;
- lower-FS writes, permissions, data path, page cache, persistence, and
  consistency remain owned by the lower filesystem.

Performance and mechanism metrics:

- lookup/readdir/open/stat/access/exec latency where the workload exercises
  those operations;
- macro build/test runtime;
- operation-weighted branch rate across hit, miss, stale, corrupt, and epoch
  update;
- FUSE request count, daemon CPU, and context-switch cost;
- action-specific overhead for select/hide/reject/pass.

Uncertainty:

- correctness: at least one terminal run per state per selected row;
- performance: enough repetitions to report median and dispersion before any
  paper number is used;
- cache-hot and cache-cold conditions must be recorded explicitly.

### Planned Runs

| Run group | Role | Workload | System/method | Decision consequence |
| --- | --- | --- | --- | --- |
| preflight | dependency | one small build/test row with hit and stale/corrupt states | `namei_ext` in KVM | Establishes real attach path, oracle, trace, and result shape; not a paper result. |
| main | proposed | fixed build/cache suite across all states | `namei_ext` policy in KVM | Supports RQ1 only if every row passes the oracle and lower-FS checks. |
| main | baseline | same suite and states | feature-equivalent FUSE policy | Supports RQ2 only if FUSE passes the same oracle and receives equal policy information. |
| control | oracle/lower bound | same suite where meaningful | native/no-policy lower-FS run | Confirms source oracle and lower-bound cost; not a competing mechanism. |
| safety | control | malformed target, stale registration, unsupported decision | `namei_ext` validation path | Supports RQ3 containment only if failures are visible and fail closed. |
| boundary | RQ3 evidence | same policy responsibilities | FUSE/source/custom/stackable ownership table | Supports RQ3 only after same-oracle correctness is established. |

### Execution

- Authoritative workflow: add Make-owned targets for preflight, full
  build/cache run, FUSE comparison, controls, raw collection, and analysis. Do
  not add project-owned shell scripts as the control plane.
- Real preflight case: one selected build/test row with a real cache-hit and
  one stale or corrupt rejection through KVM.
- Full completion rule: every planned row, state, comparison, control,
  repetition, and failure case reaches terminal status. Correctness gates pass
  before performance is interpreted. dmesg must show no BUG, WARNING, Oops,
  panic, or hung-task signal.
- Raw-result path: `results/experiments/build-cache/<RUN_ID>/`.
- Required raw artifacts: source checkout identity, build/test command,
  cache-state manifest, target-object hashes, policy object hash, kernel
  identity, stdout/stderr, dmesg, per-operation traces, macro timings, FUSE
  daemon logs, and oracle outputs.

### Interpretation

- Positive result: all states pass the build/test oracle, stale/corrupt objects
  are not consumed, lower-FS semantics are preserved, FUSE passes the same
  oracle with characterized overhead, and RQ3 evidence shows narrower ownership
  than a filesystem-service or custom-FS boundary.
- Negative result: the workload requires behavior outside name resolution, or
  FUSE matches/wins on cost under a fair feature-equivalent configuration.
- Mixed or inconclusive result: missing FUSE parity, host-only execution,
  missing operation-weighted traces, missing stale/corrupt states, or
  preflight-only evidence does not support the paper claim.
- Target paper output: one state/correctness table, one overhead figure against
  FUSE, and one RQ3 ownership-boundary table.

## Conditional Workload C: Service/Config Rotation

Use service/config only if the selected service has a real lookup-time
selection oracle. Candidate services include nginx, Redis, and PostgreSQL.

Fixed policy shape:

```text
normal epoch      -> /etc/service/config resolves to current config
canary epoch      -> resolves to staged config
bad config        -> hidden/rejected/fallback current config
rollback          -> resolves back to previous config
secret/cert epoch -> selects current secret/cert object
```

Oracle:

- service config validation succeeds, for example `nginx -t` where applicable;
- service reload succeeds;
- served response or service-visible behavior changes under canary epoch;
- bad config does not become active;
- rollback restores previous behavior;
- lower-FS writes and permissions are unchanged.

Admission veto: if the behavior is merely Kubernetes projected-volume
materialization, app reload logic, or a static symlink switch, keep it in
related work or appendix context. It becomes a main or supporting workload only
when lookup-time object selection is necessary for the oracle being measured.

## Conditional Workload D: Checkpoint/Restart Path Remapping

Use checkpoint/restart path remapping as an OS-flavored third workload if the
paper still needs traditional breadth after build/cache.

Candidate source family: DMTCP-style path virtualization or comparable
checkpoint/restart workflows.

Fixed policy shape:

```text
checkpoint path state -> old absolute path maps to restored lower path
migrated root         -> same app path selects new backing object
missing/stale backing -> reject/fallback
```

Oracle:

- restart succeeds;
- reopened files resolve to the expected restored object;
- stale or missing mapping fails closed;
- lower-FS metadata and data semantics are preserved.

Expected cost: higher glue cost than build/cache. Do not start this before the
build/cache preflight unless a reviewer or orchestrator decision makes OS
breadth more valuable than completing Experiment B.

## Explicit Non-Main Workloads

Filebench, Postmark, fsbench, and metadata-service workloads from TableFS,
IndexFS, and DeltaFS should not be main RQ1 workloads. They can still be useful
as:

- RQ2 overhead or pass-through controls for generic metadata operation mixes;
- related-work evidence that full filesystems and metadata services solve a
  different problem;
- appendix context for conventional filesystem benchmarking expectations.

They should not be used to claim source-derived expressiveness because they do
not naturally encode the build/cache, service/config, checkpoint/remap, or agent
workspace state machine.

## Immediate Next Action

Start with Experiment B preflight planning and implementation:

1. choose one traditional build/test row;
2. define its cache-state manifest;
3. implement the Make-owned KVM preflight target;
4. collect raw correctness, operation trace, and lower-FS preservation evidence;
5. add feature-equivalent FUSE only after the `namei_ext` preflight proves the
   source oracle and state machine are engaged.

No result should be written into the paper until the full same-oracle
`namei_ext` plus FUSE matrix completes and receives result review.
