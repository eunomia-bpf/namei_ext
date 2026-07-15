# Iter-Refine-Writing Round 9: Language Flow And Polish

Started: 2026-07-12 03:09 PDT.
Completed: 2026-07-12 03:13 PDT.

Cycle context: standalone continuation of the current WRITE gate after
`iter-refine-ideas` and writing rounds 0 through 8.

Objective: improve old-to-new information flow, topic/stress position,
paragraph transitions, and register consistency after the Round 8 ABI/prototype
clarifications. Scientific idea, RQs, current ABI facts, workload set, evidence
status, citations, and numbers were treated as read-only.

## Files And Sources Read

- `docs/paper/main.tex`
- `docs/paper/sections/01-introduction.tex`
- `docs/paper/sections/02-motivation.tex`
- `docs/paper/sections/03-design.tex`
- `docs/paper/sections/04-implementation.tex`
- `docs/paper/sections/05-evaluation.tex`
- `docs/paper/sections/06-related-work.tex`
- `docs/paper/sections/08-conclusion.tex`

No skill files were modified.

## Method

A read-only subagent reviewed the paper using the Round 9 flow/polish checklist:
topic position, stress position, old-to-new information order, paragraph
transitions, and register consistency. The main agent applied local prose edits
only.

## Raw Subagent Findings

Must-fix findings:

- The abstract ended with three status-like sentences, making the stress
  position "project status" rather than the paper's evidence boundary.
- The introduction defined `same-oracle`, `mechanism sufficiency`, and
  `boundary value` after using them, reversing the old-to-new information flow.
- The Design overview mixed design target and current prototype status before
  the mechanism story was established.

Should-fix findings:

- The workload characterization repeated "state variables are workload-local".
- The phrase "The remaining evaluation implication is..." sounded like a report
  note rather than paper prose.
- The implementation validation paragraph repeated the design section without
  adding enough implementation detail.
- Evaluation used "evidence-status blocks", which reads as draft-internal
  register.
- Related work used colon-driven classification where a causal sentence was
  clearer.

Consider findings:

- The abstract opening used a colon-led list.
- `Evidence status:` labels remain useful for the current evidence-status draft
  but should be made final-paper prose later.
- The conclusion first sentence used a colon where a direct takeaway worked
  better.

## Applied Fixes

- Rewrote the abstract opening to avoid a colon-led list.
- Rewrote the abstract ending into a single evidence-boundary sentence plus the
  KVM evidence requirement.
- Moved same-oracle, mechanism-sufficiency, and boundary-value definitions before
  the two-layer evidence paragraph in the introduction.
- Reordered the Design overview so the design boundary is stated first and the
  current prototype subset appears as status at the end.
- Removed the repeated "state variables are workload-local" construction in
  workload characterization.
- Replaced "The remaining evaluation implication is..." with a baseline-rule
  sentence.
- Reworked the Implementation validation paragraph to add implementation detail:
  copying bounded `redirect_name`, validating length/action/same-parent scope,
  and resuming the normal VFS path.
- Replaced evaluation "evidence-status blocks" wording with direct unresolved-RQ
  prose.
- Replaced related-work colon classification with a causal sentence.
- Rewrote the conclusion opening as a direct systems-boundary takeaway.

## Rejected Or Deferred Fixes

- Kept `Evidence status:` labels in RQ sections for now because the draft
  intentionally separates completed source characterization from unresolved KVM
  results.
- Did not reformat dense tables in this round. The underfull hbox warnings come
  from narrow evidence tables and can be handled in a later table/figure pass.

## Preservation Checks

- RQs unchanged.
- No quantitative values changed.
- No citations removed.
- Current ABI facts from Round 8 remain preserved.
- Active paper and docs remain clear of the old table-only/C8/static-map route.
- Skill files were read only and not modified.

## Validation

Commands run:

```sh
make -C docs/paper check
make -C docs/paper paper
rg -n "undefined|Undefined|Overfull|LaTeX Warning: There were undefined|Reference .* undefined" .build/paper/main.log || true
git diff --check
rg -n "evidence-status blocks|The remaining evaluation implication|state variables are workload-local:|The current prototype implements pass-through|The broader design target also includes|Many systems need dynamic filesystem views without requiring a new filesystem:|systems boundary problem:|These systems occupy broader filesystem boundaries:|registered lower|kernel-registered|hide, deny|pass, hide|select registered|source ledger|still gate|still needs|pending KVM|pending plan|owner matrix|same-oracle FUSE|FUSE/source-system|source/FUSE behavior|Source/FUSE|direct baselines|same-oracle source-system, FUSE|current source ledger|policy-versus-ownership shape|This evidence block|different ownership point|Their existence sharpens|Draft synchronized|current draft|Current answer|restored idea|two-case|conceptual shrinkage|full OSDI|OSDI/SOSP|table-only|C8|precomputed-map|table-centered|static-table|two-transition|table_redirect" docs/paper docs/design.md docs/implementation.md docs/idea-story.md docs/evaluation.md docs/background-related-work.md research || true
```

Results:

- `make -C docs/paper check`: passed.
- `make -C docs/paper paper`: passed, producing
  `.build/paper/main.pdf` with 15 pages.
- Hard LaTeX warning scan: no matches for undefined references or overfull boxes.
- `git diff --check`: passed.
- Flow/old-route/terminology scan: no matches.

Remaining concern: dense evidence tables still create underfull hbox warnings,
but they do not block compilation and preserve source/evidence granularity.

Next node: Round 10, citation gate.
