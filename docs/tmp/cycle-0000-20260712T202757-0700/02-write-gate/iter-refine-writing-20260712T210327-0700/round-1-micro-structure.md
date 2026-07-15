# Round 1: Micro Structure

Started: 2026-07-12T21:10:46-0700
Completed: 2026-07-12T21:18:30-0700
Cycle: 0000
Phase: BOOTSTRAP
Gate: 02-write-gate
Parent: `000-gate-entry-20260712T210327-0700.md`
Status: complete

## Objective

Check paragraph roles, abstract shape, introduction roles, RQ evidence block
openings and closings, topic sentences, and one-idea-per-paragraph structure.
The RQ meanings are read-only.

## Inputs And Method

A fresh read-only subagent reviewed `docs/paper/main.tex` using the
`check-paper-structure-flow` skill with Levels 2-3 micro-structure focus. It
did not edit files.

## Raw Subagent Findings

Must-fix:

- Abstract had acceptable length but too many sentences and did not map cleanly
  to intro roles.
- Introduction split the "this paper" role across multiple paragraphs, and the
  same-oracle paragraph read like evaluation terminology.
- Motivation packed design requirements, source characterization, comparison
  policy, related-work positioning, and forward pointers into one paragraph.

Should-fix:

- Source Evidence combined evidence methodology and source-corpus inventory in
  one paragraph.
- Representative Workloads mixed the headline AgentFS workload with
  neighboring systems and multi-backend context.
- Policy Model began with ABI contents before explaining why the model follows
  from requirements.
- BPF ABI paragraph did too much.
- Discussion used meta-instructional prose: "The paper should choose...".

Consider:

- Add short narrative paragraphs to RQ blocks so Evaluation is not only
  list/table dominated.
- Recast Related Work's programmable-filesystem paragraph as a comparative
  topic paragraph.

## Applied Fixes

Applied all must-fix and should-fix findings:

- Rewrote the abstract into one paragraph with eight role-aligned sentences:
  background, problem, neighboring mechanisms, insight/system, design, source
  characterization, implementation/evaluation setup, and explicit evidence
  boundary.
- Merged the introduction's system/methodology/result-placeholder role into one
  paragraph and left same-oracle terminology to Evaluation setup.
- Split Motivation's three-observations paragraph into separate paragraphs for
  workload-local policy, lower-FS ownership, lookup/readdir coherence, and
  comparison rule.
- Split Source Evidence into evidence methodology and source-corpus inventory.
- Split the AgentFS representative workload paragraph from neighboring
  BranchFS/Sandlock/YoloFS/Mirage/Redis AFS context.
- Added a "why" sentence to Policy Model tying it to requirements R1-R4.
- Split the BPF ABI discussion into ABI/context, validation semantics, and
  select-target coverage paragraphs.
- Rewrote the Discussion scope paragraph in paper voice.

Applied both consider findings:

- Added narrative paragraphs to RQ2 and RQ3 that explain how result slots
  become answers.
- Recast the first Related Work paragraph as a comparative ownership-boundary
  paragraph.

## Preservation Checks

- RQ wording and meaning were not changed.
- No table-only, static-table, or materialization-as-mainline comparison was
  introduced.
- Correct citation occurrence count did not decrease:
  `rg -o -F '\\cite{' docs/paper/main.tex docs/paper/sections docs/paper/refs.bib | wc -l`
  reports 29 occurrences.
- Abstract sentence count is 8.
- Search for meta/proposal phrases `paper should`, `must be`,
  `candidate is admitted`, `Required evidence`, `required before`,
  `preliminary`, and `empirical plan` returns no matches in paper sources.

## Compilation Evidence

Command:

```sh
make -B -C docs/paper
```

Result: success. The build produced `.build/paper/main.pdf`, 16 pages. The log
contains only underfull/font warnings; no LaTeX error occurred.

## Remaining Concerns

Evaluation is now RQ-shaped but still uses many table/list slots. Later rounds
should check section conventions and logic flow, especially whether the
placeholder wording is acceptable for a BOOTSTRAP submission-shaped draft.

## Next Node

Round 2 section conventions.

