# W6 Spindle Formal Result Review

## Verdict

**GO for the W6 RQ1 row.** The formal root
`results/experiments/spindle-staging/20260802T114220Z-w6-formal01/`
supports the scoped claim that `namei_ext` can perform final pathname selection
of exact node-local objects populated and identified by LLNL Spindle, while
Spindle retains object discovery and cache population.

This result completes W6. Together with the six previously reviewed source
workflows, W1--W7 now all have complete RQ1 evidence. The seven cases remain
separate; this result does not merge or remove any workload.

## Frozen Inputs

- Project commit: `4673c1fa3f2bcf38e1adaf8f2e4bd254ee179ec6`
- Kernel commit: `b07117a3cb41826a34af5ca61e3e2c81dade793f`
- Kernel release: `7.1.0-rc7-gb07117a3cb41`
- Spindle commit: `8853636d2d774729a5a728f5cf6c296b65a1099c`
- Protocol: three fresh KVM boots; source Spindle, direct `namei_ext`, and
  withdrawn-target conditions in every boot; 47 focal objects

`run.json` records clean project and kernel worktrees, the real
`cgroup/namei_ext` policy, three expected repetitions, and completed status.
All three `boot.json` files record zero prepare, workload, cleanup, inventory,
and dmesg status.

## Source And Application Oracle

Pinned Spindle ran in serial pull mode around its unchanged
`test_driver --dlopen --pull --nompi` loader slice. It exited zero with empty
launcher stderr in every boot and emitted one first-party source log per boot.
Those logs supplied exactly 47 unique source-to-cache mappings. Every cache
object was an existing Spindle-created file on the dedicated tmpfs, on a
different device from its source, with equal size and bytes.

The direct condition ran the same loader argv without Spindle's audit client.
It exited zero in all three boots and emitted the exact 44 ordered upstream
`dlstart` progress lines required by the source-derived oracle. The result does
not infer success from exit status alone.

## Policy Attribution And Object Semantics

Each boot installed 47 targets and 48 exact source/cache-origin rules. Every
target received at least one selection. Per-boot aggregate and per-target
counters both report 68 `SELECT` events, for 204 events across the formal run.

All 141 logical-path identity rows match the selected cache object's device,
inode, type/mode, and size. Temporarily changing the selected `libtest10.so`
target to mode `000` produced lower-filesystem `EACCES` in all three boots;
restoring the mode succeeded. Thus the direct loader success is attributable
to the registered existing objects, while ordinary lower-object permission
behavior remains in force.

## Withdrawn Control And Preservation

Removing target 1 left its hit counter unchanged at five in every boot. The
same loader then exited 255 with the expected `libtest10.so` diagnostic. This
is the causal control for the selected-object dependency.

All 141 preservation rows report unchanged source metadata, unchanged cache
metadata, and equal bytes after execution. Unmounting the read-only canary
restored the original source identity and bytes. External BPF and cgroup
inventories were empty before and after each boot; no FUSE mount, residual
open FUSE descriptor, temporary mount, cgroup, target, policy, or live Spindle
executable remained. All declared dmesg scans passed.

The aggregate contains 627 observations: 141 mappings, 141 selections, 141
identity checks, 141 preservation checks, nine workload conditions, three
permission probes, three withdrawal controls, three counter windows, three
runtime records, three summaries, and 39 lifecycle cases. No observation has
`pass != true`. `analysis/summary.json`, `summary.csv`, and `report.md` agree
on three boots, 3/3/3 conditions, 141/141/141/141 focal rows, 204 selections,
and verdict `supported`.

## Admitted Claim Boundary

The paper may claim:

- a source-derived HPC file-staging RQ1 case over 47 exact Spindle-created
  node-local objects;
- successful final pathname selection through the real modified-kernel KVM
  attach path in three fresh boots;
- exact selected-object identity, lower permission behavior, withdrawn-target
  failure, lower-object preservation, and complete cleanup for this slice.

The paper must not claim:

- replacement or reproduction of Spindle's distributed cache or broadcast
  control plane;
- Pynamic, MPI-scale, or production El Capitan performance;
- cache population, object recognition, coherence, stale-object validation, or
  data distribution by `namei_ext`;
- a W6 FUSE comparison or any W6 performance advantage.

Earlier incomplete preflight roots remain diagnostic history. They are not
combined with this formal result and are not needed to support the admitted
claim.

## Independent Review

An independent read-only reviewer found no blocking issue and agreed that W6
is admissible as formal RQ1 evidence for the pinned loader slice. It identified
two wording limits reflected above:

- the source-condition record reports exit zero, and the first-party Spindle
  logs independently record the application exit code as zero; do not treat a
  summary count alone as the child-exit oracle;
- preservation establishes before/after metadata equality and final
  source/cache byte equality. It does not establish a separate byte-history
  comparison for each side across time.
