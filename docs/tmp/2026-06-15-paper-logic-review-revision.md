# paper-logic subagent weak-reject 修订记录

> 2026-06-29 baseline scope update: this historical record preserves prior reasoning and results. Current C8/B12 guidance is claim-driven baseline selection; exact-map diagnostics are optional boundary evidence only when precomputed mapping is the competing claim.

日期：2026-06-15

## 动机

独立 subagent `Aristotle` 使用 `paper-logic` 和 `osdi-experiment-design` 标准对
`docs/paper/` 做只读审查，结论是 `weak reject`。审查认为 W4 parent-scoped ccache
wording 本身基本 scoped：它保留 `qualified_for_c8=false`，明确不是 content-verified
cache decision，也没有把 table-only pass 写成 C8 支持证据。弱拒的主要原因是整篇论文
仍容易被读成“当前评估已经回答发布级问题”，并且 C1/C8、B1/B10 等 ID 未在 LaTeX 中定义。

## 审查指出的 must-fix

1. `docs/paper/sections/05-evaluation.tex` 用“我们评估五个问题”描述性能、C8 和
   artifact reproducibility，容易读成当前结果。
2. `docs/paper/sections/02-motivation.tex` 把 cache workload “不能只依赖静态 table”写成
   观察，但当前 W4 sampled table comparator 已通过。
3. `C1/C8` 和 `B1/B10` 在 LaTeX 中未定义。
4. `docs/paper/sections/04-implementation.tex` 引用的
   `results/phase1/20260615T-parent-key-poc/summary.md` 早于 W4 parent hardgate，不能暗示
   parent hardgate 已由 full report artifact 覆盖。
5. “这些 gate 证明 policy object 可以沿真实 attach path 运行”范围过宽，因为列表中含
   host witness、trace-only gate 和 host-side analysis gate。

## 本轮修订

### 评估 framing

- 将 `docs/paper/sections/05-evaluation.tex` 的开头改为：
  “最终发布级评估将回答五个问题；当前本文只报告 Phase 1 functional evidence，并把性能、
  可编程性和 artifact reproducibility 作为尚未完成的 gates。”
- `docs/paper/evaluation.md` 同步改为发布级评估问题，而不是当前结果。

### Claim/Gate 定义

- 在 `docs/paper/sections/05-evaluation.tex` 新增 `Claim 和 Gate 速查` subsection。
- 定义 C1-C8 的短含义和当前 evidence status。
- 明确定义 B1、B10、B12：
  - B1：路径解析正确性和 lookup/readdir 一致性矩阵；
  - B10：健壮性和失败语义；
  - B12：policy-family programmability 与 table-only counterfactual。
- 从 abstract 和 design 中删除定义前出现的 `C1/C8` 字样，改成“最终表达力或可编程性主张”。

### 执行角色

- 在 `docs/paper/sections/05-evaluation.tex` 新增 `执行角色` 表，区分 Make target、
  workload materializer、guest runner、oracle checker、report checker 和 table comparator。
- 明确只有 attach window 内的 KVM guest result 能证明 policy execution；host-only 和
  trace-only evidence 只提供 provenance 或 candidate evidence。

### W4 parent-scoped hardgate 证据边界

- `docs/paper/sections/04-implementation.tex` 将 `make report` row 改成
  `pre-parent canonical`，并明确 `20260615T-parent-key-poc/summary.md` 早于 W4
  parent-scoped hardgate。
- W4 parent-scoped 段落改为：Makefile/report recipes 已纳入 hard-check，但本文只引用
  独立 hardgate raw artifact，尚未引用 post-parent full report artifact。
- `docs/paper/sections/05-evaluation.tex` 解释 `table_equivalent_rule_updates`：
  它只估算 sampled object set 若用 exact table 表达所需的 lookup entries 加 readdir
  aliases，不是 release-scale table-budget failure。

### 数字和预算 hygiene

- W1 candidate hit rate 改为 `11330/3021315 = 0.00375`，即 `0.375%`，避免读者把
  0.00375 误读成 0.00375%。
- 在 budget 表后加入 rationale：budget constants 来自
  `configs/eval-osdi/policy-budgets.mk`，其中 policy footprint 是 verifier/map-footprint
  gate，path-class/hash-witness 上限来自 bounded-loop/map schema 设计，0.80 hit-rate、
  100 ms stale-window 和 1000 ms update-latency 是发布级 workload SLO 假设。

### 术语收窄

- `docs/paper/sections/02-motivation.tex` 将 W4 描述为 cache locality family，并说明
  content-verified cache locality 是发布级目标，当前 parent-scoped ccache 是 suffix PoC。
- 将“不能依赖静态 table”的强观察改成：只有 release-level table-only counterfactual 失败、
  超预算或违反 stale/update 门槛后，才写成必须使用 eBPF programmable logic。

## 验证

- `make -C docs/paper check` 通过。
- `make -C docs/paper paper` 通过，生成 `.build/paper/main.pdf`。
- 机械 grep 检查未发现 `~number`、em dash、独立分号、figure label 或 `weak accept` 残留。
- 搜索确认：
  - abstract/design 中不再提前使用未定义的 `C1/C8`；
  - W4 parent hardgate 只写成 independent raw hardgate + Make/report recipe integration；
  - `table_equivalent_rule_updates` 被定义为 sampled estimate，不是 C8 failure；
  - `content-verified cache decision` 只出现在“不是 content-verified cache decision”的限制语境中。
- 为降低 PDF overfull，正文中的若干长 raw field 名被改成 prose 描述；完整字段仍可在
  raw JSONL 和本文档前述记录中追溯。

## 剩余风险

## 复审结果

独立 subagent `Aristotle` 对本轮修订做只读复审，结论是：

```text
Verdict: weak accept（只针对当前 paper 文档逻辑状态；不代表实验 goal 完成）。
上一轮 weak reject 的 must-fix 已经清零。未发现新的 must-fix 级 overclaim。
```

复审核对通过的点包括：

- evaluation framing 已改成发布级评估问题 + 当前 Phase 1 functional evidence；
- C1-C8、B1/B10/B12 已在 LaTeX 中定义；
- 执行角色表已补；
- W1 rate、W4 `table_equivalent_rule_updates`、budget rationale 已修；
- W4 parent-scoped wording 仍是 suffix PoC，不是 content-verified cache decision；
- pre-parent full report 和 W4 parent independent hardgate 已拆开；
- “具备 KVM attach 的 gates” 范围收窄正确。

该 weak accept 只覆盖论文文档逻辑，不覆盖实验完整性、OSDI 结果强度或 active goal。

## 剩余风险

本轮修订只解决 paper-logic 的文档 must-fix，并不改变实验状态。当前仍是：

- W1-W4 全部 `functional_only`；
- 无 `qualified_for_c8=true` row；
- W4 parent-scoped evidence 仍只有 4 个 sampled cache objects 和一个明显非 object sibling；
- 尚无 post-parent full `make phase1 && make report` artifact；
- 论文仍是 evaluation contract + Phase 1 evidence ledger，不是 OSDI weak-accept 结果论文。
