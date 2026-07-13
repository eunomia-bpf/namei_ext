# Iter Refine Writing Round 8: Terminology And Claim Tone

Date: 2026-07-10

## Findings

Subagent finding summary:

- `W4` was an internal workload label and should not appear in paper prose.
- `in-model path-view slice` and `complete in-model slice` read like coined
  terms before the model definition.
- The abstract phrase `makes one lookup/readdir decision` could imply one
  global decision rather than one decision function per event.
- The transition-characterization caption sounded like an internal TODO.
- `this decomposition`, `the paper cannot replace it`, `where the paper wants
  to measure`, `hook`, and `supplies only` carried project-report or defensive
  tone.
- `intentionally narrow` in Limitations could be expressed as a neutral scope
  statement.

## Changes Made

- `docs/paper/main.tex`
  - Replaced `makes one lookup/readdir decision` with one decision function for
    lookup and directory-enumeration events.

- `docs/paper/sections/01-introduction.tex`
  - Replaced `W4 environment/cache transition` with
    `SWE-Factory-Gym-derived environment/cache transition`.
  - Replaced `this decomposition` with `this separation`.

- `docs/paper/sections/02-motivation.tex`
  - Replaced pre-design `in-model slice` language with
    `object-selection-and-visibility boundary`.
  - Rewrote the table caption as a KVM-evaluation instantiation statement.
  - Replaced table-row `W4` with `SWE-Factory-Gym`.

- `docs/paper/sections/03-design.tex`
  - Replaced `complete in-model path-view slice` with direct
    object-selection-and-visibility wording.

- `docs/paper/sections/04-implementation.tex`
  - Renamed `Kernel Hook Placement` to `Kernel Attachment Placement`.
  - Replaced `The hook runs` with `The attachment point runs`.

- `docs/paper/sections/05-evaluation.tex`
  - Replaced pre-design `in-model path-view slice` wording in RQ1 and the
    correctness-oracle text.
  - Expanded the first `same-oracle` use into baselines checked against the same
    correctness oracle.
  - Replaced defensive failure wording with a neutral claim-narrowing rule.

- `docs/paper/sections/06-related-work.tex`
  - Replaced project-report wording with direct comparison prose.
  - Replaced `supplies only` with `contributes`.

- `docs/paper/sections/07-limitations.tex`
  - Replaced `intentionally narrow` with a neutral scope sentence.

## Verification

- `make -C docs/paper` passed and produced `.build/paper/main.pdf`.
- `git diff --check` passed.
- The LaTeX log has no overfull boxes, undefined references, or undefined
  citations.
- Fixed-string checks found no remaining `W4`, `complete in-model slice`,
  `in-model path-view slice`, `complete in-model path-view slice`, `makes one
  lookup`, `Concrete rows must`, `this decomposition`, `paper cannot replace`,
  `where the paper wants`, `intentionally narrow`, or `supplies only`.
- Citation-site count remained 12.
- PDF page count is 10.

## Remaining Concerns

- Scope-bearing terms such as `oracle`, `boundary`, and `claim` remain frequent.
  They should be reduced only where local repetition hurts flow.
