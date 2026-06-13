# namei_ext Research Plan

## Summary

`namei_ext` explores a `sched_ext`-style extension point for the Linux VFS.
The goal is not to implement a new filesystem. Instead, the kernel keeps
ownership of path walking, dentries, inodes, permission checks, mount traversal,
and lower-filesystem operations, while BPF programs provide a narrow namespace
policy for path resolution and directory views.

The target abstraction is:

```text
parent path + component name + operation context -> namespace decision
```

The initial decisions are:

- `PASS`: continue normal VFS resolution.
- `REDIRECT`: replace the current component with a policy-selected component
  while keeping lookup, permission checks, and file operations in the kernel.

This places `namei_ext` between fixed kernel mechanisms such as bind mounts and
OverlayFS, and fully general user-space filesystems such as FUSE.

## OSDI-Style Framing

现代系统越来越频繁地为每个 workload 构造不同的文件系统视图。构建系统为
每个 action 创建 sandbox，容器和 serverless runtime 组装 root filesystem，
包管理器和开发环境把共享 store 映射成项目私有目录，兼容层把 legacy path
重定向到新的存储布局。这些场景的共同点不是需要一个新文件系统，而是需要在
已有文件之上提供一个动态、隔离、可组合的 namespace view。

现有机制落在两个极端。Bind mount、OverlayFS 等内核机制性能好，并保留
原生 VFS 行为，但策略固定、粒度粗、动态重配置成本高。FUSE 提供了足够灵活
的 namespace 语义，但把大量路径决策移到用户态，引入额外上下文切换，并经常
重复实现 VFS 和 lower filesystem 已经提供的功能。LSM、Landlock、fanotify
和 BPF LSM 可以限制或观察访问，却不能自然表达“这个 workload 看到的路径树
应该长什么样”。

`namei_ext` 的核心观察是：许多真实 workload 需要的是可编程 namespace
policy，而不是可编程 filesystem implementation。因此，`namei_ext` 在 VFS
name resolution 路径中加入一个窄 eBPF 决策点。每次路径解析或目录枚举时，
内核向 BPF 提供 parent path、component name 和事件上下文；BPF 返回受限
动作：`PASS` 或 `REDIRECT`。在 Phase 1 中，`REDIRECT` 把当前 component
重定向到同一父目录下的 backing component，并让 readdir 把 backing entry
以 alias 名字返回。BPF 不创建 dentry，不分配 inode，不实现 file operations，
也不执行递归路径解析。

这种设计保留了内核对文件系统语义的所有权，同时让 namespace view 变成
per-workload 可编程策略。目标是在 build sandbox、container root view、
package environment 等真实场景中，获得接近内核机制的 data-path 行为，
同时避免 FUSE 式全文件系统实现的复杂性和开销。

一句话论文 claim：

```text
namei_ext shows that many filesystem-namespace customization workloads can be
expressed as a narrow in-kernel BPF policy over VFS name resolution, without
turning BPF into a filesystem implementation.
```

## Motivation

Many production systems do not need a full custom filesystem. They need a
different view of an existing directory tree:

- Build systems construct per-action sandboxes from host files.
- Container runtimes present composed root filesystems.
- Package managers and development environments reshape installed trees.
- Multi-tenant platforms expose restricted per-workload file views.
- Compatibility layers redirect legacy paths to new storage layouts.

Existing choices are awkward:

- Symlink forests and copied trees are expensive to create and maintain.
- Bind mounts and OverlayFS are fast, but policy is fixed and coarse.
- FUSE is flexible, but incurs user/kernel crossings and often duplicates logic
  already handled by the lower filesystem.
- LSM, Landlock, and fanotify can restrict or observe access, but they do not
  expose a programmable namespace transformation layer.

`namei_ext` focuses on the common middle ground: programmable filesystem
namespace policy with native lower-filesystem data I/O.

## Design Goals

1. Namespace policy, not filesystem implementation. BPF only decides how a path
   component is treated; VFS and the lower filesystem continue to own filesystem
   semantics.
2. One narrow BPF decision function. Lookup and directory enumeration call the
   same eBPF policy function and use `ctx->event` to distinguish event type.
3. Preserve VFS safety properties. BPF cannot create or hold VFS objects,
   perform recursive path walks, bypass permission checks, or implement file
   operations.
4. Redirect components, not permissions. Phase 1 uses same-parent component
   redirection: BPF writes a bounded redirect component into the context, and
   the kernel performs the resulting lookup through normal VFS machinery.
5. Keep lookup and directory views coherent. `open("/view/foo")` and
   `getdents64("/view")` must be interpreted by the same policy semantics.
6. Scope policy per workload. Phase 1 uses cgroup-scoped attachment because it
   maps directly to build actions, containers, and serverless workers.
   The first ABI admits one `namei_ext` policy at a cgroup decision point;
   multi-policy composition is future work, not an implicit cgroup-BPF side
   effect.
7. Minimize disabled overhead. When no policy is attached, the VFS fast path is
   protected by a static branch and the residual cost must be measured.
8. Stay upstream-shaped. Kernel changes should be small, local, and reviewable:
   new `namei_ext` code where possible, minimal guarded call-site changes in
   existing VFS files.
9. Be artifact-grade. Phase 1 must build the kernel, package the runtime, boot
   KVM, load policy programs, run functional tests and microbenchmarks, and
   emit reproducible results from Makefile-only infrastructure.

## Design Position

The closest analogy is `sched_ext`:

```text
sched_ext:
    kernel owns scheduler machinery
    BPF chooses scheduling policy

namei_ext:
    kernel owns VFS machinery
    BPF chooses namespace resolution policy
```

This is intentionally different from a BPF filesystem:

- BPF does not implement `inode_operations`.
- BPF does not implement `file_operations`.
- BPF does not create dentries or inodes directly.
- BPF does not perform recursive path walks.
- BPF does not handle file data reads, writes, or mmap.

Data operations remain on the lower filesystem, preserving page-cache behavior
and avoiding the main FUSE data-path overhead.

## Kernel Placement

To apply across all filesystems, the extension point must sit above individual
filesystem implementations and below syscall-level policy.

The primary hook belongs in the VFS name resolution path:

```text
openat/statx/execve/rename/unlink/mkdir/...
        |
        v
VFS namei path walk
        |
        +-- namei_ext BPF policy
        |
        v
dcache / mount traversal / lower filesystem
```

The policy object should be `struct path` oriented, not inode oriented:

- A path includes both `vfsmount` and `dentry`.
- The same inode can be reached through multiple paths and hardlinks.
- Mount namespaces, bind mounts, and chroot are path semantics.
- Dcache fast paths may bypass lower filesystem `lookup()` callbacks.

Directory enumeration must also be handled. Path lookup alone can make
`cat /view/foo` work while `ls /view` still does not show `foo`. The design
therefore has one policy abstraction invoked at two VFS boundaries:

- Component lookup during namei path walking.
- Directory enumeration during `getdents64` / `iterate_dir`.

## Proposed Interface

The first prototype exposes one cgroup-attached BPF program type with one
policy function. Lookup and directory enumeration are separate VFS call sites,
but they call the same BPF decision function with a different event type:

```c
SEC("cgroup/namei_ext")
int policy(struct bpf_namei_ext_ctx *ctx);
```

The Phase 1 context is fixed-size. Input fields are read-only, while redirect
output fields are BPF-writable:

```c
#define BPF_NAMEI_EXT_NAME_MAX 64

enum bpf_namei_ext_event {
    BPF_NAMEI_EXT_LOOKUP,
    BPF_NAMEI_EXT_READDIR,
};

struct bpf_namei_ext_ctx {
    u32 event;
    u32 flags;
    u32 name_len;
    u32 name_hash;
    u64 cgroup_id;
    u8 name[BPF_NAMEI_EXT_NAME_MAX];
    u32 redirect_name_len;
    u32 reserved;
    u8 redirect_name[BPF_NAMEI_EXT_NAME_MAX];
};
```

The return value is constrained:

```c
enum bpf_namei_ext_action {
    BPF_NAMEI_EXT_PASS,
    BPF_NAMEI_EXT_REDIRECT,
};
```

For `LOOKUP`, `REDIRECT` means lookup `redirect_name` in the same parent
directory instead of the requested component. For `READDIR`, `REDIRECT` means
emit the current lower entry using `redirect_name` as the user-visible alias.

This avoids full path-string rewrites, recursive path walks, and graph cycles
in Phase 1 while still proving the core programmable namespace-view mechanism.

## Safety Contract

The core paper claim depends on a narrow, enforceable contract:

- BPF can choose namespace policy but cannot own VFS objects.
- Redirect output names are validated as single components by the kernel.
- Phase 1 redirects are non-recursive and same-parent only.
- Policies must not bypass permissions the lower filesystem would not permit.
- Permission checks remain in the normal VFS/lower-filesystem path.
- On BPF failure, verifier rejection, runtime error, or policy timeout, the
  kernel fails closed or falls back to normal VFS behavior according to the
  attachment mode.

The prototype should start with read-mostly namespace views and only later
evaluate writable operations such as create, unlink, and rename.

## Initial Scope

The current Phase 1 semantic slice supports:

- cgroup-scoped policy attachment.
- `PASS` and same-parent component `REDIRECT`.
- `openat`, `statx`, `access`, and `execve` path resolution.
- Directory enumeration that rewrites backing entries into alias entries.
- Read and write data path delegation to the lower filesystem.

Phase 1 should avoid:

- Arbitrary BPF path-string construction.
- BPF-created dentries or inodes.
- Cross-directory or registered-path redirect until the target registry is
  designed.
- Network or remote filesystem semantics.
- Full POSIX writable union semantics.
- Cross-filesystem rename semantics beyond normal VFS behavior.

The detailed Phase 1 engineering design is
[phase1_design.md](phase1_design.md). In short, Phase 1 is not complete until a
clean checkout can build the modified kernel, package the BPF/userspace runtime,
boot the modified kernel in KVM, load a minimal policy, run correctness tests,
run a realistic microbenchmark suite, and emit reproducible results from one
top-level Make target.

## Use Cases

### Build and CI Sandboxes

Build systems often construct a per-action filesystem view. `namei_ext` can
replace symlink forests, copied trees, or FUSE sandboxes with a cgroup-scoped
namespace policy that maps action-visible paths to host files.

Key metrics:

- Sandbox creation latency.
- Metadata operation throughput.
- Build action wall time.
- Number of inodes or symlinks created.

### Container and Serverless Root Views

Container image execution depends on presenting a filesystem tree. `namei_ext`
can support dynamic per-container views while keeping file data on the lower
filesystem and preserving the page cache.

Key metrics:

- Cold-start time.
- Metadata-heavy startup latency.
- Memory overhead per container.
- Comparison against OverlayFS and FUSE-based image systems.

### Package and Development Environments

Package managers and language environments frequently reshape installed files
into project-specific layouts. `namei_ext` can present these layouts without
copying files or maintaining large symlink forests.

Key metrics:

- Environment creation time.
- Directory traversal latency.
- Storage overhead.

### Compatibility and Policy Views

Legacy applications may expect fixed paths. A platform can redirect those paths
to new backing components, with policy scoped per workload.

Key metrics:

- Path lookup overhead.
- Policy update latency.
- Isolation correctness.

## Evaluation Plan

Baselines:

- Native filesystem.
- Bind mounts.
- OverlayFS.
- Symlink forest.
- FUSE passthrough where applicable.
- A simple FUSE path-remapping filesystem.

Microbenchmarks:

- `openat` and `statx` latency.
- Dcache hit and miss paths.
- `getdents64` throughput.
- Path depth sensitivity.
- Policy map lookup overhead.
- Redirect-chain overhead.

Macrobenchmarks:

- A Bazel-style or Ninja-style build sandbox workload.
- Container rootfs startup workload.
- Package environment materialization workload.
- Metadata-heavy source tree traversal.

Correctness tests:

- Symlink handling.
- Hardlink visibility.
- Mount crossing.
- Chroot and mount namespace interaction.
- Permission preservation.
- Rename, unlink, and create behavior if enabled.
- Inotify/fanotify behavior if the prototype exposes directory views.

Phase 1 must turn the evaluation plan into a runnable artifact. The first
benchmark suite should contain realistic metadata-path microbenchmarks:

1. Cache-hot visible lookup over native lower files.
2. Redirected alias lookup where the alias path reaches a backing component.
3. Redirected alias `access` path walks.
4. Redirected alias `open` and failing `execve` path walks over a real backing
   file.
5. Directory-view coherence where `getdents64` lists the alias name and not
   the backing component name.
6. Build/package-style metadata walks over deterministic directories whose
   requested component is redirected to a backing component.

All Phase 1 measurements should run inside KVM on the modified kernel. The
current artifact emits raw JSONL, a Markdown summary, kernel config evidence,
dmesg logs, ABI layout evidence, kernel image hash, Docker image tar hash,
repo and kernel-submodule provenance, config hashes, and a Docker runtime smoke
result. Paper-grade hardening should add more repetitions, randomized order,
tail distributions, system metrics, and stronger baseline systems.

## Related Work Boundary

The related work story should be explicit:

- FUSE provides full user-space filesystem semantics. `namei_ext` targets a
  narrower namespace-policy class and keeps lower-filesystem data I/O native.
- FUSE passthrough reduces data-path overhead for backing files. `namei_ext`
  aims to avoid full FUSE semantics for namespace-only transformations.
- EXTFUSE accelerates FUSE with eBPF. `namei_ext` is not a faster FUSE request
  path; it is a VFS-level namespace extension point.
- OverlayFS and bind mounts provide fixed kernel namespace composition.
  `namei_ext` makes the policy programmable and dynamically scoped.
- Landlock, BPF LSM, and fanotify provide access control or observation.
  `namei_ext` additionally changes what namespace is visible.
- Bento and other safe filesystem frameworks help implement filesystems.
  `namei_ext` deliberately avoids exposing a full filesystem implementation
  interface.

## Research Questions

1. How narrow can the VFS extension interface be while still covering real
   build, container, and package-management workloads?
2. Can a BPF-defined namespace policy preserve VFS safety properties without
   exposing inode or dentry ownership to BPF?
3. How much metadata-path overhead remains compared with native VFS, OverlayFS,
   and FUSE passthrough?
4. What semantics are necessary for directory enumeration to stay coherent with
   redirected lookups?
5. Which writable operations can be safely supported without turning the system
   into a full programmable filesystem?

## Milestones

1. Add infrastructure-as-code configs for kernel, KVM, BPF policy programs,
   and benchmark matrices.
2. Document the kernel code survey for VFS lookup, readdir, locking/RCU,
   dcache, and permission-ordering constraints.
3. Document the one-function BPF ABI rationale, same-parent redirect design,
   functional test plan, and benchmark plan.
4. Add a top-level Makefile and Docker runtime image so `make phase1` builds,
   boots KVM, runs tests, runs benchmarks, and writes results.
5. Build a minimal kernel patch that invokes a BPF policy during namei lookup.
6. Implement cgroup-scoped attachment for Phase 1 isolation.
7. Add directory enumeration support that is coherent with lookup.
8. Run the Phase 1 functional suite inside KVM.
9. Run the Phase 1 microbenchmark suite against native-before-attach and
   attached-policy variants.
10. Add ABI layout/header-sync gates and Docker runtime smoke to the default
   Phase 1 artifact path.
11. Add a referenced backing-path registry and cross-directory redirect support
    if same-parent redirect is not enough for the paper workload set.
12. Add OverlayFS, bind mount, symlink forest, and FUSE baselines for paper
   evaluation.
13. Push the kernel submodule commit and main repository commit as a
   reproducible Phase 1 artifact.
14. Decide whether writable namespace operations are in scope for the first
    paper after the read-mostly PoC is measured.
