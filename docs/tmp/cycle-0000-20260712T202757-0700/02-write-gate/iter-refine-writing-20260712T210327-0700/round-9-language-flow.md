# Round 9: Language Flow

Timestamp: 20260712T220113-0700

Skill stage: `iter-refine-writing`, round 9.

## Scope

This round checked paragraph flow, old-to-new information order, section order,
and evaluation narrative. It did not change the paper's RQs or evidence model.

## Reviewer Input

The read-only reviewer identified six must-fix flow issues:

- Related Work appeared after Discussion, interrupting the final narrowing before
  the conclusion.
- The introduction used outline/progress-report prose before the contribution
  list.
- The workload-characterization section ended with note-like comparison prose.
- The implementation section ended by jumping into experiment planning.
- The evaluation used "report includes" and "completion criterion" checklist
  language.
- The conclusion ended on evaluation machinery rather than the paper's takeaway.

The reviewer also recommended moving access-control scope after the main design
flow, shortening the `sched_ext` analogy, leading RQ2/RQ3 paragraphs with the
interpretation rather than table bookkeeping, and making related work explain
boundary relevance instead of repeating workload lists.

## Edits Applied

- Reordered the paper body to Evaluation, Related Work, Discussion, Conclusion.
- Rewrote the introduction outline paragraph as an RQ bridge.
- Rewrote the workload-characterization comparison rule as a connected
  paragraph.
- Moved the access-control-denial sentence after the VFS return flow.
- Shortened the `sched_ext` analogy in the design section.
- Rewrote the implementation closing paragraph around implementation closure and
  provenance.
- Replaced RQ1/RQ2/RQ3 checklist language with experiment narratives.
- Rewrote related work agent-filesystem prose to focus on workload-source and
  boundary-comparison roles.
- Rewrote the discussion extension-path paragraph to lead with the boundary.
- Rewrote the conclusion to end on the testable paper claim.

## Files Edited

- `docs/paper/main.tex`
- `docs/paper/sections/01-introduction.tex`
- `docs/paper/sections/02-motivation.tex`
- `docs/paper/sections/03-design.tex`
- `docs/paper/sections/04-implementation.tex`
- `docs/paper/sections/05-evaluation.tex`
- `docs/paper/sections/06-related-work.tex`
- `docs/paper/sections/07-limitations.tex`
- `docs/paper/sections/08-conclusion.tex`

## Validation

- `make -B -C docs/paper` passed.
- Output: `.build/paper/main.pdf`
- PDF length: 16 pages.
- Citation occurrence count remained 29 before this round and was not changed
  by the flow edits.
- Search found no remaining hits for `The paper first`, `report includes`,
  `completion criterion`, `Table~\\ref{tab:safety-boundary} is explanatory`,
  `current prototype consists`, `boundary slots`, `current evidence`, `final
  RQ`, `path-resolution policy`, optional/future deny wording, `mechanism
  gradient`, `unanswered`, `placeholder`, `unresolved`, `this draft`, `remain
  unresolved`, or `will fill`.

## Residual Notes

Underfull hbox warnings remain concentrated in narrow tables and bibliography
formatting. They are layout warnings, not flow errors.
