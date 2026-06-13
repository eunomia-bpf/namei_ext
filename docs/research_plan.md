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
- `HIDE`: behave as if the entry does not exist.
- `DENY`: reject the access.
- `REDIRECT`: resolve the component against a registered backing path.

This places `namei_ext` between fixed kernel mechanisms such as bind mounts and
OverlayFS, and fully general user-space filesystems such as FUSE.

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

The first prototype should expose one BPF program type or attachment class:

```c
SEC("namei_ext/resolve")
int BPF_PROG(resolve, struct namei_ext_ctx *ctx);
```

The context should include:

```c
struct namei_ext_ctx {
    struct path *parent;
    const char *name;
    u32 name_len;
    u32 op;
    u32 lookup_flags;
    u64 cgroup_id;
    u64 mntns_id;
};
```

The result should be constrained:

```c
enum namei_ext_action {
    NAMEI_EXT_PASS,
    NAMEI_EXT_HIDE,
    NAMEI_EXT_DENY,
    NAMEI_EXT_REDIRECT,
};

struct namei_ext_result {
    u32 action;
    u32 target_id;
    u32 flags;
};
```

For `REDIRECT`, BPF should select a `target_id` from a kernel-managed registry
of backing paths. User space registers those backing paths through a control
plane, and the kernel holds references to the underlying `struct path` objects.

This avoids letting BPF return arbitrary strings, perform recursive path walks,
or create cycles that the verifier cannot reason about.

## Safety Contract

The core paper claim depends on a narrow, enforceable contract:

- BPF can choose namespace policy but cannot own VFS objects.
- Redirect targets are pre-registered and reference-counted by the kernel.
- Redirect graphs must be acyclic or bounded by kernel-enforced depth.
- Policies must not grant access that the lower filesystem would deny.
- Permission checks remain in the normal VFS/lower-filesystem path.
- On BPF failure, verifier rejection, runtime error, or policy timeout, the
  kernel fails closed or falls back to normal VFS behavior according to the
  attachment mode.

The prototype should start with read-mostly namespace views and only later
evaluate writable operations such as create, unlink, and rename.

## Initial Scope

Phase 1 should support:

- Attach policy by mount namespace or cgroup.
- `PASS`, `HIDE`, `DENY`, and registered-path `REDIRECT`.
- `openat`, `statx`, `access`, and `execve` path resolution.
- Directory enumeration for synthetic or redirected entries.
- Read and write data path delegation to the lower filesystem.

Phase 1 should avoid:

- Arbitrary BPF path-string construction.
- BPF-created dentries or inodes.
- Network or remote filesystem semantics.
- Full POSIX writable union semantics.
- Cross-filesystem rename semantics beyond normal VFS behavior.

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
to new locations while hiding unrelated files, with policy scoped per workload.

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

1. Build a minimal kernel patch that invokes a BPF policy during namei lookup.
2. Add a backing-path registry and `REDIRECT(target_id)` support.
3. Implement cgroup or mount-namespace scoped attachment.
4. Add directory enumeration support.
5. Run lookup and readdir microbenchmarks.
6. Port one build-sandbox or package-environment workload.
7. Evaluate against native, OverlayFS, bind mounts, symlink forests, and FUSE.
8. Decide whether writable operations are in-scope for the first paper.

