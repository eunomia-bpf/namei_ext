# Tool-redirect performance scope ledger 实现记录

日期：2026-06-17

## 背景

`20260615T-eval-comparison-ctx-init-split-tail10-hardgate-v1` 的 full-suite
performance comparison 已经满足 input gate、FUSE speedup gate、CI、随机顺序和
system-metrics provenance，但 full-suite C3 仍失败。失败不是所有 metadata operations
都失败：`lookup_tool_redirect`、`access_tool_redirect`、`open_tool_redirect` 和
`exec_tool_redirect` 都通过 native/FUSE p99 阈值，失败集中在 `lookup_native_hot`、
`readdir_alias_view` 和 `build_tree_stat_walk`。

为了避免把局部正结果隐藏在全局负结论里，同时避免把局部结果扩大成全局 C3，本次新增
Make-owned scoped analysis target。

## 实现

新增 target：

```text
make eval-osdi-performance-tool-redirect-ledger
```

新增变量：

- `EVAL_OSDI_PERFORMANCE_SCOPE_SOURCE_RUN_ID`
- `EVAL_OSDI_PERFORMANCE_SCOPE_SOURCE_JSON`
- `EVAL_OSDI_TOOL_REDIRECT_PERFORMANCE_BENCHES`，但该 target hard gate 要求它保持
  `lookup_tool_redirect access_tool_redirect open_tool_redirect exec_tool_redirect`，
  防止后续覆盖成更窄 scope 后仍复用固定 claim wording。
- `EVAL_OSDI_PERFORMANCE_SCOPE_JSON`
- `EVAL_OSDI_PERFORMANCE_SCOPE_INPUTS_SHA256`
- `EVAL_OSDI_PERFORMANCE_SCOPE_SUMMARY`
- `EVAL_OSDI_PERFORMANCE_SCOPE_MANIFEST`

target 读取已有 `performance-comparison.jsonl`，先 hard gate：

- source JSONL 非空；
- 恰好一个 `eval-osdi-performance-comparison-summary`，schema 为
  `namei_ext.eval_osdi.performance_comparison.v1`，且 `input_gate_pass=true`；
- scoped bench 集合恰好为
  `lookup_tool_redirect access_tool_redirect open_tool_redirect exec_tool_redirect`。
- target 入口也直接断言 `EVAL_OSDI_TOOL_REDIRECT_PERFORMANCE_BENCHES` 等于上述四个
  literal benches，避免命令行变量覆盖改变结论范围。

然后写：

- `performance-tool-redirect-scope.jsonl`
- `performance-tool-redirect-scope-inputs.sha256`
- `performance-tool-redirect-scope-manifest.json`
- `performance-tool-redirect-scope-summary.md`

该 target 不改变 raw collector，也不让 full-suite performance hard gate 通过。它只记录
tool-redirect metadata operations 的 C3 子范围是否成立，并保留
`release_gate_pass=false`。

## 验证结果

运行：

```text
make eval-osdi-performance-tool-redirect-ledger \
  RUN_ID=20260617T-eval-performance-tool-redirect-scope-v1 \
  EVAL_OSDI_PERFORMANCE_SCOPE_SOURCE_RUN_ID=20260615T-eval-comparison-ctx-init-split-tail10-hardgate-v1
```

结果通过，并生成：

- `results/eval-osdi/paper/20260617T-eval-performance-tool-redirect-scope-v1/b2-performance/performance-tool-redirect-scope.jsonl`
- `results/eval-osdi/paper/20260617T-eval-performance-tool-redirect-scope-v1/b2-performance/performance-tool-redirect-scope-inputs.sha256`
- `results/eval-osdi/paper/20260617T-eval-performance-tool-redirect-scope-v1/b2-performance/performance-tool-redirect-scope-manifest.json`
- `results/eval-osdi/paper/20260617T-eval-performance-tool-redirect-scope-v1/b2-performance/performance-tool-redirect-scope-summary.md`

summary 记录：

- `scoped_c3_supported=true`
- `full_suite_c3_supported=false`
- `release_gate_pass=false`
- `max_scoped_policy_to_native_p99_ratio=1.3377667181511355`
- `min_scoped_policy_to_fuse_p99_speedup=2.2578242999873592`
- `failed_full_suite_benches=lookup_native_hot, readdir_alias_view, build_tree_stat_walk`

随后运行 `eval-osdi-claim-verdict-ledger` v3，将 C3 从 `unsupported` 收窄为
`partial`，但仍保持 `weak_accept_ready=false` 和 `release_gate_pass=false`。
