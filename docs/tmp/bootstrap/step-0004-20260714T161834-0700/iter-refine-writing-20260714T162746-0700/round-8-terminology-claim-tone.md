# Round 8: Terminology And Claim Tone

## Skill Route

- `iter-refine-writing`, round 8.
- Reviewer scopes:
  - `check-terminology-infoflow` for invented terms, definition order, synonym
    drift, and cross-section concept consistency.
  - `paper-writing-style` for self-attacking sentences and claim tone.
- Review mode: read-only subagent; main agent applied fixes.

## Findings

The reviewer found three must-fixes:

1. `registered target` drifted from the protected current prototype scope,
   which is `registered directory-target`.
2. The abstract phrase `current draft leaves...` read like an internal status
   report rather than a paper claim.
3. `Unanswered:` closures in Evaluation read like internal planning prose.

The reviewer also flagged `source-oracle correctness` before `source oracle` is
defined, the `Lower-FS` abbreviation, undefined `operation-weighted` metrics,
and the one-off compound `source-native environment mechanism`.

## Fixes Applied

- Changed design text to `registered directory target in the current
  prototype`.
- Rewrote the abstract so the evaluation reports RQ results only from reviewed
  KVM runs, without saying `current draft`.
- Replaced `Unanswered:` evaluation closures with neutral RQ answer conditions
  and `Result slot` language.
- Replaced `source-oracle correctness` in the contribution paragraph with
  `correctness results derived from source systems`.
- Replaced `Lower-FS` with `Lower-filesystem`.
- Added a setup definition: operation-weighted metrics weight each policy
  action by its observed frequency in the workload trace.
- Replaced `source-native environment mechanism` with `original environment
  mechanism`.
- Replaced abstract/intro `matrices` with `workload evaluations` where the
  term appeared before the Evaluation tables.
- Replaced `oracle-relevant policy` with `policy needed by the source oracle`.

## Validation

- Ran `make -C docs/paper paper`.
- Result: build succeeded and produced `.build/paper/main.pdf`.
- Checked `.build/paper/main.log` for undefined citations/references, overfull
  boxes, and LaTeX warnings. None of those targeted failures were present.
- Known warnings remain fontspec CJK warnings and underfull hbox warnings.
- Page count after this round: 16 pages.
