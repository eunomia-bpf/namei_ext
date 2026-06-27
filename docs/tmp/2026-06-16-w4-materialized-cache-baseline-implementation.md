# W4 物化 cache view baseline 实现记录

## 动机

`table_redirect.bpf.c` 只能证明内部 table-style policy 是否足够强，不能替代真实外部
baseline。根据当前 evaluation 方向，负结果不能靠修改论文规避，而要继续加入更强、
更真实的替代方案。本步骤实现 `materialized_cache_view`，用于衡量没有
`namei_ext` 时直接物化 ccache cache view 的 setup/update/correctness 成本。

## 修改文件

- `tests/w1_oracle/namei_ext_w1_oracle.c`
  - 新增 `--ccache-materialized-baseline-macrobench` mode。
  - 新增 materialized setup/update/correctness/summary JSONL 事件。
  - setup 阶段读取 trace-derived ccache entries，并把 `original` 复制到
    `parent_relative/visible`。
  - update 阶段在同一 parent 下追加一个可见 cache object。
  - correctness 阶段验证可见内容、目录枚举和 hidden backing absence。
- `mk/kvm.mk`
  - 新增 `kvm-w4-ccache-materialized-baseline-macrobench`。
  - 新增 guest target
    `__phase1_guest_w4_ccache_materialized_baseline_macrobench`。
  - guest target 校验 bridge 输入、runner、设计/实现文档和 Makefile hash。
- `Makefile`
  - 新增 phony/help 入口。

## 结果语义

该 baseline 的所有核心行都写：

- `row_kind:"external_baseline"`
- `system:"materialized_cache_view"`
- `baseline:"materialized_cache_view"`
- `policy_executed:false`
- `feature_equivalent_baseline:true`
- `c2_supported:false`
- `release_gate_pass:false`

这保证它不会被误读成 eBPF policy 执行结果，也不会在 ledger 之前直接支撑 C2/C8。

## 失败语义

以下情况会让 Make target 失败：

- ccache bridge JSON、trace objects 或 entries TSV 缺失；
- runner source/binary 缺失；
- 设计/实现文档缺失；
- setup/update/correctness 行数不足；
- 任意 setup/update/correctness 行 `pass != true`；
- summary 没有声明 `policy_executed:false` 或 baseline 等价字段。

## 验证

已运行 smoke：

```text
make w1-oracle
make kvm-w4-ccache-materialized-baseline-macrobench \
  RUN_ID=20260616T-w4-ccache-materialized-baseline-smoke-v1 \
  W4_CCACHE_MATERIALIZED_BASELINE_SAMPLES=1
```

结果：`results/phase1/20260616T-w4-ccache-materialized-baseline-smoke-v1/` 通过；
1 条 setup、1 条 update、1 条 correctness row 均 `pass=true`。

已运行 release：

```text
make kvm-w4-ccache-materialized-baseline-macrobench \
  RUN_ID=20260616T-w4-ccache-materialized-baseline-release-v1 \
  W4_CCACHE_MATERIALIZED_BASELINE_SAMPLES=20
```

结果：`results/phase1/20260616T-w4-ccache-materialized-baseline-release-v1/` 通过；
summary `samples=20`、`setup_rows=20`、`update_rows=20`、`correctness_rows=20`、
`pass=true`、`failures=0`、`policy_executed=false`。setup 平均约 57.95 ms，
update 平均约 3.82 ms。
