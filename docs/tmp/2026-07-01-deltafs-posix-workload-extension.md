# DeltaFS POSIX Workload Extension

Date: 2026-07-01

## Motivation

The earlier DeltaFS evidence covered a single-rank VPIC/large-directory smoke
and libdeltafs CTest results. This follow-up tries to move closer to DeltaFS'
published workload shapes without turning DeltaFS into a main `namei_ext`
workload:

- `large_dir`: metadata create/stat/delete over a large-directory layout;
- `vpic_io`: VPIC-style one-file-per-particle dump writes;
- README local server/shell path with two metadata servers.

DeltaFS remains a full metadata-service/filesystem related-work source. The
goal here is workload-shape reproduction and boundary evidence, not a main
agent-workspace result.

## Source

- Repository: `https://github.com/pdlfs/deltafs`
- Cached source: `.cache/source-inspection/deltafs`
- Build used:
  `.cache/source-inspection/deltafs/build-repro-mpicxx-cstdint`
- Binaries:
  - `benchmarks/large_dir`
  - `benchmarks/vpic_io`
  - `src/server/deltafs-srvr`
  - `src/cmds/deltafs-shell`
- Files inspected:
  - `benchmarks/large_dir/large_dir.cc`
  - `benchmarks/vpic_io/vpic_io.cc`
  - `benchmarks/io_client.cc`
  - `benchmarks/io_posix.cc`
  - `src/server/deltafs_server.cc`
  - `src/cmds/deltafs_shell.cc`
  - `src/libdeltafs/deltafs_mds.cc`
  - `src/libdeltafs/deltafs_conf.cc`

## Raw Evidence

Result root:

- `results/reproduction/2026-07-01-official-workloads/deltafs-posix-mpirank-workloads/`

Important files:

- `summary.json`
- `large-dir-direct-fixed-env.log`
- `large-dir-direct-fixed-env.status`
- `vpic-direct-fixed-env.log`
- `vpic-direct-fixed-env.status`
- `large-dir-np2.log`
- `vpic-np2.log`
- `large-dir-np2-fixed-timeout.log`
- `vpic-np2-fixed-timeout.log`
- `deltafs-server-np2.log`
- `deltafs-shell-np2.log`
- `deltafs-server-np2-envdefault.log`
- `deltafs-shell-np2-envdefault.log`
- `deltafs-server-np2-envdefault-tcp.log`
- `deltafs-shell-np2-envdefault-tcp.log`

## Method

The existing benchmark binaries initially failed under `mpirun` because the
dynamic linker mixed MPI libraries:

```text
libmpi_cxx.so.40 => /lib/x86_64-linux-gnu/libmpi_cxx.so.40
libmpi.so.40 => /usr/local/lib/libmpi.so.40
```

The failed runs are preserved. A fixed environment was then used to force the
system OpenMPI libraries:

```text
LD_LIBRARY_PATH=/lib/x86_64-linux-gnu:/usr/lib/x86_64-linux-gnu/openmpi/lib
```

Direct single-process POSIX runs used:

```text
large_dir --num-dirs=2 --num-files=8 posix mount_point=<root>
vpic_io --num-dumps=2 --x=2 --y=2 --z=2 --ppc=2 posix mount_point=<root>
```

Multi-rank attempts used `mpirun --oversubscribe -np 2` plus explicit
`timeout 20s`.

The README server/shell path was attempted with two metadata server processes
and a shell command sequence:

```text
pwd
mkdir /demo
cpfrom <local payload> /demo/payload.txt
ls /demo
cat /demo/payload.txt
exit
```

The server was tried first with README-like default addresses, then with
`DELTAFS_EnvName=default`, and finally with both `DELTAFS_EnvName=default` and
`DELTAFS_RPCProto=tcp`.

## Results

| Attempt | Status | Result |
| --- | ---: | --- |
| `large_dir` direct POSIX | 0 | Passed. Prepare, bulk creations, checks, and bulk removes all reported `0 fail`. |
| `vpic_io` direct POSIX | 0 | Passed. Prepare and two dump phases all reported `0 fail`. |
| `large_dir` 2-rank before library fix | 127 | Failed at startup with mixed-MPI undefined symbol. |
| `vpic_io` 2-rank before library fix | 127 | Failed at startup with the same mixed-MPI undefined symbol. |
| `large_dir` 2-rank after library fix | 124 | Reached `Bulk creations...` then timed out. |
| `vpic_io` 2-rank after library fix | 124 | Reached `Dump ...` then timed out. |
| `large_dir` minimal 2-rank diagnostic | 124 | A later tiny 2-rank run with 2 dirs and 2 files still reached `Bulk creations...` then timed out; see `docs/tmp/2026-07-01-deltafs-mpirank-minimal-diagnostic.md`. |
| `vpic_io` minimal 2-rank diagnostic | 124 | A later tiny 2-rank run with one 1x1x1 ppc=2 dump still reached `Dump ...` then timed out; see `docs/tmp/2026-07-01-deltafs-mpirank-minimal-diagnostic.md`. |
| README server/shell default | shell 0, server 1 | Server failed with `cannot load MDS env`; shell saw connection refused. |
| README server/shell with `DELTAFS_EnvName=default` | shell 0, server 1 | Server started and reported OK, but shell still saw connection refused. |
| README server/shell with `DELTAFS_EnvName=default` and `DELTAFS_RPCProto=tcp` | shell 0, server 1 | Server started and reported OK, but shell still went through a failing UDP connection path. |

The single-process POSIX result is clean workload-shape evidence. The
multi-rank and server/shell results are not clean reproductions on this host.
They are preserved as runtime/porting evidence. The follow-up minimal 2-rank
diagnostic shows the multi-rank timeout persists at the smallest nontrivial
POSIX scales, so the current evidence should not be presented as a full
multi-rank DeltaFS/VPIC reproduction.

## Reuse Decision

DeltaFS can be reused as appendix or related-work workload-shape evidence for:

- VPIC-style file-per-particle writes;
- large-directory metadata create/stat/delete;
- metadata-service and snapshot design context.

Do not cite this run as:

- full multi-rank DeltaFS reproduction;
- clean README server/shell reproduction;
- main `namei_ext` workload evidence.

For the paper, DeltaFS should remain a boundary anchor: it shows what full
metadata-service systems own, while `namei_ext` intentionally targets a much
narrower VFS path-view mechanism.

## Remaining Risks

- The clean runs are single-process POSIX backend runs, not distributed
  DeltaFS metadata-service runs.
- Multi-rank POSIX benchmark attempts timed out after entering the workload
  phase.
- The README server/shell path needs further DeltaFS RPC/config porting before
  it can be claimed as reproduced.
- This should not displace the higher-value agent workspace and W4
  environment/cache workload sources.
