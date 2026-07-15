# Round 7: Language - Word Choice

Timestamp: 20260712T215326-0700

Skill stage: `iter-refine-writing`, round 7.

## Scope

This round applied word-choice and tone fixes. It preserved the settled story:
\namei is a `sched_ext`-style VFS extension point, RQ1 is
expressiveness/sufficiency, RQ2 is FUSE-relative cost under the same oracle, and
RQ3 is safety/boundary versus custom or stackable filesystems.

## Reviewer Input

The read-only reviewer identified five must-fix issues and several should-fix
issues. The main pattern was that the paper prose still used internal progress
language such as "draft," "unanswered," "placeholder," and "remain unresolved."
The reviewer also flagged weak verbs such as "realizes," vague phrases such as
"flows through," and self-limiting phrases such as "\namei's claim is useful
only when."

## Edits Applied

- Replaced abstract and introduction status language with a claim-facing
  evidence-boundary statement.
- Replaced evaluation "unanswered" and "placeholder" prose with report items
  and completion criteria.
- Replaced "will fill ... placeholders" in the implementation section with
  direct experiment wording.
- Replaced weak implementation verbs with concrete actor/action wording.
- Replaced self-limiting related-work phrasing with boundary-applicability
  language.
- Rephrased the conclusion so it closes on the evaluated boundary rather than
  missing results.

## Files Edited

- `docs/paper/main.tex`
- `docs/paper/sections/01-introduction.tex`
- `docs/paper/sections/02-background.tex`
- `docs/paper/sections/02-motivation.tex`
- `docs/paper/sections/04-implementation.tex`
- `docs/paper/sections/05-evaluation.tex`
- `docs/paper/sections/06-related-work.tex`
- `docs/paper/sections/07-limitations.tex`
- `docs/paper/sections/08-conclusion.tex`

## Validation

- `make -B -C docs/paper` passed.
- Output: `.build/paper/main.pdf`
- PDF length: 17 pages.
- Citation occurrence count remained 29.
- Search over `docs/paper/main.tex` and `docs/paper/sections` found no remaining
  hits for `unanswered`, `placeholder`, `unresolved`, `this draft`, `remain
  unresolved`, `will fill`, `workload pressure`, `flows through`, `realizes the
  design`, `The FUSE row`, or `claim is useful only`.

## Residual Notes

Underfull hbox warnings remain concentrated in narrow tables. They are layout
warnings and should be handled in a figure/table/layout pass, not in the word
choice pass.
