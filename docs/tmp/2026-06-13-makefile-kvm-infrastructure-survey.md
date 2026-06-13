# Makefile/KVM Infrastructure Survey

Date: 2026-06-13

## Purpose

This note records the infrastructure research before adding Phase 1 Makefile,
Docker, and KVM scaffolding. The goal is a minimal workflow where the top-level
Makefile owns the dependency graph and KVM boots the modified kernel.

## Files and Tools Inspected

- Current `namei_ext` tree: `README.md`, `docs/phase1_design.md`,
  `docs/research_plan.md`, and the `kernel` submodule.
- `../agentsight/Makefile`
- `../agentsight/bpf/Makefile`
- `../agentsight/docs/build.md`
- `../bpf-benchmark/Makefile`
- `../bpf-benchmark/runner/mk/build.mk`
- `../bpf-benchmark/build.md`
- `../bpf-benchmark/docs/tmp/benchmark-runtime-architecture.md`
- Local tool availability: `docker`, `vng`, `qemu-system-x86_64`, `clang`,
  `bpftool`, `pahole`, and `make`.

## Local Environment Facts

- Kernel submodule commit: `062871f1371b2e02a272ff5279c6479aff0a37ef`.
- Kernel version: `7.1.0-rc7`.
- Host kernel: `6.15.11-061511-generic` on x86_64.
- KVM tooling: `vng` is available.
- Docker is available.
- BPF build tools `clang`, `bpftool`, and `pahole` are available.

## Adopted Patterns

### From agentsight

`agentsight` uses a small top-level Makefile that delegates BPF-specific build
logic into `bpf/Makefile`. This is the right shape for `namei_ext`: root
targets should orchestrate Phase 1, while BPF source and libbpf/bpftool details
stay under `bpf/`.

The useful rule is structural, not literal: keep component Makefiles local and
make the root target compose them.

### From bpf-benchmark

`bpf-benchmark` provides the stronger systems-artifact pattern:

- one Makefile surface for all supported runs;
- build outputs under explicit build roots;
- Docker packages runtime artifacts;
- KVM boots the modified kernel;
- raw results go into stable result roots;
- no whole-workspace bind mount over the runtime image as the normal Docker
  model.

For `namei_ext`, the Phase 1 implementation should use this pattern with less
code and no AWS/cross-arch support in the first cut.

## KVM Runner Choice

Use `vng` for the first x86_64 KVM path because it is already installed and
matches the parent benchmark repository. The public Make target should still be
named generically (`kvm-smoke`, `functional`, `bench`) so a later fallback to
direct `qemu-system-x86_64` does not change the user-facing contract.

The first guest command should be a Make target:

```text
vng --run <bzImage> --cwd <repo> --rwdir <repo> --overlay-rwdir /tmp \
    --exec "make -C <repo> __phase1_guest_smoke RUN_ID=<id>"
```

This keeps guest orchestration Makefile-owned and avoids checked-in shell
scripts.

## Kernel Config Strategy

Use a committed config fragment at `configs/kernel/x86_64_phase1.config`.
The Makefile may call the kernel tree's own Kconfig tooling to merge the
fragment with `x86_64_defconfig`. This does not introduce a project-owned shell
script control plane.

The initial fragment must enable:

- `CONFIG_NAMEI_EXT`;
- BPF syscall and JIT support;
- cgroup/BPF plumbing needed by the planned attachment path;
- BTF/debug info needed by libbpf CO-RE workflows.

## First Implementation Slice

The first infrastructure slice should add:

- top-level `Makefile`;
- `mk/kernel.mk`, `mk/kvm.mk`, `mk/docker.mk`, and `mk/report.mk`;
- `configs/kernel/x86_64_phase1.config`;
- `configs/kvm/x86_64.mk`;
- `configs/benchmarks/phase1.mk`;
- a minimal `Dockerfile`;
- a minimal `bpf/Makefile` placeholder so root Make targets have a stable
  component boundary.

The first target set should support:

- `make check-prereqs`;
- `make kernel-config`;
- `make kernel-objects`;
- `make kernel`;
- `make docker`;
- `make kvm-smoke`;
- `make phase1-smoke`;
- `make phase1`;
- `make report`;
- `make clean`;

`phase1` can initially run the smoke path and produce a smoke report, but it
must remain the target that grows into the complete functional and benchmark
artifact path.

## Risks

- Full kernel builds may take significant time. The object-level validation
  target remains useful for fast iteration but does not replace KVM.
- Docker-in-KVM may need additional kernel config and guest environment work.
  The first smoke slice should validate boot and guest Make invocation before
  requiring Docker execution inside the guest.
- `CONFIG_DEBUG_INFO_BTF` may fail if `pahole` is missing or too old on another
  workstation; `check-prereqs` should catch this dependency.
