# Iter-Refine-Writing Round 6: Language, Sentence Structure

Started: 2026-07-12 02:30 PDT.
Completed: 2026-07-12 02:52 PDT.

Cycle context: standalone continuation of the current WRITE gate after
`iter-refine-ideas` and writing rounds 0 through 5.

Objective: check sentence structure only. The scientific idea, RQs, claim
scope, workload set, and evidence status were treated as read-only.

## Files And Sources Read

- `docs/paper/main.tex`
- `docs/paper/sections/01-introduction.tex`
- `docs/paper/sections/02-motivation.tex`
- `docs/paper/sections/03-design.tex`
- `docs/paper/sections/04-implementation.tex`
- `docs/paper/sections/05-evaluation.tex`
- `docs/paper/sections/06-related-work.tex`
- `docs/paper/sections/08-conclusion.tex`
- `research/CLAIM_VERDICT.md`
- `docs/background-related-work.md`
- Read-only skill instructions:
  `/home/yunwei37/workspace/my-paper-work/academic-writing-skills/skills/iter-refine-writing/SKILL.md`

No skill files were modified.

## Method

A read-only subagent reviewed the paper for the Round 6 checklist:
semicolon-joined independent clauses, fragments, weak openings, colons before
unlabeled lists, subject-verb distance, and list-like prose. The main agent then
applied local subsection-sized edits and rebuilt the paper.

## Raw Subagent Findings

Must-fix findings:

- `main.tex`, `01-introduction.tex`, and `08-conclusion.tex` used semicolons to
  join evidence-status clauses. Suggested fix: split the source-ledger,
  prototype, and KVM-gate statements into separate sentences.
- `02-motivation.tex` used a semicolon between the agent oracle sentence and the
  reuse sentence. Suggested fix: split into two sentences.
- `03-design.tex` used a semicolon in the redirect-target invariant and an
  awkward "promise from userspace text" phrase. Suggested fix: split the
  invariant and rewrite registration as validated identity/lifetime.
- `04-implementation.tex` had repeated semicolon-joined independent clauses.
  Suggested fix: replace with periods or causal connectors.
- `05-evaluation.tex` had repeated semicolon-joined independent clauses in the
  protocol, interpretation, result standard, and RQ4 scope prose.

Should-fix findings:

- `main.tex` repeated "need" in the abstract opening.
- `main.tex` used vague antecedent "It then defines".
- `02-motivation.tex` repeated "This implies".
- `03-design.tex` used two colon-led policy-model sentences in a row.
- `04-implementation.tex` used the wordy phrase "This implementation choice is
  what keeps...".
- `06-related-work.tex` used informal/self-attacking "should lose, by design".

Consider findings:

- Several table rows remain dense.
- `Evidence status:` labels are less final-paper-like, but currently serve the
  intended evidence-status draft purpose.

## Applied Fixes

- Rewrote the abstract opening in `docs/paper/main.tex` from "without needing"
  to "without requiring".
- Replaced vague "It then defines" with "The paper then defines" in
  `docs/paper/main.tex`.
- Split source-ledger/prototype/KVM-gate semicolon chains into separate
  sentences in:
  - `docs/paper/main.tex`
  - `docs/paper/sections/01-introduction.tex`
  - `docs/paper/sections/08-conclusion.tex`
- Replaced the repeated "This implies" sequence in
  `docs/paper/sections/02-motivation.tex` with a causal sentence about
  workload-local state.
- Split the AgentFS/YoloFS oracle sentence in
  `docs/paper/sections/02-motivation.tex`.
- Reworked the policy-model opening in `docs/paper/sections/03-design.tex` to
  separate input and output without repeating colon-led sentence structure.
- Split the redirect-target invariant in `docs/paper/sections/03-design.tex`
  and rewrote registration as validated identity and lifetime rather than a
  userspace text promise.
- Cleaned implementation sentence structure in
  `docs/paper/sections/04-implementation.tex`, including registration,
  collector/report separation, and host-only diagnostic wording.
- Cleaned evaluation sentence structure in
  `docs/paper/sections/05-evaluation.tex`, including host-only diagnostics,
  out-of-model reporting, falsifiability wording, and RQ4 KVM-scope wording.
- Shortened the three workload rows in `docs/paper/sections/05-evaluation.tex`
  by replacing dense semicolon-separated cells with comma or causal phrasing.
- Replaced "should lose, by design" with "is out of scope by design" in
  `docs/paper/sections/06-related-work.tex`.
- Removed two active-doc instances of internal "paper-facing" language in
  `research/CLAIM_VERDICT.md` and `docs/background-related-work.md`.

## Rejected Or Deferred Fixes

- Kept the `Evidence status:` labels in the evaluation because the current draft
  intentionally distinguishes completed source characterization from unresolved
  KVM results. Removing those labels would make the paper sound more finished
  than the evidence supports.
- Kept remaining semicolons that are list punctuation in `itemize` or compact
  table cells. They are not semicolon-joined independent clauses. The tables
  still need final formatting work, but changing the table layout is outside
  this sentence-structure round.

## Preservation Checks

- RQ count and RQ meaning unchanged.
- No quantitative value changed.
- Citation commands were not removed.
- The old table-only/C8/static-map framing remains absent from active paper and
  current active docs.
- Skill files were read only and not modified.

## Validation

Commands run:

```sh
make -C docs/paper check
make -C docs/paper paper
rg -n "undefined|Undefined|Overfull|LaTeX Warning: There were undefined|Reference .* undefined" .build/paper/main.log || true
git diff --check
rg -n "Draft synchronized|current draft|paper-facing|Current answer|restored idea|two-case|conceptual shrinkage|full OSDI|OSDI/SOSP|table-only|C8|precomputed-map|table-centered|static-table|two-transition|table_redirect" docs/paper docs/idea-story.md docs/evaluation.md docs/background-related-work.md docs/implementation.md research || true
```

Results:

- `make -C docs/paper check`: passed.
- `make -C docs/paper paper`: passed, producing
  `.build/paper/main.pdf` with 14 pages.
- Hard LaTeX warning scan: no matches for undefined references or overfull boxes.
- `git diff --check`: passed.
- Old-route/internal-process phrase scan over active docs and paper: no matches.

Remaining concern: the current paper is structurally consistent and builds, but
the mechanism-sufficiency and boundary-value claims still depend on the planned
Make-owned KVM workloads.

Next node: Round 7, language word choice.
