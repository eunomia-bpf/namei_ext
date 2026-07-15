# Round 7: Language, Word Choice

## Skill Step

`iter-refine-writing` round 7: word-choice pass. A read-only subagent invoked
`paper-writing-style` with word-choice focus.

## Raw Findings

### Must-Fix

1. `sections/02-motivation.tex` contained the grammar error `but it the
   operation`.
2. `main.tex` used the vague phrase `current path-view action set` in the
   abstract, which could overstate final-file support.
3. `sections/02-motivation.tex` said the environment/cache workload "chooses
   among verified local, canonical, stale, corrupt, or regenerated objects,"
   which implied stale/corrupt objects could be selected.

### Should-Fix

4. `sections/05-evaluation.tex` used meta wording, "reviewer-facing questions."
5. `sections/05-evaluation.tex` used bureaucratic wording, "admitted workload."
6. `sections/05-evaluation.tex` used overloaded "what the developer must own."
7. `sections/05-evaluation.tex` used the spatial metaphor "leaves below the
   hook."
8. `sections/06-related-work.tex` said mechanisms "own a filesystem-service
   boundary."
9. `sections/07-limitations.tex` used the inflated phrase "filesystem
   programmability."

### Consider

10. `sections/03-design.tex` used avoidable `it` for policy state.
11. `sections/04-implementation.tex` used weak `this subset`.
12. `sections/08-conclusion.tex` used informal "cheaper" and vague "path
    policy."

## Fixes Applied

- Fixed the Motivation grammar error.
- Removed `current path-view action set` from the abstract and limited the
  abstract implementation claim to one decision function, attachment, and
  kernel validation for the currently implemented actions.
- Rewrote the environment/cache workload so stale/corrupt local objects are
  hidden, not selected.
- Replaced `reviewer-facing questions` with `research questions`.
- Replaced `admitted workload` with `included workload`.
- Replaced overloaded ownership wording with responsibilities the developer must
  implement or operate.
- Replaced "leaves below the hook" with "leaves to the VFS and lower
  filesystem."
- Replaced "own a filesystem-service boundary" with "require a
  filesystem-service boundary."
- Replaced "filesystem programmability" with "policy."
- Clarified policy-state and redirect-subset references.
- Replaced "cheaper than feature-equivalent FUSE for path policy" with "lower
  cost than feature-equivalent FUSE for lookup/readdir policy."

## Validation

- `make -C docs/paper paper` passed.
- The generated PDF is `/home/yunwei37/workspace/namei_ext/.build/paper/main.pdf`.
- Abstract length is 242 words.
- Page count remains 15.
- Targeted grep no longer matches the flagged phrases.

## Remaining Risks

- The paper still lacks result-backed final answer paragraphs.
- Later rounds should ensure the now tighter wording did not weaken protected
  scope or change RQ meaning.
