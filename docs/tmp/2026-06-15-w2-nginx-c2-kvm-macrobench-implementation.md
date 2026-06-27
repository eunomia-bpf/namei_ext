# W2 nginx C2 KVM macrobench PoC 实现记录

日期：2026-06-15

## 动机

此前 C2 release-sample ledger 已经证明 `namei_ext` 内部 microbench 的 setup/update
raw rows 和 external baseline release rows 都能被 fail-fast gate 读取；workload-derived
ledger 也能机械化 W1--W4 的 8 个 workload row。但这些仍然不是同一个 workload 在修改内核
KVM 内的 per-sample setup/update macrobenchmark，因此不能支持 C2。

本步骤实现第一个真实 workload PoC：W2 nginx fixture。它复用已经存在的 nginx fixture
correctness oracle，在修改内核 KVM guest 内对每个 sample 记录 materialization setup、
source backing update 和 app-level correctness。

## 代码改动

- `tests/w1_oracle/namei_ext_w1_oracle.c`
  - 新增 `struct nginx_macro_stats`，记录 setup/update 原始计数：
    `created_dirs`、`created_files`、`bytes_written`、`bytes_copied`、
    `source_update_writes`、`policy_update_writes`、`update_bytes_written` 和
    `update_bytes_copied`。
  - 新增 `monotonic_ns()`、`mkdir_counted()`、`write_text_file_counted()` 和
    `copy_file_counted()`。
  - 扩展 `prepare_nginx_prefix()`，可选写入 setup 计数；旧
    `--sandbox-nginx-smoke` 传 `NULL`，保持原 real-app health oracle 输出不变。
  - 新增 `--sandbox-nginx-macrobench` mode：

```text
namei_ext_w1_oracle --sandbox-nginx-macrobench OUT_JSONL CGROUP_MOUNT WORK_DIR SAMPLES NGINX_BIN FIXTURE_CONF ENDPOINT_FIXTURE MIME_TYPES SANDBOX_POLICY
```

  - 每个 sample 独立执行：
    - materialize nginx prefix；
    - 写 `w2-nginx-macrobench-setup` row；
    - 验证 pre-attach `nginx -t` 必须失败；
    - load/attach `sandbox_fixture_view.bpf.c`；
    - 验证 attached `nginx -t`、config/endpoint/cert/secret/poison probes；
    - 更新 `upstream.local`、`server.fake.crt`、`db.fake.pass`；
    - 写 `w2-nginx-macrobench-update` row；
    - 验证 post-update `nginx -t` 和 post-update endpoint/cert/secret probes；
    - detach policy；
    - 写 `w2-nginx-macrobench-correctness` row。

- `mk/kvm.mk`
  - 新增变量：
    - `W2_NGINX_MACROBENCH_JSON`
    - `W2_NGINX_MACROBENCH_INPUTS`
    - `W2_NGINX_MACROBENCH_WORK_DIR`
    - `W2_NGINX_MACROBENCH_SAMPLES ?= 2`
  - 新增 target：

```text
make kvm-w2-nginx-macrobench
```

  - 新增 guest target `__phase1_guest_w2_nginx_macrobench`，负责 mount bpf/debugfs/cgroup、
    固定输入 hash、调用 runner、用 `jq` 检查 setup/update/correctness/summary rows。

- `Makefile`
  - `make help` 新增 `kvm-w2-nginx-macrobench` 说明。

## 结果格式

所有 W2 macrobench row 都显式标记：

- `schema="namei_ext.eval_osdi.w2_nginx_macrobench.v1"`
- `result_level="kvm_workload_setup_update_poc"`
- `run_environment="kvm"`
- `workload="w2-nginx-fixture"`
- `policy_family="sandbox_fixture_view.bpf.c"`
- `c2_supported=false`
- `release_gate_pass=false`

这一步是 KVM workload setup/update PoC，不是 C2 release gate。

## 验证命令

编译 runner：

```text
make w1-oracle
```

KVM smoke：

```text
make kvm-w2-nginx-macrobench RUN_ID=20260615T-w2-nginx-c2-macrobench-smoke-v1 W2_NGINX_MACROBENCH_SAMPLES=2
```

结果路径：

```text
results/phase1/20260615T-w2-nginx-c2-macrobench-smoke-v1/w2-nginx-macrobench.jsonl
results/phase1/20260615T-w2-nginx-c2-macrobench-smoke-v1/w2-nginx-macrobench-inputs.sha256
results/phase1/20260615T-w2-nginx-c2-macrobench-smoke-v1/dmesg-w2-nginx-macrobench.log
```

## 验证结果

KVM run 通过。JSONL 中有：

- `w2-nginx-macrobench-setup`：2 rows；
- `w2-nginx-macrobench-update`：2 rows；
- `w2-nginx-macrobench-correctness`：2 rows；
- `w2-nginx-macrobench-summary`：1 row。

summary：

```text
samples=2
setup_rows=2
update_rows=2
correctness_rows=2
pass=true
failures=0
policy_executed=true
kvm_validated=true
c2_supported=false
release_gate_pass=false
```

setup rows：

```text
sample 0: setup_ns=11799476, created_dirs=5, created_files=12, bytes_written=293, bytes_copied=5638
sample 1: setup_ns=8402519, created_dirs=5, created_files=12, bytes_written=293, bytes_copied=5638
```

update rows：

```text
sample 0: update_ns=12160, source_update_writes=3, policy_update_writes=0, update_bytes_written=149
sample 1: update_ns=15237, source_update_writes=3, policy_update_writes=0, update_bytes_written=149
```

correctness rows 均为 pass，且全部满足：

```text
pre_attach_nginx_rejected=true
attached_nginx_test_pass=true
post_update_nginx_test_pass=true
config_probe_pass=true
endpoint_probe_pass=true
cert_probe_pass=true
secret_probe_pass=true
poison_probe_pass=true
post_update_endpoint_probe_pass=true
post_update_cert_probe_pass=true
post_update_secret_probe_pass=true
policy_executed=true
kvm_validated=true
```

## 不能升级 C2 的原因

这一步仍不能支持 C2：

- 只有 2-sample smoke，不是 release repetition；
- 只有 W2 nginx fixture，不覆盖 W1/W3/W4；
- 没有同 workload feature-equivalent baseline；
- 没有 setup/storage/update 成功阈值；
- update 只覆盖 source backing 文件更新，`policy_update_writes=0`；
- 这是 PoC raw evidence，不是 paper-grade comparison。

后续若要进入 C2，应该把该 target 扩展为 release target：

- `W2_NGINX_MACROBENCH_SAMPLES>=20`；
- 增加 copy/symlink/bind/projected-volume/OverlayFS/FUSE 等同 workload baseline；
- 给 setup object count、storage footprint、source update cost、policy update cost 设定阈值；
- 将 `eval-osdi-workload-macrobench-ledger` 从 derived inventory 提升为读取 KVM raw rows；
- 仍然要求 correctness oracle 先通过，性能解释后置。

