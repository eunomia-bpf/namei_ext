# Semantic Continuation Pre-KVM Implementation Review

## Scope

An independent read-only reviewer checked the reviewed scientific plan against
the BPF policy, C controller, KVM Make lifecycle, and host finalizer. The review
was deliberately limited to five pre-KVM blocker classes:

1. incorrect logical versus physical lower paths;
2. cgroup attachment, keying, or exact-parent scope mismatch;
3. S16 pipe deadlock or teardown-order failure;
4. fixture or mount cleanup that makes the guest fail;
5. finalizer counts or comparisons that admit a false positive.

## Initial Finding And Recheck

The first response reported one cleanup blocker. It interpreted
`prepare_case_dirs(&fixture->selected)` as creating S01--S16 beneath the
logical placeholder directories, which would leave those placeholders
non-empty during cleanup.

That interpretation did not match the code's execution order:

1. `prepare_arm_roots(&fixture->selected, "selected", ...)` first stores the
   physical ext4/ext4/tmpfs selected roots in `fixture.selected`.
2. `prepare_case_dirs(&fixture->selected)` creates the case directories under
   those physical roots.
3. Only afterward does the controller create logical `a`, `b`, and `x`
   placeholders and overwrite `fixture.selected` with their logical paths.
4. The physical roots remain in `selected_a_lower`, `selected_b_lower`, and
   `selected_x_lower`; cleanup removes their case directories before removing
   the empty logical placeholders.

The reviewer re-read that ordering, withdrew the finding, and found no second
path that creates case directories beneath the placeholders.

## Verdict

No blocker remained in any of the five reviewed classes.

**PRE-KVM GO**

This verdict means the implementation is ready for one real modified-kernel
preflight. It is not evidence that the semantic matrix passes. The preflight
result must still be reviewed from raw observations before any formal run.

## Post-Review Correction

The second launch showed that this review missed a real cgroup ownership and
ordering error. The reviewed controller registered the exact parent in the
experiment child cgroup before any namei_ext policy was attached, and then
planned to attach the program at the cgroup-v2 root. Kernel
`namei_ext_policy_parent_write()` accepts `exact` only when the current cgroup
owns the attached policy. The child therefore failed before any matrix case
ran. The earlier PRE-KVM GO is preserved above as review history, but it was not
a valid approval of that implementation.

The forward fix attaches the program directly to the experiment child cgroup
before registering the exact parent. A new independent review is required
before another KVM attempt. The failed roots and corrected dependency analysis
are recorded in
`2026-08-01-semantic-continuation-preflight-v1-v2.md`.

## Forward-Fix Review

The independent reviewer checked the corrected ownership/order, S16 teardown,
setup-event finalization, and source cleanliness. The first pass found two
additional evidence blockers:

1. direct and selected S16 used different `detail` strings, so the formal arm
   comparison would reject a correct result;
2. the finalizer counted the S16 teardown event but did not prove it occurred
   after `open-directory` and before the first descriptor-relative operation.

The controller now applies the same object-identity oracle and detail to both
S16 arms. The per-boot finalizer compares raw event positions and requires
`open-directory < teardown-policy-before-dirfd < openat-create`. Analyzer
outputs are directed outside the source tree. The reviewer rechecked these
fixes, found no remaining issue in the reviewed scope, and returned:

**PRE-KVM V3 GO**

## V3 Result Review Status

V3 completed the guest matrix with every semantic, engagement, residual,
cleanup, and dmesg oracle passing, but the result root failed in the host
finalizer. Its two filesystem checks searched for `FSTYPE ext4` and
`FSTYPE tmpfs`; the `findmnt` data rows place filesystem type in the third
column after target and source. The validator now checks that exact column.
The immutable failed root and its evidence boundary are recorded in
`2026-08-01-semantic-continuation-preflight-v3.md`. A separate review must decide
formal-run readiness; the earlier GO does not authorize a formal run by itself.

The independent raw-result review confirmed that V3 contains no failed guest
oracle and that the first ext4 grep is the exact host-finalize failure. It also
validated the corrected third-column predicates against both captured tables.
Because another preflight would only repeat this deterministic host parser after
three bounded attempts, the review returned:

**FORMAL GO**
