# BOOTSTRAP Step 0005 Report

Started: 2026-07-14T17:41:51-0700

## Step Objective

The latest user instruction explicitly asks the project to return to BOOTSTRAP
under the new skills and reorganize/improve the paper. This step therefore
supersedes the previous BUILD_AND_EVALUATE route recorded by BOOTSTRAP step
0004. The scientific target remains the user-fixed strong story: `namei_ext` is
a `sched_ext`-style VFS name-resolution extension point between eBPF LSM and
FUSE/custom filesystem ownership, with the design and Linux implementation as a
single systems contribution.

The step objective is to re-enter BOOTSTRAP, remove phase drift from canonical
docs and the paper, run a full writing pass, verify that the RQs and
contribution match user intent, and decide whether the paper is ready to freeze
again for BUILD_AND_EVALUATE.

## EXPERIMENT_GATE

Entry timestamp: 2026-07-14T17:41:51-0700

### Gate Entry And Instruction Alignment

Read at entry:

- `docs/user-instruction.md`
- `docs/questions-for-author.md` if present
- `docs/idea-story.md`
- `docs/design.md`
- `docs/evaluation.md`
- `docs/paper/main.tex` and `docs/paper/sections/*.tex`
- `research/STATE.md`

Alignment with user intent:

- The latest user instruction requires BOOTSTRAP re-entry and paper
  reorganization.
- The fixed RQs remain read-only: RQ1 is expressiveness/sufficiency, RQ2 is
  cost/overhead versus feature-equivalent FUSE, and RQ3 is safety/boundary
  versus custom or stackable filesystem ownership.
- The step must not reopen table-only or materialized-view shootouts as the
  novelty line.
- The paper should keep the strong positive hypothesis and avoid shrinking the
  idea around incomplete prototype evidence.

### Node 001: BOOTSTRAP Re-Entry And Contract Check

Status: completed

Question: does the current paper/canonical frontier already satisfy the latest
BOOTSTRAP request, or does it still contain phase drift that would misroute the
project back to BUILD_AND_EVALUATE prematurely?

Inputs and method: compared the user instruction log with `research/STATE.md`,
`docs/idea-story.md`, `docs/design.md`, `docs/evaluation.md`, and the paper.

Current findings:

- The core story, contribution, and RQ meanings are aligned with the user's
  latest fixed direction.
- Several canonical files still say the contract is frozen for
  BUILD_AND_EVALUATE after step 0004. That is stale after the latest
  BOOTSTRAP re-entry instruction.
- The abstract states that reviewed KVM runs provide RQ evidence. During
  BOOTSTRAP, missing result values may remain as explicit placeholders, but
  that sentence can be misread as a completed-result claim.

Decision: do not change the RQ meanings or central claim. Run WRITE_GATE as a
full `iter-refine-writing` pass focused on phase drift, result-placeholder
truthfulness, and paper organization under the fixed RQs.

Transition: EXPERIMENT_GATE exits with no new literature or empirical node
because the latest instruction does not change the central position or RQ set;
the required work is paper/frontier convergence. WRITE_GATE now runs a full
orchestrated writing pass.

## WRITE_GATE

Entry timestamp: 2026-07-14T17:41:51-0700

### Gate Entry

The orchestrated BOOTSTRAP policy requires full `iter-refine-writing`.
The paper entry snapshot is stored under
`docs/tmp/bootstrap/step-0005-20260714T174151-0700/iter-refine-writing-20260714T174151-0700/entry-snapshot/`.

Round reports are written in
`docs/tmp/bootstrap/step-0005-20260714T174151-0700/iter-refine-writing-20260714T174151-0700/`.

### Node 002: Full Writing Pass

Status: completed

Question: can the paper and canonical frontier express the user-fixed story
without phase drift, result overclaiming, table-only drift, or loss of the
strong RQ/contribution contract?

Inputs and method:

- Ran the full `iter-refine-writing` cycle required for BOOTSTRAP WRITE.
- Used the entry snapshot under
  `docs/tmp/bootstrap/step-0005-20260714T174151-0700/iter-refine-writing-20260714T174151-0700/entry-snapshot/`.
- Wrote round reports `round-0-macro-structure.md` through
  `round-11-meaning-preservation.md` under the same run directory.
- Ran the citation gate with
  `/home/yunwei37/workspace/my-paper-work/academic-writing-skills/skills/check-paper-citations/scripts/verify_bib.py`.
- Ran a read-only Round 11 meaning-preservation subagent and reran it once
  after restorations.

Results:

- The paper now presents `namei_ext` as a `sched_ext`-style VFS
  name-resolution extension point, not a BPF filesystem or table-only
  mechanism.
- RQ meanings are preserved: RQ1 expressiveness/sufficiency, RQ2 cost versus
  feature-equivalent FUSE, and RQ3 ownership/containment versus custom or
  stackable filesystem ownership.
- The contribution remains design plus Linux implementation as one systems
  boundary.
- Evaluation result cells remain explicit placeholders; no unsupported
  completed-result numbers were invented.
- Round 10 citation gate passed: 35 active entries verified by the script, 61
  total BibTeX entries with complete annotation blocks, and no missing/non-yes
  `REAL` annotations.
- Round 11 initially found lost measurement-protocol and RQ3 ownership fields.
  The root restored operation-weighted metric definition, final-run measurement
  protocol, RQ2 metric contract, page-cache preservation, privileged code
  surface, policy code size, conclusion triad, and abstract workload/scope
  anchors. The confirmation audit reported no remaining Must-fix or Should-fix
  findings.

Verification:

- `make -C docs/paper clean paper` succeeded.
- `make -C docs/paper paper` succeeded after the final abstract scope edit.
- `.build/paper/main.pdf` has 15 pages.
- Final log grep found no undefined citation/reference warning, LaTeX error, or
  overfull box.
- Remaining build warnings are underfull boxes and CJK font-script warnings.

Canonical updates:

- Updated `research/STATE.md`, `docs/idea-story.md`, `docs/design.md`,
  `docs/evaluation.md`, `docs/implementation.md`,
  `docs/background-related-work.md`, `docs/paper/evaluation.md`, and
  `docs/questions-for-author.md` so their current-frontier pointers reference
  BOOTSTRAP step 0005 REVIEW_GATE rather than the stale step-0004
  BUILD_AND_EVALUATE freeze.

Decision: WRITE_GATE passes. The paper is ready for REVIEW_GATE, where the
root must audit the scientific contract and a fresh reviewer must run the
outer audit/meta-review before any renewed freeze or BUILD_AND_EVALUATE route.

## REVIEW_GATE

Entry timestamp: 2026-07-15T02:11:37-0700

### Gate Entry And Root Scientific-Contract Audit

Read at entry:

- `docs/user-instruction.md`
- `docs/questions-for-author.md`
- `docs/idea-story.md`
- `docs/design.md`
- `docs/evaluation.md`
- `docs/background-related-work.md`
- `research/STATE.md`
- `docs/paper/main.tex` and `docs/paper/sections/*.tex`
- step-0005 writing round reports

`scripts/check_progress.py` is not present in this repository, so no progress
diagnostic output was available for meta-review input.

Root disposition:

- The newest user instruction asks for BOOTSTRAP re-entry and paper
  reorganization under the new skills.
- The initial narrative, previous step-0004 freeze, and current user-fixed
  direction all support the same central story: a narrow `sched_ext`-style VFS
  name-resolution extension point between eBPF LSM and FUSE/custom filesystem
  ownership.
- No accepted evidence in step 0005 contradicts that story or requires a
  smaller/table-only claim.
- The step-0005 writing pass improved expression and restored lost evidence
  protocol details without changing RQ meanings, contribution, baseline
  families, workload families, or metric meaning.

Disposition: keep the same strong story and send it to independent outer audit.
If the audit accepts it, the correct route is back to BUILD_AND_EVALUATE for
the complete Agent workspace lifecycle experiment, followed by environment/cache
after the required target-selection support and source-oracle admission.

### Node 003: Independent Outer Audit And Meta-Review

Status: completed

Question: did step 0005 solve the right BOOTSTRAP problem, preserve the
ambitious user-fixed story, avoid weak-baseline/table-only drift, and leave a
clear next route?

Inputs and method:

- Fresh independent reviewer read the step report, Round 10 citation report,
  Round 11 meaning-preservation report, current paper sources, canonical docs,
  user instruction log, questions file, and `research/STATE.md`.
- `scripts/check_progress.py` was not present and was recorded as an
  unavailable diagnostic rather than a blocker.
- The audit report is
  `docs/tmp/bootstrap/step-0005-20260714T174151-0700/outer-audit-20260715T021137-0700.md`.

Findings:

- Direction: pass with no blocking defect. The strongest story remains visible
  and faithful: `namei_ext` is a `sched_ext`-style VFS name-resolution
  extension point between access-control hooks and FUSE/custom filesystem
  ownership, not a BPF filesystem or table-only mechanism.
- The paper does not overclaim completed results. It keeps explicit result
  placeholders and states that reviewed KVM source-oracle rows, FUSE
  latency/macro-runtime rows, and ownership/invalid-policy rows are incomplete.
- Efficiency: the step produced a paper decision rather than checker churn.
  Round 11 caught and fixed real meaning drift in measurement protocol and RQ3
  ownership evidence fields.
- Maintenance: canonical docs were broadly aligned. The only nonblocking
  maintenance finding is that `docs/evaluation.md` has accumulated historical
  run detail and should be condensed in a later housekeeping pass.

Root response:

- Accepted the audit recommendation.
- Updated canonical docs from "review pending" to the accepted
  BUILD_AND_EVALUATE route.
- Deferred `docs/evaluation.md` condensation to the next housekeeping pass
  because it is a size/history issue, not a scientific or routing blocker.
- No new `AGENTS.md` rule or repo-local skill is justified by this step.

### REVIEW_GATE Exit And Routing

Status: completed

Decision: BOOTSTRAP step 0005 freezes the current scientific contract again and
routes to BUILD_AND_EVALUATE.

Frozen story:

- `namei_ext` is a `sched_ext`-style VFS name-resolution extension point, not a
  BPF filesystem.
- The contribution is the design and Linux implementation of that extension
  point as one systems boundary.
- RQ1 is expressiveness/sufficiency.
- RQ2 is cost/overhead versus feature-equivalent FUSE.
- RQ3 is verifier-bounded, fail-closed ownership boundary versus custom or
  stackable filesystem ownership.
- Agent workspace and environment/cache are the primary workload families.
  Service/config remains conditional on a concrete lookup-time source oracle.
- Table-only, materialized-view shootouts, and scattered weak baselines remain
  rejected as the novelty line.

Next action: resume BUILD_AND_EVALUATE with the complete Agent workspace
lifecycle experiment. The run must use the real KVM `cgroup/namei_ext` attach
path, same-oracle `namei_ext` and feature-equivalent FUSE rows,
lower-filesystem preservation checks, operation-weighted lookup/readdir traces,
raw results under `results/`, and RQ3 custom/stackable filesystem boundary
evidence.

Remaining nonblocking maintenance:

- Condense `docs/evaluation.md` in a future housekeeping pass by archiving
  historical run detail into the relevant step directory and keeping the
  canonical file focused on the current admitted experiment program.

Completed: 2026-07-15T02:11:37-0700
