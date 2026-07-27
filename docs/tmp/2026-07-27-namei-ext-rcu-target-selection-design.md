# namei_ext RCU Target Selection Design

## Motivation

The committed-tree FxMark preflight
`20260727T-rq2-post-parent-fastpath-v2` passed all correctness, provenance,
mechanism-engagement, and dmesg gates, but one-worker cache-hot `MRPL` measured
about 1.62 million operations/s for `SELECT` and 2.00 million operations/s for
the optimized FUSE comparison. `PASS` reached about 2.17 million operations/s.

The approved RQ2 hypothesis and matrix remain unchanged. The difference between
`PASS` and `SELECT` identifies the selected-target path as the next mechanism
boundary to repair before spending the complete-matrix budget.

## Code Paths Inspected

- `kernel/fs/namei_ext.c`
  - target registration, lookup, replacement, and clear;
  - `namei_ext_lookup()` and `namei_ext_resolve_target()`.
- `kernel/fs/namei.c`
  - component and final-component namei_ext wrappers;
  - RCU-to-ref-walk conversion;
  - `namei_ext_apply_target()`.
- `kernel/kernel/bpf/cgroup.c`
  - cgroup owner and BPF dispatch.
- `bench/fxmark/fxmark_cell.c`
  - target setup and selected-directory correctness oracle.

## Finding

Every successful `SELECT` currently:

1. exits the BPF decision with a target ID;
2. converts the pathname walk from RCU walk to ref-walk;
3. takes the global target-table mutex;
4. searches the target hash;
5. increments target path references;
6. releases the old path references and installs the target.

Target registration, replacement, and clearing are control-plane operations.
Serializing every lookup with their mutex is unnecessary. More importantly,
the registered target already owns mount and dentry references, but the current
implementation cannot borrow those references during RCU walk.

## Stage 1: RCU Target Registry

Keep mutation under the existing target mutex, but publish new hash entries
with `hash_add_rcu()`, replace an existing key with `hlist_replace_rcu()`, and
remove entries with `hash_del_rcu()`. Readers search under RCU, take their own
path references before leaving the read-side critical section, and never
acquire the update mutex. Atomic replacement ensures that a reader sees either
the old or new target rather than a transient missing entry.

Replacement and clear remove entries, wait for one RCU grace period, and only
then release path references and free target records. A lookup overlapping an
update may observe either the old or new registered target; an update that has
returned guarantees that no later lookup can borrow the removed record.

This stage preserves current ref-walk application semantics. A short FxMark
preflight isolates how much of the `SELECT` gap came from the mutex.

## Stage 2: Borrowed Target During RCU Walk

If Stage 1 is insufficient, an RCU pathname walk can borrow the selected
target's path without incrementing references:

- the target record's existing path references keep the mount and dentry live;
- removal waits for all pre-existing RCU readers before dropping those
  references;
- namei's outer RCU read-side section spans the remaining pathname walk;
- the target dentry sequence is sampled when the jump occurs;
- ordinary `complete_walk()` legitimizes the final path before returning it to
  userspace.

Ref-walk callers continue taking independent path references. The redirect
state must distinguish borrowed and owned targets so error paths never
`path_put()` an RCU-borrowed path.

The RCU jump must retain the existing restrictions for scoped lookup,
`LOOKUP_NO_XDEV`, non-directory targets, create/open behavior, target removal,
and fail-closed lookup. It must also preserve normal `-ECHILD` restart behavior
when sequence validation fails.

## Alternatives Rejected

### Decision caching

Caching BPF results could match stable FUSE metadata caching, but arbitrary BPF
map updates do not identify which pathname decisions became stale. It adds a
new invalidation ABI and is not required for the target-lifetime repair.

### Invoke policy only on dcache miss

This changes the promised per-lookup policy semantics and can make a policy
update invisible indefinitely.

### Weaken the FUSE baseline

The optimized FUSE view is the strongest matched stable-view competitor in the
approved plan. Its configuration remains fixed.

## Validation Plan

Each stage must pass:

1. strict checkpatch on the kernel diff;
2. touched-object and full kernel builds;
3. ABI, BPF, policy-load, functional, and policy-semantic validation;
4. modified-kernel KVM tests covering target replace, clear, invalid target,
   selected directory, permissions, lookup, open/stat/access/exec, and readdir;
5. dmesg failure scanning; and
6. the unchanged six-condition FxMark preflight.

Only a fresh repeated full RQ2 matrix can change the paper result. These short
stage preflights are internal mechanism diagnostics.
