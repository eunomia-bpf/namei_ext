# W4 ccache rule macrobench 设计记录

> 2026-06-29 baseline scope update: this historical record preserves prior reasoning and results. Current C8/B12 guidance is claim-driven baseline selection; exact-map diagnostics are optional boundary evidence only when precomputed mapping is the competing claim.

日期：2026-06-16

## 动机

C2 的当前缺口不是没有任何 setup/update 数据，而是缺少按 workload 切开的 KVM
macrobench。W2 已经有 threshold-supported slice，W1 已经有 release input 但结果为负；
W3 的 Podman/CRIU restore 在当前环境被 capability audit 阻塞。因此下一步最高价值是把
W4 从 correctness/counterfactual witness 推进到可复验的 setup/update raw input。

W4 已有真实 workload 基础：

- `kvm-w4-ccache-trace` 从 Redis/nginx 的 real ccache hot compile 中提取 cache-path file ops；
- `kvm-w4-ccache-policy-bridge` 把 trace-derived ccache cache object 转成 policy entries；
- `kvm-w4-ccache-parent-compile` 在 KVM 中运行真实 ccache hot compile，并通过
  `cache_locality_view.bpf.c` parent-scoped policy 命中 cache objects；
- `kvm-w4-ccache-table-compile` 在同一 workload 上运行 `table_redirect.bpf.c` exact-rule
  baseline，当前也能通过，因此它是 C8 负证据。

新增 W4 macrobench 的目标是把这些真实 entries 变成重复 samples 的 rule setup/update
raw rows，而不是把 W4 直接升级为 C2/C8 支持证据。

## 已检查代码和 artifact

- `mk/kvm.mk`：
  - W4 ccache trace/bridge/parent/table/release-counterfactual 均已有 Makefile-owned KVM
    targets；
  - 现有 W1/W2 macrobench targets 都采用 `kvm-*` 生成 raw JSONL，然后由
    `mk/eval_osdi.mk` 中的 ledger 合并 claim-level 结果。
- `tests/w1_oracle/namei_ext_w1_oracle.c`：
  - 已有 `run_ccache_policy_compile()`，能为 parent-scoped policy 和 table baseline 填充
    map、attach policy、运行真实 ccache compile、检查 output hash；
  - 已有 `prepare_cache_content_dir()`、`cache_expect_equal()`、`cache_expect_readdir()` 等
    content/path oracle helper，可以复用到 macrobench correctness；
  - 已有 W1/W2 setup/update macrobench JSON schema 风格。
- `results/phase1/20260615T-full-phase1-b12-refresh-v1/`：
  - `w4-ccache-parent-compile.jsonl` 记录 parent policy：4 个 trace objects、4 个
    parent lookup rules、4 个 exact readdir rules、40 个 sampled ccache cache-path file ops；
  - `w4-ccache-table-compile.jsonl` 记录 table baseline：同样 correctness 通过，但需要
    8 个 exact lookup/readdir rules；
  - `w4-ccache-release-counterfactual.jsonl` 当前仍为 C8 负证据，因为 table baseline 也通过。

## 新增实验定义

新增目标：`make kvm-w4-ccache-rule-macrobench`。

输入：

- `w4-ccache-policy-bridge-entries.tsv`，来自真实 ccache trace；
- `cache_locality_view.bpf.c` 和其 BPF object；
- `table_redirect.bpf.c` 和其 BPF object；
- runner source/binary、`mk/kvm.mk` 和本设计文档，全部写入 input sha256。

执行：

1. target 先依赖 `kvm-w4-ccache-policy-bridge`，确保 entries 来自真实 ccache trace 且已通过
   cache-content policy oracle。
2. guest runner 对每个 sample 同时运行两个系统：
   - proposed system：`cache_locality_view.bpf.c` 的 parent-scoped cache policy；
   - feature baseline：`table_redirect.bpf.c` exact-rule table baseline。
3. 每个 sample 输出：
   - setup row：materialize trace-derived cache objects、load policy、populate map、attach policy
     的 elapsed time 和 rule-write/object counters；
   - update row：同一 parent 下追加一个 sample-local cache object，更新 policy/table rules，
     并记录 elapsed time 与 update rule writes；
   - correctness row：attached lookup/readdir content oracle 必须通过，post-detach alias 必须
     消失。
4. summary 要求 setup/update/correctness rows 均等于 `samples * 2`，且 failures 为 0。

## 指标

Raw rows 保留以下字段：

- `setup_ns`、`update_ns`；
- `created_dirs`、`created_files`、`bytes_copied`；
- `lookup_rule_writes`、`readdir_rule_writes`、`total_rule_writes`；
- `update_lookup_rule_writes`、`update_readdir_rule_writes`、`update_total_rule_writes`；
- `cache_objects`、`cache_leaf_parents`；
- `policy_executed`、`kvm_validated`、`feature_equivalent_baseline`。

解释规则：

- 这个 target 只提供 W4 setup/update raw input；
- 它不把 `c2_supported` 或 `release_gate_pass` 置为 true；
- 如果 parent policy 的 lookup rule writes 少于 table baseline，但 readdir 或 update 让总写入并不占优，
  结果必须如实记录为 mixed/negative，而不是改阈值让它通过；
- C8 仍由 table-only failure、operation-weighted release hit rate 或 stale/update window 证据决定，
  不能由本 target 单独支持。

## 拒绝的替代方案

- 重跑完整 real ccache compile 20 次：最接近真实端到端，但成本高、噪声大，且当前主要缺口是
  setup/update raw input，不是重复证明 output hash correctness。
- 从旧 `w4-ccache-parent-compile.jsonl` 派生 20 个 samples：会伪造重复输入，不能作为 release
  evidence。
- 只写 Markdown 解释 parent/table rule count：不可机械化，无法进入 Make hard gate。
- 用 synthetic cache entries：会削弱 W4 workload provenance；本设计坚持 entries 来自真实 ccache
  trace。

## 验证计划

1. `make w1-oracle` 确认 runner 编译。
2. `make kvm-w4-ccache-rule-macrobench RUN_ID=... W4_CCACHE_RULE_MACROBENCH_SAMPLES=2`
   跑通 smoke。
3. 检查 JSONL row count、summary、input sha256 和 dmesg。
4. 若 smoke 通过，运行 20-sample release input。
5. 增加 W4 workload ledger，并保持 hard gate 为 false，直到 C2 全局 claim 明确满足或收窄。
