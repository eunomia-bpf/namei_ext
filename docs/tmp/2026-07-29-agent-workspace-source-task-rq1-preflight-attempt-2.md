# Agent Workspace Source-Task RQ1 Preflight: Attempt 2

## Purpose

This was the second real modified-kernel KVM preflight for the source-derived
Agent Workspace workload. It tested the repaired exact pytest oracle and was
the first attempt to reach concurrent logical workspace selection through the
real `cgroup/namei_ext` attach path.

## Run

- Result root:
  `results/experiments/agent-workspace-source-task-rq1-preflight/20260729T-agent-source-task-preflight02/`
- Project commit: `6fae06d09d7b88ae60674408349660348be1eba5`
- Kernel commit: `621aff8d1bb52fad718f11fd882c956d6a5686ae`
- Kernel release: `7.1.0-rc7-g621aff8d1bb5`
- Source task: SWE-Factory-Gym `pallets__click-2622`
- Entry point:
  `make kvm-agent-workspace-source-task-rq1-preflight RUN_ID=20260729T-agent-source-task-preflight02`

A preceding one-second host invocation stopped during kernel build and never
entered the guest. It is not a preflight attempt.

## Evidence Reached

The physical controls passed the exact structured source-task oracle:

- base: 40 tests, 39 passed, and only
  `tests.test_types::test_choice_get_invalid_choice_message` failed;
- completed: 40 tests and 40 passed;
- both import probes matched the selected source and test files.

The real policy then loaded and attached. Before assignment, lookup returned
`ENOENT` and readdir omitted `ws`. After assigning worker A to completed and
worker B to base, both lookup and readdir exposed `ws`.

The two children entered their cgroups before release from the pre-exec
barrier. Their task intervals overlapped. Both pytest outcomes were correct:
worker A passed 40/40 against completed, while worker B passed 39/40 and failed
only the expected node against base. In both children:

- `PYTHONPATH` contained the exact absolute logical `view/ws/src`;
- `click.__file__` and `click.types.__file__` used that logical pathname;
- logical source and test device/inode matched the independently selected
  completed or base lower tree.

Teardown detached the policy, cleared both target sets, removed both cgroups,
and left the external BPF/FUSE inventory clean. Direct source-file comparisons,
lower metadata records, and the dmesg scan also passed.

## Failure

Both concurrent import probes returned failure only because
`cwd_is_logical_root` was false. The child successfully called
`chdir(view/ws)`, but selecting an existing lower directory gives the process
that lower dentry as its current directory. Attempt 2 recorded only that cwd
did not equal the logical spelling; the v1 import record did not preserve the
actual cwd string. Kernel target-selection and `getcwd()` semantics explain why
a lower-object cwd is expected.

This string equality is not the admitted leakage concern. The concern is
whether the child starts outside the workspace, enters the cgroup before lookup,
resolves the absolute logical path, and then executes from the selected object.
The controller's successful `chdir`, exact logical import paths, and source/test
object identities establish most of this already. The correct cwd check is
exact device/inode identity between the current directory and the assigned
lower workspace root.

The controller failed fast after the concurrent cell, so switch, rollback,
withdrawal, and policy counters were not executed. A failed, incomplete
terminal summary was emitted; no passing complete summary exists. Attempt 2 is
therefore not an RQ1 result.

## Proposed Repair

Record the `getcwd()` string as a raw observation, but replace
`cwd_is_logical_root` with:

- current-directory device/inode equals the assigned physical workspace root;
- logical workspace-root device/inode equals that same assigned root.

Retain every other gate unchanged: exact absolute logical `sys.path`, logical
module pathnames, source/test device/inode, exact 39/1 and 40/0 pytest outcomes,
fresh child protocol, overlap, visibility, lower-file preservation, cleanup,
inventory, and dmesg.

## Independent Review

The independent reviewer agreed that `getcwd()` string equality conflicts with
the implemented target-selection semantics and that exact cwd object identity
is the correct stronger gate. The reviewer found two additional raw-evidence
defects that must be repaired before another run:

- the terminal summary hard-coded six pytest runs and one concurrent pair even
  when fail-fast stopped earlier;
- `prepare_environment()` attributed privilege or environment failures to the
  cgroup move field.

The third preflight remains NO-GO until the import schema records cwd and
workspace-root identities, the finalizer checks those identities directly, the
summary stops reporting hard-coded event counts, and cgroup move errors are
attributed separately. No other static blocker was found.

The complete review is recorded in
`docs/tmp/2026-07-29-agent-workspace-source-task-rq1-preflight-attempt-2-review.md`.
