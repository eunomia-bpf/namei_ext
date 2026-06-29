# W4 parent object-shape guard 对抗审阅修订记录

> 2026-06-29 baseline scope update: this historical record preserves prior reasoning and results. Current C8/B12 guidance is claim-driven baseline selection; exact-map diagnostics are optional boundary evidence only when precomputed mapping is the competing claim.

日期：2026-06-15

## 背景

在实现 `cache_locality_view.bpf.c` 的 ccache object-shape guard 和 `metadata.txt`
sibling PASS 负例后，启动独立只读 subagent 按 OSDI 实验设计标准审阅以下材料：

- `bpf/policies/cache_locality_view.bpf.c`
- `tests/w1_oracle/namei_ext_w1_oracle.c`
- `docs/tmp/2026-06-15-w4-parent-object-shape-negative-implementation.md`
- `docs/tmp/2026-06-15-w4-parent-scoped-cache-policy-implementation.md`
- `docs/tmp/2026-06-15-w4-parent-scoped-cache-policy-review-revision.md`
- `docs/research_plan.md`

## Subagent verdict

Verdict：weak accept，仅限 “Phase 1 W4 parent object-shape guard + `metadata.txt`
sibling PASS 负例 PoC”。

如果把该结果用于 C8、table-only 不足、production-grade path-resolution customization
或 OSDI 主结论，则 verdict 是 block。

## 可声明内容

- lookup path 已不再是 per-object exact table：policy 使用 parent key 查规则，并在 BPF 中检查
  ccache object shape 后构造 `component.local`。
- KVM raw result 支持一个窄 PoC：`attached_parent_sibling_pass=true`，summary 为
  `pass=true`、`failures=0`、`output_hash_match=true`，`parent_rule_updates=4`，
  `exact_readdir_updates=4`，`qualified_for_c8=false`。
- 文档主线没有把该结果升级成 C8。

## Blocker

- C8 仍 blocked。当前样本已被 `table_redirect.bpf.c` exact redirect comparator 通过解释；
  parent-shape run 自身没有 same-run table comparator，总 update 仍是 4 条 parent lookup
  加 4 条 exact readdir。
- shape guard 不是 content-verified cache decision。parent lookup 只看名字形状和
  verified-hit parent state；任何同 parent 下“长得像 ccache object”的非 cache sibling 仍会被
  redirect。
- `metadata.txt` PASS 负例只证明一个明显非 object sibling 不会被旧粗 wildcard 误伤，不证明 sibling
  安全性。
- readdir 仍是 exact alias rule，所以完整目录视图仍可被 table-only baseline 解释。
- parent-shape target 原本没有显式 hard-check `attached_parent_sibling_pass`，只通过 failure count
  间接覆盖。

## 本次修订

- `mk/kvm.mk`：`__phase1_guest_w4_ccache_parent_compile` 现在显式从
  `w4-ccache-parent-compile.jsonl` 中统计
  `event == "w4-ccache-parent-compile" && op == "attached_parent_sibling_pass" && pass == true`
  的事件数量，并执行 `test "$$sibling_pass" -gt 0`。缺少该事件会让 Make target 失败。
- `mk/kvm.mk`：`w4-ccache-parent-compile-stats` 追加
  `parent_sibling_pass=true` 和 `parent_sibling_pass_count`。
- `docs/research_plan.md`：把“不会误伤同 parent 普通 sibling”收窄为
  “`metadata.txt` 这个明显不满足 ccache object-shape 的同 parent sibling 会 PASS”。
- `docs/tmp/2026-06-15-w4-parent-object-shape-negative-implementation.md` 和
  `docs/tmp/2026-06-15-w4-parent-scoped-cache-policy-implementation.md`：同步收窄 sibling
  结论，并记录 hardgate run。

## 修订后验证

- `make kvm-w4-ccache-parent-compile RUN_ID=20260615T-w4-parent-shape-hardgate`：通过。

关键 raw result：

- `results/phase1/20260615T-w4-parent-shape-hardgate/w4-ccache-parent-compile.jsonl`
- `results/phase1/20260615T-w4-parent-shape-hardgate/w4-ccache-parent-compile-stats.txt`
- `results/phase1/20260615T-w4-parent-shape-hardgate/w4-ccache-parent-compile-outputs.sha256`

关键字段：

- `attached_parent_sibling_pass`: `pass=true`
- `w4-ccache-parent-compile-summary`: `pass=true`, `failures=0`,
  `output_hash_match=true`, `policy_redirected_cache_objects=4`,
  `cache_leaf_parents=4`, `parent_rule_updates=4`, `exact_readdir_updates=4`,
  `table_equivalent_rule_updates=8`, `qualified_for_c8=false`
- `w4-ccache-parent-compile-stats`: `parent_sibling_pass=true`,
  `parent_sibling_pass_count=1`, `cache_miss=0`, `direct_cache_hit=2`,
  `local_storage_hit=2`, `local_storage_write=0`

## 仍需补齐

- release-scale ccache 或 BuildKit workload：object 数、parent fanout、object-name 分布、ccache
  版本、rule/update count。
- paired same-run table-only comparator：同一输入、同一 cache dir、同一 workload，并记录 table
  entries、update writes、memory、stale window。
- operation-weighted redirect coverage：BPF counter 或 trace 关联真实 `openat`、`stat`、
  `getdents`。
- 更强负例：valid-shape non-cache sibling、`metadata.txt.local` decoy、temp/lock/stats 文件、
  多 parent sibling PASS、missing backing、stale/corrupt backing、update-window transition。
- parent-shape target 已在
  `docs/tmp/2026-06-15-w4-parent-report-gate-implementation.md` 中纳入 `make phase1` 和
  `make report` gate；后续完整 `make phase1 RUN_ID=...` 需要确认 `summary.md` 中出现该
  section，并继续强制 `qualified_for_c8=false`。
