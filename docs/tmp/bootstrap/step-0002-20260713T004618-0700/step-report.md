# BOOTSTRAP Step 0002 Report

Timestamp: 2026-07-13T00:46:18-07:00
Phase: BOOTSTRAP
Status: completed
Current gate: complete; next phase BUILD_AND_EVALUATE

## Step Objective

Re-enter BOOTSTRAP under the current `auto-research-orchestrator` rules after
the user explicitly instructed: `按照新的 skills 重新回到 BOOTSTRAP 阶段`.

The purpose of this step is to re-pressure the paper's scientific contract
before any renewed BUILD_AND_EVALUATE work: problem, claim, RQs, workload
coverage, baseline families, contribution shape, design goals, evaluation
promise, and related-work positioning.

## Completed Nodes

- Recovery node:
  `docs/tmp/bootstrap/step-0002-20260713T004618-0700/000-recovery-bootstrap-reentry-20260713T004618-0700.md`
- Canonical frontier alignment:
  `docs/tmp/bootstrap/step-0002-20260713T004618-0700/001-canonical-frontier-alignment-20260713T004618-0700.md`
- EXPERIMENT_GATE entry:
  `docs/tmp/bootstrap/step-0002-20260713T004618-0700/01-experiment-gate/000-gate-entry-20260713T004618-0700.md`
- Literature/novelty/workload/baseline pressure:
  `docs/tmp/bootstrap/step-0002-20260713T004618-0700/01-experiment-gate/literature-20260713T005632-0700/001-claim-novelty-workload-baseline-pressure-20260713T005632-0700.md`
- Standalone Phase 1 record:
  `docs/tmp/2026-07-13-bootstrap-step-0002-literature-pressure.md`
- Independent EXPERIMENT_GATE audit:
  `docs/tmp/bootstrap/step-0002-20260713T004618-0700/01-experiment-gate/990-independent-outer-audit-20260713T011900-0700.md`
- EXPERIMENT_GATE report:
  `docs/tmp/bootstrap/step-0002-20260713T004618-0700/01-experiment-gate/999-gate-report-20260713T012400-0700.md`
- Standalone EXPERIMENT_GATE record:
  `docs/tmp/2026-07-13-bootstrap-step-0002-experiment-gate-report.md`
- WRITE_GATE entry:
  `docs/tmp/bootstrap/step-0002-20260713T004618-0700/02-write-gate/000-gate-entry-20260713T012400-0700.md`
- WRITE_GATE full writing refinement:
  `docs/tmp/bootstrap/step-0002-20260713T004618-0700/02-write-gate/iter-refine-writing-20260714T143346-0700/`
- REVIEW_GATE outer audit and meta-review:
  `docs/tmp/bootstrap/step-0002-20260713T004618-0700/outer-audit-20260714T154246-0700.md`

## Current Routing

BOOTSTRAP step 0002 is complete. The previous BUILD_AND_EVALUATE route and
Agent workspace Loop 002 remain historical; this step refroze the scientific
contract after renewed EXPERIMENT_GATE, full WRITE_GATE, and REVIEW_GATE. Prior
KVM, FUSE, source-reproduction, literature, and writing artifacts remain
available as feasibility or supporting evidence, but final RQ answers require
fresh BUILD_AND_EVALUATE admission, full execution, and result review under the
renewed contract.

The frozen story is:

- `namei_ext` is a `sched_ext`-style VFS name-resolution extension point
  between eBPF LSM and FUSE/custom filesystem ownership;
- RQ1 asks expressiveness/sufficiency for real state-dependent path-view
  policies without taking over filesystem semantics;
- RQ2 asks overhead versus feature-equivalent FUSE;
- RQ3 asks for a narrower verifier-bounded, fail-closed ownership boundary
  versus custom or stackable filesystem ownership;
- table-only/static-table diagnostics are historical context, not the novelty
  line;
- scattered weak baselines and partial runs are not the paper evidence shape.

The literature pressure node found no same-claim blocker, but it made
ExtFUSE/FUSE-BPF explicit closest mechanism pressure and reaffirmed that the
main evaluation should be two deep complete experiments, not table-only
diagnostics or scattered baselines.

The next phase is BUILD_AND_EVALUATE. The first target is the complete admitted
Agent workspace lifecycle experiment. Environment/cache remains a primary
workload target, with file-object evidence gated on final-file target
selection.

## WRITE_GATE Completion

Timestamp: 2026-07-14T14:33:46-0700 through 2026-07-14T15:37:14-0700
Gate: 02-write-gate
Status: completed; reviewed in REVIEW_GATE below

### Entry And Alignment

The gate used the accepted BOOTSTRAP contract from the EXPERIMENT_GATE:

- `namei_ext` is a `sched_ext`-style VFS name-resolution extension point, not a
  BPF filesystem.
- One bounded eBPF decision function handles lookup and directory enumeration.
- The kernel and lower filesystem retain VFS object, permission, file-method,
  data-path, write, page-cache, persistence, and consistency ownership.
- RQ1 is expressiveness/sufficiency.
- RQ2 is overhead versus feature-equivalent FUSE.
- RQ3 is verifier-bounded, fail-closed ownership boundary versus custom or
  stackable filesystem ownership.
- The main evaluation shape is two complete matrices: Agent workspace lifecycle
  and environment/cache transition. Service/config remains conditional.

The gate treated `docs/user-instruction.md`, the accepted
`docs/idea-story.md` frontier, and the EXPERIMENT_GATE report as scientific
authority. Writing rounds expressed that contract but did not change the RQ
meanings or reintroduce the earlier table-only novelty line.

### Writing Node Record

The active child loop was a full `iter-refine-writing` run:

`docs/tmp/bootstrap/step-0002-20260713T004618-0700/02-write-gate/iter-refine-writing-20260714T143346-0700/`

Round reports:

- Round 0 macro structure:
  `.../round-0-macro-structure.md`
- Round 1 micro structure:
  `.../round-1-micro-structure.md`
- Round 2 section conventions:
  `.../round-2-section-conventions.md`
- Round 3 logic flow:
  `.../2026-07-14-round-3-logic-flow.md`
- Round 4 abstract/introduction:
  `.../2026-07-14-round-4-abstract-introduction.md`
- Round 5 consistency:
  `.../2026-07-14-round-5-consistency.md`
- Round 6 language, sentence structure:
  `.../2026-07-14-round-6-language-sentence.md`
- Round 7 language, word choice:
  `.../2026-07-14-round-7-language-word.md`
- Round 8 terminology and claim tone:
  `.../2026-07-14-round-8-terminology-claim-tone.md`
- Round 9 language flow:
  `.../2026-07-14-round-9-language-flow.md`
- Round 10 citation gate:
  `.../2026-07-14-round-10-citations.md`
- Round 11 meaning preservation:
  `.../2026-07-14-round-11-meaning-preservation.md`

The expected `entry-snapshot/` directory was missing for this recovered run.
Round 11 therefore used `git show HEAD:docs/paper/...` plus the completed
Round 0--10 reports as the baseline. This is recorded as a process risk in the
Round 11 report and should not be repeated in a fresh writing invocation.

### Paper Impact

The paper draft now has a single reader-facing story:

- `namei_ext` is a narrow VFS name-resolution extension point in the design
  space between namespace materialization, eBPF LSM, and FUSE/custom filesystem
  ownership.
- The contribution is the design and Linux implementation together: one eBPF
  decision function, the real `cgroup/namei_ext` attach path, and kernel
  validation for bounded lookup/readdir actions.
- Evaluation is organized by three RQs: expressiveness/sufficiency, cost versus
  feature-equivalent FUSE, and verifier-bounded fail-closed boundary versus
  custom or stackable filesystems.
- Agent workspace lifecycle and environment/cache transition are the two main
  experiment matrices; service/config is conditional on a concrete lookup-time
  source oracle.
- Environment/cache file-object evidence is explicitly gated on final-file
  target selection, so the paper no longer overclaims completed evidence for
  that row.
- Table-only and materialized-view shootouts are no longer the novelty line.
  Materialization, LSM, native mechanisms, FUSE, ExtFUSE, FUSE-BPF, Bento,
  Wrapfs, DeltaFS, IndexFS, and TableFS are positioned as related work or
  boundary pressure rather than a scattered baseline list.

### Verification

Commands run:

```text
make -C docs/paper paper
pdfinfo /home/yunwei37/workspace/namei_ext/.build/paper/main.pdf | rg '^Pages'
perl -0ne '...' docs/paper/main.tex
rg -n 'undefined|Citation .* undefined|There were undefined references|LaTeX Warning' .build/paper/main.log
```

Results:

- `make -C docs/paper paper` succeeded.
- Current PDF: `.build/paper/main.pdf`.
- Page count: 15.
- Abstract word count: 240.
- No undefined citations or references were reported.
- The only remaining LaTeX messages are font/underfull-box warnings.

### Remaining Risks And Next Gate

This writing gate produced a stronger and cleaner BOOTSTRAP draft, not final RQ
answers. Missing evidence remains:

- final KVM same-oracle runs for admitted workloads;
- feature-equivalent FUSE correctness and overhead rows for RQ2;
- reviewed RQ3 boundary accounts under the same source oracles;
- final-file target selection before environment/cache file-object evidence can
  be reported as completed.

Next action at the time of WRITE_GATE completion was REVIEW_GATE for an
independent outer audit and meta-review.

## REVIEW_GATE Completion

Timestamp: 2026-07-14T15:42:46-0700
Gate: 03-review-gate
Status: completed

Outer audit:
`docs/tmp/bootstrap/step-0002-20260713T004618-0700/outer-audit-20260714T154246-0700.md`

The independent reviewer returned pass-with-fixes. The root accepted and
applied both must-fixes:

- paper wording that implied completed reviewed KVM runs now uses
  admission/reporting obligation language;
- `docs/idea-story.md` now separates the primary contribution
  (design plus implementation) from the evidence program.

The root also accepted the should-fix wording change in `docs/evaluation.md`,
replacing "cheaper" and "safer/narrower" with "lower overhead than
feature-equivalent FUSE" and "narrower verifier-bounded, fail-closed ownership
boundary."

Validation after the fixes:

- `make -C docs/paper paper` succeeded.
- Current PDF: `.build/paper/main.pdf`.
- Page count: 15.
- No undefined citations or references were reported.
- Targeted grep confirmed that the reviewer-identified stale paper phrasing and
  canonical contribution drift were removed.

Root disposition: freeze the BOOTSTRAP step 0002 scientific contract and route
to BUILD_AND_EVALUATE. Missing result values are not a writing defect; they are
the next phase's work. The next admitted experiment should be the complete
Agent workspace lifecycle matrix, not another scattered baseline or table-only
diagnostic.

## Git Publication

No Git mutation has been performed. This step is complete but unpublished
because repository instructions require explicit git-mutation authorization and
scope inspection before staging, committing, or pushing.
