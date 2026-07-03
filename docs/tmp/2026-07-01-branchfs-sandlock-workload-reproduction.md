# BranchFS And Sandlock Workload Reproduction

Date: 2026-07-01

## Motivation

The current paper direction uses AI agent workspace lifecycle as the strongest
candidate workload family. BranchFS and Sandlock are high-priority sources
because both expose agent-oriented workspace state transitions rather than only
generic filesystem microbenchmarks:

- BranchFS: branch creation, nested branches, `@branch` virtual paths,
  commit-to-parent, abort, and FUSE-visible file operations.
- Sandlock: process sandbox runs, readable/writable path classes, COW workdir,
  dry-run, chroot/fs-mount, checkpoint/fork, policy callbacks, and protected
  paths.

This record reproduces their upstream workload/test entry points and records
what can be reused by `namei_ext`. The purpose is workload selection, not
proving static tables or any other interface impossible.

Raw logs are under:

- `results/reproduction/2026-07-01-official-workloads/branchfs/`
- `results/reproduction/2026-07-01-official-workloads/sandlock/`

Source commits:

- BranchFS: `a4b6592d31aa`
- Sandlock: `e7f2993a2b10`

## BranchFS

### Workload Shape

BranchFS provides a FUSE-based speculative workspace workload:

- mount a base tree as a workspace;
- create isolated branches from parent state;
- modify files in a branch;
- commit a leaf branch into its parent;
- abort a leaf branch and discard its delta;
- access branches through `@branch` virtual paths;
- validate nested branch inheritance, readdir behavior, symlinks, rename,
  delete/tombstone behavior, and mount cleanup.

The benchmark suite adds:

- branch creation latency versus base tree size;
- commit latency versus modification size;
- abort latency;
- read/write throughput through the FUSE layer;
- nested branch read latency.

### Commands And Results

Logs:

- `branchfs-cargo-build-release.log`
- `branchfs-run-all-tests.log`
- `branchfs-python-bench-quick.log`
- `branchfs-bench-results-quick.json`
- `branchfs-shell-quick-bench.log`

Results:

- `cargo build --release` passed.
- `tests/run_all_tests.sh` passed all 13 suites.
- The shell suites cover abort, mount, branch create, branch directories,
  branch validation, commit, file operations, quota, rename, symlink, and
  unmount.
- Rust integration tests passed:
  - `test_ioctl`: 8 passed, 0 failed.
  - `test_integration`: 22 passed, 0 failed.
- Python quick benchmark passed and wrote JSON. It produced read/write
  throughput and nested-depth latency rows. It did not find daemon `[BENCH]`
  timing rows for creation/commit/abort in this checkout, so those internal
  timing rows should not be claimed from the Python benchmark.
- Shell quick benchmark passed and produced direct operation timings for branch
  creation, commit, abort, read, and switch.

Representative shell quick benchmark results:

- branch creation: 100 files 102 ms, 1000 files 110 ms, 10000 files 161 ms,
  including CLI/socket overhead;
- commit: 1 KB 3 ms, 10 KB 2 ms, 100 KB 2 ms, 1000 KB 4 ms;
- abort: 1 KB 2 ms, 100 KB 2 ms, 1000 KB 2 ms;
- read: 1 MB 1 ms;
- switch branch: 860 us.

Representative Python benchmark rows:

- read throughput: 3656.2 MB/s on a 20 MB file with 64 KB blocks;
- write throughput: 1496.2 MB/s on the same shape;
- nested read latency: depth 1 121.2 us, depth 4 71.2 us.

### Reuse Decision

BranchFS is a primary workload seed for AI agent workspace lifecycle.

Reusable pieces:

- branch/session path-view transitions;
- commit/abort oracle;
- nested branch inheritance;
- `@branch` virtual namespace;
- multi-agent parallel branch access;
- symlink, rename, readdir, tombstone, and cleanup oracles;
- FUSE baseline behavior for the same workflow.

For `namei_ext`, the right reuse is not "reimplement BranchFS." The useful
subset is the path-view policy problem: choosing which branch view a lookup or
directory enumeration should expose while preserving ordinary lower-filesystem
file semantics.

## Sandlock

### Workload Shape

Sandlock provides a lightweight agent sandbox workload:

- `sandlock run` with readable and writable path policies;
- COW workdir with commit on success;
- dry-run that reports changes and discards them;
- protected path denial;
- chroot and per-sandbox fs-mount;
- checkpoint/fork/reduce;
- dynamic `policy_fn` callbacks;
- profile-based execution;
- Python and Go SDK wrappers.

### Commands And Results

Logs:

- `sandlock-cargo-build-release.log`
- `sandlock-cargo-test-release.log`
- `sandlock-core-integration-release-tee-serial.log`
- `sandlock-core-named-unix-short-target.log`
- `sandlock-cli-tests-release.log`
- `sandlock-python-venv-install.log`
- `sandlock-python-pytest.log`
- `sandlock-go-test.log`
- `sandlock-go-test-sandlock-repo.log`
- `sandlock-cli-cow-protected-path-smoke.log`

Build and CLI results:

- `cargo build --release` passed.
- Full `cargo test --release` started successfully but ended negative because
  `sandlock-core` integration had failures.
- `cargo test --release -p sandlock-cli` passed:
  - 5 CLI unit tests passed;
  - 22 CLI integration tests passed;
  - 6 profile integration tests passed.
- The CLI tests cover `sandlock run`, exit status, denied paths, hostname
  virtualization, `--no-supervisor`, writable paths, nested sandboxing, COW
  commit on CLI exit, UID mapping, and profiles.
- Manual CLI smoke passed:
  - COW workdir commit updated `file.txt` and created `created.txt` on the host
    side after sandbox exit;
  - reading `/etc/group` without `/etc` readability failed with permission
    denied and exit status 1.

Rust core integration results:

- The first redirected full run recorded 270 passed and 10 failed in
  `sandlock-core` integration.
- Re-running with `tee` and one test thread removed the checkpoint false failure
  caused by restoring a file descriptor pointing at the raw log path. The rerun
  recorded 271 passed and 9 failed.
- The passing core tests include checkpoint metadata, chroot/fs-mount, COW
  create/abort/relative path/commit/open directory/statx/exec, dry-run,
  fork/reduce, handlers, HTTP ACL, network rules, policy callbacks, procfs
  virtualization, resource controls, sandbox nesting, seccomp enforcement, and
  user mapping.
- The remaining 9 failures were named UNIX socket Landlock tests.
- Re-running the named-UNIX subset with short `CARGO_TARGET_DIR=/tmp/sl-t`
  removed the AF_UNIX path-length problem. In that run, 4 allow-path tests
  passed and 5 deny-path tests failed because the operation succeeded when the
  test expected `EACCES`.

Python and Go SDK results:

- Python editable install with `sandlock[mcp]` passed in a local venv.
- `pytest tests/ -q` recorded 354 passed and 2 failed.
- The Python failures were resource-control assumptions:
  - `test_restrict_max_memory`: the unrestricted 256 MiB baseline did not
    complete the Python 128 MiB allocation on this host;
  - `test_throttle_result_correct`: the CPU-throttle run returned failure.
- Go SDK default `go test ./...` failed because `sandlock.pc` was not installed
  for pkg-config.
- Go SDK in-tree mode from the upstream README passed:
  `go test -tags sandlock_repo ./...`.

### Reuse Decision

Sandlock is a primary workload seed for the service/agent sandbox side of the
AI workspace story, with caveats.

Reusable pieces:

- sandbox run lifecycle;
- readable/writable path classes;
- COW workdir commit and dry-run behavior;
- protected-path oracle;
- chroot/fs-mount path mapping;
- checkpoint/fork/reduce as agent lifecycle sub-experiments;
- dynamic policy callback traces;
- SDK-level API workload shapes.

Do not claim full Sandlock conformance from this host:

- named UNIX socket deny tests are negative in the short-path rerun;
- two Python resource-control tests are negative;
- default Go SDK mode requires installing pkg-config metadata, while in-tree
  mode passes.

These caveats do not make Sandlock unusable for `namei_ext`. They define which
oracles can be reused safely. The best `namei_ext` subset is protected path and
workspace path-view behavior, not Sandlock's whole syscall/network/resource
sandbox.

## Implication For The Paper Idea

BranchFS and Sandlock strengthen the current idea:

> many agent systems implement broad FUSE/custom/sandbox machinery, but a
> central repeated subproblem is dynamic path-view selection during workspace
> state transitions.

`namei_ext` should target that subproblem: a narrow VFS name-resolution
extension where an eBPF policy selects lookup/readdir views while the kernel and
lower filesystem keep file objects and data semantics. The paper should compare
against natural mechanisms such as FUSE, materialized workspace trees,
copy/symlink/bind/projected views, and native sandbox/workspace mechanisms. It
should not claim that BranchFS or Sandlock "need eBPF" or that a table-only
interface is the main thing being disproved.

## Next Step

The next implementation step is a Make-owned, KVM-validated
`namei_ext` AI-agent workspace workload that combines the strongest reusable
pieces:

- BranchFS-style branch create, nested branch, `@branch`, commit, and abort;
- Sandlock-style COW/protected-path/dry-run sandbox oracles;
- AgentFS and Redis AFS workspace lifecycle and checkpoint/fork operations;
- Mirage cross-mount command oracles if a multi-backend namespace slice is
  needed.

The result should report correctness first, then setup/update/storage/latency
against natural baselines. It should not add new table-centered experiments as
the mainline.
