# W4 attach-window optrace review revision 记录

更新日期：2026-06-15
阶段：review / revision
来源/命令：独立 subagent Mill 对 W4 attach-window optrace 和 release counterfactual
accounting 做 OSDI-style 对抗审查
完整性：P0/P1 清零，复审 verdict 为 Weak Accept

## 初始审查结论

Mill 初审给出 Weak Reject。没有 P0，两个 P1：

1. `mk/report.mk` 仍把 `w4-ccache-parent-compile-outputs.sha256` 和
   `w4-ccache-table-compile-outputs.sha256` 当作 4 行文件检查，但 KVM target 已经把
   Redis/nginx policy compile strace logs 加入 output sha，实际为 6 行。
2. release counterfactual hard gate 只检查 sampled optrace 字段存在且为正数，没有
   复算 `attached_sampled_operation_hit_rate`，也没有从 raw strace replay 计数。

P2 包括：`count_ccache_optrace()` 是 substring proxy、论文中 “sampled object hit
rate” 容易被误读为 release-level hit rate、设计记录仍写“待实现”。

## 修复

- `mk/report.mk`
  - parent/table output sha 行数 gate 改为 6；
  - 第 5/6 行必须分别是 Redis/nginx policy compile strace log；
  - strace log 文件必须非空；
  - parent/table summary 和 release counterfactual 都重新计算
    `attached_sampled_operation_hit_rate ==
    attached_policy_cache_object_ops / attached_cache_path_file_ops`；
  - report gate 从 parent compile raw strace logs replay 计数 Redis/nginx
    cache-path ops 和 object ops，并要求它们等于 parent summary 与 release row。
- `docs/research_plan.md` 和 `docs/experiment-plans/osdi-evaluation.md`
  - canonical W4 run 更新为
    `RUN_ID=20260615T-w4-attach-window-optrace-gatefix`。
- `docs/paper/sections/04-implementation.tex`
  - 将 “sampled object hit rate” 改为 “eligible object-set coverage”，避免和
    release-level operation-weighted hit rate 混淆。
- `docs/paper/sections/05-evaluation.tex`
  - 当前证据列表和 workload/source-signal ledger 补上 W4 release counterfactual
    accounting，避免 paper 和 canonical result root 不一致。
- `docs/tmp/2026-06-15-w4-attach-window-optrace-design.md`
  - 加入后续实现记录指针。
- `docs/tmp/2026-06-15-w4-attach-window-optrace-implementation.md`
  - 加入后续 gatefix 记录指针。
- `docs/tmp/2026-06-15-w4-attach-window-report-gate-fix.md`
  - 记录 report gate fix、raw strace replay checker 和 KVM 验证结果。

## 验证

已执行并通过：

```text
git diff --check
make bpf w1-oracle
make kvm-w4-ccache-release-counterfactual RUN_ID=20260615T-w4-attach-window-optrace-gatefix
sha256sum -c results/phase1/20260615T-w4-attach-window-optrace-gatefix/w4-ccache-release-counterfactual-inputs.sha256
make -C docs/paper check paper
```

额外复算：

```text
parent raw strace replay: Redis 20/8, nginx 20/8
release row: attached_cache_path_file_ops=40
release row: attached_policy_cache_object_ops=16
release row: attached_sampled_operation_hit_rate=0.4
release row: qualified_for_c8=false
```

## 复审结论

Mill 复审给出 Weak Accept：

- 原 P1 1 已解决：report gate 现在要求 6 行，并检查 strace log 路径和非空性。
- 原 P1 2 已解决：report gate 现在复算 sampled hit rate，并从 raw strace replay
  验证 Redis/nginx counts。
- 没有剩余 P0/P1。
- 当前 W4 optrace 仍正确标记为 non-release / non-C8：
  `attached_sampled_operation_hit_rate_is_release=false`、
  `operation_weighted_policy_cache_hit_rate=false`、
  `operation_weighted_policy_hit_rate_is_release=false`、
  `qualified_for_c8=false`。

## 剩余 P2

下一次声明“完整 Phase 1 闭环”前，需要在完整 result root 上跑 `make phase1` 或至少
跑完整 root 的 `make report`，让这些 W4 hard gates 在真实全量 report 中执行一次。
单项 W4 result root 不能冒充完整 Phase 1 report root。
