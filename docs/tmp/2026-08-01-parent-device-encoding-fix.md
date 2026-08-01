# Parent Device Encoding Fix

Date: 2026-08-01
Status: implementation record before the third official XDG portal RQ2
preflight

## Motivation

The second official XDG portal RQ2 preflight used a dedicated loop-backed ext4
filesystem. The official portal arm completed, and the `namei_ext` arm loaded,
attached, registered its target, and dispatched the BPF program. However, every
managed operation returned `PASS`: `SELECT`, lookup `HIDE`, and readdir `HIDE`
counters remained zero. The logical placeholder directory was consequently
visible while its selected payload was absent.

The failed immutable result root is:

```text
results/experiments/application-file-sharing-rq2-official-preflight/20260801T111530Z-d8c1654/
```

## Root Cause

The component-map control plane constructs its parent key from
`stat(parent).st_dev`. Linux exports that value using `new_encode_dev()` (or the
equivalent 64-bit `huge_encode_dev()`). The BPF context instead copied the
kernel-internal `super_block::s_dev` value directly.

Those representations are not interchangeable. For `/dev/loop0` (major 7,
minor 0), the userspace encoding is 1792, while the kernel-internal `MKDEV`
representation with 20 minor bits is 7340032. Therefore the exact
`(parent_dev, parent_ino, name)` key installed by userspace could not match the
key constructed by the BPF program. Earlier tmpfs-backed runs did not exercise
this block-device encoding difference.

The fixed 22-byte document ID was present in the compiled BPF instruction
stream, policy dispatch counters were nonzero, and target/scope map update calls
succeeded. These observations rule out the name literal, verifier, attachment,
and target registration as the failure source.

## Implementation

`kernel/fs/namei_ext.c` now exposes `parent_dev` with
`huge_encode_dev(inode->i_sb->s_dev)`. This matches the `st_dev` representation
used by the userspace map-key API while retaining the existing 64-bit UAPI
field. `parent_ino` and the rest of the ABI are unchanged.

The experiment remains on the dedicated loop-backed ext4 filesystem. It does
not weaken the scope key, use a global policy, or return to a tmpfs lower tree.

## Validation Performed

Before committing the kernel repair:

- `make kernel-objects` rebuilt all touched namei/BPF kernel objects, including
  `fs/namei_ext.o`, without error;
- `make application-file-sharing-rq2-official-host-gate` passed the BPF and C
  builds, shared transaction smoke, all three analysis tests (including
  duplicate-sample rejection), fixed host/KVM configuration gates, and all four
  selected upstream portal tests with zero failures, skips, or timeouts.

These checks validate compilation and the frozen host protocol. They cannot
validate the corrected context value because that requires the modified kernel
and real BPF attachment.

## Remaining Validation

1. Build the full committed kernel image through Make.
2. Run the third fresh-root paired KVM preflight.
3. Require nonzero `SELECT`, lookup `HIDE`, readdir `HIDE`, and visible-readdir
   counters, complete source/namei correctness oracles, clean teardown, and a
   valid paired analysis before admitting the result.

The preflight result will be reviewed independently before any formal run.

## Remaining Risk

This repair establishes compatibility with `stat(2)` map keys on the tested
architecture and ext4 lower filesystem. The UAPI still exposes a compound
device number rather than separate major/minor fields; an upstream ABI proposal
should specify the encoding explicitly or expose major/minor separately.
