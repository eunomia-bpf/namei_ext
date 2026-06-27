# W4 materialized baseline ledger 集成记录

## 动机

W4 之前的 workload ledger 只比较 `cache_locality_view.bpf.c` parent-rule policy 和
`table_redirect.bpf.c`。这会把内部 table policy 当成主 baseline，不能回答用户提出的
问题：如果 baseline 不够强，不能修改论文来规避，而应该继续实现真实外部 baseline。

本步骤把 `materialized_cache_view` 接入 W4 workload ledger，让 W4 C2 判定由外部
feature-equivalent baseline 施压。`table_redirect.bpf.c` 仍保留，但只作为内部 ablation
和 C8 counterfactual 输入。

## 修改文件

- `configs/eval-osdi/w4-ccache-workload-macrobench.jq`
  - 新增 `--slurpfile w4_materialized` 输入。
  - 输出第三类 row：`row_kind:"external_baseline"`、
    `baseline:"materialized_cache_view"`、`policy_executed:false`。
  - summary 中新增 `materialized_baseline_pass`、`table_release_input_pass`、
    `materialized_setup_ns_avg`、`materialized_update_ns_avg`。
  - `baseline_release_input_pass` 改为外部 materialized baseline 是否通过。
  - setup/update/materialization threshold 改为 proposed system 对比 materialized
    baseline。
- `mk/eval_osdi.mk`
  - 新增 `EVAL_OSDI_W4_CCACHE_MATERIALIZED_RUN_ID` 及 JSON/input sha256 变量。
  - `eval-osdi-w4-ccache-workload-macrobench-ledger` hard-require materialized run。
  - 输入 hash 覆盖 rule macrobench、materialized baseline、设计/实现文档和 JQ filter。
  - summary markdown 写入 materialized external baseline run id。

## 运行结果

KVM materialized baseline：

```text
make kvm-w4-ccache-materialized-baseline-macrobench \
  RUN_ID=20260616T-w4-ccache-materialized-baseline-release-v1 \
  W4_CCACHE_MATERIALIZED_BASELINE_SAMPLES=20
```

结果：`results/phase1/20260616T-w4-ccache-materialized-baseline-release-v1/`。

- 20 setup rows、20 update rows、20 correctness rows。
- summary `pass=true`、`failures=0`、`policy_executed=false`、
  `feature_equivalent_baseline=true`。
- setup avg `57,954,965.5 ns`。
- update avg `3,823,967.1 ns`。

W4 ledger：

```text
make eval-osdi-w4-ccache-workload-macrobench-ledger \
  RUN_ID=20260616T-eval-w4-ccache-workload-macrobench-ledger-v2 \
  EVAL_OSDI_W4_CCACHE_RULE_RUN_ID=20260616T-w4-ccache-rule-macrobench-release-v1 \
  EVAL_OSDI_W4_CCACHE_MATERIALIZED_RUN_ID=20260616T-w4-ccache-materialized-baseline-release-v1
```

结果：`results/eval-osdi/paper/20260616T-eval-w4-ccache-workload-macrobench-ledger-v2/b3-macrobench/`。

- `policy_release_input_pass=true`
- `table_release_input_pass=true`
- `materialized_baseline_pass=true`
- `full_feature_equivalent_baseline_pass=true`
- `storage_footprint_pass=false`
- `setup_latency_threshold_pass=false`
- `update_latency_threshold_pass=false`
- `rule_materialization_threshold_pass=false`
- `w4_c2_slice_supported=false`
- `release_gate_pass=false`

Hard gate：

```text
make eval-osdi-w4-ccache-workload-macrobench \
  RUN_ID=20260616T-eval-w4-ccache-workload-macrobench-hardgate-v2 \
  EVAL_OSDI_W4_CCACHE_RULE_RUN_ID=20260616T-w4-ccache-rule-macrobench-release-v1 \
  EVAL_OSDI_W4_CCACHE_MATERIALIZED_RUN_ID=20260616T-w4-ccache-materialized-baseline-release-v1
```

按预期非零退出；status artifact 记录 `status=4`、`pass=false`。

## 解释

这是更强的负结果，不是论文文字问题。当前 trace shape 只有 4 个 cache objects、4 个
leaf parents，直接物化目录树在 setup/update 上更快，且没有 policy rule writes。因此
W4 不能支持 C2 materialization-cost claim。

下一步如果继续 W4，应做新的真实 baseline/workload，而不是降低标准：

- 扩大到更多 cache objects 和更多同 parent fanout；
- 加入真实 stale/corrupt/update window；
- 加入 operation-weighted policy hit rate；
- 增加 BuildKit/Prometheus Go cache trace；
- 或引入 FUSE/cache-remap/native ccache/BuildKit 对照。
