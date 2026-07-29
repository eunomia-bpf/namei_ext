# Experiment Plan: RQ1 Agent Workspace Source Task

## Research Question

- RQ exactly as written in the paper: Can a narrow VFS name-resolution
  extension express real state-dependent path-view policies without taking over
  filesystem semantics?
- Specific uncertainty tested here: Can one `cgroup/namei_ext` policy give two
  concurrent software-engineering workers different existing workspace roots
  at the same logical pathname, switch one worker to a completed branch, and
  roll it back while an unmodified test runner observes the expected
  fail-to-pass behavior?
- Why the answer matters: The current headline Agent workspace evidence
  replays AgentFS-derived operations with a project runner. It does not yet
  execute a public software-engineering task against a real repository through
  the selected view.

## Paper-Value Admission

- Planned role: headline.
- Largest credible paper story this experiment could unlock: `namei_ext`
  expresses the existing-object view-selection part of an AgentFS-style
  workspace lifecycle while an unmodified real application executes a released
  software-engineering task through that view.
- Strongest reviewer reject argument or load-bearing uncertainty addressed:
  The Agent result may work only for a small project-authored syscall trace and
  not for a released Click test module executed by Python and pytest through a
  selected repository view.
- Independent evidence added beyond existing runs and published results: A
  released SWE-Factory-Gym task, a real Click source tree, the task's
  fail-to-pass oracle, concurrent process-group isolation, and live
  branch-switch/rollback behavior.
- Why the result is not tautological, already settled, or dominated: Policy
  counters cannot satisfy the oracle. The result depends on pytest importing
  the selected `src/click/types.py`, executing the released test, and producing
  opposite outcomes for two simultaneous views of the same logical pathname.
- Paper decision if positive: Promote W2 from a source-derived lifecycle replay
  to a source-task-backed headline RQ1 case while retaining the existing
  AgentFS lifecycle rows for whiteout, readdir, and lower-filesystem semantics.
- Paper decision if contradictory, mixed, or inconclusive: Keep the current
  scoped AgentFS-derived result and report that complete source-tree traversal
  or concurrent root selection remains outside the demonstrated RQ1 evidence;
  do not weaken RQ1 or substitute another toy workload.
- Best alternative experiment and why this one has higher decision value: A
  concurrent XDG grant/revoke test would deepen a supporting row. This task
  instead repairs the strongest source-integration gap in the headline Agent
  row. Reopening nginx, DMTCP, or Spindle would violate their exhausted
  three-preflight protocols without a new source-native execution path.

## Expected And Alternative Outcomes

- Current expected answer: Two concurrent cgroups can resolve `view/ws` to
  different registered Click workspaces. The base view fails the released new
  test, the completed view passes it, switching the base worker to the
  completed view makes the same command pass, and rollback restores the
  expected failure.
- Strongest competing explanation: Python or pytest may bypass the logical
  workspace through an installed Click package, or both workers may consume
  one physical tree despite different policy state.
- Result that would contradict the expectation: Either worker imports Click
  outside its selected logical workspace, concurrent workers observe the same
  lower object, switch/rollback does not change the fail-to-pass result, or
  lookup/readdir and lower-object identity disagree.

## Published Precedent And Real Assets

- Closest published protocol: The reproduced
  `DeepSoftwareAnalytics/swe-factory` artifact at commit
  `760b1758c04ba61885972fe8f635c9db3b2c3232` evaluates SWE-Factory-Gym
  issue-resolution tasks with a real repository base commit, a released
  candidate patch, a released test patch, and the repository test result as
  the correctness oracle. AgentFS provides the branch/workspace lifecycle that
  motivates per-worker views.
- Official system/model/data/benchmark/tool and version:
  `SWE-Factory/SWE-Factory-Gym`, task `pallets__click-2622`; Click base commit
  `1787497713fa389435ed732c9b26274c3cdc458d`; AgentFS commit
  `0a014ebd4918615baff589ed17486e557e7c6a23`; the repository's installed
  Python/pytest toolchain.
- What is reused: The task's base commit, gold patch, test patch, and
  `tests/test_types.py` pytest oracle. The existing reproduction record already
  establishes that the official task resolves with 40 passing tests. The exact
  preserved dataset row is
  `results/reproduction/2026-07-01-official-workloads/
  swe-factory-gym-click2622/dataset.json`.
- Necessary deviations or custom glue: Make prepares base and completed
  workspaces and a test environment. A C controller registers the two existing
  roots, attaches the policy, moves pytest children into the two cgroups, and
  records syscall/object observations. It does not implement a filesystem,
  patch generator, test oracle, or agent model.

## Comparison

- Proposed system or method: `namei_ext` selects one of two registered existing
  Click workspace roots according to process-group workspace state.
- Main baselines and the competing position each represents: None for this RQ1
  sufficiency experiment. AgentFS/FUSE behavior is source precedent and already
  has an official reproduction plus a matched RQ2 experiment; rerunning it here
  would not change whether `namei_ext` passes the source-task oracle.
- Why each main baseline needs a matched run instead of citation alone: Not
  applicable.
- Controls or ablations, labeled separately: Make constructs two independent
  Click trees from base commit `1787497713fa389435ed732c9b26274c3cdc458d`.
  It applies the released test patch to both trees and the released gold source
  patch only to the completed tree. Every pytest invocation must collect
  exactly 40 tests. The physical base tree must exit 1 with exactly 39 passed
  and only
  `tests/test_types.py::test_choice_get_invalid_choice_message` failed. The
  physical completed tree must exit 0 with exactly 40 passed. A collection
  error, dependency error, different failed test, or different count
  invalidates the task cell. Before assignment and after withdrawal, the
  logical workspace must be absent. Imported module paths plus logical/lower
  device and inode establish the selected objects. Saved expected source files
  are compared directly after the run; no checksum is used.
- Conclusion if each main baseline matches or wins: Not applicable. A failed
  physical control invalidates the task rather than favoring either mechanism.
- Information, tuning, and compute fairness: Both workers use the same Python
  environment, pytest command, task test patch, logical pathname, CPU budget,
  and prepared source trees. Only the cgroup-to-target state differs.
- Split or leakage rule when relevant: Before launch, define `L` as the
  absolute logical workspace pathname. Logical runs start outside both physical
  workspaces, enter the assigned cgroup before any logical-path lookup, resolve
  and `chdir(L)`, and invoke the fixed environment as
  `python -m pytest tests/test_types.py` with `PYTHONPATH=L/src`. The relative
  form `view/ws/src` is not used after `chdir`. Record the effective `sys.path`
  entry and require it to equal `L/src`. Also record `click.__file__`,
  `click.types.__file__`, and logical/lower device and inode for both
  `src/click/types.py` and `tests/test_types.py`; each must correspond to the
  assigned physical tree.

## Workloads And Metrics

- Real workloads or tasks: SWE-Factory-Gym `pallets__click-2622`,
  `tests/test_types.py`, including the released
  `test_choice_get_invalid_choice_message` fail-to-pass test.
- Primary metrics: Per-state pytest exit status and passed/failed test counts;
  imported Click and `click.types` module pathnames; logical/lower device and
  inode for the patched source and test files; concurrent worker interval;
  switch and rollback outcome.
- Correctness check or ground truth: Physical base fails the new test and
  physical completed passes all 40 tests under the exact count and node rules
  above. Concurrent logical base/completed views reproduce those outcomes.
  Both mappings exist before launch. Each child enters its cgroup, signals
  ready, and blocks on a shared pre-exec barrier before any logical lookup.
  Release occurs only after both children are ready. Monotonic ready, release,
  task-start, and completion times must show overlapping task intervals, and
  workers use distinct `--basetemp` directories. After each acknowledged map
  update, a fresh child starts outside the logical tree, enters the same worker
  cgroup, and resolves `view/ws` without inheriting a workspace cwd, workspace
  file descriptor, or imported Click module. The exact transition sequence is
  base 39/1, switch to completed 40/0, rollback to base 39/1, delete mapping,
  then logical-path absence. Lookup and readdir agree with
  assigned/withdrawn state, relevant source files remain directly equal to
  their prepared copies, and teardown leaves no attached policy or workload
  cgroup.
- Repetitions, seeds, and uncertainty: One real end-to-end preflight, followed
  by three fresh modified-kernel KVM boots. This is deterministic correctness,
  not a timing experiment; no statistical performance claim is planned.
- Cost estimate when material: One Click checkout/environment preparation and
  six pytest invocations per boot, expected to complete within minutes.

## Planned Runs

| Run group | Role | Workload | System/method | Repetitions | Decision consequence |
|---|---|---|---|---:|---|
| task controls | control | Click 2622 base and completed roots | direct physical paths | 1 per root per boot | Validates the released fail-to-pass oracle |
| concurrent views | proposed | Click 2622 base and completed roots | two cgroup-scoped `namei_ext` views at `view/ws`, released from one pre-exec barrier | 3 fresh boots | Tests simultaneous source-task isolation with overlapping execution |
| transition | proposed | Click 2622 completed, switch, rollback, withdrawal | acknowledged map update plus a fresh logical-path child per state | 3 fresh boots | Tests live workspace-state transitions without inherited path state |

## Execution

- Authoritative command or workflow:
  `make experiment-agent-workspace-source-task-rq1 RUN_ID=<fresh-id>`.
- Real preflight case:
  `make kvm-agent-workspace-source-task-rq1-preflight RUN_ID=<fresh-id>`;
  it runs both physical controls and the complete concurrent/switch/rollback
  sequence in one real modified-kernel KVM boot.
- Full completion rule: All three boots complete both physical controls, both
  concurrent logical tasks, switch, rollback, withdrawal, object-identity,
  exact pytest-node/count, overlap, lower-file, policy-engagement, cleanup,
  inventory, and dmesg checks with no undeclared failure. Pytest runs set
  `PYTHONDONTWRITEBYTECODE=1`, disable the pytest cache provider, and use unique
  temp directories so task execution does not mutate either source tree.
- Raw-result path:
  `results/experiments/agent-workspace-source-task-rq1/<run-id>/`.
- Checkpoint or recovery approach: Each boot writes its pytest stdout/stderr,
  state observations, object identities, policy counters, status, inventory,
  and dmesg before host aggregation. A failed boot remains a failed raw result
  and is not interpreted as a completed experiment.

## Interpretation

- Positive result: A real released software-engineering task observes correct
  concurrent branch selection, switch, rollback, and withdrawal through one
  logical workspace path on the real KVM attach path.
- Negative or contradictory result: Source-tree traversal, task isolation, or
  state transition exceeds the demonstrated mechanism or implementation; keep
  the current narrower W2 evidence and repair only if the failure is an
  execution defect rather than a mechanism boundary.
- Mixed or inconclusive result: Any mismatch between task outcome, imported
  object identity, lookup/readdir visibility, or physical controls makes the
  run inconclusive or invalid rather than a partial RQ1 success.
- Target paper figure or table: Replace the W2 RQ1 row's custom-trace-only
  result with one compact source-task state table: base, completed, concurrent
  isolation, switch, rollback, and withdrawal.

## Reproducibility Notes

- Software and data versions: Versions and commits are fixed above and will be
  recorded as text in the result root.
- Config and seed notes: No model, random seed, or performance tuning is used.
- Known deviations: This replays a released task patch; it does not run an LLM,
  generate a patch, provide copy-on-write, merge branches, or reproduce the
  full SWE-Factory evaluator container. Those functions remain with the agent,
  workspace manager, and source evaluator.
