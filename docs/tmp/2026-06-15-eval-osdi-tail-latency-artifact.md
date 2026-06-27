# eval-osdi tail latency artifact implementation

Date: 2026-06-15
Stage: Phase 1 B2/B8 performance gate implementation
Scope: `mk/eval_osdi.mk`, `Makefile`, `research/STATE.md`, `research/EXPERIMENT_TRACKER.md`, `research/RESULTS_SUMMARY.md`, `research/FOLLOWUP_PLAN.md`

## 动机

OSDI B2/B8 performance gate 不能只看 aggregate timing。之前 `kvm-bench` 已经能在修改内核 KVM
中输出 raw `event=bench_latency` rows，但 `eval-osdi-performance-ledger` 只能判断这些 rows 是否存在，
没有把它们变成 reviewer 可审计的 p50/p95/p99 和 confidence interval artifact。

本实现补齐最小的分析 target：仍由 Makefile 驱动，不新增项目 `.sh`、Python 脚本或手工流程。

## 设计

- 新增 `make eval-osdi-performance-tail`。
- 输入：`results/phase1/<run>/bench.jsonl` 中的 raw `bench_latency` rows。
- 输出：
  - `bench-latency-tail.jsonl`
  - `bench-latency-tail-inputs.sha256`
  - `bench-latency-tail-summary.md`
  - `bench-latency-tail-manifest.json`
- 每个 `(bench, variant)` 输出一行 `bench-latency-tail`，包含 rows、observed samples、mean、stdev、
  `ci95_low_ns_per_op`、`ci95_high_ns_per_op`、`p50_ns_per_op`、`p95_ns_per_op`、`p99_ns_per_op`、
  min/max 和 failure count。
- summary row 明确记录：
  - `has_tail_latency_artifact`
  - `has_confidence_interval`
  - `has_release_sample_budget`
  - expected rows/groups 和实际 rows/groups。

## 实现细节

本地 `jq` 没有 `sqrt()`，所以 CI 不能完全用 jq 实现。Make target 使用 `jq` 只把 JSONL 转成 TSV，
然后在同一个 Make recipe 中用 `awk` 计算排序后的 percentile、sample stdev 和 95% CI。
这保持了 Makefile-only 控制面，也避免新增 project-owned shell script。

`eval-osdi-performance-ledger` 现在依赖 `eval-osdi-performance-tail`，并把 tail artifact 的路径、
group count、min group rows、CI 状态和 release sample budget 状态写入 `performance.jsonl`、
`manifest.json` 和 `summary.md`。

如果 `bench-start.latency_samples > 0`，但实际 rows/groups 不完整或 latency row 有 failure，
`eval-osdi-performance-tail` 会直接失败。只有 `latency_samples=0` 的 canonical smoke root 才允许
生成 negative/empty artifact，用于明确记录当前缺 tail evidence。

## 验证

Pilot target：

```text
make eval-osdi-performance-tail RUN_ID=20260615T-tail-artifact-pilot EVAL_OSDI_PHASE1_RUN_ID=20260615T-kvm-bench-latency-pilot
```

结果：

- `rows=70`
- `expected_rows=70`
- `groups=35`
- `expected_groups=35`
- `min_group_rows=2`
- `has_tail_latency_artifact=true`
- `has_confidence_interval=true`（pilot-scale CI plumbing emitted，不是 release CI 结论）
- `has_release_sample_budget=false`

Canonical full-root ledger：

```text
make eval-osdi-performance-ledger RUN_ID=20260615T-eval-ledger-tail-artifact EVAL_OSDI_PHASE1_RUN_ID=20260615T-full-phase1-bench-variants
```

结果：

- `samples=1`
- `bench_latency_rows=0`
- `has_tail_latency_artifact=false`
- `has_confidence_interval=false`
- `has_release_tail_sample_budget=false`
- `release_gate_pass=false`

Hard gate negative check：

```text
make eval-osdi-performance RUN_ID=20260615T-eval-ledger-tail-artifact-hardgate EVAL_OSDI_PHASE1_RUN_ID=20260615T-full-phase1-bench-variants
```

结果按预期失败，因为 C2/C3/C5 仍缺 release repetitions、external baselines、randomized order 和
system metrics。

## 剩余风险

该 target 只证明 analysis infrastructure 已经可用。它不能替代 release run：

- pilot 每组只有 2 rows；
- canonical full Phase 1 root 没有 `bench_latency` rows；
- 仍缺 FUSE/copy/symlink/bind/OverlayFS baselines；
- 仍缺 randomized run order 和 CPU/memory/context-switch/disk metrics。

## Review revision

Hooke scoped review 给出 Weak Accept、P0/P1 无，并指出三个 P2：

- P2.1：声明采集 latency rows 时，不完整 rows/groups 或 failures 应该 hard fail。已修复：
  `eval-osdi-performance-tail` 在 `latency_samples > 0` 时强制 summary 满足完整性和 0 failure。
- P2.2：standalone tail artifact 需要更自包含 provenance。已修复：新增
  `bench-latency-tail-manifest.json`，记录 run id、phase1 root、repo HEAD/dirty 和 artifact paths。
- P2.3：pilot 的 `has_confidence_interval=true` 可能被误读。已修复文档措辞，统一写为
  pilot-scale CI plumbing，不作为 release CI。
