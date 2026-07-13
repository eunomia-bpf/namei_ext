# Iter Refine Writing Idea Round 3: Contributions And Design Goals

Date: 2026-07-10

## What Was Checked

Target: `docs/idea-story.md`

Scope: contribution list, design goals, dominant claim, method thesis, and
claim ledger.

Checklist: `iter-refine-writing-idea/references/idea-quality-checklist.md`
Section 3.

## Findings

Subagent finding summary:

- Contribution 1 still read like an abstraction plus broad domain statement.
  It needed to become a testable model/classification contribution.
- Contribution 3 was too compound, packing characterization, evaluation, KVM,
  traces, oracles, and baselines into one long sentence.
- G1 and C1 did not clearly state that out-of-model behavior is a result, not a
  filtered success.
- The dominant claim still risked a tautology because it spoke about
  "oracle-relevant in-scope effects" after classification.
- The one-decision-function claim was basically safe but needed to be scoped to
  classified in-model effects.
- Design goals had evaluation mappings but no explicit contribution mapping.
- G4/C4 needed correctness parity before setup/update/runtime interpretation.

## What Changed

- `docs/idea-story.md:84-90`
  - Rewrote the contribution list as three independent claims:
    state-transition path-view model, `namei_ext` system, and
    correctness-first KVM evaluation.
  - Added placeholder section references to each contribution.

- `docs/idea-story.md:121-126`
  - Added a `Contribution` column to the design-goal table.
  - Added the G1 rule that a workload family supports the current claim only if
    its chosen oracle-relevant transition has a complete in-model slice.
  - Added correctness parity to the G4 baseline matrix before interpreting
    setup/update/runtime measurements.

- `docs/idea-story.md:128-136`
  - Scoped the one-decision-function mechanism hypothesis to classified
    in-model effects.
  - Rewrote the target claim so classification first identifies a complete
    oracle-relevant in-model path-view slice, and `namei_ext` implements that
    slice.

- `docs/idea-story.md:152-157`
  - Updated C1 evidence to state that out-of-model transitions become
    motivation or related work, not evaluation evidence.
  - Changed C1 status to `pending KVM workload classification`.

## Verification

`git diff --check` is run after this edit round and before Round 4.

No LaTeX compile was run because Round 3 edited the Markdown idea layer.

## Remaining Concerns

Round 4 should check whether the newly stricter G1 rule remains aligned with
the problem, insight, contributions, claim ledger, and upcoming paper draft.
