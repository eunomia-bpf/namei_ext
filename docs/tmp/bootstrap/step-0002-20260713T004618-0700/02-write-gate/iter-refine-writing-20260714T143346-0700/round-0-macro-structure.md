# Round 0: Macro Structure

Started: 2026-07-14T14:33:46-07:00
Completed: 2026-07-14T14:40:13-07:00
Phase: BOOTSTRAP
Gate: WRITE_GATE
Parent step: `docs/tmp/bootstrap/step-0002-20260713T004618-0700/`
Run directory:
`docs/tmp/bootstrap/step-0002-20260713T004618-0700/02-write-gate/iter-refine-writing-20260714T143346-0700/`

## Objective

Run `iter-refine-writing` Round 0 macro-structure review on
`docs/paper/main.tex` under the accepted EXPERIMENT_GATE contract:

- `namei_ext` is a `sched_ext`-style VFS name-resolution extension point;
- RQ1 is expressiveness/sufficiency;
- RQ2 is cost versus feature-equivalent FUSE;
- RQ3 is safety/boundary versus custom or stackable filesystems;
- the main experiments are Agent workspace lifecycle and environment/cache
  transition, with service/config conditional;
- table-only novelty, scattered weak baselines, and negative-result story are
  not the paper direction.

## Inputs Read

- `docs/user-instruction.md`
- `docs/tmp/bootstrap/step-0002-20260713T004618-0700/02-write-gate/000-gate-entry-20260713T012400-0700.md`
- `docs/tmp/bootstrap/step-0002-20260713T004618-0700/01-experiment-gate/999-gate-report-20260713T012400-0700.md`
- Complete paper under `docs/paper/`
- `iter-refine-writing` skill instructions
- Round 0 read-only subagent report

## Raw Subagent Findings

Must-fix:

- Abstract and introduction contributions drifted from the accepted contract by
  elevating source-derived characterization and the evaluation contract into
  contributions.
- Evaluation RQ blocks existed and matched the accepted RQs, but did not close
  with an answer or explicit `unanswered` evidence TODOs; RQ2/RQ3 also did not
  name the two main experiments.

Should-fix:

- Implementation leaked evaluation/provenance workflow into the implementation
  section.
- Design opened with overview/action-set detail before goals and invariants.
- Related Work had too many groups and an oversized source-workload group.

Consider:

- The draft is submission-shaped for BOOTSTRAP but still shorter than a full
  12--14 page systems paper unless result placeholders are explicit.
- The overview figure is acceptable as a placeholder but should later be
  replaced by a clearer architecture figure.

## Fixes Applied

Applied must-fix findings:

- Rewrote the abstract to say source systems select evaluation oracles rather
  than serving as a paper contribution.
- Rewrote the introduction contribution list from three contribution bullets
  into two primary contributions: the \namei design and the Linux/eBPF
  implementation. Evaluation is now described as evidence for those
  contributions.
- Added `Table~\ref{tab:experiment-shape}` in Evaluation to make the two
  primary complete matrices explicit: Agent workspace lifecycle and
  environment/cache transition; service/config is conditional.
- Added `Bootstrap status: RQ is unanswered` paragraphs to RQ1, RQ2, and RQ3,
  each naming the final evidence required.

Applied should-fix findings:

- Reordered Design so invariants appear before the action-set detail.
- Narrowed Implementation's failure-handling subsection so raw run identity and
  final-run provenance live in Evaluation rather than Implementation.
- Merged custom/stackable filesystem work with metadata-service/full-filesystem
  work in Related Work.
- Added FUSE passthrough and FUSE-BPF as closest FUSE-neighborhood related-work
  pressure, with a verified annotated bibliography entry for FUSE-BPF.

Deferred consider findings:

- The architecture figure remains a text/table placeholder for this round. It
  is acceptable for BOOTSTRAP Round 0 and should be revisited by a later figure
  or macro-structure pass.
- Page-budget expansion is deferred until the remaining writing rounds decide
  whether Design/Evaluation need more substance or the current draft is the
  intended BOOTSTRAP placeholder paper.

## Verification

Compilation command:

```text
make -C docs/paper paper
```

Result: passed. The generated PDF is:

```text
.build/paper/main.pdf
```

PDF evidence:

- page count: 15;
- file size: 126648 bytes;
- no LaTeX fatal error;
- citations were resolved after `latexmk` reran BibTeX and XeLaTeX;
- remaining output contains only font/underfull warnings.

Current citation-line count:

```text
rg -F '\cite{' docs/paper -g '*.tex' | wc -l
31
```

## Claim Preservation Check

- RQ meanings were not changed.
- The paper still uses exactly three RQs.
- The contribution became more faithful to the user instruction: design plus
  implementation are now primary; workload characterization and evaluation are
  supporting evidence.
- No table-only or materialized-view shootout was introduced.
- FUSE remains the RQ2 comparison.
- Custom/stackable filesystem ownership remains the RQ3 boundary comparison.

## Next Node

Proceed to Round 1, micro-structure review. The next round should check
paragraph roles, topic sentences, abstract/intro role flow, and whether each RQ
block now opens and closes correctly without changing scientific meaning.
