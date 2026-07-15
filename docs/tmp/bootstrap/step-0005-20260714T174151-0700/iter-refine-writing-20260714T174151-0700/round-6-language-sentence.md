# Round 6: Language, Sentence Structure

Started: 2026-07-15T00:40:00-0700  
Completed: 2026-07-15T00:53:00-0700

Parent step: `docs/tmp/bootstrap/step-0005-20260714T174151-0700/step-report.md`

## Objective

Check sentence-structure issues only: non-list colons, semicolons joining
independent clauses, fragments, weak referents, and awkward sentence boundaries.

## Review Method

Spawned one read-only subagent to invoke `paper-writing-style` with
sentence-structure focus. The subagent did not edit files and did not propose
scientific, RQ, citation, or placeholder changes.

## Raw Findings

The review reported eight must-fix items, six should-fix items, and two
consider items. Most findings were non-list colons, semicolon-joined independent
clauses, one clipped sentence boundary, one vague "This boundary" referent, and
one awkward "AgentFS-derived source oracle" repetition.

## Applied Fixes

- Split non-list colons in the abstract, introduction, Design, Implementation,
  Discussion, and Conclusion.
- Replaced semicolon-joined independent clauses in Introduction, Motivation, and
  Evaluation.
- Rewrote the RQ2 placement-cost sentence to avoid weak "it" reference.
- Rewrote the RQ3 "expressive; they are" construction.
- Changed Motivation's repeated "AgentFS-derived source oracle" wording to
  "AgentFS source oracle."
- Replaced "This boundary" in Discussion with "The \namei boundary."
- Smoothed the BPF/`sched_ext` paragraph in Background.
- Split the long final Related Work paragraph about environment/cache and
  runtime behavior.
- Fixed an additional same-class colon in Motivation's closing paragraph.

## Verification

- `make -C docs/paper paper` succeeded.
- Output PDF: `.build/paper/main.pdf`, 15 pages.
- Remaining LaTeX warnings are underfull boxes in a compact design table and
  bibliography entries.

## Next Node

Proceed to Round 7 word-choice review.

