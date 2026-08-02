# RQ2 mdtest Reconsideration Preflight Attempt 1

## Purpose

This record preserves the first real KVM preflight under the 2026-08-02
reconsideration plan. The immutable result root is:

```text
results/experiments/mdtest-cold-metadata-rq2-preflight/20260802T013000Z-mdtest-reconsideration-preflight01/
```

The source and kernel commits were clean and pushed. The host used no turbo,
the performance governor on CPUs 8--15, no pre-existing QMP listener on port
3636, and no QEMU, mdtest, MPI, or FUSE process before launch.

## Outcome

The first stock boot failed before the guest workload barrier. No mdtest, MPI,
ext4 fixture, FUSE, BPF, cache-drop, or performance observation exists. The
runner stopped before the other four conditions.

Raw statuses are:

```text
QMP listener observed: 0 (success)
launcher/QEMU status: 255
affinity verifier status: 1
run.json failure: vcpu-affinity-verification
```

The verifier waited the frozen six seconds and then made 200 attempts. All
failed with `ECONNREFUSED` because QEMU had already exited. The original
`run.json` label gives verifier failure priority and therefore does not capture
the simultaneous launcher failure; the separate raw status files preserve both
return values.

## Root Cause

The verbose launcher log contains a complete kernel boot followed by:

```text
/dev/root: Can't open blockdev
VFS: Cannot open root device "" or unknown-block(0,0)
Kernel panic - not syncing: VFS: Unable to mount root fs
```

The actual kernel command line contains the large base64 `virtme.exec` payload
but no `rootfstype=9p`, `rootflags=...`, `root=/...`, or init argument. In the
official launcher source those root arguments are appended after the encoded
guest command. A source-native dry run with a short `--exec true` includes the
expected 9p root arguments. The evidence therefore supports this diagnosis:
the project passed six repeated absolute artifact/result paths through the
guest Make command, the x86 kernel command line was truncated before the later
root arguments, and the kernel could not mount its host-backed root. This is a
runner argument-size defect, not an mdtest, FUSE, `namei_ext`, or native-pinning
result.

## Repair For Attempt 2

The guest command now passes one `MDTEST_RUN_ROOT` plus short condition,
repetition, item-count, and kernel identity values. Guest Make derives the six
runtime artifact paths, boot directory, and kernel config path from that root.
This preserves the exact binaries, mdtest phases, oracle, conditions, ranks,
item counts, and analysis while removing repeated long command-line paths.

The native capture failure label is also repaired: simultaneous nonzero
launcher and verifier statuses are recorded as
`kvm-launch-and-affinity-verification`, rather than silently attributing both
to the verifier. The immutable attempt-1 root is not changed or reinterpreted
as a workload result.

An official-launcher `--dry-run` with the shortened attempt-2 guest command
completed successfully and showed all of the arguments that were absent from
the failed boot:

```text
virtme.exec=<present>
rootfstype=9p
rootflags=version=9p2000.L,trans=virtio,access=any,msize=524288
raid=noautodetect
init=.../virtme/guest/virtme-init
```

This validates the repaired command construction without modifying or rerunning
the attempt-1 result root. It is not a KVM preflight result; attempt 2 must still
boot each real condition and pass the guest workload barrier.

## Decision

```text
run status: incomplete
paper evidence: none
preflight budget: attempt 1 consumed; at most two attempts remain
next action: independently review the bounded command-size repair, then run a
  fresh attempt 2 only if approved
```
