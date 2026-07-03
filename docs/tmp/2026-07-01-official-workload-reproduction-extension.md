# Official Workload Reproduction Extension

Date: 2026-07-01

## Motivation

The 2026-06-30 reproduction report established that several candidate systems
could be built or smoke-tested. This record extends that work by running
upstream workload and test entry points where they are available, so the paper
does not confuse "we built it" with "we reproduced its workload."

The goal is source-backed workload selection, not proving that tables or any
other mechanism cannot work. A workload is useful here if it gives `namei_ext`
real path-view operations, state transitions, and correctness oracles.

Raw logs are under:

- `results/reproduction/2026-07-01-official-workloads/`

## Summary

| Source | Upstream workload or test attempted | Result | Reuse decision |
| --- | --- | --- | --- |
| BranchFS | Release build; full upstream shell/Rust test suite; Python quick benchmark; shell quick benchmark | Reproduced. Build passed, all 13 test suites passed, Python quick benchmark wrote JSON for throughput/nested-depth rows, and shell quick benchmark covered create/commit/abort/read/switch timings. Python benchmark did not expose daemon `[BENCH]` rows for creation/commit/abort in this checkout. | Strong main workload source for agent branch/session lifecycle, nested branch inheritance, `@branch` virtual paths, commit/abort oracles, and FUSE baseline behavior. |
| Sandlock | Release build; Rust workspace tests; core integration reruns; CLI tests; Python SDK tests; Go SDK tests; COW/protected-path CLI smoke | Mostly reproduced with negative sub-oracles. Build and CLI tests passed; core integration passed 271/280 after avoiding log-fd artifact; Python passed 354/356; Go in-tree mode passed. Named UNIX socket deny tests and two Python resource-control tests failed. | Strong main workload source for sandbox/workspace lifecycle, COW workdir, dry-run, protected path, chroot/fs-mount, checkpoint/fork, policy_fn, and SDK-level API shapes. Do not claim full Sandlock conformance on this host. |
| OpenHands SDK | Remote workspace tests; file-editor workspace-root tests; terminal session tests | Reproduced targeted subset: 195 passed. Initial `uv` run failed before tests due user-level cache permission; rerun with repo-local `UV_CACHE_DIR` passed. | Strong main workload source for workspace command execution, file upload/download, file-editor path validation, event polling, output deduplication, and terminal session behavior. |
| SWE-ReX | Local runtime/deployment/server/execution pytest subset | Reproduced local subset after installing `aiohttp`: 68 passed, 1 xfailed, excluding one 401-vs-403 auth-status drift test. | Good runtime harness source for local shell sessions, command execution, and file transfer. Do not claim remote Docker/Modal/Fargate reproduction yet. |
| Terminal-Bench | Unit tests; installed-agent runtime tests; run/resume/status Docker-backed tests; selected official oracle tasks | Reproduced: 93 unit tests passed, 2 installed-agent tests passed, 5 run/resume/status tests passed, and 63 selected official tasks resolved through the upstream oracle agent, plus seven preserved setup/content/artifact/workload-boundary tasks and two attempted tasks without upstream result summaries. A permission-adapted replay of `shell-deobfuscation` passed. | Strong task-oracle source for terminal-agent workloads with Docker setup, `run-tests.sh`, interrupt/resume/status lifecycle, protected paths, packaging, services/logs, Git/object cleanup, data/log/database transforms, security repair, forensics/document tasks, build/environment/debug/compile tasks, service/API state, and materialized output oracles. |
| SWE-MiniSandbox | Per-sandbox `/tmp` tmpfs/chroot isolation pytest | Reproduced: 4 passed, including concurrent sandbox tmpfs isolation. | Good many-agent sandbox setup source for private tmpfs, chroot/namespace startup, and no host-`/tmp` sharing oracle. |
| AgentCgroup | Python daemon tests; bash wrapper tests; characterization analysis; scheduler/process/memcg build attempts | Mostly reproduced. Python tests passed 43/43, wrapper tests passed 14/14, characterization fast-mode regenerated trace analysis, and scheduler/process monitor built after submodules. `memcg` build failed because running kernel BTF lacks `struct memcg_bpf_ops`. | Strong trace source for per-tool-call boundaries and operation-weighted agent tasks. Not a filesystem baseline; do not claim full memory-controller reproduction on this host. |
| SWE-rebench V2 | Prompt rendering; README sample Docker eval | Reproduced. Rendering produced one prompt/meta-prompt record. Sample eval for `unidata__netcdf-c-1925` passed with `all_ok=true`, exit code 0, and matched fail-to-pass tests. | Strong W4 source for real repo, Docker image, install config, test command, patch/test-patch, and executable environment/cache oracle. |
| MEnvAgent | Source audit; full HF `MEnvData-SWE` and trajectory downloads; Docker Hub registry probes; official image/eval rows | Partially reproduced as dataset plus image/eval rows. Public repo says core code is still being organized. Full data has 3,005 environment rows across 10 languages and 3,918 trajectory rows over 3,000 unique image names. Passing rows: `python-attrs__attrs-586` passed 21 pytest tests with `OMNIGRIL_EXIT_CODE=0`, and `go-task__task-1814` passed `TestExitCodeZero`/`TestExitCodeOne` with `OMNIGRIL_EXIT_CODE=0`. Negative row: `eyre-rs__color-eyre-114` pulled but failed applying the official test patch because `tests/install.rs` already existed in the image. | Use as an executable W4 environment seed plus environment-reuse dataset/schema and agent trajectory source. Do not claim reproduced MEnvAgent system/runtime or assume every row replays without per-row evidence. |
| Multi-Docker-Eval | Source audit; full HF parquet; evaluator `make_test_spec` smoke; one synthetic-`docker_res` evaluator probe | Full parquet has 334 task rows with language/label/task metadata, but repo does not ship a sample `dataset` plus `docker_res` pair and rows lack Dockerfile/eval-script fields. A synthetic `docker_res` for real task `uber-go__atomic-90` ran through the upstream evaluator and produced the expected F2P oracle: before patch failed, after gold patch passed, `resolved=true`. | Use as benchmark/task/evaluator source for environment construction. Do not claim full benchmark reproduction until released or officially generated `docker_res` is available. |
| SWE-Factory | Correct repository audit; HF dataset downloads; SWE-Factory-Gym one-task evaluator run | Reproduced one executable workload slice. `SWE-Factory-Gym` `pallets__click-2622` built and ran through the upstream evaluator with the gold patch: 40 pytest tests passed, `OMNIGRIL_EXIT_CODE=0`, and report `resolved=true`. SetupBench-lite has 671 rows; SWE-Factory-Gym has 430 rows with Dockerfile/eval script; DeepSWE trajectory dataset has 2,809 rows. | Strong W4 executable source. Do not claim full LLM-driven SWE-Builder generation without API-backed generation. |
| DockSmith | HF model/dataset file inspection; all index shards; one full training shard structure | Dataset/model artifacts are accessible. All nine training index shards were downloaded, totaling 39,719 conversation metadata rows. Shard 1 contains 4,033 aligned conversation lists for context retrieval, test analysis, Dockerfile writing, and eval-script writing agents. No primary public GitHub implementation or official evaluator was identified. | Use as environment-construction trajectory source. Do not present it as a reproduced DockSmith system workload. |
| AgentFS | Go SDK tests; CLI init, mount, run, overlay, cache-invalidation, symlink tests; npm-like workload generator; full `pjdfstest`; `xfstests` quick generic attempt | Mostly reproduced with explicit negative conformance evidence. SDK and most CLI tests passed. Linux syscall and `agentfs run` syscall suites failed 2/22 on exact permission checks for `stat` and `mknod`; the Linux baseline failed the same checks. Full `pjdfstest` executed 238 files and 8,798 tests, but failed 75 files with `Result: FAIL`. Unadapted `xfstests` did not reach tests due mount-source mismatch; an adapted helper reached tests, produced a partial quick run through `generic/067`, and a closed 10-test smoke subset failed 4 tests with 2 notrun. | Strong main workload source for agent workspace lifecycle, COW overlay, mount behavior, cache invalidation, symlink handling, and npm-like path-operation mix. Do not claim full POSIX/FUSE conformance on this host. Keep `pjdfstest`/`xfstests` as conformance caveats, not the main path-view workload. |
| Redis Agent Filesystem | `make test`; markdown-heavy benchmark harness; Docker Redis 8 Search follow-up; grep/search-index targeted tests | `make test` passed after installing `redis-server`. The unmodified markdown benchmark harness failed on stale `afs ws import`. An adapted current-CLI/local-Redis fallback run reproduced the markdown workload semantics at 200 and 1000 files with grep/ripgrep output equivalence and five file-op count oracles passing. Docker `redis:8` provides Redis 8.8.0 with Search, and the adapted 200-file current-CLI workload passed on it after a Redis 8 missing-index compatibility patch. However, current `afs fs <workspace> grep` routes to `cmdFSGrep`, not the older indexed `cmdGrep` backend; indexed evidence is limited to internal grep tests. | Strong main workload source for workspace/checkpoint/fork/sync/query/search. Use the passing tests and adapted markdown workload as workload-source evidence, but do not cite unmodified upstream or public CLI indexed RedisSearch performance reproduction. |
| Mirage | Native cross-mount pytest; prior Python conformance suite | Cross-mount pytest failed without S3 extra, then passed with `--extra s3`. Prior RAM/Disk/Redis conformance already passed. | Strong secondary workload source for multi-backend namespace, cross-mount operations, exact stdout/stderr/exit-code oracles, and cache behavior. |
| DeltaFS | Build server/shell/tests; libdeltafs CTest; VPIC and large-directory POSIX generators; README server/shell path; minimal multi-rank diagnostic | Built `deltafs-srvr`, `deltafs-shell`, and test targets. Ten libdeltafs tests passed. Direct single-process POSIX `large_dir` and `vpic_io` runs passed with zero-fail phase output. Multi-rank POSIX generator attempts reached workload phases but timed out, and minimum 2-rank diagnostics still timeout before file or particle writes complete; README server/shell attempts did not produce a clean shell workload because the shell still hit connection refused. | Reusable as related-work and appendix workload-shape evidence. Full multi-rank DeltaFS/VPIC and README server/shell reproduction remain unclosed. |
| TableFS | Privileged `fsbench` with `tablefs_user`; individual split runs for the original fsbench groups | Split independent tiny runs reproduced 6/12 fsbench groups: `metadatacreate`, `metadataquery`, `onedircreate`, `onedirquery`, `renamequery`, and `deletequery` exited 0. `metadatacreatecompact` and the small-file/scan groups still segfaulted. The one-directory groups also printed bad-count messages. | Reusable as related-work and appendix metadata workload-shape evidence. Not a stable main workload artifact without patching/porting. |
| IndexFS | Original build, non-RPC unit tests, official tree-test dependency checks, and source POSIX mdtest shape | Full RPC/server tree-test remains blocked by old compiler assumptions and Thrift API drift. Nine built upstream tests pass across common, metadb, util, and network components. The source POSIX mdtest variant now passes 2-rank file and directory metadata runs. | Related-work and appendix metadata evidence only. Do not claim full IndexFS RPC/server workload reproduction until the server/client stack is ported. |
| YoloFS | Public umbrella/filesystem/site audit; filesystem unit tests; compat kmod build; VM e2e attempts including latest `make test-e2e-vm` retry | Partially reproduced. Public filesystem code was found. Main and compat unit tests passed with 288/288 tests. Compat branch direct kmod build produced `yolofs.ko`. Umbrella agent/perf evaluation submodules are not accessible. The latest mounted VM e2e retry bypassed the default-QEMU networking issue with system QEMU, booted the guest, but timed out before SSH/9p readiness and never reached kmod install or Rust e2e tests. | Use as methodology plus partial stackable-filesystem artifact evidence. Do not claim original YoloFS agent/perf benchmark reproduction or mounted e2e conformance. |

## YoloFS Workloads

### What YoloFS Provides

YoloFS is now a public code-backed source, but only partially reproducible from
the public artifacts available here. The public materials provide:

- a stackable Linux filesystem implementation;
- staging, snapshot, permission, and commit/abort semantics;
- hidden-side-effect agent task methodology;
- routine filesystem task methodology with permission dialogs, tool calls,
  snapshots, terminal/session logs, and final file-state checks;
- performance workload descriptions for single-file I/O, metadata operations,
  snapshot scalability, and a kernel-development workflow.

The public umbrella repository also references agent and performance evaluation
submodules, but those submodules are not accessible from this environment.

### What Ran

Logs:

- `yolofs-umbrella-recursive-clone.log`
- `yolofs-filesystem-test-unit.log`
- `yolofs-filesystem-compat-test-unit.log`
- `yolofs-filesystem-compat-kmod-direct-src-build.log`
- `yolofs-filesystem-test-e2e-vm.log`
- `yolofs-filesystem-test-e2e-vm-usrbin-qemu.log`
- `yolofs-filesystem-test-e2e-vm-with-deps.log`
- `yolofs-filesystem-vm-deps-retry.log`
- `yolofs-e2e-vm-retry/summary.json`
- `yolofs-e2e-vm-retry/yolofs-test-e2e-vm-retry.log`
- `yolofs-e2e-vm-retry/yolofs-test-e2e-vm-retry-system-qemu.log`
- `yolofs-e2e-vm-retry/yolofs-vm-system-qemu-boot.log`

Passing results:

- `YoloFS/filesystem` main branch unit tests passed: 288 passed, 0 failed.
- `YoloFS/filesystem` compat branch unit tests passed: 288 passed, 0 failed.
- The compat branch direct kmod build with `KBUILD_KMOD_SRC` passed and built
  `yolofs.ko`.

Negative or blocked results:

- Recursive umbrella clone failed on unavailable submodules including
  `agent-eval`, `agent-results`, `perf-eval`, and `perf-results`.
- Main branch direct kmod build reached host-kernel compilation but failed on
  Linux 6.15 headers because `no_llseek` is not declared.
- VM e2e first failed with a QEMU binary lacking user networking; the `/usr/bin`
  QEMU path started the VM, but the guest lacked `make`.
- Attempts to install guest dependencies were blocked by SSH/cloud-init
  instability.
- The latest `make test-e2e-vm` retry confirmed the same boundary more
  precisely: default PATH QEMU still lacks user networking; forcing system QEMU
  boots Ubuntu 24.04 and reaches cloud-init completion, but `vm.py` times out
  before SSH/9p readiness, and manual SSH probes return `Connection reset by
  peer`. The run does not reach `make kmod install`, `yolo reload`, or the Rust
  e2e test body.

### Reuse

YoloFS should be reused as:

- a methodology source for hidden-side-effect final-tree oracles;
- a related-work artifact for stackable kernel filesystems that own broader
  staging/write/snapshot semantics;
- a source of agent workspace state-transition shapes.

Do not cite it as:

- reproduced original YoloFS agent benchmark;
- reproduced original YoloFS performance benchmark;
- mounted e2e filesystem conformance;
- evidence that `namei_ext` replaces YoloFS.

## AgentFS Workloads

### What AgentFS Provides

AgentFS provides several workload shapes that are directly relevant to agent
workspace lifecycle:

- session/database initialization;
- FUSE mount read/write behavior;
- `agentfs run` with copy-on-write overlay behavior;
- overlay whiteout and delta-in-base-dir behavior;
- FUSE cache invalidation after mutation;
- symlink handling;
- git operations inside the overlay;
- SDK-level filesystem, key-value, tool-call, overlay, symlink, and streaming
  tests;
- an npm-like synthetic workload derived from an observed FUSE operation mix:
  lookup, create, mkdir, readdir, write, flush, release, chmod, stat, and
  access.

### What Ran

Logs:

- `agentfs-sdk-go-test.log`
- `agentfs-cli-test-init.log`
- `agentfs-cli-test-mount.log`
- `agentfs-cli-test-run-bash.log`
- `agentfs-cli-test-run-git.log`
- `agentfs-cli-test-overlay-whiteout.log`
- `agentfs-cli-test-overlay-delta-in-base-dir.log`
- `agentfs-cli-test-fuse-cache-invalidation.log`
- `agentfs-cli-test-symlinks.log`
- `agentfs-cli-linux-syscalls.log`
- `agentfs-cli-test-run-syscalls.log`
- `agentfs-npm-workload-scale001.log`
- `agentfs-pjdfstest/agentfs-pjdfstest-rerun.log`
- `agentfs-pjdfstest/summary.json`
- `agentfs-xfstests/xfstests-quick-generic.log`
- `agentfs-xfstests/summary.json`
- `agentfs-xfstests/mount-helper-adapter.log`
- `agentfs-xfstests/xfstests-quick-generic-adapted.log`
- `agentfs-xfstests/summary-adapted-partial.json`
- `agentfs-xfstests/xfstests-smoke-subset-adapted.log`
- `agentfs-xfstests/summary-smoke-subset-adapted.json`

Passing results:

- Go SDK tests passed for `github.com/tursodatabase/agentfs/sdk/go` and
  `github.com/tursodatabase/agentfs/sdk/go/internal/cache`.
- CLI init, mount, bash-run, git-run, overlay whiteout, overlay delta,
  FUSE cache invalidation, and symlink tests passed.
- The npm-like workload at scale `0.01` created 24 directories, 41 files,
  performed 26 readdir operations, 7 chmod operations, 5 stat operations, and
  50 extra lookup/access operations.

Negative result:

- The Linux baseline syscall suite failed 2 of 22 checks.
- The `agentfs run` syscall suite also failed 2 of 22 checks.
- The failures were exact permission checks in `stat` and `mknod`; the same
  checks failed on the Linux baseline, so this is not evidence of an
  AgentFS-specific semantic gap.
- Full `pjdfstest` against an AgentFS FUSE mount reproduced and failed:
  238 files, 8,798 tests, 75 failed files, and `Result: FAIL`. Representative
  failures include `mknod` returning `EPERM` where pjdfstest expected success,
  ownership/permission transition mismatches, and failures across
  `mkdir`, `mkfifo`, `link`, `rename`, `rmdir`, `symlink`, `truncate`,
  `unlink`, and `utimensat` groups. This is recorded separately in
  `docs/tmp/2026-07-01-agentfs-pjdfstest-workload-reproduction.md`.
- The official `xfstests` quick-generic shape did not reach tests with
  `TEST_DEV=<database file>` because the mounted FUSE source appeared as
  `agentfs:<database file>` while xfstests searched for the exact `TEST_DEV`
  source. A local adapter using `TEST_DEV=agentfs:<database file>` reached the
  test body; the long quick-generic attempt was interrupted after 50 tests with
  artifacts, and a closed 10-test smoke subset failed `generic/003`,
  `generic/005`, `generic/007`, and `generic/009`, with `generic/004` and
  `generic/008` not run. This is recorded separately in
  `docs/tmp/2026-07-01-agentfs-xfstests-workload-reproduction.md`.

### Reuse

AgentFS should be a primary workload source. Its best reusable pieces are:

- workspace setup and session lifecycle;
- FUSE mount behavior;
- overlay copy-on-write and whiteout transitions;
- cache invalidation;
- symlink and git-visible behavior;
- npm-like path-operation mix.

For `namei_ext`, do not copy AgentFS as a full filesystem. Reuse its workload
and oracle shapes, then implement only the path-view policy subset that belongs
at name resolution. Treat `pjdfstest` and `xfstests` as full-filesystem
conformance evidence, not as the main path-view workload.

## Redis Agent Filesystem Workloads

### What Redis AFS Provides

Redis AFS provides:

- workspace create/import/mount/unmount;
- sync mode and live mount mode;
- checkpoint create/list/restore;
- workspace fork;
- file grep/query;
- MCP file operations;
- Redis-backed live roots, manifests, metadata, blobs, checkpoints, and mount
  runtime state;
- Go tests for CLI, control plane, MCP tools, query/search, mount client, NFS
  filesystem, sync, and worktree materialization.

### What Ran

Logs:

- `redis-afs-make-test.log`
- `redis-server-install.log`
- `redis-afs-make-test-after-redis-server.log`
- `redis-afs-mdbench-small.log`
- `redis-afs-md-workload-adapted/upstream-stale-ws-import.log`
- `redis-afs-md-workload-adapted/adapted-small-run-v2.log`
- `redis-afs-md-workload-adapted/adapted-local-no-search-small.log`
- `redis-afs-md-workload-adapted/adapted-current-cli-local-no-search-small.log`
- `redis-afs-md-workload-adapted/adapted-current-cli-local-no-search-medium.log`
- `redis-afs-md-workload-adapted/summary.json`

The first `make test` failed because the upstream tests exec `redis-server`,
which was not installed. After installing the Ubuntu `redis-server` package,
`make test` passed across:

- `./cmd/...`
- `./deploy/...`
- `./internal/...`
- `mount/...`

The unmodified markdown-heavy benchmark harness failed before running the
benchmark:

```text
"afs ws import" now manages Agent Workspaces, which are manifests of attached volumes.

Use "afs vol import" for the volume file-tree command instead.
```

This is a harness/API drift in the current repository, not a negative result
for the workspace lifecycle workload itself. A first adaptation to `afs vol
import` reached live workspace initialization but failed on Docker `redis:8`
with `SEARCH_INDEX_NOT_FOUND` because Redis 8's `Index not found` error string
was not recognized by the cached source's missing-index matcher.

A second explicit adaptation ran the current CLI with local Redis no-Search
fallback:

- `afs ws import` was changed to `afs vol import`;
- `afs grep --workspace <name>` was changed to
  `afs fs <workspace> grep`;
- Docker RedisSearch fallback was disabled so the run used local Redis 7.0.15
  and the direct fallback path.

The current-CLI adapted runs reproduced the workload semantics:

- 200-file run: grep/ripgrep rare/common/regex outputs all matched the local
  filesystem output; tree/find/read/head/line-window counts all matched.
- 1000-file run: grep/ripgrep rare/common/regex outputs all matched the local
  filesystem output; file-op counts matched `1049`, `250`, `100813`, `37767`,
  and `24759`.

The indexed-search follow-up then showed:

- `redis:8` starts Redis 8.8.0 with RediSearch and `FT._LIST` exits 0;
- after a local Redis 8 missing-index compatibility patch, the adapted 200-file
  current-CLI markdown workload also passes on Docker `redis:8`;
- current `afs fs <workspace> grep` dispatches to `cmdFSGrep` in
  `cmd/afs/fs_remote_commands.go`, so the adapted markdown benchmark does not
  exercise the older indexed `cmdGrep` backend;
- targeted grep tests pass, including
  `TestRunIndexedGrepTargetsLoadsExternalAndInlineContent`.

The detailed record is
`docs/tmp/2026-07-01-redis-afs-md-workload-reproduction.md`. The indexed-search
follow-up record is
`docs/tmp/2026-07-01-redis-afs-indexed-search-workload-reproduction.md`.

### Reuse

Redis AFS should be a primary workload source for:

- checkpoint/fork lifecycle;
- sync convergence and stale-window observation;
- dirty live state versus checkpointed state;
- workspace search/grep/query;
- manifest and mount runtime state.

The passing `make test` and adapted markdown benchmark are strong evidence
that the current codebase has executable workspace/query/file-operation
oracles. Cite the markdown benchmark only as an adapted current-CLI
reproduction. Do not cite the unmodified upstream harness or public CLI indexed
RedisSearch performance path as reproduced.

## Mirage Workloads

### What Mirage Provides

Mirage provides:

- RAM, Disk, Redis, S3, and many service-backed namespace resources;
- cross-mount command execution;
- Python and TypeScript command conformance;
- exact stdout/stderr/exit-code oracles for `cat`, `cmp`, `du`, `file`,
  `find`, `grep`, `head`, `ls`, `md5`, `stat`, `tree`, and `wc`;
- native command tests for cross-mount `cp`, `mv`, `find`, `grep`, and shell
  pipelines;
- cache and snapshot tests.

### What Ran

Logs:

- `mirage-native-cross-mount-pytest.log`
- `mirage-native-cross-mount-pytest-s3extra.log`

The first native cross-mount pytest failed while importing the native-test
conftest because the S3 resource module needs `aioboto3`. Re-running with:

```text
uv run --project python --extra s3 pytest python/tests/commands/native/test_cross_mount.py -q
```

passed with exit status 0.

Together with the prior RAM/Disk/Redis conformance run, this makes Mirage a
good secondary workload source for multi-backend namespace behavior.

## DeltaFS Workloads

### What DeltaFS Provides

DeltaFS provides:

- VPIC file-per-particle write pattern;
- trajectory/read-side workload shape;
- large-directory create/stat/delete generator;
- snapshot and metadata-service mechanisms;
- server and shell binaries for local DeltaFS testing;
- libdeltafs tests around API, buffered IO, filters, ranges, PLFS-style IO, and
  metadata-server internals.

### What Ran

Logs:

- prior `deltafs-vpic-posix-n1-smoke.log`
- prior `deltafs-large-dir-posix-n1-smoke.log`
- `deltafs-build-server-shell-tests.log`
- `deltafs-ctest-libdeltafs.log`
- `deltafs-ctest-libdeltafs-after-build.log`
- `deltafs-posix-mpirank-workloads/summary.json`
- `deltafs-posix-mpirank-workloads/large-dir-direct-fixed-env.log`
- `deltafs-posix-mpirank-workloads/vpic-direct-fixed-env.log`
- `deltafs-posix-mpirank-workloads/large-dir-np2-fixed-timeout.log`
- `deltafs-posix-mpirank-workloads/vpic-np2-fixed-timeout.log`
- `deltafs-posix-mpirank-workloads/deltafs-shell-np2-envdefault-tcp.log`

Newly reproduced:

- built `deltafs-srvr`;
- built `deltafs-shell`;
- built `pdl-build-tests`;
- ran 10 libdeltafs CTest cases from the correct build subdirectory, all
  passed.
- ran direct single-process POSIX `large_dir` with 2 directories and 8 files:
  prepare, bulk creations, checks, and bulk removes all reported `0 fail`;
- ran direct single-process POSIX `vpic_io` with two dumps over a 2x2x2 grid
  and two particles per cell: prepare and both dump phases reported `0 fail`.

The first CTest attempt ran before the test binaries were built and from the
wrong directory, so it reported "Not Run" for missing executables. That log is
preserved as a workflow mistake, not a semantic failure.

New negative or unclosed results:

- the first 2-rank `large_dir` and `vpic_io` attempts failed at startup because
  the dynamic linker mixed system OpenMPI `libmpi_cxx.so.40` with
  `/usr/local/lib/libmpi.so.40`;
- after forcing the system OpenMPI library path, 2-rank `large_dir` reached
  `Bulk creations...` and timed out;
- after the same fix, 2-rank `vpic_io` reached `Dump ...` and timed out;
- a follow-up minimum 2-rank diagnostic still timed out: `large_dir` with 2
  directories and 2 files timed out in `Bulk creations...`, and `vpic_io` with
  one 1x1x1 ppc=2 dump timed out in `Dump ...`; output roots had directories
  but no completed file or particle writes;
- README-style two-server plus `deltafs-shell` attempts did not close. The
  default server failed `cannot load MDS env`; with `DELTAFS_EnvName=default`
  the server started and reported OK, but the shell still hit connection
  refused, including with `DELTAFS_RPCProto=tcp`.

### Reuse

DeltaFS is now more reproducible than the earlier smoke suggested, but its best
role is still related work or appendix:

- metadata-service and snapshot design context;
- VPIC and large-directory workload shape;
- optional metadata/path stress generator.

It should not displace the AI-agent workload unless the paper deliberately
adds an HPC metadata appendix. Do not cite the current run as full multi-rank
DeltaFS or clean README server/shell reproduction.

## TableFS Workloads

### What TableFS Provides

TableFS provides:

- original FUSE TableFS mount;
- `tablefs_user` in-process fsbench backend;
- metadata microbenchmarks: `metadatacreate`, `metadataquery`,
  `metadatacreatecompact`, `onedircreate`, `onedirquery`, `smallfilecreate`,
  `smallfilequery`, `scanquery`, `lsstatquery`, `scanfilequery`,
  `renamequery`, and `deletequery`;
- conventional metadata-heavy workload provenance from the paper: Linux kernel
  unpack/search/build/compress and Postmark.

### What Ran

Logs:

- `tablefs-fsbench-root-metadatacreate.log`
- `tablefs-fsbench-root/monitor.log`
- `tablefs-fsbench-root-all-small.log`
- `tablefs-fsbench-individual/status.tsv`
- `tablefs-fsbench-individual/summary.json`
- `tablefs-fsbench-individual/smallfilecreate/gdb-backtrace.log`

The single `metadatacreate` fsbench run passed under `sudo` with a tiny trace.
Root was needed because the original fsbench hard-codes:

```text
echo 3 > /proc/sys/vm/drop_caches
```

The full fsbench list at tiny scale segfaulted with exit status 139 after
duplicate path/state messages. Therefore TableFS is reproducible enough to
show one metadata workload and to inspect all workload names, but not stable
enough to become a main artifact without patching or porting.

The follow-up split run used independent metadata/data roots and the original
argument form `-configfile <path>` for each group. Six of the twelve original
fsbench groups exited 0: `metadatacreate`, `metadataquery`, `onedircreate`,
`onedirquery`, `renamequery`, and `deletequery`. `renamequery` and
`deletequery` reported `Error count = 0`; the one-directory groups exited 0
but printed bad-count messages, so they are executable workload-shape evidence
rather than clean correctness evidence.

The remaining groups exited 139: `metadatacreatecompact`, `smallfilecreate`,
`smallfilequery`, `scanquery`, `lsstatquery`, and `scanfilequery`. A gdb
backtrace for `smallfilecreate` points into the original TableFS/LevelDB
metadata path (`DBImpl::Get`, `LevelDBAdaptor::Get`, `InodeCache::Get`,
`TableFS::GetAttr`, `TableFSWrapper::Stat`, `TableFSWrapper::Mkdir`). This is
preserved as a porting/runtime failure of the original TableFS code on this
host, not as evidence against `namei_ext`.

## IndexFS And YoloFS

No successful full IndexFS RPC/server reproduction was produced in this
extension. The official standalone tree-test path still needs an IndexFS
server and `io_test/io_driver`; those targets remain blocked on old source
assumptions and Thrift API drift. A narrower source-backed workload shape did
reproduce: the POSIX `mdtest` variant from the IndexFS tree built manually with
`mpicc` and passed 2-rank file and directory metadata runs. This is recorded in
`docs/tmp/2026-07-01-indexfs-workload-extension.md`.

IndexFS workload descriptions remain useful as related-work or appendix
metadata-service context: standalone shared-directory tree test, mdtest
create/stat/delete, bulk insertion, replay/cache/RPC/SST-compaction tests.

YoloFS reusable parts now include the public filesystem artifact, its
hidden-side-effect workload and final-tree oracle methodology, and its
staging/snapshot/permission design. Do not claim original YoloFS agent/perf
benchmark reproduction.

## What Can Be Reused

### Primary Workloads

1. **Agent workspace lifecycle.**
   Combine BranchFS, Sandlock, AgentFS, and Redis AFS evidence:
   branch/session setup, `@branch` virtual paths, commit/abort, protected-path
   sandboxing, workspace/session setup, mount, COW overlay, checkpoint/fork,
   dirty live state, sync convergence, symlinks, git-visible behavior, and
   cache invalidation.

2. **Hidden side-effect oracle.**
   Use YoloFS-like protected paths, hidden destructive tool behavior, and final
   file-tree hashing as the correctness oracle.

3. **Multi-backend namespace.**
   Use Mirage only if the paper needs a second workload beyond agent workspace:
   cross-mount copy/read/search and exact command-output conformance.

### Appendix Or Related-Work Workloads

1. **DeltaFS.**
   Use VPIC and large-directory shapes as metadata-service context.

2. **TableFS.**
   Use the passing split fsbench groups and fsbench workload taxonomy as
   conventional FUSE/full-filesystem metadata context.

3. **IndexFS.**
   Use the passing POSIX mdtest file/directory shapes plus workload
   descriptions until the original RPC/server code is ported.

## Paper Idea Implication

The paper idea is not "table-only is impossible" and not "replace AgentFS,
Redis AFS, Mirage, DeltaFS, or TableFS."

The idea is:

> `namei_ext` is a narrow programmable VFS name-resolution layer. It lets an
> eBPF policy decide lookup and directory-enumeration path views while the
> kernel and lower filesystem retain ownership of VFS objects, file data,
> writes, and ordinary filesystem semantics.

The workload evidence should therefore show that real systems already build or
use full FUSE/custom filesystem machinery for agent/workspace/path-view
problems, and that the part relevant to `namei_ext` can be expressed as
dynamic name-resolution policy with clear correctness oracles.

The next implementation step should not be more table counterfactual work. It
should be a Make-owned KVM `namei_ext` workload derived from the primary
workloads above.

## BranchFS And Sandlock Addendum

The dedicated BranchFS/Sandlock reproduction record is:

- `docs/tmp/2026-07-01-branchfs-sandlock-workload-reproduction.md`

The short result is:

- BranchFS is reproduced strongly enough to use as a main agent branch/workspace
  source: release build, all upstream tests, and quick benchmarks passed.
- Sandlock is reproduced strongly enough to use as a main sandbox/workspace
  source, but not as a full-conformance claim: build, CLI tests, Go in-tree
  tests, COW/protected-path smoke, and most Rust/Python tests passed; named
  UNIX socket deny tests and two Python resource-control tests are negative.

## Agent Runtime And Environment Addendum

The dedicated agent-runtime/environment reproduction record is:

- `docs/tmp/2026-07-01-agent-runtime-environment-workload-reproduction.md`
- `docs/tmp/2026-07-01-multi-docker-eval-evaluator-probe.md`
- `docs/tmp/2026-07-01-menvdata-polyglot-eval-extension.md`

The short result is:

- OpenHands SDK, Terminal-Bench, SWE-MiniSandbox, SWE-ReX, AgentCgroup, and
  SWE-rebench V2 now have executable evidence on this machine.
- OpenHands SDK passed a 195-test targeted workspace/file/terminal subset.
- Terminal-Bench passed unit, installed-agent, and Docker-backed run/resume
  tests. Sixty-three selected official oracle task runs now reproduce protected
  paths, deterministic packaging, directory reconstruction, services/logs,
  protected-data cleanup, Git/object cleanup, archive/TLS/deployment tasks,
  data/log/database transforms, security repair, large-file/pipeline/RPC and
  network-flow tasks, forensics/document tasks, build/environment/debug/compile
  tasks, and service/API state such as LocalStack S3 and spreadsheet creation.
  Seven additional selected tasks
  are preserved as setup/content/artifact/workload-boundary negatives:
  `postgres-csv-clean`, `cron-broken-network`, `broken-networking`, unmodified
  `shell-deobfuscation`, `password-recovery`, `build-cython-ext`, and
  `incompatible-python-fasttext`. The `amuse-install` task was requested and
  produced partial logs, but no upstream result summary; keep it as an
  attempted task without result rather than counting it in accuracy.
  `mlflow-register` also produced agent-side service-registration evidence but
  no upstream result summary and a client exit 255, so it is the second
  attempted-without-result boundary. The
  `shell-deobfuscation` workload oracle passes under an isolated
  permission-adapted replay. `build-cython-ext` passed 10/11 parser checks
  before failing the repository-test oracle. Dedicated records are
  `docs/tmp/2026-07-01-terminal-bench-acl-workload-reproduction.md`,
  `docs/tmp/2026-07-01-terminal-bench-filesystem-suite-reproduction.md`,
  `docs/tmp/2026-07-01-terminal-bench-file-security-suite-reproduction.md`, and
  `docs/tmp/2026-07-01-terminal-bench-git-service-suite-reproduction.md`, and
  `docs/tmp/2026-07-01-terminal-bench-package-data-suite-reproduction.md`, and
  `docs/tmp/2026-07-01-terminal-bench-data-log-service-suite-reproduction.md`,
  `docs/tmp/2026-07-01-terminal-bench-data-sql-log-suite-reproduction.md`,
  `docs/tmp/2026-07-01-terminal-bench-security-network-suite-reproduction.md`,
  `docs/tmp/2026-07-01-terminal-bench-file-service-pipeline-suite-reproduction.md`,
  and
  `docs/tmp/2026-07-01-terminal-bench-forensics-document-suite-reproduction.md`,
  and
  `docs/tmp/2026-07-01-terminal-bench-build-env-suite-reproduction.md`, and
  `docs/tmp/2026-07-01-terminal-bench-compile-system-suite-reproduction.md`,
  and
  `docs/tmp/2026-07-01-terminal-bench-env-debug-suite-reproduction.md`, and
  `docs/tmp/2026-07-01-terminal-bench-data-file-debug-suite-reproduction.md`,
  and
  `docs/tmp/2026-07-01-terminal-bench-service-api-suite-reproduction.md`.
- SWE-MiniSandbox passed the private `/tmp` sandbox isolation tests.
- AgentCgroup passed local daemon/wrapper tests and trace characterization, and
  built scheduler/process components after submodule init; memcg remains
  blocked by missing `memcg_bpf_ops` in running kernel BTF.
- SWE-rebench V2 passed prompt rendering and a one-task Docker sample eval.
- MEnvData-SWE now has two passing executable image/evaluator rows
  (`python-attrs__attrs-586` and `go-task__task-1814`) plus one preserved
  negative Rust row (`eyre-rs__color-eyre-114`). SWE-Factory-Gym has one
  executable evaluator slice. Multi-Docker-Eval has a one-task evaluator probe
  with a synthetic `docker_res`, but the official full benchmark reproduction
  remains unclosed without released or generated `docker_res`. MEnvAgent,
  SWE-Factory, and DockSmith remain broader environment-construction sources,
  but the current audit did not reproduce each full system workload
  end-to-end.
