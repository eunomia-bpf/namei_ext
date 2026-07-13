# Iter Refine Writing Idea Round 2b: Insight Defense

Date: 2026-07-10

## What Was Checked

Target: `docs/idea-story.md`

Scope: strengthen insight framing against the Round 2a attack.

## Findings

The Round 2a reviewer identified the strongest attack as "existing mechanisms
already perform lookup-time object selection; `namei_ext` looks like a narrower
hook." The required defense was to make the contribution a decomposition, not
an implementation placement claim.

## What Changed

- `docs/idea-story.md:51-56`
  - Rewrote P3 to state that the novelty is not that pathname lookup can choose
    objects.
  - Defined the missing decomposition: state changes should affect only
    name-to-existing-object binding or visibility while the lower filesystem
    retains data, writes, permissions, persistence, and consistency.
  - Added the contrast that existing mechanisms can implement the behavior but
    commonly couple object selection to namespace materialization or
    filesystem-service ownership.

- `docs/idea-story.md:62-67`
  - Reframed `namei_ext` as a policy-only object-selection boundary inside VFS
    name resolution.
  - Made explicit that the policy does not implement filesystem methods, own
    VFS objects, run a filesystem server, or materialize a namespace tree.

- `docs/idea-story.md:154-157`
  - Rewrote C4 so the comparison claim is the separation of state-transition
    object selection from namespace materialization and filesystem-service
    ownership.

## Verification

`git diff --check` is run after this edit round and before Round 2c.

## Remaining Concerns

Round 2c must check whether "missing decomposition" is now clear enough, or
whether the story still reads like a known stackable-filesystem idea with an
eBPF implementation.
