# Semantic Continuation Formal V1 Claim Review

## Result Root

`results/experiments/semantic-continuation/20260801T133000Z-semantic-formal-v1`

The immutable run used clean source commit
`99f0c740a0c9998d5ff76574084fc1523c2f674a` and clean kernel commit
`b07117a3cb41826a34af5ca61e3e2c81dade793f`. Three fresh modified-kernel KVM
boots completed with alternating direct/selected arm order.

## Raw Result

Each boot contains 255 events: 160 operation rows, 32 case summaries, 16
case-level selected engagements, 32 residual checks, 14 lifecycle rows, and one
summary. No row carrying `pass` is false. Across the three boots:

- all 48 direct and 48 selected cases passed;
- all 48 case-level engagement and 96 residual checks passed;
- S04 produced six expected `EACCES` results;
- S13/S14 produced twelve expected `EXDEV` results;
- S15 selected arms recorded no target selection and a positive PASS delta;
- S16 raw ordering is `open-directory < teardown < openat-create` in every boot;
- runner, fixture cleanup, dmesg, and kernel identity checks passed.

## Independent Rejection

An independent claim-to-code-to-raw audit rejected the intended broad result,
despite the completed run lifecycle:

1. S16 compared device/inode identity in the controller but did not preserve the
   actual and expected values in raw output.
2. Target counters bracketed a complete case, so they could not attribute each
   operation with a pathname operand.
3. The arm comparator reduced every return to success/error class, even when a
   byte count or ordinary syscall return should match exactly.
4. S15 direct and selected controls referenced the same unmanaged physical file,
   contrary to the disjoint fixture rule.

The exact v1 claim supported by the audit is limited to passing operation
predicates with normalized outcome equivalence, per-case target engagement,
PASS behavior for S15, post-teardown descriptor operations for S16, residual
emptiness, cleanup, and clean dmesg. It does not satisfy the frozen plan's full
raw-evidence rule and must not be used as the final paper result.

## Forward Fix

Protocol v2 keeps the S01--S16 operation matrix unchanged and adds:

- per-operation target/PASS/no-policy deltas for every selected operation;
- raw actual and expected S16 device/inode identities;
- return-kind-aware comparison that normalizes only successful descriptor
  numbers and compares all other returns exactly;
- independent S15 direct and selected physical files.

A fresh formal-v2 run is required. This document does not reinterpret or modify
formal v1.

## Protocol V2 Pre-Formal Review

An independent reviewer compared the 80-row operation oracle, C mapping,
counter snapshots, S15 cleanup, S16 detach/identity path, return normalization,
and host finalizer. Its first response reported two blockers, but both were
scope-reading errors: `2/6/10` in `engagement_specs` are target bitmasks rather
than row counts, and the two-identity assertion runs once per boot rather than
once per three-boot aggregate. After rechecking the loop and variable use, the
reviewer withdrew both findings, found no oracle/callsite mismatch, and returned
**FORMAL-V2 GO**.
