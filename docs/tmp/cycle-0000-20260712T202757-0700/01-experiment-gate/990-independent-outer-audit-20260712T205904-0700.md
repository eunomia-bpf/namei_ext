# Independent Outer Audit: BOOTSTRAP EXPERIMENT_GATE Literature/Novelty Node

Timestamp: 2026-07-12T20:59:04-0700
Cycle: 0000
Phase: BOOTSTRAP
Gate: 01-experiment-gate
Audited node: `literature-20260712T205136-0700/001-claim-search-and-novelty-map-20260712T205136-0700.md`
Status: complete
Verdict: PASS

## Context

This audit checks whether the BOOTSTRAP EXPERIMENT_GATE literature/novelty node solved the intended gate problem before the project moves toward the gate report and BOOTSTRAP WRITE_GATE. The gate entry defines that problem as novelty pressure, closest-work positioning, and source-backed workload assets for a later OSDI/SOSP-grade evaluation, not proof from the current prototype (`000-gate-entry`, lines 15-18).

The user-fixed direction is ambitious and specific: `namei_ext` is a `sched_ext`-style VFS extension point between bind/Overlay/materialization and FUSE/custom filesystems (`docs/user-instruction.md`, lines 4-6 and 44-46). The user also fixed RQ1 as expressiveness/sufficiency, RQ2 as FUSE cost/overhead, and RQ3 as custom/FUSE/stackable filesystem safety or boundary evidence (`docs/user-instruction.md`, lines 9-19). Later instructions explicitly reject scattered small experiments, weak baselines, table-only novelty, static-table impossibility, and materialization as the main experimental story (`docs/user-instruction.md`, lines 30-42).

Independence disclosure: I read the required root disposition and the literature node's own completion statement because they were part of the requested input. I did not read a completed gate report or any proposed repair. I did not edit skills, run git mutations, or change paper/story/design files. This audit reviews the Markdown node and its handoff; it does not redo final citation verification.

## Inputs Read

- `docs/user-instruction.md`, lines 1-88.
- `docs/idea-story.md`, lines 1-243.
- `docs/background-related-work.md`, lines 1-189.
- `docs/tmp/cycle-0000-20260712T202757-0700/00-bootstrap-idea/500-root-disposition-20260712T205136-0700.md`, lines 1-109.
- `docs/tmp/cycle-0000-20260712T202757-0700/01-experiment-gate/000-gate-entry-20260712T205136-0700.md`, lines 1-75.
- `docs/tmp/cycle-0000-20260712T202757-0700/01-experiment-gate/literature-20260712T205136-0700/001-claim-search-and-novelty-map-20260712T205136-0700.md`, lines 1-214.

## Findings

### Direction: PASS

The literature/novelty node solved the intended BOOTSTRAP gate question. It restates the gate objective as checking whether the restored story has a defensible novelty gap and credible OSDI/SOSP evaluation promise after prior drift toward table diagnostics and weak baselines (`001-claim-search-and-novelty-map`, lines 12-15). It searches the claim without project names as a narrow VFS name-resolution hook, bounded eBPF decision function, FUSE cost comparison, and custom/stackable filesystem boundary comparison (`001-claim-search-and-novelty-map`, lines 27-39), which matches the gate entry scope (`000-gate-entry`, lines 42-63).

The node preserves the user-fixed ambitious story. The root disposition accepted the `sched_ext`-style VFS name-resolution extension point between eBPF LSM and FUSE/custom filesystem ownership and required source systems to serve as path-view/oracle specifications rather than a baseline list (`500-root-disposition`, lines 50-69). The literature node carries that forward by identifying the safe ambitious claim as a missing middle between access-control hooks and filesystem ownership, with programmable name-resolution policy, source-derived workloads, FUSE cost comparison, and custom/stackable boundary comparison (`001-claim-search-and-novelty-map`, lines 142-147). The background frontier now records the same novelty verdict (`docs/background-related-work.md`, lines 170-178).

There is no material shrinkage back to table-only, materialization-mainline, or scattered weak baselines. The literature node explicitly rejects exclusive-necessity claims, table impossibility, generic FUSE dismissal, materialization shootouts, and full-reproduction claims for unavailable systems (`001-claim-search-and-novelty-map`, lines 149-158). It also requires future experiments to be Make-owned, KVM-attached, same-oracle, correctness-gated, raw-artifact-backed, and free of weak baselines that cannot change an RQ interpretation (`001-claim-search-and-novelty-map`, lines 170-178). This is aligned with the user instruction against scattered experiments and weak baselines (`docs/user-instruction.md`, lines 30-36) and against table-only novelty (`docs/user-instruction.md`, lines 38-42).

The handoff is credible for WRITE_GATE. The node gives writing a clear claim to carry, a list of claims to avoid, and a concrete evaluation promise: RQ1 uses representative source-derived workloads through the real KVM `cgroup/namei_ext` path, RQ2 uses feature-equivalent FUSE plus controls, and RQ3 uses same-oracle boundary accounting against custom/stackable filesystem ownership (`001-claim-search-and-novelty-map`, lines 160-178). The related-work frontier independently records the same next action: after BOOTSTRAP freeze, implement the agent workspace complete experiment first, then an environment/cache complete experiment, and add service/config only if a concrete lookup-time source oracle makes it strong rather than weak breadth (`docs/background-related-work.md`, lines 179-189).

### Scope Completion

The declared EXPERIMENT_GATE completion condition required a detailed literature node with exact search branches, source families, closest-work risk, and baseline/evaluation implications, plus an updated `docs/background-related-work.md` frontier and this audit before the gate report (`000-gate-entry`, lines 65-74). The node satisfies the first part: it lists search branches and sources (`001-claim-search-and-novelty-map`, lines 41-80), closest-work findings (`001-claim-search-and-novelty-map`, lines 82-128), novelty risk and decision (`001-claim-search-and-novelty-map`, lines 130-158), and baseline/evaluation handoff (`001-claim-search-and-novelty-map`, lines 160-178). The canonical related-work file was updated with the BOOTSTRAP search log row and novelty verdict (`docs/background-related-work.md`, lines 9-13 and 170-189).

No blocker is created by the node's own caveat that it is "not final citation verification" (`001-claim-search-and-novelty-map`, line 8 and lines 208-211). That caveat is appropriate for BOOTSTRAP pressure. The later WRITE/verification path still needs citation verification, but this gate does not need to block on final paper-reference checking.

### Efficiency

No material issue. The node consolidates the evidence program instead of expanding it into many new experiment fragments. It selects mechanism-family comparisons that can change RQ interpretation: feature-equivalent FUSE for RQ2 and custom/stackable filesystem boundary evidence for RQ3 (`001-claim-search-and-novelty-map`, lines 98-108 and 160-168). It also keeps materialized namespace mechanisms in background unless they are part of a selected source workload (`001-claim-search-and-novelty-map`, lines 124-128), which avoids re-opening the old baseline churn.

### Maintenance

No material issue. The node updated the correct canonical frontier, `docs/background-related-work.md`, and did not create extra control artifacts. The background document remains a current literature/source frontier and records role separation for source systems, FUSE, custom/stackable filesystems, materialized mechanisms, and related-work-only metadata systems (`docs/background-related-work.md`, lines 112-134 and 155-178).

The gate report should carry two non-blocking residual risks: final citation verification is still pending, and service/config remains conditional until a concrete lookup-time source oracle is selected (`docs/background-related-work.md`, lines 187-189). Neither risk invalidates this literature node or the transition to writing.

## Verdict

PASS. I found no blocker. The literature/novelty node solved the intended BOOTSTRAP EXPERIMENT_GATE problem, preserved the user-fixed ambitious `sched_ext`-style VFS extension-point story, avoided restoring table-only novelty, materialization-as-mainline framing, and weak scattered baselines, and created a credible handoff for the gate report and BOOTSTRAP WRITE_GATE.

## Next Action

The EXPERIMENT_GATE can proceed to its gate report. If the gate report records the above non-blocking residual risks, the cycle can then enter BOOTSTRAP WRITE_GATE.
