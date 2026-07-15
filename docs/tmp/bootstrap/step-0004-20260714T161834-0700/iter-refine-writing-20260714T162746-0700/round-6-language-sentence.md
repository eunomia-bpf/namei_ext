# Round 6: Language, Sentence Structure

## Skill Route

- `iter-refine-writing`, round 6.
- Reviewer scope: `paper-writing-style`, sentence-structure focus.
- Review mode: read-only subagent; main agent applied fixes.

## Findings

The reviewer found six sentence-structure must-fixes:

1. Semicolons joining independent clauses in the abstract and evaluation.
2. Unlabeled colon lists in design and conclusion.
3. Note-like prose in background, motivation, and evaluation tables.
4. A long RQ3 safety sentence that combined verifier, validation, failure, and
   lower-filesystem preservation in one sentence.

The reviewer also suggested smoothing a related-work paragraph and preserving
the contribution paragraph unless page budget permits a longer split.

## Fixes Applied

- Split the abstract's service/config sentence from the matrix sentence.
- Rewrote the VFS background paragraph so lookup selection and lower-FS
  ownership flow as one contrast rather than as short notes.
- Rewrote source-evidence and comparison-rule paragraphs in Motivation.
- Converted the design-goal and conclusion colon lists to explicit numbered
  lists.
- Rewrote RQ1 and RQ2 table cells to avoid `oracle:` and semicolon-note style.
- Split the RQ3 safety sentence into verifier/kernel-validation and fail-closed
  lower-filesystem-preservation sentences.
- Smoothed the Agent workload related-work paragraph.

The contribution paragraph's semicolons were retained because they separate an
explicit numbered list and preserve compactness.

## Validation

- Ran `make -C docs/paper paper`.
- Result: build succeeded and produced `.build/paper/main.pdf`.
- Checked `.build/paper/main.log` for undefined citations/references, overfull
  boxes, and LaTeX warnings. None of those targeted failures were present.
- Known warnings remain fontspec CJK warnings and underfull hbox warnings.
- Page count after this round: 16 pages.
