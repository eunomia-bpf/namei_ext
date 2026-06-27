# OSDI subagent review Poincare 记录

日期：2026-06-15

审稿人：subagent `Poincare`

来源/命令：主 agent 在修订 W4 真实 ccache policy-attached compile witness 后，请
subagent 只读 review `docs/research_plan.md`、`docs/experiment-plans/osdi-evaluation.md`、
`docs/paper/`、W4 新实现记录和
`results/phase1/20260615T-parent-key-poc/` 相关 raw evidence。

## Verdict

`blocked`

Poincare 给出的 maturity level 是 2。它认为当前计划接近 Level 3，但证据仍是
Phase 1 functional/report artifact，不满足 OSDI 主结果所需的 release-level workload、
baseline、table-only counterfactual、重复实验和 clean artifact。

## 主要 findings

1. C8 仍是最高风险 blocker。当前 table-only 反事实没有在 release workload 上失败；
   相反，当前 path/probe oracle 下 table baseline 都通过。因此 C8 不能成立，只能说
   table-budget infrastructure 已经搭好。
2. C1 还没有 qualifying policy family。计划要求至少四个 family 达到
   `qualified_for_c8`，每个 family 至少两个真实应用或真实 trace；当前台账明确
   “尚无 qualifying family”。
3. Workload realism 的方向合格，但当前 evidence 仍大量是 fixture、path oracle 和
   synthetic witness，不能写成 production result。
4. W4 policy-attached compile witness 被正确降级为 `functional_only`，但论文仍有过期
   表述。特别是 `docs/paper/sections/07-limitations.tex` 曾写 W4 不运行真实 ccache/
   BuildKit、不产生 compiler/go output hash。
5. 当前 run 不能支撑 OSDI 结果：main repo dirty、kernel dirty、`Samples: 1`，且
   microbenchmark 是 smoke-scale。
6. Policy diversity 仍是“方向成立，证据不足”。W1/W2 主要还是 literal component
   checks + map fallback，W4 最接近可编程但仍缺 release-level transition 和 table
   counterfactual。

## Poincare 要求的 must-fix

- 做 B12 release-level table-only counterfactual：同等 table/update budget、update
  writes、stale window、content-equivalent oracle、失败或过度物化证据。
- 把四个 family 各自升级为 `qualified_for_c8`，或主动收窄 C1/C8。
- 为每个 qualifying workload 补 operation-weighted hit rate、真实来源 evidence、至少
  两个真实 row。
- 做 clean checkout release run，足够 repetitions，报告 p95/p99/p99.9、CI 和 baseline
  raw artifacts。
- 修正文稿不一致处，尤其 W4 limitations 和 evaluation 表格中的过期状态。

## W4 新 witness 对 blocker 的影响

Poincare 认为 W4 新 compile witness 改变了一个局部 blocker：现在不能再说
“W4 真实 ccache compile 阶段完全没有执行 policy”。但它没有改变主要 blocker：该
witness 仍只是两个 compile unit、4 个 trace-derived cache objects 和 verified-hit
path 的 functional witness；没有 release-level operation-weighted policy hit rate、
真实 stale/corrupt transition、BuildKit/Prometheus workload，也没有 table/update
counterfactual。因此 W4 仍不能计入 C8。

后续主 agent 又实现并运行了 `kvm-w4-ccache-table-compile`。该 comparator 用同一份真实
`CCACHE_DIR`、同一组 Redis/nginx source file 和同一组 4 个 trace-derived cache
objects，把 policy 换成 `table_redirect.bpf.c` exact redirects。结果为
`table_baseline_current_oracle_pass=true`、`content_equivalent_table_oracle=true`、
`output_hash_match=true`、`failures=0`，ccache stats 仍有 `direct_cache_hit=2`。这不是
修复 C8，而是把 C8 blocker 变得更具体：当前 sampled witness 能被 table-only 解释，
所以 release-level table/update budget failure 仍是必须补的证据。

## 本轮已修订

根据 finding 4，本轮已经修正文稿中的 W4 过期表述：

- `docs/paper/sections/07-limitations.tex`
  - 不再写 W4 不运行真实 ccache 或不产生 compiler output hash。
  - 改为说明 W4 已有真实 ccache cold/hot transition、cache-path trace、trace-derived
    policy bridge 和 sampled policy-attached hot compile，但仍缺 release-level
    operation-weighted hit rate、真实 stale/corrupt transition、BuildKit/Prometheus、
    stale/update window 和 table/update counterfactual。
- `docs/paper/sections/05-evaluation.tex`
  - workload 表和 source-to-signal 表都补入 W4 policy-attached compile witness。
  - W4 release blocker 改为 release-level weighted hit、真实 stale/corrupt、
    BuildKit、stale/update window 和 table/update budget。
- `docs/paper/sections/04-implementation.tex`
  - W4 path oracle/cache content rows 改成“该 gate 自身不覆盖真实 cache workload”，避免
    和后续 policy-attached compile gate 矛盾。
- `docs/paper/sections/05-evaluation.tex`、`docs/paper/evaluation.md` 和
  `docs/experiment-plans/osdi-evaluation.md`
  - 补入 W4 table-only ccache compile comparator，并明确它是 C8 负面证据。

## 仍未修复

Poincare 的 verdict 仍应保持 `blocked`。本轮只修正文档一致性；C8/table-only、
qualified families、release-level repetitions 和 clean artifact 仍未完成。
