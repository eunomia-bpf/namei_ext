# Agent Workspace Complete Experiment Plan

Date: 2026-07-13
Status: planned complete experiment; not yet implemented or run

## Research Question

This is the headline experiment for the current paper direction.

- RQ1: Can a narrow VFS name-resolution extension express a real
  state-dependent agent workspace path view without taking over filesystem
  semantics?
- RQ2: What is the cost of putting the same policy on the VFS
  name-resolution path compared with a feature-equivalent FUSE policy?
- RQ3: Does `namei_ext` provide a narrower and safer boundary than a custom or
  stackable filesystem when the oracle-relevant behavior is path selection and
  visibility over existing lower objects?

## Paper-Value Admission

Reviewer question: if agent filesystems already use FUSE or custom filesystem
logic, is a `sched_ext`-style VFS extension point a real middle point or only a
small optimization?

This experiment is admitted because a positive result would directly support
the main thesis: `namei_ext` can satisfy a source-derived agent workspace
path-view oracle through the real KVM attach path while the kernel and lower
filesystem keep object, data, write, permission, page-cache, and persistence
semantics. It also gives the required FUSE cost comparison and the custom-FS
boundary evidence. A source reproduction, smoke test, static mapping
diagnostic, or materialization comparison cannot answer the same question.

## Source Assets

Primary source: AgentFS, commit `0a014ebd4918615baff589ed17486e557e7c6a23`,
with reproduced official SDK, CLI, integration, and example evidence recorded
in `docs/tmp/2026-07-02-agentfs-official-workload-reproduction.md`.

The reusable AgentFS behaviors are:

- FUSE-mounted agent workspace paths;
- copy-on-write sandbox behavior;
- bash and git actions in the sandbox;
- whiteout/delete state;
- symlink handling;
- cache invalidation after unlink, rename, and cached-negative creation;
- final tree and host non-materialization oracles.

Supporting sources: BranchFS, Sandlock, YoloFS, Mirage, OpenHands,
SWE-agent/SWE-ReX, SWE-MiniSandbox, AgentCgroup, Redis AFS, and Terminal-Bench.
These support workload selection and boundary evidence. They are not separate
paper-result rows for this experiment.

This is an AgentFS-derived workload, not a claim that the full AgentFS system
has been reimplemented or replaced.

## Hypothesis

A bounded eBPF decision function at VFS name resolution can express the
AgentFS-derived path-view slice of an agent workspace lifecycle:

```text
logical path + workspace state -> selected existing lower object or hidden name
```

The kernel and lower filesystem still own ordinary filesystem behavior. The
policy does not synthesize contents, implement COW writes, persist custom
metadata, mediate read/write after open, or orchestrate the agent runtime.

## Implementation Preconditions

The current prototype supports `PASS`, same-parent `REDIRECT`, `HIDE`, and an
initial `SELECT_TARGET`. `HIDE` and intermediate registered-directory selection
have passed KVM functional validation through the real attach path, but that is
not enough for the full headline workload until any required registered-target
directory aliasing, final-object semantics, and the full Agent workspace matrix
are implemented. The full experiment must not be shrunk to a functional
redirect/hide/select toy just because that is the current implemented subset.

Before the full paper-result run, the implementation must add or otherwise
provide equivalent bounded actions for:

- `HIDE`: lookup returns absence and readdir suppresses a logical name, needed
  for whiteout/delete and protected-path visibility semantics; implemented and
  KVM-validated by `make kvm-functional` in
  `results/phase1/20260713T014740Z-efb9dc00/functional.jsonl`;
- registered target selection: lookup selects a pre-registered lower object
  outside the immediate visible directory, needed for base/upper/checkpoint
  selection without materializing a copy tree. The implementation design is
  `docs/tmp/2026-07-13-registered-target-selection-design.md` and requires
  kernel-held `struct path` registrations, not string path rewrites. The
  current prototype implements intermediate directory selection; directory
  aliasing and final-object selection remain workload-oracle dependent;
- validation and containment for malformed, unknown, out-of-scope, or invalid
  decisions.

Until the full Agent workspace semantics and matrix are implemented, only a
preflight redirect/hide/select slice can run, and that preflight is not a paper
result for Experiment A.

## Workload

The fixed workload should be selected before the run and kept stable through
all comparison cells.

Workspace state:

- a base repository tree with source files, `.git`-like metadata, and symlinks;
- a per-agent upper/delta tree with edited files and new generated files;
- a whiteout/delete state for at least one base file;
- a checkpoint or branch state that changes which lower object a stable
  logical path resolves to;
- a cache-invalidation or cached-negative state that changes directory
  visibility after unlink, rename, or creation.

Operations:

- `stat`, `open`, `read`, `access`, `exec` where applicable, and `readdir` over
  the same logical workspace paths;
- a bash or git-derived command sequence from the AgentFS integration evidence,
  reduced only enough to keep the oracle deterministic in KVM;
- an epoch/state update that changes path selection without remounting or
  rebuilding a materialized view.

Correctness oracle:

- final logical tree equals the AgentFS-derived expected tree;
- edited paths select the upper object;
- unchanged paths select the base object;
- deleted/whiteout paths are absent from lookup and readdir;
- symlink behavior matches the selected lower object;
- cache-invalidation or cached-negative transitions become visible;
- host/base tree remains unmodified except for explicitly declared lower-FS
  state files;
- lower-FS permission, data path, writes, page cache, and persistence semantics
  are preserved.

## Comparison

The main comparison for RQ2 is a feature-equivalent FUSE policy implementation.
It must use the same source tree, state machine, logical paths, operation mix,
and correctness oracle as the `namei_ext` run. The FUSE daemon must not receive
weaker information or a weaker oracle. If the FUSE row is incomplete, the RQ2
result is incomplete rather than a win for `namei_ext`.

Controls:

- no-hook or lower-FS control for interpreting pass-through overhead;
- malformed or unsupported policy decision control for RQ3 containment;
- source AgentFS behavior as oracle provenance and boundary evidence, not as a
  performance baseline unless the same oracle and operation mix can be run.

RQ3 comparison:

- account for the filesystem methods, daemon state, privileged code surface,
  and storage semantics owned by FUSE/custom/stackable filesystems;
- use AgentFS, BranchFS, YoloFS, Mirage, Bento, Wrapfs, and ExtFUSE evidence
  where a full custom-FS implementation would only repeat prior work;
- avoid copy/symlink/bind/Overlay/projected-volume rows in the main matrix
  unless they directly change one RQ under the same oracle.

## Planned Runs

All project-owned execution must go through Make targets. The exact target
names should be added with the implementation, but the owning run families are:

| Run family | Role | Required output |
| --- | --- | --- |
| Agent workspace preflight | dependency | One state transition through the real `cgroup/namei_ext` KVM attach path, with raw stdout/stderr, dmesg, policy identity, and oracle output. |
| Agent workspace full `namei_ext` | proposed system | Full fixed workload and oracle through KVM, including operation-weighted lookup/readdir traces and lower-FS semantic checks. |
| Agent workspace FUSE policy | RQ2 comparison | Same workload, state machine, and oracle through feature-equivalent FUSE, with daemon request counts and latency/runtime rows. |
| No-hook/lower-FS control | overhead control | Same operation mix where meaningful, used only to interpret overhead. |
| Invalid-policy control | RQ3 safety control | Verifier/kernel validation and failure containment for malformed or unsupported decisions. |
| Result review | paper gate | Valid/invalid/incomplete verdict, hypothesis impact, FUSE fairness audit, lower-FS audit, and boundary-evidence audit. |

Raw artifacts belong under `results/experiments/agent-workspace/<RUN_ID>/` or
an equivalent documented result root. The result review should be a dated
Markdown record under `docs/tmp/` and should reference raw artifacts, not embed
aggregated-only evidence.

## Metrics

Correctness gates every row:

- source oracle pass/fail;
- lookup/readdir coherence;
- final-tree hash or manifest diff;
- whiteout absence in lookup and readdir;
- symlink target behavior;
- lower-FS permission/write/data-path/page-cache/persistence checks;
- mechanism engagement: cgroup attach, policy object hash, map state, and
  operation-weighted decision trace.

RQ2 metrics after correctness:

- lookup, open, stat, access, exec, and readdir latency;
- macro command runtime;
- operation-weighted policy invocation rate;
- pass-through overhead and action-specific overhead;
- FUSE daemon request counts, context switches, and request-path cost;
- repetitions and uncertainty for any performance number used in the paper.

RQ3 metrics:

- policy code size and privileged code surface;
- required filesystem methods for the FUSE/custom/stackable alternative;
- daemon/process ownership and failure surface;
- verifier/kernel validation behavior;
- malformed-decision containment.

## Interpretation

Supported:

- the `namei_ext` full run passes the same source-derived oracle;
- lower-FS semantics are preserved;
- the FUSE row passes the same oracle and has higher or otherwise clearly
  characterized policy-path cost;
- boundary evidence shows `namei_ext` avoids owning filesystem methods or data
  semantics that the workload oracle does not require.

Contradicted:

- the oracle needs synthetic contents, custom metadata persistence,
  post-open data-path mediation, write conflict resolution, or agent
  orchestration that cannot be moved out of the filesystem boundary;
- lower-FS semantics are not preserved;
- the FUSE row is feature-equivalent and has equal or better cost without a
  boundary tradeoff that matters for RQ3.

Incomplete:

- only the redirect preflight runs;
- the FUSE row is not feature-equivalent;
- operation-weighted traces or lower-FS checks are missing;
- correctness fails before performance can be interpreted.

The hypothesis should be redesigned only if the full experiment shows that the
source-derived path-view slice actually requires broader filesystem ownership.
An underbuilt prototype or incomplete comparison does not justify shrinking the
paper to a smaller claim.
