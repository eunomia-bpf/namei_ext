# Table-only budget accounting 实现记录

日期：2026-06-14
阶段：Phase 1 实现
类型：实现记录

## 动机

C8 的核心问题是：静态 `table_redirect.bpf.c` 是否能在同等 table/update budget 下同时满足
不同 policy family 的 oracle 和成本门槛。此前 W1/W2/W3/W4 KVM path oracle 已经运行
`table_redirect.bpf.c`，但 report 只证明 table baseline 当前通过，没有把 budget 字段、
entries、update writes 和 `qualified_for_c8=false` 作为 raw artifact 固定下来。

本次实现添加一个 Makefile-owned accounting target。它不是 C8 证据本身；它把当前 table
baseline 行为记录为 raw JSONL，并明确说明当前 path oracle 不能支撑 C8。

## 修改文件

- `Makefile`
- `mk/table_budget.mk`
- `mk/report.mk`
- `configs/eval-osdi/policy-budgets.mk`
- `docs/research_plan.md`
- `docs/experiment-plans/osdi-evaluation.md`
- `docs/paper/sections/04-implementation.tex`
- `docs/paper/sections/05-evaluation.tex`
- `docs/paper/evaluation.md`

## 设计

新增 target：

```text
make table-budget
```

该 target 读取以下 KVM oracle 结果和 workload TSV：

- `w1-oracle.jsonl` + `w1-build-graph-oracle-entries.tsv`
- `w2-oracle.jsonl` + `w2-sandbox-fixture-oracle-entries.tsv`
- `w3-oracle.jsonl` + `w3-checkpoint-oracle-entries.tsv`
- `w4-oracle.jsonl` + `w4-cache-oracle-entries.tsv`

输出：

```text
results/phase1/<run-id>/table-budget.jsonl
```

每个 family 记录：

- `result_level=table_budget_accounting`
- `budget_basis=phase1_path_oracle_table_baseline`
- `pass`，等于当前 path oracle 中对应 `table_redirect.bpf.c` summary 是否通过；
- `table_baseline_current_oracle_pass`
- `entries`
- `table_entries_required`
- `programmable_entries_observed`
- `over_materialization_ratio`
- `update_writes_accounted`
- `update_writes_basis=entry_count_from_phase1_table_load`
- `max_update_writes`
- committed `max_entries`、`max_memory_bytes`、`max_stale_window_ms`、`max_update_latency_ms`
- `qualified_for_c8=false`

新增 committed budget：

```text
OSDI_TABLE_MAX_UPDATE_WRITES_RATIO ?= 10
```

当前 Phase 1 accounting 把 `max_update_writes` 设为 `entries * ratio`，仅用于固定字段和
后续 release-level gate 的 shape。它不声称 update workload 已经执行。

## Report gate

`make report` 现在依赖 `make table-budget`，要求 `table-budget.jsonl` 和
`table-budget-inputs.sha256` 存在，并检查：

- 4 个 `table-budget` rows；
- 1 个 `table-budget-summary`；
- `table-budget-inputs.sha256` 可用 `sha256sum -c` 校验，覆盖 W1/W2/W3/W4 oracle JSONL、
  W1/W2/W3/W4 TSV、`configs/eval-osdi/policy-budgets.mk` 和 `mk/table_budget.mk`；
- 所有 row `result_level=table_budget_accounting`；
- 所有 row `budget_basis=phase1_path_oracle_table_baseline`；
- 所有 row `qualified_for_c8=false`；
- family set 必须精确等于 `build_graph`、`sandbox_fixture`、`checkpoint_restore` 和
  `cache_locality`；
- 每个 family 的 programmable policy、table policy、oracle JSONL 和 committed budget
  字段必须匹配 Makefile/config；
- 当前 W1/W2/W3/W4 path oracle 中 table baseline 均记录为 pass；
- `over_materialization_ratio=1`；
- `table_entries_required == entries`；
- `update_writes_accounted == entries`；
- `update_writes_basis == entry_count_from_phase1_table_load`。

`make table-budget` 自身也执行 fail-fast 检查：raw JSONL 先写出；若任一 family 的
当前 table path oracle summary 不是 pass，target 随即失败，避免把缺失/失败的 baseline
误记为成功 accounting。

## 验证

已在现有完整 Phase 1 result root 上运行：

```text
make table-budget RUN_ID=20260614T-w2-nginx-probes-phase1
make report RUN_ID=20260614T-w2-nginx-probes-phase1
```

生成的 `table-budget.jsonl` 包含 4 个 family row 和 1 个 summary row：

- `build_graph`：9 entries，当前 table path oracle pass，`qualified_for_c8=false`
- `sandbox_fixture`：6 entries，当前 table path oracle pass，`qualified_for_c8=false`
- `checkpoint_restore`：7 entries，当前 table path oracle pass，`qualified_for_c8=false`
- `cache_locality`：4 entries，当前 table path oracle pass，`qualified_for_c8=false`

`summary.md` 已新增 `Table-Only Budget Accounting` section，并把
`table-budget.jsonl` 和 `table-budget-inputs.sha256` 列入 raw artifacts。

论文 artifact 验证也已运行：

```text
make -C docs/paper paper
make -C docs/paper check
git diff --check
```

`docs/paper/sections/04-implementation.tex` 中新增的 artifact evidence 表被拆成
infrastructure/workload-facing 两张表，避免单个 float 超页；长 gate 描述被改为短
itemize，避免 target 名称在中文段落中触发 overfull line。随后扫描
`.build/paper/main.log`，未发现 overfull、float-too-large、undefined reference、
undefined citation 或 fatal LaTeX error。

## 剩余风险

- 当前 accounting 只覆盖 Phase 1 path oracle；它不会让任何 family 进入 C8。
- W2 nginx real app oracle 和 W4 cache content oracle 还没有对应 table-only content/app
  equivalent counterfactual。
- 真正 C8 仍要求 release-level workload matrix、真实 update/stale-window measurements、
  table entries/map memory/update writes、latency 和 oracle failure/over-budget evidence。
