# Phase 1 微基准 variant 报告门禁

> 2026-06-29 baseline scope update: this historical record preserves prior reasoning and results. Current C8/B12 guidance is claim-driven baseline selection; exact-map diagnostics are optional boundary evidence only when precomputed mapping is the competing claim.

日期：2026-06-15

## 动机

此前 `kvm-bench` 已经能单独在修改后的 KVM guest 中跑出 `pass_only`、
`table_redirect_empty` 和 `table_redirect_hit`，但完整 `make phase1` 的
`report` 只检查 `bench` 行没有失败，没有把这些 variant 写成 Phase 1 closure
的 hard gate。这样会导致旧的完整 root 仍可能被误当作当前 canonical evidence。

本步骤的目标是把 microbenchmark variant set、真实 eBPF attach、detach 和
`table_redirect_hit` map update 都纳入 `mk/report.mk`，让完整 Phase 1 root 必须包含
真实 KVM bench evidence 才能生成 `summary.md`。

## 检查过的文件

- `mk/report.mk`：Phase 1 summary 生成和 hard gate。
- `mk/kvm.mk`：`__phase1_guest_bench` 写入 `bench-start.policy_variants`，并把
  `pass_only.bpf.o`、`table_redirect.bpf.o` 传给 runner。
- `bench/workloads/namei_ext_bench.c`：实际输出 `bench`、`bench_attach`、
  `bench_detach` 和 `bench_map_update` 行。
- `results/phase1/20260615T-bench-variants-smoke/bench.jsonl`：单独 KVM bench smoke，
  用于确认新增 jq gate 的字段名和数量。
- `results/phase1/20260615T-full-phase1-gatefix/bench.jsonl`：旧完整 root，用于确认
  新 gate 会拒绝缺少 variant 的历史结果。

## 实现内容

`mk/report.mk` 新增以下 hard gate：

- `bench` 名称必须正好覆盖 7 个 Phase 1 metadata-path microbenchmark：
  `lookup_native_hot`、`lookup_tool_redirect`、`access_tool_redirect`、
  `open_tool_redirect`、`exec_tool_redirect`、`readdir_alias_view` 和
  `build_tree_stat_walk`。
- `bench` variant 必须正好覆盖 `baseline`、`pass_only`、`policy`、
  `table_redirect_empty` 和 `table_redirect_hit`。
- 默认 `SAMPLES=1` 时必须产生 35 个 `bench` row；一般情况下要求每个 variant 有
  `7 * SAMPLES` 个 row。
- `bench-start.policy_variants` 必须声明 `pass_only`、`table_redirect_empty`、
  `table_redirect_hit` 和 `policy`。
- `pass_only`、`table_redirect_empty`、`table_redirect_hit` 和 `policy` 必须都有一次
  `bench_attach` 成功和一次 `bench_detach` 成功。
- `table_redirect_hit` 必须有一次 `bench_map_update`，且 `ops=66`、`ok=66`、
  `fail=0`。

`summary.md` 也新增三行概览：

- benchmark variant 列表；
- `table_redirect_hit` map update 成功数；
- policy attach 成功数。

## 拒绝的替代方案

- 不在 report 中检查，只让 eval ledger 解释缺失字段：这会让完整 Phase 1 closure
  仍然接受不完整 bench root，不符合 fail-fast 规则。
- 只检查 `pass_only` 和 `table_redirect_hit` 是否存在：这无法防止 runner 漏掉部分
  benchmark 或 attach/detach 失败。
- 用非 Makefile 脚本做检查：违反项目 Makefile-only control plane 约束。

## 验证

Makefile 解析：

```text
make -n report RUN_ID=20260615T-full-phase1-gatefix
```

结果：通过，说明 recipe 语法可解析。

定向 jq gate：

- `results/phase1/20260615T-bench-variants-smoke/bench.jsonl` 通过新增 variant gate；
- `results/phase1/20260615T-full-phase1-gatefix/bench.jsonl` 因缺少新 variant 返回
  false，符合预期。

随后完整 run：

```text
make phase1 RUN_ID=20260615T-full-phase1-bench-variants
```

结果：通过。新 root 的 `summary.md` 包含：

```text
Benchmark failing operations: 0
Benchmark variants: baseline,pass_only,policy,table_redirect_empty,table_redirect_hit
Benchmark table_redirect_hit map updates: 66
Benchmark policy attach successes: 4
```

## 剩余风险

- 该 gate 只证明 Phase 1 smoke-scale KVM bench 的完整性，不提供 tail latency、
  confidence interval、随机顺序或 release-scale baseline。
- `table_redirect_hit` 的规则数 66 来自当前 bench fixture shape；如果 fixture 改变，
  report gate 也要同步改成显式配置或新的 committed invariant。
- `table_redirect_empty` 只是空表 miss-path overhead，不代表 populated table baseline。
