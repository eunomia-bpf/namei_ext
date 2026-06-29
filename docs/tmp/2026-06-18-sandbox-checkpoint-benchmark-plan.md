# Sandbox and Checkpoint Benchmark Plan

> 2026-06-29 baseline scope update: this note preserves historical reasoning and results, but older C8/B12 baseline-gate wording is superseded by `docs/tmp/2026-06-29-redirect-table-novelty-position.md`. Current evaluation uses claim-driven, workload-appropriate baselines. Exact-map diagnostics are optional and only relevant when precomputed mapping is the competing claim.

## Motivation

This note records the current status of the sandbox fixture and checkpoint/restore lines, and turns them into an OSDI-grade benchmark plan. It is intentionally scoped: the current paper story is already a scoped weak-accept story, while full release claims still need stronger benchmark evidence.

## Current sandbox status

The sandbox line is W2. The strongest row is `w2-nginx-fixture`.

Current positive evidence:

- `results/phase1/20260617T-w2-nginx-real-trace-release-v1/w2-nginx-real-trace.jsonl` passes the real nginx trace gate: `w2_real_trace_gate_pass=true`, `endpoint_health_pass=true`, `upstream_seen=true`, `no_real_production_open_pass=true`, `attached_production_decoy_opens=0`, and `attached_fixture_alias_opens=9`.
- `results/eval-osdi/paper/20260617T-eval-w2-nginx-workload-macrobench-hardgate-v11/b3-macrobench/w2-nginx-workload-macrobench.jsonl` passes the W2 C2 slice: `w2_c2_slice_supported=true`, `storage_footprint_pass=true`, `setup_latency_threshold_pass=true`, `update_latency_threshold_pass=true`, and `update_materialization_threshold_pass=true`.
- The W2 feature-equivalent baseline set covers `copy_tree`, `symlink_forest`, `bind_mount`, `projected_volume`, and `fuse_redirect`.

Boundary:

- W2 supports only the scoped sandbox fixture slice. It does not prove global C2, C8, or security isolation.
- Direct fixture content probes for cert/secret/poison are useful, but the stronger release benchmark should prefer traced real-app behavior or a declared helper path with operation-weighted accounting.

## Current checkpoint/restore status

The checkpoint/restore line is W3. The current evidence is not a real restore benchmark.

Current evidence:

- `workload/w3-redis-podman-criu/evidence.md` explicitly states that the current implemented witness is `w3-redis-rdb-load-replay`, not Podman/CRIU restore.
- `results/phase1/20260615T-parent-key-poc/w3-redis-replay.jsonl` shows a real Redis RDB load path observes the checkpoint policy redirect.
- `results/phase1/20260616T-w3-redis-macrobench-release-v1/w3-redis-policy-macrobench.jsonl` and `w3-redis-baseline-macrobench.jsonl` provide 20-sample KVM proposed-system, materialized checkpoint-view, and FUSE checkpoint-view input rows.
- `results/eval-osdi/paper/20260617T-eval-w3-redis-workload-macrobench-ledger-v7/b3-macrobench/w3-redis-workload-macrobench.jsonl` is threshold-negative: `w3_c2_slice_supported=false`, `setup_latency_threshold_pass=false`, and `update_latency_threshold_pass=false`.

Boundary:

- The current W3 result cannot be described as restore health, restore latency, or CRIU recovery evidence.
- CRIU-restored file descriptors, mmap mappings, or sockets do not count as `namei_ext` evidence unless the workload performs new post-restore VFS lookup/readdir operations.

## Revised use-case organization

The paper should not split fork, checkpoint, rollback, and trace replay into separate use cases. They are operations inside one higher-level use case:

1. Agent sandbox lifecycle.
2. Service fixture sandbox.
3. Content-verified cache view.

The agent sandbox lifecycle use case should not include eval isolation. Eval isolation would introduce a broader security or benchmark-harness claim that the current system and evidence do not need. The useful operations for this use case are workspace fork/fanout, checkpoint rollback or restore to a prior workspace state, and deterministic trace replay over a pinned agent task corpus such as SWE-bench-style repository tasks. The correctness oracle should be workspace content equality, post-rollback path trace consistency, and zero mixed epoch when a checkpoint generation is declared.

Under this organization, the current W1 build graph should either be folded into agent sandbox trace replay or moved to appendix/negative evidence. The current W3 Redis checkpoint line should not be a main use case unless it is redesigned around a real sandbox or restore workflow with fresh post-restore VFS operations. The current W2 nginx fixture remains the service fixture sandbox positive slice.

## OSDI benchmark bar

A benchmark row should only support a paper claim when it has all of the following:

- Real workload source and pinned provenance: source commit or image digest, input manifests, policy object hash, kernel identity, and result root.
- Feature-equivalent baselines: FUSE for programmable user-space path remapping, plus materialized/kernel alternatives such as copy, symlink, bind, projected-volume, native tool behavior, or checkpoint materialization as applicable.
- Correctness gate before performance: app health, content hashes, no-real-secret or 0 mixed-epoch checks, dmesg cleanliness, and declared failure handling.
- Release repetition: at least 20 macrobench samples for current project gates; final paper figures should prefer 30 samples or explain the lower sample budget in the artifact audit.
- Distributional metrics: p50, p95, p99, confidence intervals, absolute values, and ratios.
- Resource attribution: setup objects, bytes, update writes, materialization writes, mount count, FUSE process evidence, CPU/rusage where performance is claimed.
- Ablation or counterfactual: pass-only for hook overhead, table-only for programmability, and FUSE/materialized baselines for external alternatives.
- Reproducible Make entrypoint: every run should be a Make target and preserve raw JSONL/log/dmesg/provenance under `results/`.

## Sandbox benchmark design

Claim tested: W2 sandbox fixture path views reduce setup/materialization cost and preserve real app behavior compared with feature-equivalent materialized and FUSE baselines.

Workloads:

- Primary: nginx fixture config/endpoint/cert/secret/poison path set.
- Supplement: PostgreSQL config/auth/secret fixture, if the paper needs a second sandbox workload.

Compared systems:

- `namei_ext` with `sandbox_fixture_view.bpf.c`.
- `copy_tree`, `symlink_forest`, `bind_mount`, `projected_volume`, and `fuse_redirect`.
- `table_redirect.bpf.c` for C8 only, with update-write and table-size accounting.

Oracles:

- Real app starts and serves the expected health response.
- Upstream fixture is actually reached.
- Production decoy config/secret/cert paths are not opened during the attached trace.
- Fixture aliases are opened during the attached trace.
- Post-update reload or config test observes the new fixture generation.
- Poison path access is either observed as a declared poison event or remains outside the app trace and is not counted as app coverage.

Metrics:

- setup latency, setup objects, setup bytes, mount count, and FUSE mounts.
- update latency, update writes, materialization update writes, update bytes, and stale window.
- startup/reload health latency.
- lookup/open/access p99 if the row is used for C3.
- operation-weighted redirected hit rate.

Success criterion:

- Correctness passes with zero unexpected opens or dmesg issues.
- W2 remains threshold-positive against the full feature-equivalent baseline family.
- If used for C8, table-only must fail a declared oracle or exceed table/update/stale-window budget.

Failure interpretation:

- If materialized/projected/FUSE baselines pass correctness and match cost, the claim must remain a local engineering tradeoff rather than a broad sandbox advantage.
- If only direct probes cover cert/secret/poison, the row supports functional coverage but not app-level sandbox trace coverage.

## Checkpoint/restore benchmark design

Claim tested: checkpoint/restore path views can remap post-restore state/config/runtime paths while preserving restore correctness and avoiding mixed checkpoint epochs.

Precondition:

- `make workload-w3-podman-criu-capability` must pass. Current recorded audit failed because `criu_present=false` and Podman did not expose the expected checkpoint command path.

Workloads:

- Primary: Redis Podman/CRIU checkpoint and restore.
- Supplement: nginx Podman/CRIU checkpoint and restore, because reload/static-file/log-reopen paths are easier to trace after restore.

Compared systems:

- Native Podman/CRIU restore without `namei_ext`, as the functionality reference.
- Materialized checkpoint-view tree.
- Copy or bind restore tree where feature-equivalent.
- `fuse_redirect` checkpoint-view baseline.
- `table_redirect.bpf.c` with restore_id x epoch x path_class accounting.
- `namei_ext` with `checkpoint_restore_view.bpf.c`.

Oracles:

- Restore health passes: Redis responds to `PING` and preserves expected key state, or nginx serves the expected response.
- State/config/cache hashes match the checkpoint manifest.
- Runtime-local socket/temp/pid/log paths resolve to the restore-session environment.
- Post-restore VFS trace shows new lookup/readdir/open/stat operations through the policy window.
- 0 mixed checkpoint/current epoch events.
- Detach behavior and failure cases are explicit.

Metrics:

- checkpoint-view setup latency and object count.
- restore-to-health latency.
- post-restore metadata p99 for config rewrite, BGSAVE, AOF/RDB open/stat, log reopen, reload, static file request, and directory enumeration.
- table update writes, stale window, and map/table footprint.
- FUSE mount count and process evidence.

Success criterion:

- Correctness passes under real restore, not only RDB replay.
- `namei_ext` is not slower than the declared materialized/FUSE baselines under the configured threshold for the scoped claim.
- If used for C8, table-only must either fail 0 mixed epoch or exceed table/update/stale-window budget at the declared restore/session scale.

Failure interpretation:

- If the benchmark only observes CRIU-restored file descriptors and no fresh post-restore VFS operations, it does not test `namei_ext`.
- If table-only passes with a small exact table and no update-window cost, C8 remains unsupported.
- If materialized checkpoint-view setup remains faster, W3 should stay a negative result in the paper.

## Other benchmark blocks needed for OSDI quality

- C3/C5 overhead: keep FUSE as the primary programmable baseline, but use native/no-hook/pass-only to explain kernel overhead. Current blocker is native overhead in full metadata suite, especially readdir/per-dirent dispatch and common hook/dispatch residual.
- C8 programmability: table-only must be tested under update budget, stale-window budget, map memory, operation-weighted hit rate, and branch coverage. A static table-capacity microbenchmark can be a control, but it is not sufficient for the main claim.
- Scale/stress: sweep alias count, path depth, cgroup count, restore sessions, update churn, and cache/sandbox path-class count. Report saturation point and fail-fast behavior.
- Reproducibility: close C7 with a clean-checkout Make-owned reproduction path and a release result manifest.

## Next implementation choices

The least risky next step is to keep the current paper scoped and improve benchmark quality in one focused direction:

1. For a stronger positive story, extend W2 sandbox to a second real app or a broader nginx trace matrix.
2. For a broader systems story, fix W3 Podman/CRIU capability and build the real restore benchmark.
3. For a performance story, root-cause and optimize C3/C5 native overhead before expanding the latency claim.

Do not treat another static table-only smoke as sufficient for OSDI C8. A small control showing table capacity limits may be useful in an appendix, but the main benchmark must be operation-weighted and tied to real workload update semantics.
