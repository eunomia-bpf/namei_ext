# OSDI subagent review Poincare table comparator 记录

> 2026-06-29 baseline scope update: this historical record preserves prior reasoning and results. Current C8/B12 guidance is claim-driven baseline selection; exact-map diagnostics are optional boundary evidence only when precomputed mapping is the competing claim.

日期：2026-06-15

## 背景

主 agent 在 W4 真实 ccache policy-attached compile witness 之后，实现并运行了
`kvm-w4-ccache-table-compile`。该 comparator 用同一份真实 `CCACHE_DIR`、同一组
Redis/nginx source file 和同一组 4 个 trace-derived cache objects，把 policy 换成
`table_redirect.bpf.c` exact redirects。

本轮请 Poincare 作为只读 OSDI/SOSP 评审复审：

- `docs/research_plan.md`
- `docs/experiment-plans/osdi-evaluation.md`
- `docs/paper/evaluation.md`
- `docs/paper/sections/04-implementation.tex`
- `docs/paper/sections/05-evaluation.tex`
- `docs/paper/sections/07-limitations.tex`
- `docs/tmp/2026-06-15-w4-table-only-ccache-compile-comparator.md`
- `docs/tmp/2026-06-15-policy-diversity-and-c8-blocker-audit.md`
- `docs/tmp/2026-06-15-osdi-subagent-review-poincare.md`

## Verdict

Poincare verdict 仍为 `blocked`，maturity level 为 2。

Poincare 认为当前文档没有严重 C8 overclaim：table-only comparator 被正确解释为负面
证据，而不是 C8 支持证据。关键 raw evidence 是
`results/phase1/20260615T-parent-key-poc/w4-ccache-table-compile.jsonl` 中的：

- `table_baseline_current_oracle_pass=true`
- `content_equivalent_table_oracle=true`
- `output_hash_match=true`
- `failures=0`
- `qualified_for_c8=false`

## 主要结论

1. C8 仍是最高风险 blocker。当前 sampled W4 可以被 exact table redirect 解释，不能证明
   需要 eBPF programmable path-resolution abstraction。
2. C1 仍没有 qualifying policy family。四个 use case 的设计方向足够多样，但当前证据仍是
   `functional_only`。
3. W4 table-only comparator 是重要反证：它提升了文档诚实度，但降低了当前 C8 成熟度。
4. 下一步最高价值实验是 W4 release-level cache-locality counterfactual：必须包含
   operation-weighted hit rate、output hash、stale/corrupt transition、update/stale window
   和 table update budget。

## Poincare 指出的立即修复项

Poincare 指出以下文档仍漏掉 table comparator：

- `docs/research_plan.md` 的 canonical Phase 1 run summary。
- `docs/paper/sections/05-evaluation.tex` 的 workload intro。
- `docs/paper/sections/04-implementation.tex` 的 W4 implementation narrative。
- `docs/paper/sections/04-implementation.tex` 的 W4 段尾，应说明 table-only 通过同一
  sampled oracle。

## 本轮修订

主 agent 已按上述 finding 做增量修订：

- `docs/research_plan.md`
  - 在 `20260615T-parent-key-poc` summary 中加入 W4 table-only ccache compile comparator。
- `docs/paper/sections/05-evaluation.tex`
  - 在 workload intro 中加入 W4 policy-attached compile witness 和 table-only compile
    comparator。
- `docs/paper/sections/04-implementation.tex`
  - 在 W4 implementation narrative 中加入 table-only ccache compile comparator。
  - 在 W4 段尾明确 table-only 也通过当前 sampled output oracle，因此是 C8 负面证据。

## 剩余 blocker

Poincare 的 `blocked` verdict 不应改变。当前项目仍缺：

- release-level W4 operation-weighted policy cache hit rate；
- 真实 stale/corrupt ccache 或 BuildKit/Prometheus Go cache transition；
- table-only 在同等 table/update budget 下失败、过度物化或违反 stale/update 门槛；
- 每个 policy family 的 qualifying workload rows；
- 干净 checkout、足够 repetitions、p95/p99/CI 和完整 baseline raw artifacts。
