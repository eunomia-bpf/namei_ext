# OSDI external baseline release gate 实现记录

Last updated: 2026-06-15
Stage at update: execute/gate loop
Source/command: `make eval-osdi-baselines RUN_ID=20260615T-kvm-external-baselines-release-pilot BASELINE_SAMPLES=20 BASELINE_ITERS=500 BASELINE_LATENCY_SAMPLES=1 BASELINE_LATENCY_BATCH=4` 和 `make eval-osdi-performance-ledger RUN_ID=20260615T-eval-ledger-release-baselines-pilot EVAL_OSDI_PHASE1_RUN_ID=20260615T-kvm-bench-release-sample-pilot EVAL_OSDI_PERFORMANCE_BASELINE_RUN_ID=20260615T-kvm-external-baselines-release-pilot`
Completeness: partial

## 动机

之前 performance ledger 中的 `missing_release_baselines=[]` 只表示五类 external baseline family
都出现过 smoke rows，并不表示这些 baseline 有 release repetitions。这个语义会让评估记录看起来
比实际更强。为了避免把 smoke baseline 误用为 OSDI 性能证据，本次把 baseline ledger 拆成两层：

- smoke gate：baseline 是否能 setup/update/cleanup，通过 feature oracle，并且没有失败操作。
- release gate：在 smoke gate 通过的基础上，每个 baseline/bench 至少有 20 个 aggregate rows 和
  20 个 latency rows。

## 实现内容

修改 `mk/eval_osdi.mk`：

- `eval-osdi-baselines` 的 per-baseline row 新增：
  - `samples_observed`
  - `latency_samples_observed`
  - `min_bench_rows_per_case`
  - `min_latency_rows_per_case`
  - `required_paper_samples`
  - `has_release_sample_budget`
  - `qualified_for_baseline_release`
- baseline summary 新增：
  - `baselines_release_passed`
  - `has_copy_tree_release_baseline`
  - `has_symlink_forest_release_baseline`
  - `has_bind_mount_release_baseline`
  - `has_overlayfs_release_baseline`
  - `has_fuse_redirect_release_baseline`
  - `baseline_release_gate_pass`
- `missing_release_baselines` 改为基于 release-qualified baseline，而不是 smoke-qualified baseline。
- `eval-osdi-performance-ledger` 继续保留 smoke baseline fields，同时新增 release baseline fields；
  performance ledger 的 `missing_release_baselines` 现在基于 release-qualified fields。

## Smoke schema 验证

命令：

```text
make eval-osdi-baselines \
  RUN_ID=20260615T-kvm-external-baselines-ledger-schema-smoke-v1 \
  BASELINE_SAMPLES=1 BASELINE_ITERS=50 \
  BASELINE_LATENCY_SAMPLES=1 BASELINE_LATENCY_BATCH=2
```

结果：

- `baselines_selected=5`
- `baselines_passed=5`
- `baselines_release_passed=0`
- `baseline_smoke_gate_pass=true`
- `baseline_release_gate_pass=false`
- `missing_release_baselines=["copy_tree","symlink_forest","bind_mount","overlayfs","fuse_redirect"]`

这说明旧 smoke 规模不会误清空 release baseline list。

## Release baseline pilot

命令：

```text
make eval-osdi-baselines \
  RUN_ID=20260615T-kvm-external-baselines-release-pilot \
  BASELINE_SAMPLES=20 BASELINE_ITERS=500 \
  BASELINE_LATENCY_SAMPLES=1 BASELINE_LATENCY_BATCH=4
```

结果 root：

```text
results/eval-osdi/baselines/20260615T-kvm-external-baselines-release-pilot/
```

关键结果：

- `raw_rows=1617`
- `bench_rows=800`
- `latency_rows=800`
- `baselines_selected=5`
- `baselines_passed=5`
- `baselines_release_passed=5`
- `baseline_smoke_gate_pass=true`
- `baseline_release_gate_pass=true`
- `missing_release_baselines=[]`
- 每个 baseline 都有 `samples_observed=20`
- 每个 baseline 都有 `min_bench_rows_per_case=20`
- 每个 baseline 都有 `min_latency_rows_per_case=20`
- FUSE row 有 `fuse_mounts=1`
- dmesg issue count 为 0

## Performance ledger 链接

命令：

```text
make eval-osdi-performance-ledger \
  RUN_ID=20260615T-eval-ledger-release-baselines-pilot \
  EVAL_OSDI_PHASE1_RUN_ID=20260615T-kvm-bench-release-sample-pilot \
  EVAL_OSDI_PERFORMANCE_BASELINE_RUN_ID=20260615T-kvm-external-baselines-release-pilot
```

结果 root：

```text
results/eval-osdi/paper/20260615T-eval-ledger-release-baselines-pilot/b2-performance/
```

关键字段：

- `has_repetition_budget=true`
- `has_release_tail_sample_budget=true`
- `has_randomized_order=true`
- `has_system_metrics=true`
- `baseline_release_gate_pass=true`
- `has_copy_tree_release_baseline=true`
- `has_symlink_forest_release_baseline=true`
- `has_bind_mount_release_baseline=true`
- `has_overlayfs_release_baseline=true`
- `has_fuse_redirect_release_baseline=true`
- `missing_release_baselines=[]`
- `release_gate_pass=false`

## Hard gate 检查

命令：

```text
make eval-osdi-performance \
  RUN_ID=20260615T-eval-ledger-release-baselines-hardgate \
  EVAL_OSDI_PHASE1_RUN_ID=20260615T-kvm-bench-release-sample-pilot \
  EVAL_OSDI_PERFORMANCE_BASELINE_RUN_ID=20260615T-kvm-external-baselines-release-pilot
```

该 hard gate 按预期失败，外层 expected-fail 检查通过。原因是当前 ledger 只证明 release
输入证据存在，还没有完成 head-to-head comparison、overhead/ratio/CI 判定、claim verdict
和 paper-number audit。

## 剩余风险

- B2/B8 的数据输入 gate 明显更完整，但 C2/C3/C5 仍未 supported。
- 还需要从 raw distributions 计算 namei_ext vs native/pass-only/table/baselines 的绝对数、
  overhead ratio、CI 和可能的 tail regression。
- 还需要判断哪些 baseline 是公平比较、哪些只是可行性/功能对照。
- B12 policy-family gate 仍为 false，是更高优先级 blocker。
