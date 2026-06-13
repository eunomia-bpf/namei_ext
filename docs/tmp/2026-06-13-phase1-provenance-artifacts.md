# Implementation Record: Phase 1 Provenance Artifacts

Date: 2026-06-13

## Motivation

Post-fix review found that the Phase 1 report still lacked enough
OSDI-style provenance. The design requires each artifact run to record source
identity, dirty state, configuration hashes, kernel image identity, Docker
identity, and runtime parameters. The previous report recorded kernel and
Docker tar hashes but did not preserve repo commits or dirty status as raw
artifacts.

## Files Changed

- `mk/report.mk`
- `mk/kvm.mk`
- `tests/functional/Makefile`
- `bench/workloads/Makefile`
- `kernel/tools/lib/bpf/libbpf_probes.c`
- `tests/functional/namei_ext_functional.c`

## Implementation Details

`mk/report.mk` now has a `provenance` target that runs before `report`.
It writes these raw files into `results/phase1/<run-id>/`:

- `metadata.json`
- `main-repo-head.txt`
- `main-repo-status.txt`
- `kernel-repo-head.txt`
- `kernel-repo-status.txt`
- `kernel-config-fragment.sha256`
- `kernel-config.sha256`
- `benchmark-config.sha256`
- `kvm-config.sha256`
- `project-config.sha256`
- `kernel-image.sha256`
- `docker-image-tar.sha256`
- `docker-image-id.txt`
- `host-cpu.txt`

`metadata.json` includes the run id, generation timestamp, main and kernel
commit IDs, dirty booleans, kernel image hash, Docker image id, Docker tar
hash, kernel config hash, benchmark/KVM config hashes, sample count, benchmark
iteration count, KVM CPU/memory settings, and kernel command-line append.

`mk/kvm.mk` now captures the guest's actual `/proc/cmdline` as
`kernel-cmdline.txt` during the smoke boot. `mk/report.mk` treats both
`metadata.json` and `kernel-cmdline.txt` as required artifacts.

The functional attach-ABI tests were expanded to prove rejection of
`BPF_F_ALLOW_OVERRIDE` and `BPF_F_REPLACE` in addition to `BPF_F_ALLOW_MULTI`.

`kernel/tools/lib/bpf/libbpf_probes.c` now sets
`expected_attach_type = BPF_CGROUP_NAMEI_EXT` when probing
`BPF_PROG_TYPE_NAMEI_EXT`, matching the hardened kernel load ABI.

The functional and benchmark Makefiles now make `libbpf.a` depend on the
modified libbpf source files, avoiding stale links after tool-side changes.

## Alternatives Rejected

- Writing provenance only into `summary.md` was rejected because raw result
  files should preserve observations before Markdown interpretation.
- Using ad hoc shell scripts for provenance was rejected because orchestration
  must remain Makefile-owned.
- Treating dirty state as a warning was rejected. Dirty source state is useful
  artifact evidence and should be recorded explicitly.

## Validation

The validation command was:

```text
make phase1
```

It completed successfully with result directory:

```text
results/phase1/20260613T182237Z-e34d8cfa/
```

The run proved that:

- `metadata.json` and all provenance sidecar files exist;
- the report includes main/kernel commit identity and dirty flags;
- functional attach-ABI cases include multi, override, replace, and link
  rejection;
- all previous ABI, functional, benchmark, Docker, and dmesg gates still pass.

Report gates:

- Guest smoke events: 2
- ABI failing cases: 0
- Functional failing cases: 0
- Benchmark failing operations: 0
- Docker failing cases: 0
- Dmesg warning/oops/panic lines: 0

The raw provenance recorded:

- main repo HEAD: `4918f885367ba69246778e71f96814fd29de848a`;
- main repo dirty: `true`;
- kernel repo HEAD: `062871f1371b2e02a272ff5279c6479aff0a37ef`;
- kernel repo dirty: `true`;
- kernel image sha256:
  `21b551c2cfb40ae659f2bcf5ec0ae27b8b8f0e2887121694c259c18303af9a2f`;
- benchmark config sha256:
  `596f0c991c5b145e341764d7a3042dadfd3d29f38be8c4e918ec61ef9900ece5`;
- Docker image id:
  `sha256:62c7cf026cb5f0ab03e7a89c5a8e9b595187cde6d57042c8d950db5b731479e5`;
- Docker image tar sha256:
  `78b09e81d8cde7197086e86e0b47cddbe7929bc9e66803379322cb729b958299`.

## Remaining Risks

- Dirty-state reporting is intentionally strict and will record this working
  tree as dirty until the user explicitly commits the main repo and kernel
  submodule changes.
- Provenance records local commit IDs and status but does not push or publish
  them. Git mutation still requires explicit user authorization.
