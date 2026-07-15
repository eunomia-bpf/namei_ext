# Claim, Novelty, Workload, And Baseline Pressure

Timestamp: 2026-07-13T00:56:32-07:00
Phase: BOOTSTRAP
Step: `docs/tmp/bootstrap/step-0002-20260713T004618-0700/`
Gate: 01-experiment-gate
Status: completed

## Question

Can the current candidate story be admitted for the rest of BOOTSTRAP?

Candidate story:

- `namei_ext` is a `sched_ext`-style VFS name-resolution extension point.
- The programmable unit is a bounded eBPF decision function over lookup and
  directory-enumeration events.
- The kernel and lower filesystem keep ownership of VFS objects, file methods,
  permissions, data path, page cache, persistence, and ordinary consistency.
- The paper evaluates the point between eBPF LSM and FUSE/custom filesystem
  ownership, not a table-only mechanism and not a materialized-view shootout.

## Inputs

Local inputs:

- `docs/user-instruction.md`
- `docs/idea-story.md`
- `docs/design.md`
- `docs/evaluation.md`
- `docs/implementation.md`
- `docs/background-related-work.md`
- `docs/reference/CODE_SOURCES.md`
- `docs/tmp/bootstrap/step-0002-20260713T004618-0700/step-report.md`

Primary external checks:

- Linux `sched_ext` documentation:
  <https://docs.kernel.org/scheduler/sched-ext.html>
- Linux BPF LSM documentation:
  <https://docs.kernel.org/bpf/prog_lsm.html>
- Linux FUSE documentation:
  <https://www.kernel.org/doc/html/next/filesystems/fuse.html>
- Linux FUSE passthrough documentation:
  <https://docs.kernel.org/6.17/filesystems/fuse-passthrough.html>
- ExtFUSE repository and ATC 2019 paper:
  <https://github.com/extfuse/extfuse>,
  <https://www.usenix.org/system/files/atc19-bijlani.pdf>
- FUSE-BPF patch series:
  <https://patchew.org/linux/20230418014037.2412394-1-drosen%40google.com/>
- AgentFS:
  <https://github.com/tursodatabase/agentfs>
- BranchFS:
  <https://github.com/multikernel/branchfs>
- YoloFS paper:
  <https://arxiv.org/abs/2604.13536>
- Mirage:
  <https://github.com/strukto-ai/mirage>
- Redis Agent Filesystem:
  <https://github.com/redis/agent-filesystem>
- SWE-Factory:
  <https://github.com/deepsoftwareanalytics/swe-factory>
- MEnvAgent and MEnvData-SWE:
  <https://github.com/ernie-research/MEnvAgent>,
  <https://huggingface.co/datasets/ernie-research/MEnvData-SWE>
- SWE-rebench V2:
  <https://github.com/SWE-rebench/SWE-rebench-V2>
- Multi-Docker-Eval:
  <https://github.com/Z2sJ4t/Multi-Docker-Eval>

## Same-Claim Pressure

| Neighbor | What it already proves | Same-claim risk | Pressure on our framing |
| --- | --- | --- | --- |
| `sched_ext` | BPF can safely express policy inside a kernel-owned subsystem, with dynamic enable/disable and kernel containment. | Low as prior art for filesystems; high as analogy. | Use it as the extension-point pattern, not as evidence for VFS. |
| BPF LSM and fanotify | Kernel/user policies can mediate security or permission decisions. | Medium if we describe `namei_ext` as "filesystem policy" too broadly. | State the action-space delta: `namei_ext` selects bounded pathname-to-object visibility/targeting; LSM/fanotify primarily allow, deny, audit, or notify. |
| FUSE | Userspace can implement arbitrary filesystem behavior. | High as RQ2 baseline. | RQ2 must compare feature-equivalent FUSE over the same oracle and not strawman FUSE. |
| FUSE passthrough, ExtFUSE, FUSE-BPF | FUSE can be accelerated or extended with kernel-side fast paths/BPF-like request handling. | High as closest mechanism pressure. | Treat as related-work pressure inside the FUSE/stacked-filesystem boundary. They do not remove the need to show the value of a VFS name-resolution-only boundary. |
| Bento, Wrapfs, custom/stackable FS | Developers can build safer or more reusable filesystems. | Medium for RQ3. | RQ3 should be a boundary/safety accounting against method ownership and containment, not a performance race against every filesystem framework. |
| DeltaFS, IndexFS, TableFS | Metadata services and stacked filesystems improve namespace/metadata-heavy workloads. | Low for same mechanism; medium as background. | Use as boundary/non-goal context, not as main runnable baselines. |

Verdict: no checked source already claims a narrow verified BPF-controlled VFS
name-resolution policy boundary that preserves lower-filesystem object and data
semantics. The surrounding area is crowded, so the paper must be precise: the
novelty is the boundary and action space, not merely programmability,
dynamism, or agent filesystems.

## Workload Pressure

| Workload family | Source systems | Source-derived state | Oracle shape | Fit |
| --- | --- | --- | --- | --- |
| Agent workspace lifecycle | AgentFS, BranchFS, YoloFS, Mirage, Redis AFS, Sandlock, OpenHands/SWE-agent context | branch/fork/checkpoint, COW upper/base state, hidden/staged entries, symlink/cache invalidation, snapshot/final tree | source workspace operation succeeds, final tree or checkpoint state matches, lower-FS semantics remain intact | Strong headline. Agent systems repeatedly use FUSE, NFS, runtime, or custom FS because they need workspace semantics; our experiment should test the narrower name-resolution subset with the same oracle. |
| Environment/cache transition | SWE-Factory, MEnvAgent/MEnvData-SWE, SWE-rebench V2, Multi-Docker-Eval, DockSmith context | environment identity, cache hit/miss, stale/corrupt rejection, epoch changes, canonical fallback | build/test/eval oracle passes; stale/corrupt state rejected or falls back; cache transition trace observed | Strong second family if tied to real eval rows rather than a toy cache. |
| Service/config transition | Kubernetes projected volumes, OverlayFS, service reload/config-rotation systems | config object selection, epoch/secret/cert rotation | service-visible behavior changes because lookup resolved a different object | Conditional only. Admit if there is a real lookup-time object-selection oracle; otherwise keep in related work. |

Decision: two deep families are stronger than three shallow families. Agent
workspace and environment/cache should remain the main complete experiments.
Service/config is useful only if it produces a concrete lookup-time oracle.

## Baseline Pressure

The evaluation should not keep rotating through weak opponents. Each comparison
must answer one RQ:

| RQ | Baseline/comparison | Required discipline |
| --- | --- | --- |
| RQ1 expressiveness/sufficiency | Source/native oracle behavior | The oracle must come from a real source system or dataset. Source behavior establishes correctness, not a proposed-method win. |
| RQ2 cost/overhead | Feature-equivalent FUSE policy | Same source oracle, same policy inputs, same state-update schedule, same correctness gate. Account for FUSE caching/passthrough where fairness requires it. |
| RQ3 safety/boundary | Custom or stackable filesystem ownership, including FUSE-derived systems when relevant | Account for filesystem methods, daemon/state ownership, privileged code surface, verifier/kernel validation, invalid-policy containment, and lower-FS preservation. |
| Overhead attribution | No-hook/lower-FS controls | Controls are necessary for attribution but are not a central baseline. |
| Related-work context | bind mounts, OverlayFS, projected volumes, symlinks, copies, table redirects | Cite and position. Do not make them the main paper fight unless a selected source oracle makes one a direct operator baseline. |

Decision: stop treating `table_redirect.bpf.c`, static tables, and materialized
views as the novelty gate. They may remain historical artifacts or background,
but they do not answer the current paper story.

## OSDI/SOSP Paper-Value Decision

The current candidate is strong enough to continue BOOTSTRAP, but not yet
frozen. It should be routed to the rest of the BOOTSTRAP gates with these
conditions:

1. The paper's contribution remains design plus implementation of the
   `namei_ext` boundary. Workload characterization is input selection, not the
   core contribution.
2. RQs remain:
   - RQ1: expressiveness/sufficiency for real state-dependent path-view policy.
   - RQ2: cost/overhead versus feature-equivalent FUSE.
   - RQ3: safety/boundary versus custom or stackable filesystem ownership.
3. The main evaluation promise is a small number of complete matrices:
   Agent workspace lifecycle first; environment/cache transition second;
   service/config only if admitted by a real source oracle.
4. FUSE-BPF and ExtFUSE must appear as closest related-work pressure. They do
   not automatically become new baselines, but they prevent a simplistic
   "FUSE is slow" story.
5. Negative or incomplete prototype results should not shrink the hypothesis.
   They should trigger stronger experiment design unless they demonstrate that
   the hypothesis itself is impossible.

## Must Not Do

- Do not claim the source workloads intrinsically require eBPF or only
  `namei_ext` can implement them.
- Do not make table-only failure the core novelty.
- Do not admit scattered microbenchmarks or dependency checks as paper results.
- Do not compare against intentionally weak FUSE.
- Do not turn RQ3 into a broad reimplementation contest against every prior
  filesystem.

## Next Routing

Proceed inside BOOTSTRAP step 0002:

1. Update canonical related-work and evaluation docs to reflect this pressure.
2. Run an independent outer audit of the updated candidate.
3. Produce an EXPERIMENT_GATE report.
4. Route to WRITE_GATE only if the audit finds no must-fix story/RQ/baseline
   blockers.
