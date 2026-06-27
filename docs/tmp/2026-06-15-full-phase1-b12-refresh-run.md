# Full Phase 1 B12 refresh 运行记录

Last updated: 2026-06-15
Stage at update: execute/gate loop
Source/command: `make phase1 RUN_ID=20260615T-full-phase1-b12-refresh-v1`
Completeness: complete

## 动机

此前 B12 reviewer 指出 canonical Phase 1 root
`results/phase1/20260615T-full-phase1-bench-variants/` 已经落后于当前 gate：它没有
`w3-redis-counterfactual.jsonl` 和 `w4-cache-table-content.jsonl`，而新的
`mk/eval_osdi.mk` 已经把这两个 same-workload table-only comparator 作为 B12 输入。

因此需要重新跑完整 `make phase1`，生成一个包含 W3/W4 负证据、W4 真实 ccache witness、
Docker smoke、KVM dmesg/provenance 和 report hard gate 的新 Phase 1 root。

## 执行命令

```text
make phase1 RUN_ID=20260615T-full-phase1-b12-refresh-v1
```

## 结果路径

- Phase 1 root:
  `results/phase1/20260615T-full-phase1-b12-refresh-v1/`
- Workload root:
  `results/workloads/runs/20260615T-full-phase1-b12-refresh-v1/`
- Summary:
  `results/phase1/20260615T-full-phase1-b12-refresh-v1/summary.md`
- Metadata:
  `results/phase1/20260615T-full-phase1-b12-refresh-v1/metadata.json`

## 覆盖的关键 gate

该 run 在修改内核 KVM 中完成并返回 0。它覆盖：

- KVM guest smoke；
- ABI、policy load、policy semantic、table conformance；
- W1 Redis/nginx build graph oracle、build replay、release binary replay、branch probes；
- W2 nginx real-app health/config witness；
- W3 Redis checkpoint replay、table replay、same-workload table-only counterfactual；
- W4 cache oracle、cache-content oracle、same-workload table-content comparator；
- W4 真实 ccache cold/hot Redis/nginx compile witness；
- W4 ccache trace、policy bridge、policy-attached compile、parent-rule compile；
- W4 table-only ccache compile comparator；
- W4 release counterfactual accounting；
- table-budget accounting；
- Phase 1 functional and microbenchmark rows；
- Docker runtime image build、save 和 image-internal `make bpf` smoke；
- report artifact existence checks、metadata、kernel/Docker sha256、dmesg logs。

## B12 判读

这个 run 修复的是 evidence freshness，不是 C8 支持性。

关键负证据仍然存在：

- W3 Redis same-workload table-only replay 通过，`qualified_for_c8=false`。
- W4 cache-content same-workload table comparator 通过，
  `content_equivalent_table_oracle=true`、`qualified_for_c8=false`。
- W4 ccache release counterfactual summary 标记 `operation_weighted_policy_hit_rate_is_release=false`
  且 table baseline 仍未失败。

因此新 root 可以作为当前 B12 ledger 的输入，但不能把
programmable path-resolution necessity claim 判为 supported。

## 后续验证

随后运行：

```text
make eval-osdi-policy-family-ledger \
  RUN_ID=20260615T-eval-b12-refresh-v1 \
  EVAL_OSDI_PHASE1_RUN_ID=20260615T-full-phase1-b12-refresh-v1
```

该 ledger 写出后，`qualified_families=0`、`release_gate_pass=false`。

再运行：

```text
make eval-osdi-policy-family \
  RUN_ID=20260615T-eval-b12-refresh-hardgate-v1 \
  EVAL_OSDI_PHASE1_RUN_ID=20260615T-full-phase1-b12-refresh-v1
```

该 hard gate 按预期返回非零，证明 release gate 仍会阻止 C1/C8 过度声明。

