# Implementation Record: Makefile, Docker, and KVM Smoke Infrastructure

Date: 2026-06-13

## Motivation

Phase 1 needs a one-command infrastructure path before adding real BPF policy
semantics, functional tests, or benchmarks. This slice turns the design
constraint into executable Make targets:

- committed kernel config fragment;
- top-level Makefile entrypoint;
- component Makefiles for BPF, tests, and workloads;
- Docker runtime image packaging;
- KVM boot of the modified kernel through `vng`;
- guest-side Make target that writes raw smoke results.

## Files Added

- `Makefile`
- `.dockerignore`
- `Dockerfile`
- `configs/kernel/x86_64_phase1.config`
- `configs/kvm/x86_64.mk`
- `configs/benchmarks/phase1.mk`
- `mk/kernel.mk`
- `mk/docker.mk`
- `mk/kvm.mk`
- `mk/report.mk`
- `bpf/Makefile`
- `bpf/include/namei_ext.h`
- `bpf/policies/README.md`
- `bench/workloads/Makefile`
- `tests/functional/Makefile`
- `thirdparty/README.md`

## Target Surface

The current public targets are:

- `make phase1`
- `make phase1-smoke`
- `make check-prereqs`
- `make kernel-config`
- `make kernel-objects`
- `make kernel`
- `make docker`
- `make kvm-smoke`
- `make bpf`
- `make functional`
- `make bench`
- `make report`
- `make clean`
- `make clean-results`

The default target is `phase1`. In this slice, `phase1` runs the smoke path,
builds or reuses the Docker runtime image tar, and writes a smoke report. It is
not yet the complete Phase 1 functional and benchmark evaluation.

## Kernel Config Notes

The initial kernel config enables:

- `CONFIG_NAMEI_EXT=y`
- `CONFIG_BPF_SYSCALL=y`
- `CONFIG_BPF_JIT=y`
- `CONFIG_CGROUP_BPF=y`
- namespace and overlay/9p/virtio support needed by KVM and future tests
- `CONFIG_DEBUG_INFO_BTF=y`

The first full kernel build failed when `CONFIG_DEBUG_INFO_DWARF_TOOLCHAIN_DEFAULT=y`
caused `pahole v1.30` to segfault during `BTF .tmp_vmlinux1`:

```text
Segmentation fault (core dumped)
Failed to generate BTF for vmlinux
Try to disable CONFIG_DEBUG_INFO_BTF
```

The config was changed to `CONFIG_DEBUG_INFO_DWARF4=y` while keeping
`CONFIG_DEBUG_INFO_BTF=y`. With DWARF4, BTF generation and `BTFIDS` completed.

## Validation Performed

### Tool and component checks

```text
make help
make check-prereqs
make bpf functional bench
```

Results:

- `make help` prints the expected target list.
- `check-prereqs` found `make`, `clang`, `docker`, `vng`, `pahole`, and
  readable/writable `/dev/kvm`.
- empty component boundaries for BPF, functional tests, and workloads create
  their build roots under `.build/`.

### Kernel config and object checks

```text
make kernel-config
make kernel-objects
```

Results:

- `kernel-config` verifies `CONFIG_NAMEI_EXT`, `CONFIG_BPF_SYSCALL`,
  `CONFIG_BPF_JIT`, `CONFIG_CGROUP_BPF`, and `CONFIG_DEBUG_INFO_BTF`.
- `kernel-objects` compiles `fs/namei.o`, `fs/readdir.o`, and
  `fs/namei_ext.o`.

### Full kernel image

```text
make kernel
```

Results:

- `bzImage` built successfully:
  `.build/kernel/arch/x86/boot/bzImage`
- `vmlinux` built successfully:
  `.build/kernel/vmlinux`
- `System.map` built successfully:
  `.build/kernel/System.map`

### KVM smoke

```text
make kvm-smoke
make phase1-smoke
```

Results:

- `vng` booted the modified kernel image.
- The guest executed:
  `make -C /home/yunwei37/workspace/namei_ext __phase1_guest_smoke`.
- The guest mounted bpffs and debugfs when needed.
- The guest wrote raw smoke artifacts:
  - `guest-smoke.jsonl`
  - `uname.txt`
  - `proc-version.txt`
  - `config-namei-ext.txt`
- `RUN_ID` was fixed to expand once per Make invocation so host and guest write
  to the same result directory.
- `VNG_MODULE_FLAGS=--skip-modules` removes the normal-path warning about
  missing `modules.order` for this built-in-only smoke kernel.

### Docker runtime image

```text
make docker
```

Results:

- Docker built `namei-ext/phase1:dev`.
- Docker saved the runtime image tar at:
  `.cache/images/namei-ext-phase1-runtime.tar`

### Current one-command smoke

```text
make phase1
```

Results:

- checks prerequisites;
- compiles touched kernel objects;
- boots KVM smoke;
- reuses or builds the Docker runtime tar;
- writes `summary.md` into the run result directory.

## Remaining Gaps

- This is still a smoke infrastructure path. It does not yet load a real
  `namei_ext` BPF policy.
- `bpf/Makefile`, `tests/functional/Makefile`, and
  `bench/workloads/Makefile` are component boundaries, not complete suites.
- The KVM smoke path skips modules. If future tests require modules, the
  kernel target should grow to build `bzImage modules` and provide
  `modules.order`.
- The Docker image packages the current user-space skeleton. It does not yet
  carry a policy loader, benchmark binary, or functional test binary.
- `thirdparty/` records the intended dependency boundary, but libbpf/bpftool
  are not yet pinned there as submodules.
