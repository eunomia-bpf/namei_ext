# Round 1 Micro Structure

Started: 2026-07-12T23:08:00-0700  
Completed: 2026-07-12T23:13:21-0700  
Phase: BOOTSTRAP  
Step: step-0001-20260712T223808-0700  
Gate: 02-write-gate  
Parent node: round-0-macro-structure  
Status: completed

## Question And Entry

This round ran the `iter-refine-writing` Round 1 micro-structure check. The
fixed scientific meaning was read-only: `namei_ext` is a `sched_ext`-style VFS
name-resolution extension point; RQ1 is expressiveness/sufficiency; RQ2 is cost
versus feature-equivalent FUSE; RQ3 is safety and boundary value versus custom
or stackable filesystems; table-only/static-table novelty remains retired.

## Inputs And Method

A read-only reviewer invoked `check-paper-structure-flow` with focus on Levels
2--3 micro structure. The reviewer read `docs/user-instruction.md`,
`docs/idea-story.md`, and the current LaTeX paper under `docs/paper/`.

The review checked paragraph roles, abstract and introduction role coverage,
topic sentences, one idea per paragraph, RQ block closure, and story drift.

## Raw Review Findings

Must-fix:

- The abstract and contribution #3 described the evaluation as if it were a
  completed deliverable, while Evaluation honestly says all RQs are unanswered
  in BOOTSTRAP.
- RQ3 reintroduced FUSE into the safety/boundary account, blurring the fixed
  split where RQ2 owns FUSE cost and RQ3 owns custom/stackable filesystem
  boundary.
- The introduction jumped from insight to system without a challenge paragraph,
  making the extension point look obvious.

Should-fix:

- The Design overview paragraph mixed figure reference, operation flow, action
  set, and exclusions.
- Motivation's Source Evidence paragraph compressed too many source systems and
  transitions into one paragraph.
- Implementation's replacement-component paragraph combined redirect, hide, and
  registered-target validation.
- RQ blocks closed honestly but did not use visually standardized BOOTSTRAP
  status language.

Consider:

- Discussion mostly restated scope. Add or preserve a forward-looking extension
  path paragraph.
- Conclusion will need a result-backed final sentence after experiments exist.

## Applied Fixes

`docs/paper/main.tex`:

- Changed the abstract from "The evaluation tests" to "The evaluation program
  tests" so it does not imply completed RQ evidence.

`docs/paper/sections/01-introduction.tex`:

- Added a challenge paragraph naming the three hard parts: bounded
  expressiveness, lower-filesystem preservation, and same-oracle comparison
  against FUSE/custom filesystem boundaries.
- Revised the system paragraph so it answers those constraints with one
  decision function, bounded actions, and kernel validation.
- Changed contribution #3 from a completed evaluation structure to a
  correctness-first evidence program that will evaluate the three fixed RQs.

`docs/paper/sections/05-evaluation.tex`:

- Standardized RQ closures to `Status: unanswered in BOOTSTRAP.` plus
  `Evidence TODO: ...`.
- Removed FUSE from RQ3's boundary account. RQ3 now compares `namei_ext`
  against custom or stackable filesystem ownership; FUSE remains in RQ2.

`docs/paper/sections/03-design.tex`:

- Split the overview into boundary decision, lookup/readdir flow, and action
  set/exclusion paragraphs.

`docs/paper/sections/02-motivation.tex`:

- Split Source Evidence by source family: agent/workspace, environment/cache,
  and conditional service/config.

`docs/paper/sections/04-implementation.tex`:

- Split redirect validation, hide behavior, and registered-target validation
  into separate paragraphs.

`docs/paper/sections/07-limitations.tex`:

- No change was needed for the Consider item because the section already has an
  `Extension Path` paragraph after Round 0.

`docs/paper/sections/08-conclusion.tex`:

- Deferred the result-sentence change. The experiments do not yet exist, and
  adding a result-backed sentence in BOOTSTRAP would fabricate evidence.

## Verification

Commands:

```sh
make -B -C docs/paper
pdfinfo /home/yunwei37/workspace/namei_ext/.build/paper/main.pdf | rg '^Pages:'
rg -n 'Status: unanswered|Evidence TODO|evaluation structure|The evaluation tests this boundary|FUSE places policy|table_redirect|table-only|static-table' docs/paper docs/idea-story.md docs/evaluation.md docs/design.md docs/implementation.md research/STATE.md docs/background-related-work.md
```

Results:

- `make -B -C docs/paper` completed successfully.
- The PDF remains 13 pages.
- Evaluation now has standardized BOOTSTRAP status closures for all three RQs.
- The old "evaluation structure" phrase and RQ3 FUSE boundary mix no longer
  appear in the paper.
- Remaining `table-only`/`table_redirect` references are retirement/history
  notes in canonical docs, not paper-facing novelty or experiment claims.

## Scientific Impact And Decision

Round 1 improves micro flow without changing the fixed RQs. The paper now more
clearly separates completed contributions from BOOTSTRAP evidence TODOs, and it
preserves the intended RQ split: FUSE cost in RQ2, custom/stackable filesystem
boundary in RQ3.

## Completion And Next Action

Round 1 completed. Next node: Round 2 section conventions. The next reviewer
should check abstract word count and structure, introduction roles, design-goals
paragraphs, explicit RQ-organized Evaluation, related-work grouping, and
conclusion structure.
