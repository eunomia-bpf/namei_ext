# Idea And Hypothesis History

Last updated: 2026-07-15
Current phase: BUILD_AND_EVALUATE
Current step root: `docs/tmp/bootstrap/step-0005-20260714T174151-0700/`

## Current Frontier

BOOTSTRAP step 0005 is the current accepted frontier. The latest user
instruction asked the project to return to BOOTSTRAP under the new skills and
reorganize/improve the paper again. Step 0005 completed a full
`iter-refine-writing` pass, restored meaning lost during compression, verified
citations and the paper build, passed independent outer audit, and routed the
project back to BUILD_AND_EVALUATE.

The frozen story is unchanged from the user's fixed direction:
`namei_ext` is a `sched_ext`-style VFS name-resolution extension point between
eBPF LSM and FUSE/custom filesystem ownership. The contribution is the design
and Linux implementation of that extension point as one systems boundary. Agent
workspace and environment/cache remain the primary workload families;
service/config remains conditional; incomplete prototype evidence must not
shrink the paper's hypothesis.

The previous completed re-entry and route are recorded in:
`docs/tmp/bootstrap/step-0002-20260713T004618-0700/step-report.md`.

The accepted BOOTSTRAP re-entry, writing pass, and review route are recorded in
`docs/tmp/bootstrap/step-0005-20260714T174151-0700/step-report.md`.

## Initial Narrative

Modern systems increasingly need per-workload filesystem views without wanting
to implement a filesystem. Build systems, agent workspaces, service sandboxes,
and environment/cache systems repeatedly change which existing object a
pathname should denote, or whether that object should be visible, while leaving
ordinary file data, writes, permissions, page-cache behavior, persistence, and
consistency to an existing lower filesystem.

The existing design space has a missing middle. Bind mounts, OverlayFS,
projected volumes, symlink forests, copies, and other materialized views
preserve kernel filesystem semantics, but encode the view by constructing,
layering, or updating namespace state outside each lookup. eBPF LSM can attach
verified policy to security hooks, but its natural role is access-control
mediation rather than changing which existing object a pathname denotes during
VFS name resolution. FUSE and source-system agent filesystems are expressive,
but place a filesystem service on the path and often own operation handling,
caching, daemon availability, and correctness details. Custom or stackable
filesystems can be expressive and fast, but ask the developer to own a broader
filesystem interface.

`namei_ext` tests a different point between eBPF LSM and filesystem ownership:
put a constrained eBPF policy at VFS name resolution, analogous to how
`sched_ext` lets policy choose scheduling while the kernel retains scheduler
machinery. The policy chooses bounded lookup and directory-enumeration actions;
the kernel and lower filesystem continue to own VFS objects and ordinary file
semantics.

The central principle is:

```text
state-dependent pathname policy belongs at VFS name resolution;
filesystem objects and data semantics remain with the kernel and lower FS.
```

The intended contribution is the design and implementation of this narrow
extension point plus a source-grounded evaluation showing where it is expressive
enough, what it costs compared with feature-equivalent FUSE, and how its
implementation boundary differs from custom or stackable filesystem ownership.

## Current Research Questions

| RQ | Question | Evidence standard |
| --- | --- | --- |
| RQ1 Expressiveness / sufficiency | Can a narrow VFS name-resolution extension express real state-dependent path-view policies without taking over filesystem semantics? | Representative source-derived workloads pass their correctness oracles through the real `cgroup/namei_ext` KVM attach path, with coherent lookup/readdir behavior and lower-filesystem permission/write/data-path preservation. |
| RQ2 Cost / overhead versus FUSE | What is the cost of putting programmable policy on the VFS name-resolution path compared with a feature-equivalent FUSE policy implementation? | Same-oracle `namei_ext` and FUSE policy implementations, with correctness gating lookup/open/stat/access/exec/readdir latency, macro runtime, pass-through overhead, action overhead, and operation-weighted invocation traces. |
| RQ3 Safety / boundary versus custom or stackable FS | Does `namei_ext` provide a narrower verifier-bounded, fail-closed ownership boundary than building a custom or stackable filesystem when the needed policy is only name resolution? | Ownership and containment evidence: filesystem methods owned, privileged code surface, daemon/state responsibility, verifier/kernel validation, invalid-policy handling, and lower-filesystem data/write preservation. |

## Contribution And Evidence Program Under BOOTSTRAP Pressure

Primary contribution: the design and implementation of `namei_ext`, a
`sched_ext`-style VFS name-resolution extension point whose eBPF policy selects
bounded lookup and directory-enumeration behavior while the kernel and lower
filesystem retain VFS object and data-path ownership.

Evidence program:

1. Source-derived characterization of state-dependent path views in
   agent/workspace, environment/cache, and service/config systems is workload
   and oracle selection evidence, not a standalone contribution.
2. A small set of complete, same-oracle experiments is organized around RQ1,
   RQ2, and RQ3. FUSE is the central RQ2 comparison. Custom or stackable
   filesystem ownership is the central RQ3 boundary comparison. Materialized
   namespace mechanisms are related-work/background unless a renewed BOOTSTRAP
   decision gives them a specific source-driven role.

## Hypothesis Frontier

| ID | Parent | Prediction | Falsifier | Evidence for/against | Status | Decisive next test | Reopen condition |
| --- | --- | --- | --- | --- | --- | --- | --- |
| H1 | root | A bounded VFS name-resolution policy can cover representative source-derived path-view transitions while lower FS semantics remain owned below. | The strongest source-derived agent workspace or environment/cache oracle requires synthetic contents, data-path mediation, write conflict resolution, or custom metadata persistence in the main path. | Current source surveys and prototype actions suggest plausible coverage; final same-oracle KVM evidence is missing. | Frozen for BUILD_AND_EVALUATE | Run Agent workspace lifecycle through same-oracle KVM/FUSE/RQ3 review. | If final admitted oracles show name resolution is not the right boundary. |
| H2 | H1 | FUSE is the right cost comparison because it can implement equivalent policy but owns a filesystem daemon/request path. | A fair FUSE implementation cannot be made feature-equivalent for the admitted oracle, or another mechanism is a stronger direct cost opponent. | User fixed RQ2 to FUSE; FUSE literature and source systems support the comparison. | Frozen for BUILD_AND_EVALUATE | Run feature-equivalent FUSE rows for the admitted oracle before interpreting RQ2. | If a final admitted workload oracle makes FUSE non-comparable. |
| H3 | H1 | Custom/stackable filesystems are the right safety/boundary comparison because they own broader filesystem methods than the policy requires. | The admitted workload requires broad filesystem ownership, making `namei_ext` the wrong abstraction. | Prior stackable/custom FS work supports the boundary distinction; workload-specific audit still needed. | Frozen for BUILD_AND_EVALUATE | Produce same-oracle RQ3 ownership and containment evidence after RQ1 correctness. | If the selected source behavior is not name-resolution policy. |
| H4 | root | The paper is strongest with two deep workload families plus conditional service/config breadth, not a large catalog of weak comparisons. | Reviewers would reject coverage as too narrow even with deep same-oracle evidence, or service/config produces a strong lookup-time oracle. | User repeatedly rejected scattered weak baselines and table-only mainline. | Frozen for BUILD_AND_EVALUATE | Start with Agent workspace; keep environment/cache primary after required target-selection support. | If final review finds the two-family plan insufficient. |

## Claim Evolution

| Date | Ambitious target claim | Evidence status | Unresolved uncertainty | Next evidence program |
| --- | --- | --- | --- | --- |
| 2026-07-12 | `namei_ext` is a missing-middle VFS name-resolution policy boundary between eBPF LSM and FUSE/custom FS. | Literature/source grounding and prototype feasibility only; not final RQ evidence. | Whether the planned workload oracles and comparisons are strong enough for OSDI/SOSP. | BOOTSTRAP re-entry under the new skill, followed by renewed idea/literature/write/review gates before freeze. |
| 2026-07-13 | `namei_ext` is a `sched_ext`-style VFS name-resolution extension point with RQ1 expressiveness, RQ2 feature-equivalent FUSE cost, and RQ3 custom/stackable FS boundary. | Renewed BOOTSTRAP EXPERIMENT, WRITE, and REVIEW gates passed; final RQ evidence is still pending. | Whether final same-oracle KVM matrices support the frozen claims. | BUILD_AND_EVALUATE starts with the complete Agent workspace matrix. |
| 2026-07-13 | Same `sched_ext`-style VFS name-resolution story, but demoted from frozen contract to BOOTSTRAP candidate. | Latest user instruction explicitly re-entered BOOTSTRAP; BUILD_AND_EVALUATE Loop 001 result was supporting-only and Loop 002 remained incomplete. | Whether the candidate story should be strengthened, expanded, or frozen again under the new skill hierarchy. | BOOTSTRAP step 0002 pressures idea, literature, workload coverage, baseline families, and evaluation promise before any renewed BUILD_AND_EVALUATE route. |
| 2026-07-13 | BOOTSTRAP candidate -> WRITE_GATE candidate | Step 0002 EXPERIMENT_GATE found no same-claim blocker, fixed RQ3 boundary schema, promoted the Experiment B candidate suite, and separated baselines from oracles/controls/boundary evidence. | Whether the paper draft expresses this contract without shrinking or overclaiming. | WRITE_GATE pressure on abstract, introduction, contribution framing, evaluation section, related work, and evidence boundaries. |
| 2026-07-14 | WRITE_GATE candidate -> REVIEW_GATE candidate | A full `iter-refine-writing` pass rewrote the paper around the accepted contract and fixed evidence-boundary drift, especially RQ3 ownership wording and environment/cache final-file target gating. | Whether the step-level review accepts the writing gate and freezes the contract for renewed BUILD_AND_EVALUATE. | REVIEW_GATE independent outer audit and meta-review. |
| 2026-07-14 | REVIEW_GATE candidate -> renewed BUILD_AND_EVALUATE freeze | Independent outer audit returned pass-with-fixes; root applied the must-fixes and verified compile/citation/grep checks. | Whether final same-oracle KVM matrices support the frozen claims. | BUILD_AND_EVALUATE starts with the complete Agent workspace lifecycle experiment; environment/cache remains primary after final-file target support. |
| 2026-07-14 | renewed BUILD_AND_EVALUATE freeze -> active BOOTSTRAP re-entry | User again instructed the project to return to BOOTSTRAP and reorganize/improve the paper under the new skills. | Whether the current paper and canonical documents still express the strongest user-fixed story without premature BUILD_AND_EVALUATE routing. | BOOTSTRAP step 0003 audits and cleans the paper/canonical frontier before any experiment continuation. |
| 2026-07-14 | active BOOTSTRAP re-entry -> renewed BUILD_AND_EVALUATE freeze | Step 0003 cleanup and independent review found no blocking story or RQ defect after the root fixed stale routing text. | Whether final same-oracle KVM matrices support the frozen claims. | Resume BUILD_AND_EVALUATE with the complete Agent workspace lifecycle experiment. |
| 2026-07-14 | renewed BUILD_AND_EVALUATE freeze -> active BOOTSTRAP re-entry | The user repeated the instruction to return to BOOTSTRAP and reorganize/improve the paper under the new skills. | Whether the step-0003 freeze was premature relative to the renewed instruction and whether the paper/canonical docs still contain phase drift or evidence-promise ambiguity. | BOOTSTRAP step 0004 re-audits the paper/frontier and records cleanup before a new freeze decision. |
| 2026-07-14 | active BOOTSTRAP re-entry -> renewed BUILD_AND_EVALUATE freeze | Step 0004 completed full writing, explicit RQ result slots, fresh outer audit, citation/build verification, and canonical cleanup with no must-fix findings. | Whether final same-oracle KVM matrices support the frozen claims. | BUILD_AND_EVALUATE starts with the complete Agent workspace lifecycle experiment, then environment/cache after final-file target support. |
| 2026-07-15 | renewed BUILD_AND_EVALUATE freeze -> active BOOTSTRAP REVIEW_GATE | The user explicitly asked again to return to BOOTSTRAP under the new skills and reorganize/improve the paper. Step 0005 completed the full writing pass, citation gate, meaning-preservation audit, and build verification without changing RQ meanings. | Whether the step-level REVIEW_GATE accepts the unchanged strong story and routes back to BUILD_AND_EVALUATE. | Outer audit and meta-review decide whether to freeze again or re-enter WRITE/EXPERIMENT. |
| 2026-07-15 | active BOOTSTRAP REVIEW_GATE -> renewed BUILD_AND_EVALUATE freeze | Independent outer audit found no blocking direction defect, accepted the restored paper/frontier, and recommended routing to BUILD_AND_EVALUATE. | Whether final same-oracle KVM matrices support the frozen claims. | BUILD_AND_EVALUATE starts with the complete Agent workspace lifecycle experiment, then environment/cache after target-selection/source-oracle admission. |

## Rejected Or Dormant Paths

| Path | Why rejected/dormant | Raw evidence | Revisit trigger |
| --- | --- | --- | --- |
| Table-only or `table_redirect.bpf.c` as main novelty | User explicitly retired this line; proving static-table insufficiency no longer answers the intended paper. | Prior June diagnostics and current user log. | Only if the user explicitly reopens it as a separate paper question. |
| Many weak baselines and scattered smoke tests | User requested few complete OSDI/SOSP-grade integrated experiments. | `docs/user-instruction.md` and prior drift audit. | If BOOTSTRAP review finds a specific additional baseline changes an RQ answer. |
| Materialized namespace shootout as RQ3 | User fixed RQ3 toward custom/FUSE/stackable boundary and citation-based positioning for bind/Overlay/projected/copy/symlink. | Current user log and prior related-work survey. | If a selected source oracle makes a materialized mechanism the natural direct opponent. |
| Negative-result story in the paper | User requested a more attractive positive story and warned against changing the hypothesis around flawed experiment design. | Current user log. | If a valid final result contradicts a frozen claim and must be scoped honestly. |

## Narrative Evolution

| Date | Before -> after | Reason and decisive evidence/instruction | Root disposition | Initial vs previous vs chosen comparison | Idea-audit report | Revisit condition |
| --- | --- | --- | --- | --- | --- | --- |
| 2026-07-12 | Narrow/table-oriented story -> `sched_ext`-style VFS name-resolution extension point | User rejected table-only mainline and fixed the mechanism ladder and RQ shape. | Accepted as the candidate story for cycle-0 BOOTSTRAP. | Chosen story is stronger than the table-oriented version because it targets a systems boundary, not one diagnostic mechanism. | `docs/tmp/cycle-0000-20260712T202757-0700/00-bootstrap-idea/500-root-disposition-20260712T205136-0700.md` | Reopen if closest work collapses the boundary or source oracles require broader FS ownership. |
| 2026-07-12 | BOOTSTRAP candidate -> frozen BUILD_AND_EVALUATE contract | Cycle-0 review accepted the story under the older report layout. | Accepted then, now historical. | It was faithful to then-current instructions but preceded the current explicit BOOTSTRAP re-entry instruction. | `docs/tmp/cycle-0000-20260712T202757-0700/step-report.md` | Superseded by current user instruction. |
| 2026-07-13 | BUILD_AND_EVALUATE freeze -> active BOOTSTRAP re-entry | User explicitly asked to return to BOOTSTRAP under the new skills. | Accepted as a phase/routing change; scientific story remains candidate, not frozen. | Chosen state is more faithful to the new skill because BOOTSTRAP may still pressure story, RQs, workload coverage, and evidence promise before freeze. | `docs/tmp/bootstrap/step-0001-20260712T223808-0700/000-recovery-bootstrap-reentry-20260712T223808-0700.md` | Exit BOOTSTRAP only after the new hierarchy's EXPERIMENT, WRITE, and REVIEW gates accept a freeze. |
| 2026-07-13 | active BOOTSTRAP re-entry -> renewed BUILD_AND_EVALUATE freeze | Current EXPERIMENT, WRITE, REVIEW, meta-review, and independent audit accepted the story with no must-fix before freeze. | Accepted; freeze the scientific contract and route to BUILD_AND_EVALUATE. | Chosen state is stronger and more faithful than the re-entry candidate because it was pressured against user intent, closest-work/baseline obligations, and full writing review under the new hierarchy. | `docs/tmp/bootstrap/step-0001-20260712T223808-0700/step-report.md` | Reopen only if final admitted evidence requires changing the problem, claim, RQs, baseline families, workload coverage, or evaluation promise; otherwise iterate implementation and protocol details. |
| 2026-07-13 | renewed BUILD_AND_EVALUATE freeze -> active BOOTSTRAP candidate | User again instructed the project to return to BOOTSTRAP under the new skills. | Accepted as a routing and contract-status change; no scientific claim is rejected yet. | Chosen state is more faithful than continuing Loop 002 because the latest instruction asks to re-pressure the story before implementation/evaluation continuation. | `docs/tmp/bootstrap/step-0002-20260713T004618-0700/000-recovery-bootstrap-reentry-20260713T004618-0700.md` | Exit BOOTSTRAP only after step 0002 completes EXPERIMENT, WRITE, and REVIEW gates and records a renewed freeze. |
| 2026-07-13 | active BOOTSTRAP candidate -> WRITE_GATE candidate | Step 0002 EXPERIMENT_GATE passed after literature pressure, independent audit, and canonical fixes. | Accepted as a gate transition, not as a freeze. | Chosen state is stronger than the raw re-entry candidate because it now names FUSE-BPF/ExtFUSE pressure, RQ3 comparator schema, Experiment B suite, and evidence-role separation. | `docs/tmp/bootstrap/step-0002-20260713T004618-0700/01-experiment-gate/999-gate-report-20260713T012400-0700.md` | Continue WRITE_GATE; freeze only after WRITE and REVIEW gates pass. |
| 2026-07-14 | WRITE_GATE candidate -> REVIEW_GATE candidate | Step 0002 WRITE_GATE completed all 12 writing rounds, citation verification, compile verification, and meaning-preservation audit. | Accepted as a gate transition, not as a freeze. | Chosen state is stronger than the previous candidate because the reader-facing paper now states the contribution as design plus implementation, organizes evaluation by the fixed RQs, removes the table-only novelty drift, and carries the final-file target qualifier for environment/cache evidence. | `docs/tmp/bootstrap/step-0002-20260713T004618-0700/02-write-gate/iter-refine-writing-20260714T143346-0700/2026-07-14-round-11-meaning-preservation.md` | Freeze only after REVIEW_GATE accepts the step direction and routing. |
| 2026-07-14 | REVIEW_GATE candidate -> renewed BUILD_AND_EVALUATE freeze | Step 0002 outer audit accepted the direction after two must-fixes; root applied both fixes and verified the paper. | Accepted; freeze the scientific contract and route to BUILD_AND_EVALUATE. | Chosen state is stronger and more faithful than the re-entry candidate because it preserves the ambitious VFS extension-point story, keeps contribution as design plus implementation, and now gives the next phase a small complete experiment program instead of scattered baselines. | `docs/tmp/bootstrap/step-0002-20260713T004618-0700/outer-audit-20260714T154246-0700.md` | Reopen only if final admitted evidence requires changing the problem, claim, RQs, baseline families, workload coverage, or evaluation promise; otherwise iterate implementation and protocol details. |
| 2026-07-14 | renewed BUILD_AND_EVALUATE freeze -> active BOOTSTRAP re-entry | User's latest instruction explicitly says to return to BOOTSTRAP and reorganize/improve the paper. | Accepted as a phase/routing change; no scientific claim is rejected. | Chosen state is more faithful than continuing Experiment A protocol repair because the latest request is about paper/story convergence under the new skill hierarchy. | `docs/tmp/bootstrap/step-0003-20260714T155854-0700/step-report.md` | Exit BOOTSTRAP only after step 0003 records paper verification and review disposition. |
| 2026-07-14 | active BOOTSTRAP re-entry -> renewed BUILD_AND_EVALUATE freeze | Step 0003 compiled the paper, fixed stale routing wording, and passed independent BOOTSTRAP review with no blocking must-fix findings. | Accepted; freeze the scientific contract and route back to BUILD_AND_EVALUATE. | Chosen state is stronger than the active re-entry because it preserves the step-0002 paper story while removing route drift and merging the contribution as design plus implementation. | `docs/tmp/bootstrap/step-0003-20260714T155854-0700/outer-audit-20260714T160549-0700.md` | Reopen only if final admitted evidence requires changing the problem, claim, RQs, baseline families, workload coverage, or evaluation promise; otherwise iterate implementation and protocol details. |
| 2026-07-14 | renewed BUILD_AND_EVALUATE freeze -> active BOOTSTRAP re-entry | The latest prompt repeats the BOOTSTRAP/paper-reorganization request after step 0003. | Accepted as a phase/routing change; no scientific claim is rejected. | Chosen state is more faithful than silently continuing BUILD_AND_EVALUATE because the user asked for paper convergence under the new skill hierarchy. | `docs/tmp/bootstrap/step-0004-20260714T161834-0700/step-report.md` | Exit only after step 0004 records verification and review disposition. |
| 2026-07-14 | active BOOTSTRAP re-entry -> renewed BUILD_AND_EVALUATE freeze | Step 0004 addressed the initial audit must-fixes, completed all 12 writing rounds, verified citations/build, condensed state, and passed fresh independent audit. | Accepted; freeze the scientific contract and route back to BUILD_AND_EVALUATE. | Chosen state is stronger than the re-entry candidate because the paper now has explicit RQ result slots and the canonical docs no longer carry phase ambiguity. | `docs/tmp/bootstrap/step-0004-20260714T161834-0700/outer-audit-20260714T162658-0700.md` | Reopen only if final admitted evidence requires changing the problem, claim, RQs, baseline families, workload coverage, or evaluation promise; otherwise iterate implementation and protocol details. |
| 2026-07-15 | renewed BUILD_AND_EVALUATE freeze -> active BOOTSTRAP REVIEW_GATE | The latest prompt again asks for BOOTSTRAP re-entry and paper reorganization. Step 0005 did not change the idea; it corrected paper/frontier expression and restored lost evaluation-protocol meaning. | Pending REVIEW_GATE disposition. | Chosen state is more faithful than treating step 0004 as final because it honors the newest explicit BOOTSTRAP instruction without shrinking the hypothesis. | `docs/tmp/bootstrap/step-0005-20260714T174151-0700/step-report.md` | Exit only after step 0005 outer audit and meta-review accept the route. |
| 2026-07-15 | active BOOTSTRAP REVIEW_GATE -> renewed BUILD_AND_EVALUATE freeze | Step 0005 passed independent outer audit with no Must-fix and routed back to BUILD_AND_EVALUATE. | Accepted; freeze the scientific contract and resume evidence work. | Chosen state is stronger than the active re-entry because the paper now preserves measurement protocol, RQ3 ownership fields, and workload/scope anchors while keeping the ambitious VFS extension-point story. | `docs/tmp/bootstrap/step-0005-20260714T174151-0700/outer-audit-20260715T021137-0700.md` | Reopen only if final admitted evidence requires changing the problem, claim, RQs, baseline families, workload coverage, or evaluation promise; otherwise iterate implementation and protocol details. |

## Guardrails

- Do not claim only `namei_ext` or only eBPF can implement the selected
  workloads.
- Do not make table-only impossibility, static-table failure, or materialized
  namespace shootouts the novelty line.
- Do not let writing/review passes shrink the idea around currently easy
  prototype evidence.
- Do not treat source characterization, preflight runs, or unreviewed matrices
  as final RQ evidence.
- Do keep the paper focused on the strongest honest systems abstraction:
  policy at VFS name resolution, lower filesystem semantics below.
