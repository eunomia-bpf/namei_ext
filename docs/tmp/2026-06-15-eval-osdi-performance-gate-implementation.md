# OSDI performance/baseline gate 实现记录

Last updated: 2026-06-15
Stage at update: Phase 1 implementation / OSDI performance gate
Source/command: `make eval-osdi-performance-ledger RUN_ID=20260615T-eval-contract EVAL_OSDI_PHASE1_RUN_ID=20260615T-full-phase1-gatefix`
Completeness: complete for the contract gate; blocked for OSDI release performance evidence

## 动机

完整 Phase 1 full root 已包含 `bench.jsonl`。它来自修改内核 KVM guest 中的
`make kvm-bench`，覆盖 lookup/open/access/exec/readdir/stat-walk 等 VFS
microbench operations，并且当前没有 failing ops。

但是该数据仍然只是 smoke-scale microbench：

- `SAMPLES=1`，没有足够重复；
- 每个 row 只有 aggregate `elapsed_ns`，没有 per-operation distribution 或 p99；
- 只有 `baseline` 和 `policy` 两个 variant；
- 没有 pass-only、table-redirect-hit、FUSE、copy-tree、symlink-forest、bind mount、
  OverlayFS 等 OSDI baselines；
- 没有 randomized order、confidence interval、CPU/memory/context-switch 等系统指标。

因此不能把 `bench.jsonl` 写成 C2/C3/C5 的 OSDI 级性能结论。需要一个
Makefile-owned gate 把“已有 smoke 证据”和“发布级性能证据缺口”机械化。

## 调研和检查过的文件

- `bench/workloads/namei_ext_bench.c`：确认现有 bench 只写 aggregate JSONL row，
  每个 sample/variant/bench 一行。
- `bench/workloads/Makefile`：确认 bench binary 由 Make 构建，链接 kernel
  `tools/lib/bpf`。
- `mk/kvm.mk`：确认 `kvm-bench` 在修改内核 KVM guest 中运行
  `namei_ext_bench`，输出 `bench.jsonl` 和 `dmesg-bench.log`。
- `mk/report.mk`：确认 Phase 1 report 只要求 `bench.fail` 总数为 0，并把
  ns/op 表写入 smoke report。
- `results/phase1/20260615T-full-phase1-gatefix/bench.jsonl`：确认当前 samples=1、
  iterations=2000、variants 为 `baseline` 和 `policy`。
- `docs/experiment-plans/osdi-evaluation.md`：确认 OSDI evaluation 要求 B2
  microbenchmark、B8 ablation/baselines、tail latency、CI、named baselines。

## 实现内容

在 `mk/eval_osdi.mk` 中新增：

- `eval-osdi-performance-ledger`
- `eval-osdi-performance`

新增输出目录：

```text
results/eval-osdi/paper/<run-id>/b2-performance/
```

新增 raw artifacts：

- `performance.jsonl`
- `performance-inputs.sha256`
- `manifest.json`
- `summary.md`

`eval-osdi-performance-ledger` 读取已有 Phase 1 full root 的 `bench.jsonl`，并生成
一行 `eval-osdi-performance` 和一行 `eval-osdi-performance-summary`。当前字段包括：

- `samples`
- `required_paper_samples`
- `iterations`
- `bench_rows`
- `bench_names`
- `variants_observed`
- `has_native_baseline`
- `has_namei_policy_variant`
- `has_tail_latency`
- `has_confidence_interval`
- `has_randomized_order`
- `has_system_metrics`
- `failing_ops`
- `missing_release_baselines`
- `release_gate_pass`
- `qualified_for_c2_c3_c5`

当前 `release_gate_pass=false`，`c2_supported=false`，`c3_supported=false`，
`c5_supported=false`。这保留了 smoke 性能证据，同时阻止它被误用为 OSDI
performance claim。

`eval-osdi-performance` 是 hard gate。它要求 summary 中 release gate、C2、C3 和
C5 全部为 true；当前应失败。

`eval-osdi-smoke` 现在会在 `phase1` 后同时写 B12 policy-family ledger 和 B2/B8
performance ledger。`eval-osdi-paper` 现在把 policy-family hard gate 和
performance hard gate 都列为发布级 gate。

## 拒绝的方案

- 不从 aggregate `elapsed_ns/ops` 计算 p99 或 CI。现有 raw data 没有 per-op
  distribution；强行计算会误导。
- 不把 `baseline` variant 重命名成 native/FUSE/table-redirect-hit 多个 baseline。当前
  binary 没有运行这些 baseline。
- 不把 `SAMPLES=1` 的 smoke run 当成论文性能数据。它只能用于 pipeline sanity。

## 验证

Performance ledger 生成通过：

```text
make eval-osdi-performance-ledger \
  RUN_ID=20260615T-eval-contract \
  EVAL_OSDI_PHASE1_RUN_ID=20260615T-full-phase1-gatefix
```

生成的 summary 显示：

```text
samples=1
required=20
variants=baseline,policy
failing_ops=0
release_gate=false
missing baselines: pass_only, table_redirect_hit, fuse_redirect, copy_tree, symlink_forest, bind_mount, overlayfs
```

输入哈希校验通过：

```text
sha256sum -c results/eval-osdi/paper/20260615T-eval-contract/b2-performance/performance-inputs.sha256
```

Hard gate 按预期失败：

```text
make -s eval-osdi-performance \
  RUN_ID=20260615T-eval-contract-perf-hardgate \
  EVAL_OSDI_PHASE1_RUN_ID=20260615T-full-phase1-gatefix
```

失败点是 `eval-osdi-performance` 的 `jq -e`，因为当前
`release_gate_pass=false`、`c2_supported=false`、`c3_supported=false`、
`c5_supported=false`。这是正确行为。

## 剩余风险和后续工作

- 需要实现发布级 benchmark runner，记录 per-operation latency distribution、
  p50/p95/p99、warmup、randomized order、repetitions、CI 和系统指标。
- 需要实现 named baselines：pass-only、table-redirect-hit、FUSE、copy-tree、
  symlink-forest、bind mount、OverlayFS。
- 需要把 correctness oracle 作为性能 run 的前置 gate；性能数字只能在 oracle
  通过后解释。
- 需要让 report target 从 raw JSONL 生成论文表格和 confidence interval，而不是在
  collector 里计算论文结论。

## 后续更新：bench variants 进入完整 Phase 1 root

同日后续重新运行了完整 Phase 1：

```text
make phase1 RUN_ID=20260615T-full-phase1-bench-variants
```

并基于该 root 重新生成 performance ledger：

```text
make eval-osdi-performance-ledger \
  RUN_ID=20260615T-eval-contract-bench-variants \
  EVAL_OSDI_PHASE1_RUN_ID=20260615T-full-phase1-bench-variants
```

新的 ledger 显示：

```text
samples=1
required=20
variants=baseline,pass_only,policy,table_redirect_empty,table_redirect_hit
failing_ops=0
has_pass_only_baseline=true
has_table_redirect_empty_baseline=true
has_table_redirect_hit_baseline=true
release_gate=false
missing baselines: fuse_redirect, copy_tree, symlink_forest, bind_mount, overlayfs
```

对应输入哈希校验通过：

```text
sha256sum -c results/eval-osdi/paper/20260615T-eval-contract-bench-variants/b2-performance/performance-inputs.sha256
```

新的 hard gate 仍按预期失败：

```text
make eval-osdi-performance \
  RUN_ID=20260615T-eval-contract-bench-variants-hardgate \
  EVAL_OSDI_PHASE1_RUN_ID=20260615T-full-phase1-bench-variants
```

失败是正确行为：当前已经补齐 Phase 1 内部的 pass-only、empty-table 和 populated-table
KVM smoke variants，但仍没有 release-scale repetitions、tail latency、confidence
interval、随机顺序、系统指标和外部 filesystem baselines。
