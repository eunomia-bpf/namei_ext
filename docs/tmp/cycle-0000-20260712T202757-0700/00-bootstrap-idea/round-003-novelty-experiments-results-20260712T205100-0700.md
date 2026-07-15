# Round 3 Novelty, Experiments, And Results

Timestamp: 2026-07-12T20:51:00-0700

Parent run path: `docs/tmp/cycle-0000-20260712T202757-0700/00-bootstrap-idea/`

Role: fresh independent Round 3 discussant for `iter-refine-ideas`.

Central question: What published work and experimental results would make
researchers believe, limit, or change this direction?

## Entry Snapshot

I read the following project files completely and treated them as the only
project input snapshot for this report:

- `docs/user-instruction.md`
- `docs/questions-for-author.md`
- `docs/idea-story.md`
- `docs/design.md`
- `docs/implementation.md`
- `docs/evaluation.md`
- `docs/background-related-work.md`
- `docs/reference/INDEX.md`
- `docs/reference/CODE_SOURCES.md`
- `docs/paper/Makefile`
- `docs/paper/README.md`
- `docs/paper/evaluation.md`
- `docs/paper/refs.bib`
- `docs/paper/main.tex`
- `docs/paper/sections/01-introduction.tex`
- `docs/paper/sections/02-background.tex`
- `docs/paper/sections/02-motivation.tex`
- `docs/paper/sections/03-design.tex`
- `docs/paper/sections/04-implementation.tex`
- `docs/paper/sections/05-evaluation.tex`
- `docs/paper/sections/06-related-work.tex`
- `docs/paper/sections/07-limitations.tex`
- `docs/paper/sections/08-conclusion.tex`
- `docs/tmp/2026-07-12-idea-shrinkage-trajectory-audit.md`
- `docs/tmp/2026-07-13-user-instruction-and-complete-experiment-audit.md`
- `docs/tmp/2026-07-13-osdi-sosp-readiness-audit.md`
- `docs/tmp/2026-07-13-story-drift-audit.md`
- `docs/tmp/2026-07-13-agent-workspace-complete-experiment-plan.md`
- `docs/tmp/2026-07-13-environment-cache-complete-experiment-plan.md`

I did not read or use Round 1, Round 2, or other files in this cycle
directory.

## Current Idea As I Understand It

The current idea is not that `namei_ext` is a new filesystem, a table-based
redirect mechanism, or a proof that FUSE, OverlayFS, bind mounts, projected
volumes, copies, or symlinks cannot work. The idea is that modern systems have
a recurring subproblem: state changes alter which existing object a pathname
denotes, or whether that object is visible, while file data, writes,
permissions, page cache, persistence, and consistency should remain owned by
the VFS and lower filesystem.

`namei_ext` tests whether this subproblem deserves a `sched_ext`-style VFS
extension point. eBPF supplies bounded policy at lookup and readdir; the kernel
keeps ownership of filesystem machinery. The design space is fixed by the
user's words and current canonical documents:

```text
bind/Overlay/materialization < eBPF LSM < namei_ext < FUSE/custom FS
```

The three RQs are also fixed:

- RQ1: expressiveness and sufficiency for real state-dependent path-view
  policies without taking over filesystem semantics.
- RQ2: cost of VFS name-resolution policy compared with feature-equivalent
  FUSE.
- RQ3: safety and boundary versus custom or stackable filesystem ownership.

The current draft is strongest where it says source characterization selects
workloads and oracles, but claim-moving evidence must come from complete
Make-owned, KVM-validated, same-oracle experiments.

## Closest Published Work And Source Systems

Based on the verified reference and source inventory, I see no full same-claim
precedent in the snapshot. Same-claim risk is medium because many neighboring
systems are close in setting or mechanism, but they mostly occupy broader
filesystem, runtime, sandbox, environment-builder, or metadata-service
boundaries.

The closest mechanism work is:

- FUSE and FUSE studies: the direct programmable-filesystem cost comparison.
  The inventory explicitly warns against generic "FUSE is slow" claims; RQ2
  needs direct workload-specific measurement.
- ExtFUSE: an important pressure point because it moves selected FUSE handling
  into the kernel. It limits any argument that kernel involvement alone is
  novel. The gap is that ExtFUSE remains a FUSE-extension boundary, while
  `namei_ext` exposes only a VFS name-resolution decision.
- Wrapfs and stackable filesystems: the classic broader boundary for adding
  filesystem behavior under existing applications. These matter for RQ3.
- Bento: safer in-kernel filesystem construction. It weakens any safety claim
  that merely says "kernel filesystems are hard," but it still asks the
  developer to build a filesystem.
- OverlayFS, bind mounts, projected volumes, symlink forests, and copies: valid
  namespace construction mechanisms, but the user's instructions explicitly
  demote them from central RQ opponents.
- eBPF LSM, Landlock, and fanotify: nearby kernel hooks. They matter because
  reviewers may ask why existing security or event hooks are not enough. The
  answer must stay precise: those hooks mediate, deny, or observe operations;
  `namei_ext` selects existing objects during name resolution.

The closest source-system workload families are:

- Agent workspace and sandbox systems: AgentFS, BranchFS, Sandlock, YoloFS,
  Mirage, Redis AFS, OpenHands, SWE-agent, SWE-ReX, SWE-MiniSandbox,
  AgentCgroup, and Terminal-Bench. These provide branch, fork, checkpoint, COW,
  whiteout, protected path, hidden side effect, cache invalidation, symlink,
  command-session, workspace, and tool-call evidence. They are workload and
  boundary sources, not things the paper should claim to replace wholesale.
- Environment/cache systems: SWE-Factory-Gym, MEnvData-SWE, SWE-rebench V2,
  DockSmith, and Multi-Docker-Eval. These supply executable build/test oracles,
  Docker/image/eval rows, and environment-construction pressure. The current
  strongest usable rows are selected clean reproductions, not full-corpus
  reproduction claims.
- Service/config systems: Kubernetes projected volumes and service reload or
  config/secret/certificate rotation are the pending non-agent family. The
  snapshot does not yet contain a concrete same-oracle source row strong enough
  to be a main experiment.
- Metadata and full filesystem systems: DeltaFS, IndexFS, TableFS, NOVA,
  BetrFS, and composite-file FS anchor the "full metadata/storage ownership"
  boundary. They are related work and possible appendix context, not mainline
  evidence unless the paper intentionally expands into metadata services.

The most important novelty boundary is therefore not "nobody has dynamic path
views" and not "nobody has programmable filesystems." The defensible novelty is
that this project isolates a narrower VFS name-resolution policy boundary and
tests whether real source-derived path-view workloads can live there.

## Results That Would Make Researchers Believe

Researchers would believe the paper if the results make the middle boundary
feel necessary, fair, and empirically real. I would look for four classes of
evidence.

First, the source characterization must be broad but disciplined. It should
show recurring path-view transitions across agent/workspace,
environment/cache, and at least one non-agent operational family, while keeping
evidence status explicit. This is not enough by itself, but it prevents the
paper from reading as one handpicked AgentFS adaptation.

Second, Experiment A must be a full AgentFS-derived lifecycle, not the current
preflight. Belief-changing evidence would include:

- same AgentFS-derived final-tree, COW, whiteout, symlink, cache-invalidation,
  branch/checkpoint oracle for `namei_ext` and FUSE;
- real `cgroup/namei_ext` attach in KVM;
- operation-weighted lookup/readdir traces proving the policy is engaged on
  the path operations that matter;
- lower-FS semantic checks showing data, writes, permissions, page cache, and
  persistence remain lower-FS owned;
- a feature-equivalent FUSE implementation that passes the same oracle before
  cost is interpreted;
- invalid-policy and stale-target containment evidence;
- result review that audits fairness and marks unsupported cells incomplete,
  not victorious.

Third, Experiment B must prove the abstraction is not agent-specific. The
environment/cache result needs a pre-registered row suite and a
`path-view-manifest.jsonl` that shows the source evaluator actually opens,
stats, executes, or enumerates the policy-controlled paths. A compelling
result would cover hit, miss, stale, corrupt, and epoch-update states over
clean SWE-Factory-Gym, MEnvData-SWE, or SWE-rebench V2 rows, with the unchanged
source build/test oracle and a feature-equivalent FUSE cache/policy view.

Fourth, RQ3 needs evidence stronger than a prose table. The paper should show
for the same policies: which filesystem methods a FUSE/custom/stackable design
would own, where daemon availability or privileged code enters, what custom
state must persist, and how malformed decisions are contained by the verifier
and kernel validation. RQ3 becomes believable when it is tied to the same
oracle as RQ1/RQ2, not when it is a generic "less code is safer" claim.

## Results That Would Limit Or Change The Direction

The direction should not shrink because an early prototype lacks an action or a
FUSE row is incomplete. But some results would legitimately limit the story:

- If the full AgentFS-derived oracle requires synthetic contents, custom
  metadata persistence, post-open data-path mediation, write-conflict
  resolution, or agent-runtime orchestration inside the filesystem boundary,
  then that workload is not a clean `namei_ext` workload. The paper should
  keep the larger hypothesis but move that exact oracle to a boundary/negative
  case and choose a stronger path-view representative.
- If the environment/cache suite cannot produce a path-view manifest in which
  the source evaluator actually depends on lookup-time selection, then
  environment/cache is not yet claim-moving evidence. It may still motivate the
  idea, but the decisive second experiment must change.
- If feature-equivalent FUSE matches or beats `namei_ext` cost on the same
  oracle and operation mix, RQ2 is bounded or contradicted for that workload.
  The paper could still have an RQ3 boundary story, but it should not imply a
  general performance win.
- If custom/stackable or FUSE designs do not actually own more meaningful
  methods, state, or failure surface for the admitted policies, RQ3 weakens.
  The paper would need to focus on where verifier-bounded attachment and
  lower-FS ownership still matter, or find workloads where the boundary
  difference is real.
- If operation-weighted traces show the workloads barely exercise lookup or
  readdir after setup, then the main evidence is misaligned. That would not
  falsify the abstraction generally, but it would invalidate those workloads as
  headline experiments.

## Planned Results That Are Not Enough

Several planned or existing results are useful but not sufficient:

- The current `HIDE` and `SELECT_TARGET` KVM validations show prototype
  feasibility, not RQ1 expressiveness for source workloads.
- The Agent workspace preflight is dependency evidence. It lacks the full
  AgentFS-derived lifecycle, feature-equivalent FUSE cell, result review,
  complete operation-weighted traces, and custom/stackable boundary audit.
- Source reproductions and workload inventory motivate the experiments but do
  not establish `namei_ext` expressiveness.
- A table-only or static-table insufficiency result is explicitly not the
  novelty line and should not return.
- Microbenchmarks without a source oracle are overhead context, not the main
  cost answer.
- A FUSE row that implements a weaker policy, sees weaker information, or fails
  the oracle leaves RQ2 incomplete.
- An RQ3 ownership table without same-oracle policy evidence is background, not
  a safety/boundary result.
- Service/config source inspection is not enough for Experiment C. It needs a
  concrete service oracle where lookup-time object selection changes
  service-visible behavior.

## Unexpected Experimental Directions Or Larger Framings

1. Treat operation-weighted path-view pressure as a first-class result. The
   source inventory includes AgentCgroup, OpenHands, SWE-agent, SWE-ReX, and
   Terminal-Bench evidence that can identify tool-call and command boundaries.
   A strong experiment could show where real agent execution spends path-view
   decisions: during checkout, branch, build, test, hidden side-effect checks,
   cache invalidation, or service setup. This would not add a new RQ. It would
   make RQ1 and RQ2 more believable by showing that the admitted workload is
   representative in operation mix, not merely correct on a small final-tree
   oracle.

2. Make invalid-policy containment a visible cross-workload experiment rather
   than an appendix check. For a `sched_ext`-style extension point, the
   verifier and kernel validation boundary is part of the scientific claim.
   Testing malformed target IDs, stale registrations, unsupported final-object
   selection, invalid redirect names, and attach-mode deny across Agent and
   environment/cache policies would make RQ3 more concrete. The result should
   be framed as boundary evidence, not as a new central contribution.

3. Use service/config as an operational stress test only if it is source-real.
   The tempting weak version is a toy nginx or PostgreSQL reload fixture. The
   stronger unexpected direction is to find a Kubernetes projected-volume,
   secret/certificate rotation, or config epoch source where stale object
   selection produces an observable service failure and correct lookup-time
   selection fixes it without owning reload logic. If found, this would prevent
   the paper from looking agent-specific.

4. Explore checkpoint/restore path virtualization as a boundary source, not a
   main comparison. The bibliography already contains DMTCP/path
   virtualization and CRIU-adjacent entries as unused material. If public
   source evidence is available later, this could supply a larger "execution
   context path view" framing. It should not displace Agent workspace and
   environment/cache unless it yields a complete same-oracle experiment.

## A Strictly Larger Version Of The Current Story

The larger version is:

> VFS name resolution is a general OS policy boundary for transient execution
> contexts. Agent workspaces, build/test environments, service configuration,
> and checkpoint/restore-style execution contexts all need low-latency
> state-dependent selection among existing filesystem objects, while the kernel
> and lower filesystem should keep object and data semantics. `namei_ext`
> demonstrates that this policy/ownership split can be made verifier-bounded,
> workload-scoped, and cheaper or narrower than filesystem-service ownership.

This is strictly larger than the current story because it expands the
motivation from "path views in agent and environment systems" to "transient
execution contexts" across agents, build/test, services, and restore/replay.
It is not a different artifact and it does not change the RQs. It would need
substantially more evidence:

- a source-characterization table with at least one credible source row in each
  family;
- the full AgentFS-derived experiment as the headline result;
- the full environment/cache experiment as the non-agent decisive result;
- a service/config or checkpoint/restore source oracle as breadth evidence,
  admitted only if lookup-time object selection changes behavior;
- direct FUSE comparisons for each main same-oracle workload;
- RQ3 boundary evidence showing the broader mechanisms own unnecessary
  filesystem or daemon responsibilities for those exact policies.

This larger framing is attractive, but it is only stronger if the third family
is real. Without that evidence it would become a motivational overreach.

## Original Narrative, Current Version, And My Proposal

The original/earlier narrative did better at ambition. It treated `namei_ext`
as a systems abstraction: a `sched_ext`-style middle point between namespace
construction and full programmable filesystems. It had broader use cases and a
clearer sense that the project is about OS boundary placement, not one
workload trick.

The shrunken intermediate narrative improved discipline but lost force. It
correctly dropped table-only impossibility and exclusive-necessity claims, but
it overcorrected into two-transition feasibility and defensive negative-result
language.

The current version improves substantially. It restores the mechanism sequence,
fixes RQ2 on FUSE, moves RQ3 to custom/stackable FS boundary evidence, requires
complete experiments, and keeps source characterization separate from
claim-moving evidence. What it still risks losing is the confident "why now and
why this boundary" argument. The draft reads partly like a strong plan rather
than a result-backed systems paper because the full experiments are not done.

My proposal is genuinely stronger only if it is used to raise the evidence bar,
not to add new names or new scope text. The core idea should remain unchanged.
The improvement is to make belief-changing evidence explicit: full
same-oracle Agent and environment/cache matrices, operation-weighted path-view
pressure, invalid-policy containment, and one real non-agent breadth source if
it exists. That keeps the idea large while preventing unsupported claims.

## Conflicts With Exact User Instructions

The report's proposals are consistent with the authoritative instructions I
read:

- Do not shrink the idea: I do not propose replacing `namei_ext` with a
  two-transition feasibility claim or with current implemented subsets.
- Do not return to table-only/static-table/dynamic-necessity proof: I treat
  table-only and `table_redirect` results as insufficient and explicitly not
  central.
- Use complete OSDI/SOSP experiments: I require integrated same-oracle KVM
  matrices with `namei_ext`, feature-equivalent FUSE, custom/stackable
  boundary evidence, controls, raw results, repetitions/uncertainty, and result
  review.
- RQ2 compares FUSE: I keep feature-equivalent FUSE as the central RQ2
  comparison and state that incomplete FUSE makes RQ2 incomplete.
- RQ3 is boundary/safety versus custom/stackable FS: I do not move RQ3 back to
  bind/Overlay/projected/copy/symlink comparisons.
- Do not use negative results to weaken the hypothesis prematurely: I
  distinguish incomplete prototype/comparison failures from valid
  same-oracle contradictions.
- Do not claim unreproduced sources as reproduced: I preserve the source
  inventory's caveats around YoloFS private submodules, full SWE-rebench,
  full Gym/MEnv, DockSmith, Multi-Docker-Eval, Redis AFS mounted sync, Mirage
  live providers, and metadata-service reproductions.

The only tension is that the paper draft's conclusion still says the prototype
implements pass-through and validated redirect, while the canonical docs now
also discuss KVM-validated hide and registered-target increments. That is a
paper-synchronization issue, not a scientific conflict. It should not change
the idea or RQs.

## Remaining Questions And Next Evidence

- Which exact AgentFS-derived lifecycle is the smallest one that is still
  source-faithful and exercises COW, whiteout, symlink, cache invalidation,
  state update, lookup, and readdir?
- Does the full Agent lifecycle require synthetic parent-directory aliases or
  final-file target selection? If yes, implement only the bounded semantics
  needed by that oracle.
- Can the FUSE comparison be made feature-equivalent without accidentally
  giving the daemon broader information or weaker obligations?
- Which environment/cache rows produce real path-view manifests under KVM,
  rather than only successful Docker/eval reproduction?
- What is the concrete RQ3 measurement for privileged code surface and owned
  filesystem methods, and how will it be kept source-grounded rather than
  rhetorical?
- Is there a real service/config source oracle that depends on lookup-time
  object selection, or should Experiment C stay out of the main evaluation?

Suggested next evidence:

1. Freeze the exact Experiment A oracle and implement the missing bounded
   actions it needs.
2. Build the feature-equivalent FUSE policy for the same Agent oracle before
   collecting performance numbers.
3. Add operation-weighted trace collection and lower-FS semantic checks to the
   Agent result root.
4. Run a preflight environment/cache path-view manifest for two clean candidate
   rows before committing the full suite.
5. Draft the RQ3 boundary audit schema before running results, so the audit is
   not reverse-engineered around a favorable outcome.

## Final Self-Check

- I did not narrow the author's position to current prototype capability,
  table-only evidence, static-table impossibility, or two selected transitions.
- I did not change the fixed RQs.
- I did not restore rejected terminology or promote `table_redirect`, source
  characterization, path-view manifests, operation traces, or invalid-policy
  controls into the central contribution.
- I did not make claims about sources beyond the verified inventory in the
  provided files.
- I preserved the central contribution as the design and implementation of a
  `sched_ext`-style VFS name-resolution extension point, with evidence required
  from complete same-oracle KVM experiments.
