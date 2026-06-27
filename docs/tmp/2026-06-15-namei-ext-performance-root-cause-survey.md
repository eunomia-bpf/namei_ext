# namei_ext performance root-cause 调研记录

Last updated: 2026-06-15
Stage at update: execute/gate
Source/command: subagent Arendt review；`rg`/`nl` inspect `kernel/fs/namei.c`, `kernel/fs/namei_ext.c`, `kernel/fs/readdir.c`, `kernel/kernel/bpf/cgroup.c`, `bench/workloads/namei_ext_bench.c`；`jq` inspect `results/phase1/20260615T-kvm-bench-release-sample-pilot/bench.jsonl`
Completeness: partial

## 背景

Arendt 对 B2/B8 comparison gate 给出基础设施 Weak Accept，但对性能 claim 本身给出
Weak Reject。最高价值下一步是解释 pass-only/static-branch/BPF-call residual overhead
以及 `access_tool_redirect`、`readdir_alias_view` p99 regressions，而不是继续堆 ledger。

## 调研目标

1. 判断当前 pass-only 结果到底测的是静态分支残余开销，还是更大的 path-resolution
   slow-path 组合成本。
2. 判断 `access`/`readdir` p99 失败是稳定 steady-state 性能问题，还是 release pilot
   的 latency batch 方法放大了 outlier。
3. 给下一步实现选择提供 reviewer-auditable 依据。

## 查看过的代码路径

- `kernel/fs/namei.c`
  - `walk_component()` 在 `namei_ext_enabled()` 后直接拒绝 RCU walk，并调用
    `namei_ext_lookup()`。
  - `open_last_lookups()` 对 open trailing component 也重复同样逻辑。
  - `namei_ext_apply_redirect()` 只在 action 为 REDIRECT 后替换 `nd->last`。
- `kernel/fs/namei_ext.c`
  - `namei_ext_lookup()` 每次先 `memset()` 整个 `bpf_namei_ext_ctx`，填充 name、
    parent inode identity，再调用 `__cgroup_bpf_run_namei_ext()`。
  - `namei_ext_filldir()` 对目录枚举中的每一个 dirent 构造 ctx 并运行 BPF。
- `kernel/kernel/bpf/cgroup.c`
  - `__cgroup_bpf_run_namei_ext()` 每次做 `task_dfl_cgroup(current)`、写
    `ctx->cgroup_id`、读 cgroup effective program array、设置 BPF run context、
    `bpf_prog_run()`。
- `bench/workloads/namei_ext_bench.c`
  - `pass_only` variant 仍然走完整 attach path。
  - latency row 是 batch timing：`elapsed_ns / ops`，不是单次 syscall p99。

## 主要发现

当前 pass-only 不是“只测一个 static branch”。它至少包含：

1. `namei_ext_enabled()` static key 检查；
2. lookup/open path 退出 RCU walk；
3. `bpf_namei_ext_ctx` 清零和字段填充；
4. cgroup lookup 和 effective program array 读取；
5. BPF run context setup/reset；
6. pass-only eBPF 程序执行；
7. 对 readdir，每个 dirent 重复上述 BPF 调用路径。

因此，`pass_only/native` 远高于 1.1x 的结果不能被解释成单纯 static-branch residual。
它暴露的是当前原型 hook placement 和 ctx construction 的真实热路径成本。

## Raw evidence

旧 release-sample pilot：

- `results/phase1/20260615T-kvm-bench-release-sample-pilot/bench.jsonl`
- `SAMPLES=20`
- `BENCH_ITERS=2000`
- `BENCH_LATENCY_SAMPLES=1`
- `BENCH_LATENCY_BATCH=4`

`bench_latency` 的 ops 分布是：

- min ops per row: 4
- unique ops: 4, 20, 256

`access_tool_redirect` 和 `readdir_alias_view` 的 aggregate rows 显示 median/steady-state
差距远小于 tail comparison 中的极端 p99：

- `access_tool_redirect` aggregate median ns/op:
  - baseline: 约 205 ns/op
  - pass_only: 约 344 ns/op
  - policy: 约 351 ns/op
- `readdir_alias_view` aggregate median ns/op:
  - baseline: 约 208 ns/op
  - pass_only: 约 283 ns/op
  - policy: 约 283 ns/op

但 `bench_latency` p99 来自每组 20 个 4-op batch 的最大值，坏样本明显由单个
small-batch outlier 决定：

- `access_tool_redirect` policy 出现 2539.5 ns/op outlier；
- `readdir_alias_view` policy 出现 1887.4 ns/op outlier；
- `pass_only` access 也出现 1394.5 ns/op outlier。

这些 outlier 不能删除，但在 OSDI 口径下也不能直接当成稳定 release p99 结论。

## 解释

当前证据同时说明两件事：

1. 系统实现确实还有热路径开销问题。尤其是 RCU walk 降级、每次 ctx 构造、cgroup
   BPF run setup 和 readdir per-entry BPF 调用。
2. 旧 release pilot 的 tail-latency 方法不够强。4-op batch 让 p99 对单个调度或
   cache outlier 非常敏感，不能支撑 paper-grade p99 claim。

这两点都应该 fail-closed：不能 claim C3/C5，也不能把旧数据包装成 release p99。

## 备选方案

- 只调高阈值：拒绝。阈值调整会掩盖真实 overhead，缺少 reviewer-auditable 原因。
- 删除 p99 outlier：拒绝。负结果必须保留。
- 只报告 aggregate median：拒绝。OSDI 性能 claim 需要 tail/distribution。
- 增加 release latency batch gate：接受。旧 raw evidence 保留，但不再被 input gate
  当作 paper-grade p99 输入。

## 后续

1. 已实现 `EVAL_OSDI_REQUIRED_LATENCY_BATCH` gate，旧数据变成
   `blocked_by_missing_inputs`。
2. 下一步需要重跑 release microbench 和 external baselines：
   `BENCH_LATENCY_BATCH=64`、`BASELINE_LATENCY_BATCH=64`。
3. 若重跑后仍失败，再进入内核优化：
   - 减少 lookup/open 中不必要的 RCU walk 降级；
   - 缩小 pass-only ctx construction；
   - 评估 per-cgroup program pointer/cache；
   - 评估 readdir 是否需要 per-entry BPF 或可以使用更粗粒度 fast path。

