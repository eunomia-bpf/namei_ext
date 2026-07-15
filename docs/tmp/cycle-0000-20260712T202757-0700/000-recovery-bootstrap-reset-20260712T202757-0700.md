# Recovery Node: BOOTSTRAP Re-Entry

Timestamp: 2026-07-12T20:27:57-0700
Cycle: 0000
Phase: BOOTSTRAP
Status: complete

## Question And Entry

The user instructed: "按照新的 skills 重新回到 BOOTSTRAP 阶段". This node
re-enters the project through the new `auto-research-orchestrator` lifecycle
instead of continuing the previous BUILD_AND_EVALUATE-style implementation
trajectory.

The immediate problem is that the repository already contains useful prototype
and preflight evidence, but the new orchestrator requires BOOTSTRAP to freeze
the strongest defensible problem, claim, RQs, design goals, evaluation promise,
and paper structure before final evidence collection.

## Inputs And Method

Inputs read:

- `docs/user-instruction.md`
- `docs/idea-story.md`
- `docs/evaluation.md`
- `docs/implementation.md`
- `research/STATE.md`
- `docs/tmp/2026-07-13-agent-workspace-preflight-implementation.md`
- `results/experiments/agent-workspace/20260713T032434Z-8cbbac1b/agent-workspace-preflight.jsonl`
- `auto-research-orchestrator/SKILL.md`
- `auto-research-orchestrator/references/hierarchical-research-state-machine.md`

The recovery method was to preserve existing implementation and source evidence,
but change its orchestration role: current KVM runs are BOOTSTRAP
feasibility/dependency evidence, not frozen paper results. The next work is the
BOOTSTRAP cycle, not more experiment-matrix implementation.

## Results And Raw Evidence

State updates made:

- Appended the latest user-authored instruction to `docs/user-instruction.md`.
- Marked `docs/idea-story.md` as BOOTSTRAP re-entry and linked this cycle root.
- Marked `research/STATE.md` as BOOTSTRAP and changed its next action from
  implementation to cycle-0 bootstrap work.
- Added `docs/questions-for-author.md` with no open decision-critical
  questions.
- Updated `docs/evaluation.md`, `docs/implementation.md`, and
  `docs/tmp/2026-07-13-agent-workspace-preflight-implementation.md` so the
  latest agent-workspace preflight root is
  `results/experiments/agent-workspace/20260713T032434Z-8cbbac1b/`.

The latest preflight raw JSONL has 61 rows and includes nonzero counters for
both `namei_ext` and FUSE policy paths. That evidence proves preflight
engagement of the small bounded-action slice; it does not answer RQ1/RQ2/RQ3.

## Scientific Impact And Decision

Decision: return to BOOTSTRAP.

The current candidate story remains:

```text
namei_ext is a sched_ext-style VFS extension point for state-dependent path
views, positioned between eBPF LSM and FUSE/custom filesystem ownership.
```

This candidate is not frozen. BOOTSTRAP must now decide whether this is the
strongest honest story, pressure it against literature and closest work, write
a complete submission-shaped paper with explicit placeholders, and review it
before BUILD_AND_EVALUATE resumes.

Existing experiment plans for Agent workspace and environment/cache remain
valuable, but only as BOOTSTRAP evaluation promises until the freeze.

## Independent Review

No independent outer audit ran for this recovery node. The next BOOTSTRAP gate
must audit this routing decision against `docs/user-instruction.md` and the
new orchestrator rules.

## State Updates

The formal report root for the new lifecycle is:

```text
docs/tmp/cycle-0000-20260712T202757-0700/
```

The current frontier is recorded in:

- `docs/idea-story.md`
- `research/STATE.md`

## Completion And Next Action

This recovery node is complete. The next node is the BOOTSTRAP cycle-0
idea-discussion/root-disposition prelude:

```text
docs/tmp/cycle-0000-20260712T202757-0700/00-bootstrap-idea/000-entry-20260712T202757-0700.md
```

Completion condition for that next node: read the full user-instruction and
idea-story files, run or explicitly audit the required read-only idea
discussion evidence under the new rules, record one root disposition, and only
then enter the BOOTSTRAP EXPERIMENT_GATE literature/novelty pressure.
