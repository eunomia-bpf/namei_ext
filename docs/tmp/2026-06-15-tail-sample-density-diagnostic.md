# tail sample density 诊断记录

Last updated: 2026-06-15
Stage at update: research/execute
Source/command: R050-R053 diagnostic over ctx 初始化拆分 PoC
Completeness: complete

## 动机

`20260615T-eval-comparison-ctx-init-split-batch64-v1` 使用 20 个 sample、每个
sample 1 条 latency batch row。当前 percentile 实现是 nearest-rank；在每组只有
20 条 latency row 时，p99 实际等于该组最大值。`lookup_native_hot/policy` 的
20-row 结果中只有一个 756ns outlier，其余 19 条都在约 395-408ns，因此不能直接把
这个 p99 失败解释为稳定内核 hot-path 成本。

本诊断不改代码，只把 `BENCH_LATENCY_SAMPLES` 和 `BASELINE_LATENCY_SAMPLES` 从 1 提到
10，保持：

- `SAMPLES=20`
- `BENCH_LATENCY_BATCH=64`
- `BASELINE_LATENCY_BATCH=64`
- `BENCH_RANDOMIZE_ORDER=1`
- 同一个 ctx 初始化拆分内核镜像和同一组 external baselines

目标是判断 C3/C5 失败来自稳定成本，还是来自过稀疏 tail sampling。

## 执行命令

内部 KVM bench：

```text
make kvm-bench RUN_ID=20260615T-kvm-bench-ctx-init-split-tail10-v1 SAMPLES=20 BENCH_ITERS=2000 BENCH_LATENCY_SAMPLES=10 BENCH_LATENCY_BATCH=64 BENCH_RANDOMIZE_ORDER=1
```

外部 baselines：

```text
make eval-osdi-baselines RUN_ID=20260615T-kvm-external-baselines-ctx-init-split-tail10-v1 BASELINE_SAMPLES=20 BASELINE_ITERS=500 BASELINE_LATENCY_SAMPLES=10 BASELINE_LATENCY_BATCH=64
```

Comparison：

```text
make eval-osdi-performance-comparison RUN_ID=20260615T-eval-comparison-ctx-init-split-tail10-v1 EVAL_OSDI_PHASE1_RUN_ID=20260615T-kvm-bench-ctx-init-split-tail10-v1 EVAL_OSDI_PERFORMANCE_BASELINE_RUN_ID=20260615T-kvm-external-baselines-ctx-init-split-tail10-v1
```

Hard gate：

```text
make eval-osdi-performance RUN_ID=20260615T-eval-comparison-ctx-init-split-tail10-hardgate-v1 EVAL_OSDI_PHASE1_RUN_ID=20260615T-kvm-bench-ctx-init-split-tail10-v1 EVAL_OSDI_PERFORMANCE_BASELINE_RUN_ID=20260615T-kvm-external-baselines-ctx-init-split-tail10-v1
```

## 输入完整性

内部 KVM bench result root：
`results/phase1/20260615T-kvm-bench-ctx-init-split-tail10-v1/`

- `bench_rows=700`
- `latency_rows=7000`
- `unique_samples=20`
- `latency_samples=10`
- `min_latency_ops=64`
- `failing_ops=0`
- `done_status=0`

外部 baseline result root：
`results/eval-osdi/baselines/20260615T-kvm-external-baselines-ctx-init-split-tail10-v1/`

- `raw_rows=8817`
- `bench_rows=800`
- `latency_rows=8000`
- `baselines_selected=5`
- `baselines_release_passed=5`
- `baseline_min_bench_unique_samples_per_case=20`
- `baseline_min_latency_unique_samples_per_case=20`
- `runner_failures=0`
- `baseline_release_gate_pass=true`

内部和外部 dmesg 均无 panic/oops/warning/hung-task gate pattern。

## Comparison 结果

Comparison result root：
`results/eval-osdi/paper/20260615T-eval-comparison-ctx-init-split-tail10-v1/b2-performance/`

Summary：

- `input_gate_pass=true`
- `kernel_p99_threshold_pass=false`
- `fuse_speedup_threshold_pass=true`
- `pass_only_threshold_pass=false`
- `max_policy_to_native_p99_ratio=4.373989449932007`
- `min_policy_to_fuse_p99_speedup=2.2578242999873592`
- `max_pass_only_to_native_p99_ratio=2.624059316157427`
- `c2_supported=false`
- `c3_supported=false`
- `c5_supported=false`
- `release_gate_pass=false`

Hard gate result root：
`results/eval-osdi/paper/20260615T-eval-comparison-ctx-init-split-tail10-hardgate-v1/b2-performance/`

`make eval-osdi-performance` 退出状态为 2，符合预期；失败原因仍是 release gate false。

## 关键观察

1. `exec_tool_redirect` 不再是 C3 blocker。
   在 tail10 comparison 中，`exec_tool_redirect` 的 `policy_to_fuse_p99_speedup`
   为 2.26x，已经超过 2x 阈值。

2. `lookup_native_hot` 的原始单点 outlier 被稀释，但仍略超 kernel 阈值。
   20-row run 中 `policy` p99 是 756ns；tail10 的 200-row run 中 `policy` p99 是
   452ns，max 是 566ns。对应 `policy/native` p99 ratio 仍为 1.53x，略高于 1.5x。

3. 更密的 sampling 暴露出 pass-only residual 的 tail 问题。
   tail10 summary 中 `pass_only_threshold_pass=false`，最差
   `pass_only/native` p99 ratio 为 2.62x。这说明 batch64 1-sample run 中
   pass-only 过阈值不够稳健，不能作为 C5 supported evidence。

4. `readdir_alias_view` 和 `build_tree_stat_walk` 是新的稳定 C3 blocker。
   tail10 per-bench rows 中 `readdir_alias_view` 的 `policy/native` p99 ratio 为
   4.37x，`build_tree_stat_walk` 为 1.75x。二者都伴随 pass-only residual 放大，
   更像 attach/static-branch/BPF dispatch/RCU path interaction 的 tail 问题，而不是
   redirect-alias policy 自身的 literal-compare 成本。

5. table-only 不是这里的性能瓶颈解释。
   `table_redirect.bpf.o` 有约 634 条 BPF 指令，主要来自 64-byte key 构造和 map lookup；
   `redirect_alias.bpf.o` 约 46 条指令。tail10 中多数 redirect policy rows 比
   table-hit 更快，说明用 table-only 替代 policy 不会修复当前 C3/C5 gate。

## 结论

tail10 诊断改变了下一步优先级：

- 不应继续围绕 `exec_tool_redirect` 或 FUSE 2x speedup 做主要优化；更密采样下该阈值已通过。
- 也不能把 ctx 初始化拆分视为 C5 完成；pass-only tail 在更密采样下仍失败。
- 下一步应定位 attach/pass-only/readdir/tree-walk 的 tail residual：是否来自 RCU-walk
  interaction、cgroup dispatch、run context setup、guest filesystem variance、或 benchmark
  order/cache state。需要比当前 before/after system metrics 更细的 per-variant
  CPU/context-switch/fault 观测，或一个 no-hook/static-key-off kernel build 做真正下界。

该诊断仍不支持 C2/C3/C5。它只说明 C3 的 FUSE speedup blocker 可以消除，真正 blocker
转移到 kernel p99 和 pass-only residual。
