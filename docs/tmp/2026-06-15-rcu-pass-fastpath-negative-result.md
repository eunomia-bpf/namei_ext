# RCU pass fastpath 负结果记录

Last updated: 2026-06-15
Stage at update: execute/analyze
Source/command: `make kernel`、`make kvm-bench`、`make eval-osdi-baselines`、`make eval-osdi-performance-comparison`
Completeness: complete for this optimization attempt; optimization rejected

## 动机

Batch=64 release comparison 已经消除了 B2/B8 的 latency input 阻塞，但 C3/C5
仍然失败：

- max policy/native p99 ratio：1.77x；
- min policy/FUSE p99 speedup：1.33x；
- max pass-only/native p99 ratio：1.71x。

性能 root-cause 调研显示，当前 `walk_component()` 和 `open_last_lookups()` 在
`namei_ext_enabled()` 且处于 `LOOKUP_RCU` 时先返回 `-ECHILD`，再在 ref-walk 中调用
`namei_ext_lookup()`。这意味着 pass-only policy 也会放弃 RCU-walk，并且测到的不是
单纯 static-branch 开销，而是 RCU 降级、context 构造、cgroup BPF dispatch 和
BPF 程序执行的组合成本。

本次尝试的目标是验证一个最小内核 fastpath：如果 policy 返回 `PASS`，是否可以在
RCU-walk 中直接继续，从而降低 pass-only residual overhead。

## 调研过的代码路径

- `kernel/fs/namei.c`
  - `walk_component()` 中 lookup component 的 RCU/ref-walk 分支。
  - `open_last_lookups()` 中 trailing component 的 open path。
  - `try_to_unlazy(nd)` 能否在 RCU decision 后转入 ref-walk 并复用 decision。
- `kernel/fs/namei_ext.c`
  - `namei_ext_lookup()` 构造 `bpf_namei_ext_ctx` 并调用 cgroup BPF hook。
- `kernel/kernel/bpf/cgroup.c`
  - `__cgroup_bpf_run_namei_ext()` 仍包含 cgroup lookup、effective prog array、
    BPF run context setup 和 `bpf_prog_run()`。

## PoC 1：RCU 中允许 BPF，REDIRECT 返回 `-ECHILD`

实现思路：

1. 删除 lookup/open path 中 “只要 namei_ext enabled 就先退出 RCU” 的逻辑。
2. 在 RCU-walk 中调用 `namei_ext_lookup()`。
3. 如果 action 是 `PASS`，继续 RCU-walk。
4. 如果 action 是 `REDIRECT`，返回 `-ECHILD`，让 VFS 以 ref-walk 重试。

验证命令：

```text
make kernel
make kvm-bench RUN_ID=20260615T-kvm-bench-rcu-pass-smoke-v1 SAMPLES=1 BENCH_ITERS=500 BENCH_LATENCY_SAMPLES=1 BENCH_LATENCY_BATCH=64 BENCH_RANDOMIZE_ORDER=1
make kvm-bench RUN_ID=20260615T-kvm-bench-rcu-pass-batch64-v1 SAMPLES=20 BENCH_ITERS=2000 BENCH_LATENCY_SAMPLES=1 BENCH_LATENCY_BATCH=64 BENCH_RANDOMIZE_ORDER=1
make eval-osdi-baselines RUN_ID=20260615T-kvm-external-baselines-rcu-pass-batch64-v1 BASELINE_SAMPLES=20 BASELINE_ITERS=500 BASELINE_LATENCY_SAMPLES=1 BASELINE_LATENCY_BATCH=64
make eval-osdi-performance-comparison RUN_ID=20260615T-eval-comparison-rcu-pass-batch64-v1 EVAL_OSDI_PHASE1_RUN_ID=20260615T-kvm-bench-rcu-pass-batch64-v1 EVAL_OSDI_PERFORMANCE_BASELINE_RUN_ID=20260615T-kvm-external-baselines-rcu-pass-batch64-v1
```

KVM smoke raw result：

- root：`results/phase1/20260615T-kvm-bench-rcu-pass-smoke-v1/`
- `bench` rows：35
- `bench_latency` rows：35
- unique samples：1
- `min_ops_per_latency_row=64`
- failing ops：0

Release comparison result：

- root：`results/eval-osdi/paper/20260615T-eval-comparison-rcu-pass-batch64-v1/b2-performance/`
- `input_gate_pass=true`
- `kernel_p99_threshold_pass=false`
- `fuse_speedup_threshold_pass=false`
- `pass_only_threshold_pass=false`
- max policy/native p99 ratio：2.49x
- min policy/FUSE p99 speedup：1.62x
- max pass-only/native p99 ratio：1.48x

Exact raw files：

- internal bench：`results/phase1/20260615T-kvm-bench-rcu-pass-batch64-v1/bench.jsonl`
- internal metadata：`results/phase1/20260615T-kvm-bench-rcu-pass-batch64-v1/metadata.json`
- internal kernel status：`results/phase1/20260615T-kvm-bench-rcu-pass-batch64-v1/kernel-repo-status.txt`
- external baseline ledger：`results/eval-osdi/baselines/20260615T-kvm-external-baselines-rcu-pass-batch64-v1/baseline-ledger.jsonl`
- comparison verdict：`results/eval-osdi/paper/20260615T-eval-comparison-rcu-pass-batch64-v1/b2-performance/performance-comparison.jsonl`
- internal tail artifact：`results/eval-osdi/paper/20260615T-eval-comparison-rcu-pass-batch64-v1/b2-performance/bench-latency-tail.jsonl`
- external tail artifact：`results/eval-osdi/paper/20260615T-eval-comparison-rcu-pass-batch64-v1/b2-performance/external-baseline-latency-tail.jsonl`

解释：

- pass-only residual 从原始 batch=64 的 1.71x 降到 1.48x，说明 RCU-walk 降级确实是
  一部分开销来源。
- 但 redirect policy 变差，max policy/native 从 1.77x 增加到 2.49x。原因很可能是
  redirect path 在 RCU-walk 中先运行一次 BPF，再返回 `-ECHILD`，ref-walk 重试时又运行
  一次 BPF，导致 redirect 场景 double run。
- 该 PoC 不能保留，因为它改善 pass-only，却显著恶化真实 redirect policy。

## PoC 2：RCU 中允许 BPF，REDIRECT 通过 `try_to_unlazy(nd)` 复用 decision

实现思路：

1. 保留 PoC 1 的 RCU 中运行 BPF。
2. 当 action 是 `REDIRECT` 时，不直接返回 `-ECHILD`。
3. 先调用 `try_to_unlazy(nd)`，若成功，则在同一次 path walk 中应用 redirect decision。
4. 若 unlazy 失败，返回 `-ECHILD`。

验证命令：

```text
make kernel
make kvm-bench RUN_ID=20260615T-kvm-bench-rcu-redirect-unlazy-smoke-v1 SAMPLES=1 BENCH_ITERS=500 BENCH_LATENCY_SAMPLES=1 BENCH_LATENCY_BATCH=64 BENCH_RANDOMIZE_ORDER=1
make kvm-bench RUN_ID=20260615T-kvm-bench-rcu-redirect-unlazy-batch64-v1 SAMPLES=20 BENCH_ITERS=2000 BENCH_LATENCY_SAMPLES=1 BENCH_LATENCY_BATCH=64 BENCH_RANDOMIZE_ORDER=1
make eval-osdi-baselines RUN_ID=20260615T-kvm-external-baselines-rcu-redirect-unlazy-batch64-v1 BASELINE_SAMPLES=20 BASELINE_ITERS=500 BASELINE_LATENCY_SAMPLES=1 BASELINE_LATENCY_BATCH=64
make eval-osdi-performance-comparison RUN_ID=20260615T-eval-comparison-rcu-redirect-unlazy-batch64-v1 EVAL_OSDI_PHASE1_RUN_ID=20260615T-kvm-bench-rcu-redirect-unlazy-batch64-v1 EVAL_OSDI_PERFORMANCE_BASELINE_RUN_ID=20260615T-kvm-external-baselines-rcu-redirect-unlazy-batch64-v1
```

KVM smoke raw result：

- root：`results/phase1/20260615T-kvm-bench-rcu-redirect-unlazy-smoke-v1/`
- `bench` rows：35
- `bench_latency` rows：35
- unique samples：1
- `min_ops_per_latency_row=64`
- failing ops：0

Release comparison result：

- root：`results/eval-osdi/paper/20260615T-eval-comparison-rcu-redirect-unlazy-batch64-v1/b2-performance/`
- `input_gate_pass=true`
- `kernel_p99_threshold_pass=false`
- `fuse_speedup_threshold_pass=false`
- `pass_only_threshold_pass=false`
- max policy/native p99 ratio：2.43x
- min policy/FUSE p99 speedup：1.70x
- max pass-only/native p99 ratio：1.38x

Exact raw files：

- internal bench：`results/phase1/20260615T-kvm-bench-rcu-redirect-unlazy-batch64-v1/bench.jsonl`
- internal metadata：`results/phase1/20260615T-kvm-bench-rcu-redirect-unlazy-batch64-v1/metadata.json`
- internal kernel status：`results/phase1/20260615T-kvm-bench-rcu-redirect-unlazy-batch64-v1/kernel-repo-status.txt`
- external baseline ledger：`results/eval-osdi/baselines/20260615T-kvm-external-baselines-rcu-redirect-unlazy-batch64-v1/baseline-ledger.jsonl`
- comparison verdict：`results/eval-osdi/paper/20260615T-eval-comparison-rcu-redirect-unlazy-batch64-v1/b2-performance/performance-comparison.jsonl`
- internal tail artifact：`results/eval-osdi/paper/20260615T-eval-comparison-rcu-redirect-unlazy-batch64-v1/b2-performance/bench-latency-tail.jsonl`
- external tail artifact：`results/eval-osdi/paper/20260615T-eval-comparison-rcu-redirect-unlazy-batch64-v1/b2-performance/external-baseline-latency-tail.jsonl`

解释：

- pass-only residual 继续降到 1.38x，说明该方向对 attach/pass-only overhead 有帮助。
- 但 policy/native 仍然比原始 batch=64 差。最差 case 是 `access_tool_redirect`，
  policy/native p99 ratio 为 2.43x；`lookup_native_hot` 也为 1.56x，超过 1.5x 阈值。
- `exec_tool_redirect` 对 FUSE 只有 1.70x speedup，仍达不到 2x 阈值。
- 该 PoC 仍不能保留，因为它没有让 C3/C5 通过，并且把主 redirect policy 的最差
  kernel p99 ratio 从 1.77x 恶化到 2.43x。

## 与原始 batch=64 的对比

| Run | max policy/native p99 | min policy/FUSE p99 speedup | max pass-only/native p99 | 结论 |
|---|---:|---:|---:|---|
| 原始 batch=64 | 1.77x | 1.33x | 1.71x | input 通过，阈值失败 |
| RCU PASS PoC | 2.49x | 1.62x | 1.48x | pass-only 改善，policy/native 恶化 |
| RCU REDIRECT unlazy PoC | 2.43x | 1.70x | 1.38x | pass-only 改善，policy/native 仍恶化 |

## 最终处理

两个 PoC 都被撤回；当前内核代码没有保留 RCU fastpath 改动。恢复稳定路径后重新构建：

```text
make kernel
make kvm-bench RUN_ID=20260615T-kvm-bench-post-rcu-experiment-stable-smoke-v1 SAMPLES=1 BENCH_ITERS=500 BENCH_LATENCY_SAMPLES=1 BENCH_LATENCY_BATCH=64 BENCH_RANDOMIZE_ORDER=1
```

恢复后 KVM smoke raw result：

- root：`results/phase1/20260615T-kvm-bench-post-rcu-experiment-stable-smoke-v1/`
- kernel image：`Linux version 7.1.0-rc7-g31a33d22c212-dirty ... #7`
- `bench` rows：35
- `bench_latency` rows：35
- unique samples：1
- `min_ops_per_latency_row=64`
- failing ops：0

恢复后 exact raw files：

- stable smoke bench：`results/phase1/20260615T-kvm-bench-post-rcu-experiment-stable-smoke-v1/bench.jsonl`
- stable smoke metadata：`results/phase1/20260615T-kvm-bench-post-rcu-experiment-stable-smoke-v1/metadata.json`
- stable kernel status：`results/phase1/20260615T-kvm-bench-post-rcu-experiment-stable-smoke-v1/kernel-repo-status.txt`

当前 `kernel/fs/namei.c` 没有 RCU fastpath diff；剩余 kernel diff 是 parent-aware
ABI/context 支持，涉及 `fs/namei_ext.c`、`include/uapi/linux/bpf.h`、
`kernel/bpf/cgroup.c` 和 `tools/include/uapi/linux/bpf.h`。因此当前内核没有保留上述
RCU fastpath。

## 可复现性限制

两个 PoC 都在 dirty kernel tree 中验证，result roots 的 `kernel-repo-status.txt`
记录了当时 `fs/namei.c` 被修改，但 exact PoC patch 没有被持久化为可应用 diff。
因此这些结果只作为 negative engineering evidence 和 claim narrowing 依据，不作为
可复现的正向性能 claim 或主线实现依据。

## 结论和后续

这个优化方向不应作为 Phase 1 主线提交。它证明 RCU-walk 降级是 pass-only overhead 的
一部分，但一个只为 PASS 优化的 fastpath 会让 REDIRECT policy 结果更差；即使用
`try_to_unlazy(nd)` 避免 double run，也没有通过 C3/C5 的 release thresholds。

下一步更高价值的方向是：

1. 降低 `__cgroup_bpf_run_namei_ext()` 的 per-lookup dispatch/context 成本；
2. 分析 `access_tool_redirect` 和 `build_tree_stat_walk` 为什么对 policy/native p99
   最敏感；
3. 评估是否需要更保守地收窄 C3/C5，比如只声称功能机制和相对 FUSE 的部分场景优势；
4. 继续补 C2 macrobench setup/storage/update 和 C8 table/update budget evidence。
