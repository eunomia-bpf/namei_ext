# Independent Outer Audit

Timestamp: 2026-07-13T01:19:00-07:00
Phase: BOOTSTRAP
Step: `docs/tmp/bootstrap/step-0002-20260713T004618-0700/`
Gate: 01-experiment-gate
Reviewer: read-only subagent audit
Status: completed

## Scope

The audit read:

- `docs/user-instruction.md`
- `docs/idea-story.md`
- `docs/evaluation.md`
- `docs/design.md`
- `docs/background-related-work.md`
- `research/STATE.md`
- `docs/tmp/bootstrap/step-0002-20260713T004618-0700/step-report.md`

The review question was whether the current story/RQs/baseline organization
matches the latest user direction:

- no table-only mainline;
- stronger `sched_ext`-style VFS extension story;
- RQ1 expressiveness/sufficiency;
- RQ2 cost versus feature-equivalent FUSE;
- RQ3 safety/boundary versus custom or stackable filesystems;
- few complete OSDI/SOSP experiments rather than scattered weak baselines.

## Findings

### High: no-freeze state is explicit and correct

The canonical docs correctly mark the story as an active BOOTSTRAP candidate,
not a frozen contract. This matches the latest instruction, but it also means a
renewed freeze would be premature until step 0002 completes EXPERIMENT, WRITE,
and REVIEW gates.

Disposition: accepted. No canonical change required beyond keeping step 0002
active.

### High: RQ3 was directionally right but under-specified for freeze

The docs correctly moved RQ3 to safety/boundary versus custom or stackable
filesystems, not bind/Overlay/table shootouts. However, the planned evidence
was still too generic: it said "boundary evidence" without naming concrete
workload-specific comparators or an exact table schema.

Disposition: fixed in `docs/evaluation.md` by adding `RQ3 Boundary Audit
Schema`, concrete comparators for Agent workspace, environment/cache, and
conditional service/config workloads, and required evidence columns.

### Medium: Experiment B was promising but not admitted enough

The environment/cache story matched the intended stronger direction, but the
canonical evaluation document did not yet surface the fixed source-row suite,
cache-state harness, and same-oracle matrix. The detailed dated plan had a
candidate suite, but the main document still read as too open.

Disposition: fixed in `docs/evaluation.md` by promoting the step 0002 candidate
suite and the fixed hit/miss/stale/corrupt/epoch state machine into the
canonical Experiment B section.

### Medium: baseline organization mostly matched, but wording could cause drift

The docs correctly made FUSE the central RQ2 comparison and rejected scattered
weak baselines. However, `docs/background-related-work.md` grouped source
oracles, controls, and boundary evidence under `Mandatory Baselines`, which
could reintroduce baseline-count thinking.

Disposition: fixed in `docs/background-related-work.md` by replacing
`Mandatory Baselines` with `Main Comparisons And Evidence Roles` and replacing
`Baseline Candidates` with `Non-Main Comparison Disposition`.

## Recommendation

No freeze yet. The current story matches the latest direction after the
follow-up canonical fixes, but step 0002 still needs an EXPERIMENT_GATE report.
If that report accepts the fixes, the next route is WRITE_GATE, not immediate
BUILD_AND_EVALUATE.

## Must-Fix Status

| Must-fix item | Status | Evidence |
| --- | --- | --- |
| Keep no-freeze BOOTSTRAP state explicit. | Satisfied. | `docs/idea-story.md`, `docs/evaluation.md`, `research/STATE.md`, and the step report all identify step 0002 as active BOOTSTRAP. |
| Specify RQ3 comparators and evidence schema. | Satisfied for BOOTSTRAP routing. | `docs/evaluation.md` now names workload-specific comparators and boundary-table fields. |
| Promote Experiment B fixed suite and state machine. | Satisfied for BOOTSTRAP routing. | `docs/evaluation.md` now names the candidate source rows and fixed state machine; BUILD_AND_EVALUATE must still produce path-view manifests. |
| Separate baselines from oracles, controls, and boundary evidence. | Satisfied. | `docs/background-related-work.md` now separates evidence roles. |
