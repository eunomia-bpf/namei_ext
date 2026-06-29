# OSDI policy-family release gate 实现记录

> 2026-06-29 baseline scope update: this note preserves historical reasoning and results, but older C8/B12 baseline-gate wording is superseded by `docs/tmp/2026-06-29-redirect-table-novelty-position.md`. Current evaluation uses claim-driven, workload-appropriate baselines. Exact-map diagnostics are optional and only relevant when precomputed mapping is the competing claim.

Last updated: 2026-06-15
Stage at update: Phase 1 implementation / OSDI evaluation gate
Source/command: `make eval-osdi-policy-family-ledger RUN_ID=20260615T-eval-contract EVAL_OSDI_PHASE1_RUN_ID=20260615T-full-phase1-gatefix`
Completeness: complete for the contract gate; blocked for C1/C8 release evidence

## 动机

此前 `make phase1 RUN_ID=20260615T-full-phase1-gatefix` 已经把 W1--W4 的 KVM
witnesses、W4 parent/table/release counterfactual、functional、bench、Docker 和
dmesg gates 放进同一个 full root。这个 full root 能证明 Phase 1 机制和多个
policy family 的功能路径可以跑通，但不能证明 OSDI 级 C1/C8：当前没有任何
`qualified_for_c8=true` row。

因此需要一个独立的 Makefile-owned release evaluation contract。它的作用不是把
当前功能证据解释成论文主结论，而是把 C1/C8 的必要条件写成可执行 gate：

- 每个 policy family 至少两个真实应用或真实 trace row；
- semantic witness 必须通过；
- release-level operation-weighted metric 必须成立；
- table-only counterfactual 或 table/update budget failure 必须成立；
- 只有同时满足这些条件的 row 才能计入 C1/C8。

## 调研和检查过的文件

- `Makefile`：确认顶层入口、`phase1` 依赖链、help 文本和 Makefile-only 约束。
- `mk/report.mk`：确认 full Phase 1 report 已经 hard-gate W1/W2/W3/W4 raw
  artifacts、input SHA、non-C8 字段和 W4 release counterfactual。
- `mk/table_budget.mk`：确认当前 table-only budget accounting 只记录 path-oracle
  accounting，全部 `qualified_for_c8=false`。
- `configs/eval-osdi/workloads.mk`：确认 W1--W4 的 workload IDs。
- `configs/eval-osdi/policy-budgets.mk`：确认 table/update budget 和 policy budget
  是 Makefile 配置，不是 policy DSL。
- `docs/experiment-plans/osdi-evaluation.md`：确认 B11/B12 已经要求
  `results/eval-osdi/paper/<run-id>/b12-policy-family/`。
- `results/phase1/20260615T-full-phase1-gatefix/`：确认 full root 中存在
  `w1-release-build-replay.jsonl`、`w1-branch-probes.jsonl`、`w2-nginx-real.jsonl`、
  `w3-redis-replay.jsonl`、`w4-ccache-release-counterfactual.jsonl` 和
  `table-budget.jsonl`。
- `results/workloads/runs/20260615T-full-phase1-gatefix/`：确认 workload run
  artifacts 是 manifests、trace、oracle TSV 和 build outputs；`evidence.md`
  属于 repo 下 `workload/<id>/`，不属于 run result 目录。

## 设计选择

新增 `mk/eval_osdi.mk`，只负责 release-evaluation 层的 B12 policy-family contract。
它不改 KVM runner、不改 kernel witness、不生成 policy 配置语言，也不把当前 smoke
证据升级成 release 证据。

新增 Make targets：

- `eval-osdi-smoke`：默认先运行 `phase1`，再从同一 `RUN_ID` 的 Phase 1 root 写
  OSDI evidence ledger。这是 fresh checkout 的一键 smoke 入口。
- `eval-osdi-policy-family-ledger`：读取已有 `EVAL_OSDI_PHASE1_RUN_ID` 指向的
  Phase 1 full root，生成 B12 JSONL ledger、input sha256、manifest 和 Markdown
  summary。这个目标用于审计已有 full root，不声明 release gate 通过。
- `eval-osdi-policy-family`：在 ledger 之后执行 hard gate，要求四个 policy
  family 都 qualified。当前应失败。
- `eval-osdi-paper`：当前 release-evaluation hard gate；默认先跑 `phase1`，再跑
  B12 hard gate。当前应失败。
- `eval-osdi-paper-report`：只有 hard gate 通过后才写发布级 report。

生成路径：

- `results/eval-osdi/paper/<run-id>/manifest.json`
- `results/eval-osdi/paper/<run-id>/b12-policy-family/policy-family.jsonl`
- `results/eval-osdi/paper/<run-id>/b12-policy-family/policy-family-inputs.sha256`
- `results/eval-osdi/paper/<run-id>/b12-policy-family/summary.md`

`policy-family.jsonl` 每个 family 记录：

- `observed_workload_rows`：当前 Phase 1 full root 中已有的真实或近真实 row 数。
- `semantic_witness_pass`：对应 policy family 的功能/语义 witness 是否通过。
- `release_metric_pass`：是否已有 release-level operation-weighted metric。
- `table_counterfactual_support`：是否已有 table-only 反事实支持 C8。
- `qualifying_workload_rows`：只有 semantic、release metric、table counterfactual
  同时成立后才非零。
- `qualified_for_c1_c8`：只有达到每 family 两个 workload rows 且上述 gate 全部
  成立后才为 true。
- `gate_state`：当前为 `blocked` 或未来的 `qualified`。
- `release_blocker`：中文记录该 family 进入 C1/C8 前必须补齐的 raw evidence。

## 拒绝的方案

- 不把 `table-budget.jsonl` 当前 path-oracle accounting 当成 C8 支持证据。它的
  table baseline 通过，反而是 C8 的负证据。
- 不把 `eval-osdi-smoke` 做成论文 hard gate。Smoke 可以生成 ledger，但
  release gate 必须由 `eval-osdi-policy-family` 和 `eval-osdi-paper` 失败/通过。
- 不使用 shell script、Python script、YAML、JSON 或 DSL 作为 control plane。
  所有 orchestration 都在 Makefile 中完成。
- 不在 low-level collector 里计算论文结论。ledger 只机械化当前 raw evidence 到
  release gate 字段，论文结论仍由 report/paper 层引用。

## 验证

复用已有 full root 的 ledger 目标通过：

```text
make eval-osdi-policy-family-ledger \
  RUN_ID=20260615T-eval-contract \
  EVAL_OSDI_PHASE1_RUN_ID=20260615T-full-phase1-gatefix
```

生成的 summary 显示：

```text
Qualified families: 0
Release gate pass: false
build_graph observed=2 qualifying=0 semantic=true release_metric=false table_counterfactual=false
sandbox_fixture observed=1 qualifying=0 semantic=true release_metric=false table_counterfactual=false
checkpoint_restore observed=1 qualifying=0 semantic=true release_metric=false table_counterfactual=false
cache_locality observed=2 qualifying=0 semantic=true release_metric=false table_counterfactual=false
```

输入哈希校验通过：

```text
sha256sum -c results/eval-osdi/paper/20260615T-eval-contract/b12-policy-family/policy-family-inputs.sha256
```

Hard gate 按预期失败：

```text
make eval-osdi-policy-family \
  RUN_ID=20260615T-eval-contract-hardgate \
  EVAL_OSDI_PHASE1_RUN_ID=20260615T-full-phase1-gatefix
```

失败点是 `eval-osdi-policy-family` 最后的 `jq -e`，因为
`release_gate_pass=false` 且 `qualified_families=0`。这是正确结果，防止把当前
Phase 1 功能证据写成 C1/C8 论文主结论。

## 剩余风险和后续工作

- B12 仍未通过：四类 family 都缺 release metric 和 table/update counterfactual。
- C1/C8 仍不能支撑：当前 qualifying family 数为 0。
- `eval-osdi-paper` 现在会先跑 full `phase1`，然后在 B12 hard gate 失败；这符合
  fail-fast，但完整 OSDI paper run 还需要后续加入性能 baseline、tail latency、CI
  和 FUSE/materialized baselines。
- 当前 ledger 是 release contract，不是最终分析 report；后续需要在 raw evidence
  补齐后再让 `eval-osdi-paper-report` 生成论文表格和 figure 输入。
