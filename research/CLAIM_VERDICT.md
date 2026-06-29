# 主张裁决

## 2026-06-18 current verdict snapshot

2026-06-29 baseline scope update: C8 should now be read as dynamic-policy
necessity relative to workload-appropriate baselines. Any older row below that
treats an exact-map diagnostic as the sole C8 path is historical provenance,
not current guidance.

Source/command: `results/eval-osdi/paper/20260617T-eval-claim-verdict-ledger-v17/claim-verdict/claim-verdict.jsonl`, W2 paper-release gate v6, W2 workload hardgate v11, W3 Redis workload ledger v7, C4 lookup/readdir matrix v4, and C7 artifact audit v11.

Completeness: scoped paper verdict complete; full release incomplete.

| Claim | Current verdict | Evidence boundary | What the paper may claim now | What remains outside scope |
|---|---|---|---|---|
| C1 | supported, scoped | Four Phase 1 KVM-backed policy families have functional slices and declared oracle rows. | A narrow VFS path-resolution extension can run four Phase 1 policy-family witnesses through the real `cgroup/namei_ext` attach path. | Release-level programmability across full real workloads. |
| C2 | supported only for W2 | W2 nginx fixture passes storage/setup/update/materialization gates against copy, symlink, bind, projected-volume, and FUSE baselines. | The W2 nginx sandbox fixture slice reduces setup/materialization cost under the declared baselines. | W1 build graph, W3 checkpoint/replay, and W4 cache locality are threshold-negative and cannot be rolled into global C2. |
| C3 | supported only for tool-redirect | Lookup/access/open/exec tool-redirect metadata rows pass native p99 and FUSE speedup thresholds. | The tool-redirect slice keeps selected metadata operations within the configured thresholds. | Full metadata suite remains negative because lookup-native-hot, readdir alias view, and build-tree stat walk still fail native overhead thresholds. |
| C4 | supported, scoped | C4 matrix v4 passes 4 families, 26 entries, 26 lookup rows, 26 readdir rows, and no duplicate or missing keys. | Declared W1-W4 Phase 1 lookup/readdir oracle entries are consistent. | Complete real workload correctness, dynamic update consistency, and C8. |
| C5 | scoped out | Residual overhead diagnostics remain negative. | Nothing stronger than diagnostic observations. | VFS placement/lower-FS ownership as a proven mechanism explanation. |
| C6 | scoped out | Phase 1 fail-fast/dmesg checks exist but no release stress matrix. | Phase 1 checks fail fast on declared gates. | Scalability, churn, reload, migration, and robustness claims. |
| C7 | scoped out | Artifact packaging/replay/anonymization evidence exists, but clean-checkout reproduction is still missing. | Make-owned evidence paths are inspectable. | Full release reproducibility. |
| C8 | scoped out | Current evidence does not show dynamic policy necessity relative to workload-appropriate baselines. Exact-map diagnostics only provide boundary/negative evidence. | No C8 positive claim. | "Programmable policy is necessary" as a broad claim. |

Key run verdict: claim verdict v17 records `weak_accept_ready=true`, `paper_release_gate_pass=true`, `release_gate_pass=false`, `active_main_claims=4`, `scoped_out_claims=4`, and highest-risk claims `C7` and `C8`.

The older 2026-06-16 table below is retained as historical provenance.

Last updated: 2026-06-16
Stage at update: claim-gate
Source/command: `research/RESULTS_SUMMARY.md` plus refreshed B12 ledger, C2 macrobench/workload-derived ledgers, W2 workload ledger, W1 build macrobench release input, W1 baseline/ledger release input, W3 Redis policy/materialized/FUSE release input, W3 workload ledger, W4 ccache rule/materialized release input, W4 bulk ccache trace/bridge smoke, W4 bulk materialized baseline release input, W4 bulk policy-attached compile smoke, W4 bulk policy setup/update release input, W4 bulk FUSE cache-view baseline release input, W4 bulk-integrated workload ledger v6, batch=64, RCU-fastpath, ctx-init-split, tail10 comparison, rusage, and no-hook diagnostic artifacts
Completeness: partial

| Claim | Verdict | Evidence | Supported wording | Missing evidence |
|---|---|---|---|---|
| C1 | blocked | 当前 B12 ledger 基于 `20260615T-full-phase1-c2-setup-update-v1`，记录 4 个 semantic witnesses，但 `qualified_families=0`，hard gate 也按预期失败。 | 当前只能说“Phase 1 原型在 KVM 中展示了四类 policy family semantic witnesses”。 | 每个 family 至少两个真实 workload release rows、release metrics、table counterfactual support。 |
| C2 | unsupported | C2 input gate 已满足到较细粒度：`20260615T-eval-c2-release-sample-ledger-v1` 中 `macrobench_input_gate_pass=true`，W2 nginx v5 workload ledger 中 `w2_c2_slice_supported=true`，W1 build graph v2 ledger 已有五类 feature baseline 但 `w1_c2_slice_supported=false`。W3 Redis v1 workload ledger 已有 proposed-system、`materialized_checkpoint_view` 和 `fuse_redirect` 20-sample KVM release input，但 `w3_c2_slice_supported=false`：policy setup/update 平均 22.96 ms/5.16 s，best external setup/update 平均 6.52 ms/5.15 s。W4 已有 parent-rule/materialized release input且为负；v6 bulk ledger 又加入 `20260616T-w4-ccache-bulk-policy-macrobench-release-v1` proposed-system setup/update release input、bulk materialized baseline、bulk FUSE cache-view baseline 和 compile smoke witness，但 `bulk_release_comparison_pass=false`、`w4_c2_slice_supported=false`。 | 可以说“Phase 1 已在 KVM 中记录 namei_ext release-sample setup/update input；W2 nginx slice 过 storage/threshold；W1、W3 和 W4 在完整或更强 baseline 下仍是负结果；W3 FUSE/materialized rows 和 W4 bulk proposed-system/materialized/FUSE rows 已进入 claim-level ledger”。不应在 intro/abstract 中写全局 materialization cost improvement。 | 只能通过 scope narrowing、把 W1/W3/W4 明确写成负结果、或新增能改变 W3/W4 comparison 的真实 workload/baseline evidence；W4 仍缺 complete compile-through-FUSE 或 native/cache-remap/BuildKit baseline、stale/corrupt/update window、BuildKit/Prometheus cache trace。 |
| C3 | unsupported | 最新 release-level tail10 comparison summary 为 `input_gate_pass=true`、`fuse_speedup_threshold_pass=true`，但 `kernel_p99_threshold_pass=false`。max `policy/native` p99 ratio 为 4.37x，min `policy/FUSE` p99 speedup 为 2.26x。rusage/no-hook diagnostic 不替代该 comparison，只说明非 exec tail 更像 common hook/dispatch CPU residual。 | 只能说“release input 已经足以暴露当前 prototype 的 p99 overhead 风险；更密 tail sampling 消除了 FUSE speedup blocker，但没有解决 kernel p99”。 | 降低 common dispatch/hook residual，或收窄/删除 kernel-baseline 性能主张。 |
| C4 | partial | Phase 1 path oracles and report gates check lookup/readdir semantics for declared policies。 | “For the declared Phase 1 PASS/REDIRECT policies, KVM checkers validate lookup/readdir witnesses。” | dynamic update/epoch consistency、concurrency、fault/reload behavior。 |
| C5 | unsupported | 最新 release-level tail10 comparison shows `pass_only_threshold_pass=false`，max pass-only/native p99 ratio 为 2.62x。新增 no-hook 和 matched baseline/pass-only diagnostics 将 worst case 降到 1.306x/1.323x，但仍高于 1.1x；rusage 显示非 exec p99 rows 主要是 self CPU/op 上升，不是 fault/context-switch。 | 可以说“ctx 初始化拆分和 rusage/no-hook 诊断定位了 pass-only residual 的一部分来源”；不应 claim VFS placement 已解释整体性能。 | 设计 helper-set/no-run-ctx 或其他 common dispatch 降低方案；若不改 ABI/helper fastpath，则收窄机制归因。 |
| C6 | partial | Phase 1 dmesg gates and some failure semantics exist。 | “Phase 1 gates fail fast on declared smoke checks。” | full invalid redirect/verifier/map exhaustion/detach/reload/cgroup migration/stress matrix。 |
| C7 | partial | Makefile-owned KVM/Docker path and provenance artifacts exist。 | “The prototype has Makefile-owned Phase 1 reproduction artifacts。” | clean tree final run、artifact checklist、release result manifest、external reproducibility audit。 |
| C8 | unsupported | 当前 B12 ledger 仍为 `c8_supported=false`；多个 exact-map diagnostics/current oracle 都能通过；W3 Redis same-workload diagnostic 以 `table_rule_writes=2` 和 `table_baseline_current_oracle_pass=true` 通过；W3 Podman/CRIU capability audit 显示 `podman_checkpoint_listed=false`、`criu_present=false`；W4 cache-content same-workload diagnostic 也以 `content_equivalent_table_oracle=true` 通过，并且 B12 记录 `content_table_counterfactual_negative=true`；W4 sampled ccache diagnostic 也通过。W4 bulk ccache rows 现在证明 proposed system 和外部 materialized/FUSE cache-view baselines 都能在 20-source/40-object shape 上运行，但 v6 仍记录 `bulk_release_comparison_pass=false`、`operation_weighted_policy_cache_hit_rate=false` 和 `qualified_for_c8=false`；仍没有 external-baseline weakness、release operation-weighted advantage 或真实 workload necessity evidence。 | 还不能声称外部 materialized/FUSE baseline 或 native cache tooling 不足以表达这些场景。 | 四个 family class 的 release workloads 上需要 workload-appropriate baseline comparison；W3 还需要可运行的真实 Podman/CRIU restore 环境、restore trace、zero mixed epoch 或 update/stale window；W4 还需要 release operation-weighted hit rate、真实 stale/corrupt transition、BuildKit/Prometheus trace、cache-remap/native ccache/BuildKit baseline、完整 compile-through-FUSE baseline、external-baseline weakness 或 update/stale window。 |

## Paper wording guard

在上述 verdict 改变前，论文中文稿必须避免：

- “证明通用可编程 path-resolution abstraction”。
- “性能优于 FUSE/OverlayFS/symlink/bind/copy”。
- “四个 use case 都达到 OSDI release evidence”。
- “exact-map diagnostic 已证明这些场景必须使用 dynamic policy”。

允许的当前 wording：

- “Phase 1 原型在修改内核 KVM 中跑通了四类 policy semantic witnesses。”
- “当前 evaluation contract 明确阻止 threshold-failing release evidence 被误写成 supported claim。”
- “现有负结果显示 C8 仍需更强 release workload 和 baseline comparison 才能支持。”
