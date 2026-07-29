# Kubernetes ConfigMap Publication RQ1 Plan Review

## Scope

An independent read-only reviewer examined:

- `docs/tmp/2026-07-29-kubernetes-configmap-publication-rq1-plan.md`;
- the fixed RQ1 and paper story;
- Kubernetes v1.30.0 `AtomicWriter` source and tests;
- the closed nginx service-rotation, DMTCP, and Spindle protocols; and
- the current directory-target, readdir, and old-fd implementation paths.

The review checked scientific admission, source fidelity, retry lineage,
correctness-oracle equivalence, KVM executability, repetition count,
Make-only ownership, and the prohibition on checksum gates.

## Initial Findings

The initial plan received `NO-GO` for three blocking oracle defects.

### Rollback Object Identity

The initial text required V0 object identities to return after rollback in
both conditions. Kubernetes `AtomicWriter` instead creates a new timestamp
directory and new files when it writes V0 after V1. Only the payload bytes,
modes, and membership return. `namei_ext` reselects the original pre-existing
V0 objects.

The repaired plan now defines payload semantics as the common oracle and
checks object allocation separately for each mechanism. An old descriptor
must remain attached to the original V0 inode in both conditions.

### Payload Namespace

The initial text compared complete directory membership. `AtomicWriter`
contains private timestamp directories and a `..data` symlink, while a direct
generation target does not.

The repaired plan now compares only the user-visible payload namespace,
filters reserved `..*` source objects in the same manner as the upstream test
helper, and preserves the complete source directory inventory as raw evidence.
Symlink topology, `lstat`, `readlink`, and inotify are explicitly out of scope.

### Metadata Preservation

The initial text included timestamps without separating source lifecycle from
pre-existing lower-object preservation. Reads may update atime, and
`AtomicWriter` deliberately deletes retired timestamp generations.

The repaired plan now excludes atime, applies unchanged-object checks only to
the pre-existing `namei_ext` V0/V1 trees, and validates the source-positive
condition against the official creation/deletion lifecycle. Both conditions
use the same fixed consumer UID/GID.

## Non-Blocking Findings

- The experiment is scientifically distinct from the closed nginx protocol:
  it tests official projected-volume publication rather than HUP, worker
  replacement, invalid nginx configuration, or HTTP behavior.
- An adapter that imports and invokes the official v1.30.0 package is a valid
  source-positive control; copying or reimplementing the algorithm is not.
- Three fresh KVM boots are sufficient for this deterministic RQ1
  correctness row.
- No additional baseline is needed.
- The unquantified concurrent-update probe was optional. The repaired plan
  removes it rather than creating a new stress protocol.
- v1.30.0 `TestUpdate` does not execute its second write for the ordinary
  no-update case. The repaired plan correctly assigns repeated no-op identity
  checking to the source adapter.

## Initial Verdict

`NO-GO` pending the three oracle repairs above.

The repaired plan requires one follow-up review before implementation.

## Follow-Up Review

The same reviewer re-read the repaired plan. The follow-up confirmed:

- rollback identity is now separated correctly by mechanism;
- readdir comparison is limited to the common payload namespace;
- preservation applies only to pre-existing V0/V1 objects and excludes
  atime;
- source lifecycle, fixed UID/GID, no-op, old-fd, add/delete, unmanaged
  scope, KVM attach, three fresh boots, Make ownership, and the no-checksum
  rule remain executable; and
- the repair introduced no new scientific or execution blocker.

## Final Verdict

`GO`

## Implementation Review And Plan Revision

An independent implementation review after the initial `GO` found a source
semantic gap that the earlier plan review missed. Kubernetes keeps the
projected-volume root stable while replacing `..data`. A directory descriptor
opened on that root before an update must therefore reach the new payload on a
later relative lookup. The initial implementation instead selected a complete
V0 or V1 directory at the logical root component, which would pin later
`openat()` calls through an old descriptor to the old generation.

The same review found that the initial raw `namei_ext` state record omitted
several actual bytes, modes, nested-directory unexpected counts, and
per-file identities needed to recompute the fixed oracle. It also found that
analysis occurred after result completion, libbpf-style failures lost errno,
and source metadata omitted exact commands.

This is plan revision 1. The revised plan keeps one stable logical root,
selects existing payload files at their leaf components, hides generation-
absent entries during lookup and readdir, and adds a root-directory-descriptor
oracle to both source and `namei_ext` conditions. The correctness oracle and
finalizer now require exact raw file and directory observations rather than
trusting runner verdict fields. Analysis precedes the final result-completion
transition, error recording preserves errno, and source command metadata is
complete.

No real KVM preflight had run when these defects were found, so the fixed
experiment matrix has not changed during execution and the preflight budget
remains unused.

## Implementation Review Verdict

`NO-GO` pending follow-up review of the revised implementation.

## Follow-Up Implementation Review

The same reviewer re-read the revised policy, source adapter, C runner, Make
workflow, raw fields, finalizer, and plan. The follow-up found no blocking
defect and confirmed that all five implementation-review findings were
repaired.

Three non-blocking observations were retained:

- directory-descriptor failures should record their errno for diagnosis;
- the recorded source test command should preserve shell quoting; and
- positive readdir entries use the logical placeholder's dirent inode and
  type, so the claim must remain visible-name membership rather than dirent
  metadata equivalence.

The implementation now records dirfd errno, records a directly replayable
quoted test command, and states the readdir-name scope explicitly.

## Final Implementation Verdict

`GO`

The experiment may enter its first one-boot modified-kernel KVM preflight. No
preflight attempt had been consumed at this point.
