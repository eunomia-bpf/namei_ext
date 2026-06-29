# 后续计划

## 2026-06-18 next-action summary

Stage at update: post scoped weak-accept / full-release follow-up.

Highest-value next benchmark work:

1. Agent sandbox lifecycle redesign: if broadening beyond the current scoped paper, make this one top-level use case and put fork/fanout, checkpoint rollback/restore, workspace materialization/update, and deterministic trace replay inside it. Do not include eval isolation.
2. W2 service fixture sandbox upgrade: keep W2 as the current positive anchor, but add a broader OSDI-grade sandbox benchmark only if it tests real app behavior, not more direct probes. Required pieces are nginx endpoint matrix, reload/update trace, cert/secret/poison path coverage under the real app or traced helper path, operation-weighted redirected hit rate, claim-specific comparison, and safety/semantic-boundary evidence.
3. W3 checkpoint/restore upgrade only if it feeds the agent sandbox lifecycle story: do not call the current W3 Redis RDB replay a restore benchmark. First make the Podman/CRIU capability gate pass, or replace this line with a real sandbox checkpoint/rollback workload. Then count only post-restore/post-rollback VFS operations and check health, state/config/cache hashes, runtime-local remap, 0 mixed epoch, natural comparisons, and safety/semantic-boundary evidence.
4. C3/C5 native overhead: if expanding beyond the tool-redirect slice, the next step is root-causing common hook/dispatch and per-dirent readdir overhead. FUSE speedup is no longer the blocker for the current scoped story.
5. C7/C8 full release: clean-checkout reproduction and missing evidence for the expressiveness/safety/efficiency balance remain the largest full-release risks.

The older 2026-06-16 follow-up list below is retained as detailed provenance.

Last updated: 2026-06-16
Stage at update: supplement
Source/command: OSDI evaluation audit of current result roots
Completeness: partial

## Highest-risk blocker

最高风险是 C8：当前证据还没有证明 `namei_ext` 作为动态 path-view abstraction 在 expressiveness、safety 和 efficiency 之间形成可推广的平衡；已有 exact-map diagnostics 在多个 sampled/path-oracle 场景中通过；最新
full Phase 1 refresh 和 B12 ledger 已经把 W3/W4 counterfactual artifacts 纳入同一个
canonical root；`c2-setup-update-v1` root 把 `namei_ext` raw setup/update rows
纳入 full Phase 1，最新 `c2-release-sample-v1` root 又把这些 rows 扩展到 20 个
unique samples，但 `qualified_families=0`、`release_gate_pass=false`。新增 W3
Redis same-workload diagnostic replay 也通过，只需要 2 条 rule 就能满足当前 Redis
checkpoint replay oracle。因此当前证据还不能证明 balanced dynamic path-view abstraction
在 release workloads 上成立。W4 cache-content same-workload diagnostic comparator 也通过，
说明当前 stale/corrupt/miss content oracle 仍可由预计算映射解释。W3
Podman/CRIU capability audit 也已机械化；当前 host 有 Podman 4.9.3，但 checkpoint
command 未列出且 CRIU 缺失，真实 restore 必须先修复环境能力。
第二风险是 C3/C5：batch=64 release rerun 已经让 B2/B8 `input_gate_pass=true`。
两个 RCU-pass fastpath PoC 都在 KVM 中跑通，但它们只降低 pass-only residual，同时把
最差 policy/native p99 从原始 1.77x 恶化到 2.49x 或 2.43x，因此已被拒绝。
ctx 初始化拆分 PoC 在 1-sample batch64 run 中把 pass-only/native worst case 降到
1.095x；但 tail10 diagnostic 将每组 latency rows 从 20 增到 200 后，
`fuse_speedup_threshold_pass=true`、`kernel_p99_threshold_pass=false`、
`pass_only_threshold_pass=false`。当前证据显示 FUSE speedup 不是主要 blocker，真正风险是
pass-only/readdir/tree-walk tail residual。新增 rusage/no-hook 诊断显示非 exec p99 rows
主要是 self CPU/op 上升，不是 fault/context-switch；baseline-only no-hook 和
matched baseline/pass-only 将 worst case 降到 1.306x/1.323x，但仍超过 1.1x C5 阈值。
C2 已有 `namei_ext` 侧 raw setup/update rows 和 release-sample repetition，并已有
fail-fast macrobench ledger；最新 ledger 显示 external baseline release rows 与
`namei_ext` release sample budget 都已满足。新增 workload derived ledger 已把 W1--W4
的 8 个 workload row 机械化，其中 5 个已有 correctness oracle 和 KVM policy witness，
但 `c2_eligible_rows=0`，因为真正的 KVM per-sample workload setup/storage/update
macrobench、完整 feature-equivalent baseline 和 C2 成功阈值仍缺。W2 nginx fixture 已有
20-sample KVM proposed-system setup/update raw input、同 workload `copy_tree`/`symlink_forest`/
`bind_mount`/`projected_volume`/`fuse_redirect` baseline input 和 thresholded W2 workload
ledger，证明真实 workload release repetition path 与五类 materialization/bind/projected/FUSE
baseline 可运行；v5 ledger 已让 W2 slice 的 storage footprint 和阈值通过。W1 build graph
已有 20-sample KVM proposed-system setup/update release input，以及 `copy_tree`、
`symlink_forest`、`bind_mount`、`projected_volume`、`fuse_redirect` 五类 baseline
release input；但 W1 release ledger 为负，`w1_c2_slice_supported=false`。W4 ccache
已有 parent-rule/table/materialized release input、bulk materialized baseline release
input、bulk FUSE cache-view baseline release input、bulk policy-attached compile
smoke witness 和 bulk policy setup/update release input；v6 W4 workload ledger 已把这些
bulk inputs 合并，但仍为负：`bulk_policy_release_input_pass=true`，而
`bulk_release_comparison_pass=false`，因为 bulk policy update 平均慢于 best external
update。W3 Redis checkpoint replay 也已补齐 proposed-system、materialized checkpoint-view
和 FUSE checkpoint-view 20-sample KVM release input；W3 ledger 记录
`storage_footprint_pass=true`，但 setup/update latency thresholds 失败，
`w3_c2_slice_supported=false`。全局 C2 现在不是缺 W3/FUSE input，而是 W1、W3、W4
均为负结果；下一步需要 W4 cache-remap/native ccache/BuildKit 或完整
compile-through-FUSE baseline、operation-weighted/stale-window evidence，或者 scope narrowing。

## Must-do follow-ups

| Priority | Claim | Experiment block | Concrete fix | Oracle | Result path |
|---|---|---|---|---|---|
| P0 | C3,C5 | B2/B8 | RCU-pass fastpath 已拒绝；ctx 初始化拆分只有部分 residual attribution；tail10 诊断显示 FUSE speedup 已过；rusage/no-hook 诊断已排除 fault/context-switch 为主因，并把 C5 blocker 定位到 common hook/dispatch CPU residual。下一步若继续性能线，需要设计 namei_ext helper-set/no-run-ctx fastpath 或更细 cgroup dispatch attribution；否则收窄 C3/C5。 | `kernel_p99_threshold_pass=true`、`pass_only_threshold_pass=true`，并保持 `fuse_speedup_threshold_pass=true`；或 claim narrowing 写入 `CLAIM_VERDICT.md` 和论文。 | `results/eval-osdi/paper/<run-id>/b2-performance/` |
| P0 | C2 | B3-B6 | 在已有 `eval-osdi-macrobench-ledger`、`eval-osdi-workload-macrobench-ledger`、`namei_ext` 20-sample release rows、W2 nginx 20-sample KVM setup/update raw input、W2 `copy_tree`/`symlink_forest`/`bind_mount`/`projected_volume`/`fuse_redirect` baseline、W2 thresholded ledger、W1 proposed-system 和五类 baseline release inputs、W3 proposed-system/materialized/FUSE release inputs，以及 W4 parent-rule/table/materialized release inputs、bulk materialized baseline、bulk FUSE cache-view baseline、bulk policy-attached compile smoke、bulk policy setup/update release input 和 v6 bulk-integrated W4 ledger 基础上，为 W4 建立 cache-remap/native ccache/BuildKit 或完整 compile-through-FUSE baseline、operation-weighted/stale-window evidence，或明确收窄。 | `macrobench_input_gate_pass=true` 已满足，W2 proposed-system 与五类 baseline release input summary 均 pass，`w2_c2_slice_supported=true`；W1 release input 和五类 baseline input pass，但 W1 ledger 为负，`w1_c2_slice_supported=false`，fastest baseline setup/update/storage 优于 proposed-system；W3 release input、materialized baseline 和 FUSE baseline pass，但 W3 ledger 为负，`w3_c2_slice_supported=false`，best external setup/update 优于 proposed-system；W4 release input pass，但 W4 ledger 为负，`w4_c2_slice_supported=false`。下一步必须让 W4 有完整且通过的同 schema comparison，或把 W1/W3/W4 写成负结果并收窄 C2。 | `results/eval-osdi/paper/<run-id>/b3-macrobench/` |
| P0 | C8 | B12 | 对每个 policy family 选择 conceptual comparison 和 workload-specific baseline，并补齐真实 workload oracle、operation-weighted coverage、stale/update-window evidence、安全/语义边界证据或外部机制对照。exact-map diagnostic 只在预计算映射是相关替代方案时运行。W3 下一步必须先让 capability target 通过，再做真实 restore、zero mixed epoch、restore trace 或 update/stale window。W4 下一步必须是 release-level operation-weighted hit rate、真实 stale/corrupt transition、BuildKit/Prometheus cache trace 或 update/stale window。 | balanced dynamic-path-view claim 只有在真实 workload oracle、自然 baseline 对照和 safety/semantic-boundary evidence 都支持时才升级；否则降级。 | `results/eval-osdi/paper/<run-id>/b12-policy-family/` |
| P1 | C1,C8 | B3 | W1 Redis/nginx release workload 中补完整 trace-derived alias set、natural poison/negative hit 和 operation-weighted redirected hit rate。 | binary output hash、poison/negative checker、hit-rate threshold。 | `results/phase1/<run-id>/w1-*` |
| P1 | C1,C8 | B4 | W2 PostgreSQL 真实 app health/query 与 no-real-secret trace checker。 | query result、fake secret used、real secret hash never opened。 | `results/phase1/<run-id>/w2-*` |
| P1 | C1,C8 | B5 | W3 真实 Podman/CRIU restore for Redis 或 nginx；前置条件是 `make workload-w3-podman-criu-capability` 通过。 | restore health、checkpoint hash、0 mixed epoch、post-restore trace。 | `results/phase1/<run-id>/w3-*` |
| P1 | C1,C8 | B6 | W4 Prometheus/BuildKit real Go cache run，或扩展 ccache 到 release operation-weighted hit rate。 | output hash、stale/corrupt reject、operation-weighted hit rate、update writes。 | `results/phase1/<run-id>/w4-*` |

## Should-do follow-ups

- 给 `docs/paper` 增加 paper-number import discipline：任何数字必须从 `research/RESULTS_SUMMARY.md` 或 generated report 引入。
- 增加 `research/ARTIFACT_CHECKLIST.md`，在 release gates 通过后检查 clean checkout、Docker image、KVM dependency 和 expected runtime。
- 给 `make help` 暴露未来 release-performance 和 baseline targets。

## Appendix candidates

- 当前 `kvm-bench` latency pilot 可作为 artifact/plumbing appendix，不进入主性能结论。
- 当前 exact-map diagnostics 是边界/负结果，应保留为 “scope narrowing” 表格。
- 当前 W4 ccache rule macrobench ledger 也是负结果：20-sample KVM release input 通过，
  但 parent-rule policy 没有超过 table baseline。
- 当前 W4 cache-content exact-map diagnostic pass 也是负结果，应保留为 “scope narrowing” 表格。
- 当前 W3 Redis exact-map diagnostic replay pass 也是负结果，应和 W4 一起保留为 B12
  scope-narrowing 表格。
- RCU-pass fastpath 两个 PoC 是性能负结果，可作为 appendix/engineering lesson，但不能作为主线优化或性能 claim。
- ctx 初始化拆分 PoC 是混合结果；tail10 进一步说明 1-sample pass-only 过阈值不够稳健。
- rusage/no-hook 诊断可作为 C5 appendix：它说明 pass-only residual 不是 page fault 或
  context-switch 主导，且 baseline denominator 有 order/cache variance；但 matched
  pass-only/native worst case 仍为 1.323x，不能支持主性能 claim。
- 直接移除 `bpf_cg_run_ctx` 或懒填 `cgroup_id` 需要 ABI/helper 设计，不能作为小补丁混入。

## Decision rule

- 如果 P0 baselines 中任一 feature-equivalent baseline 在 release workload 上与 `namei_ext`
  同等通过且性能相近，C3/C5 必须缩小。
- 如果四个 family 不能各自用真实 workload oracle、自然 baseline 对照和 safety/semantic-boundary evidence
  支持 balanced dynamic-path-view abstraction，C8 必须改写为 “eBPF policy family prototypes”，不能写成通用 abstraction claim。
