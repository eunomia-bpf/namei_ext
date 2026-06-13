# Implementation Record: Phase 1 Validation And Artifact Gates

Date: 2026-06-13

## Motivation

The first complete `make phase1` run proved the KVM functional and benchmark
paths, but the evidence chain still had three weak points:

- the report counted `panic=30 oops=panic` from the kernel command line as
  dmesg failures;
- the Docker image target did not depend on all copied source files and did not
  prove that the image could run a Makefile entry point without a workspace bind
  mount;
- the new UAPI did not have a dedicated ABI layout/header-sync gate.

These issues were infrastructure problems, not changes to the policy semantics.
The goal of this step was to make Phase 1 evidence fail-fast and reproducible.

## Files Changed

- `tests/abi/Makefile`
- `tests/abi/namei_ext_abi.c`
- `Makefile`
- `Dockerfile`
- `mk/docker.mk`
- `mk/report.mk`
- `docs/experiment-plans/phase1.md`
- `docs/phase1_design.md`
- `docs/research_plan.md`

## Implementation Details

`tests/abi` adds a small C ABI checker. It builds one binary against
`kernel/tools/include/uapi/linux/bpf.h` and one binary against
`bpf/include/namei_ext.h`. The checks cover:

- `BPF_PROG_TYPE_NAMEI_EXT == 33`;
- `BPF_CGROUP_NAMEI_EXT == 59`;
- `BPF_NAMEI_EXT_*` event and action values;
- `struct bpf_namei_ext_ctx` field offsets;
- `sizeof(struct bpf_namei_ext_ctx) == 88`;
- sync between the `namei_ext` UAPI block in `kernel/include/uapi/linux/bpf.h`
  and `kernel/tools/include/uapi/linux/bpf.h`.

The top-level `make abi` target runs the checker and writes raw `abi.jsonl`
under the current Phase 1 result directory.

`mk/report.mk` now requires `abi.jsonl` and `docker.jsonl`, writes ABI and
Docker case tables, and turns all gates into shell tests. A nonzero ABI,
functional, benchmark, Docker, or dmesg issue count now fails `make report`
instead of merely appearing in the Markdown.

The dmesg issue detector now matches real splat-like lines such as
`WARNING:`, `Oops:`, `Kernel panic`, `panic:`, `hung task`, and `kernel BUG at`
after the dmesg timestamp prefix. This avoids treating kernel command-line
arguments such as `panic=30` as failures.

`mk/docker.mk` now tracks all files copied into the Docker context through
`DOCKER_CONTEXT_FILES`. `Dockerfile` copies the top-level `Makefile`. The new
`docker-smoke` target builds/saves the image, runs `make -C /opt/namei_ext bpf`
inside the image without a host workspace bind mount, and writes raw
`docker.jsonl`.

## Alternatives Rejected

- Keeping dmesg warnings as an informational report field was rejected because
  Phase 1 gates should fail visibly.
- Running Docker with `-v $(ROOT_DIR):/opt/namei_ext` was rejected because the
  runtime image must carry project files through image layers, not through a
  normal workspace bind mount.
- Checking only `sizeof(struct bpf_namei_ext_ctx)` was rejected because ABI
  tests need enum values and field offsets to catch meaningful drift.

## Validation

The initial validation command for this artifact-gate step was:

```text
make clean && make phase1
```

It completed successfully with result directory:

```text
results/phase1/20260613T161016Z-0effa4f9/
```

The report gates were:

- Guest smoke events: 2
- ABI failing cases: 0
- Functional failing cases: 0
- Benchmark failing operations: 0
- Docker failing cases: 0
- Dmesg warning/oops/panic lines: 0

The raw result directory contains:

- `guest-smoke.jsonl`
- `abi.jsonl`
- `functional.jsonl`
- `bench.jsonl`
- `docker.jsonl`
- `kernel.config`
- `dmesg-smoke.log`
- `dmesg-functional.log`
- `dmesg-bench.log`
- `summary.md`

## Remaining Risks

- The performance run remains smoke-scale: `SAMPLES=1`, `BENCH_ITERS=2000`.
- `REDIRECT` remains reserved but not implemented in the current semantic
  slice.
- Paper-grade evaluation still needs stronger baselines such as bind mounts,
  OverlayFS, symlink forests, and FUSE, plus repeated randomized runs and tail
  latency distributions.

## Later Validation After Attach-ABI Hardening

After the `namei_ext` attach ABI was tightened to one attach type and one
policy per cgroup decision point, `make phase1` was run again.

Attach-hardening result directory:

```text
results/phase1/20260613T180909Z-d82e6c0b/
```

Attach-hardening report gates:

- Guest smoke events: 2
- ABI failing cases: 0
- Functional failing cases: 0
- Benchmark failing operations: 0
- Docker failing cases: 0
- Dmesg warning/oops/panic lines: 0

This later run also includes functional coverage for attach-type rejection,
multi-attach rejection, cgroup-link rejection, `access(X_OK)`, and failing
`execve`, plus benchmark rows for `access_hidden` and `exec_denied`.

## Later Validation After Provenance Gating

After adding raw provenance artifacts, kernel command-line capture, attach flag
coverage for override and replace, and libbpf probe dependency fixes,
`make phase1` was run again.

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

The latest result directory includes `metadata.json`, repo head/status files,
kernel and Docker image identity, config hashes, `kernel-cmdline.txt`, KVM
dmesg logs, ABI JSONL, functional JSONL, benchmark JSONL, Docker JSONL, and
`summary.md`.
