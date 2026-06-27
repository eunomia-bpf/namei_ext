# W2 nginx FUSE baseline 实现记录

日期：2026-06-16

阶段：Phase 1 implementation documentation

## 动机

`docs/tmp/2026-06-16-w2-nginx-fuse-baseline-design.md` 确认 W2 nginx C2 comparison 仍缺
same-workload FUSE baseline。没有 FUSE，`copy_tree`、`symlink_forest`、`bind_mount` 和
`projected_volume` 只能覆盖物化和 kernel mount 风格 baseline，不能覆盖 reviewer 期望的
user-space programmable remap baseline。

## 修改文件

- `tests/w1_oracle/namei_ext_w1_oracle.c`
- `tests/w1_oracle/Makefile`
- `mk/kvm.mk`
- `mk/eval_osdi.mk`

## 实现内容

`tests/w1_oracle/namei_ext_w1_oracle.c` 新增 `fuse_redirect` W2 baseline：

- oracle binary 增加 `FUSE_USE_VERSION=26` 和 libfuse headers；
- `struct nginx_macro_stats` 增加 `fuse_mounts`，setup JSON 不再把 `fuse_mounts` 硬编码为 0；
- setup 先复用 `prepare_nginx_prefix()`，再把 `prefix/conf` rename 到
  `prefix/.fuse-conf-backing`，重新创建 `prefix/conf` 作为 FUSE mount point；
- FUSE daemon 在 `prefix/conf` 提供只读 view，映射：
  `nginx.conf -> nginx.test.conf`、`upstream.sock -> upstream.local`、
  `server.crt -> server.fake.crt`、`db.password -> db.fake.pass`、
  `prod.token -> poison.secret`，并允许现有 comparator 读取 backing/prod/mime names；
- update 阶段为 FUSE 拆出 `update_nginx_macro_fixture_dir()`，把 source update 写入
  `.fuse-conf-backing`，post-update `nginx -t` 和 probes 通过 FUSE 读取新 content；
- cleanup 对每个 FUSE sample 执行 `umount(prefix/conf)` 并 wait/terminate FUSE child；
  cleanup failure 计入 sample failure。

`tests/w1_oracle/Makefile` 增加：

```text
FUSE_CFLAGS ?= -D_FILE_OFFSET_BITS=64 -I/usr/include/fuse
FUSE_LIBS ?= -lfuse -pthread
```

`mk/kvm.mk` 默认 `W2_NGINX_BASELINES` 扩展为：

```text
copy_tree symlink_forest bind_mount projected_volume fuse_redirect
```

`mk/eval_osdi.mk` 的 W2 workload ledger 新增：

- `fuse_baseline_pass`
- `all_feature_baselines_pass`

当 FUSE 存在时，`missing_evidence` 不再列出 `FUSE W2 baseline`；但
`storage_footprint_pass=false` 和 `threshold_pass=false` 仍使 `c2_supported=false`。

## 验证

本地 build：

```text
make w1-oracle
```

通过，`namei_ext_w1_oracle` 成功链接 `-lfuse -pthread`。

FUSE-only KVM smoke：

```text
make kvm-w2-nginx-baseline-macrobench \
  RUN_ID=20260616T-w2-nginx-fuse-baseline-smoke-v1 \
  W2_NGINX_BASELINE_MACROBENCH_SAMPLES=2 \
  W2_NGINX_BASELINES=fuse_redirect
```

通过。raw result：

```text
results/phase1/20260616T-w2-nginx-fuse-baseline-smoke-v1/w2-nginx-baseline-macrobench.jsonl
```

summary 为 `baseline_count=1`、`samples=2`、`setup_rows=2`、`update_rows=2`、
`correctness_rows=2`、`pass=true`、`failures=0`。每个 setup row 记录
`fuse_mounts=1`，setup 约 58.98--59.39 ms；每个 update row 记录
`source_update_writes=3`、`baseline_update_writes=0`。

五类 baseline release-input：

```text
make kvm-w2-nginx-baseline-macrobench \
  RUN_ID=20260616T-w2-nginx-baseline-macrobench-release-sample-v4 \
  W2_NGINX_BASELINE_MACROBENCH_SAMPLES=20
```

通过。raw result：

```text
results/phase1/20260616T-w2-nginx-baseline-macrobench-release-sample-v4/w2-nginx-baseline-macrobench.jsonl
```

summary 为 `selected_baselines="copy_tree symlink_forest bind_mount projected_volume fuse_redirect"`、
`baseline_count=5`、`samples=20`、`setup_rows=100`、`update_rows=100`、
`correctness_rows=100`、`pass=true`、`failures=0`、`policy_executed=false`、
`kvm_validated=true`、`feature_equivalent_baseline=true`、`c2_supported=false`、
`release_gate_pass=false`。

per-baseline setup rows：

- `copy_tree`：20 rows，setup 8.90--12.47 ms，5 dirs、17 files、0 symlinks。
- `symlink_forest`：20 rows，setup 8.75--13.45 ms，5 dirs、12 files、5 symlinks。
- `bind_mount`：20 rows，setup 9.60--14.27 ms，5 dirs、17 files、5 bind mounts。
- `projected_volume`：20 rows，setup 6.13--13.52 ms，7 dirs、17 files、6 symlinks。
- `fuse_redirect`：20 rows，setup 58.50--64.18 ms，6 dirs、12 files、1 FUSE mount。

per-baseline update rows：

- `copy_tree`：20 rows，update 17.1--48.9 us，3 baseline writes。
- `symlink_forest`：20 rows，update 10.4--30.1 us，0 baseline writes。
- `bind_mount`：20 rows，update 7.86--29.9 us，0 baseline writes。
- `projected_volume`：20 rows，update 38.2--231.2 us，6 baseline writes。
- `fuse_redirect`：20 rows，update 11.3--44.9 us，0 baseline writes。

## 当前判读

W2 same-workload feature baseline family 现在覆盖 copy、symlink、bind、projected-volume
和 FUSE 五类。C2 仍不能升级，因为 storage footprint aggregation 和显式
setup/storage/update 成功阈值还没有实现；W1/W3/W4 也没有对等 workload macrobench。

## 2026-06-16 追加：v5 storage/threshold 后的状态

后续 `docs/tmp/2026-06-16-w2-nginx-storage-threshold-implementation.md` 已在同一组
W2 proposed-system 与五类 feature baseline raw rows 上补齐 storage footprint
aggregation 和显式 setup/update/materialization 阈值。v5 ledger
`results/eval-osdi/paper/20260616T-eval-w2-nginx-workload-macrobench-ledger-v5/b3-macrobench/w2-nginx-workload-macrobench.jsonl`
中 `storage_footprint_pass=true`、`threshold_pass=true`、`w2_c2_slice_supported=true`。
因此本文件上一段的 storage/threshold 缺口只描述 FUSE baseline 刚完成时的 v4 状态；
当前全局 C2 blocker 已缩小为 W1/W3/W4 对等 workload macrobench。
