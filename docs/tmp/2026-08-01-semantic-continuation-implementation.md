# Semantic Continuation Experiment Implementation

## Motivation

The paper's mechanism principle is that policy chooses a pathname binding and
the VFS safely commits that binding before continuing ordinary filesystem
semantics. Existing source-derived workloads establish useful path-view state
transitions, but they do not systematically test mutation, metadata, two-path
operations, and cross-filesystem errors in the same pathname walk that returns
`SELECT_TARGET`.

This implementation realizes the reviewed experiment in
`2026-08-01-rq1-pjdfstest-semantic-continuation-plan.md`. It is supporting RQ1
mechanism evidence. It is not an industrial workload, a performance benchmark,
or a claim of complete POSIX conformance.

## Code Paths

- `bpf/policies/semantic_continuation.bpf.c` implements one
  `cgroup/namei_ext` decision function. A component map selects registered
  targets `a`, `b`, and `x` for lookup events. Other names and event types pass.
  Separate counters record decision engagement without defining correctness.
- `experiments/semantic_continuation/semantic_continuation.c` implements the
  fixed S01--S16 differential matrix. Every selected pathname in S01--S15
  retains the logical selected component. S16 opens the selected directory,
  then continues through its directory descriptor after policy detach, target
  clear, cgroup migration, and cgroup removal.
- `experiments/semantic_continuation/Makefile` builds the controller against
  the shared harness and libbpf with `-Wall -Wextra -Werror`.
- `configs/benchmarks/semantic_continuation.mk` freezes the preflight/formal
  result roots, one/three fresh boots, timeout, and filesystem sizes.
- `mk/experiments/semantic_continuation.mk` owns the KVM lifecycle, filesystem
  setup, arm ordering, cleanup, result validation, and report generation.
- The top-level `Makefile` exposes only Make entrypoints. `mk/suites.mk`
  classifies the result as mechanism evidence rather than a case study.

## Fixture And Scope

Each KVM boot creates a scratch tmpfs, a loop-backed ext4 filesystem, and a
second tmpfs target. The direct arm uses independent physical ext4/ext4/tmpfs
roots. The selected arm uses a logical tmpfs parent whose `a`, `b`, and `x`
components select physical lower roots. `a` and `b` reside on the same ext4
mount; `x` resides on tmpfs.

The BPF program, registered targets, and exact-parent scope belong to one
experiment child cgroup. The component-map keys contain that cgroup's ID. Only
selected case children enter it; the controller and direct children remain
outside the attachment and cannot satisfy selected target-hit attribution.

The kernel exact-parent filter is configured only for the logical parent.
Physical lower-object checks therefore do not recursively invoke policy. A
physically present unmanaged logical sibling establishes the selected child's
`PASS` behavior.

## Correctness Evidence

The controller writes one raw JSONL stream per boot. Operation rows record the
arm, case, syscall-level operation, return, errno, expected detail, and oracle
result. Case rows summarize only those operation rows. Engagement rows compare
BPF counters immediately before and after each selected child and require every
expected operand target to be hit. Residual rows inspect the physical case
directories after each arm.

Protocol v2 additionally records one counter-delta row after every selected
operation. Each row freezes whether that operation must select a target set,
must PASS, or must cause no policy decision. S16 identity rows preserve the
actual and expected device/inode values. Operation rows classify descriptor
returns so only descriptor numbers are normalized; byte counts and ordinary
syscall returns remain exact in the arm comparison. The S15 direct and selected
unmanaged controls use distinct physical files.

`configs/benchmarks/semantic_continuation_operations.tsv` is an independent
80-row formal oracle for case, operation, expected decision class, target mask,
and return kind. It is captured in each result root. The host finalizer requires
one matching direct operation, selected operation, and selected engagement for
every row, so the C mapping cannot validate itself.

The host finalizer rejects a boot unless all of the following hold:

- every raw row carrying `pass` is true;
- direct and selected arms contain the complete profile-specific case set;
- normalized operation outcomes are identical across arms;
- every selected operation has one passing per-operation engagement row and all
  non-descriptor return values match exactly across arms;
- each selected case has the expected target engagement and each case has an
  empty lower-object residual check;
- formal permission and `EXDEV` errors have the exact expected errno;
- S16 tears down policy before its descriptor-relative operations;
- both S16 arms preserve raw actual/expected device and inode identities;
- the controller, fixture cleanup, ext4/tmpfs identity, and boot status pass;
- dmesg contains none of the project failure signatures, an RCU stall, or a
  `namei_ext` failure diagnostic.

Counters are used only for mechanism attribution. Syscall return/errno, bytes,
metadata relations, directory membership, link identity, lower-object state,
and filesystem identity define semantic correctness.

## Failure Handling

The result root is created once and remains `running` through KVM execution,
finalization, and analysis. A guest, finalizer, or analyzer failure marks the
root failed. A completed or failed root is not reused. Guest cleanup records an
independent status after unmounting tmpfs and ext4 and removing the scratch
fixture. The workflow does not create or validate checksum artifacts.

## Validation Performed

Before KVM execution:

- `make -C experiments/semantic_continuation clean all` completed with
  `-Wall -Wextra -Wshadow -Wconversion -Werror`.
- `make semantic-continuation bpf` built the userspace controller and BPF
  policy.
- `make abi runner semantic-continuation bpf` passed the shared ABI, harness,
  controller, and policy host gates.
- Clang static analysis completed with no remaining diagnostics after an
  explicit initialization fix in the S16 identity handoff.
- `make help` parsed the complete top-level Make graph and exposed both public
  experiment entrypoints.
- `git diff --check` reported no whitespace errors.
- The revised scientific plan received an independent GO before implementation.

The implementation received a claim-to-code preflight review before KVM. The
first launch did not start a guest because the PTY stopped the QEMU process
group. The second launch entered the modified-kernel guest but exposed a
control-plane ordering error before any semantic case ran: the controller tried
to set an exact parent for a child cgroup before that cgroup owned an attached
policy. The forward fix attaches the policy to the child cgroup first, then
registers the exact parent. Each configuration operation now emits its own raw
setup event, and the host finalizer freezes the complete successful setup
sequence. Neither failed root is mechanism evidence.

## Remaining Risks

- The experiment has not yet established that final-component creation and
  two-path operations work through the current modified kernel.
- The controller is custom glue derived from standard `pjdfstest` operation
  families; it does not run the unmodified upstream suite.
- Three deterministic boots detect semantic disagreement, not rare concurrent
  lifetime failures. The separate target-lifetime experiment owns that claim.
- A positive result is scoped to the frozen operations and tested ext4/tmpfs
  configuration. It cannot establish complete POSIX or arbitrary-filesystem
  conformance.
