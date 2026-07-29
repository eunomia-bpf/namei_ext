# FxMark Readdir KVM Preflight Attempt 2

## Run

```text
make kvm-fxmark-readdir-preflight \
  RUN_ID=20260729T080444Z-fxmark-readdir-preflight-v2
```

Raw root:

```text
results/experiments/fxmark-readdir-preflight/
  20260729T080444Z-fxmark-readdir-preflight-v2/
```

The run used clean source commit
`3e4e35ba8ea31d8ddb32baf9717e2d76cf0539ad` and clean kernel commit
`1e81d4793c78b7667d0798248c70c0b15a2c3877`.

## Guest Outcome

All five fresh boots completed: stock, unattached, `PASS`, `SELECT`, and FUSE.
All 20 workload cells passed their in-guest correctness gates.

The repaired attribution equation held exactly in every attached cell. For
example:

```text
PASS MRDL, one worker:
  returned entries       = 8,194
  non-empty getdents     = 81
  enumerated directories = 1
  retry runs             = 80
  readdir policy runs    = 8,274
  lookup policy runs     = 2
  total policy delta     = 8,276
```

`SELECT` produced the same exact counts and selected the expected lower
directory identity. All FUSE rows observed one measured-phase acknowledgement,
one after-phase acknowledgement, zero invalid transitions, complete logical
names, and positive measured `opendir`, `readdir`, and `releasedir` requests.

## Host Finalizer Failure

The run failed after all guests completed, before top-level observation
collection and analysis. `NAMEI_EXT_MULTI_BOOT_COLLECT_OBSERVATIONS` always
iterates each direct boot directory and requires
`$boot/observations.jsonl`. Its optional third parameter is passed to a tree
gate that counts nested observations at depth three or greater.

The readdir suite incorrectly passed the five direct boot files as that nested
count. The actual files are correctly located at depth two:

```text
boots/block-01-*/observations.jsonl
```

The gate therefore expected five nested files, found zero, and stopped before
creating the top-level `observations.jsonl`. `run.json` remains in its emitted
`running` state because the generic host finalizer has no failure-state
rewriter. The raw root must not be resumed or repaired in place.

## Repair

The suite now calls the shared collector without the optional nested-file
count, matching the already completed multi-boot suites. The collector still:

- requires exactly five direct boot directories;
- rejects non-directory children under `boots/`;
- rejects nested `boot.json` and nested observation artifacts;
- requires one direct `observations.jsonl` in every boot while collecting; and
- is followed by exact 20-row, uniqueness, expected-cell, expected-boot, input
  hash, artifact hash, boot-file, dmesg, and analyzer gates.

## Repair Review

A fresh independent read-only review recomputed the attempt from raw evidence.
It confirmed five completed boots, 20/20 passing cells, matching expected and
observed boot/cell manifests, exact BPF attribution, `SELECT` identity, FUSE
phase acknowledgement, clean dmesg, verified affinity, empty external
inventories, and valid source/artifact hashes. On a diagnostic copy, the
reviewer completed direct observation collection and the frozen preflight
analysis.

The review found that the optional nested-file count was the only failing gate
and that omitting it retains every direct-file, row-count, uniqueness,
provenance, dmesg, inventory, and analyzer check.

Final verdict: GO

## Attempt Accounting

This is real KVM preflight attempt 2 of the maximum three. It is strong
diagnostic evidence that all 20 guest cells and the repaired policy-attribution
oracle work, but it is not a completed preflight and is excluded from paper
performance results. Attempt 3 must use a new clean commit and fresh run ID.
