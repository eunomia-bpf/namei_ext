# Idea Story

Last updated: 2026-07-10
Stage at update: iter-refine-writing-idea and iter-refine-writing interleaved refinement in progress
Source/command: `research-project-startup` skill layout, local source/reproduction records under `docs/tmp/`, related-work state in `docs/background-related-work.md`, and raw logs under `results/reproduction/`
Completeness: partial; ready to drive the next KVM workload implementation, not ready for final paper claims

## Current State

- Stage: runnable prototype plus workload-source selection.
- Blocking gate: the paper needs a Make-owned KVM workload derived from real agent/workspace or environment/cache sources.
- Next action: implement the AgentFS-derived AI agent workspace lifecycle workload first; use SWE-Factory-Gym or MEnvData-SWE for the environment/cache workload next, with SWE-rebench V2 as a broader companion source.

## Downstream Document Index

| Doc | Role | Current status | Next required update |
| --- | --- | --- | --- |
| `docs/background-related-work.md` | novelty, closest work, baselines | present; newly consolidated | Keep source status current when new workload reproduction closes. |
| `docs/design.md` | mechanism and artifact boundary | missing | Define the one-decision-function VFS name-resolution ABI and policy/lower-FS boundary. |
| `docs/implementation.md` | prototype and runnable commands | missing | Document Make-owned KVM paths once the next source-derived workload is implemented. |
| `docs/evaluation.md` | experiment plan, results, claim verdict | missing | Convert workload-source decisions into run matrix, oracles, baselines, and thresholds. |

## Intro P1: Problem And Stakes

Purpose: establish why state-transition path views matter now.

Draft paragraph:
Agent-workspace and environment/cache workflows create short-lived branches, checkpoints, cache epochs, and validation states while invoking unmodified build and test tools. After a workspace transition, a path bound to the previous state can cause a tool to validate the wrong revision; a path bound to shared state can direct writes into the parent workspace; after a cache-epoch change, a path bound to an old cache object can feed stale inputs into a build. These failures arise even when the underlying files and ordinary read/write semantics need not change: the wrong existing lower object is selected, or an object is visible when it should not be.

Primary executable evidence: AgentFS-derived workspace lifecycle first; SWE-Factory-Gym or MEnvData-SWE environment/cache second.

Motivating and related evidence: BranchFS, Sandlock, Redis AFS, Mirage, YoloFS, OpenHands SDK, Terminal-Bench, SWE-rebench V2, MEnv/DockSmith trajectories, DeltaFS, IndexFS, TableFS, and FUSE/custom-FS literature.

Completeness: plausible; one implemented trace unblocks implementation, while two KVM-validated upstream transitions are required to promote the paper claim.

## Intro P2: Status Quo And Gap

Purpose: distinguish the project from FUSE, full filesystems, and static namespace construction.

Draft paragraph:
Existing mechanisms cover this need at different ownership boundaries. FUSE and NFS-like designs can compute views dynamically and are appropriate when a system is prepared to serve filesystem operations and manage a daemon or server, caching behavior, and failure handling. Copies, bind mounts, symlink trees, and projected volumes encode the view during namespace construction or update. OverlayFS selects among layers during lookup, but exposes a fixed layer-and-whiteout model rather than general application-state-indexed selection. Custom and stackable filesystems are appropriate when new semantics justify implementing a broader filesystem interface. The unresolved mismatch is the need to change only pathname-to-object bindings or visibility while leaving ordinary filesystem ownership and semantics unchanged.

Evidence/claim dependency: ExtFUSE, Bento, FUSE studies, DeltaFS, IndexFS, TableFS, Wrapfs, Kubernetes projected-volume style baselines, and our materialized/FUSE baseline rows.

Completeness: good as framing; needs careful wording to avoid claiming mechanism exclusivity.

## Intro P3: Key Insight And Thesis

Purpose: state the central idea.

Draft paragraph:
The key insight is not that pathname lookup can choose objects; existing filesystems and namespace mechanisms already do that. The insight is a missing decomposition for state-transition path views: state changes should affect only the binding from names to existing lower objects, or whether those objects are visible, while the lower filesystem continues to own data, writes, permissions, persistence, and consistency. Existing mechanisms can implement these behaviors, but they commonly couple object selection to namespace materialization or filesystem-service ownership. Agent workspace and environment/cache systems expose this pattern when branches, checkpoints, epochs, or validation results change what unmodified tools should see at ordinary pathnames. This class is defined from source-system state transitions and workload oracles before assigning a mechanism.

Evidence/claim dependency: source-derived workload traces must first identify state-transition path-view effects, then show that oracle-relevant behavior can be validated without workload-specific data-path interposition.

Completeness: thesis is clear; implementation evidence still pending for the first source-derived workload.

## Intro P4: Proposed Artifact Or Method

Purpose: define `namei_ext`.

Draft paragraph:
`namei_ext` realizes this decomposition as a policy-only object-selection boundary inside VFS name resolution. A policy is an eBPF program attached through the real `cgroup/namei_ext` path in the modified kernel. The kernel exposes one decision function because lookup and directory enumeration share the same contract: given an event, pathname context, and policy state, choose the visible lower path or visibility action while leaving the VFS object model and lower filesystem semantics intact. Unlike a stackable or passthrough filesystem, the policy does not implement filesystem methods, own VFS objects, run a filesystem server, or materialize a namespace tree; it returns a path-resolution action before the kernel continues through the ordinary lower filesystem. It does not define a filesystem, a YAML policy language, or a replacement VFS object model.

Evidence/claim dependency: kernel ABI/design docs, BPF policy examples, and KVM Phase 1 validation.

Completeness: mechanism boundary is stable; design doc should be created.

## Intro P5: Claims And Evaluation Promise

Purpose: map claims to evidence.

Draft paragraph:
The evaluation should show that `namei_ext` can implement realistic state-transition path views with correctness first: one AgentFS-derived workspace transition and one environment/cache transition must pass their oracles before latency or overhead is interpreted. The first characterization must start from each upstream transition and its oracle, then classify each oracle-relevant filesystem effect as object selection, visibility, lower-filesystem behavior, or out-of-model behavior before any `namei_ext` implementation is counted as evidence. If the oracle requires out-of-model behavior, that transition cannot support C3; an in-model slice counts only when it has its own oracle-valid transition. The comparison is against natural mechanisms for the same oracle: source-system behavior where runnable, standalone FUSE only when distinct from the source system, and materialized copy/symlink/bind/Overlay/projected views. Operation-weighted lookup and readdir traces should record the workload-specific event mix, without requiring every transition to exercise both event types.

Evidence/claim dependency: Make-owned KVM workload result, natural baseline result, operation-weighted trace, and correctness oracle.

Completeness: evaluation promise is defined; next workload implementation is required.

## Intro P6: Contributions, Scope, And Non-Goals

Purpose: keep the paper defensible.

Draft contribution list:
1. A state-transition path-view model that classifies source-system state transitions into pathname-object selection, visibility, lower-filesystem behavior, and out-of-model effects (Model, Section 2).
2. `namei_ext`, a VFS name-resolution prototype that realizes classified in-model effects with one eBPF decision interface for lookup and directory enumeration, without implementing filesystem methods or owning VFS objects (System, Sections 3-4).
3. A correctness-first KVM evaluation of two examined upstream transitions, measuring oracle correctness, operation-weighted lookup/readdir policy events, and setup/update/runtime behavior against source-system, distinct standalone FUSE, and materialized baselines (Evaluation, Section 5).

Status:
Contribution 3 is a candidate until the two examined upstream transitions pass.

Non-goals:
The paper does not claim that competing mechanisms are impossible, that every candidate workload requires eBPF, or that `namei_ext` replaces agent filesystems, FUSE, or metadata services. Synthetic file contents, custom metadata persistence, distributed directory indexing, write-conflict resolution, data-path mediation, storage layout, agent orchestration, cross-path transactional snapshots, atomic multi-object commits, and consistency beyond selecting state-indexed existing lower objects remain outside the artifact boundary.

Evidence/claim dependency: related-work map, workload-source catalog, and explicit negative/appendix rows.

Completeness: wording guard is ready.

## Supporting Research State

### Problem Anchor

- Pain: tools can validate the wrong revision, write into a parent workspace, or consume stale cache inputs when pathnames remain bound to objects from the wrong workspace, branch, or cache epoch.
- Root cause: the workload's state unit, such as a workspace, branch, or cache epoch, changes only which existing objects names denote or expose, whereas common mechanisms couple that change either to constructing or updating a namespace representation or to a component serving a broader filesystem interface. This mismatch between workload state granularity and namespace ownership or update granularity is the structural cause.
- Status quo gap: FUSE, custom filesystems, metadata services, and materialized views remain valid, but they take responsibility for broader filesystem service, metadata, daemon availability, or namespace-update work when a state transition only changes pathname-to-object binding or visibility.
- Scope: target state-transition path views where the lower filesystem should retain file data, writes, permissions, persistence, and per-object consistency semantics.
- Release gate: correctness oracle passes in KVM, operation-weighted lookup/readdir signal is recorded, and natural baselines are measured for the same oracle.

### Why Now

- Technical/scientific change: public agent-workspace and environment-construction systems now provide source code and executable correctness oracles for short-lived state transitions.
- New deployment pressure or workload shift: agents and build systems frequently create, fork, checkpoint, evaluate, and discard filesystem views.
- Why the question is newly measurable: existing mechanisms remain valid baselines; evaluation must establish when their additional service or namespace-update responsibilities are material.

### Target Audience And Venue Bar

Systems reviewers should see a precise kernel mechanism, real workload provenance, KVM validation, correctness-first evaluation, and fair comparisons against FUSE, full filesystem/source-system behavior, and materialized views.

### Design Goals

| Goal | Statement | Contribution | Evaluation mapping |
| --- | --- | --- | --- |
| G1 Path-view completeness | A source-derived transition is in scope only when its oracle-relevant behavior is completely expressible as lookup/readdir-time selection or hiding of existing lower objects. | C1, C3 | Classification starts from the upstream transition and oracle; any required open/read/write/setattr interposition or synthetic contents is marked out of model. A transition supports the paper claim only if its chosen oracle-relevant behavior has a complete in-model path-view slice; otherwise it becomes motivation or related work, not evaluation evidence. |
| G2 Lower-FS ownership preservation | File data, metadata persistence, permissions, writeback, and per-object consistency remain with the lower filesystem; path-view freshness is checked by workload oracles. | C2, C3 | Boundary checks, permission/write behavior, lower-object consistency checks, freshness oracles, and no workload-specific data-path interposition. |
| G3 Narrow programmable interface | One policy decision interface covers lookup and directory enumeration for classified in-model effects. | C2 | ABI tests plus policies loaded through the real `cgroup/namei_ext` attach path for source-derived transitions whose oracle-relevant effects pass G1; traces record the workload-specific lookup/readdir event mix without requiring both events in every transition. |
| G4 Practical comparison boundary | Compare against natural source-system, distinct FUSE, native, and materialized mechanisms for the same correctness oracle. | C3 comparison subclaim | Per-transition baseline matrix recording same oracle, correctness parity, baseline type, whether it implements filesystem methods, whether it needs a daemon, whether it performs materialization writes, and setup/update/runtime measurements interpreted only after correctness passes. |

### Method Thesis

- Thesis sentence: state-transition path views separate pathname-to-object binding from filesystem ownership; `namei_ext` realizes that boundary while preserving lower-filesystem semantics.
- Mechanism hypothesis: one BPF decision function over lookup and directory-enumeration events is sufficient for classified in-model effects from the source-derived transitions.
- Why the mechanism should work: the relevant filesystem work is object selection before VFS object acquisition, not custom file data or persistence semantics.

### Dominant Claim

- Target claim after two KVM transitions pass: for one AgentFS-derived workspace transition and one environment/cache transition, classification identifies a complete oracle-relevant in-model path-view slice, and `namei_ext` implements that slice while the lower filesystem retains ordinary file semantics. Natural-baseline measurements then determine whether this avoids filesystem-service or namespace-update work for the same oracle.
- Stretch opportunity: service reload/secret-rotation can become a third workload family only after an implemented oracle and natural baseline exist.
- Evidence needed to promote the claim: two real upstream transitions beyond controlled fixtures, with KVM correctness, operation-weighted traces, and natural baseline comparisons; broader family-level claims require additional classified transitions.

### Core Mechanism

`namei_ext` hooks VFS name resolution, not file operations. Policies are eBPF programs under `bpf/policies/*.bpf.c`. The kernel retains VFS object ownership and lower-filesystem semantics.

### Scope And Non-Goals

In scope: lookup/readdir-time selection or hiding of existing lower objects, source-derived workspace/sandbox/cache transitions whose oracle-relevant effects are classified as state-transition path views, KVM validation, and natural baselines.

Out of scope: synthetic file contents, custom metadata persistence, distributed directory indexing, write-conflict resolution, cross-path transactional snapshots, atomic multi-object commits, data-path mediation, new filesystem implementation, storage layout changes, YAML/JSON policy language, and proof that other mechanisms cannot handle a workload.

### Claim Ledger

| ID | Claim | Scope | Metric/evidence needed | Status |
| --- | --- | --- | --- | --- |
| C1 Model | The two examined upstream transitions contain state-transition path-view effects. | One AgentFS-derived workspace transition and one environment/cache transition whose state changes alter pathname-to-object binding or visibility while lower FS owns data, writes, permissions, persistence, and consistency. | Upstream-transition classification plus oracle checks showing no workload-specific data-path interposition; out-of-model transitions become motivation or related work, not evaluation evidence. | pending KVM workload classification |
| C2 System | `namei_ext` realizes the model without owning filesystem methods or VFS objects. | Modified-kernel VFS lookup/readdir path with one eBPF decision interface. | ABI/design doc, BPF policy examples, KVM attach validation, lower-FS ownership boundary checks. | proposed |
| C3 Evidence | Two examined upstream transitions pass correctness oracles through the policy-only object-selection boundary. | AgentFS-derived workspace transition first; SWE-Factory-Gym or MEnvData-SWE environment/cache transition second. | KVM correctness, raw traces, natural baselines, operation-weighted policy events after transition classification, and the comparison subclaim that the mechanism separates object selection from namespace materialization and filesystem-service ownership for the same oracle. | next |

### Largest Plausible Claim

- Paper thesis candidate: the two examined upstream transitions contain state-transition path-view effects, and `namei_ext` is a policy-only VFS boundary for those effects.
- Why it would matter: it would let systems reuse the kernel and lower filesystem for ordinary file semantics while specializing only the pathname bindings and visibility decisions that turn state transitions into visible filesystem views.
- Experiments needed: AgentFS-derived workspace lifecycle, environment/cache reuse, FUSE/source-system/materialized baselines, and overhead measurements; service reload/secret-rotation is stretch only.
- Cheapest probe: implement the AgentFS-derived COW workspace lifecycle KVM workload.

### Adjacent Idea Intake

| Adjacent idea/source | What can be absorbed | How it could expand the paper | Risk |
| --- | --- | --- | --- |
| AgentFS first; BranchFS/Sandlock/Redis AFS/Mirage/YoloFS as supporting evidence | AgentFS COW/FUSE/git/bash/cache-invalidation/whiteout oracle first; branch, checkpoint/fork, staging, hidden-side-effect, and multi-backend namespace oracles as motivation and baseline checks. | Strong AI agent workspace lifecycle workload. | Some systems are broader than path resolution; avoid claiming replacement or mixing all sources into one implementation target. |
| SWE-rebench V2/SWE-Factory-Gym/MEnvData-SWE | Docker-backed repo build/test oracles. | Strong environment/cache workload. | Full environment generation may require LLM/API or broader image access. |
| MEnvAgent/DockSmith/Multi-Docker-Eval | Environment scripts, trajectories, Docker/eval generation methodology. | Broader environment/cache task selection and operation traces. | Some artifacts are datasets/trajectories rather than executable systems. |
| DeltaFS/IndexFS/TableFS | Metadata-service/full-filesystem workload shapes. | Appendix or related-work context. | Mainline drift into full FS comparison. |

### Expansion Agenda

| Expansion axis | Bigger experiment | Claim upside | Cost/risk | Probe |
| --- | --- | --- | --- | --- |
| Agent workspace | AgentFS-derived COW workspace lifecycle. | Makes the paper timely and real. | Needs trace extraction and KVM integration. | First workload is AgentFS-derived; Redis AFS, Mirage, BranchFS, Sandlock, YoloFS, OpenHands, SWE-agent, and SWE-ReX are supporting motivation, checklist, or baseline sources. |
| Environment/cache | SWE-Factory-Gym or MEnvData-SWE stale/corrupt/update-window run, with SWE-rebench V2 as a companion source. | Best evidence for state-dependent path views. | Docker build variability and image access. | Pick one clean source-backed row family from the evidence inventory, then promote only if the KVM workload passes G1-G4. |
| Service sandbox | nginx reload/update or PostgreSQL secret/config rotation. | Operational systems relevance. | Needs real reload/update trace. | Extend existing W2 fixture. |

### Reviewer Attack Surface

- "This is just FUSE": answer that the same behavior is expressible elsewhere, but those mechanisms couple object selection to daemon, filesystem-method, or materialization responsibilities; the evidence measures that boundary under the same oracle.
- "This is just precomputed namespace state": answer by not claiming impossibility for alternatives; show source-derived transitions and natural baselines under the same oracle.
- "The workloads are synthetic": answer with public source provenance and executable upstream oracles.
- "You built a filesystem": answer by showing lower FS owns objects, data, writes, and permissions.

### Open Questions

- Should the first environment/cache implementation use SWE-rebench V2, SWE-Factory-Gym, or the newly passing MEnvData-SWE slice?
- What is the minimum safe directory-enumeration policy needed for the first workload?
