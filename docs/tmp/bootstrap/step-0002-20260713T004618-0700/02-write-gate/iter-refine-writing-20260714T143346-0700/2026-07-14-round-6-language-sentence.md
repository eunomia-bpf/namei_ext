# Round 6: Language, Sentence Structure

## Skill Step

`iter-refine-writing` round 6: sentence-structure pass. A read-only subagent
invoked `paper-writing-style` with sentence-structure focus.

## Raw Findings

### Must-Fix

1. `sections/03-design.tex`: the opening design invariants used a colon before
   an unlabeled list and semicolons between independent clauses.
2. `sections/02-motivation.tex`: source-evidence strength used semicolons
   between independent clauses.
3. `sections/05-evaluation.tex`: the RQ3 safety definition used a colon before
   an explanatory list.

### Should-Fix

1. `main.tex`: abstract root-cause sentence used a colon before an explanation.
2. `sections/01-introduction.tex`: weak `It is` opening.
3. `sections/01-introduction.tex`: colon before the state-dependent path-view
   definition.
4. `sections/05-evaluation.tex`: semicolon in the environment/cache table cell.
5. `sections/06-related-work.tex`: colon before a boundary explanation.

### Consider

1. `sections/02-motivation.tex`: ambiguous `it` in the opening workload-pattern
   sentence.
2. `sections/02-motivation.tex`: weak `This filter` opening.
3. `sections/06-related-work.tex`: two short note-like sentences in the source
   workload systems paragraph.

## Fixes Applied

- Rewrote the design invariant sentence as an explicit numbered sentence.
- Split or connected semicolon-linked independent clauses in Motivation,
  Evaluation, Introduction, and Related Work.
- Replaced colon-definition patterns with comma or causal wording.
- Replaced the weak `It is` and `This filter` openings.
- Clarified the ambiguous `it` in the Motivation opening.
- Smoothed note-like Related Work prose.
- Also cleaned remaining semicolons in tables/captions found by the local
  follow-up check, and normalized `Lower-FS` to `Lower-filesystem`.

## Validation

- `make -C docs/paper paper` passed.
- The generated PDF is `/home/yunwei37/workspace/namei_ext/.build/paper/main.pdf`.
- Abstract length is 249 words.
- Page count remains 15.
- Targeted grep no longer matches semicolons, weak `It is`/`There is` starts,
  `This filter`, `lower-FS`, `registered target-selection`,
  `stacked-filesystem`, or `Unanswered status` in paper `.tex` files.

## Remaining Risks

- LaTeX still reports underfull boxes in narrow table cells and bibliography
  entries, but there are no compile errors.
- The paper still needs later compression after final evidence is available.
