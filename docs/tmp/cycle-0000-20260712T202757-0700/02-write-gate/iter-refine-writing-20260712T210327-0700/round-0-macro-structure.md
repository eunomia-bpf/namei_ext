# Round 0: Macro Structure

Started: 2026-07-12T21:03:27-0700
Completed: 2026-07-12T21:10:46-0700
Cycle: 0000
Phase: BOOTSTRAP
Gate: 02-write-gate
Parent: `000-gate-entry-20260712T210327-0700.md`
Status: complete

## Objective

Run the macro-structure pass from `iter-refine-writing`: check section order,
design/implementation separation, architecture overview, explicit RQ-organized
evaluation, subsection balance, and whether the paper is submission-shaped
rather than a plan.

## Inputs And Method

Read:

- `docs/paper/main.tex`
- all section files under `docs/paper/sections/`
- `docs/idea-story.md`
- `docs/user-instruction.md`
- `docs/tmp/cycle-0000-20260712T202757-0700/01-experiment-gate/999-gate-report-20260712T210219-0700.md`

A fresh read-only subagent reviewed the paper using the
`check-paper-structure-flow` skill with Level 1 macro focus. The subagent did
not edit files.

## Raw Subagent Findings

Must-fix:

- Evaluation listed three RQs but did not organize evidence blocks by all three
  RQs. RQ1 had no primary evidence subsection.
- Evaluation read as a plan/proposal through phrases such as "candidate is
  admitted," "Required evidence," and "must pass".
- Design leaked implementation status and ABI details, including current
  prototype support, `struct path`, and current selected-target limitations.

Should-fix:

- Motivation was implicit under "Workload Characterization"; frame it as the
  motivation/problem-evidence section.
- The overview figure was a boxed text pipeline rather than an architecture
  diagram showing one decision function, event types, policy state, validation,
  and lower-FS ownership.
- Evaluation lacked a conventional setup subsection with machine/kernel/run
  placeholders and baseline definitions.
- Related Work had too many small subsections and overlapped with Motivation.

Consider:

- Discussion functioned partly as an empirical TODO list.
- The paper was short for a full-paper shape; expand design and evaluation
  with real decision subsections and RQ evidence blocks, not extra static
  baseline tables.

## Applied Fixes

Applied all must-fix items and all should-fix items:

- Rewrote `docs/paper/sections/05-evaluation.tex` into the macro outline:
  Research Questions, Experimental Setup, RQ1, RQ2, RQ3, Limitations And
  Interpretation.
- Added explicit `unanswered:` result slots for setup, RQ1, RQ2, and RQ3 so
  the paper is submission-shaped with visible result placeholders rather than
  a proposal.
- Moved prototype support and selected-target limitations out of
  `docs/paper/sections/03-design.tex` into a new Prototype Coverage subsection
  in `docs/paper/sections/04-implementation.tex`.
- Replaced the overview figure with a more explicit architecture/ownership
  diagram: workload, VFS event, single eBPF policy, kernel validation, and lower
  filesystem ownership.
- Renamed `Workload Characterization` to `Motivation And Workload
  Characterization`, added an opening problem-evidence paragraph, and added a
  bridge from observations to design and evaluation.
- Merged related-work source workload subsections so Related Work now has five
  broader topic groups.

Applied both consider items:

- Rewrote Discussion's extension-path paragraph to interpret scope and
  deployment boundary instead of listing empirical next work.
- Expanded the evaluation with RQ evidence blocks and explicit placeholders.

## Preservation Checks

- RQ meanings were preserved exactly: RQ1 expressiveness/sufficiency, RQ2 cost
  versus FUSE, and RQ3 safety/boundary versus custom or stackable filesystems.
- No table-only, static-table, or materialization-as-mainline experiment was
  introduced.
- Citations remain present; `rg -F '\\cite{' docs/paper/main.tex
  docs/paper/sections docs/paper/refs.bib | wc -l` reports 27 citation
  occurrences.
- Search for `preliminary`, `Required evidence`, `required before`,
  `empirical plan`, `candidate is admitted`, and `must pass` in paper sources
  returns no matches.

## Compilation Evidence

Command:

```sh
make -B -C docs/paper
```

Result: success. The build produced
`.build/paper/main.pdf`, 16 pages. The log contains only underfull/font warnings
already typical of the current table-heavy draft; no LaTeX error occurred.

## Remaining Concerns

Round 0 resolves the macro blockers. Later rounds should check whether
paragraphs and section conventions still overuse placeholders, and whether the
abstract/intro should be rebuilt around the new RQ-shaped Evaluation.

## Next Node

Round 1 micro-structure review.

