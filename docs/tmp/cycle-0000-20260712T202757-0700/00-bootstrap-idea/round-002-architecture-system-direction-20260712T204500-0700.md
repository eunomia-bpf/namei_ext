# Round 2: Academic Architecture And System Direction

Timestamp: 2026-07-12T20:45:00-0700

Parent run path: `docs/tmp/cycle-0000-20260712T202757-0700/00-bootstrap-idea/`

Role: fresh independent read-only Round 2 discussant for `iter-refine-ideas`.

Central question: if the `namei_ext` position is correct, what academic
architecture and system direction follow from it?

## Entry Snapshot

I read the following files completely from `/home/yunwei37/workspace/namei_ext`:

- `docs/user-instruction.md`
- `docs/questions-for-author.md`
- `docs/idea-story.md`
- `docs/design.md`
- `docs/implementation.md`
- `docs/evaluation.md`
- `docs/background-related-work.md`
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

I did not read or use any Round 1/Round 3 reports or other files under
`docs/tmp/cycle-0000-20260712T202757-0700/00-bootstrap-idea/`.

## How I Understand The Current Idea

The current idea is not "BPF makes paths programmable" and not "we can redirect
names." The stronger idea is an ownership split:

```text
state-dependent pathname-to-object or visibility policy
  belongs at VFS name resolution

ordinary filesystem objects, data, writes, permissions, page cache,
persistence, and consistency
  remain owned by the kernel and lower filesystem
```

`namei_ext` is therefore a `sched_ext`-style VFS extension point. It offers a
bounded eBPF decision boundary for lookup and directory enumeration while
avoiding the broader ownership boundary of a FUSE daemon, stackable filesystem,
custom filesystem, metadata service, or agent runtime. Its intended position is
the exact design sequence recorded in the user prompt log:

```text
bind/Overlay/materialization < eBPF LSM < namei_ext < FUSE/custom FS
```

The paper should test whether this missing middle is real for source-derived
workloads. It should not argue that bind mounts, OverlayFS, FUSE, custom
filesystems, or source systems are invalid. It should argue, if the evidence
supports it, that some recurring workload state transitions need only
path-view policy over existing objects, and that a verifier-bounded VFS
name-resolution hook is a better boundary for that subset than either
pre-materializing a namespace or owning a filesystem.

## Academic Architecture That Should Follow

### Problem

Modern agent, build/test, cache, environment, and service systems repeatedly
need stable application-visible paths whose bindings change with workload state.
A pathname may need to resolve to a base tree, an upper tree, a checkpoint, a
verified cache object, a canonical object, or a current config/secret object.
The consequence of getting this wrong is not cosmetic: wrong bindings can
validate the wrong revision, leak edits, read stale or corrupt cache contents,
or expose the wrong operational configuration.

The problem should be stated as a boundary problem, not a mechanism problem:
when state changes which existing object a name denotes, where should the
policy live so that the system does not unnecessarily own filesystem semantics?

### Motivation

The motivation should derive from three families, not from current prototype
actions:

1. Agent/workspace systems: branches, COW state, checkpointing, whiteouts,
   symlinks, cache invalidation, git/bash behavior, hidden side effects, and
   final-tree oracles.
2. Environment/cache systems: build/test oracles over hit, miss, stale,
   corrupt, verified-local, canonical, and epoch-update states.
3. Service/config systems: config, secret, certificate, and fixture epochs,
   included only when lookup-time object selection affects service-visible
   behavior.

The characterization should motivate the requirements but not become the main
claim-moving experiment. Its job is to show that the workload pressure is
recurring and source-backed.

### Requirements

The requirements should be solution-independent enough that they could reject
`namei_ext` if the mechanism is wrong:

- The policy point must act at the affected lookup or readdir operation, because
  the path view depends on current workload state.
- Lookup and readdir must be coherent, because source oracles include both
  direct object selection and directory visibility.
- The boundary must preserve lower-filesystem semantics for permissions, file
  data, writes, page cache, persistence, and consistency.
- The policy must be bounded and fail closed on malformed or unsupported
  decisions.
- The scope must be workload-local, currently represented by the
  `cgroup/namei_ext` attach path.
- The evaluation must preserve raw observations and separate correctness from
  performance.

One requirement needs care: "observable provenance" is an evaluation discipline,
not a core system requirement. It belongs in the artifact and evaluation
architecture, not in the minimal abstraction argument unless the paper frames
observability as part of the extension-point contract.

### Mechanism

The system mechanism should stay small:

- one kernel-facing decision function;
- lookup and directory-enumeration event types passed to that function;
- bounded actions such as pass-through, same-parent redirect, hide, and
  registered target selection;
- kernel-held target identities for selections outside the immediate parent,
  rather than arbitrary path strings or userspace callbacks;
- kernel validation and visible failure for invalid decisions;
- ordinary VFS and lower-filesystem continuation after the selected object is
  validated.

The mechanism should not be presented as a new filesystem abstraction. It is a
new VFS name-resolution policy boundary. That distinction is the academic
architecture.

### Contributions

The strongest contribution structure is:

1. A characterization of recurring state-dependent path-view transitions across
   source-backed agent/workspace, environment/cache, and service/config systems,
   with explicit separation between path-view effects and out-of-bound
   filesystem/runtime responsibilities.
2. The design and implementation of `namei_ext`, a `sched_ext`-style VFS
   name-resolution extension point that gives eBPF a bounded lookup/readdir
   policy role while preserving kernel/lower-filesystem ownership.
3. A correctness-first KVM evaluation over complete source-derived workloads
   that measures expressiveness, cost versus feature-equivalent FUSE, and
   safety/ownership boundary versus custom or stackable filesystems.

The contribution should not include a new named taxonomy, a new policy
language, a static-table impossibility proof, or source reproduction as a main
result.

### RQs

The fixed RQs should be preserved exactly in meaning:

- RQ1: expressiveness/sufficiency. Can a narrow VFS name-resolution extension
  express real state-dependent path-view policies without taking over
  filesystem semantics?
- RQ2: cost/overhead versus FUSE. What is the cost of putting programmable
  policy on the VFS name-resolution path compared with a FUSE-based policy
  implementation?
- RQ3: safety/boundary versus custom or stackable filesystem. Does `namei_ext`
  provide a narrower and safer implementation boundary than building a custom
  or stackable filesystem when the needed policy is only name resolution?

The RQs are already architecturally right. Do not split them into workload
families, do not replace RQ3 with materialized-view comparisons, and do not add
a separate "dynamic necessity" RQ.

### Experiments

The system direction requires a small number of integrated experiments. The
experiment should be the unit of belief change:

- Experiment A: AgentFS-derived workspace lifecycle as the headline experiment.
  It should run a full fixed source-derived oracle through `namei_ext`, a
  feature-equivalent FUSE policy, lower-FS controls, invalid-policy containment,
  operation-weighted traces, and custom/stackable boundary evidence.
- Experiment B: environment/cache transition as the decisive non-agent
  experiment. It should pre-register real source rows and cache states, then
  compare `namei_ext` and feature-equivalent FUSE under the same source
  build/test oracle.
- Experiment C: service/config transition only if a real source oracle depends
  on lookup-time object selection. If it is merely projected-volume mechanics
  or app reload behavior, it should remain related work/background.

This architecture means preflights, source reproductions, table diagnostics,
policy-load tests, and prototype action checks are dependencies. They are not
paper experiments.

## Unexpected Architectural Or System Directions

### Direction 1: Treat `namei_ext` As An Admission Test For Filesystem Ownership

The paper currently asks whether `namei_ext` can implement selected path-view
policies. A larger architecture would make each workload answer a more general
question: what is the minimal ownership boundary that can satisfy the oracle?

That reframes `namei_ext` as an empirical admission test:

```text
if a source oracle can be satisfied by bounded lookup/readdir decisions
and lower-FS preservation,
then filesystem ownership was not necessary for that policy slice
```

This is stronger than "we implemented a hook." It gives reviewers a reason to
care even when FUSE or custom filesystems can also implement the behavior.
The evidence needed is an ownership delta per experiment: methods not
implemented, daemon state not owned, post-open data path not mediated, metadata
not persisted by the hook, and failure containment for malformed policies.

### Direction 2: Make Operation-Weighted Path View Pressure A First-Class Result

The current docs mention operation-weighted traces mainly as instrumentation.
They could become a central empirical bridge between characterization and
mechanism: not just "these systems have path-view transitions," but "their
oracle-relevant operations concentrate policy decisions at lookup/readdir in a
way that makes a name-resolution hook the natural boundary."

This avoids the rejected static-table/dynamic-necessity proof. It does not try
to prove alternatives impossible. Instead, it shows where the workload actually
exercises policy and whether the policy rate, action mix, and coherence needs
match the proposed boundary. The evidence needed is per-workload distributions
of lookup, open, stat, access, exec, readdir, action type, epoch transition,
FUSE request path, and no-hook lower-FS behavior.

### Direction 3: Use `namei_ext` To Separate "View State" From "Data State"

A third framing is to say that many source systems conflate two states:
view state, which selects the object visible at a name, and data state, which
owns contents, writes, durability, and consistency. `namei_ext` is a kernel
mechanism for isolating view state as a bounded policy plane while leaving data
state alone.

This would connect agent workspaces and environment/cache systems more cleanly:
both are about changing view state while preserving data-state semantics. The
risk is that "view state" could become another unnecessary coined abstraction.
It is worth using only if it makes the design and experiments simpler, not as a
new novelty label.

## A Strictly Larger Version Of The Current Story

Strictly larger story:

> `namei_ext` tests whether Linux should expose a verifier-bounded path-view
> policy plane at VFS name resolution, analogous to `sched_ext` for scheduling,
> because modern workload systems increasingly need to change object visibility
> and selection independently from filesystem data ownership.

This is larger than the current story in three ways:

- It is not limited to proving two workloads work. The workloads are deep
  evidence for a general OS extension-point argument.
- It turns RQ3 into a positive ownership-boundary result, not just a defensive
  "not custom FS" comparison.
- It treats agent and environment systems as evidence of a broader shift:
  workload-local state transitions are becoming common enough that path-view
  policy deserves a kernel extension point rather than ad hoc materialization or
  full filesystem ownership each time.

Evidence it would need:

- A source-backed characterization across at least the agent/workspace and
  environment/cache families, with service/config admitted only if a real oracle
  exists.
- Two complete KVM same-oracle experiments, not preflights, each with
  feature-equivalent FUSE and ownership-boundary evidence.
- Operation-weighted traces showing that the relevant policy decisions occur at
  lookup/readdir/open/stat/access/exec path resolution rather than requiring
  post-open data mediation.
- Lower-FS preservation evidence for writes, permissions, page cache,
  persistence, and consistency.
- Invalid-policy containment evidence that distinguishes the BPF hook from a
  custom filesystem implementation.
- A credible negative boundary: examples from the same source corpus where the
  workload does need synthetic contents, custom metadata, data-path mediation,
  or runtime orchestration and therefore belongs outside `namei_ext`.

This larger story is genuinely stronger if the full experiments succeed. It is
not stronger if the paper remains a plan, because OSDI/SOSP reviewers will not
accept an extension-point thesis without completed evidence.

## Original, Shrunken, Current, And Proposed Narratives

The original/earlier narrative did something important better: it had a clear
systems abstraction. It treated `namei_ext` as a missing middle between static
namespace construction and full programmable filesystems, with the
`sched_ext`-style policy/ownership split as the intellectual center. That was
the right academic instinct.

The shrunken narrative improved rigor but lost ambition. It removed weak
claims about table-only impossibility and exclusivity, which was necessary.
But it overcorrected into two-transition feasibility, static-table avoidance,
and defensive proposal language. That made the paper safer but less like an
OSDI/SOSP systems contribution.

The current restored version is much better than the shrunken version. It
preserves the mechanism sequence, fixes RQ2 around FUSE, fixes RQ3 around
custom/stackable filesystem boundaries, and demands complete integrated
experiments. Its remaining weakness is that parts of the active paper still
sound like an empirical plan rather than a results-bearing paper, and the
service/config family is not yet backed by a concrete oracle.

My proposal is stronger only if it is used to structure the completed
experiments rather than to add new terminology. The best change is not to
invent a larger name. It is to make the paper's architecture derive every
design choice and experiment from the ownership-boundary thesis.

## Conflicts With Exact User Instructions

I see no necessary conflict between the current restored direction and the
author's exact prompts, but there are several places where execution can drift.

Exact prompt: "`namei_ext` 是一个 `sched_ext`-style VFS extension point，位于 bind/Overlay/materialization 与 FUSE/custom FS 之间。"

Assessment: the proposed architecture preserves this. It should additionally
keep eBPF LSM in the sequence because the later exact prompt says:
"机制定位要写成 bind/Overlay/materialization < eBPF LSM < namei_ext < FUSE/custom FS。"

Exact prompt: "论文也不应该放负面结果，故事越吸引人越好。我们应该根据 hypothesis 改实验尝试能不能证明，而不是根据实验目前的设计问题修改 hypothesis / claim；除非这个 hypothesis 本身完全不可能成立，不然不应该改变我们的 hypothesis。"

Assessment: do not weaken the claim because preflights are incomplete. The
correct action is to implement the missing complete Agent workspace and
environment/cache matrices. Negative or contradictory results should define
boundaries only after full, fair experiments.

Exact prompt: "实验不能是一堆零散的小实验、弱 baseline、proxy-only 检查、smoke test、或者不断更换 baseline 的记录集合。OSDI/SOSP 级别实验必须是少数完整的 integrated experiment..."

Assessment: the current evaluation plan matches this, but the active paper
must not present dependency preflights or source reproductions as paper results.
The architecture should keep Experiment A and B as integrated matrices.

Exact prompt: "不要再把 table-only / table_redirect / '证明 workload 不能用静态 table'作为主线 novelty 或实验目标。"

Assessment: the proposal does not restore that line. Operation-weighted traces
are acceptable only as same-oracle evidence for policy placement and cost, not
as static-table impossibility proof.

Exact prompt: "RQ2 要对比 FUSE。"

Assessment: this is fixed and should remain fixed. Any experiment without a
feature-equivalent FUSE row leaves RQ2 incomplete.

Exact prompt: "RQ3 应该考虑是否对比 custom filesystem / FUSE / stackable filesystem 这类 broader FS boundary 的安全性或实现边界。"

Assessment: the restored plan correctly separates FUSE as the RQ2 cost
comparison and custom/stackable filesystems as the RQ3 boundary comparison.
The report's proposal preserves that separation.

Exact prompt: "DeltaFS / IndexFS / TableFS / Bento / ExtFUSE 等主要是 related work 或 boundary evidence，不能挤掉 Agent workspace 和 environment/cache 主实验。"

Assessment: my proposal keeps those systems as boundary/related-work evidence.
They should not displace Experiment A or B.

Potential conflict: if the larger story is written as "Linux should expose a
path-view plane" without completed results, it would overclaim. The safe but
ambitious version is: `namei_ext` tests whether such an extension point is the
right boundary, and the complete experiments answer that question.

## Remaining Questions And Suggested Next Evidence

1. Does the AgentFS-derived workload require final file target selection,
   synthetic parent-directory aliases, or additional bounded semantics beyond
   the current prototype? Decide this from the source oracle, not from the
   current implemented subset.
2. Can the FUSE comparison be made truly feature-equivalent for the Agent
   workspace lifecycle, including whiteout, symlink, cache-invalidation, and
   selected-target behavior?
3. Which environment/cache source rows actually yield a `path-view-manifest`
   with observed lookup/open/stat/access/exec/readdir operations over the
   policy prefix? Rows that do not yield this manifest should remain
   dependency evidence.
4. Is the service/config family strong enough for the paper, or should it stay
   a motivation/related-work family until a concrete source oracle exists?
5. What is the cleanest RQ3 evidence package? A convincing RQ3 result probably
   needs a table of required filesystem methods, privileged code surface,
   daemon/state ownership, invalid-policy containment, and data/write-path
   responsibility for the same policy in `namei_ext`, FUSE, and custom/stackable
   alternatives.
6. The paper conclusion currently lags the implementation docs by mentioning
   only pass-through and redirect. After root disposition and evidence updates,
   the paper should be synchronized so it does not understate or misstate the
   current mechanism boundary.

Suggested next evidence:

- Complete Experiment A full matrix through Make-owned KVM targets.
- Feature-equivalent Agent workspace FUSE row with request counts and latency.
- Agent workspace result-review report auditing correctness, FUSE fairness,
  lower-FS preservation, and boundary evidence.
- Environment/cache preflight producing `path-view-manifest.jsonl` before the
  full matrix is admitted.
- Boundary-evidence review for custom/stackable filesystems using Bento,
  Wrapfs, YoloFS, ExtFUSE, and source-system evidence without turning those into
  new main experiments.

## Final Self-Check

- I did not narrow the author's position to current prototype actions,
  preflights, or two selected transitions.
- I did not change the fixed RQs.
- I did not restore table-only, `table_redirect`, static-table insufficiency,
  or dynamic-necessity proof as novelty.
- I did not move RQ3 back to bind/Overlay/projected/copy/symlink comparisons.
- I did not treat source characterization as claim-moving evidence by itself.
- I did not promote registered targets, operation-weighted traces, Make
  routing, result reviews, or policy-state manifests into the central
  contribution. They remain mechanisms or evidence infrastructure.
- I preserved the central contribution as the `sched_ext`-style VFS
  name-resolution extension point and its policy/ownership boundary.
