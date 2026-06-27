# C3 full-suite residual diagnostic ledger

日期：2026-06-17

## 背景

当前 claim verdict v10 已经把主稿收窄到 W2 C2 slice、tool-redirect C3 slice 和声明
W1--W4 Phase 1 lookup/readdir matrix。full-suite C3 仍不能进入主结论，因为 release
performance comparison 中 native p99 threshold 和 pass-only residual threshold 仍失败。

用户特别要求继续补充 FUSE baseline 和测试。现有
`20260617T-eval-comparison-ctx-init-split-tail10-hardgate-v4` 已经包含 batch=64 KVM
internal rows、external FUSE redirect baseline tail rows 和 comparison verdict。该 run 的
summary 显示 `fuse_speedup_threshold_pass=true`，因此下一步不是降低 C3 gate，而是把 FUSE
baseline 已通过和剩余 native/residual blocker 写成独立、可复查的 Make-owned diagnostic ledger。

## 实现

新增 Make target：

```text
make eval-osdi-c3-residual-diagnostic-ledger
```

新增变量：

- `EVAL_OSDI_C3_RESIDUAL_SOURCE_RUN_ID`
- `EVAL_OSDI_C3_RESIDUAL_SOURCE_JSON`
- `EVAL_OSDI_C3_RESIDUAL_SOURCE_TAIL_JSON`
- `EVAL_OSDI_C3_RESIDUAL_SOURCE_BASELINE_TAIL_JSON`
- `EVAL_OSDI_C3_RESIDUAL_JSON`
- `EVAL_OSDI_C3_RESIDUAL_INPUTS_SHA256`
- `EVAL_OSDI_C3_RESIDUAL_SUMMARY`
- `EVAL_OSDI_C3_RESIDUAL_MANIFEST`

target 只消费已有 JSONL，不运行 ad hoc shell script，也不改变 raw collector。入口 hard gate 要求：

- source comparison summary 存在，schema 为 `namei_ext.eval_osdi.performance_comparison.v1`；
- `input_gate_pass=true`；
- `fuse_speedup_threshold_pass=true`；
- `c3_supported=false`，即该 ledger 明确是 negative full-suite C3 diagnostic；
- internal tail artifact 有 `has_tail_latency_artifact=true`、release sample budget 和 latency batch budget；
- external baseline tail artifact 有 `has_external_baseline_tail_artifact=true`；
- 所有输入通过 `sha256sum -c`。

生成的每个 bench row 保留 comparison ratio 和 tail percentile：

- native/pass-only/policy p50/p95/p99；
- FUSE p50/p95/p99；
- policy/native p99 ratio；
- policy/FUSE p99 speedup；
- pass-only/native p99 ratio；
- policy p99/p95 ratio；
- diagnostic class。

diagnostic class 只解释 blocker，不把失败转成通过：

- `near_native_p99_threshold`：native p99 ratio 只略高于阈值；
- `policy_p99_tail_outlier`：policy p99/p95 比例显示 tail outlier；
- `common_hook_residual_dominates`：pass-only residual 失败且 policy/pass-only ratio 不高；
- `policy_specific_native_p99_gap`：剩余 policy-specific native p99 gap；
- `passes_full_suite_c3`：该 bench 自身通过 C3，但 summary 仍保持 full-suite C3 false。

summary 固定写 `release_gate_pass=false`，避免 diagnostic ledger 被误用为 release gate。

## 验证

运行：

```text
make eval-osdi-c3-residual-diagnostic-ledger \
  RUN_ID=20260617T-eval-c3-full-suite-residual-diagnostic-v1 \
  EVAL_OSDI_C3_RESIDUAL_SOURCE_RUN_ID=20260617T-eval-comparison-ctx-init-split-tail10-hardgate-v4
```

target 通过，生成：

- `results/eval-osdi/paper/20260617T-eval-c3-full-suite-residual-diagnostic-v1/b2-performance/c3-full-suite-residual-diagnostic.jsonl`
- `results/eval-osdi/paper/20260617T-eval-c3-full-suite-residual-diagnostic-v1/b2-performance/c3-full-suite-residual-diagnostic-inputs.sha256`
- `results/eval-osdi/paper/20260617T-eval-c3-full-suite-residual-diagnostic-v1/b2-performance/c3-full-suite-residual-diagnostic-manifest.json`
- `results/eval-osdi/paper/20260617T-eval-c3-full-suite-residual-diagnostic-v1/b2-performance/c3-full-suite-residual-diagnostic-summary.md`

summary 记录：

- `source_input_gate_pass=true`
- `fuse_baseline_threshold_pass=true`
- `full_suite_c3_supported=false`
- `full_suite_c5_supported=false`
- `release_gate_pass=false`
- failed native p99 benches:
  `lookup_native_hot`, `readdir_alias_view`, `build_tree_stat_walk`
- failed pass-only benches:
  `lookup_native_hot`, `lookup_tool_redirect`, `access_tool_redirect`,
  `open_tool_redirect`, `readdir_alias_view`, `build_tree_stat_walk`
- diagnostic classes:
  `common_hook_residual_dominates`, `near_native_p99_threshold`,
  `passes_full_suite_c3`, `policy_p99_tail_outlier`

Key rows:

- `lookup_native_hot`: near-threshold, policy/native p99 = 1.526x, policy/FUSE speedup = 51.07x.
- `readdir_alias_view`: p99 tail outlier, policy/native p99 = 4.374x, policy p99/p95 = 3.116x.
- `build_tree_stat_walk`: common hook residual dominates, policy/native p99 = 1.750x, pass-only/native p99 = 2.624x.
- all seven shared benches have `fuse_speedup_threshold_pass=true`; min policy/FUSE p99 speedup is 2.258x.

## 结论和后续

该 ledger 补齐了 FUSE baseline/test 的 result-level 可审查性：FUSE 2x baseline 已不再是
full-suite C3 blocker。剩余 blocker 是 native p99 和 pass-only residual，分布在
lookup near-threshold、readdir p99 tail outlier 和 build-tree common-hook residual 三类。

后续如果要把 C3 从 tool-redirect scoped claim 扩展到 full-suite claim，需要针对这些三类 blocker
做内核优化或 workload-specific 解释，并重新运行 release performance comparison 和 claim verdict。
