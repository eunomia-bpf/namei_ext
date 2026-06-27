# W4 合法形状 sibling hard gate 对齐记录

Last updated: 2026-06-15
Stage at update: execute / claim-gate
Source/command: Curie subagent review after `RUN_ID=20260615T-w4-valid-sibling-structured-oracle`
Completeness: complete

## 动机

Curie review 给出 scoped weak accept，但指出两个 P2：

- `mk/kvm.mk` 的 valid-shape sibling gate 已检查结构化内容 oracle，但没有同时要求
  `policy_executed=true` 和 `qualified_for_c8=false`。
- `mk/report.mk` 的展示行 predicate 比 report hard gate 略弱，少了
  `expected_content_len > 0`、`policy_executed=true` 和 `qualified_for_c8=false`。

这些不是 P0/P1 blocker，但会让后续 reviewer 或 report reader 看到的 gate 条件不完全一致。

## 实现

- `mk/kvm.mk`
  - `valid_sibling_pass` 现在要求：
    `pass=true`、`policy_executed=true`、`ccache_compile_policy_executed=true`、
    `qualified_for_c8=false`、`content_oracle=true`、`content_oracle_kind=exact-text`、
    `expected_content_len > 0`、长度相等、FNV hash 相等。
- `mk/report.mk`
  - W4 parent-scoped report 展示行的 `Valid-Shape PASS` predicate 与 hard gate 对齐：
    同样要求 policy executed、非 C8、exact-text oracle、非零长度、长度/hash 相等。

## 验证计划

不需要重跑 KVM 生成新 raw result，因为 `20260615T-w4-valid-sibling-structured-oracle`
artifact 已经包含这些字段。本步骤验证应使用同一个 artifact 运行等价 jq predicate，并
重新构建 paper/report 相关检查。

## 剩余风险

这一步只对齐 gate predicate，不改变 eBPF policy、oracle 文件内容比较逻辑或 W4 scope。
W4 仍然是 sampled parent-rule PoC，不能计入 C8。
