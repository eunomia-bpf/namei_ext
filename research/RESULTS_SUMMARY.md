# 结果总结

Last updated: 2026-06-29
Stage at update: analyze
Source/command: current Phase 1 and eval ledger result roots
Completeness: partial

## Headline result

当前结果证明：修改内核 KVM 中的 Phase 1 smoke path 可以加载并执行多类 `namei_ext`
eBPF policies，真实 workload provenance 和若干真实应用 witness 已经进入 Makefile-owned
pipeline。

当前结果不能证明：OSDI 级 C1/C8 programmable abstraction、C2/C3/C5 performance
advantage、或 submission-ready paper。B2/B8 的 release input 已经通过；tail10
diagnostic 让 FUSE speedup 阈值通过，但 kernel p99 和 pass-only residual 仍失败。
新增 rusage/no-hook 诊断显示该 residual 主要是 common hook/dispatch CPU 成本，而不是
fault 或 context-switch；matched baseline/pass-only run 将 worst case 降到 1.32x，
但仍高于 1.1x C5 阈值。W3 Redis checkpoint same-workload table-only replay 已补齐，
结果显示 table_redirect 也能通过当前 Redis replay，因此这是 C8 负证据。C2 macrobench
ledger 已补齐为 fail-fast contract；最新 release-sample root 让 `namei_ext`
setup/source-update/policy-update 都达到 20 个 unique samples，C2 macrobench ledger 的
`macrobench_input_gate_pass=true`，但 `c2_supported=false` 且 hard gate 仍然失败。W4
cache-content same-workload table-only
comparator 也已补齐，结果同样通过，因此当前 W4 stale/corrupt/miss content oracle
也不能支持 C8。最新 full Phase 1 refresh 已把 W3/W4 counterfactual artifacts 和
`namei_ext` raw setup/update rows 纳入同一个 canonical root，并用 B12 ledger/hardgate
确认 `qualified_families=0`、`release_gate_pass=false`。C2 blocker 现在从“没有
`namei_ext` setup/update raw rows”进一步缩小为“W1/W3/W4 workload-equivalent
macrobench 是负结果，只有 W2 slice 通过 C2 成功阈值”。新增 C2 workload derived ledger 已把 8 个 W1--W4
workload row、5 个已有 correctness oracle 和 5 个已有 KVM policy witness 机械化，
但 `c2_eligible_rows=0`，因此它是 blocked inventory，不是 C2 支持证据。随后新增
W2 nginx fixture KVM setup/update macrobench，20 个 samples 都通过 setup、update 和
correctness rows，证明真实 workload release repetition raw input 已跑通；随后新增同
workload `copy_tree`/`symlink_forest`/`bind_mount`/`projected_volume`/`fuse_redirect`
baseline 20-sample run 和 W2 workload macrobench ledger，证明三类
materialization/bind baseline、projected-volume-equivalent atomic-writer baseline
以及 FUSE path-remap baseline 可运行并被纳入 claim-level expected-fail gate。最新 v5
ledger 进一步把 W2 storage footprint aggregation 和显式 setup/update/materialization
threshold 机械化，`w2_c2_slice_supported=true`；当时全局 C2 仍缺 W1
proposed-system release input/baselines/threshold 和 W3/W4 对等 workload macrobench。随后 W1
build graph 已从 1-sample KVM proposed-system setup/update PoC 推进到 20-sample
KVM proposed-system release input，并补齐同 workload `copy_tree`、`symlink_forest`、
`bind_mount`、`projected_volume` 和 `fuse_redirect` 五类 20-sample KVM baseline release
input。最新 W1 workload ledger 显示 `baseline_release_input_pass=true`、
`projected_volume_baseline_pass=true`、`fuse_baseline_pass=true` 和
`full_feature_equivalent_baseline_pass=true`，但
`storage_footprint_pass=false`、`setup_latency_threshold_pass=false`、
`update_latency_threshold_pass=false`、`update_materialization_threshold_pass=false` 和
`w1_c2_slice_supported=false`；同时 fastest baseline 在 setup/update/storage 上优于
proposed-system，因此 W1 当前是完整 baseline 下的负结果，不改变全局 C2 verdict。
随后 W3 Redis checkpoint replay 也补齐 20-sample KVM proposed-system setup/update
release input，并补齐同 workload `materialized_checkpoint_view` 和 `fuse_redirect`
baseline release input。W3 workload ledger 记录 `policy_release_input_pass=true`、
`baseline_release_input_pass=true`、`materialized_baseline_pass=true`、
`fuse_baseline_pass=true`、`full_feature_equivalent_baseline_pass=true` 和
`storage_footprint_pass=true`，但 `setup_latency_threshold_pass=false`、
`update_latency_threshold_pass=false`、`threshold_pass=false` 和
`w3_c2_slice_supported=false`。policy setup/update 均值为 22.96 ms/5.16 s，
best external setup/update 均值为 6.52 ms/5.15 s。因此 W3 现在是 release input
已补齐后的负结果，不再是 C2 input 缺口。
随后 W4 ccache 已从 table-only/function witnesses 推进到 20-sample KVM
parent-rule/table baseline setup/update release input。新的 W4 workload ledger 显示
release raw input、table baseline 和 storage footprint 都通过，但 setup/update latency
阈值不通过，parent-rule policy 平均慢于 table baseline，且 rule writes 相同。因此 W4
当前也是 C2 负结果，不改变全局 C2 verdict。
后续 bulk ccache smoke 已把 W4 trace shape 从 2 个 source/4 个 cache objects 扩到
20 个真实 Redis/nginx source、400 条 cache-path file ops 和 40 个 trace-derived
cache objects，并在修改内核 KVM 中通过 `cache_locality_view.bpf.c` policy bridge；
这为下一轮 bulk baseline 和 operation-weighted hit-rate 提供输入，但尚不改变 W4
负 verdict。
随后 bulk materialized cache baseline 已补到同一个 20-source/40-object trace shape：
`20260616T-w4-ccache-bulk-materialized-release-v1` 在修改内核 KVM 中对 40 个
trace-derived cache objects 跑 20-sample 外部 `materialized_cache_view` baseline，
setup 平均 484.83 ms、update 平均 3.12 ms，correctness 全部通过。它补的是更强
baseline 输入，不是 W4 正结果。随后
`20260616T-w4-ccache-bulk-policy-compile-smoke-v1` 又在同一 bulk trace shape 上运行
attached `cache_locality_view.bpf.c` hot compile witness，20 个真实 source 全部编译并
匹配输出 hash，40 个 redirected cache objects 和 400 条 cache-path file ops 被记录。
这关闭了“完全没有 bulk proposed-system policy-attached compile”的输入缺口，但它仍只是
smoke witness。随后 `20260616T-w4-ccache-bulk-fuse-baseline-release-v1` 在同一
20-source/40-object bulk shape 上运行 20-sample 外部 FUSE cache-view baseline，
记录 20 setup/update/correctness rows、`fuse_mounts=1`、setup 平均 794.16 ms、
update 平均 2.28 ms、input hash 复验通过和 dmesg issue count 0。它关闭的是
read-oriented FUSE cache-view baseline 输入缺口，不是完整 compile-through-FUSE
ccache 对照。随后 `20260616T-w4-ccache-bulk-policy-macrobench-release-v1`
补上同一 bulk shape 的 proposed-system release setup/update input：20 setup rows、
20 update rows、20 correctness rows、`policy_executed=true`、`pass=true`。
最新 W4 workload ledger v6 已把非 bulk parent-rule/table/materialized rows、bulk
policy-attached compile smoke、bulk policy setup/update release input、bulk materialized
external baseline 和 bulk FUSE cache-view external baseline 合并到同一个 claim-level
artifact。该 summary 记录 `bulk_policy_compile_smoke_pass=true`、
`bulk_policy_release_input_pass=true`、`bulk_materialized_baseline_pass=true`、
`bulk_fuse_baseline_pass=true`、`bulk_external_baseline_release_input_pass=true`、
`bulk_release_comparison_pass=false` 和 `release_gate_pass=false`。bulk policy setup
平均 336.19 ms，优于 best external setup 484.83 ms；但 bulk policy update 平均
4.99 ms，慢于 best external update 2.28 ms。因此新增 FUSE baseline 和 proposed-system
release 测试已经入账，但 W4 仍是负 verdict，而不是 C2/C8 支持证据。
2026-06-29 又新增 W3 checkpoint epoch targeted counterfactual，并随后补入同 oracle 的
materialized view 和 FUSE baseline：`20260629T-w3-checkpoint-epoch-c8-fuse-v2`
在修改内核 KVM 中比较 `checkpoint_restore_view.bpf.c`、static exact table、
externally-updated exact table、external `materialized_checkpoint_epoch_view` 和 external
`fuse_checkpoint_epoch_view`。static table 在 epoch 切换后失败，externally-updated table、
materialized view 和 FUSE view 都保持 correctness，但三者都需要 `update_write_ratio=16`，
超过预算 10；该 run 明确记录 `targeted_c8_budget_failure=true`、
`materialized_feature_equivalent_baseline=true`、`fuse_feature_equivalent_baseline=true`、
`real_podman_criu_restore=false`、`qualified_for_c8=false` 和 `release_gate_pass=false`。
因此它是更强的 W3 update-budget 机制证据，不是完整 Podman/CRIU checkpoint/restore
release 证据。
同日 W4 cache epoch targeted counterfactual 又补入同 oracle 的 materialized view 和 FUSE baseline：
`20260629T-w4-cache-epoch-c8-fuse-v1` 在修改内核 KVM 中比较
`cache_locality_view.bpf.c`、static exact table、externally-updated exact table 和
external `materialized_cache_epoch_view`、external `fuse_cache_epoch_view`。static table
在 cache epoch 切换后失败，externally-updated table、materialized view 和 FUSE view
都保持 correctness，但三者都需要 `update_write_ratio=16`，超过预算 10；该 run 明确记录
`targeted_c8_budget_failure=true`、`materialized_feature_equivalent_baseline=true`、
`fuse_feature_equivalent_baseline=true`、`real_ccache_trace=false`、`qualified_for_c8=false`
和 `release_gate_pass=false`。
因此它是更强的 W4 update-budget 机制证据，不是完整 ccache/BuildKit release 证据。

## Completed runs

| Run | Result path | Key observations | Claim effect |
|---|---|---|---|
| Phase 1 full smoke `20260615T-full-phase1-bench-variants` | `results/phase1/20260615T-full-phase1-bench-variants/` | `bench.jsonl` 有 35 个 aggregate row、5 个 variant、0 failing ops、`table_redirect_hit` 66 map updates、4 attach success。 | 支持 smoke-level C4/C7，不能支持 C2/C3/C5 release。 |
| B12 policy-family ledger `20260615T-eval-contract-bench-variants` | `results/eval-osdi/paper/20260615T-eval-contract-bench-variants/b12-policy-family/` | 4 个 family 都有 `semantic_witness_pass=true`，但 `qualified_families=0`、`release_gate_pass=false`。 | C1/C8 blocked。 |
| B2/B8 performance ledger `20260615T-eval-ledger-after-latency-code-p2fix` | `results/eval-osdi/paper/20260615T-eval-ledger-after-latency-code-p2fix/b2-performance/` | `samples=1`、`bench_latency_rows=0`、`has_tail_latency_artifact=false`、缺 FUSE/copy/symlink/bind/OverlayFS baselines。 | C2/C3/C5 unsupported。 |
| KVM latency pilot `20260615T-kvm-bench-latency-pilot` | `results/phase1/20260615T-kvm-bench-latency-pilot/` | 35 aggregate rows、70 latency rows、0 failure、4 attach、66 table updates。 | 证明 raw latency plumbing，可作为后续 release run 基础；不能单独支持 paper claim。 |
| Tail artifact pilot `20260615T-tail-artifact-pilot` | `results/eval-osdi/paper/20260615T-tail-artifact-pilot/b2-performance/` | 从 R004 的 70 条 `bench_latency` rows 生成 35 个 p50/p95/p99/pilot-scale CI 统计 row；`has_release_sample_budget=false`。 | 证明 analysis target，可作为 appendix/plumbing evidence；不能支持 C3 release。 |
| B2/B8 performance ledger `20260615T-eval-ledger-tail-artifact` | `results/eval-osdi/paper/20260615T-eval-ledger-tail-artifact/b2-performance/` | canonical full root 仍为 `samples=1`、`bench_latency_rows=0`、`has_tail_latency_artifact=false`、`release_gate_pass=false`。 | C2/C3/C5 仍 unsupported。 |
| External baseline smoke `20260615T-kvm-external-baselines-content-v1` | `results/eval-osdi/baselines/20260615T-kvm-external-baselines-content-v1/` | copy_tree、symlink_forest、bind_mount、overlayfs 均在修改内核 KVM 内通过，raw rows=78、bench rows=32、latency rows=32、每个 baseline 都有 `read_tool_content` update oracle、0 failure；FUSE 缺失。 | 证明 baseline infrastructure，可减少 B2/B8 missing-baseline list；不能支持 release performance claim。 |
| B2/B8 performance ledger `20260615T-eval-ledger-content-baselines` | `results/eval-osdi/paper/20260615T-eval-ledger-content-baselines/b2-performance/` | performance ledger 识别 copy/symlink/bind/OverlayFS baseline 为 true，`missing_release_baselines=["fuse_redirect"]`；但 canonical full root 仍无 latency rows，`release_gate_pass=false`。 | C2/C3/C5 仍 unsupported。 |
| External baseline smoke `20260615T-kvm-external-baselines-fuse-smoke-v2` | `results/eval-osdi/baselines/20260615T-kvm-external-baselines-fuse-smoke-v2/` | copy_tree、symlink_forest、bind_mount、overlayfs 和 fuse_redirect 均在修改内核 KVM 内通过，raw rows=97、bench rows=40、latency rows=40、每个 baseline 都有 `read_tool_content` update oracle、0 failure；FUSE row 记录 `fuse_mounts=1`；dmesg issue count 0。 | 证明 5-baseline smoke infrastructure；不能支持 release performance claim。 |
| B2/B8 performance ledger `20260615T-eval-ledger-fuse-baselines-smoke` | `results/eval-osdi/paper/20260615T-eval-ledger-fuse-baselines-smoke/b2-performance/` | performance ledger 识别 copy/symlink/bind/OverlayFS/FUSE baseline 为 true，`missing_release_baselines=[]`；但 canonical full root 仍无 latency rows，`release_gate_pass=false`。 | C2/C3/C5 仍 unsupported。 |
| KVM run-order/system-metrics pilot `20260615T-kvm-bench-order-metrics-pilot-v3` | `results/phase1/20260615T-kvm-bench-order-metrics-pilot-v3/` | `bench-done status=0`；35 bench rows、70 latency rows、35 bench-order rows、5 variant-order rows、2 system-metric rows、0 failure；`metadata.json` present。 | 证明随机化顺序、系统指标和 provenance 可进入单独 KVM bench root；不能支持 release performance claim。 |
| B2/B8 performance ledger `20260615T-eval-ledger-order-metrics-pilot-v2` | `results/eval-osdi/paper/20260615T-eval-ledger-order-metrics-pilot-v2/b2-performance/` | `has_tail_latency_artifact=true`、`has_confidence_interval=true`、`has_randomized_order=true`、`has_system_metrics=true`、五个 baseline flags 全 true、`missing_release_baselines=[]`；`has_release_tail_sample_budget=false`、`release_gate_pass=false`。 | C2/C3/C5 仍 unsupported，但 release blocker 缩小到 release repetitions/sample budget。 |
| KVM release-sample microbench pilot `20260615T-kvm-bench-release-sample-pilot` | `results/phase1/20260615T-kvm-bench-release-sample-pilot/` | `bench-done status=0`；700 bench rows、700 latency rows、700 bench-order rows、5 variant-order rows、2 system-metric rows、0 failure；`metadata.json` present。 | 证明 microbench root 可以满足 20-sample release tail sample budget；不能单独支持 C2/C3/C5。 |
| B2/B8 performance ledger `20260615T-eval-ledger-release-sample-pilot` | `results/eval-osdi/paper/20260615T-eval-ledger-release-sample-pilot/b2-performance/` | `has_repetition_budget=true`、`has_release_tail_sample_budget=true`、`has_randomized_order=true`、`has_system_metrics=true`、五个 baseline smoke flags 全 true；`release_gate_pass=false`。 | Microbench 侧 release sample budget 已通过；后续 R023/R024 补齐 external baseline release gate。 |
| External baseline release pilot `20260615T-kvm-external-baselines-release-pilot` | `results/eval-osdi/baselines/20260615T-kvm-external-baselines-release-pilot/` | raw rows=1617、bench rows=800、latency rows=800、5 个 baselines 全部 `qualified_for_baseline_release=true`，FUSE `fuse_mounts=1`，dmesg issue count 0。 | 证明 external baseline release sample-budget gate；不能单独支持 C2/C3/C5。 |
| B2/B8 performance ledger `20260615T-eval-ledger-release-baselines-pilot` | `results/eval-osdi/paper/20260615T-eval-ledger-release-baselines-pilot/b2-performance/` | `has_repetition_budget=true`、`has_release_tail_sample_budget=true`、`has_randomized_order=true`、`has_system_metrics=true`、`baseline_release_gate_pass=true`、`missing_release_baselines=[]`；`release_gate_pass=false`。 | 旧输入证据具备 20 samples，但后来发现 latency batch 太小，不能作为 paper-grade p99 输入。 |
| External baseline expected-set smoke `20260615T-kvm-external-baselines-expected-set-smoke-v1` | `results/eval-osdi/baselines/20260615T-kvm-external-baselines-expected-set-smoke-v1/` | 5 个 baseline 都覆盖固定 8-case expected benchmark set；`baseline_smoke_gate_pass=true`、`baseline_release_gate_pass=false`，每 case 只有 1 row。 | 证明 baseline release gate 不会因少跑 case 误过；不能支持 release performance。 |
| B2/B8 comparison verdict `20260615T-eval-comparison-pilot-v1` | `results/eval-osdi/paper/20260615T-eval-comparison-pilot-v1/b2-performance/` | 当时规则下 `input_gate_pass=true`、`comparison_rows_complete=true`，但 `kernel_p99_threshold_pass=false`、`fuse_speedup_threshold_pass=false`、`pass_only_threshold_pass=false`；max policy/native p99 ratio 8.18x，min policy/FUSE p99 speedup 1.45x，max pass-only/native p99 ratio 4.36x。后续 latency-batch gate 将该 run 降级为 diagnostic negative evidence。 | C2/C3/C5 unsupported；不能作为 paper-grade p99 release evidence。 |
| B2/B8 comparison hard gate `20260615T-eval-comparison-hardgate-v1` | `results/eval-osdi/paper/20260615T-eval-comparison-hardgate-v1/b2-performance/` | `make eval-osdi-performance` 生成 comparison artifacts 后按预期失败。 | 防止 input evidence 被误写为 supported performance claim。 |
| B2/B8 latency-batch gate `20260615T-eval-comparison-latency-batch-gate-v1` | `results/eval-osdi/paper/20260615T-eval-comparison-latency-batch-gate-v1/b2-performance/` | internal/external tail 都有 `has_release_sample_budget=true`，但 `min_ops_per_latency_row=4`、`required_latency_batch=64`、`has_release_latency_batch_budget=false`；comparison summary 为 `input_gate_pass=false`、`verdict=blocked_by_missing_inputs`。 | 旧 R019/R023 raw evidence 保留为 diagnostic，不再算 paper-grade release p99 input。 |
| External baseline unique-sample smoke `20260615T-kvm-external-baselines-unique-sample-smoke-v1` | `results/eval-osdi/baselines/20260615T-kvm-external-baselines-unique-sample-smoke-v1/` | `baseline_smoke_gate_pass=true`、`baseline_release_gate_pass=false`、`baseline_unique_sample_budget_pass=false`、每 case 唯一 sample 数为 1。 | 证明 baseline release gate 不会被重复 sample id 或 smoke rows 误过。 |
| KVM batch=64 release microbench `20260615T-kvm-bench-release-batch64-v1` | `results/phase1/20260615T-kvm-bench-release-batch64-v1/` | 700 个 aggregate rows、700 个 latency rows、700 个 bench-order rows、5 个 variant-order rows、20 个 unique samples、`min_ops_per_latency_row=64`、0 failure。 | B2/B8 internal release latency batch input 通过。 |
| External baseline batch=64 release `20260615T-kvm-external-baselines-batch64-v1` | `results/eval-osdi/baselines/20260615T-kvm-external-baselines-batch64-v1/` | raw rows=1617、bench rows=800、latency rows=800、5 个 baselines release-pass、`baseline_unique_sample_budget_pass=true`、min unique samples per case = 20。 | B2/B8 external baseline release input 通过。 |
| B2/B8 batch=64 comparison verdict `20260615T-eval-comparison-batch64-v1` | `results/eval-osdi/paper/20260615T-eval-comparison-batch64-v1/b2-performance/` | `input_gate_pass=true`、`has_internal_latency_batch=true`、`has_external_latency_batch=true`，但 `kernel_p99_threshold_pass=false`、`fuse_speedup_threshold_pass=false`、`pass_only_threshold_pass=false`；max policy/native p99 ratio 1.77x、min policy/FUSE p99 speedup 1.33x、max pass-only/native p99 ratio 1.71x。 | C2/C3/C5 仍 unsupported；当前已是 release threshold failure，而不是 input-blocked。 |
| B2/B8 batch=64 hard gate `20260615T-eval-comparison-batch64-hardgate-v1` | `results/eval-osdi/paper/20260615T-eval-comparison-batch64-hardgate-v1/b2-performance/` | `make eval-osdi-performance` 生成 comparison artifacts 后按预期失败，退出状态 2。 | 防止 threshold-failing release evidence 被误写为 supported claim。 |
| RCU-pass fastpath PoC `20260615T-eval-comparison-rcu-pass-batch64-v1` | `results/eval-osdi/paper/20260615T-eval-comparison-rcu-pass-batch64-v1/b2-performance/` | PoC 在 KVM 中可运行，input gate 通过；pass-only/native 从原始 batch=64 的 1.71x 降到 1.48x，但 max policy/native p99 恶化到 2.49x，min policy/FUSE speedup 为 1.62x，三项阈值仍失败。 | 负结果；RCU PASS fastpath 不保留，不能支持 C3/C5。 |
| RCU redirect-unlazy PoC `20260615T-eval-comparison-rcu-redirect-unlazy-batch64-v1` | `results/eval-osdi/paper/20260615T-eval-comparison-rcu-redirect-unlazy-batch64-v1/b2-performance/` | PoC 在 KVM 中可运行，input gate 通过；pass-only/native 降到 1.38x，但 max policy/native p99 仍恶化到 2.43x，min policy/FUSE speedup 为 1.70x，三项阈值仍失败。 | 负结果；`try_to_unlazy(nd)` 版本也不保留，不能支持 C3/C5。 |
| Post-RCU stable smoke `20260615T-kvm-bench-post-rcu-experiment-stable-smoke-v1` | `results/phase1/20260615T-kvm-bench-post-rcu-experiment-stable-smoke-v1/` | RCU fastpath PoC 撤回后重新构建内核并运行 KVM bench smoke：35 bench rows、35 latency rows、`min_ops_per_latency_row=64`、0 failure、bench status 0。 | 确认当前稳定路径仍能在 KVM 中运行；不改变 canonical batch=64 performance verdict。 |
| ctx 初始化拆分 smoke `20260615T-kvm-bench-ctx-init-split-smoke-v1` | `results/phase1/20260615T-kvm-bench-ctx-init-split-smoke-v1/` | `make kernel` 通过；KVM smoke 有 35 bench rows、35 latency rows、`min_latency_ops=64`、0 failure、bench status 0。 | 证明 no-UAPI-change ctx 初始化拆分 PoC 可启动并跑通 KVM smoke。 |
| ctx 初始化拆分 internal release input `20260615T-kvm-bench-ctx-init-split-batch64-v1` | `results/phase1/20260615T-kvm-bench-ctx-init-split-batch64-v1/` | 700 bench rows、700 latency rows、20 unique samples、`min_latency_ops=64`、0 failure、bench status 0。 | B2/B8 internal release input 通过，可用于 R048 comparison。 |
| ctx 初始化拆分 external baselines `20260615T-kvm-external-baselines-ctx-init-split-batch64-v1` | `results/eval-osdi/baselines/20260615T-kvm-external-baselines-ctx-init-split-batch64-v1/` | raw rows=1617、bench rows=800、latency rows=800、5 个 baselines 全部 release-pass、runner failures 0。 | B2/B8 external baseline release input 通过，可用于 R048 comparison。 |
| ctx 初始化拆分 comparison `20260615T-eval-comparison-ctx-init-split-batch64-v1` | `results/eval-osdi/paper/20260615T-eval-comparison-ctx-init-split-batch64-v1/b2-performance/` | `input_gate_pass=true`、`pass_only_threshold_pass=true`，但 `kernel_p99_threshold_pass=false`、`fuse_speedup_threshold_pass=false`；max policy/native p99 ratio 1.81x、min policy/FUSE p99 speedup 1.64x、max pass-only/native p99 ratio 1.095x。 | 混合结果；证明 ctx 初始化是 residual overhead 的一部分，但 C2/C3/C5 仍 unsupported。 |
| ctx 初始化拆分 hard gate `20260615T-eval-comparison-ctx-init-split-batch64-hardgate-v1` | `results/eval-osdi/paper/20260615T-eval-comparison-ctx-init-split-batch64-hardgate-v1/b2-performance/` | `make eval-osdi-performance` 生成 comparison artifacts 后按预期失败，退出状态 2。 | 防止 pass-only-only improvement 被误写为 supported performance claim。 |
| tail10 sample-density internal input `20260615T-kvm-bench-ctx-init-split-tail10-v1` | `results/phase1/20260615T-kvm-bench-ctx-init-split-tail10-v1/` | 700 bench rows、7000 latency rows、20 unique samples、10 latency samples/sample、`min_latency_ops=64`、0 failure。 | 诊断 20-row p99=max 是否扭曲 R048。 |
| tail10 sample-density external baselines `20260615T-kvm-external-baselines-ctx-init-split-tail10-v1` | `results/eval-osdi/baselines/20260615T-kvm-external-baselines-ctx-init-split-tail10-v1/` | raw rows=8817、bench rows=800、latency rows=8000、5 个 baselines 全部 release-pass、runner failures 0。 | 为 tail10 comparison 提供同密度 external baselines。 |
| tail10 sample-density comparison `20260615T-eval-comparison-ctx-init-split-tail10-v1` | `results/eval-osdi/paper/20260615T-eval-comparison-ctx-init-split-tail10-v1/b2-performance/` | `input_gate_pass=true`、`fuse_speedup_threshold_pass=true`，但 `kernel_p99_threshold_pass=false`、`pass_only_threshold_pass=false`；max policy/native p99 ratio 4.37x、min policy/FUSE p99 speedup 2.26x、max pass-only/native p99 ratio 2.62x。 | 诊断负结果；FUSE blocker 消失，pass-only/readdir/tree-walk residual 成为主要 blocker。 |
| tail10 sample-density hard gate `20260615T-eval-comparison-ctx-init-split-tail10-hardgate-v1` | `results/eval-osdi/paper/20260615T-eval-comparison-ctx-init-split-tail10-hardgate-v1/b2-performance/` | `make eval-osdi-performance` 生成 artifacts 后按预期失败，退出状态 2。 | 防止 tail10 diagnostic evidence 被误写为 supported claim。 |
| rusage collector smoke `20260615T-kvm-bench-rusage-smoke-v1` | `results/phase1/20260615T-kvm-bench-rusage-smoke-v1/` | 35 bench rows、35 latency rows、`missing_rusage_bench=0`、`missing_rusage_latency=0`、0 failure、0 resource error。 | 证明 per-row CPU/fault/context-switch raw fields 可在 KVM 内采集。 |
| rusage full tail10 `20260615T-kvm-bench-rusage-tail10-v1` / `20260615T-eval-rusage-tail10-v1` | `results/phase1/20260615T-kvm-bench-rusage-tail10-v1/` and `results/eval-osdi/paper/20260615T-eval-rusage-tail10-v1/b2-performance/` | 700 bench rows、7000 latency rows、20 samples、0 failure；非 exec p99 rows 基本无 fault/context-switch，pass-only 与 policy self CPU/op 同步上升。 | 说明 blocker 更像 common hook/dispatch CPU，而不是 scheduler/fault noise。 |
| variant selector smokes `20260615T-kvm-bench-variant-selector-full-smoke-v1` / `20260615T-kvm-bench-nohook-baseline-smoke-v1` | `results/phase1/20260615T-kvm-bench-variant-selector-full-smoke-v1/` and `results/phase1/20260615T-kvm-bench-nohook-baseline-smoke-v1/` | full/default 仍为 35 bench rows、35 latency rows、4 attach rows；baseline-only 为 7 bench rows、7 latency rows、0 attach rows；均 0 failure。 | 证明 `BENCH_VARIANTS` 可提供 Make-owned no-hook/static-key-off diagnostic path。 |
| no-hook baseline-only tail10 `20260615T-kvm-bench-nohook-baseline-tail10-v1` / `20260615T-eval-nohook-baseline-tail10-v1` | `results/phase1/20260615T-kvm-bench-nohook-baseline-tail10-v1/` and `results/eval-osdi/paper/20260615T-eval-nohook-baseline-tail10-v1/b2-performance/` | 140 bench rows、1400 latency rows、0 attach rows、0 failure；max pass-only/nohook p99 ratio 1.306x，max policy/nohook 1.244x。 | no-hook denominator variance 明显；但 pass-only 仍超过 1.1x C5 threshold。 |
| matched baseline/pass-only tail10 `20260615T-kvm-bench-baseline-passonly-tail10-v1` / `20260615T-eval-baseline-passonly-tail10-v1` | `results/phase1/20260615T-kvm-bench-baseline-passonly-tail10-v1/` and `results/eval-osdi/paper/20260615T-eval-baseline-passonly-tail10-v1/b2-performance/` | 280 bench rows、2800 latency rows、1 attach row、0 failure；max pass-only/native p99 ratio 1.323x。 | 最小 matched attach path 仍未过 1.1x C5 threshold；C5 继续 unsupported。 |
| W3 Redis table-only counterfactual `20260615T-w3-redis-counterfactual-smoke-v1` | `results/phase1/20260615T-w3-redis-counterfactual-smoke-v1/` | checkpoint policy replay pass、table_redirect replay pass、`table_rule_writes=2`、`table_baseline_current_oracle_pass=true`、`qualified_for_c8=false`。 | W3 table-only same-workload comparator 已补齐，但结果是 C8 负证据：当前 Redis checkpoint replay 不能支撑 checkpoint/restore 的 balanced dynamic path-view claim。 |
| W3 Podman/CRIU capability audit `20260615T-w3-podman-criu-capability-audit-v1` | `results/workloads/runs/20260615T-w3-podman-criu-capability-audit-v1/w3-podman-criu-capability/` | `podman_present=true`、`podman_version_ok=true`、`podman_checkpoint_help_ok=true`，但 `podman_checkpoint_listed=false`、`criu_present=false`、`pass=false`。 | 证明当前 host 不能运行真实 Podman/CRIU restore；这是 W3 C8 blocker evidence，不是支持证据。 |
| W3 checkpoint epoch C8 counterfactual `20260629T-w3-checkpoint-epoch-c8-release-v1` | `results/phase1/20260629T-w3-checkpoint-epoch-c8-release-v1/` | `make kvm-w3-checkpoint-epoch-counterfactual W3_CHECKPOINT_EPOCH_COUNTERFACTUAL_SAMPLES=20 W3_CHECKPOINT_EPOCH_COUNTERFACTUAL_OBJECTS=16` 通过；summary 记录 `samples=20`、`objects=16`、`static_wrong_epoch_hits=320`、`policy_update_writes=20`、`table_update_writes=320`、`table_update_write_ratio=16`、`max_table_update_write_ratio=10`、`table_static_current_oracle_pass=false`、`table_updated_current_oracle_pass=true`、`table_update_budget_failure=true`、`targeted_c8_budget_failure=true`、`real_podman_criu_restore=false`、`qualified_for_c8=false`、`release_gate_pass=false`；input hash 复验通过，dmesg issue scan 为 0。 | 证明 targeted W3 epoch fixture 中 static exact table 失败、externally-updated exact table correctness 通过但 update writes 超预算；由于不是真实 Podman/CRIU restore，只能作为 C8 机制证据，不能作为完整 W3 release 支持证据。 |
| W3 checkpoint epoch C8 materialized follow-up `20260629T-w3-checkpoint-epoch-c8-materialized-v1` | `results/phase1/20260629T-w3-checkpoint-epoch-c8-materialized-v1/` | `make kvm-w3-checkpoint-epoch-counterfactual W3_CHECKPOINT_EPOCH_COUNTERFACTUAL_SAMPLES=20 W3_CHECKPOINT_EPOCH_COUNTERFACTUAL_OBJECTS=16` 通过；summary 记录 `samples=20`、`objects=16`、`setup_rows=80`、`correctness_rows=160`、`update_rows=60`、`static_wrong_epoch_hits=320`、`policy_update_writes=20`、`table_update_writes=320`、`materialized_update_writes=320`、`table_update_write_ratio=16`、`materialized_update_write_ratio=16`、`table_update_budget_failure=true`、`materialized_current_oracle_pass=true`、`materialized_feature_equivalent_baseline=true`、`materialized_update_budget_failure=true`、`targeted_c8_budget_failure=true`、`real_podman_criu_restore=false`、`qualified_for_c8=false`、`release_gate_pass=false`；304 JSONL rows，input hash 复验通过，dmesg issue scan 为 0。 | 补齐 targeted W3 checkpoint epoch 的 materialized view baseline；同一 oracle 下 exact table 和 materialized view 都 correctness 通过但 update writes 超预算。仍是 synthetic mechanism evidence，不是完整 W3 C8 release 支持证据。 |
| W3 checkpoint epoch C8 FUSE follow-up `20260629T-w3-checkpoint-epoch-c8-fuse-v2` | `results/phase1/20260629T-w3-checkpoint-epoch-c8-fuse-v2/` | `make kvm-w3-checkpoint-epoch-counterfactual W3_CHECKPOINT_EPOCH_COUNTERFACTUAL_SAMPLES=20 W3_CHECKPOINT_EPOCH_COUNTERFACTUAL_OBJECTS=16` 通过；summary 记录 `samples=20`、`objects=16`、`setup_rows=100`、`correctness_rows=200`、`update_rows=80`、`static_wrong_epoch_hits=320`、`policy_update_writes=20`、`table_update_writes=320`、`materialized_update_writes=320`、`fuse_update_writes=320`、`fuse_mounts=20`、`table_update_write_ratio=16`、`materialized_update_write_ratio=16`、`fuse_update_write_ratio=16`、`table_update_budget_failure=true`、`materialized_current_oracle_pass=true`、`materialized_feature_equivalent_baseline=true`、`materialized_update_budget_failure=true`、`fuse_current_oracle_pass=true`、`fuse_feature_equivalent_baseline=true`、`fuse_update_budget_failure=true`、`targeted_c8_budget_failure=true`、`real_podman_criu_restore=false`、`qualified_for_c8=false`、`release_gate_pass=false`；384 JSONL rows，input hash 复验通过，dmesg issue scan 为 0。 | 补齐 targeted W3 checkpoint epoch 的 FUSE baseline；同一 oracle 下 exact table、materialized view 和 FUSE view 都 correctness 通过但 update writes 超预算。仍是 synthetic mechanism evidence，不是完整 W3 C8 release 支持证据。 |
| W4 cache-content table-only counterfactual `20260615T-w4-cache-table-content-smoke-v1` | `results/phase1/20260615T-w4-cache-table-content-smoke-v1/` | table_redirect content oracle pass、4 个 expected match、3 个 forbidden mismatch、4 个 readdir alias、`table_baseline_current_oracle_pass=true`、`content_equivalent_table_oracle=true`、`qualified_for_c8=false`。 | W4 table-only same-workload content comparator 已补齐，但结果是 C8 负证据：当前 stale/corrupt/miss cache-content oracle 仍能被 exact table 解释。 |
| W4 cache epoch C8 counterfactual `20260629T-w4-cache-epoch-c8-release-v1` | `results/phase1/20260629T-w4-cache-epoch-c8-release-v1/` | `make kvm-w4-cache-epoch-counterfactual W4_CACHE_EPOCH_SAMPLES=20 W4_CACHE_EPOCH_OBJECTS=16` 通过；summary 记录 `samples=20`、`objects=16`、`static_wrong_local_hits=320`、`policy_update_writes=20`、`table_update_writes=320`、`table_update_write_ratio=16`、`max_table_update_write_ratio=10`、`table_static_current_oracle_pass=false`、`table_updated_current_oracle_pass=true`、`table_update_budget_failure=true`、`targeted_c8_budget_failure=true`、`real_ccache_trace=false`、`qualified_for_c8=false`、`release_gate_pass=false`；input hash 复验通过，dmesg issue scan 为 0。 | 证明 targeted W4 cache epoch fixture 中 static exact table 失败、externally-updated exact table correctness 通过但 update writes 超预算；由于不是真实 ccache/BuildKit trace，只能作为 C8 机制证据，不能作为完整 W4 release 支持证据。 |
| W4 cache epoch C8 materialized follow-up `20260629T-w4-cache-epoch-c8-materialized-v3` | `results/phase1/20260629T-w4-cache-epoch-c8-materialized-v3/` | `make kvm-w4-cache-epoch-counterfactual W4_CACHE_EPOCH_SAMPLES=20 W4_CACHE_EPOCH_OBJECTS=16` 通过；summary 记录 `samples=20`、`objects=16`、`setup_rows=80`、`correctness_rows=160`、`update_rows=60`、`static_wrong_local_hits=320`、`policy_update_writes=20`、`table_update_writes=320`、`materialized_update_writes=320`、`table_update_write_ratio=16`、`materialized_update_write_ratio=16`、`table_update_budget_failure=true`、`materialized_current_oracle_pass=true`、`materialized_feature_equivalent_baseline=true`、`materialized_update_budget_failure=true`、`targeted_c8_budget_failure=true`、`real_ccache_trace=false`、`qualified_for_c8=false`、`release_gate_pass=false`；304 JSONL rows，input hash 复验通过，dmesg issue scan 为 0。 | 补齐 targeted W4 cache epoch 的 materialized view baseline；同一 oracle 下 exact table 和 materialized view 都 correctness 通过但 update writes 超预算。仍是 synthetic mechanism evidence，不是完整 W4 C8 release 支持证据。 |
| W4 cache epoch C8 FUSE follow-up `20260629T-w4-cache-epoch-c8-fuse-v1` | `results/phase1/20260629T-w4-cache-epoch-c8-fuse-v1/` | `make kvm-w4-cache-epoch-counterfactual W4_CACHE_EPOCH_SAMPLES=20 W4_CACHE_EPOCH_OBJECTS=16` 通过；summary 记录 `samples=20`、`objects=16`、`setup_rows=100`、`correctness_rows=200`、`update_rows=80`、`static_wrong_local_hits=320`、`policy_update_writes=20`、`table_update_writes=320`、`materialized_update_writes=320`、`fuse_update_writes=320`、`fuse_mounts=20`、`table_update_write_ratio=16`、`materialized_update_write_ratio=16`、`fuse_update_write_ratio=16`、`table_update_budget_failure=true`、`materialized_current_oracle_pass=true`、`materialized_feature_equivalent_baseline=true`、`materialized_update_budget_failure=true`、`fuse_current_oracle_pass=true`、`fuse_feature_equivalent_baseline=true`、`fuse_update_budget_failure=true`、`targeted_c8_budget_failure=true`、`real_ccache_trace=false`、`qualified_for_c8=false`、`release_gate_pass=false`；384 JSONL rows，input hash 复验通过，dmesg issue scan 为 0。 | 补齐 targeted W4 cache epoch 的 FUSE baseline；同一 oracle 下 exact table、materialized view 和 FUSE view 都 correctness 通过但 update writes 超预算。仍是 synthetic mechanism evidence，不是完整 W4 C8 release 支持证据。 |
| refreshed full Phase 1 `20260615T-full-phase1-b12-refresh-v1` | `results/phase1/20260615T-full-phase1-b12-refresh-v1/` | 完整 `make phase1` 退出 0；该 root 同时包含 `w3-redis-counterfactual.jsonl`、`w4-cache-table-content.jsonl`、W4 ccache release counterfactual、Docker smoke、KVM dmesg 和 metadata。 | 解决旧 canonical root stale 问题；支持 Phase 1 evidence freshness，但不支持 C8。 |
| B12 refreshed ledger `20260615T-eval-b12-refresh-v1` | `results/eval-osdi/paper/20260615T-eval-b12-refresh-v1/b12-policy-family/` | summary 为 `qualified_families=0`、`release_gate_pass=false`、`c1_supported=false`、`c8_supported=false`；W4 row 为 `content_table_counterfactual_negative=true`。 | 明确 refreshed evidence 仍不能支撑 C1/C8。 |
| B12 refreshed hard gate `20260615T-eval-b12-refresh-hardgate-v1` | `results/eval-osdi/paper/20260615T-eval-b12-refresh-hardgate-v1/b12-policy-family/` | `make eval-osdi-policy-family` 写出 ledger artifacts 后按预期退出 2，因为 final `jq -e` 找不到 release-pass summary。 | 防止 refreshed Phase 1 evidence 被误写成 supported programmable-abstraction claim。 |
| C2 setup/update 完整 Phase 1 `20260615T-full-phase1-c2-setup-update-v1` | `results/phase1/20260615T-full-phase1-c2-setup-update-v1/` | 完整 `make phase1` 退出 0；`bench.jsonl` 新增 1 条 `namei_ext-setup` row（67 dirs、66 files、132 bytes written）和 2 条 `namei_ext-update` rows（source update 65 writes / 845 bytes written；table update 66 writes）。 | 支持 C2 raw-input plumbing；仍不支持 setup/storage/update release comparison。 |
| 基于 C2 setup/update root 的 B12 ledger `20260615T-eval-b12-c2-setup-update-v1` | `results/eval-osdi/paper/20260615T-eval-b12-c2-setup-update-v1/b12-policy-family/` | summary 仍为 `qualified_families=0`、`release_gate_pass=false`、`c1_supported=false`、`c8_supported=false`；W4 row 保持 `content_table_counterfactual_negative=true`。 | 新 canonical root 没有改变 C1/C8 verdict。 |
| 基于 C2 setup/update root 的 B12 hard gate `20260615T-eval-b12-c2-setup-update-hardgate-v1` | `results/eval-osdi/paper/20260615T-eval-b12-c2-setup-update-hardgate-v1/b12-policy-family/` | `make eval-osdi-policy-family` 写出 ledger artifacts 后按预期退出 2，因为 final `jq -e` 找不到 release-pass summary。 | 防止 C2 raw-row refresh 被误写成 C1/C8 support。 |
| C2 macrobench ledger `20260615T-eval-c2-macrobench-ledger-v1` | `results/eval-osdi/paper/20260615T-eval-c2-macrobench-ledger-v1/b3-macrobench/` | summary 为 `namei_ext_raw_gate_pass=true`、`baseline_release_gate_pass=true`、`baseline_unique_sample_budget_pass=true`，但 `namei_ext_release_sample_budget_pass=false`、`macrobench_input_gate_pass=false`、`c2_supported=false`；5 个 external baselines 都有 release rows。 | C2 从“缺 ledger”变为“有 fail-fast negative contract”；仍不支持 setup/storage/update advantage。 |
| C2 macrobench hard gate `20260615T-eval-c2-macrobench-hardgate-v1` | `results/eval-osdi/paper/20260615T-eval-c2-macrobench-hardgate-v1/b3-macrobench/` | `make eval-osdi-macrobench` 写出 macrobench artifacts 后按预期退出 2，因为 summary 没有 `release_gate_pass=true` 和 `c2_supported=true`。 | 防止 raw setup/update rows 或 baseline rows 被误写成 C2 supported claim。 |
| C2 release-sample 完整 Phase 1 `20260615T-full-phase1-c2-release-sample-v1` | `results/phase1/20260615T-full-phase1-c2-release-sample-v1/` | 完整 `make phase1` 退出 0；`bench.jsonl` 中 `namei_ext-setup`、`namei_ext-update variant=backing_tree` 和 `namei_ext-update variant=table_redirect_hit` 各有 20 rows、20 unique samples，`bench_map_update` 有 20 rows，bench failure 为 0。 | 解决 `namei_ext` 侧 release repetition input；仍不支持 C2 setup/storage/update advantage。 |
| C2 release-sample macrobench ledger `20260615T-eval-c2-release-sample-ledger-v1` | `results/eval-osdi/paper/20260615T-eval-c2-release-sample-ledger-v1/b3-macrobench/` | summary 为 `namei_ext_raw_gate_pass=true`、`namei_ext_release_sample_budget_pass=true`、`baseline_release_gate_pass=true`、`baseline_unique_sample_budget_pass=true`、`macrobench_input_gate_pass=true`，但 `c2_supported=false`、`release_gate_pass=false`、`verdict=blocked_by_missing_thresholds`。 | C2 input gate 已补齐；后续 W1/W2/W3/W4 workload-equivalent ledgers 进一步显示只有 W2 slice 过阈值，W1/W3/W4 为负结果。 |
| C2 release-sample macrobench hard gate `20260615T-eval-c2-release-sample-hardgate-v1` | `results/eval-osdi/paper/20260615T-eval-c2-release-sample-hardgate-v1/b3-macrobench/` | `make eval-osdi-macrobench` 写出 macrobench artifacts 后按预期失败，因为 summary 仍没有 `release_gate_pass=true` 和 `c2_supported=true`。 | 防止 release sample budget 被误写成 C2 supported claim。 |
| C2 workload derived ledger `20260615T-eval-c2-workload-derived-ledger-v1` | `results/eval-osdi/paper/20260615T-eval-c2-workload-derived-ledger-v1/b3-macrobench/` | summary 为 `workload_rows=8`、`correctness_oracle_passed=5`、`policy_kvm_rows=5`、`c2_eligible_rows=0`、`c2_supported=false`、`release_gate_pass=false`、`verdict=derived_contract_only`。 | W1--W4 workload inventory 已机械化，但只是 derived contract；C2 仍缺 KVM per-sample workload setup/update macrobench、feature-equivalent baseline 和阈值。 |
| C2 workload macrobench hard gate `20260615T-eval-c2-workload-derived-hardgate-v1` | `results/eval-osdi/paper/20260615T-eval-c2-workload-derived-hardgate-v1/b3-macrobench/` | `make eval-osdi-workload-macrobench` 写出 workload macrobench artifacts 后按预期失败，因为 summary 仍没有 `release_gate_pass=true` 和 `c2_supported=true`。 | 防止 derived inventory 被误写成 C2 supported claim。 |
| W2 nginx KVM setup/update macrobench PoC `20260615T-w2-nginx-c2-macrobench-smoke-v1` | `results/phase1/20260615T-w2-nginx-c2-macrobench-smoke-v1/` | `make kvm-w2-nginx-macrobench W2_NGINX_MACROBENCH_SAMPLES=2` 通过；`w2-nginx-macrobench.jsonl` 有 2 setup rows、2 update rows、2 correctness rows 和 1 summary；summary 为 `pass=true`、`failures=0`、`policy_executed=true`、`kvm_validated=true`、`c2_supported=false`、`release_gate_pass=false`。setup 每样本创建 5 dirs/12 files，update 每样本 3 source writes。 | 证明 W2 真实 workload per-sample KVM setup/update plumbing；不是 release C2 evidence。 |
| W2 nginx KVM setup/update release-sample run `20260615T-w2-nginx-c2-macrobench-release-sample-v1` | `results/phase1/20260615T-w2-nginx-c2-macrobench-release-sample-v1/` | `make kvm-w2-nginx-macrobench W2_NGINX_MACROBENCH_SAMPLES=20` 通过；`w2-nginx-macrobench.jsonl` 有 20 setup rows、20 update rows、20 correctness rows 和 1 summary；summary 为 `pass=true`、`failures=0`、`policy_executed=true`、`kvm_validated=true`、`c2_supported=false`、`release_gate_pass=false`。setup_ns 约 6.94--9.31 ms；update_ns 约 10.8--32.4 us；每 setup sample 5 dirs/12 files，每 update sample 3 source writes。 | 证明 W2 真实 workload release repetition raw input；与后续 copy/symlink/bind/projected/FUSE baseline 和 v5 threshold ledger 合并后，W2 slice 已满足当前 C2 input/threshold；全局 C2 仍受 W1、W3 和 W4 负结果阻塞。 |
| W2 nginx copy/symlink/bind/projected/FUSE baseline release-sample run `20260616T-w2-nginx-baseline-macrobench-release-sample-v4` | `results/phase1/20260616T-w2-nginx-baseline-macrobench-release-sample-v4/` | `make kvm-w2-nginx-baseline-macrobench W2_NGINX_BASELINE_MACROBENCH_SAMPLES=20` 通过；`w2-nginx-baseline-macrobench.jsonl` 覆盖 `copy_tree`、`symlink_forest`、`bind_mount`、`projected_volume` 和 `fuse_redirect`，每个 baseline 有 20 setup rows、20 update rows、20 correctness rows；summary 为 `baseline_count=5`、`samples=20`、`setup_rows=100`、`update_rows=100`、`correctness_rows=100`、`pass=true`、`failures=0`、`policy_executed=false`、`kvm_validated=true`、`feature_equivalent_baseline=true`、`c2_supported=false`、`release_gate_pass=false`。 | 证明 W2 同 workload copy/symlink/bind/projected/FUSE feature baseline 可在 KVM 中跑通。 |
| W2 nginx workload macrobench ledger `20260616T-eval-w2-nginx-workload-macrobench-ledger-v5` | `results/eval-osdi/paper/20260616T-eval-w2-nginx-workload-macrobench-ledger-v5/b3-macrobench/` | `make eval-osdi-w2-nginx-workload-macrobench-ledger` 通过；summary 为 `policy_release_input_pass=true`、`baseline_release_input_pass=true`、`all_feature_baselines_pass=true`、`full_feature_equivalent_baseline_pass=true`、`storage_footprint_pass=true`、`setup_latency_threshold_pass=true`、`update_latency_threshold_pass=true`、`update_materialization_threshold_pass=true`、`threshold_pass=true`、`w2_c2_slice_supported=true`，但 `c2_supported=false`、`release_gate_pass=false`；该 ledger 当时的 `missing_evidence` 字段为 W1/W3/W4 workload setup/storage/update macrobench。 | 把 W2 proposed-system rows、五类 feature baseline rows、storage footprint 和阈值合并为 thresholded W2 slice ledger；后续 W1 已补齐五类 baseline 但为负结果，全局 C2 仍 unsupported。 |
| W2 nginx workload macrobench hard gate `20260616T-eval-w2-nginx-workload-macrobench-hardgate-v5` | `results/eval-osdi/paper/20260616T-eval-w2-nginx-workload-macrobench-hardgate-v5/b3-macrobench/` | `make eval-osdi-w2-nginx-workload-macrobench` 写出 ledger artifacts 后按预期非零退出，因为 summary 仍没有 `release_gate_pass=true` 和 `c2_supported=true`。 | 防止 W2 slice success 被误写成全局 C2 supported claim。 |
| W1 build graph KVM setup/update macrobench PoC `20260616T-w1-build-macrobench-smoke-v3` | `results/phase1/20260616T-w1-build-macrobench-smoke-v3/` | `make kvm-w1-build-macrobench W1_BUILD_MACROBENCH_SAMPLES=1` 通过；`w1-build-macrobench.jsonl` 有 1 条 setup row、1 条 update row、1 条 correctness row 和 1 条 summary；summary 为 `pass=true`、`failures=0`、`policy_executed=true`、`kvm_validated=true`、`c2_supported=false`、`release_gate_pass=false`。setup row 记录 `setup_ns=57973895`、`entries=9`、`created_files=10`、`created_symlinks=2`；update row 记录 `update_ns=66338828`、`update_bytes_copied=412795`。 | 证明 W1 proposed-system macrobench plumbing；release repetition 已由后续 `release-sample-v1` 补齐，但该 PoC 本身不是 C2 comparison。 |
| W1 build graph KVM setup/update release-sample run `20260616T-w1-build-macrobench-release-sample-v1` | `results/phase1/20260616T-w1-build-macrobench-release-sample-v1/` | `make kvm-w1-build-macrobench W1_BUILD_MACROBENCH_SAMPLES=20` 通过；`w1-build-macrobench.jsonl` 有 20 条 setup rows、20 条 update rows、20 条 correctness rows 和 1 条 summary；summary 为 `samples=20`、`pass=true`、`failures=0`、`policy_executed=true`、`kvm_validated=true`、`c2_supported=false`、`release_gate_pass=false`。setup_ns min/avg/max 为 55.34/66.09/86.33 ms，update_ns min/avg/max 为 42.59/52.42/72.92 ms；host input hash 复验通过。 | 证明 W1 proposed-system release repetition raw input；后续 v2 baseline/ledger 已补齐五类 feature baselines，但 W1 C2 slice 仍为负。 |
| W1 build graph copy/symlink/bind baseline release-sample run `20260616T-w1-build-baseline-release-sample-v1` | `results/phase1/20260616T-w1-build-baseline-release-sample-v1/` | `make kvm-w1-build-baseline-macrobench W1_BUILD_BASELINE_MACROBENCH_SAMPLES=20 W1_BUILD_BASELINES='copy_tree symlink_forest bind_mount'` 通过；`w1-build-baseline-macrobench.jsonl` 覆盖 3 个 baseline，每个 baseline 有 20 条 setup/update/correctness rows；summary 为 `baseline_count=3`、`samples=20`、`setup_rows=60`、`update_rows=60`、`correctness_rows=60`、`pass=true`、`failures=0`、`feature_equivalent_baseline=true`、`c2_supported=false`、`release_gate_pass=false`。`copy_tree` setup 平均约 18.33 ms，`bind_mount` update 平均约 40.17 ms；input hashes verified。 | 历史三 baseline release input；后续 v2 已由完整五 baseline run 取代。 |
| W1 build graph workload macrobench ledger `20260616T-eval-w1-build-workload-macrobench-ledger-release-v1` | `results/eval-osdi/paper/20260616T-eval-w1-build-workload-macrobench-ledger-release-v1/b3-macrobench/` | `make eval-osdi-w1-build-workload-macrobench-ledger` 通过；summary `policy_release_input_pass=true`、`baseline_release_input_pass=true`、`copy_tree_baseline_pass=true`、`symlink_forest_baseline_pass=true`、`bind_mount_baseline_pass=true`，但 `projected_volume_baseline_pass=false`、`fuse_baseline_pass=false`、`storage_footprint_pass=false`、`threshold_pass=false`、`w1_c2_slice_supported=false`、`c2_supported=false`、`release_gate_pass=false`。`missing_inputs` 只列 W1 projected-volume、W1 FUSE 和 W3/W4 macrobench；`failed_gates` 列 storage/setup/update/materialization gate failure。`best_baseline_setup_ns_avg=18326753.1` 小于 `policy_setup_ns_avg=66090011.6`，`best_baseline_update_ns_avg=40165924.95` 小于 `policy_update_ns_avg=52416038.25`。 | 历史 v1 ledger 暴露 W1 projected/FUSE 缺口；后续 v2 已关闭该输入缺口，但 W1 仍是负结果。 |
| W1 build graph workload macrobench hard gate `20260616T-eval-w1-build-workload-macrobench-hardgate-release-v1` | `results/eval-osdi/paper/20260616T-eval-w1-build-workload-macrobench-hardgate-release-v1/b3-macrobench/` | target 写出 ledger artifacts 后按预期非零退出；`w1-build-workload-macrobench-hardgate-status.json` 记录 hard-gate predicate `status=4`、`pass=false`，外层 Make wrapper 观察到 `hardgate_status=2`。 | 历史 v1 hard gate；后续 v2 hard gate 保持 expected-fail。 |
| W1 build graph copy/symlink/bind/projected/FUSE baseline release-sample run `20260616T-w1-build-baseline-release-sample-v2` | `results/phase1/20260616T-w1-build-baseline-release-sample-v2/` | `make kvm-w1-build-baseline-macrobench W1_BUILD_BASELINE_MACROBENCH_SAMPLES=20` 通过；`w1-build-baseline-macrobench.jsonl` 覆盖 `copy_tree`、`symlink_forest`、`bind_mount`、`projected_volume` 和 `fuse_redirect`，每个 baseline 有 20 条 setup/update/correctness rows；summary 为 `baseline_count=5`、`samples=20`、`setup_rows=100`、`update_rows=100`、`correctness_rows=100`、`pass=true`、`failures=0`、`feature_equivalent_baseline=true`、`c2_supported=false`、`release_gate_pass=false`；FUSE setup rows 记录 `fuse_mounts=4`，dmesg issue scan 为 0。 | 证明 W1 五类同 workload feature baseline release input 可运行；不是 C2 支持证据。 |
| W1 build graph workload macrobench ledger `20260616T-eval-w1-build-workload-macrobench-ledger-release-v2` | `results/eval-osdi/paper/20260616T-eval-w1-build-workload-macrobench-ledger-release-v2/b3-macrobench/` | `make eval-osdi-w1-build-workload-macrobench-ledger` 通过；summary `policy_release_input_pass=true`、`baseline_release_input_pass=true`、五类 baseline pass 均为 true、`full_feature_equivalent_baseline_pass=true`、`baseline_count_observed=5`，但 `storage_footprint_pass=false`、`setup_latency_threshold_pass=false`、`update_latency_threshold_pass=false`、`update_materialization_threshold_pass=false`、`w1_c2_slice_supported=false`、`c2_supported=false`、`release_gate_pass=false`。`best_baseline_setup_ns_avg=17324797.3` 小于 `policy_setup_ns_avg=66090011.6`，`best_baseline_update_ns_avg=37528990.95` 小于 `policy_update_ns_avg=52416038.25`。 | W1 projected/FUSE 输入缺口关闭；完整 feature-baseline comparison 仍是明确负结果，不能 claim W1 setup/storage/update improvement。 |
| W1 build graph workload macrobench hard gate `20260616T-eval-w1-build-workload-macrobench-hardgate-release-v2` | `results/eval-osdi/paper/20260616T-eval-w1-build-workload-macrobench-hardgate-release-v2/b3-macrobench/` | target 写出 ledger artifacts 后按预期非零退出；`w1-build-workload-macrobench-hardgate-status.json` 记录 hard-gate predicate `status=4`、`pass=false`。 | 防止完整五 baseline W1 release input 被误写成 C2 supported claim。 |
| W3 Redis checkpoint policy setup/update release run `20260616T-w3-redis-macrobench-release-v1` | `results/phase1/20260616T-w3-redis-macrobench-release-v1/` | `make kvm-w3-redis-policy-macrobench W3_REDIS_POLICY_MACROBENCH_SAMPLES=20` 通过；`w3-redis-policy-macrobench.jsonl` 有 20 setup rows、20 update rows、20 correctness rows 和 1 summary；summary 为 `samples=20`、`setup_rows=20`、`update_rows=20`、`correctness_rows=20`、`pass=true`、`failures=0`、`policy_executed=true`、`kvm_validated=true`、`c2_supported=false`、`release_gate_pass=false`。ledger-derived policy setup/update 平均为 22.96 ms/5.16 s。 | 补齐 W3 Redis checkpoint replay proposed-system release setup/update raw input；不是 C2 支持证据。 |
| W3 Redis materialized/FUSE baseline release run `20260616T-w3-redis-macrobench-release-v1` | `results/phase1/20260616T-w3-redis-macrobench-release-v1/` | `make kvm-w3-redis-baseline-macrobench W3_REDIS_BASELINE_MACROBENCH_SAMPLES=20` 通过；`w3-redis-baseline-macrobench.jsonl` 覆盖 `materialized_checkpoint_view` 和 `fuse_redirect`，每个 baseline 有 20 setup rows、20 update rows 和 20 correctness rows；summary 为 `baseline_count=2`、`setup_rows=40`、`update_rows=40`、`correctness_rows=40`、`pass=true`、`failures=0`、`feature_equivalent_baseline=true`。FUSE setup rows 记录 `fuse_mounts=1`，dmesg issue scan 为 0。 | 补齐 W3 同 workload materialized checkpoint-view 和 FUSE checkpoint-view external baselines。 |
| W3 Redis workload macrobench ledger `20260616T-eval-w3-redis-workload-macrobench-ledger-v1` | `results/eval-osdi/paper/20260616T-eval-w3-redis-workload-macrobench-ledger-v1/b3-macrobench/` | `make eval-osdi-w3-redis-workload-macrobench-ledger` 通过；summary `policy_release_input_pass=true`、`baseline_release_input_pass=true`、`materialized_baseline_pass=true`、`fuse_baseline_pass=true`、`full_feature_equivalent_baseline_pass=true`、`storage_footprint_pass=true`，但 `setup_latency_threshold_pass=false`、`update_latency_threshold_pass=false`、`threshold_pass=false`、`w3_c2_slice_supported=false`、`c2_supported=false`、`release_gate_pass=false`。`best_baseline_setup_ns_avg=6522913.55` 小于 `policy_setup_ns_avg=22961752`，`best_baseline_update_ns_avg=5154457275.05` 小于 `policy_update_ns_avg=5157854343.45`。 | W3 FUSE/materialized input 缺口关闭；thresholded comparison 是明确负结果，不能 claim W3 checkpoint setup/update improvement。 |
| W4 ccache rule macrobench release run `20260616T-w4-ccache-rule-macrobench-release-v1` | `results/phase1/20260616T-w4-ccache-rule-macrobench-release-v1/` | `make kvm-w4-ccache-rule-macrobench W4_CCACHE_RULE_MACROBENCH_SAMPLES=20` 通过；`w4-ccache-rule-macrobench.jsonl` 有 40 setup rows、40 update rows、40 correctness rows 和 1 条 summary；summary 为 `samples=20`、`systems=2`、`pass=true`、`failures=0`、`policy_executed=true`、`kvm_validated=true`、`c2_supported=false`、`release_gate_pass=false`。parent-rule policy setup/update 平均为 110.55 ms/6.52 ms，table baseline 为 104.06 ms/6.31 ms；两者 setup/update rule writes 均为 8/2。 | 证明 W4 ccache rule setup/update release input 可在修改内核 KVM 中跑通；当前数字是负结果，不支持 W4 C2。 |
| W4 ccache materialized external baseline release run `20260616T-w4-ccache-materialized-baseline-release-v1` | `results/phase1/20260616T-w4-ccache-materialized-baseline-release-v1/` | `make kvm-w4-ccache-materialized-baseline-macrobench W4_CCACHE_MATERIALIZED_BASELINE_SAMPLES=20` 通过；`w4-ccache-materialized-baseline.jsonl` 有 20 setup rows、20 update rows、20 correctness rows 和 1 条 summary；summary 为 `samples=20`、`systems=1`、`pass=true`、`failures=0`、`policy_executed=false`、`feature_equivalent_baseline=true`、`kvm_validated=true`。materialized setup/update 平均为 57.95 ms/3.82 ms。 | 新增 W4 外部 feature-equivalent baseline；这是更强 baseline，不是 `table_redirect` 内部 ablation。 |
| W4 ccache workload macrobench ledger `20260616T-eval-w4-ccache-workload-macrobench-ledger-v2` | `results/eval-osdi/paper/20260616T-eval-w4-ccache-workload-macrobench-ledger-v2/b3-macrobench/` | `make eval-osdi-w4-ccache-workload-macrobench-ledger` 通过；summary `policy_release_input_pass=true`、`table_release_input_pass=true`、`materialized_baseline_pass=true`、`full_feature_equivalent_baseline_pass=true`，但 `storage_footprint_pass=false`、`setup_latency_threshold_pass=false`、`update_latency_threshold_pass=false`、`rule_materialization_threshold_pass=false`、`w4_c2_slice_supported=false`、`c2_supported=false`、`release_gate_pass=false`。parent-rule setup/update 平均 110.55 ms/6.52 ms，materialized baseline 57.95 ms/3.82 ms。 | W4 release comparison 在更强外部 baseline 下仍是明确负结果；不能 claim cache-locality setup/update improvement。 |
| W4 ccache workload macrobench hard gate `20260616T-eval-w4-ccache-workload-macrobench-hardgate-v2` | `results/eval-osdi/paper/20260616T-eval-w4-ccache-workload-macrobench-hardgate-v2/b3-macrobench/` | target 写出 ledger artifacts 后按预期非零退出；`w4-ccache-workload-macrobench-hardgate-status.json` 记录 hard-gate predicate `status=4`、`pass=false`，外层 Make 返回非零。 | 防止 W4 release input 和 materialized baseline 被误写成 C2 supported claim。 |
| W4 ccache workload macrobench ledger `20260616T-eval-w4-ccache-workload-macrobench-ledger-v5` | `results/eval-osdi/paper/20260616T-eval-w4-ccache-workload-macrobench-ledger-v5/b3-macrobench/` | `make eval-osdi-w4-ccache-workload-macrobench-ledger` 通过并把非 bulk parent-rule/table/materialized rows、bulk policy compile smoke、bulk materialized baseline 和 bulk FUSE cache-view baseline 合并。summary 记录 `bulk_policy_compile_smoke_pass=true`、`bulk_policy_release_input_pass=false`、`bulk_materialized_baseline_pass=true`、`bulk_fuse_baseline_pass=true`、`bulk_external_baseline_release_input_pass=true`、`bulk_release_comparison_pass=false`、`w4_c2_slice_supported=false`、`c2_supported=false`、`release_gate_pass=false`。bulk policy smoke 有 20 个 attached compile jobs、40 个 redirected cache objects、400 条 cache-path file ops；bulk materialized setup/update 平均为 484.83 ms/3.12 ms；bulk FUSE setup/update 平均为 794.16 ms/2.28 ms，`fuse_mounts_avg=1`。 | 历史 v5 ledger：W4 bulk FUSE baseline 和测试已进入 claim ledger，但当时 bulk proposed-system 仍无 release setup/update repetition；后续 v6 已补该 input，但 comparison 仍为负。 |
| W4 bulk policy setup/update release run `20260616T-w4-ccache-bulk-policy-macrobench-release-v1` | `results/phase1/20260616T-w4-ccache-bulk-policy-macrobench-release-v1/` | `make kvm-w4-ccache-bulk-policy-macrobench W4_CCACHE_BULK_POLICY_MACROBENCH_SAMPLES=20` 通过；`w4-ccache-bulk-policy-macrobench.jsonl` 有 20 setup rows、20 update rows、20 correctness rows 和 1 summary；summary 记录 `result_level=kvm_workload_bulk_policy_setup_update_input`、`policy_executed=true`、`kvm_validated=true`、`pass=true`、`failures=0`、`source_manifest_count=20`、`cache_objects=40`。ledger 计算 bulk policy setup/update 平均为 336.19 ms/4.99 ms。 | 补齐 W4 bulk proposed-system release setup/update raw input；compile output oracle 仍由 separate compile smoke witness 覆盖，不能单独支持 C2/C8。 |
| W4 ccache workload macrobench ledger `20260616T-eval-w4-ccache-workload-macrobench-ledger-v6` | `results/eval-osdi/paper/20260616T-eval-w4-ccache-workload-macrobench-ledger-v6/b3-macrobench/` | `make eval-osdi-w4-ccache-workload-macrobench-ledger` 通过并把非 bulk parent-rule/table/materialized rows、bulk policy compile smoke、bulk policy setup/update release input、bulk materialized baseline 和 bulk FUSE cache-view baseline 合并。summary 记录 `bulk_policy_compile_smoke_pass=true`、`bulk_policy_release_input_pass=true`、`bulk_materialized_baseline_pass=true`、`bulk_fuse_baseline_pass=true`、`bulk_external_baseline_release_input_pass=true`、`bulk_release_comparison_pass=false`、`c2_supported=false`、`release_gate_pass=false`。bulk policy setup 平均 336.19 ms，优于 best external setup 484.83 ms；bulk policy update 平均 4.99 ms，慢于 best external update 2.28 ms。 | W4 bulk proposed-system/FUSE/materialized inputs 均入账，但 comparison gate 仍失败；剩余缺口是 W4 complete compile-through-FUSE 或 native/cache-remap/BuildKit baseline，以及 update/stale/table-budget evidence。 |
| W4 bulk ccache trace/bridge smoke `20260616T-w4-ccache-bulk-smoke-v1` | `results/phase1/20260616T-w4-ccache-bulk-smoke-v1/` | `make kvm-w4-ccache-bulk-policy-bridge` 通过；bulk trace 对 Redis/nginx 各 10 个真实 source 做 ccache cold/hot compile，summary 记录 `source_count=20`、`cache_path_file_ops=400`、`cache_miss=20`、`direct_cache_hit=20`、`output_hash_match=true`；policy bridge 从 strace 抽取 40 个 trace-derived cache objects，summary 记录 `redis_trace_objects=20`、`nginx_trace_objects=20`、`policy_content_oracle_failures=0`、`policy_executed=true`、`kvm_validated=true`、`pass=true`、`qualified_for_c8=false`。 | 把 W4 cache workload 扩到更真实 bulk trace shape；仍不是 C2/C8 支持证据，下一步要跑 bulk operation-weighted policy compile 和更多同 shape 外部/原生 baseline。 |
| W4 bulk materialized cache baseline release run `20260616T-w4-ccache-bulk-materialized-release-v1` | `results/phase1/20260616T-w4-ccache-bulk-materialized-release-v1/` | `make kvm-w4-ccache-bulk-materialized-baseline-macrobench W4_CCACHE_BULK_MATERIALIZED_BASELINE_SAMPLES=20` 通过；trace row 记录 20 个 Redis/nginx source、400 条 cache-path file ops、20 miss、20 direct cache hit 和 output hash match；bridge summary 记录 40 个 trace-derived cache objects；materialized baseline summary 记录 `workload=w4-ccache-bulk-redis-nginx`、20 setup/update/correctness rows、`pass=true`、`failures=0`、`policy_executed=false`、`feature_equivalent_baseline=true`。setup min/avg/max 为 425.40/484.83/573.99 ms；update min/avg/max 为 2.83/3.12/3.77 ms；object shape 为 40 cache objects、36 leaf parents、201335 bytes copied。 | 补齐 W4 bulk trace shape 的外部 materialized baseline raw input；仍不是 C2/C8 支持证据。后续 v6 已补 proposed-system release setup/update input，但仍缺 cache-remap/native/BuildKit baseline、完整 compile-through-FUSE baseline 和 stale/table-budget gate。 |
| W4 bulk policy-attached ccache compile smoke `20260616T-w4-ccache-bulk-policy-compile-smoke-v1` | `results/phase1/20260616T-w4-ccache-bulk-policy-compile-smoke-v1/` | `make kvm-w4-ccache-bulk-policy-compile` 通过；目标先复用 bulk trace/bridge，再在修改内核 KVM 中 attach `cache_locality_view.bpf.c` 运行 20 个 Redis/nginx hot compile。summary 记录 `result_level=kvm_real_ccache_bulk_policy_compile_witness`、`source_manifest_count=20`、`attached_compile_jobs=20`、`attached_compile_output_matches=20`、`policy_executed=true`、`ccache_compile_policy_executed=true`、`output_hash_match=true`、`policy_redirected_cache_objects=40`、`attached_cache_path_file_ops=400`、`attached_policy_cache_object_ops=160`、`pass=true`、`failures=0`、`operation_weighted_policy_cache_hit_rate=false`、`qualified_for_c8=false`。 | 关闭 W4 bulk proposed-system policy-attached compile 的 smoke 输入缺口；后续 v6 已补 setup/update release input，但该 compile smoke 仍不是 C2/C8 支持证据，仍缺同 shape cache-remap/native ccache 或 BuildKit baseline、完整 compile-through-FUSE baseline、operation-weighted release metric 和 stale/table-budget gate。 |
| W4 bulk FUSE cache-view baseline release run `20260616T-w4-ccache-bulk-fuse-baseline-release-v1` | `results/phase1/20260616T-w4-ccache-bulk-fuse-baseline-release-v1/` | `make kvm-w4-ccache-bulk-fuse-baseline-macrobench W4_CCACHE_BULK_FUSE_BASELINE_SAMPLES=20` 通过；目标复用 bulk trace/bridge 的 40 个 trace-derived cache objects，在修改内核 KVM 中运行外部 `fuse_redirect` cache-view baseline。summary 记录 `workload=w4-ccache-bulk-redis-nginx`、20 setup/update/correctness rows、`pass=true`、`failures=0`、`policy_executed=false`、`feature_equivalent_baseline=true`、`c2_supported=false`、`release_gate_pass=false`；setup rows 记录 `fuse_mounts=1`。setup min/avg/max 为 636.59/794.16/1006.38 ms；update min/avg/max 为 1.61/2.28/3.23 ms；input hash 复验通过，dmesg issue scan 为 0。 | 补齐 W4 bulk trace shape 的外部 FUSE cache-view baseline raw input；仍不是 C2/C8 支持证据，也不是完整 compile-through-FUSE ccache baseline。 |

## Anomalies and negative results

- B12 当前为负结果：最新 refreshed ledger 中 `qualified_families=0`、`release_gate_pass=false`，
  hard gate 按预期失败。
- W4 exact-map ccache compile diagnostic 在当前 sampled witness 上通过，是 C8 的负面证据。
- W3 Redis same-workload table-only replay 也通过：`table_rule_writes=2` 且
  `table_baseline_current_oracle_pass=true`。因此 W3 仍不能支持 C8；需要真实
  Podman/CRIU restore、restore trace、zero mixed epoch 或 update/stale window 让
  table-only 失败或超预算。
- W3 checkpoint epoch targeted counterfactual 现在给出了更强的机制证据：
  static exact table 在 epoch 切换后失败，externally-updated exact table correctness
  通过但 `table_update_write_ratio=16` 超过预算 10；同一 run 的
  `materialized_checkpoint_epoch_view` 也 correctness 通过但
  `materialized_update_write_ratio=16`，`targeted_c8_budget_failure=true`。
  但该 run 明确是 synthetic epoch fixture，`real_podman_criu_restore=false`、
  `qualified_for_c8=false`、`release_gate_pass=false`，因此不能替代真实 Podman/CRIU
  restore 证据。
- W3 Podman/CRIU capability audit 当前失败：Podman 存在，但 help 未列出 checkpoint
  command，且 host 没有 CRIU。因此真实 restore target 不能在当前 host 上声称已完成。
- W4 cache-content same-workload table-only comparator 也通过：
  `content_equivalent_table_oracle=true` 且 `table_baseline_current_oracle_pass=true`。
  因此当前 stale/corrupt/miss content oracle 仍不能支持 C8；需要 release-level
  operation-weighted cache hit rate、真实 stale/corrupt transition、BuildKit cache trace
  或 update/stale window 让 table-only 失败或超预算。
- W4 cache epoch targeted counterfactual 现在给出了更强的机制证据：
  static exact table 在 cache epoch 切换后失败，externally-updated exact table correctness
  通过但 `table_update_write_ratio=16` 超过预算 10；同一 run 的
  `materialized_cache_epoch_view` 也 correctness 通过但
  `materialized_update_write_ratio=16`，`targeted_c8_budget_failure=true`。
  但该 run 明确是 synthetic cache epoch fixture，`real_ccache_trace=false`、
  `qualified_for_c8=false`、`release_gate_pass=false`，因此不能替代真实 ccache/BuildKit
  trace 证据。
- W4 ccache rule macrobench release ledger 是 C2 负结果：parent-rule policy setup/update
  平均慢于 table baseline，rule writes 相同，`w4_c2_slice_supported=false`。当前
  ccache trace 只有 4 个 cache objects 且分别落在 4 个 leaf parent，不能展示
  parent-scoped rule-count advantage。
- W4 bulk ccache smoke 已把 trace shape 扩到 40 个 trace-derived cache objects 并通过
  policy bridge；bulk materialized cache baseline 进一步在同 shape 下跑通 20-sample
  外部 baseline，setup/update 平均为 484.83 ms/3.12 ms；bulk policy-attached compile
  smoke 又证明 20 个真实 hot compiles 可通过 attached cache policy 消费这些 objects。
  bulk FUSE cache-view baseline 也在同 shape 下跑通 20-sample 外部 baseline，
  setup/update 平均为 794.16 ms/2.28 ms，每个 setup sample 记录 `fuse_mounts=1`。
  bulk policy setup/update macrobench 又在同 shape 下跑通 20-sample proposed-system
  release input。最新 v6 W4 workload ledger 已把这些 bulk rows 纳入 claim-level
  artifact，并记录 `bulk_policy_release_input_pass=true`，但
  `bulk_release_comparison_pass=false`：policy setup 平均优于 best external setup，
  policy update 平均慢于 best external update。它还缺同 shape cache-remap/native ccache
  或 BuildKit baseline、完整 compile-through-FUSE baseline、operation-weighted policy
  hit-rate、stale/update window 或 table budget failure。
  因此它仍不能把 W4 负结果改写成正结果。
- Latency pilot 是 `kvm-bench` 子集，不含完整 Phase 1 `metadata.json`，不能作为 release ledger root。
- 历史 full root `20260615T-full-phase1-c2-setup-update-v1` 首次写入 `namei_ext`
  setup/update raw rows；当前 C2 release-sample full root 是
  `20260615T-full-phase1-c2-release-sample-v1`，但它仍没有 W1-W4
  workload-equivalent macrobench comparison；它也不是 B2/B8 performance root，不能替代
  batch=64/tail10 performance roots。
- C2 macrobench ledger 已能读取 `namei_ext` raw rows 和五个 release external baseline rows，
  但 `namei_ext_release_sample_budget_pass=false`、`macrobench_input_gate_pass=false`。
  因此旧 `20260615T-eval-c2-macrobench-ledger-v1` 是 input/contract 未满足的历史记录。
- 最新 C2 release-sample ledger 已把 `namei_ext_release_sample_budget_pass` 和
  `macrobench_input_gate_pass` 提升为 true，但仍明确 `c2_supported=false`、
  `release_gate_pass=false` 和 `verdict=blocked_by_missing_thresholds`。因此当前 C2
  不是性能正结果，而是阈值和 workload-equivalent macrobench 仍未满足。
- C2 workload derived ledger 已把 W1--W4 的 8 个 workload row 写入
  `workload-macrobench.jsonl`，但它的 `result_level` 是
  `c2_workload_derived_contract`，`run_environment` 是 `mixed_host_kvm_derived`，
  且 `c2_eligible_rows=0`。因此它只能作为下一步 KVM macrobench 的 inventory 和
  blocker 列表，不能作为 setup/materialization cost improvement。
- W2 nginx KVM setup/update macrobench 已跑通 20 个 samples；它只能证明
  `kvm-w2-nginx-macrobench` 的真实 workload release repetition raw input 可运行，不能作为
  setup/materialization cost improvement。
- W2 nginx copy/symlink/bind/projected/FUSE baseline macrobench 已跑通 20 个 samples，并由
  W2 workload ledger 合并到 claim-level artifacts；v5 ledger 进一步证明 W2 slice 的
  `storage_footprint_pass=true`、`threshold_pass=true` 和
  `w2_c2_slice_supported=true`。W1 已有 20-sample proposed-system release input 和
  copy/symlink/bind/projected/FUSE baseline release input，但 W1 ledger 为负：
  storage/setup/update/materialization threshold 不通过，且 fastest baseline 优于
  proposed-system。W3 已有 20-sample proposed-system release input 和
  materialized/FUSE checkpoint-view baseline release input，但 W3 ledger 为负：
  setup/update latency threshold 不通过，且 best external baseline 优于 proposed-system。
  W4 已有 parent-rule/table baseline release ledger 和 bulk materialized/FUSE/policy
  release ledger，但这些 ledgers 也为负。剩余全局缺口是 W4 更强 cache workload 或范围收窄，
  并需要把 W1/W3/W4 作为完整 baseline 下的负结果处理。
- Tail artifact pilot 虽有 p50/p95/p99/pilot-scale CI rows，但每组只有 2 rows，`has_release_sample_budget=false`。
- Run-order/system-metrics first pilot `20260615T-kvm-bench-order-metrics-pilot` 是失败 run：runner 成功但 Make recipe 丢失跨行 shell status，写出 malformed `bench-done`。该失败已保留，并通过 `bench-status.txt` 修复。
- Run-order/system-metrics successful pilot 仍然只有 `SAMPLES=1` 和每组 2 个 latency rows，不能支持 release claim。
- Release-sample microbench pilot 和 external baseline release pilot 虽有 20 samples、tail/CI、随机化顺序、系统指标和五个 release baselines，但 latency rows 的最小 ops 只有 4；这些旧 roots 保留为 diagnostic evidence，不再作为 paper-grade p99 输入。
- 原始 batch=64 B2/B8 comparison 的 input gate 已通过，但阈值失败：`lookup_native_hot` 的 policy/native p99 worst case 约 1.77x，`exec_tool_redirect` 未达到相对 FUSE 2x speedup，pass-only residual 最高 1.71x，不能支撑 C3/C5。
- RCU-pass fastpath 两个 PoC 都是负结果。它们说明 RCU-walk 降级确实解释一部分 pass-only residual，但同时让 redirect policy 的最差 policy/native p99 从原始 1.77x 恶化到 2.49x 或 2.43x；因此不能作为主线优化保留。
- ctx 初始化拆分 PoC 是混合结果：pass-only/native worst case 降到 1.095x 并通过
  pass-only 阈值，但 max policy/native p99 仍为 1.81x，min policy/FUSE speedup 仍只有
  1.64x；因此它不能单独支持 C3/C5，只能作为 residual-overhead attribution evidence。
- tail10 诊断显示 1-sample batch64 的 pass-only 过阈值不稳健：每组 200 条 latency row 后
  FUSE speedup 阈值通过，但 `pass_only_threshold_pass=false`，且 `readdir_alias_view`
  与 `build_tree_stat_walk` 暴露 kernel p99 blocker。
- rusage/no-hook 诊断降低了 C5 失败的严重程度但没有改变 verdict：非 exec p99 rows
  几乎没有 fault/context-switch，full-run baseline denominator 存在 order/cache variance；
  no-hook denominator 下 pass-only worst case 为 1.306x，matched baseline/pass-only worst
  case 为 1.323x，仍高于 1.1x。
- Main repo 和 kernel repo 都是 dirty state，不能作为 final artifact claim。

## Variance/tail/resource observations

当前已有 B2 microbench/external-baseline raw tail、CI、batch=64 release input 和 threshold verdict；W2 为正向 thresholded workload slice，W1/W3/W4 为负向 workload comparison。已有数据包含：

- smoke aggregate timing；
- latency pilot batch raw rows；
- pilot-scale p50/p95/p99/CI plumbing artifact；
- canonical full root 没有 tail/CI artifact；
- run-order/system-metrics pilot 已记录 35 个 bench-order rows、5 个 variant-order rows、
  before/after system metrics，但不是 release repetition；
- release-sample microbench pilot 已记录 700 个 bench-order rows、700 个 latency rows、
  before/after system metrics，并满足每组 20 个 latency rows；
- 已有 copy-tree、symlink-forest、bind-mount、OverlayFS 和 FUSE redirect 的 20-sample KVM
  external baseline timing，且 comparison target 已生成 external baseline p50/p95/p99/CI；
- C2 macrobench ledger 已把同一个 batch=64 external baseline root 的 setup/update rows
  和 `namei_ext` setup/update raw rows 放入 `b3-macrobench/macrobench.jsonl`；最新
  release-sample root 已达到 20-sample release budget，但仍未覆盖 W1-W4
  workload-equivalent setup/storage/update，也没有 C2 成功阈值。
- C2 workload derived ledger 已把 W1--W4 的当时 correctness/provenance/KVM witness
  摊平成 8 条 row；它是历史 inventory，不能替代后续 W1/W2/W3/W4 专用 release
  macrobench ledgers。后续专用 ledgers 显示 W2 slice 为正，W1/W3/W4 为负。
- W2 workload macrobench ledger 已把 W2 proposed-system release rows 和 copy/symlink/bind/projected/FUSE
  baseline release rows 合并到 `w2-nginx-workload-macrobench.jsonl`；summary 中
  `policy_release_input_pass=true`、`baseline_release_input_pass=true`、
  `all_feature_baselines_pass=true`、`full_feature_equivalent_baseline_pass=true`、
  `storage_footprint_pass=true`、`threshold_pass=true` 和
  `w2_c2_slice_supported=true`，但全局 `c2_supported=false`。W1 已有 proposed-system
  setup/update release input 和 copy/symlink/bind/projected/FUSE baseline release input；
  W1 ledger 为负，threshold 未通过，需要作为负结果处理或范围收窄。W4 ccache workload
  macrobench 已有 release input 但为负。W3 Redis workload macrobench 也已有 proposed-system
  release input 和 materialized/FUSE baseline release input；ledger 记录
  `storage_footprint_pass=true`，但 setup/update latency thresholds 失败，
  `w3_c2_slice_supported=false`。
- 最新 tail10 head-to-head comparison artifact 已生成，input gate 和 FUSE speedup 阈值已通过；
  但 C2/C3/C5 release gate 因 kernel p99 threshold、pass-only residual 和 C2 macrobench
  缺口仍为 false。
- rusage collector 已为每条 `bench`/`bench_latency` row 增加 user/sys CPU、minor/major
  fault、voluntary/involuntary context switch 和 child rusage delta。no-hook baseline-only
  与 matched baseline/pass-only tail10 表明 residual 主要表现为 self CPU/op 增加。
- RCU-pass fastpath 的 release comparison artifact 已生成，并作为 negative engineering
  evidence 保留：它降低 pass-only residual，但没有通过阈值，且让 redirect policy
  的 worst-case policy/native p99 明显恶化。

## Figure/table candidates

- 表 1：Phase 1 correctness gates 和 policy family semantic witness，当前只能作为 prototype evidence。
- 图 1：B2 microbenchmark distribution，可画负结果；当前不能作为性能优势图。
- 图 2-5：W1-W4 macrobench，W2 是当前唯一正向 thresholded slice；W1、W3 和 W4 都已有 release comparison 但为负。
- 图 8/表 4：B12 policy family programmability，当前是 blocked/negative evidence table。

## Result files used

- `results/phase1/20260615T-full-phase1-bench-variants/summary.md`
- `results/phase1/20260615T-full-phase1-b12-refresh-v1/summary.md`
- `results/eval-osdi/paper/20260615T-eval-b12-refresh-v1/b12-policy-family/policy-family.jsonl`
- `results/eval-osdi/paper/20260615T-eval-b12-refresh-hardgate-v1/b12-policy-family/policy-family.jsonl`
- `results/phase1/20260615T-full-phase1-c2-setup-update-v1/summary.md`
- `results/phase1/20260615T-full-phase1-c2-setup-update-v1/bench.jsonl`
- `results/eval-osdi/paper/20260615T-eval-b12-c2-setup-update-v1/b12-policy-family/policy-family.jsonl`
- `results/eval-osdi/paper/20260615T-eval-b12-c2-setup-update-hardgate-v1/b12-policy-family/policy-family.jsonl`
- `results/eval-osdi/paper/20260615T-eval-c2-macrobench-ledger-v1/b3-macrobench/macrobench.jsonl`
- `results/eval-osdi/paper/20260615T-eval-c2-macrobench-hardgate-v1/b3-macrobench/macrobench.jsonl`
- `results/phase1/20260615T-full-phase1-c2-release-sample-v1/summary.md`
- `results/phase1/20260615T-full-phase1-c2-release-sample-v1/bench.jsonl`
- `results/eval-osdi/paper/20260615T-eval-c2-release-sample-ledger-v1/b3-macrobench/macrobench.jsonl`
- `results/eval-osdi/paper/20260615T-eval-c2-release-sample-hardgate-v1/b3-macrobench/macrobench.jsonl`
- `results/eval-osdi/paper/20260615T-eval-c2-workload-derived-ledger-v1/b3-macrobench/workload-macrobench.jsonl`
- `results/eval-osdi/paper/20260615T-eval-c2-workload-derived-hardgate-v1/b3-macrobench/workload-macrobench.jsonl`
- `results/phase1/20260615T-w2-nginx-c2-macrobench-release-sample-v1/w2-nginx-macrobench.jsonl`
- `results/phase1/20260616T-w2-nginx-baseline-macrobench-release-sample-v4/w2-nginx-baseline-macrobench.jsonl`
- `results/eval-osdi/paper/20260616T-eval-w2-nginx-workload-macrobench-ledger-v5/b3-macrobench/w2-nginx-workload-macrobench.jsonl`
- `results/eval-osdi/paper/20260616T-eval-w2-nginx-workload-macrobench-hardgate-v5/b3-macrobench/w2-nginx-workload-macrobench.jsonl`
- `results/phase1/20260616T-w1-build-macrobench-smoke-v3/w1-build-macrobench.jsonl`
- `results/phase1/20260616T-w1-build-macrobench-release-sample-v1/w1-build-macrobench.jsonl`
- `results/phase1/20260616T-w1-build-baseline-release-sample-v1/w1-build-baseline-macrobench.jsonl`
- `results/eval-osdi/paper/20260616T-eval-w1-build-workload-macrobench-ledger-release-v1/b3-macrobench/w1-build-workload-macrobench.jsonl`
- `results/eval-osdi/paper/20260616T-eval-w1-build-workload-macrobench-hardgate-release-v1/b3-macrobench/w1-build-workload-macrobench.jsonl`
- `results/phase1/20260616T-w1-build-baseline-release-sample-v2/w1-build-baseline-macrobench.jsonl`
- `results/eval-osdi/paper/20260616T-eval-w1-build-workload-macrobench-ledger-release-v2/b3-macrobench/w1-build-workload-macrobench.jsonl`
- `results/eval-osdi/paper/20260616T-eval-w1-build-workload-macrobench-hardgate-release-v2/b3-macrobench/w1-build-workload-macrobench.jsonl`
- `results/phase1/20260616T-w3-redis-macrobench-release-v1/w3-redis-policy-macrobench.jsonl`
- `results/phase1/20260616T-w3-redis-macrobench-release-v1/w3-redis-baseline-macrobench.jsonl`
- `results/eval-osdi/paper/20260616T-eval-w3-redis-workload-macrobench-ledger-v1/b3-macrobench/w3-redis-workload-macrobench.jsonl`
- `results/phase1/20260616T-w4-ccache-rule-macrobench-release-v1/w4-ccache-rule-macrobench.jsonl`
- `results/phase1/20260616T-w4-ccache-materialized-baseline-release-v1/w4-ccache-materialized-baseline.jsonl`
- `results/eval-osdi/paper/20260616T-eval-w4-ccache-workload-macrobench-ledger-v2/b3-macrobench/w4-ccache-workload-macrobench.jsonl`
- `results/eval-osdi/paper/20260616T-eval-w4-ccache-workload-macrobench-hardgate-v2/b3-macrobench/w4-ccache-workload-macrobench.jsonl`
- `results/eval-osdi/paper/20260616T-eval-w4-ccache-workload-macrobench-ledger-v5/b3-macrobench/w4-ccache-workload-macrobench.jsonl`
- `results/phase1/20260616T-w4-ccache-bulk-policy-macrobench-release-v1/w4-ccache-bulk-policy-macrobench.jsonl`
- `results/eval-osdi/paper/20260616T-eval-w4-ccache-workload-macrobench-ledger-v6/b3-macrobench/w4-ccache-workload-macrobench.jsonl`
- `results/phase1/20260616T-w4-ccache-bulk-smoke-v1/w4-ccache-bulk-trace.jsonl`
- `results/phase1/20260616T-w4-ccache-bulk-smoke-v1/w4-ccache-bulk-policy-bridge.jsonl`
- `results/phase1/20260616T-w4-ccache-bulk-materialized-release-v1/w4-ccache-bulk-trace.jsonl`
- `results/phase1/20260616T-w4-ccache-bulk-materialized-release-v1/w4-ccache-bulk-policy-bridge.jsonl`
- `results/phase1/20260616T-w4-ccache-bulk-materialized-release-v1/w4-ccache-bulk-materialized-baseline.jsonl`
- `results/phase1/20260616T-w4-ccache-bulk-policy-compile-smoke-v1/w4-ccache-bulk-policy-compile.jsonl`
- `results/phase1/20260616T-w4-ccache-bulk-fuse-baseline-release-v1/w4-ccache-bulk-fuse-baseline.jsonl`
- `results/phase1/20260615T-full-phase1-bench-variants/bench.jsonl`
- `results/eval-osdi/paper/20260615T-eval-contract-bench-variants/b12-policy-family/policy-family.jsonl`
- `results/phase1/20260615T-w3-redis-counterfactual-smoke-v1/w3-redis-counterfactual.jsonl`
- `results/eval-osdi/paper/20260615T-eval-ledger-after-latency-code-p2fix/b2-performance/performance.jsonl`
- `results/phase1/20260615T-kvm-bench-latency-pilot/bench.jsonl`
- `results/eval-osdi/paper/20260615T-tail-artifact-pilot/b2-performance/bench-latency-tail.jsonl`
- `results/eval-osdi/paper/20260615T-eval-ledger-tail-artifact/b2-performance/performance.jsonl`
- `results/eval-osdi/baselines/20260615T-kvm-external-baselines-content-v1/baseline-ledger.jsonl`
- `results/eval-osdi/paper/20260615T-eval-ledger-content-baselines/b2-performance/performance.jsonl`
- `results/eval-osdi/baselines/20260615T-kvm-external-baselines-fuse-smoke-v2/baseline-ledger.jsonl`
- `results/eval-osdi/paper/20260615T-eval-ledger-fuse-baselines-smoke/b2-performance/performance.jsonl`
- `results/phase1/20260615T-kvm-bench-order-metrics-pilot-v3/bench.jsonl`
- `results/phase1/20260615T-kvm-bench-order-metrics-pilot-v3/bench-system-metrics.jsonl`
- `results/phase1/20260615T-kvm-bench-order-metrics-pilot-v3/metadata.json`
- `results/eval-osdi/paper/20260615T-eval-ledger-order-metrics-pilot-v2/b2-performance/performance.jsonl`
- `results/phase1/20260615T-kvm-bench-release-sample-pilot/bench.jsonl`
- `results/phase1/20260615T-kvm-bench-release-sample-pilot/bench-system-metrics.jsonl`
- `results/phase1/20260615T-kvm-bench-release-sample-pilot/metadata.json`
- `results/eval-osdi/paper/20260615T-eval-ledger-release-sample-pilot/b2-performance/performance.jsonl`
- `results/eval-osdi/baselines/20260615T-kvm-external-baselines-release-pilot/baseline-ledger.jsonl`
- `results/eval-osdi/paper/20260615T-eval-ledger-release-baselines-pilot/b2-performance/performance.jsonl`
- `results/eval-osdi/baselines/20260615T-kvm-external-baselines-expected-set-smoke-v1/baseline-ledger.jsonl`
- `results/eval-osdi/paper/20260615T-eval-comparison-pilot-v1/b2-performance/performance-comparison.jsonl`
- `results/eval-osdi/paper/20260615T-eval-comparison-pilot-v1/b2-performance/external-baseline-latency-tail.jsonl`
- `results/eval-osdi/paper/20260615T-eval-comparison-hardgate-v1/b2-performance/performance-comparison.jsonl`
- `results/eval-osdi/paper/20260615T-eval-comparison-latency-batch-gate-v1/b2-performance/performance-comparison.jsonl`
- `results/eval-osdi/baselines/20260615T-kvm-external-baselines-unique-sample-smoke-v1/baseline-ledger.jsonl`
- `results/eval-osdi/paper/20260615T-eval-comparison-latency-batch-hardgate-v2/b2-performance/performance-comparison.jsonl`
- `results/phase1/20260615T-kvm-bench-release-batch64-v1/bench.jsonl`
- `results/phase1/20260615T-kvm-bench-release-batch64-v1/bench-system-metrics.jsonl`
- `results/phase1/20260615T-kvm-bench-release-batch64-v1/metadata.json`
- `results/eval-osdi/baselines/20260615T-kvm-external-baselines-batch64-v1/baseline-ledger.jsonl`
- `results/eval-osdi/paper/20260615T-eval-comparison-batch64-v1/b2-performance/performance-comparison.jsonl`
- `results/eval-osdi/paper/20260615T-eval-comparison-batch64-v1/b2-performance/bench-latency-tail.jsonl`
- `results/eval-osdi/paper/20260615T-eval-comparison-batch64-v1/b2-performance/external-baseline-latency-tail.jsonl`
- `results/eval-osdi/paper/20260615T-eval-comparison-batch64-hardgate-v1/b2-performance/performance-comparison.jsonl`
- `results/phase1/20260615T-kvm-bench-rcu-pass-smoke-v1/bench.jsonl`
- `results/phase1/20260615T-kvm-bench-rcu-pass-batch64-v1/bench.jsonl`
- `results/eval-osdi/baselines/20260615T-kvm-external-baselines-rcu-pass-batch64-v1/baseline-ledger.jsonl`
- `results/eval-osdi/paper/20260615T-eval-comparison-rcu-pass-batch64-v1/b2-performance/performance-comparison.jsonl`
- `results/phase1/20260615T-kvm-bench-rcu-redirect-unlazy-smoke-v1/bench.jsonl`
- `results/phase1/20260615T-kvm-bench-rcu-redirect-unlazy-batch64-v1/bench.jsonl`
- `results/eval-osdi/baselines/20260615T-kvm-external-baselines-rcu-redirect-unlazy-batch64-v1/baseline-ledger.jsonl`
- `results/eval-osdi/paper/20260615T-eval-comparison-rcu-redirect-unlazy-batch64-v1/b2-performance/performance-comparison.jsonl`
- `results/phase1/20260615T-kvm-bench-post-rcu-experiment-stable-smoke-v1/bench.jsonl`
- `results/phase1/20260615T-kvm-bench-ctx-init-split-smoke-v1/bench.jsonl`
- `results/phase1/20260615T-kvm-bench-ctx-init-split-batch64-v1/bench.jsonl`
- `results/eval-osdi/baselines/20260615T-kvm-external-baselines-ctx-init-split-batch64-v1/baseline-ledger.jsonl`
- `results/eval-osdi/paper/20260615T-eval-comparison-ctx-init-split-batch64-v1/b2-performance/performance-comparison.jsonl`
- `results/eval-osdi/paper/20260615T-eval-comparison-ctx-init-split-batch64-hardgate-v1/b2-performance/performance-comparison.jsonl`
- `results/phase1/20260615T-kvm-bench-ctx-init-split-tail10-v1/bench.jsonl`
- `results/eval-osdi/baselines/20260615T-kvm-external-baselines-ctx-init-split-tail10-v1/baseline-ledger.jsonl`
- `results/eval-osdi/paper/20260615T-eval-comparison-ctx-init-split-tail10-v1/b2-performance/performance-comparison.jsonl`
- `results/eval-osdi/paper/20260615T-eval-comparison-ctx-init-split-tail10-hardgate-v1/b2-performance/performance-comparison.jsonl`
- `results/phase1/20260615T-kvm-bench-rusage-smoke-v1/bench.jsonl`
- `results/phase1/20260615T-kvm-bench-rusage-tail10-v1/bench.jsonl`
- `results/eval-osdi/paper/20260615T-eval-rusage-tail10-v1/b2-performance/bench-latency-tail.jsonl`
- `results/phase1/20260615T-kvm-bench-variant-selector-full-smoke-v1/bench.jsonl`
- `results/phase1/20260615T-kvm-bench-nohook-baseline-smoke-v1/bench.jsonl`
- `results/phase1/20260615T-kvm-bench-nohook-baseline-tail10-v1/bench.jsonl`
- `results/eval-osdi/paper/20260615T-eval-nohook-baseline-tail10-v1/b2-performance/bench-latency-tail.jsonl`
- `results/phase1/20260615T-kvm-bench-baseline-passonly-tail10-v1/bench.jsonl`
- `results/eval-osdi/paper/20260615T-eval-baseline-passonly-tail10-v1/b2-performance/bench-latency-tail.jsonl`
