# W1 host build-output oracle 实现记录

最后更新：2026-06-14
更新阶段：Phase 1 实现
来源/命令：`make workload-w1-build-output-oracle RUN_ID=20260614T-w2-nginx-probes-phase1` 和 `make kvm-w1-oracle RUN_ID=20260614T-w2-nginx-probes-phase1`
完整性：部分完成

## 背景和动机

W1 build-graph use case 是当前最接近真实生产 workload 的证据链：Redis `7.2.14`
和 nginx `1.26.3` 已经由 Makefile 获取、校验、构建、strace，并生成
trace-witness manifest。已有 `make kvm-w1-oracle` 能在修改后的 kernel KVM guest 中
验证 trace-derived entries 沿真实 `cgroup/namei_ext` attach path 执行 lookup/readdir
oracle。

缺口是：W1 文档一直把 build output hash 作为 release blocker，但构建输出本身没有独立
raw oracle。这样会让后续审查难以区分三件事：

1. 真实 host source build 是否确实产出了可审计 binary hash；
2. KVM path oracle 是否把这些真实构建证据纳入输入完整性链；
3. 发布级 KVM policy build replay 是否已经完成。

本次实现只解决前两点，不声称完成第三点。

## 调研过的代码路径

- `mk/workload.mk`
  - W1 real build targets：`$(REDIS_BUILD_JSON)`、`$(REDIS_TRACE_JSON)`、
    `$(NGINX_BUILD_JSON)`、`$(NGINX_TRACE_JSON)`。
  - W1 manifest/alias targets：`$(REDIS_MANIFEST_JSON)`、
    `$(REDIS_ALIAS_MANIFEST_JSON)`、`$(NGINX_MANIFEST_JSON)`、
    `$(NGINX_ALIAS_MANIFEST_JSON)`。
  - W1 oracle TSV target：`$(W1_ORACLE_ENTRIES_TSV)`。
- `mk/kvm.mk`
  - `kvm-w1-oracle` host-side dependency graph。
  - `__phase1_guest_w1_oracle` guest-side input checks and
    `w1-oracle-inputs.sha256` generation。
- `mk/report.mk`
  - `report` hard gate for W1 input sha256, W1 result-level checks, and summary
    generation。
- `docs/research_plan.md`、`docs/experiment-plans/osdi-evaluation.md`、
  `docs/paper/sections/04-implementation.tex`、`docs/paper/sections/05-evaluation.tex`
  and `docs/paper/evaluation.md`。

## 设计选择

新增 Make target：

```text
make workload-w1-build-output-oracle RUN_ID=<run>
```

输出 artifact：

```text
results/workloads/runs/<run>/w1-build-output-oracle.jsonl
```

每个 workload row 记录：

- `result_level=host_real_build_output_oracle`
- `run_environment=host`
- `policy_executed=false`
- `kvm_validated=false`
- `output_hash_oracle=false`
- `host_output_hash_oracle=true`
- `release_output_hash_oracle=false`
- `output_hash_oracle_scope=host`
- `qualified_for_c8=false`
- build binary path and SHA256
- trace build binary path and SHA256
- build/trace duration
- trace file-operation line count
- source manifest path and SHA256

summary row 要求两个 workload row 都 pass。pass 条件是：

- build JSON schema 为 `namei_ext.real_workload_build.v1`；
- trace JSON schema 为 `namei_ext.real_workload_trace.v1`；
- build 和 trace binary SHA256 都是 64 位 hex；
- duration 为正；
- trace file-operation 行数大于 1000；
- 记录的 binary path 存在、可执行，且 SHA256 与 JSON 字段一致。

## 为什么不直接标成 release-level oracle

该 target 在 host 上验证真实构建输出，不在 KVM guest 中执行 Redis/nginx build，也没有在
policy attached 时做 build replay。因此它不能证明 `build_graph_view.bpf.c` 在真实构建
过程中产生正确 output hash，也不能证明 undeclared dependency poison、negative fallback、
operation-weighted redirected hit rate 或 table/update budget counterfactual。

所以所有 row 明确保留：

```text
policy_executed=false
kvm_validated=false
qualified_for_c8=false
```

## 与 KVM W1 gate 的连接

`kvm-w1-oracle` 现在依赖：

```text
workload-w1-build-output-oracle
```

`__phase1_guest_w1_oracle` 会检查 `w1-build-output-oracle.jsonl` 存在，并把它加入：

```text
results/phase1/<run>/w1-oracle-inputs.sha256
```

这样 W1 KVM path oracle 仍只执行 path semantics，但它的输入完整性链包含真实构建输出
oracle。`report` 会检查 `w1-oracle-inputs.sha256` 正好包含 10 个输入，并校验其中包含
`w1-build-output-oracle.jsonl`。

## Report gate

`make report` 新增硬检查：

- `$(W1_BUILD_OUTPUT_ORACLE)` 存在且非空；
- `w1-build-output` pass row 数量为 2；
- `w1-build-output-summary` pass row 数量为 1；
- 所有 row 都是 `host_real_build_output_oracle`；
- 所有 row 都是 `policy_executed=false`、`kvm_validated=false`、
  `qualified_for_c8=false`；
- workload set 精确等于 `w1-nginx-build` 和 `w1-redis-build`；
- W1 oracle input event 记录 `build_output_oracle` 路径。

报告中新增 `W1 Host Real Build Output Oracle` 小节，列出 workload、pass、build binary
SHA256、trace file-op lines、C8 状态和 detail。

## 已执行验证

生成 host oracle：

```text
make workload-w1-build-output-oracle RUN_ID=20260614T-w2-nginx-probes-phase1
```

结果：

- `w1-redis-build` pass，build binary SHA256 为
  `c6676758f2b9ddd7f6179602291fa3ab0c10cb8ab202a73fe0eda58051581d3f`；
- `w1-nginx-build` pass，build binary SHA256 为
  `d62549c506b5b572bbb905f81a8009fc4912b9bbab6dddfe9ab9eb628cf214e7`；
- summary pass，failures 为 0。

重跑 KVM W1 path oracle：

```text
make kvm-w1-oracle RUN_ID=20260614T-w2-nginx-probes-phase1
```

结果：

- KVM guest 内 `w1-oracle.jsonl` 重新生成成功；
- `w1-oracle-inputs.sha256` 行数为 10；
- `sha256sum -c results/phase1/20260614T-w2-nginx-probes-phase1/w1-oracle-inputs.sha256`
  全部 OK；
- W1 oracle input row 包含 `build_output_oracle` 字段。

## 剩余风险和后续工作

- 这仍然不是 KVM policy build replay。下一步若要推进 C1，需要在 KVM guest 内运行
  Redis/nginx build 或 trace replay，并在 policy attached 时验证 output hash。
- 当前 trace-witness entries 仍是手工候选，不是完整 trace-derived alias set；release
  gate 仍需要 operation-weighted redirected hit rate。
- 当前 W1 缺 undeclared dependency poison 和 negative fallback 的真实 workload hit。
- 当前 table baseline 在 W1 path oracle 上通过；C8 仍需要 table/update budget
  counterfactual 证明 static table 在同等预算下失败。
