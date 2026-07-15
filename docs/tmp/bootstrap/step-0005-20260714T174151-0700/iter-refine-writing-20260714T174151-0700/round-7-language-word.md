# Round 7: Language, Word Choice

Started: 2026-07-15T00:53:00-0700  
Completed: 2026-07-15T01:08:00-0700

Parent step: `docs/tmp/bootstrap/step-0005-20260714T174151-0700/step-report.md`

## Objective

Check word choice, jargon inflation, nominalizations, vague referents, redundant
hedging, and weak phrases without changing scientific claims, RQs, citations, or
result placeholders.

## Review Method

Spawned one read-only subagent to invoke `paper-writing-style` with word-choice
focus. The subagent did not edit files.

## Raw Findings

The review reported eight must-fix items, seven should-fix items, and three
consider items. The most important issues were project-report phrasing such as
"result slots" and "Final answer field," inflated terms such as "surface" and
"direct context," and repeated "boundary" wording.

## Applied Fixes

- Replaced "result slots" in the abstract and conclusion with evaluation-table
  or evidence-needed phrasing.
- Replaced "The result structure follows..." with "The evaluation follows this
  ownership split."
- Replaced "same-oracle evaluation structure" with "an evaluation that uses the
  same source oracle..."
- Replaced "This evidence filter leaves..." with "This source filter selects..."
- Renamed Evaluation table columns from "Final answer field" and
  "policy/lower-FS/extra surface" to result-evidence and responsibility wording.
- Rewrote `Unanswered` sentences to avoid status-update wording.
- Replaced vague phrases: "machinery that owns filesystem objects," "can be
  enough," "workload-derived requirements imply," "single mechanism path,"
  "direct context," and "right boundary."
- Removed a duplicated Related Work sentence introduced during the previous
  patch.

## Verification

- `make -C docs/paper paper` succeeded.
- Output PDF: `.build/paper/main.pdf`, 15 pages.
- Grep found no remaining targeted phrases: `result slots`,
  `Final answer field`, `final answer awaits`, `policy surface`,
  `lower-FS surface`, `extra surface`, `This evidence filter`, `can be enough`,
  `machinery that owns filesystem objects`, `workload-derived requirements
  imply`, `single mechanism path`, `direct context`, `right boundary`, or
  `Final-file`.

## Next Node

Proceed to Round 8 terminology and claim-tone review.

