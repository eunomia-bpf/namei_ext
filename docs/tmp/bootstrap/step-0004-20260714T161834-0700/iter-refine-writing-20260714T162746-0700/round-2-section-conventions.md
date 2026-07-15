# Round 2: Section Conventions

Started: 2026-07-14T16:46:00-0700
Completed: 2026-07-14T16:53:00-0700
Parent step: `docs/tmp/bootstrap/step-0004-20260714T161834-0700/`
Objective: check section-specific full-paper conventions after the macro and
micro-structure repairs.

## Inputs

- Paper source after Round 1
- Fixed RQs and contribution from `docs/user-instruction.md` and
  `docs/idea-story.md`
- Skill references:
  `check-paper-structure-flow/SKILL.md`,
  `check-paper-structure-flow/references/full-paper-12p.md`

## Raw Review Findings

Read-only reviewer: subagent `019f62fe-7da8-75f0-8fe8-005c88976f9c`.

Must-fix:

- None. The reviewer found that the Evaluation section now has three fixed RQs,
  one evidence block per RQ, evidence tables, explicit `Unanswered` status,
  success/failure criteria, and `Evidence TODO` slots.

Should-fix:

- Page budget remains tight at 15 pages; Motivation and Evaluation are the
  largest future compression targets.
- The Motivation title still risked making workload characterization look like
  a standalone contribution.
- Implementation lacked a closing implementation summary.
- Discussion overlapped lightly with Evaluation limitations.
- Conclusion needs real key results before submission; until then it should
  point to explicit result slots rather than claim completed findings.

## Applied Fixes

- Renamed `Motivation And Workload Characterization` to `Motivation And
  Workloads`.
- Added an Implementation closing paragraph summarizing kernel call-site
  changes, BPF ABI definitions, eBPF policies, user-space attachment/test code,
  Make-owned KVM integration, and raw artifact preservation.
- Removed the repeated `Scope Of The Hypothesis` subsection from Discussion so
  Evaluation owns evidence gaps and scope.
- Rewrote the conclusion tail to say the evaluation is organized to fill three
  explicit result slots rather than implying completed results.

Skipped or deferred:

- Did not add code-size numbers because this writing round treats numbers as
  read-only. A later consistency/citation pass may add code-size facts only with
  a source record.
- Did not compress Motivation/Evaluation aggressively yet; later style and flow
  rounds can cut prose without changing the claim.

## Verification

Commands:

```text
make -C docs/paper paper
pdfinfo .build/paper/main.pdf | rg '^Pages|^Creator|^Producer'
rg -n 'undefined|Citation .* undefined|There were undefined references|Overfull' .build/paper/main.log
wc -w docs/paper/sections/02-motivation.tex docs/paper/sections/05-evaluation.tex docs/paper/main.tex
```

Results:

- Build succeeded.
- PDF page count: 15.
- No undefined references, undefined citations, or overfull boxes were present
  in the final log.
- Motivation: 969 words. Evaluation: 1499 words. These remain later
  compression targets.

## Preservation Check

No RQ, contribution, workload family, or comparison family changed. The paper
continues to preserve explicit BOOTSTRAP result slots rather than inventing
numbers.

Next round: Round 3 logic flow.
