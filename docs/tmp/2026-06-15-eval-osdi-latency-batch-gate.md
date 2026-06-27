# OSDI latency batch release gate 实现记录

Last updated: 2026-06-15
Stage at update: execute/gate
Source/command: `make eval-osdi-performance-comparison RUN_ID=20260615T-eval-comparison-latency-batch-gate-v1 EVAL_OSDI_PHASE1_RUN_ID=20260615T-kvm-bench-release-sample-pilot EVAL_OSDI_PERFORMANCE_BASELINE_RUN_ID=20260615T-kvm-external-baselines-release-pilot`; `make eval-osdi-baselines RUN_ID=20260615T-kvm-external-baselines-unique-sample-smoke-v1 BASELINE_SAMPLES=1 BASELINE_ITERS=50 BASELINE_LATENCY_SAMPLES=1 BASELINE_LATENCY_BATCH=4`
Completeness: complete for gate hardening; blocked for positive performance claim

## 动机

旧 B2/B8 comparison target 已能产生 head-to-head ratio verdict，但它把
`BENCH_LATENCY_BATCH=4` 的 20-sample pilot 视为 `input_gate_pass=true`。这不够严格：
每个 latency row 只有 4 次操作，p99 实际上是 20 个小 batch 的最大值，容易被单个
调度或 cache outlier 主导。

OSDI 级性能 gate 应该 fail-closed：输入方法不够时产出 blocked verdict，而不是把
方法学不足的数据直接送入 threshold verdict。

## 实现改动

修改文件：

- `mk/eval_osdi.mk`
- `configs/benchmarks/phase1.mk`

新增 Make 变量：

- `EVAL_OSDI_REQUIRED_LATENCY_BATCH ?= 64`

内部 `bench_latency` tail artifact 新增字段：

- `min_group_samples`
- `max_group_samples`
- `min_ops_per_latency_row`
- `max_ops_per_latency_row`
- `required_latency_batch`
- `has_release_latency_batch_budget`

外部 baseline tail artifact 同步新增同一组 release batch 字段。

`eval-osdi-performance-comparison` 的 input gate 现在要求：

- internal release sample budget；
- internal release latency batch budget；
- internal CI；
- randomized order；
- system metrics；
- external baseline release gate；
- external tail artifact；
- external CI；
- external release sample budget；
- external release latency batch budget；
- comparison rows complete。

如果上述输入不足，comparison target 仍然写出 JSONL 和 Markdown artifact，但 summary
为：

- `input_gate_pass=false`
- `verdict="blocked_by_missing_inputs"`
- `release_gate_pass=false`

这样上层 hard gate 继续失败，但不会丢失 raw evidence。

## baseline release gate hardening

Arendt 指出 baseline release gate 原先按 row 数判断，理论上重复 sample id 也可能
满足 20 rows。实现中增加 summary-level 唯一 sample budget：

- `baseline_min_bench_unique_samples_per_case`
- `baseline_min_latency_unique_samples_per_case`
- `baseline_unique_sample_budget_pass`

`baseline_release_gate_pass` 现在还要求该 unique sample budget 为 true。

## 默认配置

`configs/benchmarks/phase1.mk` 中默认 batch 从 16 提高到 64：

- `BENCH_LATENCY_BATCH ?= 64`
- `BASELINE_LATENCY_BATCH ?= 64`

默认 `BENCH_LATENCY_SAMPLES` 和 `BASELINE_LATENCY_SAMPLES` 仍为 0，因此默认
`make phase1` 不会因为该改动增加 latency rows；但用户显式打开 release latency
采样时默认更接近 gate 要求。

## 验证

### 旧 release pilot 重新生成 comparison

命令：

```text
make eval-osdi-performance-comparison \
  RUN_ID=20260615T-eval-comparison-latency-batch-gate-v1 \
  EVAL_OSDI_PHASE1_RUN_ID=20260615T-kvm-bench-release-sample-pilot \
  EVAL_OSDI_PERFORMANCE_BASELINE_RUN_ID=20260615T-kvm-external-baselines-release-pilot
```

结果：

- internal tail summary:
  - `has_release_sample_budget=true`
  - `has_release_latency_batch_budget=false`
  - `min_group_samples=20`
  - `min_ops_per_latency_row=4`
  - `required_latency_batch=64`
- external tail summary:
  - `has_release_sample_budget=true`
  - `has_release_latency_batch_budget=false`
  - `min_group_samples=20`
  - `min_ops_per_latency_row=4`
  - `required_latency_batch=64`
- comparison summary:
  - `input_gate_pass=false`
  - `has_internal_latency_batch=false`
  - `has_external_latency_batch=false`
  - `verdict="blocked_by_missing_inputs"`
  - `release_gate_pass=false`

### hard gate expected-fail

命令：

```text
if make eval-osdi-performance \
  RUN_ID=20260615T-eval-comparison-latency-batch-hardgate-v2 \
  EVAL_OSDI_PHASE1_RUN_ID=20260615T-kvm-bench-release-sample-pilot \
  EVAL_OSDI_PERFORMANCE_BASELINE_RUN_ID=20260615T-kvm-external-baselines-release-pilot; \
then exit 1; else test "$$?" != "0"; fi
```

结果：wrapper 通过，inner `make eval-osdi-performance` 按预期失败。

### baseline unique sample smoke

命令：

```text
make eval-osdi-baselines \
  RUN_ID=20260615T-kvm-external-baselines-unique-sample-smoke-v1 \
  BASELINE_SAMPLES=1 \
  BASELINE_ITERS=50 \
  BASELINE_LATENCY_SAMPLES=1 \
  BASELINE_LATENCY_BATCH=4
```

结果：

- `baseline_smoke_gate_pass=true`
- `baseline_release_gate_pass=false`
- `baseline_unique_sample_budget_pass=false`
- `baseline_min_bench_unique_samples_per_case=1`
- `baseline_min_latency_unique_samples_per_case=1`

## 当前结论

旧 B2/B8 release pilot 不再算 paper-grade performance input。当前状态不是“性能阈值已被
release-quality 输入证伪”，而是更保守的：

- 旧 raw evidence 仍显示明显 overhead 和 outlier；
- 但 release p99 输入方法不足，必须用更大的 latency batch 重跑；
- C2 仍缺 setup/storage/update macrobench comparison；
- C3/C5 仍不能写成已支持 claim。

## 后续

1. 重跑 KVM microbench：
   `SAMPLES=20 BENCH_ITERS=2000 BENCH_LATENCY_SAMPLES=1 BENCH_LATENCY_BATCH=64`。
2. 重跑 external baselines：
   `BASELINE_SAMPLES=20 BASELINE_ITERS=500 BASELINE_LATENCY_SAMPLES=1 BASELINE_LATENCY_BATCH=64`。
3. 若新的 input gate 通过但 threshold 仍失败，再进入内核热路径优化或 claim narrowing。

