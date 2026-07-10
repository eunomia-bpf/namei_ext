# Iter Refine Writing Idea Round 2b: Insight Defend

Date: 2026-07-09

## What Was Changed

Target: `docs/idea-story.md`

The defense edit reframed the insight from an implementation hook to a
decomposition:

- `docs/idea-story.md:49-50`
  - Before: "many workloads do not need a new filesystem" and "need a
    programmable decision at VFS name resolution."
  - After: "dynamic filesystem views can separate path-view policy from
    filesystem ownership," with the workload class modeled as a
    state-indexed mapping from lookup/readdir event, pathname, and
    workspace/branch/cache/request state to a lower object or visibility
    decision.

- `docs/idea-story.md:60-61`
  - Before: `namei_ext` was described mainly as a narrow VFS extension point
    exposing one decision function.
  - After: `namei_ext` realizes the decomposition as a programmable path-view
    layer, with one function because lookup and directory enumeration share
    the same contract.

- `docs/idea-story.md:82-83`
  - Before: contribution paragraph was mostly defensive non-goals.
  - After: it starts with the positive contribution: a state-indexed path-view
    policy abstraction and kernel prototype.

- `docs/idea-story.md:111-118`
  - Before: thesis and claims foregrounded an eBPF-controlled hook and a
    "general programmable filesystem abstraction."
  - After: thesis and claims foreground separating state-indexed path-view
    policy from filesystem ownership; the stretch claim is now a
    "programmable path-view abstraction for state-indexed name resolution."

- `docs/idea-story.md:142-143`
  - Before: "missing middle point" was descriptive.
  - After: it names the property: unbundling state-indexed path-view selection
    from filesystem ownership.

## Verification

`git diff --check` passed after the edit.

No LaTeX compile was run because the active idea layer is Markdown and the
LaTeX tree is a historical routing stub.

## Remaining Concerns

Round 2c should test whether a skeptical reviewer can still say the
decomposition is already known from stackable filesystems, OverlayFS, FUSE
passthrough, or VFS interposition.

## Second Defense After Round 2c

Round 2c found that the decomposition was stronger but still under-specified
relative to stackable and passthrough filesystems. A second defense edit made
the semantic boundary explicit:

- `docs/idea-story.md:49-50`
  - Added the model membership condition: all workload-specific behavior must
    be expressible as lookup- or directory-enumeration-time selection or hiding
    of existing lower objects.

- `docs/idea-story.md:60-61`
  - Added the direct contrast with stackable/passthrough filesystems: the
    policy does not implement filesystem methods or own VFS objects; it returns
    a path-resolution action before the kernel continues through the ordinary
    lower filesystem.

- `docs/idea-story.md:71-72`
  - Added the evaluation characterization requirement: selected transitions
    must be dominated by lookup/readdir object-selection events and not require
    data-path interposition.

- `docs/idea-story.md:82-83`
  - Defined the contribution contract as object selection before VFS object
    acquisition.

- `docs/idea-story.md:111-129`
  - Tightened thesis, core claim, scope, and non-goals around object selection
    before VFS object acquisition, excluding synthetic contents, custom
    metadata persistence, distributed indexing, write-conflict resolution, and
    data-path mediation.

`git diff --check` passed after this second defense edit.
