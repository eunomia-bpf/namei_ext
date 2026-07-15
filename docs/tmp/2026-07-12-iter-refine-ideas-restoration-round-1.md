# Iter-Refine-Ideas Restoration Round 1

Date: 2026-07-12
Skill: `iter-refine-ideas`
Round: 1, Problem and Research Direction

## Objective

Recover the largest, most interesting, and most faithful version of the user's
idea after the shrinkage audit.

## Files Read

- `docs/user-instruction.md`
- `docs/idea-story.md`
- `docs/tmp/2026-07-12-idea-shrinkage-trajectory-audit.md`
- `docs/tmp/2026-07-12-shrunken-claim-archive.md`
- `docs/paper/main.tex`
- `docs/paper/sections/*.tex`
- `docs/paper/refs.bib`

## Discussant Finding

The discussant agreed that the largest faithful idea is not table-only
failure, two-workload eBPF necessity, or agent-filesystem optimization. It is:

> `namei_ext` is a `sched_ext`-style VFS extension point for
> state-dependent path views. eBPF chooses bounded name-resolution policy,
> while the kernel and lower filesystem keep ownership of dentries, inodes,
> permissions, file operations, page cache, writes, persistence, and
> consistency.

The discussant identified the strongest novelty axis as ownership boundary:
what each mechanism forces the developer to own. It also argued that workload
characterization should be a first-class contribution and that a third
service/config workload would make the abstraction less dependent on agent
trends.

## Main-Agent Response

Accepted:

- Mark `docs/paper/` as the active paper draft again.
- Make RQ3 falsifiable rather than assuming a positive result.
- Add evidence-status language to the workload characterization table.
- Add related work for Landlock, BPF LSM, and fanotify as neighboring access
  control or observation hooks.
- Clarify that redirect targets are kernel-registered lower objects or bounded
  components, not arbitrary path strings.

Deferred:

- Splitting the grouped workload table into per-system rows is left for a
  later appendix/body expansion, because this round's purpose is to restore the
  core idea without bloating the short draft.

## Changes Applied

- `docs/paper/README.md`: active restored draft status.
- `docs/paper/evaluation.md`: active companion note and falsifiable RQ3.
- `docs/paper/sections/05-evaluation.tex`: RQ3 changed to ask whether and
  where ownership/update work is avoided.
- `docs/paper/sections/02-motivation.tex`: evidence-status column added.
- `docs/paper/sections/03-design.tex`: lower-object validation clarified.
- `docs/paper/sections/06-related-work.tex`: access-control and observation
  hooks added.
- `docs/paper/refs.bib`: active verified entries added for Landlock, BPF LSM,
  and fanotify.
- `docs/evaluation.md` and `docs/idea-story.md`: RQ3 synchronized.

## Preservation Check

The changes preserve the user's requested restored idea: a `sched_ext`-style
VFS extension point between bind/Overlay/materialization and FUSE/custom
filesystems. They do not revive table-only impossibility as the novelty gate
and do not claim exclusive necessity for eBPF or `namei_ext`.

## Next Action

Run Round 2 to check whether the academic architecture and system direction
follow from the restored motivation.
