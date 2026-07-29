# RQ2 FxMark Directory Enumeration Plan Review

## Scope

An independent read-only reviewer checked:

- `docs/tmp/2026-07-28-rq2-fxmark-readdir-experiment-plan.md`;
- pinned FxMark `MRDL.c` and `MRDM.c`;
- `bench/fxmark/fxmark_cell.c` and `bench/fxmark/fxmark_fuse.c`;
- the kernel exact-scope and directory-iteration paths; and
- the existing formal FxMark result review.

The review asked whether corrected private/shared directory enumeration adds
paper value, keeps work equivalent, exercises the intended hook, uses a valid
FUSE comparator, and has an interpretable paired protocol.

## Initial Verdict

The reviewer returned `NO-GO` before implementation for four blocking
contracts:

1. the current cell runner recognizes only `MRPL`, `MRPM`, and `MRPH`, and
   validates only the physical tree;
2. current attachment identity is not proof that exact scope includes the
   directories being enumerated or that the readdir event executes;
3. the current FUSE callback ignores directory offsets and passes zero to every
   filler call; and
4. the current cell accepts FUSE timing with no positive measured
   `opendir`/`readdir`/`releasedir` evidence.

The reviewer found that the fixed-cardinality and EOF corrections are
scientifically justified, the paired block/bootstrap protocol is appropriate,
and the experiment is not redundant with the Agent lifecycle because it
isolates standard private/shared directory enumeration.

## Required Repairs

Implementation is not authorized to enter KVM until all four contracts are
executable:

- extend the runner and analyzer with exact `MRDL`/`MRDM` physical and logical
  cardinality;
- pre-create and register each enumerated directory as an exact policy scope;
- after timing, prove the readdir event with an already-open-directory
  handshake in the measured cgroup and exact run-count attribution;
- prove the nonexistent logical `view` selects the expected lower object;
- implement FUSE `seekdir()`/`telldir()` offsets and verify a full logical
  enumeration over a directory larger than one FUSE reply; and
- require positive measured `opendir`, `readdir`, and `releasedir` counts.

## Gate

The initial `NO-GO` rejects running the current implementation, not the
experiment question. After the repairs, a fresh independent implementation
review must inspect the actual code and return `GO` before the first real KVM
preflight.

The first real KVM attempt later showed that the initial
`run-count == returned-entry-count` equation omitted VFS buffer-boundary
retries: policy runs before the userspace fill actor rejects a candidate that
does not fit. The repaired exact equation records fixed-size non-empty
`getdents64` calls and adds one retry per non-final call. This preserves the
review's attribution requirement rather than weakening it.
