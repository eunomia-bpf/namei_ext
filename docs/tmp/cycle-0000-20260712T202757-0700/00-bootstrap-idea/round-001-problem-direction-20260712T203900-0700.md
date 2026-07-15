# Round 1 Problem And Research Direction

Timestamp: 2026-07-12T20:39:00-0700

Parent run path: `docs/tmp/cycle-0000-20260712T202757-0700/00-bootstrap-idea/`

Role: Round 1 read-only research discussant for BOOTSTRAP idea discussion.

Method: I read the requested input snapshot directly from the repository and did not inspect later round reports in the parent run directory. I did not edit paper, canonical docs, code, or skills. This report is a proposal memo for root disposition, not an applied paper edit.

## Entry Snapshot

Exact file list read:

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
- `docs/paper/main.tex`
- `docs/paper/refs.bib`
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

## Understanding Of The Current Idea

The current idea is not "BPF for filesystems" and not "a faster FUSE." It is a narrower systems boundary: `namei_ext` places verified, bounded policy at VFS name resolution, while the kernel and lower filesystem keep ownership of path walking, dentries, inodes, permissions, file operations, page cache, writes, persistence, and consistency.

The strongest current phrasing is the `sched_ext` analogy. As `sched_ext` lets BPF choose scheduling policy while the kernel retains scheduler machinery, `namei_ext` lets eBPF choose a path-view decision while the VFS and lower filesystem retain filesystem machinery. The mechanism position is fixed as:

```text
bind/Overlay/materialization < eBPF LSM < namei_ext < FUSE/custom FS
```

The paper's fixed RQs are also clear:

- RQ1: expressiveness/sufficiency for real state-dependent path-view policies without taking over filesystem semantics.
- RQ2: cost/overhead compared with a feature-equivalent FUSE policy.
- RQ3: safety and implementation boundary compared with custom or stackable filesystems when the needed policy is only name resolution.

The current story has recovered from the shrunken table-only path. The paper now treats source-system characterization as workload and oracle selection, and it reserves claim-moving evidence for complete, Make-owned, KVM-validated, same-oracle experiments. That is the right discipline. The risk is that the restored story may still undersell the consequence: it says "missing middle" and "state-dependent path views," but it could more forcefully explain why this is a new operating-system boundary problem rather than an implementation convenience.

## What The Largest Faithful Problem Is

The largest faithful problem is:

> Modern task-specific systems increasingly depend on changing the object identity behind stable pathnames as workload state changes, but the available mechanisms force that state-dependent path policy either into pre-materialized namespace construction, access-control hooks, or broader filesystem ownership. The missing boundary is a verified, per-workload policy point in VFS name resolution that can change pathname-to-object selection and visibility while preserving ordinary filesystem semantics.

This is larger than "agent workspaces need dynamic paths" and larger than "FUSE has overhead." It says the filesystem interface has a boundary mismatch: many systems need a programmable object-selection plane, not a new filesystem service. Agent workspaces, build/test environment caches, and service/config rotations are instances because each has a state variable that changes which lower object a stable pathname should denote.

The key consequence should be correctness before performance. A stale cache object, wrong branch object, hidden side-effect leak, or wrong secret/config object is a path-binding failure. The user explicitly rejected returning to a static-table necessity proof, so the problem should not be "tables cannot express it." The problem is that existing mechanism families put this policy in the wrong ownership boundary for workloads whose oracle-relevant behavior is only name resolution.

## Unexpected Direction 1: State-Epoch Path Views

One larger framing is to organize the problem around state epochs rather than around filesystem mechanisms. In the current sources, the repeated pattern is not merely "dynamic policy"; it is that a workload has an epoch:

- branch, fork, checkpoint, COW, whiteout, or cache-invalidation epoch for an agent workspace;
- verified-local, canonical, stale, corrupt, or update epoch for environment/cache systems;
- secret, certificate, config, or fixture epoch for service/config systems.

The path-view policy maps:

```text
stable logical pathname + workload epoch -> selected lower object or absence
```

This keeps the current RQs intact but makes the paper's problem more concrete. It also avoids the rejected "prove static table insufficiency" route. A table can store state; that is not the point. The point is that epoch transitions must be reflected at ordinary lookup and directory-enumeration operations without forcing the workload to rebuild a namespace tree or delegate the whole filesystem boundary to a service.

Evidence needed: operation-weighted traces around epoch changes, not just before/after final states. For AgentFS-derived workspace lifecycle, the trace should show lookup/readdir behavior changing across branch/COW/whiteout/cache epochs. For environment/cache, the path-view manifest should prove hit/miss/stale/corrupt/epoch-update objects are selected or hidden during real source evaluator operations. For service/config, the source oracle must show a service-visible difference caused by selecting the wrong config/secret object at the path, not merely by application reload logic.

Target locations if accepted by root: `docs/idea-story.md` could add "state epoch" as explanatory language under the core insight, and `docs/paper/sections/01-introduction.tex` / `docs/paper/sections/02-motivation.tex` could use epoch examples to sharpen the problem. This should not become a new named framework or central contribution; it is an explanatory lens.

## Unexpected Direction 2: Boundary Safety As The Main Payoff

Another larger framing is that the paper is not primarily about avoiding FUSE cost. RQ2 must compare FUSE, but the bigger systems idea is boundary safety: if the needed behavior is only name resolution, a full filesystem boundary asks developers to own too much privileged or failure-sensitive machinery.

In this framing, performance is necessary but not sufficient. A feature-equivalent FUSE policy could match or even beat some overheads and the paper might still have a strong RQ3 result if `namei_ext` demonstrably avoids a daemon availability dependency, avoids filesystem method ownership, contains invalid policy decisions through verifier/kernel validation, and preserves lower-FS data/write semantics.

This direction is faithful to the current design docs and to the user's fixed RQ3. It also makes the custom/stackable filesystem comparison more than a table of "methods owned." The question becomes: what responsibilities must move into the policy author's trusted boundary for the same oracle? `namei_ext` should win only when the workload's needed behavior is path selection/visibility and the evidence shows broader filesystem ownership is unnecessary.

Evidence needed: for each complete experiment, an RQ3 boundary audit tied to the same oracle. It should account for required filesystem methods, privileged code surface, daemon/process state, invalid-policy containment, lower-FS semantic preservation, and what a custom/stackable alternative would have to own for the same policy. Bento, ExtFUSE, Wrapfs, YoloFS, AgentFS, BranchFS, Mirage, and FUSE docs are useful boundary anchors, but the comparison must stay connected to the admitted workload oracle.

Target locations if accepted by root: `docs/paper/sections/05-evaluation.tex` can make RQ3 read as a first-class safety argument rather than a secondary ownership table, and `docs/evaluation.md` can require a same-oracle RQ3 boundary audit as part of result review.

## Unexpected Direction 3: Source Systems As Specifications, Not Baselines

The current docs already say source reproductions are not paper results by themselves. The larger version is to treat source systems as partial specifications of path-view behavior. AgentFS, BranchFS, Sandlock, YoloFS, Mirage, OpenHands, SWE-agent/SWE-ReX, SWE-Factory-Gym, MEnvData-SWE, SWE-rebench V2, Kubernetes projected volumes, and service/config sources should not be lined up as baselines. They define or constrain the behaviors a path-view boundary must be able to preserve or explicitly reject.

This direction protects the paper from baseline sprawl. It also makes the characterization contribution more consequential without making it claim-moving evidence for RQ1/RQ2/RQ3. The characterization can establish that the problem exists and choose representative oracles; only the complete KVM/FUSE/boundary experiments answer the RQs.

Evidence needed: a source-derived transition matrix whose rows distinguish source oracle, path-view effect, non-name-resolution responsibility, and mechanism boundary. The current paper has grouped and per-system tables; the next evidence step is to attach each admitted experiment to a specific source-derived oracle and path-view manifest so reviewers can see the source is acting as a specification, not an anecdote.

## A Strictly Larger Version Of The Current Story

Strictly larger proposed story:

> `namei_ext` is a verified VFS state-epoch path-view extension point. It tests whether modern workload-local filesystem views can be expressed as pathname-to-object and visibility policy at VFS name resolution, preserving lower-filesystem semantics while avoiding both namespace materialization and filesystem-service ownership. The paper demonstrates this through a source-derived characterization and complete same-oracle experiments across agent workspace, environment/cache, and, if a real oracle is found, service/config state epochs; it compares cost against feature-equivalent FUSE and boundary safety against custom or stackable filesystem ownership.

This is larger than the current story in three ways:

- It makes state change and stable path identity the central consequence, rather than presenting the mechanism sequence as the main intellectual object.
- It raises RQ3 from a boundary checklist to a systems safety argument.
- It treats service/config not as optional breadth filler but as the strongest route to proving the abstraction is not agent- or build-specific, while still requiring admission by a real lookup-time oracle.

Evidence this larger story would need:

- A source characterization that identifies state epochs and path-view effects across all source families without claiming exclusive necessity for `namei_ext`.
- Experiment A: full AgentFS-derived workspace lifecycle in KVM through `cgroup/namei_ext`, full feature-equivalent FUSE comparison, no-hook/control rows, invalid-policy containment, lower-FS semantic checks, operation-weighted lookup/readdir traces, and a result review.
- Experiment B: environment/cache suite with a pre-registered path-view manifest, hit/miss/stale/corrupt/epoch-update states, unchanged source evaluator, same-oracle FUSE, native/source control, invalid-policy controls, and result review.
- Experiment C only if admitted: a service/config source oracle where lookup-time selection changes service-visible correctness. If no such oracle exists, the paper should state that service/config remains characterization and related-work motivation, not force a weak experiment.
- RQ3 boundary evidence per admitted experiment: methods owned, privileged code surface, daemon/process dependency, state ownership, invalid-policy containment, and preservation of lower-FS data/write semantics.

This is genuinely stronger if those evidence items can be produced. Without them, the current version is the more honest paper draft because it avoids claiming results that do not exist. The larger story should therefore be accepted as the target direction, not as current empirical fact.

## Comparison With Earlier And Current Narratives

The original broad narrative did better at ambition. It saw `namei_ext` as a clear systems abstraction: programmable path-resolution policy, kernel ownership of VFS machinery, and a middle ground between materialized namespaces and FUSE/custom filesystems. It also named a broad set of relevant use cases rather than letting the paper collapse into two transitions or a diagnostic table.

The shrunken July 10 style did one thing well: it prevented overclaiming. It caught the danger of saying workloads require eBPF or that static/materialized alternatives are impossible. But it overcorrected. It let the absence of a clean table-only failure turn into reluctance to claim that state-dependent path-view policy is a real workload property.

The current version improved substantially. It restored the `sched_ext`-style VFS extension-point story, fixed the mechanism ordering, made RQ2 explicitly compare feature-equivalent FUSE, moved RQ3 to custom/stackable filesystem safety and boundary, demoted materialization mechanisms to background/related work, and defined complete integrated experiments rather than scattered smoke checks. It also correctly treats the current KVM preflight as dependency evidence, not a paper result.

What the current version still risks losing is narrative force. The abstract and introduction say "missing middle," but the strongest reader-facing problem should be "state changes make stable pathnames correctness-critical, and current mechanism boundaries put that policy either too early, too late, or too broadly." That is more interesting than a mechanism taxonomy alone. The proposal above is stronger if it keeps the current RQs and experiment discipline while making this consequence explicit.

## Conflicts Checked Against Exact User Instructions

I checked the proposals against the authoritative prompt log, especially these exact constraints:

- "不要再把 table-only / table_redirect / '证明 workload 不能用静态 table'作为主线 novelty 或实验目标."
- "claim-moving evidence 必须来自 Make-owned、KVM-validated、same-oracle 的完整 workload experiments."
- "RQ2 要对比 FUSE."
- "RQ3 应该考虑是否对比 custom filesystem / FUSE / stackable filesystem 这类 broader FS boundary 的安全性或实现边界."
- "`namei_ext` 是一个 sched_ext-style VFS extension point，位于 bind/Overlay/materialization < eBPF LSM < `namei_ext` < FUSE/custom FS 之间."
- "论文也不应该放负面结果，故事越吸引人越好."
- "除非这个 hypothesis 本身完全不可能成立，不然不应该改变我们的 hypothesis."

No proposal here returns to table-only, `table_redirect`, static-table impossibility, W1-W4 style row accounting, weak baselines, or materialized-view shootouts. The proposed larger story keeps the three fixed RQs. It does not replace RQ2's FUSE comparison or RQ3's custom/stackable boundary question. It does not claim that only `namei_ext` or only eBPF can implement the workloads.

The one tension is source characterization. The paper can use source characterization as a contribution and motivation, but the user instruction says source-system characterization is for selecting real workloads and oracles, not claim-moving evidence itself. The safe resolution is: characterization establishes the problem landscape and experiment selection; only complete KVM same-oracle experiments answer expressiveness, cost, and boundary claims.

## Remaining Questions

1. What is the exact AgentFS-derived lifecycle that should become Experiment A's fixed oracle? The plan lists COW, whiteout, symlink, cache invalidation, final tree, and host non-materialization; the root needs one admitted lifecycle that maps to implemented or explicitly planned bounded actions.
2. Does Experiment A require synthetic parent-directory aliases or final-file target selection, or can the admitted source oracle be satisfied with directory selection plus ordinary lower-FS behavior? This should be decided from the source oracle, not from the current prototype subset.
3. Which environment/cache rows can produce a real `path-view-manifest.jsonl` showing opened/stated/executed/enumerated paths under hit/miss/stale/corrupt/epoch states? Rows that only prove Docker evaluator reproducibility should remain dependency evidence.
4. Can the feature-equivalent FUSE policies for Experiments A and B be made fair without accidentally implementing a broader system than `namei_ext`? If FUSE gets a weaker state machine or weaker oracle, RQ2 is invalid.
5. Is there a concrete service/config source oracle where lookup-time object selection changes service-visible correctness? If not, service/config should remain characterization and related work until a real oracle is found.
6. What is the minimal but convincing RQ3 evidence for custom/stackable filesystems without building a full custom filesystem? The paper needs a boundary audit strong enough that reviewers do not read RQ3 as hand-waving.

## Suggested Next Evidence

- Freeze an AgentFS-derived oracle document before implementation changes continue. It should list state epochs, logical paths, expected lower object, expected visibility, non-name-resolution responsibilities, and lower-FS checks.
- Build the Experiment A full matrix only after that oracle is fixed: `namei_ext`, feature-equivalent FUSE, no-hook/control, invalid-policy containment, operation-weighted traces, raw artifacts, and result review.
- Preflight the environment/cache path-view manifest before building the full suite. The manifest should prove the source evaluator actually observes the policy-controlled paths.
- Search for one service/config oracle with a service-visible path-selection failure. If none is found quickly, do not force the third experiment; keep it as a future/conditional breadth claim.
- For RQ3, prepare a per-experiment boundary artifact that compares `namei_ext`, FUSE, and custom/stackable ownership for the same policy, including methods owned, privileged surface, daemon/state dependency, and invalid-policy containment.

## Final Self-Check

- I did not narrow the author's position; the main proposal is strictly larger than the current story.
- I did not change the fixed RQs.
- I did not restore table-only, `table_redirect`, static-table impossibility, W1-W4, or dynamic-necessity proof as the main line.
- I did not promote source characterization, path-view manifests, epoch language, FUSE, or RQ3 boundary audits into the central contribution. They remain explanation, evidence routing, or comparison mechanisms around the central `sched_ext`-style VFS name-resolution extension point.
- I preserved the mechanism order: bind/Overlay/materialization < eBPF LSM < `namei_ext` < FUSE/custom FS.
- I preserved the requirement that claim-moving evidence come from complete, Make-owned, KVM-validated, same-oracle experiments with FUSE comparison for RQ2 and custom/stackable boundary evidence for RQ3.
