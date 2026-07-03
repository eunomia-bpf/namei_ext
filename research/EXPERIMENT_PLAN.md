# Historical Experiment Plan

Status: historical provenance only.
Last routing update: 2026-07-02.

This file no longer owns the active experiment plan. It is kept only as a
pointer to the canonical layout required by the project skills.

| Current question | Canonical file |
| --- | --- |
| Current story, claim scope, and next action | `docs/idea-story.md` |
| Reviewer-facing workload-source and baseline decisions | `docs/background-related-work.md` |
| Source and artifact entry points | `docs/reference/CODE_SOURCES.md` |
| Current handoff pointer | `research/STATE.md` |
| Detailed reproduction or implementation records | `docs/tmp/YYYY-MM-DD-*.md` |
| Raw observations and generated reports | `results/` |

Active experiment direction:

1. Build a Make-owned, KVM-validated AI agent workspace lifecycle workload from
   the already reproduced source pool: BranchFS, Sandlock, AgentFS, Redis AFS,
   Mirage, SWE-agent/SWE-ReX, OpenHands SDK, Terminal-Bench, SWE-MiniSandbox,
   AgentCgroup, and YoloFS-like hidden-side-effect oracles.
2. Build a W4 cache/environment transition workload from ccache/BuildKit,
   SWE-rebench V2, SWE-Factory-Gym, MEnvData-SWE, Multi-Docker-Eval, or
   DockSmith-style traces.
3. Optionally upgrade W2 with a real service reload/update or secret/config
   rotation trace.

Do not add new static-table or interface-exclusivity experiments here. Future
experiment plans should be written in the relevant canonical doc or in a dated
`docs/tmp/YYYY-MM-DD-*.md` record when they are standalone evidence.
