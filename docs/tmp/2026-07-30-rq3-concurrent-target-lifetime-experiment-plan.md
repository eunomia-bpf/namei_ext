# Experiment Plan: RQ3 Concurrent Target Lifetime

## Research Question

- RQ exactly as written in the paper: Does `namei_ext` provide a narrower
  verifier-bounded, fail-closed ownership boundary than building a custom or
  stackable filesystem when the needed policy is only name resolution?
- Specific uncertainty tested here: whether the RCU-borrowed registered-target
  design remains memory-safe and exposes one atomic existing-object selection
  under concurrent replace, clear, register, rename, unlink, and lookup, while
  already-open file and directory descriptors retain ordinary VFS behavior.
- Why the answer matters: a narrow interface is not credible if avoiding
  filesystem ownership moves use-after-free, data-race, stale-selection, or
  descriptor-semantics bugs into VFS name resolution.

## Paper-Value Admission

- Planned role: decisive mechanism evidence for RQ3.
- Largest credible paper story this experiment could unlock: `namei_ext` is not
  merely another eBPF callback; it safely hands a policy-selected existing
  object back to an in-progress VFS walk under concurrent publication and
  retirement, without moving ordinary file and directory operations into the
  policy.
- Strongest reviewer reject argument or load-bearing uncertainty addressed:
  the cache-hot RQ2 result depends on borrowing registered `struct path`
  objects in RCU-walk, but the current functional test performs only 128 file
  and directory replacements on a normal kernel. That is too shallow to support
  the target-lifetime and containment claim.
- Independent evidence added beyond existing runs and published results:
  operation histories for replace/clear/register and lookup, old-descriptor
  continuation across updates, pinned-object unlink/rename cases, and repeated
  execution under KASAN, KCSAN, lockdep, and PROVE_RCU.
- Why the result is not tautological, already settled, or dominated: code review
  and a 128-update functional test cannot detect all sampled data races,
  use-after-free paths, or history violations. Linux's sanitizers and an
  operation-history checker test distinct failure modes in the actual modified
  kernel.
- Paper decision if positive: make safe continuation from policy selection back
  into ordinary namei a central design result, scoped to the tested operations,
  debug configurations, and concurrency.
- Paper decision if contradictory, mixed, or inconclusive: preserve the failure
  outside the paper, repair the target registry or namei continuation, and rerun
  this unchanged experiment before retaining the RCU-lifetime claim.
- Best alternative experiment and why this one has higher decision value:
  another RQ1 workflow would add little beyond five reviewed workflows. A
  second Wrapfs workload would repeat the same ownership surface. YoloFS is
  source-backed but owns staging, journaling, snapshots, permissions, and
  commit/abort, so reducing it to this narrow oracle would not be a fair matched
  baseline. Reopening mdtest would add metadata breadth but would not answer the
  central safety objection.

## Expected And Alternative Outcomes

- Current expected answer: completed lookups observe exactly one registered
  object or the declared absent state; an update acknowledged before a lookup
  begins determines that lookup unless a later update overlaps it; old
  descriptors retain their original object; debug kernels report no
  namei_ext-related memory, race, locking, or RCU defect.
- Strongest competing explanation: the RCU reader can outlive a retired target,
  observe an impossible state across clear/register, or resume VFS completion
  with stale dentry or mount state; the current short test simply misses the
  interleaving.
- Result that would contradict the expectation: any non-linearizable history,
  unexpected errno or object identity, changed old descriptor, corrupted lower
  object, sanitizer report, lockdep report, RCU warning, kernel fault, or hang.

## Published Precedent And Real Assets

- Closest published protocol: Herlihy and Wing's linearizability condition is
  used for the registered target ID as a concurrent object whose state is one
  existing VFS object or absent.
- Official system and tools: the project Linux 7.1 modified kernel; Linux
  Generic KASAN, KCSAN in strict mode, lockdep, and PROVE_RCU as documented in
  the same kernel source; the real `cgroup/namei_ext` BPF attach path.
- What is reused: the current `SELECT_TARGET` policy, runner library, target
  registration ABI, KVM launcher, ext4 lower filesystem, and the already
  reviewed Wrapfs RQ3 result at
  `results/experiments/agent-workspace-rq3-formal/20260728-rq3-formal-v3/`.
  That run used project commit
  `1f5d0c9d699163cd70284dd21a4da6dbf02803bc`, kernel commit
  `1e81d4793c78b7667d0798248c70c0b15a2c3877`, and official Wrapfs commit
  `464802c8fd1a25413b295161c9bb9a4ce7bfa33b`; both mechanisms passed the
  same 37-row oracle. The Wrapfs experiment is not rerun.
- Current-kernel control: the current kernel commit is
  `621aff8d1bb52fad718f11fd882c956d6a5686ae`. Its only change after the
  reviewed RQ3 kernel adds final regular-file selection by modifying shared
  selected-target validation and continuation in `fs/namei.c` and target
  admission in `fs/namei_ext.c`. Because those files can affect the matched
  semantics, every formal debug-kernel boot reruns the current `namei_ext`
  side of the existing 37-row contract. This is a regression control, not a
  new baseline or a new paper result. The prior Wrapfs result remains fixed,
  and boot counts are never compared.
- Necessary custom glue: one C stress workload that records raw operation
  histories, one offline history checker, two committed debug-kernel config
  fragments, and Make targets for build, KVM execution, and analysis.

## Comparison

- Proposed system: the current RCU-borrowed `namei_ext` registered-target
  implementation.
- Main baseline: the existing matched Wrapfs-derived RQ3 result remains the
  ownership comparator. No new baseline run is needed because Wrapfs does not
  share the registered-target lifetime mechanism and repeating its 37-row
  oracle cannot validate this mechanism.
- Controls: direct reads and metadata observations of every lower target before
  and after stress; unattached and cleared-target lookups; old file and
  directory descriptors held across acknowledged updates; and the current
  `namei_ext` side of the existing 37-row semantic contract.
- Conclusion if the current 37-row control fails: the prior matched ownership
  comparison no longer supports the current kernel. Repair and rerun the
  current `namei_ext` control before interpreting the new lifetime result;
  do not rerun or reinterpret Wrapfs merely to increase repetition count.
- Fairness: no throughput or superiority claim is made. Debug-kernel conditions
  are correctness instruments, not performance baselines.

## Workloads And Metrics

- Three independent cells use separate cgroups, policy attachments, and target
  registries. `clear` removes every target for its cgroup, so sharing a cgroup
  would couple otherwise independent histories.
- Final-file publication cell: one serial writer repeats `SET(new)`,
  `SET(replacement)`, and `CLEAR` for one target ID using uniquely identifiable
  existing regular files. Readers
  invoke `openat()` on one logical pathname. On success they immediately record
  the returned descriptor's device and inode; on absence they record the exact
  errno. Subsequent `read()` and `fstat()` validate descriptor stability but
  are not separate target-state operations.
- Directory publication cell: one serial writer repeats the same new,
  replacement, and clear sequence over uniquely identifiable nonempty
  directories. Readers use the logical directory as an intermediate
  component in multi-component `openat()` and also open it as a directory.
  Each logical `openat()` is a selection operation. Reads of the child and
  `readdir()` on the already-open directory descriptor validate ordinary
  descriptor behavior and do not re-enter the target-state history.
- Pinned-object lifecycle cell: a registered regular file is renamed and then
  unlinked, and a nonempty registered directory is renamed. Registration holds
  the object selectable across those physical namespace changes until an
  acknowledged `CLEAR` or `SET`. After `CLEAR`, a new logical lookup must be
  absent, while file and directory descriptors opened before the transition
  remain usable. Physical-object checks after unlink use descriptors opened
  before unlink, never the removed pathname.
- Primary metrics: operation-history validity; exact counts of successful,
  absent, and overlap reads; old-descriptor object and byte stability; completed
  update and lookup counts; zero relevant KASAN, KCSAN, lockdep, PROVE_RCU,
  warning, fault, or hang reports.
- Selection operation and raw history: every `SET`, `CLEAR`, and reader
  `openat()` records separate invocation and response events with operation ID,
  process or thread, monotonic timestamp, result, device/inode, exact payload
  class, and errno. `SET` and `CLEAR` are issued by one writer, so their order
  is fixed. A successful `openat()` linearizes to the registered object whose
  device/inode it returns; a declared absence linearizes to the absent state.
- Concurrent RCU engagement is a separate raw ftrace oracle. Writer markers
  associate one history `writer_seq` with the control write, while dynamic
  entry/return probes on `namei_ext_register_target_write()` define the actual
  in-kernel update interval. A return probe on `namei_ext_resolve_target()`
  captures both `rcu_walk` and its result. Only a zero-returning RCU resolve
  inside the kernel update interval counts; a resolve in the marker-to-kernel
  gap or a failed resolve during clear does not.
- Writer control operations and trace shutdown share a mutex. Shutdown waits
  for an active marked write, stops tracing and removes update probes while
  holding that mutex, then allows the writer to continue untraced. An unmarked
  update cannot enter the bounded raw trace during shutdown.
- Global correctness model: the checker must find one global sequential history
  for all completed `SET`, `CLEAR`, and `openat()` operations that preserves
  the serial writer order, preserves real-time order whenever one operation
  responds before another is invoked, and implements the sequential register
  states exactly. It cannot validate each read independently against one
  overlapping update interval. The checker uses the single-writer structure to
  assign each read a legal position in the ordered update sequence and rejects
  the history if no nondecreasing assignment respecting all completed-before
  constraints exists.
- Checker tests include valid overlap histories and at least these invalid
  controls: an old object returned after `CLEAR` responds and before the next
  `SET` begins; object A returned after `SET(B)` responds with no overlapping
  update; and a history in which one long `SET(B)` overlaps a completed read
  of B followed in real time by a read of A. The last history makes both reads
  independently overlap-valid but has no global legal order.
- Lower-object oracle: exact expected bytes and stat metadata are read directly
  from every target after stress; no content checksum is used.
- Preflight scale: one boot for each kernel configuration, two readers, five
  seconds for each concurrent publication cell, at least eight completed
  updates and 64 completed opens per reader, and four pinned-object lifecycle
  cycles. Each boot has a three-minute timeout.
- Formal scale: three fresh boots for each kernel configuration, four readers,
  60 seconds for each concurrent publication cell, at least 256 completed
  updates and 2,000 completed opens per reader, and 64 pinned-object lifecycle
  cycles per boot. Each boot has an eight-minute timeout. Fixed duration avoids
  requiring tens of thousands of `synchronize_rcu()` calls under KCSAN; minimum
  counts prevent an idle or stalled run from passing.
- Cost estimate: two debug-kernel builds plus nine formal KVM boots; expected
  host disk use is below 25 GiB and execution is expected to fit within one
  working session.

## Kernel Configurations And Diagnostic Rules

- Normal uses the committed Phase 1 configuration.
- KASAN uses an independent build root and image with Generic KASAN,
  `KASAN_VMALLOC`, lockdep, `PROVE_LOCKING`, `DEBUG_LOCK_ALLOC`, `PROVE_RCU`,
  and `PROVE_RCU_LIST`.
- KCSAN uses a third independent build root and image with `CONFIG_KASAN=n`,
  strict KCSAN, weak-memory modeling, unknown-origin reports, lockdep,
  `PROVE_LOCKING`, `DEBUG_LOCK_ALLOC`, `PROVE_RCU`, and `PROVE_RCU_LIST`.
  Sampling is frozen at 64 watchpoints, 80 microseconds task delay, 20
  microseconds interrupt delay, one watchpoint attempt per 1,000 instrumented
  accesses, no delay or skip randomization, and no report-rate interval.
- Every KCSAN boot records the complete `/sys/kernel/debug/kcsan` counters
  before and after the stress. The cumulative `setup_watchpoints` count must
  increase; `used_watchpoints` is a live gauge and need only remain nonnegative.
  A boot without setup-watchpoint engagement is inconclusive, not a clean pass.
- Diagnostic attribution is fixed before execution. Any KASAN, KCSAN, lockdep,
  RCU, warning, fault, or hung-task report that names `fs/namei_ext.c`, the
  registered-target functions, `namei_ext_apply_target()`, or a reader/writer
  syscall stack from this experiment is a negative result. Any other kernel
  sanitizer, lockdep, RCU, warning, fault, or hung-task report makes that boot
  inconclusive and cannot count as a clean pass. Every boot preserves complete
  unfiltered dmesg; filtered excerpts are diagnostic aids only.

## Planned Runs

| Run group | Role | Workload | Kernel | Repetitions | Decision consequence |
| --- | --- | --- | --- | ---: | --- |
| preflight | real path | all three lifetime cells at reduced duration | normal, KASAN, KCSAN | 1 each | establishes that the actual debug kernels, attach path, history, descriptor checks, and KCSAN counters run |
| formal-normal | proposed | all three lifetime cells plus current 37-row namei control | normal Phase 1 | 3 boots | validates the production-config mechanism history |
| formal-kasan | correctness instrumentation | same cells and control | Generic KASAN, lockdep, PROVE_RCU | 3 boots | tests use-after-free, invalid access, lock, and RCU failures |
| formal-kcsan | correctness instrumentation | same cells and control | strict KCSAN, weak-memory modeling, lockdep, PROVE_RCU | 3 boots | tests data races and weak-memory-sensitive publication failures |

## Execution

- Authoritative preflight command:
  `make kvm-namei-ext-target-lifetime-preflight RUN_ID=<fresh-id>`.
- Authoritative formal command:
  `make experiment-namei-ext-target-lifetime RUN_ID=<fresh-id>`.
- Real preflight case: all three cells execute through the modified-kernel
  `cgroup/namei_ext` attach path once under each actual kernel image.
- Full completion rule: all nine fresh formal boots reach terminal success; all
  minimum operation counts are present; every global history passes; all direct
  lower-object and descriptor checks pass; the current `namei_ext` 37-row
  control passes in every boot; each captured config contains its declared
  debug options; every KCSAN boot demonstrates watchpoint engagement; and no
  kernel diagnostic makes a boot negative or inconclusive.
- Raw-result paths:
  `results/experiments/namei-ext-target-lifetime-preflight/<run-id>/` and
  `results/experiments/namei-ext-target-lifetime/<run-id>/`.
- Recovery: each boot writes its raw history and dmesg before analysis. A failed
  boot remains a failed result; formal analysis does not silently omit it.

## Interpretation

- Positive result: all three configurations satisfy the same history and VFS
  continuation oracle in all boots with no kernel diagnostic, and the current
  kernel retains the 37-row namei contract used in the earlier matched Wrapfs
  comparison.
- Negative result: any validly engaged cell violates the history, descriptor,
  lower-object, or kernel-debug oracle.
- Mixed or inconclusive result: missing operations, a debug kernel that did not
  enable its declared instrumentation, infrastructure failure before
  attachment, or incomplete formal boots.
- Target paper artifact: one compact construction-validation table reporting
  kernel configuration, boots, update/lookups completed, history violations,
  descriptor violations, and kernel diagnostic count. It is not a performance
  figure.

## Reproducibility Notes

- Kernel source is the committed project submodule revision used by the run.
- The normal, KASAN, and KCSAN config fragments, fixed durations, minimum
  operation counts, and timeouts are committed inputs.
- The workload serializes a shared event sequence as authoritative history
  order. Monotonic raw timestamps are retained as observations, not used to
  break equal-time boundaries or support latency or throughput claims.
- This experiment does not claim formal proof, all possible interleavings,
  general filesystem safety, or behavior outside the registered-existing-object
  boundary.
