# Round 1: Micro Structure

Started: 2026-07-14T18:00:00-0700  
Completed: 2026-07-14T18:13:00-0700

Parent step: `docs/tmp/bootstrap/step-0005-20260714T174151-0700/step-report.md`

## Objective

Check paragraph roles, abstract and introduction roles, topic sentences, RQ
block openings and endings, and whether any writing silently changes the fixed
RQ meanings.

## Review Method

Spawned one read-only subagent to invoke `check-paper-structure-flow` with
Levels 2-3 micro-structure focus. The subagent did not edit files.

## Raw Findings

Must-fix findings:

- The abstract ended with evaluation-plan/status language rather than a result
  or honest placeholder sentence.
- The introduction still presented the evaluation and third contribution as a
  plan-like structure rather than an empirical deliverable.
- RQ blocks opened with the right RQs but ended with decision rules rather than
  explicit answer or unanswered statements.
- Evaluation tables still read as slot tables.
- RQ2 included no-hook/lower rows as if they were a three-way baseline; RQ3 was
  too generic rather than source-oracle tied.

Should-fix findings:

- Motivation included too much methodology-gating language.
- Design goals mixed goals and action model.
- Policy Model repeated definitions from Motivation.
- Prototype coverage wording can create tension with environment/cache
  final-file evidence until the implementation is complete.
- Conclusion used evaluation-plan language.

Consider findings:

- Merge the one-sentence FUSE contrast paragraph in Related Work.
- Make Background's bridge less design-like.
- Rename the RQ3 subsection more neutrally.

## Applied Fixes

- Changed the abstract's final evaluation language to say that the final result
  fields are source-oracle correctness, cost versus feature-equivalent FUSE, and
  ownership-boundary evidence.
- Rewrote the Introduction contribution paragraph as an enumerated deliverable
  list.
- Added explicit `\textbf{Unanswered.}` endings to RQ1, RQ2, and RQ3 blocks.
- Replaced `TBD` and "answer placeholder" table wording with explicit
  `[Result]` fields.
- Clarified that no-hook/lower rows calibrate fixed hook cost only and are not
  RQ2 competing baselines.
- Reworked RQ3's table so rows are source-workload tied: Agent workspace and
  environment/cache, each with `namei`-owned surface, broader filesystem-owned
  surface, and final result field.
- Renamed RQ3 subsection to "Ownership And Containment Boundary."
- Condensed Motivation's source-evidence protocol language.
- Moved action-model content into Policy Model and removed duplicate term
  definitions.
- Changed Background's \namei bridge to a neutral boundary statement.
- Merged the detached FUSE contrast paragraph.
- Rewrote Conclusion to avoid "evaluation centers on" language.

## Rejected Or Deferred Fixes

- Did not invent final result numbers or demote the paper to only currently
  completed partial rows. BOOTSTRAP requires explicit placeholders; final
  answer text must be filled by BUILD_AND_EVALUATE evidence.
- Did not remove environment/cache from the primary hypothesis. The user asked
  not to shrink the story around incomplete implementation evidence.

## Verification

- `make -C docs/paper paper` succeeded.
- Output PDF: `.build/paper/main.pdf`, 15 pages.
- Grep found no remaining `TBD`, `Result slot`, `answer placeholder`,
  `Reviewed KVM`, `evaluation plan`, or `BOOTSTRAP evidence` phrases in the
  paper source.
- Citation-key audit: entry snapshot had 69 cite-key uses and 31 unique keys;
  current paper has 66 cite-key uses and the same 31 unique keys. The removed
  uses were duplicate service/config citations, not lost source families.

## Next Node

Proceed to Round 2 section-conventions review.

