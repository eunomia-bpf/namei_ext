# Implementation

Last updated: 2026-07-18
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

## Current Make Control Plane

The default Make path separates current validation, prototype experiment
entrypoints, and archived diagnostics:

- `make phase1` runs current prototype validation only: host checks, component
  builds, KVM smoke, policy load, and KVM functional tests.
- `make experiments` is the integrated experiment-suite entrypoint for the
  frozen evaluation program.
- `make experiment-agent-workspace` currently runs an Agent workspace prototype
  matrix and preserves raw KVM/FUSE outputs; its latest reviewed run is
  supporting-only and incomplete for final paper evidence.
- `make experiment-env-cache` is the historical target name for the traditional
  build/cache matrix entrypoint. It currently fails with the required cells.
- `ENABLE_LEGACY_DIAGNOSTICS=1 make phase1-legacy-diagnostics` preserves the
  archived W1-W4/table diagnostic flow for provenance and debugging; it is not
  the current paper experiment route.

The implementation record for this control-plane alignment is
`docs/tmp/2026-07-13-build-evaluate-make-control-plane-alignment.md`.

## Current Implementation State

The current prototype ABI implements `PASS`, `REDIRECT`, `HIDE`, and an initial
`SELECT_TARGET`. `REDIRECT` carries a bounded replacement component in
`redirect_name` and is validated as a same-parent component redirect. `HIDE`
returns absence for lookup and suppresses the entry during directory
enumeration. `SELECT_TARGET` selects a kernel-held registered `struct path` by
opaque target ID; the current implementation supports intermediate directory
selection plus final directory selection for stat, `O_DIRECTORY` open, and
readdir over the selected lower directory. It still fails closed for create,
non-directory final opens, final file target selection, and synthetic
parent-directory aliases. Optional deny remains a design-target action, not a
current prototype action.

The paper direction needs admitted complete experiments, not isolated runner
checks. These are the implementation work items for the active
BUILD_AND_EVALUATE phase:

1. Headline AgentFS-derived workspace lifecycle with source-derived oracle,
   operation-weighted lookup/readdir trace, feature-equivalent FUSE comparison,
   lower-filesystem semantic checks, and custom/stackable-FS boundary evidence.
2. Decisive traditional build/cache transition, using Redis/nginx/PostgreSQL,
   ccache/BuildKit-style workloads, or MEnv/SWE-Factory/SWE-rebench rows as
   sources of real build/test oracles. The fixed state machine is hit, miss,
   stale, corrupt, and epoch update, with feature-equivalent FUSE comparison
   and raw result review. This remains part of the strong hypothesis; the
   current prototype's lack of final-file target selection is an implementation
   gap to close before the row can be admitted, not a reason to shrink the
   paper. The concrete plans are
   `docs/tmp/2026-07-13-environment-cache-complete-experiment-plan.md` and
   `docs/tmp/2026-07-18-traditional-workloads-evaluation-plan.md`.
3. Conditional service/config transition or checkpoint/restart path remapping
   only after a real source oracle is selected where lookup-time object
   selection affects service-visible behavior.

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
Future BUILD_AND_EVALUATE implementation work should add only the remaining
bounded semantics required by the admitted Agent workspace oracle, plus
full-lifecycle traces and the Make-owned full matrix. Those actions must keep
the existing one-decision
`cgroup/namei_ext` ABI shape and must fail visibly on malformed or unsupported
decisions.

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

This preflight is dependency evidence only. It still lacks the feature-equivalent
FUSE comparison for the full AgentFS-derived lifecycle, calibrated
full-lifecycle RQ2 measurements, full AgentFS-derived lifecycle oracle,
parent-directory synthetic alias enumeration, final file target selection if
the admitted oracle needs it, result review, and custom/stackable boundary
audit required for full Experiment A.

An unreviewed prototype matrix target also exists: `make
experiment-agent-workspace` runs the current Agent workspace matrix through KVM
and the FUSE runner, then appends boundary-evidence rows. The preserved raw
roots are:

- `results/experiments/agent-workspace-matrix/20260713T053547Z-77bb2b4d/`
- `results/experiments/agent-workspace-matrix/20260713T053556Z-e2d462d9/`

A quick raw check found no `pass == false` rows in either JSONL file. Because
the project has re-entered BOOTSTRAP before renewed admission and independent
result review, these roots are prototype implementation artifacts only, not
final RQ evidence.

Historical BUILD_AND_EVALUATE Loop 001 repaired the Agent workspace matrix gates and ran
`make experiment-agent-workspace`, producing
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
review and reran `make experiment-agent-workspace`, producing
`results/experiments/agent-workspace-matrix/20260714T231148Z-7e0cc0e8/`.
That root now preserves command provenance, input hashes, kernel config,
stdout/stderr logs, explicit FUSE options, matrix-specific summary labels, and
no-hook latency controls for both the `namei_ext` and FUSE paths. It is still
supporting implementation evidence only: the next implementation work must add
source-derived AgentFS lifecycle rows such as rename, unlink, cached-negative
creation, a bash/git command sequence or source trace, source-tied RQ3 boundary
evidence, and broader invalid-policy containment before final Experiment A
result review.
