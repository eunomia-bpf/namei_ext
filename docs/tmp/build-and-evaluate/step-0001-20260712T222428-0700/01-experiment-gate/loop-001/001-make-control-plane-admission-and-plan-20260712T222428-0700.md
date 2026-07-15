# Make Control-Plane Alignment: Admission And Plan

Timestamp: 2026-07-12T22:24:28-07:00
Phase: BUILD_AND_EVALUATE
Step: 0001
Gate: 01-experiment-gate
Loop: 001
Status: admitted as dependency repair

## Question And Entry

Does the current Make control plane support the frozen evaluation promise, or
does it still route researchers toward the old scattered W1-W4/table diagnostic
program?

## Paper-Value Admission

Role: dependency.

This node does not answer RQ1, RQ2, or RQ3. It is admitted because it removes a
review-blocking execution ambiguity before any final experiment can be run. If
the Make entrypoints remain scattered, later successful runs could still be
scientifically ambiguous: they might be legacy diagnostics rather than the
integrated same-oracle matrices promised by the paper.

Largest credible paper story unlocked:

- the next actual experiment can be the AgentFS-derived Agent workspace
  lifecycle matrix, not another table or W1-W4 diagnostic;
- feature-equivalent FUSE comparison can be part of that matrix rather than a
  separate weak baseline;
- legacy diagnostics remain reproducible without controlling the paper story.

Decision value:

- positive result: BUILD_AND_EVALUATE can proceed to admit/run the Agent
  workspace lifecycle experiment through Make;
- contradictory result: if Make cannot be aligned without breaking current
  validation, the project must repair infrastructure before any final
  experiment;
- mixed result: keep the story frozen but continue operational repair;
- inconclusive result: do not run final experiments until control-plane intent
  is explicit.

## Scope

This plan may edit Makefiles and current documentation/state reports. It must
not edit the frozen RQs, paper thesis, or user-instruction log.

## Planned Changes

1. Add current experiment lifecycle targets at the top level:
   `experiments`, `experiment-agent-workspace`, and `experiment-env-cache`.
2. Keep `kvm-agent-workspace-preflight` as the implemented dependency
   preflight for the Agent workspace matrix.
3. Make unsupported final matrix targets fail visibly with a clear Make error
   until their complete matrices exist.
4. Move old W1-W4/table/eval-osdi diagnostics behind explicit legacy naming in
   help and, where practical, conditional includes.
5. Avoid adding project-owned shell scripts or non-Make control planes.

## Validation Commands

- `make help`
- `make -n experiments`
- `make -n experiment-agent-workspace`
- `make -n experiment-env-cache`
- `make -B -C docs/paper`

The dry-run commands are sufficient for this dependency node because the goal
is control-plane routing, not final experiment execution. Later admitted
experiments must run real KVM commands and preserve raw results.

