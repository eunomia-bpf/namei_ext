# B2/B8 batch=64 release rerun 记录

Last updated: 2026-06-15
Stage at update: execute/analyze
Source/command: `make kvm-bench`、`make eval-osdi-baselines`、`make eval-osdi-performance-comparison`、`make eval-osdi-performance`
Completeness: complete for this run; release claims still unsupported

## 动机

上一轮 B2/B8 comparison 使用 20 个 sample，但每条 raw latency row 只有 4 个操作。
这会让 p99 容易被极小 batch 的计时噪声放大。Arendt review 后，release gate 新增
`EVAL_OSDI_REQUIRED_LATENCY_BATCH=64`，要求 internal microbench 和 external baseline
都满足 `min_ops_per_latency_row>=64`，否则只能作为 diagnostic evidence。

本步骤的目标不是证明性能主张，而是消除 latency-batch 方法学阻塞，让 B2/B8 从
`blocked_by_missing_inputs` 进入真实阈值判定。

## 执行的 Make 目标

Internal KVM microbench：

```text
make kvm-bench RUN_ID=20260615T-kvm-bench-release-batch64-v1 SAMPLES=20 BENCH_ITERS=2000 BENCH_LATENCY_SAMPLES=1 BENCH_LATENCY_BATCH=64 BENCH_RANDOMIZE_ORDER=1
```

External baselines：

```text
make eval-osdi-baselines RUN_ID=20260615T-kvm-external-baselines-batch64-v1 BASELINE_SAMPLES=20 BASELINE_ITERS=500 BASELINE_LATENCY_SAMPLES=1 BASELINE_LATENCY_BATCH=64
```

Comparison verdict：

```text
make eval-osdi-performance-comparison RUN_ID=20260615T-eval-comparison-batch64-v1 EVAL_OSDI_PHASE1_RUN_ID=20260615T-kvm-bench-release-batch64-v1 EVAL_OSDI_PERFORMANCE_BASELINE_RUN_ID=20260615T-kvm-external-baselines-batch64-v1
```

Hard gate expected-fail：

```text
make eval-osdi-performance RUN_ID=20260615T-eval-comparison-batch64-hardgate-v1 EVAL_OSDI_PHASE1_RUN_ID=20260615T-kvm-bench-release-batch64-v1 EVAL_OSDI_PERFORMANCE_BASELINE_RUN_ID=20260615T-kvm-external-baselines-batch64-v1
```

## 结果

Internal KVM microbench root：

- 路径：`results/phase1/20260615T-kvm-bench-release-batch64-v1/`
- `bench` rows：700
- `bench_latency` rows：700
- unique samples：20
- `min_ops_per_latency_row=64`
- randomized order rows：700
- variant order rows：5
- failing ops：0

External baseline root：

- 路径：`results/eval-osdi/baselines/20260615T-kvm-external-baselines-batch64-v1/`
- raw rows：1617
- bench rows：800
- latency rows：800
- five baselines release-pass：copy tree、symlink forest、bind mount、OverlayFS、FUSE redirect
- unique sample budget：pass
- min bench unique samples per case：20
- min latency unique samples per case：20

Comparison root：

- 路径：`results/eval-osdi/paper/20260615T-eval-comparison-batch64-v1/b2-performance/`
- `input_gate_pass=true`
- `has_internal_latency_batch=true`
- `has_external_latency_batch=true`
- `comparison_rows_complete=true`
- `baseline_release_gate_pass=true`
- `release_gate_pass=false`

Hard gate root：

- 路径：`results/eval-osdi/paper/20260615T-eval-comparison-batch64-hardgate-v1/b2-performance/`
- `make eval-osdi-performance` 按预期失败，退出状态为 2。

## 阈值判定

Batch=64 后，B2/B8 不再是方法学输入阻塞，而是明确的阈值失败：

- `kernel_p99_threshold_pass=false`
- `fuse_speedup_threshold_pass=false`
- `pass_only_threshold_pass=false`
- max policy/native p99 ratio：1.77x
- min policy/FUSE p99 speedup：1.33x
- max pass-only/native p99 ratio：1.71x

失败 case 的 reviewer 含义：

- `build_tree_stat_walk` 的 policy/native p99 ratio 最高，说明 tree-walk 场景仍有内核
  path overhead 风险。
- `lookup_tool_redirect` 也超过 1.5x kernel p99 threshold。
- `exec_tool_redirect` 对 FUSE 只有 1.33x speedup，不能支撑“明显优于 FUSE”的表述。
- pass-only residual 超过 1.1x，说明 attach/static-branch/BPF call 之外还有
  RCU-walk downgrade、context 构造、cgroup effective program lookup 或 BPF run context
  setup 等剩余成本需要定位。

## 结论

这一步完成了 B2/B8 release input methodology 修正：raw input、tail artifact、
external baseline tail、CI、随机化顺序、system metrics 和 baseline release gate 都已经通过。

但 C2/C3/C5 仍不支持：

- C2 仍缺 setup/storage/update macrobench comparison。
- C3 失败在 kernel p99 threshold 和 FUSE speedup threshold。
- C5 失败在 pass-only residual overhead threshold 和机制归因不足。

下一步应转向内核热路径优化或性能 claim narrowing，而不是继续重复同一组 batch=64
方法学修正。
