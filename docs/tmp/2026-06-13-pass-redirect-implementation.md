# Implementation Record: PASS/REDIRECT Phase 1

Date: 2026-06-13

## Motivation

The Phase 1 implementation was changed from visibility and access-control
actions to a namespace-view redirect primitive. The new implementation makes
`REDIRECT` the only non-pass action and validates same-parent alias behavior
through lookup and directory enumeration.

## Files Changed

- `kernel/include/uapi/linux/bpf.h`
- `kernel/tools/include/uapi/linux/bpf.h`
- `kernel/include/linux/namei_ext.h`
- `kernel/fs/namei_ext.c`
- `kernel/fs/namei.c`
- `kernel/kernel/bpf/cgroup.c`
- `bpf/include/namei_ext.h`
- `bpf/policies/redirect_alias.bpf.c`
- `tests/abi/namei_ext_abi.c`
- `tests/functional/namei_ext_functional.c`
- `bench/workloads/namei_ext_bench.c`
- `mk/kvm.mk`
- `AGENTS.md`
- `docs/research_plan.md`
- `docs/phase1_design.md`
- `docs/experiment-plans/phase1.md`

## Implementation Details

The UAPI action enum now contains only:

```c
BPF_NAMEI_EXT_PASS = 0,
BPF_NAMEI_EXT_REDIRECT = 1,
```

`struct bpf_namei_ext_ctx` now has BPF-writable redirect output fields:

```c
__u32 redirect_name_len;
__u32 reserved;
__u8 redirect_name[BPF_NAMEI_EXT_NAME_MAX];
```

The verifier permits writes only to `redirect_name_len` and bounded 1, 2, 4, or
8 byte stores within `redirect_name[]`. Input fields remain read-only.

`fs/namei_ext.c` validates redirect components before VFS uses them. Invalid
output returns `-EINVAL`; redirect during `LOOKUP_CREATE` returns
`-EOPNOTSUPP`.

`fs/namei.c` handles redirect by temporarily replacing `nd->last` with a
validated same-parent component for the current lookup/open operation and
restoring the original `qstr` before returning.

`namei_ext_iterate_dir()` handles redirect by emitting the current lower
directory entry under the policy-written alias name.

The policy `redirect_alias.bpf.c` implements:

```text
LOOKUP  tool      -> tool.real
READDIR tool.real -> tool
```

The functional and benchmark suites now create a real backing component
`tool.real` and exercise the user-visible alias `tool`.

## Alternatives Rejected

- Keeping compatibility actions in the ABI was rejected because Phase 1 should
  demonstrate namespace redirection rather than permission mediation.
- Full path rewrites were rejected for Phase 1 because they require recursive
  path parsing and cycle handling.
- A target registry was rejected for this step because same-parent component
  redirect proves the key lookup/readdir coherence property with less kernel
  code.

## Validation

Host-side build checks completed successfully:

```text
make bpf abi functional bench
make kernel-objects
```

The first full `make phase1` run after the redirect rewrite reached KVM
functional validation but the BPF verifier rejected the policy because clang
coalesced adjacent `redirect_name[]` byte stores into an 8-byte context store.
The verifier access rule was then tightened to allow bounded 1, 2, 4, and
8-byte writes within `redirect_name[]` while keeping input fields read-only.

The final validation command was:

```text
make phase1
```

It completed successfully with result directory:

```text
results/phase1/20260613T190520Z-f0ac9710/
```

Report gates:

- Guest smoke events: 2
- ABI failing cases: 0
- Functional failing cases: 0
- Benchmark failing operations: 0
- Docker failing cases: 0
- Dmesg warning/oops/panic lines: 0

The functional suite emitted 24 passing cases, including attach ABI rejection
cases, `alias_before_attach`, `alias_stat`, `alias_open`, `alias_access`,
`alias_read`, `alias_exec`, `readdir_view`, `alias_after_detach`, and
`backing_after_detach`.

The benchmark suite emitted baseline and policy rows for
`lookup_native_hot`, `lookup_tool_redirect`, `access_tool_redirect`,
`open_tool_redirect`, `exec_tool_redirect`, `readdir_alias_view`, and
`build_tree_stat_walk`; every `bench` row had `fail == 0`.

The latest kernel image hash was:

```text
0b465b88272a9ae6fac2cc9af838bf33891508c2fa1a4c2b99257dea03c58228
```

The latest Docker image id was:

```text
sha256:ecea29aede0e7458d9e19b4f57d739e9a5bed606ba5b233c12640fbf89731d5c
```

The ABI checker now verifies:

- `BPF_NAMEI_EXT_REDIRECT == 1`;
- `redirect_name_len` offset `88`;
- `redirect_name` offset `96`;
- `sizeof(struct bpf_namei_ext_ctx) == 160`;
- kernel/tools UAPI header sync.

## Remaining Risks

- Phase 1 redirect is intentionally same-parent and non-recursive.
- Writable alias mutation is not implemented.
- Paper-grade performance evaluation still needs repeated runs, stronger
  baselines, and tail distributions.
