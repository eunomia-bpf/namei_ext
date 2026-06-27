# OSDI policy-family gate review revision

Last updated: 2026-06-15
Stage at update: Phase 1 implementation revision / subagent review
Source/command: Hooke subagent review of `mk/eval_osdi.mk` and B12 ledger outputs
Completeness: complete for P2 review fixes

## Review 结论

Hooke 对 B12 release contract 增量给出 scoped Weak Accept：

- 无 P0。
- 无 P1。
- 没有发现把 non-C8 evidence 包装成成功的字段或目标。
- `eval-osdi-policy-family` 在当前 `release_gate_pass=false` 时失败，是正确行为。
- 文档和 paper wording 明确 C1/C8 仍 blocked。

Hooke 给出三个 P2 建议：

1. `observed_workload_rows` 没有列出具体 row IDs 或 basis，特别是 W4 的
   `observed=2` 是从一个 release summary 推导出来的。
2. eval manifest 只列 JSON 和 input sha，未直接记录 gate summary、summary path、
   dirty flags。
3. `make help` 未列出可通过的 `eval-osdi-policy-family-ledger` 审计入口。

## 修复内容

### observed workload basis

`mk/eval_osdi.mk` 现在给每个 family row 添加 `observed_workload_basis`：

- `build_graph`：
  `w1-redis-build:release-output-compare`、
  `w1-nginx-build:release-output-compare`
- `sandbox_fixture`：
  `w2-nginx-fixture:nginx-real-endpoint-health`
- `checkpoint_restore`：
  `w3-redis-podman-criu:redis-checkpoint-replay`
- `cache_locality`：
  `w4-ccache-redis-nginx:redis-hot-compile`、
  `w4-ccache-redis-nginx:nginx-hot-compile`

这些字段只解释 `observed_workload_rows` 的来源，不改变 `qualifying_workload_rows`
或 `qualified_for_c1_c8` 的 gate 条件。

### manifest gate summary

`results/eval-osdi/paper/<run-id>/manifest.json` 现在直接记录：

- `main_repo.head`、`main_repo.dirty`
- `kernel_repo.head`、`kernel_repo.dirty`
- `artifacts.policy_family_summary`
- `gate.qualified_families`
- `gate.release_gate_pass`
- `gate.c1_supported`
- `gate.c8_supported`

这样 artifact reviewer 可以先读 manifest 判断当前 release gate 状态，再追到 raw
JSONL 和 input SHA。

### help 入口

`make help` 现在列出：

```text
make eval-osdi-policy-family-ledger write B12 ledger from an existing Phase 1 root
```

`eval-osdi-smoke` 保持 fresh checkout 的一键入口：先跑 `phase1`，再写 ledger。
`eval-osdi-policy-family-ledger` 是复用已有 full root 的审计入口。

## 不改变的语义

- `eval-osdi-policy-family` 仍然 hard-gate `release_gate_pass=true` 和
  `qualified_families >= 4`。
- 当前 full root 仍应得到 `qualified_families=0`、`release_gate_pass=false`。
- 当前 `eval-osdi-policy-family` 仍应失败；这是防止 C1/C8 误升级的预期行为。

## 后续验证

需要重新运行：

```text
make eval-osdi-policy-family-ledger \
  RUN_ID=20260615T-eval-contract \
  EVAL_OSDI_PHASE1_RUN_ID=20260615T-full-phase1-gatefix
sha256sum -c results/eval-osdi/paper/20260615T-eval-contract/b12-policy-family/policy-family-inputs.sha256
make -s eval-osdi-policy-family \
  RUN_ID=20260615T-eval-contract-hardgate \
  EVAL_OSDI_PHASE1_RUN_ID=20260615T-full-phase1-gatefix
```

最后一个命令仍应通过 expected-failure wrapper 验证为失败。
