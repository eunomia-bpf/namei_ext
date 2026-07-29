# Spindle HPC Staging KVM Preflight Attempt 1

## Purpose And Result

This record covers the first real modified-kernel KVM preflight of the
Spindle HPC staging case study. The attempt tested the packaged guest path and
evidence protocol before admission of any formal result.

The attempt is invalid as a workload result. The guest booted the intended
kernel and completed preparation, but the inner target stopped at its first
runtime-tree integrity check because a repository-relative manifest path was
resolved after changing the working directory. No Spindle source condition,
`namei_ext` policy, or withdrawn-target condition executed.

## Frozen Identity

- result root:
  `results/experiments/spindle-staging-preflight/20260729T142246Z-spindle01/`
- source commit:
  `88f8b2538f3b2099ac5ce725e241ca97d5d7aeb3`
- source tree: clean
- kernel commit:
  `621aff8d1bb52fad718f11fd882c956d6a5686ae`
- kernel tree: clean
- kernel release: `7.1.0-rc7-g621aff8d1bb5`
- Spindle commit:
  `8853636d2d774729a5a728f5cf6c296b65a1099c`
- repetitions requested: one

## Failure

The sealed guest Makefile stores repository paths relative to the repository
root, as required by the shared guest contract. The inner recipe ran:

```text
(cd <runtime-worktree> &&
    sha256sum -c results/.../runtime-inputs.sha256)
```

After the directory change, `sha256sum` interpreted the manifest path relative
to `<runtime-worktree>`, where it does not exist. The exact guest diagnostic
was:

```text
sha256sum: results/experiments/spindle-staging-preflight/\
20260729T142246Z-spindle01/boots/repetition-01/\
runtime-inputs.sha256: No such file or directory
```

This is a packaging-path defect, not evidence for or against the hypothesis,
the source workload, the BPF policy, or the kernel mechanism.

## Structured Status

`boot.json` records:

```text
status             failed
prepare_status     0
inner_status       2
cleanup_status     0
inventory_status   0
dmesg_status       0
```

The runtime bind mount had not been created. The cleanup target returned zero
without taking its conditional unmount branch. The independent after-inventory
found no remaining BPF attachment or FUSE state, and the post-cleanup mount
probe confirmed that the compile-time runtime path was not mounted. The
preserved dmesg contains no `namei_ext`, BPF, warning, oops, or panic failure
attributable to the attempt.

The host captured `boot.json` after the launcher exited and sealed the complete
boot directory. `sha256sum -c evidence.sha256` passes. The failure therefore
also validates that the outer guest target and host evidence wrapper preserve
an early inner-target failure instead of converting it to partial success.

## Fix

The guest configuration remains repository-relative. The owning Makefile now
constructs one absolute manifest helper from `ROOT_DIR` and uses it for every
runtime manifest read, including both checks executed inside a changed working
directory. No policy, workload, oracle, timeout, object inventory, or result
acceptance rule changed.

## Next Gate

Attempt 1 counts toward the plan's maximum of three preflight roots. A second
attempt must use a fresh run ID and a committed clean source tree. It may begin
only after host validation and a read-only review confirm that the path fix is
complete and does not weaken artifact verification.

## Read-Only Gate Review

An independent reviewer checked the sealed failed root, current code diff, and
this record. It confirmed that the failure occurred before the runtime mount
and every workload condition, that all 1,050 sealed evidence files verify,
that the fix covers all four runtime-manifest reads, and that no analogous
working-directory-relative blocker remains in the inner guest target. The
review found no code-level blocker and returned `GO` for a fresh attempt 2.
