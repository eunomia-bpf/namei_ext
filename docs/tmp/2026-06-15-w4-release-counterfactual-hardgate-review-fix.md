# W4 release counterfactual hard gate 审稿修复记录

更新日期：2026-06-15
阶段：执行 / 主张门禁
来源/命令：Mencius 子代理按 OSDI evaluation 规则复审 W4 release counterfactual accounting
完整性：完成

## 背景

独立 subagent 按 OSDI/SOSP evaluation 标准审阅
`w4-ccache-release-counterfactual.jsonl`、KVM target、report hard gate 和相关文档后给出
Weak Reject。它认可 raw artifact 可以作为 W4 的负 C8 证据，但指出 report gate 还不够强：

- 只检查存在 1 条负证据结果行，没有禁止同一 JSONL 中额外出现
  `qualified_for_c8=true` 或发布级命中为 true 的结果行；
- `table_budget_failure=false` 虽然当前事实成立，但 report 没有复算
  `table_over_parent_rule_ratio <= max_over_materialization_ratio`；
- 实现记录头部仍有英文元数据标签；
- `cache_path_policy_coverage` 字段名容易被误读成 operation coverage。

## 修复

本次只做报告和文档修复，不改变已经通过的 KVM 原始语义。

- `mk/report.mk`
  - 增加 `w4-ccache-release-counterfactual` 事件数量恰好为 1 的硬门禁；
  - 增加 `w4-ccache-release-counterfactual-summary` 事件数量恰好为 1 的硬门禁；
  - 增加所有带 `qualified_for_c8` 字段的结果行都必须为 `false` 的硬门禁；
  - 增加 `operation_weighted_policy_cache_hit_rate` 和
    `operation_weighted_policy_hit_rate_is_release` 不能为 `true` 的硬门禁；
  - 增加表基线预算关系复算：
    `table_over_parent_rule_ratio == table_rule_writes / parent_rule_writes`，
    且 `table_over_parent_rule_ratio <= max_over_materialization_ratio`；
  - 将报告表头中的 `Cache-Path Coverage` 改为
    `Sampled Object/Ops Ratio`，避免把 4/40 误读成发布级操作覆盖率。
- `docs/tmp/2026-06-15-w4-release-counterfactual-accounting-implementation.md`
  - 将头部元数据标签改为中文；
  - 明确 `cache_path_policy_coverage=0.1` 的严格含义是
    抽样对象数 / cache-path 文件操作数，不是发布级操作加权命中率；
  - 补充硬门禁的额外不变量。

## 验证结果

对当前原始 artifact 运行 report gate 等价检查：

```text
jq -s '[.[] | select(.event == "w4-ccache-release-counterfactual")] | length' \
  results/phase1/20260615T-w4-release-counterfactual/w4-ccache-release-counterfactual.jsonl

jq -s '[.[] | select(.qualified_for_c8 != null and .qualified_for_c8 != false)] | length' \
  results/phase1/20260615T-w4-release-counterfactual/w4-ccache-release-counterfactual.jsonl

jq -s '[.[] | select(.event == "w4-ccache-release-counterfactual" and
  .table_over_parent_rule_ratio == (.table_rule_writes / .parent_rule_writes) and
  .table_over_parent_rule_ratio <= .max_over_materialization_ratio)] | length' \
  results/phase1/20260615T-w4-release-counterfactual/w4-ccache-release-counterfactual.jsonl
```

还需要重跑 `make -C docs/paper check paper`，确保文档改动不破坏论文构建。

实际结果：

- release counterfactual 事件数量为 1；
- summary 事件数量为 1；
- `qualified_for_c8` 非 false 的结果行为 0；
- 发布级操作加权命中字段为 true 的结果行为 0；
- 表基线预算公式复算通过；
- `sha256sum -c` 对 11 个输入全部返回 OK；
- `git diff --check` 无输出；
- `make -C docs/paper check paper` 通过。
- Mencius 子代理复审结论为 Weak Accept；P0/P1 findings 为无，当前 artifact 可以作为
  W4 的负 C8 accounting gate 保留。
