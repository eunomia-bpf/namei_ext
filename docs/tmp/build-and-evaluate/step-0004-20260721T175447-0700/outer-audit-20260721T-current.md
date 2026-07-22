# Independent Outer Audit: BUILD_AND_EVALUATE Step 0004

Reviewer role: fresh outer auditor; no execution, implementation, paper-editing,
or earlier review role in this step. I saw the plan's expected outcome and the
plan/result-review verdicts because they are required audit inputs, but treated
them as diagnostic claims and checked the raw roots and diff independently.

## Verdict

**PASS for the scoped Agent-workspace RQ1 cell and its targeted paper edit.**
The result is paper-admissible for the fixed AgentFS-derived path-view slice.
It does not close paper-level RQ1, does not authorize any RQ2 timing
interpretation, and does not establish RQ3. Step closure should route directly
to the still-open traditional build/cache RQ1 family.

## Evidence Audit

- The experiment asks the exact frozen RQ1 and attacks a load-bearing gap: a
  source-derived integrated workspace lifecycle through the real KVM
  `cgroup/namei_ext` path, rather than another mechanism smoke test.
- The three formal raw roots each contain 1,176 JSONL records, 94 passing cases,
  16 passing measurement records, four passing trace artifact/replay gates, two
  passing implementation summaries, one terminal marker, and no failed
  `pass` row. All twelve recorded input digests currently verify. Stdout and
  stderr are empty by design because the runners append JSONL directly.
- The paper's operation counts match every formal root: 2,581 lookup calls, 903
  readdir calls, 419 selections, three hidden lookups, and 53 hidden readdir
  entries. Direct cases cover create, rename, unlink, final-tree state,
  lower-tree non-materialization, and unregistered-target containment.
- The trace is bound to both `namei_ext` and FUSE and hashes to the same fixed
  AgentFS-derived artifact in all three roots. This remains a deterministic
  source-derived replay, not a claim to reproduce AgentFS's SQLite, audit, full
  COW, or runtime semantics; the plan, result review, canonical evaluation, and
  paper all retain that scope.
- Run 2 records a clocksource watchdog timeout. It does not undermine the
  deterministic correctness cells, but it makes it especially important that
  these collected timings are not reused as RQ2 evidence.

## Direction And Contract Fidelity

**Direction passes.** The step preserves the frozen `sched_ext`-style VFS
extension-point position and adds evidence for one promised primary family. It
does not revive table-only novelty, materialized-view shootouts, or a catalog of
weak baselines. The ambitious contribution remains design plus Linux
implementation of a narrow name-resolution boundary.

The exact two-primary-workload promise is intact: Agent workspace and
traditional build/cache remain the only primary families; service/config and
checkpoint/restart were not promoted. The Agent cell is complete, while the
traditional build/cache cell remains explicitly open in the step report,
`docs/evaluation.md`, and the paper.

The targeted edit is authorized in BUILD_AND_EVALUATE: it changes only the RQ1
result row and Evaluation-scope status. The numerical claims are supported by
the raw roots, and the edit does not touch the frozen abstract, introduction,
contribution, RQs, structure, related work, or conclusion.

Explicit boundary checks:

- **RQ2 is not interpreted.** Timings are collected but remain placeholders in
  the paper and are expressly reserved for a fresh correctness-gated RQ2 step.
- **RQ3 is not claimed.** Raw boundary labels and the one unregistered-target
  control are not promoted into an ownership result; both RQ3 paper rows remain
  placeholders.
- **RQ1 is not overclosed.** Only the Agent-workspace subproblem is closed;
  traditional build/cache remains necessary before paper-level RQ1 can close.

## Efficiency And Maintenance

The step produced a paper-decision-changing result after one bounded invalid
BTF build and a minimally invasive `JOBS=1` repair. Three complete terminal
runs then satisfied the approved conjunctive rule; no fragmented prefix or
extra baseline was interpreted. Canonical evaluation memory and the verbatim
user log are current; no idea-story change was appropriate because the
scientific contract did not change, and there is no open author question.

The repository lacks the orchestrator reference's
`scripts/check_progress.py`, so no progress diagnostic could be consumed in
this audit. This is a maintenance/process gap, not a defect in the raw result.

## Findings And Routing

### Must-fix before step closure

- The root must add the audit disposition, meta-review findings, ranked open
  objections, and explicit next-step route to `step-report.md` before the one
  step-boundary commit/push. This is routine REVIEW_GATE closure and requires no
  experiment rerun.

### Should-fix

- Future final-result targets should record the parent repository HEAD and
  dirty-worktree/patch identity in addition to executed-input hashes.
- Restore or deliberately replace the missing progress diagnostic before a
  later meta-review relies on it.
- Keep the run-2 clocksource caveat out of correctness interpretation and run a
  fresh RQ2 protocol with its own warmup, repetition, uncertainty, and
  cache-hot/cache-cold controls.

### Consider

- Before final workshop publication, reconcile the user's commit/push request
  for the paper PDF with the current ignored `.build/paper/main.pdf` output;
  this is not needed to validate the present RQ1 evidence cell.

### Recommended route

Complete this REVIEW_GATE, persist the coherent step once, and return to
EXPERIMENT_GATE for one admitted traditional build/cache RQ1 experiment. Do not
advance to WRITING or milestone acceptance, and do not interpret RQ2 or RQ3,
until the two-family RQ1 promise and their separately reviewed evidence are
complete.
