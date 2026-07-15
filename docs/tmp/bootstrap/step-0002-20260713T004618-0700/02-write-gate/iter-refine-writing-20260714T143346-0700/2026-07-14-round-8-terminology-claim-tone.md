# Round 8: Terminology And Claim Tone

## Skill Step

`iter-refine-writing` round 8: terminology, information flow, and claim tone.
A read-only subagent invoked `check-terminology-infoflow` in
terminology-infoflow scope and `paper-writing-style` for claim tone.

## Raw Findings

### Must-Fix

1. The abstract used the coined term `path-view` before the reader had a
   definition.
2. `source oracle`, `source-derived oracle`, `same-oracle`, and source behavior
   wording drifted around the evaluation contract.
3. Evaluation limitations and conclusion still contained BOOTSTRAP/status tone:
   `not final evidence yet`, `preflight runs`, and `will determine`.

### Should-Fix

4. `boundary` was overloaded. In particular, `G3 Cost boundary` was confusing
   because RQ2 is a placement-cost comparison, while RQ3 is the ownership
   boundary claim.
5. `source/runtime` was an internal slash shorthand.
6. The Motivation final-file prerequisite sounded like a project status update.
7. Implementation used `final file target selection` instead of
   `final-file target selection`.
8. The service/config row used internal process language such as `conditional
   KVM row` and `after admission`.

### Consider

9. `Goal Mapping` was process-style title language.
10. The design-goal table caption referred vaguely to oracles needing "more
    than these goals."
11. Related Work said `It tests whether...`, which sounded tentative.

## Fixes Applied

- Replaced abstract `real path-view policies` with `real object-selection and
  directory-visibility policies`.
- Replaced early abstract/introduction `source oracle` references with
  `same correctness condition` until the paper defines the term.
- Added a first definition in Motivation: a source oracle is the correctness
  condition extracted from the original source system, and a same-oracle KVM run
  applies that condition unchanged to `namei_ext` and comparison rows.
- Kept the Evaluation setup definition aligned with the Motivation definition.
- Replaced `Cost boundary` with `Placement cost`.
- Replaced `source/runtime` shorthand with reader-facing `source runtime`
  language.
- Rephrased final-file target support as a scope boundary rather than a project
  status apology.
- Hyphenated `final-file target selection` consistently.
- Rewrote service/config experiment shape as an included row only when a source
  oracle requires lookup-time object selection.
- Renamed `Goal Mapping` to `Name-Resolution Boundary Goals`.
- Rewrote the design-goal caption to name synthetic contents, custom metadata,
  and data-path mediation explicitly.
- Replaced tentative Related Work phrasing with a direct boundary statement.
- Replaced the conclusion's `will determine` phrasing with a result-neutral
  evaluation-structure sentence.

## Validation

- `make -C docs/paper paper` passed.
- The generated PDF is `/home/yunwei37/workspace/namei_ext/.build/paper/main.pdf`.
- Abstract length is 247 words.
- Page count remains 15.
- Targeted grep no longer matches the flagged status/process phrases:
  `real path-view`, `source-derived oracle`, `same-oracle means`,
  `source/runtime`, `source-runtime`, `final evidence yet`, `preflight`,
  `will determine`, `Cost boundary`, `after admission`, `conditional KVM`,
  `does not supply breadth`, `final file target`, `It tests whether`,
  `more than these goals`, `own a filesystem-service`, `path policy`,
  `current path-view action set`, or `not final evidence`.

## Remaining Risks

- The paper still uses `source oracle` frequently after the definition because
  it is now a core evaluation term.
- The draft still needs final result-backed RQ answer paragraphs and page-count
  compression.
