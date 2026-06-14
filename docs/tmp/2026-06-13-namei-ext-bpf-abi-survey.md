# namei_ext BPF ABI Survey

Date: 2026-06-13

## Purpose

This note records the Phase 1 ABI decision for connecting VFS lookup and
directory enumeration to eBPF. The goal is to keep the kernel patch small,
upstream-shaped, and runnable in KVM while preserving the project invariant
that one policy is one eBPF program, not a policy configuration file.

## Files Inspected

- `kernel/include/uapi/linux/bpf.h`
- `kernel/include/linux/bpf_types.h`
- `kernel/include/linux/bpf-cgroup-defs.h`
- `kernel/include/linux/bpf-cgroup.h`
- `kernel/kernel/bpf/cgroup.c`
- `kernel/kernel/bpf/syscall.c`
- `kernel/kernel/bpf/verifier.c`
- `kernel/kernel/bpf/btf.c`
- `kernel/fs/namei.c`
- `kernel/fs/readdir.c`
- `kernel/include/linux/fs.h`

## Kernel Paths Relevant To The ABI

The existing VFS hook prototype already proves where `namei_ext` needs to run:

- path component lookup: `walk_component()` in `fs/namei.c`;
- final open component: `open_last_lookups()` in `fs/namei.c`;
- directory enumeration: `iterate_dir()` in `fs/readdir.c`, wrapping the
  `dir_context.actor` callback.

`walk_component()` and `open_last_lookups()` can run in RCU walk mode. The BPF
program should not execute there in Phase 1 because it uses cgroup attachment
state and a normal BPF run context. The safe VFS-shaped behavior is to return
`-ECHILD` when a policy is active and `LOOKUP_RCU` is set, forcing the existing
ref-walk fallback before evaluating the policy.

`iterate_dir()` has already passed `security_file_permission()` and
`fsnotify_file_perm()` before calling the filesystem iterator. Its
`dir_context.actor` returns `bool`: returning `true` continues enumeration, and
returning `false` stops. A `namei_ext` wrapper can hide an entry by not calling
the original actor and returning `true`.

## ABI Shape

Phase 1 should add one cgroup-scoped BPF program type:

```c
BPF_PROG_TYPE_NAMEI_EXT
BPF_CGROUP_NAMEI_EXT
```

The program receives one context pointer and returns one action:

```c
SEC("cgroup/namei_ext")
int policy(struct bpf_namei_ext_ctx *ctx)
{
	/* Return BPF_NAMEI_EXT_PASS, HIDE, DENY, or REDIRECT. */
}
```

The context is fixed-size and read-only from BPF:

```c
#define BPF_NAMEI_EXT_NAME_MAX 64

struct bpf_namei_ext_ctx {
	__u32 event;
	__u32 flags;
	__u32 name_len;
	__u32 name_hash;
	__u64 cgroup_id;
	__u8  name[BPF_NAMEI_EXT_NAME_MAX];
};
```

The `event` field distinguishes call sites:

- `BPF_NAMEI_EXT_LOOKUP`: path component lookup or final open component;
- `BPF_NAMEI_EXT_READDIR`: a directory entry emitted by `iterate_dir()`.

The action enum is:

- `BPF_NAMEI_EXT_PASS`: continue normal VFS behavior;
- `BPF_NAMEI_EXT_HIDE`: make the name invisible at this operation;
- `BPF_NAMEI_EXT_DENY`: fail the operation with an access error;
- `BPF_NAMEI_EXT_REDIRECT`: reserved for the later redirect registry; Phase 1
  may return `-EOPNOTSUPP` until the target representation is implemented.

This preserves the user's requirement that the kernel-facing ABI expose one
decision function. Lookup and readdir are events in the same context, not two
policy interfaces.

## Why Cgroup Scope

The realistic workloads named in the research plan are build actions,
container-like roots, package environments, and tenant-specific path-resolution
views. Those are naturally scoped to a process subtree, not to a global kernel
switch. Existing cgroup BPF infrastructure already provides:

- program attachment and detachment lifecycle;
- inherited effective program arrays;
- static-branch enablement through `cgroup_bpf_enabled_key[atype]`;
- local storage helper compatibility through `bpf_cg_run_ctx`;
- a syscall and link model userspace already understands.

The implementation should therefore reuse `CGROUP_*` plumbing rather than
inventing a separate global `namei_ext` registry in Phase 1.

## cgroup BPF Changes Required

The internal cgroup enum in `include/linux/bpf-cgroup-defs.h` needs a new
`CGROUP_NAMEI_EXT` value before `CGROUP_LSM_START`.

`include/linux/bpf-cgroup.h` needs to map `BPF_CGROUP_NAMEI_EXT` to
`CGROUP_NAMEI_EXT` and declare a runner for the VFS hook.

`kernel/bpf/syscall.c` needs the new attach type in:

- `attach_type_to_prog_type()`;
- `is_cgroup_prog_type()`;
- `bpf_prog_detach()`;
- `bpf_prog_query()`;
- `link_create()`.

`include/linux/bpf_types.h` needs the new program type entry so the BPF core
can find `namei_ext_verifier_ops` and `namei_ext_prog_ops`.

`kernel/bpf/btf.c` should classify the new program type as a cgroup kfunc hook
if kfunc dispatch asks for a hook type.

`kernel/bpf/verifier.c` must allow the program to return the action range
`0..3`, not the usual cgroup filter range `0..1`.

## Runner Semantics

The normal cgroup helper `bpf_prog_run_array_cg()` converts return value `0`
into `-EPERM` for cgroup filter semantics. That is not usable for
`namei_ext`, where `0` means `PASS`. Phase 1 should add a small custom cgroup
runner that:

1. gets `task_dfl_cgroup(current)` under RCU;
2. reads the effective `CGROUP_NAMEI_EXT` program array;
3. sets `bpf_cg_run_ctx` so cgroup local storage helpers keep working;
4. runs programs in order;
5. stops on the first non-`PASS` action;
6. returns `PASS` when the current cgroup has no effective program.

This gives multi-program composition a simple and reviewable rule:
first non-pass action wins.

## Context Access

The verifier should permit read-only access to scalar fields and byte reads from
`ctx->name[]`. The first Phase 1 policy programs can compare literal names
without adding custom helpers:

```c
if (ctx->event == BPF_NAMEI_EXT_LOOKUP &&
    ctx->name_len == 6 &&
    ctx->name[0] == 's' && ctx->name[1] == 'e' &&
    ctx->name[2] == 'c' && ctx->name[3] == 'r' &&
    ctx->name[4] == 'e' && ctx->name[5] == 't')
	return BPF_NAMEI_EXT_HIDE;
```

The fixed 64-byte name buffer is intentionally conservative. It is enough for
the Phase 1 policies and avoids pointer lifetime, path construction, and string
helper complexity. Longer names remain visible through `name_len`, but only the
first `BPF_NAMEI_EXT_NAME_MAX` bytes are copied into the context.

## Alternatives Rejected

### Two BPF Functions

Separate lookup and readdir BPF programs would be easier to wire mechanically,
but it would violate the project invariant. It also creates unnecessary policy
duplication: realistic policies usually need consistent treatment across
lookup and directory listing. A single function with `ctx->event` makes
coherence testable.

### LSM Hook Only

LSM BPF can restrict operations, but it is not a good fit for path-resolution
transformation semantics such as hiding from readdir or redirecting names. The
goal is not another permission hook; it is a VFS path-resolution decision point that
can later express controlled transformations.

### FUSE/Filesystem Implementation

A FUSE or pseudo-filesystem implementation would own dentries/inodes and would
move the project away from the intended narrow VFS extension point. Phase 1
should prove that the kernel can keep normal filesystem ownership while BPF
supplies only the path-resolution decision.

### Global Attachment

A global policy is simpler to prototype but does not match build sandbox,
container, and package environment workloads. It also makes tests less
realistic because all processes would share the same path-resolution policy.

## Risks And Follow-up

- Redirect needs a target representation and likely a registry or map-backed
  target table. Phase 1 can reserve the action and initially reject it.
- The fixed name buffer is enough for PoC policies but not a full path language.
  If later work needs longer names, a helper or dynptr-style access should be
  designed explicitly.
- Returning `-ECHILD` for active policies in RCU walk adds a measurable
  overhead mode. Benchmarks must separate disabled-policy overhead from
  attached-policy overhead.
- Userspace tools must understand the new program and attach types. The
  shortest Phase 1 path is to update the kernel tree's `tools/lib/bpf` section
  table and use a tiny loader in the KVM guest.
