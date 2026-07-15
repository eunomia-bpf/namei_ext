# Round 1: Micro Structure

Started: 2026-07-14T16:36:00-0700
Completed: 2026-07-14T16:46:00-0700
Parent step: `docs/tmp/bootstrap/step-0004-20260714T161834-0700/`
Objective: check paragraph roles, abstract/intro correspondence, RQ block
closures, and paragraph-level flow under `check-paper-structure-flow` Levels
2-3.

## Inputs

- Paper source after Round 0
- Fixed RQs and contribution from `docs/user-instruction.md` and
  `docs/idea-story.md`
- Skill references read by the root:
  `check-paper-structure-flow/SKILL.md`,
  `check-paper-structure-flow/references/full-paper-12p.md`,
  `rewrite-abstract-intro/references/abstract-intro-structure.md`

## Raw Review Findings

Read-only reviewer: subagent `019f62fa-af94-7ea1-a73c-c38b18758e81`.

Must-fix:

- Abstract and introduction did not correspond strictly. The abstract included
  `cgroup/namei_ext`, prototype action details, final-file target gating, and
  evaluation plan phrasing without matching intro roles or explicit unanswered
  status.
- The introduction's contribution paragraph mixed the primary contribution,
  implementation details, and evaluation program without a clean deliverable
  structure.
- Evaluation RQ blocks ended with `unanswered` language but did not state what
  would answer each RQ positively or make it fail.

Should-fix:

- Motivation source-evidence paragraphs mixed evidence taxonomy, source oracle
  definition, source families, and admission rules.
- Design goals opened with the `sched_ext` analogy before naming the goals.
- Implementation repeated the final-file target selection gap in both ABI and
  prototype coverage.
- Related Work combined agent/workspace sources and environment/cache sources
  in one paragraph.

## Applied Fixes

- Rewrote the abstract's system/evaluation tail to match the intro and make
  missing RQ result slots explicit.
- Rewrote the introduction contribution paragraph as one primary contribution
  plus three concrete deliverables with section references:
  design/policy contract, Linux prototype, and RQ-organized evidence program.
- Added explicit answer/fail/evidence-TODO closures for RQ1, RQ2, and RQ3 in
  `docs/paper/sections/05-evaluation.tex`.
- Split Motivation's workload-selection evidence and selected-workload
  paragraphs so source admission, AgentFS, environment/cache, service/config,
  and workload selection each have a clearer role.
- Changed the design-goals opening sentence to name the four goals before the
  `sched_ext` analogy.
- Removed the duplicate final-file target gap sentence from the ABI subsection,
  keeping prototype coverage as the single place for that gap.
- Split the Related Work source-workload paragraph into agent/workspace and
  environment/cache source paragraphs.

Skipped or deferred:

- Did not change RQ meanings, contribution scope, workload families, or
  comparison families.
- Did not add result numbers.
- Did not remove the explicit BOOTSTRAP result placeholders because the current
  step requires them until final reviewed evidence exists.

## Verification

Commands:

```text
make -C docs/paper paper
pdfinfo .build/paper/main.pdf | rg '^Pages|^Creator|^Producer'
rg -n 'undefined|Citation .* undefined|There were undefined references|Overfull' .build/paper/main.log
rg -n 'current draft leaves|Evidence TODO|Unanswered|will fail|will be answered' docs/paper/main.tex docs/paper/sections/05-evaluation.tex
```

Results:

- Build succeeded.
- PDF page count: 15.
- No undefined references, undefined citations, or overfull boxes were present
  in the final log.
- RQ result placeholders and answer/fail criteria are explicit in the paper.

## Preservation Check

The RQs remain unchanged. The primary contribution remains design plus Linux
implementation as one systems boundary. Workload characterization remains
workload-selection evidence rather than standalone novelty. Table-only and
materialized-view shootouts were not revived.

Next round: Round 2 section conventions.
