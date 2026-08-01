# Plan Review: RQ3 Concurrent Target Lifetime

## Scope

This review covers
`docs/tmp/2026-07-30-rq3-concurrent-target-lifetime-experiment-plan.md`.
The experiment tests whether a policy-selected registered VFS object can be
published, retired, and handed back to ordinary namei safely under concurrent
updates. It does not add a workload, rerun Wrapfs, or make a throughput claim.

## Initial Independent Review

The initial reviewer returned `NO-GO` with four blocking findings and one
comparison-version finding.

1. The original oracle checked each read against an overlapping publication
   interval independently. That could accept a set of observations for which no
   one legal global sequential history exists.
2. The original plan mixed `openat()`, read, fstat, and readdir into one target
   operation and did not define the behavior of an already registered object
   after physical rename or unlink. It also shared one cgroup even though
   `clear` removes every registered target for that cgroup.
3. The original fixed count required 25,000 updates in every formal boot even
   though each replacement and clear waits for `synchronize_rcu()`. That scale
   was not credible under strict KCSAN, and the plan did not prove that KCSAN
   watchpoints engaged.
4. The original diagnostic rule allowed post-hoc judgment about whether a
   sanitizer or kernel report was relevant.
5. Reusing the existing Wrapfs result was appropriate, but the plan did not
   connect that run's project, kernel, Wrapfs, and 37-row oracle identities to
   the current kernel.

## Repairs

- The raw history now records separate invocation and response events for every
  serial-writer `SET`/`CLEAR` and reader `openat()`. The checker must find one
  global sequential history preserving writer order, completed-before
  real-time order, and the register state machine. Three negative checker
  controls include a locally overlap-valid but globally impossible history.
- `openat()` is the only selection operation. Immediate descriptor device/inode
  identifies the selected object. Later read, fstat, and readdir calls test
  descriptor stability without becoming additional state operations.
- Rename and unlink do not retire a registered object: the held `struct path`
  remains selectable until `CLEAR` or replacement. After clear, new logical
  opens are absent and old descriptors remain usable. Nonempty directories use
  rename, and post-unlink checks use pre-held descriptors.
- Final-file, directory, and pinned-object cells use independent cgroups and
  registries.
- Fixed operation counts were replaced by fixed durations, minimum completed
  operations, and per-boot timeouts. Normal, KASAN, and KCSAN use independent
  build roots and images.
- The strict KCSAN configuration freezes watchpoint count, delays, skip count,
  randomization, and report interval. Every KCSAN boot preserves before/after
  counters and must increase both setup and used watchpoints.
- Diagnostic attribution is fixed in advance. A report involving namei_ext or
  this experiment's syscall stacks is negative; any other kernel sanitizer,
  lockdep, RCU, warning, fault, or hang makes the boot inconclusive. Complete
  dmesg is retained.
- The prior fixed Wrapfs comparison is identified by result root, project
  commit, kernel commit, and upstream Wrapfs commit. Since the current kernel
  changed shared selected-target handling to add final-file support, every
  formal boot reruns only the current `namei_ext` side of the same 37-row
  contract. Wrapfs is not rerun, and repetition counts are not compared.

## Follow-Up Verdict

The same independent reviewer re-read the repaired plan and found no remaining
P0, P1, or P2 issue. The follow-up confirmed that the global history oracle,
selection/descriptor split, independent cgroups, pinned-object semantics,
fixed-duration debug runs, KCSAN engagement, diagnostic attribution, and
Wrapfs/current-kernel linkage address the initial blockers.

`Plan verdict: GO`
