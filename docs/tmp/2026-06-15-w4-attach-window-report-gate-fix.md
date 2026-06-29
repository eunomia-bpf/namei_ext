# W4 attach-window report gate 修复记录

> 2026-06-29 baseline scope update: this historical record preserves prior reasoning and results. Current C8/B12 guidance is claim-driven baseline selection; exact-map diagnostics are optional boundary evidence only when precomputed mapping is the competing claim.

更新日期：2026-06-15
阶段：实现 / 报告门禁修复
来源/命令：本地审查 `mk/report.mk` 与
`results/phase1/20260615T-w4-attach-window-optrace/` 的 output hash 文件
完整性：修复完成，KVM 重跑验证通过

## 动机

`w4-ccache-parent-compile-outputs.sha256` 和
`w4-ccache-table-compile-outputs.sha256` 已经从 4 行扩展为 6 行：前四行仍是
baseline/policy object hash pairs，新增两行是 Redis/nginx policy compile strace log。
本地审查发现 `make report` 的旧 hard gate 仍要求 output sha 文件只有 4 行。

这会导致新 W4 attach-window optrace 证据已经由 KVM target 生成成功，但完整 Phase 1
报告 target 在读取同一 result root 时失败。该问题会阻塞 Makefile-only 的 Phase 1
闭环，因此必须作为实现修复处理。

## 修改

- `mk/report.mk`
  - parent-scoped ccache compile output sha 行数从 4 改为 6；
  - table-only ccache compile output sha 行数从 4 改为 6；
  - parent/table output sha 的第 5/6 行必须分别指向 Redis/nginx policy compile
    strace log，且对应文件非空；
  - parent/table compile summary gate 重新检查 sampled optrace 字段：
    `attached_optrace_collected=true`、scope 为
    `sampled_ccache_compile_strace`、分子分母均大于 0，且分子不超过分母；
  - parent/table compile summary gate 重新计算
    `attached_sampled_operation_hit_rate ==
    attached_policy_cache_object_ops / attached_cache_path_file_ops`；
  - release counterfactual hard gate 同样重新计算 sampled hit rate，而不是只要求
    hit rate 大于 0。
  - release counterfactual hard gate 使用 parent compile raw strace log 重新计算
    Redis/nginx cache-path ops 和 object ops，并要求它们等于 parent summary 与
    release counterfactual row。

## 拒绝的替代方案

- 不把 strace logs 放进 output sha：这会让 optrace 原始证据不进入输出完整性检查。
- 只把行数从 4 改成 6：这能修复报告失败，但不能防止 JSON rate 与 raw count 不一致。
- 让 report 自动容忍 4 或 6 行：这会掩盖 result schema 漂移，不符合 fail-fast 规则。
- 只相信 parent summary：summary 是 runner 输出，不能替代 report 阶段对 raw strace 的
  独立复算。

## 验证结果

已执行：

```text
git diff --check
make bpf w1-oracle
make kvm-w4-ccache-release-counterfactual RUN_ID=20260615T-w4-attach-window-optrace-gatefix
sha256sum -c results/phase1/20260615T-w4-attach-window-optrace-gatefix/w4-ccache-release-counterfactual-inputs.sha256
```

结果：

- KVM target 退出码为 0；
- `w4-ccache-parent-compile-outputs.sha256` 为 6 行；
- `w4-ccache-table-compile-outputs.sha256` 为 6 行；
- `w4-ccache-release-counterfactual-inputs.sha256` 为 11 行，`sha256sum -c` 全部 OK；
- report 等价 gate 复算通过：parent raw strace replay 得到 Redis `20 8` 和 nginx
  `20 8`，release row 为 `attached_cache_path_file_ops=40`、
  `attached_policy_cache_object_ops=16`、`attached_sampled_operation_hit_rate=0.4`，
  且 `qualified_for_c8=false`。

完整 `make report` 仍要求完整 Phase 1 result root。单项 W4 result root 不能冒充完整
Phase 1 report root；下一次完整 `make phase1` 会通过 `report` target 重新执行这些
W4 hard gates。

## 剩余风险

当前 sampled hit rate 仍是 strace path-name proxy，不是 kernel-side policy decision
counter，也不是 release-level operation-weighted hit rate。因此该修复只加强报告一致性，
不能把 W4 升级为 `qualified_for_c8=true`。
