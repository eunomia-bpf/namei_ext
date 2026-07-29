# Agent Workspace RQ3 Formal-v3 Result Review

Date: 2026-07-28

## Question

This experiment answers RQ3 for one fixed existing-object Agent workspace
oracle:

> Does `namei_ext` keep policy ownership narrower than a stackable filesystem
> when the required behavior is pathname selection and directory visibility?

It is a responsibility and fault-containment comparison, not a throughput
comparison and not a claim that stackable filesystems are unsafe.

## Compared Implementations

- `namei_ext`: the AgentFS-derived workspace policy runs through the real
  `cgroup/namei_ext` KVM attach path. The BPF program chooses lookup and
  directory-enumeration results over registered ext4 objects.
- Wrapfs-derived stackable filesystem: the official Wrapfs source at upstream
  commit `464802c8fd1a25413b295161c9bb9a4ce7bfa33b` was ported to Linux 7.1 and
  implements the matched workspace view over the same ext4 lower tree.
- FUSE: the already matched Agent workspace FUSE implementation is included as
  a supporting responsibility comparator. RQ2, not this experiment, owns the
  FUSE performance comparison.

Both executed implementations consume the same 37-row semantic-oracle
contract and compare exact 19-field lower/visible-tree manifests.

## Formal Protocol

Command:

```text
make experiment-agent-workspace-rq3 RUN_ID=20260728-rq3-formal-v3
```

Result root:

```text
results/experiments/agent-workspace-rq3-formal/20260728-rq3-formal-v3/
```

The run used three independent KVM boots. Every boot mounted a fresh ext4
lower filesystem, ran both mechanisms, exercised the fault matrix, collected
runtime attribution, and preserved source and artifact hashes.

The complete result is committed as a portable `namei_ext.run.v2` publication
bundle and listed in `configs/publication/published-formal.json`. The bundle
contains all raw boot observations, verifier logs, kprobe traces, tested source
files, runtime binaries, portable hash manifests, and replayable analysis.

Clean provenance was identical in all three boots:

- project commit: `1f5d0c9d699163cd70284dd21a4da6dbf02803bc`
- kernel commit: `1e81d4793c78b7667d0798248c70c0b15a2c3877`
- project dirty: false
- kernel dirty: false
- kernel submodule commit matched the running kernel
- Wrapfs upstream commit was fixed to the commit above

## Results

All three boots passed.

- Both mechanisms passed all 37/37 pairwise AgentFS-derived semantic oracles in
  every boot.
- `namei_ext` selected an ordinary lower file and then detached its policy and
  removed the child cgroup. Read, write, `fsync`, `fstat`, and `fchmod` on the
  already-open descriptor still used the lower file operations, and the BPF
  invocation counter did not change. This passed in 3/3 boots.
- The Wrapfs-derived implementation executed all 13 instrumented operation
  classes in every boot: superblock setup/teardown, lookup, readdir, open,
  read, write, fsync, getattr, setattr, create, rename, and unlink.
- All 21 fault-containment cells passed in every boot: two verifier-rejected
  programs and 19 independently loaded runtime malformed/unsupported
  decisions.
- Every runtime fault preserved statx/SHA-256 evidence for eight lower objects
  and exact before/after manifests for two directories.
- The analysis test suite passed 8/8 tests.

Exact Wrapfs kprobe counts were stable across boots:

| Method | Count per boot |
| --- | ---: |
| `fill_super`, `put_super` | 2 each |
| `lookup` | 28 |
| `readdir` | 10 |
| `open` | 22 |
| `read_iter` | 15 |
| `write_iter` | 2 |
| `fsync` | 1 |
| `getattr` | 10 |
| `setattr`, `unlink` | 1 each |
| `create`, `rename` | 2 each |

Source-derived accounting found nine deployed `namei_ext` kernel integration
files. The matched Wrapfs module compiled six sources and registered 34 unique
VFS operation slots. The supporting userspace FUSE policy registers 12
callbacks; the active kernel FUSE configuration compiles 15 client sources.
These counts describe ownership surface and are not a safety score by
themselves.

## Claim Decision

The result supports this scoped claim:

> For the existing-object Agent workspace view, `namei_ext` confines workload
> policy execution to pathname lookup and directory iteration. Ordinary
> operations on the selected file use the lower filesystem. A matched
> stackable implementation owns and executes superblock, lookup, directory,
> inode, and file methods for the same oracle. Invalid programs and unsupported
> decisions are contained at the verifier or declared errno boundary in the
> tested matrix.

The result does not establish complete-system security, prove that all custom
filesystems are unsafe, or cover synthetic contents, copy-up, write-conflict
resolution, distributed metadata, or arbitrary filesystem semantics. Those
requirements remain valid reasons to use FUSE, a stackable filesystem, or a
custom filesystem.

## Independent Review

The first independent review returned no-go because the two implementations did
not yet share exact pairwise oracle rows and deployed-source accounting was
incomplete. The experiment was repaired to use one 37-row contract, exact
tree manifests, compiled-source accounting, and runtime method attribution.
The reviewer then returned GO with no remaining blocker before the formal run.
