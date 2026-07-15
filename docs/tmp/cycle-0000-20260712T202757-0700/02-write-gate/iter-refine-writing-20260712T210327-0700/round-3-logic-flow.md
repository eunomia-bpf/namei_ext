# Round 3: Logic Flow

Started: 2026-07-12T21:28:00-0700
Completed: 2026-07-12T21:38:00-0700
Cycle: 0000
Phase: BOOTSTRAP
Gate: 02-write-gate
Parent: `000-gate-entry-20260712T210327-0700.md`
Status: complete

## Objective

Check whether the paper tells one coherent story from abstract and
introduction through design, implementation, evaluation, related work, and
conclusion. This round checks logic flow only; it does not change RQ meaning.

## Inputs And Method

A fresh read-only subagent read the complete paper and reported logic-flow
findings. It did not invoke `iter-review-critique` and did not edit files.

## Raw Subagent Findings

Must-fix:

- The paper inconsistently treated attachment-mode deny as part of the
  validated design/prototype action set, while Implementation listed only
  `PASS`, `REDIRECT`, `HIDE`, and `SELECT_TARGET`.
- Service/config was presented as the third representative workload in
  Motivation, but Evaluation admitted it only conditionally.
- Registered-target selection appeared in the prototype/action set, but RQ1 did
  not state which oracle exercises it.

Should-fix:

- Define RQ3 safety evidence more concretely, not only narrower ownership.
- State which source-evidence classes can become headline or decisive
  evaluation rows.
- Require RQ2 to match action mix and operation distribution before overhead
  interpretation.

Consider:

- Add a bridge from intro failure examples to the admitted workload oracles.
- Bound the `sched_ext` analogy as policy-versus-kernel ownership, not
  scheduler semantics or maturity.

## Applied Fixes

Applied all must-fix items:

- Removed attachment-mode deny from the current abstract, Design action list,
  Design figure, and Policy Model. Kept only the related-work/design-space idea
  that attachment modes may add denial in the future.
- Made service/config consistently conditional: it is a source-characterization
  and related-work family until a concrete lookup-time source oracle is
  selected.
- Added `SELECT_TARGET` to the Agent workspace RQ1 source-oracle and result
  slots so registered-target selection has a same-oracle KVM evidence path.

Applied all should-fix items:

- Added a safety-evidence criterion paragraph for RQ3: verifier-bounded policy,
  fail-closed invalid decisions, lower-FS preservation, and reduced trusted
  filesystem-method/state surface for the same oracle.
- Added a source-evidence admission rule: reproduced or replayed source oracles
  can become headline/decisive rows; source inspection and paper-derived
  evidence stay contextual/conditional unless backed by a real KVM oracle.
- Added matched action mix and operation distribution to RQ2 measurement and
  result slots before overhead interpretation.

Applied consider items:

- Strengthened the introduction evaluation preview to name RQ1/RQ2/RQ3
  evidence blocks.
- Added a sentence bounding the `sched_ext` analogy to ownership split rather
  than scheduler semantics or interface maturity.

## Preservation Checks

- RQ wording and meaning were preserved.
- Service/config remains conditional; it was not promoted to a weak main row.
- No table-only, `table_redirect`, static-table, or materialization-as-mainline
  direction was introduced.
- Citation occurrence count remains 29:
  `rg -o -F '\\cite{' docs/paper/main.tex docs/paper/sections docs/paper/refs.bib | wc -l`.
- Abstract sentence count remains 9.

## Compilation Evidence

Command:

```sh
make -B -C docs/paper
```

Result: success. The build produced `.build/paper/main.pdf`, 17 pages. The log
contains only underfull/font warnings; no LaTeX error occurred.

## Remaining Concerns

Round 4 should rebuild abstract and introduction using the accepted logic flow,
without changing the RQs or the evidence boundary.

## Next Node

Round 4 abstract/intro rebuild.

