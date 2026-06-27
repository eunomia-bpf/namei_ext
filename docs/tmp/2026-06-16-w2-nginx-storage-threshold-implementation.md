# W2 nginx storage/threshold ledger 实现记录

日期：2026-06-16

## 实现范围

本步骤把 W2 nginx workload macrobench ledger 从“baseline input expected-fail”推进到
“W2 slice storage/threshold 已机械化”的状态。全局 C2 仍不升级。

## 代码改动

- 新增 `configs/eval-osdi/w2-nginx-workload-macrobench.jq`：
  - 读取 W2 proposed-system JSONL 和 W2 feature baseline JSONL；
  - 输出 proposed-system row、五类 feature baseline row 和 summary row；
  - 从 raw rows 聚合 setup/update latency、setup objects、setup bytes、update writes、
    materialization update writes 和 update bytes；
  - 计算 `storage_footprint_pass`、`setup_latency_threshold_pass`、
    `update_latency_threshold_pass`、`update_materialization_threshold_pass`、
    `threshold_pass` 和 `w2_c2_slice_supported`。
- 更新 `mk/eval_osdi.mk`：
  - `eval-osdi-w2-nginx-workload-macrobench-ledger` 改为 `jq -f` 调用该 filter；
  - filter 文件和本设计记录纳入 `w2-nginx-workload-macrobench-inputs.sha256`；
  - summary markdown 输出新增 storage/threshold 字段；
  - `c2_supported=false` 和 `release_gate_pass=false` 保持不变，避免 W2 单 workload
    slice 误升级为全局 C2。

## 阈值结果

运行命令：

```text
make eval-osdi-w2-nginx-workload-macrobench-ledger \
  RUN_ID=20260616T-eval-w2-nginx-workload-macrobench-ledger-v5 \
  EVAL_OSDI_W2_NGINX_POLICY_RUN_ID=20260615T-w2-nginx-c2-macrobench-release-sample-v1 \
  EVAL_OSDI_W2_NGINX_BASELINE_RUN_ID=20260616T-w2-nginx-baseline-macrobench-release-sample-v4
```

通过，结果位于：

```text
results/eval-osdi/paper/20260616T-eval-w2-nginx-workload-macrobench-ledger-v5/b3-macrobench/w2-nginx-workload-macrobench.jsonl
```

summary 关键字段：

- `storage_footprint_pass=true`
- `setup_latency_threshold_pass=true`
- `update_latency_threshold_pass=true`
- `update_materialization_threshold_pass=true`
- `threshold_pass=true`
- `w2_c2_slice_supported=true`
- `c2_supported=false`
- `release_gate_pass=false`

聚合数值：

- proposed-system 平均 setup latency：`7500337.5 ns`
- 最快 baseline 平均 setup latency：`9959036.45 ns`
- proposed-system 平均 update latency：`13914.8 ns`
- 最快 baseline 平均 update latency：`14044.7 ns`
- proposed-system 平均 setup objects：`17`
- baseline 最小平均 setup objects：`19`
- proposed-system 平均 setup bytes：`5931`
- baseline 最小平均 setup bytes：`5931`

`missing_evidence` 现在只列出：

```text
W1/W3/W4 workload setup/storage/update macrobench
```

## Hard gate

运行命令：

```text
make eval-osdi-w2-nginx-workload-macrobench \
  RUN_ID=20260616T-eval-w2-nginx-workload-macrobench-hardgate-v5 \
  EVAL_OSDI_W2_NGINX_POLICY_RUN_ID=20260615T-w2-nginx-c2-macrobench-release-sample-v1 \
  EVAL_OSDI_W2_NGINX_BASELINE_RUN_ID=20260616T-w2-nginx-baseline-macrobench-release-sample-v4
```

按预期非零退出。该 target 写出 v5 hardgate artifacts，但最终 `jq -e` 找不到同时满足
`release_gate_pass=true` 和 `c2_supported=true` 的 summary row。

## 判读

W2 slice 现在已经有：

- 20-sample KVM proposed-system setup/update/correctness rows；
- 五类同 workload feature baseline rows；
- storage footprint aggregation；
- 显式 setup/update/materialization threshold。

这可以支撑“W2 nginx slice 的 C2 input gate 已通过”的内部结论，但不能支撑全局 C2 或论文
abstract 中的性能主张。下一步全局 C2 必须扩展 W1/W3/W4 对等 workload macrobench，或在论文
中把 C2 范围收窄到 W2。
