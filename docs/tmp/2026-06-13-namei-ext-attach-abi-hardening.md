# Implementation Record: namei_ext Attach ABI Hardening

Date: 2026-06-13

## Motivation

The first KVM smoke run proved the lookup/readdir policy path, but review found
two ABI risks:

- `BPF_PROG_TYPE_NAMEI_EXT` could be loaded with an unrelated
  `expected_attach_type`;
- generic cgroup BPF attach semantics still exposed multi-policy and link-based
  composition even though Phase 1 has no defined policy-composition model.

Those were correctness and reviewability risks. Phase 1 should expose one BPF
decision function and one policy at a cgroup decision point. Ordering multiple
path-resolution policies by generic cgroup attach order would make hide/deny
semantics hard to explain and hard to test.

## Code Paths Inspected

- `kernel/kernel/bpf/syscall.c`
  - `bpf_prog_load_check_attach()`
  - `bpf_prog_attach_check_attach_type()`
  - `bpf_prog_attach()`
  - `link_create()`
- `kernel/kernel/bpf/cgroup.c`
  - `__cgroup_bpf_attach()`
  - `cgroup_bpf_link_attach()`
  - effective-program construction for cgroup inheritance/multi attach
- `kernel/tools/lib/bpf/libbpf.c`
  - `bpf_program__attach_cgroup()`
  - `bpf_link_create()` cgroup path
- `tests/functional/namei_ext_functional.c`
- `bench/workloads/namei_ext_bench.c`
- `mk/kernel.mk`

The important discovery was that libbpf's high-level cgroup attach helper uses
`BPF_LINK_CREATE`, while the kernel cgroup-link path forces
`BPF_F_ALLOW_MULTI`. That is correct for existing cgroup BPF links, but it is
not a defined Phase 1 `namei_ext` semantic.

## Design Choices

Phase 1 now uses a single-policy attach ABI:

- `BPF_PROG_TYPE_NAMEI_EXT` loads only with
  `expected_attach_type == BPF_CGROUP_NAMEI_EXT`.
- Attaching a `namei_ext` program through `BPF_PROG_ATTACH` rejects nonzero
  attach flags, `relative_fd`, and `expected_revision`.
- `BPF_LINK_CREATE` is rejected for `namei_ext` with `-EOPNOTSUPP`, because the
  current generic cgroup link path implies multi-attach semantics.
- Functional and benchmark helpers attach with `bpf_prog_attach(...,
  BPF_CGROUP_NAMEI_EXT, 0)` and detach with `bpf_prog_detach2(...)`.

This keeps the first ABI small: one policy, one attach type, one decision
function, and no implicit multi-policy ordering.

## Implementation Details

`kernel/kernel/bpf/syscall.c` now:

- validates the expected attach type during `BPF_PROG_LOAD`;
- requires runtime attach type equality in
  `bpf_prog_attach_check_attach_type()`;
- applies stricter flag checks for `BPF_PROG_ATTACH` when the program type is
  `BPF_PROG_TYPE_NAMEI_EXT`;
- rejects cgroup link creation for this program type.

`tests/functional/namei_ext_functional.c` now includes raw syscall negative
tests for:

- loading with the correct attach type;
- rejecting a wrong attach type;
- rejecting `BPF_F_ALLOW_MULTI`;
- rejecting cgroup `BPF_LINK_CREATE`.

The same functional test also now covers real `access(X_OK)` and failing
`execve()` path walks, in addition to `stat`, `open`, and `readdir`.

`bench/workloads/namei_ext_bench.c` now uses direct cgroup attach/detach and
adds `access_hidden` and `exec_denied` workloads. The `exec_denied` workload
forks a child so the benchmark process cannot be replaced; the baseline expects
`ENOEXEC` from a non-ELF executable text file, while the attached policy expects
`EACCES`.

`mk/kernel.mk` now makes the kernel image depend on the kernel source and UAPI
files touched by this PoC, so `make phase1` rebuilds `bzImage` after source
changes instead of reusing a stale image.

## Alternatives Rejected

- Keeping cgroup link attach and documenting first-non-PASS policy composition
  was rejected because it would make Phase 1 depend on semantics not justified
  by the design.
- Modifying the generic cgroup link path to support non-multi
  `namei_ext`-only links was rejected for Phase 1 because cgroup links are
  designed around multi-attach behavior and the single-link replacement path is
  not the minimal kernel change.
- Allowing `BPF_F_ALLOW_OVERRIDE` but rejecting only `BPF_F_ALLOW_MULTI` was
  rejected because override still introduces hierarchy-composition semantics
  outside the Phase 1 claim.
- Counting `access` or `execve` as covered by `stat`/`open` was rejected
  because those syscalls exercise distinct VFS entry paths that real build and
  container workloads use.

## Validation

The validation sequence for this step was:

1. `make functional`
2. `make bench`
3. `make bpf`
4. `make kernel-objects`
5. `make kernel-clean kernel`
6. `make phase1`

The clean kernel rebuild was necessary because a prior interrupted incremental
build left `vmlinux.o` in a bad state. Removing `.build/kernel` and rebuilding
from committed config files produced a fresh `bzImage`.

The attach-ABI hardening validation completed successfully with result
directory:

```text
results/phase1/20260613T180909Z-d82e6c0b/
```

The report gates were:

- Guest smoke events: 2
- ABI failing cases: 0
- Functional failing cases: 0
- Benchmark failing operations: 0
- Docker failing cases: 0
- Dmesg warning/oops/panic lines: 0

The functional suite emitted 19 passing cases, including
`load_good_attach_type`, `load_bad_attach_type`, `multi_attach_rejected`,
`link_create_rejected`, `visible_access`, `hidden_access`, `denied_access`, and
`denied_exec`.

The benchmark suite emitted baseline and policy rows for
`lookup_visible_hot`, `lookup_hidden`, `access_hidden`, `open_denied`,
`exec_denied`, `readdir_filter`, and `build_tree_stat_walk`; all rows had
`fail == 0`.

The final kernel image hash was:

```text
2885791bab4ff7869233ed2db0d7aa9ae153f5a74d4031d64b0910db301c5118
```

The final Docker image tar hash was:

```text
fbfdd7b3126e1971907dc21a49b5caa0fad6e916482ab7d9671da3d73291daf0
```

## Later Validation After Provenance Gating

After adding raw provenance artifacts and expanding attach-flag rejection
coverage to include override and replace flags, `make phase1` was run again.

Latest result directory:

```text
results/phase1/20260613T182237Z-e34d8cfa/
```

Latest report gates:

- Guest smoke events: 2
- ABI failing cases: 0
- Functional failing cases: 0
- Benchmark failing operations: 0
- Docker failing cases: 0
- Dmesg warning/oops/panic lines: 0

The functional suite emitted 21 passing cases. The attach ABI cases now cover
good attach type, bad attach type, multi attach rejection, override attach
rejection, replace attach rejection, and cgroup-link rejection.

The benchmark suite emitted 14 `bench` rows: baseline and policy variants for
`lookup_visible_hot`, `lookup_hidden`, `access_hidden`, `open_denied`,
`exec_denied`, `readdir_filter`, and `build_tree_stat_walk`; every row had
`fail == 0`.

The latest kernel image hash was:

```text
21b551c2cfb40ae659f2bcf5ec0ae27b8b8f0e2887121694c259c18303af9a2f
```

The latest Docker image tar hash was:

```text
78b09e81d8cde7197086e86e0b47cddbe7929bc9e66803379322cb729b958299
```

The latest Docker image id was:

```text
sha256:62c7cf026cb5f0ab03e7a89c5a8e9b595187cde6d57042c8d950db5b731479e5
```

## Remaining Risks

- The single-policy ABI is intentionally conservative. If Phase 2 needs
  multiple path-resolution policies, it must define explicit composition rules and
  tests before enabling multi attach.
- `BPF_LINK_CREATE` rejection is acceptable for the PoC but may need a cleaner
  upstream story if the community prefers fd-owned link lifetimes for all new
  cgroup program types.
- `exec_denied` is a smoke workload, not a process-launch benchmark; paper
  runs should add a separate successful-exec workload or a controlled helper
  binary when measuring exec overhead.
