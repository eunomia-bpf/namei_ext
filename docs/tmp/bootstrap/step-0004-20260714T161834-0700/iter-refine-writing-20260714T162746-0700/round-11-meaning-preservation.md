# Round 11: Meaning-Preservation Audit

## Skill Route

- `iter-refine-writing`, round 11.
- Baseline: `entry-snapshot/` created before Round 0.
- Review mode: read-only subagent audit, followed by targeted restoration and a
  read-only confirmation audit.

## Findings

The audit found two must-fix losses relative to the entry snapshot:

1. The Agent workspace RQ1 row lost the `whiteout` oracle detail from the
   original `branch/checkpoint, COW, whiteout, symlink, and final-tree`
   behavior.
2. The RQ3 boundary/accounting row lost `privileged code surface` and
   `policy code size`; the current table only covered owned methods and state.

The audit found no RQ wording drift, no table-only or materialized-view framing
creep, and no prototype-scope broadening beyond registered directory-target
support.

## Restorations Applied

- Restored the Agent workspace oracle detail as `final tree, whiteout/hide
  effects, symlink metadata, lookup/readdir coherence, and branch-visible
  state`.
- Restored RQ3 accounting detail as `owned methods, state responsibility,
  privileged code surface, and policy code size`.

## Confirmation

A follow-up read-only confirmation audit checked only the two restored items.
It confirmed:

- The Agent workspace RQ1 oracle includes final tree, whiteout/hide effects,
  symlink metadata, lookup/readdir coherence, and branch-visible state.
- The RQ3 boundary/accounting row includes state responsibility, privileged code
  surface, and policy code size.
- The restoration introduced no scope broadening. The prototype remains scoped
  to registered directory-target support, and environment/cache evidence remains
  gated on final-file target selection.

## Validation

- Ran `make -C docs/paper paper`.
- Result: paper build was up to date and `.build/paper/main.pdf` exists.
- Checked `.build/paper/main.log` for undefined citations/references, overfull
  boxes, and LaTeX warnings. None of those targeted failures were present.
- PDF page count: 16 pages.
