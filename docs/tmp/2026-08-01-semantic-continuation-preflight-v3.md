# Semantic Continuation Preflight V3

## Scope

Result root:

`results/experiments/semantic-continuation-preflight/20260801T132000Z-semantic-preflight-v3`

This immutable root used clean source commit
`021c016b644c644a9376452c7193fa768b0b9ed7` and clean kernel commit
`b07117a3cb41826a34af5ca61e3e2c81dade793f`. It ran the frozen preflight matrix
with direct then selected arms in one fresh modified-kernel KVM boot.

## Guest Evidence

The guest completed successfully:

- `runner.status=0`;
- `boot.json` records `status=completed`, `inner_status=0`,
  `cleanup_status=0`, and `dmesg_status=0`;
- the ext4 and tmpfs fixtures were both mounted and identified in the guest;
- runner stderr, launcher stderr, and the project dmesg failure-signature scan
  were empty.

The raw guest stream contains 51 events. Every event carrying `pass` is true:

- 14 setup/teardown/cleanup events;
- 26 syscall-level operation events;
- four case summaries and four lower-object residual checks;
- two selected-arm BPF engagement events;
- one passing experiment summary.

S02 passed eight operations in each arm, including exclusive create, write,
metadata and access checks, read, `EEXIST`, unlink, and `ENOENT`. S11 passed five
operations in each arm, including a source create, rename across two selected
components backed by the same ext4 mount, source disappearance, destination
read, and unlink. The normalized direct and selected operation streams are
identical. Selected S02 recorded seven target-A decisions. Selected S11 recorded
three target-A and three target-B decisions. All four physical residual checks
passed.

## Host Finalizer Failure

The result lifecycle is nevertheless `status=failed` with
`failure=host-finalize`. The finalizer expected the literal pattern
`FSTYPE<space>ext4` in the human-readable `findmnt` table. The actual rows are:

```text
TARGET                                    SOURCE     FSTYPE OPTIONS
/tmp/namei-ext-semantic-continuation/ext4 /dev/loop0 ext4   ...
```

and the analogous tmpfs row. The filesystem type is the third data column, not
text immediately following the header token. All earlier frozen assertions
passed. The ext4 grep failed first and stopped the finalizer; the identical
tmpfs predicate would also reject its captured row.

The forward fix parses the third data column with `awk` and requires an exact
`ext4` or `tmpfs` value. It does not modify this root or rerun a target against
it.

## Evidence Boundary

V3 demonstrates that the corrected guest dependency path can attach the policy,
register targets and exact-parent scope, run S02/S11 with direct-selected
equivalence, attribute selected decisions, clean lower objects, and shut down
cleanly. It is not a successful experiment root and is not formal S01--S16
mechanism evidence. An independent raw-result and workflow review found no guest
oracle failure, confirmed the parser root cause and narrow fix, and approved
proceeding directly to the three-boot frozen formal matrix without a fourth
preflight.
