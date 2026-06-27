# W1 build graph baseline release run

日期：2026-06-16

## 动机

前一轮 `kvm-w1-build-baseline-macrobench` 只完成了 `copy_tree`、`symlink_forest` 和
`bind_mount` 的 1-sample KVM smoke。它证明 runner 和三类 baseline plumbing 可运行，
但不能作为 C2 release input。为了让 W1 build graph 能进入同 workload
setup/storage/update ledger，需要把同一组真实 Redis/nginx trace-derived entries
提升到 20-sample KVM baseline release run。

## 命令

```text
make kvm-w1-build-baseline-macrobench \
  RUN_ID=20260616T-w1-build-baseline-release-sample-v1 \
  W1_BUILD_BASELINE_MACROBENCH_SAMPLES=20 \
  W1_BUILD_BASELINES='copy_tree symlink_forest bind_mount'
```

## 输入和执行路径

- workload source：Redis `7.2.14` 与 nginx `1.26.3` 真实源码构建/strace。
- entries：同 RUN_ID 下生成的 `w1-build-graph-oracle-entries.tsv`。
- runner：`tests/w1_oracle/namei_ext_w1_oracle.c`。
- KVM target：`mk/kvm.mk` 中的 `kvm-w1-build-baseline-macrobench` 和
  `__phase1_guest_w1_build_baseline_macrobench`。
- baseline family：`copy_tree`、`symlink_forest`、`bind_mount`。

## 结果

结果位于：

```text
results/phase1/20260616T-w1-build-baseline-release-sample-v1/w1-build-baseline-macrobench.jsonl
results/phase1/20260616T-w1-build-baseline-release-sample-v1/w1-build-baseline-macrobench-inputs.sha256
results/phase1/20260616T-w1-build-baseline-release-sample-v1/dmesg-w1-build-baseline-macrobench.log
```

summary row：

```text
baseline_count=3
samples=20
setup_rows=60
update_rows=60
correctness_rows=60
pass=true
failures=0
policy_executed=false
kvm_validated=true
feature_equivalent_baseline=true
c2_supported=false
release_gate_pass=false
```

这里的 `feature_equivalent_baseline=true` 只表示已实现的三类 baseline 各自通过了
per-baseline correctness oracle；不表示 W1 的完整 feature-equivalent baseline set 已覆盖。
完整 W1 ledger 仍使用 `full_feature_equivalent_baseline_pass=false` 记录
`projected_volume` 和 `fuse_redirect` 缺口。

host 侧 `sha256sum -c
results/phase1/20260616T-w1-build-baseline-release-sample-v1/w1-build-baseline-macrobench-inputs.sha256`
通过。

## 关键观测

setup 平均值：

- `copy_tree`: `18.33 ms`，`setup_objects_avg=6`，`bytes_copied_avg=69298`。
- `symlink_forest`: `79.19 ms`，`setup_objects_avg=20`，`bytes_copied_avg=388054`。
- `bind_mount`: `55.48 ms`，`setup_objects_avg=28`，`bind_mounts_avg=8`。

update 平均值：

- `copy_tree`: `48.84 ms`，`baseline_update_writes_avg=6`。
- `symlink_forest`: `46.22 ms`，`baseline_update_writes_avg=0`。
- `bind_mount`: `40.17 ms`，`baseline_update_writes_avg=0`。

这些数字说明 W1 baseline release input 已经补齐，但它不是正向性能证据。当前最快
setup baseline 是 `copy_tree`，最快 update baseline 是 `bind_mount`，都优于 W1
proposed-system release input 的均值。

## 失败历史和修复状态

早先 smoke `20260616T-w1-build-baseline-smoke-v1` 在 `bind_mount` 上因重复
`stdio.h` alias 触发 `EBUSY`。本次 20-sample release run 覆盖了 `bind_mount`
20 个样本且全部通过，说明 `dir+visible` 去重修复在该 workload slice 上稳定。

## 结论

该 run 把 W1 build graph 的 `copy_tree`、`symlink_forest` 和 `bind_mount`
baseline 从 smoke 提升为 release input。它仍不能支持 C2，因为 W1 还缺
`projected_volume`、`fuse_redirect`，并且当前三类 baseline 已显示 proposed-system
在 setup/storage/update 上没有优势。
