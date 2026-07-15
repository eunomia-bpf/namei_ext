# Design Record: Registered Target Selection

Date: 2026-07-13

Same-day follow-up: the first implementation used this design for intermediate
directory selection only. A later increment keeps the same registered
`struct path` design but adds final directory stat and `O_DIRECTORY` readdir
support. See
`docs/tmp/2026-07-13-namei-ext-select-target-final-dir-implementation.md`.
Historical notes below that say final lookup fails closed refer to the first
implementation increment.

## Motivation

The restored paper story requires an AgentFS-derived workspace lifecycle, not a
redirect-only preflight. `PASS`, same-parent `REDIRECT`, and `HIDE` cover
ordinary pass-through, aliasing inside one lower directory, and absence
semantics. They do not cover this required transition:

```text
logical workspace path + workspace state -> existing lower object outside the immediate visible directory
```

Agent workspace base/upper/checkpoint selection needs a bounded mechanism that
can choose an existing lower object without forcing a copy tree, symlink forest,
bind-mount layout, FUSE daemon, or custom filesystem.

## Non-Negotiable Boundary

Registered target selection must keep `namei_ext` as a VFS name-resolution
extension point:

- the kernel owns the target `struct path` reference;
- the policy returns an action plus an opaque target ID, not an arbitrary path
  string;
- lookup/open still resume through normal VFS permission and file-operation
  paths for the selected object;
- the lower filesystem owns data, writes, page cache, persistence, and
  consistency;
- invalid target IDs, stale registrations, non-directory intermediate targets,
  and malformed outputs fail visibly;
- no synthetic file contents, inode allocation, COW write ownership, custom
  metadata persistence, or cross-path transaction semantics are added.

## Minimal ABI Shape

Use a new action:

```c
BPF_NAMEI_EXT_SELECT_TARGET = 3,
```

The BPF context needs a bounded output target field. The lowest-churn prototype
choice is to repurpose the existing 32-bit `reserved` slot as `target_id`:

```c
__u32 redirect_name_len;
__u32 target_id;
__u8 redirect_name[BPF_NAMEI_EXT_NAME_MAX];
```

Layout remains unchanged. The verifier should allow BPF writes to `target_id`
only as a 32-bit store. Existing input fields remain read-only.

For `SELECT_TARGET`, `redirect_name_len` and `redirect_name` are ignored unless
a later design explicitly adds an alias-emission mode. The first implementation
should keep `SELECT_TARGET` lookup-only for the target object selected by the
policy and leave synthetic readdir aliases out of scope.

## Registration API

The selected target must be registered before policy execution. The registry
must store referenced kernel paths, not strings:

```text
(cgroup_id, target_id) -> struct path
```

Registration input should be an `O_PATH` file descriptor supplied by a
Make-owned test/workload runner. The kernel takes a path reference with
`path_get()` and releases it when the target is unregistered, the attachment is
destroyed, or the owning registry is reset.

For the first prototype, it is acceptable to expose a narrow test-only control
surface if it is documented as Phase-1 infrastructure, but it must still take
fds and hold `struct path` references. A string-based path lookup control file
is not acceptable because it would collapse the design into arbitrary path
rewrite.

## Lookup/Open Semantics

For `LOOKUP` on an intermediate component:

1. BPF returns `SELECT_TARGET` and `target_id`.
2. The kernel looks up `(current_cgroup_id, target_id)` in the registry.
3. The registered target must be a directory.
4. The name walk switches `nd->path` to the target directory and continues with
   the next component.

For final-component lookup/open, the broader design target is:

1. BPF returns `SELECT_TARGET` and `target_id`.
2. The kernel looks up the registered target path.
3. The selected path becomes the resolved object for the final component.
4. `open`, `stat`, `access`, and `exec` must still flow through normal VFS
   completion, permission, and file-operation paths.
5. Create-through-select is out of scope for the first prototype and should
   fail closed.

The current implementation does not claim this final-component path. It fails
closed for final-component/open `SELECT_TARGET` and only supports intermediate
directory selection.

The implementation should reject `SELECT_TARGET` in RCU walk and force the
existing `-ECHILD` fallback, matching the current policy execution path.

## Readdir Semantics

Full readdir support requires alias records:

```text
(parent_id, visible_name, target_id)
```

and stable directory positions after lower filesystem iteration. This is the
highest-risk part of the mechanism because repeated `getdents64()` calls must
not duplicate or skip aliases.

The current code increment does not claim full registered-target readdir
support. It should either stay explicit about this limit or, in a later patch:

1. reject `SELECT_TARGET` for `READDIR` with `-EOPNOTSUPP`; or
2. implement a separate alias-record iterator with explicit position semantics
   and KVM tests.

For the Agent workspace full paper experiment, intermediate directory target
selection is now implemented, but any workload row that requires synthetic alias
listing must wait for the alias iterator.

## Validation Plan

The first implementation added a KVM functional case for intermediate directory
selection:

```text
visible/portal/payload -> registered target directory / payload
```

Current required cases:

- selecting an existing directory works for an intermediate path component;
- direct final lookup of the selected component fails closed;
- detach releases the attached policy and restores normal behavior;
- old `PASS`, `REDIRECT`, and `HIDE` functional cases still pass;
- dmesg contains no BUG/WARNING/Oops/panic/hung-task signal.

Additional cases such as final-object selection, invalid-target checks,
non-directory intermediate rejection, explicit registry reset, and synthetic
alias listing should be added only if the admitted source oracle needs those
semantics.

Validated result:

```text
make kvm-functional
results/phase1/20260713T021039Z-a5adda84/functional.jsonl
```

The run passed `select_register_target`, `attach_select_policy`,
`select_portal_payload_stat`, `select_portal_payload_open`,
`select_portal_payload_read`, `detach_select_policy`, and
`select_portal_after_detach`. It also confirmed that direct final lookup of the
selected component fails closed with `EOPNOTSUPP`. The dmesg scan found no BUG,
WARNING, Oops, kernel panic, or hung-task line.

The command must remain Make-owned, and Phase 1 validation must run through the
modified kernel in KVM.

## Paper Status

This design is required infrastructure for the headline Agent workspace
experiment. Implementing it and passing KVM functional tests is still dependency
work. It becomes paper evidence only after the complete Agent workspace matrix
runs under the same source oracle with:

- `namei_ext`;
- feature-equivalent FUSE;
- controls and invalid-policy containment;
- custom/stackable filesystem boundary evidence;
- operation-weighted traces;
- result review.

## Rejected Shortcuts

- BPF-returned absolute or relative path strings: this is arbitrary path
  rewriting, not registered target selection.
- Symlink forests, copies, bind mounts, or OverlayFS setup as the proposed
  mechanism: these are namespace construction mechanisms, not `namei_ext`.
- Userspace daemon callbacks on lookup: this moves the design toward FUSE.
- Treating missing or invalid targets as `PASS`: this hides policy errors and
  invalidates correctness oracles.
