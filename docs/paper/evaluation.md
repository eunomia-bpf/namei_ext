# Paper Evaluation Notes

Status: active companion note for the frozen BUILD_AND_EVALUATE paper draft
after BOOTSTRAP step 0005.
Last routing update: 2026-07-15.

The canonical evaluation plan is `../evaluation.md`. This file records the
paper-directory routing rule: the LaTeX evaluation section should follow the
frozen step-0005 RQ1/RQ2/RQ3 paper plan and must not revive older
narrow-baseline gates.

Use the skill-compatible layout instead:

| Need | Canonical location |
| --- | --- |
| Current paper idea, claim scope, non-goals, and next action | `docs/idea-story.md` |
| Related work, novelty risk, source-use verdicts, mandatory comparisons | `docs/background-related-work.md` |
| Source repositories, datasets, artifacts, and reproduction-record links | `docs/reference/CODE_SOURCES.md` |
| PDF inventory | `docs/reference/INDEX.md` |
| Standalone research or implementation records | `docs/tmp/YYYY-MM-DD-*.md` |
| Raw logs, JSON/JSONL, benchmark outputs, generated summaries | `results/` |
| Current handoff pointer | `research/STATE.md` |

Current boundary:

- Do not use this file to revive workload-necessity or interface-exclusivity
  claims from older drafts.
- Do not claim that selected workloads require only eBPF or only `namei_ext`,
  or that alternative namespace mechanisms are impossible.
- Do preserve the restored paper idea: `namei_ext` is a `sched_ext`-style VFS
  extension point in the sequence bind/Overlay/materialization < eBPF LSM <
  `namei_ext` < FUSE/custom filesystems for state-dependent path-view policy.
- The paper RQs are expressiveness/sufficiency, overhead versus
  feature-equivalent FUSE, and a verifier-bounded, fail-closed ownership
  boundary versus custom or stackable filesystems.
- Bind/Overlay/projected/copy/symlink materialization mechanisms belong in
  related work and background comparisons, not as the central RQ3 opponent.

Historical detailed text remains recoverable through Git history and dated
records under `docs/tmp/`.
