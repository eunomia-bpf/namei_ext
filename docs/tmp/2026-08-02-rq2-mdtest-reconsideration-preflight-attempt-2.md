# RQ2 mdtest Reconsideration Preflight Attempt 2

## Purpose

This record preserves the second real KVM preflight under the 2026-08-02
reconsideration plan. The immutable result root is:

```text
results/experiments/mdtest-cold-metadata-rq2-preflight/20260802T084214Z-mdtest-reconsideration-preflight02/
```

## Outcome

The command-size repair succeeded. Stock, unattached, PASS, and SELECT each
completed a real KVM boot with exact vCPU-affinity verification and all six
mdtest observations. These four conditions produced 24/24 passing create,
cold-stat, and cold-remove observations across one and four MPI ranks.

The official FUSE condition booted and passed affinity verification, mount-type
and `/dev/fuse`-fd engagement checks, then failed its one-rank create phase.
The raw observation records `phase_status=255`, a live official passthrough
daemon, and a client-side `close(14) failed`. No FUSE performance number is
valid, the 5-condition matrix is incomplete, and no attempt-2 value enters the
paper.

## Root Cause

A host diagnostic with the same unmodified libfuse 3.18.2 passthrough binary,
mount options, and official mdtest reproduced the failure independently of
`namei_ext`:

```text
8 files, inherited RLIMIT_NOFILE=1024: pass
4096 files, inherited RLIMIT_NOFILE=1024: fail near file 1007
4096 files, RLIMIT_NOFILE=262144: pass with all 4096 files
```

With `cache=always` and a long entry timeout, the official passthrough retains
backing descriptors for cached inodes. The inherited soft open-file limit was
1024 even though the system hard limit was 1,048,576. This resource limit made
the optimized baseline invalid at the declared namespace size; it is not a
FUSE-versus-`namei_ext` result.

## Repair For Attempt 3

The controller raises only the official FUSE daemon's soft `RLIMIT_NOFILE` to
262,144 before `exec`. The parent reads the live daemon's limit with `prlimit`
and rejects the phase unless it observes that exact value. Each FUSE
observation records the verified limit, and the analyzer rejects missing,
lower, or non-FUSE values. The official FUSE source, mount options, mdtest
source, conditions, ranks, operations, item counts, cache-drop sequence,
correctness oracle, and performance analysis remain unchanged.

## Repair Validation

- The controller rebuilt with `-Wall -Wextra -Werror`.
- The 19 mdtest analyzer tests, six legacy affinity-controller tests, and ten
  read-only affinity-verifier tests pass.
- Source feasibility reran unmodified mdtest create/stat/remove at one and four
  ranks and rechecked the official FUSE options.
- A same-binary host positive control with `RLIMIT_NOFILE=262144` completed all
  4,096 file creates that failed under the inherited 1,024 limit.
- The diff does not change any condition, rank, operation, sample size,
  cache-drop rule, source parser, tree oracle, or comparison formula.

## Decision

```text
run status: incomplete
paper evidence: none
preflight budget: attempt 2 consumed; one attempt remains
next action: test and audit the resource-limit repair, then run a fresh attempt
  3 only if the existing scientific protocol remains unchanged
```
