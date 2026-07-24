# LPC Reference Map

Date: 2026-07-23
Scope: primary references for the current `namei_ext` LPC/upstream discussion
draft. This is not a complete related-work survey.

## Local Evidence References

| Evidence | Local path | Use |
| --- | --- | --- |
| Current status report | `docs/tmp/2026-07-23-current-state-lpc-status.md` | Canonical snapshot of what is complete and what remains open. |
| LPC proposal draft | `docs/tmp/2026-07-23-lpc-proposal-namei-ext.md` | Upstream discussion draft. |
| Build/cache experiment plan | `docs/tmp/2026-07-23-build-cache-experiment-b-plan.md` | Scoped Experiment B plan for verified-hot-cache release row. |
| Build/cache result report | `docs/tmp/2026-07-23-build-cache-lpc-result-report.md` | Result review and LPC interpretation for the release run. |
| Build/cache raw result root | `results/experiments/build-cache/20260723T-build-cache-release-v1/` | Raw JSONL, hashes, dmesg, stdout/stderr, kernel provenance. |
| Build/cache terminal summary | `results/experiments/build-cache/20260723T-build-cache-release-v1/build-cache-matrix.jsonl` | `namei_ext`/native/FUSE correctness and timing summary. |
| Agent workspace formal runs | `results/experiments/agent-workspace-matrix/20260722T020120Z-rq1run1/`, `results/experiments/agent-workspace-matrix/20260722T020210Z-rq1run2/`, `results/experiments/agent-workspace-matrix/20260722T020245Z-rq1run3/` | RQ1 source-trace evidence for Agent workspace behavior. |

## Venue And Format References

| Source | Link | Relevance |
| --- | --- | --- |
| LPC 2026 Call for Proposals | https://lpc.events/event/20/abstracts/ | Official dates and proposal categories. It says LPC 2026 is in Prague on 2026-10-05 to 2026-10-07, and Refereed Track proposals closed on 2026-06-28. |
| LPC 2026 overview | https://lpc.events/ | Frames LPC as a developer conference for Linux plumbing/core design problems. Useful for explaining why the proposal asks for design feedback, not only presenting paper results. |
| LPC 2026 topics/blog | https://lpc.events/blog/current/ | Shows relevant microconference families such as Build Systems, Containers and checkpoint/restore, Linux System Monitoring and Observability, Safe Systems with Linux, and `sched_ext`. |
| LPC 2026 FAQ | https://lpc.events/event/20/page/283-faqs | Notes microconference proposals are closed and need maintainer/community buy-in. This supports treating the current proposal as a discussion draft. |

## Kernel Mechanism References

| Source | Link | Relevance to `namei_ext` |
| --- | --- | --- |
| Linux kernel pathname lookup documentation | https://docs.kernel.org/filesystems/path-lookup.html | Primary VFS context for path walk, RCU-walk, and ref-walk. This is the core safety/placement reference for an upstream discussion. |
| Linux kernel `sched_ext` documentation | https://docs.kernel.org/scheduler/sched-ext.html | Primary analogy: BPF policy customizes subsystem behavior while the kernel retains subsystem machinery. Do not overclaim equivalence; use only as an architectural analogy. |
| Linux kernel BPF LSM documentation | https://docs.kernel.org/bpf/prog_lsm.html | Boundary reference: BPF LSM instruments LSM hooks for MAC/audit policy, while `namei_ext` targets object selection during name resolution. |
| Linux kernel BPF documentation index | https://docs.kernel.org/bpf/ | General kernel-side BPF reference for verifier/program-type context. |

## Filesystem Comparison References

| Source | Link | Relevance |
| --- | --- | --- |
| Linux kernel FUSE documentation | https://www.kernel.org/doc/html/next/filesystems/fuse.html | Primary reference that FUSE is a userspace filesystem framework with kernel module, userspace library, and mount utility. |
| libfuse API documentation | https://libfuse.github.io/doxygen/ | Primary/reference implementation context for FUSE as a userspace filesystem interface and request/callback model. |
| FUSE passthrough documentation | https://source.android.com/docs/core/storage/fuse-passthrough | Mechanism pressure for RQ2: optimized FUSE can bypass daemon read/write requests after open. This must be acknowledged before broad performance claims. |
| Linux kernel OverlayFS documentation | https://docs.kernel.org/filesystems/overlayfs.html | Related namespace/materialization mechanism. Use as background, not the main RQ3 baseline. |

## Workload References

| Source | Link | Relevance |
| --- | --- | --- |
| ccache manual | https://ccache.dev/manual/3.7.9.html | Official workload/tool reference for cache hits, misses, and correctness expectations. The current run uses ccache stats and output hashes as oracle/control evidence. |

## Claim-To-Reference Map

| Claim or design pressure | Supporting references | Current evidence |
| --- | --- | --- |
| Pathname lookup is a core VFS subsystem and must be treated with locking/RCU care. | Linux pathname lookup documentation. | Prototype runs in KVM; upstream hook-location review still required. |
| BPF can be used as programmable policy while kernel subsystem machinery remains in-kernel. | `sched_ext` documentation. | `namei_ext` mirrors this as an analogy for name resolution, not as a scheduler feature. |
| eBPF LSM is not the same boundary because it is security/MAC/audit oriented. | BPF LSM documentation. | `namei_ext` evaluates object-selection policy, not only authorization. |
| FUSE is the strongest RQ2 comparison because it can implement the same policy with a filesystem daemon. | Kernel FUSE and libfuse docs. | Build/cache has a feature-equivalent FUSE row with the same output oracle. |
| Broad FUSE performance claims require acknowledging optimized FUSE. | FUSE passthrough documentation. | Current run reports release-run timing only; no broad superiority claim. |
| Materialized namespace mechanisms are related mechanisms, not the central baseline. | OverlayFS documentation plus local user-instruction file. | Current docs keep Overlay/materialization as background unless a source oracle makes it load-bearing. |
| Real build/cache workload evidence exists. | ccache manual plus local build/cache raw root. | Redis/nginx ccache verified-hot-cache row passes under `namei_ext`, native, and FUSE. |

## Reference Gaps Before RFC

- Exact kernel mailing-list discussion targets for VFS and BPF maintainers.
- Any recent in-tree FUSE passthrough status in the target kernel version used
  for an RFC.
- Existing selftests around comparable BPF attach points and VFS path-walk
  behavior.
- Prior LKML discussions about programmable VFS/namei hooks, if any.
