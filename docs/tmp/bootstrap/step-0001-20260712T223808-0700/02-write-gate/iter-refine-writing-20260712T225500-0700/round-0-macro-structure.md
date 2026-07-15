# Round 0 Macro Structure

Started: 2026-07-12T22:55:00-0700  
Completed: 2026-07-12T23:07:25-0700  
Phase: BOOTSTRAP  
Step: step-0001-20260712T223808-0700  
Gate: 02-write-gate  
Parent node: 000-gate-entry-20260712T225200-0700  
Status: completed

## Question And Entry

This round ran the Round 0 macro-structure check required by
`iter-refine-writing` inside the BOOTSTRAP WRITE gate. The paper already had
the accepted three RQs, so writing refinement was allowed to reorganize and
express the current story but not to change RQ meaning.

The objective was to make the draft read like a systems paper around the
current BOOTSTRAP hypothesis:

- `namei_ext` is a `sched_ext`-style VFS name-resolution extension point, not a
  BPF filesystem.
- RQ1 is expressiveness/sufficiency at the narrow VFS boundary.
- RQ2 is cost/overhead against feature-equivalent FUSE under the same oracle.
- RQ3 is safety and boundary value against custom or stackable filesystems.
- Table-only/static-table/materialized-namespace arguments are retired from
  the main novelty line.

## Inputs And Method

Files read or checked:

- `docs/user-instruction.md`
- `docs/idea-story.md`
- `docs/background-related-work.md`
- `docs/design.md`
- `docs/implementation.md`
- `docs/evaluation.md`
- `research/STATE.md`
- `docs/paper/main.tex`
- `docs/paper/sections/01-introduction.tex`
- `docs/paper/sections/02-background.tex`
- `docs/paper/sections/02-motivation.tex`
- `docs/paper/sections/03-design.tex`
- `docs/paper/sections/04-implementation.tex`
- `docs/paper/sections/05-evaluation.tex`
- `docs/paper/sections/06-related-work.tex`
- `docs/paper/sections/07-limitations.tex`
- `docs/paper/sections/08-conclusion.tex`

The Round 0 reviewer checked macro section order, design/implementation
separation, overview figure presence, Evaluation RQ organization, subsection
balance, and page shape.

## Raw Review Findings

Must-fix:

- The draft was 16 pages before this WRITE-gate cleanup and still too long
  after the first pass. It needed to move toward a 12--14 page systems-paper
  shape without adopting a venue template prematurely.
- The main section order placed Related Work before Discussion. The expected
  paper order is Evaluation, Discussion, Related Work, Conclusion.
- Evaluation was mostly a planned experiment description. Each RQ block needed
  an explicit current-status statement that the RQ is unanswered in BOOTSTRAP
  and a concise evidence TODO.

Should-fix:

- The design figure was a boxed text table rather than a compact architecture
  or dataflow view.
- Implementation duplicated action-set and prototype-coverage details.
- Motivation contained dense characterization tables that made source evidence
  look like final RQ evidence.
- Evaluation listed too many metrics and baseline fragments, creating the same
  weak-baseline drift that the current user instructions rejected.

Consider:

- Rename `07-limitations.tex` to `07-discussion.tex` later. This was deferred
  to avoid broad file churn in a dirty worktree.
- Keep Evaluation gaps in Evaluation and broader implication/scope text in
  Discussion.

## Applied Fixes

`docs/paper/main.tex`:

- Reordered the paper so Discussion comes before Related Work.
- Kept the current paper entrypoint and did not switch venue templates.
- Wrapped the bibliography in `{\small ...}` to reduce draft page pressure.

`docs/paper/sections/02-motivation.tex`:

- Removed the dense source-characterization tables from the paper-facing text.
- Rewrote source evidence as concise prose grouped by agent/workspace,
  environment/cache, and conditional service/config source families.
- Kept the evidence-class distinction between reproduced runs, source
  inspection, selected replays, and paper-derived oracles.

`docs/paper/sections/03-design.tex`:

- Replaced the boxed text figure with a compact dataflow/ownership diagram.
- Made the design boundary explicit: eBPF chooses bounded name-resolution
  actions; the kernel and lower filesystem keep object and data semantics.
- Preserved the `sched_ext`-style separation between programmable policy and
  subsystem ownership.

`docs/paper/sections/04-implementation.tex`:

- Compressed repeated action-set language.
- Separated implemented prototype coverage from remaining coverage boundaries.
- Preserved the real `cgroup/namei_ext` KVM attach-path requirement.

`docs/paper/sections/05-evaluation.tex`:

- Replaced the old four-RQ evaluation plan with the current three-RQ structure.
- Added explicit BOOTSTRAP current-status paragraphs for RQ1, RQ2, and RQ3.
- Collapsed scattered metric and baseline lists into one same-oracle evaluation
  contract.
- Kept FUSE as the RQ2 comparison and custom/stackable filesystems as the RQ3
  safety/boundary comparison.
- Removed table-only/static-table/materialized-namespace comparison from the
  main experiment line.

## Rejected Or Deferred Fixes

- Venue-template migration was deferred. The paper is still an article-class
  draft; switching templates is a later formatting decision and should not be
  mixed with BOOTSTRAP meaning and structure cleanup.
- Renaming `07-limitations.tex` was deferred. The section title is now
  `Discussion`, and the input order is correct, so the filename mismatch is
  harmless for this round.
- No new result numbers were added. The paper remains in BOOTSTRAP, and the
  RQ blocks honestly mark required evidence as unanswered.

## Verification

Commands:

```sh
make -B -C docs/paper
pdfinfo /home/yunwei37/workspace/namei_ext/.build/paper/main.pdf | rg '^Pages:'
rg -n 'table_redirect|static table|redirect table|table-only|static-table|BUILD_AND_EVALUATE|Current status' docs/paper docs/idea-story.md docs/design.md docs/evaluation.md docs/implementation.md research/STATE.md docs/background-related-work.md
```

Results:

- `make -B -C docs/paper` completed successfully.
- The PDF is 13 pages.
- Active paper text contains the three intended `Current status` paragraphs in
  Evaluation.
- The remaining `table-only` and `table_redirect` references in canonical docs
  are retirement/history statements, not active paper novelty or experiment
  claims.

LaTeX still reports underfull hbox warnings in the compact design and
evaluation prose. They do not block this macro-structure round.

## Scientific Impact And Decision

Round 0 strengthens the draft by making the story larger and cleaner rather
than smaller. The paper now presents `namei_ext` as a VFS extension-point
boundary, not as a table-only counterexample exercise. It also avoids a weak
baseline matrix by organizing evidence around the three load-bearing RQs:
expressiveness at the boundary, cost against FUSE, and safety/boundary value
against custom or stackable filesystems.

This round does not answer any RQ. It prepares a BOOTSTRAP paper shape in which
missing results are explicit placeholders and source characterization is not
overinterpreted as final RQ evidence.

## State Updates

- Paper macro order and Evaluation RQ organization were updated.
- No user instructions were changed.
- No Git operation was performed.

## Completion And Next Action

Round 0 completed. Next node: Round 1 micro structure. The next reviewer should
check paragraph roles, abstract and introduction roles, topic sentences, one
idea per paragraph, and whether every RQ block opens with the RQ and closes
with an honest BOOTSTRAP evidence placeholder.
