# Implementation Record: namei_ext SELECT_TARGET Increment

Date: 2026-07-13

Same-day follow-up: the first increment described below was later extended to
support final directory stat and `O_DIRECTORY` readdir over selected targets.
See
`docs/tmp/2026-07-13-namei-ext-select-target-final-dir-implementation.md` for
the current final-directory validation. Historical statements below about
direct final lookup failing closed describe the first increment only.

## Motivation

The headline Agent workspace experiment needs more than same-parent aliases and
hidden names. A workspace policy must be able to map a logical directory
component to an existing lower directory outside the immediate visible parent:

```text
visible/portal/payload -> registered lower target directory / payload
```

This is still a name-resolution action. The lower filesystem keeps ownership of
the selected directory, file data, permissions, page cache, writes, and
persistence.

## Implemented Scope

This increment adds:

- `BPF_NAMEI_EXT_SELECT_TARGET = 3`;
- `target_id` as a bounded BPF output field, reusing the previous 32-bit
  reserved slot without changing `struct bpf_namei_ext_ctx` size;
- verifier support for 32-bit writes to `target_id`;
- a kernel-held target registry keyed by `(cgroup_id, target_id)`;
- a Phase-1 debugfs registration file,
  `/sys/kernel/debug/namei_ext/register_target`, that accepts `target_id fd`;
- fd-backed registration using `fdget_raw()` so `O_PATH` fds are accepted;
- intermediate-directory pathwalk selection in `walk_component()`;
- hard rejection for final-component/open selection and `READDIR`
  `SELECT_TARGET`;
- `bpf/policies/select_portal.bpf.c`, a minimal policy that selects target ID
  1 for the component `portal`;
- KVM functional tests for registered target selection.

## Boundary Preserved

The BPF policy never returns a path string. It returns an opaque target ID. The
kernel resolves that ID to a referenced `struct path` that was registered from
an fd before policy execution.

The implementation fails closed for:

- target ID 0;
- unknown target IDs;
- create/open final-component selection;
- final lookup selection;
- synthetic readdir aliasing;
- non-directory targets used as intermediate path components;
- scoped lookup or no-cross-device violations.

## Files Changed

- `kernel/include/uapi/linux/bpf.h`
- `kernel/tools/include/uapi/linux/bpf.h`
- `bpf/include/namei_ext.h`
- `kernel/include/linux/namei_ext.h`
- `kernel/kernel/bpf/cgroup.c`
- `kernel/kernel/bpf/verifier.c`
- `kernel/fs/namei_ext.c`
- `kernel/fs/namei.c`
- `bpf/policies/select_portal.bpf.c`
- `bpf/policies/README.md`
- `tests/abi/namei_ext_abi.c`
- `tests/functional/namei_ext_functional.c`
- `mk/kvm.mk`

## Validation Performed

Host-side validation:

```text
make abi bpf functional
make kernel-objects
```

KVM validation:

```text
make kvm-functional
```

Result root:

```text
results/phase1/20260713T021039Z-a5adda84/
```

Observed SELECT_TARGET cases:

- `select_portal_before_attach`: `visible/portal/payload` is absent before
  policy attach.
- `select_register_target`: target directory registered through debugfs using
  an fd.
- `attach_select_policy`: BPF policy loaded and attached.
- `select_portal_final_rejected`: direct final lookup of `visible/portal`
  fails closed with `EOPNOTSUPP`.
- `select_portal_payload_stat`: intermediate selected path resolves.
- `select_portal_payload_open`: selected payload opens.
- `select_portal_payload_read`: selected payload content matches.
- `detach_select_policy`: policy detaches.
- `select_portal_after_detach`: selected path becomes absent again.

The same KVM run also revalidated HIDE and same-parent REDIRECT behavior. The
functional summary reported zero failing cases. The dmesg scan found no BUG,
WARNING, Oops, kernel panic, or hung-task line.

## Remaining Work

This is still dependency work, not a paper result. The next steps are:

1. Select the exact AgentFS-derived workspace oracle row that will determine
   whether intermediate directory selection is enough or whether final-object
   selection and synthetic readdir aliasing are required.
2. Add only the registered-target semantics needed by that admitted oracle.
3. Build the complete Agent workspace experiment matrix: `namei_ext`,
   feature-equivalent FUSE, controls, boundary evidence, operation-weighted
   traces, raw results, and result review.

## Risks

- The debugfs registration file is Phase-1 control-plane infrastructure. It is
  acceptable for KVM validation but should not be presented as the final user
  API.
- The registry currently has no explicit unregister operation. Replacing a
  target ID releases the old path, and the Phase-1 KVM test lifetime is short,
  but a long-running workload will need explicit cleanup or attachment-owned
  lifetime.
- Synthetic readdir aliases are intentionally not implemented yet because they
  require stable position semantics across repeated `getdents64()` calls.
