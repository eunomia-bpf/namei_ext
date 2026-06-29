# W4 release-level cache counterfactual 设计

> 2026-06-29 baseline scope update: this historical record preserves prior reasoning and results. Current C8/B12 guidance is claim-driven baseline selection; exact-map diagnostics are optional boundary evidence only when precomputed mapping is the competing claim.

Last updated: 2026-06-15
Stage at update: supplement / execute planning
Source/command: goal resume after `20260615T-parent-key-poc` Phase 1 run and Poincare table-comparator review
Completeness: partial

## 背景

当前 W4 已经有真实 `ccache` hot compile 在 KVM guest 的 policy attach window 内运行：
`make kvm-w4-ccache-policy-compile RUN_ID=20260615T-parent-key-poc` 记录
`ccache_compile_policy_executed=true`、`policy_redirected_cache_objects=4`、
Redis/nginx output object hash match 和 0 failure。

但是同一批 sampled trace-derived cache objects 也被
`make kvm-w4-ccache-table-compile RUN_ID=20260615T-parent-key-poc` 通过。该结果是
C8 的负面证据：如果 oracle 只覆盖预先抽样出来的 4 个 exact entries，
`table_redirect.bpf.c` 可以直接枚举 `(event, parent, component) -> target` 并通过。

因此 W4 下一步不能只是增加几个 sampled redirect。它必须把实验升级为 release-level
counterfactual：在真实 workload 产生的 cache footprint 上，比较可编程
cache-locality policy 和 exact table baseline 的正确性、entry/update 成本、stale
window 和操作加权 hit rate。

## 真实来源

W4 仍绑定三个真实来源，不使用手写 toy cache workload 作为 C8 主证据。

- `ccache`：官方 manual 说明 ccache 通过缓存编译结果加速重新编译；它的 direct mode
  会维护 manifest，`hash_dir` 会把 CWD 纳入 hash，`ignore_headers_in_manifest` 可能导致
  stale hit 风险，`read_only` / `read_only_direct` 又体现了只消费既有 cache 的真实模式。
  来源：https://ccache.dev/manual/4.13.6.html
- Docker BuildKit cache mount：Docker 文档把 cache mount 定义为 build step 使用的
  persistent package cache，重建 layer 时可以复用未变化的包内容。来源：
  https://docs.docker.com/build/cache/optimize/
- Go module cache / Prometheus：Go modules reference 说明 module cache 存放下载的
  module files，默认在 `$GOPATH/pkg/mod`，可由 `GOMODCACHE` 指定；Prometheus 是固定的
 真实 Go module workload，当前仓库已固定 `v2.55.1` source provenance。来源：
  https://go.dev/ref/mod 和 https://github.com/prometheus/prometheus

## 当前证据为什么不够

当前 `cache_locality_view.bpf.c` 的 release witness 仍主要是 exact cache object rules：

```text
lookup(cache_parent, object)  -> object.local
readdir(cache_parent, object.local) -> object
```

这对证明机制可运行有价值，但对 C8 不够。原因是 exact table baseline 可以用同样的
key/value 形态表达每个已知 object。只要 workload oracle 的对象集合在运行前已经完整
抽样，table baseline 就能抄答案。

因此 C8 的最低可接受条件必须是以下至少一项：

1. 同等正确性 oracle 下，exact table 需要显著更多 entries 或 map update writes；
2. table 必须预物化完整 workload footprint 才能通过，而 programmable policy 只需要
   parent/state/class 级别规则；
3. table 在真实 stale/corrupt/update 转换下产生超过门槛的 stale window 或错误 hit；
4. table 在同等 map/update budget 下不能覆盖 workload 的 operation-weighted file-op
   stream，而 programmable policy 达到预设 hit-rate 门槛。

如果 table 仍能在同等 budget 下通过，W4 必须继续标记为 `qualified_for_c8=false`。

## 新的 policy 形态

下一步 W4 policy 不应继续只做 exact-key redirect。需要在
`cache_locality_view.bpf.c` 中增加 parent-scoped transformation rule：

```text
cache parent class + event + component + cache state -> redirect decision
```

具体 Phase 1 PoC：

- 用户态 runner 从真实 ccache/BuildKit trace 中识别 cache object parent directories；
- policy map 只写入 parent-level rule，而不是每个 object 一个 rule；
- lookup 事件中，若 parent 命中 verified local-cache class，policy 把 component
  改写为 `<component>.local`；
- readdir 事件中，若 lower entry 以 `.local` 结尾，policy 去掉 suffix 并暴露 alias；
- `stats`、lock、tmp、config 和 create path 必须 PASS，不作为 cache object redirect；
- stale/corrupt 状态不能返回 local object，必须走 canonical 或 reject target。

这个 policy 与 exact table 的算法复杂度不同：

```text
programmable parent rule:
  rule writes = O(P + S)
  lookup decision = O(1) parent lookup + bounded component transform
  readdir decision = O(1) parent lookup + bounded suffix strip

exact table baseline:
  rule writes = O(N objects * E events)
  lookup decision = O(1) exact lookup
  readdir decision = O(1) exact lookup
  但必须提前枚举 N 个真实 cache objects
```

其中 `P` 是 cache leaf parent 数，`S` 是状态规则数，`N` 是 workload 产生的 cache object
数，`E` 至少包含 lookup 和 readdir 两类事件。只有当真实 workload 让 `N` 明显大于
`P + S`，或者发生 state/update 转换时 table update 明显更贵，这个 family 才能支撑
C8。

## Release-level workload contract

新增目标应保持 Makefile-only，并在 KVM guest 内运行修改后的 kernel：

```text
make kvm-w4-ccache-release-counterfactual RUN_ID=...
```

最小 release-level 版本先使用真实 Redis 和 nginx source tree：

1. 在 guest 内创建独立 `CCACHE_DIR`；
2. 使用真实 `ccache gcc -c` 或 release build 子集 warm cache；
3. 记录 ccache version、compiler version、source SHA256、compile command list 和 raw
   stdout/stderr；
4. 从 warm cache 中抽取真实 cache object footprint，排除 `stats`、tmp、lock 和 config；
5. 把真实 cache objects rename 为 hidden `.local` backing；
6. attach `cache_locality_view.bpf.c`，写入 parent-scoped rules；
7. 运行同一真实 hot workload；
8. 保存 output object hash、ccache stats、policy redirect count、per-parent rule count、
   per-object footprint count、operation-weighted cache-path trace 和 dmesg；
9. 用 `table_redirect.bpf.c` 复跑同一 workload，并记录 table entries、map update writes、
   update latency、stale window 和 output hash；
10. report 只从 raw JSONL/TSV/logs 计算 ratio，不在 runner 内写论文解释。

第二个 release-level 版本使用 Prometheus / Go module cache 或 BuildKit cache mount：

- 固定 Prometheus source、Go version、`GOMODCACHE` 或 BuildKit cache mount path；
- 运行真实 `go test` / `go build` 或 BuildKit build step；
- trace module-cache / build-cache file operations；
- 比较 policy parent rule 与 exact table 对 module/cache footprint 的 entry/update 成本；
- 保存 output hash 或 test result oracle。

## Oracle 和成功条件

W4 C8 合格前必须同时满足：

- 正确性：policy run 和 baseline run 的 output hash/test result 等价；
- 真实性：workload 来自 Redis/nginx/Prometheus/BuildKit，不是自造循环；
- KVM：全部 policy path 在修改后的 kernel guest 内执行；
- 覆盖：cache-path trace 中真实触碰 cache root，且 policy attach window 内触发；
- 反事实：table baseline 必须被同等 correctness oracle 和同等 budget 检验；
- 解释：若 table 通过，结果必须保留为负面证据，不能升级 C8；
- 预算：记录 `policy_rule_writes`、`table_rule_writes`、`cache_objects`、
  `cache_leaf_parents`、`update_latency_ms`、`stale_window_ms` 和
  `operation_weighted_policy_cache_hit_rate`。

初始门槛沿用 `configs/eval-osdi/policy-budgets.mk`：

- `OSDI_CACHE_MIN_STATE_TRANSITION_HIT_RATE >= 0.80`
- `OSDI_TABLE_MAX_OVER_MATERIALIZATION_RATIO <= 10`
- `OSDI_TABLE_MAX_UPDATE_WRITES_RATIO <= 10`
- `OSDI_TABLE_MAX_STALE_WINDOW_MS <= 100`
- `OSDI_TABLE_MAX_UPDATE_LATENCY_MS <= 1000`

## 需要修改的代码路径

- `bpf/policies/cache_locality_view.bpf.c`：增加 parent-scoped suffix transform rule；
- `tests/w1_oracle/namei_ext_w1_oracle.c`：增加 release counterfactual runner mode，保存 raw
  per-object/per-parent observations；
- `mk/kvm.mk`：新增 KVM target 和 guest target；
- `mk/report.mk`：新增 hard gate，但只计算 ratio 和检查 raw artifact；
- `docs/research_plan.md`、`docs/experiment-plans/osdi-evaluation.md` 和
  `docs/paper/sections/05-evaluation.tex`：更新 W4 evidence 等级。

## 风险

- 当前 ABI 只有 lookup flags，没有 open intent 的完整读写语义；因此该 release target
  必须只把已有 cache object 的 read path 计入 policy hit，create/update path 必须 PASS。
- ccache 的 object fanout 可能让 `N/P` 比例不够大；如果 Redis/nginx 子集太小，需要扩大
  到完整 release build 或切换到 Go module cache/BuildKit cache mount。
- Parent-scoped suffix transform 不能跨目录 redirect。它只证明同父目录 cache object
  alias，这和当前 Phase 1 ABI 一致；跨目录 CAS/store lookup 是后续 ABI 工作。
- 如果 exact table 在完整 release workload 和同等 budget 下仍然通过，C8 必须继续
  blocked，论文只能声称 W4 证明了可运行性而非可编程必要性。

## 结论

W4 下一步的实现目标不是“更多 exact redirect”，而是把 cache-locality policy 从
object-level table mimic 升级为 parent/state/class 级别的 bounded BPF decision。只有
真实 ccache/BuildKit/Go workload 让该 policy 与 `table_redirect.bpf.c` 在 budget 或
state-transition oracle 上分叉时，W4 才能作为 C8 的支持证据。
