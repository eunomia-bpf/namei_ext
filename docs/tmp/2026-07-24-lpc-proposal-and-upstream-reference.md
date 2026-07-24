# LPC Proposal And Upstream Reference Packet

Date: 2026-07-24
Status: draft packet for LPC eBPF Track and upstream discussion
Repository: `/home/yunwei37/workspace/namei_ext`

## LPC Submission Status

The official LPC 2026 CFP page lists Linux Plumbers Conference 2026 for
2026-10-05 through 2026-10-07 in Prague. The Refereed Track and Kernel Summit
deadlines are closed. The eBPF Track proposal deadline is 2026-07-24, and the
Microconference Subtopic deadline is 2026-08-07.

Practical action: submit this as an eBPF Track discussion proposal first, then
reuse the same packet for filesystem and BPF maintainer outreach and, if useful,
as a Filesystems/eBPF microconference subtopic.

## Proposal Title

`namei_ext`: a sched_ext-style eBPF extension point for VFS name resolution

## Short Abstract

Many Linux workloads need dynamic path views without wanting to own a whole
filesystem. Examples include agent workspaces with staged or hidden effects,
build/cache systems that select verified local objects or canonical backing
objects by cache state, and service/runtime setups that switch path views across
epochs. Today these policies are usually implemented with bind mounts,
OverlayFS/materialization, LSM allow/deny hooks, FUSE daemons, or custom
filesystems. Those mechanisms are useful, but they sit at different boundaries:
some only construct static namespaces, some cannot select an alternate VFS
object, and FUSE/custom filesystems take ownership of filesystem methods,
daemon lifetime, and failure modes.

We propose `namei_ext`, a narrow VFS name-resolution extension point. A
cgroup-scoped eBPF program is invoked during lookup and directory enumeration
and returns bounded actions such as pass, hide, or select a registered target.
The BPF program decides name-resolution policy; the VFS and lower filesystem
retain ownership of inodes, dentries, permissions, data path, writes, page
cache, persistence, and filesystem-specific semantics. The design is analogous
to `sched_ext`: policy is programmable, while the subsystem machinery remains
in the kernel.

This talk asks for early kernel feedback on the boundary, not acceptance of a
finished ABI. We will present the current prototype, the cgroup attachment
model, verifier and fail-closed constraints, RCU/ref-walk constraints at the
hook point, and KVM evidence from two source-derived workloads: an AgentFS-like
workspace lifecycle and a Redis/nginx ccache build/cache workload with a
feature-equivalent FUSE comparison.

## Long Pitch

The design target is the space:

```text
bind/Overlay/materialization < eBPF LSM < namei_ext < FUSE/custom FS
```

`namei_ext` is not a BPF filesystem. It does not synthesize file contents, own
metadata persistence, intercept reads and writes, implement copy-on-write, or
replace filesystem operations. It only lets a policy participate in path
resolution when the desired behavior is a state-dependent path view.

The current prototype exposes one BPF decision function. Lookup and directory
enumeration are event types passed to that one function. Policies are ordinary
eBPF C programs, for example `bpf/policies/cache_locality_view.bpf.c`. The
current experiments attach through the real `cgroup/namei_ext` KVM path in a
modified kernel.

The talk should focus on kernel questions:

- Is VFS name resolution a plausible BPF extension boundary, or should this
  remain entirely in LSM/FUSE/filesystems?
- What restrictions are required to preserve VFS pathname lookup invariants,
  especially RCU-walk to REF-walk fallback, dentry stability, and mount/rename
  seqlock assumptions?
- Should the attachment model be cgroup-scoped, mount-scoped, fs-scoped, or
  some combination?
- Which actions are acceptable for an upstreamable first version: pass, fail
  closed, hide, select registered target, readdir aliasing?
- What should invalid policy decisions do: fail closed, fall back to original
  lookup, or disable the attachment?
- What selftests and documentation would make filesystems and BPF reviewers
  comfortable?
- How should this relate to eBPF LSM, FUSE passthrough, OverlayFS/idmapped
  mounts, and future filesystem stacking work?

## Current Evidence To Mention

Agent workspace RQ1:

- Three formal KVM runs under
  `results/experiments/agent-workspace-matrix/20260722T020120Z-rq1run1/`,
  `20260722T020210Z-rq1run2/`, and `20260722T020245Z-rq1run3/`.
- Each run has zero failed JSONL records, same-oracle `namei_ext` and FUSE
  summaries, empty stderr, and clean dmesg gates.
- Covered behavior includes epoch selection, whiteout lookup/readdir coherence,
  `.git` and source visibility, symlink/executable behavior, cached-negative
  creation, rename, unlink, final-tree state, lower-tree non-materialization,
  and unregistered-target containment.

Traditional build/cache:

- Release run `results/experiments/build-cache/20260723T-build-cache-state-release-v1/`
  covers 20 samples, 400 Redis/nginx ccache compile jobs for each of
  `namei_ext`, native hot ccache control, and feature-equivalent FUSE.
- All 1,200 output objects match the hot-object oracle.
- That release also contains a trace-derived state row over real ccache object
  names for verified-local to canonical epoch selection.
- The 2026-07-24 real compile epoch-switch release run
  `results/phase1/20260724T-epoch-switch-release-v2/` passed with 20 samples.
  `namei_ext` and FUSE each compiled 400 source objects in epoch 1 and 400 in
  epoch 2, and all 1,600 epoch outputs matched the native hot-object oracle.
  The run recorded 20 BPF policy session updates and 20 FUSE mounts. FUSE was
  `2.095x` the `namei_ext` total epoch compile time in this run.

Do not overclaim:

- Do not say the full miss/stale/corrupt build/cache compile state machine is
  closed until those cells run through the real compile oracle.
- Do not claim broad FUSE superiority. The correct claim is a matched workload
  comparison against a feature-equivalent FUSE policy, with optimized FUSE work
  treated as mechanism pressure.
- Do not present this as a table-redirection or materialization-failure paper.

## Upstream Reference Material

Send maintainers a small packet, not the full paper history:

- Prototype branch and patch summary.
- Kernel hook/API note: action enum, context fields, cgroup attach path,
  registered-target lifetime, verifier restrictions, and fail-closed behavior.
- Minimal demo command that runs in KVM in minutes.
- Selftest plan for lookup, readdir, hide, target selection, invalid actions,
  cgroup scoping, policy unload, and lower-filesystem permission/write
  preservation.
- RCU/ref-walk safety note explaining where the hook runs, what it can inspect,
  why it cannot sleep, and when the kernel falls back or fails closed.
- Boundary note comparing the same policy against eBPF LSM, FUSE, OverlayFS,
  bind mounts, and custom/stackable filesystems.
- Result summary for the two current workloads and raw-result roots.

Primary upstream references:

- LPC 2026 CFP: `https://lpc.events/event/20/abstracts/`
- Linux pathname lookup documentation:
  `https://docs.kernel.org/filesystems/path-lookup.html`
- `sched_ext` documentation:
  `https://docs.kernel.org/scheduler/sched-ext.html`
- BPF LSM documentation:
  `https://docs.kernel.org/bpf/prog_lsm.html`
- FUSE documentation:
  `https://docs.kernel.org/filesystems/fuse/fuse.html`
- FUSE passthrough documentation:
  `https://docs.kernel.org/next/filesystems/fuse-passthrough.html`
- BPF selftests reference path in a kernel tree:
  `tools/testing/selftests/bpf/`
- Filesystem selftests reference path in a kernel tree:
  `tools/testing/selftests/filesystems/`

Local paper and evidence references:

- Current story: `docs/idea-story.md`
- Evaluation plan: `docs/evaluation.md`
- Design: `docs/design.md`
- Implementation: `docs/implementation.md`
- Related work: `docs/background-related-work.md`
- Reference index: `docs/reference/INDEX.md`
- Code/source catalog: `docs/reference/CODE_SOURCES.md`
- Build/cache epoch-switch plan:
  `docs/tmp/2026-07-24-build-cache-real-compile-epoch-plan.md`

## Suggested Maintainer Email Shape

Subject:

```text
[RFC bpf/vfs] namei_ext: eBPF policy for VFS name-resolution decisions
```

Body outline:

```text
This is an early RFC for a narrow VFS name-resolution BPF extension point.
The goal is not to implement a BPF filesystem. The BPF program returns bounded
decisions during lookup/readdir, while VFS and the lower filesystem keep object,
permission, data-path, write, page-cache, and persistence semantics.

The use cases we are testing are agent workspaces and build/cache path views.
The attached prototype is cgroup-scoped and KVM-tested. We are looking for
feedback on whether this is a plausible boundary, what hook-point restrictions
are needed around RCU/ref-walk, which actions are acceptable for an initial ABI,
and what selftests would be required before a serious RFC series.

Pointers:
- design/API note:
- KVM demo command:
- selftest plan:
- raw result summary:
- LPC proposal:
```

Keep the first email focused on the kernel boundary and safety model. Put the
paper motivation and workload numbers below the fold.
