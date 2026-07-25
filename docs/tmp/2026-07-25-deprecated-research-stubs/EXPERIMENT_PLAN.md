# Historical Experiment Plan

Status: historical provenance only.
Last routing update: 2026-07-02.

This file no longer owns the active experiment plan. It is kept only as a
pointer to the canonical layout required by the project skills.

| Current question | Canonical file |
| --- | --- |
| Current story, claim scope, and next action | `docs/idea-story.md` |
| Reviewer-facing workload-source and comparison decisions | `docs/background-related-work.md` |
| Source and artifact entry points | `docs/reference/CODE_SOURCES.md` |
| Current handoff pointer | `research/STATE.md` |
| Detailed reproduction or implementation records | `docs/tmp/YYYY-MM-DD-*.md` |
| Raw observations and generated reports | `results/` |

Active experiment direction:

0. First restore the paper framing: `namei_ext` is a `sched_ext`-style VFS
   extension point positioned between namespace materialization and
   FUSE/custom filesystems. Experiments should support expressiveness,
   overhead-versus-FUSE, and custom-filesystem safety-boundary claims rather
   than reduce the paper to materialization diagnostics.

1. Build a Make-owned, KVM-validated AI agent workspace lifecycle workload from
   the already reproduced source pool: BranchFS, Sandlock, AgentFS, Redis AFS,
   Mirage, SWE-agent/SWE-ReX, OpenHands SDK, Terminal-Bench, SWE-MiniSandbox,
   AgentCgroup, and YoloFS-like hidden-side-effect oracles.
2. Build an environment/cache transition workload from ccache/BuildKit,
   SWE-rebench V2, SWE-Factory-Gym, MEnvData-SWE, Multi-Docker-Eval, or
   DockSmith-style traces.
3. Optionally add a service/config transition workload with a real service
   reload/update, secret/config/cert rotation, or PostgreSQL-style query/secret
   trace.

Do not add new diagnostic-comparison or interface-exclusivity experiments here.
Future experiment plans should be written in the relevant canonical doc or in a
dated `docs/tmp/YYYY-MM-DD-*.md` record when they are standalone evidence.
