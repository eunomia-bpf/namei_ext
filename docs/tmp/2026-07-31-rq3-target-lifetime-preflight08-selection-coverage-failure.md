# RQ3 target-lifetime preflight08 selection-coverage failure

## Purpose

This record preserves the first KVM result from the bounded-history runner and
explains why it is not target-lifetime evidence.

## Immutable failed result

The result root is:

`results/experiments/namei-ext-target-lifetime-preflight/20260801T071055Z-target-lifetime-preflight08/`

It used clean project commit
`cd21c298d547d526071c1df4a98a8eef24a7e09d` and clean kernel commit
`621aff8d1bb52fad718f11fd882c956d6a5686ae`. The run is terminally `failed`
with `failure: kvm-launch-or-guest-command`. Only the normal-kernel boot ran;
the matrix correctly stopped before KASAN and KCSAN.

## Raw observations

- The runner returned status 0 and its run summary reported zero failures.
  Both publication cells, all four deterministic retirement litmus rows, and
  the four-cycle pinned-object lifecycle completed.
- The bounded histories were 312 KiB in total rather than the 457 MiB produced
  by preflight07. The final-file and directory raw traces retained all 163/163
  and 168/168 entries, respectively, with exactly eight begin/end marker,
  kernel-entry, and kernel-return pairs in each cell.
- Each history completed in about 33 ms, below the five-second success
  deadline. The five-second supplemental stress phases completed with zero
  unexpected operations.
- The offline analyzer rejected the final-file cell with `fewer than two
  selected target states observed`. Reader 0 observed 63 successful opens of
  `final-file-1` and one absent result; reader 1 observed 66 successful opens
  of the same target and one absent result. The history contained five
  successful `SET` operations, but the writer advanced before the readers
  sampled a second selected state. The directory cell happened to observe two
  selected states and absence.

These observations show that bounded capture, trace retention, and fail-fast
execution worked. They do not establish the complete lifetime oracle because
one cell lacked the declared selected-state breadth. No KASAN or KCSAN result
exists, and the run must not be cited as positive mechanism evidence.

## Root cause and repair

The runner required every reader to observe a selected object and absence, but
the stronger two-selected-state condition existed only in the offline
analyzer. Satisfying it therefore depended on guest scheduling.

The repaired history makes this condition deterministic with generation-scoped
rendezvous. After the writer completes its first two `SET` operations and first
`CLEAR`, it publishes a new generation and the expected target identity or
absent state. Each reader performs exactly one complete validation for that
generation and then waits for the next one; a result from before that
publication cannot acknowledge it. After all readers acknowledge all three
generations, the writer begins a fourth update's recorded interval and waits
for one complete absent open from every reader before entering the control
write. This guarantees per-reader overlap in the global operation history;
readers then continue immediately for concurrent stress. Each reader records a
raw target-state bitmask summary, and the offline analyzer recomputes the
distinct-state count from paired history. The existing operation upper bound
and history deadline remain hard failure gates. Exact kernel-window overlap is
tested by the deterministic replacement/clear litmus; bounded ftrace requires
complete update entry/return coverage plus successful and absent RCU-path
engagement. The collector and analyzer require an exact `-ENOENT` return for
the absent class and separately count all nonzero returns, while retaining
under-update counts as descriptive evidence.

Before another KVM attempt, the repaired code must pass warnings-as-errors and
GCC `-fanalyzer` builds, analyzer tests, `git diff --check`, and independent
P0/P1 review. The next attempt must use a fresh result root.

## Repaired host validation

The repaired runner passed a clean normal warnings-as-errors build and a clean
GCC `-fanalyzer` build. The analyzer passed 52 unit tests, including a negative
test that rejects `-ESTALE` as absent evidence; Python bytecode compilation and
`git diff --check` also passed. An independent review found that the first
version accepted any nonzero RCU result as absent evidence. The exact
`-ENOENT` gate and raw-backed `rcu_absent_results` field correct that P1 before
the next KVM attempt. The follow-up independent review returned GO with no P0
or P1. It confirmed the three generation-scoped state observations, the fourth
update API-interval rendezvous for every reader, exact raw-backed absent
evidence, and fail-fast deadline and abort propagation.
