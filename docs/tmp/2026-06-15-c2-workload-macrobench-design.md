# C2 W1--W4 workload-equivalent macrobench 设计

> 2026-06-29 baseline scope update: this note preserves historical reasoning and results, but older C8/B12 baseline-gate wording is superseded by `docs/tmp/2026-06-29-redirect-table-novelty-position.md`. Current evaluation uses claim-driven, workload-appropriate baselines. Exact-map diagnostics are optional and only relevant when precomputed mapping is the competing claim.

日期：2026-06-15

## 背景

当前 C2 release-sample root 已经补齐 `namei_ext` 自身的 generic setup/source-update/table
policy update repetition：

- `results/phase1/20260615T-full-phase1-c2-release-sample-v1/bench.jsonl`
- `results/eval-osdi/paper/20260615T-eval-c2-release-sample-ledger-v1/b3-macrobench/macrobench.jsonl`

ledger 现在给出 `macrobench_input_gate_pass=true`，但仍给出 `c2_supported=false` 和
`release_gate_pass=false`。剩余缺口不是样本数，而是 W1--W4 的真实 workload-equivalent
setup/storage/update macrobench 和成功阈值。

## 设计目标

1. 用同一个 C2 schema 覆盖四类不同 workload family：
   - W1 build graph：Redis/nginx source build trace、release replay、build output hash。
   - W2 sandbox fixture：nginx real config/endpoint health、fixture content probes。
   - W3 checkpoint/restore：Redis checkpoint replay；Podman/CRIU restore 仍是 blocker。
   - W4 cache locality：real ccache transition、trace、policy-attached compile、parent/table comparator。
2. 每个 workload row 必须指向真实来源 artifact，而不是新造 synthetic loop。
3. 正确性先于性能。只有 workload oracle 已经通过时，setup/storage/update 数字才可进入比较。
4. 所有 orchestration 由 Make target 拥有，输出 raw JSONL、input sha256、manifest 和 Markdown summary。
5. derived ledger 和 KVM re-execution macrobench 必须分层，不能把 host provenance 或 replay
   summary 当成最终 C2 支持证据。

## 非目标

- 不在第一版里声明 C2 supported。
- 不把 `bench.jsonl` generic tree setup 数字外推到 W1--W4。
- 不把 W1 host trace duration 当作 KVM policy execution cost。
- 不把 W3 Redis RDB replay 等价为真实 Podman/CRIU restore。
- 不把 W4 sampled ccache witness 等价为 release-level operation-weighted cache workload。

## 证据等级

第一版目标是 `result_level=c2_workload_derived_contract`。它只能回答：

- W1--W4 是否已有可审计的真实 workload artifacts。
- 每个 family 当前可提取哪些 setup/storage/update proxy fields。
- 哪些 rows 已有 KVM correctness oracle。
- 哪些 rows 仍然因为 missing oracle、host-only provenance、table-only pass 或 threshold
  缺失而不能计入 C2。

发布级目标是后续 `result_level=c2_workload_kvm_macrobench`。它必须在修改内核 KVM 内重跑
workload-specific setup/update，记录 per-sample raw rows，并与 feature-equivalent baselines
比较。

## 第一版输入

固定输入来自当前 full Phase 1 root：

- `results/phase1/20260615T-full-phase1-c2-release-sample-v1/metadata.json`
- `results/phase1/20260615T-full-phase1-c2-release-sample-v1/w1-build-replay.jsonl`
- `results/phase1/20260615T-full-phase1-c2-release-sample-v1/w1-release-build-replay.jsonl`
- `results/phase1/20260615T-full-phase1-c2-release-sample-v1/w2-nginx-real.jsonl`
- `results/phase1/20260615T-full-phase1-c2-release-sample-v1/w3-redis-replay.jsonl`
- `results/phase1/20260615T-full-phase1-c2-release-sample-v1/w4-ccache-real.jsonl`
- `results/phase1/20260615T-full-phase1-c2-release-sample-v1/w4-ccache-policy-compile.jsonl`
- `results/phase1/20260615T-full-phase1-c2-release-sample-v1/w4-ccache-parent-compile.jsonl`
- `results/phase1/20260615T-full-phase1-c2-release-sample-v1/w4-ccache-table-compile.jsonl`
- `results/phase1/20260615T-full-phase1-c2-release-sample-v1/w4-ccache-release-counterfactual.jsonl`
- `results/workloads/runs/20260615T-full-phase1-c2-release-sample-v1/w1-redis-build/manifest.json`
- `results/workloads/runs/20260615T-full-phase1-c2-release-sample-v1/w1-nginx-build/manifest.json`
- `results/workloads/runs/20260615T-full-phase1-c2-release-sample-v1/w2-nginx-fixture/fixture-manifest.json`
- `results/workloads/runs/20260615T-full-phase1-c2-release-sample-v1/w3-redis-podman-criu/checkpoint-manifest.json`
- `results/workloads/runs/20260615T-full-phase1-c2-release-sample-v1/w4-ccache-redis-nginx/cache-manifest.json`

这些输入必须写入 `workload-macrobench-inputs.sha256`。任何缺失都应 fail fast。

## 输出 schema

第一版 raw JSONL 放在：

```text
results/eval-osdi/paper/<run-id>/b3-macrobench/workload-macrobench.jsonl
```

每个 workload row：

```json
{
  "schema": "namei_ext.eval_osdi.workload_macrobench.v1",
  "event": "eval-osdi-workload-macrobench",
  "run_id": "...",
  "phase1_run_id": "...",
  "result_level": "c2_workload_derived_contract",
  "run_environment": "mixed_host_kvm_derived",
  "workload_id": "w1-redis-build",
  "policy_family": "build_graph_view.bpf.c",
  "source_kind": "real_source_build_trace",
  "correctness_oracle_pass": true,
  "policy_executed_in_kvm": true,
  "setup_proxy_available": true,
  "storage_proxy_available": true,
  "update_proxy_available": false,
  "release_sample_budget_pass": false,
  "feature_equivalent_baseline_pass": false,
  "threshold_pass": false,
  "c2_eligible": false,
  "blocking_reason": "derived contract only; missing KVM per-sample workload setup/update macrobench"
}
```

summary row：

```json
{
  "event": "eval-osdi-workload-macrobench-summary",
  "workload_rows": 8,
  "correctness_oracle_passed": 0,
  "c2_eligible_rows": 0,
  "release_gate_pass": false,
  "c2_supported": false
}
```

## Workload-specific fields

W1 build graph rows：

- `build_duration_ns` from host build manifest。
- `trace_duration_ns` and `file_op_lines` from trace manifest。
- `kvm_build_replay_pass` and `kvm_release_replay_pass` from Phase 1 JSONL。
- `storage_proxy_bytes` from generated replay outputs if available。
- `update_proxy_available=false` until real generated/source/toolchain update macrobench exists。

W2 sandbox fixture rows：

- fixture entry count and fixture file hashes from `fixture-manifest.json`。
- nginx health/config/content correctness from `w2-nginx-real.jsonl`。
- setup proxy counts fixture files, cert, endpoint, poison sentinel。
- update proxy remains false until config/secret rotation macrobench exists。

W3 checkpoint/restore rows：

- Redis checkpoint entry count and manifest hashes from checkpoint manifest。
- Redis replay correctness from `w3-redis-replay.jsonl`。
- `real_restore=false` until Podman/CRIU capability gate passes and restore runs in KVM。
- update/stale/epoch proxy remains false until zero mixed epoch and post-restore trace exist。

W4 cache locality rows：

- real ccache transition correctness from `w4-ccache-real.jsonl`。
- policy-attached/parent/table compile summaries from corresponding JSONL。
- release counterfactual from `w4-ccache-release-counterfactual.jsonl`。
- C2 eligible false until operation-weighted hit rate, stale/corrupt transition, and KVM
  per-sample cache setup/update macrobench exist。

## Make target design

第一版 target：

```text
make eval-osdi-workload-macrobench-ledger \
  RUN_ID=<run> \
  EVAL_OSDI_PHASE1_RUN_ID=<phase1-run>
```

它只读取 existing artifacts，写：

- `b3-macrobench/workload-macrobench.jsonl`
- `b3-macrobench/workload-macrobench-inputs.sha256`
- `b3-macrobench/workload-macrobench-summary.md`
- `b3-macrobench/workload-macrobench-manifest.json`

hard gate target：

```text
make eval-osdi-workload-macrobench \
  RUN_ID=<run> \
  EVAL_OSDI_PHASE1_RUN_ID=<phase1-run>
```

第一版必须 expected fail，因为 summary 中 `release_gate_pass=false`。

## 成功阈值草案

这些阈值先写成 design，不在第一版 ledger 中判 supported：

- 每个 family 至少 2 个真实 workload rows。
- 每个 workload 至少 20 个 KVM per-sample setup/update rows。
- correctness oracle 必须全部通过，且 app-level oracle 不能只依赖 path probe。
- 每个 workload 都有 feature-equivalent baseline comparison。
- setup/storage/update 至少一个维度显著优于最强 baseline，且没有 metadata tail 阈值失败。
- 如果 table-only baseline 在同 workload 下通过且预算不超，C2/C8 均不能升级。

## 预期 reviewer 价值

第一版 derived ledger 的价值不是证明性能，而是把 C2 的缺口从散落的文本变成
machine-checkable inventory。reviewer 能看到每个 use case：

- 真实来源是什么；
- 当前 correctness oracle 是否来自 KVM attach path；
- 当前 setup/update 数字是否只是 proxy；
- 为什么还不能支持 C2。

这能防止下一轮实现把单个 workload 的成功误写成所有 family 的 C2 结论。

## 下一步

实现 `eval-osdi-workload-macrobench-ledger`，先让 derived contract 机械化并 expected-fail。
随后再选择一个 workload family 做真正 KVM per-sample setup/update macrobench PoC；优先级是
W2 nginx fixture 或 W4 ccache，因为它们已有 app-level correctness oracle 和真实 KVM attach
path，且比 W3 Podman/CRIU restore blocker 更少。
