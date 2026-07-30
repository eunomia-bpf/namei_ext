# RQ2 mdtest Cold Metadata Implementation Review

## Purpose

This record captures the independent read-only review of the implementation for
the RQ2 mdtest cold and mutating metadata experiment. It covers implementation
readiness for one real KVM preflight. It does not approve formal execution or
interpret performance.

## Material Reviewed

The reviewer inspected:

- `docs/tmp/2026-07-29-rq2-mdtest-cold-metadata-experiment-plan.md`;
- `configs/benchmarks/mdtest_cold_metadata.mk`;
- `mk/experiments/mdtest_cold_metadata.mk`;
- `bench/mdtest/mdtest_cell.c`;
- `analysis/mdtest_cold_metadata/analyze.py`;
- `analysis/mdtest_cold_metadata/test_analyze.py`; and
- `docs/tmp/2026-07-30-rq2-mdtest-cold-metadata-implementation.md`.

The review checked plan conformance, condition and kernel mapping, process
attribution, cache-state evidence, filesystem identity, FUSE and policy
engagement, result lifecycle, analysis publication, and false-pass paths.

## Initial Verdict

The first review returned NO-GO with three P1 findings:

1. The cgroup descendant threshold could pass before all actual MPI ranks had
   been observed.
2. Cache drop and ext4 identity were represented by asserted booleans or
   constants rather than the actual operation results.
3. The owning target marked the run completed before analysis and then allowed
   analysis publication to mutate that completed result root.

The reviewer otherwise found the condition rotation, stock/patched mapping,
FUSE lifecycle, tree cardinality, parser, paired bootstrap, and verdict rules
consistent with the frozen plan.

## Repairs

The implementation now:

1. reads `OMPI_COMM_WORLD_RANK` from processes observed in `cgroup.procs`,
   accumulates the exact `0..ranks-1` set, requires that complete set plus the
   timeout leader, and preserves PID/rank/command audit rows;
2. records the requested cache-drop value, requested byte count, actual
   `write(2)` return value, and `errno`, while phase observations use the actual
   fresh-mount `statfs(2)` value; and
3. validates raw observations and publishes analysis while `run.json` remains
   `running`, then performs the one-way transition to `completed`. The analysis
   target rejects completed or failed runs and an existing final analysis
   directory.

## Validation Supplied To Follow-Up

- the controller was force-rebuilt with `-Werror`;
- `make mdtest-cold-metadata-source-feasibility` passed after the repairs;
- all 19 analyzer tests passed;
- all seven vCPU-affinity tests passed; and
- `git diff --check` passed.

## Follow-Up Verdict

The same independent reviewer re-read the repaired implementation and reported
no remaining P0/P1 blockers for one real KVM preflight. The reviewer confirmed
that the exact MPI rank-set proof replaced the old threshold, raw cache-drop
and actual ext4 identity evidence are preserved and validated, and analysis is
published before the completion transition.

Implementation verdict: GO

## Remaining Boundary

This GO authorizes one real KVM preflight under the frozen plan. The preflight
must still prove guest Open MPI rank observation, guest FUSE mount behavior,
real `cgroup/namei_ext` attachment, fresh ext4 and cache-drop execution, cleanup,
and complete five-condition evidence. Formal execution requires a separate
independent review of a valid preflight.
