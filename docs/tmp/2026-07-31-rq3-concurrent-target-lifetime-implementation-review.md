# RQ3 Concurrent Target Lifetime Implementation Review

## Scope

This record covers the independent pre-KVM review of the implementation in
`experiments/namei_ext_target_lifetime/`, its offline analyzer, debug-kernel
configuration, and Make/KVM result lifecycle. It does not establish a KVM
result. The implementation must receive a follow-up `GO` before images are
built or a preflight result root is created.

## Initial Verdict

The independent reviewer returned `NO-GO`. The checker algorithm itself matched
an additional exhaustive small-history audit, and the default path could not
pass without the real `cgroup/namei_ext` attachment and `SELECT_TARGET` action.
The blockers concerned evidence fidelity and experiment engagement:

1. a response timestamp was captured before raw-event serialization, so an
   equal timestamp could order a later invocation incorrectly;
2. the run could pass without any reader operation overlapping a target update;
3. no raw observation proved that target resolution executed with
   `rcu_walk=true`;
4. rename, unlink, clear, and post-clear held-descriptor claims appeared only in
   an aggregate lifecycle result;
5. child-side output failures could be lost through fork copy-on-write, and
   reader summaries were not fully reconciled with paired history;
6. hung-task detector configuration was absent and the diagnostic expression
   did not match the kernel's standard blocked-task headline;
7. the internal KVM capture target accepted a matching run ID without requiring
   a still-running result root and empty boot directory; and
8. formal duration, reader, progress, lifecycle, and timeout variables could be
   overridden even though only repetition count was frozen.

## Repairs Submitted For Follow-Up

- Invocation and response boundaries now receive a shared monotonic event
  sequence while the JSONL write is serialized. The checker uses that sequence
  as history order and treats the timestamp as a raw observation only.
- Every configured publication reader must have at least one `OPEN` interval
  overlapping a `SET` or `CLEAR` interval.
- Each publication cell performs one controlled
  `openat2(RESOLVE_CACHED)`. A PID-filtered dynamic kprobe on
  `namei_ext_resolve_target()` records its `rcu_walk` argument. The analyzer
  requires a successful target-identity check and at least one `true` branch
  observation. The probe is enabled only for this bounded operation and does
  not modify the kernel ABI or normal hot path.
- Every pinned-file and pinned-directory lifecycle cycle records the exact
  result for registration, held open, rename, post-rename open, unlink where
  applicable, clear, post-clear absence, and post-clear held-descriptor use.
  Held checks record expected and observed device/inode identity.
- Event sequence, operation sequence, and failure count now use shared anonymous
  memory across the policy-cgroup child and parent. The analyzer independently
  reconstructs each reader's open, success, and absence counts from paired raw
  history and compares them with the runner summary.
- KASAN and KCSAN configurations enable hung-task detection with a 120-second
  timeout. Both the guest gate and analyzer recognize the standard
  `INFO: task ... blocked for more than` headline.
- Internal KVM capture requires a matching, still-running run without completion
  or failure metadata or prior launcher output. The target-lifetime protocol
  additionally requires an empty boot directory. Failure marking repeats the
  mutable-run predicate.
- Preflight and formal duration, reader, minimum-progress, lifecycle, repetition,
  and timeout values are exact Make gates. Formal analysis also checks the root
  matrix and every boot's raw run configuration against the frozen protocol.

During repair, inspection found an additional raw-record defect: a successful
`OPEN` passed `result`, device, and inode arguments to the history emitter in the
wrong positions. The corrected response records the selected device/inode and
zero result after descriptor and object-identity validation. A fork-shared
operation sequence also prevents duplicate IDs across cells.

## Host Evidence

- C build passes `-Wall -Wextra -Werror` and GCC `-fanalyzer`.
- Twenty-three analyzer tests pass. The exact single-writer checker still matches
  exhaustive search for all 12,100 frozen two-update/two-reader histories.
- Effective normal, KASAN, and KCSAN configurations pass the analyzer's exact
  feature checks.
- Negative Make checks show that completed result roots and nonempty boot roots
  are rejected without mutation, while a controlled launch failure marks only a
  still-running root.
- Python bytecode compilation and `git diff --check` pass.

## First Follow-Up Verdict

The same independent reviewer returned a second `NO-GO`. The original event
ordering, lifecycle-step, fork-shared failure, result-capture, and frozen-scale
findings were closed, but six remaining defects prevented KVM admission:

1. the generic dmesg `lockdep` expression also matched the clean informational
   boot line `RCU lockdep checking is enabled`;
2. `used_watchpoints` was treated as cumulative even though it is a live KCSAN
   gauge;
3. the controlled `RESOLVE_CACHED` probe ran before concurrent retirement and
   therefore did not prove RCU target borrowing during replacement or clear;
4. successful `OPEN` responses were emitted only after yield, content,
   directory, and repeated-fstat checks, making the recorded selection interval
   wider than the actual `openat()` operation;
5. the controlled proof emitted expected target identity in place of separately
   observed identity; and
6. aggregation, formal-analysis, or completion failure after run start could
   leave a mutable `running` root.

## Second Follow-Up Repairs

- The dmesg classifier now lists precise diagnostic headlines and accepts the
  informational RCU-lockdep enablement line. A regression test covers it.
- KCSAN engagement requires a positive cumulative `setup_watchpoints` delta;
  `used_watchpoints` is captured and checked as a nonnegative live gauge. A
  zero-to-zero gauge regression test passes.
- The controlled proof now records expected and observed device/inode
  independently. A separate raw `target-lifetime-open-return` event records the
  exact boundary immediately after `openat()` and supplies the linearizability
  interval endpoint; the later response carries object identity. Descriptor
  content and repeated-stat checks remain separate raw evidence.
- Each running publication cell now enables a filtered dynamic kprobe and uses
  trace-marker begin/end records immediately around the target register or
  clear syscall. The cross-CPU atomic-counter ftrace stream is preserved as a
  raw text file.
  The analyzer reparses that file and requires an `rcu_walk=true` event inside a
  complete marker window whose writer sequence exists in paired operation
  history. It also reconciles all emitted marker, branch, and summary records
  against the raw trace and rejects trace-buffer loss.
- The writer now executes `SET(new) -> SET(replacement) -> CLEAR(retirement)`;
  the analyzer requires independently raw-backed RCU overlap in both the
  replacement and retirement windows. This closes a local audit finding that
  the earlier alternating `SET -> CLEAR` sequence never entered
  `hlist_replace_rcu()`.
- Post-start host stages explicitly capture subshell status and mark a
  still-running root failed. A failure-injection test caught and repaired a Bash
  `set -e` suppression bug caused by placing a subshell on the left side of
  `||`; the corrected matrix stops at a missing image before boot-root creation
  and records `host-boot-matrix`.

## Second Follow-Up Verdict

The same independent reviewer returned a third `NO-GO`. Six earlier findings
were closed, but two P1 evidence defects remained:

1. the case-insensitive `KCSAN:` dmesg expression classified normal
   `kcsan: enabled early` and `kcsan: strict mode configured` startup messages as
   diagnostics, so every clean KCSAN boot would fail; and
2. writer markers bracketed target-path open, command formatting, the control
   write, and cleanup. A successful RCU resolve between the begin marker and the
   actual control syscall could therefore be misclassified as concurrent with
   update. A local audit also found that an entry-only resolve probe could count
   an RCU lookup that later returned `ENOENT` during clear.

## Third Follow-Up Repairs

- The dmesg classifier no longer treats arbitrary `KCSAN:` text as a report.
  The existing `BUG:` diagnostic prefix still catches real KCSAN race reports.
  Separate regressions accept both normal startup lines and reject a
  `BUG: KCSAN: data-race` headline attributed to `namei_ext`.
- Target-path open and command formatting now finish before the writer emits its
  begin marker. More importantly, markers only associate `writer_seq` with the
  operation; they no longer define concurrency. Dynamic entry/return probes on
  `namei_ext_register_target_write()` define the exact in-kernel control-write
  interval.
- `namei_ext_resolve_target()` now uses a return probe that captures both
  `rcu_walk` and the function result. Only a `rcu_walk=true`, zero-return event
  between the update function's entry and return counts as concurrent target
  resolution. Failed target lookup does not satisfy the oracle.
- Raw parsing requires the sequence marker-begin, kernel-update-enter,
  zero or more resolve returns, kernel-update-return, marker-end for every traced
  update. Emitted update, resolve, marker, and summary JSONL records are
  reconciled with that raw sequence.
- New negative controls reject a successful resolve in the marker-to-kernel
  gap and a failed resolve inside the kernel update interval. The analyzer now
  has 27 tests; all pass, including the unchanged exhaustive 12,100-history
  cross-check.

## Third Follow-Up Verdict

The reviewer confirmed that clean KCSAN classification, kretprobe syntax,
successful-return filtering, marker-gap rejection, and separate replacement and
clear requirements were closed. It found one new P1 shutdown race. The short
trace stops after 0.25--2 seconds while the writer continues for the full cell.
After the stop path disabled marker generation but before it wrote
`tracing_on=0`, a writer could start an unmarked control write. Its kernel
update event would remain in the trace and make an otherwise valid run fail.

## Fourth Follow-Up Repair

- A publication-cell mutex now serializes each writer control operation with
  trace shutdown. The writer holds it while reading marker state and executing
  the complete marked or unmarked control operation.
- The stop path acquires the same mutex, waits for any marked update to finish,
  stops tracing, disables and removes all three dynamic events, closes the
  marker descriptor, and only then releases the writer. A later writer can
  execute only after update probes are inactive.
- If stopping tracing fails, the stop path sets the cell abort flag while still
  holding the mutex. A writer rechecks that flag after acquiring the mutex, so
  it cannot enter an unmarked update before event cleanup.
- The repaired C runner again passes `-Wall -Wextra -Werror` and GCC
  `-fanalyzer`; all 27 analyzer tests and `git diff --check` pass.

## Fourth Follow-Up Verdict

The same independent reviewer found no unresolved P0, P1, or P2 issue and
returned `GO for commit/build and real KVM preflight`. It confirmed that the
shared publication-cell mutex closes the shutdown window: an update already
holding the mutex finishes with markers before shutdown, while an update that
acquires it after shutdown sees the trace events inactive. If stopping tracing
fails, the abort flag is published while the mutex remains held and the writer
rechecks it after acquiring that mutex.

This verdict admits the implementation to build and preflight only. The
reviewer did not build the debug images or run KVM, and this document therefore
makes no runtime, sanitizer, race-freedom, or formal-result claim.
