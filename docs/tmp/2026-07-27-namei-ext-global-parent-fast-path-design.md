# namei_ext global parent fast-path design

## Motivation

The exact-parent dispatch implementation reduced FxMark policy execution from
about ten BPF runs per operation to one, but did not close the active-path
throughput gap. The attached `EXACT(empty)` ablation then executed the BPF
program zero times while reaching only 1.251M operations/s, close to PASS at
1.222M and far below patched-unattached at 2.424M. The preserved runs are:

```text
results/experiments/fxmark-rq2-preflight/20260727T-exact-empty-run-count-v2
results/experiments/fxmark-rq2-preflight/20260727T-exact-empty-preflight-v1
```

The remaining dominant cost occurs before BPF execution. Every pathname
component enters cgroup dispatch, resolves the current cgroup and effective
attachment owner, and scans the owner scope even when no policy parent can
match.

## Goal

Reject pathname parents that cannot match any exact namei_ext scope before
cgroup or BPF work, while preserving the existing cgroup owner and scope check
as the authoritative policy decision.

The fast path may return false positives, which only retain existing dispatch
cost. It must not return a false negative after an acknowledged scope or
attachment update, because that would skip an applicable policy.

## Design

### Global exact-parent registry

Each immutable exact scope set embeds one hash node per registered
`struct path`. The nodes are inserted into a global RCU hash keyed by mount and
dentry identity. The scope set already owns path references, so the registry
does not create a second path-lifetime model.

An exact-entry counter avoids entering the RCU hash when no exact parent is
registered. An exact scope remains indexed while its cgroup is detached. This
can produce a conservative false positive at an old registered parent, but it
avoids reusing an RCU-removed hash node across rapid detach and reattach.
Scope replacement, `global`, and cgroup release remove the old nodes and retain
the scope allocation until an RCU grace period completes.

Component lookup, final-component open lookup, and directory iteration evaluate
the filter before entering their namei_ext slow wrappers:

```text
any active global owner || exact-parent hash contains this struct path
```

If false, normal VFS behavior continues without allocating the redirect or BPF
contexts and without discovering the current cgroup. If true, the existing
effective-owner, owner-scope, and BPF-array checks still run. The registry
therefore cannot authorize a policy for another cgroup.

### Global scopes

A null scope set means `GLOBAL`, so it cannot be represented by exact hash
entries. A counter tracks cgroups that both directly own a live namei_ext
attachment and currently use global scope. When nonzero, the fast path
conservatively sends every parent through existing dispatch.

Inherited descendants do not increment the counter. The direct attachment
owner contributes once regardless of the number of descendants using its
program.

### Publication order

The existing scope mutex serializes lifecycle changes. A short raw-spinlock
section and an associated sequence counter publish the counters, hash entries,
and authoritative scope pointer atomically to RCU-walk readers. A reader that
overlaps an update retries against the completed state without acquiring a
sleeping lock, including on PREEMPT_RT. Transitions use these orders:

| Transition | Required order |
| --- | --- |
| global to exact | add new exact nodes, publish exact scope, decrement active-global count |
| exact to global | increment active-global count, publish global scope, remove old exact nodes |
| exact to exact/empty | add new nodes, publish new scope, remove old nodes |
| direct attach in global mode | increment active-global count, then publish the direct owner |
| direct detach from global mode | publish the replacement/null owner, then decrement active-global count |
| cgroup release | remove active-global contribution or exact nodes, publish the tombstone, wait for RCU, free old scope |

Readers that overlap an update retry if the sequence changes. Readers starting
after the update returns find either the active-global count or the new exact
node. Counter overflow or invariant failure saturates to a conservative
nonzero value instead of enabling the zero-entry shortcut.

## Ownership and lifetime

- The scope mutex owns registry mutation and the direct-active state.
- The raw spinlock protects only counter, hash, pointer, and sequence
  publication; allocation, path reference changes, and RCU waits occur outside
  it.
- RCU readers own no path references.
- Scope sets retain mount and dentry references while indexed.
- `synchronize_rcu()` precedes path release and scope free.
- Rename preserves object-identity scope because the registered dentry and
  mount remain the key.
- Replacement at the same pathname creates a different object and is not
  implicitly added to the old scope.
- Lazy unmount and cgroup teardown retain the existing path-reference and
  fail-closed behavior.

## Alternatives

### Lookup-lifetime cgroup/scope snapshot

Caching owner state in `nameidata` could avoid repeated cgroup discovery, but
it adds namei-specific state to every path walk, must survive symlink and
mount transitions, and risks increasing the unattached path footprint. It
remains a fallback if the registry still leaves excessive matching-parent
cost.

### Dentry marker

A dentry bit is cheaper to test but cannot represent mount identity or safely
clear duplicate registrations without new per-dentry reference state. Adding
that state to every dentry is broader and less suitable for a cgroup-specific
optional hook.

## Validation plan

1. Compile all touched kernel objects with the committed Phase 1 config.
2. Extend functional KVM coverage for exact, add, empty, global, inherited
   owner, detach, reattach, lookup, and readdir transitions.
3. Run complete Phase 1 and policy-semantic KVM validation.
4. Run the six-condition FxMark attribution preflight with BPF statistics:
   `empty` must remain at zero policy runs and PASS/SELECT near one run/work.
5. Run the same preflight with statistics disabled. The implementation is
   promising only if `empty` moves materially toward patched-unattached and
   PASS/SELECT improve relative to the prior exact-parent kernel.
6. Do not run the full RQ2 matrix until the short preflight justifies its cost.

## Validation result

Kernel commit `8fd1fb52fa8d91519424285ec9d24b26314c2cfc` passed:

- `make phase1
  RUN_ID=20260727T-parent-fast-path-8fd1fb52f-phase1`;
- `make kvm-policy-semantic
  RUN_ID=20260727T-parent-fast-path-8fd1fb52f-semantic`;
- a six-boot normal FxMark preflight in
  `results/experiments/fxmark-rq2-preflight/20260727T-parent-fast-path-8fd1fb52f-normal/`;
- the matching BPF-statistics preflight in
  `results/experiments/fxmark-rq2-preflight/20260727T-parent-fast-path-8fd1fb52f-stats/`.

The normal single-cell preflight measured 2.356M operations/s unattached,
2.403M `empty`, 2.166M PASS, 1.698M SELECT, and 1.938M for the optimized
cache-hot FUSE comparison. The prior exact-empty run measured only 1.251M
operations/s. The statistics run retained zero BPF invocations for `empty` and
about one invocation per operation for PASS and SELECT; the BPF body remained
about 25 ns per invocation.

This is directional preflight evidence, not a replacement for the repeated
full RQ2 matrix. It is sufficient to retain the mechanism and proceed to the
next formal run.

## Remaining risks

- RCU hash lookup may still be too expensive for a one-component metadata
  operation.
- Any active global policy disables the negative-parent optimization system
  wide; production use therefore needs exact scope registration as part of
  attachment setup.
- Detached exact scopes remain conservative hash entries until replaced or
  their cgroup is released.
- The generic cgroup detach OOM purge path predates this change and still
  needs dedicated fault-injection coverage for namei_ext owner and dummy
  program behavior.
- The current debugfs setup interface is prototype control plumbing, not a
  proposed stable ABI.
