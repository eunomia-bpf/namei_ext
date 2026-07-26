# Evaluation

Last updated: 2026-07-25

This file holds the scientific evaluation state: use cases, experiment
matrices, result pointers, and open questions. Research process rules and
gates belong to the orchestrator skill, not to this repository. The previous
process-heavy version is archived at
`docs/tmp/2026-07-25-archived-process-docs/evaluation.md`.

## Research Questions

| RQ | Question | Main comparison |
| --- | --- | --- |
| RQ1 Expressiveness / sufficiency | Can a narrow VFS name-resolution extension express real state-dependent path-view policies without taking over filesystem semantics? | Source-system behavior as correctness oracle |
| RQ2 Cost / overhead versus FUSE | What is the cost of programmable policy on the VFS name-resolution path compared with a feature-equivalent FUSE policy? | Feature-equivalent FUSE over the same oracle |
| RQ3 Safety / boundary | Is the verifier-bounded, fail-closed ownership boundary narrower than custom or stackable filesystem ownership when only name resolution is needed? | Workload-specific ownership accounting |

## Use Cases

| Use case | Source systems | Oracle | Necessity status |
| --- | --- | --- | --- |
| Agent workspace lifecycle | AgentFS, BranchFS, YoloFS, Sandlock, Mirage | Source-derived workspace lifecycle tree state (branch/COW/whiteout/symlink/rename/unlink) | Sources implement the same behavior with FUSE/runtime mechanisms. The claim is a narrower, daemon-free boundary, not exclusive necessity. |
| Traditional build/cache | Redis/nginx ccache; SWE-Factory/MEnv/SWE-rebench rows as build/test oracles | Compile output hashes plus the hit/miss/stale/corrupt/epoch-update cache-state machine | ccache handles plain hits natively. The open question is whether multi-workspace cache views with runtime state transitions justify lookup-time policy. |
| Service/config rotation (conditional) | nginx/Redis/PostgreSQL config paths | Lookup-time config/secret/cert object selection with service-visible behavior | Not admitted: no concrete lookup-time source oracle selected yet. |
| Checkpoint/restart remapping (conditional) | DMTCP-style path virtualization | Restart success depending on reopened-file object selection | Not admitted: no concrete source oracle selected yet. |

Known positioning constraint (from `docs/review/` adversarial analysis): the
one capability no materialized mechanism provides is same-mount-namespace,
per-cgroup divergent views with runtime state transitions. No admitted
workload yet names a customer that strictly requires cgroup scope over mount
namespaces; the paper currently argues boundary and cost, not necessity.

## Experiment Matrix Status

### A. Agent workspace lifecycle (headline)

| Cell | Status | Raw root |
| --- | --- | --- |
| RQ1 correctness: AgentFS-derived trace oracle for `namei_ext` and feature-equivalent FUSE | Passed, independently reviewed; 3 terminal KVM runs, 1,176 records each, zero failures, clean dmesg | `results/experiments/agent-workspace-matrix/20260722T020120Z-rq1run1/`, `-rq1run2/`, `-rq1run3/` |
| RQ2 timing versus FUSE | Open: no macro runtime or per-operation latency claim yet | — |
| RQ3 boundary table | Open: source-tied ownership rows not yet written | — |

### B. Traditional build/cache (decisive)

| Cell | Status | Raw root |
| --- | --- | --- |
| Verified hot-cache compile, 20 samples, `namei_ext` / native / FUSE | Passed in KVM; 400/400 output hashes per mechanism; observed FUSE/namei_ext compile-time ratio 2.18x, native/namei_ext 0.945x | `results/experiments/build-cache/20260723T-build-cache-release-v1/` |
| Trace-derived state row (verified-hit→local, epoch→canonical) | Passed in KVM for `namei_ext` and FUSE | `results/experiments/build-cache/20260723T-build-cache-state-release-v1/` |
| Real compiler-output epoch switch, 20 samples, 2 epochs | Passed in KVM; 800/800 output matches; observed FUSE/namei_ext ratio 2.10x; policy session updates 20 vs 800 backing invalidations | `results/phase1/20260724T-epoch-switch-release-v2/` |
| Stale-local and corrupt-hidden fallback | One-sample probes passed in KVM for both mechanisms | `results/phase1/20260724T-bad-local-stale-smoke-v1/`, `-corrupt-hidden-smoke-v1/` |
| Real-compile miss cell | Open | — |
| Release-scale stale/corrupt compile cells | Open (probes only) | — |
| Timing uncertainty (median/dispersion across samples) | Open: ratios are release-run observations, not modeled statistics | — |
| RQ3 boundary table | Open | — |

Make entrypoints: `make experiments` (both matrices),
`make experiment-env-cache`, `make experiment-agent-workspace`,
`make kvm-w4-ccache-bulk-compile-epoch-switch`,
`make kvm-w4-ccache-bulk-bad-local-fallback`.

## Open Questions

1. Does the build/cache state machine close at release scale (real-compile
   miss, stale, corrupt cells under the same oracle for both mechanisms)?
2. Does the RQ2 ratio survive median/dispersion reporting and a hardened
   FUSE configuration (single daemon, caching/passthrough accounted)?
3. Which admitted workload demonstrates per-cgroup divergent views with
   runtime state transitions — the capability materialized mechanisms do
   not provide — and does any real customer need cgroup scope specifically?
4. What do the per-workload RQ3 ownership tables show once written from the
   same-oracle evidence?
