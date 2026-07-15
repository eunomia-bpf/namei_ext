# BOOTSTRAP Step 0003 Paper Re-entry

Date: 2026-07-14

## Motivation

The latest user instruction asks the project to return to BOOTSTRAP under the
new skills and reorganize/improve the paper. The existing paper had already
been reorganized during BOOTSTRAP step 0002, but canonical state files still
described the active route as BUILD_AND_EVALUATE. That mismatch could cause the
next work to continue Experiment A protocol repair before the paper/story
frontier was explicitly accepted again.

## Files Inspected

- `docs/user-instruction.md`
- `research/STATE.md`
- `docs/tmp/bootstrap/step-0002-20260713T004618-0700/step-report.md`
- `docs/tmp/build-and-evaluate/step-0003-20260714T154705-0700/step-report.md`
- `docs/idea-story.md`
- `docs/evaluation.md`
- `docs/design.md`
- `docs/implementation.md`
- `docs/background-related-work.md`
- `docs/paper/main.tex`
- `docs/paper/sections/*.tex`

## Design Choices

The cleanup preserves the step-0002 scientific story rather than shrinking it:
`namei_ext` remains a `sched_ext`-style VFS name-resolution extension point
between eBPF LSM and FUSE/custom filesystem ownership. RQ1 remains
expressiveness/sufficiency, RQ2 remains overhead versus feature-equivalent FUSE,
and RQ3 remains verifier-bounded, fail-closed ownership boundary versus custom
or stackable filesystems.

The main paper-facing change is to state the contribution as one integrated
design-and-implementation contribution. The evaluation is framed as the
evidence program for that contribution, not as a separate workload-survey
contribution.

## Alternatives Rejected

- Continuing BUILD_AND_EVALUATE Experiment A immediately was rejected because
  the latest instruction explicitly asks for BOOTSTRAP paper re-entry.
- Reopening table-only or materialized-view experiments was rejected because
  user instructions retire those as the novelty line.
- Running a new full experiment was rejected for this step because it would not
  answer the current paper/story cleanup request.

## Implementation Details

The cleanup updated:

- `docs/paper/sections/01-introduction.tex`;
- `docs/idea-story.md`;
- `docs/evaluation.md`;
- `docs/design.md`;
- `docs/implementation.md`;
- `research/STATE.md`;
- `docs/background-related-work.md`;
- `docs/tmp/bootstrap/step-0003-20260714T155854-0700/step-report.md`.

## Validation Performed

Commands run:

```text
make -C docs/paper paper
rg -n 'two primary contributions|Current phase: BUILD_AND_EVALUATE|Orchestrator phase: BUILD_AND_EVALUATE|frozen evaluation' docs/paper docs/idea-story.md docs/evaluation.md docs/design.md docs/implementation.md research/STATE.md
pdfinfo .build/paper/main.pdf | rg '^Pages|^Title|^Creator|^Producer'
rg -n 'undefined|Citation .* undefined|There were undefined references|LaTeX Warning' .build/paper/main.log
```

Results:

- The paper compiled successfully.
- The current PDF is `.build/paper/main.pdf`.
- The PDF has 15 pages.
- The stale-phrase audit returned no matches.
- No undefined citation or undefined-reference warning was found in the LaTeX
  log.

## Remaining Risks

This is a scoped BOOTSTRAP cleanup, not a fresh complete WRITE_GATE. Step 0002
already ran a full writing refinement pass, but step 0003 still needs a review
disposition. If that review finds structural paper defects, the next BOOTSTRAP
action should run a fresh full writing pass rather than returning directly to
BUILD_AND_EVALUATE.

## Review Disposition

Independent review completed in
`docs/tmp/bootstrap/step-0003-20260714T155854-0700/outer-audit-20260714T160549-0700.md`.
It found no blocking must-fix issues. The one actionable should-fix in
`research/STATE.md` was applied. The root disposition is to freeze this
BOOTSTRAP re-entry cleanup and return to BUILD_AND_EVALUATE for the complete
Agent workspace lifecycle experiment.
