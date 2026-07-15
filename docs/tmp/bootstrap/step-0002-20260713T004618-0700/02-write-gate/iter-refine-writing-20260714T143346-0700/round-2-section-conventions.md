# Round 2: Section Conventions

Started: 2026-07-14T14:47:00-07:00
Completed: 2026-07-14T14:52:05-07:00
Phase: BOOTSTRAP
Gate: WRITE_GATE
Parent step: `docs/tmp/bootstrap/step-0002-20260713T004618-0700/`
Run directory:
`docs/tmp/bootstrap/step-0002-20260713T004618-0700/02-write-gate/iter-refine-writing-20260714T143346-0700/`

## Objective

Run `iter-refine-writing` Round 2 section-convention review on the paper after
Rounds 0--1. Preserve fixed RQs and the accepted BOOTSTRAP contract while
checking abstract roles, introduction roles, design goal conventions,
RQ-organized evaluation, related-work grouping, and conclusion structure.

## Inputs Read

- `docs/user-instruction.md`
- Active WRITE_GATE entry
- Round 0 and Round 1 reports
- Complete paper under `docs/paper/`
- Round 2 read-only subagent report

## Raw Subagent Findings

Must-fix:

- Abstract was at the lower bound and skipped the intro's explicit challenge
  role. Add one challenge sentence covering lookup/readdir placement, bounded
  kernel validation, and same-oracle comparison.

Should-fix:

- Fold the evaluation preview into the system/method role before the
  contribution list.
- Collapse the design goals into two to four clear named goals derived from
  Motivation.
- Evaluation setup lacks concrete hardware/software/run-count/warmup/baseline
  settings; this is blocked on final runs.
- Related Work `Source Workload Systems` remained too long and mixed
  source-oracle details with mechanism comparison.

Consider:

- Replace the conclusion's future-evidence sentence with evidence-backed RQ
  answers once final evidence exists.
- `Unanswered status` blocks are acceptable for this WRITE_GATE state but must
  become evidence-backed answers before submission.

## Fixes Applied

Applied must-fix:

- Added an abstract challenge sentence while keeping the abstract in the
  200--300 word range and preserving eight role-aligned sentences.

Applied should-fix:

- Folded the introduction's evaluation preview into the \namei system paragraph
  before the contribution list.
- Rewrote the design-goal table into four explicit goals:
  expressiveness, lower-FS ownership, cost boundary, and fail-closed safety.
- Compressed Related Work's source workload section into one comparative
  paragraph, leaving workload-source details in Motivation/Evaluation.

Deferred should-fix:

- Concrete hardware/software/run-count/warmup/baseline settings are not yet
  available because final runs have not executed. The Evaluation section keeps
  this as recorded final-run metadata rather than inventing values.

Deferred consider:

- The conclusion remains a design thesis plus evaluation promise until final RQ
  evidence exists.
- `Unanswered status` paragraphs remain because BOOTSTRAP WRITE_GATE must not
  invent final results.

## Verification

Compilation command:

```text
make -C docs/paper paper
```

Result: passed and up to date.

PDF evidence:

- path: `.build/paper/main.pdf`;
- page count: 14;
- no LaTeX fatal error.

Checks:

```text
perl ... abstract word count
```

Result: approximately 210 words.

```text
rg -F '\item[RQ' docs/paper/sections/05-evaluation.tex | wc -l
```

Result: `3`.

```text
rg -n "table-only|table_redirect|negative result|killer experiment|TODO|PLACEHOLDER|FIXME|BOOTSTRAP" docs/paper -g '*.tex'
```

Result: no matches.

## Claim Preservation Check

- The RQ set remains exactly three RQs.
- Contribution remains design plus implementation.
- The paper names two complete primary experiment matrices and keeps
  service/config conditional.
- FUSE remains RQ2; custom or stackable filesystems remain RQ3.
- No source characterization row became a main contribution.

## Next Node

Proceed to Round 3, logic flow. It should check the whole-paper argument from
abstract through conclusion, including whether the paper now tells one coherent
story without shrinking the hypothesis or overclaiming missing evidence.
