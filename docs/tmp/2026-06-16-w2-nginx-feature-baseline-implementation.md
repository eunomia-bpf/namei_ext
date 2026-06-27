# W2 nginx feature-equivalent baseline 实现记录

日期：2026-06-16

阶段：Phase 1 implementation documentation

## 动机

W2 nginx 已有 `namei_ext` 侧 KVM setup/update macrobench，但 C2 仍缺同 workload 的
feature-equivalent baseline。本实现补第一批最小 baseline：`copy_tree` 和
`symlink_forest`。它们用于比较“预先把 fixture view 物化成真实路径”的成本，不代表完整
projected-volume、bind mount 或 FUSE baseline。

## 修改文件

- `tests/w1_oracle/namei_ext_w1_oracle.c`
- `mk/kvm.mk`
- `Makefile`

## 实现内容

`tests/w1_oracle/namei_ext_w1_oracle.c` 新增 mode：

```text
--sandbox-nginx-baseline-macrobench OUT_JSONL WORK_DIR SAMPLES NGINX_BIN FIXTURE_CONF ENDPOINT_FIXTURE MIME_TYPES BASELINES
```

新增逻辑：

- `copy_tree` setup：把 `nginx.test.conf`、`upstream.local`、`server.fake.crt`、
  `db.fake.pass`、`poison.secret` 复制成真实可见 alias：
  `nginx.conf`、`upstream.sock`、`server.crt`、`db.password`、`prod.token`。
- `symlink_forest` setup：为相同 alias 创建同目录 symlink。
- update：先更新 source backing 中的 endpoint/cert/secret；`copy_tree` 再复制到 alias，
  `symlink_forest` 不需要额外 baseline 写。
- correctness：每个 sample 都运行真实 `nginx -t`，并检查 config、endpoint、cert、
  secret、poison probes；update 后再次运行 `nginx -t` 和 post-update probes。

`mk/kvm.mk` 新增：

- `W2_NGINX_BASELINE_MACROBENCH_JSON`
- `W2_NGINX_BASELINE_MACROBENCH_INPUTS`
- `W2_NGINX_BASELINE_MACROBENCH_WORK_DIR`
- `W2_NGINX_BASELINE_MACROBENCH_SAMPLES`
- `W2_NGINX_BASELINES`
- `kvm-w2-nginx-baseline-macrobench`
- `__phase1_guest_w2_nginx_baseline_macrobench`

`Makefile` help 新增该 target。

## 输出

结果文件：

```text
results/phase1/<run-id>/w2-nginx-baseline-macrobench.jsonl
```

行类型：

- `w2-nginx-baseline-setup`
- `w2-nginx-baseline-update`
- `w2-nginx-baseline-correctness`
- `w2-nginx-baseline-summary`

summary 明确记录：

- `feature_equivalent_baseline=true`
- `policy_executed=false`
- `kvm_validated=true`
- `c2_supported=false`
- `release_gate_pass=false`

## 验证

编译：

```text
make w1-oracle
```

通过。

KVM smoke：

```text
make kvm-w2-nginx-baseline-macrobench \
  RUN_ID=20260616T-w2-nginx-baseline-macrobench-smoke-v1 \
  W2_NGINX_BASELINE_MACROBENCH_SAMPLES=2
```

通过。结果：

- 2 个 baselines：`copy_tree symlink_forest`
- setup rows：4
- update rows：4
- correctness rows：4
- summary：`pass=true`、`failures=0`、`c2_supported=false`、
  `release_gate_pass=false`

KVM release-input：

```text
make kvm-w2-nginx-baseline-macrobench \
  RUN_ID=20260616T-w2-nginx-baseline-macrobench-release-sample-v1 \
  W2_NGINX_BASELINE_MACROBENCH_SAMPLES=20
```

通过。结果：

- setup rows：40
- update rows：40
- correctness rows：40
- summary：`baseline_count=2`、`samples=20`、`pass=true`、`failures=0`、
  `policy_executed=false`、`kvm_validated=true`、`feature_equivalent_baseline=true`、
  `c2_supported=false`、`release_gate_pass=false`
- invalid pass row count：0
- input hash 校验通过：
  `sha256sum -c results/phase1/20260616T-w2-nginx-baseline-macrobench-release-sample-v1/w2-nginx-baseline-macrobench-inputs.sha256`

Release-input 分布：

- `copy_tree` setup：7.90--13.83 ms
- `symlink_forest` setup：9.70--12.64 ms
- `copy_tree` update：15.5--91.4 us
- `symlink_forest` update：7.65--26.2 us
- `copy_tree` setup objects：5 dirs、17 files、0 symlinks、293 bytes written、
  6022 bytes copied
- `symlink_forest` setup objects：5 dirs、12 files、5 symlinks、293 bytes written、
  5638 bytes copied
- `copy_tree` update writes：3 source writes、3 baseline writes、149 bytes written、
  149 bytes copied
- `symlink_forest` update writes：3 source writes、0 baseline writes、149 bytes written、
  0 bytes copied

## 判读

这一步把 W2 从“只有 `namei_ext` 侧 setup/update raw input”推进到“有同 workload 的
copy/symlink materialization baseline raw input”。它仍不能支持 C2，因为还缺：

- projected-volume 或 equivalent config/secret injection baseline；
- bind mount / FUSE baseline；
- storage footprint 汇总；
- 显式 C2 阈值；
- W1/W3/W4 对等 workload macrobench。

后续 `docs/tmp/2026-06-16-w2-nginx-workload-ledger-implementation.md` 已把 W2
proposed-system rows 和 baseline rows 合并成 claim-level ledger，并保留
`c2_supported=false` 的 expected-fail hard gate。

## 2026-06-16 追加：bind baseline v2

这份记录描述的是第一版 `copy_tree`/`symlink_forest` baseline。后续
`docs/tmp/2026-06-16-w2-nginx-bind-baseline-implementation.md` 已把同一 target 扩展到
默认 `copy_tree symlink_forest bind_mount`，canonical release-sample run 变为
`20260616T-w2-nginx-baseline-macrobench-release-sample-v2`。v2 覆盖三类 baseline，
summary 为 `baseline_count=3`、`setup_rows=60`、`update_rows=60`、
`correctness_rows=60`、`pass=true`、`failures=0`。

因此后续文档和 claim ledger 应以 v2 为当前 W2 feature-baseline input；本文件保留为
copy/symlink 第一阶段实现历史。

## 2026-06-16 追加：projected-volume v3

后续 `docs/tmp/2026-06-16-w2-nginx-projected-volume-baseline-implementation.md` 已把同一
target 扩展到默认 `copy_tree symlink_forest bind_mount projected_volume`，canonical
release-sample run 变为
`20260616T-w2-nginx-baseline-macrobench-release-sample-v3`。v3 覆盖四类 baseline，
summary 为 `baseline_count=4`、`setup_rows=80`、`update_rows=80`、
`correctness_rows=80`、`pass=true`、`failures=0`。

因此后续文档和 claim ledger 应以 v3 为当前 W2 feature-baseline input；本文件继续保留为
copy/symlink 第一阶段实现历史。

## 2026-06-16 追加：FUSE v4

后续 `docs/tmp/2026-06-16-w2-nginx-fuse-baseline-implementation.md` 已把同一 target
扩展到默认 `copy_tree symlink_forest bind_mount projected_volume fuse_redirect`，
canonical release-sample run 变为
`20260616T-w2-nginx-baseline-macrobench-release-sample-v4`。v4 覆盖五类 baseline，
summary 为 `baseline_count=5`、`setup_rows=100`、`update_rows=100`、
`correctness_rows=100`、`pass=true`、`failures=0`。

因此后续文档和 claim ledger 应以 v4 为当前 W2 feature-baseline input；本文件继续保留为
copy/symlink 第一阶段实现历史。
