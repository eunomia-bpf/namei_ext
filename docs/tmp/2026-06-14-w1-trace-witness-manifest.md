# W1 trace-witness manifest 实现记录

> 2026-06-29 baseline scope update: this historical record preserves prior reasoning and results. Current C8/B12 guidance is claim-driven baseline selection; exact-map diagnostics are optional boundary evidence only when precomputed mapping is the competing claim.

日期：2026-06-14

## 动机

OSDI 级评估不能只说“有真实项目”。W1 build-graph workload 必须证明：

- 上游源码、构建命令和 trace 都可复现；
- candidate entries 必须由真实 trace 命中和文件 hash 约束，而不是没有 workload
  evidence 的手写样例；
- 每个 policy family 的 semantic witness 能被机器字段审计；
- host-side 证据不能被误用为 KVM policy oracle。

本步骤为 Redis `7.2.14` 和 nginx `1.26.3` 增加 Makefile-owned
trace-witness manifest 生成路径。

## 调研和约束

已检查的相关文件：

- `mk/workload.mk`
- `workload/README.md`
- `workload/w1-redis-build/evidence.md`
- `workload/w1-nginx-build/evidence.md`
- `bpf/policies/build_graph_view.bpf.c`
- `bpf/include/namei_ext.h`
- `docs/experiment-plans/osdi-evaluation.md`

当前 Phase 1 BPF ABI 只把 `event`、`cgroup_id` 和当前 component name 传给
policy；没有完整 parent path 字段。因此本步骤不能声称已经有 parent-aware 的
真实 workload policy loader。生成的 `alias-manifest.json` 是 trace-witness
manifest：它保留一组手工选择的 build-graph candidate entries，并用真实 trace
中的命中计数和文件 hash 约束这些 candidates。它不是 trace parser，也不会从
`strace` 自动推导完整 `(event, parent, component)` alias set。

## 实现内容

新增 Make targets：

- `make workload-redis-build-alias-manifest`
- `make workload-nginx-build-alias-manifest`
- `make workload-build-graph` 现在依赖两个 alias manifest target。

输出文件：

- `results/workloads/runs/<run-id>/w1-redis-build/alias-manifest.json`
- `results/workloads/runs/<run-id>/w1-nginx-build/alias-manifest.json`

schema 为 `namei_ext.trace_witness_manifest.v1`。关键字段包括：

- `status=trace_witness`
- `result_level=host_trace_witness_manifest`
- `policy_executed=false`
- `kvm_validated=false`
- `output_hash_oracle=false`
- `release_gate_eligible=false`
- `policy_execution_basis=host_trace_only`
- `candidate_entries`
- `semantic_witness.branch_coverage`
- `hit_rate.candidate_witness_hit_rate`
- `c1_c8_gate=not_validated_until_kvm_policy_oracle_materializer_loader_and_table_counterfactual_pass`

该 target 不创建 shadow backing files，不装载 BPF map，也不启动 KVM。它只把
手工候选、真实 trace 命中和文件 hash 变成后续 materializer/loader 可消费的
候选证据。

## 设计取舍

保留 Makefile-only 控制面，没有新增项目自有 `.sh` 文件。

候选 entries 选择真实 trace 中能命中 build-graph 语义的组件：

- Redis：`release.h`、`server.c`、`cc`、`stdio.h`
- nginx：`ngx_auto_config.h`、`ngx_auto_headers.h`、`nginx.c`、`cc`、`stdio.h`

这些 entries 覆盖 generated output、declared source fallback、toolchain
selection 和 external dependency。clean host build 不会触发 undeclared dependency
poison 或 negative fallback，因此这两个分支明确标记为未覆盖，必须由后续 KVM
policy oracle probes 覆盖。

当前 `hit_rate.candidate_witness_hit_rate` 只表示 candidate substring hits 除以
全部 `strace %file` 行数。它不是发布级 `operation_weighted_alias_hit_rate`，
后者只能由 KVM policy oracle 或 trace replay 在真实 redirected operations 上计算。

Redis 构建和 trace recipe 设置 `GIT_CEILING_DIRECTORIES` 到 per-run source root。
原因是 Redis release-header 生成会调用 git；如果 source tree 位于 `namei_ext`
父项目内部，git 可能向上扫描父项目仓库并把 kernel/repo 路径污染到 trace 中。

## 验证

执行命令：

```text
make workload-build-graph RUN_ID=20260614T-workloads-git-ceiling
```

JSON gate：

```text
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

验证结果：

- Redis trace-witness manifest：4 个 candidate entries，5,692 个 candidate
  trace hits，`candidate_witness_hit_rate` 为 `0.004609526462666237`。
- nginx trace-witness manifest：5 个 candidate entries，5,638 个 candidate
  trace hits，`candidate_witness_hit_rate` 为 `0.0031378162513058003`。
- 两个 manifest 都通过 Make target 内建 JSON gate；gate 失败时 target 会删除
  `.tmp` 并退出，不会产出成功 manifest。
- Redis/nginx 新 trace 没有扫到 host `namei_ext` repo/kernel 路径污染。

## 仍然不能支撑的主张

该步骤不能计入 C1/C8，因为：

- policy 没有在 KVM 中执行；
- BPF maps 没有从 alias manifest 装载；
- shadow backing files 没有 materialize；
- poison 和 negative 分支未由真实 KVM probes 覆盖；
- table-only counterfactual 还没有运行；
- 当前 `candidate_witness_hit_rate` 很低，只能作为 witness，不是发布级
  operation-weighted alias hit rate。

下一步必须实现 KVM materializer/loader/oracle，把该 manifest 转成真实 guest 内
path-resolution 行为，再跑 output hash、dependency leak、poison、lookup/readdir
一致性和 table-only counterfactual。

## Subagent review 后的修正

同日的 OSDI 对抗 review 认为第一版没有 blocker，但有三个 major 风险：

- 第一版文件名和 schema 容易暗示它是真正 trace-derived alias manifest；
- `operation_weighted_alias_hit_rate` 会和发布级 redirected-operation gate 混淆；
- Make target 没有内建 semantic witness fail-fast gate。

修正如下：

- schema/status/result level 降级为 `namei_ext.trace_witness_manifest.v1`、
  `trace_witness` 和 `host_trace_witness_manifest`；
- hit-rate 字段改成 `hit_rate.candidate_witness_hit_rate`，把发布级
  `operation_weighted_alias_hit_rate` 留给后续 KVM oracle/replay；
- alias manifest target 先写 `$@.tmp`，再运行 `jq -e` gate，gate 通过后才
  `mv` 到正式结果；
- 顶层加入 `output_hash_oracle=false`；
- 对 `/usr/bin` toolchain parent 假设加入 fail-fast 检查。
