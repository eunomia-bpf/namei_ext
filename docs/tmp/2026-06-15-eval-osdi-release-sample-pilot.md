# OSDI performance release-sample pilot 记录

Last updated: 2026-06-15
Stage at update: execute/gate loop
Source/command: `make kvm-bench RUN_ID=20260615T-kvm-bench-release-sample-pilot SAMPLES=20 BENCH_ITERS=2000 BENCH_LATENCY_SAMPLES=1 BENCH_LATENCY_BATCH=4 BENCH_RANDOMIZE_ORDER=1` 和 `make eval-osdi-performance-ledger RUN_ID=20260615T-eval-ledger-release-sample-pilot EVAL_OSDI_PHASE1_RUN_ID=20260615T-kvm-bench-release-sample-pilot EVAL_OSDI_PERFORMANCE_BASELINE_RUN_ID=20260615T-kvm-external-baselines-fuse-smoke-v2`
Completeness: partial

## 动机

前一个 run-order/system-metrics pilot 证明 KVM `kvm-bench` 可以写出随机化顺序、系统指标、
`metadata.json` 和 tail/CI artifact，但只有 `SAMPLES=1`、每个 bench/variant group 只有 2
个 latency rows。OSDI 性能 claim 至少需要 release 级重复数。本次 pilot 的目的不是生成论文
最终数字，而是验证同一套 Makefile-owned KVM path 能否满足 microbench 的 release sample
budget。

## 运行配置

```text
make kvm-bench RUN_ID=20260615T-kvm-bench-release-sample-pilot \
  SAMPLES=20 BENCH_ITERS=2000 BENCH_LATENCY_SAMPLES=1 \
  BENCH_LATENCY_BATCH=4 BENCH_RANDOMIZE_ORDER=1
```

结果 root：

```text
results/phase1/20260615T-kvm-bench-release-sample-pilot/
```

关键 raw artifacts：

- `bench.jsonl`
- `bench-system-metrics.jsonl`
- `metadata.json`
- `bench-status.txt`
- `dmesg-bench.log`
- `bench-proc-stat-before.txt` / `bench-proc-stat-after.txt`
- `bench-meminfo-before.txt` / `bench-meminfo-after.txt`
- `bench-vmstat-before.txt` / `bench-vmstat-after.txt`
- `bench-diskstats-before.txt` / `bench-diskstats-after.txt`

## 结果

KVM bench run 通过：

- `bench-done status=0`
- `bench_rows=700`
- `bench_latency_rows=700`
- `bench_order rows=700`
- `bench_variant_order rows=5`
- `bench-system-metrics` before/after rows 均存在
- 0 runner failure

随后运行：

```text
make eval-osdi-performance-ledger \
  RUN_ID=20260615T-eval-ledger-release-sample-pilot \
  EVAL_OSDI_PHASE1_RUN_ID=20260615T-kvm-bench-release-sample-pilot \
  EVAL_OSDI_PERFORMANCE_BASELINE_RUN_ID=20260615T-kvm-external-baselines-fuse-smoke-v2
```

生成：

```text
results/eval-osdi/paper/20260615T-eval-ledger-release-sample-pilot/b2-performance/
```

关键 ledger 字段：

- `samples=20`
- `bench_rows=700`
- `bench_latency_rows=700`
- `has_repetition_budget=true`
- `has_tail_latency_artifact=true`
- `has_confidence_interval=true`
- `has_release_tail_sample_budget=true`
- `has_randomized_order=true`
- `has_system_metrics=true`
- `missing_release_baselines=[]`
- `release_gate_pass=false`

`bench-latency-tail-summary` 中 `rows=700`、`groups=35`、`min_group_rows=20`、
`failures=0`。

## Hard gate 检查

运行：

```text
make eval-osdi-performance \
  RUN_ID=20260615T-eval-ledger-release-sample-hardgate \
  EVAL_OSDI_PHASE1_RUN_ID=20260615T-kvm-bench-release-sample-pilot \
  EVAL_OSDI_PERFORMANCE_BASELINE_RUN_ID=20260615T-kvm-external-baselines-fuse-smoke-v2
```

该 hard gate 按预期失败，外层 expected-fail 检查通过。当前不应把该 pilot 写成 C2/C3/C5
论文性能结论。

## 解释

这次 run 清除了 microbench 侧的一个主要 blocker：modified-kernel KVM root 可以用
20-sample 配置生成完整 raw timing、tail/CI、随机化顺序和系统指标。

但 `missing_release_baselines=[]` 目前只表示 performance ledger 已经能链接到五类 external
baseline family：copy tree、symlink forest、bind mount、OverlayFS 和 FUSE redirect。它还
没有证明这些 baselines 自身也有 release repetitions。因此下一步需要把 baseline ledger
扩展出机器可读的 release repetition/sample-budget 字段，或者跑并审计 baseline release
root 后再让 B2/B8 gate 考虑通过。

## 剩余风险

- External baselines 仍然只有 smoke run 被链接进当前 performance ledger。
- `release_gate_pass` 仍为 false，C2/C3/C5 仍不能写成 supported。
- B12 policy-family gate 仍为 false，C1/C8 仍是最高风险 blocker。
- 当前仓库和 kernel submodule 是 dirty state，不适合作为 final artifact revision。
