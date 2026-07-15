# Idea Shrinkage Trajectory Audit

Date: 2026-07-12

## Question

The audit asks whether the current `namei_ext` idea has become too small and
less interesting, why that happened, and which repository documents or
constraints caused useful caution to become over-constraining.

## Verdict

Yes. The current paper/idea state is safer and more internally consistent, but
it has become too defensive for a strong systems paper. The repository still
contains a broad and interesting project:

> `namei_ext` is a missing middle point between static namespace construction
> and full programmable filesystems for state-dependent path views.

The current draft instead reads as:

> classify two selected upstream transitions, implement only the
> object-selection/visibility slice, and accept the boundary only if both
> transitions pass.

That is a useful artifact milestone, but it is too close to a feasibility or
workshop claim unless the paper recovers a broader workload characterization
and a stronger mechanism principle.

## Execution Trajectory

### 1. Initial idea was broad and reviewer-relevant

`docs/research_plan.md` started from a clear systems position: a
`sched_ext`-style VFS extension point where the kernel owns VFS machinery and
BPF chooses path-resolution policy. The initial use cases were broad: build/CI
sandboxes, container/serverless root views, package/development environments,
multi-tenant file views, and compatibility path redirection.

The strong original shape was:

- programmable path-resolution policy;
- kernel/lower-filesystem ownership of VFS objects and data path;
- middle ground between bind/Overlay and FUSE/custom filesystems.

### 2. Phase 1 correctly narrowed the mechanism, but it also biased the story

The implementation discipline in `AGENTS.md` is appropriate for artifact
quality: Make-owned workflows, KVM validation, fail-fast behavior, raw results,
and the real `cgroup/namei_ext` attach path. The issue is that these artifact
rules started to act as paper-scope rules. A systems artifact must be narrow,
but the paper's hypothesis should remain ambitious while evidence determines
which parts are proven.

### 3. The table-only/C8 loop created a defensive correction

The project spent many records on static/exact-map/table counterfactuals. Some
runs were useful boundary diagnostics, but several did not produce a clean
"table-only fails" result. The 2026-06-30 correction was therefore right to
say the paper should not center novelty on table impossibility.

The overcorrection was the stronger rule now repeated in canonical docs:

- do not claim selected workloads require eBPF;
- do not claim selected workloads require `namei_ext`;
- do not claim selected workloads require dynamic policy logic.

The first two are good exclusivity guards. The third is too broad: it removes
the positive workload characteristic the paper should be able to argue, namely
that many real systems exercise state-dependent path-view policy even if other
mechanisms can implement it.

### 4. Source reproduction produced strong evidence, but it was not synthesized
as a workload characterization

By 2026-07-03 the repo had strong source-backed evidence: AgentFS, BranchFS,
Sandlock, YoloFS public filesystem paths, Mirage, OpenHands SDK, SWE-agent,
SWE-ReX, SWE-rebench V2, SWE-Factory-Gym, MEnvData-SWE, DockSmith trajectory
evidence, and others.

`docs/background-related-work.md` and
`docs/tmp/2026-07-03-workload-inventory-and-reuse-decision.md` correctly
select AgentFS and SWE-Factory/MEnv as next KVM targets. But the synthesis
mostly became source-role triage and caveat accounting. It did not become a
strong paper-facing characterization such as:

> Across agent workspace and environment/cache systems, many state transitions
> change which existing object a pathname denotes or whether it is visible,
> while ordinary file data, writes, and permissions should remain with an
> existing filesystem.

That missing characterization is why the current two-transition claim feels
small.

### 5. Idea/writing refinement optimized for defensibility, not ambition

The 2026-07-09 idea stress test fixed a real circularity: the paper cannot
define the domain as lookup/readdir-expressible behavior and then claim the
selected workloads fit. The fix introduced "state-transition path views" and
an anti-cherry-picking rule based on upstream transitions and oracles.

The 2026-07-10 idea stress test then explicitly reported the main remaining
risk: two examined upstream transitions may read as workshop/feasibility scope
unless later evidence shows they represent a recurring subproblem.

The writing rounds did not repair that scale risk. They made the paper more
consistent by:

- binding the rows to AgentFS and SWE-Factory-Gym;
- requiring both selected transitions to pass for the boundary claim;
- removing W4/internal labels;
- removing table-centered language;
- turning the paper into a proposal-style draft.

Those edits are locally reasonable, but their combined effect is a smaller
paper: the central claim moved from a general programmable path-view
abstraction to a two-transition boundary check.

## Documents And Constraints That Caused Problems

## Current Skill Audit

The current skills are not the same as the ones that produced the 2026-07-10
shrunk draft.

- `auto-research-orchestrator` now explicitly says the default bias is
  "bigger is better," forbids replacing the user's target with a narrower
  proxy, requires writing skills to preserve the scientific idea, and treats
  silent narrowing as a review failure.
- `iter-refine-ideas` now asks Round 1 to recover the largest, most
  interesting, and most faithful version of the idea. It also says not to
  reduce the author's central position because a smaller idea is easier to
  defend.
- `iter-refine-writing` now says it does not handle claims, RQ meaning,
  research framing, or scope. It requires an explicit RQ set established by
  `iter-refine-ideas` and makes RQ meaning read-only.
- `iter-review-critique` now says not to recommend claim shrinkage as the
  default repair and to seek stronger mechanism, evidence, workload, baseline,
  external grounding, or a larger more principled framing.

Therefore the continuing risk is not that the current skill text necessarily
forces shrinkage. The risk is operational:

- the previous run used the older `iter-refine-writing-idea`/writing behavior;
- the repo had no `docs/user-instruction.md`, so the user's broader target was
  not pinned as an authority file;
- the mandatory outer-audit checks were not present in the flat `docs/tmp`
  record layout;
- writing refinement was allowed to make scientific-scope edits instead of
  routing them back to the idea skill.

The repair is to use the current skills' intended separation: `iter-refine-ideas`
owns the restored scientific position; writing may express it but not narrow it.
The restored position is:

> `namei_ext` is a `sched_ext`-style VFS extension point for programmable
> path-resolution policy, placed between bind/Overlay/materialization and
> FUSE/custom filesystems.

### Useful constraints that should stay

- `namei_ext` is not a BPF filesystem.
- Policies are eBPF programs, not a YAML/JSON policy language.
- One kernel-facing decision function covers lookup and directory enumeration.
- KVM is required for Phase 1 validation.
- Correctness gates precede performance interpretation.
- FUSE/source-system/materialized baselines must use the same oracle.

These rules protect the artifact and the mechanism boundary.

### Over-constraining or misleading rules

1. **"Do not claim workloads require dynamic policy logic."**

   This is too strong. The paper should avoid exclusivity claims, but it can
   still characterize real workloads as using dynamic, state-dependent
   path-view policy. Better wording:

   > Do not claim that only `namei_ext` or eBPF can implement the workload.
   > Do claim, when supported, that the workload's oracle-relevant behavior is
   > dynamic path-view policy and compare ownership/cost against natural
   > mechanisms.

2. **"Both selected transitions must pass for the boundary-validity claim."**

   This makes the paper brittle and small. A stronger structure is:

   - model/characterization claim across many source systems;
   - deep KVM case studies for two or three representative transitions;
   - per-transition positive/negative verdicts;
   - family-level claim only when enough families pass.

3. **Writing rounds changed scientific scope.**

   `iter-refine-writing` should reorganize and polish established content, but
   Round 0-9 effectively changed scientific scope from "missing middle
   abstraction" to "proposal with two selected transitions." That violates the
   orchestrator principle that writing refinement may not narrow the idea.

4. **Skill layout conflicts with repo AGENTS.md.**

   The orchestrator skill says reports should live in cycle directories and
   explicitly says not to flatten `docs/tmp`. `AGENTS.md` requires
   `docs/tmp/YYYY-MM-DD-*.md` flat records. The project followed `AGENTS.md`,
   but that means the orchestrator's outer-audit structure was never actually
   present.

5. **No `docs/user-instruction.md` authority log exists.**

   The orchestrator requires a verbatim user-instruction log and says every
   specialist node must compare against it. This repo does not currently have
   that file. As a result, the later instruction "do not keep proving table"
   was preserved, but the broader user intent "real workloads need eBPF policy
   logic / general programmable filesystem abstraction" was not protected as an
   active research objective.

## What The Paper Should Prove Instead

The paper should not prove:

- static tables are impossible;
- FUSE cannot implement the workload;
- every workload intrinsically requires eBPF;
- `namei_ext` replaces agent filesystems or environment systems.

The paper should prove:

1. **Workload characterization.**
   Real agent workspace and environment/cache systems repeatedly expose
   state transitions where the oracle-relevant filesystem effect is changing
   pathname-to-object binding or visibility, not replacing file data semantics.

2. **Mechanism sufficiency.**
   A single eBPF decision function at VFS name resolution can implement these
   path-view transitions for representative workloads through the real KVM
   attach path while preserving lower-filesystem semantics.

3. **Boundary value.**
   Under the same oracle, `namei_ext` avoids at least one ownership or update
   responsibility that natural alternatives must take: filesystem-service
   daemon ownership, filesystem-method ownership, namespace materialization
   writes, stale-window/update work, or setup/update cost.

4. **Scope discipline.**
   Out-of-model effects are reported honestly, but they do not erase the
   broader characterization unless the source-system evidence shows the path
   view slice is rare or artificial.

## Recovery Path

1. Re-expand `docs/idea-story.md` around the larger thesis:

   > State-dependent path views are a recurring filesystem subproblem between
   > static namespace construction and full programmable filesystems; `namei_ext`
   > tests whether VFS name resolution is the right policy boundary for that
   > subproblem.

2. Move defensive non-goal language out of the introduction and into a concise
   limitations/evaluation-boundary section.

3. Add a workload-characterization table over all reproduced source systems,
   not only two selected transitions. Columns should be source system, state
   transition, oracle, path-view effect, out-of-model effect, and natural
   baseline.

4. Keep AgentFS and SWE-Factory/MEnv as first deep KVM workloads, but treat
   them as representatives of a broader characterized class. Add a third
   service/config or another agent-workspace transition if the paper targets
   OSDI/SOSP rather than workshop scope.

5. Update `research/STATE.md`, `research/CLAIM_LEDGER.md`, and
   `docs/idea-story.md` to replace the overbroad "do not claim dynamic policy
   logic" rule with the narrower "do not claim exclusive necessity" rule.

6. Resolve the report-layout conflict explicitly: either keep the flat
   `docs/tmp/YYYY-MM-DD-*.md` rule as the repo-local override, or add a
   top-level note that the orchestrator's cycle-directory layout does not
   apply in this repository.

## Bottom Line

The idea did become smaller, but the repo has enough evidence to recover it.
The main mistake was not dropping the table-only argument. Dropping that was
right. The mistake was allowing "do not prove table-only failure" to become
"do not claim dynamic path-view policy is a meaningful workload property," and
then letting writing-review gates turn a broad mechanism paper into a
two-transition proposal.
