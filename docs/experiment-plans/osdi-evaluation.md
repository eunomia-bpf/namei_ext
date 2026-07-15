# Current Evaluation Plan

Status: current routing entry.
Last updated: 2026-07-13.

This file is only a routing entry for the active evaluation direction. The
current idea is that `namei_ext` is a `sched_ext`-style VFS extension point for
state-dependent path-view policies. The evaluation should be engineered to give
the strongest plausible evidence for that hypothesis: expressive enough for real
workloads, cheaper than an equivalent FUSE policy path, and narrower than
custom or stackable filesystem ownership.

## Canonical Files

| Question | Canonical file |
| --- | --- |
| Paper idea, claim scope, non-goals, and next action | `docs/idea-story.md` |
| Current evaluation protocol and RQs | `docs/evaluation.md` |
| Headline Agent workspace complete experiment plan | `docs/tmp/2026-07-13-agent-workspace-complete-experiment-plan.md` |
| Decisive environment/cache complete experiment plan | `docs/tmp/2026-07-13-environment-cache-complete-experiment-plan.md` |
| Paper evaluation section | `docs/paper/sections/05-evaluation.tex` |
| Related work and workload-source verdicts | `docs/background-related-work.md` |
| Source repositories, datasets, artifacts, and evidence links | `docs/reference/CODE_SOURCES.md` |
| Current handoff pointer | `research/STATE.md` |
| Standalone research and implementation records | `docs/tmp/YYYY-MM-DD-*.md` |
| Raw logs, JSON/JSONL, generated summaries, and benchmark outputs | `results/` |

## Current Evaluation Shape

The active evaluation shape is a small set of complete experiments, not a list
of scattered workload/comparison snippets:

1. Headline complete experiment: AgentFS-derived workspace lifecycle through the
   real `cgroup/namei_ext` KVM attach path, with source oracle, lower-FS semantic
   checks, operation-weighted lookup/readdir traces, feature-equivalent FUSE
   comparison, and custom/stackable-FS boundary evidence. The detailed plan is
   `docs/tmp/2026-07-13-agent-workspace-complete-experiment-plan.md`; a
   redirect-only preflight is not a paper-result substitute for the full
   workload.
2. Decisive complete experiment: environment/cache transition from
   SWE-Factory-Gym, MEnvData-SWE, or SWE-rebench V2, with a pre-registered
   environment/cache workload suite, stale/corrupt/update or environment-reuse
   state, unchanged source evaluator, feature-equivalent FUSE policy, and
   result review. The detailed plan is
   `docs/tmp/2026-07-13-environment-cache-complete-experiment-plan.md`;
   individual cache, Docker, or source-row replays are dependencies unless they
   are part of this same-oracle matrix.
3. Conditional supporting experiment: service/config transition only after a
   real source oracle is selected where lookup-time object selection affects
   service-visible behavior.
4. Related-work/background context: bind/Overlay/projected/copy/symlink
   materialization, eBPF LSM access-control hooks, native production mechanisms,
   and metadata-service systems. Cite or classify these unless they directly
   change one of the admitted experiments under the same oracle.
5. Non-results: smoke tests, source reproduction, runner setup, object-file
   inspection, host-only checks, weak comparisons, and partial rows. These may
   support preflight or provenance but do not count as paper experiments.

Each admitted experiment must follow the `research-experiment-design` discipline:
paper-value admission, proposal, plan review, real preflight, full run, result
review, raw artifacts under `results/`, and a dated record under `docs/tmp/`.

The historical detailed plan that previously occupied this path has been
archived as
`docs/tmp/2026-07-12-archived-osdi-evaluation-plan.md`.
