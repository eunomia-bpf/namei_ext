# W2 nginx projected-volume baseline 实现记录

日期：2026-06-16

阶段：Phase 1 implementation documentation

## 动机

W2 nginx C2 comparison 已覆盖 `copy_tree`、`symlink_forest` 和 `bind_mount`，但仍把
projected-volume-equivalent baseline 记为缺失。Kubernetes projected volume/Secret 是
真实生产配置注入模式；只用普通 symlink forest 不能表达 Kubernetes atomic writer 的
generation 更新语义。因此本步骤补一个最小 `projected_volume` baseline，用真实 nginx
fixture 和现有 KVM macrobench oracle 验证。

## 设计

`projected_volume` baseline 在每个 sample 的 `conf/` 下创建：

```text
conf/.projected/..gen0/<alias>
conf/.projected/..data -> ..gen0
conf/<alias> -> .projected/..data/<alias>
```

update 阶段写入 `..gen1`，复制当前 backing payload，并原子替换 `..data` symlink：

```text
conf/.projected/..gen1/<alias>
conf/.projected/..data_tmp -> ..gen1
rename(..data_tmp, ..data)
```

这与已有 baseline 的差异：

- `copy_tree`：visible alias 本身是独立文件，update 需要逐 alias 覆盖；
- `symlink_forest`：visible alias 直接指向 backing 文件，update 由 backing 原位变化体现；
- `bind_mount`：visible alias 是 file bind mount，update 由同一 backing inode 体现；
- `projected_volume`：visible alias 指向 generation payload，update 通过新 generation 和
  atomic symlink swap 体现。

## 修改文件

- `tests/w1_oracle/namei_ext_w1_oracle.c`
- `mk/kvm.mk`
- `mk/eval_osdi.mk`

## 实现内容

`namei_ext_w1_oracle.c` 新增：

- baseline name：`projected_volume`；
- generation helper：`prepare_nginx_projected_generation()`；
- setup helper：`materialize_nginx_projected_volume()`；
- update helper：`update_nginx_projected_volume()`；
- `all` baseline count 从 3 增加到 4；
- known baseline 顺序扩展为 `copy_tree symlink_forest bind_mount projected_volume`。

`mk/kvm.mk` 默认 `W2_NGINX_BASELINES` 扩展为：

```text
copy_tree symlink_forest bind_mount projected_volume
```

`mk/eval_osdi.mk` 的 W2 ledger 新增：

- `projected_volume_baseline_pass`
- `copy_symlink_bind_projected_baselines_pass`

并把 `required_baseline_families` 改为：

```text
copy_tree
symlink_forest
bind_mount
projected_volume
fuse_redirect
```

因此 projected baseline 通过后，C2 缺口应缩小为 FUSE baseline、storage footprint
aggregation 和显式 setup/storage/update 阈值。

## 验证计划

必须通过：

```text
make w1-oracle
make kvm-w2-nginx-baseline-macrobench \
  RUN_ID=20260616T-w2-nginx-projected-baseline-smoke-v1 \
  W2_NGINX_BASELINE_MACROBENCH_SAMPLES=2 \
  W2_NGINX_BASELINES=projected_volume
```

若 smoke 通过，再运行 20-sample release-input：

```text
make kvm-w2-nginx-baseline-macrobench \
  RUN_ID=20260616T-w2-nginx-baseline-macrobench-release-sample-v3 \
  W2_NGINX_BASELINE_MACROBENCH_SAMPLES=20
```

随后刷新 W2 workload ledger/hard gate。

## 当前判读

本步骤只补 projected-volume-equivalent baseline。它不改变 C2 verdict；即使
`projected_volume_baseline_pass=true`，C2 仍需要 FUSE baseline、storage footprint 和显式
阈值。

## 验证结果

`make w1-oracle` 通过，确认 host-side oracle runner 仍能构建并运行。

KVM projected-volume smoke：

```text
make kvm-w2-nginx-baseline-macrobench \
  RUN_ID=20260616T-w2-nginx-projected-baseline-smoke-v1 \
  W2_NGINX_BASELINE_MACROBENCH_SAMPLES=2 \
  W2_NGINX_BASELINES=projected_volume
```

通过。该 run 只选择 `projected_volume` baseline，在修改内核 KVM guest 中完成
setup/update/correctness path，summary `pass=true`、`failures=0`、
`policy_executed=false`、`kvm_validated=true`。

20-sample release-input：

```text
make kvm-w2-nginx-baseline-macrobench \
  RUN_ID=20260616T-w2-nginx-baseline-macrobench-release-sample-v3 \
  W2_NGINX_BASELINE_MACROBENCH_SAMPLES=20
```

通过。raw result：

```text
results/phase1/20260616T-w2-nginx-baseline-macrobench-release-sample-v3/w2-nginx-baseline-macrobench.jsonl
```

summary 为 `selected_baselines="copy_tree symlink_forest bind_mount projected_volume"`、
`baseline_count=4`、`samples=20`、`setup_rows=80`、`update_rows=80`、
`correctness_rows=80`、`pass=true`、`failures=0`、`policy_executed=false`、
`kvm_validated=true`、`feature_equivalent_baseline=true`、`c2_supported=false`、
`release_gate_pass=false`。

按 baseline 分解：

- `copy_tree`：20 setup/update/correctness rows；setup 6.97--8.32 ms；
  update 15.4--58.7 us；setup 创建 5 dirs、17 files、0 symlinks。
- `symlink_forest`：20 setup/update/correctness rows；setup 6.95--10.05 ms；
  update 7.70--29.96 us；setup 创建 5 dirs、12 files、5 symlinks。
- `bind_mount`：20 setup/update/correctness rows；setup 7.24--12.55 ms；
  update 7.07--18.40 us；setup 创建 5 dirs、17 files、5 file bind mounts。
- `projected_volume`：20 setup/update/correctness rows；setup 9.34--14.02 ms；
  update 37.8--82.1 us；setup 创建 7 dirs、17 files、6 symlinks，update 写入
  6 个 baseline-side payload/symlink 操作并复制 429 bytes。

W2 workload ledger：

```text
make eval-osdi-w2-nginx-workload-macrobench-ledger \
  RUN_ID=20260616T-eval-w2-nginx-workload-macrobench-ledger-v3 \
  EVAL_OSDI_W2_NGINX_POLICY_RUN_ID=20260615T-w2-nginx-c2-macrobench-release-sample-v1 \
  EVAL_OSDI_W2_NGINX_BASELINE_RUN_ID=20260616T-w2-nginx-baseline-macrobench-release-sample-v3
```

通过。summary 为 `policy_release_input_pass=true`、`baseline_release_input_pass=true`、
`copy_symlink_baselines_pass=true`、`bind_baseline_pass=true`、
`projected_volume_baseline_pass=true`、`copy_symlink_bind_projected_baselines_pass=true`、
`baseline_count_observed=4`，但 `full_feature_equivalent_baseline_pass=false`、
`storage_footprint_pass=false`、`threshold_pass=false`、`c2_supported=false`、
`release_gate_pass=false`。`missing_evidence` 缩小为 FUSE W2 baseline、storage
footprint aggregation 和 C2 setup/storage/update success thresholds。

expected-fail hard gate：

```text
make eval-osdi-w2-nginx-workload-macrobench \
  RUN_ID=20260616T-eval-w2-nginx-workload-macrobench-hardgate-v3 \
  EVAL_OSDI_W2_NGINX_POLICY_RUN_ID=20260615T-w2-nginx-c2-macrobench-release-sample-v1 \
  EVAL_OSDI_W2_NGINX_BASELINE_RUN_ID=20260616T-w2-nginx-baseline-macrobench-release-sample-v3
```

按预期非零退出，因为没有 summary row 同时满足 `release_gate_pass=true` 和
`c2_supported=true`。这证明 v3 projected-volume evidence 没有被误升级为 C2 支持证据。

## 2026-06-16 追加：FUSE baseline 后的 v4 evidence

后续 `docs/tmp/2026-06-16-w2-nginx-fuse-baseline-implementation.md` 已把同一 target
扩展到默认 `copy_tree symlink_forest bind_mount projected_volume fuse_redirect`，并生成：

```text
results/phase1/20260616T-w2-nginx-baseline-macrobench-release-sample-v4/w2-nginx-baseline-macrobench.jsonl
results/eval-osdi/paper/20260616T-eval-w2-nginx-workload-macrobench-ledger-v4/b3-macrobench/w2-nginx-workload-macrobench.jsonl
```

v4 ledger summary 中 `fuse_baseline_pass=true`、`all_feature_baselines_pass=true`、
`full_feature_equivalent_baseline_pass=true`；但 `storage_footprint_pass=false`、
`threshold_pass=false`、`c2_supported=false`、`release_gate_pass=false`。因此 v4 已补齐
当前 W2 feature-baseline family input，但仍不是 C2 支持证据。
