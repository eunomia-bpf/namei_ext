Last updated: 2026-06-15
Stage at update: execute / claim gate
Source/command: manual audit of `mk/workload.mk`, `mk/kvm.mk`, `tests/w1_oracle/namei_ext_w1_oracle.c`, `bpf/policies/build_graph_view.bpf.c`, `bpf/include/namei_ext_policy.h`, `docs/research_plan.md`, `docs/experiment-plans/osdi-evaluation.md`, and existing W1 result descriptions
Completeness: complete for current Phase 1 evidence boundary; implementation follow-up required

# W1 完整 release binary replay 缺口分析

## 动机

W1 build-graph use case 的最终论文 claim 不能只说“真实构建 trace 中存在几个可被重定向的 component”。如果要达到 OSDI 级别，至少需要能解释下面三个问题：

1. policy 是否沿修改后的 kernel/KVM attach path 真实执行；
2. policy 是否能影响真实 workload 的 path resolution，而不是只在 synthetic 目录中命中；
3. 影响之后的真实构建输出是否仍满足 release binary 等价性，或者差异是否被明确解释。

当前已经有 KVM policy path oracle 和 KVM preprocessing replay witness，但这两个结果都刻意标记为 `qualified_for_c8=false`。本记录的目的，是明确为什么它们还不能升级成完整 release binary replay 证据，以及下一步最小实现应该补什么。

## 已检查文件和代码路径

- `mk/workload.mk`
  - `workload-redis-build-alias-manifest`
  - `workload-nginx-build-alias-manifest`
  - `workload-w1-oracle-entries`
  - `workload-w1-build-output-oracle`
- `mk/kvm.mk`
  - `kvm-w1-oracle`
  - `kvm-w1-build-replay`
  - guest-side `__phase1_guest_w1_build_replay`
- `tests/w1_oracle/namei_ext_w1_oracle.c`
  - `run_build_replay`
  - `prepare_replay_aliases`
  - `run_redis_replay`
  - `run_nginx_replay`
  - `emit_build_replay_case`
- `bpf/policies/build_graph_view.bpf.c`
  - `build_lookup`
  - `build_readdir`
  - `apply_build_rule`
- `bpf/include/namei_ext_policy.h`
  - `struct namei_ext_component_key`
  - `namei_ext_build_component_key`

## 当前 W1 证据

当前 W1 证据分为三层，强度不同：

1. Host real build output oracle。
   `make workload-w1-build-output-oracle` 证明 Redis/nginx 在 host 上可以完成真实源码构建并产出可审计 binary SHA256。它不执行 policy，不在 KVM 内运行，因此只能证明 workload provenance 和输出 hash 可记录。

2. KVM path oracle。
   `make kvm-w1-oracle` 在修改后的 kernel guest 中 attach `build_graph_view.bpf.c` 和 `table_redirect.bpf.c`，对 trace-derived entries 做 lookup/readdir 语义检查。它证明每个 entry 可沿真实 attach path 生效，但目录是 synthetic per-entry directory，不验证真实 Redis/nginx source tree 的 parent/path interaction。

3. KVM policy preprocessing replay witness。
   `make kvm-w1-build-replay RUN_ID=20260614T-w2-nginx-probes-phase1` 在 KVM guest 中复制真实 Redis/nginx source tree，先生成 baseline preprocessed output，再 attach policy 并通过 alias path 生成 policy preprocessed output。已有 raw evidence 显示 Redis baseline/policy output hash 相同，nginx baseline/policy output hash 相同。该结果证明 policy 可以影响真实源码 preprocessing path，但仍不是完整 `make redis-server` 或 nginx release binary replay。

## 为什么现在还不能 claim 完整 release binary replay

### 1. alias manifest 是候选 witness，不是完整 trace-derived alias set

当前 Redis alias manifest 只有 4 个 candidate entries，nginx alias manifest 只有 5 个 candidate entries。二者覆盖 generated/source/toolchain/external-dep 几个代表性分支，但 manifest 自身写明：

- `release_gate_eligible=false`
- `policy_execution_basis=host_trace_only`
- `materialization_status="shadow backing files not created by this target"`

trace hit rate 也说明当前 entries 只是小切片：

- Redis candidate trace hits 是 5,692，`candidate_witness_hit_rate=0.004609526462666237`；
- nginx candidate trace hits 是 5,638，`candidate_witness_hit_rate=0.0031378162513058003`。

这足以证明真实 trace 中存在这些 path-resolution 机会，但不足以证明 release build 全路径都被 policy-aware replay 覆盖。

### 2. 当前 BPF ABI key 没有 parent/path identity

`struct namei_ext_component_key` 当前只包含：

- `event`
- `name_len`
- `cgroup_id`
- `name`

也就是说，map-backed rule 只能按同一个 cgroup 内的 component name 匹配。它不能区分：

- `src/config.h`
- `deps/foo/config.h`
- `objs/config.h`

这种限制对完整 release binary replay 很关键。真实构建中很多 component 名会在不同目录重复出现；如果只按 component 匹配，policy 无法表达 parent-sensitive build graph 规则。当前 preprocessing replay 之所以能跑通，是因为它选择了很少量不会触发严重 parent collision 的 alias，并且 runner 对 Redis/nginx 各跑一个指定源文件的 preprocessing。

### 3. policy 内还有 hard-coded 示例规则

`build_graph_view.bpf.c` 当前内置了示例 literal：

- `config.h -> config.gen.h`
- `version.h -> version.src.h`
- `cc -> cc.real`
- `libssl.so -> libssl.dep`
- `private.h -> poison.dep`
- `missing.h` PASS

这些 literal 有助于 Phase 1 PoC 和 branch witness，但完整 release binary replay 不应该主要依赖 hard-coded component。OSDI 主结论需要证明通用 programmable path-resolution abstraction 可以承载一类 build-graph policy family，而不是某几个文件名特例。

### 4. 当前 replay 只跑 preprocessing，不跑完整 release build

`run_redis_replay` 和 `run_nginx_replay` 调用 `cc -E -P`，分别处理 Redis `src/server.c` 和 nginx `src/core/nginx.c`。它们比较 `.i` 输出，而不是比较最终 `redis-server` 或 `objs/nginx` binary。

这一步很有价值，因为它排除了“policy load 了但真实编译器没有消费 alias”的假阳性。但它只能支持 “KVM policy preprocessing replay witness”，不能支持 “release binary output hash oracle”。

### 5. poison 和 negative fallback 还没有真实 workload hit

当前 alias manifests 明确写明 `undeclared_dependency_poison=false` 和 `negative_fallback=false`。`build_graph_view.bpf.c` 有 `private.h` 和 `missing.h` branch，但真实 Redis/nginx 构建 trace 当前没有这些 branch 的 workload hit。它们可以作为 KVM semantic branch test，但不能直接作为 release workload 主证据。

### 6. table/update budget counterfactual 还没有闭环

W1 的核心论文 claim 是 programmable path-resolution abstraction，而不是“一个 redirect table”。因此 release binary replay 之外，还需要 table baseline/update budget 反事实：

- 同等语义若用 table 表达，需要多少 entries；
- parent-sensitive 或 branch-dependent 规则在 table 中如何膨胀；
- eBPF policy 的 verifier-bounded computation 在 lookup/readdir path 上具体省掉了什么状态枚举。

当前已有 `table_redirect.bpf.c` 和 path oracle，但还没有把完整 W1 policy family 的 state/update budget 与 release workload 绑定。

## 当前结论

当前 W1 证据应被描述为：

> 已完成 KVM policy path oracle 和 KVM policy preprocessing replay witness。它们证明修改后的 kernel attach path 可执行 W1 policy，并且 policy 可影响真实 Redis/nginx source preprocessing 且保持 `.i` 输出等价。它们不等于完整 release binary replay，也不能单独支撑 C1/C8。

当前 W1 证据不应被描述为：

> Redis/nginx 最终二进制产物已经由 policy replay 证明等价。

除非后续补齐完整 release binary build replay，否则 `release_output_hash_oracle`、`output_hash_oracle` 和 `qualified_for_c8` 必须保持 false。

## 下一步最小实现选择

### 路径 A：补 parent-aware rule identity

扩展 kernel/BPF ABI 或 policy key，使 decision function 能看到可验证的 parent identity。可选设计包括：

- parent directory inode/dev generation key；
- kernel-provided parent cookie；
- bounded parent class ID，由用户态 loader/materializer 从 manifest 写入 map；
- event-local path class，而不是完整字符串 path。

这一路径能支持真实构建中的重复 component 名，并且最接近最终 claim。但它会触及 kernel ABI，需要先做 kernel code survey 和 ABI design doc。

### 路径 B：补完整 W1 release-build replay runner

在现有 ABI 不变的前提下，先实现一个保守的 KVM release-build probe：

- 在 guest 中复制 Redis/nginx trace source tree；
- 在 attach 前跑完整 release build，记录 binary SHA256；
- materialize 当前小 alias set；
- attach policy；
- 清理并重跑完整 release build；
- 比较 binary SHA256；
- 结果仍标记 `release_gate_eligible=false`，除非 alias set 和 parent collision audit 也通过。

这一路径代码改动可能较小，但如果不解决 parent identity，只能证明“当前小 alias set 没有破坏 release build”，不能证明完整 programmable build graph semantics。

### 路径 C：补真实 trace 的 poison/negative hit

构造一个来自真实 build workflow 的 declared/undeclared dependency probe，例如：

- 使用 build system 的 generated header dependency 检查触发 missing header fallback；
- 使用 real configure feature probe 触发 negative lookup；
- 使用 dependency hygiene test 触发 poison sentinel。

这一路径能强化 W1 branch diversity，但仍不能替代完整 release binary replay。

## 推荐决策

推荐先做路径 A 的 kernel/ABI survey 和设计文档，再决定是否直接实现 parent-aware key。原因是：

- OSDI claim 要证明 programmable path resolution，而不是 component-name redirect table；
- 当前最大技术缺口是 parent/path identity，不是 Makefile target 数量；
- 如果先堆完整 build runner，很可能得到一个不能泛化的 release-build smoke test；
- parent-aware ABI 也会让 W2/W3/W4 的 policy family 更可信，因为它们同样依赖目录上下文。

在路径 A 完成前，任何 W1 release binary build probe 都只能作为 appendix/non-C8 witness。

## 剩余风险

- parent identity 若暴露过多 VFS 内部状态，可能影响 upstream acceptability；
- parent cookie 若不稳定，可能导致 policy map 和 runtime lookup 不一致；
- 完整 release replay 可能被 toolchain nondeterminism、timestamp、generated header、parallel build order 影响；
- table/update budget counterfactual 需要明确“相同语义”的定义，否则容易变成不公平 baseline；
- 真实 workload hit rate 需要 operation-weighted 而不是只数 candidate trace hits。
