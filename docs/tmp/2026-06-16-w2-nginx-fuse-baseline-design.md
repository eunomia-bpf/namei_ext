# W2 nginx FUSE baseline 设计记录

日期：2026-06-16

阶段：Phase 1 research/design documentation

## 动机

W2 nginx C2 comparison 已有 `namei_ext` proposed-system 20-sample KVM raw input，以及同
workload 的 `copy_tree`、`symlink_forest`、`bind_mount` 和 `projected_volume` baseline。
最新 v3 ledger 仍明确缺少 FUSE W2 baseline、storage footprint aggregation 和显式
C2 setup/storage/update 阈值。FUSE 是 reviewer 会期待的 user-space programmable
path-remapping baseline；没有同 workload FUSE baseline，C2 不能声称 feature-equivalent
baseline family 完整。

## 已调研代码路径

- `bench/workloads/namei_ext_baselines.c`：已有 external baseline 的最小 libfuse
  redirect filesystem，使用 `FUSE_USE_VERSION=26`、`fuse_main()`、`getattr/access/open/read/readdir`
  和 `attr_timeout=0,entry_timeout=0,negative_timeout=0`。
- `bench/workloads/Makefile`：已有 `FUSE_CFLAGS=-D_FILE_OFFSET_BITS=64 -I/usr/include/fuse`
  和 `FUSE_LIBS=-lfuse -pthread`。
- `configs/kernel/x86_64_phase1.config`：已有 `CONFIG_FUSE_FS=y`，KVM guest 不依赖
  module load。
- `tests/w1_oracle/namei_ext_w1_oracle.c`：W2 nginx baseline runner 已支持
  `copy_tree`、`symlink_forest`、`bind_mount` 和 `projected_volume`，并统一执行真实
  `nginx -t`、config/endpoint/cert/secret/poison probes、post-update `nginx -t` 和
  post-update probes。
- `tests/w1_oracle/Makefile`：当前 oracle binary 只链接 libbpf/libelf/zlib，尚未链接
  libfuse。

## 设计选择

FUSE baseline 不应直接把 mount 覆盖在已有 `prefix/conf` 上后继续用该目录作为 backing，
因为 mount 会遮住同目录 backing files，daemon 再按绝对路径读取 backing 会失败。

最小可验证布局为：

```text
prefix/
  conf/                  # FUSE mount point, visible to nginx
  .fuse-conf-backing/    # original prepared conf files, visible only to daemon/test oracle
  html/
  logs/
```

setup 流程：

1. 复用 `prepare_nginx_prefix()` 生成普通 nginx prefix。
2. 将 `prefix/conf` rename 为 `prefix/.fuse-conf-backing`。
3. 重新创建空 `prefix/conf` 作为 FUSE mount point。
4. fork FUSE daemon，mount 到 `prefix/conf`。
5. daemon 将以下 visible paths 映射到 backing：
   - `nginx.conf -> .fuse-conf-backing/nginx.test.conf`
   - `upstream.sock -> .fuse-conf-backing/upstream.local`
   - `server.crt -> .fuse-conf-backing/server.fake.crt`
   - `db.password -> .fuse-conf-backing/db.fake.pass`
   - `prod.token -> .fuse-conf-backing/poison.secret`
   - backing/prod/mime names 也映射到同名 backing 文件，供现有 correctness comparator
     检查 visible alias 与 backing/prod decoy 的内容关系。

update 流程：

FUSE mount 是 read-only view；source update 应写入 `.fuse-conf-backing`，而不是写入
`prefix/conf`。因此实现应把当前 `update_nginx_macro_fixture(prefix, sample, stats)`
拆出一个 `update_nginx_macro_fixture_dir(conf_dir, sample, stats)`，普通 baseline 传
`prefix/conf`，FUSE baseline 传 `.fuse-conf-backing`。FUSE baseline 本身不需要额外
baseline-side copy/update writes，post-update reads 由 daemon 读取新的 backing content。

cleanup 流程：

每个 sample 完成后对 `prefix/conf` 执行 `umount()`，必要时终止并 wait FUSE child。
cleanup failure 应计入 sample failure，不能静默忽略。

## 拒绝的替代方案

- 不复用 external baseline runner：它的 tree/tool workload 与 W2 nginx config/secret
  workload 不同，不能作为 W2 same-workload C2 baseline。
- 用 symlink forest 代替 FUSE：这不会测 user-space path-resolution crossing，也不能回应
  reviewer 对 FUSE baseline 的公平性要求。
- 把 FUSE baseline 放到单独 shell script：违反项目 Makefile-only 控制面约束。

## 验证计划

实现后必须通过：

```text
make w1-oracle
make kvm-w2-nginx-baseline-macrobench \
  RUN_ID=20260616T-w2-nginx-fuse-baseline-smoke-v1 \
  W2_NGINX_BASELINE_MACROBENCH_SAMPLES=2 \
  W2_NGINX_BASELINES=fuse_redirect
```

若 smoke 通过，再运行包含所有 baseline 的 20-sample release input：

```text
make kvm-w2-nginx-baseline-macrobench \
  RUN_ID=20260616T-w2-nginx-baseline-macrobench-release-sample-v4 \
  W2_NGINX_BASELINE_MACROBENCH_SAMPLES=20
```

随后刷新 W2 workload ledger/hard gate。即使 FUSE 通过，C2 仍不能自动升级；还需要
storage footprint aggregation 和显式 setup/storage/update 成功阈值。
