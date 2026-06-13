# namei_ext BPF ABI Implementation

Date: 2026-06-13

## Purpose

This note records the implementation that turns the earlier no-op VFS hook into
a cgroup-scoped BPF policy path.

## Implementation Summary

The implemented Phase 1 ABI is:

```c
SEC("cgroup/namei_ext")
int policy(struct bpf_namei_ext_ctx *ctx);
```

The program returns one action:

- `BPF_NAMEI_EXT_PASS`
- `BPF_NAMEI_EXT_HIDE`
- `BPF_NAMEI_EXT_DENY`
- `BPF_NAMEI_EXT_REDIRECT` reserved; currently mapped to `-EOPNOTSUPP`

Lookup and directory enumeration are represented by `ctx->event`, not by two
separate policy functions.

## Kernel Changes

- Added UAPI values in `include/uapi/linux/bpf.h`:
  `BPF_PROG_TYPE_NAMEI_EXT`, `BPF_CGROUP_NAMEI_EXT`,
  `struct bpf_namei_ext_ctx`, event constants, and action constants.
- Mirrored the UAPI header into `tools/include/uapi/linux/bpf.h`.
- Added `CGROUP_NAMEI_EXT` to cgroup BPF attach types.
- Added syscall routing in `kernel/bpf/syscall.c` for load, attach, detach,
  query, and link creation.
- Added verifier access rules and return range `0..3`.
- Added a custom cgroup runner in `kernel/bpf/cgroup.c` because normal cgroup
  filter semantics treat return value `0` as deny, while `namei_ext` treats `0`
  as pass.
- Reused `cgroup_bpf_enabled(CGROUP_NAMEI_EXT)` as the VFS static branch.
- Implemented lookup and readdir action handling in `fs/namei_ext.c`.
- Forced ref-walk fallback by returning `-ECHILD` before running BPF when VFS is
  in `LOOKUP_RCU`.

## Userspace Tooling

The kernel tree `tools/lib/bpf` tables were updated so libbpf recognizes:

```text
cgroup/namei_ext
BPF_PROG_TYPE_NAMEI_EXT
BPF_CGROUP_NAMEI_EXT
```

The project BPF policy `bpf/policies/hide_deny.bpf.c` uses the single policy
function. `hidden` is hidden from lookup and readdir; `denied` remains visible
in readdir but lookup/open returns `EACCES`.

## Validation

Commands run:

```text
make kernel-objects
make -C kernel O=.build/kernel kernel/bpf/cgroup.o kernel/bpf/syscall.o kernel/bpf/verifier.o kernel/bpf/btf.o -j$(nproc)
make kernel
make bpf
make functional
make kvm-functional
```

The first interrupted full kernel build corrupted generated archive files under
`.build/kernel`; cleaning the generated kernel build directory fixed that. The
final `make kernel` completed and produced `arch/x86/boot/bzImage`.

KVM functional evidence:

```text
results/phase1/20260613T154631Z-104213e4/functional.jsonl
```

All functional cases passed in the guest.

## Remaining Risks

- `REDIRECT` is ABI-reserved but not implemented.
- The fixed 64-byte name buffer is sufficient for Phase 1 policies but not a
  complete long-name/string-access design.
- Running active policy in ref-walk mode is correct but may be measurable; the
  benchmark suite records this overhead rather than hiding it.
