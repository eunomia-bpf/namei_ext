# IndexFS Workload Extension

Date: 2026-07-01

## Motivation

IndexFS was previously recorded as a metadata-service related-work system with
public code but no reproduced full RPC/server workload on this host. This
record extends that status by checking the official standalone workload path
and by running the metadata benchmark shape available in the original source
tree.

This is appendix or related-work evidence only. `namei_ext` is a VFS
name-resolution hook, not a distributed metadata service or a replacement for
IndexFS.

Raw logs and generated summary are under:

- `results/reproduction/2026-07-01-official-workloads/indexfs-workload-extension/`

## Source And Workload Entry Points

The IndexFS 0.4 README describes a standalone test flow that starts an IndexFS
server and then runs `sbin/tree-test.sh`. That script drives
`io_test/io_driver --task=tree` through MPI with two clients creating and
statting files in a shared directory.

The source tree also includes an `md_test` directory with an `mdtest_posix`
target based on the mdtest metadata benchmark. The generated build does not
enable `md_test`, so this record built the POSIX mdtest source directly with
`mpicc`. That direct build is a workload-shape reproduction from the IndexFS
source tree, not an IndexFS RPC/server reproduction.

## What Ran

Build and workload attempts:

- `make -C build/io_test io_driver V=1`
- `make -C build/server indexfs_server V=1`
- `make -C build V=1`
- `mpicc -O2 -o build-mdtests/mdtest_posix_manual md_test/md_test.c -lm`
- `mpirun --oversubscribe -np 2 mdtest_posix_manual -d <root> -i 1 -n 64 -F`
- `mpirun --oversubscribe -np 2 mdtest_posix_manual -d <root> -i 1 -n 32 -D`

Result summary:

| Attempt | Status | Interpretation |
| --- | --- | --- |
| `io_driver` build | Failed | Modern compiler rejects an old `std::getline(...) == NULL` comparison in `io_test/replay_test.cc`. |
| `indexfs_server` subdir build | Failed | The server target depends on `ipc/libipc_idxfs.la`, which was not built in the subdir-only attempt. |
| Top-level build | Failed | The old IndexFS Thrift-generated/source code uses `boost::shared_ptr`, while current Thrift headers expect `std::shared_ptr` constructors. |
| Manual POSIX mdtest build | Passed with warnings | Built the upstream POSIX mdtest variant outside the disabled generated `md_test` target. |
| POSIX mdtest files run | Passed | Two MPI ranks created/stat/read/removed 128 files and completed tree create/remove phases. |
| POSIX mdtest directory run | Passed | Two MPI ranks created/stat/removed 64 directories and completed tree create/remove phases. |

The raw machine-readable summary is:

- `results/reproduction/2026-07-01-official-workloads/indexfs-workload-extension/summary.json`

## Reuse Decision

Use IndexFS only as metadata-service related work and optional appendix
workload-shape evidence:

- shared-directory tree create/stat/delete;
- mdtest-style file and directory create/stat/read/remove phases;
- bulk insertion and checkpoint/metadata-service discussion from the paper and
  source;
- RPC/server portability caveat for artifact reproduction.

Do not use IndexFS as a primary workload for `namei_ext`. The full IndexFS
server/client path remains blocked until the thrift/client stack is ported, and
the passing mdtest runs are POSIX metadata benchmark shapes rather than
IndexFS-backed runs.

## Remaining Risks

The direct POSIX mdtest run is intentionally small and local. It proves the
metadata workload shape can be exercised from the IndexFS source tree, but it
does not validate distributed IndexFS metadata semantics, the official
`tree-test.sh` server path, or multi-client performance.
