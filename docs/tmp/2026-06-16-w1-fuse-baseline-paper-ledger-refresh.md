# W1 FUSE baseline paper and ledger refresh

日期：2026-06-16

## 动机

W1 build graph 的 `projected_volume` 和 `fuse_redirect` baselines 已经由
`20260616T-w1-build-baseline-release-sample-v2` 补齐，并由
`20260616T-eval-w1-build-workload-macrobench-ledger-release-v2` 写入 claim-level
ledger。旧的论文评价章、claim ledger 和结果总结仍把 W1 projected/FUSE 当作缺口，
这会把一个完整 baseline 下的负结果误写成输入未完成。

## 检查的证据

- `results/phase1/20260616T-w1-build-baseline-release-sample-v2/w1-build-baseline-macrobench.jsonl`
- `results/eval-osdi/paper/20260616T-eval-w1-build-workload-macrobench-ledger-release-v2/b3-macrobench/w1-build-workload-macrobench.jsonl`
- `docs/tmp/2026-06-16-w1-build-projected-fuse-baseline-implementation.md`
- `research/STATE.md`
- `docs/paper/sections/05-evaluation.tex`
- `research/CLAIM_LEDGER.md`
- `research/CLAIM_VERDICT.md`
- `research/RESULTS_SUMMARY.md`

## 更新内容

- `research/CLAIM_LEDGER.md` 的 C2 row 改为：W1 已有
  `copy_tree`、`symlink_forest`、`bind_mount`、`projected_volume` 和
  `fuse_redirect` 五类 baseline release input；W1 仍因 storage/setup/update/update
  materialization thresholds 失败而 unsupported。
- `research/CLAIM_VERDICT.md` 的 C2 verdict 改为引用 v2 W1 baseline/ledger，
  明确 `projected_volume_baseline_pass=true`、`fuse_baseline_pass=true` 和
  `full_feature_equivalent_baseline_pass=true`，同时保留 C2 unsupported verdict。
- `research/RESULTS_SUMMARY.md` 增补 v2 W1 baseline/ledger/hardgate rows，并把全局
  C2 blocker 从 W1 projected/FUSE 缺口改成 W1 完整负结果、W3 缺对等 macrobench 和
  W4 负结果/更强 workload 缺口。
- `docs/paper/sections/05-evaluation.tex` 更新 C2 速查表、workload source-signal 表、
  W1 release macrobench 段落和 W2 段落中的全局 C2 blocker。
- 同一评价章把 W3 表格 ID 从 `w3-redis-podman-criu`/`w3-nginx-podman-criu` 改为
  `w3-redis-rdb-replay`/`w3-nginx-checkpoint-fixture`，避免暗示当前已经完成
  Podman/CRIU restore。

## 当前结论

W1 不再缺 projected-volume 或 FUSE baseline evidence。v2 release input 覆盖五类
feature baselines，每类 20 setup/update/correctness rows，FUSE rows 记录
`fuse_mounts=4`。W1 ledger 的完整 feature baseline gate 通过，但 W1 C2 slice 仍为负：

```text
storage_footprint_pass=false
setup_latency_threshold_pass=false
update_latency_threshold_pass=false
update_materialization_threshold_pass=false
w1_c2_slice_supported=false
```

关键均值仍显示 baseline 更强：

```text
policy_setup_ns_avg=66090011.6
best_baseline_setup_ns_avg=17324797.3
policy_update_ns_avg=52416038.25
best_baseline_update_ns_avg=37528990.95
```

因此 W1 应写成完整 baseline 下的 negative evidence，而不是 C2 支持证据，也不是输入缺口。

## 剩余风险

- 全局 C2 仍不能成立：W2 slice 为正，W1 和 W4 为负，W3 缺对等 release macrobench。
- C3/C5 仍受 kernel p99 和 common hook/dispatch residual 阻塞。
- C8 仍没有 table-only failure 或 over-budget release row；W3/W4 当前 table-only
  counterfactual 是负证据。
- 本次只同步派生文档和论文文字，没有重写 raw result artifacts。
