# Round 4: Abstract And Introduction Rebuild

Started: 2026-07-14T17:00:00-0700
Completed: 2026-07-14T17:04:00-0700
Parent step: `docs/tmp/bootstrap/step-0004-20260714T161834-0700/`
Objective: apply the `rewrite-abstract-intro` role-mapping procedure and
repair the opening only if role or logic-chain defects remain.

## Inputs

- Paper source after Round 3
- `rewrite-abstract-intro/SKILL.md`
- `rewrite-abstract-intro/references/abstract-intro-revision.md`
- `rewrite-abstract-intro/references/abstract-intro-structure.md`
- `check-paper-structure-flow/references/full-paper-12p.md`

## Role Mapping And Diagnosis

Abstract:

| Sentence role | Current content | Verdict |
| --- | --- | --- |
| Background | Modern agent, build, and service systems construct task-specific filesystem views. | Present. |
| Problem | Wrong pathname binding can corrupt workspace/cache/config behavior. | Present. |
| Root cause | Workload state changes pathname-to-object selection while lower-FS semantics should remain below. | Present. |
| Existing solutions | Namespace materialization, security hooks, and FUSE/custom boundaries sit around the need. | Present. |
| Insight | The missing narrow boundary is VFS name-resolution policy. | Present. |
| Challenge | Policy must run at lookup/readdir, return bounded actions, and remain comparable. | Present. |
| System | `namei_ext` is a `sched_ext`-style VFS extension point. | Present. |
| Implementation | Linux prototype implements one attach-path decision function and bounded action validation. | Present. |
| Evaluation/status | Agent/workspace and environment/cache matrices have explicit RQ result slots pending reviewed KVM runs. | Present and intentionally placeholder-shaped for BOOTSTRAP. |

Introduction:

| Paragraph | Role | Verdict |
| --- | --- | --- |
| 1 | Background and workload context | Present. |
| 2 | Problem and concrete consequence | Present. |
| 3 | Root cause | Present. |
| 4 | Existing mechanisms and limitations | Present. |
| 5 | Insight/thesis | Present. |
| 6 | Challenges | Present. |
| 7 | This paper/system | Present. |
| 8 | Evaluation plan/RQs | Present. |
| 9 | Contribution/deliverables | Present. |

Logic-chain check: the opening now follows the required chain: workload views
create pathname-binding risk; existing boundaries either materialize state,
mediate access, or own too much filesystem behavior; the insight is policy at
VFS name resolution; the system realizes it with bounded eBPF decisions while
the lower filesystem keeps ownership; the evaluation slots test expressiveness,
cost versus FUSE, and boundary versus custom/stackable filesystems.

## Applied Fixes

No text changes were required in this round. Rounds 1-3 had already repaired
the abstract/intro correspondence, contribution paragraph, and evaluation
status language.

Rejected changes:

- Did not replace BOOTSTRAP result placeholders with numbers because no final
  reviewed RQ evidence exists.
- Did not remove the explicit pending-result status from the abstract because
  the step must remain honest about missing RQ results.

## Verification

Commands:

```text
make -C docs/paper paper
rg -n 'undefined|Citation .* undefined|There were undefined references|Overfull' .build/paper/main.log
pdfinfo .build/paper/main.pdf | rg '^Pages|^Creator|^Producer'
```

Results:

- Paper target was up to date.
- PDF page count: 15.
- No undefined references, undefined citations, or overfull boxes were present
  in the final log.

## Preservation Check

The opening preserves the fixed RQs and the design-plus-Linux-implementation
contribution. It does not introduce table-only novelty, materialized-view
shootouts, or a weakened hypothesis.

Next round: Round 5 paper consistency.
