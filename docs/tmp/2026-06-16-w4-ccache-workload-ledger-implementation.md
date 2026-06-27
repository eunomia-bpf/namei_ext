# W4 ccache workload ledger 实现记录

日期：2026-06-16

## 动机

本步骤把 `kvm-w4-ccache-rule-macrobench` 的 20-sample KVM raw rows 接入 OSDI C2
workload ledger。目标不是把 W4 升级成正结果，而是让 W4 ccache workload 的
proposed-system 与 table baseline 比较进入 fail-fast claim accounting，避免“policy
能跑通”被误写成 “C2 supported”。

## 修改文件

- `configs/eval-osdi/w4-ccache-workload-macrobench.jq`
  - 新增 W4 专用 ledger filter；
  - 从 `w4-ccache-rule-macrobench.jsonl` 读取 proposed-system 和 table baseline rows；
  - 输出 proposed-system row、feature-baseline row 和 summary row；
  - 计算 release input、storage、setup latency、update latency 和 rule materialization
    threshold gates；
  - 保持 `c2_supported=false` 和 `release_gate_pass=false`，因为 W3 缺对等 workload
    macrobench，且 W4 当前 threshold 不通过。
- `mk/eval_osdi.mk`
  - 新增 `eval-osdi-w4-ccache-workload-macrobench-ledger`；
  - 新增 `eval-osdi-w4-ccache-workload-macrobench` hard gate；
  - 生成 JSONL、summary、manifest、input sha256 和 hardgate status artifact。
- `Makefile`
  - 增加 W4 ledger/hardgate 顶层入口和 help 文本。

## 验证命令

ledger：

```text
make eval-osdi-w4-ccache-workload-macrobench-ledger \
  RUN_ID=20260616T-eval-w4-ccache-workload-macrobench-ledger-v1 \
  EVAL_OSDI_W4_CCACHE_RULE_RUN_ID=20260616T-w4-ccache-rule-macrobench-release-v1
```

input hash 复验：

```text
sha256sum -c \
  results/eval-osdi/paper/20260616T-eval-w4-ccache-workload-macrobench-ledger-v1/b3-macrobench/w4-ccache-workload-macrobench-inputs.sha256
```

hard gate：

```text
make eval-osdi-w4-ccache-workload-macrobench \
  RUN_ID=20260616T-eval-w4-ccache-workload-macrobench-hardgate-v1 \
  EVAL_OSDI_W4_CCACHE_RULE_RUN_ID=20260616T-w4-ccache-rule-macrobench-release-v1
```

该 hard gate 预期失败，因为 summary 中没有 `release_gate_pass=true` 和
`c2_supported=true`。失败状态被写入：

```text
results/eval-osdi/paper/20260616T-eval-w4-ccache-workload-macrobench-hardgate-v1/b3-macrobench/w4-ccache-workload-macrobench-hardgate-status.json
```

## Ledger 结果

ledger artifact：

- `results/eval-osdi/paper/20260616T-eval-w4-ccache-workload-macrobench-ledger-v1/b3-macrobench/w4-ccache-workload-macrobench.jsonl`
- `results/eval-osdi/paper/20260616T-eval-w4-ccache-workload-macrobench-ledger-v1/b3-macrobench/w4-ccache-workload-macrobench-summary.md`
- `results/eval-osdi/paper/20260616T-eval-w4-ccache-workload-macrobench-ledger-v1/b3-macrobench/w4-ccache-workload-macrobench-inputs.sha256`
- `results/eval-osdi/paper/20260616T-eval-w4-ccache-workload-macrobench-ledger-v1/b3-macrobench/w4-ccache-workload-macrobench-manifest.json`

summary：

- `policy_release_input_pass=true`
- `baseline_release_input_pass=true`
- `table_baseline_pass=true`
- `full_feature_equivalent_baseline_pass=true`
- `storage_footprint_pass=true`
- `setup_latency_threshold_pass=false`
- `update_latency_threshold_pass=false`
- `rule_materialization_threshold_pass=true`
- `threshold_pass=false`
- `w4_c2_slice_supported=false`
- `c2_supported=false`
- `release_gate_pass=false`
- `policy_setup_ns_avg=110545949.3`
- `baseline_setup_ns_avg=104058982.65`
- `policy_update_ns_avg=6518131.3`
- `baseline_update_ns_avg=6308357.65`
- `policy_setup_rule_writes_avg=8`
- `baseline_setup_rule_writes_avg=8`
- `policy_update_rule_writes_avg=2`
- `baseline_update_rule_writes_avg=2`
- `missing_inputs=W3 workload setup/storage/update macrobench`
- `failed_gates=W4 setup latency threshold failed, W4 update latency threshold failed`

hard gate status：

```json
{
  "schema": "namei_ext.eval_osdi.hardgate_status.v1",
  "run_id": "20260616T-eval-w4-ccache-workload-macrobench-hardgate-v1",
  "target": "eval-osdi-w4-ccache-workload-macrobench",
  "status": 4,
  "pass": false
}
```

外层 `make` 返回非零，这是 expected-fail gate。

## 解释

W4 现在有 release-level KVM raw input 和 claim-level ledger，但结论仍为负：

- correctness、KVM attach path、proposed-system rows、table baseline rows 和 input hash
  都通过；
- storage footprint 与 rule materialization 没有比 table baseline 差；
- setup latency 与 update latency 都没有达到比 table baseline 更好的阈值；
- 当前 trace shape 中每个 cache object 位于不同 leaf parent，parent-rule policy 没有
  减少 lookup/readdir rule writes；
- table baseline 仍是 full feature-equivalent comparator。

因此本步骤降低了 C2 的工程不确定性，但没有提升 C2 verdict。全局 C2 当前仍只有 W2
slice 是正结果；W1 为负，W3 缺 workload macrobench，W4 为负。C8 也不因本步骤改变，
因为 table baseline 继续通过当前 ccache oracle。

## 后续

- 若要让 W4 支持 C2，需要真实 cache workload 产生 same-parent 多对象或更高 fanout 的
  parent-rule advantage，并在 release ledger 中同时通过 setup/update threshold。
- 若要让 W4 支持 C8，需要 release-level operation-weighted policy cache hit rate、真实
  stale/corrupt transition、BuildKit/Prometheus cache trace，或 table/update budget failure。
- 若当前真实 ccache trace 长期保持 table-friendly 形状，应把 W4 写成负结果，并收窄 C2/C8
  主张。
