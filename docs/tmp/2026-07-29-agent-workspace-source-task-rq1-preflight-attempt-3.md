# Agent Workspace Source-Task RQ1 Preflight: Attempt 3

## Purpose

This was the third and final permitted real KVM preflight for the source-task
deepening of the headline Agent Workspace RQ1 workload. It ran the complete
admitted protocol after two bounded oracle and evidence-recording repairs.

## Run

- Result root:
  `results/experiments/agent-workspace-source-task-rq1-preflight/20260729T-agent-source-task-preflight03/`
- Project commit: `7804bef450cdf33495c11be1dcd0a0d43202668d`
- Kernel commit: `621aff8d1bb52fad718f11fd882c956d6a5686ae`
- Kernel release: `7.1.0-rc7-g621aff8d1bb5`
- Source task: SWE-Factory-Gym `pallets__click-2622`
- Entry point:
  `make kvm-agent-workspace-source-task-rq1-preflight RUN_ID=20260729T-agent-source-task-preflight03`

The project and kernel trees were clean at capture. The top-level run,
guest boot, finalizer, and analysis all completed.

## Source-Task Controls

Both direct physical controls passed:

- base collected 40 tests, passed 39, and failed only
  `tests.test_types::test_choice_get_invalid_choice_message`;
- completed collected and passed all 40 tests.

The import records used schema v2. For every state, the exact absolute source
path was in `sys.path`; `click.__file__` and `click.types.__file__` used the
declared logical root; and the source, test, workspace root, and cwd object
identities matched the expected lower tree.

## Concurrent Views

Worker A and worker B entered different cgroups and blocked behind the same
pre-exec barrier. Their task intervals overlapped:

- A start/end:
  `9828347814` to `11410196310` ns, completed view, 40/40 passed;
- B start/end:
  `9828340134` to `11475033994` ns, base view, 39/40 passed with only the
  expected failure.

Both used the same absolute logical workspace pathname. A's cwd, logical root,
and expected completed root shared device 64 and inode 35984239. B's
corresponding objects shared device 64 and inode 35984237.

## State Transitions

A fresh worker-B child after the acknowledged switch selected completed and
passed 40/40. Another fresh child after rollback selected base and reproduced
the exact 39/1 result. Their workspace, cwd, changed-source, and test-object
identities matched the newly assigned lower tree.

Before assignment and after withdrawal, `stat(view/ws)` returned `ENOENT` and
directory enumeration did not list `ws`. Assigned A and B states exposed the
entry through both lookup and enumeration.

## Mechanism And Preservation Evidence

The boot recorded:

- 100255 policy lookup events;
- 56620 readdir events;
- 1354 target selections;
- 2 hidden lookups and 2 hidden readdir entries;
- 339 A-completed, 677 B-base, and 338 B-completed target hits.

Direct comparisons of the prepared source and task test files passed after
execution. The lower metadata record was unchanged. Policy detach, both target
clears, both cgroup removals, external BPF/FUSE inventory checks, and the dmesg
scan all passed.

## Preflight Decision

The one-boot preflight satisfies the implemented completion gates: six passing
source-task states, one overlapping concurrent pair, four visibility states,
the complete transition sequence, positive policy engagement, lower-object
preservation, cleanup, inventory, and dmesg.

This is a preflight, not the formal RQ1 result. The independent claim-to-code-
to-raw review found no blocker and authorized the predeclared three-fresh-boot
formal run. The review is recorded in
`docs/tmp/2026-07-29-agent-workspace-source-task-rq1-preflight-03-review.md`.
