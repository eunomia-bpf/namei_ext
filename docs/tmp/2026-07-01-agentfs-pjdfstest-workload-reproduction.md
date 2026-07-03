# AgentFS pjdfstest Workload Reproduction

Date: 2026-07-01

## Motivation

AgentFS documents `pjdfstest` as an official POSIX/FUSE conformance workload in
`TESTING.md`. Earlier AgentFS reproduction covered the Go SDK, CLI lifecycle
tests, FUSE mount smoke tests, overlay/cache/symlink tests, and an npm-like
operation mix. This record closes the next official workload attempt: running
full `pjdfstest` against an AgentFS FUSE mount.

The goal is workload reproduction, not making AgentFS pass or fail for the
`namei_ext` claim. A negative result is still useful because it tells us which
semantics AgentFS does not fully implement on this host.

## Sources

Local sources:

- AgentFS: `.cache/source-inspection/agentfs`
- pjdfstest: `.cache/source-inspection/pjdfstest`

Commits:

- AgentFS: `0a014ebd4918615baff589ed17486e557e7c6a23`
- pjdfstest: `ededbeb2b44929972898afb87474b0937f78a877`

Raw evidence:

- `results/reproduction/2026-07-01-official-workloads/agentfs-pjdfstest/agentfs-pjdfstest-rerun.log`
- `results/reproduction/2026-07-01-official-workloads/agentfs-pjdfstest/summary.json`

## What Ran

The run followed the official shape from AgentFS `TESTING.md`:

1. Build `pjdfstest` with `autoreconf -ifs`, `./configure`, and
   `make pjdfstest`.
2. Build AgentFS CLI with `cargo build --release`.
3. Initialize an AgentFS database with `agentfs init testing`.
4. Mount `.agentfs/testing.db` through AgentFS FUSE.
5. Run `prove -rv <pjdfstest>/tests` from inside the mounted directory.

The first attempt used a non-existent `agentfs init --data-dir` argument and
failed before mounting. The rerun used AgentFS's normal `.agentfs/testing.db`
layout and reached the full pjdfstest workload.

The FUSE mount was unmounted after the run.

## Result

The official workload reproduced and failed:

- `Files=238`
- `Tests=8798`
- `Result: FAIL`
- `pjdfstest_status=1`
- `failed_files=75`
- `ok_lines=3085`
- `not_ok_lines=5713`

Representative failed classes include:

- device-node creation and follow-on semantics: `mknod` returned `EPERM`
  where pjdfstest expected success, which also caused later `chmod`, `stat`,
  `unlink`, and `O_EXCL` checks to observe `ENOENT` or wrong existence state;
- ownership and permission transitions: multiple `chown`, `chmod`, and
  unprivileged-user checks returned `EPERM` or no result where pjdfstest
  expected POSIX behavior;
- directory and link semantics: failures appeared in `mkdir`, `mkfifo`,
  `link`, `rename`, `rmdir`, `symlink`, and `unlink` groups;
- timestamp/truncation semantics: failures appeared in `truncate` and
  `utimensat` groups.

This is not a harness failure. AgentFS mounted successfully, pjdfstest executed
238 test files, and the workload produced normal TAP/prove output.

## Reuse Decision

AgentFS remains a strong agent-workspace workload source, but this run narrows
how it should be cited:

- cite AgentFS for session lifecycle, FUSE mounting, COW overlays, cache
  invalidation, symlink/git tests, SDK tests, and npm-like path-operation mix;
- cite this pjdfstest run as a reproduced full POSIX/FUSE conformance workload
  with a negative result on this host;
- do not claim full AgentFS POSIX/FUSE conformance;
- do not use pjdfstest failure as a `namei_ext` claim by itself, because
  `namei_ext` intentionally does not own create/write/chown/mknod/truncate
  semantics.

For `namei_ext`, the reusable part is the subset of AgentFS workloads dominated
by workspace setup, path visibility, branch/fork/checkpoint state, cache
invalidation, symlink/git-visible behavior, and operation-weighted path
resolution. The failed pjdfstest groups mostly exercise full filesystem
semantics outside the narrow VFS name-resolution boundary.

## Follow-up

The other official AgentFS workload, `xfstests` quick generic, was attempted
separately and is recorded in
`docs/tmp/2026-07-01-agentfs-xfstests-workload-reproduction.md`. The
unadapted documented configuration did not reach tests because of a mount-source
name mismatch; an adapted helper reached the test body and produced negative
partial/smoke evidence. A full uninterrupted adapted quick-generic run is only
needed if the paper adds a full-filesystem conformance appendix.
