# BOOTSTRAP Re-entry Recovery

Timestamp: 2026-07-13T00:46:18-07:00
Phase: BOOTSTRAP
Step: 0002
Gate: recovery before 01-experiment-gate
Status: complete

## Question And Entry

The latest user instruction is: `按照新的 skills 重新回到 BOOTSTRAP 阶段`.
This directly overrides the active BUILD_AND_EVALUATE route recorded in
`docs/tmp/build-and-evaluate/step-0002-20260713T002404-0700/step-report.md`.

The recovery question is whether the project should continue Loop 002 of the
Agent workspace experiment or move the active research frontier back to
BOOTSTRAP under the current `auto-research-orchestrator` rules.

## Inputs And Method

Inputs read:

- `docs/user-instruction.md`
- `docs/idea-story.md`
- `docs/design.md`
- `docs/evaluation.md`
- `docs/implementation.md`
- `docs/background-related-work.md`
- `docs/questions-for-author.md`
- `docs/tmp/bootstrap/step-0001-20260712T223808-0700/step-report.md`
- `docs/tmp/build-and-evaluate/step-0002-20260713T002404-0700/step-report.md`
- `auto-research-orchestrator/SKILL.md`
- `auto-research-orchestrator/references/hierarchical-research-state-machine.md`

Method:

1. Treat the newest user instruction as the active phase/routing constraint.
2. Preserve prior reports and raw artifacts as history and evidence.
3. Stop interpreting the previous BOOTSTRAP freeze as the active scientific
   contract.
4. Open a new BOOTSTRAP step rather than mutating or deleting the old
   BUILD_AND_EVALUATE step.

`scripts/check_progress.py` was not run because this repository currently has
no `scripts/` directory.

## Results And Raw Evidence

The current repo state contained a real conflict:

- `docs/idea-story.md`, `docs/design.md`, `docs/evaluation.md`,
  `docs/implementation.md`, and `docs/background-related-work.md` described a
  frozen BUILD_AND_EVALUATE route.
- `docs/questions-for-author.md` and the latest user prompt required re-entry
  to BOOTSTRAP before resuming BUILD_AND_EVALUATE experiments.
- BUILD_AND_EVALUATE step 0002 was active in its experiment gate, with Loop 002
  open, but the Loop 001 result review had already classified the latest
  Agent workspace matrix as incomplete, supporting-only evidence.

No raw result is invalidated. The latest run
`results/experiments/agent-workspace-matrix/20260713T073438Z-5be906d9/`
remains prototype/supporting evidence and must not be used as final RQ evidence.

## Scientific Impact And Decision

Decision: re-enter BOOTSTRAP immediately.

The candidate story remains strong and should not be shrunk: `namei_ext` is a
`sched_ext`-style VFS name-resolution extension point between eBPF LSM and
FUSE/custom filesystem ownership. However, under the newest instruction and the
current skill policy, it is now a candidate BOOTSTRAP contract, not a frozen
BUILD_AND_EVALUATE contract.

This re-entry does not reject the prior story. It changes its status so the
next BOOTSTRAP pass can apply idea pressure, literature pressure, workload
coverage pressure, and evidence-promise pressure before any renewed freeze.

Reversibility: route back to BUILD_AND_EVALUATE only after this BOOTSTRAP step
completes EXPERIMENT, WRITE, and REVIEW gates and records a renewed freeze.

## State Updates

- Active phase becomes BOOTSTRAP.
- Active step root becomes
  `docs/tmp/bootstrap/step-0002-20260713T004618-0700/`.
- BUILD_AND_EVALUATE step 0002 is paused/superseded by user instruction, not
  completed.
- Agent workspace Loop 002 remains historical repair planning, not the next
  active action.

## Completion And Next Action

This recovery node is complete. The next node is BOOTSTRAP
`01-experiment-gate/000-gate-entry`, which should select the first high-value
BOOTSTRAP action. Because the phase was reopened after a claimed freeze, the
gate should pressure the scientific contract and closest-work/workload evidence
before any empirical plan is treated as final RQ evidence.
