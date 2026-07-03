# Source role reassessment

## Motivation

The earlier source survey used a too-coarse split between direct workload
seeds, methodology sources, and related work. That split made several sources
look useless even though they provide important reviewer-facing evidence. The
right question is not whether a paper directly becomes a workload. The right
question is what evidence role it can play in the `namei_ext` argument.

## Reassessed Roles

### Workload seeds

These sources can directly feed Make-owned KVM workloads because they provide
code, tasks, or executable oracles:

- BranchFS, Sandlock, SWE-MiniSandbox, SWE-agent/SWE-ReX, OpenHands SDK,
  Terminal-Bench, and AgentCgroup traces for AI agent workspace lifecycle.
- ccache, BuildKit/Go cache, SWE-Factory, MEnvAgent, Multi-Docker-Eval,
  SWE-rebench V2, and SWE-agent/SWE-ReX builds for environment/cache reuse.
- nginx, PostgreSQL, Kubernetes projected volumes, and Docker Compose
  configs/secrets for service fixture sandboxing.
- AgentFS, Redis Agent Filesystem, and Mirage as open-source agent filesystem
  systems whose session, checkpoint, fork, audit, mount, and multi-backend
  behavior can inform agent workspace workloads and baselines.

### Methodology and oracle sources

YoloFS should be treated as methodology and oracle evidence. This survey did not find a
public implementation, so we should not claim to reproduce YoloFS. However, it
is strong methodology evidence: it studies agent filesystem misuse, defines
hidden side-effect tasks, and evaluates staging, snapshots, and progressive
permission. Its value is oracle design for agent filesystem safety:
side-effect containment, reviewable staged effects, rollback/correction, and
permission interaction.

DockSmith should be treated as methodology and trajectory evidence. The arXiv paper
links a public Hugging Face collection containing the DockSmith model and a
Docker-building trajectory dataset. Even without a primary public code repo,
DockSmith is evidence that environment construction is a first-class agentic
task, not just setup noise. It should guide W4 source selection together with
SWE-Factory, Multi-Docker-Eval, and MEnvAgent.

### Mechanism and baseline anchors

DeltaFS, IndexFS, TableFS, Bento, and ExtFUSE are meaningful, but mostly as
mechanism anchors rather than main workloads.

- ExtFUSE is especially relevant because it is an eBPF/FUSE hybrid. It shows a
  nearby design point where specialized FUSE request handlers move into the
  kernel. The contrast with `namei_ext` should be about hook placement and
  ownership: ExtFUSE accelerates a user-space filesystem path; `namei_ext`
  exposes only name-resolution decisions while the kernel and lower filesystem
  retain object and data semantics.
- Bento is the custom in-kernel filesystem anchor. It makes kernel filesystem
  development safer with Rust, but it is still a framework for writing a
  filesystem. It supports our design-space comparison without becoming a main
  workload.
- DeltaFS, IndexFS, and TableFS are full metadata/indexing/filesystem systems.
  They show cases where systems own metadata representation and namespace
  organization. Reproducing them would evaluate distributed metadata services,
  not directly evaluate a narrow VFS name-resolution extension.

## What We Need To Show

The paper does not need a redirect-table impossibility argument, and it does
not need a claim that selected workloads require `namei_ext` or eBPF policy
logic.

The paper does need evidence for this narrower claim:

`namei_ext` can implement useful path-view policies for real workloads through a
narrow VFS name-resolution hook, while preserving lower-filesystem ownership;
for the selected workloads, this point in the design space has measurable
correctness, cost, semantic-boundary, and baseline-comparison evidence.

That means each main workload needs:

1. Real source provenance and a reproducible task or trace.
2. A correctness oracle tied to the workload, not to the implementation.
3. Operations during the relevant state transition.
4. Operation-weighted path signal.
5. Natural comparisons: FUSE, projected/bind/copy/symlink/Overlay where
   applicable, native workload mechanism where applicable, and mechanism-family
   comparison to ExtFUSE/Bento/full metadata services in related work.
6. A verdict that can downgrade the claim if the natural mechanism is equally
   good.

## Rejected Framings

- Do not frame the agent workload as a static-table argument.
- Do not frame workload selection as a policy-necessity argument.
- Do not dismiss YoloFS, DockSmith, ExtFUSE, Bento, DeltaFS, IndexFS, or TableFS
  because they are not all direct workload seeds.
- Do not reproduce a full filesystem or distributed metadata service unless the
  claim being tested is explicitly about that mechanism family.

## Documentation Updates

The code-source catalog now separates direct workload seeds, methodology/oracle
sources, and mechanism/baseline anchors. The case-study documents should use
this split when deciding which source belongs in a workload, which belongs in
the oracle design, and which belongs in related work or mechanism comparison.
