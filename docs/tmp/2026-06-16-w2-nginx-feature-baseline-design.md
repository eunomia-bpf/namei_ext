# W2 nginx feature-equivalent baseline 设计

日期：2026-06-16

阶段：Phase 1 research/implementation design

## 动机

当前 W2 nginx 已有 `namei_ext` 侧 20-sample KVM setup/update raw input：

```text
results/phase1/20260615T-w2-nginx-c2-macrobench-release-sample-v1/w2-nginx-macrobench.jsonl
```

该 run 证明真实 nginx fixture workload 可以在修改内核 KVM 中跑通，但 C2 仍不能成立，
因为缺少同 workload 的 feature-equivalent baseline。下一步需要让 copy/symlink/bind/FUSE
等替代方案在同一 nginx fixture oracle 下记录 setup/update/correctness raw rows。

## 现有代码路径

- `mk/kvm.mk`
  - 已有 `kvm-w2-nginx-macrobench` 和 `__phase1_guest_w2_nginx_macrobench`。
  - 该 target 会在 KVM guest 中校验 nginx binary、fixture config、endpoint fixture、
    `mime.types`、policy object 和 runner。
- `tests/w1_oracle/namei_ext_w1_oracle.c`
  - 已有 `--sandbox-nginx-macrobench` mode。
  - 已有 `prepare_nginx_prefix()`、`update_nginx_macro_fixture()`、
    `check_nginx_fixture_compare()` 和 `run_nginx_test()`。
  - 当前 `namei_ext` policy 方式故意让 `conf/nginx.conf`、`conf/upstream.sock` 等 alias
    不真实存在，attach 后由 `sandbox_fixture_view.bpf.c` redirect。
- `bench/workloads/namei_ext_baselines.c`
  - 已有通用 microbench baselines，但不是 nginx fixture workload。
  - 不适合直接复用为 W2 release evidence，因为它没有 nginx config parser、fixture
    path-class 和 app-level oracle。

## 设计选择

第一版新增一个 runner mode：

```text
--sandbox-nginx-baseline-macrobench OUT_JSONL WORK_DIR SAMPLES NGINX_BIN FIXTURE_CONF ENDPOINT_FIXTURE MIME_TYPES BASELINES
```

它不加载 BPF，不需要 cgroup attach，但仍在修改内核 KVM guest 内运行真实 nginx binary。
`BASELINES` 是 Make 变量传入的空格/逗号分隔列表；第一版实现：

- `copy_tree`：setup 时把 fixture backing 文件复制成真实 alias 文件；
- `symlink_forest`：setup 时把 alias 文件符号链接到 fixture backing 文件。

这两个 baseline 的语义是“测试 view 在启动前已经物化好”，因此：

- `nginx -t -p <prefix>/ -c conf/nginx.conf` attach 前必须成功；
- `conf/nginx.conf`、`conf/upstream.sock`、`conf/server.crt`、`conf/db.password`
  和 `conf/prod.token` 必须能通过普通 VFS 访问到 fixture/fake/poison backing；
- update 阶段必须更新 endpoint/cert/secret backing，并再次通过 `nginx -t` 和 probes。

## 输出 schema

输出仍放入 Phase 1 result root，但文件独立：

```text
results/phase1/<run-id>/w2-nginx-baseline-macrobench.jsonl
```

行类型：

- `w2-nginx-baseline-setup`
- `w2-nginx-baseline-update`
- `w2-nginx-baseline-correctness`
- `w2-nginx-baseline-summary`

字段必须包含：

- `baseline`
- `sample`
- `setup_ns` / `update_ns`
- `created_dirs`、`created_files`、`created_symlinks`
- `bytes_written`、`bytes_copied`
- `source_update_writes`、`baseline_update_writes`
- `policy_executed=false`
- `kvm_validated=true`
- `feature_equivalent_baseline=true`
- `c2_supported=false`
- `release_gate_pass=false`

## Makefile 接入

新增 Make 变量：

- `W2_NGINX_BASELINE_MACROBENCH_JSON`
- `W2_NGINX_BASELINE_MACROBENCH_INPUTS`
- `W2_NGINX_BASELINE_MACROBENCH_WORK_DIR`
- `W2_NGINX_BASELINE_MACROBENCH_SAMPLES`
- `W2_NGINX_BASELINES`

新增 targets：

- `kvm-w2-nginx-baseline-macrobench`
- `__phase1_guest_w2_nginx_baseline_macrobench`

默认 `W2_NGINX_BASELINES` 第一版只含 `copy_tree symlink_forest`。bind mount、FUSE 和
projected-volume 类 baseline 后续应按同一 schema 加入；当前不能把第一版写成完整 C2。

## 成功条件

第一版 smoke/release input 的 gate 是：

- 每个 selected baseline 都有 `samples` 条 setup/update/correctness rows；
- 每个 correctness row `pass=true`；
- summary `pass=true`、`failures=0`；
- summary `baseline_count` 等于 selected baseline 数；
- summary `c2_supported=false` 和 `release_gate_pass=false`，防止 raw input 被误写成 C2 结论。

## 风险和限制

- `copy_tree` 和 `symlink_forest` 不能代表 Kubernetes projected volume、bind mount 或 FUSE；
  它们只补第一批 feature-equivalent materialization 对照。
- `symlink_forest` 对 update 的语义可能只需要更新 backing，不需要改 symlink；这会暴露
  baseline update write count 与 copy baseline 不同，属于真实 tradeoff，不应隐藏。
- baseline rows 还需要后续接入 `eval-osdi-workload-macrobench-ledger`；没有 ledger 接入
  前，只是 raw input。
- 当前仍不做 trace-level no-real-open，因此 W2 仍不能计入 C1/C8。
