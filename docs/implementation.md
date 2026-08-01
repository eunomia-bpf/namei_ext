# Implementation

Last updated: 2026-07-29
Orchestrator phase: BUILD_AND_EVALUATE after BOOTSTRAP step
`docs/tmp/bootstrap/step-0005-20260714T174151-0700/` completed the latest paper
reorganization pass and independent outer audit. Implementation artifacts below
remain feasibility, dependency, or prototype evidence until a BUILD_AND_EVALUATE
step promotes them through admission, full execution, and result review.

`namei_ext` is implemented as a modified-kernel VFS name-resolution extension
with a `cgroup/namei_ext` attach path. Policies live under
`bpf/policies/*.bpf.c`; project-owned build, KVM, Docker, benchmark, and report
flows must run through Make targets.

## Validation Boundary

Phase 1 validation must use the modified kernel in KVM and the real attach
path. Host-kernel-only checks, object-file inspection, bpftool-only smoke tests,
and mocked decision stubs are diagnostics only.

Failures are hard failures: unsupported actions, verifier failures, malformed
decisions, syscall failures, missing capabilities, invalid lower selections,
and workload oracle failures must fail the owning Make target and preserve raw
evidence under `results/`.

## Unified Experiment Infrastructure

Formal case studies now live under `experiments/`, mechanism regressions remain
under `tests/`, and performance suites remain under `bench/`. Per-case KVM
recipes live in `mk/experiments/`; `mk/kvm.mk` retains shared guest setup and
mechanism suites. Standard performance matrices live in `mk/benchmarks/`.
`mk/results.mk` owns immutable result-root creation and the common
`namei_ext.run.v2` start, source-state and artifact validation, and completion
gates. Formal runs reject dirty main or kernel trees, start on the host before
KVM launch, preserve launcher logs, validate while `running`, and only then
transition to `completed`. The old ccache matrix is isolated in
`mk/experiments/legacy_build_cache.mk`.

`runner/libnamei_ext_harness.a` owns repeated mechanism lifecycle code:
cgroup movement and identity, BPF load/attach/detach, registered targets, exact
component-map updates, counters, path helpers, and child cleanup. Workload
state machines and correctness oracles remain in focused experiment runners.
Sandboxed Application File Sharing and Build Action Sandboxing use this shared
harness. The historical 24,286-line multi-workload runner is isolated under
`experiments/legacy_oracle/` and is not a template for new cases.

Canonical case-study result roots use `namei_ext.run.v2` metadata and preserve
`observations.jsonl`, commands, source inputs and captured runtime artifacts,
main and kernel commit/status files, guest and launcher stdout/stderr, kernel
configuration and identity, and dmesg. Source identity is captured on the host
before KVM boot, and kernel identity is validated in the guest; dirty, missing,
or malformed formal-run provenance is a hard failure.

Multi-boot benchmark suites use the same run schema with
`layout="boot-matrix"`. The root records the fixed matrix and both stock and
patched kernel identities. Every boot must preserve its own `boot.json`,
observations, kernel config/commit, uname, `/proc/version`, command line, CPU
snapshots, and dmesg before the root can transition to `completed`. Formal
matrices compare every observed boot and cell key with the declared plan and
establish the selected kernel identity from inside the guest.

The infrastructure migration passed the real modified-kernel KVM path for
Sandboxed Application File Sharing, Build Action Sandboxing, and the Agent
workspace namei_ext/FUSE matrix, followed by a complete `make phase1` run. The
standalone implementation and validation record is
`docs/tmp/2026-07-26-unified-experiment-infrastructure-implementation.md`.

A 2026-07-27 follow-up audit retained this layout and removed the remaining
control-plane drift. The top-level current-suite catalog is now also the source
of KVM provenance dependencies, current suites share one fail-fast dmesg gate,
and the default mechanism microbenchmark runs only `baseline`, `pass_only`,
and `policy`. The retired table comparison remains available only through an
explicit `BENCH_VARIANTS` override and is not part of the current benchmark
default. The audit and modified-kernel KVM validation are recorded in
`docs/tmp/2026-07-27-unified-infrastructure-followup-audit.md`.

Kernel commit `8fd1fb52f` adds the next active-path optimization without
changing the BPF ABI. A global RCU exact-parent filter and active-global counter
let component lookup, final-component open lookup, and directory iteration
skip namei_ext slow wrappers before context construction or cgroup discovery.
The filter is conservative; the existing effective-owner and per-cgroup scope
checks remain authoritative. Publication uses a raw-spinlock sequence counter
compatible with RCU pathname walk, while scope allocation and release remain
under the existing mutex and RCU lifetime model. The implementation and KVM
evidence are recorded in
`docs/tmp/2026-07-27-namei-ext-global-parent-fast-path-implementation.md`.

The same-day source-provenance convergence adds a clean-tree gate and records
both repository states under the v2 result schema for every current case-study
and FxMark RQ2 run. Design, alternatives, and validation are recorded in
`docs/tmp/2026-07-27-unified-source-provenance-infrastructure.md`.

Kernel commits `83d52c216` and `bdc9a83e3` remove the remaining selected-target
RCU fallback. Target-table reads are RCU-safe, replacement is atomic, and an
RCU pathname walk borrows the registered path until ordinary namei
legitimization acquires independent references. Ref-walk retains owned path
references. Phase 1 now forces both final and intermediate selected-target
RCU walks with `openat2(RESOLVE_CACHED)` and replaces a target 128 times while
another process continuously reads through it. The complete implementation,
lifetime argument, validation, and independent review are recorded in
`docs/tmp/2026-07-27-namei-ext-rcu-target-selection-implementation.md`.

The 128-replacement check does not by itself identify an old target borrowed
before concurrent retirement. The follow-up RQ3 experiment now uses a test-only
tracing-BPF litmus to hold an exact final-file or directory reader after a
successful RCU borrow, begin an exact replacement or clear writer, observe that
writer enter `synchronize_rcu()`, and then require ordinary namei completion on
the old object plus a distinct fresh replacement or absence. Its first
normal-kernel preflight failed the obsolete probabilistic clear-window oracle;
the failed root remains immutable and supplies no positive lifetime claim. The
deterministic repair builds cleanly, passes 36 analyzer tests and GCC
`-fanalyzer`, and has independent `GO` for a fresh normal/KASAN/KCSAN preflight.
No repaired KVM result exists yet. The complete record is
`docs/tmp/2026-07-31-rq3-target-lifetime-preflight01-failure-and-deterministic-repair.md`.

The unchanged RQ2 matrix produced 50 KVM boots and 450/450 passing cells with
numerically positive ranges, but independent review found that its patched
binary was built from a pre-commit dirty tree. It is diagnostic rather than a
paper result. The scoped result review and required clean rerun are recorded in
`docs/tmp/2026-07-27-rq2-fxmark-rcu-target-rerun-review.md`.

The forward fix binds patched and stock builds to separate source and built
commit stamps. FxMark runs freeze both kernel identities, benchmark/FUSE
binaries, and BPF objects before the first boot; all boots consume those
run-local snapshots, and finalization rechecks cross-boot kernel and workload
identity. The analyzer now derives duration and matrix shape from `run.json`,
uses an independent workload-cardinality oracle, and requires recorded FUSE
mount identity. Details and validation are in
`docs/tmp/2026-07-27-kernel-binary-provenance-and-rq2-analysis.md`.

## Current Make Control Plane

The default Make path separates current validation, prototype experiment
entrypoints, and archived diagnostics:

- `make phase1` runs current prototype validation only: host checks, component
  builds, KVM smoke, policy load, and KVM functional tests.
- `make experiments` runs the implemented case-study gates: the Agent workspace
  matrix and the Application File Sharing and Build Action Sandboxing
  preflights.
- `make kvm-agent-workspace-matrix` runs the Agent workspace matrix and
  preserves raw KVM/FUSE outputs.
- `make experiment-agent-workspace-source-task-rq1` runs the released
  SWE-Factory-Gym Click task through three fresh KVM boots with concurrent
  completed/base views, switch, rollback, and withdrawal.
- `make experiment-agent-workspace-rq2` runs the formal ten-pair
  `namei_ext`/FUSE lifecycle comparison.
- `make experiment-agent-workspace-rq3` runs the formal three-boot matched
  `namei_ext`/Wrapfs-derived ownership and fault-containment matrix.
- `make legacy-build-cache` is the canonical aggregate entrypoint for the
  historical traditional build/cache matrix.
- `make kvm-application-file-sharing-preflight` runs one W1 Sandboxed
  Application File Sharing grant/revoke boot; `make
  experiment-application-file-sharing-rq1` runs the formal three-boot result.
- `make kvm-build-action-sandboxing-preflight` runs the source-derived Bazel
  action-input visibility oracle through the real KVM attach path.
- `make kvm-service-config-rotation-preflight` runs one live nginx
  current/canary/invalid/rollback state machine; the ten-boot formal entrypoint
  is `make experiment-service-config-rotation`.
- `make experiment-fxmark-rq2` runs and reports the clean-source 450-cell,
  50-boot RQ2 matrix against stock, patched-unattached, attached `PASS`,
  attached `SELECT`, and optimized feature-equivalent FUSE.
- `make kvm-fxmark-readdir-preflight` runs the corrected FxMark `MRDL`/`MRDM`
  five-condition dependency gate. The final allowed preflight passed 20/20
  cells and independently authorized the unchanged 50-boot formal entrypoint,
  `make experiment-fxmark-readdir`.
- Lower-level `kvm-w4-ccache-*` targets remain available for historical ccache
  diagnostics; they are not dependencies of `make experiments`.

The implementation record for this control-plane alignment is
`docs/tmp/2026-07-13-build-evaluate-make-control-plane-alignment.md`.

The formal W1 source-oracle workload combines the official
`xdg-document-portal` 1.18.4 FUSE implementation with
`bpf/policies/application_file_sharing.bpf.c`,
`experiments/application_file_sharing/xdg_document_portal_oracle.c`, and
`experiments/application_file_sharing/namei_ext_application_file_sharing.c`.
Each boot runs the official portal first, verifies empty midpoint BPF/FUSE
state, and then runs `namei_ext`. Both mechanisms execute the same five
grant/isolation/revoke states with complete lookup, read, and directory
enumeration observations. The reviewed formal run completed three fresh KVM
boots with 15/15 official-source and 15/15 `namei_ext` states in exact
agreement, lower-object preservation, positive source/policy engagement, and
complete cleanup:
`results/experiments/application-file-sharing-source-oracle-rq1/20260730T-xdg-source-formal01/`.
Implementation and result records are
`docs/tmp/2026-07-30-application-file-sharing-source-oracle-rq1-implementation.md`
and
`docs/tmp/2026-07-30-application-file-sharing-source-oracle-rq1-formal01-result-review.md`.

The Agent workspace source-task workload is implemented by
`bpf/policies/agent_workspace_source_task.bpf.c` and
`experiments/agent_workspace_source_task/`. It runs the released
SWE-Factory-Gym `pallets__click-2622` pytest oracle through two concurrent
process-group views of one logical workspace, then switches, rolls back, and
withdraws one view. The reviewed formal result completed three fresh KVM boots
with 12/12 policy-backed task states and 6/6 direct physical source controls:
`results/experiments/agent-workspace-source-task-rq1/20260729T-agent-source-task-formal01/`.
Implementation and result records are
`docs/tmp/2026-07-29-agent-workspace-source-task-rq1-implementation.md` and
`docs/tmp/2026-07-29-agent-workspace-source-task-rq1-formal01-result-review.md`.

The Agent workspace RQ3 implementation ports the official Wrapfs source at
commit `464802c8fd1a25413b295161c9bb9a4ce7bfa33b` to the current Linux 7.1
kernel and executes it over the same ext4 lower tree as `namei_ext`. One shared
37-row semantic contract checks both implementations. Runtime kprobes attribute
13 stackable operation classes. The independent fault suite covers two
verifier rejections with exact logs plus 19 malformed or unsupported runtime
decisions with exact lower-object manifests. The clean formal run completed
three independent
KVM boots with all pairwise oracles and fault cells passing:
`results/experiments/agent-workspace-rq3-formal/20260728-rq3-formal-v3/`.
The result root is packaged under the common `namei_ext.run.v2` publication
contract with captured tested source/runtime artifacts and replayable analysis.
Implementation and result records are
`docs/tmp/2026-07-28-namei-ext-rq3-fault-matrix-implementation.md`,
`docs/tmp/2026-07-28-wrapfs-rq3-port-implementation.md`, and
`docs/tmp/2026-07-28-agent-workspace-rq3-formal-v3-result-review.md`. The
portable bundle implementation is recorded in
`docs/tmp/2026-07-28-agent-workspace-rq3-publication-bundle.md`.

## Current Implementation State

The current prototype ABI implements `PASS`, `REDIRECT`, `HIDE`, and
`SELECT_TARGET`. `REDIRECT` carries a bounded replacement component in
`redirect_name` and is validated as a same-parent component redirect. `HIDE`
returns absence for lookup and suppresses the entry during directory
enumeration. `SELECT_TARGET` selects a kernel-held registered `struct path` by
opaque target ID. Intermediate targets must be directories. Final targets may
be regular files or directories and support normal stat, access, open, exec,
`O_PATH`, `O_DIRECTORY`, and readdir behavior subject to target type. Create,
symbolic-link and special-file targets, type-incompatible use, and synthetic
parent-directory aliases fail closed or remain unsupported. Registration pins
the selected object and grants logical reachability without replaying the
physical target-parent walk; target inode and mount permissions remain on the
normal VFS path. Optional deny remains a design-target action, not a current
prototype action.

Kernel commit `621aff8d1bb5` adds final existing-file selection without changing
the BPF ABI. The complete Phase 1 run on
`7.1.0-rc7-g621aff8d1bb5` passed 3/3 ABI checks, 8/8 policy
load/attach/detach events, and 117/117 functional cases, with no declared fatal
pattern in smoke, policy-load, or functional dmesg:
`results/phase1/20260729T220000Z-f1e5e1e1/`. The design and implementation
records are
`docs/tmp/2026-07-29-namei-ext-final-file-selection-design.md` and
`docs/tmp/2026-07-29-namei-ext-final-file-selection-implementation.md`.

The paper direction needs admitted complete experiments, not isolated runner
checks. Agent workspace RQ1, RQ2, and RQ3 are complete for the admitted
existing-object slice, including the released source task. The Kubernetes
`AtomicWriter` payload-view subset is also complete as supporting RQ1 evidence.
The highest-value remaining implementation work is:

1. Add cache-cold lookup or selected mdtest metadata operations for RQ2 rather
   than rerunning completed cache-hot or readdir matrices.
2. Add a second source-derived RQ3 boundary row if it can reuse a complete RQ1
   oracle and a real custom, stackable, or source filesystem implementation.
3. Treat full nginx validation/reload, DMTCP, and Spindle as separate
   source-native extensions. The completed `AtomicWriter` result does not turn
   the older nginx or Spindle failed preflights into paper evidence.
4. Treat the old ccache hit/epoch/stale/corrupt matrix as supporting macro
   evidence. It must not replace a source-derived workload because ccache
   already owns cache lookup and validation in userspace.

Older diagnostic-comparison records are retained only as archived provenance.
Future implementation work follows the complete experiments above. Smoke
tests, artifact setup, object-file inspection, or host-only runs do not count
as paper results.

The concrete Experiment A implementation plan is
`docs/tmp/2026-07-13-agent-workspace-complete-experiment-plan.md`. `HIDE` has
passed the KVM functional attach-path validation in
`results/phase1/20260713T014740Z-efb9dc00/functional.jsonl`. The initial
`SELECT_TARGET` increment passed KVM functional validation in
`results/phase1/20260713T021039Z-a5adda84/functional.jsonl`. The concrete
design record is
`docs/tmp/2026-07-13-registered-target-selection-design.md`: target selection
uses kernel-held `struct path` registrations keyed by opaque target IDs, not
BPF-returned path strings or userspace daemon callbacks. A follow-up final
directory and registry-clear increment passed `make kvm-functional` in
`results/phase1/20260713T031516Z-997cf1c7/` and is recorded in
`docs/tmp/2026-07-13-namei-ext-select-target-final-dir-implementation.md`.
That run verifies both selected-root final directory behavior and that a select
policy after registry clear does not reuse a stale target.
Future BUILD_AND_EVALUATE implementation work must keep the existing
one-decision `cgroup/namei_ext` ABI shape and fail visibly on malformed or
unsupported decisions.

The first Agent workspace dependency preflight is implemented as
`make kvm-agent-workspace-preflight` and recorded in
`docs/tmp/2026-07-13-agent-workspace-preflight-implementation.md`. It KVM-tests
the current bounded-action slice: a stable logical `view/ws/...` path switches
between registered base and upper lower directories, `deleted.txt` is hidden as
a whiteout-style path, selected-root final directory lookup and readdir work,
symlink metadata remains lower-filesystem owned, and a logical write lands in the
selected upper target without materializing a base copy. The same KVM target
also runs a FUSE policy filesystem preflight for the same small
base/upper/whiteout/symlink/readdir/write oracle shape. The latest passing raw
root is
`results/experiments/agent-workspace/20260713T032434Z-8cbbac1b/`. That root
adds nonzero operation counters for both the `namei_ext` policy path and the
FUSE policy path, preserving the distinction between preflight engagement and
full-lifecycle RQ2 evidence.

This historical preflight is dependency evidence only. Later formal Agent
workspace RQ1, RQ2, and RQ3 experiments supplied the full-lifecycle oracle,
feature-equivalent FUSE comparison, calibrated measurements, result review, and
custom/stackable boundary audit. Synthetic parent-directory alias enumeration
remains outside the implemented contract; final existing-file selection is now
implemented and Phase 1 validated independently.

An unreviewed prototype matrix target also exists: `make
kvm-agent-workspace-matrix` runs the current Agent workspace matrix through KVM
and the FUSE runner, then appends boundary-evidence rows. The preserved raw
roots are:

- `results/experiments/agent-workspace-matrix/20260713T053547Z-77bb2b4d/`
- `results/experiments/agent-workspace-matrix/20260713T053556Z-e2d462d9/`

A quick raw check found no `pass == false` rows in either JSONL file. Because
the project has re-entered BOOTSTRAP before renewed admission and independent
result review, these roots are prototype implementation artifacts only, not
final RQ evidence.

Historical BUILD_AND_EVALUATE Loop 001 repaired the Agent workspace matrix gates and ran
`make kvm-agent-workspace-matrix`, producing
`results/experiments/agent-workspace-matrix/20260713T073438Z-5be906d9/`.
The repaired target now emits lower-filesystem/no-hook control rows, generated-file
negative-before-write rows, final manifest rows, fixed stat/readdir latency
rows, unregistered-target containment, and hard Make checks for required rows
and dmesg failure patterns. Independent result review still classified the run
as incomplete for final Experiment A because the workload remains too
synthetic and lacks source-derived lifecycle strength, per-operation samples,
uncertainty, macro runtime, source-tied RQ3 boundary accounting, and broader
invalid-policy containment. The raw root is supporting implementation evidence
only.

The current BUILD_AND_EVALUATE step repaired protocol blockers found by that
review and reran `make kvm-agent-workspace-matrix`, producing
`results/experiments/agent-workspace-matrix/20260714T231148Z-7e0cc0e8/`.
That root now preserves command provenance, source inputs, kernel config,
stdout/stderr logs, explicit FUSE options, matrix-specific summary labels, and
no-hook latency controls for both the `namei_ext` and FUSE paths. It is still
supporting implementation evidence only: the next implementation work must add
source-derived AgentFS lifecycle rows such as rename, unlink, cached-negative
creation, a bash/git command sequence or source trace, source-tied RQ3 boundary
evidence, and broader invalid-policy containment before final Experiment A
result review.
