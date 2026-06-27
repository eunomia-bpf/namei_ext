# OSDI weak-accept 差距自审记录

最近更新：2026-06-15
更新阶段：第一阶段研究审计
来源/命令：主 agent 读取 `auto-research-orchestrator` 和
`osdi-experiment-design` skill 后，对 `docs/research_plan.md`、
`docs/experiment-plans/osdi-evaluation.md`、`docs/paper/`、`workload/` 和
`results/phase1/20260615T-parent-key-poc/` 的当前状态做恢复审计。
完整性：部分完成；独立 subagent review 因额度限制没有返回。

## 为什么不能停

当前目标要求四类真实 workload/policy family 完整实现 policy、获取真实 workload，
并维护中文论文草稿，直到独立 subagent 按 OSDI 顶会标准给出 weak accept。当前树已经有
大量 Phase 1 KVM evidence，但所有主线 workload 仍显式记录为 `functional_only` 或
`qualified_for_c8=false`。因此当前状态只能说明 Phase 1 PoC 和若干真实 workload
witness 能跑通，不能说明目标已经完成。

本轮恢复时，subagent `Kuhn` 返回错误：

```text
You've hit your usage limit. Visit https://chatgpt.com/codex/settings/usage to purchase more credits or try again at 9:52 PM.
```

这意味着独立 review 没有完成，不能把 subagent weak accept 作为已满足条件。主 agent
只能继续做 skill-based 自审和实现推进，并在 subagent 可用后重新请求独立验收。

## 本轮检查过的文件和证据

- `docs/research_plan.md`：记录 Phase 1 当前状态、W1/W2/W3/W4 witness 和剩余
  release blocker。
- `docs/experiment-plans/osdi-evaluation.md`：记录 claim ledger、workload matrix、
  source-to-signal ledger、C1/C8 降级规则和 B12 policy programmability gate。
- `docs/paper/sections/01-introduction.tex`：检查引言是否把 Phase 1 限制讲清楚。
- `docs/paper/sections/04-implementation.tex`：检查当前实现证据是否和 raw result 对齐。
- `docs/paper/sections/05-evaluation.tex`：检查 evaluation 是否防止把
  `functional_only` 证据写成主结果。
- `workload/*/evidence.md`：检查每个 workload 的真实来源、状态和 release blocker。
- `results/phase1/20260615T-parent-key-poc/summary.md`：作为当前 canonical Phase 1
  run 的 summary evidence。

## 自审结论

按 OSDI evaluation rubric，当前最强结论是：

1. `namei_ext` 的 Phase 1 infrastructure、KVM boot path、policy build/load/attach、
   path oracle、若干真实 workload witness 和报告 hard gate 已经形成可审计 artifact。
2. W1 已有 Redis/nginx 真实 source trace、KVM preprocessing replay、KVM release
   binary replay 和 branch probes，但仍缺完整 trace-derived alias set、release-level
   natural poison/negative hit、operation-weighted hit rate 和 table/update budget
   counterfactual。
3. W2 已有真实 nginx config/endpoint health oracle 和 fixture content probes，但仍缺
   PostgreSQL real app oracle、trace-level no-real-open checker、endpoint matrix 和
   table/update budget counterfactual。
4. W3 已有 checkpoint witness KVM path oracle 和 Redis RDB load replay witness；它证明
   真实 Redis 文件加载路径能观察到 checkpoint policy redirect，但仍尚无真实 Podman/CRIU
   checkpoint archive、restore health、post-restore VFS trace、state/config/cache hash 或
   0 mixed epoch oracle。
5. W4 已有真实 ccache cold/hot transition、真实 cache-path trace、trace-derived policy
   bridge 和真实 ccache policy-attached compile witness；这补强了真实来源，并证明
   sampled hot compile 能在 attach window 内通过 `namei_ext` policy 消费 trace-derived
   cache objects。但它仍缺 release-level operation-weighted policy cache hit rate、真实
   stale/corrupt transition、BuildKit cache-path trace 和 table/update budget counterfactual。

因此当前 evaluation maturity 介于 rubric level 2 和 level 3 之间：claim ledger、
workload、baseline、oracle 和 raw artifact 路径已经成形，但尚无任何
`qualified_for_c8=true` workload row，也没有 release-level repetitions、性能分布、
table-only failure 或独立 subagent weak accept。

## 本轮发现并修正的 must-fix

`docs/experiment-plans/osdi-evaluation.md` 的 C1/C8 claim ledger 曾经遗漏 W4
trace-derived ccache policy bridge，并在 C8 状态里仍写着 W4 缺
`ccache trace-to-policy bridge`。这和当前 `make kvm-w4-ccache-policy-bridge
RUN_ID=20260615T-parent-key-poc` 已通过的证据冲突。

本轮初始修订曾把 C1/C8 台账同步为：

- W4 trace-derived ccache policy bridge 已完成；
- 当时仍把真实 ccache compile attach window、BuildKit cache-path trace、
  operation-weighted policy cache hit rate、真实 stale/corrupt transition 和
  table/update budget counterfactual 列为 W4 缺口。

后续 `make kvm-w4-ccache-policy-compile RUN_ID=20260615T-parent-key-poc` 已把真实
ccache hot compile 放进 `cache_locality_view.bpf.c` attach window，并通过完整
`make phase1` 和 `make report` hard gates。因此当前 W4 blocker 应更新为：缺
release-level operation-weighted policy cache hit rate、真实 stale/corrupt transition、
BuildKit cache-path trace、stale/update window 和 table/update budget counterfactual；
不再是“真实 ccache 编译阶段完全没有进入 policy attach window”。

## 下一步最高价值工作

如果继续朝 weak accept 推进，最高价值顺序是：

1. 先做 W3 真实 Podman/CRIU restore witness，因为 W3 当前证据最弱，且会显著提高
   policy family diversity。
2. 同步补 W2 PostgreSQL real app oracle 或 nginx trace-level no-real-open checker，
   让 sandbox fixture 从单个 nginx endpoint witness 变成更可信的真实服务 family。
3. 对 W4 把当前 sampled policy-attached ccache compile 扩展成 release-level workload，
   记录 operation-weighted policy cache hit rate、真实 stale/corrupt transition 和
   update/stale window，再考虑 BuildKit/Prometheus Go cache path。
4. 最后做 B12 table/update budget counterfactual 和 release-level repetition；只有
   table-only 在同等 budget 下失败或明显付出不可接受成本时，C8 才能升级。

## 剩余风险

- subagent independent review 未完成，目标中的 weak accept 条件未满足。
- 当前结果根目录来自 dirty tree；可以作为 Phase 1 证据，但不能作为投稿级 artifact。
- 多数性能数字仍缺发布级重复、分布和置信区间。
- table-only baseline 在当前 path/probe oracle 下仍通过，不能支撑“必须 eBPF”的 C8。
