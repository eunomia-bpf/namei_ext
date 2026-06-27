# 历史文档：Phase 1 Design: KVM-Runnable PASS/REDIRECT `namei_ext` PoC

> 状态：历史设计记录，已经过期，不作为当前 Phase 1 规范使用。
> 当前规范以 [research_plan.md](/home/yunwei37/workspace/namei_ext/docs/research_plan.md)
> 和 [osdi-evaluation.md](/home/yunwei37/workspace/namei_ext/docs/experiment-plans/osdi-evaluation.md)
> 为准。该文件保留 2026-06-13 早期 same-parent `redirect_alias.bpf.c`
> PoC 的设计背景；它没有覆盖 parent-aware ABI、四类 policy family、W1/W2/W3/W4
> workload gates、W3 Redis checkpoint replay 或当前 C1/C8 降级规则。

## Goal

Phase 1 proves that `namei_ext` is a narrow VFS name-resolution extension point
for programmable path resolution. It is not a BPF filesystem, not a mount
namespace replacement, and not a permission mediation framework. The kernel
keeps ownership of dentries, inodes, mount traversal, lower-filesystem
semantics, and permission checks. A cgroup-attached eBPF policy only chooses
whether a path component is used unchanged or redirected to a backing component.

The Phase 1 claim is:

```text
One cgroup-attached eBPF decision function can keep lookup and readdir coherent
for same-parent path-resolution aliases while the modified kernel boots and
validates inside KVM through one Makefile-owned artifact flow.
```

## Non-Goals

- No BPF-owned dentries, inodes, file operations, page-cache behavior, or data
  path.
- No YAML/JSON policy language. A policy is an eBPF program under
  `bpf/policies/*.bpf.c`.
- No project-owned shell scripts as the control plane. Build, KVM, Docker,
  benchmark, and report steps go through Make targets.
- No full path-string rewrite in Phase 1.
- No cross-directory target registry in Phase 1.
- No create-through-alias, unlink-through-alias, or rename-through-alias
  semantics in Phase 1.
- No multi-policy composition. The current cgroup decision point accepts one
  `namei_ext` policy.

## Public ABI

The kernel-facing BPF ABI exposes one program section:

```c
SEC("cgroup/namei_ext")
int namei_ext_policy(struct bpf_namei_ext_ctx *ctx);
```

Lookup and directory enumeration are event types on that one function:

```c
enum bpf_namei_ext_event {
	BPF_NAMEI_EXT_LOOKUP = 0,
	BPF_NAMEI_EXT_READDIR = 1,
};
```

The action set is intentionally small:

```c
enum bpf_namei_ext_action {
	BPF_NAMEI_EXT_PASS = 0,
	BPF_NAMEI_EXT_REDIRECT = 1,
};
```

The BPF context contains read-only input fields and BPF-writable redirect output
fields:

```c
#define BPF_NAMEI_EXT_NAME_MAX 64

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

For `LOOKUP`, `REDIRECT` means the kernel looks up `redirect_name` in the same
parent directory instead of the requested component. For `READDIR`, `REDIRECT`
means the kernel emits the current lower entry using `redirect_name` as the
user-visible component. This makes `stat("/x/tool")` and
`getdents64("/x")` agree when `tool` is an alias for `tool.real`.

Redirect output is validated by the kernel:

- `redirect_name_len` must be in `1..BPF_NAMEI_EXT_NAME_MAX`;
- the redirected component cannot contain `/` or NUL;
- `.` and `..` are invalid redirect components;
- `LOOKUP_CREATE` with redirect returns `-EOPNOTSUPP` in Phase 1.

## Kernel Implementation

The kernel patch is intentionally narrow:

- `fs/namei.c` calls `namei_ext_lookup()` from `walk_component()` and
  `open_last_lookups()`. If the policy redirects, the call site temporarily
  replaces `nd->last` with a validated same-parent component and restores the
  original `qstr` before returning.
- `fs/readdir.c` routes `iterate_dir()` through `namei_ext_iterate_dir()` when
  the cgroup static key is enabled.
- `fs/namei_ext.c` builds the BPF context, runs the cgroup-attached program,
  validates redirect output, and maps redirect decisions to VFS operations.
- `kernel/bpf/cgroup.c` adds the custom cgroup runner and verifier access rules
  for `struct bpf_namei_ext_ctx`. Input fields are read-only; redirect output
  fields are writable.
- `kernel/bpf/verifier.c` constrains return values to `PASS..REDIRECT`.

The attach ABI is also narrow:

- `BPF_PROG_TYPE_NAMEI_EXT` must load with
  `expected_attach_type == BPF_CGROUP_NAMEI_EXT`.
- `BPF_PROG_ATTACH` accepts no attach flags for this program type.
- `BPF_LINK_CREATE` is rejected for this program type in Phase 1 because the
  generic cgroup link path implies multi-attach semantics.

## Policy

The Phase 1 policy is `bpf/policies/redirect_alias.bpf.c`.

It implements a deterministic alias:

```text
LOOKUP  "tool"      -> "tool.real"
READDIR "tool.real" -> "tool"
```

There is no policy configuration file. The policy source is the policy.

This use case models package, build, and container path-resolution behavior
where a workload keeps using a stable path while the platform selects a
versioned backing component.
For example, a build action can access `tool`, while the lower filesystem stores
the selected implementation as `tool.real`.

## Functional Tests

`tests/functional/namei_ext_functional.c` creates a real lower directory with:

```text
native
tool.real
```

Before attaching the policy, `tool` is absent and `tool.real` exists. After
attaching the policy:

- `stat("tool")` succeeds through `tool.real`;
- `open("tool")` succeeds through `tool.real`;
- `access("tool", X_OK)` succeeds through `tool.real`;
- reading `tool` returns the contents of `tool.real`;
- `execve("tool")` reaches `tool.real` and fails with the lower file's normal
  executable-format error;
- `readdir()` lists `native` and `tool`, not the backing component name;
- detaching the policy makes `tool` absent again while `tool.real` remains.

The same suite keeps the attach ABI tests:

- correct attach type accepted;
- wrong attach type rejected;
- multi/override/replace attach flags rejected;
- cgroup link attach rejected.

## Microbenchmarks

The Phase 1 microbenchmarks are smoke-scale but use real VFS operations:

1. `lookup_native_hot`: repeated `stat()` on a normal lower file.
2. `lookup_tool_redirect`: baseline `stat()` on `tool.real`, policy `stat()` on
   `tool`.
3. `access_tool_redirect`: baseline `access()` on `tool.real`, policy
   `access()` on `tool`.
4. `open_tool_redirect`: baseline `open()` on `tool.real`, policy `open()` on
   `tool`.
5. `exec_tool_redirect`: baseline `execve()` on `tool.real`, policy `execve()`
   on `tool`.
6. `readdir_alias_view`: baseline lists the backing component, policy lists the
   alias component.
7. `build_tree_stat_walk`: deterministic package-style directories where each
   requested `tool` component redirects to a local `tool.real`.

Collectors write raw JSONL rows only. Interpretation, ratios, confidence
intervals, and paper tables belong in report or analysis targets.

## Infrastructure

The default Phase 1 flow is:

```text
make phase1
```

That target builds the BPF policy, user-space tests, benchmark binary, modified
kernel, KVM runs, Docker runtime smoke, provenance artifacts, and Markdown
summary. KVM boots the modified kernel and runs the privileged validation path.
Docker packages runtime dependencies and project artifacts; it is not a
substitute for KVM validation.

Generated artifacts live under documented roots:

- `.build/` for build outputs;
- `.cache/` for downloaded/cache/image artifacts;
- `results/phase1/<run-id>/` for raw JSONL, dmesg, configs, hashes, metadata,
  and reports;
- `docs/tmp/` only for Markdown research and implementation records.

## Result Evidence

A Phase 1 result directory must contain:

- `guest-smoke.jsonl`;
- `abi.jsonl`;
- `functional.jsonl`;
- `bench.jsonl`;
- `docker.jsonl`;
- `metadata.json`;
- repo head/status sidecars;
- kernel and Docker image identity;
- config hashes;
- `kernel-cmdline.txt`;
- KVM dmesg logs;
- `summary.md`.

`make report` must fail if ABI, functional, benchmark, Docker, or dmesg gates
record a failure.

## Completion Criteria

Phase 1 is complete when all of these are true:

1. The modified kernel builds with `CONFIG_NAMEI_EXT=y`.
2. UAPI and BPF-local ABI checks agree on enum values, context layout, and
   kernel/tools header sync.
3. The BPF policy loads and attaches through the real `cgroup/namei_ext` path.
4. Same-parent `PASS/REDIRECT` works for lookup, open, access, exec path walk,
   and readdir.
5. Functional and benchmark suites run inside KVM on the modified kernel.
6. `make phase1` exits 0 and emits raw reproducibility artifacts.
7. The design and research plans describe redirect-based programmable path
   resolution as the Phase 1 semantic surface.
