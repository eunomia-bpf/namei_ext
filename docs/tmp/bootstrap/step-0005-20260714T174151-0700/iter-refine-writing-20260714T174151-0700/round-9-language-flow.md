# Round 9: Language Flow And Polish

Started: 2026-07-15T01:23:00-0700  
Completed: 2026-07-15T01:39:00-0700

Parent step: `docs/tmp/bootstrap/step-0005-20260714T174151-0700/step-report.md`

## Objective

Check topic/stress position, old-to-new information flow, paragraph transitions,
register consistency, and whether text reads like a systems paper rather than a
project report.

## Review Method

Spawned one read-only subagent to invoke `paper-writing-style` with flow and
polish focus. The subagent did not edit files.

## Raw Findings

Must-fix findings:

- Abstract ended on evaluation-table organization.
- Introduction's evaluation paragraph led with structure rather than takeaway.
- Contribution 3 remained noun-heavy.
- Motivation introduced `source oracle` before explaining why source systems
  mattered.
- RQ paragraphs ended with draft-status text instead of evidence-shape prose.
- Conclusion closed on remaining evidence rather than the systems lesson.

Should-fix findings:

- One `SELECT_TARGET` notation instance still used the escaped form.
- Several topic sentences used vague phrases such as "This separation,"
  "The design has four goals," and "The prototype maps."
- Discussion repeated thesis vocabulary instead of extracting the broader
  programmable-hook lesson.

## Applied Fixes

- Rewrote the abstract ending to state that the evaluation uses the same
  workload correctness condition to compare \namei with FUSE and identify
  responsibilities outside the hook.
- Rewrote the Introduction evaluation paragraph to lead with the three-way
  question: sufficiency, FUSE placement cost, and containment versus broader
  filesystem ownership.
- Rewrote contribution 3 to hold workload correctness fixed while comparing
  \namei with FUSE and recording responsibilities that would move into custom or
  stackable filesystems.
- Reordered the Motivation source-oracle paragraph so source systems motivate
  workload and correctness-condition selection before the term is introduced.
- Replaced per-RQ `Unanswered` status paragraphs with required-evidence
  paragraphs, and moved draft-status text to Evaluation Scope.
- Rewrote the Conclusion to close on the systems lesson, not on missing
  evidence.
- Fixed topic sentences in Background, Design, Implementation, and Discussion.
- Standardized the remaining `SELECT_TARGET` notation.

## Verification

- `make -C docs/paper paper` succeeded.
- Output PDF: `.build/paper/main.pdf`, 15 pages.
- Fixed-string grep found no `\code{SELECT\_TARGET}` occurrences.
- Grep found no target status phrases: `evaluation tables`, `result slots`,
  `The result structure`, `Final answer field`, `Unanswered`, `source oracle
  is`, `The prototype maps`, `This separation`, `The design has four goals`,
  `The evaluation defines`, or `final answer awaits`.

## Next Node

Proceed to Round 10 citation gate.

