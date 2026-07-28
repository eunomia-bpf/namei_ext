# Repository infrastructure and kernel build identity

## Motivation

Before the next formal experiment, this audit asked whether `namei_ext` should
be reorganized to resemble `bpf-benchmark`, and whether the existing kernel
pair could be reproduced safely. The useful property of `bpf-benchmark` is not
its larger directory tree or Python runner. It is the separation between a
single build and execution control plane, suite-owned workload semantics,
immutable raw artifacts, and analysis performed after collection.

## Repository finding

The current repository already has those primary ownership boundaries:

```text
Makefile                    public entrypoints and current-suite catalog
mk/kernel.mk                patched and matched-stock kernel construction
mk/kvm.mk                   common KVM launch and guest gates
mk/results.mk               raw run lifecycle and source-state contract
mk/experiments/*.mk         source-derived case-study matrices
mk/benchmarks/*.mk          standard performance matrices
runner/                     shared namei_ext mechanism lifecycle
experiments/                case-study code and correctness oracles
bench/                      microbenchmark and macrobenchmark code
analysis/                   derived statistics, tables, and figures
```

A directory move or a new runner framework would not strengthen the current
claims. It would instead invalidate paths and input manifests that have already
been exercised. The appropriate convergence work is to strengthen shared
contracts in place.

## Failure observed

The first clean FxMark preflight attempt was terminated after one second while
the kernel build was still running. A second invocation started before all
children from the first invocation had exited. Both invocations wrote the same
patched and stock build directories.

The resulting stock image panicked during boot on an unsupported MSR read.
Inspection found:

- `arch/x86/power/cpu.o` contained the expected safe-RDMSR exception-table
  relocation;
- the corrupted final stock `vmlinux` contained 39 out-of-order exception-table
  records even though `main_extable_sort_needed` had been cleared;
- the run-local stock `bzImage` matched that corrupted build;
- the run-local patched `bzImage` did not match the patched build tree after
  the overlapping builders stopped; and
- `results/experiments/fxmark-rq2-preflight/20260727T-clean-artifact-preflight-v2/run.json`
  correctly preserved the run as failed.

CPU-model changes did not repair the image. A full `make kernel-clean` followed
by one serial `make fxmark-kernel-pair` produced fully sorted exception tables
for both kernels. The rebuilt stock and patched images both booted in KVM.
Therefore the failure was concurrent build-tree mutation, not a stock-kernel,
QEMU CPU-model, or `namei_ext` semantic defect.

## Infrastructure change

`mk/kernel.mk` now owns one lock under `.cache/locks/` for all patched and stock
kernel mutations. Separate top-level Make invocations can no longer configure,
compile, clean, or validate the shared kernel build trees concurrently.

The patched build tree is also bound to the current kernel commit before any
configuration or compilation:

1. `kernel-source-identity` validates a 40-character commit identifier.
2. If `.build/kernel/.source-commit` differs, it removes the complete patched
   build tree.
3. It recreates the tree and writes the new source identity atomically.
4. The image recipe refuses to build unless the source stamp equals the live
   kernel repository commit.
5. The existing `.built-commit`, UTS release, embedded version, and provenance
   checks remain independent gates.

The stock source remains an archive of its pinned ancestor commit. Its source
creation, configuration, build, provenance, and cleanup now use the same lock.
`flock` is an explicit Phase 1 prerequisite.

## Validation

Completed validation:

- `make kernel-clean && make fxmark-kernel-pair` completed from empty patched
  and stock build trees;
- both rebuilt final exception tables were fully ordered;
- the rebuilt stock image passed a KVM smoke boot;
- `make kernel-provenance kernel-stock-provenance` passed through the new
  locked incremental path;
- `make result-contract` passed all 19 FxMark analyzer tests, existing result
  and clean-source negative tests, and the new kernel identity tests;
- the new tests prove that a changed commit deletes a stale object, the same
  commit preserves an incremental object, and a subsequent commit change
  deletes it again; and
- `git diff --check` passed before review.

## Remaining convergence work

These items do not justify blocking the current FxMark preflight with a broad
refactor:

- FxMark has the strongest artifact contract because it snapshots both kernel
  images, configs, BTF, notes, policies, and runtime binaries into the immutable
  run root. Current single-guest case studies still hash artifacts in place.
  The FxMark pattern should become a shared helper after the formal run.
- Several component Makefiles repeat libbpf archive construction. That build
  ownership can be moved into one common Make include after the formal run.
- `results/` currently occupies about 44 GB and 1.46 million filesystem
  entries, while the containing filesystem was measured at roughly 96% usage.
  Historical raw results must be reviewed and archived deliberately before a
  long formal matrix; this change does not delete them.
- The 61 tracked historical result files and ignored `namei_ext.run.v2` raw
  roots need a written release-snapshot policy. This is a retention and
  publication issue, not a reason to mix raw collection into source control.

The next experiment gate is a clean-tree FxMark RQ2 preflight using the rebuilt,
locked kernel pair. A complete preflight must finish every declared boot, pass
the workload and dmesg gates, and verify its run-local artifact checksums before
the full matrix is started.
