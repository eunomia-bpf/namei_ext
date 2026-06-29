# C2 workload macrobench 派生账本实现记录

> 2026-06-29 baseline scope update: this historical record preserves prior reasoning and results. Current C8/B12 guidance is claim-driven baseline selection; exact-map diagnostics are optional boundary evidence only when precomputed mapping is the competing claim.

日期：2026-06-15

## 背景

前一阶段已经把 `namei_ext` 自身的 setup/source-update/policy-update raw rows 扩展到
20 个 unique samples，并用 `eval-osdi-macrobench-ledger` 证明 C2 input gate 已经能
fail fast 地读取这些 rows 和五个 external baseline release rows。但这个证据仍不是
workload-equivalent macrobenchmark：它没有在 W1--W4 的真实 workload 语境下重跑
setup/storage/update，也没有同 workload feature-equivalent baseline comparison 或明确的
C2 成功阈值。

本步骤实现设计文档中的第一阶段 target：生成一个派生 contract，而不是 C2 支持结果。

## 修改内容

- 在 `mk/eval_osdi.mk` 中新增 `eval-osdi-workload-macrobench-ledger`。
- 在 `mk/eval_osdi.mk` 中新增 `eval-osdi-workload-macrobench` hard gate。
- 在顶层 `Makefile` 中暴露这两个 target，并把 ledger target 加入 `make help`。
- 输出路径固定在 `results/eval-osdi/paper/<run-id>/b3-macrobench/`，与 C2 B3--B6
  macrobench block 对齐。

## 账本语义

`eval-osdi-workload-macrobench-ledger` 读取现有 Phase 1 root 和 workload run root：

- W1 Redis/nginx build manifests 与 KVM build/release replay summary。
- W2 nginx/PostgreSQL fixture manifests 与 nginx KVM health oracle。
- W3 Redis/nginx checkpoint manifests 与 Redis KVM replay witness。
- W4 ccache/BuildKit cache manifests 与 ccache KVM witnesses、table comparator 和 release
  counterfactual summary。

该 target 写出 8 条 workload row 和 1 条 summary row。每条 workload row 记录：

- workload id 和 policy family；
- source kind；
- correctness oracle 是否已有；
- policy 是否已在 KVM 中执行；
- setup/storage/update proxy 是否存在；
- release sample budget、feature-equivalent baseline、threshold 和 C2 eligibility。

当前所有 row 都固定 `c2_eligible=false`，summary 固定：

- `result_level=c2_workload_derived_contract`
- `run_environment=mixed_host_kvm_derived`
- `release_gate_pass=false`
- `c2_supported=false`
- `verdict=derived_contract_only`

这样做的目的不是绕过缺失工作，而是把缺失项机械化：KVM per-sample workload setup/update
macrobench、feature-equivalent workload baselines 和 C2 setup/storage/update 阈值。

## 验证命令

```text
make eval-osdi-workload-macrobench-ledger \
  RUN_ID=20260615T-eval-c2-workload-derived-ledger-v1 \
  EVAL_OSDI_PHASE1_RUN_ID=20260615T-full-phase1-c2-release-sample-v1
```

该命令通过，并写出：

- `results/eval-osdi/paper/20260615T-eval-c2-workload-derived-ledger-v1/b3-macrobench/workload-macrobench.jsonl`
- `results/eval-osdi/paper/20260615T-eval-c2-workload-derived-ledger-v1/b3-macrobench/workload-macrobench-inputs.sha256`
- `results/eval-osdi/paper/20260615T-eval-c2-workload-derived-ledger-v1/b3-macrobench/workload-macrobench-summary.md`
- `results/eval-osdi/paper/20260615T-eval-c2-workload-derived-ledger-v1/b3-macrobench/workload-macrobench-manifest.json`

summary 关键字段为：

- `workload_rows=8`
- `correctness_oracle_passed=5`
- `policy_kvm_rows=5`
- `c2_eligible_rows=0`
- `c2_supported=false`
- `release_gate_pass=false`
- `verdict=derived_contract_only`

随后运行 hard gate：

```text
make eval-osdi-workload-macrobench \
  RUN_ID=20260615T-eval-c2-workload-derived-hardgate-v1 \
  EVAL_OSDI_PHASE1_RUN_ID=20260615T-full-phase1-c2-release-sample-v1
```

该 target 写出同 schema artifacts 后按预期失败。最终 `jq -e` 没有找到
`release_gate_pass=true` 且 `c2_supported=true` 的 summary row，外层捕获的 Make 退出码为
2。这是正确结果：派生 inventory 不能被误写成 C2 支持证据。

## 当前 workload 状态

- W1 Redis/nginx：已有 host build trace 和 KVM build/release replay witness，但缺 KVM
  per-sample build-graph setup/update macrobench。
- W2 nginx：已有 KVM app health oracle，但缺 config/secret rotation per-sample macrobench
  和同 workload baseline comparison。
- W2 PostgreSQL：fixture manifest 存在，但真实 app oracle 未实现。
- W3 Redis：已有 KVM replay witness，但真实 Podman/CRIU restore、epoch/update macrobench
  和 feature-equivalent baseline 缺失。
- W3 nginx：checkpoint manifest 存在，但真实 restore oracle 未实现。
- W4 ccache：已有真实 ccache KVM witnesses，但缺 release operation-weighted hit rate、
  stale/update macrobench 和同 workload baseline comparison。
- W4 BuildKit/Prometheus：cache manifest 存在，但真实 BuildKit/Prometheus cache run 未实现。

## 结论

本步骤完成的是 C2 workload macrobench 的 derived-contract 层。它提高了实验台账的可审计性，
但不改变 claim verdict：C2 仍为 unsupported。下一步如果继续 C2，最小可运行 PoC 应选择
W2 nginx fixture 或 W4 ccache，在修改内核 KVM 内做真正的 per-sample setup/update
macrobenchmark，并引入同 workload feature-equivalent baseline 和显式阈值。
