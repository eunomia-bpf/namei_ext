# w1-redis-build 证据

状态：`source-build-trace` + `functional_only_kvm_path_oracle` + KVM release-binary
replay witness + KVM branch-probe witness。host-side 真实源码构建、strace 和
trace-witness manifest 已通过；KVM path oracle、policy preprocessing replay、
release-binary replay 和 poison/negative branch probes 已在修改内核 guest 中通过。
完整 trace-derived alias set、release-level poison/negative natural workload hit、
operation-weighted hit rate 和 table/update budget counterfactual 仍未验证。

Policy family：`build_graph_view.bpf.c`

## 真实来源

- Redis repository: https://github.com/redis/redis
- Redis top-level Makefile:
  https://github.com/redis/redis/blob/f2262eccb855eadd1afb0c457ea583ef9d5400b5/Makefile
- Redis src Makefile:
  https://github.com/redis/redis/blob/f2262eccb855eadd1afb0c457ea583ef9d5400b5/src/Makefile
- Redis configuration documentation:
  https://redis.io/docs/latest/operate/oss_and_stack/management/config/

## 固定 provenance

- 固定 release：Redis `7.2.14`
- 固定 tag commit：`f2262eccb855eadd1afb0c457ea583ef9d5400b5`
- tarball SHA256：
  `704bfac84ab1c0771ddc08c8bea72e2203e3ce64c1fc6750e76b8ce2c00f3145`
- license file hash：
  `97f0a15b7bbae580d2609dad2e11f1956ae167be296ab60f4691ab9c30ee9828`
- source provenance target：`make workload-redis-build-fetch`
- source provenance result：`results/workloads/provenance/redis-source.json`

## Make targets

- build command：`make workload-redis-build`
- trace command：`make workload-redis-build-trace`
- source-build-trace manifest：`make workload-redis-build-manifest`
- trace-witness manifest：`make workload-redis-build-alias-manifest`
- KVM path oracle：`make kvm-w1-oracle`
- KVM release binary replay witness：`make kvm-w1-release-build-replay`
- KVM poison/negative branch probes：`make kvm-w1-branch-probes`

## 已观察 run

- Run ID：`20260615T-parent-key-poc`
- source-build-trace manifest：
  `results/workloads/runs/20260615T-parent-key-poc/w1-redis-build/manifest.json`
- trace-witness manifest：
  `results/workloads/runs/20260615T-parent-key-poc/w1-redis-build/alias-manifest.json`

## 当前 host trace-witness

- Trace size：`1,224,839` file-operation lines
- Candidate entries：`4`
- Candidate trace hits：`5,692`
- `candidate_witness_hit_rate` over all strace `%file` operations：
  `0.004647141379397619`
- 已观察分支：generated output、declared source fallback、toolchain selection、
  external dependency
- KVM branch-probe 已覆盖但 host trace 未自然命中：undeclared dependency poison、
  negative fallback
- Policy 执行状态：`policy_executed=false`
- KVM 验证状态：`kvm_validated=false`
- Output hash oracle：`output_hash_oracle=false`
- 发布级 gate 状态：`release_gate_eligible=false`
- Policy execution basis：`host_trace_only`

Redis build/trace recipe 设置 `GIT_CEILING_DIRECTORIES` 到 per-run source root，
避免 Redis release-header 生成过程调用 git 后向上扫描父项目 repository，从而污染
file-operation trace。

## 当前 KVM path oracle

- Run ID：`20260615T-parent-key-poc`
- KVM raw result：
  `results/phase1/20260615T-parent-key-poc/w1-oracle.jsonl`
- KVM input hash manifest：
  `results/phase1/20260615T-parent-key-poc/w1-oracle-inputs.sha256`
- 该 gate 从 W1 Redis/nginx trace-witness manifests 生成 9 个 entries，在修改内核
  KVM guest 中为每个 entry 创建独立 synthetic directory，并分别运行
  `build_graph_view.bpf.c` 和 `table_redirect.bpf.c`。两个 policy summary 均为
  0 failure。
- 该 gate 只验证 per-entry lookup/readdir path semantics、attach/detach 行为和
  table baseline conformance；它不运行完整 Redis build，不验证 output hash、
  operation-weighted redirected hit rate 或 table/update budget failure。

## 当前 KVM setup/update macrobench release input

- Smoke Run ID：`20260616T-w1-build-macrobench-smoke-v3`
- Release Run ID：`20260616T-w1-build-macrobench-release-sample-v1`
- KVM raw result：
  `results/phase1/20260616T-w1-build-macrobench-release-sample-v1/w1-build-macrobench.jsonl`
- KVM input hash manifest：
  `results/phase1/20260616T-w1-build-macrobench-release-sample-v1/w1-build-macrobench-inputs.sha256`
- 该 gate 使用真实 Redis/nginx trace source、9 个 W1 trace-derived entries 和
  `build_graph_view.bpf.c`，在修改内核 KVM guest 中写出 20 条 setup rows、20 条
  update rows 和 20 条 correctness rows。summary 为 `samples=20`、`pass=true`、
  `failures=0`、`policy_executed=true`、`kvm_validated=true`、`c2_supported=false`、
  `release_gate_pass=false`；host 侧 `sha256sum -c` 通过。
- 该 gate 的 correctness oracle 是 baseline/policy preprocessing output
  byte-for-byte match，不是本步骤内完整 release binary rebuild。它证明 W1
  proposed-system setup/update release input 可在 KVM 中跑通，但仍缺 W1
  feature-equivalent baselines、storage/threshold ledger 和 W3/W4 对等 macrobench。

## Semantic witness 要求

- generated output precedence
- declared source fallback
- toolchain selection
- external dependency path
- undeclared dependency poison（已有 KVM branch probe；仍需 release-level natural
  workload hit 才能计入 C8）
- negative miss（已有 KVM branch probe；仍需 release-level natural workload hit 才能计入 C8）

## Oracle 要求

- KVM release-binary replay witness output hash：baseline/policy 规范化 binary 均为
  `65c8f5155d78a1a04ebb937cf7c85483b8320e1444686a691694c46e83f2de8b`；
  raw evidence 是
  `results/phase1/20260615T-parent-key-poc/w1-release-build-replay.jsonl`，
  output hash manifest 是
  `results/phase1/20260615T-parent-key-poc/w1-release-build-replay-outputs.sha256`。
  该 witness 仍记录 `release_output_hash_oracle=false` 和
  `qualified_for_c8=false`，不是完整 C8 workload oracle。
- declared input manifest hash
- dependency leak checker
- poison sentinel report
- lookup/readdir visible set checker

## Raw results

- Host source-build-trace：
  `results/workloads/runs/20260615T-parent-key-poc/w1-redis-build/`
- KVM path oracle：
  `results/phase1/20260615T-parent-key-poc/w1-oracle.jsonl`
- KVM release-binary replay witness：
  `results/phase1/20260615T-parent-key-poc/w1-release-build-replay.jsonl`
- KVM release-binary replay output hashes：
  `results/phase1/20260615T-parent-key-poc/w1-release-build-replay-outputs.sha256`
- KVM branch probes：
  `results/phase1/20260615T-parent-key-poc/w1-branch-probes.jsonl`
- KVM setup/update macrobench release input：
  `results/phase1/20260616T-w1-build-macrobench-release-sample-v1/w1-build-macrobench.jsonl`
- Final C8 release-level KVM policy validation：
  `results/eval-osdi/paper/<run-id>/workloads/w1-redis-build/`（`TBD`）

当前证据不能计入 C1/C8。它证明真实 Redis source build、trace 采集、trace-witness
manifest 生成路径可复现，并证明这些 trace-derived entries 能沿真实 KVM attach path
执行；后续 release-binary replay、branch-probe witness 和 20-sample setup/update
release input 进一步证明 attached policy 路径可支撑 Redis/nginx preprocessing
equivalence、poison/negative 分支语义和 proposed-system release repetition，但这些结果仍
不是完整 trace-derived alias set、release-level natural branch hit、feature-equivalent
baseline 或 table/update budget counterfactual。
