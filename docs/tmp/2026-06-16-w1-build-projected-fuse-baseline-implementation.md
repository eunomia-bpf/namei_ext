# W1 build projected and FUSE baseline implementation

日期：2026-06-16

## 动机

W1 build graph 已有 proposed-system 20-sample KVM release input，以及
`copy_tree`、`symlink_forest`、`bind_mount` 三类 feature baseline release input。
旧 ledger 的缺口是 `projected_volume_baseline_pass=false` 和
`fuse_baseline_pass=false`，因此 W1 comparison 既是负结果，又是不完整 baseline
family。此次补齐 Kubernetes projected-volume style baseline 和 FUSE redirect
baseline，并把它们纳入默认 `kvm-w1-build-baseline-macrobench` baseline 集合。

## 代码路径

- `tests/w1_oracle/namei_ext_w1_oracle.c`
  - 将 W1 baseline family 扩展为 `copy_tree`、`symlink_forest`、`bind_mount`、
    `projected_volume` 和 `fuse_redirect`。
  - 新增 W1 alias spec 收集和去重，复用 Redis/nginx build graph oracle entries，
    并跳过 toolchain helper branch。
  - `projected_volume` 为每个 alias parent 创建 `.namei_ext_projected/..data`
    generation，visible alias 指向当前 generation；update 切换到新 generation。
  - `fuse_redirect` 将每个 alias parent rename 为 backing directory，在原路径
    fork libfuse passthrough server；visible alias 解析到 shadow backing file，
    shadow names 从 readdir 中隐藏；update 写 backing shadow file。
  - FUSE teardown 使用 `umount2(MNT_DETACH)` 和 child process wait/terminate。
- `mk/kvm.mk`
  - `W1_BUILD_BASELINES` 默认值改为五类 baseline：
    `copy_tree symlink_forest bind_mount projected_volume fuse_redirect`。

这些 baseline 仍是外部 filesystem materialization comparator；它们不执行
`cgroup/namei_ext` policy，也不改变 namei_ext 的 VFS ownership model。

## 验证

Host build:

```text
make w1-oracle
```

KVM smoke for new baselines:

```text
make kvm-w1-build-baseline-macrobench \
  RUN_ID=20260616T-w1-build-fuse-baseline-smoke-v1 \
  W1_BUILD_BASELINE_MACROBENCH_SAMPLES=1 \
  W1_BUILD_BASELINES='projected_volume fuse_redirect'
```

KVM smoke for all default baselines:

```text
make kvm-w1-build-baseline-macrobench \
  RUN_ID=20260616T-w1-build-baseline-all-smoke-v1 \
  W1_BUILD_BASELINE_MACROBENCH_SAMPLES=1
```

KVM release input:

```text
make kvm-w1-build-baseline-macrobench \
  RUN_ID=20260616T-w1-build-baseline-release-sample-v2 \
  W1_BUILD_BASELINE_MACROBENCH_SAMPLES=20
```

Ledger:

```text
make eval-osdi-w1-build-workload-macrobench-ledger \
  RUN_ID=20260616T-eval-w1-build-workload-macrobench-ledger-release-v2 \
  EVAL_OSDI_W1_BUILD_POLICY_RUN_ID=20260616T-w1-build-macrobench-release-sample-v1 \
  EVAL_OSDI_W1_BUILD_BASELINE_RUN_ID=20260616T-w1-build-baseline-release-sample-v2
```

Hard gate, expected to fail because W1 thresholds remain negative:

```text
make eval-osdi-w1-build-workload-macrobench \
  RUN_ID=20260616T-eval-w1-build-workload-macrobench-hardgate-release-v2 \
  EVAL_OSDI_W1_BUILD_POLICY_RUN_ID=20260616T-w1-build-macrobench-release-sample-v1 \
  EVAL_OSDI_W1_BUILD_BASELINE_RUN_ID=20260616T-w1-build-baseline-release-sample-v2
```

## Raw results

Main release artifacts:

```text
results/phase1/20260616T-w1-build-baseline-release-sample-v2/w1-build-baseline-macrobench.jsonl
results/phase1/20260616T-w1-build-baseline-release-sample-v2/w1-build-baseline-macrobench-inputs.sha256
results/phase1/20260616T-w1-build-baseline-release-sample-v2/dmesg-w1-build-baseline-macrobench.log
```

Summary row:

```text
selected_baselines=copy_tree symlink_forest bind_mount projected_volume fuse_redirect
baseline_count=5
samples=20
setup_rows=100
update_rows=100
correctness_rows=100
pass=true
failures=0
policy_executed=false
kvm_validated=true
feature_equivalent_baseline=true
c2_supported=false
release_gate_pass=false
```

Per-baseline row counts:

```text
copy_tree: setup/update/correctness rows = 20/20/20
symlink_forest: setup/update/correctness rows = 20/20/20
bind_mount: setup/update/correctness rows = 20/20/20
projected_volume: setup/update/correctness rows = 20/20/20
fuse_redirect: setup/update/correctness rows = 20/20/20
```

FUSE-specific evidence:

```text
fuse_redirect setup rows record fuse_mounts=4
failure rows=0
dmesg BUG/WARNING/Oops/hung-task scan=0
```

Input hash checks:

```text
sha256sum -c results/phase1/20260616T-w1-build-baseline-release-sample-v2/w1-build-baseline-macrobench-inputs.sha256
sha256sum -c results/eval-osdi/paper/20260616T-eval-w1-build-workload-macrobench-ledger-release-v2/b3-macrobench/w1-build-workload-macrobench-inputs.sha256
```

Both checks passed.

## Ledger result

Ledger artifacts:

```text
results/eval-osdi/paper/20260616T-eval-w1-build-workload-macrobench-ledger-release-v2/b3-macrobench/w1-build-workload-macrobench.jsonl
results/eval-osdi/paper/20260616T-eval-w1-build-workload-macrobench-ledger-release-v2/b3-macrobench/w1-build-workload-macrobench-summary.md
results/eval-osdi/paper/20260616T-eval-w1-build-workload-macrobench-hardgate-release-v2/b3-macrobench/w1-build-workload-macrobench-hardgate-status.json
```

Key ledger fields:

```text
policy_release_input_pass=true
baseline_release_input_pass=true
copy_tree_baseline_pass=true
symlink_forest_baseline_pass=true
bind_mount_baseline_pass=true
projected_volume_baseline_pass=true
fuse_baseline_pass=true
full_feature_equivalent_baseline_pass=true
baseline_count_observed=5
storage_footprint_pass=false
setup_latency_threshold_pass=false
update_latency_threshold_pass=false
update_materialization_threshold_pass=false
threshold_pass=false
w1_c2_slice_supported=false
c2_supported=false
release_gate_pass=false
```

The hard gate wrote:

```text
status=4
pass=false
```

## Performance observations

The complete W1 baseline family makes the W1 negative result stronger, not
weaker. The fastest setup and update baselines remain below the proposed-system
means:

```text
policy_setup_ns_avg=66090011.6
best_baseline_setup_ns_avg=17324797.3
policy_update_ns_avg=52416038.25
best_baseline_update_ns_avg=37528990.95
policy_setup_objects_avg=14
min_baseline_setup_objects_avg=6
policy_setup_bytes_avg=457356
min_baseline_setup_bytes_avg=69298
```

Per-baseline means from the release input:

```text
copy_tree: setup_ns_avg=17324797.3, update_ns_avg=46789199
symlink_forest: setup_ns_avg=85935427.7, update_ns_avg=46438477.15
bind_mount: setup_ns_avg=57541966.95, update_ns_avg=37528990.95
projected_volume: setup_ns_avg=180179443.05, update_ns_avg=136251410
fuse_redirect: setup_ns_avg=306513512.25, update_ns_avg=42280826.95
```

## Conclusion

W1 no longer lacks projected-volume or FUSE baseline evidence. The complete
feature baseline family passes the modified-kernel KVM release run and the
ledger now reports `full_feature_equivalent_baseline_pass=true`.

W1 still does not support C2. The remaining W1 failures are storage footprint,
setup latency, update latency, and update materialization thresholds. The global
C2 ledger still needs W3/W4 workload setup/storage/update macrobench evidence,
but W1 itself should now be treated as a complete negative slice rather than a
partial baseline slice.

