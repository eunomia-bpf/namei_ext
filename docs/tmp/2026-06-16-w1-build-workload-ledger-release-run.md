# W1 build workload ledger release run

日期：2026-06-16

## 动机

W1 build graph 已有 proposed-system 20-sample KVM setup/update release input：
`20260616T-w1-build-macrobench-release-sample-v1`。本轮新增
`20260616T-w1-build-baseline-release-sample-v1` 后，需要把两类输入合并到
claim-level ledger，并用 hard gate 防止 partial evidence 被误写成 C2 支持。

## 命令

ledger：

```text
make eval-osdi-w1-build-workload-macrobench-ledger \
  RUN_ID=20260616T-eval-w1-build-workload-macrobench-ledger-release-v1 \
  EVAL_OSDI_W1_BUILD_POLICY_RUN_ID=20260616T-w1-build-macrobench-release-sample-v1 \
  EVAL_OSDI_W1_BUILD_BASELINE_RUN_ID=20260616T-w1-build-baseline-release-sample-v1
```

hard gate：

```text
make eval-osdi-w1-build-workload-macrobench \
  RUN_ID=20260616T-eval-w1-build-workload-macrobench-hardgate-release-v1 \
  EVAL_OSDI_W1_BUILD_POLICY_RUN_ID=20260616T-w1-build-macrobench-release-sample-v1 \
  EVAL_OSDI_W1_BUILD_BASELINE_RUN_ID=20260616T-w1-build-baseline-release-sample-v1
```

## 输入和执行路径

ledger target 位于 `mk/eval_osdi.mk`，核心过滤器为
`configs/eval-osdi/w1-build-workload-macrobench.jq`。输入包括：

- proposed-system JSONL：
  `results/phase1/20260616T-w1-build-macrobench-release-sample-v1/w1-build-macrobench.jsonl`
- proposed-system input hash：
  `results/phase1/20260616T-w1-build-macrobench-release-sample-v1/w1-build-macrobench-inputs.sha256`
- baseline JSONL：
  `results/phase1/20260616T-w1-build-baseline-release-sample-v1/w1-build-baseline-macrobench.jsonl`
- baseline input hash：
  `results/phase1/20260616T-w1-build-baseline-release-sample-v1/w1-build-baseline-macrobench-inputs.sha256`
- W1 baseline design/implementation/ledger implementation docs、jq filter 和 `mk/eval_osdi.mk`。

两个 ledger result root 的 `w1-build-workload-macrobench-inputs.sha256` 均已通过
`sha256sum -c` 复验。hard gate target 额外写出：

```text
results/eval-osdi/paper/20260616T-eval-w1-build-workload-macrobench-hardgate-release-v1/b3-macrobench/w1-build-workload-macrobench-hardgate-status.json
```

## 结果

ledger artifacts：

```text
results/eval-osdi/paper/20260616T-eval-w1-build-workload-macrobench-ledger-release-v1/b3-macrobench/w1-build-workload-macrobench.jsonl
results/eval-osdi/paper/20260616T-eval-w1-build-workload-macrobench-ledger-release-v1/b3-macrobench/w1-build-workload-macrobench-inputs.sha256
results/eval-osdi/paper/20260616T-eval-w1-build-workload-macrobench-ledger-release-v1/b3-macrobench/w1-build-workload-macrobench-summary.md
```

summary：

```text
policy_release_input_pass=true
baseline_release_input_pass=true
copy_tree_baseline_pass=true
symlink_forest_baseline_pass=true
bind_mount_baseline_pass=true
projected_volume_baseline_pass=false
fuse_baseline_pass=false
implemented_feature_baselines_pass=true
full_feature_equivalent_baseline_pass=false
storage_footprint_pass=false
setup_latency_threshold_pass=false
update_latency_threshold_pass=false
update_materialization_threshold_pass=false
threshold_pass=false
w1_c2_slice_supported=false
c2_supported=false
release_gate_pass=false
```

关键均值：

```text
policy_setup_ns_avg=66090011.6
best_baseline_setup_ns_avg=18326753.1
policy_update_ns_avg=52416038.25
best_baseline_update_ns_avg=40165924.95
policy_setup_objects_avg=14
min_baseline_setup_objects_avg=6
policy_setup_bytes_avg=457356
min_baseline_setup_bytes_avg=69298
```

missing inputs：

```text
W1 projected-volume baseline
W1 FUSE baseline
W3/W4 workload setup/storage/update macrobench
```

failed gates：

```text
W1 storage footprint gate failed
W1 setup latency threshold failed
W1 update latency threshold failed
W1 update materialization threshold failed
```

hard gate 写出 artifacts 后按预期非零退出。持久化 status artifact 记录的是
hard-gate predicate 的状态：

```text
status=4
pass=false
```

外层 Make wrapper 观察到的退出状态是 `hardgate_status=2`；这个值用于交互式运行诊断，
不作为 ledger JSONL 的 claim 字段。

## 结论

W1 现在有 proposed-system release input 和三类 baseline release input，但 W1 C2 slice
仍为负。当前结果不能写成 setup/materialization improvement；更准确的表述是：
W1 release comparison infrastructure 已可运行，缺失输入是 projected-volume、FUSE 和
W3/W4 对等宏基准；已计算的 storage/setup/update gates 均失败，第一批三类 baseline
表明 proposed-system 在这个 sampled build-graph slice 上没有超过最快 copy/bind baseline。
