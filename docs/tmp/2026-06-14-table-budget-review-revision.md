# Table-budget 复审修订记录

> 2026-06-29 baseline scope update: this historical record preserves prior reasoning and results. Current C8/B12 guidance is claim-driven baseline selection; exact-map diagnostics are optional boundary evidence only when precomputed mapping is the competing claim.

日期：2026-06-14
阶段：Phase 1 实现
类型：复审修订记录

## 动机

独立 subagent 使用 OSDI evaluation rubric 复审 `table-budget` 集成后确认：当前实现没有把
`table-budget` 错误计入 C8，但仍存在 result-integrity 风险，包括 stale artifact、防错
schema 不足，以及 `update_writes_observed` 容易被误读为真实 update workload measurement。

## 修订内容

- `Makefile`：将 `phase1` 标为非并行目标，避免 `make -j phase1` 下 `table-budget` 或
  `report` 抢跑；`make help` 文案改为 non-C8 raw accounting。
- `mk/table_budget.mk`：新增 `table-budget-inputs.sha256`，覆盖 W1/W2/W3/W4 oracle JSONL、
  W1/W2/W3/W4 TSV、`configs/eval-osdi/policy-budgets.mk` 和 `mk/table_budget.mk`。
- `mk/table_budget.mk`：将 `update_writes_observed` 改为 `update_writes_accounted`，并新增
  `update_writes_basis=entry_count_from_phase1_table_load`，明确这是 static table-load
  accounting，不是真实 update workload measurement。
- `mk/table_budget.mk`：row `pass` 绑定到对应 `table_redirect.bpf.c` path oracle summary；
  raw JSONL 先写出，随后若任一 table baseline 未通过则 target 失败。
- `mk/report.mk`：`report` 显式依赖 `table-budget`，并校验 `table-budget-inputs.sha256`。
- `mk/report.mk`：新增 exact family set、programmable policy、table policy、oracle JSONL、
  committed budget、`update_writes_accounted` 和 `update_writes_basis` 断言。
- 文档：同步 `docs/research_plan.md`、`docs/experiment-plans/osdi-evaluation.md`、
  `docs/paper/evaluation.md`、`docs/paper/sections/04-implementation.tex` 和
  `docs/paper/sections/05-evaluation.tex`，避免 C8 overclaim。

## 仍然不计入 C8

本次修订只提高 accounting artifact 的可审计性。它仍然不证明 table-only baseline 在
release-level workload oracle、update workload、stale window、latency 或 table/update budget
下失败，因此 `qualified_for_c8=false` 仍是 hard gate。

