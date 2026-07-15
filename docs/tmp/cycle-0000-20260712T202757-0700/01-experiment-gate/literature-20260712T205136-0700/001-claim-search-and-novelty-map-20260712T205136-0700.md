# Literature Node: Claim Search And Novelty Map

Timestamp: 2026-07-12T20:51:36-0700
Cycle: 0000
Phase: BOOTSTRAP
Gate: 01-experiment-gate
Node: literature-20260712T205136-0700
Status: complete for BOOTSTRAP pressure; not final citation verification

## Question And Entry

This node asks whether the restored `namei_ext` story has a defensible novelty
gap and a credible OSDI/SOSP evaluation promise after closest-work pressure.
The node is required before empirical plan review because the previous work had
drifted toward table-only diagnostics and scattered weak baselines.

The active user intent fixes the high-level shape:

- RQ1: expressiveness/sufficiency of a narrow VFS name-resolution extension.
- RQ2: cost/overhead against feature-equivalent FUSE.
- RQ3: safety and ownership boundary against custom or stackable filesystems.
- Materialized namespace mechanisms are related-work/background context unless
  a concrete workload makes them the natural source behavior.
- Source systems select workloads and oracles; they are not by themselves
  claim-moving evidence.

## Claims Searched Without Project Names

The search stripped away project names and compared these plain claims:

1. A narrow VFS name-resolution hook can implement state-conditioned
   pathname-to-object or visibility policy over existing lower-filesystem
   objects while preserving ordinary lower-FS semantics.
2. A bounded eBPF decision function can sit on the name-resolution path without
   becoming a full filesystem or policy daemon.
3. Feature-equivalent FUSE is the closest cost baseline for programmable
   path-view policy.
4. Custom or stackable filesystems are the closest safety/ownership-boundary
   comparison when a workload needs only name-resolution policy.

## Search Branches And Sources

The node searched current primary sources and public artifact sources. Search
strings were grouped by threat category rather than by keyword volume.

| Branch | Example queries and source families | Primary sources checked |
| --- | --- | --- |
| Kernel-extension analogy and security hooks | `sched_ext Linux kernel docs`, `BPF_PROG_TYPE_LSM`, `eBPF LSM docs` | Linux `sched_ext` docs, Linux BPF LSM docs, eBPF LSM program-type docs |
| VFS and filesystem interception | `Linux VFS docs`, `fanotify`, `FUSE kernel docs`, `FUSE BPF patch` | Linux VFS docs, FUSE docs, fanotify man page/docs, FUSE-BPF patch series |
| FUSE acceleration and programmable filesystem boundary | `ExtFUSE eBPF FUSE`, `RFUSE ExtFUSE`, `Bento filesystem framework` | ExtFUSE repository/slides/paper leads, RFUSE paper lead, Bento FAST page |
| Agent/workspace source systems | `AgentFS`, `YoloFS`, `BranchFS`, `Sandlock`, `Mirage agent filesystem` | AgentFS repository/site/blog, YoloFS arXiv/site/code evidence from prior reproduction records, BranchFS arXiv/repository, Sandlock arXiv/repository, Mirage repository |
| Environment/cache source systems | `SWE-Factory`, `MEnvAgent`, `SWE-rebench V2`, `DockSmith` | SWE-Factory repository/arXiv, MEnvAgent repository/arXiv, SWE-rebench V2 repository/Hugging Face/arXiv, DockSmith arXiv |

Key source URLs recorded for later citation verification:

- Linux `sched_ext`: <https://docs.kernel.org/scheduler/sched-ext.html>
- Linux BPF LSM: <https://docs.kernel.org/bpf/prog_lsm.html>
- eBPF LSM program type: <https://docs.ebpf.io/linux/program-type/BPF_PROG_TYPE_LSM/>
- Linux VFS: <https://docs.kernel.org/filesystems/vfs.html>
- Linux FUSE: <https://www.kernel.org/doc/html/v5.18/filesystems/fuse.html>
- fanotify: <https://man7.org/linux/man-pages/man7/fanotify.7.html>
- FUSE-BPF patch series: <https://patchew.org/linux/20230418014037.2412394-1-drosen%40google.com/>
- ExtFUSE repository: <https://github.com/extfuse/extfuse>
- Bento FAST page: <https://www.usenix.org/conference/fast21/presentation/miller>
- AgentFS repository: <https://github.com/tursodatabase/agentfs>
- AgentFS FUSE blog: <https://turso.tech/blog/agentfs-fuse>
- BranchFS arXiv: <https://arxiv.org/html/2602.08199v1>
- BranchFS repository: <https://github.com/multikernel/branchfs>
- YoloFS arXiv: <https://arxiv.org/html/2604.13536v1>
- Sandlock arXiv: <https://arxiv.org/html/2605.26298v1>
- Sandlock repository: <https://github.com/multikernel/sandlock>
- Mirage repository: <https://github.com/strukto-ai/mirage>
- SWE-Factory repository: <https://github.com/deepsoftwareanalytics/swe-factory>
- SWE-Factory arXiv: <https://arxiv.org/html/2506.10954v2>
- MEnvAgent repository: <https://github.com/ernie-research/MEnvAgent>
- MEnvAgent arXiv: <https://arxiv.org/html/2601.22859v2>
- SWE-rebench V2 repository: <https://github.com/SWE-rebench/SWE-rebench-V2>
- SWE-rebench V2 Hugging Face dataset: <https://huggingface.co/datasets/nebius/SWE-rebench-V2>
- SWE-rebench V2 arXiv: <https://arxiv.org/html/2602.23866v1>
- DockSmith arXiv: <https://arxiv.org/abs/2602.00592>

## Closest-Work Findings

`sched_ext` supports the systems analogy, not the mechanism claim. It exposes
a verified programmable policy boundary while the kernel retains subsystem
machinery, but it is a scheduler interface rather than a VFS interface.

eBPF LSM is close in implementation style but different in boundary. It
attaches verified programs to LSM hooks and is naturally framed around
security mediation. It does not by itself provide the paper's positive claim:
choosing which existing object a pathname denotes during VFS name resolution.

fanotify and related notification/interposition APIs are useful background for
filesystem monitoring and access decisions. They are not the same claim because
they do not define a narrow object-selection policy boundary inside name
resolution while preserving lower-FS semantics.

FUSE is the main RQ2 baseline. FUSE systems and FUSE-BPF/ExtFUSE-style work are
closest because they address programmable filesystem behavior and path cost.
They should not be dismissed with generic "FUSE is slow" claims. The paper must
measure feature-equivalent FUSE policies under the same correctness oracle.

Bento, Wrapfs, stackable filesystems, and custom filesystems are the main RQ3
boundary comparison. They can be safe, expressive, and sometimes fast, but they
ask the developer to own a broader filesystem or stackable-filesystem
interface. The paper's boundary claim is narrower: when the oracle-relevant
behavior is only lookup/readdir path-view policy, `namei_ext` should require
less filesystem ownership and a smaller privileged implementation surface.

AgentFS, BranchFS, YoloFS, Sandlock, Mirage, OpenHands/SWE-agent-family
systems, and runtime/workspace sources are strong workload and oracle sources.
They are not mechanism duplicates because most are full agent filesystems,
sandboxes, runtimes, or broader control planes. The paper should reuse their
source behavior where reproducible, and explicitly avoid claiming full
reproduction when original private benchmark code or live service backends are
unavailable.

SWE-Factory, MEnvAgent/MEnvData-SWE, SWE-rebench V2, and DockSmith provide
environment/cache sources. They are not name-resolution mechanisms, but they
provide real build/test oracles and environment-construction pressure. The
strongest later environment/cache experiment should derive one complete
same-oracle matrix from these sources rather than mixing many small rows.

Materialized namespace mechanisms remain important background. Copy trees,
symlink forests, bind mounts, OverlayFS, projected volumes, and native build
cache mechanisms describe existing namespace construction options. They should
not become the central RQ unless a selected source workload makes one of them
the source-system behavior being compared.

## Novelty Risk And Decision

Overall same-claim risk: medium.

The risk is medium because nearby systems are real and relevant: FUSE and FUSE
acceleration, eBPF LSM, stackable/custom filesystem frameworks, and agent
filesystems each cover part of the space. The current search did not find a
primary source making the same combined claim: a `sched_ext`-style VFS
name-resolution extension where eBPF chooses bounded lookup/readdir policy
while the kernel and lower filesystem retain VFS objects and ordinary file
semantics.

Safe ambitious claim to carry into BOOTSTRAP writing:

`namei_ext` evaluates a missing middle point between access-control hooks and
filesystem ownership: programmable name-resolution policy for path-view
decisions, with source-derived workloads and same-oracle comparisons against
FUSE and custom/stackable filesystem boundaries.

Claims to avoid:

- exclusive necessity: do not say only `namei_ext` or only eBPF can implement a
  workload;
- table impossibility: do not use table-only failure as the novelty proof;
- generic FUSE dismissal: RQ2 must measure feature-equivalent FUSE;
- materialization shootout: materialized namespace mechanisms are background or
  source behavior, not the central experimental opponent;
- full reproduction claims for systems whose public code, images, private
  benchmark harnesses, or live-provider backends were not actually run.

## Baseline And Evaluation Handoff

The handoff to `research-experiment-design` is:

| RQ | Main evidence shape | Required comparison or asset | Why |
| --- | --- | --- | --- |
| RQ1 | Representative source-derived workloads pass the same correctness oracle through real KVM `cgroup/namei_ext` attach path. | AgentFS-derived workspace first; SWE-Factory/MEnv/SWE-rebench-derived environment/cache second; service/config only with a concrete lookup-time oracle. | Establish sufficiency without claiming exclusivity. |
| RQ2 | Measure path-policy overhead after correctness parity. | Feature-equivalent FUSE policy implementation for each admitted workload, plus no-hook/lower-FS controls. | FUSE is the closest programmable-filesystem cost alternative. |
| RQ3 | Same-oracle boundary accounting. | Custom/stackable FS evidence from Bento/Wrapfs/YoloFS/BranchFS/AgentFS-style systems: FS methods owned, daemon/state responsibility, privileged code surface, invalid-policy containment, lower-FS preservation. | This answers "why not build a filesystem?" without turning the paper into a full FS comparison. |

Mandatory future experiment properties:

- Make-owned orchestration;
- modified-kernel KVM attach path for `namei_ext`;
- correctness gates before performance interpretation;
- same source oracle for `namei_ext` and FUSE;
- operation-weighted lookup/readdir/open/stat/access/exec traces where relevant;
- raw artifacts under `results/`, with analysis only in report targets;
- no weak baseline row that cannot change an RQ interpretation.

## Larger Opportunity

The strongest story is not "dynamic policies exist" and not "tables fail." The
stronger systems claim is that workload state can change stable pathname
bindings while all ordinary filesystem semantics should remain with the kernel
and lower filesystem. That observation directly predicts the mechanism,
baselines, and measurements:

- if the behavior is only path-view policy, a VFS name-resolution hook should
  be sufficient;
- if the implementation is on the VFS path, FUSE is the closest overhead
  comparison;
- if the policy does not own file data or persistence, custom/stackable
  filesystems should carry a broader boundary than necessary.

No new branded term is needed for this opportunity.

## State Updates

Updated `docs/background-related-work.md` with a BOOTSTRAP 2026-07-13 search
log row, refreshed novelty verdict guidance, and a clear handoff:

- FUSE is RQ2, not related-work-only;
- custom/stackable filesystem ownership is RQ3;
- materialized namespace mechanisms remain background/context unless selected
  as source behavior;
- table-only diagnostics remain retired.

## Completion And Next Action

This literature node is complete enough for BOOTSTRAP pressure. It does not
replace full citation verification or final paper references. The next action
is an independent outer audit of this EXPERIMENT_GATE work, then a gate report
deciding whether BOOTSTRAP can enter WRITE_GATE.

