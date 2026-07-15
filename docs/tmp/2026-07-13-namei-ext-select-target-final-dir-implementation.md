# Implementation Record: SELECT_TARGET Final Directory Increment

Date: 2026-07-13

## Motivation

The Agent workspace preflight needs a stable logical workspace root:

```text
view/ws
```

The first `SELECT_TARGET` increment supported `view/ws/file` by selecting the
registered lower directory as an intermediate component, but direct operations
on `view/ws` failed closed. That was too narrow for a workspace-shaped path
view because tools naturally `stat()` and `opendir()` the workspace root before
walking children.

## Change

This increment keeps `SELECT_TARGET` as a bounded directory-selection action and
extends it to final directory operations:

- `kernel/fs/namei_ext.c` still rejects `LOOKUP_CREATE`;
- the Phase-1 debugfs registry accepts `clear` to drop registered targets for
  the current cgroup;
- final `LOOKUP_OPEN` is accepted only when the path walk is for a directory;
- `kernel/fs/namei.c` applies a selected target in `walk_component()` even when
  it is the final component;
- `open_last_lookups()` applies a selected target only for `LOOKUP_DIRECTORY`
  and fails closed with `EOPNOTSUPP` otherwise;
- `namei_ext_apply_target()` continues to require `d_can_lookup()`, so a
  selected target must be a directory;
- functional tests now require `visible/portal` final directory stat and
  `readdir(visible/portal)` to succeed through the selected target;
- functional tests now clear the target registry and verify that reattaching a
  select policy without registering a target fails instead of reusing stale
  state;
- the Agent workspace preflight now requires `stat(view/ws)` and
  `readdir(view/ws)` to succeed in both base and upper epochs, including after a
  generated file is written into upper;
- the FUSE preflight cell checks the same selected-root readdir shape for the
  small oracle.

## Boundary Preserved

The BPF policy still returns only an opaque target ID. It does not return a path
string, allocate a dentry, synthesize directory contents, or perform a recursive
path walk from userspace.

The implementation still fails closed for:

- target ID 0 or unknown target IDs;
- stale target reuse after the Phase-1 registry is cleared;
- create through a final selected target;
- non-directory final open selection;
- final file target selection;
- non-directory registered targets;
- scoped lookup or no-cross-device violations;
- synthetic parent-directory aliases, such as making `readdir(view)` list an
  otherwise nonexistent `ws` entry.

## Files Changed

- `kernel/fs/namei_ext.c`
- `kernel/fs/namei.c`
- `tests/functional/namei_ext_functional.c`
- `tests/agent_workspace/namei_ext_agent_workspace.c`
- `tests/agent_workspace/namei_ext_agent_workspace_fuse.c`
- `docs/design.md`
- `docs/implementation.md`
- `docs/evaluation.md`
- `docs/tmp/2026-07-13-agent-workspace-preflight-implementation.md`
- `docs/paper/sections/03-design.tex`
- `docs/paper/sections/04-implementation.tex`
- `research/STATE.md`

## Validation Performed

Build and object validation:

```text
make bpf functional agent-workspace kernel-objects
```

KVM functional validation:

```text
make kvm-functional
```

Result root:

```text
results/phase1/20260713T031516Z-997cf1c7/
```

Observed final-directory cases:

- `select_portal_final_stat`: direct stat of the selected directory succeeded;
- `select_readdir_view`: `readdir()` over the selected directory exposed the
  lower `payload` entry;
- `select_portal_payload_stat`, `select_portal_payload_open`, and
  `select_portal_payload_read`: children under the selected directory still
  resolve and read correctly.
- `select_clear_targets`: Phase-1 target registry cleanup succeeded.
- `select_unregistered_after_clear`: after cleanup, reattaching the select
  policy without a registered target returned absence rather than reusing stale
  target state.

The functional summary passed with 51 JSONL rows and zero failing cases. The
dmesg fatal scan found no `BUG:`, `WARNING:`, `Oops`, `Call Trace`, hung task,
general-protection fault, KASAN, UBSAN, segfault, or kernel panic signal.

KVM Agent workspace dependency preflight:

```text
make kvm-agent-workspace-preflight
```

Result root:

```text
results/experiments/agent-workspace/20260713T031638Z-46918d26/
```

Observed Agent workspace cases:

- `selected_root_final_visible`: direct stat of `view/ws` succeeded;
- `base_epoch_readdir`: selected-root readdir matched base epoch and hid
  `deleted.txt`;
- `upper_selected_root_final_visible`: direct stat of `view/ws` still
  succeeded after target ID 1 was re-registered to upper;
- `upper_epoch_readdir_before_write`: selected-root readdir matched upper epoch
  before creating `generated.txt`;
- `upper_epoch_readdir_after_write`: selected-root readdir exposed the generated
  upper file while preserving the base non-materialization oracle;
- `clear_targets_after_detach`: Phase-1 target registry cleanup succeeded after
  the preflight policy detached;
- matching FUSE preflight cases passed for the same small oracle shape.

The Agent workspace preflight summary and FUSE preflight summary both passed.
The result file has 45 JSONL rows and zero failing cases. The dmesg fatal scan
found no `BUG:`, `WARNING:`, `Oops`, `Call Trace`, hung task,
general-protection fault, KASAN, UBSAN, segfault, or kernel panic signal.

Paper draft check:

```text
make -C docs/paper check paper
```

The paper check and XeLaTeX build passed after synchronizing the design and
implementation sections with the current selected-target directory behavior.

## Experiment Status

This is still dependency work for Experiment A, not a paper-result row.

It strengthens the preflight by removing the earlier selected-root final
directory gap, but it still does not provide:

- the full AgentFS-derived lifecycle oracle;
- operation-weighted lookup/readdir traces;
- RQ2 latency/runtime comparison against a feature-equivalent full-lifecycle
  FUSE policy;
- parent-directory synthetic alias enumeration;
- final file target selection if the admitted oracle requires it;
- invalid-policy containment review for this final-directory path;
- custom/stackable filesystem boundary audit;
- result-review report.

The next implementation step should be selected from the full Agent workspace
plan, not from legacy table/materialization diagnostics.
