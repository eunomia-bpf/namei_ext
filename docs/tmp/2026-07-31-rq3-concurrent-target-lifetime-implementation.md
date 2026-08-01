# RQ3 Concurrent Registered-Target Lifetime Implementation

## Motivation

The central `namei_ext` construction claim is not that Linux can call a BPF
program from pathname lookup. It is that a policy-selected existing VFS object
can be published, borrowed during RCU-walk, converted into an owned path, and
returned to ordinary VFS completion without transferring filesystem ownership.
The earlier 128-replacement check observed complete payloads, but did not record
a global operation history, target retirement, pinned-object namespace changes,
or debug-kernel race and lifetime evidence. This experiment implements the
reviewed plan in
`docs/tmp/2026-07-30-rq3-concurrent-target-lifetime-experiment-plan.md`.

This document records implementation state only. No KVM result or paper claim
is established until preflight, formal execution, and independent result review
complete.

## Code Paths Inspected

- `kernel/fs/namei_ext.c`: target registration, atomic replacement, clear,
  RCU lookup, and target resolution;
- `kernel/fs/namei.c`: selected-target installation and RCU-to-ref-walk
  legitimization;
- `runner/src/namei_ext_harness.c`: real `cgroup/namei_ext` attach, exact-parent
  scope, target clear, and teardown paths;
- `experiments/agent_workspace/namei_ext_agent_workspace.c`: the current
  37-row `namei_ext` semantic control reused in every formal boot;
- `mk/kvm.mk` and `mk/results.mk`: KVM launch, failure propagation, source-state
  gate, and raw-result lifecycle; and
- `kernel/kernel/kcsan/debugfs.c`: KCSAN counter names and engagement evidence.

## Implemented Workload

`experiments/namei_ext_target_lifetime/namei_ext_target_lifetime.c` implements
three independent cells. Each cell has its own cgroup, BPF attachment, exact
managed parent, and registered-target namespace because `clear` retires all
targets for one cgroup.

1. `final-file` alternates one target ID among 16 existing regular files and an
   absent state while reader threads open one logical final-component path.
2. `directory` alternates one target ID among 16 existing directories. Readers
   use the selected directory both as an intermediate component and as an opened
   directory whose existing child is read and enumerated.
3. `pinned-object` registers a regular file, renames and unlinks its physical
   name, and verifies that the registered object remains selectable until
   `CLEAR`. It separately renames a nonempty directory. New logical opens become
   absent after clear, while descriptors opened before the transition retain
   their original object and contents.

The publication cells use one serial writer with a repeating
`SET(new) -> SET(replacement) -> CLEAR(retirement)` sequence and a fixed
duration with minimum completed update and per-reader open counts. Every reader
must observe both at least one registered target and the absent state. The
writer always issues a final clear. Directory enumeration uses a new file
description opened relative
to the held directory descriptor so a check cannot consume the descriptor's
shared directory offset and invalidate a later old-descriptor check.

## Raw Evidence Contract

The runner writes JSONL observations before interpretation:

- `target-lifetime-target` defines each state's target and child device, inode,
  mode, owner, group, and size;
- `target-lifetime-history` records separate invocation and response events for
  every `SET`, `CLEAR`, and `openat()`, including operation ID, actor, writer
  sequence, monotonic timestamp, result, state, device, and inode;
- `target-lifetime-open-return` records the exact serialized boundary
  immediately after each `openat()` syscall. The later history response carries
  the device/inode classification obtained by `fstat()` but does not widen the
  selection interval used for real-time ordering;
- `target-lifetime-rcu-branch` records dynamic-kretprobe observations of both
  the `rcu_walk` argument and return value of `namei_ext_resolve_target()`. A
  controlled, PID-filtered `RESOLVE_CACHED` open must return successfully and
  establish the selected object identity. In the concurrent trace, kprobe and
  kretprobe events on `namei_ext_register_target_write()` define the exact
  in-kernel update interval. Writer `trace_marker` records associate that
  interval with the paired history `writer_seq`; they are not themselves
  treated as the update interval;
- per-cell `controlled-rcu-trace.txt` and `concurrent-rcu-trace.txt` files
  preserve both raw ftrace streams before interpretation.
  `target-lifetime-rcu-marker`, `target-lifetime-rcu-update`, and
  `target-lifetime-rcu-stress` expose the parsed marker order, kernel update
  entry/return sequence, successful and failed RCU returns, and engagement
  counts;
- `target-lifetime-descriptor` records read/readdir and repeated-fstat stability
  on the already opened descriptor;
- `target-lifetime-lifecycle-step` records exact rename, unlink, clear,
  post-transition logical-open, and held-descriptor results, including expected
  and observed identity for held objects;
- `target-lifetime-lower-object` records direct post-stress bytes and metadata
  checks for every publication target and directory child;
- `target-lifetime-cleanup` separately records target clear, scope clear, policy
  detach, cgroup removal, and work-tree removal for each cell;
- reader, lifecycle, cell, and run summaries enforce minimum engagement and
  expose the runner's controlling return state.

No checksum is produced or used. File contents are read and compared directly.
Event sequence numbers, operation sequence numbers, and the controlling failure
counter live in shared anonymous memory, so a child that has entered the policy
cgroup cannot lose an output or validation failure through fork copy-on-write.
Invocation, update-response, and `openat()`-return boundaries are assigned while
serializing the raw event. Event sequence is therefore the history order, while
the monotonic timestamp is retained as an observation rather than used to break
equal-time ties.

A publication-cell mutex serializes writer control operations with trace
shutdown. Shutdown waits for any marked update, stops tracing, disables and
removes the dynamic events, closes the marker descriptor, and only then releases
the writer. Therefore the captured trace cannot contain an unmarked update from
the interval between disabling markers and disabling tracing.

## Offline Correctness Check

`analysis/namei_ext_target_lifetime/analyze.py` pairs invocation and response
events, verifies the writer sequence, and checks one global linearization for
the single-writer register. Each completed `openat()` is assigned a position in
the ordered `SET`/`CLEAR` sequence that preserves completed-before real-time
order and returns exactly the object or absence at that position. The greedy
earliest-position assignment is exact for this single-writer register because
an earlier legal assignment only relaxes the lower bound imposed on later
reads.

The analyzer independently ties every `SET` and successful `OPEN` state to the
device/inode in its target definition. It rejects absent opens with object
identity, undefined states, unexpected errno, duplicate or incomplete history,
missing reader engagement, descriptor failures, missing lower-object coverage,
or any bytes or metadata mismatch.

Every publication reader must have at least one `OPEN` whose interval overlaps a
`SET` or `CLEAR`. Reader summaries are independently recomputed from paired
history. The analyzer separately requires (1) a successful controlled
`RESOLVE_CACHED` open whose observed identity matches its registered target and
(2) a zero-returning `rcu_walk=true` target resolution ordered after the
in-kernel `namei_ext_register_target_write()` entry and before its return. Both
a replacement `SET` and a retiring `CLEAR` must contain such a successful
return. A resolve between the writer marker and kernel entry, or an in-window
resolve returning `ENOENT`, does not count. The analyzer independently reparses
the raw ftrace file, rejects overwritten trace buffers or incomplete
marker/kernel windows, and reconciles every marker, update event, resolve
return, writer sequence, and summary count with the JSONL history.

Twenty-seven focused checker tests cover a valid overlap, stale return after clear, old
object after replacement, a locally overlap-valid but globally impossible
history, unexpected errno, state/object-identity mismatch, and lower-object
metadata mismatch, a positive KCSAN data-race counter delta even when
watchpoints engaged, and a `pass=true` reader summary below the declared
operation minimum. They also cover the KCSAN live-gauge semantics, distinguish
informational RCU-lockdep and KCSAN startup lines from diagnostics, and retain a
real KCSAN data-race headline as a failure. They accept successful raw-backed
RCU returns inside replacement and retirement kernel intervals, and reject a
return outside the interval, between marker and kernel entry, with a failed
return value, or in a trace that misses either update class. Another control
rejects an `OPEN` history without its exact syscall-return boundary.
Additional controls reject a history without actual
update/read overlap and a reader summary not backed by paired history, and show
that event sequence preserves boundary order when timestamps are equal. They
also reject an RCU summary without a raw branch event and a lifecycle aggregate
without step evidence. Another test rejects a successful open that lacks its corresponding
descriptor-stability record. The exhaustive test enumerates 12,100 deterministic
two-update/two-reader interval
and state combinations and compares the greedy checker with exhaustive
permutation search; the two decisions agree for the complete test family.

## Kernel Instrumentation

- `configs/kernel/x86_64_phase1_kasan.config` enables Generic KASAN,
  `KASAN_VMALLOC`, lockdep, `PROVE_RCU`, and `PROVE_RCU_LIST` in an independent
  build root.
- `configs/kernel/x86_64_phase1_kcsan.config` disables KASAN and enables strict
  KCSAN, weak-memory modeling, unknown-origin reports, fixed watchpoint and
  delay parameters, lockdep, `PROVE_RCU`, and `PROVE_RCU_LIST` in a third build
  root.
- Both debug kernels enable hung-task detection with a frozen 120-second
  timeout. All three kernel kinds require tracing and dynamic kprobe events for
  the bounded RCU-branch probe.
- Each KCSAN boot captures complete debugfs counters before and after the
  workload. The cumulative setup-watchpoint count must increase, the live
  used-watchpoint gauge must remain nonnegative, and the data-race counter must
  not increase.
- Every boot retains complete dmesg. A diagnostic attributed to `namei_ext` or
  this experiment is negative; any other sanitizer, lockdep, RCU, warning,
  fault, or hung-task report is inconclusive and cannot count as a pass.

## Make And KVM Integration

`mk/experiments/namei_ext_target_lifetime.mk` owns build, debug-kernel, KVM
preflight, formal, guest, and analysis entrypoints. The formal matrix is three
fresh boots each for normal, KASAN, and KCSAN. Every formal boot reruns only the
current `namei_ext` side of the established 37-row Agent workspace contract.
The prior Wrapfs result remains the fixed ownership comparator and is not
rerun.

The control dependency uses the new `namei-only` target in
`experiments/agent_workspace/Makefile`. It therefore builds only the current
namei runner and does not enter the legacy FUSE download or checksum path.
Preflight and formal targets require clean project and kernel worktrees before
creating a fresh immutable result root.
The internal KVM capture entrypoint independently rejects a run that is not
still `running`, has completion or failure metadata, or already has launcher
outputs. This experiment additionally requires each new boot root to be empty.
Failure marking repeats the mutable-run check. Preflight and formal scales
and timeouts are exact protocol constants, so command-line overrides fail before
result-root creation. Any post-start host failure in the boot matrix,
aggregation, formal analysis, or completion marks a still-running root failed;
an already failed or completed root is not rewritten.

## Alternatives Rejected

- Per-read overlap checks were rejected because they can accept a set of reads
  with no global legal history.
- A shared cgroup was rejected because one cell's clear would retire another
  cell's targets.
- Treating read, fstat, and readdir as separate publication operations was
  rejected. `openat()` selects the object; later descriptor operations test VFS
  continuation and descriptor stability.
- A fixed large update count was rejected because every replacement waits for
  an RCU grace period and would make strict-KCSAN completion uncertain. Fixed
  duration plus minimum progress detects both idle and stalled runs.
- Repeating Wrapfs was rejected because it cannot validate the registered-path
  RCU lifetime mechanism and would add a baseline without new evidence value.

## Host Validation Performed

- the C runner builds with `-Wall -Wextra -Werror`;
- the runner also builds under GCC `-fanalyzer` with no finding;
- all twenty-seven analyzer tests pass, including the 12,100-history exhaustive
  checker cross-check;
- the analyzer accepts the effective normal, KASAN, and KCSAN build-tree
  configurations;
- the namei-only current-control target builds without invoking FUSE setup;
- direct negative checks confirm that internal KVM capture does not mutate a
  completed root, that this experiment rejects a nonempty boot root, and that
  failure is marked only while the run is still mutable. A separate host-stage
  injection confirms that a missing image stops the matrix before creating a
  boot directory and marks the root with `host-boot-matrix`;
- `git diff --check` passes.

## Remaining Risks And Next Gate

Host validation cannot execute the modified-kernel attach path. The next gate is
one fresh normal, KASAN, and KCSAN KVM preflight using
`make kvm-namei-ext-target-lifetime-preflight RUN_ID=<fresh-id>`. The same
independent reviewer re-checked the repaired plan-to-code mapping, checker
soundness, raw evidence fields, Make failure propagation, and debug-kernel
engagement rules and returned `GO for commit/build and real KVM preflight` with
no unresolved P0, P1, or P2 finding. A failed or incomplete preflight root
remains immutable; any repair uses a new run ID.
