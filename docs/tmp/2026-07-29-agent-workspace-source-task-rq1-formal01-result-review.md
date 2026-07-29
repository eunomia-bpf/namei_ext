# Agent Workspace Source-Task RQ1 Formal01 Result Review

## Scope

This review covers the predeclared three-boot formal result:

`results/experiments/agent-workspace-source-task-rq1/20260729T-agent-source-task-formal01/`.

An independent reviewer traced the fixed SWE-Factory-Gym task, controller,
policy, import and pytest oracles, Make finalizer, and every boot's raw records.
The review did not infer validity from the successful Make exit or aggregate
summary.

## Verdict

- Run status: valid.
- Tested hypothesis: supported.
- Research value: decisive for the W2 Agent Workspace case study.
- Paper role: additional headline RQ1 evidence.

The result promotes W2 from a project-authored lifecycle trace alone to a
source-task-backed case study. It is one RQ1 case, not a complete answer to RQ1
by itself.

## Source And Provenance

The formal run records clean project commit
`2329ad18a4fb4565ca0c5f81d5c0111a0b617f4f`, clean kernel commit
`621aff8d1bb52fad718f11fd882c956d6a5686ae`, and three fresh boots of
`7.1.0-rc7-g621aff8d1bb5`.

The Click archive comes from commit
`1787497713fa389435ed732c9b26274c3cdc458d`. The test and gold patches match the
released SWE-Factory-Gym `pallets__click-2622` task assets. The earlier upstream
evaluator reproduction records that task as resolved with 40 passing tests.

## Correctness Evidence

All 12 policy-backed task states and all six direct physical source controls
passed. In each boot:

- physical base, concurrent B base, and rollback base collected 40 tests,
  passed 39, and failed only
  `tests.test_types::test_choice_get_invalid_choice_message`;
- physical completed, concurrent A completed, and switched completed collected
  and passed all 40 tests.

The concurrent intervals overlapped by 1.690, 1.723, and 1.584 seconds. A and B
used the same logical `view/ws` pathname but matched different completed and
base workspace, changed-source, and test objects.

Switch and rollback each launched a fresh child after the acknowledged map
update. B's object identity and task result followed the sequence base 39/1,
completed 40/0, and base 39/1. After withdrawal, lookup returned `ENOENT` and
directory enumeration omitted `ws`.

The 12 policy-backed import records used the exact logical `L/src` entry, while
the six physical source controls used their direct lower `src` paths. All 18
records matched the expected workspace, source, and test objects. For the
policy-backed tasks, module paths remained under `view/ws`, cwd and object
device/inode matched the selected lower tree, and no physical lower path
appeared in `sys.path`.

## Mechanism And Preservation

Each boot recorded 1354 selections. The A-completed, B-base, and B-completed
target-hit counts summed exactly to 1354. Lookup and readdir hide counters were
also positive.

The four relevant lower files remained directly equal to their prepared copies,
and their recorded metadata was unchanged. No Python bytecode or pytest cache
was created in the source trees. Every boot detached the policy, cleared both
target sets, removed both cgroups, left the external BPF/FUSE inventory empty,
and passed the dmesg scan.

## Paper Claim

The supported statement is:

> Across three fresh KVM boots, `namei_ext` gave two concurrent process groups
> different existing Click workspace roots at the same pathname. The released
> task observed 39/40 tests on the base view and 40/40 on the completed view;
> switching and rollback changed both object identity and task outcome, while
> withdrawal hid the workspace.

The result does not demonstrate complete AgentFS compatibility, copy-on-write
workspaces, agent fork/checkpoint, LLM patch generation, the complete
SWE-Factory evaluator, write-path semantics, FUSE superiority, or performance.
