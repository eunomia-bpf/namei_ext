# Iter Refine Writing Idea Round 5: Reviewer Stress Test

Date: 2026-07-10

## What Was Checked

Target: `docs/idea-story.md`

Scope: final skeptical OSDI/SOSP review of problem framing, novelty,
contribution scope, anti-cherry-picking rule, FUSE/Overlay/stackable-filesystem
contrast, and whether an easy reject argument remains.

## Findings

Subagent verdict:

- Easy rejection is no longer obvious.
- The strongest previous reject is no longer "this is just
  FUSE/Overlay/stackable FS" because the text now explicitly acknowledges that
  existing mechanisms can do object selection.
- The current novelty is the decomposition: separate state-transition object
  selection from daemon, filesystem-method, or materialization ownership.
- The evaluation promise includes the anti-cherry-picking rule: classification
  starts from the upstream transition and oracle; out-of-model behavior cannot
  support C3.

Remaining non-easy risks:

- OSDI/SOSP scale risk: two examined upstream transitions may read as a
  workshop/feasibility scope unless later evidence shows they represent a real
  recurring subproblem.
- Generality risk: any family-level claim must wait for additional classified
  transitions.
- Baseline value risk: the same-oracle baseline matrix must quantify daemon,
  filesystem-method ownership, materialization writes, and setup/update/runtime
  costs after correctness parity.
- Related-work risk: the paper must keep saying that FUSE, OverlayFS, and
  stackable filesystems choose a different ownership boundary, not that they
  are unable to express the behavior.

## What Changed

- `docs/idea-story.md:136-138`
  - Replaced the remaining "two real workload families" wording with "two real
    upstream transitions beyond controlled fixtures."
  - Added that broader family-level claims require additional classified
    transitions.

## Verification

`git diff --check` is run after this edit round and before entering the
writing-refinement workflow.

No LaTeX compile was run because Round 5 edited the Markdown idea layer.

## Remaining Concerns

The idea layer is past the easy-reject gate. The next work should not keep
arguing table-only or workload-necessity claims. It should implement and report
the two source-derived transition classifications, KVM oracles, and same-oracle
baseline matrices.
