# Spindle RQ2 FUSE Comparison Implementation

## Purpose

This implementation adds RQ2 depth to the completed W6 HPC File Staging case.
It does not change the seven mandatory RQ1 cases, and it does not replace any
W1--W7 source-oracle result. The experiment measures the cost of final pathname
selection after the official Spindle implementation has populated its cache.

The matched conditions are:

- `namei_ext`: the existing cgroup-attached Spindle policy selects 47 registered
  cache objects; and
- `fuse`: a libfuse 3.18.2 low-level filesystem implements the same 47 exact
  mappings and uses Linux FUSE passthrough for file I/O.

Both conditions run the unchanged Spindle `testsuite/test_driver` loader slice
and require its exact 44-line diagnostic transcript.

Each loader process moves into a condition-specific sibling cgroup after fork.
The `namei_ext` sibling has the policy attached and the FUSE sibling does not;
the per-launch migration cost is therefore common to both timed conditions.

## Files

- `experiments/spindle_staging/namei_ext_spindle_staging_rq2.c` implements the
  two-condition runner and reuses the reviewed W6 source population, mapping,
  preservation, and transcript helpers.
- `experiments/spindle_staging/Makefile` provides an explicit `rq2` build linked
  against the pinned static libfuse 3.18.2 library.
- `configs/benchmarks/spindle_staging_rq2.mk` freezes the preflight and formal
  matrix.
- `mk/experiments/spindle_staging_rq2.mk` owns artifact packaging, paired KVM
  boots, guest cleanup, hard gates, and analysis publication.
- `analysis/spindle_staging_rq2/analyze.py` computes the paired result, with
  unit tests in `analysis/spindle_staging_rq2/test_analyze.py`.

## FUSE Baseline

The baseline uses libfuse commit
`033844748010a3b8265bf1c90b9ae8ffe4cd9ca7` (`fuse-3.18.2`). It uses the
low-level multithreaded API with eight worker threads, `allow_other`,
`default_permissions`, long entry and attribute timeouts, and negotiated
`FUSE_CAP_PASSTHROUGH`.

The view first bind-mounts the original Spindle testsuite at a hidden read-only
lower path, then mounts FUSE over the application-visible testsuite path.
Mapped names select the corresponding Spindle cache object; other names pass
through to the hidden lower tree. The daemon supplies lookup and directory
operations, while successful regular-file opens receive positive kernel
passthrough backing IDs. A userspace `read` callback exists only as a measured
failure detector.

Mode changes and target withdrawal issue both inode and entry invalidations.
The run fails if passthrough is not negotiated, any backing open fails, a
measured read falls back to userspace, or an invalidation is not acknowledged.

## Correctness And Engagement

Each fresh boot performs these gates before timing is accepted:

1. Official Spindle serial pull mode populates exactly the 47 source-derived
   cache objects.
2. Every source/cache mapping has equal bytes and a distinct cache filesystem
   object.
3. A non-root probe opens every logical pathname and compares its bytes with
   the selected cache object. The `namei_ext` condition additionally requires
   exact lower device and inode identity.
4. Changing one cache object's mode to `0000` produces `EACCES`; restoration is
   followed by the mechanism-specific update or invalidation.
5. Every warmup and measured loader launch exits successfully and emits the
   exact 44-line transcript.
6. Every target has positive measured selection or passthrough engagement.
7. Withdrawing `libtest10.so` produces the expected loader failure without
   another hit on that target.
8. All source and Spindle cache payloads and required metadata remain
   unchanged, and no BPF attachment, FUSE mount, daemon, or temporary mount is
   left after the condition.

## Timing And Statistics

Timing begins immediately before `fork` and ends with blocking `wait4` after a
pidfd poll. Transcript parsing and JSON output are outside the timed interval.
The collector records elapsed time and child `rusage` for every launch. The
FUSE condition also records daemon CPU time, runqueue wait, context switches,
and stable thread count over the same measured window.

The preflight is one alternating pair of fresh modified-kernel KVM boots, with
one warmup and five measured launches per condition. The formal matrix is ten
pairs (20 fresh boots), with three warmups and 50 measured launches per boot.
Odd pairs run `namei_ext` first and even pairs run FUSE first.

The primary unit is the median loader latency from one boot. Analysis computes
the geometric mean of the ten paired FUSE/namei_ext boot-median ratios and a
deterministic paired bootstrap 95% confidence interval over log ratios.

## Alternatives Rejected

- libfuse 3.14 without kernel passthrough would charge avoidable userspace data
  forwarding to the baseline.
- One boot containing both conditions would allow one mechanism to inherit the
  other's cache state.
- Treating 500 loader launches as independent samples would overstate the
  statistical sample size; the boot pair is the experimental unit.
- Timing source Spindle population would measure a responsibility that both
  final-selection mechanisms reuse rather than implement.

## Validation Performed

- Strict C build with `-Wall -Wextra -Werror` passed.
- The resulting runner has no dynamic `libfuse.so` dependency.
- FUSE control responses, startup, and daemon exit have bounded internal
  timeouts; a failed sample stops its series and enters teardown immediately.
- Finalization and analysis run before completion; a failed gate marks the raw
  result root failed rather than leaving it reusable or mutating a completed
  root.
- The pinned libfuse source commit and Linux kernel FUSE passthrough config were
  checked by `make spindle-staging-rq2-host-gate`.
- Spindle runtime packaging and the 47-object archive passed the host artifact
  gate.
- Four analysis tests passed, including rejection of missing samples and failed
  workload oracles.
- Make parsing and `git diff --check` passed.

## Remaining KVM Validation

The real modified-kernel preflight must still confirm mount permission,
passthrough negotiation, positive backing IDs, explicit invalidation behavior,
FUSE inode lifetime under the loader, stable daemon resource snapshots, guest
cleanup, and the complete two-boot protocol. No performance claim is valid
until that preflight, an independent result review, the ten-pair formal run,
and final result review are complete.

The scope remains one-node Spindle source-derived final-object selection. The
experiment does not measure or claim Spindle distribution, cache population
scalability, production launch scale, or MPI behavior.
