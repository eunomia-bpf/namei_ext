# DeltaFS Multi-Rank Minimal Diagnostic

Date: 2026-07-01

## Motivation

The earlier DeltaFS POSIX extension showed that direct single-process
`large_dir` and `vpic_io` runs pass, while 2-rank runs time out after entering
their workload phases. This record checks whether those timeouts are only scale
artifacts by reducing both benchmarks to the minimum nontrivial 2-rank POSIX
scale.

This remains related-work and appendix evidence. DeltaFS is a distributed
metadata/index service; `namei_ext` is not attempting to reproduce or replace
that full system.

Raw logs, strace files, and generated summary are under:

- `results/reproduction/2026-07-01-official-workloads/deltafs-mpirank-minimal-extension/`

## What Ran

Both runs used the already built DeltaFS benchmark binaries from:

- `.cache/source-inspection/deltafs/build-repro-mpicxx-cstdint/benchmarks/large_dir`
- `.cache/source-inspection/deltafs/build-repro-mpicxx-cstdint/benchmarks/vpic_io`

The OpenMPI library path was pinned to the system OpenMPI libraries to avoid
the earlier mixed-library undefined-symbol failure.

Attempts:

| Attempt | Scale | Status | Observation |
| --- | --- | --- | --- |
| `large_dir` minimal 2-rank POSIX | 2 ranks, 2 dirs, 2 files | 124 | Prepare completed with 4 successes, then timed out in `Bulk creations...`. The output root had only directories and no files after timeout. |
| `vpic_io` minimal 2-rank POSIX | 2 ranks, 1 dump, 1x1x1 grid, ppc=2 | 124 | Prepare completed with 3 successes, then timed out in `Dump ...`. The output root had the `particles` directory and no particle files after timeout. |
| `large_dir` strace diagnostic | same as above | 124 | Confirmed the run does not reach a completed bulk-create phase before timeout. |
| `vpic_io` strace diagnostic | same as above | 124 | Confirmed the run does not reach a completed dump phase before timeout. |

The raw machine-readable summary is:

- `results/reproduction/2026-07-01-official-workloads/deltafs-mpirank-minimal-extension/summary.json`

## Interpretation

The multi-rank failure is not just the original workload scale. Even the
minimum nontrivial 2-rank POSIX runs do not complete on this host. The clean
DeltaFS workload evidence therefore remains the direct single-process POSIX
generator runs:

- `large_dir`: create/stat/delete metadata workload shape;
- `vpic_io`: VPIC-style file-per-particle dump shape.

Do not cite the current artifact as full multi-rank DeltaFS/VPIC reproduction
or as a clean README server/shell reproduction.

## Reuse Decision

DeltaFS remains useful for related work and optional appendix workload shapes:

- large-directory metadata create/stat/delete;
- VPIC file-per-particle write pattern;
- trajectory/snapshot metadata-service discussion.

It should not displace the paper's agent workspace or W4 environment/cache
mainline workloads.
