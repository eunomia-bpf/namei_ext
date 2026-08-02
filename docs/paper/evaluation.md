# Paper Evaluation Notes

Status: routing note for the paper draft.
Last updated: 2026-08-02.

The old process-heavy evaluation plan was archived to
`docs/tmp/2026-07-25-archived-process-docs/evaluation.md` on 2026-07-25 and
replaced by a slim `docs/evaluation.md` holding only the scientific
evaluation state (use cases, matrices, results, open questions). Research
process plans, admission rules, and gates are owned by the orchestrator
skill, not by this repository.

| Need | Canonical location |
| --- | --- |
| Current paper idea, claim scope, non-goals | `docs/idea-story.md` |
| Related work, novelty risk, source-use verdicts, mandatory comparisons | `docs/background-related-work.md` |
| Source repositories, datasets, artifacts, and reproduction-record links | `docs/reference/CODE_SOURCES.md` |
| PDF inventory | `docs/reference/INDEX.md` |
| Standalone research or implementation records | `docs/tmp/YYYY-MM-DD-*.md` |
| Raw logs, JSON/JSONL, benchmark outputs, generated summaries | `results/` |
| Current handoff pointer | `research/STATE.md` |
| Complete experiment inventory | `docs/tmp/2026-07-28-complete-experiment-status.md` |
| Current workload hierarchy, data, and raw paths | `docs/tmp/2026-08-02-workload-evidence-audit.md` |
| Formal application file sharing source-oracle RQ1 review | `docs/tmp/2026-07-30-application-file-sharing-source-oracle-rq1-formal01-result-review.md` |
| Formal Agent source-task RQ1 review | `docs/tmp/2026-07-29-agent-workspace-source-task-rq1-formal01-result-review.md` |
| Formal Agent workspace RQ3 review | `docs/tmp/2026-07-28-agent-workspace-rq3-formal-v3-result-review.md` |
| Formal corrected FxMark readdir review | `docs/tmp/2026-07-29-rq2-fxmark-readdir-formal-v1-result-review.md` |
| Formal Kubernetes ConfigMap publication RQ1 result and review | `docs/tmp/2026-07-29-kubernetes-configmap-publication-rq1-result.md` |
| RQ3 target-lifetime failed preflight and deterministic repair | `docs/tmp/2026-07-31-rq3-target-lifetime-preflight01-failure-and-deterministic-repair.md` |

Current boundary:

- Do not use this file to revive workload-necessity or interface-exclusivity
  claims from older drafts.
- Do not claim that selected workloads require only eBPF or only `namei_ext`,
  or that alternative namespace mechanisms are impossible.
- Do preserve the restored paper idea: `namei_ext` is a `sched_ext`-style VFS
  extension point in the sequence bind/Overlay/materialization < eBPF LSM <
  `namei_ext` < FUSE/custom filesystems for state-dependent path-view policy.
- The paper RQs are expressiveness/sufficiency, overhead versus
  feature-equivalent FUSE, and filesystem-method/runtime responsibility versus
  custom or stackable filesystems.
- Bind/Overlay/projected/copy/symlink materialization mechanisms belong in
  related work and background comparisons, not as the central RQ3 opponent.
- The target-lifetime sanitizer protocol closed without a formal result after
  strict KCSAN diagnostics failed. Its roots are diagnostic evidence only and
  do not replace the bounded target-replacement construction check.

Historical detailed text remains recoverable through Git history and dated
records under `docs/tmp/`.
