# Round 5 Consistency

Started: 2026-07-12T23:29:00-0700  
Completed: 2026-07-12T23:30:43-0700  
Phase: BOOTSTRAP  
Step: step-0001-20260712T223808-0700  
Gate: 02-write-gate  
Parent node: round-4-abstract-intro-rebuild  
Status: completed

## Question And Entry

This round checked terminology and information-flow consistency across the
paper. The review focused on whether the abstract, introduction, design,
implementation, evaluation, related work, discussion, and conclusion all
preserve the same BOOTSTRAP story and RQ meanings.

## Inputs And Method

A read-only reviewer invoked `check-terminology-infoflow` in
paper-consistency scope and read:

- `docs/user-instruction.md`
- `docs/idea-story.md`
- all LaTeX under `docs/paper/`

## Raw Review Findings

Must-fix:

- Abstract, Design, Implementation, and Evaluation mixed broad
  registered-target wording with the current prototype's narrower directory
  target coverage.
- Motivation and Evaluation mixed workload status terms: "candidate,"
  "admitted," and "main row."
- The introduction still used final-paper contribution framing for a
  BOOTSTRAP evaluation contract.

Should-fix:

- RQ2 used "FUSE-based policy implementation" instead of the stable
  "feature-equivalent FUSE policy implementation."
- Related Work blurred agent-filesystem workload sources with boundary
  comparisons and mentioned FUSE in RQ3-adjacent text.
- Service/config related-work text sounded like an admitted evaluation row.
- Motivation's "We use reproduced runs" could overstate current evidence.

Consider:

- Rename `07-limitations.tex` to `07-discussion.tex` later.
- Conclusion should say evaluation planning, not completed same-oracle
  evaluation, while BOOTSTRAP evidence is missing.

## Applied Fixes

`docs/paper/main.tex`:

- Narrowed abstract prototype wording to "registered directory-target selection
  actions."

`docs/paper/sections/01-introduction.tex`:

- Changed the contribution lead-in to "This BOOTSTRAP draft is organized around
  three intended contributions."

`docs/paper/sections/02-motivation.tex`:

- Replaced "We use reproduced runs..." with "We distinguish reproduced runs..."
  to avoid overstating evidence status.
- Replaced "separate main rows" with "additional headline candidates."
- Replaced "main row" and "second row" with "headline candidate" and stated
  that candidates are admitted only after a reviewed KVM same-oracle run.

`docs/paper/sections/04-implementation.tex`:

- Standardized the current capability as registered directory-target selection.
- Preserved the explicit BOOTSTRAP gap for final-file target selection.

`docs/paper/sections/05-evaluation.tex`:

- Changed RQ2 wording to "feature-equivalent FUSE policy implementation."
- Standardized workload status around candidates admitted after reviewed KVM
  same-oracle runs and deferred service/config rows.

`docs/paper/sections/06-related-work.tex`:

- Clarified that source systems provide workload oracles, while custom or
  stackable ownership is the RQ3 boundary context and FUSE cost remains RQ2.
- Changed service/config text to "would evaluate ... if a concrete
  lookup-time source oracle is admitted."

`docs/paper/sections/08-conclusion.tex`:

- Changed "same-oracle evaluation" to "same-oracle evaluation planning" for the
  BOOTSTRAP draft.

## Rejected Or Deferred Fixes

- The filename `07-limitations.tex` remains unchanged to avoid nonessential
  file churn in the dirty worktree; the section title and `main.tex` order are
  correct.
- Result-backed contribution and conclusion text are deferred until RQ evidence
  exists.

## Verification

Commands:

```sh
make -B -C docs/paper
pdfinfo /home/yunwei37/workspace/namei_ext/.build/paper/main.pdf | rg '^Pages:'
rg -n 'registered-target|registered target|registered-target selection|main row|second row|This paper makes|FUSE-based policy implementation|We use reproduced|evaluates whether|same-oracle evaluation make|separate main rows|direct cost baselines|service/config systems|table-only|table_redirect|static-table' docs/paper/main.tex docs/paper/sections/*.tex
```

Results:

- `make -B -C docs/paper` completed successfully.
- The PDF remains 14 pages.
- The remaining "registered target" matches are mechanism-level descriptions,
  not broad claims that final-file target selection is implemented.
- No paper-facing table-only/static-table/table_redirect novelty line appears.

## Scientific Impact And Decision

Round 5 removed inconsistent status vocabulary and capability overstatement.
The draft now consistently distinguishes headline candidates, reviewed KVM
admission, deferred service/config breadth, implemented directory-target
selection, and the BOOTSTRAP gap for final-file target selection.

## Completion And Next Action

Round 5 completed. Next node: Round 6 language sentence structure. The next
reviewer should check sentence-level mechanics without changing claims, RQs, or
numbers.
