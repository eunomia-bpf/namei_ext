# LPC Proposal Draft: BPF Policy At VFS Name Resolution

Date: 2026-07-23
Status: submission-ready draft for the LPC 2026 eBPF Track, plus a
microconference/upstream discussion version
Target audience: BPF, VFS, filesystem, LSM, containers/build systems, and
`sched_ext` reviewers

Note: Linux Plumbers Conference 2026 is scheduled for 2026-10-05 to
2026-10-07 in Prague. The official Refereed Track, Kernel Summit, and BoF
submission deadline listed by LPC was 2026-06-28, which has passed as of this
document date. The eBPF Track proposal deadline is 2026-07-24, and
Microconference Subtopic proposals close on 2026-08-07. The immediate action is
to submit this to the eBPF Track, then reuse it for maintainer outreach and
microconference discussion.

## Submission Fields

| Field | Value |
| --- | --- |
| Track | eBPF Track |
| Alternative venue | Microconference Subtopic, likely Filesystems, BPF, Build Systems, Containers/checkpoint-restore, or `sched_ext` adjacent discussion |
| Format | 30-minute talk/discussion for eBPF Track |
| Title | `namei_ext: BPF Policy at VFS Name Resolution Without Owning a Filesystem` |
| Audience | BPF developers, VFS/filesystem maintainers, LSM reviewers, container/build-system developers |
| Desired outcome | Early upstream feedback before an RFC patch series |
| Required attendees | BPF maintainers/reviewers, VFS/pathname lookup reviewers, filesystem/FUSE reviewers, LSM reviewers |

## Proposed Title

`namei_ext`: BPF Policy at VFS Name Resolution Without Owning a Filesystem

## Abstract To Submit

Many Linux workloads need a dynamic view of existing filesystem objects without
wanting to implement a filesystem. Agent workspaces, build caches, service
configuration rollouts, and checkpoint/restart flows often need to decide at
lookup time which existing object a pathname should denote, or whether that
object should be hidden, while leaving ordinary data, writes, permissions,
page-cache behavior, and persistence to the lower filesystem.

This proposal discusses `namei_ext`, an experimental VFS extension point that
lets a constrained BPF program participate in pathname lookup and directory
enumeration decisions. The intended boundary is similar in spirit to
`sched_ext`: policy is programmable, but subsystem ownership remains in the
kernel. `namei_ext` is not a BPF filesystem. It does not ask BPF to implement
file operations or data-path semantics.

We will present the current prototype, KVM validation path, and early results:
Agent-workspace source-trace oracles pass through both `namei_ext` and FUSE,
and a Redis/nginx ccache build-cache workload passes 400/400 output-hash
checks under `namei_ext`, native hot ccache, and a feature-equivalent FUSE
cache view. The goal of the session is to get upstream feedback on whether this
is the right VFS/BPF boundary, what restrictions are necessary, and what
selftests and API shape would be required before an RFC patch series.

## Short Pitch For Maintainer Email

We are looking for early VFS/BPF feedback on whether a constrained BPF policy
hook at name resolution is a viable boundary for dynamic path views over
existing filesystem objects, before turning the prototype into an RFC patch
series.

`namei_ext` is not a BPF filesystem. The policy only participates in bounded
lookup/readdir decisions; the VFS and lower filesystem still own dentries,
inodes, file operations, writes, permissions, page cache, and persistence. The
current prototype has KVM evidence from Agent-workspace traces and a
Redis/nginx ccache workload with a matched FUSE comparison.

## Problem

Today, a developer who needs dynamic path views usually chooses one of four
families:

- construct or update namespace state with bind mounts, OverlayFS, symlinks,
  projected volumes, or copies;
- mediate access with eBPF LSM, which is naturally an authorization boundary,
  not an object-selection boundary;
- implement a FUSE filesystem, taking a userspace filesystem daemon and
  request path into the design;
- build or modify a custom/stackable filesystem and own broader filesystem
  methods.

The missing point is a narrow programmable boundary for pathname policy over
existing lower filesystem objects.

## Proposed Mechanism

`namei_ext` adds a VFS name-resolution extension point with one BPF decision
function. Lookup and directory enumeration are event types passed to that
function. The BPF policy can return bounded decisions such as selecting an
existing registered target, hiding an entry, or controlling a directory view.
The kernel keeps ownership of dentries, inodes, file operations, data I/O,
permissions, page cache, writeback, and persistence.

The current prototype is cgroup-scoped and validates policies through a real
KVM boot of the modified kernel. Policies are normal eBPF programs, for
example `bpf/policies/cache_locality_view.bpf.c`.

## Current Evidence

### Agent Workspace

Three formal KVM runs bind an AgentFS-derived trace to both `namei_ext` and a
feature-equivalent FUSE implementation. Each run contains 1,176 JSONL records,
zero failed records, successful same-oracle summaries, empty stderr, and clean
dmesg failure-signature gates.

Covered behavior includes epoch selection, whiteout lookup/readdir coherence,
source and `.git` visibility, symlink and executable behavior, cached-negative
creation, rename, unlink, final-tree state, lower-tree non-materialization, and
unregistered-target containment.

### Traditional Build/Cache

Release command:

```sh
make experiment-env-cache BUILD_CACHE_SAMPLES=20 RUN_ID=20260723T-build-cache-release-v1
```

The release row runs Redis/nginx source compiles through ccache and compares
`namei_ext`, native hot ccache, and a feature-equivalent FUSE cache view.

| Metric | `namei_ext` | Native hot ccache | Feature-equivalent FUSE |
| --- | ---: | ---: | ---: |
| Samples | 20 | 20 | 20 |
| Compile jobs | 400 | 400 | 400 |
| Output hash matches | 400 | 400 | 400 |
| Total compile ns | 152,263,433,153 | 157,443,184,178 | 267,748,534,960 |
| Average ns/job | 380,658,582.9 | 393,607,960.4 | 669,371,337.4 |
| Cache object ops | 3,200 | 3,200 | 3,200 |

The matched FUSE row completes the same output oracle but owns a userspace
filesystem-service boundary with `getattr/readdir/open/read/release` handling
and mount lifecycle. The `namei_ext` row executes an attached
`cache_locality_view.bpf.c` policy through the real KVM `cgroup/namei_ext`
path while ccache and the lower filesystem keep data/write semantics.

## Known Limits

- The build/cache release row covers verified hot-cache object selection, not
  the full miss/stale/corrupt/epoch state machine.
- The current FUSE comparison is feature-equivalent for the tested oracle, but
  broad performance claims must account for FUSE optimizations and passthrough.
- The prototype needs kernel selftests, API docs, and explicit locking/RCU
  analysis before an RFC patch series.
- The upstream question is not whether this replaces FUSE, OverlayFS, or LSM.
  The question is whether there is a useful narrower boundary for pathname
  policy over existing filesystem objects.

## Discussion Questions For LPC

1. Is VFS name resolution an acceptable place for a constrained BPF policy if
   the kernel retains object and data-path ownership?
2. Which parts of path walk can safely call such a policy, and what must happen
   under RCU-walk versus ref-walk?
3. Should the attach model be cgroup-scoped, mount-scoped, namespace-scoped, or
   something else?
4. Which policy actions are acceptable for an RFC: select existing target,
   hide, directory-enumeration filtering, fail closed?
5. What verifier restrictions are required for bounded runtime, memory access,
   path component handling, and failure containment?
6. How should this interact with eBPF LSM? Should LSM remain purely
   authorization while `namei_ext` handles object selection?
7. What is the minimum selftest suite reviewers would require?
8. Which workloads would convince VFS/filesystem maintainers that this is a
   real need rather than a FUSE convenience wrapper?

## Requested Upstream Feedback

- Hook location and acceptable VFS invariants.
- Exact ABI surface for the first RFC.
- Policy action subset that is small enough to review.
- Required selftests and negative tests.
- Whether the idea should be discussed first with VFS, BPF, LSM, filesystems,
  containers, or build-system maintainers.

## Proposed Session Shape

For the LPC eBPF Track 30-minute format:

1. 4 minutes: workload problem and why eBPF LSM/FUSE/custom FS are different
   boundaries.
2. 8 minutes: proposed VFS/BPF mechanism and current cgroup attach path.
3. 7 minutes: KVM evidence from Agent workspace and build/cache.
4. 8 minutes: safety/API questions: hook point, RCU/ref-walk, verifier,
   allowed actions, and selftests.
5. 3 minutes: requested maintainer feedback and next RFC steps.

For a 20-minute microconference subtopic discussion:

1. 3 minutes: workload problem and missing-middle boundary.
2. 5 minutes: proposed VFS/BPF mechanism and safety constraints.
3. 5 minutes: KVM evidence from Agent workspace and build/cache.
4. 7 minutes: open design questions and maintainer feedback.

For a 45-minute track talk:

1. 8 minutes: motivation and prior mechanism boundaries.
2. 10 minutes: design and ABI.
3. 10 minutes: implementation and verifier/containment model.
4. 10 minutes: evaluation results and limits.
5. 7 minutes: upstream roadmap and discussion.

## Local Artifacts

- Upstream reference packet:
  `docs/tmp/2026-07-23-lpc-reference-map.md`
- Current-state report:
  `docs/tmp/2026-07-23-current-state-lpc-status.md`
- Build/cache plan:
  `docs/tmp/2026-07-23-build-cache-experiment-b-plan.md`
- Build/cache result report:
  `docs/tmp/2026-07-23-build-cache-lpc-result-report.md`
- Build/cache raw root:
  `results/experiments/build-cache/20260723T-build-cache-release-v1/`
- Current commit with raw result:
  `ce87d81 Add build cache experiment matrix`

## References

See `docs/tmp/2026-07-23-lpc-reference-map.md`.
