# namei_ext Final Existing-File Selection Implementation

## Motivation

The registered-target prototype selected directories, but the declared
`namei_ext` boundary is selection of an existing file or directory during VFS
name resolution. Source-derived workloads such as Spindle require the final
component of an ordinary open to select a prepared regular file. This
increment closes that mechanism gap before any such workload is admitted as
paper evidence.

This work is dependency validation, not an RQ1 case-study result.

## Files Changed

Kernel commit `621aff8d1bb52fad718f11fd882c956d6a5686ae` changes:

- `kernel/fs/namei_ext.c`: admits registered regular files and lookup-capable
  directories, rejects symbolic links and special files, and allows a
  non-directory target for a final open while retaining create rejection.
- `kernel/fs/namei.c`: distinguishes intermediate from final target use,
  carries final regular files through normal VFS completion, preserves scoped
  lookup restrictions, and releases completed symbolic-link state on the
  selected-target path.

Project changes extend:

- `bpf/policies/select_portal.bpf.c` with final file, executable, and pinned
  file target IDs;
- `tests/functional/namei_ext_functional.c` with final-file, permission,
  cross-mount, lifetime, replacement, and fail-closed cases; and
- `bpf/policies/README.md` with the expanded regression-policy role.

The kernel diff is 24 insertions and 20 deletions. It adds no BPF action,
context field, map type, policy language, or new control-plane interface.

## Implemented Contract

- Intermediate selected targets must be directories.
- Final selected targets may be existing regular files or directories.
- A regular file supports final stat, access, `O_PATH`, ordinary open, read,
  and exec through existing VFS and lower-filesystem operations.
- `LOOKUP_DIRECTORY` on a regular file fails with `ENOTDIR`.
- Create-through-select remains unsupported and fails with `EOPNOTSUPP`.
- Symbolic-link targets are rejected with `ELOOP`; FIFOs and other special
  files are rejected with `EOPNOTSUPP`.
- `RESOLVE_NO_XDEV`, `RESOLVE_BENEATH`, and `RESOLVE_IN_ROOT` restrictions
  remain authoritative.

Registration has object-capability semantics. The controller resolves and
registers a referenced target object. Later logical lookup checks traversal on
the logical path and normal permissions on the selected inode and mount; it
does not replay traversal through the target's original physical parents. The
registry pins object identity rather than a live pathname. Rename or unlink
therefore does not revoke or silently retarget the registration. Explicit
replacement or registry clear publishes or revokes an object.

## Review And Repairs

An independent read-only kernel review initially returned `NO-GO`. It found
that special files were not excluded, capability and pinned-object semantics
were unspecified, the cached `O_PATH` case was not distinct, boundary tests
were incomplete, and generic selected-target traversal omitted symbolic-link
stack cleanup.

The implementation and design were repaired to address each item. The same
reviewer then returned `GO` with no remaining P0-P2 correctness, security, or
lifetime finding. The review also confirmed that the tmpfs target was a real
second mount and that the permission, `openat2`, replacement, unlink, and
cleanup tests exercised the intended branches.

## Validation

Host and build validation passed:

```text
make bpf functional kernel-objects
make abi bpf functional policy-load policy-semantic kernel-objects \
  RUN_ID=20260729T-final-file-select-host-v1
```

The kernel patch passed:

```text
git -C kernel diff HEAD^ | kernel/scripts/checkpatch.pl --strict -
```

with 0 errors, 0 warnings, and 0 checks.

A focused modified-kernel KVM preflight passed 117/117 functional cases:

```text
make kvm-functional RUN_ID=20260729T-final-file-select-preflight-v2
```

Raw root:
`results/phase1/20260729T-final-file-select-preflight-v2/`.

The complete Phase 1 suite then passed:

```text
make phase1 RUN_ID=20260729T220000Z-f1e5e1e1
```

The guest ran
`Linux 7.1.0-rc7-g621aff8d1bb5`. Raw results contain:

- 3/3 ABI checks passed;
- 8/8 policy load, attach, and detach events passed;
- 117/117 functional cases passed, including `functional_summary`;
- `CONFIG_NAMEI_EXT=y`; and
- no match for BUG, WARNING, oops, panic, lockup, RCU stall, sanitizer,
  refcount, or use-after-free patterns in smoke, policy-load, or functional
  dmesg.

Raw root:
`results/phase1/20260729T220000Z-f1e5e1e1/`.

The functional cases include real tmpfs cross-mount selection, cached ref-walk
and RCU-walk, final stat/open/read/access/exec, target-mode denial, reachability
through an inaccessible physical parent, scoped `openat2` rejection, file used
as an intermediate component, symbolic-link and FIFO registration rejection,
concurrent target replacement, file-to-directory replacement, pinned read
after physical unlink, explicit registry revocation, detach, and successful
tmpfs unmount.

## Issues Encountered

The first KVM invocation was correctly rejected because the kernel source was
dirty and therefore lacked formal provenance. The kernel change was committed
before retrying. Rebuilding after the cache reset also required the existing
`make kernel-config` target to restore `.config`. Neither attempt produced a
guest result and neither is counted as a mechanism preflight.

An initial complete-suite command used a nonconforming manual run ID. The
infrastructure test rejected it before KVM execution. The successful suite
uses the required timestamp-shaped run ID above.

## Alternatives Rejected

- Directory-only selection plus generated cache basenames would expose
  source-system cache layout rather than implement final existing-file
  selection.
- Copying or renaming targets into a view tree would measure materialization,
  not the proposed action.
- BPF-returned path strings would require an arbitrary second pathname walk.
- Direct file construction in the hook would bypass normal VFS open,
  permission, LSM, and lower-filesystem ownership.

## Remaining Risks And Follow-Up

- Registered symbolic-link and special-file targets remain deliberately out of
  scope.
- Pinned-object revocation is controller-driven, not coupled to rename or
  unlink of the original physical pathname.
- The Phase 1 target registry uses debugfs; this work does not settle an
  upstream registration ABI.
- The next source workload must independently prove source-mechanism
  engagement and its application oracle. These functional results alone do
  not prove the Spindle case.
