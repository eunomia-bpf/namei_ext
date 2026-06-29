# W4 bulk materialized cache baseline 设计

> 2026-06-29 baseline scope update: this historical record preserves prior reasoning and results. Current C8/B12 guidance is claim-driven baseline selection; exact-map diagnostics are optional boundary evidence only when precomputed mapping is the competing claim.

## 背景

`2026-06-16-w4-bulk-ccache-workload-implementation.md` 已把 W4 ccache trace 从
two-file sampled witness 扩展到 Redis/nginx 各 10 个真实 source，并在修改内核 KVM
中产生 40 个 trace-derived cache objects。这个 bulk trace 仍只是 workload input：
它没有证明 `namei_ext` 优于外部机制，也没有证明 table-only 或 materialized baseline
不足。

下一步必须在同一个 bulk trace shape 上跑外部 baseline。最小有价值 baseline 是
`materialized_cache_view`：把 trace-derived cache objects 直接复制成可见 cache path，
不 attach eBPF policy，不使用 `namei_ext`，用普通 lower filesystem 文件验证内容、
目录可见性和 update。

## 目标

- 复用 bulk policy bridge 生成的
  `w4-ccache-bulk-policy-bridge-entries.tsv`。
- 在修改内核 KVM guest 中运行。
- 只通过 Make target 进入，不新增项目自有 shell 脚本。
- 写出独立 raw JSONL、input sha256、workdir 和 dmesg。
- 每个 row 使用 workload label `w4-ccache-bulk-redis-nginx`，避免和 two-file
  `w4-ccache-redis-nginx` baseline 混合统计。
- 作为后续 bulk ledger 的外部 feature-equivalent baseline 输入。

## Baseline 定义

`materialized_cache_view` 不加载 BPF policy，也不使用 `namei_ext` attach path。它在每个
sample 中：

1. 根据 entries TSV 创建每个 trace-derived parent directory。
2. 把原始 ccache cache object 复制到可见 component。
3. 验证可见 component 内容等于原始 cache object。
4. 验证 `readdir` 能看到可见 component。
5. 验证 hidden `.local` backing 不存在。
6. 追加一个 materialized update object，并验证内容和目录可见性。

它是强 baseline，不是 strawman。若它在同 bulk shape 上 setup/update 更快，W4 仍是负结果；
如果它更慢，也还需要 policy-attached bulk compile、FUSE/cache-remap/native ccache
baseline 和 release repetitions 才能升级 claim。

## Oracle

Target 必须 fail-fast 检查：

- bulk trace JSONL、input hash、artifact hash 存在；
- bulk bridge JSONL、trace object list、entries TSV 存在；
- runner source/binary 存在；
- design/implementation docs 存在；
- input sha256 可复验；
- setup rows 数等于 sample 数；
- update rows 数等于 sample 数；
- correctness rows 数等于 sample 数；
- summary `pass=true`、`policy_executed=false`、`feature_equivalent_baseline=true`；
- summary workload 为 `w4-ccache-bulk-redis-nginx`。

## OSDI 解释

这个 baseline 只能回答一个问题：在同一个 bulk ccache trace-derived object set 上，
直接物化可见 cache view 的 setup/update/correctness 成本是多少。它不能单独证明
`namei_ext` 好或坏；必须和 bulk policy-attached compile、bulk parent-rule/table
comparator、FUSE/cache-remap/native ccache baseline 以及 operation-weighted hit-rate
放在同一个 ledger 中解释。
