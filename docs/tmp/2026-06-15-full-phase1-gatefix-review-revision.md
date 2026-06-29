# 完整 Phase 1 gatefix 复审记录

> 2026-06-29 baseline scope update: this historical record preserves prior reasoning and results. Current C8/B12 guidance is claim-driven baseline selection; exact-map diagnostics are optional boundary evidence only when precomputed mapping is the competing claim.

更新日期：2026-06-15
阶段：复审 / OSDI evidence gate
来源/命令：Hooke subagent 复审
完整性：scoped weak accept，overall weak reject

## 背景

此前 Hooke 总体 review 给出 weak reject，其中 P1.3 指出最新 W4
attach-window/release-counterfactual gatefix 只是 scoped root，不是完整 Phase 1
report root；P2 指出 `workload/w4-ccache-redis-nginx/evidence.md` 仍把
policy-attached ccache compile 写成 pending。

本轮修复运行了：

```text
make phase1 RUN_ID=20260615T-full-phase1-gatefix
```

并把 `docs/research_plan.md`、`docs/experiment-plans/osdi-evaluation.md`、W4 workload
evidence 和 paper sections 同步到新的 canonical full root。

## 复审结论

Hooke verdict：

- 本轮修复本身：scoped weak accept；
- 整体项目状态：weak reject；
- P1.3：关闭；
- P2：关闭；
- 剩余最高风险仍是 P1.1 和 P1.2。

## 已关闭的问题

P1.3 已关闭，因为
`results/phase1/20260615T-full-phase1-gatefix/summary.md` 存在，并在同一个 full root
中包含 W4 parent-scoped compile、table-only comparator 和 release counterfactual
accounting。`w4-ccache-release-counterfactual-inputs.sha256` 的 11 个输入可校验；
parent/table output sha 均为 6 行；jq gate 可复算 attached sampled hit rate
`16/40 = 0.4`；row 仍显式记录 `qualified_for_c8=false`。

P2 已关闭，因为 W4 workload evidence 已明确记录 policy-attached compile witness、
parent-scoped compile witness、table-only comparator 和 release counterfactual
accounting 已完成；剩余 blocker 被改写为 release-level operation-weighted hit rate、
BuildKit、stale/corrupt、update/window 和 table budget，而不是 pending
policy-attached ccache compile。

## 剩余 P1

P1.1：C1/C8 仍没有 qualifying evidence。四个 family 仍没有
`qualified_for_c8=true` row。下一步必须实现 release-level policy-family
counterfactual：每个 qualifying family 至少两个真实 workload/trace row，包含
usecase oracle、operation-weighted metric、table-only comparator、budget/stale/update
gate。

P1.2：仍没有 OSDI-level performance/baseline evaluation。当前 full-root 仍是
smoke-scale，`Samples: 1`，并记录 dirty tree。下一步必须实现并运行 release-level
baseline/performance suite：native、copy-tree、symlink-forest、bind/OverlayFS、FUSE
和 table-only，并保存 repetition、tail latency、CI、raw provenance。

## 下一步

继续推进 Makefile-owned release-level eval entrypoints。最小下一步不是修改论文措辞，
而是增加 `make eval-osdi-policy-family` / `make eval-osdi-paper` / report targets 的
可执行 infrastructure 和 raw result schema，然后用真实 workloads 逐步把 C1/C8 和
性能基线从 planned 推到可审计 evidence。
