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
