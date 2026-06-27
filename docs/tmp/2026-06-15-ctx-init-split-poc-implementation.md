# ctx 初始化拆分 PoC 实现记录

Last updated: 2026-06-15
Stage at update: implementation
Source/command: planned R045 from `docs/tmp/2026-06-15-namei-ext-dispatch-context-cost-survey.md`
Completeness: complete

## 动机

RCU-pass fastpath 两轮 PoC 都已拒绝：它们降低 pass-only residual，但恶化 redirect
policy 的 worst-case policy/native p99。Dispatch/context survey 将下一轮最低风险优化
收敛到不改 UAPI 的 ctx 初始化拆分。

当前 `namei_ext_init_ctx()` 每次对 184 字节 `struct bpf_namei_ext_ctx` 做整块
`memset()`，再填字段并复制 component name。这个 PoC 尝试减少无用写入：

- 保持所有 UAPI offset 和字段语义不变；
- 保持 `name[]` 超出 copied component 的尾部为 0；
- 保持 `redirect_name_len`、`reserved` 和 `redirect_name[]` 在 BPF 执行前为 0；
- 保持 `cgroup_id`、parent identity 和 `parent_flags` 初始为 0；
- 不改变 `__cgroup_bpf_run_namei_ext()`、helper set、RCU 行为或 policy 逻辑。

## 实际修改

只修改 `kernel/fs/namei_ext.c`：

1. 移除 `memset(ctx, 0, sizeof(*ctx))`。
2. 显式写入 input scalar fields。
3. 显式清零 `cgroup_id`、`redirect_name_len`、`reserved`、parent fields。
4. 先复制 `name` 的 `copied` 字节，再只清零 `name + copied` 的 tail。
5. 清零完整 `redirect_name[]` output buffer，保持 BPF 部分写 output 时的旧语义。

该修改不改变 `struct bpf_namei_ext_ctx` 的 UAPI layout，不改变 verifier access
rules，不改变 attach type，也不改变 policy object。当前工作树中的 diff 仍保留
parent-aware context 的既有修改；本 PoC 只在 `namei_ext_init_ctx()` 内拆分初始化路径。

## 不做的事情

- 不删除 `bpf_cg_run_ctx`。
- 不懒填 `cgroup_id`。
- 不改变 `BPF_NAMEI_EXT_NAME_MAX`。
- 不改变 verifier access rules。
- 不把 object-file inspection 当成 Phase 1 validation。

## 验证计划

最小验证：

```text
make kernel
make kvm-bench RUN_ID=20260615T-kvm-bench-ctx-init-split-smoke-v1 SAMPLES=1 BENCH_ITERS=500 BENCH_LATENCY_SAMPLES=1 BENCH_LATENCY_BATCH=64 BENCH_RANDOMIZE_ORDER=1
```

若 smoke 通过，再跑 release comparison：

```text
make kvm-bench RUN_ID=20260615T-kvm-bench-ctx-init-split-batch64-v1 SAMPLES=20 BENCH_ITERS=2000 BENCH_LATENCY_SAMPLES=1 BENCH_LATENCY_BATCH=64 BENCH_RANDOMIZE_ORDER=1
make eval-osdi-baselines RUN_ID=20260615T-kvm-external-baselines-ctx-init-split-batch64-v1 BASELINE_SAMPLES=20 BASELINE_ITERS=500 BASELINE_LATENCY_SAMPLES=1 BASELINE_LATENCY_BATCH=64
make eval-osdi-performance-comparison RUN_ID=20260615T-eval-comparison-ctx-init-split-batch64-v1 EVAL_OSDI_PHASE1_RUN_ID=20260615T-kvm-bench-ctx-init-split-batch64-v1 EVAL_OSDI_PERFORMANCE_BASELINE_RUN_ID=20260615T-kvm-external-baselines-ctx-init-split-batch64-v1
```

还需要运行 hard gate，确认 threshold-failing evidence 不会被误计为 supported：

```text
make eval-osdi-performance RUN_ID=20260615T-eval-comparison-ctx-init-split-batch64-hardgate-v1 EVAL_OSDI_PHASE1_RUN_ID=20260615T-kvm-bench-ctx-init-split-batch64-v1 EVAL_OSDI_PERFORMANCE_BASELINE_RUN_ID=20260615T-kvm-external-baselines-ctx-init-split-batch64-v1
```

## 成功/失败判定

成功需要同时满足：

- KVM smoke 无 functional failure；
- batch=64 input gate 通过；
- pass-only/native p99 改善；
- policy/native p99 不恶化；
- 若 thresholds 仍失败，必须保留负结果并更新 tracker/summary/verdict。

如果该 PoC 无法同时改善 pass-only 与 redirect policy，则不能继续把 ctx 初始化拆分作为
C3/C5 remediation 主线，应转向 claim narrowing 或 helper-set/no-run-ctx ABI 设计。

## 验证结果

`make kernel` 通过，生成 `.build/kernel/arch/x86/boot/bzImage`。

KVM smoke：

- 命令：`make kvm-bench RUN_ID=20260615T-kvm-bench-ctx-init-split-smoke-v1 SAMPLES=1 BENCH_ITERS=500 BENCH_LATENCY_SAMPLES=1 BENCH_LATENCY_BATCH=64 BENCH_RANDOMIZE_ORDER=1`
- 结果目录：`results/phase1/20260615T-kvm-bench-ctx-init-split-smoke-v1/`
- `bench_rows=35`、`latency_rows=35`、`unique_samples=1`、`min_latency_ops=64`、
  `failing_ops=0`、`done_status=0`。

内部 release input：

- 命令：`make kvm-bench RUN_ID=20260615T-kvm-bench-ctx-init-split-batch64-v1 SAMPLES=20 BENCH_ITERS=2000 BENCH_LATENCY_SAMPLES=1 BENCH_LATENCY_BATCH=64 BENCH_RANDOMIZE_ORDER=1`
- 结果目录：`results/phase1/20260615T-kvm-bench-ctx-init-split-batch64-v1/`
- `bench_rows=700`、`latency_rows=700`、`unique_samples=20`、
  `min_latency_ops=64`、`max_latency_ops=4096`、`failing_ops=0`、
  `done_status=0`。

外部 baseline release input：

- 命令：`make eval-osdi-baselines RUN_ID=20260615T-kvm-external-baselines-ctx-init-split-batch64-v1 BASELINE_SAMPLES=20 BASELINE_ITERS=500 BASELINE_LATENCY_SAMPLES=1 BASELINE_LATENCY_BATCH=64`
- 结果目录：`results/eval-osdi/baselines/20260615T-kvm-external-baselines-ctx-init-split-batch64-v1/`
- `raw_rows=1617`、`bench_rows=800`、`latency_rows=800`、
  `baselines_selected=5`、`baselines_release_passed=5`、
  `baseline_min_bench_unique_samples_per_case=20`、
  `baseline_min_latency_unique_samples_per_case=20`、`runner_failures=0`、
  `baseline_release_gate_pass=true`。

Comparison verdict：

- 命令：`make eval-osdi-performance-comparison RUN_ID=20260615T-eval-comparison-ctx-init-split-batch64-v1 EVAL_OSDI_PHASE1_RUN_ID=20260615T-kvm-bench-ctx-init-split-batch64-v1 EVAL_OSDI_PERFORMANCE_BASELINE_RUN_ID=20260615T-kvm-external-baselines-ctx-init-split-batch64-v1`
- 结果目录：`results/eval-osdi/paper/20260615T-eval-comparison-ctx-init-split-batch64-v1/b2-performance/`
- Summary：`input_gate_pass=true`、`kernel_p99_threshold_pass=false`、
  `fuse_speedup_threshold_pass=false`、`pass_only_threshold_pass=true`、
  `max_policy_to_native_p99_ratio=1.812401707481465`、
  `min_policy_to_fuse_p99_speedup=1.6385146327254374`、
  `max_pass_only_to_native_p99_ratio=1.0946244650331562`、
  `c2_supported=false`、`c3_supported=false`、`c5_supported=false`、
  `release_gate_pass=false`。

Hard gate：

- 命令：`make eval-osdi-performance RUN_ID=20260615T-eval-comparison-ctx-init-split-batch64-hardgate-v1 EVAL_OSDI_PHASE1_RUN_ID=20260615T-kvm-bench-ctx-init-split-batch64-v1 EVAL_OSDI_PERFORMANCE_BASELINE_RUN_ID=20260615T-kvm-external-baselines-ctx-init-split-batch64-v1`
- 结果目录：`results/eval-osdi/paper/20260615T-eval-comparison-ctx-init-split-batch64-hardgate-v1/b2-performance/`
- 退出状态：2，符合预期。失败原因是 `release_gate_pass=false`，不是输入缺失。

## 结论

ctx 初始化拆分是混合结果：

- 正向：pass-only/native p99 从原始 batch=64 verdict 的 1.71x 降到 1.095x，
  `pass_only_threshold_pass=true`。这说明整块 ctx 清零和字段初始化确实是 residual
  overhead 的一部分。
- 仍未达标：C3 仍失败。`lookup_native_hot` 的 policy/native p99 ratio 为 1.81x，
  `exec_tool_redirect` 的 policy/FUSE speedup 为 1.64x，低于 2x 阈值。
- 与原始 batch=64 verdict 相比，policy/native worst case 从 1.77x 小幅变为
  1.81x，因此该 PoC 不能作为完整 C3/C5 remediation。

因此，这个修改最多可作为低风险清理候选保留，不能支持论文中的性能主张。下一步应转向
redirect policy/map hot path、`cgroup_id`/run-context ABI 取舍的更明确设计，或直接收窄
C3/C5 wording。
