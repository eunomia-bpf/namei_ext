# Idea And Hypothesis

Last updated: 2026-07-25

The full historical version of this file, including the orchestrator process
tables (Claim Evolution, Narrative Evolution, Hypothesis Frontier), is archived
at `docs/tmp/2026-07-25-archived-process-docs/idea-story-full.md`. Research
process state and gates are owned by the orchestrator skill, not by this
repository.

## Narrative

Modern systems increasingly need per-workload filesystem views without wanting
to implement a filesystem. Build systems, build caches, agent workspaces,
service sandboxes, and checkpoint/restart workflows repeatedly change which
existing object a pathname should denote, or whether that object should be
visible, while leaving ordinary file data, writes, permissions, page-cache
behavior, persistence, and consistency to an existing lower filesystem.

The existing design space has a missing middle. Bind mounts, OverlayFS,
projected volumes, symlink forests, copies, and other materialized views
preserve kernel filesystem semantics, but encode the view by constructing,
layering, or updating namespace state outside each lookup. eBPF LSM can attach
verified policy to security hooks, but its natural role is access-control
mediation rather than changing which existing object a pathname denotes during
VFS name resolution. FUSE and source-system agent filesystems are expressive,
but place a filesystem service on the path and often own operation handling,
caching, daemon availability, and correctness details. Custom or stackable
filesystems can be expressive and fast, but ask the developer to own a broader
filesystem interface.

`namei_ext` tests a different point between eBPF LSM and filesystem ownership:
put a constrained eBPF policy at VFS name resolution, analogous to how
`sched_ext` lets policy choose scheduling while the kernel retains scheduler
machinery. The policy chooses bounded lookup and directory-enumeration actions;
the kernel and lower filesystem continue to own VFS objects and ordinary file
semantics.

The central principle is:

```text
state-dependent pathname policy belongs at VFS name resolution;
filesystem objects and data semantics remain with the kernel and lower FS.
```

The intended contribution is the design and implementation of this narrow
extension point plus a source-grounded evaluation showing where it is expressive
enough, what it costs compared with feature-equivalent FUSE, and how its
implementation boundary differs from custom or stackable filesystem ownership.

## Research Questions

| RQ | Question | Evidence standard |
| --- | --- | --- |
| RQ1 Expressiveness / sufficiency | Can a narrow VFS name-resolution extension express real state-dependent path-view policies without taking over filesystem semantics? | Representative source-derived workloads pass their correctness oracles through the real `cgroup/namei_ext` KVM attach path, with coherent lookup/readdir behavior and lower-filesystem permission/write/data-path preservation. |
| RQ2 Cost / overhead versus FUSE | What is the cost of putting programmable policy on the VFS name-resolution path compared with a feature-equivalent FUSE policy implementation? | Same-oracle `namei_ext` and FUSE policy implementations, with correctness gating lookup/open/stat/access/exec/readdir latency, macro runtime, pass-through overhead, action overhead, and operation-weighted invocation traces. |
| RQ3 Safety / boundary versus custom or stackable FS | Does `namei_ext` provide a narrower verifier-bounded, fail-closed ownership boundary than building a custom or stackable filesystem when the needed policy is only name resolution? | Ownership and containment evidence: filesystem methods owned, privileged code surface, daemon/state responsibility, verifier/kernel validation, invalid-policy handling, and lower-filesystem data/write preservation. |

## Contribution And Evidence Program

Primary contribution: the design and implementation of `namei_ext`, a
`sched_ext`-style VFS name-resolution extension point whose eBPF policy selects
bounded lookup and directory-enumeration behavior while the kernel and lower
filesystem retain VFS object and data-path ownership.

Evidence program:

1. Source-derived characterization of state-dependent path views in
   agent/workspace, traditional build/cache, service/config, and
   checkpoint/restart systems is workload and oracle selection evidence, not a
   standalone contribution.
2. A small set of complete, same-oracle experiments is organized around RQ1,
   RQ2, and RQ3. FUSE is the central RQ2 comparison. Custom or stackable
   filesystem ownership is the central RQ3 boundary comparison. Materialized
   namespace mechanisms are related-work/background unless a renewed decision
   gives them a specific source-driven role.

## Current Evidence Highlights

- Agent workspace RQ1: three terminal KVM runs
  (`results/experiments/agent-workspace-matrix/20260722T0201*-rq1run{1,2,3}/`)
  pass the same AgentFS-derived trace oracle for `namei_ext` and
  feature-equivalent FUSE, with zero failed records and clean dmesg gates.
- Traditional build/cache: historical runs now aggregated by
  `make legacy-build-cache`
  (2026-07-23 hot-cache, 2026-07-24 epoch-switch) pass the Redis/nginx ccache
  output oracle in KVM for `namei_ext`, native control, and
  feature-equivalent FUSE; observed `FUSE/namei_ext` compile-time ratio is
  about 2.1x with `namei_ext` near native. Miss/stale/corrupt compile cells
  are not yet closed at release scale; one-sample stale/corrupt-hidden
  fallback probes passed.

## Rejected Or Dormant Paths

| Path | Why rejected/dormant | Revisit trigger |
| --- | --- | --- |
| Table-only or `table_redirect.bpf.c` as main novelty | User explicitly retired this line; proving static-table insufficiency no longer answers the intended paper. | Only if the user explicitly reopens it as a separate paper question. |
| Many weak baselines and scattered smoke tests | User requested few complete OSDI/SOSP-grade integrated experiments. | If a review finds a specific additional baseline changes an RQ answer. |
| Materialized namespace shootout as RQ3 | User fixed RQ3 toward custom/FUSE/stackable boundary and citation-based positioning for bind/Overlay/projected/copy/symlink. | If a selected source oracle makes a materialized mechanism the natural direct opponent. |
| Negative-result story in the paper | User requested a more attractive positive story and warned against changing the hypothesis around flawed experiment design. | If a valid final result contradicts a frozen claim and must be scoped honestly. |
| C8 table-only insufficiency as a live claim, and repo-global release gates | The table-only novelty line was retired; keeping C8 in verdict ledgers and coupling per-run results to repo-global conditions made no run ever pass. The claim-verdict machinery was deleted from the Make control plane on 2026-07-25. | Only if the user explicitly reopens table-only insufficiency as a separate paper question. |

## Change Log

| Date | Accepted change |
| --- | --- |
| 2026-07-15 | Story frozen after BOOTSTRAP step 0005: `sched_ext`-style VFS name-resolution extension point; RQ1 expressiveness, RQ2 cost versus feature-equivalent FUSE, RQ3 boundary versus custom/stackable FS; Agent workspace and traditional build/cache as the two primary workload families. |
| 2026-07-25 | Repository cleanup: retired C1–C8 claim-verdict machinery deleted from the Make control plane; process docs archived to `docs/tmp/2026-07-25-archived-process-docs/`; this file slimmed to story, RQs, evidence, rejected paths, and guardrails (full history in the archive). Scientific story unchanged. |
| 2026-07-25 | Use cases grounded in industrial demand evidence (`docs/tmp/2026-07-25-usecase-industrial-demand-survey.md`): six domains re-implemented lookup-time object selection at wrong layers. Service/config rotation promoted to the third use case; build/cache repositioned as access-point view governance; remote filesystem cache recorded as motivation evidence. |

## Guardrails

- Do not claim only `namei_ext` or only eBPF can implement the selected
  workloads.
- Do not make table-only impossibility, static-table failure, or materialized
  namespace shootouts the novelty line.
- Do not let writing/review passes shrink the idea around currently easy
  prototype evidence.
- Do not treat source characterization, preflight runs, or unreviewed matrices
  as final RQ evidence.
- Do keep the paper focused on the strongest honest systems abstraction:
  policy at VFS name resolution, lower filesystem semantics below.
