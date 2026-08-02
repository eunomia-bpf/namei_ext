# Spindle RQ2 preflight code review

## Purpose

This review gates the two-boot KVM preflight for the W6 Spindle staging RQ2
comparison. It checks whether the namei_ext and FUSE conditions execute the same
source-derived workload and correctness oracle, and whether a failed launch,
daemon, boot, finalization, or analysis step can be mistaken for evidence.
This experiment adds RQ2 depth to W6; it does not merge, replace, or narrow the
seven mandatory W1--W7 case studies.

## Reviewed paths

- `experiments/spindle_staging/namei_ext_spindle_staging_rq2.c`
- `experiments/spindle_staging/Makefile`
- `configs/benchmarks/spindle_staging_rq2.mk`
- `mk/experiments/spindle_staging_rq2.mk`
- `analysis/spindle_staging_rq2/analyze.py`
- `analysis/spindle_staging_rq2/test_analyze.py`

## Findings and repairs

The first review blocked KVM execution because the FUSE lifecycle still had
unbounded waits, the startup probe could block inside `stat`, and a failed KVM
matrix could leave `run.json` in the `running` state. The runner now performs
the startup `stat` in a child with a pidfd timeout, bounds daemon wait and reap,
and uses a timed control-thread join. If cancellation and the second timed join
still fail, the isolated FUSE child exits without destroying objects that the
thread may still reference. Normal shutdown continues to issue
`fuse_session_exit`, return the control response, detach the mount, and reap the
daemon. Both preflight and formal Make entrypoints mark a matrix failure as a
failed run before exiting.

The review also confirmed that both conditions enter sibling cgroups during the
timed launch, while only the namei_ext cgroup attaches the policy. The FUSE
condition uses libfuse 3.18.2, a multithreaded low-level daemon, long entry and
attribute caching, and kernel passthrough. Both conditions use the same 47
selected objects, 44-line loader transcript, permission and withdrawal checks,
byte comparisons, preservation checks, and cleanup gate. Any failed oracle
stops sample collection and prevents timing analysis.

## Validation

- strict runner build with `-Wall -Wextra -Werror`: passed;
- isolated GCC `-fanalyzer` runner build: passed;
- five analyzer unit tests: passed;
- full `make spindle-staging-rq2-host-gate`: passed;
- static libfuse linkage check: passed;
- Make parse and `git diff --check`: passed;
- independent final code review: **GO** with no remaining P0/P1 blocker.

## Remaining gate

No KVM result is claimed by this review. The next gate is one paired preflight
with two fresh modified-kernel boots, one warmup, and five measured launches per
condition. A failed preflight result root remains immutable and must be replaced
by a fresh run ID after a forward fix.
