# Iter Refine Writing Round 0: Macro Structure

Date: 2026-07-10

## Findings

Subagent finding summary:

- The section order was basically correct and did not revive table-only or
  workload-requires-eBPF claims.
- The draft still read like an idea/evaluation-plan skeleton rather than a
  paper macro structure.
- Motivation lacked a source-derived workload-characterization layer.
- Implementation mostly described validation discipline and Make workflow, not
  implementation structure.
- Evaluation had research questions and baselines but lacked workload,
  oracle, metrics, setup, and results-by-RQ structure.
- Design used run-in `\textbf{}` goal headings and Related Work used
  `\paragraph{}` headings, both flagged by the writing pitfalls.
- The draft lacked a conclusion.

## Changes Made

- `docs/paper/main.tex`
  - Reworded the abstract as a proposal draft rather than a completed result.
  - Added `sections/08-conclusion.tex` to the paper.

- `docs/paper/sections/01-introduction.tex`
  - Replaced "draft" wording with "proposal" wording for current claim state.

- `docs/paper/sections/02-motivation.tex`
  - Renamed the section to `Workload Characterization`.
  - Added Table 1 with planned source transition, oracle, in-model effects,
    out-of-model exclusions, and baselines.

- `docs/paper/sections/03-design.tex`
  - Replaced run-in bold design-goal headings with a compact table.

- `docs/paper/sections/04-implementation.tex`
  - Added subsections for kernel hook placement, BPF ABI and attach path, and
    policy loading/failure handling.

- `docs/paper/sections/05-evaluation.tex`
  - Added workload, correctness-oracle, metrics/setup, and results-by-question
    subsections.

- `docs/paper/sections/06-related-work.tex`
  - Replaced `\paragraph{}` headings with real subsections.

- `docs/paper/sections/08-conclusion.tex`
  - Added a short conclusion matching the bounded proposal claim.

## Verification

- `make -C docs/paper` passed and produced `.build/paper/main.pdf`.
- The PDF is 8 pages.
- A fixed-string check found no remaining `\paragraph{}` or `\textbf{}` run-in
  headings in `docs/paper/main.tex` or section files.
- `git diff --check` passed.

## Remaining Concerns

- The transition-characterization table produces layout warnings and should be
  tightened in later writing/format rounds.
- The paper remains a proposal draft until the two KVM transitions pass.
