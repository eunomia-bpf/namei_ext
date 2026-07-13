# Iter Refine Writing Round 1: Micro Structure

Date: 2026-07-10

## Findings

Subagent finding summary:

- The abstract was a single compressed proposal paragraph and did not clearly
  follow context, problem, paper, and evaluation/result roles.
- The introduction mixed proposal and paper-result stance. Since no KVM results
  exist yet, the draft should consistently be a proposal draft.
- Motivation and Design repeated the model boundary at similar depth.
- Implementation still included validation discipline and raw-evidence text
  that belonged in evaluation setup.
- Evaluation used plan language, so the section should be explicitly an
  evaluation plan rather than a result section.
- The introduction's status quo paragraph was too dense.
- The workload-characterization table should be introduced as an evidence
  contract, not as completed characterization results.
- Limitations and conclusion contained defensive/internal language.

## Changes Made

- `docs/paper/main.tex`
  - Tightened the abstract into a clear proposal abstract and kept the result
    beat as an evaluation gate rather than a completed result.

- `docs/paper/sections/01-introduction.tex`
  - Replaced detailed mechanism contrast with a shorter grouped status quo
    paragraph.
  - Reframed contributions as planned deliverables to match proposal stance.

- `docs/paper/sections/02-motivation.tex`
  - Renamed the opening subsection to `Source Transitions`.
  - Removed formal model language from Motivation and left formal classification
    to Design.
  - Introduced the table as an evidence contract.

- `docs/paper/sections/03-design.tex`
  - Added a deliverable-mapping column to the design-goals table.

- `docs/paper/sections/04-implementation.tex`
  - Rewrote policy loading/failure handling around attach/failure behavior.
  - Moved KVM/raw-evidence details out of Implementation.

- `docs/paper/sections/05-evaluation.tex`
  - Renamed the section to `Evaluation Plan`.
  - Moved KVM/raw-evidence details into Metrics and Setup.
  - Renamed the final subsection to `Results Skeleton`.

- `docs/paper/sections/06-related-work.tex`
  - Merged short related-work subsections into larger topic groups.

- `docs/paper/sections/07-limitations.tex`
  - Added a neutral artifact-boundary topic sentence.

- `docs/paper/sections/08-conclusion.tex`
  - Removed the internal "not another table-only argument" wording.

## Verification

- `make -C docs/paper` passed and produced `.build/paper/main.pdf`.
- Fixed-string checks found no remaining `\paragraph{}` or `\textbf{}` run-in
  headings.
- `git diff --check` passed.

## Remaining Concerns

- The transition-characterization and design-goal tables still produce layout
  warnings. Later section/format rounds should tighten them.
- The paper is intentionally a proposal draft until the two KVM transitions
  pass.
