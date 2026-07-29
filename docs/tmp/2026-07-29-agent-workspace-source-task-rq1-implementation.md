# Agent Workspace Source Task RQ1 Implementation

## Motivation

The completed Agent workspace experiment replays an AgentFS-derived lifecycle
with a project C runner. The admitted follow-up tests a released
SWE-Factory-Gym Click task through two concurrent process-group workspace
views, then switches and rolls one view back. This adds a real repository,
unmodified Python/pytest execution, and a released fail-to-pass oracle to the
headline RQ1 workload.

## Source Assets

- SWE-Factory repository:
  `https://github.com/DeepSoftwareAnalytics/swe-factory`
- SWE-Factory commit:
  `760b1758c04ba61885972fe8f635c9db3b2c3232`
- Task: `pallets__click-2622`
- Click repository: `https://github.com/pallets/click.git`
- Click base commit: `1787497713fa389435ed732c9b26274c3cdc458d`
- Preserved source row:
  `results/reproduction/2026-07-01-official-workloads/
  swe-factory-gym-click2622/dataset.json`

The experiment stores the released gold and test patches as ordinary fixtures.
The Make dependency target obtains the fixed Click commit and verifies the Git
revision and clean checkout. Result capture uses `git archive` from that
revision. It does not create or validate checksum manifests.

## Implementation

### Policy

`bpf/policies/agent_workspace_source_task.bpf.c` implements one decision
function for lookup and directory enumeration:

- assigned `ws` lookup selects the target registered for the current cgroup;
- assigned `ws` enumeration passes the placeholder entry;
- unassigned `ws` lookup and enumeration hide the workspace;
- all unrelated names pass.

The policy records lookup, readdir, select, hide, pass, and per-target hit
counters. These counters establish mechanism engagement; they are not the task
oracle.

### Source-Task Controller

`experiments/agent_workspace_source_task/
namei_ext_agent_workspace_source_task.c` performs:

1. direct physical base and completed controls;
2. hidden-before-assignment lookup and readdir;
3. concurrent completed/base logical views behind a two-child pre-exec
   barrier;
4. an acknowledged switch from base to completed in a fresh child;
5. an acknowledged rollback to base in another fresh child;
6. mapping withdrawal and hidden lookup/readdir;
7. counter, detach, target-clear, and cgroup-removal checks.

Each task child enters its cgroup before resolving the absolute logical
workspace path. It starts outside both lower workspaces, waits at the barrier
when required, changes to the logical workspace, and launches the fixed system
Python as `python -m pytest tests/test_types.py`. Every state has its own pytest
temporary directory.

### Semantic Oracles

`parse_pytest_junit.py` parses pytest's standard JUnit output:

- base must collect 40 tests, pass 39, and fail only
  `test_choice_get_invalid_choice_message`;
- completed must collect and pass all 40;
- collection errors, dependency errors, skips, different failures, and
  different counts fail the state.

`import_probe.py` records the effective `sys.path`, `click.__file__`,
`click.types.__file__`, and device/inode identity for the changed source file
and task test file. It requires the absolute logical source path and the
assigned lower tree to agree. This prevents success through an installed Click
package or the wrong workspace.

The controller records monotonic ready, release, start, and completion times.
The concurrent row requires overlapping task intervals. Relevant lower source
and test files are also compared directly before and after execution.

### Make And KVM

The implementation adds:

- `configs/benchmarks/agent_workspace_source_task.mk`;
- `mk/experiments/agent_workspace_source_task.mk`;
- `make kvm-agent-workspace-source-task-rq1-preflight`;
- `make experiment-agent-workspace-source-task-rq1`.

The one-boot preflight and three-boot formal target use the shared modified
kernel KVM lifecycle, preserve raw task files per boot, check external
BPF/FUSE inventory before and after, scan dmesg, and aggregate only after every
boot passes.

## Validation Performed

- The C controller builds with `-Wall -Wextra`.
- The BPF policy builds with the repository BPF toolchain.
- Both Python helpers compile successfully.
- `make help` exposes the two new public experiment entrypoints.
- `make agent-workspace-source-task-source` obtained the fixed Click commit and
  verified a clean checkout.
- KVM preflight attempt 1 prepared and ran both physical source-task controls:
  base produced exactly 39 passes and the intended single failure, while
  completed produced 40 passes. It stopped before BPF attachment because
  pytest 8 omitted the optional JUnit `file` attribute required by the first
  parser implementation.
- The parser now requires the exact structured classname and test name instead
  of the optional JUnit file attribute. The substantive 39/1 and 40/0 gates are
  unchanged.
- `git diff --check` passes.

## Remaining Work

A fresh modified-kernel KVM preflight must reach the real BPF attach path and
verify the exact 39/1 and 40/0 controls, task dependencies, absolute import
path, concurrent overlap, switch, rollback, withdrawal, lower-file
preservation, and cleanup. Only a successful real preflight and independent
evidence review permit the three-boot formal run.

Attempt 1 is recorded in
`docs/tmp/2026-07-29-agent-workspace-source-task-rq1-preflight-attempt-1.md`.
