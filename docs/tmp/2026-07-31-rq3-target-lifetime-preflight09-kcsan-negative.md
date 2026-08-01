# RQ3 target-lifetime preflight09 KCSAN negative result

## Purpose

This record preserves preflight09 and explains why its normal and KASAN boots
are positive but the complete three-kernel preflight is not paper evidence.

## Immutable result

The result root is:

`results/experiments/namei-ext-target-lifetime-preflight/20260801T075813Z-target-lifetime-preflight09/`

It used clean project commit
`af6498eaf89eb3c86201a93dd0183bb237c3ff36` and clean kernel commit
`621aff8d1bb52fad718f11fd882c956d6a5686ae`. The root is terminally `failed`
with `failure: kvm-launch-or-guest-command`; it must not be repaired, rerun, or
cited as a complete positive result.

## Positive mechanism observations

- The normal and KASAN boots each produced a positive `analysis.json`, clean
  dmesg, zero runner status, four deterministic RCU retirement litmus passes,
  complete final-file and directory histories, and a passing pinned-object
  lifecycle.
- In both boots, every bounded history executed exactly eight traced updates,
  every reader completed 64 descriptor-validated opens, observed at least four
  selected target states plus absence, and overlapped an update interval.
- The normal five-second stress phases executed 1,584 and 1,621 updates plus
  9.04 million and 8.45 million opens. The KASAN phases executed 673 and 796
  updates plus 360,534 and 353,428 opens. All reported zero semantic,
  descriptor, lower-object, lifecycle, cleanup, KASAN, lockdep, and RCU
  failures.
- Both raw traces retained every entry: 160/160 for each normal and KASAN
  final-file and directory cell. Each trace contained exact marker,
  kernel-entry, and kernel-return coverage plus successful and `-ENOENT`
  RCU-walk results.

These are diagnostic observations from an incomplete preflight, not a paper
result.

## KCSAN outcome

The KCSAN runner itself returned zero. Its two bounded histories, stress
phases, four retirement litmus rows, pinned-object lifecycle, lower-object
checks, and cleanup all passed. KCSAN engaged in every cell and recorded
237,077 setup watchpoints with zero assertion failures.

KCSAN's counters increased by 248 data races during the enabled windows. The
retained dmesg starts in the middle of a report and contains 179 complete
report blocks:

- 178 `data-race in init_file / init_file` reports; and
- one `data-race in acct_account_cputime / stop_this_handle` report.

The retained blocks do not exhaust the 248 detections: 69 detections were not
preserved as complete reports and cannot be attributed. Moreover, although no
retained report headline names a `namei_ext` kernel function, the report
stacks include the experiment reader/writer process. The experiment's frozen
rule therefore classifies the KCSAN boot as negative, irrespective of the
mechanism oracles.

The dominant retained pair occurs before the extension point in source:
`path_openat()` calls `alloc_empty_file()` and `init_file()` before
`path_init()`, `link_path_walk()`, or `open_last_lookups()`. Strict weak-memory
KCSAN simulates reordering of plain writes in `init_file()` while the
`SLAB_TYPESAFE_BY_RCU` file cache rapidly reuses file-object addresses. This
source attribution motivates a prospectively changed configuration; it does
not reclassify or excuse the negative preflight09 result.

## Bounded correction

The next preflight keeps strict KCSAN, the same sampling parameters,
unknown-origin reports, lockdep, PROVE_RCU, no report filter, and the zero-race
gate, but disables `CONFIG_KCSAN_WEAK_MEMORY`. This separates sampled actual
concurrent accesses from the broader simulated-reordering question encountered
before the extension point. KASAN and the deterministic update/grace-period
litmus continue to own the use-after-free and publication-order claims.

This is the final allowed interpretation change for this preflight path. If a
fresh run still reports a kernel diagnostic or fails any mechanism oracle, it
must remain negative or inconclusive and the formal matrix must not start.
