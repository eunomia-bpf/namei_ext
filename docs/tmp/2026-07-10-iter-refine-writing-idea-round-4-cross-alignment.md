# Iter Refine Writing Idea Round 4: Cross-Alignment

Date: 2026-07-10

## What Was Checked

Target: `docs/idea-story.md`

Scope: alignment from problem to insight, goals, contributions, evaluation,
claim ledger, workload scope, and reviewer attack responses.

## Findings

Subagent verdict:

- The main story is coherent: state transitions change pathname binding; the
  insight separates object selection from filesystem/server/materialization
  ownership; `namei_ext` is a policy-only VFS boundary; evaluation starts with
  AgentFS-derived and W4 transitions.
- The document did not slide back into table-only or "workload requires eBPF"
  claims.

Must-fix findings:

- Scope terms drifted across `transition`, `workload family`, and `workflow`.
  The current claim should consistently say two examined upstream transitions:
  one AgentFS-derived workspace transition and one W4 environment/cache
  transition.
- The out-of-model failure rule still left a cherry-picking hole. The
  classification must start from an upstream transition and its oracle; if the
  oracle requires out-of-model behavior, that transition cannot support C3.
- C4 was orphaned relative to the three-item contribution list. It should be a
  comparison subclaim under Contribution 3 rather than a fourth contribution.
- The FUSE/Overlay/stackable response risked artifact-first framing. The
  response should say that other mechanisms can express the behavior, but
  couple selection to daemon, filesystem-method, or materialization
  responsibilities.

Should-fix findings:

- One trace unblocks implementation, while two KVM transitions are needed to
  promote the paper claim.
- The baseline list should avoid double-counting a FUSE-like source system and
  a standalone FUSE reimplementation.
- G3 should record the workload-specific lookup/readdir event mix rather than
  requiring every transition to exercise both event types.

## What Changed

- `docs/idea-story.md:25-34`
  - Renamed the P1 purpose to state-transition path views.
  - Clarified that one trace unblocks implementation, but two KVM-validated
    upstream transitions are required for the paper claim.

- `docs/idea-story.md:73-78`
  - Rewrote the evaluation promise around one AgentFS-derived workspace
    transition and one W4 environment/cache transition.
  - Required oracle-first classification.
  - Stated that a transition requiring out-of-model behavior cannot support C3.
  - Avoided double-counting source-system behavior and standalone FUSE.

- `docs/idea-story.md:84-90`
  - Rephrased Contribution 3 as an evaluation of two examined upstream
    transitions.
  - Updated the status note to require those two transitions, not broad
    workload families.

- `docs/idea-story.md:121-126`
  - Tightened G1's failure rule.
  - Made G3 event-mix recording explicit.
  - Folded G4 into a C3 comparison subclaim.

- `docs/idea-story.md:134-138`
  - Rewrote the dominant claim around one AgentFS-derived transition and one
    W4 transition.

- `docs/idea-story.md:152-157`
  - Folded the former C4 comparison claim into C3, leaving three claims aligned
    with the three contributions.

- `docs/idea-story.md:183-188`
  - Rewrote the "just FUSE" reviewer response to focus on coupling boundaries
    measured under the same oracle.

## Verification

`git diff --check` is run after this edit round and before Round 5.

No LaTeX compile was run because Round 4 edited the Markdown idea layer.

## Remaining Concerns

Round 5 should confirm that no easy reject remains after the scope is narrowed
to two examined upstream transitions and C4 is folded into the evaluation
comparison subclaim.
