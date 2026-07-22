# Experiment Plan: RQ1 Agent Workspace Expressiveness

## Research Question

- RQ exactly as written in the paper: Can a narrow VFS name-resolution
  extension express real state-dependent path-view policies without taking
  over filesystem semantics?
- Specific uncertainty tested here: whether the real `cgroup/namei_ext` KVM
  path can implement the AgentFS-derived base/agent epoch, whiteout,
  symlink, cached-negative, create, rename, unlink, executable, and coherent
  lookup/readdir lifecycle while writes and object semantics remain with the
  lower filesystem.
- Why the answer matters: Agent workspaces are the headline source-derived
  workload. Without this same-oracle result, `namei_ext` is only a mechanism
  prototype and RQ1 remains unanswered.

## Paper-Value Admission

- Planned role: headline.
- Largest credible paper story this experiment could unlock: a narrow verified
  VFS policy can realize a real agent-workspace path-view slice without taking
  over filesystem operations or the data path.
- Strongest reviewer reject argument or load-bearing uncertainty addressed:
  the current hook may only pass synthetic redirect tests and may not preserve
  coherent directory visibility, mutable lower-FS behavior, symlinks, and
  cache-invalidating lifecycle operations under a source-derived oracle.
- Independent evidence added beyond existing runs and published results: a
  fresh current-revision KVM run binds the official AgentFS reproduction record
  and fixed trace artifact to the executed workload, the attached BPF policy,
  operation counters, final tree, and lower-FS preservation checks. Existing
  raw matrices are not reused as final results because they predate the current
  source-trace gate.
- Why the result is not tautological, already settled, or dominated: AgentFS
  proves that the lifecycle is real but not that a name-resolution-only hook
  can express it while delegating filesystem semantics. Unit/functional tests
  prove individual actions but not the integrated lifecycle.
- Paper decision if positive: RQ1 gains headline evidence for the Agent
  workspace family; the paper can state that the tested source-derived slice is
  sufficient at the narrow boundary, while leaving the independent
  traditional build/cache family open.
- Paper decision if contradictory, mixed, or inconclusive: identify the exact
  lifecycle operation that crosses the boundary or the execution defect that
  invalidates the run; do not weaken the frozen RQ or substitute a toy.
- Best alternative experiment and why this one has higher decision value: the
  traditional build/cache experiment adds non-agent breadth, but the frozen
  plan and strongest reviewer risk first require the headline Agent workspace
  row to move beyond prototype evidence.

## Expected And Alternative Outcomes

- Current expected answer: the selected AgentFS-derived slice passes through
  `namei_ext`; registered base/agent epochs change the logical view, hidden
  names agree across lookup and readdir, and create/rename/unlink/read/exec
  preserve lower-FS ownership.
- Strongest competing explanation: the lifecycle only works because the test
  bypasses source provenance, pre-materializes the answer, or relies on path
  operations whose dcache/readdir behavior becomes incoherent after state
  changes.
- Result that would contradict the expectation: any source-oracle mismatch,
  stale visibility, incorrect symlink/executable behavior, write outside the
  selected lower tree, base-tree mutation, unattached policy path, or required
  operation that needs synthetic contents or custom filesystem state.

## Published Precedent And Real Assets

- Closest published protocol: AgentFS official CLI integration and COW sandbox
  tests, reproduced at commit `0a014ebd4918615baff589ed17486e557e7c6a23` in
  `docs/tmp/2026-07-02-agentfs-official-workload-reproduction.md`.
- Official system/model/data/benchmark/tool and version: Turso AgentFS official
  repository at the reproduced commit; Linux KVM with the repository's modified
  kernel; the real `cgroup/namei_ext` BPF attach path.
- What is reused: AgentFS bash/git overlay workload shape, whiteout, symlink,
  cache-invalidation, cached-negative, rename/unlink, and final-tree oracles.
- Necessary deviations or custom glue: a compact deterministic C runner maps
  the source-derived slice to registered lower directories and emits raw
  events; it does not reimplement AgentFS or claim full COW/audit semantics.

## Comparison

- Proposed system or method: `agent_workspace_view.bpf.c` attached to the
  modified kernel's `cgroup/namei_ext` hook.
- Main baselines and the competing position each represents: none for RQ1;
  source AgentFS behavior defines the oracle rather than a baseline.
- Why each main baseline needs a matched run instead of citation alone: not
  applicable.
- Controls or ablations, labeled separately: no-hook/lower-FS observations
  verify source files and write placement; the feature-equivalent FUSE row is
  an independent same-oracle realization control but its performance is held
  for RQ2; clearing registered targets verifies that an unavailable selected
  object does not resolve accidentally.
- Conclusion if each main baseline matches or wins: not applicable for RQ1.
- Information, tuning, and compute fairness: the same base/agent state and
  final-tree oracle are used across the `namei_ext` and independent FUSE
  realization; no result-dependent tuning is permitted.
- Split or leakage rule when relevant: the source trace and oracle are fixed
  before the fresh run; correctness is derived from filesystem state, not BPF
  counters.

## Workloads And Metrics

- Real workloads or tasks: one fixed AgentFS-derived bash/git workspace
  lifecycle over base and per-agent lower trees, including `.git/HEAD`, edited
  source, whiteout, symlink, generated file, cached-negative creation, rename,
  unlink, and epoch selection.
- Primary metrics: per-run source-oracle pass, final-tree pass, lookup/readdir
  coherence pass, and lower-FS semantic-preservation pass. These are direct
  correctness outcomes, not a project-defined aggregate score.
- Correctness check or ground truth: the fixed source trace plus direct stat,
  read, readlink, readdir, exec, final-tree, and lower-tree observations.
- Repetitions, seeds, and uncertainty: three fresh terminal KVM runs. The
  deterministic correctness claim requires all three to pass; per-operation
  timings are collected but not interpreted in RQ1.
- Cost estimate when material: one existing-kernel build check plus three KVM
  boots; expected wall time is minutes rather than hours.

## Planned Runs

| Run group | Role | Workload | System/method | Repetitions | Decision consequence |
|---|---|---|---|---:|---|
| preflight | real-path preflight | fixed AgentFS-derived lifecycle | current `namei_ext` KVM path plus same-oracle control | 1 | Establishes the current revision, source trace, policy attach, oracle, and raw-output path. |
| main | proposed | complete fixed lifecycle | `namei_ext` KVM path | 3 | Supports the tested RQ1 slice only if all correctness and preservation gates pass. |
| control | lower-FS/no-hook | same base/agent objects and operation-relevant checks | native lower filesystem | 3, within each run | Detects fixture or write-placement errors; not a baseline win. |
| control | independent oracle realization | same lifecycle and oracle | feature-equivalent FUSE policy | 3, within each run | Detects a method-tailored oracle; performance is reserved for RQ2. |
| control | missing selected target | logical path after target registry clear | `namei_ext` validation path | 3, within each run | Verifies the workload cannot silently resolve an unregistered backing object. |

## Execution

- Authoritative command or workflow: `make experiment-agent-workspace
  RUN_ID=<fresh-id>` for each run. The Make-owned KVM target builds the runner
  and policy, boots the modified kernel, executes the matrix, and preserves raw
  artifacts.
- Real preflight case: the same target once after repairing the missing source
  trace argument in `mk/kvm.mk`; a unit test or host binary is not sufficient.
- Full completion rule: three fresh run directories each contain the command,
  hashes, kernel identity/config, stdout/stderr, dmesg, and JSONL; every declared
  source, oracle, preservation, policy-counter, and summary gate passes; no
  kernel BUG/WARNING/Oops signature appears.
- Raw-result path:
  `results/experiments/agent-workspace-matrix/<RUN_ID>/`.
- Checkpoint or recovery approach: each KVM run is independent and terminal;
  preserve failed attempts and rerun only cells affected by a repaired
  systematic defect.

## Interpretation

- Positive result: the AgentFS-derived slice supplies headline positive RQ1
  evidence, scoped to name selection/visibility over existing lower objects.
- Negative or contradictory result: report the exact unsupported operation or
  boundary violation and keep RQ1 open; do not present an execution failure as
  scientific contradiction.
- Mixed or inconclusive result: retain the supported operations as mechanism
  evidence but do not close the Agent workspace RQ1 row.
- Target paper figure or table: fill the Agent workspace row of the RQ1 answer
  table with the lifecycle states, three-of-three pass result, operation mix,
  and lower-FS preservation evidence.

## Reproducibility Notes

- Software and data versions: repository commit at run time, kernel submodule
  commit, AgentFS source commit above, and all input hashes are recorded per
  run.
- Config and seed notes: deterministic workload; KVM CPU/memory and kernel
  config are preserved by the target.
- Known deviations: this is a source-derived AgentFS path-view slice, not full
  AgentFS SQLite state, audit trail, COW implementation, or framework runtime.
