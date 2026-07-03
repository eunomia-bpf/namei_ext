# Filesystem Workload Source Reproduction Report

Date: 2026-06-30

Correction on 2026-07-01: the YoloFS source status in this report is
historical. Public YoloFS filesystem code was later found and partially
reproduced; see
`docs/tmp/2026-07-01-yolofs-public-artifact-reproduction-update.md`. The
original YoloFS agent/perf benchmark submodules remain unavailable, so this
correction does not turn the 2026-06-30 YoloFS-like fixture into an original
YoloFS benchmark reproduction.

## Motivation

This report follows the source audit in
`docs/tmp/2026-06-30-deltafs-yolofs-agentfs-workload-audit.md` and checks which
candidate systems can actually be built or exercised on the current machine.

The goal is not to prove that another mechanism is impossible. The goal is to
separate:

- systems that can immediately seed `namei_ext` workloads;
- systems that are reproducible only as related-work or appendix baselines;
- systems that require a porting effort before they can be used;
- paper-only systems where only a workload/oracle, not the original
  implementation, can be reproduced.

Raw logs are under
`results/reproduction/2026-06-30-fs-workload-repro/`.

## Environment

Observed toolchain:

- Rust: `cargo 1.90.0`
- Go: `go1.22.2`
- Python: `3.12.3`
- `uv`: `0.8.22`
- Node: `v22.22.0`
- OpenMPI: `4.1.6`
- FUSE: `2.9.9`
- Docker: `29.1.3`

`thrift-compiler` was installed with `sudo apt-get install -y
thrift-compiler` during this reproduction because the original IndexFS
configure step required the `thrift` generator binary.

## Summary

| Source | Reproduction status | What ran | Paper-use decision |
| --- | --- | --- | --- |
| YoloFS | Historical 2026-06-30 status: public filesystem code was not yet identified in that survey; workload/oracle reproduced. Superseded on 2026-07-01 by public filesystem-code discovery and partial reproduction. | Hidden-side-effect file-tree oracle fixture intentionally failed on deleted protected file | Use as methodology for a YoloFS-like workload. For current artifact status, cite the 2026-07-01 YoloFS update. |
| AgentFS | Reproduced | Rust CLI build, SQLite-backed `init`/`fs`, FUSE mount write/read | Strong main workload seed and potential FUSE/NFS/SQLite baseline source. |
| Redis Agent Filesystem | Reproduced | Go CLI/control-plane build, Docker Redis, workspace create/add/mount, sync edit, checkpoint, bookmark, fork | Strong main workload seed for agent workspace lifecycle, checkpoint/fork semantics, and sync/mount behavior. |
| Mirage | Reproduced | Python package import, RAM/Disk cross-mount commands, conformance suite with Redis extra | Useful main/secondary workload seed for multi-backend namespace and cross-mount command behavior. |
| DeltaFS | Partially reproduced | CMake configure/build of `vpic_io` and `large_dir`, single-rank POSIX workload runs | Related-work or appendix workload-shape source; full multi-rank/server run needs more MPI/debug effort. |
| IndexFS original | Build blocked | `autoreconf` and configure passed after installing thrift; make blocked on thrift API drift from old Boost pointers to modern `std::shared_ptr` APIs | Use workload descriptions and code inspection; do not claim original standalone tree-test reproduction yet. |
| IndexFS reimplementation | Build-level reproduced | CMake configure and `indexfs-common` build | Related-work mechanism/code context only; no standalone IndexFS workload target exposed. |
| TableFS original | Reproduced with caveats | Original tarball built with compatibility flags; FUSE mount worked on short path; fsbench started but needs privileged drop-cache handling | Related-work or appendix baseline source. |

## YoloFS

### Source Status

Historical 2026-06-30 status: the original YoloFS implementation was not
found in that survey. This statement is superseded by
`docs/tmp/2026-07-01-yolofs-public-artifact-reproduction-update.md`, which
found public filesystem code and reproduced unit tests plus a compat kmod
build. The original agent/perf benchmark submodules are still unavailable, so
the workload/oracle fixture below remains a YoloFS-like reproduction rather
than an original benchmark reproduction.

### Reproduced Workload/Oracle Shape

Log:

- `results/reproduction/2026-06-30-fs-workload-repro/yolofs-like-hidden-side-effect-oracle.log`

The fixture created a small repository with:

- `README.md`
- `src/main.py`
- protected `docs/guide.md`

The simulated hidden-side-effect command edited `src/main.py` and silently
deleted `docs/guide.md`. The oracle failed with:

```text
ORACLE_FAIL missing protected docs/guide.md
```

This is not a YoloFS system reproduction. It is a reproduction of the paper's
workload/oracle pattern: run a task with hidden filesystem side effects and
judge correctness by final filesystem state.

### How To Use

Use this as an agent workload family:

- protected paths and expected final tree;
- commands with plausible hidden side effects, such as formatter, build, lint,
  cleanup, or package scripts;
- final-tree oracle over existence, content hash, and permissions;
- optional permission/rejection log and raw tool-call trace.

Do not describe this as reproducing YoloFS unless the original code is later
found and run.

## AgentFS

### Source

Local source:

- `.cache/source-inspection/agentfs`

Upstream:

- `https://github.com/tursodatabase/agentfs`

Commit:

- `0a014eb`

### Commands Run

Build:

```bash
cargo build --release --no-default-features
```

Logs:

- `results/reproduction/2026-06-30-fs-workload-repro/agentfs-cli-smoke-full.log`
- `results/reproduction/2026-06-30-fs-workload-repro/agentfs-fuse-smoke-success.log`

The CLI smoke created an agent database, wrote `/notes.txt`, listed `/`, and
read the file back:

```text
Created agent filesystem: .agentfs/demo2.db
f notes.txt
hello from reproduction full
```

The FUSE smoke mounted the same style of database, wrote through the mounted
path, unmounted, and verified through the AgentFS CLI:

```text
second fuse pass
second fuse pass
```

One semantic detail: reading the SQLite database with the CLI while the FUSE
mount still holds it can fail with a database locking error. The correct smoke
validated the DB after unmount.

### How To Use

AgentFS is immediately useful for a main workload:

- session/database creation;
- POSIX-like file operations through the CLI;
- FUSE/NFS mount behavior;
- copy-on-write workspace or overlay behavior;
- snapshot/restore and audit-log behavior;
- syscall and POSIX conformance tests as optional robustness inputs.

This is a complete agent filesystem, not a narrow path-resolution hook. In the
paper, use it either as workload provenance or as a complete-system baseline
with a clearly stated mechanism boundary.

## Redis Agent Filesystem

### Source

Local source:

- `.cache/source-inspection/redis-agent-filesystem`

Upstream:

- `https://github.com/redis/agent-filesystem`

Commit:

- `990b8eb`

### Commands Run

Build:

```bash
make commands
```

A short-lived Docker Redis instance was used on `127.0.0.1:16379`. The config
was stored in:

- `results/reproduction/2026-06-30-fs-workload-repro/redis-afs.config.json`

Logs:

- `results/reproduction/2026-06-30-fs-workload-repro/redis-afs-make-commands.log`
- `results/reproduction/2026-06-30-fs-workload-repro/redis-afs-workspace-smoke.log`
- `results/reproduction/2026-06-30-fs-workload-repro/redis-afs-fs-volume-smoke.log`
- `results/reproduction/2026-06-30-fs-workload-repro/redis-afs-sync-edit-smoke.log`
- `results/reproduction/2026-06-30-fs-workload-repro/redis-afs-bookmark-fork-smoke.log`
- `results/reproduction/2026-06-30-fs-workload-repro/redis-afs-checkpointed-fork-smoke.log`

The reproduction covered:

- workspace manifest creation;
- importing a local directory as a volume;
- listing/cat/grep/find on the volume;
- sync-mode workspace mount;
- local edit propagation after watcher convergence;
- checkpoint creation;
- workspace bookmark creation;
- volume fork.

Important observed semantics:

- `afs fs repro-ws ...` did not operate on the Agent Workspace name in this
  version; `afs fs --volume repro-vol ...` was the successful path.
- In sync mode, local edits require watcher convergence. An immediate unmount
  can miss a just-written edit; adding a short wait produced the expected
  Redis-backed state.
- `vol fork` uses the source volume's current checkpoint. A dirty live edit was
  not included until `cp create` captured a checkpoint; after checkpointing, the
  fork contained the edit.

### How To Use

Redis AFS is one of the strongest main workload sources for `namei_ext`:

- create/import/mount/unmount;
- sync-mode edit propagation and stale-window behavior;
- checkpoint and fork lifecycle;
- dirty live state versus checkpointed state;
- grep/query over workspace contents;
- agent MCP file operations.

This gives a natural correctness oracle: the file visible through the local
workspace, the Redis-backed volume, and a checkpoint/fork should match the
expected lifecycle state.

## Mirage

### Source

Local source:

- `.cache/source-inspection/mirage`

Upstream:

- `https://github.com/strukto-ai/mirage`

Commit:

- `627016b`

### Commands Run

The first import attempt using the default `uv` cache failed with a permission
error in `~/.cache/uv`. Re-running with a workspace-local uv cache and without
dev dependencies succeeded:

```bash
UV_CACHE_DIR=/home/yunwei37/workspace/namei_ext/.cache/uv-cache \
  uv run --no-dev --project python python -c 'import mirage; print(mirage.__file__)'
```

Logs:

- `results/reproduction/2026-06-30-fs-workload-repro/mirage-python-import-nondev-workspace-cache.log`
- `results/reproduction/2026-06-30-fs-workload-repro/mirage-ram-disk-cross-mount-smoke.log`
- `results/reproduction/2026-06-30-fs-workload-repro/mirage-python-conformance-extra-redis.log`

A first manual `echo > /data/a.txt` on a default RAM mount failed because the
mount was read-only. The successful reproduction followed the repository
examples: use `MountMode.WRITE` and `tee` through the Mirage command layer.

The cross-mount smoke used RAM and Disk resources and ran:

- write via `tee` to `/ram/a.txt`;
- create `/ram/sub`;
- copy `/ram/a.txt` to `/disk/copied.txt`;
- `find`;
- `grep ... | wc -l`;
- `cat`.

The focused conformance test passed after installing the Redis extra and
pointing `REDIS_URL` to the local Docker Redis:

```bash
REDIS_URL=redis://127.0.0.1:16379/1 \
  uv run --project python --extra redis pytest python/tests/conformance/test_conformance.py -q
```

The log shows all conformance cases completed:

```text
........................................................................ [ 87%]
..........                                                               [100%]
```

### How To Use

Mirage is useful for a multi-backend namespace workload:

- cross-mount copy/read/search;
- RAM/Disk/Redis backend parity;
- cache warm/cold behavior;
- out-of-band mutation and revalidation;
- exact stdout/stderr/exit-code conformance oracles.

It is not the first workload to implement if the paper stays focused on agent
workspace setup/update, but it is a strong secondary workload if we want a
service/VFS namespace story.

## DeltaFS

### Source

Local source:

- `.cache/source-inspection/deltafs`

Upstream:

- `https://github.com/pdlfs/deltafs`

Commit:

- `2a80a6b`

### Commands Run

The first CMake configure failed in CMake's MPI CXX detection when CMake tried
to use `/usr/bin/c++` with MPI. Explicit MPI wrappers fixed configure:

```bash
CC=mpicc CXX=mpicxx cmake -S . -B build-repro-mpicxx ...
```

The first benchmark build then failed on a modern compiler because
`snap_stor.h` used `uint64_t` without including `<cstdint>`. Without editing
third-party source, this compatibility flag fixed the build:

```bash
-DCMAKE_CXX_FLAGS='-include cstdint'
```

Logs:

- `results/reproduction/2026-06-30-fs-workload-repro/deltafs-cmake-configure-mpicxx-cstdint.log`
- `results/reproduction/2026-06-30-fs-workload-repro/deltafs-build-vpic-large-dir-cstdint.log`
- `results/reproduction/2026-06-30-fs-workload-repro/deltafs-vpic-posix-n1-smoke.log`
- `results/reproduction/2026-06-30-fs-workload-repro/deltafs-large-dir-posix-n1-smoke.log`

Targets built:

- `vpic_io`
- `large_dir`

Running the binaries initially failed because runtime linking mixed
`/usr/local/lib/libmpi.so.40` with the system OpenMPI `libmpi_cxx.so.40`.
Running with:

```bash
LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu
```

fixed the symbol lookup error.

Single-rank POSIX workloads completed:

- `vpic_io`: prepare and dump operations succeeded.
- `large_dir`: prepare, bulk create, check, and bulk remove operations
  succeeded.

Two-rank POSIX smoke runs entered the workload phase but did not finish within
60 seconds and were interrupted. That path is not yet closed.

### How To Use

DeltaFS is usable as:

- a workload-shape source for VPIC file-per-particle writes and trajectory
  reads;
- a reduced POSIX generator for appendix-scale metadata/path stress;
- related-work evidence for why HPC systems build full metadata/index
  services.

It should not be a main `namei_ext` workload unless we intentionally spend time
debugging multi-rank MPI/server execution. The current reproduction supports
"builds and single-rank generators run," not "full DeltaFS system reproduced."

## IndexFS

### Original Source

Local source:

- `.cache/source-inspection/indexfs-0.4`

Upstream:

- `https://github.com/zhengqmark/indexfs-0.4`

Commit:

- `4f6c36c`

### Original Build Attempt

Logs:

- `results/reproduction/2026-06-30-fs-workload-repro/indexfs-autoreconf.log`
- `results/reproduction/2026-06-30-fs-workload-repro/indexfs-bootstrap-build.log`
- `results/reproduction/2026-06-30-fs-workload-repro/indexfs-bootstrap-build-after-thrift.log`
- `results/reproduction/2026-06-30-fs-workload-repro/indexfs-make-after-thrift-shim.log`
- `results/reproduction/2026-06-30-fs-workload-repro/indexfs-make-after-threadfactory-shim.log`

The first configure failed because the `thrift` generator binary was missing.
After installing `thrift-compiler`, configure advanced. Modern thrift did not
generate `indexfs_constants.*` because the IDL declares no constants; two empty
compatibility files were added under the build directory to continue:

- `.cache/source-inspection/indexfs-0.4/build/thrift/indexfs_constants.cpp`
- `.cache/source-inspection/indexfs-0.4/build/thrift/indexfs_constants.h`

The build then failed in the RPC layer:

```text
fatal error: thrift/concurrency/PosixThreadFactory.h: No such file or directory
```

A local header alias for `PosixThreadFactory` moved the build further, but the
next failure was systemic: the original IndexFS code uses `boost::shared_ptr`,
while modern thrift generated headers and runtime constructors expect
`std::shared_ptr`. The failed constructors include `TBufferedTransport`,
`TBinaryProtocol`, `MetadataIndexServiceClient`,
`MetadataIndexServiceProcessor`, and `TThreadedServer`.

This is a thrift API drift/porting issue in the original IndexFS code, not a
single missing-header problem.

### Reimplementation

Local source:

- `.cache/source-inspection/indexfs`

Upstream:

- `https://github.com/pdlfs/indexfs`

Commit:

- `7e3ccc8`

Logs:

- `results/reproduction/2026-06-30-fs-workload-repro/indexfs-reimpl-cmake-configure.log`
- `results/reproduction/2026-06-30-fs-workload-repro/indexfs-reimpl-build-all.log`

The DeltaFS reimplementation configured and built `indexfs-common`, but it did
not expose the original standalone server/tree-test workload path.

### How To Use

For now, IndexFS should be used as:

- related-work workload provenance: mdtest create/stat/delete, shared
  directory metadata stress, tree/replay/cache/RPC/SST-compaction tasks;
- evidence that the original implementation needs a thrift port before we can
  claim reproduction;
- optional future reproduction target if we decide the porting effort is worth
  it.

Do not claim the original IndexFS standalone `tree-test.sh` has been
reproduced.

## TableFS

### Source

Local source:

- `.cache/source-inspection/tablefs-0.3/tablefs-0.3/src`

Upstream tarball:

- `https://www.cs.cmu.edu/~kair/code/tablefs-0.3.tar.gz`

### Commands Run

Initial build failed on modern defaults because the bundled LevelDB static
library was not PIE-compatible. Adding `-no-pie` exposed an older C++ ABI
mismatch. The successful build used:

```bash
make clean
make LDFLAGS=-no-pie OPT='-O2 -DNDEBUG -D_GLIBCXX_USE_CXX11_ABI=0' tablefs fsbench
```

Logs:

- `results/reproduction/2026-06-30-fs-workload-repro/tablefs-original-build.log`
- `results/reproduction/2026-06-30-fs-workload-repro/tablefs-original-build-no-pie.log`
- `results/reproduction/2026-06-30-fs-workload-repro/tablefs-original-build-no-pie-old-abi.log`
- `results/reproduction/2026-06-30-fs-workload-repro/tablefs-fuse-shortpath-smoke.log`
- `results/reproduction/2026-06-30-fs-workload-repro/tablefs-fsbench-tablefs-user-smoke.log`

The first FUSE mount attempt used a long result path and aborted with a buffer
overflow because `tablefs_main.cpp` copies the mount directory into a
fixed-size `char[100]`. Re-running with a short `/tmp/tfs-repro` path worked:

```text
/tmp/tfs-repro/x tablefs fuse.tablefs rw,nosuid,nodev,relatime,user_id=1000,group_id=1000
tablefs fuse hello
nested
```

`fsbench` with the in-process `tablefs_user` backend created TableFS metadata
and data files, but the run timed out after hitting:

```text
cannot create /proc/sys/vm/drop_caches: Permission denied
```

The tool hard-codes a privileged cache-drop step, so a clean fsbench run needs
root privileges or a small local compatibility patch.

### How To Use

TableFS is reproducible enough for an appendix or baseline:

- original FUSE filesystem builds and mounts with compatibility flags and a
  short mount path;
- fsbench workload names and behavior are inspectable;
- complete fsbench automation needs a privileged cache-drop workaround.

It is not a main agent-workspace workload. Its value is conventional
metadata-heavy full-filesystem comparison.

## Recommended Next Use In `namei_ext`

### Main Workload Candidates

1. **AgentFS-derived workspace lifecycle.**
   Use CLI/FUSE operations, COW/session setup, and POSIX-like file actions as a
   realistic agent filesystem trace source.

2. **Redis AFS-derived checkpoint/fork lifecycle.**
   Use import, sync mount, local edit convergence, checkpoint, fork, and dirty
   live-state versus checkpointed-state semantics.

3. **YoloFS-like hidden-side-effect oracle.**
   Use protected files, destructive tool side effects, final-tree oracle, and
   permission/rejection logs. Label it as YoloFS-like, not original YoloFS.

4. **Mirage cross-mount namespace workload.**
   Add if we want a multi-backend namespace story with exact command-output
   conformance.

### Appendix / Related-Work Candidates

1. **TableFS FUSE metadata baseline.**
   Use short-path mount smoke and, if needed, patch or privileged-run fsbench.

2. **DeltaFS VPIC/large-dir generator.**
   Use single-rank POSIX generator now; debug multi-rank/server mode only if an
   HPC appendix becomes important.

3. **IndexFS original standalone test.**
   Do not use until the thrift API drift is ported. Use paper/code inspection
   for workload descriptions in the meantime.

## Remaining Risks

- AgentFS and Redis AFS are complete systems. If a reviewer asks "why not just
  use them?", the answer must be mechanism scope, deployment boundary, and
  kernel/VFS integration, not "they cannot do it."
- YoloFS-like tests are not original YoloFS reproduction.
- DeltaFS and TableFS required compatibility flags. Artifact instructions must
  record these flags if we use them.
- IndexFS original reproduction is blocked by thrift API drift from old Boost
  pointer APIs to modern `std::shared_ptr` thrift APIs; claiming otherwise
  would be misleading.
- Some reproduction commands wrote build artifacts under `.cache/source-inspection`
  and raw logs under `results/reproduction`; no `docs/tmp` non-Markdown output
  was used.

## 2026-07-01 Official Workload Extension

The follow-up record
`docs/tmp/2026-07-01-official-workload-reproduction-extension.md` expands this
report from build/smoke reproduction to upstream workload and test entry
points. Raw logs are under
`results/reproduction/2026-07-01-official-workloads/`.

Key updates:

- AgentFS Go SDK tests and most CLI workload tests passed, including init,
  mount, bash/git run, overlay whiteout, overlay delta, FUSE cache
  invalidation, symlinks, and an npm-like path-operation workload. The Linux
  baseline and `agentfs run` syscall suites both failed 2/22 exact permission
  checks, so do not claim full POSIX syscall conformance on this host.
- Redis AFS `make test` passed after installing the upstream-required
  `redis-server` binary. Its markdown benchmark harness is stale against the
  current CLI because it still calls `afs ws import` for volume import.
- Mirage native cross-mount pytest passed when run with the S3 extra, in
  addition to the earlier RAM/Disk/Redis conformance run.
- DeltaFS built `deltafs-srvr`, `deltafs-shell`, and `pdl-build-tests`; ten
  libdeltafs CTest cases passed from the correct build subdirectory.
- TableFS `fsbench` `metadatacreate` passed under root, but the full fsbench
  list at tiny scale segfaulted. Treat TableFS as appendix/related-work
  evidence unless it is ported or patched.

This extension strengthens AgentFS, Redis AFS, and Mirage as primary workload
sources and keeps DeltaFS, TableFS, and IndexFS in related-work or appendix
roles.
