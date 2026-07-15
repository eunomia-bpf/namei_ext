# Round 8: Terminology, Information Flow, And Claim Tone

Timestamp: 20260712T215724-0700

Skill stage: `iter-refine-writing`, round 8.

## Scope

This round checked terminology consistency, definition order, invented jargon,
claim tone, and cross-section coherence. It preserved the settled RQ structure:
RQ1 is expressiveness/sufficiency, RQ2 is feature-equivalent FUSE cost, and RQ3
is the safety/boundary comparison against custom or stackable filesystems.

## Reviewer Input

The read-only reviewer identified three must-fix patterns:

- project-status language in the abstract, introduction, and evaluation;
- terminology drift from "name-resolution policy" to "path-resolution policy";
- optional deny/access-control language that blurred the boundary between
  \namei and eBPF LSM/access-control mechanisms.

The reviewer also recommended clarifying YoloFS evidence status, strengthening
the RQ3 safety definition before using "safer," replacing internal shorthand in
implementation prose, and removing invented wording such as "mechanism
gradient."

## Edits Applied

- Changed the title to emphasize VFS name resolution.
- Replaced abstract/introduction project-status language with claim-facing
  evaluation wording.
- Standardized the hook boundary as "name-resolution policy" and kept
  "path-view action" for PASS/REDIRECT/HIDE/SELECT_TARGET effects.
- Removed optional deny language from the core design story and related work;
  access-control denial is now explicitly outside the current action set.
- Clarified YoloFS evidence as public tests/artifacts plus a paper-derived
  oracle, while keeping the original private benchmark as not reproduced.
- Rephrased RQ3 to define safety as verifier-bounded policy plus kernel
  validation before comparing against custom or stackable filesystems.
- Replaced "FUSE-overhead/custom-filesystem boundary experiments" with explicit
  RQ1/RQ2/RQ3 experiment language.
- Replaced "mechanism gradient" with "neighboring mechanisms."
- Rephrased limitations and evaluation interpretation so they describe the
  evidence method rather than apologizing for the source characterization.
- Replaced narrative uses of `lower-FS` with `lower-filesystem` or `lower
  filesystem`; two `lower-FS` abbreviations remain only in narrow table cells.

## Files Edited

- `docs/paper/main.tex`
- `docs/paper/sections/01-introduction.tex`
- `docs/paper/sections/02-motivation.tex`
- `docs/paper/sections/03-design.tex`
- `docs/paper/sections/04-implementation.tex`
- `docs/paper/sections/05-evaluation.tex`
- `docs/paper/sections/06-related-work.tex`
- `docs/paper/sections/07-limitations.tex`

## Validation

- `make -B -C docs/paper` passed.
- Output: `.build/paper/main.pdf`
- PDF length: 17 pages.
- Citation occurrence count remained 29.
- Search found no remaining hits for `boundary slots`, `current evidence`,
  `final RQ`, `path-resolution policy`, optional/future deny wording,
  `mechanism gradient`, `unanswered`, `placeholder`, `unresolved`, `this draft`,
  `remain unresolved`, or `will fill`.

## Residual Notes

The remaining `lower-FS` occurrences are inside narrow tables. They are not
reader-facing narrative terminology drift and should be revisited only during a
table layout pass.
