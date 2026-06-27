# Research lifecycle artifacts 实现记录

Last updated: 2026-06-15
Stage at update: execute/gate documentation
Source/command: auto-research-orchestrator and osdi-experiment-design artifact contract
Completeness: complete for current-state indexing; incomplete for release evidence

## 动机

当前项目已经有大量 `docs/tmp/`、`docs/experiment-plans/`、`docs/paper/` 和 `results/`
证据，但没有 `research/` 目录。按照 research state machine，缺少
`STATE`、`CLAIM_LEDGER`、`EXPERIMENT_TRACKER`、`RESULTS_SUMMARY` 和 `CLAIM_VERDICT`
会导致后续论文和实验无法机械地区分：

- 哪些 claim 已被当前结果支持；
- 哪些只是 Phase 1 smoke；
- 哪些 release gate 是 expected-fail；
- 下一批实验应该优先补哪一个 reviewer risk。

本次更新把当前状态索引到 `research/`，不改变任何 release gate，也不把 partial evidence
写成 supported claim。

## 检查过的证据

- `results/phase1/20260615T-full-phase1-bench-variants/bench.jsonl`
- `results/eval-osdi/paper/20260615T-eval-contract-bench-variants/b12-policy-family/policy-family.jsonl`
- `results/eval-osdi/paper/20260615T-eval-ledger-after-latency-code-p2fix/b2-performance/performance.jsonl`
- `results/phase1/20260615T-kvm-bench-latency-pilot/bench.jsonl`
- `docs/experiment-plans/osdi-evaluation.md`
- `docs/paper/sections/*.tex`
- `workload/*/evidence.md`
- `configs/eval-osdi/workload-sources.mk`

## 新增 artifacts

- `research/STATE.md`：记录当前 stage 为 execute/gate loop，阻塞 gate 为 B12 和 B2/B8 release gates。
- `research/CLAIM_LEDGER.md`：冻结 C1-C8 claim、scope、所需证据和当前状态。
- `research/EXPERIMENT_PLAN.md`：把 `docs/experiment-plans/osdi-evaluation.md` 的长计划压缩为 reviewer-facing claim-to-experiment map。
- `research/EXPERIMENT_TRACKER.md`：记录当前已完成或 expected-fail 的 run，以及下一批 planned rows。
- `research/RESULTS_SUMMARY.md`：总结当前结果、负结果、缺失 tail/resource observations 和使用的 result files。
- `research/CLAIM_VERDICT.md`：明确当前 C1/C8 blocked、C2/C3/C5 unsupported、C4/C6/C7 partial。
- `research/FOLLOWUP_PLAN.md`：按 reviewer value 排列下一步 release performance、baseline 和 per-family workload gaps。

## 当前关键结论

- `make phase1 RUN_ID=20260615T-full-phase1-bench-variants` 是当前 canonical Phase 1 smoke root。
- B12 ledger 中 `qualified_families=0`，所以不能声称 C1/C8 达到 release evidence。
- B2/B8 ledger 中 `release_gate_pass=false`，所以不能声称性能优势或机制归因。
- latency pilot 只证明 raw `bench_latency` plumbing，不是完整 ledger root。
- `docs/paper/` 仍是中文 LaTeX claim/evaluation contract，不是 submission-ready paper。

## 拒绝的方案

- 不把 `docs/experiment-plans/osdi-evaluation.md` 整体复制进 `research/EXPERIMENT_PLAN.md`。
  新 artifact 是索引和 handoff，不替代详细计划。
- 不把 expected-fail hard gates 写成失败噪声；它们是防止 overclaim 的负证据。
- 不用 tracker 修改 git 状态或 stage 文件。git mutation 仍需用户明确授权。

## 后续

下一步应补 Makefile-owned release performance/baseline target，而不是继续润色论文 prose。
只有 `research/CLAIM_VERDICT.md` 中 C2/C3/C5/C8 至少变成 partial/supported 后，
`docs/paper` 才适合进入 paper-logic 和 paper-review 的正式 revision loop。
