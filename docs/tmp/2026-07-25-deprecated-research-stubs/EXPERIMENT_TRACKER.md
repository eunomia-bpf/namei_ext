# Historical Experiment Tracker

Status: historical provenance only.
Last routing update: 2026-07-02.

This file used to collect run rows and planned rows. It is no longer the
canonical place for reviewer-facing evidence or next-workload decisions.

Current routing:

- Raw run outputs, logs, JSON/JSONL, summaries, dmesg, hashes, and generated
  reports live under `results/`.
- Standalone research and implementation records live under
  `docs/tmp/YYYY-MM-DD-*.md`.
- Reviewer-facing result interpretation, source-use decisions, and comparison
  implications live in `docs/background-related-work.md`.
- Current story and claim scope live in `docs/idea-story.md`.
- The current handoff pointer lives in `research/STATE.md`.

Current planned run families:

| Planned family | Purpose | Canonical planning owner |
| --- | --- | --- |
| AI agent workspace lifecycle | Source-backed branch/session/COW/checkpoint/protected-path workload with correctness oracle, operation-weighted path signal, FUSE policy comparison, and custom/stackable FS boundary evidence. | `docs/idea-story.md` and a future dated implementation record |
| Environment/cache transition | Real hit/miss/stale/corrupt/update-window or environment-reuse workload with output/test oracle, a feature-equivalent FUSE policy comparison for RQ2, and custom/stackable FS boundary evidence for RQ3. | `docs/background-related-work.md` and a future dated implementation record |
| Service/config transition | Optional upgrade from fixture setup/update to real reload, secret/config/cert rotation, or PostgreSQL-style query/secret trace. | `docs/idea-story.md` and a future dated implementation record |

Historical detailed run rows are available through Git history and raw result
roots under `results/`. Do not add new source-role or novelty verdicts here.
