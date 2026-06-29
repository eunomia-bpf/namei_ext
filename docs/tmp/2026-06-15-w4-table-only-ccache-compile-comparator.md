# W4 table-only ccache compile comparator 实现记录

> 2026-06-29 baseline scope update: this historical record preserves prior reasoning and results. Current C8/B12 guidance is claim-driven baseline selection; exact-map diagnostics are optional boundary evidence only when precomputed mapping is the competing claim.

日期：2026-06-15

## 动机

Poincare subagent 的 OSDI 评审指出，C8 的最高风险 blocker 是 table-only
counterfactual 没有在 release workload 上失败。此前 W4 已经有
`cache_locality_view.bpf.c` 的真实 ccache policy-attached compile witness，但这只能证明
programmable policy 可以在 attach window 内服务 sampled ccache hot compile，不能证明
table-only baseline 做不到同一件事。

本步骤的目标不是支持 C8，而是构造一个严格的负面对照：用同一份真实 ccache trace、
同一组 Redis/nginx source file、同一组 4 个 trace-derived cache objects 和同一套 KVM
runner，把 policy 换成 `table_redirect.bpf.c`。如果 table-only 也通过，则当前 W4
witness 必须继续标记 `qualified_for_c8=false`。

## 检查和修改的代码路径

- `tests/w1_oracle/namei_ext_w1_oracle.c`
  - 把 ccache compile runner 参数化为 `POLICY_CACHE_LOCALITY` 和 `POLICY_TABLE` 两种。
  - 新增 CLI `--ccache-table-compile`。
  - 在 table 模式下写出 `w4-ccache-table-compile-*` event、summary 和 stats 字段。
  - 对 `table_redirect.bpf.c` 使用 `update_rule()` 填充 exact lookup/readdir redirects；
    对 `cache_locality_view.bpf.c` 仍使用 `update_cache_rule()`。
- `mk/kvm.mk`
  - 新增 `kvm-w4-ccache-table-compile` 和 guest target
    `__phase1_guest_w4_ccache_table_compile`。
  - 复用 `w4-ccache-policy-bridge` 产出的 trace object list、entries TSV 和真实
    `CCACHE_DIR`。
  - 记录 `w4-ccache-table-compile.jsonl`、input/output SHA、ccache version/path、
    stats 和 dmesg。
- `Makefile`
  - 把 `kvm-w4-ccache-table-compile` 加入 `phase1`。
- `mk/report.mk`
  - 将 table compile comparator 加入 hard gate：输入 SHA、输出 SHA、summary 字段、
    per-entry case、stats、dmesg artifact 和 summary section 都必须存在并通过。

## 设计选择

table-only comparator 必须尽量公平，因此它不复用 synthetic path oracle，而是运行真实
`ccache gcc -c` hot compile。它只替换 policy family，不替换 workload、cache dir、
source file、baseline object 或 output hash oracle。

Comparator 的结果字段故意写成：

- `table_baseline_current_oracle_pass=true`
- `content_equivalent_table_oracle=true`
- `qualified_for_c8=false`

这表示 table-only 在当前 sampled witness 上确实通过，因此不能把 W4 作为 C8 支持证据。
如果以后某个 release-level workload 证明 table-only 超过 budget、违反 stale window 或
无法通过 workload oracle，再新增单独的 C8-qualified row。

## 验证结果

已运行：

```text
make kvm-w4-ccache-table-compile RUN_ID=20260615T-parent-key-poc
make phase1 RUN_ID=20260615T-parent-key-poc SAMPLES=1 BENCH_ITERS=2000
make report RUN_ID=20260615T-parent-key-poc SAMPLES=1 BENCH_ITERS=2000
```

关键 raw result 位于：

```text
results/phase1/20260615T-parent-key-poc/w4-ccache-table-compile.jsonl
```

summary 记录：

- `policy_family=table_redirect.bpf.c`
- `real_ccache_run=true`
- `policy_executed=true`
- `ccache_compile_policy_executed=true`
- `policy_redirected_cache_objects=4`
- `redis_trace_objects=2`
- `nginx_trace_objects=2`
- `output_hash_match=true`
- `table_baseline_current_oracle_pass=true`
- `content_equivalent_table_oracle=true`
- `pass=true`
- `failures=0`
- `qualified_for_c8=false`

stats 记录：

- `cache_miss=0`
- `direct_cache_hit=2`
- `local_storage_hit=2`
- `local_storage_write=0`

## 结论和剩余风险

这个 comparator 收窄了 C8 的 blocker：当前问题不是 W4 policy 无法接入真实
ccache compile，而是 sampled Redis/nginx ccache witness 仍可由 exact table redirects
解释。C8 仍需要更强证据，包括 release-level operation-weighted policy cache hit rate、
真实 stale/corrupt transition、BuildKit/Prometheus Go cache workload、update writes、
stale window，以及 table-only 在同等 budget 下失败、过度物化或违反 oracle。

因此，本文档记录的是一个必须保留的负面结果，而不是 C8 成功结果。
