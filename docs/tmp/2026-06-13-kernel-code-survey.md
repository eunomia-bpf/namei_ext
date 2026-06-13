# Kernel Code Survey: VFS Lookup And Readdir Hook Points

Date: 2026-06-13
Kernel commit: `062871f1371b2e02a272ff5279c6479aff0a37ef`

## Purpose

This survey is the mandatory pre-implementation record for the Phase 1 kernel
patch. The goal is to identify the smallest VFS hook points that can support
one `namei_ext` eBPF decision function for lookup and directory enumeration,
while preserving VFS ownership of path walking, dentries, inodes, mount
traversal, permission checks, and lower-filesystem operations.

The key design constraint is:

```text
one BPF policy function, multiple kernel call sites
```

The BPF ABI remains one function. The kernel may call it from more than one VFS
location because `open()` and `getdents64()` do not share one internal call
site with all other lookups.

## Files Inspected

- `kernel/fs/namei.c`
- `kernel/fs/readdir.c`
- `kernel/include/linux/fs.h`

Important inspected functions:

- `link_path_walk()` at `kernel/fs/namei.c:2574`
- `walk_component()` at `kernel/fs/namei.c:2261`
- `lookup_fast()` at `kernel/fs/namei.c:1838`
- `lookup_slow()` at `kernel/fs/namei.c:1925`
- `may_lookup()` at `kernel/fs/namei.c:1951`
- `step_into()` at `kernel/fs/namei.c:2126`
- `handle_dots()` at `kernel/fs/namei.c:2223`
- `path_lookupat()` at `kernel/fs/namei.c:2797`
- `filename_lookup()` at `kernel/fs/namei.c:2830`
- `open_last_lookups()` at `kernel/fs/namei.c:4563`
- `lookup_open()` at `kernel/fs/namei.c:4406`
- `path_openat()` at `kernel/fs/namei.c:4838`
- `may_open()` at `kernel/fs/namei.c:4238`
- `may_o_create()` at `kernel/fs/namei.c:4322`
- `iterate_dir()` at `kernel/fs/readdir.c:87`
- `filldir64()` and `getdents64()` at `kernel/fs/readdir.c:341` and
  `kernel/fs/readdir.c:384`
- `struct dir_context` at `kernel/include/linux/fs.h:1857`
- `dir_emit()` at `kernel/include/linux/fs.h:3572`

## Lookup Path Summary

Generic path lookup enters through `filename_lookup()`, which first calls
`path_lookupat()` with `LOOKUP_RCU`, then retries without RCU on `-ECHILD`, and
retries with `LOOKUP_REVAL` on `-ESTALE`.

`path_lookupat()` initializes the starting path with `path_init()`, then loops:

```text
link_path_walk()
lookup_last()
complete_walk()
```

`link_path_walk()` parses each path component. For each real component it:

1. calls `may_lookup()` on the current parent directory before component lookup;
2. parses and hashes `nd->last`;
3. classifies `.` / `..` / normal names;
4. calls `walk_component()` for intermediate components and nested symlink
   continuations.

`walk_component()` handles only normal components through:

```text
lookup_fast()
  -> __d_lookup_rcu() or __d_lookup()
  -> d_revalidate()
lookup_slow()
  -> inode_lock_shared()
  -> __lookup_slow()
  -> filesystem ->lookup()
step_into()
  -> mount traversal
  -> symlink handling
  -> nd->path update
```

`handle_dots()` owns `.` and `..`; `..` must respect root, mount, scoped lookup,
rename sequence, and mount sequence constraints. Phase 1 should not special-case
or redirect `.` or `..`.

## Open Path Summary

`open()` does not use `lookup_last()` for the final component. It enters
`do_file_open()`, then `path_openat()`, which loops:

```text
path_init()
link_path_walk()
open_last_lookups()
do_open()
```

`open_last_lookups()` has its own final-component logic:

- handles `.` / `..`;
- calls `lookup_fast_for_open()`;
- if necessary drops out of RCU mode;
- takes the parent inode lock;
- calls `lookup_open()`;
- supports `O_CREAT`, `atomic_open`, and create permission checks.

Therefore a hook only in `walk_component()` would miss the final path component
for normal `openat()` calls. Phase 1 needs an additional final-open call site in
`open_last_lookups()` or a shared helper invoked by both `walk_component()` and
`open_last_lookups()`.

## Readdir Path Summary

`getdents64()` creates a `getdents_callback64` whose embedded
`struct dir_context` has `ctx.actor = filldir64`, then calls `iterate_dir()`.

`iterate_dir()`:

1. checks that the file has `iterate_shared`;
2. calls `security_file_permission(file, MAY_READ)`;
3. calls `fsnotify_file_perm(file, MAY_READ)`;
4. takes `inode->i_rwsem` shared;
5. sets `ctx->pos = file->f_pos`;
6. calls `file->f_op->iterate_shared(file, ctx)`;
7. writes back `file->f_pos = ctx->pos`;
8. emits fsnotify/access side effects.

Filesystems emit entries through `dir_emit()` or direct `ctx->actor()` calls.
The generic place to filter directory entries is therefore an actor wrapper
around the caller-provided `dir_context`, not every filesystem's iterator.

`struct dir_context` contains the actor, position, count, and d_type flags.
The wrapper must preserve `ctx->pos`, `ctx->count`, and actor return semantics.

## Permission And Security Ordering

Traversal permission is checked before component lookup:

```text
link_path_walk()
  -> may_lookup()
     -> lookup_inode_permission_may_exec()
```

Open permission is checked after final path resolution:

```text
do_open()
  -> may_open()
     -> inode_permission(..., MAY_OPEN | acc_mode)
  -> vfs_open()
  -> security_file_post_open()
```

Create permission is handled separately:

```text
lookup_open()
  -> may_o_create()
     -> security_path_mknod()
     -> inode_permission(parent, MAY_WRITE | MAY_EXEC)
     -> security_inode_create()
```

Readdir permission is checked before invoking filesystem iteration:

```text
iterate_dir()
  -> security_file_permission(file, MAY_READ)
  -> fsnotify_file_perm(file, MAY_READ)
  -> filesystem iterate_shared()
```

Implication: a `namei_ext` redirect must not skip normal target permission
checks. For final file opens, the redirected `nd->path` must still flow through
`do_open()` and `may_open()`. For intermediate directory redirects, the next
component's `may_lookup()` must run on the redirected target directory.

## RCU And Ref-Walk Constraints

Path lookup starts in RCU mode for common user lookups and open:

- `filename_lookup()` calls `path_lookupat(... | LOOKUP_RCU)`.
- `do_file_open()` calls `path_openat(... | LOOKUP_RCU)`.

The existing code falls back to ref-walk when a path operation returns
`-ECHILD`. Helpers such as `try_to_unlazy()` and `try_to_unlazy_next()`
legitimize the current path and leave RCU mode.

Phase 1 should not attempt to run the BPF policy in RCU-walk. Reasons:

- The policy needs a stable parent `struct path`.
- Redirect targets are referenced `struct path` objects.
- The first PoC should keep verifier and lifetime rules simple.
- Disabled-policy overhead is the important fast-path property; active-policy
  overhead will be measured.

Recommended Phase 1 rule:

```text
if namei_ext policy is active and nd->flags has LOOKUP_RCU:
    return -ECHILD from the hook site
```

This uses the existing retry path to re-run the lookup in ref-walk. A later
optimization can add an RCU-safe fast path after the semantics are stable.

## Hook Point Decision

### Lookup Hook

Best Phase 1 hook location for generic path components:

```text
walk_component()
  after LAST_NORM check
  before lookup_fast()
```

Reasons:

- The parent path is already the current `nd->path`.
- `may_lookup()` has already checked traversal permission on the parent.
- `nd->last` is parsed and hashed.
- The hook can return `HIDE` before dcache/lower filesystem lookup.
- The hook can return `DENY` before dcache/lower filesystem lookup.
- The hook can redirect by replacing `nd->path` with a registered target path
  and then continuing with the next component.

Rejected locations:

- `lookup_fast()` only: misses slow lookup and mixes policy with dcache lookup.
- `lookup_slow()` only: misses dcache-hit paths.
- lower filesystem `->lookup()`: does not apply across all filesystems and
  misses dcache fast paths.
- syscall wrappers: too high-level and cannot naturally preserve path-walk
  semantics.

### Open Final-Component Hook

Best Phase 1 hook location for open final components:

```text
open_last_lookups()
  after LAST_NORM check
  before lookup_fast_for_open()
```

Reasons:

- It covers the final component of `openat()`, which `walk_component()` does
  not cover.
- It keeps `O_CREAT` and `atomic_open` behavior below the hook.
- It can force RCU fallback before policy execution.
- Final redirected paths still flow into `do_open()` and `may_open()`.

Phase 1 should avoid special writable namespace semantics. If a policy redirects
an `O_CREAT` final component, the safe initial behavior is to fail closed or
require the target to already exist. Full create-through-redirect semantics are
out of scope.

### Readdir Hook

Best Phase 1 hook location:

```text
iterate_dir()
  after security_file_permission()
  after fsnotify_file_perm()
  before filesystem iterate_shared()
```

Mechanism:

1. Build a stack wrapper containing an outer `struct dir_context` and a pointer
   to the caller's original `struct dir_context`.
2. Set wrapper actor to `namei_ext_filldir()`.
3. Let the filesystem call the wrapper.
4. For every lower entry, call the same BPF function with
   `ctx->event = NAMEI_EXT_READDIR`.
5. `PASS` emits the original entry through the original actor.
6. `HIDE` skips the entry and returns `true` to keep iterating.
7. `DENY` emits the entry. Deny controls lookup/open access; hide controls
   listing visibility.
8. After lower iteration, append registered synthetic alias names for this
   parent by calling the same BPF function with `NAMEI_EXT_READDIR`.

Appending synthetic aliases must respect `ctx->count` and actor return value.
`ctx->pos` semantics need careful implementation so repeated `getdents64()`
calls do not duplicate aliases or skip lower entries. Phase 1 can keep this
simple by assigning aliases positions after the lower iterator reaches end.

## Action Semantics

For `NAMEI_EXT_LOOKUP`:

- `PASS`: continue normal VFS lookup.
- `HIDE`: return `-ENOENT`.
- `DENY`: return `-EACCES`.
- `REDIRECT`: replace the current component with a registered target path.

For `NAMEI_EXT_READDIR`:

- `PASS`: emit the entry.
- `HIDE`: skip the entry.
- `DENY`: emit the entry; later lookup/open returns `-EACCES`.
- `REDIRECT`: emit the alias entry if the registered target exists and the
  alias belongs to the current parent.

This preserves a useful distinction: hidden names do not exist from the
workload's view, denied names exist but cannot be accessed.

## Redirect Registry Requirements

The redirect registry needs at least:

- target IDs mapped to referenced `struct path` objects from `O_PATH` fds;
- parent IDs mapped to referenced parent `struct path` objects;
- optional alias records `(parent_id, name, target_id)` so the kernel can list
  synthetic names during `READDIR`;
- link or attachment lifetime ownership so references are released on detach;
- redirect-depth limit and cycle detection;
- validation that a target used for an intermediate path component is a
  directory.

The alias records are not a policy language. They are runtime backing objects
and names that allow the kernel to enumerate synthetic entries. The eBPF program
still decides the action.

## Risks And Open Questions

1. Readdir position semantics are the highest-risk Phase 1 area. The wrapper
   must avoid duplicated synthetic aliases across repeated `getdents64()` calls.
2. `REDIRECT` in `open_last_lookups()` with `O_CREAT` should probably fail
   closed until explicit writable semantics are designed.
3. Parent identity should be path-based, not inode-only. The registry should
   compare both mount and dentry.
4. Active policy will likely disable RCU-walk for affected lookups in Phase 1.
   This is acceptable only if benchmark results report the overhead clearly.
5. Mount traversal after redirect must remain VFS-owned. Registered targets
   should be fed into the existing path state instead of bypassing managed
   dentry handling.

## First Implementation Slice

The first implementation slice should be minimal and testable:

1. Add a stub `CONFIG_NAMEI_EXT` and new kernel files with static branch state.
2. Add a no-policy fast path that compiles but does not alter behavior.
3. Add hook calls in `walk_component()`, `open_last_lookups()`, and
   `iterate_dir()` behind the static branch.
4. Initially implement only hardcoded kernel-side no-op behavior
   (`NAMEI_EXT_PASS`) to validate build and boot.
5. Add Makefile-only infrastructure to build the modified kernel and run a KVM
   smoke test that confirms the kernel boots with `CONFIG_NAMEI_EXT`.

Only after that should the BPF attachment and initial policy behavior be added.
