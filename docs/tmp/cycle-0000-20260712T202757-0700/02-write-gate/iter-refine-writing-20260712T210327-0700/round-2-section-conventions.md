# Round 2: Section Conventions

Started: 2026-07-12T21:18:30-0700
Completed: 2026-07-12T21:28:00-0700
Cycle: 0000
Phase: BOOTSTRAP
Gate: 02-write-gate
Parent: `000-gate-entry-20260712T210327-0700.md`
Status: complete

## Objective

Check section-specific conventions: abstract structure, introduction roles,
design goals, explicit RQ-organized evaluation, one evidence block per RQ, no
orphan experiment, related-work grouping, and conclusion structure.

## Inputs And Method

A fresh read-only subagent reviewed `docs/paper/main.tex` using the
`check-paper-structure-flow` skill with section-specific convention focus. It
did not edit files.

## Raw Subagent Findings

Must-fix:

- RQ3 was still too centered on a static ownership/accounting table, risking a
  static table-only safety claim. The reviewer required dynamic evidence slots:
  same-oracle KVM pass, lower-FS permission/write-path preservation,
  malformed/unsupported decision containment through `cgroup/namei_ext`, and
  code/method-surface accounting for broader filesystem comparisons.

Should-fix:

- Design goals were mostly a table; add a prose goals paragraph.
- RQ2 "Hook overhead" looked like a standalone experiment; label it as
  fixed-cost controls for the FUSE comparison.
- Introduction evaluation preview needed to name the RQ evidence shape.
- Source Workload Systems in Related Work needed clearer differentiation.
- Conclusion should end with established evidence plus explicit unanswered RQ
  placeholders.

Consider:

- Make the abstract thesis sentence and system mechanism sentence distinct.
- Avoid implementation-specific "attached cgroup" wording in Design.

## Applied Fixes

Applied the must-fix:

- Kept Table~4 as explanatory and changed RQ3 into a dynamic same-oracle
  containment and ownership comparison.
- Added RQ3 evidence requirements for same-oracle KVM pass/fail, lower-FS
  permission/write/data-path preservation, malformed/unsupported decision
  containment through `cgroup/namei_ext`, filesystem methods owned, privileged
  code surface, policy code size, and evidence that the policy does not require
  broader filesystem responsibilities.
- Added RQ3 result slots for same-oracle boundary run, agent workspace boundary,
  environment/cache boundary, and invalid-policy containment with fail-closed
  behavior and absence of weaker fallback.

Applied all should-fix items:

- Added a prose design-goals paragraph with three obligations:
  expressiveness without file-operation ownership, lower-FS ownership and
  fail-closed safety, and workload-scoped observable policy.
- Renamed hook overhead to fixed-cost controls subordinate to RQ2.
- Strengthened the introduction evaluation preview to name RQ1 KVM
  expressiveness/lower-FS preservation, RQ2 feature-equivalent FUSE cost, and
  RQ3 dynamic containment plus custom/stackable ownership accounting.
- Added differentiating sentences to Related Work's source workload paragraphs.
- Rewrote the conclusion ending to state established characterization and
  prototype coverage, with final RQ answers explicitly unanswered until the
  full matrix completes.

Applied both consider items:

- Split the abstract's thesis sentence from the system mechanism sentence.
- Replaced "attached cgroup" with "workload scope" in Design.

## Preservation Checks

- RQ wording was preserved.
- RQ3 remains custom/stackable filesystem boundary, but no longer rests on a
  static table alone.
- No table-only, `table_redirect`, or materialization-as-mainline direction was
  introduced.
- Citation occurrence count remains 29:
  `rg -o -F '\\cite{' docs/paper/main.tex docs/paper/sections docs/paper/refs.bib | wc -l`.
- Abstract sentence count is 9, within the 7-9 target.

## Compilation Evidence

Command:

```sh
make -B -C docs/paper
```

Result: success. The build produced `.build/paper/main.pdf`, 16 pages. The log
contains only underfull/font warnings; no LaTeX error occurred.

## Remaining Concerns

The paper now satisfies the main section-convention fixes for BOOTSTRAP. Round
3 should check whole-paper logic flow, especially whether the explicit
unanswered placeholders make the paper read as a submission-shaped draft rather
than a proposal.

## Next Node

Round 3 logic flow.

