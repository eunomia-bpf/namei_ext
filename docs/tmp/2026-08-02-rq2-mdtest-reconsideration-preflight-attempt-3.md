# RQ2 mdtest Reconsideration Preflight Attempt 3

## Purpose

This record preserves the third and final real KVM preflight allowed by the
2026-08-02 reconsideration plan. The immutable result root is:

```text
results/experiments/mdtest-cold-metadata-rq2-preflight/20260802T090648Z-mdtest-reconsideration-preflight03/
```

## Outcome

The stock, patched-unattached, attached `PASS`, and attached `SELECT`
conditions each completed one KVM boot and all six declared mdtest cells. They
produced 24/24 passing observations across file create, cold stat, and cold
remove at one and four MPI ranks. Each boot also passed independent vCPU
affinity read-back.

The official FUSE condition failed before the FUSE daemon mounted and before
mdtest executed. Its launcher status is 2. The single failure observation is a
controller placeholder with no FUSE engagement or performance measurement.
The five-condition matrix is incomplete, so this root supplies no RQ2 result
or paper number.

## Root Cause

The attempt-2 repair assumed that the guest FUSE process already had a hard
open-file limit at least as large as the requested 262,144 soft limit. Linux
initializes `RLIMIT_NOFILE` to `INR_OPEN_CUR=1024` and
`INR_OPEN_MAX=4096`, as defined in `include/uapi/linux/fs.h` and used by
`include/asm-generic/resource.h`. In the guest, `start_fuse()` rejected the
4,096 hard limit before redirecting the daemon's stdout and stderr and exited
with status 126. The parent subsequently exhausted the 30-second mount wait.

This diagnosis is supported by the absence of daemon logs and a FUSE mount,
the zeroed FUSE engagement fields in the failure observation, the exact child
branch in `start_fuse()`, and the kernel's initial rlimit constants. It is not a
FUSE-versus-`namei_ext` workload result.

## Protocol Decision

```text
run status: failed and incomplete
paper evidence: none
preflight budget: all three attempts consumed
formal run: not authorized
next action: close this mdtest protocol and complete required W5 DMTCP and W6
  Spindle RQ1 workloads
```

The result root remains unchanged. There will be no fourth preflight under this
protocol. A future mdtest experiment would require a new scientific plan and a
fresh implementation preflight; it cannot reuse or repair this root.
