# Sidecar Execution Alignment Audit

Timestamp: 20260712T214900-0700

Status: captured from the closed read-only sidecar agent. No edits were made by
the sidecar agent.

## Verdict

Not ready for a final experiment gate. The document direction is now aligned
with the stronger OSDI/SOSP story, but the executable control plane and
implementation gates still reflect older scattered evaluation structure.

## Blockers To Carry Forward

- The active paper/docs organize the evaluation around integrated experiments,
  but `make phase1` and help text still expose old W1-W4/table/eval-osdi style
  flows. Since Make is the project entrypoint, the executable workflow must be
  realigned with the admitted RQ1/RQ2/RQ3 experiment matrix.
- The admitted agent/workspace and environment/cache experiments are specified
  as plans but are not yet executable same-oracle matrices.
- The environment/cache plan still needs concrete per-row path-view evidence so
  a source evaluator pass cannot degrade into generic dependency evidence.
- RQ3 is currently boundary analysis plus dynamic containment evidence gated by
  RQ1/RQ2, not a runnable same-oracle empirical win over every custom or
  stackable filesystem. The paper should keep that framing unless the
  experiment design changes.

## Non-Blocker Confirmations

- The active docs demote static table, table-only, and materialized namespace
  comparisons out of the main experiment line.
- The main RQ2 comparison is consistently feature-equivalent FUSE under the same
  oracle.
- The mechanism gradient
  `bind/Overlay/materialization < eBPF LSM < namei_ext < FUSE/custom FS`
  remains consistent across the current framing.

## Follow-Up Gate

The next EXPERIMENT/IMPLEMENTATION pass must make the Makefile-owned workflow
match the new integrated experiment design before the project can claim
experiment readiness.
