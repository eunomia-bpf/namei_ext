# Iter-Refine-Writing Round 8: Terminology And Claim Tone

Started: 2026-07-12 03:04 PDT.
Completed: 2026-07-12 03:08 PDT.

Cycle context: standalone continuation of the current WRITE gate after
`iter-refine-ideas` and writing rounds 0 through 7.

Objective: check terminology consistency, invented-term definition order,
paper-versus-artifact consistency, and claim tone. Scientific idea, RQs,
workload set, citations, evidence status, and numbers were treated as
read-only.

## Files And Sources Read

- `docs/paper/main.tex`
- `docs/paper/sections/01-introduction.tex`
- `docs/paper/sections/02-motivation.tex`
- `docs/paper/sections/03-design.tex`
- `docs/paper/sections/04-implementation.tex`
- `docs/paper/sections/05-evaluation.tex`
- `docs/paper/sections/06-related-work.tex`
- `docs/paper/sections/08-conclusion.tex`
- `docs/design.md`
- `docs/implementation.md`
- `docs/idea-story.md`
- `docs/evaluation.md`
- `docs/background-related-work.md`
- `research/RESULTS_SUMMARY.md`
- ABI evidence:
  - `bpf/include/namei_ext.h`
  - `kernel/include/uapi/linux/bpf.h`

No skill files were modified.

## Method

A read-only subagent reviewed the paper using the terminology and claim-tone
checklists. The main agent independently checked the cited ABI headers and then
applied local paper/doc edits. No kernel or BPF ABI implementation was changed
in this writing round.

## Raw Subagent Findings

Must-fix findings:

- The paper described `pass/hide/deny/select registered lower object`, but the
  current UAPI exposes only `PASS` and `REDIRECT`, with a bounded
  `redirect_name` field. This was a paper-versus-artifact mismatch.
- `mechanism sufficiency`, `boundary value`, and `same-oracle` were core terms
  used before definition.

Should-fix findings:

- Baseline terms drifted among `source-system`, `source filesystem`,
  `source/FUSE behavior`, `FUSE`, and `native`.
- `out-of-model` appeared before the boundary was explained.
- The design figure made `deny` look like a core action.
- `component` was overloaded between current input component and redirect target.
- The source evidence section slightly overclaimed with "reproduced, replayed,
  or inspected a broad set."
- `still gate`, `pending plan`, and `still needs` read like status notes.

Consider findings:

- Dense table abbreviations may slow readers.
- DeltaFS/IndexFS/TableFS as "direct baselines" could imply planned
  reproduction rather than boundary comparison.
- The Makefile help still advertises old table/C8 targets; this is an artifact
  cleanup follow-up outside the LaTeX writing round.

## Applied Fixes

- Confirmed from `bpf/include/namei_ext.h` and
  `kernel/include/uapi/linux/bpf.h` that the current action set is `PASS` and
  `REDIRECT`, and `REDIRECT` carries `redirect_name`.
- Revised `docs/paper/sections/03-design.tex` so the current prototype is
  described as pass-through plus validated same-parent replacement-component
  redirect. Hide, registered-target selection, and optional attachment-mode deny
  are now described as broader design targets, not current prototype actions.
- Revised the design figure to say: pass or same-parent redirect; extensions
  hide/select, optional deny.
- Revised `docs/paper/sections/04-implementation.tex` so the BPF ABI section
  explicitly names `PASS`, `REDIRECT`, and `redirect_name`, and so the validation
  section describes replacement-component validation rather than registered
  lower-object selection.
- Revised `docs/design.md` and `docs/implementation.md` to match the current
  prototype ABI and mark hide/registered-target/deny as design-target actions.
- Added definitions in the introduction: same-oracle, mechanism sufficiency,
  and boundary value.
- Added a baseline taxonomy in the evaluation: source-system baseline,
  filesystem-service baseline, materialized baseline, and native production
  baseline.
- Replaced `FUSE/source-system` and `source/FUSE behavior` across the active
  paper and canonical docs with the baseline taxonomy terms.
- Replaced first-use `out-of-model` in the abstract/intro with "behavior outside
  this name-resolution boundary" and defined `out-of-model` in the workload
  characterization section before using it as shorthand.
- Rewrote the source-evidence opening to "We use reproduced runs, selected
  replays, source inspection, and paper-derived oracles..." rather than a broad
  reproduction claim.
- Replaced status-note language with paper-tone evidence requirements:
  representative KVM workloads are required to establish mechanism sufficiency
  and boundary value.
- Changed DeltaFS/IndexFS/TableFS from "direct baselines" to natural comparison
  points when metadata-service ownership is required.
- Added an abbreviation note for COW, e2e, FS, and AFS in the workload
  characterization table caption.

## Rejected Or Deferred Fixes

- Did not implement hide, registered-target selection, or optional deny in the
  ABI during this writing round. The paper now treats them as design targets
  that must be implemented before they count as prototype evidence.
- Did not edit Makefile help or old table/C8 targets in this round. That is an
  artifact cleanup task, not a terminology edit, and may require Makefile scope
  review under the project rules.

## Preservation Checks

- RQ count and scientific meaning unchanged.
- No quantitative values changed.
- No citations removed.
- Prototype claims now match current ABI action set.
- Active docs and paper no longer contain the old table-only/C8/static-map
  framing.
- Skill files were read only and not modified.

## Validation

Commands run:

```sh
make -C docs/paper check
make -C docs/paper paper
rg -n "undefined|Undefined|Overfull|LaTeX Warning: There were undefined|Reference .* undefined" .build/paper/main.log || true
git diff --check
rg -n "registered lower|kernel-registered|hide, deny|pass, hide|select registered|source ledger|still gate|still needs|pending KVM|pending plan|owner matrix|same-oracle FUSE|FUSE/source-system|source/FUSE behavior|Source/FUSE|direct baselines|same-oracle source-system, FUSE|current source ledger|policy-versus-ownership shape|This evidence block|different ownership point|Their existence sharpens|Draft synchronized|current draft|Current answer|restored idea|two-case|conceptual shrinkage|full OSDI|OSDI/SOSP|table-only|C8|precomputed-map|table-centered|static-table|two-transition|table_redirect" docs/paper docs/design.md docs/implementation.md docs/idea-story.md docs/evaluation.md docs/background-related-work.md research || true
```

Results:

- `make -C docs/paper check`: passed.
- `make -C docs/paper paper`: passed, producing
  `.build/paper/main.pdf` with 15 pages.
- Hard LaTeX warning scan: no matches for undefined references or overfull boxes.
- `git diff --check`: passed.
- Targeted terminology/claim-tone scan: no matches.

Remaining concern: the paper is accurate about the current ABI, but the broader
design actions still require implementation before they can support mechanism
claims for workloads that need them.

Next node: Round 9, language flow and polish.
