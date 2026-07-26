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

Full demand evidence with verbatim quotes and source URLs:
`docs/tmp/2026-07-25-usecase-industrial-demand-survey.md`. The framing result
of that survey: six domains (AgentFS/BranchFS in FUSE, YoloFS as a stackable
kernel FS, kubelet via symlink indirection, ingress-nginx via embedded Lua,
DMTCP via LD_PRELOAD, cloud-mount/lazy-pull systems via FUSE then in-kernel
erofs+fscache) all re-implemented lookup-time object selection at layers that
force them to own far more than name resolution.

| Use case | Role | Demand and citation basis | Necessity status |
| --- | --- | --- | --- |
| Agent workspace views | Primary (Experiment A) | YoloFS (290 real incident reports) and BranchFS motivate workspace fork/snapshot/hide; YoloFS independently implements our HIDE/REDIRECT/SELECT semantics inside an entire stackable kernel FS; BranchFS measures FUSE at 19% of native read throughput; AgentFS issues #228/#167 document 10x multicore slowdown and daemon deadlock. | Sources implement the same behavior with FUSE/stackable-FS mechanisms. The claim is the same capability at a narrow verified boundary, not exclusive necessity. Covers view/visibility, not write-path COW staging. |
| Traditional build/cache view governance | Primary (Experiment B) | sccache/ccache/Bazel/BuildKit shared caches are infrastructure; BuildKit cache-mount `id` and ccache `namespace` are productized cache views; Bazel #4276 and the Angular incident show cache poisoning in production; GitHub now issues read-only cache tokens to untrusted triggers. | Industry's mainstream isolation is key-space (namespace-in-hash, CAS), deliberately bypassing paths. Defensible gap: cache visibility/writability governance for unmodified toolchains on shared build machines. Position as access-point governance, not ccache acceleration. |
| Service/config rotation | Third use case (promoted 2026-07-25) | kubelet AtomicWriter already implements epoch switching as symlink retargeting at name resolution; official K8s docs document 60–90s propagation, subPath never updating, env requiring restart; Vault sidecars, Reloader, and nginx/envoy hot-restart are the workaround ecosystem; ingress-nginx embeds Lua to move object selection to request time. | The switch already lives at name resolution as a symlink hack; namei_ext removes the minute-scale reconcile trigger and the choreography for every app that re-resolves paths at open. Cannot help apps holding old fds. |
| Checkpoint/restart remapping | Conditional | DMTCP path virtualization (Cluster'16, SELSE'17 with Intel) is the direct precedent, implemented as fragile LD_PRELOAD `open()` interposition. | Kubernetes keeps migration as a non-goal (KEP-2008) and CRIU `--external mnt` covers restore-time mapping. Weakest demand; do not invest before the first three. |
| Remote filesystem cache | Motivation evidence only, not evaluated | s3fs/gcsfuse/JuiceFS are FUSE daemons with documented pain; lazy container-image pulling migrated from FUSE to in-kernel erofs+fscache for "significantly better performance than FUSE" (AWS EKS AMI #2569). | Strongest industrial proof that the boundary exists: the kernel absorbed the data path, but selection/visibility policy stays hardwired per system. Not evaluated: the data path is the bulk of the problem and namei_ext deliberately does not own it. |

Additional candidates recorded as pattern evidence, not as evaluated use
cases (full verdicts in `docs/background-related-work.md`):

| Candidate | Citation | Verdict |
| --- | --- | --- |
| SELinux polyinstantiation / pam_namespace | namespace.conf(5); Red Hat SELinux guide: per-context `/tmp` instances bound at login | Closest shipping precedent. Static per-context instance trees, not programmable per-lookup policy; must be positioned against in related work. |
| Plan 9 per-process name spaces, union directories | Pike et al., Operating Systems Review 27(2):72–76, 1993 | Intellectual ancestor of view mechanisms; the delta is policy evaluated at lookup inside one shared namespace. |
| Dependency/toolchain version views | Dolstra et al., LISA'04 (Nix); virtualenv/nvm/rbenv/Lmod/update-alternatives ecosystem | Daily demand implemented as symlink/PATH choreography; pattern-ubiquity evidence, not a target workload. |
| Dataset versioning | lakeFS/DVC: git-like branches over object storage | Demand is real but consumption is via SDK/S3 API, not POSIX paths; related work only. |

Positioning constraint (from `docs/review/` adversarial analysis, still
unresolved): the one capability no materialized mechanism provides is
same-mount-namespace, per-cgroup divergent views with runtime state
transitions. No admitted workload yet names a customer that strictly requires
cgroup scope over mount namespaces; the paper currently argues boundary and
cost, not necessity. Additional candidate use cases and existing-mechanism
precedents (SELinux polyinstantiation, Plan 9 name spaces, Nix/toolchain
version views, lakeFS/DVC) are recorded as pattern evidence in
`docs/background-related-work.md`; SELinux polyinstantiation is the closest
shipping precedent and must be positioned against in related work.

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
5. Can the service/config use case produce a KVM oracle cell (config epoch
   switch with `nginx -t`-style validation and service-visible behavior)
   through the real attach path, now that its demand evidence is strong?
