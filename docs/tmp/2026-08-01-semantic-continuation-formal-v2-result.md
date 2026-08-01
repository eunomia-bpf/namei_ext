# Semantic Continuation Formal V2 Result

## Question

This mechanism experiment asks whether a policy-selected existing object can
continue through ordinary VFS operations with the same outcomes as direct use
of the lower object. It isolates the semantic-preservation part of the VFS
acceptance contract. It is not an industrial workload, a performance result,
or a claim of complete POSIX conformance.

## Immutable Result

Result root:

`results/experiments/semantic-continuation/20260801T190000Z-semantic-formal-v2`

The run used clean source commit
`f9aa34b41c4726bcc698aa9f47c20e51d250ff7a` and clean modified-kernel commit
`b07117a3cb41826a34af5ca61e3e2c81dade793f`. Protocol
`namei_ext.semantic_continuation.v2` completed three fresh KVM boots with
alternating direct/selected arm order on ext4 and tmpfs.

## Frozen Matrix

The captured `semantic_continuation_operations.tsv` contains 80 independent
operation rows across S01--S16. Each boot records one direct and one selected
execution of every row. The cases cover creation below a selected directory,
open/read/write, access and permission errors, metadata changes, links,
rename/unlink, same- and cross-filesystem two-path operations, an unmanaged
PASS control, and descriptor-relative continuation after policy teardown.

The selected arm records one per-operation engagement row. The independent TSV
specifies whether that operation must select target A/B/X, must execute PASS,
or must not invoke policy. Only successful file-descriptor numbers are
normalized between arms; byte counts, ordinary returns, errno, and semantic
details must match exactly.

## Raw Evidence

Each boot contains exactly 337 JSONL events:

- 160 operation records;
- 80 selected-operation engagement records;
- 32 case records and 16 selected-case engagement records;
- 32 lower-object residual checks;
- 14 setup/teardown records;
- two S16 identity records; and
- one boot summary.

Across all three boots, 48 direct and 48 selected cases, 240 per-operation
engagement checks, six raw identity checks, and 96 residual checks passed. No
record carrying `pass` is false. Every `boot.json` reports completed with zero
inner, cleanup, and dmesg status; runner and cleanup status files are zero.
Direct dmesg inspection found no project failure signature after excluding
kernel command-line text.

S16 records the actual and expected device/inode values for both arms. In every
boot, the selected sequence is `open-directory`, policy/target/cgroup teardown,
then `openat-create`, write, read, rename, and unlink through the retained
directory descriptor. Every post-teardown operation records zero A/B/X/PASS
counter deltas, so these operations do not re-enter policy.

S15 uses distinct direct and selected physical files. Its selected operation
returns the same 14-byte result as direct access, records one PASS decision,
and records zero target selections.

## Independent Audit

The first bounded reviewer response returned evidence-completeness NO-GO
because the audit was interrupted before its row-by-row reconciliation. It did
not identify a semantic defect. The reviewer resumed with only the unfinished
checks and independently reconciled every captured TSV row in all three boots.

The final review returned **GO** and closed all four formal-v1 defects:

1. S16 preserves raw actual and expected device/inode values.
2. Every operation has exactly one matching direct row, selected row, and
   selected engagement row with the required target/PASS/no-engagement deltas.
3. Direct and selected returns match exactly except for normalized successful
   descriptor numbers.
4. S15 uses disjoint physical fixtures and records a selected PASS decision.

The reviewer also confirmed S16 ordering, zero post-teardown policy deltas,
clean boot/runner/cleanup status, ext4/tmpfs identity, clean captured commits,
and direct dmesg content.

## Admitted Claim

On kernel `b07117a3cb41826a34af5ca61e3e2c81dade793f`, across three fresh KVM
boots and the frozen 80-operation matrix, `namei_ext` selected paths preserve
the direct lower-path operation outcomes and required per-operation
target/PASS/non-engagement behavior. An opened selected directory remains
usable for the tested descriptor-relative create, write, read, rename, and
unlink operations after policy teardown, with zero subsequent policy
engagement.

## Scope

The result is limited to the frozen operation matrix and ext4/tmpfs
configuration. It does not establish complete POSIX conformance, arbitrary
filesystem compatibility, final-component create-through-selection, rare
concurrent target-retirement safety, or a transaction across multiple path
lookups. The separate target-lifetime work owns concurrent retirement; source
workloads establish industrial usefulness.
