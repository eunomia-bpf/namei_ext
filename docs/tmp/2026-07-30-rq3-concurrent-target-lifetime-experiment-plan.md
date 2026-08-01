# Experiment Plan: RQ3 Concurrent Target Lifetime

## Bounded-History Correction (2026-07-31)

Preflight07 invalidated the plan's combination of fixed-duration execution and
per-operation history. On local ext4, the first five-second publication cell
produced 2,241,443 JSONL records (457 MiB). The ftrace ring retained 94,519 of
137,000 entries, one JSON record was truncated, and the runner reported 426
evidence-emission failures. The deterministic final-file litmus passed, but the
run stopped before the directory cell and before KASAN or KCSAN. The immutable
root is
`results/experiments/namei-ext-target-lifetime-preflight/20260801T061550Z-target-lifetime-preflight07/`;
it is an infrastructure-invalid preflight, not mechanism evidence.

The corrected protocol separates two evidence roles within each attached
publication cell:

1. The authoritative linearizability history is a finite operation matrix.
   The writer completes exactly the configured target update count, and each
   reader completes at least the configured target open count while observing
   both a selected object and absence. A fixed upper bound of target opens plus
   target updates plus 16 operations prevents an unbounded wait for both state
   classes. The configured time is a hard success deadline for this matrix,
   never a success condition: completion at or after the deadline fails even
   when the quotas are eventually met. Every update and open keeps its
   invocation, syscall return, response, identity, and descriptor records.
2. A supplemental sanitizer stress phase runs the same object checks for the
   configured duration but records aggregate successful, absent, and unexpected
   result counts. Every open still validates inode identity, payload, and
   descriptor stability; every unexpected result gets its own raw failure
   record. This phase supports sanitizer exposure only. It does not replace or
   enlarge the bounded history's linearizability claim.

The raw ftrace stream covers only the finite history matrix. The offline
analyzer derives marker, update, and RCU-branch counts directly from that raw
stream; the collector no longer duplicates every ftrace row into JSONL. Any
JSON write, ftrace loss, malformed trace, timeout, operation error, descriptor
error, or summary-write failure makes the cell fail. This section supersedes
the later statements that every operation in a fixed-duration stress run is
written to the history and that fixed duration is itself the publication-cell
completion rule. A failed cell stops later cells, and a failed runner prevents
the formal Agent-workspace regression control from starting; only failure
artifacts and cleanup continue.

## Selection-Coverage Correction (2026-07-31)

Preflight08 completed the bounded runner on the normal kernel, but the offline
analyzer rejected the final-file history because both readers observed only
one selected target state plus absence. The writer had executed five distinct
`SET` states, so selection breadth depended on scheduling rather than a runner
gate. The immutable failure and raw counts are recorded in
`docs/tmp/2026-07-31-rq3-target-lifetime-preflight08-selection-coverage-failure.md`.

After each of the first two `SET` operations and the first `CLEAR`, the writer
publishes a generation and the exact expected target identity or absent state.
Each reader performs one complete open and descriptor validation for that
generation, acknowledges only that generation, and then waits. The writer
cannot advance until every reader acknowledges. It then invokes the fourth
update, arms a separate rendezvous before entering the control write, and waits
for one complete absent open from every reader. Those opens therefore overlap
the update's recorded invocation/response interval; after acknowledging, the
readers immediately enter the original continuous bounded history. Reader
summaries record the distinct selected-state count, and the analyzer recomputes
it from paired history. Failure to obtain these states or the overlap within
the existing operation bound or history deadline aborts the cell.

## KCSAN Weak-Memory Correction (2026-07-31)

Preflight09 passed the complete normal and KASAN boots. The KCSAN runner also
returned zero, and every semantic, lifetime, history, stress, lower-object, and
cleanup oracle passed, but the boot was negative under the frozen diagnostic
rule. KCSAN counted 248 data races during the enabled windows. The retained
dmesg starts mid-report and contains only 179 complete blocks: 178
`init_file / init_file` reports and one
`acct_account_cputime / stop_this_handle` report. The remaining 69 detections
cannot be attributed. Although no retained headline names a `namei_ext` kernel
function, the stacks include the experiment reader/writer process and thus
meet the frozen negative criterion. The immutable result is recorded in
`docs/tmp/2026-07-31-rq3-target-lifetime-preflight09-kcsan-negative.md`.

The dominant retained report occurs before the extension point:
`path_openat()` calls
`alloc_empty_file()` and `init_file()` before `path_init()`, component walk,
or any `namei_ext` hook. Strict weak-memory KCSAN simulates reordering of plain
initialization writes within `init_file()` while the `SLAB_TYPESAFE_BY_RCU`
file cache rapidly reuses addresses. This mode therefore tests a broader VFS
file-allocation ordering question rather than the selected-target handoff.
This attribution motivates the next configuration; it does not reclassify
preflight09.

The KCSAN configuration remains strict and keeps the same watchpoint count,
delays, unknown-origin reporting, zero-race gate, lockdep, and PROVE_RCU, but
disables `CONFIG_KCSAN_WEAK_MEMORY`. KCSAN still samples actual conflicting
concurrent accesses. KASAN and the deterministic replacement/clear litmus
retain their separate use-after-free, RCU-borrow, grace-period, and
publication-order roles. No report filter is added, and any diagnostic in the
next workload window still makes the boot negative or inconclusive. If the
same reports remain without weak-memory modeling, this correction is refuted
and the experiment must not proceed to the formal matrix.

### Preflight10 outcome

Preflight10 used the corrected configuration and refuted this correction. Its
normal and KASAN boots produced positive analyses, and the KCSAN runner passed
all mechanism oracles, but the KCSAN windows recorded 99 data races. The
retained reports comprise 97 `init_file / init_file` blocks, one
`folio_mark_accessed / workingset_activation` block, and one
`link_path_walk / v9fs_stat2inode_dotl` block. Strict KCSAN was engaged with
247,452 setup watchpoints, no report filter, and zero assertion failures.

The complete preflight is therefore negative under the frozen diagnostic
rule. The formal nine-boot matrix will not run, and the KCSAN configuration
will not be weakened or reinterpreted again. The immutable result is recorded
in
`docs/tmp/2026-07-31-rq3-target-lifetime-preflight10-kcsan-negative.md`.

## KCSAN Measurement-Window Correction (2026-07-31)

Preflight04 showed that enabling strict KCSAN during virtme boot does not
measure the selected mechanism cleanly. The complete dmesg contained 160 KCSAN
blocks, including 9p root-filesystem, scheduler, GUP, kernfs, and virtqueue
races; none of the report headlines named a `namei_ext` function. The KCSAN
runner itself completed successfully and all four deterministic retirement
litmus cases passed, but the boot is inconclusive under the diagnostic rule
below and is not a positive result.

The corrected protocol disables `CONFIG_KCSAN_EARLY_ENABLE`. Before the
workload, the guest preserves and clears boot/setup dmesg while KCSAN is off.
The target-lifetime runner then enables KCSAN only after each cell has created
its cgroup, attached the real policy, registered its scope, and moved the child
into that cgroup; it disables KCSAN immediately after that child completes the
cell. Thus the measured windows contain the publication, lookup, retirement,
descriptor, and lifecycle operations that test this experiment, rather than
virtme boot and experiment setup.

The guest places the loop-backed ext4 image, statically linked target-lifetime
runner, BPF objects, and live raw outputs on a tmpfs rather than executing or
writing them through the virtme 9p root. It copies raw observations back to the
result root only after KCSAN is off. This removes experiment-owned runtime
dependencies on 9p during the KCSAN windows; it does not claim that an idle
virtme kernel can never perform unrelated background 9p work. No KCSAN report
whitelist or blacklist is installed. The boot/setup dmesg and workload-window
dmesg are both preserved and checked.

Every cell records its own before/after debugfs snapshots, and the boot records
the outer before/after pair. All snapshots must report KCSAN disabled and no
report filters. Each cell must have a positive setup-watchpoint delta; race and
assertion deltas must remain zero; and the sum of the three cell deltas must
equal the outer delta so no sampled interval is hidden between cells. A
workload-window diagnostic still makes the boot negative or inconclusive
according to the unchanged attribution rule below.

## Superseded RCU Oracle (2026-07-31)

The first normal-kernel preflight invalidated the probabilistic RCU oracle in
this plan. In particular, lines below that require a zero-returning resolve
during clear are historical and must not govern another run: after clear removes
the registry entry, a newly entering reader should return `ENOENT`. The raw
ftrace stream is retained only as replacement-success and clear-`ENOENT`
engagement evidence.

The authoritative lifetime oracle is now the deterministic tracing-BPF
borrower/updater litmus recorded in
`docs/tmp/2026-07-31-rq3-target-lifetime-preflight01-failure-and-deterministic-repair.md`.
It holds a reader that already borrowed the old target, begins replacement or
clear, releases that reader at the exact writer's `synchronize_rcu()` entry, and
checks old-reader completion plus the fresh replacement or absence
postcondition. The remaining workload, sanitizer, history, lower-object, and
cleanup requirements in this plan still apply.

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
- RCU-path engagement is a separate raw ftrace oracle. Writer markers
  associate one history `writer_seq` with the control write, while dynamic
  entry/return probes on `namei_ext_register_target_write()` define the actual
  in-kernel update interval. A return probe on `namei_ext_resolve_target()`
  captures both `rcu_walk` and its result. The raw trace must retain every
  bounded update entry/return and contain both successful and absent RCU-walk
  resolutions; only `-ENOENT`, not an arbitrary nonzero return, establishes
  the absent class. Other failures remain separately counted. Any lookup that
  happens to overlap a kernel update remains a reported count, not a second
  probabilistic lifetime gate. The deterministic
  replacement and clear litmus rows above exclusively test a borrowed target
  held across the actual kernel update and grace-period window.
- Writer control operations and trace shutdown share a mutex. Every bounded
  history update, including the final clear, carries begin/end markers. Trace
  shutdown runs only after the writer has joined, so no unmarked update can
  enter the bounded raw trace.
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
  strict KCSAN without weak-memory modeling, unknown-origin reports, lockdep,
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
| formal-kcsan | correctness instrumentation | same cells and control | strict KCSAN, lockdep, PROVE_RCU | 3 boots | tests sampled concurrent data races while the deterministic litmus tests publication ordering |

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
