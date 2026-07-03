# Reproducible workload source survey

## Motivation

The paper should stop treating `table_redirect.bpf.c` as the central question.
The stronger story is that selected real workloads expose useful path-view
state transitions that `namei_ext` can evaluate through a narrow programmable
name-resolution hook. The right next step is selecting reproducible,
paper-backed workloads whose code or artifact can drive Make-owned KVM
experiments, not proving that a static table or any other mechanism is
insufficient.

## Search Scope

I searched for recent and classic systems with public code or artifacts across:

- AI agent workspace and sandbox systems;
- AI coding-agent execution benchmarks;
- software environment construction and cache reuse systems;
- filesystem papers already motivating FUSE, custom filesystems, or metadata
  services.

New local PDF references were downloaded into `docs/reference/` for Sandlock,
SWE-MiniSandbox, AgentCgroup, SWE-agent, OpenHands SDK, Terminal-Bench,
MEnvAgent, Multi-Docker-Eval, SWE-rebench V2, and DockSmith.

## Selected Paper-Facing Workloads

The formal workload set should be paper-facing, not one-to-one with the old
W1/W2/W3/W4 implementation names.

| Paper-facing workload | Code-backed source candidates | Internal policy families | Policy-state signal |
| --- | --- | --- | --- |
| AI agent workspace lifecycle | BranchFS, Sandlock, SWE-MiniSandbox, SWE-agent/SWE-ReX, OpenHands SDK, Terminal-Bench, AgentCgroup traces, AgentFS, Redis Agent Filesystem, Mirage | W1 build/action view plus W3 checkpoint/rollback path view | The workload branches on session, branch, permission, commit/abort, rollback, and tool-call epoch state. The experiment should measure real agent lifecycle behavior and correctness, not redirect-table diagnostics. |
| Service fixture sandbox | nginx, PostgreSQL, Kubernetes projected volumes, Docker Compose configs/secrets; optionally Sandlock-style agent sandbox tasks | W2 sandbox fixture view | The workload branches on config/secret/cert/socket/endpoint/poison path classes and reload or secret-rotation epochs. The main evidence should be real app health plus no-production-open under a live transition. |
| Content-verified cache and environment reuse | ccache, BuildKit/Go cache, DockSmith trajectories, SWE-Factory, MEnvAgent, Multi-Docker-Eval, SWE-rebench V2, SWE-agent/SWE-ReX task builds | W4 cache locality view | The workload branches on verified hit, stale reject, corrupt reject, miss fallback, canonical backing, and cache/environment update epoch. The main evidence should be live operations during stale/corrupt/update windows. |

Legacy W1 and W3 remain useful as implementation families and boundary
fixtures, but they should not be promoted as independent main workloads unless
they become real transition traces from the code-backed sources above.

## Source Role Decisions

### Keep

- **BranchFS / branch contexts**: public FUSE implementation with branch create,
  nested branch, commit, abort, and `@branch` virtual paths. This is the best
  reproducible source for agent workspace lifecycle semantics.
- **Sandlock**: public process sandbox using Linux primitives plus COW workspace
  semantics. This is a good source for agent safety workloads and readable /
  writable path classes.
- **SWE-MiniSandbox**: public container-free SWE agent sandbox using namespaces,
  chroot, and bind mounts. This is the strongest scale-oriented agent sandbox
  source because it already stresses per-instance setup and environment reuse.
- **SWE-agent / SWE-ReX**: public agent and sandboxed runtime. Use these to
  produce real issue-fixing command, build, test, and file-access traces.
- **OpenHands SDK**: public SDK with local and ephemeral workspaces. Use for
  multi-agent workspace traces and tool-call lifecycle boundaries.
- **Terminal-Bench**: public task benchmark with terminal environments and
  executable tests. Use selected tasks as agent terminal workloads with
  correctness oracles.
- **MEnvAgent / Multi-Docker-Eval / SWE-rebench V2**: public code or datasets
  around environment construction. Use these for cache/environment reuse and
  BuildKit-style dynamic update workloads.
- **AgentCgroup**: public eBPF agent resource controller and 144-task
  SWE-rebench characterization. Use task lists and tool-call boundaries for
  operation-weighted trace design; do not treat it as a filesystem baseline.
- **AgentFS / Redis Agent Filesystem / Mirage**: public agent-filesystem or
  agent-workspace implementations. Use them to ground agent filesystem
  lifecycle behavior: session state, copy-on-write isolation, checkpoint,
  restore, fork, audit, mount/sync mode, and multi-backend path namespaces.

### Methodology And Oracle Sources

- **YoloFS** is methodology and oracle evidence. This survey did not find a public
  implementation, so it should not be used as a reproduced workload source.
  Its useful role is agent-filesystem oracle design: hidden side effects,
  staged mutations, snapshots, progressive permission, user review, and
  user-agent-filesystem interaction methodology.
- **DockSmith** is methodology and trajectory evidence. The paper links a public
  Hugging Face collection containing the model and Docker-building trajectory
  dataset. Its useful role is to define environment construction as a
  first-class agentic workload and to provide trajectory candidates to inspect
  alongside SWE-Factory, Multi-Docker-Eval, and MEnvAgent. Do not claim a
  primary DockSmith codebase unless one is identified.

### Mechanism And Baseline Anchors

- **ExtFUSE** is a highly relevant mechanism anchor, not a workload seed. It
  uses eBPF to accelerate specialized FUSE request handling; the comparison
  with `namei_ext` should focus on hook placement and ownership, not on a
  generic "FUSE is slow" claim.
- **Bento** is the custom in-kernel filesystem anchor. It improves the
  development/safety story for kernel filesystems, but it still asks developers
  to implement a filesystem; `namei_ext` intentionally exposes a narrower hook.
- **DeltaFS, IndexFS, and TableFS** are full filesystem or metadata-service
  anchors. They are useful related work because they own metadata layout,
  indexing, and namespace organization. Reproducing them would evaluate a
  different system class, so they should not be the next main workloads.
- **Wrapfs and FUSE studies** remain measurement and related-work anchors for
  stackable and user-space filesystem designs.

## Claim Boundary

The documentation should enforce this rule:

> A workload is paper-facing only if it has real code or tasks, observable
> path-state transitions, operation-weighted path signal, and a reproducible
> oracle. Do not define the workload's purpose as proving that another mechanism
> cannot solve it.

The broader evidence target is not mechanism exclusivity. The target is to show
that `namei_ext` can implement useful path-view policies for real workloads
through a narrow VFS name-resolution hook, with workload correctness, natural
baseline comparison, cost, and semantic-boundary evidence.

This is different from claiming interface exclusivity. The result files
currently include targeted boundary runs for W1-W4 and a positive W2 C2 slice.
The next Make-owned KVM runs should upgrade selected code-backed workloads to
live transition evidence and real correctness oracles.

## Next Experiments

1. **AI agent workspace lifecycle**: derive a branch/commit/abort or
   sandbox-dry-run workload from BranchFS/Sandlock plus SWE-agent or
   Terminal-Bench tasks. Oracle: task tests or patch output, branch-visible set,
   protected path rejection, commit/abort state, and operation-weighted branch
   distribution.
2. **W4 live cache/environment transition**: derive BuildKit/ccache/MEnvAgent
   traces with verified hit, stale, corrupt, miss, and update epoch operations.
   Oracle: build output hash, stale/corrupt reject/fallback, cache state
   transition, and operation-weighted cache-path branch distribution.
3. **W2 real reload/rotation**: run nginx reload/update or PostgreSQL
   secret/config rotation with fixture aliases active. Oracle: service health,
   endpoint response, secret hash, no production secret/config open, and
   operation-weighted fixture branch distribution.

No new generic exact-table or materialized-view work should be implemented as a
mainline task. If a reviewer-facing boundary question later requires one, it
must be explicitly scoped as appendix or negative evidence before implementation.
