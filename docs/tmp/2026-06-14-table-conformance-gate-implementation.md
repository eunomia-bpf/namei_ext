# 2026-06-14 Table-only Conformance Gate 实现记录

## 动机

第二轮论文 review 指出：`table_redirect.bpf.c` 已被定义为 C8 的强 table-only baseline，
但缺少 Makefile-owned conformance checker。没有这个 gate，table-only baseline 可能在后续
演化中悄悄加入 fallback chain、resolver、epoch state machine 或隐藏 rule engine，从而破坏
“同等 table/update budget”反事实的公平性。

本步骤实现一个最小 conformance gate。它不替代真实 table-only workload counterfactual，
只证明 `table_redirect.bpf.c` 当前仍是受限 exact lookup baseline。

## 实现内容

新增：

- `tests/table_conformance/Makefile`
- `tests/table_conformance/namei_ext_table_conformance.c`

修改：

- `Makefile`
- `mk/report.mk`
- `docs/paper/sections/04-implementation.tex`
- `docs/paper/sections/05-evaluation.tex`

新增顶层 target：

```text
make table-conformance
```

该 target 依赖 `make bpf`，然后运行 C checker，输出：

```text
results/phase1/<run-id>/table-conformance.jsonl
```

`phase1-smoke` 现在包含 `table-conformance`。`mk/report.mk` 现在要求
`table-conformance.jsonl` 存在，并检查：

- `table-conformance` failure count 为 0；
- `table-conformance-summary` 存在且 `pass=true`；
- `summary.md` 包含 Table Conformance Cases 和 raw artifact 列表。

## Checker 语义

Checker 读取：

- `bpf/policies/table_redirect.bpf.c`
- `.build/bpf/table_redirect.bpf.o`

它检查：

- source 可读且非空；
- object 存在且非空；
- object mtime 不旧于 source；
- 只存在一个 `SEC("cgroup/namei_ext")` attach section；
- policy 使用 `BPF_MAP_TYPE_HASH`；
- policy 使用 `exact_redirects`；
- key/value 是 `namei_ext_component_key` 和 `namei_ext_redirect_rule`；
- policy body 中只构造 component key、执行一次 `bpf_map_lookup_elem`、调用
  `namei_ext_apply_rule` 返回；
- source 不包含 forbidden helpers，例如 map update/delete、tail call、BPF loop、random/time/probe helpers；
- policy body 不包含 `if`、`for`、`while`、`switch`、`goto`、ternary、literal resolver helper。

## 明确边界

该 checker 是 source/object conformance gate，不是形式化 C parser，也不是 verifier 证明。
它不证明：

- table-only baseline 在真实 workload 上失败；
- table-only baseline 超过 map/update/stale-window budget；
- C8 的 programmability claim；
- per-workload oracle。

C8 仍需要真实 KVM workload counterfactual，并保存 table entries、map memory、update writes、
update latency、stale window 和 oracle output。

## 验证

已运行：

```text
make table-conformance RUN_ID=20260614T-table-conformance-dev
cat results/phase1/20260614T-table-conformance-dev/table-conformance.jsonl
make table-conformance RUN_ID=20260614T045335Z-a476f6e2
make report RUN_ID=20260614T045335Z-a476f6e2 SAMPLES=1 BENCH_ITERS=2000
jq -s '{failures: [.[] | select(.event == "table-conformance" and .pass == false)] | length, summary: [.[] | select(.event == "table-conformance-summary")][0]}' results/phase1/20260614T045335Z-a476f6e2/table-conformance.jsonl
```

结果：

- `make table-conformance` 通过。
- `table-conformance-summary` 为 `pass=true`、`failures=0`。
- `make report` 通过。
- `results/phase1/20260614T045335Z-a476f6e2/summary.md` 已包含 Table Conformance Cases。

## 后续工作

- 为 conformance gate 增加 per-policy source/object sha256 字段。
- 为 table-only counterfactual 实现真实 workload runner。
- 将 table entries、map memory、update writes、update latency 和 stale window 写入
  release-level manifest。
