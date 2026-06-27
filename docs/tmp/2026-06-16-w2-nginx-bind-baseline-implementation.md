# W2 nginx bind-mount baseline 实现记录

日期：2026-06-16

阶段：Phase 1 implementation documentation

## 动机

W2 nginx 已有 `copy_tree` 和 `symlink_forest` 两类 materialized baseline。为了让 C2 的
同 workload baseline family 更接近真实系统替代方案，本轮补 `bind_mount`：把
config/endpoint/cert/secret/poison backing files 通过 Linux bind mount 暴露到 nginx
实际读取的 visible alias 路径。

这一步仍不是完整 C2。它只把 W2 baseline family 从 2 类推进到 3 类；仍缺 FUSE、
projected-volume 或等价 config/secret injection、storage footprint aggregation 和显式
C2 setup/storage/update 阈值。

## 修改文件

- `tests/w1_oracle/namei_ext_w1_oracle.c`
- `mk/kvm.mk`
- `mk/eval_osdi.mk`

## 实现内容

`tests/w1_oracle/namei_ext_w1_oracle.c` 新增 `bind_mount` baseline：

- setup 阶段为每个 visible alias 创建空目标文件；
- 用 `mount(src, dst, NULL, MS_BIND, NULL)` 把 backing file 绑定到 visible alias；
- setup row 记录 `bind_mounts`，每个 sample 为 5；
- update 阶段只更新 backing files，不执行额外 baseline copy，因为 bind alias 观察同一
  backing inode；
- correctness 阶段继续运行真实 `nginx -t`、config/endpoint/cert/secret/poison probes
  和 post-update probes；
- correctness row 写出前用 `umount2(..., MNT_DETACH)` 卸载所有 bind aliases；卸载失败计入
  sample failure，避免静默污染后续样本或结果目录。

`mk/kvm.mk` 将默认 `W2_NGINX_BASELINES` 从：

```text
copy_tree symlink_forest
```

扩展为：

```text
copy_tree symlink_forest bind_mount
```

`mk/eval_osdi.mk` 的 W2 workload ledger 新增：

- `bind_baseline_pass`
- `copy_symlink_bind_baselines_pass`

并把缺失 baseline 从 `bind/FUSE/projected-volume-equivalent` 缩小为
`FUSE/projected-volume-equivalent`。

## 验证

编译：

```text
make w1-oracle
```

通过。

KVM smoke：

```text
make kvm-w2-nginx-baseline-macrobench \
  RUN_ID=20260616T-w2-nginx-bind-baseline-smoke-v1 \
  W2_NGINX_BASELINE_MACROBENCH_SAMPLES=2 \
  W2_NGINX_BASELINES=bind_mount
```

通过。结果：

- setup rows：2
- update rows：2
- correctness rows：2
- summary：`baseline_count=1`、`samples=2`、`pass=true`、`failures=0`
- 每个 setup row：`bind_mounts=5`
- 每个 update row：`source_update_writes=3`、`baseline_update_writes=0`

KVM release input：

```text
make kvm-w2-nginx-baseline-macrobench \
  RUN_ID=20260616T-w2-nginx-baseline-macrobench-release-sample-v2 \
  W2_NGINX_BASELINE_MACROBENCH_SAMPLES=20
```

通过。结果：

- selected baselines：`copy_tree symlink_forest bind_mount`
- setup rows：60
- update rows：60
- correctness rows：60
- summary：`baseline_count=3`、`samples=20`、`pass=true`、`failures=0`、
  `policy_executed=false`、`kvm_validated=true`、`feature_equivalent_baseline=true`、
  `c2_supported=false`、`release_gate_pass=false`

Release-input setup 分布：

- `copy_tree`：20 rows，setup 8.40--10.48 ms，0 bind mounts，17 files
- `symlink_forest`：20 rows，setup 7.84--11.11 ms，0 bind mounts，12 files，5 symlinks
- `bind_mount`：20 rows，setup 7.04--11.34 ms，5 bind mounts，17 files

W2 ledger v2：

```text
make eval-osdi-w2-nginx-workload-macrobench-ledger \
  RUN_ID=20260616T-eval-w2-nginx-workload-macrobench-ledger-v2 \
  EVAL_OSDI_W2_NGINX_POLICY_RUN_ID=20260615T-w2-nginx-c2-macrobench-release-sample-v1 \
  EVAL_OSDI_W2_NGINX_BASELINE_RUN_ID=20260616T-w2-nginx-baseline-macrobench-release-sample-v2
```

通过。summary 为：

- `policy_release_input_pass=true`
- `baseline_release_input_pass=true`
- `copy_symlink_baselines_pass=true`
- `bind_baseline_pass=true`
- `copy_symlink_bind_baselines_pass=true`
- `full_feature_equivalent_baseline_pass=false`
- `storage_footprint_pass=false`
- `threshold_pass=false`
- `c2_supported=false`
- `release_gate_pass=false`

Hard gate：

```text
make eval-osdi-w2-nginx-workload-macrobench \
  RUN_ID=20260616T-eval-w2-nginx-workload-macrobench-hardgate-v2 \
  EVAL_OSDI_W2_NGINX_POLICY_RUN_ID=20260615T-w2-nginx-c2-macrobench-release-sample-v1 \
  EVAL_OSDI_W2_NGINX_BASELINE_RUN_ID=20260616T-w2-nginx-baseline-macrobench-release-sample-v2
```

按预期非零退出，因为 summary 仍没有 `release_gate_pass=true` 和 `c2_supported=true`。

## 判读

W2 现在有 proposed-system 20-sample KVM rows，以及 copy/symlink/bind 三类同 workload
baseline 20-sample rows。C2 仍然不能升级，因为还缺：

- FUSE redirect baseline；
- projected-volume 或等价 config/secret injection baseline；
- storage footprint aggregation；
- 显式 setup/storage/update 成功阈值；
- W1/W3/W4 对等 workload macrobench。

## 2026-06-16 追加：projected-volume v3 已补齐

后续 `docs/tmp/2026-06-16-w2-nginx-projected-volume-baseline-implementation.md` 已补上
`projected_volume` baseline。当前 canonical W2 feature-baseline run 是
`20260616T-w2-nginx-baseline-macrobench-release-sample-v3`，覆盖
`copy_tree symlink_forest bind_mount projected_volume` 四类 baseline，summary 为
`baseline_count=4`、`setup_rows=80`、`update_rows=80`、`correctness_rows=80`、
`pass=true`、`failures=0`。C2 仍不升级；剩余缺口是 FUSE baseline、storage footprint、
显式 C2 阈值和 W1/W3/W4 对等 macrobench。

## 2026-06-16 追加：FUSE v4 已补齐

后续 `docs/tmp/2026-06-16-w2-nginx-fuse-baseline-implementation.md` 已补上
`fuse_redirect` baseline。当前 canonical W2 feature-baseline run 是
`20260616T-w2-nginx-baseline-macrobench-release-sample-v4`，覆盖
`copy_tree symlink_forest bind_mount projected_volume fuse_redirect` 五类 baseline，
summary 为 `baseline_count=5`、`setup_rows=100`、`update_rows=100`、
`correctness_rows=100`、`pass=true`、`failures=0`。C2 仍不升级；剩余缺口是
storage footprint、显式 C2 阈值和 W1/W3/W4 对等 macrobench。
