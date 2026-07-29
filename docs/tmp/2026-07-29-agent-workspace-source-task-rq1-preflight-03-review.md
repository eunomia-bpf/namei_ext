# Agent Workspace Source-Task RQ1 Preflight 03 Evidence Review

## Scope

An independent reviewer traced the admitted hypothesis through the current
controller, policy, import and pytest oracles, Make finalizer, and raw preflight
root:

`results/experiments/agent-workspace-source-task-rq1-preflight/20260729T-agent-source-task-preflight03/`.

The review did not infer validity from the successful Make exit. It inspected
the individual raw state, import, timing, visibility, counter, preservation,
cleanup, inventory, dmesg, and provenance records.

## Verdict

GO for the predeclared three-fresh-boot formal run. No evidence or
implementation blocker was found.

## Evidence Review

- The fixed Click source and released SWE-Factory-Gym task patches produced the
  exact physical controls: base 39/40 with only the named failure and completed
  40/40.
- Six independent task-state records exist: two physical controls, two
  concurrent logical views, switch, and rollback.
- Both concurrent children entered distinct cgroups before logical lookup,
  waited at one barrier, and overlapped for 1581848496 ns.
- The same logical `view/ws` pathname selected different completed/base
  workspace, changed-source, and test objects for A and B.
- Switch and rollback each launched a fresh child after the acknowledged map
  update. Their task outcomes and object identities followed the new mapping.
- Withdrawal returned `ENOENT` for lookup and omitted `ws` from enumeration.
- All six import records fixed the absolute logical source path and matched cwd,
  workspace, source, and test device/inode to the selected lower tree.
- Positive lookup, readdir, select, hide, and per-target counters establish
  policy execution.
- Direct source/test comparisons, lower metadata, teardown, external
  BPF/FUSE inventory, and dmesg checks passed.
- Provenance records clean project commit
  `7804bef450cdf33495c11be1dcd0a0d43202668d`, clean kernel commit
  `621aff8d1bb52fad718f11fd882c956d6a5686ae`, and the fixed task identity.

## Claim Boundary

The evidence can support existing-object Agent workspace view selection through
a released software-engineering source task. It does not demonstrate full
AgentFS compatibility, copy-on-write workspaces, patch generation, the complete
SWE-Factory evaluator, an end-to-end agent, or performance.

The formal run must preserve this protocol and pass all gates in each of three
fresh KVM boots. Its result requires a separate independent review.
