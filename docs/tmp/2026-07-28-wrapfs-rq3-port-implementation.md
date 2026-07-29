# RQ3 Wrapfs Port Implementation Record

## Motivation

RQ3 needs a real in-kernel stackable-filesystem implementation of the same
existing-object Agent workspace view used by the `namei_ext` experiment.
Published Wrapfs establishes the reusable stackable-filesystem template, but
its latest official source targets Linux 5.18 and cannot be loaded by the
project's Linux 7.1 prototype kernel without an API port.

This implementation record covers only the dependency port and its KVM behavior
gate. It is not the formal same-oracle RQ3 result.

## Source Identity

- Official source site: <https://wrapfs.filesystems.org/>
- Upstream branch: latest official Linux 5.18 branch
- Upstream commit: `464802c8fd1a25413b295161c9bb9a4ce7bfa33b`
- Vendored source: `thirdparty/wrapfs/`
- Project-specific source note: `thirdparty/wrapfs/UPSTREAM.md`
- Prototype kernel used by the KVM gate:
  `1e81d4793c78b7667d0798248c70c0b15a2c3877`

The module remains a Wrapfs-derived null stackable filesystem. The only
workload policy added for RQ3 is to hide the literal component `deleted.txt`
from lookup and directory iteration.

## Files And Paths Inspected

- Upstream Wrapfs `main.c`, `super.c`, `inode.c`, `dentry.c`, `lookup.c`,
  `file.c`, and `wrapfs.h`
- Linux 7.1 filesystem APIs in `kernel/include/linux/fs.h`,
  `kernel/fs/super.c`, `kernel/fs/fs_context.c`, and current in-tree stackable
  filesystems
- External-module Kbuild paths in `kernel/scripts/Makefile.modfinal` and the
  kernel `modules_prepare` target
- Project KVM entrypoints in `mk/kvm.mk`

## Design Choices

1. Preserve Wrapfs as a kernel module rather than translating it into FUSE or a
   userspace model. The experiment needs the actual competing ownership
   boundary.
2. Port only operations needed by the fixed Agent workspace oracle. Removed
   obsolete or unrelated compatibility surfaces are not replaced with stubs.
3. Build through standard external-module Kbuild with `obj-m`, the project's
   configured kernel output tree, `modules_prepare`, and the matching
   `Module.symvers`.
4. Keep the hide rule inside Wrapfs lookup and `iterate_shared`, because the
   matched baseline must implement the same visible namespace itself.
5. Run the first behavior gate over guest tmpfs. Virtme's writable `/tmp` is
   already layered over 9p/overlay and cannot accept another stackable layer
   without exceeding `FILESYSTEM_MAX_STACK_DEPTH`.

## Ported Interfaces

- Legacy mount/get-super handling became `fs_context`, `get_tree_nodev`, and
  `kill_anon_super`.
- Inode allocation/free, getattr/setattr, permission, symlink, create, unlink,
  and rename use current Linux 7.1 signatures and helpers.
- Dentry initialization and revalidation use the current dentry operation
  signatures.
- Directory iteration forwards the complete current `dir_context`, including
  `pos`, `count`, and `dt_flags_mask`.
- File open, read/write iterators, mmap, fsync, flush, release, and llseek
  forward to lower files with current APIs.
- The external-module Make path now generates `scripts/module.lds` through
  `modules_prepare` before final linking.

## Alternatives Rejected

- Using YoloFS as the feature-equivalent baseline was rejected because its
  broader staging, snapshot, permission, and journaling semantics do not match
  the narrow existing-object oracle.
- Counting Wrapfs source callbacks without loading the module was rejected
  because it cannot show that the current-kernel port or its data operations
  work.
- Mounting over the virtme shared workspace was rejected after KVM evidence
  showed the lower stack depth already reaches the kernel limit.
- Manually linking `wrapfs.ko` was rejected; it would bypass Kbuild's module
  metadata, symbol versioning, linker script, and BTF steps.

## Validation

Build entrypoint:

```text
make agent-workspace-rq3-wrapfs
```

The build completed all Kbuild stages:

```text
CC [M] dentry.o file.o inode.o main.o super.o lookup.o
LD [M] wrapfs.o
MODPOST Module.symvers
CC [M] wrapfs.mod.o .module-common.o
LD [M] wrapfs.ko
BTF [M] wrapfs.ko
```

Modified-kernel behavior gate:

```text
make kvm-agent-workspace-rq3-module-smoke \
  RUN_ID=20260728-rq3-wrapfs-tmpfs-validation2
```

Raw results:

```text
results/experiments/agent-workspace-rq3-module-smoke/
  20260728-rq3-wrapfs-tmpfs-validation2/
```

The gate loaded and registered the real module, mounted it over guest tmpfs,
and passed all declared cases:

- visible lookup and read;
- hidden lookup for `deleted.txt`;
- successful directory iteration with `main.txt` visible and `deleted.txt`
  absent;
- create, write, and sync forwarded to the lower file;
- rename forwarded to the lower directory;
- unlink forwarded to the lower directory;
- clean unmount and module removal;
- no configured dmesg failure signature.

An earlier directory check incorrectly hid a `find` error inside command
substitution. The corrected gate first requires `find` itself to succeed and
then checks the listing. That exposed and led to the complete `dir_context`
forwarding repair.

## Remaining Risks And Follow-Up

- The integrated preflight now places both mechanisms over ext4 and passes 37
  pairwise AgentFS-derived oracles, including nested paths, symlinks, modes,
  access, exec, create/write/fsync/fchmod/fstat, rename, unlink, and final lower
  state.
- Tracefs attributes 13 executed operation classes to their exact
  `wrapfs_* [wrapfs]` symbols, including `getattr` and `setattr`.
- The remaining gate is three independent boots from a clean, committed source
  state; the earlier three-boot development run is not reused.
- This port is not a maintained general-purpose Wrapfs release. Its supported
  surface is intentionally bounded by the declared RQ3 oracle.
