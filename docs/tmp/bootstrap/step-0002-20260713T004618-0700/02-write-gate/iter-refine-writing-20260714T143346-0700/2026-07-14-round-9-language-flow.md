# Round 9: Language, Flow And Polish

## Skill Step

`iter-refine-writing` round 9: flow and polish. A read-only subagent invoked
`paper-writing-style` with flow/polish focus.

## Raw Findings

### Must-Fix

1. The Introduction used weak `This answers the challenges directly` phrasing
   after the system paragraph.
2. Evaluation used project-status phrasing, `Evidence recorded for final runs`.
3. Evaluation used `Current Limitations And Interpretation` and `current RQ
   evidence`, which read like BOOTSTRAP status.

### Should-Fix

4. Related Work opened with six short boundary sentences.
5. Implementation used two short status sentences for directory-target versus
   final-file target selection.
6. The experiment-shape caption said `The paper is organized around...`, which
   is meta.
7. Motivation used `In this paper, a transition is...`, which interrupted the
   definition flow.
8. Implementation used two short validation-policy sentences about host-only
   diagnostics.
9. The conclusion should eventually end with RQ answers after results exist.

### Consider

10. Motivation used the meta sentence `This section identifies...`.
11. Design used `This narrow name-resolution boundary...`.
12. Discussion used `The evaluation tests whether...`, which should become
    result language after results exist.

## Fixes Applied

- Rewrote the Introduction challenge-answer transition as:
  `Together, these choices answer the three challenges...`
- Renamed `Evidence recorded for final runs` to `Measurement protocol` and
  rewrote the paragraph around reported runs.
- Renamed `Current Limitations And Interpretation` to `Interpretation Scope`.
- Rephrased final-file target selection scope as evidence scope rather than
  project status.
- Rewrote the Related Work opening as an ownership ladder paragraph.
- Merged the Implementation directory-target and final-file-target sentences.
- Replaced `The paper is organized...` with `The evaluation has two primary
  matrices...`
- Replaced `In this paper...` with `Within this definition...`
- Merged host-only diagnostics into one validation-scope sentence.
- Replaced the Motivation meta transition with `The source-system evidence
  below...`
- Replaced `This narrow name-resolution boundary` with `The name-resolution
  boundary`.

## Fixes Deferred

- The conclusion was not rewritten to answer RQ1/RQ2/RQ3 because final result
  values do not exist yet.
- The Discussion sentence `The evaluation tests whether...` was not rewritten
  to `The results show...` because that would imply completed evidence.

## Validation

- `make -C docs/paper paper` passed.
- The generated PDF is `/home/yunwei37/workspace/namei_ext/.build/paper/main.pdf`.
- Abstract length is 247 words.
- Page count remains 15.
- Targeted grep no longer matches the Round 9 flagged phrases except the
  deferred Discussion result-dependent sentence.

## Remaining Risks

- Evaluation and conclusion still need result-backed answer prose after final
  runs.
- The draft remains over a typical 12-page OSDI/SOSP budget.
