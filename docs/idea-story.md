# Idea Story

Last updated: 2026-07-09
Stage at update: iter-refine-writing-idea round 5 stress-test refinement
Source/command: `research-project-startup` skill layout, local source/reproduction records under `docs/tmp/`, related-work state in `docs/background-related-work.md`, and raw logs under `results/reproduction/`
Completeness: partial; ready to drive the next KVM workload implementation, not ready for final paper claims

## Current State

- Stage: runnable prototype plus workload-source selection.
- Blocking gate: the paper needs a Make-owned KVM workload derived from real agent/workspace or environment/cache sources.
- Next action: implement the AgentFS-derived AI agent workspace lifecycle workload first; use SWE-Factory-Gym or MEnvData-SWE for the W4 environment/cache workload next, with SWE-rebench V2 as a broader companion source.

## Downstream Document Index

| Doc | Role | Current status | Next required update |
| --- | --- | --- | --- |
| `docs/background-related-work.md` | novelty, closest work, baselines | present; newly consolidated | Keep source status current when new workload reproduction closes. |
| `docs/design.md` | mechanism and artifact boundary | missing | Define the one-decision-function VFS name-resolution ABI and policy/lower-FS boundary. |
| `docs/implementation.md` | prototype and runnable commands | missing | Document Make-owned KVM paths once the next source-derived workload is implemented. |
| `docs/evaluation.md` | experiment plan, results, claim verdict | missing | Convert workload-source decisions into run matrix, oracles, baselines, and thresholds. |

## Intro P1: Problem And Stakes

Purpose: establish why dynamic path views matter now.

Draft paragraph:
Modern agent and environment systems repeatedly fork, checkpoint, validate, and discard filesystem state while running unmodified tools. If a tool observes the wrong workspace branch, consumes a stale or corrupt cached artifact, or sees files that should remain hidden until commit, the task can pass against the wrong state or leak side effects into the host workspace. These failures appear at ordinary pathnames: the same name should resolve to a different backing object under the current workspace, branch, epoch, or request state.

Primary executable evidence: AgentFS-derived workspace lifecycle first; SWE-Factory-Gym or MEnvData-SWE environment/cache second.

Motivating and related evidence: BranchFS, Sandlock, Redis AFS, Mirage, YoloFS, OpenHands SDK, Terminal-Bench, SWE-rebench V2, MEnv/DockSmith trajectories, DeltaFS, IndexFS, TableFS, and FUSE/custom-FS literature.

Completeness: plausible, needs one implemented real workload trace.

## Intro P2: Status Quo And Gap

Purpose: distinguish the project from FUSE, full filesystems, and static namespace construction.

Draft paragraph:
The status quo offers powerful mechanisms, but their control granularity often does not match this requirement. FUSE and NFS-like agent filesystems are the natural choice when a system owns filesystem semantics, but using them for state-transition path views also moves lookup and directory enumeration, cache consistency, failure handling, and service availability into a separate filesystem server. Custom kernel filesystems and metadata services are appropriate when a system owns metadata layout, persistence, or storage distribution. Static tables, bind mounts, symlink forests, OverlayFS layers, and projected views are operationally useful, but they precompute or update the namespace outside the lookup that needs the current state. The gap is a narrow interface for state changes that affect pathname binding or visibility, not new file data semantics, distributed metadata, or custom persistence.

Evidence/claim dependency: ExtFUSE, Bento, FUSE studies, DeltaFS, IndexFS, TableFS, Wrapfs, Kubernetes projected-volume style baselines, and our materialized/FUSE baseline rows.

Completeness: good as framing; needs careful wording to avoid claiming mechanism exclusivity.

## Intro P3: Key Insight And Thesis

Purpose: state the central idea.

Draft paragraph:
The key insight is a decomposition for state-transition path views: workloads where a state change alters which existing lower object a pathname denotes, or whether that pathname is visible, while file contents, metadata persistence, writes, permissions, and consistency remain lower-filesystem responsibilities. Agent workspace and environment/cache systems expose this pattern when branches, checkpoints, epochs, or validation results change what unmodified tools should see at ordinary pathnames. This class is defined from source-system state transitions and workload oracles before assigning a mechanism. For this class, the desired behavior is a state-indexed mapping from an event, pathname, and workspace/branch/cache/request state to a lower object or visibility decision. VFS name resolution is the boundary where pathnames become objects, so it can specialize the path view before object acquisition without moving filesystem methods, the read/write data path, or the filesystem object model into a new service.

Evidence/claim dependency: source-derived workload traces must first identify state-transition path-view effects, then show that oracle-relevant behavior can be validated without workload-specific data-path interposition.

Completeness: thesis is clear; implementation evidence still pending for the first source-derived workload.

## Intro P4: Proposed Artifact Or Method

Purpose: define `namei_ext`.

Draft paragraph:
`namei_ext` realizes this decomposition as a programmable path-view layer at VFS name resolution. A policy is an eBPF program attached through the real `cgroup/namei_ext` path in the modified kernel. The kernel exposes one decision function because lookup and directory enumeration share the same contract: given an event, pathname context, and policy state, choose the visible lower path or visibility action while leaving the VFS object model and lower filesystem semantics intact. Unlike a stackable or passthrough filesystem, the policy does not implement filesystem methods or own VFS objects; it returns a path-resolution action before the kernel continues through the ordinary lower filesystem. It does not define a filesystem, a YAML policy language, or a replacement VFS object model.

Evidence/claim dependency: kernel ABI/design docs, BPF policy examples, and KVM Phase 1 validation.

Completeness: mechanism boundary is stable; design doc should be created.

## Intro P5: Claims And Evaluation Promise

Purpose: map claims to evidence.

Draft paragraph:
The evaluation should show that `namei_ext` can implement realistic state-transition path views with correctness first: agent workspace lifecycle and environment/cache oracles must pass before latency or overhead is interpreted. The first characterization must start from upstream state transitions and classify each oracle-relevant filesystem effect as object selection, visibility, lower-filesystem behavior, or out-of-model behavior before any `namei_ext` implementation is counted as evidence. Transitions that require workload-specific open/read/write/setattr interposition or synthetic file contents are excluded from the current claim rather than counted as successes. The comparison is against natural mechanisms for the same oracle: native workload behavior, FUSE or the source system where applicable, and materialized copy/symlink/bind/Overlay/projected views. Operation-weighted lookup and readdir traces should show where policy decisions occur during state transitions.

Evidence/claim dependency: Make-owned KVM workload result, natural baseline result, operation-weighted trace, and correctness oracle.

Completeness: evaluation promise is defined; next workload implementation is required.

## Intro P6: Contributions, Scope, And Non-Goals

Purpose: keep the paper defensible.

Draft contribution list:
1. A state-transition path-view abstraction for agent/workspace and environment/cache systems, defining the state changes that affect pathname-to-object binding or visibility while delegating data, writes, permissions, persistence, and consistency to the lower filesystem.
2. `namei_ext`, a VFS name-resolution prototype that realizes this abstraction with one eBPF decision interface for lookup and directory enumeration, without implementing filesystem methods or owning VFS objects.
3. A source-derived characterization and correctness-first evaluation that first classifies agent/workspace and environment/cache state transitions by filesystem effect, then shows the in-model effects pass workload oracles in KVM and expose operation-weighted lookup/readdir decision points against natural baselines.

Status:
Contribution 3 is a candidate until the two KVM workload families pass.

Non-goals:
The paper does not claim that tables are impossible, that every candidate workload requires eBPF, or that `namei_ext` replaces agent filesystems, FUSE, or metadata services. Synthetic file contents, custom metadata persistence, distributed directory indexing, write-conflict resolution, data-path mediation, storage layout, and agent orchestration remain outside the artifact boundary.

Evidence/claim dependency: related-work map, workload-source catalog, and explicit negative/appendix rows.

Completeness: wording guard is ready.

## Supporting Research State

### Problem Anchor

- Pain: tools can observe the wrong or stale filesystem view during workspace, branch, cache, or request-state transitions.
- Root cause: policy state changes at workspace, branch, epoch, or request boundaries, while existing middle points either materialize namespace state outside lookup or implement filesystem/server methods to decide it. The missing boundary is policy-only selection before VFS object acquisition.
- Status quo gap: FUSE, custom filesystems, metadata services, and materialized views remain valid, but they take responsibility for broader filesystem service, metadata, daemon availability, or precomputation work when a state transition only changes pathname-to-object binding or visibility.
- Scope: target state-transition path views where the lower filesystem should retain file data, writes, permissions, persistence, and per-object consistency semantics.
- Release gate: correctness oracle passes in KVM, operation-weighted lookup/readdir signal is recorded, and natural baselines are measured for the same oracle.

### Why Now

- Technical/scientific change: AI agents and environment-construction benchmarks now expose public code, traces, and executable oracles for workspace and build/test state transitions.
- New deployment pressure or workload shift: agents and build systems frequently create, fork, checkpoint, evaluate, and discard filesystem views.
- Why prior approaches are newly insufficient: FUSE/custom FS/materialization remain valid, but for state-transition path views they either move policy into a filesystem service or rebuild namespace state outside lookup; the VFS boundary keeps policy at the point where pathnames become objects while reusing lower-filesystem semantics.

### Target Audience And Venue Bar

Systems reviewers should see a precise kernel mechanism, real workload provenance, KVM validation, correctness-first evaluation, and fair comparisons against FUSE, full filesystem/source-system behavior, and materialized views.

### Design Goals

| Goal | Statement | Evaluation mapping |
| --- | --- | --- |
| G1 Path-view completeness | A source-derived transition is in scope only when its oracle-relevant behavior is completely expressible as lookup/readdir-time selection or hiding of existing lower objects. | Upstream-transition classification plus operation-weighted lookup/readdir trace; any required open/read/write/setattr interposition or synthetic contents is marked out of model rather than counted as success. |
| G2 Lower-FS ownership preservation | File data, metadata persistence, permissions, writeback, and per-object consistency remain with the lower filesystem; path-view freshness is checked by workload oracles. | Boundary checks, permission/write behavior, lower-object consistency checks, freshness oracles, and no workload-specific data-path interposition. |
| G3 Narrow programmable interface | One policy decision interface covers lookup and directory enumeration for classified state-transition path-view effects. | ABI tests plus policies loaded through the real `cgroup/namei_ext` attach path for source-derived transitions whose oracle-relevant effects pass G1. |
| G4 Practical comparison boundary | Compare against natural source-system, FUSE, native, and materialized mechanisms for the same correctness oracle. | Per-workload baseline matrix recording same oracle, baseline type, whether it implements filesystem methods, whether it needs a daemon, whether it performs materialization writes, and setup/update/runtime measurements interpreted only after correctness passes. |

### Method Thesis

- Thesis sentence: state-transition path views separate pathname-to-object binding from filesystem ownership; `namei_ext` realizes that boundary while preserving lower-filesystem semantics.
- Mechanism hypothesis: one BPF decision function over lookup and directory-enumeration events is sufficient for source-derived transitions whose oracle-relevant effects are state-transition path views.
- Why the mechanism should work: the relevant filesystem work is object selection before VFS object acquisition, not custom file data or persistence semantics.

### Dominant Claim

- Target claim after two KVM workloads pass: for state-transition path views in agent workspace and environment/cache systems, the relevant filesystem work is object selection before VFS object acquisition. `namei_ext` exposes that boundary as a policy-only layer, preserving lower-filesystem ownership while avoiding a separate filesystem server or materialized namespace for every state transition.
- Stretch opportunity: service reload/secret-rotation can become a third workload family only after an implemented oracle and natural baseline exist.
- Evidence needed to promote the claim: at least two real workload families beyond controlled fixtures, with KVM correctness, operation-weighted traces, and natural baseline comparisons.

### Core Mechanism

`namei_ext` hooks VFS name resolution, not file operations. Policies are eBPF programs under `bpf/policies/*.bpf.c`. The kernel retains VFS object ownership and lower-filesystem semantics.

### Scope And Non-Goals

In scope: lookup/readdir-time selection or hiding of existing lower objects, source-derived workspace/sandbox/cache transitions whose oracle-relevant effects are classified as state-transition path views, KVM validation, and natural baselines.

Out of scope: synthetic file contents, custom metadata persistence, distributed directory indexing, write-conflict resolution, data-path mediation, new filesystem implementation, storage layout changes, YAML/JSON policy language, and proof that static tables or FUSE cannot handle a workload.

### Claim Ledger

| ID | Claim | Scope | Metric/evidence needed | Status |
| --- | --- | --- | --- | --- |
| C1 Model | State-transition path views are a recurring filesystem subproblem in agent/workspace and environment/cache systems. | State changes that alter pathname-to-object binding or visibility while lower FS owns data, writes, permissions, persistence, and consistency. | Upstream-transition classification plus oracle checks showing no workload-specific data-path interposition. | next |
| C2 System | `namei_ext` realizes the model without owning filesystem methods or VFS objects. | Modified-kernel VFS lookup/readdir path with one eBPF decision interface. | ABI/design doc, BPF policy examples, KVM attach validation, lower-FS ownership boundary checks. | proposed |
| C3 Evidence | Two workload families pass correctness oracles through the policy-only object-selection boundary. | AgentFS-derived workspace lifecycle first; SWE-Factory-Gym or MEnvData-SWE W4 second. | KVM correctness, raw traces, natural baselines, and operation-weighted policy events after transition classification. | next |
| C4 Comparison | The mechanism preserves lower-FS ownership while avoiding daemon/FS-method ownership or per-transition materialization for the same oracle. | State-transition path views where lower FS owns data and writes. | Code/scope comparison, daemon/FS-method/materialization matrix, setup/update/runtime behavior, and baseline correctness parity. | proposed |

### Largest Plausible Claim

- Paper thesis candidate: state-transition path views are a real subproblem in agent/workspace and environment/cache systems, and `namei_ext` is a policy-only VFS boundary for that subproblem.
- Why it would matter: it would let systems reuse the kernel and lower filesystem for ordinary file semantics while specializing only the pathname bindings and visibility decisions that turn state transitions into visible filesystem views.
- Experiments needed: AgentFS-derived workspace lifecycle, W4 environment/cache reuse, FUSE/source-system/materialized baselines, and overhead measurements; service reload/secret-rotation is stretch only.
- Cheapest probe: implement the AgentFS-derived COW workspace lifecycle KVM workload.

### Adjacent Idea Intake

| Adjacent idea/source | What can be absorbed | How it could expand the paper | Risk |
| --- | --- | --- | --- |
| AgentFS first; BranchFS/Sandlock/Redis AFS/Mirage/YoloFS as supporting evidence | AgentFS COW/FUSE/git/bash/cache-invalidation/whiteout oracle first; branch, checkpoint/fork, staging, hidden-side-effect, and multi-backend namespace oracles as motivation and baseline checks. | Strong AI agent workspace lifecycle workload. | Some systems are broader than path resolution; avoid claiming replacement or mixing all sources into one implementation target. |
| SWE-rebench V2/SWE-Factory-Gym/MEnvData-SWE | Docker-backed repo build/test oracles. | Strong W4 environment/cache workload. | Full environment generation may require LLM/API or broader image access. |
| MEnvAgent/DockSmith/Multi-Docker-Eval | Environment scripts, trajectories, Docker/eval generation methodology. | Broader W4 task selection and operation traces. | Some artifacts are datasets/trajectories rather than executable systems. |
| DeltaFS/IndexFS/TableFS | Metadata-service/full-filesystem workload shapes. | Appendix or related-work context. | Mainline drift into full FS comparison. |

### Expansion Agenda

| Expansion axis | Bigger experiment | Claim upside | Cost/risk | Probe |
| --- | --- | --- | --- | --- |
| Agent workspace | AgentFS-derived COW workspace lifecycle. | Makes the paper timely and real. | Needs trace extraction and KVM integration. | First workload is AgentFS-derived; Redis AFS, Mirage, BranchFS, Sandlock, YoloFS, OpenHands, SWE-agent, and SWE-ReX are supporting motivation, checklist, or baseline sources. |
| Environment/cache | SWE-Factory-Gym or MEnvData-SWE stale/corrupt/update-window run, with SWE-rebench V2 as a companion source. | Best evidence for state-dependent path views. | Docker build variability and image access. | Pick one clean source-backed row family from the evidence inventory, then promote only if the KVM workload passes G1-G4. |
| Service sandbox | nginx reload/update or PostgreSQL secret/config rotation. | Operational systems relevance. | Needs real reload/update trace. | Extend existing W2 fixture. |

### Reviewer Attack Surface

- "This is just FUSE": answer with mechanism boundary, KVM VFS hook, and source-system/FUSE baselines.
- "This is just static tables": answer by not centering table impossibility; show real state transitions and natural baselines.
- "The workloads are synthetic": answer with public source provenance and executable upstream oracles.
- "You built a filesystem": answer by showing lower FS owns objects, data, writes, and permissions.

### Open Questions

- Should the first W4 implementation use SWE-rebench V2, SWE-Factory-Gym, or the newly passing MEnvData-SWE slice?
- What is the minimum safe directory-enumeration policy needed for the first workload?
