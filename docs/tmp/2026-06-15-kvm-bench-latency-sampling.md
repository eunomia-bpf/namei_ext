# KVM microbenchmark latency sampling 实现记录

Last updated: 2026-06-15
Stage at update: Phase 1 implementation / OSDI performance raw evidence plumbing
Source/command: `make bench`; `make kvm-bench RUN_ID=20260615T-kvm-bench-latency-pilot SAMPLES=1 BENCH_ITERS=200 BENCH_LATENCY_SAMPLES=2 BENCH_LATENCY_BATCH=4`
Completeness: complete for raw latency row plumbing; incomplete for release-scale C2/C3/C5 evidence

## 动机

现有 `bench.jsonl` 已经能在修改内核 KVM guest 中记录 `baseline`、`pass_only`、
`table_redirect_empty`、`table_redirect_hit` 和 `policy` 五组 aggregate timing row。
这些 row 足够作为 Phase 1 smoke evidence，但还不能支撑 OSDI 性能结论，因为 B2/B8
需要原始分布、tail latency、重复次数、CI、随机化顺序、系统指标和外部 baseline。

本实现步只解决其中一个最小缺口：让 KVM microbenchmark collector 可以按 Makefile
knob 追加原始 latency batch observations。默认仍不产生 latency row，避免现有
`make phase1` 被误解释成 release-scale performance run。

## 调研和检查过的文件

- `bench/workloads/namei_ext_bench.c`：原实现每个 benchmark 直接在函数内部计时并只
  输出 `event=bench` aggregate row。
- `configs/benchmarks/phase1.mk`：Phase 1 benchmark knobs 目前只有 `SAMPLES` 和
  `BENCH_ITERS`。
- `mk/kvm.mk`：`kvm-bench` 通过 `vng --exec` 在 guest 中调用
  `__phase1_guest_bench`，此前只显式传递 `RUN_ID`。
- `mk/report.mk`：Phase 1 report hard gate 已检查 aggregate row 数、variant set、
  attach/detach 和 `table_redirect_hit` map update。
- `mk/eval_osdi.mk`：B2/B8 performance ledger 已把旧证据标为
  `phase1_kvm_microbench_smoke`，并硬编码 `has_tail_latency=false`。

## 实现内容

`bench/workloads/namei_ext_bench.c` 新增两个可选参数：

```text
namei_ext_bench RESULT_JSONL REDIRECT_POLICY_BPF_O SAMPLES ITERATIONS \
  [CGROUP [PASS_ONLY_BPF_O [TABLE_REDIRECT_BPF_O [LATENCY_SAMPLES [LATENCY_BATCH]]]]]
```

默认 `LATENCY_SAMPLES=0`，不改变旧输出。若 `LATENCY_SAMPLES>0`，runner 会在每个
aggregate `bench` row 后，为同一个 `(bench, variant, sample)` 追加
`LATENCY_SAMPLES` 条 `event=bench_latency` row。每条 row 保留：

- `bench`
- `variant`
- `sample`
- `latency_sample`
- `ops`
- `elapsed_ns`
- `ok`
- `fail`

为避免复制七套 timing 逻辑，runner 把 stat/open/access/exec/readdir/tree-walk 抽成
统一的 operation callback。aggregate timing 和 latency batch sampling 走同一个
真实 VFS 操作路径。`readdir_alias_view` 的 `ops` 仍按目录项计数；`build_tree_stat_walk`
的 `ops` 仍按实际 stat 的文件数计数。

注意：`bench_latency` row 是 batch 级 raw observation，`elapsed_ns / ops` 表示该
batch 的平均 ns/op。它不是单次 syscall latency row，也不是已经计算好的 p95/p99。
若 release experiment 要报告单次操作 tail latency，需要把
`BENCH_LATENCY_BATCH=1` 写入 release 配置；若使用更大的 batch，则论文和分析目标必须
明确报告为 batch ns/op distribution。

`configs/benchmarks/phase1.mk` 新增：

```make
BENCH_LATENCY_SAMPLES ?= 0
BENCH_LATENCY_BATCH ?= 16
```

`mk/kvm.mk` 的 `kvm-bench` 现在把 `SAMPLES`、`BENCH_ITERS`、
`BENCH_LATENCY_SAMPLES` 和 `BENCH_LATENCY_BATCH` 显式传给 guest make。此前 guest
只收到 `RUN_ID`，外层 benchmark knob 覆盖可能不会进入 KVM guest。

`__phase1_guest_bench` 的 `bench-start` row 现在记录：

```json
{
  "latency_samples": 0,
  "latency_batch": 16
}
```

当外层打开 latency sampling 时，这两个字段会记录实际值。

`mk/report.mk` 新增 hard gate：

- `BENCH_LATENCY_SAMPLES=0` 时，要求 `bench.jsonl` 中没有 `bench_latency` row。
- `BENCH_LATENCY_SAMPLES>0` 时，要求 latency row 数为
  `SAMPLES * 35 * BENCH_LATENCY_SAMPLES`。
- 每个 variant 必须有 `SAMPLES * 7 * BENCH_LATENCY_SAMPLES` 条 latency row。
- 所有 latency row 必须 `fail=0`，且 `ops>0`、`elapsed_ns>0`、`ok>0`。

`mk/eval_osdi.mk` 的 performance ledger 现在读取：

- `latency_samples`
- `latency_batch`
- `bench_latency_rows`
- `latency_failing_ops`
- `has_latency_raw_rows`
- `has_tail_latency_artifact`

但 release gate 仍然保持 `false`，并且 `has_tail_latency_artifact=false`。有 raw
latency row 只解决后续 percentile analysis 的原始输入来源，不等于具备 release-scale
repetitions、CI、随机化顺序、系统指标、tail-latency artifact 或外部 baseline。

## 拒绝的方案

- 不在 report/ledger 中合成 p95/p99。collector 只保存 raw observations；CI、tail
  percentile 和 paper table 应由后续 analysis/report target 计算。
- 不把 aggregate samples 当成 tail latency。aggregate row 是 smoke timing，不是
  分布样本。
- 不把 batch latency row 暗示成单次 syscall p99。release run 要么设置
  `BENCH_LATENCY_BATCH=1`，要么只声明 batch ns/op distribution。
- 不默认打开 latency sampling。Phase 1 默认目标仍然是快速验证功能和路径，不应把
  smoke run 暗中升级为 release performance run。
- 不引入 shell script。所有 knobs 和执行入口继续由 Makefile 管理。

## 验证

本地 benchmark binary 编译通过：

```text
make bench
```

静态 diff 检查通过：

```text
git diff --check
```

KVM latency pilot 通过：

```text
make kvm-bench RUN_ID=20260615T-kvm-bench-latency-pilot \
  SAMPLES=1 BENCH_ITERS=200 BENCH_LATENCY_SAMPLES=2 BENCH_LATENCY_BATCH=4
```

该 run 的 raw evidence 位于：

```text
results/phase1/20260615T-kvm-bench-latency-pilot/bench.jsonl
```

验证摘要：

```json
{
  "bench_rows": 35,
  "latency_rows": 70,
  "variants": [
    "baseline",
    "pass_only",
    "policy",
    "table_redirect_empty",
    "table_redirect_hit"
  ],
  "failing_ops": 0,
  "latency_failing_ops": 0,
  "table_hit_map_updates": 66,
  "attach_successes": 4,
  "latency_samples": 2,
  "latency_batch": 4
}
```

KVM bench dmesg 检查通过：

```text
awk '/] (BUG:|WARNING:|Oops:|Kernel panic|panic:|hung task)|kernel BUG at/ { n++ } END { print n + 0 }' \
  results/phase1/20260615T-kvm-bench-latency-pilot/dmesg-bench.log
```

输出为 `0`。

对仅含 `kvm-bench` 子集的 pilot root 直接运行
`make eval-osdi-performance-ledger` 按预期失败，因为 ledger contract 要求完整
Phase 1 root 的 `metadata.json`。这不是 benchmark 失败，而是 B2/B8 ledger 的输入
完整性门禁。

使用当前 canonical 完整 Phase 1 root 重新生成 performance ledger 通过：

```text
make eval-osdi-performance-ledger \
  RUN_ID=20260615T-eval-ledger-after-latency-code \
  EVAL_OSDI_PHASE1_RUN_ID=20260615T-full-phase1-bench-variants
```

旧 full root 没有 `bench_latency` row，因此 ledger 记录
`bench_latency_rows=0`、`has_latency_raw_rows=false`、`has_tail_latency_artifact=false`，
保持 release gate 失败。这说明代码能力不会被误计入已有实验结果。

## 剩余风险和后续工作

- 需要一个 release-scale performance run target，显式设置足够的
  `SAMPLES`、`BENCH_LATENCY_SAMPLES`、随机化顺序和系统指标采集。
- 需要 analysis target 从 raw latency rows 计算 p50/p95/p99、CI 和 per-variant
  overhead，而不是在 collector 内计算。
- 需要补 FUSE、copy-tree、symlink-forest、bind mount 和 OverlayFS 外部 baseline。
- 需要 full Phase 1 或 release run 重新打开 latency sampling 后，才能把
  `has_latency_raw_rows=true` 作为完整 root 的 evidence；`has_tail_latency_artifact`
  仍要等后续 percentile/CI analysis target 生成后才可为 true。当前 canonical full
  root 仍是 smoke-scale aggregate evidence。
