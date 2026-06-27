# W1 build workload macrobench ledger 实现记录

## 实现范围

本步骤新增 W1 build graph workload comparison ledger，用于把 proposed-system
`w1-build-macrobench.jsonl` 与 baseline `w1-build-baseline-macrobench.jsonl` 合并成
OSDI evaluation 可审计的 raw-derived ledger。

新增文件与 target：

- `configs/eval-osdi/w1-build-workload-macrobench.jq`
- `make eval-osdi-w1-build-workload-macrobench-ledger`
- `make eval-osdi-w1-build-workload-macrobench`

ledger target 只归纳 raw rows，不修改 raw measurement。hard gate target 要求 summary 中
`release_gate_pass=true` 且 `c2_supported=true`；当前应失败，因为 W1 仍缺 release baseline、
FUSE/projected-volume 和 threshold support。

## Ledger 输入

必须显式传入：

```text
EVAL_OSDI_W1_BUILD_POLICY_RUN_ID=<policy-run>
EVAL_OSDI_W1_BUILD_BASELINE_RUN_ID=<baseline-run>
```

读取的 artifacts：

- `results/phase1/<policy-run>/w1-build-macrobench.jsonl`
- `results/phase1/<policy-run>/w1-build-macrobench-inputs.sha256`
- `results/phase1/<baseline-run>/w1-build-baseline-macrobench.jsonl`
- `results/phase1/<baseline-run>/w1-build-baseline-macrobench-inputs.sha256`
- `docs/tmp/2026-06-16-w1-build-feature-baseline-design.md`
- `docs/tmp/2026-06-16-w1-build-feature-baseline-implementation.md`
- `configs/eval-osdi/w1-build-workload-macrobench.jq`
- `mk/eval_osdi.mk`

target 写：

- `w1-build-workload-macrobench.jsonl`
- `w1-build-workload-macrobench-inputs.sha256`
- `w1-build-workload-macrobench-summary.md`
- `w1-build-workload-macrobench-manifest.json`

## 输出语义

每次 ledger run 输出一条 proposed-system row、多条 feature-baseline row 和一条 summary。

summary gate 包括：

- `policy_release_input_pass`
- `baseline_release_input_pass`
- `copy_tree_baseline_pass`
- `symlink_forest_baseline_pass`
- `bind_mount_baseline_pass`
- `projected_volume_baseline_pass`
- `fuse_baseline_pass`
- `implemented_feature_baselines_pass`
- `full_feature_equivalent_baseline_pass`
- `storage_footprint_pass`
- `setup_latency_threshold_pass`
- `update_latency_threshold_pass`
- `update_materialization_threshold_pass`
- `threshold_pass`
- `w1_c2_slice_supported`
- `c2_supported=false`
- `release_gate_pass=false`

`full_feature_equivalent_baseline_pass` 要求 `copy_tree`、`symlink_forest`、`bind_mount`、
`projected_volume` 和 `fuse_redirect` 全部存在。当前实现只有前三类，因此 W1 slice 不会被误判为
C2 supported。

## 验证

ledger smoke：

```text
make eval-osdi-w1-build-workload-macrobench-ledger \
  RUN_ID=20260616T-eval-w1-build-workload-macrobench-ledger-smoke-v1 \
  EVAL_OSDI_W1_BUILD_POLICY_RUN_ID=20260616T-w1-build-macrobench-release-sample-v1 \
  EVAL_OSDI_W1_BUILD_BASELINE_RUN_ID=20260616T-w1-build-baseline-smoke-v2
```

结果：通过写出 ledger artifacts。summary 关键字段：

```text
policy_release_input_pass=true
baseline_release_input_pass=false
copy_tree_baseline_pass=true
symlink_forest_baseline_pass=true
bind_mount_baseline_pass=true
projected_volume_baseline_pass=false
fuse_baseline_pass=false
implemented_feature_baselines_pass=true
full_feature_equivalent_baseline_pass=false
storage_footprint_pass=false
threshold_pass=false
w1_c2_slice_supported=false
c2_supported=false
release_gate_pass=false
```

该结果符合预期：policy side 已有 20-sample release input；baseline side 仍只是 1-sample smoke。

hard gate 预期失败：

```text
make eval-osdi-w1-build-workload-macrobench \
  RUN_ID=20260616T-eval-w1-build-workload-macrobench-hardgate-smoke-v1 \
  EVAL_OSDI_W1_BUILD_POLICY_RUN_ID=20260616T-w1-build-macrobench-release-sample-v1 \
  EVAL_OSDI_W1_BUILD_BASELINE_RUN_ID=20260616T-w1-build-baseline-smoke-v2
```

结果：`eval-osdi-w1-build-workload-macrobench-ledger` 写出 artifacts 后，hard gate 在要求
`release_gate_pass=true` 和 `c2_supported=true` 的 jq 检查处失败；外层诊断记录
`hardgate_status=2`。这是预期行为，防止 1-sample baseline smoke 被误解释为 W1 C2 支持。

## 后续

- 跑 `W1_BUILD_BASELINE_MACROBENCH_SAMPLES=20` 的 baseline release input。
- 实现或正式排除 W1 projected-volume/FUSE baseline。
- 若 W1 目标是支持 C2，需要重新审视 threshold：当前 smoke 显示 proposed-system setup/update
  对最快 `copy_tree` baseline 并无优势，因此不能写性能改进 claim。
