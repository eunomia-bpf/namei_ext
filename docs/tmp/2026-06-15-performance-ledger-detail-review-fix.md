# Performance ledger 解释文字复审修复

日期：2026-06-15

## 动机

Hooke 按 OSDI evaluation rubric 复审
`20260615T-full-phase1-bench-variants` 和
`20260615T-eval-contract-bench-variants` 后给出 scoped Weak Accept，并指出一个 P2
文字残留：`mk/eval_osdi.mk` 生成的 performance ledger `detail` 仍写着 release
performance 需要 `populated table-hit baseline`，但结构化字段已经显示
`has_table_redirect_hit_baseline=true`，`missing_release_baselines` 也不再包含
`table_redirect_hit`。

该问题不会导致 overclaim，但会让 reviewer 在阅读 raw JSONL 时困惑，因此需要修复。

## 修改内容

修改 `mk/eval_osdi.mk` 中 `eval-osdi-performance-ledger` 生成的 `detail` 字符串：

- 保留 `table_redirect_empty` 是 miss-path overhead baseline、不是 populated table
  redirect evidence 的解释；
- 删除“仍需要 populated table-hit baseline”的残留文字；
- 保留仍缺 release-scale repetitions、tail latency、CI、randomized order、
  system metrics 和外部 filesystem baselines 的结论。

结构化字段不变：

- `has_table_redirect_hit_baseline` 继续从 raw `bench.jsonl` 判断；
- `missing_release_baselines` 继续由实际缺失的 baseline 集合生成；
- `release_gate_pass` 仍为 false。

## 验证计划

需要重新运行：

```text
make eval-osdi-performance-ledger \
  RUN_ID=20260615T-eval-contract-bench-variants \
  EVAL_OSDI_PHASE1_RUN_ID=20260615T-full-phase1-bench-variants
```

然后确认：

- `detail` 不再包含 `populated table-hit baseline`；
- `has_table_redirect_hit_baseline=true`；
- `missing_release_baselines` 只包含外部 filesystem baselines；
- `release_gate_pass=false`；
- `performance-inputs.sha256` 可校验。

## 剩余风险

该修复只解决文字一致性，不改变 OSDI 发布级性能阻塞项。当前仍不能声明 C2/C3/C5。
