# Round 9: Language, Flow And Polish

## Skill Route

- `iter-refine-writing`, round 9.
- Reviewer scope: `paper-writing-style`, flow and polish focus.
- Review mode: read-only subagent; main agent applied fixes.

## Findings

The reviewer found that several sections still read like project-status prose:

1. The abstract ended on evaluation organization rather than evidence.
2. The Evaluation opening described source-characterization bookkeeping rather
   than the evidence rule for answering RQs.
3. Evaluation tables used `Evidence TODO`, and closure paragraphs used
   imperative `fill` wording.
4. The RQ3 opening used defensive negative phrasing before stating the positive
   ownership-boundary claim.

The reviewer also suggested splitting the contribution paragraph, simplifying
Motivation's evidence paragraph, tightening the Implementation closing
paragraph, improving the conclusion ending, spelling out `lower-filesystem`,
and smoothing the Related Work opening.

## Fixes Applied

- Rewrote the abstract ending to state that reviewed KVM runs provide RQ1/RQ2/RQ3
  evidence.
- Rewrote the Evaluation opening around the source-oracle rule, same-correctness
  rows, and boundary responsibility accounts.
- Replaced table `Evidence TODO` labels with `Result slot`.
- Replaced imperative result-slot closures with paper-facing descriptions of
  what each result slot reports.
- Rewrote RQ3 to state the positive ownership-boundary comparison before
  verifier and fail-closed details.
- Split the contribution paragraph into a primary-contribution sentence and
  three concrete contributions.
- Simplified Motivation's evidence paragraph.
- Tightened the Implementation closing paragraph to a single mechanism path.
- Expanded `lower-FS` to `lower-filesystem`.
- Split the Related Work opening so \namei's boundary is in the stress
  position.
- Rewrote the conclusion to center on three claims rather than on filling
  result slots.

## Validation

- Ran `make -C docs/paper paper`.
- Result: build succeeded and produced `.build/paper/main.pdf`.
- Checked `.build/paper/main.log` for undefined citations/references, overfull
  boxes, and LaTeX warnings. None of those targeted failures were present.
- Confirmed no `Evidence TODO`, `Unanswered`, `current draft`, or `lower-FS`
  prose remains in the paper sources.
- Known warnings remain fontspec CJK warnings and underfull hbox warnings.
- Page count after this round: 16 pages.
