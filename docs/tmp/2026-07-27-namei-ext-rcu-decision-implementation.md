# namei_ext RCU Decision Implementation

## Motivation

The first fast-path repair restored stock-shaped code when no namei_ext
program is attached, but an attached program still forced every pathname
component out of RCU walk before making even a `PASS` decision. A two-second
KVM FxMark diagnostic reported approximately 0.97 million operations per
second for both `PASS` and `SELECT`, compared with 2.03 million for the
cache-hot FUSE baseline. The next implementation step therefore separates
policy decision from actions that require refcounted VFS objects.

## Code Paths Inspected

- `fs/namei.c`: `try_to_unlazy()`, component walk, final-open lookup,
  redirected-name hashing, and selected-target application;
- `fs/namei_ext.c`: BPF context construction, action decoding, target
  registry lookup, and directory iteration;
- `include/linux/namei_ext.h`: internal action state; and
- existing VFS `d_hash`, `LOOKUP_CACHED`, `LOOKUP_RCU`, and
  `LOOKUP_IS_SCOPED` contracts.

## Design

The BPF decision now runs before leaving RCU walk. The BPF-visible flags mask
the internal `LOOKUP_RCU` bit so an identical lookup does not expose a
different policy ABI depending on the VFS walk mode.

Action handling is explicit:

- `PASS` continues through ordinary RCU lookup;
- `SELECT_TARGET` records only the target and cgroup IDs, transitions to
  ref-walk with `try_to_unlazy()`, then acquires the registered path;
- `REDIRECT` transitions to ref-walk before changing `nd->last`, and invokes
  the lower filesystem's `d_hash` operation for the replacement name;
- `HIDE`, policy errors, and invalid actions transition to ref-walk before
  returning a terminal result; and
- any failed `try_to_unlazy()` returns `-ECHILD` immediately without touching
  `nameidata`.

The parent inode is supplied as `nd->inode` during RCU walk instead of being
reloaded from the dentry. Directory iteration supplies `file_inode(file)`.
The VFS and lower filesystem continue to own dentries, inodes, path
validation, lookup, permissions, open, I/O, and persistence.

## Alternatives Rejected

- Running target-registry lookup under RCU walk was rejected because the
  current prototype registry uses a mutex and transfers a refcounted path.
- Returning a policy error directly from RCU walk was rejected because it
  could bypass the validation and `RESOLVE_CACHED` behavior enforced by
  `try_to_unlazy()`.
- Retrying the BPF program after an RCU fallback was rejected because programs
  may update maps or emit events; replay would change observable behavior.
- Invoking policy only on dcache miss was rejected because it changes
  per-lookup policy visibility.

## Validation

The patched kernel completed a full build and the real KVM attach path passed
after final review and repair under
`results/phase1/20260727T-rcu-decision-final`:

- 3/3 ABI cases;
- 8/8 policy-load cases;
- 49/49 functional cases;
- 76/76 policy-semantic cases plus the passing suite summary; and
- no declared BUG, warning, oops, panic, or protection-fault signature.

Both enabled-config kernel objects and an independent `allnoconfig`
`fs/namei.o` build pass. The latter covers the `CONFIG_NAMEI_EXT=n` internal
stubs that the Phase 1 kernel does not compile.

A directional one-worker `MRPL` preflight before the final safety fixes
reported:

| Condition | Operations/s |
| --- | ---: |
| stock | 2,426,111 |
| patched, unattached | 2,454,905 |
| attached `PASS` | 1,245,372 |
| attached `SELECT` | 1,099,297 |
| cache-hot FUSE | 1,853,665 |

This improved the active path but did not satisfy the predeclared RQ2
hypothesis. The result is diagnostic, not paper evidence.

## Remaining Risks And Follow-Up

- The current attachment still dispatches BPF for every normal pathname
  component, even when only one policy parent is managed.
- The BPF program type permits map updates and event output during RCU walk;
  upstream discussion must make this execution context explicit.

The final review found and corrected one blocker: VFS `d_hash` callers treat
only negative returns as errors, while the initial redirect implementation
treated every nonzero return as an error. Both redirected component and
final-open paths now use the VFS `< 0` convention. The review found no other
blocking RCU, refcount, qstr-lifetime, `RESOLVE_CACHED`, SELECT, or readdir
issue.
