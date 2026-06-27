# OSDI performance gate review revision

Last updated: 2026-06-15
Stage at update: Phase 1 implementation revision / subagent review
Source/command: Hooke subagent review of B2/B8 performance contract
Completeness: complete for P2 review fixes

## Review 结论

Hooke 对 B2/B8 performance contract 给出 scoped Weak Accept：

- 无 P0。
- 无 P1。
- 当前增量没有把 Phase 1 `bench.jsonl` 包装成 OSDI 性能结论。
- `eval-osdi-performance` hard gate 在当前证据下 fail-fast。
- paper/docs 明确当前 performance evidence 只是 smoke-scale aggregate timing。

Hooke 给出两个 P2 建议：

1. `eval-osdi-paper-report` 未来通过 hard gate 后应列出 B2 performance ledger、
   input sha 和 gate 字段。
2. `has_confidence_interval` 不应由 sample 数推导；sample 数只能说明 repetition
   budget，真正 CI 应由实际 CI artifact 决定。

## 修复内容

### Report artifact coverage

`eval-osdi-paper-report` 现在写出：

- B12 policy-family ledger 路径；
- B12 policy-family input sha256；
- B2/B8 performance ledger 路径；
- B2/B8 performance input sha256；
- performance release gate pass。

该 target 仍依赖 `eval-osdi-paper`，因此只有 policy-family 和 performance hard gate
都通过后才会写 release report。

### CI 字段语义

`eval-osdi-performance-ledger` 现在把 sample 数门槛拆成：

- `has_repetition_budget`：`samples >= EVAL_OSDI_REQUIRED_PERF_SAMPLES`；
- `has_ci_artifact`：当前固定为 false，只有未来实际 CI artifact 存在时才能变 true；
- `has_confidence_interval`：当前固定为 false，不再由 sample 数推导。

当前 full root 仍是 `samples=1`，所以这些字段不会改变 hard gate 结论。

## 不改变的语义

- `eval-osdi-performance` 仍要求 release gate、C2、C3 和 C5 全部为 true。
- 当前 `performance.jsonl` 仍应记录 `release_gate_pass=false`。
- 当前 hard gate 仍应失败。

## 后续验证

需要重新运行：

```text
make eval-osdi-performance-ledger \
  RUN_ID=20260615T-eval-contract \
  EVAL_OSDI_PHASE1_RUN_ID=20260615T-full-phase1-gatefix
make eval-osdi-policy-family-ledger \
  RUN_ID=20260615T-eval-contract \
  EVAL_OSDI_PHASE1_RUN_ID=20260615T-full-phase1-gatefix
sha256sum -c results/eval-osdi/paper/20260615T-eval-contract/b2-performance/performance-inputs.sha256
sha256sum -c results/eval-osdi/paper/20260615T-eval-contract/b12-policy-family/policy-family-inputs.sha256
```

Hard gates 仍应在 expected-failure wrapper 下失败。
