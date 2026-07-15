# Round 8: Terminology And Claim Tone

Started: 2026-07-15T01:08:00-0700  
Completed: 2026-07-15T01:23:00-0700

Parent step: `docs/tmp/bootstrap/step-0005-20260714T174151-0700/step-report.md`

## Objective

Check invented terms, definition order, synonym drift, cross-section concept
consistency, self-attacking sentences, and claim tone while protecting honest
BOOTSTRAP result placeholders and fixed RQ meanings.

## Review Method

Spawned one read-only subagent to invoke `check-terminology-infoflow` and
`paper-writing-style` claim-tone review. The subagent did not edit files.

## Raw Findings

Must-fix findings:

- `source oracle` and ownership-evidence wording appeared in the abstract or
  contribution list before definition.
- `SELECT_TARGET` notation was inconsistent between escaped and unescaped forms.
- `ownership-boundary account` was an undefined invented term.
- The reviewer again suggested adding a synthesized current-instruction block to
  `docs/user-instruction.md`.

Should-fix findings:

- `boundary` was overloaded in several contexts.
- `state-dependent path view` was defined twice.
- RQ2's support/weakening prose read self-attacking.
- "Primary workload families" could be read as completed evidence while result
  rows are placeholders.
- "may own" weakened RQ3.

Consider findings:

- Replace the low-frequency coined phrase `non-name-resolution responsibilities`.
- Replace "This source filter selects..."
- Start the agent-workload related-work paragraph with its claim instead of
  "Here".

## Applied Fixes

- Removed `source oracle` from the abstract and contribution list before its
  Motivation definition, using "workload correctness" instead.
- Standardized all paper instances to `\code{SELECT_TARGET}`.
- Replaced `ownership-boundary account` with custom/stackable responsibility
  comparison.
- Reworded the Motivation definition so Introduction defines
  state-dependent path view and Motivation says "Under this definition..."
- Replaced `non-name-resolution responsibilities` with plain text about
  behavior outside name resolution.
- Rewrote RQ2 interpretation prose positively around correctness-gated
  feature-equivalent FUSE rows.
- Rephrased primary workload status as reported only after reviewed
  same-oracle KVM runs.
- Strengthened RQ3 rows from "may own" to "would own or mediate."
- Replaced "Here" in Related Work and "This source filter selects" in Motivation.

## Rejected Or Deferred Fixes

- Did not edit `docs/user-instruction.md` with a synthesized current-instruction
  block. That file is a verbatim user-prompt log by orchestrator rule.
- Did not remove all uses of "boundary." It remains the paper's main thesis
  word; the fix was to reduce avoidable overload, not erase the term.

## Verification

- `make -C docs/paper paper` succeeded.
- Output PDF: `.build/paper/main.pdf`, 15 pages.
- Grep found no `SELECT\_TARGET`, `ownership-boundary account`,
  `non-name-resolution responsibilities`, `source-oracle correctness`,
  `same-oracle evaluation structure`, `may own`, `RQ2 supports`, `weakens`, or
  `cannot be built` target phrases in paper source.

## Next Node

Proceed to Round 9 language-flow and polish review.

