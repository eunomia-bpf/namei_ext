# W6 Spindle Preflight Attempt 6

## Result

`results/experiments/spindle-staging-preflight/20260802T113854Z-spindle06/`
completed one fresh modified-kernel KVM boot on source commit `85f6932` and
kernel commit `b07117a`. All scientific preflight gates passed. This is the
authorization evidence for a separate three-boot formal run, not the formal
W6 result itself.

## Workload Conditions

The source condition ran pinned LLNL Spindle commit `8853636` in serial pull
mode around its unchanged `test_driver --dlopen --pull --nompi` loader slice.
It exited zero with empty launcher stderr in 2.280 s. First-party Spindle logs
identified exactly 47 source-to-cache mappings.

The `namei_ext` condition ran the same loader argv and application environment
without Spindle's audit client. It exited zero in 0.162 s and emitted exactly
the 44 ordered upstream `dlstart` progress records required by the oracle.
The withdrawn condition used the same argv and environment after removing the
registered target for `libtest10.so`; it exited 255 with the expected loader
diagnostic.

## Raw Evidence Audit

- `run.json` records a clean source tree, clean kernel tree, one completed
  fresh boot, and the real `cgroup/namei_ext` policy and runner.
- All 47 mappings were byte-equal, size-equal cache copies on a distinct tmpfs
  device from their source objects.
- All 47 registered targets received at least one `SELECT`; the aggregate and
  per-target counters both report 68 selections, with per-target counts from
  one to three.
- All 47 logical-path identity probes matched the selected cache object's
  device, inode, type/mode, and size.
- Setting the selected `libtest10.so` target mode to `000` produced `EACCES`
  through the logical path, and restoring the mode succeeded.
- Removing target 1 left its counter at five while the same loader failed as
  required, demonstrating that the withdrawn run did not reuse that target.
- All 47 source/cache preservation rows report unchanged metadata and equal
  bytes after the workload.
- Guest prepare, workload, cleanup, external BPF/FUSE inventory, and dmesg
  gates all returned zero. The temporary mount, policy, targets, cgroup, and
  Spindle processes were absent after cleanup.
- The aggregate contains 209 observations and no observation with
  `pass != true`; `analysis/summary.json` reports verdict `supported`.

## Analyzer Defect And Disposition

The scientific analyzer produced and validated the correct `summary.json` and
`summary.csv`. Its final human-readable report recipe over-escaped two nested
`jq` strings, printed two empty lines, and returned success because `printf`
masked the command-substitution failures. The completed result root remains
immutable and is not repaired or promoted.

The source recipe now generates the entire report with one fallible `jq`
command, and an infrastructure test protects that execution shape. The formal
run must use the repaired clean commit and a fresh result root. It must repeat
all source, mapping, policy, selection, identity, permission, withdrawal,
preservation, cleanup, and analyzer gates on three independent KVM boots.
