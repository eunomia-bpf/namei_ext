# 完整 Phase 1 bench variants 运行记录

> 2026-06-29 baseline scope update: this historical record preserves prior reasoning and results. Current C8/B12 guidance is claim-driven baseline selection; exact-map diagnostics are optional boundary evidence only when precomputed mapping is the competing claim.

日期：2026-06-15

## 动机

单独的 `make kvm-bench RUN_ID=20260615T-bench-variants-smoke` 已证明新的 bench variant
runner 能在修改内核 KVM guest 中运行，但它不是完整 Phase 1 root。为了让 research
plan、evaluation plan 和论文只引用一份 canonical evidence，需要重新跑完整
`make phase1`，并在新的 report hard gate 下生成 `summary.md`。

## 执行命令

```text
make phase1 RUN_ID=20260615T-full-phase1-bench-variants
```

结果根目录：

```text
results/phase1/20260615T-full-phase1-bench-variants/
```

随后基于该 root 生成 OSDI contract ledgers：

```text
make eval-osdi-performance-ledger \
  RUN_ID=20260615T-eval-contract-bench-variants \
  EVAL_OSDI_PHASE1_RUN_ID=20260615T-full-phase1-bench-variants

make eval-osdi-policy-family-ledger \
  RUN_ID=20260615T-eval-contract-bench-variants \
  EVAL_OSDI_PHASE1_RUN_ID=20260615T-full-phase1-bench-variants
```

并验证 release hard gates 按预期失败：

```text
make eval-osdi-performance \
  RUN_ID=20260615T-eval-contract-bench-variants-hardgate \
  EVAL_OSDI_PHASE1_RUN_ID=20260615T-full-phase1-bench-variants

make eval-osdi-policy-family \
  RUN_ID=20260615T-eval-contract-bench-variants-hardgate \
  EVAL_OSDI_PHASE1_RUN_ID=20260615T-full-phase1-bench-variants
```

两个 hard gate 都返回非零，符合预期；失败原因是 release gate 条件未满足，不是
Phase 1 执行失败。

## Phase 1 结果

完整 `make phase1` 成功退出。该 root 包含：

- ABI/header sync；
- BPF build；
- policy load/semantic；
- table conformance；
- W1 release replay 和 branch probes；
- W2 nginx real endpoint health 和 fixture content probes；
- W3 Redis checkpoint replay；
- W4 real ccache transition、cache-path trace、trace-derived policy bridge、
  policy-attached compile、parent-scoped compile、table-only compile comparator 和
  release counterfactual accounting；
- functional tests；
- Docker smoke；
- KVM microbench variants；
- dmesg logs、metadata、kernel config、repo provenance 和 config sha256。

`bench.jsonl` 摘要：

```json
{
  "bench_rows": 35,
  "variants": [
    "baseline",
    "pass_only",
    "policy",
    "table_redirect_empty",
    "table_redirect_hit"
  ],
  "failing_ops": 0,
  "table_redirect_hit_map_updates": 66,
  "attach_successes": 4
}
```

`metadata.json` 中的配置仍是 smoke-scale：

```json
{
  "samples": "1",
  "bench_iters": "2000",
  "run_id": "20260615T-full-phase1-bench-variants"
}
```

## OSDI ledger 结果

Performance ledger：

```text
results/eval-osdi/paper/20260615T-eval-contract-bench-variants/b2-performance/performance.jsonl
```

结果要点：

- `has_pass_only_baseline=true`；
- `has_table_redirect_empty_baseline=true`；
- `has_table_redirect_hit_baseline=true`；
- `missing_release_baselines=["fuse_redirect","copy_tree","symlink_forest","bind_mount","overlayfs"]`；
- `release_gate_pass=false`；
- `c2_supported=false`、`c3_supported=false`、`c5_supported=false`。

Policy-family ledger：

```text
results/eval-osdi/paper/20260615T-eval-contract-bench-variants/b12-policy-family/policy-family.jsonl
```

结果要点：

- 四个 family 都有 `semantic_witness_pass=true`；
- 四个 family 都是 `release_metric_pass=false`；
- 四个 family 都是 `table_counterfactual_support=false`；
- `qualified_families=0`；
- `release_gate_pass=false`；
- `c1_supported=false`、`c8_supported=false`。

输入哈希校验：

```text
sha256sum -c results/eval-osdi/paper/20260615T-eval-contract-bench-variants/b2-performance/performance-inputs.sha256
sha256sum -c results/eval-osdi/paper/20260615T-eval-contract-bench-variants/b12-policy-family/policy-family-inputs.sha256
```

两者均通过。

## 结论

`20260615T-full-phase1-bench-variants` 取代
`20260615T-full-phase1-gatefix`，成为当前 canonical Phase 1 root。它确认 Phase 1
能在修改内核 KVM 中完整跑通，并且 bench variants 已进入 full-root hard gate。

但该 root 仍不能支撑 OSDI 发布级性能或可编程性主结论：当前只有 smoke-scale
`SAMPLES=1`，没有 tail latency、CI、随机顺序、系统指标和外部 filesystem baselines；
B12 中也没有任何 family 达到 `qualified_for_c1_c8=true`。

## 后续工作

- 把 release-scale performance target 做成 Makefile-owned workflow，至少覆盖 20 次重复、
  随机顺序、p50/p95/p99、confidence interval、system metrics 和外部 baselines。
- 为 B12 补齐每个 family 至少两个真实 workload row、operation-weighted release metric
  和 table/update counterfactual failure 或无法表达证据。
- 继续让 subagent 按 OSDI skill review 当前 docs/paper 和 eval ledgers；没有 weak
  accept 前不能把目标标记为完成。
