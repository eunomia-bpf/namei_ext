# Background And Related Work

Last updated: 2026-07-15
Source/command: `research-literature-novelty` during BOOTSTRAP step
`docs/tmp/bootstrap/step-0002-20260713T004618-0700/`; local PDF corpus in
`docs/reference/`; source catalog in `docs/reference/CODE_SOURCES.md`; current
web checks against primary docs, proceedings pages, official repositories, and
benchmark pages.
Completeness: BOOTSTRAP step
`docs/tmp/bootstrap/step-0005-20260714T174151-0700/` froze the novelty and
evaluation-pressure frontier for BUILD_AND_EVALUATE. This file records source
pressure and baseline obligations; it is not final RQ evidence.

## Search Log

| Date | Query/source | Purpose | Result |
| --- | --- | --- | --- |
| 2026-07-13 | BOOTSTRAP step 0002: Linux `sched_ext`, BPF LSM, FUSE, FUSE passthrough, ExtFUSE, FUSE-BPF, fanotify primary docs/pages | Check same-mechanism and neighboring-hook risk. | `sched_ext` supports the analogy of BPF policy inside a kernel subsystem; BPF LSM and fanotify are security/mediation hooks; FUSE, FUSE passthrough, ExtFUSE, and FUSE-BPF remain filesystem/request-path or stacked-filesystem mechanisms. No same VFS name-resolution policy boundary found. |
| 2026-07-13 | Bento, Wrapfs, DeltaFS, IndexFS, TableFS primary papers/pages and local PDFs | Check custom/stackable/metadata-service boundary. | These systems own broader filesystem or metadata-service interfaces. They support RQ3 boundary pressure but should not become main runnable baselines for the path-view claim. |
| 2026-07-13 | BOOTSTRAP step 0002: AgentFS, BranchFS, YoloFS, Sandlock, Mirage, Redis AFS, ToolFS, agent-vfs, OpenHands, SWE-agent/SWE-ReX, SWE-MiniSandbox, AgentCgroup | Check agent/workspace source-system assets. | Strong source assets exist for branch/COW/checkpoint/sandbox/cache-invalidation/whiteout/symlink/workspace oracles. These are workload sources and boundary evidence, not proof that only `namei_ext` works. |
| 2026-07-13 | BOOTSTRAP step 0002: SWE-Factory, MEnvAgent/MEnvData-SWE, SWE-rebench V2, DockSmith, Multi-Docker-Eval | Check environment/cache source assets. | Strong executable build/test oracles exist for environment/cache; DockSmith is mainly trajectory/methodology unless concrete evaluator paths are selected. |
| 2026-07-13 | Kubernetes projected volumes, ConfigMaps, Secrets, OverlayFS, mount namespaces | Check service/config and materialized namespace context. | Projected/materialized mechanisms are important background. Service/config should remain conditional unless a lookup-time object-selection oracle is chosen. |

## PDF Corpus

| Work | Local PDF path | Verification status | Why kept |
| --- | --- | --- | --- |
| BranchFS / branch contexts | `docs/reference/arxiv2602.08199-branch-contexts-branchfs.pdf` | local PDF plus public repository/source checks | Agent workspace branch/COW lifecycle source and FUSE boundary evidence. |
| YoloFS | `docs/reference/arxiv2604.13536-yolofs.pdf` | local PDF plus public filesystem artifact checks | Agent filesystem safety methodology, staging/snapshot/permission oracles, stackable-FS context. |
| Sandlock | `docs/reference/arxiv2605.26298-sandlock.pdf` | local PDF plus public repository/source checks | Agent sandbox and reversible filesystem effects source. |
| SWE-agent/OpenHands/Terminal-Bench/AgentCgroup/SWE-MiniSandbox | `docs/reference/arxiv2511.03690-openhands-sdk.pdf`, `docs/reference/neurips2024-yang-swe-agent.pdf`, `docs/reference/arxiv2601.11868-terminal-bench.pdf`, `docs/reference/arxiv2602.09345-agentcgroup.pdf`, `docs/reference/arxiv2602.11210-swe-minisandbox.pdf` | local PDFs plus source reproduction records | Agent runtime/task/workspace oracles and operation traces. |
| MEnvAgent, SWE-rebench V2, DockSmith, Multi-Docker-Eval | `docs/reference/arxiv2601.22859-menvagent.pdf`, `docs/reference/arxiv2602.23866-swe-rebench-v2.pdf`, `docs/reference/arxiv2602.00592-docksmith.pdf`, `docs/reference/arxiv2512.06915-multi-docker-eval.pdf` | local PDFs plus source reproduction records | Environment/cache workload sources. |
| FUSE/ExtFUSE/Bento/Wrapfs | `docs/reference/fast17-vangoor-to-fuse-or-not-to-fuse.pdf`, `docs/reference/atc19-bijlani-extfuse.pdf`, `docs/reference/fast21-miller-bento.pdf`, `docs/reference/usenix99-zadok-wrapfs-stackable-templates.pdf` | local PDFs plus primary pages | RQ2 and RQ3 comparison families. |
| DeltaFS/IndexFS/TableFS | `docs/reference/sc21-zheng-deltafs.pdf`, `docs/reference/sc14-ren-indexfs.pdf`, `docs/reference/atc13-ren-tablefs.pdf` | local PDFs plus primary pages | Related-work boundary for metadata services and stacked metadata filesystems. |

## Claim-Oriented Novelty Map

| Claim | Closest prior work | Same-claim risk | Novelty delta | Baselines implied | Expansion opportunity |
| --- | --- | --- | --- | --- | --- |
| A narrow kernel hook can expose programmable path-view policy at VFS name resolution while the lower filesystem keeps data and object semantics. | `sched_ext`, BPF LSM, fanotify, FUSE/ExtFUSE, Wrapfs/Bento. | Medium. Nearby mechanisms exist, but they are scheduler policy, access control, userspace filesystem request handling, or filesystem implementation frameworks. | The proposed boundary is name-resolution object selection/visibility, not security mediation or filesystem method ownership. | RQ2: feature-equivalent FUSE. RQ3: custom/stackable FS boundary. | Frame as a missing middle between eBPF LSM and FUSE/custom FS, not as "tables fail" or "dynamic policy exists." |
| Real agent/workspace and environment/cache systems expose source-derived path-view transitions worth evaluating. | AgentFS, BranchFS, YoloFS, Sandlock, Mirage, SWE systems, MEnv/SWE-Factory/SWE-rebench. | Low-to-medium. They motivate and sometimes implement broader filesystems/runtimes. | Use their oracles to test the narrower boundary instead of competing with the full source system. | Source oracle controls; no source inventory as final RQ evidence. | Use two deep families: Agent workspace and environment/cache; add service/config only if strong. |
| A verified name-resolution policy can have lower boundary burden than custom or stackable FS when policy is only lookup/readdir selection. | Bento, Wrapfs, TableFS, DeltaFS, IndexFS, YoloFS/BranchFS. | Medium. Prior work values custom/stackable FS for broader semantics. | The novelty is narrower ownership, not replacing full filesystems. | Boundary accounting: methods owned, daemon/state, verifier constraints, invalid-policy containment. | Make RQ3 a same-oracle boundary audit after RQ1 correctness, not a prose-only related-work table. |

## Closest Work

| Work | Claim | Method/artifact | Evaluation | Same problem/mechanism/metric/setting? | Gap relative to this project |
| --- | --- | --- | --- | --- | --- |
| Linux `sched_ext` | BPF can safely define scheduling policy inside a kernel-owned subsystem. | Kernel scheduler class and BPF scheduler programs. | Scheduler workloads. | Same extension-point pattern; different subsystem. | Supports analogy but not filesystem path-view policy. |
| BPF LSM and fanotify | Runtime security/access mediation for files and other objects. | LSM hooks or userspace permission events. | Security/audit decisions. | Same kernel/filesystem neighborhood; different action space. | They decide allow/deny or audit, not which lower object a pathname resolves to. |
| FUSE and FUSE passthrough | Userspace can implement filesystems; passthrough can reduce some I/O daemon cost. | Kernel module plus userspace daemon/library; passthrough backing files. | Filesystem workloads. | Same setting and closest RQ2 mechanism. | FUSE owns a filesystem service boundary; same-oracle measurement is required and must account for fair caching/passthrough choices. |
| ExtFUSE and FUSE-BPF | Kernel-side extensions can accelerate or filter FUSE/stacked-filesystem request handling. | Modified FUSE framework, BPF-like or eBPF request handlers, stacked-filesystem patch series. | FUSE or stacked-filesystem workloads. | Same eBPF/FUSE neighborhood and closest same-mechanism pressure. | Still starts from a FUSE or stacked-filesystem boundary, not a VFS name-resolution-only extension point. |
| Bento and Wrapfs | Safer or easier ways to build kernel/stackable filesystems. | Rust kernel FS framework; stackable FS templates. | Filesystem implementations. | Same boundary question. | They still ask the developer to own filesystem methods. |
| DeltaFS, IndexFS, TableFS | Metadata/index services and stacked metadata filesystems improve metadata scalability. | Distributed/stacked metadata systems. | HPC/local metadata workloads. | Same broad filesystem namespace area; different problem. | Useful non-goals and appendix context, not the main path-view workload. |
| AgentFS, BranchFS, YoloFS, Sandlock, Mirage, Redis AFS, ToolFS, agent-vfs | Agent filesystems/sandboxes need COW, branch, snapshot, staging, permission, and workspace state. | FUSE/NFS/kernel module/runtime/filesystem/library systems. | Agent/workspace tests and benchmarks where available. | Same workload setting; broader mechanisms. | Best source oracles and boundary evidence for Experiment A. |
| SWE-Factory, MEnvAgent, SWE-rebench V2, DockSmith | Environment construction and reuse are first-class SWE-agent workloads. | Docker/eval pipelines, datasets, trajectories. | Fail-to-pass and build/test oracles. | Same environment/cache setting; different mechanism. | Best source oracles for Experiment B. |

## Main Comparisons And Evidence Roles

This section separates baselines from oracles, controls, and boundary evidence
so the evaluation does not drift into a long baseline catalog.

| Role | Evidence item | RQ served | Runnable status | Fairness or admission rule | Claim consequence if unavailable |
| --- | --- | --- | --- | --- | --- |
| Main baseline | Feature-equivalent FUSE policy over the same oracle | RQ2 | Preflight exists; full matrix still pending | Same policy inputs, update schedule, and justified FUSE caching/passthrough settings as `namei_ext`; do not ignore FUSE passthrough/FUSE-BPF as related acceleration context. | RQ2 cannot claim lower cost or acceptable overhead versus FUSE. |
| Correctness oracle | Source/native behavior from AgentFS/BranchFS/Mirage/SWE-Factory/MEnv/SWE-rebench selected assets | RQ1 | Many source subsets reproduced; final admitted suite pending | Establishes the source oracle and task input; it is not a weaker baseline. | RQ1 lacks source credibility. |
| Boundary evidence | Workload-specific custom/stackable/source-system ownership table | RQ3 | Citation/source-code evidence plus selected source artifacts; no full-system reimplementation unless required by the oracle | Compare required filesystem methods, daemon/runtime state, metadata, data/write-path ownership, privileged code, and invalid-policy containment. | RQ3 becomes unsupported prose. |
| Control | Lower-FS/no-hook run through the project KVM target | RQ2 attribution | Existing Phase 1 controls; final workload controls pending | Same operation mix where meaningful; used only for overhead attribution. | RQ2 overhead attribution weakens. |

## Experimental Precedents And External Assets

| RQ/claim | Accepted paper/protocol citation | Official benchmark/dataset/software/test tool | Version/artifact | Real-world provenance | Reusable design | Required deviation or glue |
| --- | --- | --- | --- | --- | --- | --- |
| RQ1 Agent workspace | AgentFS/BranchFS/YoloFS/Sandlock/Mirage source systems | AgentFS tests, BranchFS quick benchmarks, Mirage FUSE/example tests, YoloFS public mounted e2e | See `docs/reference/CODE_SOURCES.md` | AI agent workspace filesystems and sandboxes | Branch/fork/checkpoint/COW/whiteout/symlink/cache-invalidation oracles | Thin KVM workload glue mapping selected oracle to `namei_ext` actions. |
| RQ1/RQ2 Environment/cache | SWE-Factory, MEnvAgent, SWE-rebench V2 | Released Docker/eval rows and selected HF/sample rows | See dated reproduction records | Real repositories and executable tests | Hit/miss/stale/corrupt or environment-reuse state with build/test oracle | Need a fixed source-row suite and explicit cache-state transition harness. |
| RQ2 FUSE overhead | FAST 2017 FUSE study; ExtFUSE; FUSE-BPF; kernel FUSE and FUSE passthrough docs | libfuse/project FUSE runner | Local runner plus official FUSE docs and closest-work records | Filesystem request path | Measure same-oracle FUSE, not generic FUSE weakness | Implement feature-equivalent policy cells and explain why FUSE-BPF/ExtFUSE remain related-work pressure rather than main baselines unless admitted by the final protocol. |
| RQ3 Boundary | Bento, Wrapfs, ExtFUSE, DeltaFS/IndexFS/TableFS | Papers, repositories, filesystem method surfaces | Local PDFs and source links | Custom/stackable/filesystem-service systems | Account ownership rather than re-run entire FS papers | Produce workload-specific boundary table after final oracle selection. |

## Non-Main Comparison Disposition

| Candidate | Disposition | Reproduction risk | Fairness notes |
| --- | --- | --- | --- |
| FUSE policy implementation | Main RQ2 baseline. | Medium. | Must be feature-equivalent and correctness-gated. |
| Source/native behavior | Correctness oracle and input provenance, not a baseline win condition. | Medium. | Establish source behavior before interpreting `namei_ext` or FUSE. |
| Custom/stackable FS boundary | Main RQ3 boundary evidence, usually citation/source-code based. | Medium. | Use workload-specific ownership tables; avoid full-system reimplementation unless needed. |
| Materialized namespace mechanisms | Related-work/background unless a selected source oracle makes one a direct operator baseline. | Low-to-medium. | Do not reopen bind/Overlay/copy/symlink/table shootouts as the main story. |

## Absorbable Ideas

| Source/community | Idea to absorb | Claim expansion enabled | Experiment implication | Risk |
| --- | --- | --- | --- | --- |
| Agent filesystems | Branch, fork, checkpoint, COW, staging, whiteout, symlink, cache invalidation, final-tree oracle. | Strong Experiment A. | Fixed lifecycle matrix with lookup/readdir traces and lower-filesystem checks. | Some source effects require broader FS/runtime ownership. |
| SWE/environment systems | Docker/eval row identity, fail-to-pass tests, environment reuse, build/test status. | Strong Experiment B. | Fixed suite with hit/miss/stale/corrupt/update states. | Cache policy must be real, not a synthetic ccache toy. |
| Filesystem literature | FUSE request path, stackable method ownership, metadata-service responsibilities. | Stronger RQ2/RQ3. | Same-oracle FUSE plus boundary accounting. | Too many baselines can fragment the paper. |
| Kubernetes/projected config | Service/config operational breadth. | Possible Experiment C. | Admit only with lookup-time object-selection oracle. | Otherwise it becomes weak breadth or app reload behavior. |

## Adjacent Communities

| Community/venue family | Why relevant | Keywords/aliases | Useful papers or benchmarks |
| --- | --- | --- | --- |
| OS/filesystems | Core mechanism, baselines, safety boundary. | VFS, FUSE, stackable FS, eBPF, LSM, fanotify. | FUSE, ExtFUSE, Bento, Wrapfs, DeltaFS, IndexFS, TableFS. |
| AI agents/SWE agents | Main workload pressure. | agent workspace, sandbox, SWE task, terminal task. | AgentFS, BranchFS, YoloFS, Sandlock, Mirage, OpenHands, SWE-agent, SWE-ReX, Terminal-Bench. |
| Build/environment construction | Environment/cache pressure. | Docker eval, fail-to-pass, environment reuse, cache. | SWE-Factory, MEnvAgent, SWE-rebench V2, DockSmith, Multi-Docker-Eval. |
| Containers/orchestration | Service/config context. | projected volume, config map, secret, overlay, namespace. | Kubernetes projected volumes, OverlayFS, mount namespaces. |

## Venue Evaluation Patterns

OSDI/SOSP-grade evidence should not look like a source catalog or a pile of
microbenchmarks. The main paper needs a few complete experiment matrices. Each
matrix must start from a real source oracle, pass correctness through the real
KVM `cgroup/namei_ext` attach path, compare against feature-equivalent FUSE for
RQ2, account for custom/stackable filesystem ownership for RQ3, preserve raw
results, and receive result review before paper interpretation. Controls and
ablations are admitted only when they change an RQ answer.

## Must-Read List

- Linux kernel docs for `sched_ext`, BPF LSM, FUSE, FUSE passthrough, OverlayFS.
- ExtFUSE, FAST 2017 FUSE study, Bento, Wrapfs.
- AgentFS, BranchFS, YoloFS, Sandlock, Mirage.
- SWE-Factory, MEnvAgent/MEnvData-SWE, SWE-rebench V2, DockSmith.
- DeltaFS, IndexFS, TableFS as boundary/non-goal context.

## Novelty Verdict

- BOOTSTRAP step 0005 freeze verdict: the current story is frozen for
  BUILD_AND_EVALUATE. It includes ExtFUSE/FUSE-BPF as closest mechanism
  pressure; keeps Agent workspace and environment/cache as complete experiments;
  keeps service/config conditional; and keeps table/materialized-view
  diagnostics out of the novelty line.
- Overall same-claim risk: medium. The surrounding systems are close and
  important, but the checked primary source families do not already claim a
  narrow BPF-controlled VFS name-resolution policy boundary that preserves
  lower-filesystem data and object semantics.
- Ambitious target claims: keep `namei_ext` as a `sched_ext`-style VFS
  extension point between eBPF LSM and FUSE/custom FS; keep RQ1/RQ2/RQ3 as
  expressiveness, cost versus FUSE, and safety/boundary versus custom or
  stackable filesystems.
- Claims requiring stronger differentiation or evidence: do not claim exclusive
  necessity for `namei_ext`; do not say workloads intrinsically require eBPF;
  do not treat source characterization or prototype matrices as final RQ
  evidence.
- Larger claim opportunities: two deep source-derived families, Agent workspace
  and environment/cache, are stronger than a large list of weak baselines.
  Service/config can strengthen breadth only if it has a real lookup-time
  source oracle.
- Main evidence roles: feature-equivalent FUSE is the RQ2 baseline;
  source/native behavior is the RQ1 correctness oracle; custom/stackable
  ownership tables are RQ3 boundary evidence; lower-filesystem/no-hook runs are
  controls for overhead attribution.
- Experimental precedents and external assets: AgentFS/BranchFS/YoloFS/Mirage
  for workspace lifecycle; SWE-Factory/MEnv/SWE-rebench for environment/cache;
  ExtFUSE/FUSE/Bento/Wrapfs for comparison discipline.
- Next action: BUILD_AND_EVALUATE should run the complete Agent workspace
  matrix with feature-equivalent FUSE for RQ2 and custom/stackable filesystem
  ownership evidence for RQ3. Experiment B follows after path-view admission
  and the required target-selection support; service/config remains conditional
  on a concrete lookup-time source oracle.
