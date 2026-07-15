# BOOTSTRAP Step 0003 Report

Timestamp: 2026-07-14T15:58:54-0700
Phase: BOOTSTRAP
Status: completed
Current gate: complete; next phase BUILD_AND_EVALUATE

## Step Objective

Re-enter BOOTSTRAP under the user's latest instruction:

```text
按照新的 skills 重新回到 BOOTSTRAP 阶段, 重新整理完善论文
```

This step starts from the completed BOOTSTRAP step 0002 paper draft rather than
from the paused BUILD_AND_EVALUATE Experiment A repair. The objective is to
make the reader-facing paper and canonical project state consistently express
the strongest current story before any experiment continuation:

- `namei_ext` is a `sched_ext`-style VFS name-resolution extension point;
- the primary contribution is design plus Linux implementation as one systems
  boundary;
- RQ1 is expressiveness/sufficiency;
- RQ2 is overhead versus feature-equivalent FUSE;
- RQ3 is a verifier-bounded, fail-closed ownership boundary versus custom or
  stackable filesystem ownership;
- table-only and scattered materialized-view shootouts remain historical
  diagnostics, not the novelty line.

## Gate Entry And Instruction Alignment

Inputs read at entry:

- `docs/user-instruction.md`;
- `research/STATE.md`;
- `docs/tmp/bootstrap/step-0002-20260713T004618-0700/step-report.md`;
- `docs/tmp/build-and-evaluate/step-0003-20260714T154705-0700/step-report.md`;
- `docs/idea-story.md`;
- `docs/evaluation.md`;
- `docs/design.md`;
- `docs/implementation.md`;
- `docs/background-related-work.md`;
- `docs/paper/main.tex` and `docs/paper/sections/*.tex`.

The entry audit found that the paper had already been reorganized in step 0002,
but canonical state had drifted back to BUILD_AND_EVALUATE. That routing is not
faithful to the latest user request. The current step therefore pauses the
Experiment A protocol repair and restores BOOTSTRAP as the active phase.

## Cleanup Node

Status: completed, pending compile verification and review disposition.

Question: does the current paper/canonical frontier still express the intended
OSDI/SOSP story without premature BUILD_AND_EVALUATE routing or split
contribution framing?

Edits applied:

- `docs/paper/sections/01-introduction.tex`: replaced the split two-item
  contribution list with one primary contribution: the design and Linux
  implementation of `namei_ext` as a single systems boundary. The evaluation is
  now described as the evidence program for that contribution, not a separate
  novelty claim.
- `docs/idea-story.md`: recorded the routing change from renewed
  BUILD_AND_EVALUATE freeze to active BOOTSTRAP re-entry, then after review
  recorded the renewed BUILD_AND_EVALUATE freeze.
- `docs/evaluation.md`: audited the evaluation program as a BOOTSTRAP
  candidate, then restored it as the frozen BUILD_AND_EVALUATE program after
  review, preserving the RQ shape, FUSE baseline, custom/stackable boundary
  comparison, and two-primary-matrix experiment plan.
- `docs/design.md`: audited the design as a BOOTSTRAP candidate proof
  obligation set, then restored it as the frozen BUILD_AND_EVALUATE design
  contract after review.
- `docs/implementation.md`: audited implementation state during BOOTSTRAP
  re-entry while preserving current prototype facts, then restored the phase to
  BUILD_AND_EVALUATE for the next complete-experiment work.
- `research/STATE.md`: changed the active handoff pointer from paused
  BUILD_AND_EVALUATE step 0003 to this BOOTSTRAP step during cleanup, then
  restored BUILD_AND_EVALUATE step 0003 as the next active work after review.
- `docs/background-related-work.md`: updated stale next-action sentences so
  related-work routing matches the completed BOOTSTRAP re-entry and renewed
  BUILD_AND_EVALUATE route.

Scientific impact: no RQ meaning, mechanism claim, workload family, or
comparison family changed. The cleanup is a routing and expression repair. It
makes the current state faithful to the latest instruction while preserving the
strong story created by step 0002.

Rejected actions:

- Did not resume Experiment A protocol repair, because the latest request is
  paper/story re-entry rather than experiment execution.
- Did not reintroduce table-only or materialized-view baselines, because those
  paths are explicitly retired by user instruction.
- Did not edit current skills.

## Verification

Commands run:

```text
make -C docs/paper paper
rg -n 'two primary contributions|Current phase: BUILD_AND_EVALUATE|Orchestrator phase: BUILD_AND_EVALUATE|frozen evaluation' docs/paper docs/idea-story.md docs/evaluation.md docs/design.md docs/implementation.md research/STATE.md
pdfinfo .build/paper/main.pdf | rg '^Pages|^Title|^Creator|^Producer'
rg -n 'undefined|Citation .* undefined|There were undefined references|LaTeX Warning' .build/paper/main.log
```

Results:

- `make -C docs/paper paper` succeeded.
- Current PDF: `.build/paper/main.pdf`.
- Page count: 15.
- Targeted stale-phrase audit returned no matches.
- No undefined citations or undefined references were reported.
- Remaining LaTeX messages are font and underfull-box warnings.

The next action is a BOOTSTRAP review disposition: either freeze this story
again and route back to BUILD_AND_EVALUATE, or run a fresh full WRITE_GATE if
the review finds a scientific or structural writing defect not covered by step
0002's completed `iter-refine-writing` run.

## Current Routing

Independent review completed with no blocking must-fix findings. The reviewer
confirmed that the current paper and canonical docs are broadly faithful to the
user-fixed story:

- active state is BOOTSTRAP re-entry, not active BUILD_AND_EVALUATE;
- the strong story remains a `sched_ext`-style VFS name-resolution extension
  point between eBPF LSM and FUSE/custom filesystem ownership;
- RQs match the fixed meanings for expressiveness/sufficiency, overhead versus
  feature-equivalent FUSE, and verifier-bounded fail-closed boundary versus
  custom/stackable filesystems;
- the primary contribution is design plus Linux implementation;
- table/materialized-view shootouts remain background or archived history;
- final RQ evidence is still pending and not claimed complete.

The only should-fix was stale wording in `research/STATE.md` that said step
0003 was preparing a fresh Make-owned run. That sentence has been changed to
say the next fresh Make-owned run waits until BOOTSTRAP step 0003 records a
reviewed freeze.

Outer audit:
`docs/tmp/bootstrap/step-0003-20260714T155854-0700/outer-audit-20260714T160549-0700.md`

Root disposition: freeze this BOOTSTRAP re-entry cleanup and route back to
BUILD_AND_EVALUATE when work resumes. No fresh full WRITE_GATE is required for
this step because step 0002 already completed the full writing pass and this
review found no structural or scientific blocker.

Next action after this step: resume the complete Agent workspace lifecycle
experiment under BUILD_AND_EVALUATE, starting from the protocol-repair findings
already recorded for the supporting-only matrix run. Do not open table-only,
materialized-view, or scattered-baseline side experiments.

Post-review verification:

```text
make -C docs/paper paper
pdfinfo .build/paper/main.pdf | rg '^Pages'
rg -n 'undefined|Citation .* undefined|There were undefined references|LaTeX Warning' .build/paper/main.log
```

Results:

- The paper target was already up to date.
- Current PDF page count is 15.
- The LaTeX log has no undefined citation or undefined-reference warning.

## Git Publication

No Git mutation has been performed in this step.
