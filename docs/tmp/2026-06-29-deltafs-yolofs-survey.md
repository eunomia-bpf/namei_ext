# DeltaFS and YoloFS survey for the C8 argument

> 2026-06-29 baseline scope update: this historical record preserves prior reasoning and results. Current C8/B12 guidance is claim-driven baseline selection; exact-map diagnostics are optional boundary evidence only when precomputed mapping is the competing claim.

## Motivation

This note supplements `2026-06-29-c8-fuse-custom-fs-table-survey.md` with two
systems that are closer to the question "why is an exact redirect table not the
right abstraction?"

- DeltaFS asks whether a filesystem namespace needs a single global ground
  truth under massively parallel metadata workloads.
- YoloFS asks whether an agent-facing filesystem needs staged, revisable, and
  dynamically permissioned state rather than command filters or static views.

Both systems are relevant because they are not merely examples of "people used
FUSE" or "people wrote a filesystem." They show cases where namespace state is
dynamic, policy-relevant, and part of the workload semantics.

## Sources inspected

- DeltaFS SC21 page:
  <https://www.sc21.supercomputing.org/proceedings/tech_paper/tech_paper_pages/pap169.html>
- DeltaFS SC21 paper:
  <https://zhengqmark.github.io/papers/deltafs-sc21.pdf>
- DeltaFS repository:
  <https://github.com/pdlfs/deltafs>
- DeltaFS Indexed Massive Directory paper:
  <https://www.cs.cmu.edu/~qingzhen/files/deltafs_pdsw17.pdf>
- YoloFS arXiv page:
  <https://arxiv.org/abs/2604.13536>
- YoloFS HTML:
  <https://ar5iv.labs.arxiv.org/html/2604.13536v2>
- Microsoft Research YoloFS page:
  <https://www.microsoft.com/en-us/research/publication/dont-let-ai-agents-yolo-your-files-shifting-information-and-control-to-filesystems-for-agent-safety-and-autonomy/>
- BranchFS repository:
  <https://github.com/multikernel/branchfs>
- Branch contexts / BranchFS paper:
  <https://arxiv.org/html/2602.08199v2>

## DeltaFS

### What problem it addresses

DeltaFS targets massively parallel HPC metadata workloads. The SC21 abstract
states the bottleneck directly: a parallel filesystem control plane struggles
when every client process must globally synchronize and serialize metadata
mutations. DeltaFS therefore lets jobs self-commit namespace changes to logs
and lets follow-up jobs selectively merge prior logs as needed. The paper calls
this "No Ground Truth": avoiding unnecessary global synchronization for
filesystem metadata.

The repository describes the same design point as a transient filesystem
service with no dedicated metadata servers and no global filesystem namespace.
Metadata service instances are application-owned and run on compute nodes.
DeltaFS uses LSM-style metadata logs, immutable namespace snapshots, and shared
object-store data.

### Why this is not just a redirect table

DeltaFS is not solving "map path A to path B." It changes the metadata model:

- each job has a private namespace view;
- writes become logged metadata mutations;
- snapshots publish immutable namespace states;
- follow-up jobs choose which snapshots/logs to merge;
- read resolution uses the job's own change set first, then dependent change
  sets in user-defined priority order;
- namespace partitioning and log compaction are part of the performance story.

An exact redirect table assumes a current set of authoritative path mappings.
DeltaFS instead makes the absence of a single authoritative namespace the core
design. A table could represent one materialized snapshot after the fact, but
not the write/merge/snapshot/priority machinery without becoming a generated
summary of the filesystem's metadata state.

### Why DeltaFS built a filesystem-like service

DeltaFS built a custom namespace and metadata service because existing parallel
filesystems impose global metadata coordination that does not scale with
application concurrency. The system uses application resources for metadata
service, packs metadata into log objects, and decouples filesystem namespace
management from a centralized platform service.

For `namei_ext`, DeltaFS supports the general design-space point: some
workloads need more than static namespace materialization because namespace
state is part of the computation. It does not directly support current C8
unless we have an analogous workload where path-resolution state changes across
epochs/actions and table materialization is expensive or stale.

### What it contributes to our paper argument

DeltaFS is useful related work for:

- dynamic namespace views;
- snapshot/manifest-based namespace state;
- avoiding a global ground truth namespace;
- using application-owned resources for metadata policy;
- showing why "just store exact paths in a table" can miss the workload's
  metadata semantics.

It is not a direct baseline for Phase 1 `namei_ext` because it owns metadata
creation/removal, snapshots, object-store layout, and data placement. Those are
outside current `PASS/REDIRECT` lookup/readdir.

## YoloFS

### What problem it addresses

YoloFS targets AI coding agents that operate on user filesystems. Its paper
argues that agents lack two things: information about their filesystem effects
and control over those effects. The paper studies 290 public misuse reports
across 13 frameworks and finds failures such as destructive writes/deletes,
secret reads, policy bypasses, and weak rollback.

YoloFS responds by moving information and control into the filesystem. It has
three main mechanisms:

- staging: redirect mutations into staged state until commit/abort;
- snapshots and travel: let agents return to previous staged states for
  self-correction;
- progressive permission: gate accesses with dynamic path rules and ask users
  only when needed.

The implementation is a Linux stackable filesystem: a kernel module on the
critical path and a userspace CLI for higher-level operations. It maintains an
override tree on VFS dentries, stores staged data in a `.yolo/` directory, and
uses a directory journal.

### Why this is not just a redirect table

YoloFS is closer than DeltaFS to the C8 question. It has an explicit path state
machine:

- `BasePath(src)`: a path maps to some base filesystem path;
- `StagedFile(ino, gen)`: a path maps to staged content with a generation;
- `Tombstone`: a path resolves as deleted;
- journal records for stage, rename, delete, snapshot, and travel;
- permission rules that are resolved along the path and can evolve during the
  session.

An exact redirect table can represent a single resolved view, but it does not
capture:

- revocable mutation state before commit;
- snapshot generations and travel;
- tombstones and readdir consistency across staged/base views;
- dynamic permission state that can loosen or tighten at runtime;
- audit history and user review semantics.

YoloFS explicitly rejects conventional staging through mirrored upper
directories as too expensive for agent workloads. It instead decouples contents
from paths using a flat file store plus an override tree and journal. This is a
good example of a workload where "materialize the current view" is not enough;
the system needs efficient state transitions and auditability.

### Why YoloFS built a filesystem

YoloFS needs to mediate both read and write effects at the point where they
occur. Command-string filters and model instructions are insufficient because
shell commands can bypass framework-level policy and the agent cannot reliably
predict command side effects. A filesystem is the enforcement point that sees
actual file operations.

Unlike `namei_ext`, YoloFS owns write-path staging, snapshot state, permission
rules, commit/abort, and journaled history. It is therefore broader than
Phase 1 `namei_ext`.

### What it contributes to our paper argument

YoloFS is important for our related work because it is a current example of
"agent-native filesystem" design. It supports these points:

- agent workloads create a real need for filesystem-level information and
  control;
- command filters and static permissions are inadequate for agent sessions;
- staged views and snapshots are path-state problems, not only file-copy
  problems;
- OverlayFS and FUSE-like branching filesystems are natural baselines for
  agent workspace views.

It also constrains our claims:

- If we mention agent sandboxes, YoloFS becomes close related work and maybe a
  stronger baseline than generic FUSE.
- `namei_ext` cannot claim YoloFS-like safety, staging, rollback, progressive
  permission, or commit semantics.
- The safer `namei_ext` positioning is as a lower-level VFS name-resolution
  hook that might implement a cheaper subset of path-view redirection, not as
  a replacement for an agent-native filesystem.

## BranchFS side note

YoloFS compares against BranchFS, a recent FUSE filesystem for agentic
exploration. BranchFS provides isolated copy-on-write workspaces, branch
creation, commit, and sibling invalidation without root privileges. It is
highly relevant if the paper pivots to agent workspace fork/fanout.

BranchFS reinforces the same lesson: agentic exploration needs lifecycle
semantics over workspace state. A redirect table can encode a branch's visible
paths only after the branch state is already computed. It is not itself the
branch lifecycle mechanism.

## Implications for C8

DeltaFS and YoloFS make the C8 experiment sharper, but they do not imply that
every C8 experiment needs a table-only baseline. A table counterfactual is
useful when the paper claims value over exact precomputed mappings. The
broader question is:

> What simpler mechanism already captures this workload's namespace lifecycle,
> and does `namei_ext` improve on that mechanism while staying limited to name
> resolution?

For a W4 cache-locality C8 experiment, exact-table variants are optional
diagnostics. If they are included, charge them for all updates required to
track hit/miss/stale/corrupt state and generation changes. But the main
baseline may instead be the existing cache tool, a materialized cache
directory, FUSE, or a BuildKit/Bazel-style mechanism.

For an agent-sandbox or W1-style lifecycle experiment, a table can probably
encode one branch/action view, but BranchFS/YoloFS/OverlayFS/copy-tree/git
worktree-style lifecycle baselines may be more relevant. Include table
regeneration only if the tested claim is specifically about exact view
precomputation versus dynamic lookup policy.

For W3 restore/session views, DeltaFS and YoloFS both suggest using generations
as first-class state. A table-only baseline can be useful to test mixed-epoch
visibility, but it should not displace restore mechanisms that are closer to
the actual lifecycle being claimed.

## Implications for related work text

Suggested related-work paragraph:

> DeltaFS and YoloFS show two cases where namespace state is itself the systems
> problem. DeltaFS avoids a single global filesystem namespace for massively
> parallel HPC metadata, using per-job metadata services, mutation logs, and
> published namespace snapshots. YoloFS builds an agent-native stackable
> filesystem because agent sessions need staged mutations, snapshots, and
> dynamic path permissions that command filters or static namespace views do
> not provide. `namei_ext` is narrower than both: it does not own metadata
> creation, write-path staging, snapshots, or commit semantics. Instead, it
> asks whether a VFS name-resolution hook can cover the read-mostly path-view
> subset while preserving lower-filesystem ownership.

Suggested C8 wording:

> Baselines should follow the claim. If the claim is dynamic lookup policy
> rather than exact mapping, include a table counterfactual and charge its
> regeneration, stale-window, and materialization costs. If the claim is a
> lighter-weight name-resolution hook than a filesystem or lifecycle manager,
> compare against that filesystem or lifecycle manager instead.

## Bottom line

DeltaFS and YoloFS are exactly the kind of related work that should be in the
survey. They show why real systems sometimes move namespace management into a
specialized filesystem layer: not because exact mappings are impossible, but
because maintaining the correct mapping over time is the hard part. For
`namei_ext`, that means C8 should focus on dynamic state transitions and update
cost when those are the claim, but it should not force every workload into a
redirect-table comparison.
