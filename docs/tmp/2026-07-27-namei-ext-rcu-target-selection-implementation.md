# namei_ext RCU Target Selection Implementation

## Motivation

The RQ2 FxMark preflight showed that removing the target-table mutex improved
one-worker cache-hot `SELECT` throughput by about 5.9%, but `SELECT` remained
below the feature-equivalent optimized FUSE baseline. Profiling the mechanism
showed that each selected target still forced the VFS pathname walk from
RCU-walk into ref-walk and acquired mount and dentry references.

This implementation keeps the approved workload, baseline, metrics, and
hypothesis fixed. It changes only the selected-target mechanism before the same
preflight and complete RQ2 matrix are repeated.

## Files Changed

- `kernel/fs/namei_ext.c`
  - factors RCU target lookup from the ref-acquiring lookup path;
  - borrows a registered target while the caller remains in RCU-walk;
  - retains the existing reference acquisition for ref-walk callers.
- `kernel/include/linux/namei_ext.h`
  - records whether a resolved target is borrowed or independently owned;
  - passes the path-walk mode to target resolution.
- `kernel/fs/namei.c`
  - installs a borrowed target without releasing the previous RCU path;
  - samples the selected dentry sequence for later validation;
  - preserves normal `try_to_unlazy()` and `complete_walk()` validation;
  - avoids releasing borrowed target references on all error paths.
- `tests/functional/namei_ext_functional.c`
  - forces intermediate and final selected-target RCU walks with
    `openat2(RESOLVE_CACHED)`;
  - repeatedly replaces one target ID while another process reads through the
    selected path and requires every read to observe one complete version.

## Lifetime And Ownership

The target registry owns one mount and dentry reference for every registered
path. Replacement and clear remove or replace the hash entry, wait for an RCU
grace period, and only then release those references and free the old record.

An RCU-walk reader therefore borrows the registered path without incrementing
its references. The outer namei RCU read-side critical section protects the
borrowed record and path until the pathname walk either terminates or obtains
independent references through `try_to_unlazy()` or `complete_walk()`.
Ref-walk readers continue to acquire their own path references.

When the selected path is installed, namei samples the selected dentry's
sequence and retains the pathname walk's mount sequence. Existing namei
legitimization checks reject or restart a walk if either object changed.
Scoped lookup, cross-mount restrictions, create/open restrictions, and
fail-closed missing-target behavior are unchanged.

## Review

An independent maintainer-style review found no reachable P0-P2 correctness
issue in the RCU borrowing diff. It checked replacement and clear lifetime,
component and final lookup, `nd->path`, dentry and mount sequence state,
RCU-to-ref-walk conversion, and borrowed-versus-owned error cleanup.

The review required explicit tests proving that the RCU path executes rather
than silently falling back. The implementation therefore added two
`RESOLVE_CACHED` cases and a concurrent atomic replacement case before
performance measurement.

## Validation

Strict checkpatch reported zero errors, warnings, and checks over the kernel
diff. Touched kernel objects and the complete `bzImage` built successfully.

Modified-kernel KVM validation is recorded under
`results/phase1/20260727T-rcu-borrowed-target-stage2-phase1-v1/`:

- ABI: 3 passed, 0 failed;
- policy load and detach: 8 passed, 0 failed;
- functional: 74 passed, 0 failed;
- policy-semantic operations: 76 passed, 0 failed;
- all captured dmesg logs passed the failure-pattern scan.

The functional result includes successful `RESOLVE_CACHED` selection both as a
final directory and as an intermediate component. It also includes 128 target
replacements concurrent with continuous reads; every read observed either the
complete original payload or the complete replacement payload.

## Remaining Work

The mechanism must be committed before a clean-source six-condition FxMark
preflight can measure its performance. If that gate passes, the unchanged
450-cell RQ2 matrix is the paper-level result.

Additional robustness work remains separate from the performance experiment:
replace/clear/register churn, cross-mount selection under mount changes, and
race-detector runs with lockdep, PROVE_RCU, KASAN, and optionally KCSAN.
