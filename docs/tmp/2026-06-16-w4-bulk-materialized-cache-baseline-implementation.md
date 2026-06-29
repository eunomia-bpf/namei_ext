# W4 bulk materialized cache baseline 实现记录

> 2026-06-29 baseline scope update: this historical record preserves prior reasoning and results. Current C8/B12 guidance is claim-driven baseline selection; exact-map diagnostics are optional boundary evidence only when precomputed mapping is the competing claim.

## 背景

本实现把 W4 bulk ccache trace/bridge 的 40 个 trace-derived cache objects 接到
外部 `materialized_cache_view` baseline。目标不是改变 W4 当前负 verdict，而是补一个
同 shape、同 KVM contract 的强 baseline 输入。

## 修改内容

- `tests/w1_oracle/namei_ext_w1_oracle.c`
  - `--ccache-materialized-baseline-macrobench` 增加可选 `WORKLOAD` 参数。
  - 旧调用不传参数时仍输出 `w4-ccache-redis-nginx`。
  - bulk target 传 `w4-ccache-bulk-redis-nginx`，避免和 two-file baseline 混淆。
- `mk/kvm.mk`
  - 新增 `W4_CCACHE_BULK_MATERIALIZED_BASELINE_*` 变量。
  - 新增 `kvm-w4-ccache-bulk-materialized-baseline-macrobench`。
  - 新增 guest target `__phase1_guest_w4_ccache_bulk_materialized_baseline_macrobench`。
- `Makefile`
  - 新增公开 help entry 和 phony target。

## Target

```text
make kvm-w4-ccache-bulk-materialized-baseline-macrobench RUN_ID=<run-id>
```

默认 sample 数：

```text
W4_CCACHE_BULK_MATERIALIZED_BASELINE_SAMPLES=2
```

可覆盖为 release-style repetition，例如 20。

## 结果

Smoke run:

```text
make kvm-w4-ccache-bulk-materialized-baseline-macrobench \
  RUN_ID=20260616T-w4-ccache-bulk-materialized-smoke-v1 \
  W4_CCACHE_BULK_MATERIALIZED_BASELINE_SAMPLES=1
```

结果：

- exit status: 0
- result root:
  `results/phase1/20260616T-w4-ccache-bulk-materialized-smoke-v1/`
- trace input: 20 个 Redis/nginx source、400 条 cache-path file ops、40 个
  trace-derived cache objects。
- materialized baseline: 1 setup row、1 update row、1 correctness row。
- summary: `pass=true`、`failures=0`、`policy_executed=false`、
  `feature_equivalent_baseline=true`。

Release-style run:

```text
make kvm-w4-ccache-bulk-materialized-baseline-macrobench \
  RUN_ID=20260616T-w4-ccache-bulk-materialized-release-v1 \
  W4_CCACHE_BULK_MATERIALIZED_BASELINE_SAMPLES=20
```

结果：

- exit status: 0
- result root:
  `results/phase1/20260616T-w4-ccache-bulk-materialized-release-v1/`
- trace artifact:
  `w4-ccache-bulk-trace.jsonl`
- bridge artifact:
  `w4-ccache-bulk-policy-bridge.jsonl`
- baseline artifact:
  `w4-ccache-bulk-materialized-baseline.jsonl`
- input hash:
  `w4-ccache-bulk-materialized-baseline-inputs.sha256`
- trace row: `source_count=20`、`cache_path_file_ops=400`、
  `cache_miss=20`、`direct_cache_hit=20`、`output_hash_match=true`。
- bridge summary: `trace_objects=40`、`redis_trace_objects=20`、
  `nginx_trace_objects=20`、`policy_content_oracle_failures=0`、
  `pass=true`。
- materialized summary: `workload=w4-ccache-bulk-redis-nginx`、
  `samples=20`、`setup_rows=20`、`update_rows=20`、
  `correctness_rows=20`、`pass=true`、`failures=0`、
  `policy_executed=false`、`kvm_validated=true`、
  `feature_equivalent_baseline=true`、`c2_supported=false`、
  `release_gate_pass=false`。
- setup latency: min/avg/max = 425.40/484.83/573.99 ms。
- update latency: min/avg/max = 2.83/3.12/3.77 ms。
- materialized object shape: 40 cache objects、36 leaf parents、201335 bytes
  copied；每个 update 写入 50 bytes。

判读：该 run 补上 W4 bulk trace shape 的同形态外部 materialized baseline 输入。
它仍是 W4 negative/blocked evidence：baseline 不执行 eBPF policy，也没有 bulk
policy-attached compile 的 operation-weighted latency/hit-rate 对照；因此不能计入 C2
或 C8。下一步必须在同一个 bulk shape 下继续补 proposed-system compile、FUSE 或
cache-remap baseline、native ccache/BuildKit baseline、stale/corrupt/update-window
gate 和 table-only budget failure。

## 风险

该 baseline 仍然只 materialize trace-derived cache object set，不等于真实 ccache 或
BuildKit 的完整 native behavior。即使它通过，也只能作为 W4 bulk comparison 的一个
external baseline；后续仍需要 operation-weighted policy-attached compile、FUSE 或
cache-remap baseline、native ccache/BuildKit baseline、stale/corrupt/update-window
gate。
