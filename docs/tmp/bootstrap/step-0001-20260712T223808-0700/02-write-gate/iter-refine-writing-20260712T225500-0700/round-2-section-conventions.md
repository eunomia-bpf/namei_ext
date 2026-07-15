# Round 2 Section Conventions

Started: 2026-07-12T23:14:00-0700  
Completed: 2026-07-12T23:19:09-0700  
Phase: BOOTSTRAP  
Step: step-0001-20260712T223808-0700  
Gate: 02-write-gate  
Parent node: round-1-micro-structure  
Status: completed

## Question And Entry

This round checked whether the current draft follows systems-paper section
conventions while preserving the accepted BOOTSTRAP meaning. Writing was
allowed to improve expression and structure only; it could not change RQ
meaning or present missing results as final evidence.

## Inputs And Method

A read-only reviewer invoked `check-paper-structure-flow` with section-specific
conventions. The reviewer read:

- `docs/user-instruction.md`
- `docs/idea-story.md`
- all current LaTeX under `docs/paper/`

Review scope: abstract structure, introduction roles, contribution list,
design goals and invariants, RQ-organized Evaluation, related-work grouping,
conclusion structure, and BOOTSTRAP placeholders.

## Raw Review Findings

Must-fix:

- The abstract and contribution #3 still presented an "evaluation program" as a
  paper contribution rather than as BOOTSTRAP evidence slots.
- Experimental Setup gave discipline rules but lacked conventional setup
  fields such as hardware, kernel version, run count, warmup, measurement
  method, and concrete FUSE/custom-boundary baselines.
- Design goals listed R1--R6, but the list did not map cleanly to RQ1/RQ2/RQ3
  or contributions; the provenance item was an evaluation requirement rather
  than a design invariant.

Should-fix:

- Motivation's Source Evidence and Representative Workloads overlapped and
  listed many systems, risking a scattered workload-sampling impression.
- Design leaked implementation-level names such as `SELECT_TARGET` and
  low-level VFS details.
- Related Work grouped FUSE cost context with custom/stackable safety-boundary
  context, blurring the fixed RQ2/RQ3 split.
- Implementation lacked a conventional implementation summary with kernel
  base, code size, and integration modes.

Consider:

- Conclusion should receive a result-backed final sentence after experiments
  exist.
- Rename `07-limitations.tex` to `07-discussion.tex` later.

## Applied Fixes

`docs/paper/main.tex`:

- Replaced "evaluation program" language with explicit BOOTSTRAP evidence-slot
  language in the abstract.

`docs/paper/sections/01-introduction.tex`:

- Changed contribution #3 to an evaluation contract with explicit BOOTSTRAP
  evidence TODOs rather than a completed evaluation contribution.

`docs/paper/sections/05-evaluation.tex`:

- Added a setup placeholder after Experimental Setup with required hardware,
  kernel, image, run-count, warmup, confidence-interval, cache protocol, FUSE,
  and custom/stackable boundary fields.

`docs/paper/sections/03-design.tex`:

- Replaced the R1--R6 checklist table with four design goals mapped directly to
  RQ1/RQ2/RQ3.
- Removed `SELECT_TARGET` from Design, replacing it with mechanism-level
  registered-target language.
- Replaced low-level `dcache/namei` phrasing with "ordinary VFS path resolution
  invariants."

`docs/paper/sections/02-motivation.tex`:

- Reduced source listing to two headline source families plus one conditional
  service/config family.
- Clarified that neighboring systems are context, not separate main evaluation
  rows.
- Compressed Representative Workloads into a small admitted workload set.

`docs/paper/sections/06-related-work.tex`:

- Split the first related-work group into `FUSE Policy Services` for RQ2 and
  `Custom And Stackable Filesystem Boundaries` for RQ3.

`docs/paper/sections/04-implementation.tex`:

- Added an explicit BOOTSTRAP implementation-summary TODO for kernel base,
  patch size, code size, integration modes, and final KVM Make targets.

## Rejected Or Deferred Fixes

- The conclusion result sentence is deferred until valid experiments exist.
  Writing one now would fabricate result-backed evidence.
- Renaming `07-limitations.tex` is deferred to avoid broad file churn in a dirty
  worktree. The section title is already `Discussion`, and the input order is
  correct.

## Verification

Commands:

```sh
make -B -C docs/paper
pdfinfo /home/yunwei37/workspace/namei_ext/.build/paper/main.pdf | rg '^Pages:'
rg -n 'evaluation program|evaluation structure|will evaluate|SELECT_TARGET|dcache/namei|FUSE places policy|table_redirect|table-only|static-table|Status: unanswered|Evidence TODO' docs/paper
```

Results:

- `make -B -C docs/paper` completed successfully.
- The PDF is 13 pages.
- Paper-facing keyword scan shows no table-only/static-table/table_redirect
  novelty line, no lingering "evaluation program" phrase, and no Design-level
  `SELECT_TARGET` or `dcache/namei` leakage.
- The remaining matches are intentional BOOTSTRAP `Status: unanswered` and
  `Evidence TODO` placeholders.

## Scientific Impact And Decision

Round 2 keeps the story ambitious while making the draft more honest about
BOOTSTRAP state. The paper now has an evaluation contract instead of a pretend
result contribution, Design goals that map to RQs, a small workload set, and a
clean RQ2/RQ3 related-work split.

## Completion And Next Action

Round 2 completed. Next node: Round 3 logic flow. The next reviewer should
check whether the complete paper supports the claims, contains logic gaps, and
tells the same story from abstract through conclusion without changing the
accepted RQ meanings.
