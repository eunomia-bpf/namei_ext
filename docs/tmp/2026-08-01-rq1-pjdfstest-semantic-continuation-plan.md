# Experiment Plan: RQ1 Selection-Boundary Semantic Continuation

Revision 1 replaces the rejected selected-cwd `pjdfstest` protocol. The
reason and independent findings are recorded in the adjacent plan review.

## Research Question

- RQ exactly as written in the paper: Can a narrow VFS name-resolution
  extension express real state-dependent path-view policies without taking
  over filesystem semantics?
- Specific uncertainty tested here: when a pathname contains an intermediate
  directory selected by `namei_ext`, does the same VFS walk continue with the
  ordinary lower-filesystem result for final lookup/create, metadata and data
  operations, two-path operations, enumeration, and errors?
- Why the answer matters: "BPF chooses the binding; VFS executes the
  semantics" is the proposed unifying principle. Current source workloads do
  not systematically exercise mutation and two-path operations across the
  selection boundary.

## Paper-Value Admission

- Planned role: supporting.
- Largest credible paper story this experiment could unlock: one bounded
  pathname-binding decision reconnects to normal VFS semantics in the same
  walk, rather than implementing a partial filesystem behind a collection of
  unrelated hooks.
- Strongest reviewer reject argument or load-bearing uncertainty addressed:
  selected paths work for the paper's read-heavy workload probes but fail or
  change semantics for create, permission, links, rename, timestamps,
  enumeration, deletion, or cross-filesystem errors.
- Independent evidence added beyond existing runs and published results: every
  checked operation crosses the selection boundary. Two-path calls cross it
  independently for both operands. Existing workload oracles and the rejected
  selected-cwd suite do not provide that coverage.
- Why the result is not tautological, already settled, or dominated: the
  checked syscall and `SELECT_TARGET` occur in the same path walk. The kernel
  must preserve the selected mount/dentry, permission context, create parent,
  same-filesystem relation, and error semantics while completing the operation.
  Direct ext4 conformance or operations from an inherited selected cwd cannot
  establish those properties for the modified walk.
- Paper decision if positive: add a compact mechanism-construction row under
  RQ1 showing that the selected and direct paths agree across the frozen
  operation families and that every selected case engaged the intended target.
  Use it as evidence for the binding/commit/continue principle, not as another
  industrial workload.
- Paper decision if contradictory, mixed, or inconclusive: a selected-only
  mismatch contradicts the semantic-continuation mechanism prediction and
  requires a kernel redesign before retaining the broad ownership claim. A
  direct-control failure or missing attribution makes the experiment
  inconclusive.
- Best alternative experiment and why this one has higher decision value: a
  second source-derived RQ3 row would broaden ownership evidence, and another
  cache-cold/FUSE run would broaden RQ2. Neither directly falsifies the
  same-walk continuation invariant that currently makes the design look ad hoc.

## Expected And Alternative Outcomes

- Current expected answer: all direct and selected operation cases pass their
  independent expected-result oracle in all three KVM boots; normalized
  selected and direct outcomes agree; each selected case has a positive hit on
  every logical target operand; and lower objects reflect exactly the intended
  operation before cleanup.
- Strongest competing explanation: replacing `nameidata::path` is sufficient
  for final read-only lookup but not for final-component creation, two-path
  mount checks, permission evaluation, or directory iteration.
- Result that would contradict the expectation: direct paths pass while any
  selected path returns a different status/errno, bytes, normalized metadata,
  link relation, directory membership, cross-filesystem `EXDEV`, or lower
  object state.

## Published Precedent And Real Assets

- Closest published protocol: the official `pjd/pjdfstest` suite exercises
  POSIX syscall families on Linux/ext4. Its operation families define the
  breadth of this focused selection-boundary matrix. Linux's standard path and
  filesystem test practice motivates direct expected-outcome controls rather
  than policy-produced success labels.
- Official system/model/data/benchmark/tool and version: the operation-family
  inventory is frozen from `pjd/pjdfstest` commit
  `ededbeb2b44929972898afb87474b0937f78a877`, the same revision previously
  reproduced in this repository. The actual system under test is the modified
  Linux kernel running ext4 plus tmpfs.
- What is reused: POSIX/Linux syscall contracts and the suite's covered
  operation families: access/stat, create/open/read/write, chmod/chown,
  mkdir/readdir/rmdir, fifo and symlink operations, link/rename, truncate and
  timestamps, unlink, and expected failure behavior.
- Necessary deviations or custom glue: the unmodified suite cannot force each
  generated pathname to retain a logical selected prefix. A small C controller
  therefore executes a fixed differential matrix and records raw per-operation
  results. Custom code supplies paths, cgroup/target setup, and observations;
  it does not define success from BPF output.

## Comparison

- Proposed system or method: selected paths of the form
  `<logical-parent>/{a,b,x}/...`, where `a` and `b` select two directories on
  one ext4 mount and `x` selects a directory on tmpfs.
- Main baselines and the competing position each represents: none. This is a
  mechanism correctness test, not a performance or ownership comparison.
- Why each main baseline needs a matched run instead of citation alone: not
  applicable.
- Controls or ablations, labeled separately: the direct control executes the
  same operation sequence on independent ext4/ext4/tmpfs directories with no
  selected component. An unrelated logical-parent control must remain on its
  ordinary lower path. Target identity controls compare device/inode after
  selection. A directory-fd continuation case selects and opens a directory,
  then detaches policy and clears the registry before completing operations
  through that already-open fd.
- Conclusion if each main baseline matches or wins: direct and selected must
  both satisfy explicit expected outcomes. Direct-pass/selected-fail
  contradicts the mechanism. Both failing is an invalid test environment, not
  evidence for or against `namei_ext`.
- Information, tuning, and compute fairness: paired arms use one committed
  runner, the same patched kernel, process credentials, operation order,
  mount options, and mirrored fresh fixtures. Arm order alternates across
  boots. No selected-only retry or excluded case is allowed.
- Split or leakage rule when relevant: direct and selected arms use disjoint
  empty roots. Every raw row names its arm, case, path role, operation, return,
  errno, and independently observed result. Residual test objects or access to
  the opposite arm fails the boot.

## Frozen Mechanism Configuration

- Policy: a new `semantic_continuation.bpf.c` with one decision function, one
  component map named `semantic_continuation_views`, and target-hit counters.
  It returns `SELECT_TARGET` only for LOOKUP keys installed for `a`, `b`, and
  `x`; all other events return `PASS`.
- Scope: the kernel exact-parent prefilter contains only the logical parent.
  The component keys include the selected child cgroup ID, userspace-encoded
  parent device/inode, event, and complete name.
- Cgroup placement: only the selected child is moved into the experiment
  cgroup. The controller and direct child remain in the root cgroup, so
  controller instrumentation cannot satisfy target-hit attribution.
- Snapshot ordering: for each selected case, the controller reads target-hit
  counters, releases the selected child to execute exactly that case, waits for
  the raw result, then reads counters again. Each logical path operand must
  increase its target's hit counter by at least one. More than one hit is
  accepted because a complete VFS `-ECHILD` restart has at-least-once policy
  semantics.
- Mount identity: ext4 and tmpfs are checked by `statfs`; selected directory
  device/inode is checked against the registered lower target; same-ext4
  link/rename cases must succeed, while ext4-to-tmpfs link/rename must return
  `EXDEV`.
- Kernel-health predicate: fail on the repository's existing project dmesg
  scan for BUG/WARNING, Oops, panic, sanitizer report, general-protection
  fault, hung task, RCU stall, or `namei_ext` failure diagnostic.

## Workloads And Metrics

- Real workloads or tasks: one fixed operation matrix in these groups:
  final lookup/error; create/open/write/read/stat/access; exclusive create;
  chmod/chown and unprivileged access; truncate and `utimensat`; mkdir/readdir/
  rmdir; fifo and symlink/lstat/readlink/follow; hard link and link count;
  same-ext4 rename across selected roots; cross-filesystem link/rename
  returning `EXDEV`; unlink; and post-detach directory-fd continuation.

| Case | Frozen operation and expected result |
|---|---|
| S01 missing lookup | `stat(a/missing)` returns `ENOENT` |
| S02 file lifecycle | Exclusive create mode 0644, write/read `alpha`, stat size 5, read/write access succeeds, second exclusive create returns `EEXIST`, unlink restores `ENOENT` |
| S03 metadata ownership | Create, chmod 0600, chown to UID/GID 65534, and stat reports the exact type/mode/owner before root cleanup |
| S04 permission | A root-owned mode-0600 file rejects UID/GID 65534 with `EACCES`; mode 0644 permits the same child's complete read |
| S05 truncate/time | Truncate an eight-byte file to three bytes and set a fixed `utimensat` mtime; size, bytes, and mtime match exactly |
| S06 directory lifecycle | Create `a/dir/child`, enumerate exactly the expected child, then unlink and remove the directory |
| S07 fifo | `mkfifo` mode 0640 produces a FIFO with the expected mode, then unlinks cleanly |
| S08 symlink | Create a relative symlink, verify `lstat` and `readlink`, follow it to exact bytes, then remove link and target |
| S09 hard link | Link `a/original` to `a/alias`, require equal device/inode and link count two, then unlink to link count one |
| S10 same-root rename | Rename `a/old` to `a/new`; old is absent and new preserves exact bytes |
| S11 two-target rename | Rename `a/src` to `b/dst` where both selected targets are on the same ext4 mount; source becomes absent and destination preserves bytes |
| S12 two-target hard link | Link `a/src` to `b/dst` on the same ext4 mount; both names have equal device/inode and link count two |
| S13 cross-FS rename | Rename from ext4 target `a` to tmpfs target `x` returns `EXDEV`, leaving source unchanged and destination absent |
| S14 cross-FS hard link | Link from ext4 target `a` to tmpfs target `x` returns `EXDEV`, leaving source unchanged and destination absent |
| S15 unmanaged sibling | A physically present unmapped child of the logical parent follows `PASS` and retains its expected bytes and identity |
| S16 directory-fd continuation | Open selected `a` as a directory fd, then detach policy, clear targets, and move the child out of the cgroup before create/read/rename/unlink through that fd; all operations succeed on the registered ext4 directory |

All path operands in S01--S15 retain the logical `a`, `b`, or `x` component.
S16 is the explicit post-binding descriptor ablation and therefore uses the
already-open directory fd after teardown.
- Primary metrics: passed/total semantic cases and passed/total operation
  observations for direct and selected arms, plus the count of pairwise
  normalized-outcome mismatches. The positive result requires zero failed
  cases, zero mismatches, and complete target-hit attribution in every boot.
- Correctness check or ground truth: explicit expected syscall return and
  errno; exact file bytes and directory membership; normalized type, mode,
  UID/GID, size, and link-count relations; symlink target; timestamp ordering;
  selected/lower identity; direct lower-object inspection; expected `EXDEV`;
  fixture emptiness after cleanup; policy detach, target clear, cgroup removal,
  clean unmount, and the frozen dmesg predicate. BPF counters establish
  engagement only and never define semantic success.
- Repetitions, seeds, and uncertainty: one paired subset preflight followed by
  three fresh paired KVM boots of the complete deterministic matrix. There is
  no performance estimator or statistical claim.
- Cost estimate when material: one preflight and three formal boots should
  complete in minutes; the matrix contains no long-running application build.

## Planned Runs

| Run group | Role | Workload | System/method | Repetitions | Decision consequence |
|---|---|---|---|---:|---|
| preflight | real-path dependency | create/write/read/stat/unlink plus same-ext4 rename | direct and selected paths | 1 paired boot | Establish KVM attach, final-create continuation, two-path selection, raw records, and cleanup |
| formal-direct | reference control | complete frozen semantic matrix | direct ext4/ext4/tmpfs paths | 3 fresh boots | Any failure invalidates the matched environment |
| formal-selected | proposed mechanism | same complete matrix with every pathname retaining `a`, `b`, or `x` selected component | 3 fresh boots | All-pass and zero differential mismatch supports scoped semantic continuation; any selected-only mismatch contradicts it |

## Execution

- Authoritative command or workflow: one committed
  `make kvm-semantic-continuation-preflight RUN_ID=<fresh-id>` target and one
  committed `make experiment-semantic-continuation RUN_ID=<fresh-id>` target.
- Real preflight case: one fresh modified-kernel KVM boot executes the frozen
  create/write/read/stat/unlink and same-ext4 rename cases through direct and
  selected paths, with exact-parent scope, per-case hit attribution, ext4/tmpfs
  identity, cleanup, and dmesg checks.
- Full completion rule: all six formal arms terminate in three fresh boots;
  every expected-result and pairwise oracle passes; every selected case has
  complete per-target engagement; all cleanup and kernel-health checks pass;
  and a fresh independent reviewer recomputes the result from raw operation,
  counter, identity, lower-object, status, and dmesg records.
- Raw-result path:
  `results/experiments/semantic-continuation/<RUN_ID>/` and
  `results/experiments/semantic-continuation-preflight/<RUN_ID>/`.
- Checkpoint or recovery approach: each boot writes observations and status
  directly under its boot directory. Completed or failed roots are immutable;
  no failed boot is replaced inside a formal matrix.

## Interpretation

- Positive result: on the tested Linux configuration, ext4 and tmpfs object
  semantics continued correctly after an intermediate selected component for
  the frozen single-path, two-path, permission, metadata, directory, and error
  matrix. This supports the mechanism principle; it does not answer all of RQ1.
- Negative or contradictory result: direct controls pass and at least one
  selected case diverges. Preserve the exact operation and lower state, repair
  the kernel handoff, and rerun the unchanged matrix; do not weaken the claim.
- Mixed or inconclusive result: direct controls fail, target engagement is
  ambiguous, a required syscall is unavailable, or fixture cleanup prevents
  attribution. No continuation claim is admitted.
- Target paper figure or table: one compact construction table grouped by
  operation family, reporting selected/direct cases, mismatches, lower-FS
  identities, and target-hit attribution. It is not a new workload or
  performance figure.

## Reproducibility Notes

- Software and data versions: project and kernel commits are recorded by the
  run. Operation-family selection is grounded in `pjdfstest` commit
  `ededbeb2b44929972898afb87474b0937f78a877`. The modified kernel must include
  ext4, tmpfs, and POSIX ACL support.
- Config and seed notes: one loop-backed ext4 image and one tmpfs mount per
  boot, fixed operation order, fixed object names, root plus UID/GID 65534
  permission checks, and alternating arm order.
- Known deviations: this is a focused selection-boundary differential matrix,
  not a claim that unmodified `pjdfstest` ran through every logical path. It
  does not establish complete POSIX conformance, crash consistency, arbitrary
  lower filesystems, or source-workload expressiveness by itself.
