# W4 parent-scoped gate 论文证据链修订

> 2026-06-29 baseline scope update: this historical record preserves prior reasoning and results. Current C8/B12 guidance is claim-driven baseline selection; exact-map diagnostics are optional boundary evidence only when precomputed mapping is the competing claim.

日期：2026-06-15

## 动机

上一轮 W4 parent-scoped ccache hardgate 已经补上 KVM raw evidence 和 Make/report gate：
`make kvm-w4-ccache-parent-compile RUN_ID=20260615T-w4-parent-shape-hardgate`
在修改后的 kernel guest 中运行 Redis/nginx 真实 `ccache gcc -c` hot compile，
用 `cache_locality_view.bpf.c` 的 parent wildcard lookup rule 重定向 4 个真实
ccache cache objects，并 hard-check 同 parent 下 `metadata.txt` sibling PASS。

该结果已经写入 `docs/research_plan.md` 和 `docs/tmp/` 的实现/审稿记录，但
`docs/paper/` 仍只描述 W4 policy-attached compile 和 table-only comparator。论文证据链
落后于 Makefile/report gate，会让后续审稿式 review 误判当前 artifact 状态。

## 检查的文件

- `docs/paper/sections/04-implementation.tex`
- `docs/paper/sections/05-evaluation.tex`
- `docs/paper/sections/07-limitations.tex`
- `docs/paper/main.tex`
- `docs/paper/sections/01-introduction.tex`
- `docs/paper/sections/03-design.tex`
- `docs/paper/evaluation.md`
- `docs/research_plan.md`
- `docs/tmp/2026-06-15-w4-parent-scoped-cache-policy-implementation.md`
- `docs/tmp/2026-06-15-w4-parent-object-shape-negative-implementation.md`
- `docs/tmp/2026-06-15-w4-parent-object-shape-review-revision.md`
- `docs/tmp/2026-06-15-w4-parent-report-gate-implementation.md`

## 修订内容

1. `docs/paper/sections/04-implementation.tex`
   - 在 gate 列表中加入 W4 parent-scoped ccache compile gate。
   - 在 artifact evidence 表中加入 `make kvm-w4-ccache-parent-compile` row。
   - 在 W4 实现状态段落中记录 parent wildcard lookup rule、object-shape guard、
     exact readdir entries、`metadata.txt` sibling PASS、report gate 和剩余限制。

2. `docs/paper/sections/05-evaluation.tex`
   - 在当前证据总览、workload matrix 和 workload-source-signal ledger 中加入
     parent-scoped compile witness。
   - 在 W4 当前证据 subsection 中新增 parent-scoped hardgate 段落，记录 raw fields：
     `real_ccache_run=true`、`ccache_compile_policy_executed=true`、
     `output_hash_match=true`、`policy_redirected_cache_objects=4`、
     `cache_leaf_parents=4`、`parent_rule_updates=4`、
     `exact_readdir_updates=4`、`table_equivalent_rule_updates=8`、
     `direct_cache_hit=2`、`local_storage_hit=2`、`parent_sibling_pass=true`
     和 0 failure。
   - 在 table-only counterfactual subsection 中明确：该 hardgate 仍缺 release-scale
     hit rate、same-run table budget failure 和完整 sibling safety，不能单独支撑 C8。

3. `docs/paper/sections/07-limitations.tex`
   - 明确 parent-scoped hardgate 只是 object-shape suffix PoC，不是
     content-verified cache decision。
   - 明确未覆盖 valid-shape decoy、metadata sidecar、临时/锁文件、多 parent、缺 backing、
     stale/corrupt 或 update-window。

4. `docs/paper/evaluation.md`
   - 同步 Markdown 评估草稿，避免与 LaTeX evaluation 分叉。

5. `docs/paper/main.tex`、`docs/paper/sections/01-introduction.tex` 和
   `docs/paper/sections/03-design.tex`
   - 同步当前 artifact 状态，避免 abstract、contribution paragraph 和 policy-family 表
     仍停留在 W4 cache-content 之前。
   - 只加入 W1 release/branch、W3 Redis replay、W4 ccache trace/compile/parent PoC 等
     已有证据，不改变 `functional_only` 和 `qualified_for_c8=false` 边界。

## 设计选择

- 只写已经有 raw artifact 的字段，不补造 release-level 数字。
- 继续把 W4 标成 `functional_only` 和 `qualified_for_c8=false`。
- 不把 parent wildcard lookup rule 写成 table-only 已失败；当前 sampled witness 只能说明
  parent-scoped policy 能跑通真实 ccache hot compile，并不能证明通用可编程性 claim。
- 将 `metadata.txt` sibling PASS 写成“明显非 object sibling 负例”，不写成完整 sibling
  safety。

## 验证计划

本次改动是文档修订，验证应包括：

- `make -C docs/paper check`
- 搜索 W4/C8/table-only/parent-scoped 相关表述，确认没有把
  `qualified_for_c8=false` 的结果升级成主 claim。
- 后续 full `make phase1` 应自然包含 `kvm-w4-ccache-parent-compile`，full
  `make report` 应生成 parent-scoped summary section。

## 剩余风险

- 当前 parent-scoped evidence 仍是 4 个 sampled cache objects，不是 release-level
  operation-weighted metric。
- 当前只有 `metadata.txt` sibling PASS，不能证明 valid-shape non-cache sibling、
  sidecar、temp/lock/stats 文件或多 parent 场景安全。
- 当前 readdir 仍依赖 exact aliases，不是完整 directory view synthesis。
- 当前没有 same-run release-scale table comparator 或 table/update budget failure。
- 因此该修订只能提高论文证据链准确性，不能把总体 goal 标记为完成。
