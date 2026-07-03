# Idea Story

Last updated: 2026-07-02
Stage at update: skill-layout convergence after workload-source consolidation
Source/command: local source/reproduction records under `docs/tmp/`, canonical related-work state in `docs/background-related-work.md`, and raw logs under `results/reproduction/`
Completeness: partial; ready to drive the next KVM workload implementation, not ready for final paper claims

## Document Ownership

This is the canonical story and claim-scope document. Keep the current thesis,
claim ledger, scope, non-goals, and next action here.

Use `docs/background-related-work.md` for related work, novelty risk, closest
work, baselines, and venue-evaluation implications. Use
`docs/reference/CODE_SOURCES.md` for code/artifact entry points. Use
`docs/tmp/YYYY-MM-DD-*.md` for standalone dated research or implementation
records, and keep raw logs, JSON/JSONL, and benchmark outputs under `results/`.
Historical planning files such as `docs/research_plan.md`,
`docs/case_studies.md`, `docs/experiment-plans/*.md`, `docs/phase1_design.md`,
and `research/*.md` are provenance stubs or handoff pointers, not current
verdict stores. Paper files under `docs/paper/` are drafts and must follow the
claim scope recorded here and the related-work verdicts in
`docs/background-related-work.md`.

## Current State

- Stage: runnable prototype plus workload-source selection.
- Blocking gate: the paper needs a Make-owned KVM workload derived from real agent/workspace or environment/cache sources.
- Next action: implement the AI agent workspace lifecycle workload first; use SWE-rebench V2, SWE-Factory-Gym, or MEnvData-SWE for the W4 environment/cache workload next.

## Downstream Document Index

| Doc | Role | Current status | Next required update |
| --- | --- | --- | --- |
| `docs/background-related-work.md` | novelty, closest work, baselines | present; newly consolidated | Keep source status current when new workload reproduction closes. |
| `docs/design.md` | mechanism and artifact boundary | missing | Define the one-decision-function VFS name-resolution ABI and policy/lower-FS boundary. |
| `docs/implementation.md` | prototype and runnable commands | missing | Document Make-owned KVM paths once the selected workload is implemented. |
| `docs/evaluation.md` | experiment plan, results, claim verdict | missing | Convert workload-source decisions into run matrix, oracles, baselines, and thresholds. |

## Intro P1: Problem And Stakes

Purpose: establish why dynamic path views matter now.

Draft paragraph:
AI agents, service sandboxes, and build/environment systems increasingly need to present different filesystem views to the same unmodified programs as execution state changes. Agent workspaces branch, fork, checkpoint, and hide side effects; service tasks rotate configs, secrets, and generated fixtures; build and cache systems choose among verified local artifacts, canonical backing stores, and regenerated environments. These decisions happen at path-resolution time, but current deployments usually express them by building a user-space filesystem, a custom filesystem or metadata service, or a materialized namespace.

Evidence/claim dependency: BranchFS, Sandlock, AgentFS, Redis AFS, Mirage, YoloFS, OpenHands SDK, Terminal-Bench, SWE-rebench V2, SWE-Factory-Gym, and MEnv/DockSmith trajectory evidence.

Completeness: plausible, needs one implemented real workload trace.

## Intro P2: Status Quo And Gap

Purpose: distinguish the project from FUSE, full filesystems, and static namespace construction.

Draft paragraph:
The status quo offers powerful but coarse mechanisms. FUSE and NFS-like agent filesystems can implement rich semantics, but they put the whole filesystem path into a user-space service. Custom kernel filesystems and metadata services can be fast and expressive, but they require owning file objects, persistence, and metadata layout. Static tables, bind mounts, symlink forests, OverlayFS layers, and projected views are operationally useful, but they materialize a path view outside the VFS lookup decision. The gap is a narrow interface for policies that only need to choose a path view while leaving ordinary VFS objects, lower-filesystem data, writes, permissions, and persistence alone.

Evidence/claim dependency: ExtFUSE, Bento, FUSE studies, DeltaFS, IndexFS, TableFS, Wrapfs, Kubernetes projected-volume style baselines, and our materialized/FUSE baseline rows.

Completeness: good as framing; needs careful wording to avoid claiming mechanism exclusivity.

## Intro P3: Key Insight And Thesis

Purpose: state the central idea.

Draft paragraph:
The key insight is that many of these workloads do not need a new filesystem for all operations. They need a programmable decision at VFS name resolution: for a lookup or directory-enumeration event, select the path view that corresponds to the current workspace, branch, sandbox, cache epoch, or service state. If the kernel keeps ownership of dentries, inodes, file data, writes, permissions, and lower-filesystem semantics, a small eBPF policy can express the path-view decision without replacing the filesystem.

Evidence/claim dependency: real workload traces must show that the selected behavior is path-view/state-transition dominated and can be validated with correctness oracles.

Completeness: thesis is clear; implementation evidence still pending for the new selected workload.

## Intro P4: Proposed Artifact Or Method

Purpose: define `namei_ext`.

Draft paragraph:
`namei_ext` is a narrow VFS name-resolution extension point. A policy is an eBPF program attached through the real `cgroup/namei_ext` path in the modified kernel. The kernel exposes one decision function, with lookup and directory-enumeration represented as event types to that function. The policy returns path-resolution actions; it does not define a filesystem, a YAML policy language, or a replacement VFS object model.

Evidence/claim dependency: kernel ABI/design docs, BPF policy examples, and KVM Phase 1 validation.

Completeness: mechanism boundary is stable; design doc should be created.

## Intro P5: Claims And Evaluation Promise

Purpose: map claims to evidence.

Draft paragraph:
The evaluation should show that `namei_ext` can implement realistic path-view workloads with correctness first: agent workspace lifecycle oracles, service reload/secret-rotation oracles, and environment/cache oracles must pass before latency or overhead is interpreted. The comparison is against natural mechanisms for the same oracle: native workload behavior, FUSE or the source system where applicable, and materialized copy/symlink/bind/Overlay/projected views. Operation-weighted lookup and readdir traces should show where policy decisions occur during state transitions.

Evidence/claim dependency: Make-owned KVM workload result, natural baseline result, operation-weighted trace, and correctness oracle.

Completeness: evaluation promise is defined; next workload implementation is required.

## Intro P6: Contributions, Scope, And Non-Goals

Purpose: keep the paper defensible.

Draft paragraph:
The contribution is not a claim that tables are impossible, that all selected workloads require eBPF, or that `namei_ext` replaces agent filesystems, FUSE, or metadata services. The contribution is a kernel/VFS mechanism point and an evaluation showing when a narrow programmable name-resolution hook is sufficient for real path-view workloads. Full filesystem semantics, storage layout, distributed metadata services, and agent orchestration frameworks remain outside the artifact boundary.

Evidence/claim dependency: related-work map, workload-source catalog, and explicit negative/appendix rows.

Completeness: wording guard is ready.

## Supporting Research State

### Problem Anchor

- Bottom-line problem: dynamic path views are currently implemented with mechanisms that are often broader than the path-resolution decision they need.
- Must-solve bottleneck: demonstrate a real workload where path-view transitions can be implemented correctly through the real kernel/BPF attach path.
- Success condition: correctness oracle passes in KVM, operation-weighted lookup/readdir signal is recorded, and natural baselines are measured for the same oracle.

### Why Now

- Technical/scientific change: AI agents and environment-construction benchmarks now expose public code, traces, and executable oracles for workspace and build/test state transitions.
- New deployment pressure or workload shift: agents and build systems frequently create, fork, checkpoint, evaluate, and discard filesystem views.
- Why prior approaches are newly insufficient: FUSE/custom FS/materialization remain valid, but they are broad for path-view-only policies and should be compared against a narrower VFS hook.

### Target Audience And Venue Bar

Systems reviewers should see a precise kernel mechanism, real workload provenance, KVM validation, correctness-first evaluation, and fair comparisons against FUSE, full filesystem/source-system behavior, and materialized views.

### Method Thesis

- Thesis sentence: a narrow eBPF-controlled VFS name-resolution hook can implement useful dynamic path views for real workloads while preserving lower-filesystem semantics.
- Smallest adequate mechanism: one BPF decision function over lookup and directory-enumeration events.
- Why the mechanism should work: the selected workloads' visible behavior is mostly path selection during state transitions, not custom file data or persistence semantics.

### Dominant Claim

- Core claim: for selected agent/workspace and environment/cache workloads, `namei_ext` can implement the required path-view behavior with correct oracles and lower mechanism scope than FUSE/custom filesystems.
- Stretch claim: this interface is a general programmable filesystem abstraction for path-view policies across agent, service, and cache/environment workloads.
- Evidence needed to promote stretch claim: at least two real workload families beyond controlled fixtures, with KVM correctness, operation-weighted traces, and natural baseline comparisons.

### Core Mechanism

`namei_ext` hooks VFS name resolution, not file operations. Policies are eBPF programs under `bpf/policies/*.bpf.c`. The kernel retains VFS object ownership and lower-filesystem semantics.

### Scope And Non-Goals

In scope: lookup/readdir path-view policy, workspace/sandbox/cache/service path-state transitions, KVM validation, and natural baselines.

Out of scope: new filesystem implementation, distributed metadata service, storage layout changes, YAML/JSON policy language, and proof that static tables or FUSE cannot handle a workload.

### Claim Ledger

| ID | Claim | Scope | Metric/evidence needed | Status |
| --- | --- | --- | --- | --- |
| C1 | `namei_ext` is a narrow, safe mechanism boundary for programmable path views. | VFS lookup/readdir policies in the modified kernel. | ABI/design doc, BPF policy examples, KVM attach validation, lower-FS semantic boundary checks. | proposed |
| C2 | Real agent workspace lifecycle can be expressed as path-view policy. | Branch/session/workspace/COW/checkpoint/fork/protected-path workloads. | Make-owned KVM workload using BranchFS/Sandlock/AgentFS/OpenHands/Terminal-Bench style source, correctness oracle, operation-weighted trace, natural baselines. | next |
| C3 | Real environment/cache reuse can be expressed as path-view policy. | SWE-rebench V2, SWE-Factory-Gym, or MEnvData-SWE style Docker-backed build/test tasks. | Correctness oracle, stale/corrupt/update-window behavior, operation-weighted cache path signal, native/FUSE/materialized baselines. | proposed |
| C4 | The mechanism is narrower than FUSE/custom FS for path-view-only workloads. | Selected workloads where lower FS owns file data and writes. | Code-size/scope comparison, baseline behavior, explanation of non-owned semantics. | proposed |

### Largest Plausible Claim

- Bigger claim hypothesis: `namei_ext` is the missing middle point between static namespace construction and full programmable filesystems for dynamic path-view policies.
- Why it would matter: it would let systems reuse the kernel and lower filesystem for ordinary file semantics while specializing only path resolution.
- Experiments needed: AI agent workspace lifecycle, W4 environment/cache reuse, service reload/secret-rotation, FUSE/source-system/materialized baselines, and overhead measurements.
- Cheapest probe: implement one BranchFS/Sandlock/AgentFS-derived KVM workload with commit/abort or protected-path oracle.

### Adjacent Idea Intake

| Adjacent idea/source | What can be absorbed | How it could expand the paper | Risk |
| --- | --- | --- | --- |
| BranchFS/Sandlock/AgentFS/Redis AFS/Mirage/YoloFS | Branch, COW, checkpoint/fork, cache invalidation, staging, hidden-side-effect, and multi-backend namespace oracles. | Strong AI agent workspace lifecycle workload. | Some systems are broader than path resolution; avoid claiming replacement. |
| SWE-rebench V2/SWE-Factory-Gym/MEnvData-SWE | Docker-backed repo build/test oracles. | Strong W4 environment/cache workload. | Full environment generation may require LLM/API or broader image access. |
| MEnvAgent/DockSmith/Multi-Docker-Eval | Environment scripts, trajectories, Docker/eval generation methodology. | Broader W4 task selection and operation traces. | Some artifacts are datasets/trajectories rather than executable systems. |
| DeltaFS/IndexFS/TableFS | Metadata-service/full-filesystem workload shapes. | Appendix or related-work context. | Mainline drift into full FS comparison. |

### Expansion Agenda

| Expansion axis | Bigger experiment | Claim upside | Cost/risk | Probe |
| --- | --- | --- | --- | --- |
| Agent workspace | Branch/session/COW/checkpoint workload from public agent systems. | Makes the paper timely and real. | Needs trace extraction and KVM integration. | Start with one source-backed oracle. |
| Environment/cache | SWE-rebench V2, SWE-Factory-Gym, or MEnvData-SWE stale/corrupt/update-window run. | Best evidence for state-dependent path views. | Docker build variability and image access. | Reuse the passing `pallets__click-2622`, `python-attrs__attrs-586`, SWE-rebench `unidata__netcdf-c-1925`, or clean raw-exit-0 SWE-rebench HF rows such as `pilosus__pip-license-checker-119`, `chrovis__cljam-268`, `pilosus__pip-license-checker-49`, high-cardinality JS row `pbiswas101__mathball-153`, Dart row `nyxx-discord__nyxx-547`, Go rows `mgechev__revive-1408`, `hashicorp__consul-10576`, or `fsouza__fake-gcs-server-1035`, and Java rows `spoonlabs__gumtree-spoon-ast-diff-171` or `jchambers__pushy-850`. Keep caveated HF rows as source-diversity evidence rather than first-choice W4 candidates; avoid `alibaba__fescar-382` unless investigating the mismatch. |
| Service sandbox | nginx reload/update or PostgreSQL secret/config rotation. | Operational systems relevance. | Needs real reload/update trace. | Extend existing W2 fixture. |

### Reviewer Attack Surface

- "This is just FUSE": answer with mechanism boundary, KVM VFS hook, and source-system/FUSE baselines.
- "This is just static tables": answer by not centering table impossibility; show real state transitions and natural baselines.
- "The workloads are synthetic": answer with public source provenance and executable upstream oracles.
- "You built a filesystem": answer by showing lower FS owns objects, data, writes, and permissions.

### Open Questions

- Which one agent workspace source should be the first Make-owned KVM workload?
- Should the first W4 implementation use SWE-rebench V2, SWE-Factory-Gym, or the newly passing MEnvData-SWE slice?
- What is the minimum safe directory-enumeration policy needed for the first workload?
