# Round 3 Logic Flow

Started: 2026-07-12T23:20:00-0700  
Completed: 2026-07-12T23:24:10-0700  
Phase: BOOTSTRAP  
Step: step-0001-20260712T223808-0700  
Gate: 02-write-gate  
Parent node: round-2-section-conventions  
Status: completed

## Question And Entry

This round checked the complete-paper logic chain after section-convention
cleanup. The fixed meaning remained read-only: `namei_ext` is a
`sched_ext`-style VFS name-resolution extension point, RQ1 is
expressiveness/sufficiency, RQ2 is cost versus feature-equivalent FUSE, RQ3 is
safety/boundary versus custom or stackable filesystems, and table-only/static
table novelty is retired.

## Inputs And Method

A read-only reviewer read:

- `docs/user-instruction.md`
- `docs/idea-story.md`
- `docs/paper/main.tex`
- every included file under `docs/paper/sections/`

The reviewer did not invoke `iter-review-critique`; this was a WRITE_GATE
logic-flow pass only.

## Raw Review Findings

Must-fix:

- RQ1 listed AgentFS lifecycle oracles such as COW, whiteout, symlink,
  cache-state, branch, and checkpoint in a way that could make `namei_ext` look
  like a filesystem.
- Design and abstract implied registered-target selection broadly works, while
  Implementation says the prototype currently supports directory targets and
  fails closed for final-file target selection.
- "AgentFS-derived lifecycle" and "environment/cache transition" were workload
  categories, not concrete enough for a paper-shaped evidence contract.
- Contribution #3 was still a BOOTSTRAP evaluation contract, not a delivered
  evaluation result.

Should-fix:

- The design-goal table mapped workload-scoped policy to RQ2, but RQ2 needs a
  cost-specific goal.
- Implementation phrasing made "each validated run records..." sound like final
  validation already exists.
- Related Work blurred source workload systems with mechanism boundary
  comparisons.

Consider:

- Service/config should remain explicitly conditional wherever it appears.
- Rename `07-limitations.tex` to `07-discussion.tex` later.

## Applied Fixes

`docs/paper/main.tex` and `docs/paper/sections/01-introduction.tex`:

- Made service/config "conditional breadth" rather than a peer source family.
- Kept contribution #3 explicitly as a BOOTSTRAP evaluation contract with
  evidence TODOs. This is a draft-only state; it must be replaced with
  result-backed evaluation contribution text after RQ evidence exists.

`docs/paper/sections/05-evaluation.tex`:

- Added a workload-admission table with source/state, path operation/effect,
  oracle, and delegated behavior/status.
- Made the table's caption explicit: only the path operation/effect column is
  `namei_ext` evidence; delegated behavior remains outside the boundary.
- Changed RQ1 prose so workloads are admitted only for their name-resolution
  slice, while runtime orchestration, storage state, synthetic contents, write
  handling, and lifecycle behavior remain delegated.
- Used ragged-right table columns to improve paper-facing layout.

`docs/paper/sections/04-implementation.tex`:

- Marked final-file target selection as a BOOTSTRAP implementation gap required
  before cache or service/config rows that need file-object selection can become
  headline evidence.
- Rephrased final validation logging as a validation path/reporting contract,
  not as completed final evidence.

`docs/paper/sections/03-design.tex`:

- Added an RQ2-specific design goal: avoid filesystem-service mediation on name
  operations.

`docs/paper/sections/06-related-work.tex`:

- Clarified that source workload systems are workload sources, not direct cost
  baselines.
- Kept FUSE in RQ2 context and custom/stackable filesystem boundaries in RQ3
  context.

`docs/paper/sections/02-motivation.tex`:

- Rephrased AgentFS evidence so COW/whiteout/cache-like behavior is not
  presented as `namei_ext` evidence. The paper now says AgentFS exposes
  workspace traces from which path-selection and visibility oracles can be
  extracted.

`docs/paper/sections/08-conclusion.tex`:

- Rephrased service/config as conditional breadth.

## Rejected Or Deferred Fixes

- The contribution #3 replacement with result-backed evaluation text is
  deferred until real RQ data exist.
- The file rename from `07-limitations.tex` to `07-discussion.tex` is deferred
  to avoid nonessential churn in the current dirty worktree.

## Verification

Commands:

```sh
make -B -C docs/paper
pdfinfo /home/yunwei37/workspace/namei_ext/.build/paper/main.pdf | rg '^Pages:'
rg -n 'conditional service/config|service/config systems|evaluation program|will evaluate|SELECT_TARGET|dcache/namei|table-only|table_redirect|static-table|Status: unanswered|Evidence TODO|final-file target|Workload admission' docs/paper
```

Results:

- `make -B -C docs/paper` completed successfully.
- The PDF is 14 pages, still within the 12--14 page BOOTSTRAP draft target.
- The paper-facing scan shows only intentional BOOTSTRAP placeholders and
  admission/boundary language. No table-only/static-table/table_redirect
  novelty line appears in the paper.
- LaTeX still reports underfull hbox warnings in Evaluation prose, but no
  fatal errors.

## Scientific Impact And Decision

Round 3 fixes the most important logic-flow risk: the draft no longer suggests
that `namei_ext` owns full AgentFS, cache, checkpoint, COW, or service behavior.
It now says exactly what is evidence for `namei_ext`: source-derived path
selection and visibility effects under the same oracle, with broader source
behavior delegated.

## Completion And Next Action

Round 3 completed. Next node: Round 4 abstract/intro rebuild. The next pass is
owned by the main agent through the `rewrite-abstract-intro` skill and must
preserve the accepted RQs and BOOTSTRAP evidence state.
