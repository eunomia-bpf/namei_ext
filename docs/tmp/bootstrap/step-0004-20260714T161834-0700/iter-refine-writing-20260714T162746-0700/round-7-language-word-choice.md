# Round 7: Language, Word Choice

## Skill Route

- `iter-refine-writing`, round 7.
- Reviewer scope: `paper-writing-style`, word-choice focus.
- Review mode: read-only subagent; main agent applied fixes.

## Findings

The reviewer found one must-fix and several local word-choice issues:

1. `fail through the real cgroup/namei_ext path` was ambiguous for a safety
   claim.
2. `Existing mechanisms sit on either side of this need` used a vague referent.
3. `RQ-organized evidence program` sounded like project-management prose.
4. `by strength`, `claim strength`, `source-evidence filter`, `small kernel
   extension`, `policy-relevant identifiers`, and `ownership ladder` were
   either compressed, vague, or distracting.

## Fixes Applied

- Replaced `fail through` with `are rejected on the real cgroup/namei_ext path`.
- Replaced vague or project-report phrases with direct paper prose:
  `lookup-time selection problem`, `evaluation plan organized around the three
  RQs`, `evidentiary strength`, `claims at different strengths`, `evidence
  filter`, `narrow kernel extension`, and `identifiers used by the policy`.
- Strengthened the abstract phrase from `explores this boundary` to `implements
  this boundary`.
- Replaced `ownership ladder` with `spectrum of filesystem ownership`.
- Rewrote the Agent workload related-work opening to state that agent
  filesystems are workload sources, not direct cost baselines.

## Validation

- Ran `make -C docs/paper paper`.
- Result: build succeeded and produced `.build/paper/main.pdf`.
- Checked `.build/paper/main.log` for undefined citations/references, overfull
  boxes, and LaTeX warnings. None of those targeted failures were present.
- Known warnings remain fontspec CJK warnings and underfull hbox warnings.
- Page count after this round: 16 pages.
