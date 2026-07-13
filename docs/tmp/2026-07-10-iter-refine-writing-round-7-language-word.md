# Iter Refine Writing Round 7: Language Word Choice

Date: 2026-07-10

## Findings

Subagent finding summary:

- The abstract used `decomposition` as a vague action and mixed classification
  and implementation into one sentence.
- The introduction used `planned deliverables`, which read like a project plan
  rather than paper contributions.
- Motivation used the invented phrase `evidence contract` and status-report
  wording.
- Design used outline-like `First, it... Second, it...` prose and a defensive
  `apparent success` phrase.
- Implementation used repository-process wording rather than paper prose.
- Evaluation had repeated TODO-like result wording and vague baseline
  referents.
- Related Work used defensive `straw-man` wording.
- Conclusion used vague `natural baselines`.

## Changes Made

- `docs/paper/main.tex`
  - Replaced vague `decomposition` phrasing with explicit classification before
    mechanism.

- `docs/paper/sections/01-introduction.tex`
  - Replaced repeated `insight` wording with a direct statement about separating
    state-dependent object selection from namespace materialization and
    filesystem-service ownership.
  - Changed `planned deliverables` to `planned contributions`.

- `docs/paper/sections/02-motivation.tex`
  - Replaced `evidence contract` with a concrete description of table fields.

- `docs/paper/sections/03-design.tex`
  - Replaced outline-like prose with one direct design sentence.
  - Replaced `apparent success` with neutral evidence wording.

- `docs/paper/sections/04-implementation.tex`
  - Rewrote Make workflow prose as paper-facing evaluation provenance.

- `docs/paper/sections/05-evaluation.tex`
  - Rewrote baseline roles with concrete subjects.
  - Replaced repeated results TODO wording with one evaluation-output sentence.

- `docs/paper/sections/06-related-work.tex`
  - Removed defensive `straw-man` wording.

- `docs/paper/sections/08-conclusion.tex`
  - Replaced `natural baselines` with `source-system, standalone FUSE, and
    materialized baselines`.

## Verification

- `make -C docs/paper` passed and produced `.build/paper/main.pdf`.
- `git diff --check` passed.
- The LaTeX log has no overfull boxes, undefined references, or undefined
  citations.
- Fixed-string checks found no remaining `planned deliverables`, `evidence
  contract`, `apparent success`, `straw-man`, `natural baselines`, or repeated
  result-report TODO phrase.
- Citation-site count remained 12.
- PDF page count is 10.

## Remaining Concerns

- Scope-bearing words such as `oracle`, `claim`, and `boundary` remain frequent
  by design. Later tone/flow rounds should reduce only nonessential repetition.
