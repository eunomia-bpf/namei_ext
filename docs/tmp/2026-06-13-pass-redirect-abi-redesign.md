# Research Record: PASS/REDIRECT ABI Redesign

Date: 2026-06-13

## Motivation

Review found that the previous Phase 1 action set, `PASS/HIDE/DENY`, made
`namei_ext` look too much like an LSM-style mediation hook. `DENY` is access
control, and `HIDE` is a special negative-lookup/filtering action. Neither is
the central reason to add a VFS name-resolution extension point.

The Phase 1 semantic surface should therefore be reduced to the mechanism that
distinguishes `namei_ext`: programmable path resolution. A policy should
either leave VFS behavior unchanged or redirect a component/view to a different
kernel-owned component.

## Code Paths Inspected

- `kernel/fs/namei.c`
  - `walk_component()`
  - `open_last_lookups()`
- `kernel/fs/readdir.c`
  - `iterate_dir()`
- `kernel/fs/namei_ext.c`
- `kernel/kernel/bpf/cgroup.c`
  - `__cgroup_bpf_run_namei_ext()`
  - `namei_ext_is_valid_access()`
- `kernel/kernel/bpf/verifier.c`
- `kernel/include/uapi/linux/bpf.h`
- `kernel/tools/include/uapi/linux/bpf.h`
- `bpf/include/namei_ext.h`
- `tests/functional/namei_ext_functional.c`
- `bench/workloads/namei_ext_bench.c`

## Design

Phase 1 now has two public actions:

- `BPF_NAMEI_EXT_PASS`: preserve the original VFS lookup or directory entry.
- `BPF_NAMEI_EXT_REDIRECT`: replace the current component with a policy-written
  redirect component.

The BPF context keeps the original component as read-only input and adds a
BPF-writable redirect output:

```c
struct bpf_namei_ext_ctx {
	__u32 event;
	__u32 flags;
	__u32 name_len;
	__u32 name_hash;
	__u64 cgroup_id;
	__u8 name[BPF_NAMEI_EXT_NAME_MAX];
	__u32 redirect_name_len;
	__u32 reserved;
	__u8 redirect_name[BPF_NAMEI_EXT_NAME_MAX];
};
```

For `LOOKUP`, `REDIRECT` means: lookup the redirected component in the same
parent directory instead of the original requested component.

For `READDIR`, `REDIRECT` means: emit the current lower entry under the
redirect component name. This gives directory views that match lookup aliases
without adding a `HIDE` primitive.

The first implementation is deliberately same-parent component redirection. It
does not implement whole-path rewrite, cross-directory target registries, fd
registries, writable alias creation, recursive redirects, or policy
composition.

## Constraints

- A policy remains a single eBPF program under `bpf/policies/*.bpf.c`.
- There are no YAML/JSON policy files or custom configuration languages.
- Lookup and readdir remain event types on one BPF decision function.
- `HIDE` and `DENY` are removed from semantics, tests, use cases, and ABI
  layout checks.
- The kernel keeps ownership of dentries, inodes, permissions, and lower
  filesystem semantics. Redirected targets are still opened through normal VFS
  lookup and permission checks.
- Redirect names are single path components. Empty names, slash-containing
  names, NUL-containing names, `.`, and `..` are invalid.

## Alternatives Rejected

- Keeping `HIDE` and `DENY` as compatibility actions was rejected because they
  keep the Phase 1 story anchored on LSM-like mediation.
- Implementing full-path string rewrites in the BPF context was rejected
  because it would add path parsing, lifetime, and privilege questions before
  proving the core redirect hook.
- Using a kernel fd/path registry in Phase 1 was rejected because the current
  phase can prove the path-resolution substrate with less code by redirecting
  same-parent components.
- Silently treating invalid redirect output as `PASS` was rejected. Invalid
  policy output should fail the operation so tests catch verifier or policy
  bugs.

## Validation Plan

The implementation must update:

- UAPI and BPF-local headers to expose only `PASS` and `REDIRECT`;
- verifier return range to reject old `HIDE/DENY` returns;
- BPF context access rules so policy can write redirect output fields;
- functional tests to prove alias lookup/open/access/exec/readdir behavior;
- microbenchmarks to measure realistic redirect workloads;
- Makefile KVM targets to load the redirect policy object;
- design and research documents so no Phase 1 use case depends on hide/deny.

The final gate remains `make phase1` inside KVM with zero ABI, functional,
benchmark, Docker, and dmesg failures.
