# Result Review: Build Action Sandboxing RQ1 Formal 01

## Inputs

- Plan:
  `docs/tmp/2026-07-29-build-action-sandboxing-rq1-formal-plan.md`
- Formal raw result:
  `results/experiments/build-action-sandboxing-rq1/20260729T175251Z-w3-formal01/`
- Source commit:
  `eee4d5d95d844d5a1045f5f9773301fbb94a89fa`
- Kernel commit:
  `621aff8d1bb52fad718f11fd882c956d6a5686ae`

## Judgment

- Run status: invalid.
- Tested hypothesis: inconclusive.
- Research value: supporting.
- Paper impact: additional RQ evidence if the raw cleanup gap is repaired.
- Next paper decision: do not promote this run; record each cgroup removal and
  rerun the unchanged matrix.

## Review

The three formal boots otherwise contain complete and consistent evidence.
Each boot has 16 lifecycle cases, two action-view records, four lower-object
records, seven positive policy counters, and one passing summary. Across the
matrix, all six Bazel actions completed, each action read its own expected
bytes through the same logical pathname, logical and selected-lower
device/inode values matched, and the undeclared child was hidden from lookup
and directory enumeration. All twelve lower-object records preserved the
planned metadata fields and bytes. Policy detach, target clearing, external
BPF/FUSE inventory, and dmesg checks passed.

The sole validity blocker is the planned cgroup cleanup oracle. The controller
attempts both `rmdir` operations and folds a failure into the summary, but it
does not emit each removal result as a raw observation. The reviewer therefore
could not independently recompute that specific cleanup condition.

The output bytes, errno values, inode observations, directory-enumeration
behavior, and lower-file checks are direct oracles rather than policy-produced
success labels. Policy counters establish mechanism engagement only. The
generated analysis label is not treated as evidence.

The finding does not contradict the mechanism result and does not justify
changing the RQ, workload, or claim. It requires only direct raw records for
the two cleanup operations and a fresh run.
