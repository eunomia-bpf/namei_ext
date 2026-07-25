# Historical Claim Verdict

Status: historical provenance only.
Last routing update: 2026-07-02.

This file no longer owns current claim verdicts. The current verdict and scope
are intentionally split by the skill-compatible layout:

| Current question | Canonical file |
| --- | --- |
| What is the paper idea and allowed claim scope? | `docs/idea-story.md` |
| Which prior work is closest, what is the novelty risk, and which comparisons are central? | `docs/background-related-work.md` |
| Which repositories, datasets, PDFs, and reproduction records exist? | `docs/reference/CODE_SOURCES.md` and `docs/reference/INDEX.md` |
| What is the current handoff state? | `research/STATE.md` |

Current verdict summary:

- Same-claim risk is medium: close systems exist, but they are mostly full
  filesystems, agent runtimes, environment builders, or metadata services.
- Safe claim: `namei_ext` is a `sched_ext`-style VFS extension point for
  programmable path-resolution policy: eBPF chooses bounded lookup/readdir
  decisions while the kernel and lower filesystem keep filesystem ownership.
- Claims to avoid: exclusive eBPF/`namei_ext` necessity, table impossibility,
  full filesystem replacement, and unreproduced source-system claims.
- Claim to restore: real source systems exercise dynamic state-dependent
  path-view policy, and `namei_ext` evaluates the missing middle between
  namespace materialization and full programmable filesystems.
- Next supporting artifact: a source-system characterization matrix for workload
  selection. Next claim-moving evidence: one Make-owned KVM AI agent workspace
  lifecycle workload, then one environment/cache transition workload, all with
  correctness-first oracles, feature-equivalent FUSE policy comparison, and
  custom/stackable FS boundary evidence.

Historical detailed verdict tables are available through Git history and dated
records under `docs/tmp/`. Do not add new verdicts here.
