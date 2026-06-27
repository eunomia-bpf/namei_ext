# W4 workload ledger 同步记录

更新日期：2026-06-15
阶段：文档 / artifact ledger 同步
来源/命令：Hooke 总体 OSDI review 的 P2
完整性：同步完成

## 动机

`workload/w4-ccache-redis-nginx/evidence.md` 仍把“真实 ccache compile under policy
attach window”列为待完成项。但当前已经有：

- `kvm-w4-ccache-policy-compile`
- `kvm-w4-ccache-parent-compile`
- `kvm-w4-ccache-table-compile`
- `kvm-w4-ccache-release-counterfactual`

如果 workload ledger 不同步，artifact reviewer 会看到 paper/result 已有 gatefix
evidence，但 workload 证据文件仍声称对应步骤未完成。

## 修改

- 将 W4 状态扩展为八层 witness：path/content/real ccache transition/cache-path
  trace/policy bridge/policy-attached compile/parent-scoped compile/table comparator +
  release counterfactual accounting。
- 增加 parent-scoped compile、table-only comparator 和 release counterfactual accounting
  的解释。
- 增加 canonical gatefix raw result 路径：
  `results/phase1/20260615T-w4-attach-window-optrace-gatefix/`。
- 将 remaining blocker 从“真实 ccache compile under policy attach window”改为
  release-level operation-weighted policy cache hit rate。

## 仍然不能声称的内容

这次同步不改变证据等级。当前 W4 仍是 `functional_only` / non-C8：

- table-only comparator 仍通过 sampled output oracle；
- release counterfactual row 仍为 `qualified_for_c8=false`；
- sampled attach-window optrace 不是 release-level operation-weighted hit rate。
