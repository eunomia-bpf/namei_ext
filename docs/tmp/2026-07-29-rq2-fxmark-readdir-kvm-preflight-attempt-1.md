# FxMark Readdir KVM Preflight Attempt 1

## Run

```text
make kvm-fxmark-readdir-preflight \
  RUN_ID=20260729T075043Z-fxmark-readdir-preflight-v1
```

Raw root:

```text
results/experiments/fxmark-readdir-preflight/
  20260729T075043Z-fxmark-readdir-preflight-v1/
```

The run used clean source commit
`788a418d80ffdaa3b9f652ced5934839c2d6e0ca` and clean kernel commit
`1e81d4793c78b7667d0798248c70c0b15a2c3877`.

## Outcome

Attempt 1 failed during the first `PASS` cell. The stock and unattached boots
completed, and all four `MRDL`/`MRDM` cells in each boot passed. The failed
`MRDL`, one-worker `PASS` observation preserved:

- successful real BPF load and cgroup attachment, program ID 5;
- successful two-second FxMark run;
- exactly 8,192 files and two physical directories;
- all 8,194 logical entries, including `.` and `..`;
- complete unique-name validation;
- matching logical and lower directory identity;
- two lookup policy runs; and
- 8,204 readdir policy runs.

The predeclared oracle expected 8,194 readdir policy runs, so the cell correctly
failed closed.

## Root Cause

The oracle incorrectly equated BPF readdir invocations with entries returned
to user space. `namei_ext_filldir()` invokes BPF before the original
`filldir64()` actor. When a `getdents64` buffer cannot hold the next candidate
dirent, BPF has already run for that candidate, but `filldir64()` returns false
and the filesystem retries the same candidate in the next syscall.

The observed ten-run surplus is therefore a buffer-boundary retry count, not
an extra visible name and not unrelated policy execution.

## Repair

The validation child now uses direct, fixed 4 KiB `getdents64` calls and
records every non-empty call. For each enumerated directory, every non-final
non-empty call contributes one candidate-entry retry. The exact oracle is:

```text
retry_runs = nonempty_getdents_calls - enumerated_directories
readdir_policy_runs = returned_entries + retry_runs
total_policy_delta = lookup_policy_runs + readdir_policy_runs
```

The child still parses every returned record, rejects malformed and duplicate
names, and requires the complete expected bitmap. The analyzer and Make
finalizer independently check the new exact relationship.

This equation is scoped to this experiment's tmpfs lower filesystem and fixed
4 KiB validation buffer. Current tmpfs uses `simple_offset_dir_operations`;
`offset_readdir()` retains the current entry offset when the actor rejects an
entry, so the next syscall retries that entry. The paper must not generalize
the equation to arbitrary filesystem iterators.

## Repair Review

A fresh independent read-only review checked `namei_ext_filldir()`,
`filldir64()`, tmpfs `offset_readdir()`, the direct `getdents64` parser, runner,
analyzer, Make finalizer, tests, and this failure record. It found no blocking
correctness, provenance, or fairness issue.

Final verdict: GO

## Attempt Accounting

This is real KVM preflight attempt 1 of the maximum three. The failed root is
immutable and excluded from paper performance results. A repaired attempt 2
requires a new clean commit and fresh run ID.
