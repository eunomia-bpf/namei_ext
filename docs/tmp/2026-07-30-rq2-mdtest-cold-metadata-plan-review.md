# RQ2 mdtest Cold Metadata Plan Review

Date: 2026-07-30

## Scope

This record covers the independent scientific and executability review of
`docs/tmp/2026-07-29-rq2-mdtest-cold-metadata-experiment-plan.md`. The proposed
experiment tests whether the existing cache-hot RQ2 result extends to official
mdtest file creation, cache-cold stat, and cache-cold removal against one
feature-equivalent official FUSE baseline.

The reviewer inspected the fixed paper RQ2, current FxMark evidence, pinned IOR
4.0.0 source at commit
`967a9f65109760db8a3ac14a7fdd007f337d2960`, and pinned libfuse 3.18.2 source
at commit `033844748010a3b8265bf1c90b9ae8ffe4cd9ca7`. The review was read-only.

## Round 1

Initial verdict: NO-GO.

Admission passed. The reviewer found that the experiment directly addresses
the paper's open cache-cold and mutating-metadata uncertainty and does not need
another workload or baseline. Pinned mdtest source confirms that fixed-rank
split invocations with `-u`, `-i 1`, and default rank shifting reuse the same
directories and filenames.

### Blocking Findings

1. mdtest warnings were not hard failures. A failed stat can warn and continue
   while the intended item count still contributes to the reported rate.
2. The plan incorrectly described mdtest's reported Mean as an arithmetic mean
   of rank rates and did not freeze the exact summary parser.
3. Host CPUs 4--7 and 8--11 belong to different maximum-frequency classes,
   placing FUSE daemon threads on slower cores.
4. The command contract omitted root-safe MPI execution, foreground FUSE
   operation, fixed timeouts, a pinned libfuse runtime, and an explicit
   `clone_fd` choice.
5. The prose selected a `bench` component while the measured logical pathname
   contained `view`.
6. The ext4 image size, inode count, backing, initialization, and mount options
   were not fixed; lazy inode-table initialization could enter create timing.

### Optional Findings

The callback description included irrelevant xattr coverage; timed callback
counts were not available from the unmodified baseline; interpretation
precedence and bootstrap details needed precision; and compiler flags and wall
time were worth recording.

## Repairs

The plan now:

1. passes mdtest `--warningAsErrors` and rejects warning/error output;
2. parses the Mean column of the exact `SUMMARY rate` operation row and records
   mdtest's actual slowest-rank-times-ranks aggregate semantics;
3. maps eight guest vCPUs to homogeneous host CPUs 8--15 and explicitly confines
   clients to guest 0--3 and FUSE to guest 4--7;
4. freezes root-safe Open MPI arguments, foreground official
   `passthrough_ll`, `clone_fd`, static pinned libfuse, and phase/boot timeouts;
5. defines logical `view` as selecting physical ext4 `bench`;
6. fixes a 2 GiB ext4 image with 262,144 inodes, disabled lazy inode and journal
   initialization, a guest-local tmpfs backing, and `noatime`;
7. replaces callback-count language with structural FUSE engagement and untimed
   BPF attribution; and
8. freezes bootstrap resampling and verdict precedence.

## Follow-Up

Follow-up verdict: GO.

The same reviewer re-read the revised plan and the pinned official sources. The
review confirmed:

1. `--warningAsErrors`, process status, and warning/error output now gate every
   mdtest phase;
2. the plan records mdtest's slowest-rank-times-ranks aggregate and freezes the
   exact `SUMMARY rate` parser;
3. clients and the FUSE daemon receive disjoint guest vCPUs backed by homogeneous
   host CPUs 8--15;
4. root-safe MPI, foreground FUSE, `clone_fd`, pinned static libfuse, and all
   timeouts are explicit;
5. logical `view` consistently selects physical ext4 `bench`; and
6. ext4 size, inode capacity, tmpfs backing, lazy initialization, mount options,
   and empty test root are fixed.

All six Round 1 blockers are closed. The reviewer found the plan sufficiently
correct, fair, and executable for implementation and one real KVM preflight.
Formal execution remains contingent on implementation review and a valid,
independently reviewed preflight.

## Executability Amendment

Host source feasibility on Open MPI 4.1.6 found that the approved combination
of `--cpu-set 0-3` and `--map-by slot` defines conflicting `RANK_FILE` and
`BYSLOT` mapping policies, so Open MPI exits before launching mdtest. The
client command now uses:

```text
taskset -c 0-3 mpirun --allow-run-as-root \
  --bind-to core --map-by core --report-bindings
```

Direct one- and four-rank probes pinned rank 0 to CPU 0 and ranks 0--3 to CPUs
0--3 respectively. The same reviewer inspected the amended plan, controller,
and source-feasibility target.

Amendment verdict: GO.

The reviewer confirmed that this command preserves the approved four-CPU client
allocation and one-core-per-rank placement. FUSE remains isolated on CPUs 4--7,
all five conditions use the same client command, and the workload, metric,
cache, and interpretation protocols are unchanged. KVM preflight must retain
the `--report-bindings` output for both rank counts.
