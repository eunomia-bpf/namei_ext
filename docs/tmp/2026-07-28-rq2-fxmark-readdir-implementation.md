# RQ2 FxMark Directory Enumeration Implementation

Date: 2026-07-28

## Purpose

This implementation adds the missing standard directory-enumeration row to
RQ2. The existing formal FxMark result covers cache-hot `stat()` path walks.
The new suite runs corrected FxMark `MRDL` and `MRDM` so that every returned
directory entry executes the `namei_ext` readdir decision and can be compared
with a feature-equivalent FUSE view.

The implementation follows the frozen protocol in
`2026-07-28-rq2-fxmark-readdir-experiment-plan.md`. It does not change the
published lookup matrix or its analyzer.

## Source Inspection And Correction

The pinned FxMark source is commit
`3f29552ce7ba6be24c4172e6e2c2c1f603209953`. Inspection covered:

- `src/MRDL.c`, which gives each worker a private directory;
- `src/MRDM.c`, which gives all workers one shared directory;
- FxMark worker setup, affinity, timing, and result aggregation; and
- the project's existing `fxmark-correctness.patch`.

The upstream directory tests created files for the benchmark duration and
continued counting calls after `readdir_r()` returned end of directory.
`bench/fxmark/fxmark-readdir-correctness.patch` therefore:

1. creates exactly 8,192 uniquely named files per worker with checked
   `O_EXCL`, `close()`, and worker errors; and
2. closes and reopens the directory at EOF while counting only non-null
   returned entries.

The original archive, both patches, and patched `MRDL.c`/`MRDM.c` are copied
into every result root with independent checksums.

## Cell Runner

`bench/fxmark/fxmark_cell.c` now supports `MRDL` and `MRDM` with exact physical
tree cardinality:

| Test | Files | Directories |
| --- | ---: | ---: |
| `MRDL`, `W` workers | `8192 * W` | `1 + W` |
| `MRDM`, `W` workers | `8192 * W` | `1` |

The controller pre-creates private worker directories before policy setup.
For attached rows it registers exact scopes for `work_root` plus the shared
physical directory or each private physical directory. At four workers this
uses five of the kernel's eight exact-scope slots.

After the timed interval, the controller enables kernel BPF run statistics and
records a baseline. A child then enters the benchmark cgroup and opens all
logical directories. It checks lower-directory device and inode identity for
direct and `SELECT` views, then stops on a pipe barrier. The controller records
the lookup delta after the opens, releases the barrier, and the child performs
only fixed 4 KiB `getdents64` calls on the already-open descriptors.

The child parses every returned record and expected FxMark filename, rejects
malformed or duplicate entries, requires one `.` and `..` per directory, and
verifies a complete bitmap. Because VFS invokes policy before the userspace
fill actor, a candidate that does not fit at a buffer boundary runs policy once
before being retried in the next syscall. The exact BPF readdir run-count delta
for this experiment's tmpfs iterator and fixed validation buffer must equal:

```text
retry runs = non-empty getdents calls - enumerated directories
readdir runs = returned entries + retry runs
```

BPF run statistics are disabled before the timed interval and disabled again
after validation. Pipe reads and child waits have explicit timeouts, and any
open, identity, enumeration, attribution, or cleanup failure fails the cell.

## FUSE Comparator

`bench/fxmark/fxmark_fuse.c` retains the existing favorable metadata and kernel
cache options. Its readdir callback now:

- honors a nonzero FUSE directory offset with `seekdir()`;
- passes the next `telldir()` position to the filler; and
- returns the underlying `readdir()` or `telldir()` error.

The measured-phase boundary uses an acknowledged Unix-domain control channel
instead of unacknowledged signals. The FxMark profile commands invoke the same
FUSE binary in control mode; the daemon changes phase before replying. A cell
requires exactly one setup-to-measured transition, exactly one
measured-to-after transition, and zero invalid commands.

The server records flat measured-phase `opendir`, `readdir`, and `releasedir`
counters. A FUSE directory cell cannot pass unless all three are positive.
The post-timing logical-name validator remains active while the FUSE mount is
live.

## KVM Suite

`mk/experiments/fxmark_readdir.mk` owns two entrypoints:

```text
make kvm-fxmark-readdir-preflight RUN_ID=<fresh-id>
make experiment-fxmark-readdir RUN_ID=<fresh-id>
```

Both require a clean repository and kernel tree, the kernel-source bpftool, the
matched stock and patched kernels, exact host-vCPU pinning to CPUs 4--7,
external BPF/FUSE inventory equality, stable TSC, complete kernel and source
provenance, and clean dmesg.

The preflight has five boots and 20 cells: two tests, one and four workers, and
all five conditions. The formal matrix has ten rotating five-condition blocks,
50 boots, and 300 cells over one, two, and four workers. The formal entrypoint
is intentionally outside aggregate suite membership until a reviewed preflight
passes. The formal run also hashes the preflight result-review document into
its immutable input manifest, so the authorization and reviewed protocol are
part of the formal result provenance.

## Analysis

`analysis/fxmark_readdir/analyze.py` validates the complete matrix before
computing any statistic. It rejects missing or duplicate cells, failed
correctness gates, wrong tree or logical-entry cardinality, incomplete names,
wrong selected identity, unaccounted BPF runs, and zero measured FUSE directory
requests. A `--run` analysis accepts only the frozen preflight or formal
matrix, including the declared CPU placement, order, inventory gate, duration,
worker set, and analysis seed.

Each published analysis contains `raw-inputs.sha256`, which binds the analysis
to the completed `run.json` and `observations.jsonl`. The analysis artifact
manifest hashes that binding file, and the report target revalidates both the
raw-input and analysis manifests.

The primary statistic is the paired per-block `SELECT/FUSE` throughput ratio
for each test/worker cell. Ten thousand deterministic bootstrap resamples
produce the median 95% interval. The result is supported only when every cell's
lower bound exceeds one; any upper bound at or below one is contradictory;
other complete outcomes are mixed.

## Local Validation

Completed local checks:

- `make fxmark-source`;
- `make fxmark-readdir-source-contract`;
- `make fxmark-fuse-readdir-contract`;
- `make fxmark-readdir-analysis-test`;
- warning-free `-Werror` builds of `fxmark_cell.c` and `fxmark_fuse.c`;
- 25 analyzer unit tests, including strict JSON integer typing, exact
  getdents retry attribution, FUSE phase acknowledgement, frozen run-manifest
  rejection, all declared rejection gates, and the non-degenerate throughput
  bootstrap;
- seven host-vCPU affinity verifier tests;
- host FUSE enumeration of all 8,192 names across multiple readdir requests
  with acknowledged measured-phase transitions;
- `git diff --check`; and
- shell syntax checks over expanded start and finalize Make recipes.

No modified-kernel KVM result has been produced yet. After one `NO-GO` repair
round, a fresh independent implementation review returned `GO`. The
implementation must now be committed and pushed so the clean-tree preflight
can run.

## Remaining Risks

- The first KVM preflight may expose a mismatch between exact directory scopes
  and the selected lower path that host tests cannot exercise.
- Kernel BPF run statistics are global; the external-inventory gate and exact
  attached-program ID limit attribution, but the KVM run must confirm the
  expected exact delta.
- FUSE request batching may vary by kernel, but completeness and positive
  measured request gates prevent a timing row from passing without real
  directory service.
- The formal matrix is not authorized until the five-boot preflight and its
  independent result review pass.
