# RQ3 Target-Lifetime Preflight01 Failure And Deterministic Repair

## Question

The paper's central construction is not merely that namei can invoke BPF. A
policy-selected existing `struct path` must remain valid while an RCU pathname
walk borrows it, a controller replaces or clears its registry entry, and
ordinary VFS completion converts the borrowed object into stable references.
This record explains why the first target-lifetime preflight did not establish
that claim and how the replacement experiment constructs the required overlap.

## Immutable Failed Run

The first preflight root is:

`results/experiments/namei-ext-target-lifetime-preflight/20260801T033358Z-target-lifetime-preflight01/`

It records clean project commit `1c76c014ac6d838928d1cd7ee5f152d560929cce`
and clean kernel commit `621aff8d1bb52fad718f11fd882c956d6a5686ae`.
The normal-kernel runner returned zero, but guest analysis failed with:

```text
analysis failed: final-file: no RCU target resolution during target retirement
```

The run root is marked `failed`. KASAN and KCSAN did not run. The root has not
been modified or reused and cannot support a positive runtime or lifetime claim.

## What The Raw Run Did Establish

All three normal-kernel runner summaries passed. The five-second final-file cell
completed 41 updates and the directory cell completed 27 updates; both exceeded
their eight-update minimum with two readers. The pinned-object cell completed
all four configured lifecycle cycles, and the run summary reported no runner
failure.

The concurrent ftrace stream was complete and engaged both update classes:

| Cell | Successful RCU resolve during replacement | `ENOENT` RCU resolve during clear |
| --- | ---: | ---: |
| final file | 198 | 213 |
| directory | 133 | 134 |

This is useful engagement evidence. It shows that RCU resolution ran while the
exact kernel update function was active. It does not identify a reader that had
already borrowed the old path before removal and remained in the outer namei RCU
critical section while the writer retired that path.

## Why The Old Oracle Was Invalid

The old analyzer required a successful `namei_ext_resolve_target()` return
inside both replacement and clear update intervals. During clear, the writer
first removes the registry entry and then enters `synchronize_rcu()`. A reader
that begins target lookup after removal should return `ENOENT`; that is the
correct result, not a lifetime failure. A successful result can occur only if a
reader wins a narrow scheduling race and borrows the entry before removal while
the writer function is already active. Failure to sample that race says nothing
about whether the kernel safely retains an already borrowed path.

The old ftrace events therefore proved concurrent mechanism engagement but
could not prove the claimed old-borrower lifetime. Increasing duration or reader
count would only make the sampling probability larger; it would not repair the
oracle.

## Deterministic Borrower/Updater Litmus

The repaired runner loads a test-only tracing-BPF object without changing the
namei_ext ABI or kernel implementation. For both a final selected file and a
selected directory, it runs separate replacement and clear cases:

1. The main thread registers and warms the old target, creates a reader thread,
   and pins the two threads to distinct allowed CPUs.
2. The reader executes `openat2(..., RESOLVE_CACHED)` through the real
   `cgroup/namei_ext` attachment.
3. An fexit program on `namei_ext_resolve_target()` accepts only the exact reader
   TID, successful `rcu_walk=true` result, expected cgroup and target ID, and a
   borrowed non-null mount/dentry. It records the old path and holds the reader
   before returning to the surrounding namei walk.
4. After observing that hold, the exact writer thread issues either replacement
   of the same target ID or `clear`.
5. Kprobes record update entry and, for clear, clear entry. A kprobe on
   `synchronize_rcu()` accepts only this writer and releases the reader hold.
6. The reader resumes ordinary namei completion and validates the old lower
   device, inode, and contents. The writer cannot finish retirement until the
   surrounding RCU reader exits.
7. A fresh lookup validates a distinct replacement object or `ENOENT` after
   clear. Kretprobes record clear and outer update exits.

A per-case cookie and one 64-bit atomic event counter define the evidence order.
Replacement must be exactly `hold(1), update-entry(2), grace-entry(3),
reader-release(4), update-exit(5)`. Clear adds `clear-entry(3)` and
`clear-exit(6)`, ending at outer update exit 7. Timestamps are retained only as
observations. The experiment constructs borrower/update overlap; it does not
measure how long `synchronize_rcu()` blocks.

## Fail-Closed Evidence Contract

Each case independently records and checks:

- expected and tracing-BPF-observed reader/writer TIDs and CPUs;
- distinct reader and writer CPUs and TIDs;
- expected and observed cgroup ID and target ID;
- borrowed mount and dentry addresses;
- exact per-event cookie and sequence;
- one matched resolve, update entry, grace entry, and update exit;
- no timeout or BPF state-machine error;
- old reader device/inode and content;
- distinct fresh replacement device/inode, or fresh `ENOENT` after clear.

The tracing links are detached before the original concurrent ftrace stress.
Exit probes accept only the completed active case, so cleanup cannot mutate the
captured state. The shared BPF/userspace state is 336 bytes with compile-time
size and critical field-offset assertions.

## Analyzer And Host Validation

The analyzer now treats the deterministic litmus as `target_retirement` evidence
and the original ftrace stream as `concurrent` engagement. It requires two cases
per publication cell and four unique cookies per boot. Negative tests reject
cookie, independently observed TID/CPU, event order, timeout, old identity,
same-object replacement, and post-clear mismatches.

Host validation completed:

- C and BPF builds pass `-Wall -Wextra -Werror`;
- GCC `-fanalyzer` reports no runner finding;
- all 36 analyzer tests pass, including the unchanged 12,100-history exhaustive
  linearizability cross-check;
- userspace DWARF and BPF BTF show the same 336-byte shared layout and offsets;
- all six tracing program sections are present; and
- rerunning only the repaired offline analyzer against the immutable old raw
  history fails because the required replacement and clear litmus rows are
  absent; and
- `git diff --check` passes.

An independent read-only review found no P0 or P1 issue. Its two P2 checker and
schema findings were repaired, after which no P0, P1, or P2 remained. The
reviewer returned `GO` for a fresh normal/KASAN/KCSAN KVM preflight.

## Next Gate

This repair has no KVM result yet. After committing the clean-source
infrastructure, run one fresh normal, KASAN, and KCSAN preflight under a new run
ID. Review the four raw litmus rows, concurrent engagement, complete dmesg,
KCSAN counters, lower-object checks, cleanup, and controlling statuses before
admitting the nine-boot formal matrix. Never reuse or reinterpret the failed
preflight01 root.
