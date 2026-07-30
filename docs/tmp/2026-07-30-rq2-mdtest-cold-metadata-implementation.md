# RQ2 mdtest Cold Metadata Implementation

## Motivation

The existing RQ2 evidence covers cache-hot lookup and directory enumeration.
It does not establish the cost of `namei_ext` for cache-cold metadata reads or
mutating metadata operations. The reviewed experiment plan therefore fixes one
official mdtest workload and one feature-equivalent official FUSE baseline for
file creation, cold stat, and cold removal.

This record covers implementation and host source feasibility. It is not a KVM
preflight result or performance result.

## Source And Protocol

The implementation uses:

- IOR/mdtest 4.0.0 at Git commit
  `967a9f65109760db8a3ac14a7fdd007f337d2960`;
- libfuse 3.18.2 at Git commit
  `033844748010a3b8265bf1c90b9ae8ffe4cd9ca7`;
- the unmodified low-level libfuse `example/passthrough_ll.c`;
- stock, patched-unattached, attached `PASS`, registered-target `SELECT`, and
  FUSE conditions;
- one and four MPI ranks; and
- separate mdtest create-only, stat-only, and remove-only invocations.

The preflight and formal dimensions, cache protocol, ext4 construction, CPU
allocation, interpretation rule, and bootstrap rule remain fixed in
`docs/tmp/2026-07-29-rq2-mdtest-cold-metadata-experiment-plan.md`.

## Files Implemented

- `configs/benchmarks/mdtest_cold_metadata.mk` freezes source identities,
  preflight and formal dimensions, CPU allocation, timeouts, storage sizes,
  analysis seed, and kernel commits.
- `mk/experiments/mdtest_cold_metadata.mk` owns source acquisition, builds,
  source feasibility, kernel-pair validation, artifact capture, the rotating
  five-condition KVM matrix, boot and matrix validation, and analysis.
- `bench/mdtest/mdtest_cell.c` owns one guest rank-count lifecycle: cgroup
  setup, fresh ext4 construction, logical-view setup, policy/FUSE lifecycle,
  mdtest phases, raw observations, and cleanup.
- `analysis/mdtest_cold_metadata/analyze.py` validates the complete frozen
  matrix and produces paired SELECT/FUSE summaries and figures.
- `analysis/mdtest_cold_metadata/test_analyze.py` tests matrix, row, workload,
  attachment, FUSE, cache-drop, tree, bootstrap, verdict, and output contracts.

## Guest Cell Design

Each rank-count cell creates a fresh 2 GiB sparse ext4 image on guest-local
tmpfs. `mkfs.ext4` receives 262,144 inodes and disables lazy inode-table and
journal initialization. The image is mounted with `loop,noatime`, and a
physical `bench` directory is exposed at the logical component `view`.

Stock, patched-unattached, and `PASS` use the same logical bind mount.
`SELECT` registers the physical ext4 directory as target ID 1, attaches the
existing exact-parent `fxmark_select` policy, and resolves `view` to that
registered object. FUSE mounts the official low-level passthrough example at
the same logical path over the same physical ext4 directory. The FUSE daemon
runs in the foreground on guest CPUs 4--7 with
`default_permissions,cache=always,timeout=86400,clone_fd`; clients use guest
CPUs 0--3.

For every condition, the controller moves the timeout/MPI process tree into a
fresh cgroup before execution. It polls `cgroup.procs`, reads each process's
`OMPI_COMM_WORLD_RANK` environment entry, and requires the complete exact rank
set `0..ranks-1` plus the timeout leader. The raw cgroup audit records every
observed PID, MPI rank, and command. Attached conditions additionally prove
stable program identity and nonzero execution with an untimed stats-enabled
probe. `SELECT` compares the logical and physical device/inode identity. FUSE
proves the mounted filesystem type, live daemon, and open `/dev/fuse`
descriptor.

Create runs without a cache drop. Before stat and remove, the controller
captures `/proc/meminfo`, calls `sync`, writes `3` to
`/proc/sys/vm/drop_caches`, and captures `/proc/meminfo` again. A raw event
records the requested value, requested byte count, actual return value from
`write(2)`, and `errno`; the phase is valid only for value 3, two bytes written,
and zero error. The phase row records the actual `statfs(2)` result for the
fresh ext4 mount rather than a declared constant. FUSE is remounted for each
phase. Raw mdtest stdout, stderr, cgroup audit, FUSE logs, mkfs/mount logs,
cache observations, rusage, and phase rows are retained.

Cleanup detaches policy state, clears registered targets, unmounts the logical
view and ext4/tmpfs mounts, verifies that the loop device is released, removes
the cgroup and cell tree, and only then marks attempted rows cleanup-complete.
The guest boot additionally requires empty BPF/cgroup and FUSE inventories
before and after both rank-count cells.

## Parser And Analysis

The parser locates exactly one `SUMMARY rate: (of 1 iterations)` section and
exactly one row for each file operation. It accepts the official whitespace
column format, requires exactly four finite numeric columns, and commits parsed
values only after the operation name matches. For the selected phase, Mean
must be positive; all inactive file-operation rows must be zero. With one
iteration, Max, Min, and Mean must agree at printed precision and Std Dev must
be zero.

Every phase row must carry the expected schema and pass process status,
warning, tree-cardinality, cache-drop, cgroup, MPI-binding, attachment,
selected-identity, FUSE-engagement, ext4-identity, and cleanup gates before any
performance summary is computed. Preflight emits diagnostic ratios only.
Formal analysis uses ten paired blocks and 10,000 paired bootstrap resamples
with seed 20260729.

The owning target validates the complete raw matrix while `run.json` is still
`running`, publishes analysis through a temporary directory, then marks the run
`completed`. The analysis target rejects a completed or failed run and rejects
an existing published analysis directory, so a completed result root cannot be
reanalyzed or mutated through the experiment entrypoint.

## Feasibility Repairs

Host source feasibility exposed and repaired four executable-contract defects:

1. mdtest 4.0.0 does not implement `--version`; source identity now comes from
   the fixed Git tag and commit rather than a nonexistent binary option.
2. Meson names the example `passthrough_ll`, while Ninja requires the generated
   `example/passthrough_ll` target path.
3. Open MPI 4.1.6 rejects `--cpu-set 0-3 --map-by slot` as conflicting mapping
   policies. The reviewed replacement uses `taskset -c 0-3`,
   `--map-by core`, and `--bind-to core`. Direct probes and official mdtest
   output show one-rank CPU 0 placement and four-rank CPU 0--3 placement.
4. The first parser expected a colon that official mdtest does not print and
   allowed nonmatching rows to overwrite a prior match. The parser now follows
   the official whitespace format and parses through a local value before an
   exact operation-name commit.

The MPI command amendment received an independent follow-up GO recorded in
`docs/tmp/2026-07-30-rq2-mdtest-cold-metadata-plan-review.md`.

The first independent implementation review returned NO-GO on three P1
findings: descendant-count cgroup evidence could pass before all MPI ranks were
seen, cache-drop and ext4 evidence were asserted rather than captured from the
actual operations, and the run was marked complete before analysis publication.
The implementation now requires the exact MPI rank set, preserves raw
cache-drop and actual `statfs` results, and publishes analysis before the
completion transition. A follow-up review is required before KVM execution.

## Validation Performed

`make mdtest-cold-metadata-source-feasibility` passes. It:

- builds the pinned unmodified mdtest and pinned static libfuse example;
- proves that the FUSE binary has no dynamic `libfuse.so` dependency;
- runs create, stat, and remove for both one and four ranks;
- parses all six official summaries;
- observes 64 and 256 files after create/stat;
- observes three and six directories after create/stat; and
- observes an empty benchmark root after remove.

The official FUSE help output confirms `source`, `cache=always`, and `clone_fd`.
After the implementation-review repairs, the controller was force-rebuilt with
`-Werror` and source feasibility was rerun successfully. Nineteen analyzer
tests and seven vCPU affinity tests pass. `git diff --check` passes.

## Remaining Risks

No real modified-kernel KVM cell has run yet. KVM preflight must establish that
guest Open MPI reports the expected bindings, guest FUSE supports the frozen
mount options, ext4 loop cleanup completes, the exact MPI rank set is observed
in the intended cgroup for short and four-rank phases, `PASS` and `SELECT`
attach through the real `cgroup/namei_ext` path, and all five condition boots
leave empty external inventories. The implementation follow-up review is GO and
is recorded separately. Formal execution remains contingent on a valid
independently reviewed preflight.
