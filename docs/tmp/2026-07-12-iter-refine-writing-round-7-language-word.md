# Iter-Refine-Writing Round 7: Language, Word Choice

Started: 2026-07-12 02:53 PDT.
Completed: 2026-07-12 03:04 PDT.

Cycle context: standalone continuation of the current WRITE gate after
`iter-refine-ideas` and writing rounds 0 through 6.

Objective: improve word choice, remove draft-internal wording, and reduce
jargon-heavy phrasing without changing the idea, RQs, workload set, evidence
status, citations, or numbers.

## Files And Sources Read

- `docs/paper/main.tex`
- `docs/paper/sections/01-introduction.tex`
- `docs/paper/sections/02-background.tex`
- `docs/paper/sections/02-motivation.tex`
- `docs/paper/sections/03-design.tex`
- `docs/paper/sections/05-evaluation.tex`
- `docs/paper/sections/06-related-work.tex`
- `docs/paper/sections/07-limitations.tex`
- `docs/paper/sections/08-conclusion.tex`
- `docs/evaluation.md`
- `docs/background-related-work.md`

No skill files were modified.

## Method

A read-only subagent reviewed the paper using the Round 7 word-choice checklist:
jargon inflation, compound terms, nominalizations, vague referents, redundant
hedging, verbose phrases, and draft-internal wording. The main agent applied
local edits and then rebuilt the paper.

## Raw Subagent Findings

Must-fix findings:

- `main.tex`, `01-introduction.tex`, and `08-conclusion.tex` used "current
  source ledger", which reads like internal draft/project terminology.
- `05-evaluation.tex` used "owner matrix" instead of the established term
  "ownership matrix".

Should-fix findings:

- `02-motivation.tex` contained defensive prose around the source evidence
  table.
- `02-motivation.tex` used "path-view slice", which is compact but
  jargon-heavy.
- `02-motivation.tex` used "should reuse", which reads like a TODO instead of
  a rule for the representative workload.
- `03-design.tex` used inflated wording: "maximal filesystem expressiveness".
- `02-background.tex` used informal "policy-versus-ownership shape".
- `05-evaluation.tex` used draft/report wording: "This evidence block".
- `07-limitations.tex` used weak procedural wording: "the interpretation should
  narrow".
- `06-related-work.tex` used vague "different ownership point".

Consider findings:

- The abstract contained a dense source-family compound.
- The third introduction contribution packed several terms into one item.
- Related work used abstract "Their existence sharpens the boundary".

## Applied Fixes

- Replaced "current source ledger" with "source characterization currently
  supports..." in the abstract, introduction, and conclusion.
- Split the abstract source-family sentence into two sentences: one for the
  source families and one for evidence status/out-of-model separation.
- Split the third contribution item in the introduction so the protocol and its
  trace/baseline evidence are easier to scan.
- Replaced "policy-versus-ownership shape" with
  "policy-versus-ownership separation" in the background.
- Rewrote the source evidence table purpose sentence to characterize the
  recurring path-view subproblem, record evidence limits, and select
  representative KVM workloads.
- Replaced "path-view slice" in paper prose/table headers with "path-view
  portion" or "path-view behavior" where appropriate.
- Replaced "should reuse" with a concrete representative-workload statement.
- Replaced "maximal filesystem expressiveness" with "build a fully expressive
  filesystem".
- Replaced "owner matrix" with "ownership matrix" in the paper and
  `docs/evaluation.md`.
- Rewrote RQ4 wording to classify out-of-model effects directly.
- Replaced weak procedural discussion wording with "A failing result narrows..."
- Replaced "different ownership point" with "narrower ownership boundary".
- Replaced "Their existence sharpens the boundary" with a direct statement that
  metadata-service systems clarify `namei_ext`'s boundary.
- Synchronized `docs/background-related-work.md` so it no longer says
  `namei_ext` "should reuse" source workloads in a way that could imply
  replacement claims.

## Rejected Or Deferred Fixes

- Kept compact family labels such as `agent/workspace`, `environment/cache`,
  and `service/config` because they are now established family names across the
  paper and active docs.
- Did not reformat dense tables in this round. The build warnings are table
  layout issues, not word-choice issues, and should be handled in a later figure
  or table-formatting pass if needed.

## Preservation Checks

- RQs unchanged.
- No numbers changed.
- No citation commands removed.
- Evidence-status claims remain explicit: representative KVM workloads still
  gate mechanism-sufficiency and boundary-value claims.
- Skill files were read only and not modified.

## Validation

Commands run:

```sh
make -C docs/paper check
make -C docs/paper paper
rg -n "undefined|Undefined|Overfull|LaTeX Warning: There were undefined|Reference .* undefined" .build/paper/main.log || true
git diff --check
rg -n "current source ledger|source ledger|owner matrix|path-view slice|path-view slices|should reuse|policy-versus-ownership shape|This evidence block|the interpretation should narrow|different ownership point|Their existence sharpens|paper-facing|Draft synchronized|current draft|Current answer|restored idea|two-case|conceptual shrinkage|full OSDI|OSDI/SOSP|table-only|C8|precomputed-map|table-centered|static-table|two-transition|table_redirect" docs/paper docs/idea-story.md docs/evaluation.md docs/background-related-work.md docs/implementation.md research || true
```

Results:

- `make -C docs/paper check`: passed.
- `make -C docs/paper paper`: passed, producing
  `.build/paper/main.pdf` with 14 pages.
- Hard LaTeX warning scan: no matches for undefined references or overfull boxes.
- `git diff --check`: passed.
- Targeted word-choice and old-route scan over active docs and paper: no
  matches.

Remaining concern: the tables are still dense and create underfull hbox
warnings, but they compile and preserve the current evidence/status detail.

Next node: Round 8, terminology and claim tone.
