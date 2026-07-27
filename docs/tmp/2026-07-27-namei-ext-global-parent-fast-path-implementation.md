# namei_ext global parent fast-path implementation

## Motivation

The exact-empty FxMark ablation executed the policy zero times but reached only
1.251M operations/s versus 2.424M for patched-unattached. This localized the
dominant active cost before BPF execution: every pathname component still
entered the namei_ext slow wrapper, constructed contexts, discovered the
current cgroup, and checked its effective owner and scope.

## Implementation

Kernel commit `8fd1fb52fa8d91519424285ec9d24b26314c2cfc` adds a conservative
global parent filter.

- `fs/namei_ext.c` embeds RCU hash nodes in immutable exact-scope sets and
  maintains exact-entry and active-global counters.
- `fs/namei.c` tests the filter before entering the noinline component and
  final-open namei_ext wrappers.
- `fs/readdir.c` tests the same filter before constructing the directory
  mediation context.
- `kernel/bpf/cgroup.c` publishes whether a direct attachment contributes a
  global-scope user.
- `include/linux/namei_ext.h` exposes only the internal VFS filter and cgroup
  lifecycle hooks.
- `include/linux/bpf-cgroup-defs.h` stores the direct-owner active state.

The filter is not an authorization decision. A positive result still executes
the existing effective-owner, per-owner scope, and BPF-array checks. False
positives retain extra work; a stable false negative is forbidden.

## Concurrency and failure behavior

The scope mutex serializes lifecycle updates. A raw spinlock and
`seqcount_raw_spinlock_t` cover only counter, hash, scope-pointer, and active
state publication, so RCU pathname walk never acquires a sleeping lock on
PREEMPT_RT. Readers retry an overlapping update while retaining RCU protection
for removed nodes. Scope allocations and path references are freed only after
an RCU grace period.

Counter overflow or underflow saturates to `UINT_MAX`, keeping dispatch
conservative instead of enabling the zero-entry shortcut. Debugfs scope updates
take `cgroup_mutex` before the scope mutex and revalidate direct ownership
under that lock, closing the detach/update race.

Current namei_ext attachment semantics admit one effective policy: attach flags
including `BPF_F_ALLOW_MULTI` are rejected and cgroup BPF links are unsupported.
The global registry therefore complements the existing single-owner scope
model; it does not add a multi-program scope model.

## Alternatives rejected

A `nameidata` snapshot would add state and update semantics to every path walk.
A dentry marker would consume global VFS state and cannot represent
mount-plus-dentry identity. Keeping the filter inside `namei_ext_lookup()` was
also rejected after object inspection showed that the noinline wrapper and
large context stack frame were entered before the test.

## Validation

The committed kernel passed strict checkpatch, touched-object compilation, a
complete kernel build, Phase 1 KVM policy load and functional validation, and
the source-derived policy semantic suite:

```text
results/phase1/20260727T-parent-fast-path-8fd1fb52f-phase1/
results/phase1/20260727T-parent-fast-path-8fd1fb52f-semantic/
```

All functional and semantic cases passed. The captured dmesg files contain no
BUG, warning, Oops, KASAN, lockdep, atomic-sleep, or counter-underflow evidence.

The committed normal preflight produced:

| Condition | Operations/s | Relative to unattached |
| --- | ---: | ---: |
| stock | 2.463M | 1.045x |
| patched-unattached | 2.356M | 1.000x |
| exact-empty | 2.403M | 1.020x |
| PASS | 2.166M | 0.919x |
| SELECT | 1.698M | 0.721x |
| optimized cache-hot FUSE | 1.938M | 0.823x |

Raw evidence:

```text
results/experiments/fxmark-rq2-preflight/20260727T-parent-fast-path-8fd1fb52f-normal/
results/experiments/fxmark-rq2-preflight/20260727T-parent-fast-path-8fd1fb52f-stats/
```

The statistics run recorded zero policy invocations for exact-empty and about
one per operation for PASS and SELECT, at about 25 ns per BPF invocation.

## Review disposition and follow-up

An independent correctness review identified and this increment fixed the
PREEMPT_RT seqcount issue, fail-open counter handling, and scope-update
ownership race. Its multi-program concern does not apply to the enforced
single-attachment ABI. Two broader lifecycle items remain separate follow-up
work: fault injection for generic cgroup OOM purge, and stress coverage for
duplicate exact paths, inherited exact scope, detach/reattach, cgroup teardown,
rename, mount identity, and concurrent scope transitions.

The next full RQ2 matrix must use committed kernel provenance and retain the
same stock, unattached, exact-empty, PASS, SELECT, and feature-equivalent FUSE
interpretation. The preflight is not itself a paper-level confidence interval.
