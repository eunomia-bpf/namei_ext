# rusage 与 no-hook tail 诊断记录

Last updated: 2026-06-15
Stage at update: research/execute
Source/command: `20260615T-kvm-bench-rusage-tail10-v1`, `20260615T-kvm-bench-nohook-baseline-tail10-v1`, `20260615T-kvm-bench-baseline-passonly-tail10-v1`
Completeness: complete

## 动机

`20260615T-eval-comparison-ctx-init-split-tail10-v1` 已经证明 B2/B8 不是
input-blocked：internal/external tail input 都完整，FUSE speedup 阈值也通过。但
`kernel_p99_threshold_pass=false` 且 `pass_only_threshold_pass=false`。因此下一步要区分：

1. `pass_only` residual 是否来自 page fault、context switch 或 guest noise；
2. full benchmark 中的 `baseline` 是否足够代表 no-hook/static-key-off 下界；
3. 最小 `baseline + pass_only` matched run 是否仍违反 C5 的 1.1x 阈值。

## 执行命令

rusage full tail10：

```text
make kvm-bench RUN_ID=20260615T-kvm-bench-rusage-tail10-v1 SAMPLES=20 BENCH_ITERS=2000 BENCH_LATENCY_SAMPLES=10 BENCH_LATENCY_BATCH=64 BENCH_RANDOMIZE_ORDER=1
make eval-osdi-performance-tail RUN_ID=20260615T-eval-rusage-tail10-v1 EVAL_OSDI_PHASE1_RUN_ID=20260615T-kvm-bench-rusage-tail10-v1
```

no-hook baseline-only tail10：

```text
make kvm-bench RUN_ID=20260615T-kvm-bench-nohook-baseline-tail10-v1 BENCH_VARIANTS=baseline SAMPLES=20 BENCH_ITERS=2000 BENCH_LATENCY_SAMPLES=10 BENCH_LATENCY_BATCH=64 BENCH_RANDOMIZE_ORDER=1
make eval-osdi-performance-tail RUN_ID=20260615T-eval-nohook-baseline-tail10-v1 EVAL_OSDI_PHASE1_RUN_ID=20260615T-kvm-bench-nohook-baseline-tail10-v1
```

baseline/pass-only matched tail10：

```text
make kvm-bench RUN_ID=20260615T-kvm-bench-baseline-passonly-tail10-v1 BENCH_VARIANTS='baseline pass_only' SAMPLES=20 BENCH_ITERS=2000 BENCH_LATENCY_SAMPLES=10 BENCH_LATENCY_BATCH=64 BENCH_RANDOMIZE_ORDER=1
make eval-osdi-performance-tail RUN_ID=20260615T-eval-baseline-passonly-tail10-v1 EVAL_OSDI_PHASE1_RUN_ID=20260615T-kvm-bench-baseline-passonly-tail10-v1
```

## 输入完整性

`20260615T-kvm-bench-rusage-tail10-v1`：

- `bench_rows=700`
- `latency_rows=7000`
- `unique_samples=20`
- `latency_samples=10`
- `min_latency_ops=64`
- `max_latency_ops=4096`
- `missing_rusage_latency=0`
- `failing_ops=0`
- `resource_errors=0`
- `done_status=0`

`20260615T-kvm-bench-nohook-baseline-tail10-v1`：

- `bench_rows=140`
- `latency_rows=1400`
- `unique_samples=20`
- `latency_samples=10`
- `attach_rows=0`
- `variants=["baseline"]`
- `failing_ops=0`
- `resource_errors=0`
- `done_status=0`

`20260615T-kvm-bench-baseline-passonly-tail10-v1`：

- `bench_rows=280`
- `latency_rows=2800`
- `unique_samples=20`
- `latency_samples=10`
- `attach_rows=1`
- `variants=["baseline","pass_only"]`
- `failing_ops=0`
- `done_status=0`

三组 KVM run 的 dmesg gate pattern 数均为 0。

## 关键结果

### rusage 归因

full rusage tail10 的非 exec p99 rows 中，minor/major fault 和 context switch 基本为 0。
`pass_only` 与 `policy` 的 p99 self CPU/op 几乎同步上升：

- `lookup_native_hot`：baseline 0.3125 us/op，pass_only 0.453 us/op，policy 0.469 us/op。
- `readdir_alias_view`：baseline 0.209 us/op，pass_only 0.300 us/op，policy 0.300 us/op。
- `build_tree_stat_walk`：baseline 0.331 us/op，pass_only 0.586 us/op，policy 0.597 us/op。

这说明当前 C5 blocker 更像 common hook/dispatch/context 成本，而不是 fault、scheduler
noise 或 redirect policy 分支复杂度。`exec_tool_redirect` 仍主要由 fork/exec child 成本和
voluntary context switch 主导，不应作为 namei_ext path-resolution hot path 的主要归因。

### no-hook 下界

baseline-only no-hook tail10 的 p99 反而比 full run 的 baseline 慢。以 no-hook
baseline-only 为 denominator：

- max full-baseline/nohook p99 ratio = 0.981x；
- max pass-only/nohook p99 ratio = 1.306x；
- max policy/nohook p99 ratio = 1.244x。

这说明 full-run baseline denominator 存在明显 order/cache variance；但 no-hook denominator
并不能让 C5 过关，因为 pass-only 仍超过 1.1x 阈值。

### baseline/pass-only matched run

只运行 `baseline pass_only` 的 matched tail10 后，max pass-only/native p99 ratio 为
1.323x：

- `open_tool_redirect`：1.323x；
- `access_tool_redirect`：1.284x；
- `lookup_native_hot`：1.155x；
- `readdir_alias_view`：1.038x；
- `build_tree_stat_walk`：1.035x；
- `exec_tool_redirect`：0.906x；
- `lookup_tool_redirect`：0.314x，该 row 是 baseline p99 outlier，不能解释为 pass-only
  改善。

因此，selector 和 rusage 诊断降低了 C5 失败的严重程度，但没有把 C5 变成 supported。

## 结论

1. C5 仍不支持。当前最小 matched pass-only run 的 worst case 为 1.32x，高于 1.1x。
2. tail residual 主要体现在 self CPU/op，而不是 page fault 或 context switch。
3. full-run baseline 的 p99 denominator 有 order/cache variance；后续 comparison gate
   应考虑把 no-hook/baseline-only 和 matched baseline-pass-only 作为 C5 ablation 输入，而不是只看
   full 5-variant run。
4. 下一步若继续优化性能，应该优先设计 namei_ext helper-set/no-run-ctx fastpath 或更细的
   cgroup dispatch attribution；若不做 ABI/helper 级改动，应收窄 C5。

