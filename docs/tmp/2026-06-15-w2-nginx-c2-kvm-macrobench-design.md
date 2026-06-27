# W2 nginx C2 KVM macrobench PoC 设计记录

日期：2026-06-15

## 背景

C2 release-sample ledger 已经证明 `namei_ext` 自身的 setup/source-update/policy-update raw
rows 和五个 external baseline release rows 都能被 fail-fast contract 读取。随后新增的
workload derived ledger 把 W1--W4 的 8 个 workload row 机械化，但 summary 仍为
`c2_eligible_rows=0`，因为没有任何 workload 在修改内核 KVM 内重跑 per-sample
setup/storage/update macrobenchmark。

本步骤选择 W2 nginx fixture 做第一个真实 KVM PoC，原因是它已有最完整的 app-level
correctness oracle：`kvm-w2-nginx-real` 已在修改内核 guest 中运行真实 nginx binary、
`nginx -t`、fixture content probes、worker 启动、HTTP health check 和 worker quit。

## 已调研代码路径

- `mk/kvm.mk`
  - `kvm-w2-nginx-real` 启动修改内核 KVM guest。
  - guest target `__phase1_guest_w2_nginx_real` 固定输入、写 `w2-nginx-real-inputs.sha256`，
    然后调用 `tests/w1_oracle/namei_ext_w1_oracle.c`。
- `tests/w1_oracle/namei_ext_w1_oracle.c`
  - `prepare_nginx_prefix()` materialize nginx prefix、`conf/`、`logs/`、`html/` 和
    fixture/decoy files。
  - `run_nginx_real_app()` load/attach `sandbox_fixture_view.bpf.c`，运行 `nginx -t`、
    fixture probes、worker start、HTTP health、upstream observation、quit 和 detach。
  - `emit_nginx_case()` 和 `emit_nginx_probe()` 已写出 correctness JSONL，但没有 sample、
    setup/update timing、object count 或 bytes 字段。
- `bench/workloads/namei_ext_bench.c`
  - `emit_namei_ext_setup()`、`emit_namei_ext_update()` 和
    `emit_setup_update_sample()` 已定义 C2 raw row 风格，可复用字段命名。
- `mk/eval_osdi.mk`
  - `eval-osdi-workload-macrobench-ledger` 已记录 W2 nginx 当前
    `correctness_oracle_pass=true`、`policy_executed_in_kvm=true`，但
    `update_proxy_available=false`、`c2_eligible=false`。

## 最小实现目标

新增一个 Make-owned target，而不是复用现有 correctness target：

- `make kvm-w2-nginx-macrobench`
- guest target `__phase1_guest_w2_nginx_macrobench`
- raw output：`results/phase1/<run-id>/w2-nginx-macrobench.jsonl`
- input hash：`results/phase1/<run-id>/w2-nginx-macrobench-inputs.sha256`
- dmesg：`results/phase1/<run-id>/dmesg-w2-nginx-macrobench.log`

新增 runner mode：

```text
namei_ext_w1_oracle --sandbox-nginx-macrobench OUT_JSONL CGROUP_MOUNT WORK_DIR SAMPLES NGINX_BIN FIXTURE_CONF ENDPOINT_FIXTURE MIME_TYPES SANDBOX_POLICY
```

每个 sample 在 KVM 内执行：

1. materialize nginx prefix；
2. 记录 `w2-nginx-macrobench-setup` row：
   - `sample`
   - `setup_ns`
   - `created_dirs`
   - `created_files`
   - `bytes_written`
   - `bytes_copied`
3. attach `sandbox_fixture_view.bpf.c`；
4. 运行 `nginx -t` 和现有 fixture probes 作为 correctness oracle；
5. 修改 fixture backing 内容或 local endpoint fixture，记录
   `w2-nginx-macrobench-update` row：
   - `update_ns`
   - `source_update_writes`
   - `policy_update_writes`
   - `update_bytes_written`
   - `update_bytes_copied`
6. detach；
7. summary 统计 `samples`、`setup_rows`、`update_rows`、`correctness_rows`、`failures`。

## 设计边界

这一步仍不能直接支持 C2：

- 没有同 workload feature-equivalent baseline；
- 没有 C2 setup/storage/update 阈值；
- 只覆盖 W2 nginx fixture，不覆盖 PostgreSQL 和其他 family；
- 第一个 smoke run 可以用 `W2_NGINX_MACROBENCH_SAMPLES=2` 验证 plumbing，不是 release sample。

因此 row 必须标记：

- `result_level=kvm_workload_setup_update_poc`
- `run_environment=kvm`
- `workload=w2-nginx-fixture`
- `policy_family=sandbox_fixture_view.bpf.c`
- `c2_supported=false`
- `release_gate_pass=false`

## 后续进入 C2 的条件

W2 PoC 只能作为下一步 release target 的基础。进入 C2 至少还需要：

- `W2_NGINX_MACROBENCH_SAMPLES>=20`；
- 同 workload 的 copy/symlink/bind/projected-volume/OverlayFS/FUSE feature-equivalent baseline；
- setup object/writes/storage footprint 和 update/stale cost 的显式阈值；
- app-level correctness oracle 先通过，再解释性能；
- `eval-osdi-workload-macrobench-ledger` 从 raw KVM rows 提升 W2 nginx 的
  `update_proxy_available=true`，但仍必须等 baseline/threshold 才能设置
  `c2_eligible=true`。
