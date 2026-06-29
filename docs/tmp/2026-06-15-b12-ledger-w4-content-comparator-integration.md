# B12 ledger 接入 W4 cache-content table comparator 实现记录

> 2026-06-29 baseline scope update: this historical record preserves prior reasoning and results. Current C8/B12 guidance is claim-driven baseline selection; exact-map diagnostics are optional boundary evidence only when precomputed mapping is the competing claim.

Last updated: 2026-06-15
Stage at update: execute/gate loop
Source/command: continue B12/C8 counterfactual audit after W4 table-content KVM run
Completeness: complete

## 动机

`w4-cache-table-content.jsonl` 已经证明同一 W4 cache-content oracle 在
`table_redirect.bpf.c` 下也能通过。这个结果必须进入 B12 policy-family ledger，否则
`eval-osdi-policy-family-ledger` 只看 W4 ccache release counterfactual，会漏掉一条
直接反驳 C8 的 same-workload table-only 负证据。

## 设计选择

- 不把该 comparator 计入 C8 支持。
- 不改变 `qualified_for_c1_c8` 的计算方式。
- 把 `w4-cache-table-content.jsonl` 加入 B12 输入存在性检查和 sha256 provenance。
- 在 `cache_locality` family row 中增加
  `content_table_counterfactual_negative`，只在 summary row 明确满足以下条件时为
  true：
  - `event == "w4-cache-table-content-summary"`；
  - `pass == true`；
  - `failures == 0`；
  - `table_baseline_current_oracle_pass == true`；
  - `content_equivalent_table_oracle == true`；
  - `qualified_for_c8 == false`。

## 实现细节

修改 `mk/eval_osdi.mk`：

- `eval-osdi-policy-family-ledger` 现在要求
  `$(EVAL_OSDI_PHASE1_DIR)/w4-cache-table-content.jsonl` 存在。
- `policy-family-inputs.sha256` 现在覆盖该 JSONL，避免 ledger 与原始负证据脱节。
- W4 family row 新增 `content_table_counterfactual_negative` 字段。
- W4 blocker 文本明确说明 release comparator 和 cache-content same-workload table
  comparator 都通过，因此是 C8 负证据。

## 判读

这个改动只提高 gate 的可审计性，不提升 claim。当前结论保持不变：

- W4 `cache_locality_view.bpf.c` 的语义 witness 和 ccache witness 能跑通；
- 但 W4 table-only comparator 也能跑通；
- 因此 W4 仍需要 release-level operation-weighted hit rate、真实 stale/corrupt
  transition、BuildKit cache trace、update/stale window 或 table/update budget failure，
  才能支持 programmable path-resolution 的 C8 claim。

## 验证结果

先做 Make parse/provenance dry-run：

```text
make -n eval-osdi-policy-family-ledger \
  RUN_ID=20260615T-eval-w4-content-ledger-parse-v1 \
  EVAL_OSDI_PHASE1_RUN_ID=20260615T-w4-cache-table-content-smoke-v1
```

随后重新跑完整 Phase 1：

```text
make phase1 RUN_ID=20260615T-full-phase1-b12-refresh-v1
```

该 run 退出 0，并生成新的 canonical input root：

`results/phase1/20260615T-full-phase1-b12-refresh-v1/`

再用新 root 生成 B12 ledger：

```text
make eval-osdi-policy-family-ledger \
  RUN_ID=20260615T-eval-b12-refresh-v1 \
  EVAL_OSDI_PHASE1_RUN_ID=20260615T-full-phase1-b12-refresh-v1
```

结果路径：

`results/eval-osdi/paper/20260615T-eval-b12-refresh-v1/b12-policy-family/policy-family.jsonl`

关键字段：

- summary: `qualified_families=0`
- summary: `release_gate_pass=false`
- summary: `c1_supported=false`
- summary: `c8_supported=false`
- W4 row: `content_table_counterfactual_negative=true`
- W4 row: `table_counterfactual_support=false`
- W4 row: `qualified_for_c1_c8=false`

最后运行 hard gate：

```text
make eval-osdi-policy-family \
  RUN_ID=20260615T-eval-b12-refresh-hardgate-v1 \
  EVAL_OSDI_PHASE1_RUN_ID=20260615T-full-phase1-b12-refresh-v1
```

该 target 按预期退出 2，因为最终 `jq -e` 找不到
`release_gate_pass=true` 且 `qualified_families>=4` 的 summary row。hard gate artifact
保存在：

`results/eval-osdi/paper/20260615T-eval-b12-refresh-hardgate-v1/b12-policy-family/`

`git diff --check` 在文档更新后再次执行。
