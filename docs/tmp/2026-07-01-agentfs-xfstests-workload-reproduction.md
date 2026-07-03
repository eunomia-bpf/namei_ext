# AgentFS xfstests Workload Reproduction

Date: 2026-07-01

## Motivation

AgentFS `TESTING.md` lists `xfstests` quick generic as the next official
filesystem workload after `pjdfstest`. This record attempts that workload
against an AgentFS FUSE mount.

This is workload reproduction evidence, not a `namei_ext` mechanism claim.
`xfstests` exercises broad filesystem semantics; `namei_ext` intentionally
does not own most of those semantics.

## Sources

Local sources:

- AgentFS: `.cache/source-inspection/agentfs`
- xfstests: `.cache/source-inspection/xfstests-dev`

Commits:

- AgentFS: `0a014ebd4918615baff589ed17486e557e7c6a23`
- xfstests: `ffc8bad17e5b2f56e48dbac43f7c5ae8ac368fe5`

Raw evidence:

- `results/reproduction/2026-07-01-official-workloads/agentfs-xfstests/dependency-install.log`
- `results/reproduction/2026-07-01-official-workloads/agentfs-xfstests/xfstests-build-install.log`
- `results/reproduction/2026-07-01-official-workloads/agentfs-xfstests/xfstests-quick-generic.log`
- `results/reproduction/2026-07-01-official-workloads/agentfs-xfstests/summary.json`
- `results/reproduction/2026-07-01-official-workloads/agentfs-xfstests/mount-helper-adapter.log`
- `results/reproduction/2026-07-01-official-workloads/agentfs-xfstests/xfstests-quick-generic-adapted.log`
- `results/reproduction/2026-07-01-official-workloads/agentfs-xfstests/summary-adapted-partial.json`
- `results/reproduction/2026-07-01-official-workloads/agentfs-xfstests/xfstests-results-adapted-partial/`
- `results/reproduction/2026-07-01-official-workloads/agentfs-xfstests/xfstests-smoke-subset-adapted.log`
- `results/reproduction/2026-07-01-official-workloads/agentfs-xfstests/summary-smoke-subset-adapted.json`
- `results/reproduction/2026-07-01-official-workloads/agentfs-xfstests/xfstests-results-smoke-subset-adapted/`
- `results/reproduction/2026-07-01-official-workloads/agentfs-xfstests/system-cleanup.log`

## Setup

The run installed xfstests dependencies listed by upstream for Ubuntu/Debian
where they were missing, including `xfsprogs`, `attr`, `xfsdump`,
`xfslibs-dev`, `libcap-dev`, `liburing-dev`, `libtool-bin`, and related tools.

AgentFS and xfstests both built successfully. During the test attempt,
`/usr/local/bin/agentfs` and `/sbin/mount.fuse.agentfs` were installed to match
AgentFS `TESTING.md`. They were removed after the run; see
`system-cleanup.log`.

## Official Configuration Attempt

The first xfstests attempt followed the AgentFS `TESTING.md` shape:

```text
export TEST_DEV=<database file>
export TEST_DIR=<mount directory>
export FSTYP=fuse
export FUSE_SUBTYP=.agentfs
sudo ./check -g quick generic/
```

That form did not reach tests. AgentFS mounted the database, but the FUSE mount
source appeared as `agentfs:<database file>`, while xfstests checked for the
exact `TEST_DEV` source. The result was an immediate `xfstests_status=1` with
no tests run.

## Adapted Mount Helper

To reach the test body, I used a minimal local adapter:

- set `TEST_DEV=agentfs:<database file>`;
- set `SCRATCH_DEV=agentfs:<scratch database file>`;
- install a temporary `/sbin/mount.fuse.agentfs` wrapper that strips the
  `agentfs:` prefix before calling `agentfs mount`.

This makes xfstests' `findmnt -S $TEST_DEV` source check match the mounted
FUSE source. It is an adaptation of the official instructions, not an
unmodified upstream xfstests reproduction.

## Adapted Full Quick Attempt

An adapted `sudo ./check -g quick generic/` run started and produced real
xfstests result artifacts, but the long run was interrupted before a final
xfstests summary was written.

Preserved partial result:

- `tests_with_artifacts=50`
- `failed_out_bad=25`
- `notrun=18`
- `mountfail=17`
- `passish=7`
- `last_test=generic/067`

Representative failures:

- `generic/003`: atime/ctime after access/remount mismatch;
- `generic/005`: symlink loop/deep symlink expected-output mismatch;
- `generic/007`, `generic/009`, `generic/012`, `generic/014`, `generic/022`,
  `generic/024`, `generic/026`: output mismatch and mount failure artifacts;
- several tests were skipped because features such as `O_TMPFILE`,
  `xfs_io fzero`, `xfs_io fpunch`, defragmentation, or scratch mkfs behavior
  were unsupported for this FUSE configuration.

Because this run was interrupted, it is not a full quick-generic result.

## Adapted Smoke Subset

To obtain a closed result, I ran a bounded subset:

```text
sudo ./check generic/001 generic/002 generic/003 generic/004 generic/005 generic/006 generic/007 generic/008 generic/009 generic/011
```

Result:

- `exit=1`
- `tests_with_artifacts=10`
- `failed_out_bad=4`
- `notrun=2`
- `mountfail=2`
- `passish=4`

The xfstests summary was:

```text
Ran: generic/001 generic/002 generic/003 generic/004 generic/005 generic/006 generic/007 generic/008 generic/009 generic/011
Not run: generic/004 generic/008
Failures: generic/003 generic/005 generic/007 generic/009
Failed 4 of 10 tests
```

Representative failures:

- `generic/003`: access time not updated and change time changed after remount;
- `generic/005`: symlink expected-output mismatch;
- `generic/007`: output mismatch plus mount-failure artifact;
- `generic/009`: file range / unwritten extent expected-output mismatch plus
  mount-failure artifact.

## Reuse Decision

AgentFS now has evidence for both official conformance workloads:

- full `pjdfstest`: reproduced and strongly negative;
- `xfstests`: official unadapted config did not reach tests due source-name
  mismatch; adapted config reached tests, produced a partial quick-generic
  result, and produced a closed 10-test negative smoke subset.

This strengthens the source-role decision:

- AgentFS is useful as a real agent workspace workload source: mount,
  COW/overlay, cache invalidation, symlink/git-visible behavior, SDK tests, and
  npm-like path-operation mix.
- AgentFS should not be cited as a full POSIX/FUSE-conformant baseline on this
  host.
- The xfstests failures are mostly full-filesystem semantics, so they should
  inform related-work/baseline caveats rather than define the `namei_ext`
  path-view workload.

## Follow-up

If a full AgentFS xfstests result is needed, rerun the adapted quick-generic
configuration under a long-running non-interrupted session and preserve the
final xfstests summary. Keep it separate from main `namei_ext` workload
selection unless the paper explicitly adds a full-filesystem conformance
appendix.
