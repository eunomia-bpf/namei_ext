# Round 5: Consistency

Started: 2026-07-12T21:39:00-0700
Completed: 2026-07-12T21:49:00-0700
Cycle: 0000
Phase: BOOTSTRAP
Gate: 02-write-gate
Parent: `000-gate-entry-20260712T210327-0700.md`
Status: complete

## Objective

Check architecture and workflow contradictions, claim/status drift, figure and
table alignment, design goals versus contributions and RQs, stable RQ wording,
and abstract/intro/body/conclusion consistency.

## Inputs And Method

A fresh read-only subagent reviewed `docs/paper/main.tex` with
`check-terminology-infoflow` in paper-consistency scope. It did not edit files.

## Raw Subagent Findings

Must-fix:

- Abstract, intro, and conclusion overstated the evidence boundary by saying
  source characterization and prototype coverage were "established", even
  though service/config is conditional and final RQ evidence is missing.
- Design and Evaluation promised lookup/readdir/registered-target behavior, but
  Implementation still fails closed for synthetic parent-directory aliases.
  RQ1 needed to state whether the admitted oracle avoids or requires that case.

Should-fix:

- Implementation said representative workload targets "fill" result
  placeholders, which read as present-tense completion.
- RQ2 said the FUSE row "implements" the same policy even though it is an
  unanswered slot.
- Motivation's per-system table mixed runtime actions into a path-operation
  column.

Consider:

- Action naming drift among selected-target, select target, `SELECT_TARGET`,
  and registered-target selection.
- Related Work should mark service/config as conditional.

## Applied Fixes

Applied all must-fix items:

- Changed the evidence boundary to "source characterization evidence and
  current prototype coverage are documented"; final RQ answers and
  service/config admission remain unresolved.
- Added RQ1 language requiring selected-directory readdir for
  `SELECT_TARGET`, and requiring synthetic parent aliases to be avoided by the
  admitted oracle or implemented before a pass is claimed.

Applied all should-fix items:

- Changed Implementation to say representative workload targets will fill
  result placeholders after admitted complete experiments run.
- Changed RQ2 language to say the FUSE row must implement the same policy.
- Reworded the OpenHands/SWE-agent/SWE-ReX table cell to "workspace file
  lookup/open/stat by edit and command tools."

Applied both consider items:

- Introduced "registered-target selection (`SELECT_TARGET`)" and used
  registered-target selection in prose.
- Marked service/config as a conditional source workload family in Related
  Work.

## Preservation Checks

- RQ wording and meaning were preserved.
- No result values or claims were strengthened.
- No table-only, `table_redirect`, static-table, or materialization-as-mainline
  direction was introduced.
- Citation occurrence count remains 29:
  `rg -o -F '\\cite{' docs/paper/main.tex docs/paper/sections docs/paper/refs.bib | wc -l`.
- Abstract length is 9 sentences and approximately 226 words.

## Compilation Evidence

Command:

```sh
make -B -C docs/paper
```

Result: success. The build produced `.build/paper/main.pdf`, 17 pages. The log
contains only underfull/font warnings; no LaTeX error occurred.

## Remaining Concerns

The technical story is now more internally consistent. Later rounds should
focus on sentence mechanics, word choice, terminology drift, and citation
verification without changing the scientific contract.

## Next Node

Round 6 language: sentence structure.

