# W2 nginx C2 KVM macrobench release-sample run 记录

日期：2026-06-15

## 目的

`kvm-w2-nginx-macrobench` 的 2-sample smoke 已证明 W2 nginx fixture 的真实 KVM
setup/update raw-row path 可以运行。本步骤把同一 target 提升到 20 samples，验证 release
repetition 输入是否稳定。

这仍不是 C2 支持证据，因为还没有同 workload feature-equivalent baseline，也没有显式
setup/storage/update 成功阈值。

## 命令

```text
make kvm-w2-nginx-macrobench RUN_ID=20260615T-w2-nginx-c2-macrobench-release-sample-v1 W2_NGINX_MACROBENCH_SAMPLES=20
```

## 结果路径

```text
results/phase1/20260615T-w2-nginx-c2-macrobench-release-sample-v1/w2-nginx-macrobench.jsonl
results/phase1/20260615T-w2-nginx-c2-macrobench-release-sample-v1/w2-nginx-macrobench-inputs.sha256
results/phase1/20260615T-w2-nginx-c2-macrobench-release-sample-v1/dmesg-w2-nginx-macrobench.log
```

## 结果摘要

KVM run 通过。JSONL row count：

```text
w2-nginx-macrobench-setup: 20
w2-nginx-macrobench-update: 20
w2-nginx-macrobench-correctness: 20
w2-nginx-macrobench-summary: 1
```

summary：

```text
samples=20
setup_rows=20
update_rows=20
correctness_rows=20
pass=true
failures=0
policy_executed=true
kvm_validated=true
c2_supported=false
release_gate_pass=false
```

setup row 分布：

```text
min_setup_ns=6935363
max_setup_ns=9311575
created_dirs=5
created_files=12
bytes_written=293
bytes_copied=5638
```

update row 分布：

```text
min_update_ns=10829
max_update_ns=32387
source_update_writes=3
policy_update_writes=0
update_bytes_written in {149,152}
```

correctness gate：

```text
所有 20 个 samples 均满足：
pre_attach_nginx_rejected=true
attached_nginx_test_pass=true
post_update_nginx_test_pass=true
post_update_endpoint_probe_pass=true
post_update_cert_probe_pass=true
post_update_secret_probe_pass=true
```

## 解释

该 run 解决了 W2 nginx fixture 的 release repetition input 问题：同一真实 workload 在修改内核
KVM 内有 20 个 setup/update/correctness samples。

它仍不能支持 C2：

- 缺同 workload copy/symlink/bind/projected-volume/OverlayFS/FUSE baseline；
- 缺 setup object count、storage footprint、source update cost、policy update cost 的阈值；
- 只覆盖 W2 nginx fixture，不覆盖 W1/W3/W4；
- `policy_update_writes=0`，只测 source backing 更新；
- row schema 仍显式记录 `c2_supported=false` 和 `release_gate_pass=false`。

下一步应让 `eval-osdi-workload-macrobench-ledger` 读取该 20-sample root，并补至少一个同
workload feature-equivalent baseline，否则 C2 只能写成 input/plumbing progress。

