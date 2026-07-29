# Result Review: Build Action Sandboxing RQ1 Formal 02

## Inputs

- Approved plan:
  `docs/tmp/2026-07-29-build-action-sandboxing-rq1-formal-plan.md`
- Plan review:
  `docs/tmp/2026-07-29-build-action-sandboxing-rq1-formal-plan-review.md`
- Repaired preflight:
  `results/experiments/build-action-sandboxing-rq1-preflight/20260729T180100Z-w3-preflight03/`
- Formal raw result:
  `results/experiments/build-action-sandboxing-rq1/20260729T180121Z-w3-formal02/`
- Source commit:
  `cd25e85e2f600f24795a6cbb49d368f82ae49d15`
- Kernel commit:
  `621aff8d1bb52fad718f11fd882c956d6a5686ae`

## Judgment

- Run status: valid.
- Tested hypothesis: supported.
- Research value: supporting.
- Paper impact: additional RQ1 evidence for the tested Bazel existing-object
  action-view subset.
- Next paper decision: admit W3 formal02 as reviewed supporting RQ1 evidence.

## Independent Recalculation

All three fresh boots completed from clean source and kernel trees. Each boot
contains exactly:

- 18 passing lifecycle cases;
- 2 passing action-view records;
- 4 passing lower-object records;
- 7 positive policy-counter records;
- 1 passing summary;
- 0 records with `pass=false`.

Across the matrix, all six unmodified Bazel 6.5.0 genrules completed after both
actions reached the common barrier. Direct saved-file comparisons confirmed
that action A and action B read their respective 17-byte inputs through the
same logical pathname. The six action-view records matched each logical
device/inode to the selected registered lower file and observed `ENOENT` for
the undeclared child.

All twelve lower-object records preserved the planned device, inode, mode,
size, and expected bytes. Per boot, the policy recorded 8 target selections,
6 allow-lookups, 2 allow-readdirs, 4 hide-lookups, and 6 hide-readdirs. Lookup
and readdir totals were positive in every boot.

Each boot independently recorded policy detach, both target clears, and both
cgroup removals. External BPF/FUSE inventories were empty before and after the
workload. All boot status files and the declared dmesg failure scan passed.

## Validity And Scope

The correctness evidence is not circular. It uses Bazel exit status, direct
file bytes, syscall errno, device/inode identity, directory enumeration, and
lower-object observations. Policy counters establish mechanism engagement but
do not define success. The analyzer reports observed counts and does not
provide the scientific judgment used here.

No material deviation changed the approved workload, oracle, policy, or
three-boot matrix. The result supports only two concurrent Bazel genrules and
the existing-object action-view subset. It is not evidence for complete Bazel
sandboxing, generic build-system coverage, performance superiority, or the
whole RQ1 by itself.
