# Iter Refine Writing Round 3: Logic Flow

Date: 2026-07-10

## Findings

Subagent finding summary:

- The main story is now in the right direction: the paper is about whether
  state-transition path views are a valid policy-only name-resolution boundary,
  not about proving table-only alternatives are impossible.
- The Evaluation Plan was not yet falsifiable enough. It needed an explicit
  rule for what happens when one planned transition is out of model or fails.
- The workload rows were still categories rather than concrete transition
  traces.
- The Design section did not explain why lookup/readdir decisions are a
  sufficient interface for the claimed path-view slice.
- The write-leak motivation could conflict with the claim that \namei does not
  own writes unless the text explains that open/create path resolution selects
  the object before lower-filesystem writes occur.
- Baseline roles needed to distinguish source/reference behavior, standalone
  FUSE as a filesystem-service boundary, and materialized namespace baselines.

## Changes Made

- `docs/paper/sections/02-motivation.tex`
  - Split `In-model effects` into `Policy-controlled effects` and preserved
    lower-filesystem checks.
  - Removed `lower-FS writes` and `lower-FS reads` from policy-controlled
    effects.
  - Added a planned AgentFS-derived workspace trace and a planned W4
    environment/cache trace.

- `docs/paper/sections/01-introduction.tex`
  - Clarified that write-leak cases are handled by open/create path resolution
    selecting the branch object or branch parent before the lower filesystem
    performs writes.

- `docs/paper/sections/03-design.tex`
  - Added `Boundary Invariants`.
  - Specified policy inputs, allowed actions, forbidden actions, decision
    scope, state source, and readdir/lookup consistency.

- `docs/paper/sections/04-implementation.tex`
  - Replaced repeated failure-handling prose with ABI shape details:
    event/context fields, decision enum, attach path, and policy-state maps.

- `docs/paper/sections/05-evaluation.tex`
  - Added an acceptance matrix with source oracle, in-model slice, KVM oracle,
    boundary checks, and baseline gates.
  - Made the main claim require both planned transitions to pass; if one fails,
    the claim must be downgraded rather than silently replacing the workload.
  - Separated baseline roles and split correctness gates, trace metrics, cost
    metrics, and boundary attributes.

- `docs/paper/sections/06-related-work.tex`
  - Added closest-delta sentences for each related-work group.

## Verification

- `make -C docs/paper` passed and produced `.build/paper/main.pdf`.
- `git diff --check` passed.
- The LaTeX log has no overfull boxes, undefined references, or undefined
  citations.
- Fixed-string checks found no `\paragraph{}`, `\textbf{}`, or defensive
  self-attack phrases from the common-pitfalls list.
- Citation-site count increased from 9 to 10.
- PDF page count is 10.

## Remaining Concerns

- The draft is now more falsifiable but longer. Later language rounds should
  compress prose and tables without weakening the acceptance gates.
- The acceptance matrix is still a plan until the KVM transition evidence
  exists.
