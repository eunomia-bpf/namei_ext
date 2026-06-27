# OSDI performance run-order 与 system-metrics 实现记录

Last updated: 2026-06-15
Stage at update: execute/gate loop
Source/command: `make kvm-bench RUN_ID=20260615T-kvm-bench-order-metrics-pilot-v3 SAMPLES=1 BENCH_ITERS=200 BENCH_LATENCY_SAMPLES=2 BENCH_LATENCY_BATCH=4 BENCH_RANDOMIZE_ORDER=1` 和 `make eval-osdi-performance-ledger RUN_ID=20260615T-eval-ledger-order-metrics-pilot-v2 EVAL_OSDI_PHASE1_RUN_ID=20260615T-kvm-bench-order-metrics-pilot-v3 EVAL_OSDI_PERFORMANCE_BASELINE_RUN_ID=20260615T-kvm-external-baselines-fuse-smoke-v2`
Completeness: partial

## 动机

OSDI 级性能评估不能只给一个固定顺序的 smoke benchmark。当前 B2/B8 gate 至少需要四类证据：

1. 修改内核 KVM 内的 raw timing rows。
2. p50/p95/p99 和 CI 统计 artifact。
3. 可审计的 randomized run order，避免固定顺序、cache/warmup 或 attach 顺序污染结果。
4. 系统指标采集，至少能把 CPU、内存、VM 和 block-device 变化与 benchmark run 绑定。

之前的 FUSE/copy/symlink/bind/OverlayFS baseline smoke 已经把 named baseline list 补齐，但
performance ledger 仍然报告缺少随机化顺序和系统指标。本次实现目标是先把这两类 artifact
接进 Makefile-owned KVM path，并保持 release gate 继续失败，直到 repetition/sample budget
真的满足。

## 涉及文件

- `bench/workloads/namei_ext_bench.c`
- `mk/kvm.mk`
- `mk/eval_osdi.mk`
- `configs/benchmarks/phase1.mk`

## 设计选择

benchmark runner 增加确定性随机化，而不是由外部脚本洗牌。seed 由
`NAMEI_EXT_BENCH_ORDER_SEED` 控制；Makefile 默认用 `RUN_ID`，因此同一个 run 可以复现，
不同 run 默认得到不同顺序。`NAMEI_EXT_BENCH_RANDOMIZE=0` 可以关闭随机化，默认通过
`BENCH_RANDOMIZE_ORDER=1` 打开。

runner 写出三类顺序 row：

- `bench_order_start`：记录是否 randomized 以及 seed hash。
- `bench_variant_order`：记录 variant 执行顺序。
- `bench_order`：记录每个 variant/sample 内具体 microbenchmark 执行顺序。

KVM guest 在 runner 前后采集 raw system metrics：

- `bench-proc-stat-before.txt` / `bench-proc-stat-after.txt`
- `bench-meminfo-before.txt` / `bench-meminfo-after.txt`
- `bench-vmstat-before.txt` / `bench-vmstat-after.txt`
- `bench-diskstats-before.txt` / `bench-diskstats-after.txt`
- `bench-system-metrics.jsonl`

这些文件只保存 raw observations，不在 guest 侧计算论文结论。

## Makefile 状态传递修复

第一次 pilot `20260615T-kvm-bench-order-metrics-pilot` 暴露了一个 Makefile 语义问题：
`__phase1_guest_bench` 在一行中设置 `status=0; ... || status=$$?`，但后续 `printf` 和
`test` 是新的 shell，导致 `status` 丢失。结果是 runner 已经写出 `bench_summary ok=1`
的情况下，最后一行变成：

```json
{"event":"bench-done","run_id":"20260615T-kvm-bench-order-metrics-pilot","status":}
```

修复方式是把 runner exit status 显式写入 `bench-status.txt`，后续 JSON 和 hard gate 都从该
文件读取。这保留了 fail-fast 行为，也让失败 run 的 dmesg 和系统指标仍然落盘。

## Provenance 补齐

`eval-osdi-performance-ledger` 要求 Phase 1 result root 有 `metadata.json`，用于把 raw
benchmark、dmesg、repo revision、kernel image/config 和 benchmark knobs 绑定在一起。
单独 `kvm-bench` 之前不写该文件。本次在 host 侧启动 KVM 前写出：

- `metadata.json`
- `main-repo-head.txt`
- `kernel-repo-head.txt`
- `main-repo-status.txt`
- `kernel-repo-status.txt`
- `kernel-image.sha256`
- `kernel-config.sha256`
- `kernel-config-fragment.sha256`
- `benchmark-config.sha256`
- `kvm-config.sha256`

该 metadata 不伪造 Docker image 字段；它的 schema 是
`namei_ext.phase1.kvm_bench_metadata.v1`，只声明 `kvm-bench` 本身实际记录到的 provenance。

## 验证结果

成功 KVM pilot：

```text
make kvm-bench RUN_ID=20260615T-kvm-bench-order-metrics-pilot-v3 \
  SAMPLES=1 BENCH_ITERS=200 BENCH_LATENCY_SAMPLES=2 \
  BENCH_LATENCY_BATCH=4 BENCH_RANDOMIZE_ORDER=1
```

关键结果：

- `results/phase1/20260615T-kvm-bench-order-metrics-pilot-v3/bench.jsonl`
- `bench-done status=0`
- `bench_rows=35`
- `bench_latency_rows=70`
- `bench_order rows=35`
- `bench_variant_order rows=5`
- `bench-system-metrics.jsonl` 有 before/after 两个 system metric rows
- `bench-status.txt` 为 `0`

成功 ledger：

```text
make eval-osdi-performance-ledger \
  RUN_ID=20260615T-eval-ledger-order-metrics-pilot-v2 \
  EVAL_OSDI_PHASE1_RUN_ID=20260615T-kvm-bench-order-metrics-pilot-v3 \
  EVAL_OSDI_PERFORMANCE_BASELINE_RUN_ID=20260615T-kvm-external-baselines-fuse-smoke-v2
```

关键 ledger 字段：

- `has_tail_latency_artifact=true`
- `has_confidence_interval=true`
- `has_randomized_order=true`
- `has_system_metrics=true`
- `has_copy_tree_baseline=true`
- `has_symlink_forest_baseline=true`
- `has_bind_mount_baseline=true`
- `has_overlayfs_baseline=true`
- `has_fuse_redirect_baseline=true`
- `missing_release_baselines=[]`
- `has_release_tail_sample_budget=false`
- `release_gate_pass=false`

预期失败 hard gate：

```text
make eval-osdi-performance \
  RUN_ID=20260615T-eval-ledger-order-metrics-hardgate-pilot \
  EVAL_OSDI_PHASE1_RUN_ID=20260615T-kvm-bench-order-metrics-pilot-v3 \
  EVAL_OSDI_PERFORMANCE_BASELINE_RUN_ID=20260615T-kvm-external-baselines-fuse-smoke-v2
```

该命令按预期失败；外层检查把这种失败视为 pass。原因是 pilot 只有 `SAMPLES=1` 和每组
2 个 latency rows，仍不满足 release sample budget。

## 剩余风险

- 当前 run-order/system-metrics 只是 pilot，不支撑 C2/C3/C5 论文性能 claim。
- release run 需要 `SAMPLES>=20` 且每个 bench/variant group 至少 20 个 latency rows。
- 外部 baselines 仍只有 smoke repetition；copy/symlink/bind/OverlayFS/FUSE 都要扩展到
  release repetition。
- 当前主仓库和 kernel submodule 都是 dirty state；最终 artifact 需要 clean revision。
- B12 policy-family gate 仍是独立 blocker，当前 table-only counterfactual 还没有让四个
  policy family 达到 `qualified_for_c1_c8=true`。
