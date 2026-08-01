# Plan Review: RQ1 Semantic Continuation

## Round 1: No-Go

The independent reviewer rejected the original selected-cwd `pjdfstest` plan
for three scientific reasons.

1. After `SELECT_TARGET` and `chdir`, the unmodified suite uses relative paths
   from an ordinary ext4 cwd. A full pass would mostly repeat ext4 conformance;
   its mutation and metadata operations would not cross the selection boundary.
2. A zero BPF counter delta after `chdir` follows from the exact-parent scope:
   descendants of the selected cwd are outside that scope. It tests the parent
   filter, not semantic continuation.
3. One static binding without a source-system state transition is supporting
   construction evidence, not a decisive answer to RQ1.

The reviewer accepted direct ext4 as the correct environment control, the
official full-pass criterion, and the executability of the pinned suite, but
also required the policy, scope, cgroup placement, snapshot order, restart
semantics, mount identity, and dmesg predicate to be frozen explicitly.

Final verdict: NO-GO

## Revision 1

The revised plan adopts the higher-value alternative from the review. It no
longer runs the full suite after a selected `chdir` and no longer treats zero
post-binding policy calls as evidence. Instead, every operation pathname in a
paired differential matrix contains the logical selected component, so each
single-path or two-path syscall crosses the `SELECT_TARGET` boundary in the
same VFS walk whose semantics are checked.

The matrix is derived from the standard `pjdfstest` operation families but is
implemented as a focused mechanism test because the unmodified shell suite
cannot prefix every pathname with the logical component. Its role is reduced
from decisive to supporting RQ1 construction evidence. The direct arm is an
expected-outcome control, not a competing baseline. Per-case target-hit deltas
establish engagement, while syscall results, errno, bytes, metadata relations,
directory membership, and lower-object state define correctness independently.

Round 2 will review the revised experiment rather than the rejected
selected-cwd protocol.

## Round 2: Go

The follow-up reviewer examined the revised every-path matrix and the frozen
S01--S16 case table. It found no remaining blocking scientific or executability
defect. The revised design directly couples each selected action to the syscall
whose lower-filesystem result is checked, keeps counters as attribution rather
than correctness, labels the direct arm as a control, and scopes the result to
supporting construction evidence.

Final verdict: GO
