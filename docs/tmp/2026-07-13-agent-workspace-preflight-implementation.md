# Implementation Record: Agent Workspace Preflight

Date: 2026-07-13

## Motivation

The current evaluation plan admits an AgentFS-derived workspace lifecycle as
the headline experiment. The full experiment still needs a same-oracle matrix
with `namei_ext`, feature-equivalent FUSE, controls, boundary evidence,
operation-weighted traces, and result review. Before that full matrix, the
project needs a Make-owned KVM preflight that proves the current bounded action
slice can run through the real `cgroup/namei_ext` attach path on an
agent-workspace-shaped path view.

## Change

Added a dependency preflight, not a paper-result experiment:

- `bpf/policies/agent_workspace_view.bpf.c`: selects logical component `ws`
  through registered target ID 1 and hides `deleted.txt` for lookup/readdir;
- `tests/agent_workspace/namei_ext_agent_workspace.c`: creates a base/upper
  workspace fixture, attaches the policy, registers target ID 1 to base and
  then upper, checks stable logical path transition, whiteout-style hide,
  symlink metadata, lower-FS write placement, detach behavior, and nonzero
  operation counters for the policy path;
- `tests/agent_workspace/namei_ext_agent_workspace_fuse.c`: implements the same
  preflight path-view shape as a FUSE policy filesystem, with `/ws` selecting
  base or upper state, `deleted.txt` hidden, symlink metadata preserved, and
  writes landing in the active upper state; it also emits FUSE operation
  counters for the small policy filesystem path;
- `tests/agent_workspace/Makefile`: builds the runner under
  `.build/agent-workspace/`;
- `Makefile`: adds `agent-workspace` and documents
  `kvm-agent-workspace-preflight`;
- `mk/kvm.mk`: adds `kvm-agent-workspace-preflight` and
  `__experiment_agent_workspace_preflight`, writing raw results under
  `results/experiments/agent-workspace/<RUN_ID>/`;
- `bpf/policies/README.md`, `docs/implementation.md`, and
  `docs/evaluation.md`: mark this as dependency preflight only.

## Behavior Tested

The KVM preflight validates:

- before attach, the logical workspace path does not resolve;
- after registering target ID 1 to the base directory, `view/ws/main.txt`
  resolves to base content;
- `view/ws/deleted.txt` is hidden as a whiteout-style path;
- selected-root final directory lookup of `view/ws` succeeds;
- `readdir(view/ws)` lists selected lower-directory entries while preserving
  lookup/readdir coherence for hidden `deleted.txt`;
- after re-registering target ID 1 to the upper directory, the same logical
  path resolves to upper content without remounting or materializing a copy;
- selected-root final directory lookup still succeeds in the upper epoch;
- symlink metadata remains lower-filesystem owned;
- a logical write through `view/ws/generated.txt` lands in the selected upper
  target, appears in `readdir(view/ws)`, and does not materialize into the base
  target;
- the Phase-1 target registry is cleared after policy detach, preventing stale
  registered targets from contaminating later runs;
- after detach, the logical path no longer resolves.
- `namei_ext` policy counters are nonzero for total events, lookup, readdir,
  selected-`ws` lookup, hidden `deleted.txt` lookup, hidden `deleted.txt`
  readdir, and pass-through decisions.

The same Make-owned KVM target now also validates a FUSE policy preflight cell
for the same base/upper/whiteout/symlink/write oracle shape:

- the FUSE policy filesystem mounts and exposes logical `/ws`;
- base and upper epoch reads return the selected backing object;
- `deleted.txt` remains hidden in both epochs;
- selected-root readdir matches the base/upper epoch and hides `deleted.txt`;
- symlink metadata remains lower-filesystem metadata;
- a logical write in the upper epoch lands in upper and does not materialize in
  base;
- the FUSE mount is cleanly unmounted.
- FUSE operation counters are nonzero for getattr, readdir, open, create, read,
  write, readlink, hidden lookup, and hidden readdir.

## Validation

Commands:

```text
make bpf agent-workspace
make kvm-agent-workspace-preflight
```

Previous passing raw root:

```text
results/experiments/agent-workspace/20260713T031638Z-46918d26/
```

Latest passing raw root with operation counters:

```text
results/experiments/agent-workspace/20260713T032434Z-8cbbac1b/
```

Observed artifacts:

- `agent-workspace-preflight.jsonl`: 61 JSONL rows in the follow-up root,
  including start/done rows, `agent_workspace_preflight_summary`,
  `fuse_agent_workspace_preflight_summary`, `agent-workspace-policy-counter`,
  and `agent-workspace-fuse-counter` rows;
- `namei_ext` policy counters in the follow-up root:
  total 111, lookup 82, readdir 29, `select_ws_lookup` 12,
  `hide_deleted_lookup` 2, `hide_deleted_readdir` 3, pass 94;
- FUSE counters in the follow-up root:
  getattr 27, readdir 3, open 2, create 1, read 2, write 1, readlink 2,
  hidden lookup 2, hidden readdir 3;
- failure-row filter found no `"pass": false` rows;
- `dmesg-agent-workspace-preflight.log`: no `BUG:`, `WARNING:`, `Oops:`,
  `Call Trace:`, hung task, general-protection fault, NULL-pointer, KASAN, or
  UBSAN signal.

## Boundary

This is not Experiment A. It is a dependency preflight for the current
`HIDE`/`SELECT_TARGET` directory slice plus a FUSE dependency cell for the same
small oracle shape. The FUSE cell and `namei_ext` cell now both expose the
selected root as a directory and validate readdir over that selected root, but
the preflight still lacks full lifecycle parity and RQ2 measurements. This
preflight does not provide:

- the full AgentFS-derived lifecycle oracle;
- feature-equivalent FUSE comparison for the full AgentFS-derived lifecycle;
- calibrated full-lifecycle operation-weighted lookup/readdir and RQ2 latency
  measurements;
- parent-directory synthetic alias enumeration, such as `readdir(view)` showing
  an otherwise nonexistent `ws` entry;
- final file target selection;
- result-review report;
- custom/stackable filesystem boundary audit.

Those missing cells remain required before any paper claim can use the Agent
workspace experiment as headline evidence.

## Independent Review

A read-only subagent review after the FUSE cell found no blockers. The review
confirmed that the FUSE runner matches the small preflight oracle shape
(base/upper epoch read, whiteout, symlink metadata, upper write placement, and
no base materialization), that the docs keep this as dependency preflight rather
than paper-result evidence, and that the change does not route the Agent
workspace path back to table/materialization baselines.

After the later same-day final-directory increment, the prior `/ws` mismatch is
resolved for selected-root final directory lookup and readdir. The review's
broader caution still applies: this preflight would become misleading if
promoted as full RQ2 evidence without the full AgentFS-derived lifecycle,
operation-weighted traces, latency measurements, and result review.
