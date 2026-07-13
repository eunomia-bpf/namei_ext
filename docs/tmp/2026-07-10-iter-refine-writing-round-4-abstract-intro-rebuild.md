# Iter Refine Writing Round 4: Abstract And Intro Rebuild

Date: 2026-07-10

## Mapping Diagnosis

Abstract sentence roles before edits:

- S1: context.
- S2: concrete problem.
- S3: existing-solution limitation.
- S4: this-paper decomposition.
- S5: system boundary.
- S6: planned evidence gate.

Introduction paragraph roles before edits:

- P1: background/context.
- P2: problem plus root cause mixed together.
- P3: existing solutions and limitation.
- P4: key insight.
- P5: this-paper system paragraph.
- P6: bounded claim and evaluation gate.
- P7: planned deliverables/contributions.

Logic-chain diagnosis:

- The overall chain is correct: background -> problem -> root cause -> existing
  mechanisms -> insight -> system -> bounded evidence gate -> contributions.
- The main opening weakness is role mixing in P2. The root cause matters
  because the insight answers it, so it should be its own paragraph.
- Contributions need section references to match the canonical intro template.
- The abstract already mirrors the intended chain, but it should be rechecked
  after the intro rewrite so no abstract-only concept remains.

## Reorganization Plan

- Split current P2 into a problem paragraph and a root-cause paragraph.
- Keep the existing-solutions paragraph after the root cause.
- Keep the insight and \namei paragraphs, but make the evidence-gate paragraph
  explicitly connect to falsifiability rather than sounding like internal
  project management.
- Add labels to the main paper sections so contribution bullets can cite the
  sections they correspond to.
- Derive a final abstract from the rewritten intro without adding new claims or
  results.

## Findings

Round 4 is a main-agent rewrite round from the `rewrite-abstract-intro` skill.
No subagent was used.

## Changes Made

- `docs/paper/sections/01-introduction.tex`
  - Split the problem/root-cause paragraph into separate problem and root-cause
    paragraphs.
  - Reworded the bounded evidence-gate paragraph so the main claim is explicitly
    falsifiable: a failed planned transition downgrades the claim rather than
    being replaced silently.
  - Added section references to the three planned deliverables.

- `docs/paper/main.tex`
  - Updated the abstract's evidence sentence to match the rewritten intro:
    both source-derived KVM transitions must pass correctness oracles before
    cost claims are interpreted.

- `docs/paper/sections/02-motivation.tex`
- `docs/paper/sections/03-design.tex`
- `docs/paper/sections/04-implementation.tex`
- `docs/paper/sections/05-evaluation.tex`
- `docs/paper/sections/06-related-work.tex`
- `docs/paper/sections/07-limitations.tex`
- `docs/paper/sections/08-conclusion.tex`
  - Added section labels used by the introduction's contribution list.

## Verification

- `make -C docs/paper` passed and produced `.build/paper/main.pdf`.
- `git diff --check` passed.
- Abstract word count is 181 words.
- Citation-site count remained 10.
- The LaTeX log has no overfull boxes, undefined references, or undefined
  citations.
- Fixed-string checks found no `\paragraph{}`, `\textbf{}`, or defensive
  self-attack phrases from the common-pitfalls list.
- PDF page count is 10.

## Remaining Concerns

- The opening is now role-aligned, but the full paper is long for a compact
  proposal. Later language rounds should compress prose while preserving the
  falsifiable evaluation gate.
