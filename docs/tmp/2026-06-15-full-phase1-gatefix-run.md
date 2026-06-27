# 完整 Phase 1 gatefix run 记录

更新日期：2026-06-15
阶段：验证 / 完整 Phase 1 report root
来源/命令：Hooke 总体 OSDI review 的 P1
完整性：已通过

## 动机

`RUN_ID=20260615T-w4-attach-window-optrace-gatefix` 已经证明 W4 release
counterfactual gatefix 的 scoped evidence chain 可审计，但它不是完整 Phase 1 result
root，缺少 guest-smoke、ABI、policy load、policy semantic、functional、bench、Docker
和完整 `summary.md`。旧完整 run `20260615T-parent-key-poc` 又不包含新的 W4
parent/table/release-counterfactual gate。

因此需要运行完整 Phase 1 Make pipeline，让 `report` 在同一个 result root 中执行
新的 W4 hard gates。

## 计划命令

```text
make phase1 RUN_ID=20260615T-full-phase1-gatefix
```

## 成功标准

- `make phase1` 退出码为 0；
- `results/phase1/20260615T-full-phase1-gatefix/summary.md` 存在；
- `summary.md` 包含 W4 release counterfactual accounting section；
- `w4-ccache-release-counterfactual-inputs.sha256` 可通过 `sha256sum -c`；
- W4 release row 仍为 `qualified_for_c8=false`，且 attached sampled rate 可由
  raw count 复算。

## 实际结果

`make phase1 RUN_ID=20260615T-full-phase1-gatefix` 已在 2026-06-15 通过，退出码为
0。完整 result root 为：

```text
results/phase1/20260615T-full-phase1-gatefix/
```

硬检查结果如下：

- `summary.md` 存在，并包含 `W4 Release Counterfactual Accounting` section；
- `sha256sum -c w4-ccache-release-counterfactual-inputs.sha256` 对 11 个输入全部
  返回 OK；
- `w4-ccache-parent-compile-outputs.sha256` 和
  `w4-ccache-table-compile-outputs.sha256` 均为 6 行，包含 Redis/nginx output objects
  与 policy compile strace logs；
- `w4-ccache-release-counterfactual.jsonl` 的 row 记录
  `trace_cache_path_file_ops=40`、`trace_cache_objects=4`、
  `parent_rule_writes=4`、`exact_readdir_rule_writes=4`、
  `table_rule_writes=8`、`attached_cache_path_file_ops=40`、
  `attached_policy_cache_object_ops=16` 和
  `attached_sampled_operation_hit_rate=0.40000000000000002`；
- `attached_sampled_operation_hit_rate` 可由
  `attached_policy_cache_object_ops / attached_cache_path_file_ops` 复算；
- row 仍明确记录 `table_baseline_current_oracle_pass=true`、
  `operation_weighted_policy_cache_hit_rate=false`、
  `operation_weighted_policy_hit_rate_is_release=false` 和
  `qualified_for_c8=false`。

该 run 解决 Hooke review 的 P1.3：W4 parent/table/release-counterfactual gates 已经
进入同一个完整 Phase 1 root 和同一份 `summary.md`。它没有解决 P1.1/P1.2：当前
结果仍不是 C1/C8 支持证据，也不是 OSDI 发布级性能评估。

## 后续动作

已把 `docs/research_plan.md`、`docs/experiment-plans/osdi-evaluation.md`、W4
workload evidence 和 paper 中的 canonical Phase 1 root 更新到该完整 root，同时保留
旧 root 作为历史或局部 witness，不把 scoped W4 root 冒充完整 Phase 1 root。
