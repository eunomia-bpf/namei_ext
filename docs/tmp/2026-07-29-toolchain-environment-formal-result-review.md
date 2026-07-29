# Toolchain Environment Formal Result Review

## Inputs

- Plan: `docs/tmp/2026-07-29-toolchain-environment-experiment-plan.md`
- Raw root:
  `results/experiments/toolchain-environment/
  20260729T171551Z-toolchain-formal01/`
- Source commit: `d1d1b635970c69d4168df7e2cafa06bc2cbcd47c`
- Kernel commit: `621aff8d1bb52fad718f11fd882c956d6a5686ae`

## Completion And Recalculation

The run contains three terminal, clean-source modified-kernel KVM boots. Each
boot completed two physical environment controls, four logical states, one
paired process-group start, one switch, one rollback, one permission control,
one withdrawn control, lower inventory comparison, teardown inventory, and
the declared dmesg scan.

Independent recalculation found:

- 66 observations and no record with `pass != true`;
- 18/18 physical or logical state records passed;
- 24/24 Python probe files passed every version, executable, prefix, SOABI,
  pip-path, environment-marker, and import check;
- 18/18 `pip check` commands reported no broken requirements;
- 3/3 paired starts observed Python 3.10 and 3.12 in distinct cgroups;
- 3/3 switches observed 3.12 and 3/3 rollbacks returned to 3.10;
- all logical root and interpreter inode observations matched the selected
  lower objects;
- 3/3 permission controls observed `EACCES`, and 3/3 withdrawn controls
  observed `ENOENT`;
- each boot recorded 159,162 lookup events, 6,739 `SELECT` events, and positive
  hits for all three targets;
- all three 3,270-row lower inventories compared equal, and teardown left no
  external BPF program, cgroup attachment, or FUSE mount/file descriptor.

## Findings And Scope

The original finalizer did not require every lifecycle and counter record to
exist, although the raw result contains all seven lifecycle and five counter
records in every boot. The implementation now checks those events explicitly
for future runs. This did not invalidate the reviewed result because the
review recomputed them directly from each boot's raw JSONL.

The permission and withdrawn records report the observed errno after the
declared mode and map changes; they do not independently identify the exact
kernel check that produced the errno. The barrier establishes a paired start,
not measured execution-time overlap. The lower inventory covers type, mode,
UID/GID, size, device, inode, and mtime, not ctime or file contents.

## Verdict

Valid as supporting RQ1 evidence. Across three fresh modified-kernel KVM
boots, one `cgroup/namei_ext` policy made the same logical
`view/current/bin/python` path select existing Ubuntu-created CPython 3.10.19
and 3.12.3 virtual environments for two process groups. Unmodified CPython
observed the expected environment, one process group switched and rolled
back, selected object identities matched the lower objects, and the declared
permission, withdrawal, inventory, cleanup, and kernel-health controls passed.

This result does not support a performance claim, superiority over FUSE or a
custom filesystem, applicability to every toolchain manager, or preservation
of filesystem semantics that the experiment did not observe.
