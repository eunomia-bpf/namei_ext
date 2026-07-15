# Round 0: Macro Structure

Started: 2026-07-14T17:45:00-0700  
Completed: 2026-07-14T18:00:00-0700

Parent step: `docs/tmp/bootstrap/step-0005-20260714T174151-0700/step-report.md`

## Objective

Check the paper's macro structure under the fixed BOOTSTRAP scientific
contract: `namei_ext` is a `sched_ext`-style VFS name-resolution extension
point, RQ1 is expressiveness/sufficiency, RQ2 is cost versus
feature-equivalent FUSE, and RQ3 is boundary/safety versus custom or stackable
filesystem ownership.

## Inputs

- Paper entry snapshot:
  `docs/tmp/bootstrap/step-0005-20260714T174151-0700/iter-refine-writing-20260714T174151-0700/entry-snapshot/`
- Current paper under `docs/paper/`
- User intent log: `docs/user-instruction.md`

## Review Method

Spawned one read-only subagent to invoke `check-paper-structure-flow` with
Level 1 macro-structure focus. The subagent did not edit files.

## Raw Findings

Must-fix findings:

- Evaluation had explicit RQs but still read as a plan or result-slot inventory
  rather than a paper-result structure.
- Abstract and introduction overclaimed result status by saying reviewed KVM
  runs provide RQ evidence.
- The contribution paragraph called the evaluation an "evaluation plan."
- The paper remained long at 16 pages.

Should-fix findings:

- Design leaked prototype-status wording into the design model.
- Motivation mixed source-selection methodology with the workload argument.
- Discussion was too thin for the boundary claim.

Consider findings:

- Section order and RQ count were acceptable.
- The architecture figure is present but minimal.
- The high-level RQ content matches user constraints.

## Applied Fixes

- Rewrote the abstract result sentence so it no longer claims reviewed final RQ
  evidence.
- Rewrote the Introduction contribution paragraph so the contribution is the
  boundary design, implementation, and same-oracle evaluation structure rather
  than an "evaluation plan."
- Replaced the Evaluation section with a shorter RQ-organized answer structure.
  The new tables are explicit answer placeholders, not final results.
- Removed prototype-status phrasing from Design's action-model paragraph.
- Expanded Discussion to explain the `sched_ext`-style policy/ownership lesson
  and the boundary where FUSE/custom filesystems remain correct.

## Rejected Or Deferred Fixes

- Did not invent final numbers or demote the paper to only completed partial
  evidence. BOOTSTRAP permits explicit placeholders for missing result values;
  BUILD_AND_EVALUATE must fill them with reviewed KVM/FUSE/RQ3 evidence.
- Did not replace the architecture figure in this round. It is acceptable for
  macro structure; figure polish can happen in later writing or figure passes.

## Verification

- `make -C docs/paper paper` succeeded.
- Output PDF: `.build/paper/main.pdf`, 15 pages.
- Cite-key audit found that the shortened Evaluation removed one duplicate
  service/config citation command, reducing repeated Kubernetes cite counts.
  The same Kubernetes sources remain cited in Intro, Background, Motivation, and
  Related Work, so no source family disappeared.

## Next Node

Proceed to Round 1 micro-structure review.

