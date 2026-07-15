# BUILD_AND_EVALUATE Step 0003 Report

Timestamp: 2026-07-14T15:47:05-0700
Phase: BUILD_AND_EVALUATE
Status: active
Current gate: 01-experiment-gate

## Step Objective

Execute the first complete experiment under the renewed frozen contract from
BOOTSTRAP step 0002:

`docs/tmp/bootstrap/step-0002-20260713T004618-0700/step-report.md`

This step must not reopen the paper story, table-only diagnostics, or scattered
baseline catalog. The frozen contract is:

- `namei_ext` is a `sched_ext`-style VFS name-resolution extension point.
- RQ1 is expressiveness/sufficiency without taking over filesystem semantics.
- RQ2 is cost/overhead versus feature-equivalent FUSE.
- RQ3 is a narrower verifier-bounded, fail-closed ownership boundary versus
  custom or stackable filesystem ownership.
- The first complete experiment is the Agent workspace lifecycle matrix.

## Recovery After BOOTSTRAP Step 0004

BOOTSTRAP step 0004 later re-entered BOOTSTRAP under the user's renewed
instruction to reorganize and improve the paper. That step completed a full
writing pass, fresh outer audit, and renewed freeze:

`docs/tmp/bootstrap/step-0004-20260714T161834-0700/step-report.md`

This BUILD_AND_EVALUATE step remains the active Agent workspace experiment
because it was already the innermost incomplete node and its experiment
direction still matches the renewed frozen contract. The parent scientific
contract for all work after this recovery point is therefore BOOTSTRAP step
0004, not the older step 0002 route. No paper story, RQ, comparison family, or
workload family changes in this step.

## Gate Entry

The active gate is EXPERIMENT_GATE. The selected experiment is Experiment A:
Agent workspace lifecycle.

Selected RQ focus: RQ1, with required RQ2 and RQ3 cells in the same integrated
matrix. RQ1 is selected because the experiment must first establish that the
source-derived path-view oracle passes through the real `cgroup/namei_ext` KVM
attach path before overhead or boundary interpretation is meaningful.

The experiment must be admitted and executed as one complete matrix, not as
independent smoke tests, run IDs, weak baselines, table-only diagnostics, or
materialized-view shootouts.

## Current Node

Node: Experiment 001, Agent workspace lifecycle
Directory:
`docs/tmp/build-and-evaluate/step-0003-20260714T154705-0700/01-experiment-gate/experiment-001-agent-workspace/`

Completed node records so far:

- Admission and plan:
  `docs/tmp/build-and-evaluate/step-0003-20260714T154705-0700/01-experiment-gate/experiment-001-agent-workspace/001-admission-and-plan-20260714T154705-0700.md`
- Execution:
  `docs/tmp/build-and-evaluate/step-0003-20260714T154705-0700/01-experiment-gate/experiment-001-agent-workspace/002-execution-20260714T155035-0700.md`
- Independent result review:
  `docs/tmp/build-and-evaluate/step-0003-20260714T154705-0700/01-experiment-gate/experiment-001-agent-workspace/003-result-review-20260714T155300-0700.md`
- Protocol repair run:
  `docs/tmp/build-and-evaluate/step-0003-20260714T154705-0700/01-experiment-gate/experiment-001-agent-workspace/004-protocol-repair-run-20260714T161245-0700.md`
- Source-lifecycle repair run:
  `docs/tmp/build-and-evaluate/step-0003-20260714T154705-0700/01-experiment-gate/experiment-001-agent-workspace/2026-07-14-agent-workspace-source-lifecycle-repair-run.md`

The latest Make-owned KVM root is
`results/experiments/agent-workspace-matrix/20260715T003201Z-a12b8555/`.
It passes the Make-owned KVM matrix with 724 JSONL rows, 0 failed rows, 600
latency samples, explicit source-trace rows, rename/unlink/cached-negative
lifecycle rows for both `namei_ext` and FUSE, and source-tied RQ3 boundary
rows. The run is candidate Experiment A evidence but is not paper evidence
until independent result review classifies it.

Current task: run an independent result review over the latest source-lifecycle
repair run. The review must decide whether the source-derived lifecycle
evidence, FUSE fairness, RQ2 metric coverage, and RQ3 boundary evidence are
sufficient for Experiment A or still incomplete/supporting.

## Git Publication

No Git mutation has been performed in this step.
