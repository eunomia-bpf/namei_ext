# W4 parent-scoped cache policy review revision

> 2026-06-29 baseline scope update: this historical record preserves prior reasoning and results. Current C8/B12 guidance is claim-driven baseline selection; exact-map diagnostics are optional boundary evidence only when precomputed mapping is the competing claim.

日期：2026-06-15

## 背景

`make kvm-w4-ccache-parent-compile RUN_ID=20260615T-w4-parent-final-poc` 通过后，请独立 subagent 对 W4 parent-scoped cache policy PoC 做只读对抗审阅。审阅目标是确认该 PoC 是否被误写成 C8 / OSDI 主结论，以及文档和测试是否仍有方法学漏洞。

## Subagent verdict

Subagent 给出的结论是 weak accept，仅限“Phase 1 parent-scoped suffix policy PoC”。如果把当前结果用于 C8 或“必须 eBPF programmable path resolution”的 OSDI 主 claim，则 verdict 是 block。

主要问题：

- W4 parent-scoped 段落本身没有过度声明，但 research plan 的全局 claim 中“生产级路径解析定制”和“证明核心 programmable path-resolution 机制”措辞偏强。
- 当前 parent rule 是 parent wildcard suffix rewrite，不是 per-object content-verified decision。
- 当前总 update 数不能写成 4 vs 8 的优势；有 4 条 parent lookup rule，也有 4 条 exact readdir rule，总数仍为 8。
- 当前 final parent run 没有 same-run table-only comparator，也没有 release-scale operation-weighted hit-rate。
- `.local` backing 不是安全隐藏；direct lookup 会 PASS 给 lower filesystem。
- `name_len >= 8` 和 `stats` 特判是 ccache-specific guard，不是通用 cache-locality 语义。

## 本次修订

已修改 `docs/research_plan.md`：

- 将一句话 claim 从“生产级路径解析定制可以表达为...”降级为“Phase 1 只证明可以在 VFS name resolution 上实现一个窄 eBPF path-resolution PoC”。
- 将“证明核心 programmable path-resolution 机制”改为“演示核心机制的最小可运行 PoC”，并明确生产级机制和 C8 claim 需要 release-scale workload、operation-weighted coverage 和 table/update-budget counterfactual。
- 在 W4 parent-scoped 段落中补充：该 PoC 不是 per-object content-verified decision，总 update 数仍包含 exact readdir rules，且没有 same-run table comparator。

已修改 `docs/tmp/2026-06-15-w4-parent-scoped-cache-policy-implementation.md`：

- 增加 `.local` direct lookup 不是访问控制的说明。
- 增加 ccache-specific guard 的说明。
- 增加 parent wildcard 缺少 sibling PASS、missing backing、corrupt backing 负例的说明。
- 增加总 update 数不能宣称预算优势的说明。
- 增加 `ccache_compile_policy_executed=true` 不等于 operation-weighted 每次 lookup coverage 的说明。
- 后续工作增加 same-run table comparator 和负例 oracle。

## 保留边界

当前可声明：

- Phase 1 已有一个 KVM 内真实 ccache hot compile 的 parent-scoped suffix policy PoC。
- 该 PoC 的 Redis/nginx output hash 与 baseline 一致，ccache stats 显示 direct hit，且 raw results 标记 0 failure。

后续实现补充：

- `docs/tmp/2026-06-15-w4-parent-object-shape-negative-implementation.md` 已把 parent lookup guard
  从早期粗 suffix wildcard 收窄为 ccache object-shape guard，并加入同 parent `metadata.txt`
  sibling PASS 负例。
- `make kvm-w4-ccache-parent-compile RUN_ID=20260615T-w4-parent-shape-poc` 已通过，raw event
  `attached_parent_sibling_pass` 记录 `pass=true`。
- 这个修订只解决“粗 wildcard 会误伤同目录普通文件”的方法学漏洞，不改变 C8 仍未成立的判断。

当前不可声明：

- 不能声明 C8 已成立。
- 不能声明 table-only 不足。
- 不能声明 production-grade path-resolution customization 已证明。
- 不能声明 `.local` backing 被安全隐藏。
- 不能声明当前 policy 是 content-verified cache decision。

## 下一步 gate

要把 W4 从 weak PoC 提升为 OSDI/C8 证据，需要补：

- release-scale cache workload；
- same-run table-only comparator；
- operation-weighted redirect coverage；
- sibling PASS、missing backing、stale/corrupt、update-window oracle；
- readdir wildcard 或其他减少 exact readdir rules 的机制；
- raw result 和 report gate，继续保持 `qualified_for_c8=false` 直到这些 gate 通过。
