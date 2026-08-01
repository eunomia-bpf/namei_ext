# Implementation Review: RQ2 official Documents portal comparison

## Round 1: No-Go

The first independent implementation review rejected a KVM preflight. The
host gate passed, but six defects could either mislabel the storage substrate,
pollute the mechanism counters, accept incomplete samples, or leave the frozen
secondary evidence unreported.

1. Both fixtures were rooted under virtme's `/tmp`, whose observed backing is
   not guaranteed to be ext4. The implementation now creates a dedicated
   512-MiB loop-backed ext4 filesystem in every fresh boot. The runner checks
   `statfs()` for `EXT4_SUPER_MAGIC`; the guest records `findmnt` and `statfs`
   output; the finalizer requires all three observations to agree. A recursive
   Make target owns setup and execution so the outer target can always attempt
   unmount and record cleanup after a setup or mechanism failure.
2. The run was marked complete before analysis. Analysis now requires a
   `running` result root and executes after raw finalization. The parent target
   marks the root complete only after all analysis outputs validate.
3. The `namei_ext` counter window included `/proc` process snapshots. The
   process snapshot is now captured before the BPF `before` snapshot and after
   the BPF `after` snapshot. Thus only the shared measured transaction lies in
   the BPF action-count interval. Both analysis and finalization require
   positive `select` and `readdir` deltas.
4. The analyzer initially emitted only the primary pair ratio. It now emits
   per-operation median ratios, transaction p95/p99 ratios, direct-ext4 boot
   sensitivity, per-transaction client/daemon resources, grant/revoke latency,
   FUSE opcode and BPF action counts, and arm-order sensitivity. It writes the
   summary, pair rows, decomposition/resources/counters/controls CSV files,
   Markdown report, and latency-decomposition PDF and PNG.
5. Any FUSE opcode could satisfy the original engagement gate, including a
   delayed `FORGET`. The corrected gate separately requires a measured file
   request (`OPEN` or `READ`) and directory request (`OPENDIR`, `READDIR`, or
   `READDIRPLUS`) for the portal connection.
6. The original analysis checked only sample row counts. It now requires each
   stream's sample IDs to be exactly `0..N-1`, every sample to be in the
   measured phase, and the per-boot summary to match the frozen 22-byte ID,
   27-byte payload, warmup count, measured count, and direct-control count.
   Unit tests include a same-length duplicate-ID corruption that must fail.

During remediation, local inspection also found and removed redundant buffer
cleanup in both C runners and stopped the host transaction smoke from calling
its unspecified `/tmp` filesystem `direct-ext4`.

## Validation After Remediation

The following host-level checks pass after the changes:

- both C runners compile with `-Wall -Wextra`;
- the real `namei_ext` policy and FUSE tracepoint collector build;
- the shared visible/read/readdir/hidden transaction smoke passes;
- three analysis tests pass, including output generation and duplicate sample
  rejection;
- the official portal 1.22.1 build has four passing selected Meson tests with
  no failures, skips, or timeouts;
- fixed host CPU, KVM, kernel-command-line, source-revision, and artifact gates
  pass.

These are source and host gates only. They do not establish that the dedicated
ext4 lifecycle, official portal FUSE attribution, real cgroup attachment, or
paired finalizer works in the modified-kernel guest.

## Round 2

The independent follow-up remained **NO-GO** and found three additional
experiment-validity defects:

1. The rows named `first-after-grant` and `first-after-revoke` followed the
   older five-state observation, so they were not the first operations after
   the corresponding acknowledgement. In RQ2 mode, both runners now execute
   the dedicated visible or hidden oracle first, then preserve the older state
   row for the complete source-oracle matrix.
2. The `namei_ext` client resource interval included its BPF map reads and JSON
   counter emission, while the portal client interval excluded its counter
   instrumentation. The corrected order is BPF counter before, client snapshot
   before, measured transaction collection, client snapshot after, and BPF
   counter after. The client delta therefore contains only the measured loop.
   The counter interval includes the two `/proc` snapshots, but the policy's
   exact-parent prefilter prevents those paths from invoking the policy; the
   gate requires positive measured `select` and `readdir` deltas.
3. The finalizer required five passing source states but did not require their
   identities. It now compares the complete sorted state-name array against
   the exact five frozen application/grant states for both mechanisms, which
   also rejects duplicates.

The C runners, host transaction smoke, analysis tests, and complete host gate
pass after these repairs.

## Round 3

The final bounded follow-up confirmed the immediate-oracle and exact-state
repairs but remained **NO-GO** on counter attribution. The raw `readdir`
counter increments before the policy filters a name and parent, so the two
`/proc/<pid>/task` resource snapshots inside its interval can increase that
counter.

The policy now also records `visible_readdir` only after the entry name matches,
the parent scope exists, the application grant exists, and the event is
`READDIR`. The raw dispatch counter remains available, but mechanism
engagement requires `select` plus this scope- and action-specific counter.
`/proc` resource collection cannot satisfy that condition. The analyzer,
synthetic tests, and finalizer all use the new counter.

No further review round is opened. The next gate is the real one-pair KVM
preflight, whose result requires an independent raw-result review before any
formal run.

## Real Preflight Attempt 1

Run `20260801T111359Z-b3eb222` failed before either controller started. The
portal guest successfully booted the modified kernel and passed the initial
inventory, clocksource, and dmesg gates. It created and formatted the ext4
image, but virtme's guest root did not provide a creatable `/mnt` parent, so
`install -d /mnt/namei-ext-rq2` failed. The outer target recorded mechanism
status 2, successful cleanup, clean post-inventory and dmesg, and marked the
result root failed. Its observation stream is empty; it is not mechanism or
performance evidence and will not be reused.

The mountpoint moves to the guest's writable `/tmp` tree. This does not change
the measured filesystem: the loop image is mounted on that directory before
fixture creation, and the existing `findmnt`, `statfs`, and runner gates still
require the resulting fixture root to be ext4. A second preflight will use a
fresh result root.
