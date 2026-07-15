# Source-Lifecycle Repair Result Review

Timestamp: 2026-07-14T17:32:37-0700
Reviewer: independent read-only subagent `019f6331-fd80-71d1-8312-d458dac1ed1e`
Phase: BUILD_AND_EVALUATE
Step: `docs/tmp/build-and-evaluate/step-0003-20260714T154705-0700/`
Experiment: Agent workspace lifecycle
Raw root: `results/experiments/agent-workspace-matrix/20260715T003201Z-a12b8555/`

## Required Judgments

```text
run status: incomplete
tested hypothesis: inconclusive
research value: supporting
paper impact: additional RQ evidence
next paper decision: keep this as supporting KVM lifecycle evidence, but do not promote it to final Experiment A until the source oracle, RQ2 metrics, and RQ3 containment are complete.
```

## Must-Fix Findings

1. The run still does not provide final paper-quality source evidence. It adds
   rename, unlink, cached-negative creation, `.git/HEAD`, and `src/app.txt`
   rows, but the AgentFS tie is a declared/reduced source-trace fixture, not an
   executed AgentFS CLI/SDK bash/git command sequence or replayed source trace.
2. RQ2 is still supporting only. FUSE is feature-equivalent for this reduced
   matrix and engages rename/unlink/create/read/write/readdir, but metrics
   cover only stat/readdir plus no-hook controls. The frozen plan still
   requires open/stat/access/exec/readdir, macro runtime,
   repetitions/uncertainty, and FUSE request-path cost.
3. RQ3 remains incomplete. The three boundary rows are source-shaped and better
   than the previous generic rows, but they are hard-coded Make JSON rows, not a
   source-backed boundary table with cited/runnable evidence. Invalid-policy
   containment is still only "unregistered target returns ENOENT";
   malformed/unsupported policy decisions are not covered.

## Usable Evidence

- Make/KVM path is valid: `experiment-agent-workspace` maps to
  `kvm-agent-workspace-matrix`, and dmesg/uname show the modified kernel booted
  in virtme/KVM.
- Real attach path is engaged: `attach_policy`, target registration, detach,
  and nonzero `namei_ext` counters passed.
- Raw JSONL supports the report: 724 rows, 90 case rows, 600 samples, 8
  metrics, 3 boundary rows, 18 counter rows, and 0 failed rows.
- Lifecycle repair rows pass for both `namei_ext` and FUSE:
  cached-negative create/visible/unlink, rename old-absent/new-visible/restore.
- Dmesg failure grep has no hits.

## Root Disposition

Accepted. The run is useful supporting KVM lifecycle evidence, but the
experiment stays in EXPERIMENT_GATE. The next repair is narrowly scoped to the
reviewer's remaining blockers: replace the trace declaration with a concrete
AgentFS-derived trace artifact, broaden RQ2 measurement coverage, and add
stronger RQ3 containment/boundary evidence without changing the frozen
hypothesis.
