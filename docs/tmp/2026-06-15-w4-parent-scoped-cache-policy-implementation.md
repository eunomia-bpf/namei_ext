# W4 parent-scoped cache policy PoC 实现记录

> 2026-06-29 baseline scope update: this historical record preserves prior reasoning and results. Current C8/B12 guidance is claim-driven baseline selection; exact-map diagnostics are optional boundary evidence only when precomputed mapping is the competing claim.

日期：2026-06-15

## 动机

W4 `cache_locality_view.bpf.c` 之前已经可以用 exact `(event, parent, component)` 规则把真实 ccache hot-hit trace 中采样到的 cache object 映射到 `.local` backing 文件，并且真实 Redis/nginx 单文件热编译可以在 KVM 内跑通。但是同一批采样对象也可以由 `table_redirect.bpf.c` 逐项表达，所以这仍然是 C8 的负证据：它证明了 namei_ext 可以跑真实 workload，不证明必须要可编程 path resolution。

本实现尝试做一个更接近 release-cache 场景的 PoC：在 cache leaf parent 上安装一条 eBPF parent-scoped 规则，lookup 时由 policy 对任意满足条件的 component 计算 `component.local`，而不是为每个 object 写一条 exact lookup 规则。目标是降低 rule shape 从 per-object exact redirect 向 per-parent suffix policy 推进，同时仍在 KVM 内执行真实 ccache hot compile。

## 设计选择

- 不新增第二张 parent map。最终版本复用 `cache_rules`，用 `name_len = 0` 的 `namei_ext_component_key` 表示 parent-scoped wildcard rule。这样保持一张规则表，代码量更小，也避免引入额外 user/kernel ABI。
- parent-scoped rule 只处理 `BPF_NAMEI_EXT_LOOKUP`。`READDIR` 仍用 exact readdir rules 暴露 visible name 并隐藏 `.local` backing；这是当前 PoC 的限制。
- parent rule 的算法是 O(1) map lookup + O(L) bounded suffix construction，其中 L 受 `BPF_NAMEI_EXT_NAME_MAX` 限制。它不是 table-only exact redirect，但当前样本规模仍不足以证明 C8。
- policy 必须跳过已经带 `.local` 后缀的 backing name，避免 `foo.local` 被再次改写成 `foo.local.local`。
- `.local` backing 不是安全隐藏或访问控制。当前策略只在 readdir alias 中隐藏 backing；如果用户直接 lookup `foo.local`，suffix guard 会让该路径 PASS 给 lower filesystem。
- 早期版本使用 `name_len >= 8` 和 `stats` 特判作为 ccache-specific PoC guard。后续
  `2026-06-15-w4-parent-object-shape-negative-implementation.md` 已把 lookup guard 收窄为
  ccache object-shape：32 字节 component，前 31 字节为 lower-alnum，最后一字节为 `M` 或 `R`。
- parent wildcard 当前对同一 cache leaf parent 下满足 ccache object-shape 的 component 追加
  `.local`。后续修订已补一个同 parent `metadata.txt` sibling PASS 负例，但仍没有 per-object
  content hash predicate，也没有覆盖缺失 backing、corrupt backing 等负例。

## 实现内容

改动文件：

- `bpf/policies/cache_locality_view.bpf.c`
  - 增加 parent wildcard lookup：exact rule miss 后，用同一 `cache_rules` map 查 `name_len = 0` 的 parent key。
  - parent rule 对 verified-hit state 生成 `name + ".local"` redirect。
  - 增加 `.local` 后缀保护，防止 backing name 二次 redirect。
- `tests/w1_oracle/namei_ext_w1_oracle.c`
  - 增加 `--ccache-parent-compile` 模式。
  - parent 模式为每个 cache leaf parent 写一条 wildcard lookup rule，并为 readdir 写 exact alias rule。
  - 输出 `parent_rule_policy`、`cache_leaf_parents`、`parent_rule_updates`、`exact_readdir_updates`、`table_equivalent_rule_updates` 等原始字段。
- `mk/kvm.mk`
  - 增加 `kvm-w4-ccache-parent-compile` 和 guest target。
  - target 复用真实 ccache trace、复制 CCACHE_DIR、在 KVM 内加载 modified kernel + policy，然后跑 Redis/nginx hot compile。
- `Makefile`
  - help 中列出 `kvm-w4-ccache-parent-compile`。

## 调试过程

第一次实现使用独立 `cache_parent_rules` map。KVM load 可以通过，但 `attached_visible_match` 返回 `ENOENT`。随后改成单 map wildcard rule 后仍然失败。

临时诊断版本加入了 BPF counter map，结果显示 parent key 已命中且发生 redirect：

- `results/phase1/20260615T-w4-parent-debug-poc/w4-ccache-parent-compile.jsonl`
- `after_attached_checks`: `parent_key_hits=8`, `parent_redirects=8`

这说明失败不是 parent key 未命中，而是测试中的 backing path 也被 parent policy 改写：比较逻辑先打开 visible path，redirect 到 `foo.local` 成功；再打开 expected backing `foo.local` 时，policy 又把它改成 `foo.local.local`，导致 `ENOENT`。最终修复是让 policy 对已带 `.local` 后缀的名称 PASS。

临时 counter 代码已经从最终实现中删除，避免污染性能路径。

## 验证结果

本地构建：

- `make bpf`：通过。
- `make w1-oracle`：通过。

KVM load：

- `make kvm-policy-load RUN_ID=20260615T-w4-parent-final-load`：通过。

KVM parent-scoped ccache witness：

- `make kvm-w4-ccache-parent-compile RUN_ID=20260615T-w4-parent-final-poc`：通过。
- `make kvm-w4-ccache-parent-compile RUN_ID=20260615T-w4-parent-shape-poc`：通过，并增加
  ccache object-shape guard 与同 parent sibling PASS 负例。
- `make kvm-w4-ccache-parent-compile RUN_ID=20260615T-w4-parent-shape-hardgate`：通过，并在
  Makefile target 中显式 hard-check `attached_parent_sibling_pass`。

关键原始结果：

- `results/phase1/20260615T-w4-parent-final-poc/w4-ccache-parent-compile.jsonl`
- `results/phase1/20260615T-w4-parent-final-poc/w4-ccache-parent-compile-stats.txt`
- `results/phase1/20260615T-w4-parent-final-poc/w4-ccache-parent-compile-outputs.sha256`
- `results/phase1/20260615T-w4-parent-final-poc/dmesg-w4-ccache-parent-compile.log`
- `results/phase1/20260615T-w4-parent-shape-poc/w4-ccache-parent-compile.jsonl`
- `results/phase1/20260615T-w4-parent-shape-poc/w4-ccache-parent-compile-stats.txt`
- `results/phase1/20260615T-w4-parent-shape-poc/w4-ccache-parent-compile-outputs.sha256`
- `results/phase1/20260615T-w4-parent-shape-poc/dmesg-w4-ccache-parent-compile.log`
- `results/phase1/20260615T-w4-parent-shape-hardgate/w4-ccache-parent-compile.jsonl`
- `results/phase1/20260615T-w4-parent-shape-hardgate/w4-ccache-parent-compile-stats.txt`
- `results/phase1/20260615T-w4-parent-shape-hardgate/w4-ccache-parent-compile-outputs.sha256`
- `results/phase1/20260615T-w4-parent-shape-hardgate/dmesg-w4-ccache-parent-compile.log`

摘要结果：

- `pass=true`
- `failures=0`
- `real_ccache_run=true`
- `policy_executed=true`
- `ccache_compile_policy_executed=true`
- `output_hash_match=true`
- `direct_cache_hit=2`
- `local_storage_hit=2`
- `cache_miss=0`
- `cache_leaf_parents=4`
- `parent_rule_updates=4`
- `exact_readdir_updates=4`
- `table_equivalent_rule_updates=8`
- `attached_parent_sibling_pass=true`（`20260615T-w4-parent-shape-poc` 与
  `20260615T-w4-parent-shape-hardgate`）
- `parent_sibling_pass=true`、`parent_sibling_pass_count=1`（仅
  `20260615T-w4-parent-shape-hardgate` stats event）

## 当前结论

这个 PoC 比 exact sampled redirect 更强：它展示了一类 parent-scoped suffix policy，可以在 KVM 内驱动真实 ccache Redis/nginx hot compile，且输出 hash 与 baseline 一致。后续 shape guard 版本还证明了一个真实 cache leaf parent 下的 `metadata.txt` 明显非 object sibling 会 PASS，不会被粗 wildcard 误改写。

但它仍不能计入 C8 的强证据，原因是：

- 当前样本只有 4 个 cache leaf parents / 4 个 cache objects，rule 数量优势还不明显。
- `READDIR` 仍依赖 exact alias rule。
- 总 update 数不能写成 4 vs 8 的优势：parent lookup updates 为 4，但另有 4 条 exact readdir updates，因此当前 PoC 的总更新仍是 8，只能说明 lookup rule shape 发生变化。
- 本 run 没有 same-run table-only comparator；table comparator 仍来自 `20260615T-parent-key-poc` 的 sampled exact baseline，且该 baseline 已通过。
- `ccache_compile_policy_executed=true` 说明真实 ccache compile 发生在 policy attach window 内，并由路径 oracle、stats 和 output hash 支撑；它不是 operation-weighted 每次 cache lookup 都经 parent redirect 的证明。
- 还没有 release-scale cache directory、stale/corrupt transition、operation-weighted hit-rate、或 table baseline 在大规模对象下的失败/膨胀证据。

因此它应记录为 W4 parent-scoped cache policy PoC 和下一步 release-cache counterfactual 的基础设施，而不是最终 OSDI claim。

## 后续工作

- 扩大 ccache workload 到 release-level object set，记录 parent count、object count、exact-table rule count、parent-rule count。
- 把 readdir 也推进到 bounded suffix-aware policy，减少 exact readdir rule。
- 扩大同 parent sibling PASS 覆盖，并增加 missing backing、stale/corrupt/cache-miss 分支的真实 workload 触发，而不是只覆盖 verified-hit。
- 与 `table_redirect.bpf.c` 做 same-run 规模化对照，只有 table-only 表达变得不可接受或明显膨胀时，才把该结果提升为 C8 证据。
