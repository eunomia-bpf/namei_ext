# Round 1: Micro Structure

Started: 2026-07-14T14:41:00-07:00
Completed: 2026-07-14T14:46:37-07:00
Phase: BOOTSTRAP
Gate: WRITE_GATE
Parent step: `docs/tmp/bootstrap/step-0002-20260713T004618-0700/`
Run directory:
`docs/tmp/bootstrap/step-0002-20260713T004618-0700/02-write-gate/iter-refine-writing-20260714T143346-0700/`

## Objective

Run `iter-refine-writing` Round 1 micro-structure review on the paper after
Round 0. Preserve the accepted scientific contract and fixed RQs while checking
paragraph roles, abstract/intro role flow, one-idea-per-paragraph structure, and
RQ block closures.

## Inputs Read

- `docs/user-instruction.md`
- Active WRITE_GATE entry:
  `docs/tmp/bootstrap/step-0002-20260713T004618-0700/02-write-gate/000-gate-entry-20260713T012400-0700.md`
- Round 0 report:
  `docs/tmp/bootstrap/step-0002-20260713T004618-0700/02-write-gate/iter-refine-writing-20260714T143346-0700/round-0-macro-structure.md`
- Complete paper under `docs/paper/`
- Round 1 read-only subagent report

## Raw Subagent Findings

Must-fix:

- Abstract role structure drifted: it had ten sentences and separate
  source-selection/prototype-contribution sentences after the system sentence.
- The introduction's challenge paragraph was too thin and treated evaluation
  comparability as a requirement without giving the system paragraph clear
  challenges to answer.
- `Implementation evidence slot` was a planning note in the paper's
  implementation section.

Should-fix:

- Design opening repeated ownership/invariant material.
- Policy model packed policy contract, terminology, inputs, outputs, and
  lookup/readdir coherence into one paragraph.
- Motivation provenance note sounded like project workflow.
- Implementation opening mixed implementation with Make/KVM orchestration.
- Prototype coverage mixed unsupported operations with evaluation admission.
- RQ3 subsection title omitted stackable filesystems.
- Repeated `Final-run evidence requirements` paragraphs created a planning-note
  rhythm.
- Evaluation's limitations/interpretation subsection mostly restated rules
  instead of naming current limitations.

Consider:

- Move the post-contribution evaluation sentence.
- Rename generic Design `Boundary`.
- Split the Motivation definition paragraph.
- Keep the conclusion as design thesis until final evidence exists.

## Fixes Applied

Applied must-fix items:

- Rewrote the abstract to eight role-aligned sentences: context, problem,
  existing mechanisms, insight, system, action/boundary design, prototype, and
  evaluation method/status.
- Expanded the introduction challenge paragraph into three concrete technical
  challenges: hook placement at lookup/readdir, bounded/kernel-validated output
  with lower-FS ownership, and same-oracle comparison to FUSE and broader
  filesystem boundaries.
- Added an answer sentence to the system paragraph explaining how \namei
  addresses those challenges.
- Removed the `Implementation evidence slot` planning paragraph.

Applied should-fix items:

- Consolidated the Design opening into overview plus explicit invariants and
  renamed `Design Goals And Invariants` to `Goal Mapping`.
- Split the Policy Model into separate paragraphs for the policy contract,
  transition/policy/action terminology, state/input model, action model, and
  lookup/readdir coherence.
- Rewrote the Motivation provenance paragraph as evidence-strength guidance
  rather than project workflow.
- Narrowed the Implementation opening to VFS call sites, BPF ABI, attachment,
  map setup, and kernel validation.
- Removed evaluation admission language from Prototype Coverage.
- Renamed RQ3 to `Safety And Boundary Versus Custom Or Stackable Filesystems`.
- Replaced repeated final-run requirement paragraphs with concise
  `Unanswered status` closures under each RQ.
- Rewrote Evaluation's final subsection as `Current Limitations And
  Interpretation` and named final-file target selection, conditional
  service/config, preflight-not-final evidence, and missing full KVM/FUSE/RQ3
  rows.

Applied consider items:

- Folded the dangling post-contribution evaluation sentence into the evaluation
  preview before the contribution list.
- Renamed `Boundary` to `Filesystem Ownership Boundary`.
- Split the state-dependent path-view definition from transition/policy/action
  terminology.
- Rewrote the conclusion as a design thesis and future evidence statement,
  rather than as if final evaluation had already established the claim.

## Verification

Compilation command:

```text
make -C docs/paper paper
```

Result: passed and up to date. The generated PDF is:

```text
.build/paper/main.pdf
```

PDF evidence:

- page count: 15;
- file size: 126084 bytes;
- no LaTeX fatal error;
- remaining output is font/underfull warning noise.

Search checks:

```text
rg -n "Implementation evidence slot|Final-run evidence requirements|future implementation work|Safety And Boundary Versus Custom Filesystems|Bootstrap status|TODO|PLACEHOLDER" docs/paper -g '*.tex'
```

Result: no matches.

## Claim Preservation Check

- The RQ set remains exactly three RQs.
- RQ wording and meaning remain aligned with the EXPERIMENT_GATE contract.
- The paper still treats contribution as design plus implementation.
- No table-only novelty, materialized-view shootout, or negative-result story
  was introduced.
- FUSE remains the RQ2 comparison.
- Custom or stackable filesystem ownership remains RQ3.
- Missing results are marked as unanswered evidence status rather than invented
  claims.

## Next Node

Proceed to Round 2, section conventions. That round should verify abstract and
introduction conventions, section-specific expectations, Evaluation overview,
one evidence block per RQ, related-work grouping, and conclusion structure.
