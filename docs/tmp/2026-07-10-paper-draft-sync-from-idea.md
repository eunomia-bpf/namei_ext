# Paper Draft Sync From Idea Story

Date: 2026-07-10

## Motivation

The `iter-refine-writing` workflow requires a LaTeX paper draft. Before this
step, `docs/paper/` was a historical routing stub while the canonical current
claim lived in `docs/idea-story.md`. The paper draft was synchronized to the
stable idea-layer framing produced by the 2026-07-10
`iter-refine-writing-idea` rounds.

## Files Updated

- `docs/paper/main.tex`
- `docs/paper/sections/01-introduction.tex`
- `docs/paper/sections/02-motivation.tex`
- `docs/paper/sections/03-design.tex`
- `docs/paper/sections/04-implementation.tex`
- `docs/paper/sections/05-evaluation.tex`
- `docs/paper/sections/06-related-work.tex`
- `docs/paper/sections/07-limitations.tex`
- `docs/paper/refs.bib`

## Design Choices

- The draft is conservative. It does not claim completed KVM workload results.
- The current claim is limited to two examined upstream transitions: one
  AgentFS-derived workspace transition and one W4 environment/cache transition.
- The draft avoids table-centered framing and avoids claiming that selected
  workloads require eBPF, `namei_ext`, or dynamic policy logic.
- FUSE, OverlayFS, stackable filesystems, and materialized views are framed as
  valid mechanisms with different ownership boundaries, not as incapable
  alternatives.
- Bibliography entries were added only for references cited by the draft.

## Validation

- `make -C docs/paper check` passed.
- `make -C docs/paper` produced `.build/paper/main.pdf`.
- The first compile showed undefined citations because `main.tex` lacked a
  bibliography command. `\bibliographystyle{plain}` and `\bibliography{refs}`
  were added, and the next compile resolved citations.

## Remaining Risks

- The draft is an evaluation-plan paper draft, not a final result paper.
- Citation entries added for source repositories are minimal and still need the
  formal citation-verification pass in the writing workflow.
- Later writing rounds should remove run-in headings such as `\paragraph{}` and
  any prose that reads like a final result before the KVM workload evidence
  exists.
