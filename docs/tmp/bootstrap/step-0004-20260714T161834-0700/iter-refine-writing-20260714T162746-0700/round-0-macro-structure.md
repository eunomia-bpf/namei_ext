# Round 0: Macro Structure

Started: 2026-07-14T16:27:46-0700
Completed: 2026-07-14T16:36:00-0700
Parent step: `docs/tmp/bootstrap/step-0004-20260714T161834-0700/`
Objective: check full-paper macro structure under `check-paper-structure-flow`
Level 1 and apply required fixes without changing scientific meaning.

## Inputs

- Entry snapshot:
  `docs/tmp/bootstrap/step-0004-20260714T161834-0700/iter-refine-writing-20260714T162746-0700/entry-snapshot/`
- Paper source: `docs/paper/main.tex`, `docs/paper/sections/*.tex`,
  `docs/paper/refs.bib`
- Fixed RQs from `docs/user-instruction.md` and `docs/idea-story.md`
- Skill references read by the root:
  `check-paper-structure-flow/SKILL.md`,
  `check-paper-structure-flow/references/full-paper-12p.md`

## Raw Review Findings

Read-only reviewer: subagent `019f62f5-e175-7f92-b985-9a21c40022b4`.

Must-fix:

- The Evaluation section was still a protocol rather than a submission-shaped
  evidence section. RQ1/RQ2/RQ3 existed, but their blocks lacked explicit
  result slots or `unanswered` evidence TODOs.
- Experimental setup and measurement protocol carried workload matrix,
  baseline, and metric details that the RQ blocks did not consume directly.

Should-fix:

- Motivation/source characterization risked reading like a separate
  contribution rather than workload selection evidence.
- Evaluation had an `Interpretation Scope` subsection but no explicit
  evaluation-scope/limitations subsection.
- The page budget is tight at 15 pages.

Consider:

- Design section and section order were macro-structurally sound.

## Applied Fixes

- Reorganized `docs/paper/sections/05-evaluation.tex` so setup now contains
  common execution, correctness, and measurement rules only.
- Added explicit RQ1/RQ2/RQ3 evidence tables:
  `tab:rq1-evidence`, `tab:rq2-evidence`, and `tab:rq3-evidence`.
- Added explicit `Evidence TODO` slots for missing RQ1 pass matrix, RQ2
  latency/macro/FUSE overhead results, and RQ3 boundary/invalid-decision rows.
- Added direct `RQ1 is unanswered`, `RQ2 is unanswered`, and `RQ3 is
  unanswered` conditions tied to the result slots.
- Renamed `Interpretation Scope` to `Evaluation Scope And Limitations`.
- Renamed Motivation's `Source Evidence` subsection to
  `Workload-Selection Evidence`, clarified that source evidence selects
  workloads and oracles rather than forming a standalone contribution, and
  renamed `Representative Workloads` to `Selected Workloads`.

Skipped or deferred:

- Did not shrink Agent workspace or environment/cache claims around current
  prototype gaps.
- Did not remove source context wholesale because the paper needs source
  grounding for workload selection.
- Page-count compression is deferred to later rounds because the current
  priority was adding explicit result slots. The PDF remains 15 pages.

## Verification

Commands:

```text
make -C docs/paper paper
pdfinfo .build/paper/main.pdf | rg '^Pages|^Creator|^Producer'
rg -n 'undefined|Citation .* undefined|There were undefined references|Overfull' .build/paper/main.log
```

Results:

- Build succeeded.
- PDF page count: 15.
- No undefined references, undefined citations, or overfull boxes were present
  in the final log.
- Remaining warnings are font and underfull-box warnings.

## Preservation Check

The fixed RQs were preserved:

- RQ1 remains expressiveness/sufficiency.
- RQ2 remains overhead versus feature-equivalent FUSE.
- RQ3 remains verifier-bounded, fail-closed boundary versus custom or stackable
  filesystems.

The primary contribution remains design plus Linux implementation as one
systems boundary. No table-only or materialized-view mainline was introduced.

Next round: Round 1 micro-structure review.
