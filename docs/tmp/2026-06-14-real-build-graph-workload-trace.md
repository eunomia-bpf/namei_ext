# 真实 build-graph workload trace 记录

日期：2026-06-14

## 动机

OSDI 评估计划要求使用真实 workload，而不是手写 path loop 或玩具 fixture。
source provenance 只能证明固定上游输入可以下载，不能证明项目已经可以从这些输入
完成构建、采集 trace 并保存可审计的 raw evidence。

本步骤把两个 W1 build-graph workload 变成 Makefile-owned 的可执行输入：

- Redis `7.2.14`
- nginx `1.26.3`

这些结果仍然只是 host-side source-build-trace。它们还没有在 KVM 中验证
`build_graph_view.bpf.c`，在 KVM policy oracle 和 table-only counterfactual
通过前不能作为 C1/C8 论文证据。

## 修改文件

- `mk/workload.mk`
- `Makefile`
- `workload/README.md`
- `workload/w1-redis-build/evidence.md`
- `workload/w1-nginx-build/evidence.md`
- `docs/research_plan.md`
- `docs/experiment-plans/osdi-evaluation.md`

## 设计选择

所有 orchestration 都由 Makefile 拥有，没有新增项目自有 shell scripts。

新增或更新的目标：

- `make workload-build-graph`
- `make workload-redis-build`
- `make workload-redis-build-trace`
- `make workload-redis-build-manifest`
- `make workload-redis-build-alias-manifest`
- `make workload-nginx-build`
- `make workload-nginx-build-trace`
- `make workload-nginx-build-manifest`
- `make workload-nginx-build-alias-manifest`

每次运行会在 `.build/workloads/runs/<run-id>/<workload-id>/` 下展开干净 source
tree，避免后续 trace 变成 incremental no-op build。

raw outputs 写入 `results/workloads/runs/<run-id>/<workload-id>/`：

- build/configure logs
- `strace` file-operation logs
- build JSON
- trace JSON
- source-build workload manifest JSON
- trace-witness manifest JSON

trace 使用 `strace -f -e trace=%file`，并写入少量 raw log 文件，而不是每个 PID
一个文件。这样 raw observation 仍然可审计，结果目录也不会过度碎片化。

manifest 明确记录 evidence level：

```text
result_level: host_source_build_trace
run_environment: host
policy_executed: false
kvm_validated: false
output_hash_oracle: false
```

这避免 report 代码把 host source-build-trace 误当作 KVM policy evidence。普通
build 和 traced build 会分别记录 binary hash，但这些 hash 不能作为最终 output-hash
oracle。最终 output-hash evidence 必须来自后续 KVM policy run 和 workload-specific
oracle。

Redis build/trace recipe 设置 `GIT_CEILING_DIRECTORIES` 到 per-run source root。
如果不设置，Redis release-header 生成过程会调用 git，并可能向上扫描父项目
`namei_ext` repository，把 kernel/repo 路径污染到 file-operation trace。

## 产物

观察到的验证命令：

```text
make workload-build-graph RUN_ID=20260614T-workloads-git-ceiling
```

观察到的 manifests：

```text
results/workloads/runs/20260614T-workloads-git-ceiling/w1-redis-build/manifest.json
results/workloads/runs/20260614T-workloads-git-ceiling/w1-redis-build/alias-manifest.json
results/workloads/runs/20260614T-workloads-git-ceiling/w1-nginx-build/manifest.json
results/workloads/runs/20260614T-workloads-git-ceiling/w1-nginx-build/alias-manifest.json
```

观察到的 trace size：

```text
w1-redis-build: 1234834 file-operation trace lines
w1-nginx-build: 1796791 file-operation trace lines
```

观察到的普通 build binary hashes：

```text
w1-redis-build: 6abd37c6998c5b97e83699d868556fcc0dc7178e12e27070271a72e3380814e0
w1-nginx-build: 9c587881ce738a3b2a8f251b7c493dca03ea0cc2d18548154a9fb81b89aa7cc1
```

观察到的 trace-witness manifest witness：

```text
w1-redis-build: 4 candidate entries, 5692 candidate trace hits, candidate_witness_hit_rate=0.004609526462666237
w1-nginx-build: 5 candidate entries, 5638 candidate trace hits, candidate_witness_hit_rate=0.0031378162513058003
```

## 验证

执行过的检查：

```text
make workload-build-graph RUN_ID=20260614T-workloads-git-ceiling

jq -e '.schema == "namei_ext.real_workload_manifest.v1" and
       .run_id == "20260614T-workloads-git-ceiling" and
       .status == "source-build-trace" and
       .result_level == "host_source_build_trace" and
       .run_environment == "host" and
       .policy_executed == false and
       .kvm_validated == false and
       .output_hash_oracle == false and
       (.trace.file_op_lines > 1000) and
       (.build.artifacts.binary_sha256 | length == 64) and
       (.trace.artifacts.strace_sha256 | length == 64) and
       (.c1_c8_gate | contains("not_validated"))'

jq -e '.schema == "namei_ext.trace_witness_manifest.v1" and
       .status == "trace_witness" and
       .result_level == "host_trace_witness_manifest" and
       .policy_executed == false and
       .kvm_validated == false and
       .output_hash_oracle == false and
       .release_gate_eligible == false and
       .policy_execution_basis == "host_trace_only" and
       (.candidate_entries | length) >= 4 and
       .semantic_witness.branch_coverage.generated_output == true and
       .semantic_witness.branch_coverage.declared_source_fallback == true and
       .semantic_witness.branch_coverage.toolchain_selection == true and
       .semantic_witness.branch_coverage.external_dependency == true and
       .semantic_witness.branch_coverage.undeclared_dependency_poison == false and
       .semantic_witness.branch_coverage.negative_fallback == false and
       (.hit_rate.candidate_witness_hit_rate >= 0) and
       .hit_rate.release_gate_eligible == false and
       (.hit_rate.numerator_candidate_trace_hits > 0) and
       (.hit_rate.denominator_file_op_lines > 1000) and
       (.c1_c8_gate | contains("not_validated"))'
```

Redis 和 nginx 的两个 manifest gates 都通过。新 Redis trace 没有再扫到
host `namei_ext` repo/kernel 路径污染。

## Subagent review 后的修正

第一版 W1 后，subagent review 找到四个问题：

- `make clean` 会通过 `workload-clean` 删除 workload results。
- archive hash 只记录，没有在解压前 fail-fast 校验。
- `workload-*-manifest` 被描述成 alias manifest，但实际只是 source-build-trace
  evidence 聚合。
- host manifests 缺少机器可读字段来说明 policy 没有执行、KVM 没有验证。

当前实现修正了这些问题：

- `workload-clean` 保留 `results/workloads/`；只有 `workload-clean-results`
  会显式删除 workload results。
- 每次解压 archive 前都会做 SHA256 校验。
- W1 evidence 把 `workload-*-manifest` 命名为 source-build-trace manifest。
- W1 manifests 包含 `result_level`、`run_environment`、`policy_executed`、
  `kvm_validated` 和 `output_hash_oracle`。
- W1 alias-manifest targets 保留手工选择的 candidate entries，并用真实 trace
  命中、文件 hash、branch coverage 和 `candidate_witness_hit_rate` 约束这些
  candidates。
  它们仍然不执行 BPF、不创建 shadow backing files、不在 KVM 中验证 policy。
- Subagent review 后，当前产物已降级命名为 trace-witness manifest：它是手工
  候选 + 真实 trace 命中证据，不是完整 trace parser 生成的 alias set。Make target
  内建 `jq -e` gate，失败不会写出正式 manifest。

## 剩余工作

- 实现 materializer/loader，从 alias manifests 创建 shadow backing files 并填充
  BPF maps。
- 在修改后的 kernel KVM guest 中 attach `build_graph_view.bpf.c`，运行真实 workload
  path。
- 增加 workload-specific oracles：build output equality、dependency leak detection、
  generated/source precedence、poison sentinel handling 和 lookup/readdir visible-set
  checks。
- 在相同 manifest 和 update budget 下运行 `table_redirect.bpf.c` counterfactual。
- 只有这些 gates 全部通过后，`w1-redis-build` 或 `w1-nginx-build` 才能从
  `source-build-trace` 移动到 `validated`。
