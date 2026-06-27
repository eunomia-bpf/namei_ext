# C5 rusage/no-hook ablation ledger

日期：2026-06-17

## 背景

当前 claim verdict v10 把 C5 residual-overhead claim scoped out，因为 pass-only/native
p99 threshold 仍失败。此前 `docs/tmp/2026-06-15-rusage-nohook-tail-diagnostic.md`
已经人工总结过三组 KVM 诊断：

- full rusage tail10；
- no-hook baseline-only tail10；
- baseline/pass-only matched tail10。

但这些证据还没有进入 Make-owned 派生 ledger。为了达到 OSDI 级审计要求，本次把这些 raw
KVM 结果整理成独立 JSONL：它保留 C5 负结论，同时把 denominator variance、no-hook 下界和
rusage 噪声指标变成可复查字段。

## 实现

新增 target：

```text
make eval-osdi-c5-rusage-nohook-ledger
```

新增变量：

- `EVAL_OSDI_C5_ABLATION_RUSAGE_RUN_ID`
- `EVAL_OSDI_C5_ABLATION_RUSAGE_PHASE1_RUN_ID`
- `EVAL_OSDI_C5_ABLATION_RUSAGE_TAIL_JSON`
- `EVAL_OSDI_C5_ABLATION_RUSAGE_RAW_JSON`
- `EVAL_OSDI_C5_ABLATION_NOHOOK_RUN_ID`
- `EVAL_OSDI_C5_ABLATION_NOHOOK_TAIL_JSON`
- `EVAL_OSDI_C5_ABLATION_MATCHED_RUN_ID`
- `EVAL_OSDI_C5_ABLATION_MATCHED_TAIL_JSON`
- `EVAL_OSDI_C5_ABLATION_JSON`
- `EVAL_OSDI_C5_ABLATION_INPUTS_SHA256`
- `EVAL_OSDI_C5_ABLATION_SUMMARY`
- `EVAL_OSDI_C5_ABLATION_MANIFEST`

target 读取：

- rusage tail JSONL：
  `results/eval-osdi/paper/20260615T-eval-rusage-tail10-v1/b2-performance/bench-latency-tail.jsonl`
- rusage raw KVM bench rows：
  `results/phase1/20260615T-kvm-bench-rusage-tail10-v1/bench.jsonl`
- no-hook baseline-only tail JSONL：
  `results/eval-osdi/paper/20260615T-eval-nohook-baseline-tail10-v1/b2-performance/bench-latency-tail.jsonl`
- baseline/pass-only matched tail JSONL：
  `results/eval-osdi/paper/20260615T-eval-baseline-passonly-tail10-v1/b2-performance/bench-latency-tail.jsonl`

入口 hard gate：

- 三个 tail JSONL 都必须有 `has_tail_latency_artifact=true`、release sample budget 和
  latency batch budget；
- rusage raw JSONL 必须包含带 `user_usec` 和 `sys_usec` 的 `bench_latency` rows；
- 所有输入写入 sha256 manifest 并通过 `sha256sum -c`；
- 输出 summary 必须保持 `c5_supported=false` 和 `release_gate_pass=false`；
- 至少一个 matched baseline/pass-only row 必须仍未通过 1.10x threshold；
- 所有 per-bench rows 必须 complete。

每个 row 记录：

- full-run baseline/pass-only/policy p99；
- no-hook baseline p99；
- matched baseline/pass-only p99；
- full pass-only/native p99 ratio；
- full pass-only/no-hook p99 ratio；
- matched pass-only/native p99 ratio；
- pass-only self CPU mean/max ns/op；
- pass-only fault/context-switch mean per op。

## 验证

运行：

```text
make eval-osdi-c5-rusage-nohook-ledger \
  RUN_ID=20260617T-eval-c5-rusage-nohook-ablation-v1 \
  EVAL_OSDI_C5_ABLATION_RUSAGE_RUN_ID=20260615T-eval-rusage-tail10-v1 \
  EVAL_OSDI_C5_ABLATION_RUSAGE_PHASE1_RUN_ID=20260615T-kvm-bench-rusage-tail10-v1 \
  EVAL_OSDI_C5_ABLATION_NOHOOK_RUN_ID=20260615T-eval-nohook-baseline-tail10-v1 \
  EVAL_OSDI_C5_ABLATION_MATCHED_RUN_ID=20260615T-eval-baseline-passonly-tail10-v1
```

target 通过，生成：

- `results/eval-osdi/paper/20260617T-eval-c5-rusage-nohook-ablation-v1/b2-performance/c5-rusage-nohook-ablation.jsonl`
- `results/eval-osdi/paper/20260617T-eval-c5-rusage-nohook-ablation-v1/b2-performance/c5-rusage-nohook-ablation-inputs.sha256`
- `results/eval-osdi/paper/20260617T-eval-c5-rusage-nohook-ablation-v1/b2-performance/c5-rusage-nohook-ablation-manifest.json`
- `results/eval-osdi/paper/20260617T-eval-c5-rusage-nohook-ablation-v1/b2-performance/c5-rusage-nohook-ablation-summary.md`

summary 记录：

- `rows=7`
- `complete_rows=7`
- `c5_supported=false`
- `release_gate_pass=false`
- `max_matched_pass_only_to_native_p99_ratio=1.3228769017980637`
- `max_full_pass_only_to_native_p99_ratio=1.7728191397011408`
- `max_full_pass_only_to_nohook_p99_ratio=1.3064224548049477`
- matched run 失败 benches:
  `access_tool_redirect`, `lookup_native_hot`, `open_tool_redirect`
- full run 失败 benches:
  `access_tool_redirect`, `build_tree_stat_walk`, `lookup_native_hot`,
  `lookup_tool_redirect`, `open_tool_redirect`, `readdir_alias_view`

关键 row：

- `open_tool_redirect` matched pass/native p99 = 1.323x；
- `access_tool_redirect` matched pass/native p99 = 1.284x；
- `lookup_native_hot` matched pass/native p99 = 1.155x；
- `readdir_alias_view` matched pass/native p99 = 1.038x；
- `build_tree_stat_walk` matched pass/native p99 = 1.035x。

`exec_tool_redirect` 的 context-switch 和 minor-fault 指标来自 fork/exec 行为，不应作为
namei hot path residual 的主要解释。非 exec matched 失败行没有 major fault 或 context-switch
信号，说明 C5 blocker 更像 common hook/dispatch/self-CPU residual。

## 结论

该 ledger 不支持 C5。它把 C5 blocker 从“full-run pass-only 失败”细化为：

1. full-run denominator 有 order/cache variance；
2. no-hook denominator 不能让 pass-only 全部过 1.10x；
3. matched baseline/pass-only 仍有三个非 exec metadata rows 超过阈值；
4. 失败行主要是 self-CPU residual，不是 page fault、major fault 或 scheduler noise。

后续如果要支持 C5，需要做内核/ABI 级优化，例如 helper-set/no-run-ctx fast path 或更细的
cgroup dispatch attribution；否则论文必须继续把 C5 机制归因 claim 保持 scoped out。
