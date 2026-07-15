# Round 4: Abstract And Introduction Rebuild

Started: 2026-07-15T00:12:00-0700  
Completed: 2026-07-15T00:24:00-0700

Parent step: `docs/tmp/bootstrap/step-0005-20260714T174151-0700/step-report.md`

## Objective

Rebuild the abstract and introduction role flow while preserving the fixed
scientific contract, RQ meanings, citations, and result-placeholder status.

## Required Skill Inputs

Read:

- `rewrite-abstract-intro/SKILL.md`
- `rewrite-abstract-intro/references/abstract-intro-revision.md`
- `rewrite-abstract-intro/references/abstract-intro-structure.md`

## Role Mapping And Reorganization Plan

| Current intro content | Target role | Decision |
| --- | --- | --- |
| Workload examples: agents, environment/cache, service/config | Background/context | Keep. |
| Wrong pathname binding consequences | Problem | Keep. |
| Boundary mismatch between lookup-time state and lower-FS ownership | Root cause | Keep as separate paragraph because the design insight answers it. |
| Namespace construction, eBPF LSM, FUSE/custom FS boundaries | Existing solutions | Keep. |
| Missing boundary is policy at VFS name resolution | Insight | Keep. |
| Lookup/readdir placement, bounded validation, same-oracle comparison | Challenges | Keep. |
| `namei_ext` as `sched_ext`-style VFS extension point | This-paper/system | Keep. |
| RQ1/RQ2/RQ3 and workloads | Methodology/result structure | Reword to consistent result-slot language. |
| Contribution list | Contributions | Convert to `itemize` deliverables. |

Abstract mapping:

- Sentence 1: background.
- Sentence 2: problem.
- Sentence 3: root cause.
- Sentence 4: existing boundary options.
- Sentence 5: insight.
- Sentence 6: realization challenge.
- Sentence 7: system.
- Sentence 8: result slots.

No new claim, number, citation, or RQ was introduced.

## Applied Fixes

- Rebuilt the abstract from the introduction role sequence and kept it at eight
  sentences.
- Rephrased the final abstract sentence as result slots, not completed results.
- Changed Introduction's evaluation paragraph to "result structure" language
  and RQ verbs that match the fixed RQ meanings.
- Converted the contribution list from `enumerate` to `itemize` deliverables.
- Kept contribution 3 as an evaluation-structure deliverable because final
  result rows do not yet exist.

## Verification

- `make -C docs/paper paper` succeeded.
- Output PDF: `.build/paper/main.pdf`, 15 pages.
- Citation-key audit after the round: 66 cite-key uses, 31 unique keys, unchanged
  from Round 3.

## Open Item

The abstract and contribution 3 still cannot become final result sentences until
BUILD_AND_EVALUATE produces reviewed source-oracle KVM/FUSE/RQ3 evidence. This
is a result-evidence gap, not a BOOTSTRAP writing defect.

## Next Node

Proceed to Round 5 consistency review.

