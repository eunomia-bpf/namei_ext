# RQ3 Target Lifetime Preflight04 KCSAN Window Repair

## Motivation

The concurrent target-lifetime experiment tests the construction risk behind
registered-object selection: a reader may borrow a registered `struct path`
during RCU path walk while another task replaces or clears that registration.
The experiment must show that the old mount and dentry survive until the
reader hands the selected object back to ordinary VFS continuation.

Preflight04 used the fresh result root
`results/experiments/namei-ext-target-lifetime-preflight/20260801T052827Z-target-lifetime-preflight04/`.
The root is failed and remains immutable.

## Observed Result

The normal and KASAN boots produced positive `analysis.json` files. The KCSAN
runner also exited with status zero, and its four version-2 deterministic
litmus rows passed for file replacement, file clear, directory replacement,
and directory clear. Each row recorded the expected borrowed target, reader
and writer identities, old-object completion, and fresh replacement or
`ENOENT` postcondition.

The KCSAN boot did not pass. Its analyzer reported 160 kernel diagnostic
blocks. KCSAN was enabled from early boot, so the before snapshot already
contained 223 detected races; the after snapshot contained 255. Report
headlines were dominated by virtme 9p, scheduler/tick, GUP, kernfs, and
virtqueue function pairs. No report headline named a `namei_ext` function.
Under the frozen plan, unrelated diagnostics make a boot inconclusive, so this
root cannot support a positive target-lifetime claim.

## Code Paths Inspected

- `configs/kernel/x86_64_phase1_kcsan.config` enabled
  `CONFIG_KCSAN_EARLY_ENABLE`, which caused KCSAN to sample virtme boot and 9p
  root activity before the experiment.
- `kernel/kernel/kcsan/debugfs.c` provides explicit `on` and `off` controls and
  exposes cumulative setup-watchpoint, race, and assertion counters.
- `mk/experiments/namei_ext_target_lifetime.mk` placed the ext4 loop image,
  runner output, and executable path under the 9p-backed result/project roots.
- `experiments/namei_ext_target_lifetime/namei_ext_target_lifetime.c` already
  separates per-cell setup in the parent from the attached workload in a
  child, giving a precise point at which to start and stop KCSAN.
- `analysis/namei_ext_target_lifetime/analyze.py` previously required KCSAN to
  be enabled at both snapshots and rejected any positive race-counter delta.

## Design Choice

KCSAN is now built with early enable disabled. Each attached child turns KCSAN
on only after policy attachment, scope setup, and cgroup migration, runs the
complete target-lifetime cell, turns KCSAN off, and verifies the observed
debugfs state. The parent verifies that KCSAN is off after the child and forces
it off while failing the run if the child exits unexpectedly.

The guest now mounts a dedicated tmpfs, creates the ext4 loop image inside that
tmpfs, and stages a statically linked target-lifetime runner, BPF objects,
source-derived control assets, and live outputs onto ext4. Raw result files are
copied to the 9p result root only after KCSAN is off. The source-derived control
runner executes only after KCSAN is disabled. This removes experiment-owned
dynamic-loader, library, input, and output accesses to 9p during each measured
window; it does not suppress or assume away unrelated kernel background work.
Before the workload, the guest preserves and clears the boot/setup dmesg. The
analyzer checks both that log and the subsequent workload-window log.

The runner preserves a complete KCSAN debugfs snapshot immediately before and
after each of the final-file, directory, and pinned-object cells. The analyzer
requires a positive setup-watchpoint delta in every cell and equality between
the sum of those deltas and the boot's outer delta. Thus one active cell cannot
stand in for the other two, and no sampled KCSAN interval can be hidden between
cells. Any abnormal child exit causes the parent to issue and verify `off`;
failure stops subsequent KCSAN cells. A wrapper sub-Make always attempts ext4
and tmpfs cleanup after the body reaches success or failure.

No report filter is used. A whitelist could hide a race between a
`namei_ext` access and a generic VFS, slab, dentry, or mount function, which is
exactly the ownership failure this experiment is intended to detect.

## Validation Performed

- `make namei-ext-target-lifetime` rebuilt the statically linked runner with
  warnings as errors and no dynamic interpreter or shared-library dependency.
- `make namei-ext-target-lifetime-analysis-test` passed 45 analyzer tests after
  the independent-review repairs.
- Tests now reject early-enabled KCSAN configuration, KCSAN left active outside
  workload windows, report filters, per-cell missing watchpoint engagement,
  activity outside the declared cell windows, positive race deltas, and
  positive assertion deltas.
- `git diff --check` reported no whitespace errors.

## Remaining Work

The KCSAN kernel has been rebuilt with the corrected fragment. The next fresh
KVM execution must show that normal, KASAN, and KCSAN boots all complete; every
KCSAN cell must show a positive setup-watchpoint delta with exact outer-window
partitioning and zero race and assertion deltas; both dmesg segments must be
clean; and all four deterministic litmus rows and the history, descriptor,
lower-object, and cleanup oracles must pass. Preflight04 will not be repaired
or reinterpreted.

## Independent Review

The first review found three P1 defects and one P2 defect: abnormal children
could leave KCSAN enabled, the dynamically linked runner could still fault
libraries from the 9p root, one aggregate counter delta did not prove per-cell
engagement, and failed guest bodies skipped explicit mount cleanup. The repair
made the target runner static, added unconditional parent-side disable and
fail-fast cell termination, added exact per-cell counter partitioning, and
wrapped the guest body with unconditional cleanup.

The follow-up review returned `GO`: all four findings were closed, the new
snapshot/partition and cleanup paths introduced no P0/P1 finding, the static
ELF was confirmed, all 45 analyzer tests passed, and `git diff --check` passed.
The reviewer did not execute KVM; modified-kernel evidence remains the next
gate.
