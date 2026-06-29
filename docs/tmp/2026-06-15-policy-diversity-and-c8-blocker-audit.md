# Policy diversity 和 C8 blocker 审计

> 2026-06-29 baseline scope update: this note preserves historical reasoning and results, but older C8/B12 baseline-gate wording is superseded by `docs/tmp/2026-06-29-redirect-table-novelty-position.md`. Current evaluation uses claim-driven, workload-appropriate baselines. Exact-map diagnostics are optional and only relevant when precomputed mapping is the competing claim.

日期：2026-06-15

## 背景

独立 subagent `Volta` 给出的 OSDI review 结论是 `blocked`。它认为当前文档没有把
W3 Redis replay overclaim 成 C1/C8 或真实 Podman/CRIU restore，但 policy diversity 和
table-only counterfactual 仍不足以支撑“必须需要 programmable path-resolution
abstraction”的 C8 claim。

本记录审计当前四个主线 policy family 的实现形态和 release-level blocker。

## 检查的代码路径

- `bpf/policies/build_graph_view.bpf.c`
- `bpf/policies/sandbox_fixture_view.bpf.c`
- `bpf/policies/checkpoint_restore_view.bpf.c`
- `bpf/policies/cache_locality_view.bpf.c`
- `docs/experiment-plans/osdi-evaluation.md`
- `results/phase1/20260615T-parent-key-poc/summary.md`
- `results/phase1/20260615T-parent-key-poc/table-budget.jsonl`

## 当前实现判断

### `build_graph_view.bpf.c`

当前实现有 generated/source/toolchain/external-dep/poison/negative 分支名义，但实际
decision path 主要是：

- literal component checks：`config.h`、`version.h`、`cc`、`libssl.so`、`private.h`、
  `missing.h`；
- fallback 到 `build_graph_rules` map lookup。

这能作为 Phase 1 branch semantics witness，但还不像 release-level build-graph policy：
缺完整 trace-derived alias set、release-level poison/negative natural workload hit、
operation-weighted redirected hit rate，以及 table/update budget counterfactual。

### `sandbox_fixture_view.bpf.c`

当前实现覆盖 config、secret、cert、endpoint 和 poison aliases，但 decision path 仍主要是：

- literal component checks：`nginx.conf`、`postgresql.conf`、`db.password`、
  `server.crt`、`upstream.sock`、`prod.token`；
- fallback 到 `fixture_rules` map lookup。

W2 nginx real gate 已证明真实 nginx config/endpoint path 能观察到 policy redirect，
但还缺 PostgreSQL real app oracle、trace-level no-real-open checker、endpoint matrix、
startup trace、operation-weighted hit rate 和 table/update budget counterfactual。

### `checkpoint_restore_view.bpf.c`

当前实现比 W1/W2 更接近独立 policy family：它有 `checkpoint_sessions`、
`checkpoint_rules`、path class 和 checkpoint epoch key。lookup 会按 state/config/cache/
runtime/mixed-epoch path class 顺序尝试 rule。

但当前 evidence 仍不够：W3 Redis replay 只证明真实 Redis RDB load path 可通过 policy
读取 hidden checkpoint backing；raw summary 明确 `podman_criu_restore_executed=false` 和
`qualified_for_c8=false`。它还缺真实 checkpoint archive、restore health、post-restore
VFS trace、state/config/cache hash、0 mixed epoch oracle 和 table/update budget
counterfactual。

### `cache_locality_view.bpf.c`

当前实现最接近可编程：`cache_rule` 包含 verified hit、canonical、reject 三类 redirect，
并按 cache state 和最多 4 个 hash witness 决定 verified-hit、stale/miss canonical、
corrupt/reject 或 pass-through。

W4 evidence 已经补过一轮：`kvm-w4-ccache-policy-compile` 把真实 Redis/nginx ccache
hot compile 放进 `namei_ext` policy attach window，4 个 trace-derived cache objects
由 `cache_locality_view.bpf.c` 重定向，output object hash 与 baseline hot object
一致，ccache stats 记录 `direct_cache_hit=2`。这消除了 “真实 ccache compile 阶段完全没有
执行 policy” 的第一层缺口。

后续又补了 `kvm-w4-ccache-table-compile`：同一份真实 `CCACHE_DIR`、同一组
Redis/nginx source file 和同一组 4 个 trace-derived cache objects 在
`table_redirect.bpf.c` exact redirects 下也通过，output object hash 匹配，ccache stats
同样记录 `direct_cache_hit=2`。这说明当前 sampled W4 witness 能被 table-only 解释，
因此它是 C8 的负面证据。

W4 当前 evidence 仍不足：该 witness 只覆盖 sampled hot compile 和 verified-hit path，
没有 release-level operation-weighted policy cache hit rate、真实 stale/corrupt
transition、stale window/update writes、BuildKit/Prometheus Go cache path trace，且
没有 table-only 在同等 budget 下失败、过度物化或 stale/update 门槛不达标的证据。

## C8 当前为什么不成立

当前 `table_redirect.bpf.c` 在 W1/W2/W3/W4 path/probe oracle 上均能通过，W4
table-only ccache compile comparator 也能通过当前 sampled output oracle，table-budget
artifact 仍记录 `qualified_for_c8=false`。这意味着当前证据最多说明：

- 同一个 ABI 可以执行多份 policy object；
- 每个 policy object 有自己的 Phase 1 semantic branch；
- KVM attach path、lookup/readdir consistency 和 raw result gates 可运行。

它还不能说明：

- table-only 在同等 table/update budget 下无法满足 workload oracle；
- eBPF 程序的算法路径比 generic `(parent, component) -> target` table 有必要性；
- 多个真实 workload/trace row 触发了不同 policy family 的核心算法分支；
- 当前系统达到了 OSDI weak accept。

## 下一步实现顺序

最高价值顺序：

1. W1：从 Redis/nginx release trace 自动生成更完整 alias set，记录 operation-weighted
   redirected hit rate，并让 poison/negative 分支在 release workload 中自然触发或证明为何
   需要专门 fault workload。
2. W2：补 PostgreSQL 或 Redis real-app fixture oracle，并增加 trace-level no-real-secret/
   config/cert checker。
3. W3：补真实 Podman/CRIU restore witness，或至少固定 checkpoint archive + restore
   trace，并只统计 restore 后新发生的 VFS lookup/readdir。
4. W4：把当前真实 ccache policy-attached compile witness 扩展成 release-level workload，
   记录 operation-weighted policy cache hit rate、真实 stale/corrupt transition、update/stale
   window，并补 BuildKit/Prometheus Go cache path trace；同时保留当前 table-only pass
   作为负面证据，直到 release-level table/update budget 反事实失败。
5. B12/table-only：为每个 family 记录 table entries、update writes、stale window、
   setup/object materialization 和 verifier/map stats；只有 table-only 在同等 budget 下失败、
   过度物化或 stale window 不达标时，才能把 C8 升级。

## 结论

当前 policy family 多样性作为设计方向成立，但实现证据还停留在 Phase 1 functional
witness 层。C8 仍是 blocker，不能把当前论文或项目标为 OSDI weak accept。
