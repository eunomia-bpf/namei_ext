# BOOTSTRAP Step 0002 Experiment Gate Report

Timestamp: 2026-07-13T01:24:00-07:00
Phase: BOOTSTRAP
Step: `docs/tmp/bootstrap/step-0002-20260713T004618-0700/`
Detailed report:
`docs/tmp/bootstrap/step-0002-20260713T004618-0700/01-experiment-gate/999-gate-report-20260713T012400-0700.md`

## Summary

The EXPERIMENT_GATE passed the current candidate story to WRITE_GATE. This is
not a renewed freeze and does not resume BUILD_AND_EVALUATE.

The accepted candidate story is that `namei_ext` is a `sched_ext`-style VFS
name-resolution extension point between eBPF LSM and FUSE/custom filesystem
ownership. The RQs are expressiveness/sufficiency, cost versus
feature-equivalent FUSE, and safety/boundary versus custom or stackable
filesystem ownership.

## Gate Work Completed

- Literature and novelty pressure found no same-claim blocker, but required the
  paper to treat ExtFUSE, FUSE-BPF, and FUSE passthrough as close mechanism
  pressure.
- Independent audit found three must-fix issues: underspecified RQ3 boundary
  evidence, underspecified Experiment B suite, and baseline wording that could
  reintroduce drift.
- Canonical docs were fixed:
  - `docs/evaluation.md` now includes a workload-specific RQ3 boundary audit
    schema.
  - `docs/evaluation.md` now names the Experiment B candidate source rows and
    fixed cache-state machine.
  - `docs/background-related-work.md` now separates main baselines from
    correctness oracles, controls, and boundary evidence.

## Decision

Proceed to BOOTSTRAP WRITE_GATE. Do not freeze the paper and do not restart
BUILD_AND_EVALUATE until WRITE_GATE and REVIEW_GATE pass.
