# namei_ext Exact-Parent Policy Dispatch

## Motivation

FxMark invocation attribution showed that one managed lookup caused about ten
namei_ext program invocations because the program ran for every component of
the absolute pathname. The BPF body itself took about 24 ns per invocation, so
optimizing policy instructions could not remove most of the remaining active
path cost.

This implementation adds an exact-parent dispatch filter. It controls where an
attached policy is invoked; it does not add a pathname policy language, cache
policy decisions, or change the existing BPF actions. The workload, policy
programs, FUSE baseline, metrics, and predeclared RQ2 matrix remain unchanged.

## Design

Each cgroup BPF state can hold an immutable RCU-published set of up to eight
registered directory paths:

- `GLOBAL` is represented by a null scope set and invokes the policy for every
  eligible parent;
- `EXACT(empty)` is represented by a non-null empty set and invokes it for no
  parent; and
- `EXACT(paths)` invokes it only when the current lookup or directory
  enumeration parent is the same VFS path as a registered directory.

Matching uses `path_equal()`, so it follows the registered directory object
across rename and distinguishes different mounts of the same inode. Registered
paths hold normal VFS path references until the immutable set is replaced or
the owning cgroup is released. Prefix, recursive, glob, and string matching are
intentionally excluded.

The scope belongs to the cgroup that owns the effective namei_ext attachment.
Descendant cgroups use that owner's scope while the BPF context continues to
report the executing cgroup ID. This prevents a descendant from installing an
empty local scope to bypass an inherited ancestor policy.

Lookup obtains the effective attachment owner and scope under RCU before
running the existing effective program array. Directory enumeration takes one
scope decision at iterator entry and pins both the cgroup and its live cgroup
BPF state until iteration ends. Cgroup release first publishes a static
`EXACT(empty)` tombstone, waits for RCU readers, and then drops path references.
This prevents release from temporarily turning a dying scope into `GLOBAL`.

The prototype control surface is:

```text
/sys/kernel/debug/namei_ext/policy_parent

exact <directory-fd>
add <directory-fd>
clear
global
```

`exact`, `add`, and `clear` require the writer's current cgroup to own the
effective local namei_ext attachment. Scope and target writers pin live cgroup
BPF state while publishing updates so concurrent cgroup release cannot clear
state and then allow it to be republished.

## Files Changed

Kernel:

- `kernel/include/linux/bpf-cgroup-defs.h`: scope and effective-owner state;
- `kernel/include/linux/bpf-cgroup.h`: effective-owner maintenance and
  namei_ext cgroup lifetime helpers;
- `kernel/include/linux/namei_ext.h`: dispatch and control declarations;
- `kernel/kernel/bpf/cgroup.c`: attachment-owner publication and cgroup
  teardown; and
- `kernel/fs/namei_ext.c`: exact-parent scope storage, matching, debugfs
  control, lookup dispatch, and directory-iteration lifetime handling.

User space and tests:

- `runner/include/namei_ext_harness.h` and
  `runner/src/namei_ext_harness.c`: cgroup-scoped policy-parent operations;
- `bench/fxmark/fxmark_cell.c`: register the managed work root after attaching
  the policy and restore `GLOBAL` before detach; and
- `tests/functional/namei_ext_functional.c`: inherited-policy, exact, add,
  clear, global, lookup, and directory-enumeration tests.

## Alternatives Rejected

- Matching the executing leaf cgroup's scope would let a descendant suppress
  an inherited ancestor policy.
- Publishing `GLOBAL` during cgroup teardown would widen policy execution while
  references were being released.
- Matching path strings, prefixes, or globs would introduce a second policy
  language and pathname parsing in the dispatch layer.
- Caching BPF decisions would require a separate invalidation and coherency
  contract and would change the promised per-lookup semantics.
- Invoking only on dcache miss would make policy state changes invisible on
  cache hits.

## Validation

The following repository entrypoints completed successfully:

- `make kernel-objects`;
- `make functional`;
- `make fxmark-rq2-build`;
- `make kernel`;
- `make phase1 RUN_ID=20260727T-policy-parent-v1`; and
- `make kvm-policy-semantic RUN_ID=20260727T-policy-parent-v1`.

The preserved Phase 1 result root is:

`results/phase1/20260727T-policy-parent-v1`

It contains 163 JSONL records and zero declared failures: 3 ABI records, 8
policy-load records, 67 functional cases, and 76 policy-semantic cases plus
their lifecycle and summary records. The functional cases include rejected
descendant scope clearing, inherited-policy enforcement, exact-root and added
parent matching, `EXACT(empty)`, `GLOBAL`, lookup visibility, and readdir
visibility. Captured dmesg logs contain no declared kernel failure signature.
Both the parent and kernel diffs pass `git diff --check`.

## Remaining Work And Risks

The implementation is functionally validated but has not yet passed the
unchanged FxMark performance preflight. The next run must first enable BPF
statistics to verify that policy invocations fall from about ten per work unit
to about one, then rerun the normal statistics-off five-condition preflight.
The full 450-cell RQ2 matrix remains gated on that result.

The debugfs commands are a prototype control surface, not a proposed upstream
ABI. Scope state is cgroup-owned and therefore survives detach and reattach in
the same live cgroup unless the manager writes `global`; the committed FxMark
lifecycle performs that cleanup explicitly. Upstream discussion must decide
whether final scope registration belongs to attachment creation, a BPF link,
or another lifetime-bound interface.
