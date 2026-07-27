# RQ2 FxMark Plan Review

## Review Scope

One fresh read-only reviewer checked the RQ2 FxMark plan against the frozen RQ,
the evaluation promises, the pinned source, the kernel patch, and current KVM
infrastructure. The initial verdict was **revise before preflight**.

## Blocking Findings And Resolution

1. **Condition isolation.** Running unattached, `PASS`, `SELECT`, and FUSE in
   one patched boot could leave the system-wide cgroup-BPF static key or cache
   state as a competing explanation. The revised design uses one fresh boot per
   condition and ten five-condition blocks.
2. **FUSE kernel and CPU budget.** FUSE on the patched kernel would include the
   proposed patch in the baseline. It now runs on the matched stock kernel.
   Every guest has four vCPUs and the figure is explicitly worker scaling.
   FxMark workers use `0..n-1`; FUSE may use all four vCPUs, which favors the
   external baseline.
3. **FxMark error propagation.** The pinned source does not return worker or
   affinity failures. A minimal, hashed source patch will propagate these
   failures without changing successful measured operations. The runner also
   enforces a hard timeout and exact tree cardinality.
4. **Measured-phase engagement.** Setup could satisfy whole-run policy and
   FUSE counters. The revised design uses FxMark's official `profbegin` and
   `profend` hooks to switch separate measured-phase counters. `SELECT` must be
   observed during `main_work`. Cached FUSE may have zero measured requests,
   but must prove a FUSE mount and setup requests.
5. **Pairing and stock construction.** Each repetition is now one five-boot
   block. Analysis uses paired bootstrap resampling with seed `20260726`.
   Stock construction checks the ancestor commit and requires final configs to
   differ only by `CONFIG_NAMEI_EXT`.

## Optional Findings

The FUSE metadata TTL is increased from 60 seconds to one hour so large
`MRPM`/`MRPH` setup cannot expire it before measurement. Host topology and
governor will be recorded. QEMU vCPU thread pinning is deferred because it is
not required for validity when every paired condition uses the same fixed
guest configuration. The result is explicitly limited to cache-hot `stat()`
path resolution; open, readdir, cache-cold, and tail-latency promises require a
separate RQ2 experiment.

## Review Outcome

The revised plan resolves every blocking scientific and executability defect.
Preflight may proceed after the implementation itself passes local build and
Make dry-run checks.

## Post-Preflight Instrumentation Review

The first full run exposed a flaw in revision 1 of the engagement gate:
`PASS` and `SELECT` performed BPF map lookups and atomic counter updates on
every pathname component. These operations were not part of the proposed
minimal policy and materially changed the quantity being measured. The run was
stopped and invalidated.

The revised gate removes all measured-path BPF instrumentation. An independent
follow-up review judged this scientifically preferable subject to one blocking
condition: the benchmark leader must be proven to reside in the queried cgroup
before timing. The final driver therefore:

1. moves the FxMark leader into the cell cgroup and stops it before `exec`;
2. records and verifies `/proc/<pid>/cgroup` against that exact cgroup;
3. queries the attached BPF program ID before and after the cell;
4. resumes the leader only after the membership gate passes;
5. uses the nonexistent logical `view` path plus the exact lower-tree oracle to
   make `SELECT` self-validating.

FUSE request counters remain because they execute in the baseline daemon, not
on cache-hit client lookup. The reviewer approved the corrected design with
the cgroup-membership condition enforced.
