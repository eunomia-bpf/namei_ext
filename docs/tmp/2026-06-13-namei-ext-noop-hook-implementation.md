# Implementation Record: No-Op `namei_ext` Kernel Hooks

Date: 2026-06-13

## Motivation

The kernel survey identified the smallest safe first implementation slice:
create a compile-time `CONFIG_NAMEI_EXT` option, add a static-branch-guarded
no-op hook helper, and place call sites in the VFS paths needed by Phase 1.

This slice intentionally does not implement BPF attachment, redirect registry,
or policy actions. It only establishes the upstream-shaped patch boundary and
lets us validate that the modified kernel can still build and boot before
adding semantics.

## Planned Code Changes

Kernel files:

- Add `include/linux/namei_ext.h`.
- Add `fs/namei_ext.c`.
- Add `CONFIG_NAMEI_EXT` in `fs/Kconfig`.
- Add `namei_ext.o` to `fs/Makefile`.
- Include `linux/namei_ext.h` from `fs/namei.c` and `fs/readdir.c`.
- Add static-branch guarded calls in:
  - `walk_component()`
  - `open_last_lookups()`
  - `iterate_dir()`

## Behavior

With `CONFIG_NAMEI_EXT=n`, all helpers compile to no-op inline code.

With `CONFIG_NAMEI_EXT=y`, the static branch is defined but disabled by
default. Hook sites therefore continue to call the original VFS logic unless a
future attachment path enables the static branch.

The exported no-op functions return:

- `0` for lookup/open call sites.
- direct filesystem iterator result for readdir.

## Validation Plan

1. Build-check touched objects with `make -C kernel O=.build/kernel ...` once
   kernel config infrastructure exists.
2. For this slice, at minimum run a syntax-oriented compile target after adding
   a minimal config or use the later `make kernel` target.
3. Confirm no behavior changes are possible while the static branch remains
   false.

## Validation Performed

The minimal compile validation was run on 2026-06-13 with an out-of-tree x86_64
kernel build directory:

```text
install -d .build/kernel
make -C kernel O=/home/yunwei37/workspace/namei_ext/.build/kernel x86_64_defconfig
kernel/scripts/config --file .build/kernel/.config -e BPF_SYSCALL -e NAMEI_EXT
make -C kernel O=/home/yunwei37/workspace/namei_ext/.build/kernel olddefconfig
make -C kernel O=/home/yunwei37/workspace/namei_ext/.build/kernel fs/namei.o fs/readdir.o fs/namei_ext.o -j$(nproc)
```

Result:

- `olddefconfig` completed with `CONFIG_BPF_SYSCALL` and `CONFIG_NAMEI_EXT`
  enabled.
- `fs/namei.o` compiled.
- `fs/readdir.o` compiled.
- `fs/namei_ext.o` compiled.

This validates the initial header, Kconfig, Makefile entry, and VFS call-site
shape. It does not yet validate a full kernel image, boot, BPF attachment, or
KVM behavior.

## Risks

- The header must not expose `struct nameidata`, which is local to
  `fs/namei.c`.
- The readdir wrapper must preserve original `iterate_shared` behavior exactly
  until real filtering is implemented.
- The hook call sites must remain before dcache/lower lookup for lookup policy,
  but after parent traversal permission checks.
- Real policy execution must handle RCU path walk. The no-op static branch
  slice does not execute policy and therefore does not yet force ref-walk.
