# W4 release counterfactual accounting 实现记录

更新日期：2026-06-15
阶段：执行 / 主张门禁
来源/命令：`make kvm-w4-ccache-release-counterfactual RUN_ID=20260615T-w4-release-counterfactual`
完整性：计数门禁完成，C8 仍未完成

## 动机

W4 的 cache-locality family 已经有真实 Redis/nginx `ccache gcc -c` hot compile 在
`cache_locality_view.bpf.c` attach window 内通过，并且 parent-scoped lookup PoC 已经
把 object-level exact lookup 降到每个 cache leaf parent 一条 wildcard lookup rule。
但是同一组 sampled cache objects 也能被 `table_redirect.bpf.c` exact redirect table
通过。因此，当前 W4 不能把 sampled parent-rule PoC 写成 C8 支持证据。

本步骤的目标是把这组事实变成一个 Make/KVM 可复现的 raw accounting gate：同一个
`RUN_ID` 下先生成真实 ccache trace、trace-derived policy bridge、parent-scoped policy
compile witness 和 table-only compile comparator，再在 KVM guest 中汇总 release
counterfactual row。该 row 必须保留负面结论：table-only 仍通过，release-level
operation-weighted policy cache hit rate 仍未建立，所以 `qualified_for_c8=false`。

## 代码路径

- `mk/kvm.mk`
  - 新增 `W4_CCACHE_RELEASE_COUNTERFACTUAL_JSON` 和
    `W4_CCACHE_RELEASE_COUNTERFACTUAL_INPUTS`。
  - 新增 `kvm-w4-ccache-release-counterfactual`，依赖
    `kvm-w4-ccache-parent-compile` 和 `kvm-w4-ccache-table-compile`，然后在修改后的
    kernel KVM guest 内执行 `__phase1_guest_w4_ccache_release_counterfactual`。
  - guest target 校验 trace、bridge、parent/table compile JSONL、parent/table input
    hashes、parent/table output hashes 均存在，写入 11 个输入文件的 SHA256。
  - guest target 从 raw JSONL/TSV 中读取 cache-path file ops、trace objects、
    parent redirect count、table redirect count、parent rule writes、readdir rule
    writes、table-equivalent rule writes 和 output oracle 状态，并 fail-fast 检查。
- `Makefile`
  - 将 `kvm-w4-ccache-release-counterfactual` 加入默认 `phase1` 顺序。
  - 增加 help 文本。
- `mk/report.mk`
  - 增加 `w4-ccache-release-counterfactual.jsonl` 和
    `w4-ccache-release-counterfactual-inputs.sha256` 的存在性、输入集合和 raw row
    hard gate。
  - 报告中新增 W4 release counterfactual accounting 表；只展示 raw accounting，不把它
    解释成 C8 成功。

## 设计选择

1. 该 gate 只做 accounting，不重新实现 policy 逻辑。真实 policy 行为仍由
   `kvm-w4-ccache-parent-compile` 和 `kvm-w4-ccache-table-compile` 产生。
2. 输入完整性使用 SHA256 文件保存 11 个输入：trace JSONL、trace object list、bridge
   TSV、parent/table compile JSONL、parent/table input hash、parent/table output hash、
   `configs/eval-osdi/policy-budgets.mk` 和 `mk/kvm.mk`。
3. 结果行同时记录 object-level hit rate 和 sampled object/op ratio：
   `eligible_object_policy_hit_rate=1` 只表示 4 个抽取出的 cache objects 都被 parent
   policy 覆盖；`cache_path_policy_coverage=0.1` 的严格含义是 4 个 sampled cache
   objects / 40 个 cache-path file ops，不是 release-level operation coverage，也不是
   release-level hit rate。report 表头使用 `Sampled Object/Ops Ratio` 降低误读风险。
4. `operation_weighted_policy_cache_hit_rate=false` 和
   `operation_weighted_policy_hit_rate_is_release=false` 是显式负证据字段，避免后续报告把
   sampled object oracle 当成发布级性能/正确性结论。
5. report hard gate 必须防止未来错报：release counterfactual row 和 summary row 各
   exactly 1，任何带 `qualified_for_c8` 的 row 都必须为 `false`，且不能出现
   operation-weighted hit rate 为 true 的 row。`table_budget_failure=false` 还必须由
   `table_over_parent_rule_ratio <= max_over_materialization_ratio` 复算得到。

## 拒绝的替代方案

- 不接受把 `jq` 汇总作为 host-only report 步骤。Phase 1 validation 必须在修改后的
  kernel KVM guest 内运行；本 target 的 accounting row 也在 guest 内生成。
- 不接受只在 Markdown 中说明 table-only 也通过。OSDI 风格的 claim gate 需要 raw
  artifact 和 hard gate，因此必须有 JSONL row、input hash 和 report predicate。
- 不接受把当前结果升级为 C8。当前 workload 只有 sampled Redis/nginx ccache hot compile，
  table-only exact redirect 仍能通过同一 output oracle。

## 验证

命令：

```text
make kvm-w4-ccache-release-counterfactual RUN_ID=20260615T-w4-release-counterfactual
```

结果：

- KVM target 退出码为 0。
- `results/phase1/20260615T-w4-release-counterfactual/w4-ccache-release-counterfactual.jsonl`
  中有 1 条 `w4-ccache-release-counterfactual` row 和 1 条 summary row。
- `sha256sum -c results/phase1/20260615T-w4-release-counterfactual/w4-ccache-release-counterfactual-inputs.sha256`
  11 个输入全部通过。
- report 等价 jq hard gate 通过，匹配 row 数为 1。

关键 raw 字段：

```text
trace_cache_path_file_ops=40
trace_cache_objects=4
parent_rule_writes=4
exact_readdir_rule_writes=4
table_rule_writes=8
eligible_object_policy_hit_rate=1
cache_path_policy_coverage=0.1
table_baseline_current_oracle_pass=true
operation_weighted_policy_cache_hit_rate=false
qualified_for_c8=false
```

## 剩余风险和后续工作

- 这仍是 sampled Redis/nginx ccache witness，不是完整 release build 或 BuildKit/Go cache
  workload。
- `eligible_object_policy_hit_rate=1` 不能被写成 release-level operation-weighted hit
  rate；当前 `cache_path_policy_coverage=0.1` 反而说明 release stream 覆盖不足。
- table-only comparator 在当前 sampled oracle 上通过，因此 W4 仍只能支撑
  `functional_only`，不能计入 C1/C8。
- W4 下一步必须补真实 stale/corrupt transition、release-level operation-weighted hit
  rate、update/stale window、BuildKit 或 Go module cache workload，以及能让
  table-only 在同等预算下失败或暴露不可接受成本的 counterfactual。
