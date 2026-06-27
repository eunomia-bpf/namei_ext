# C2 setup/update release repetition 实现记录

日期：2026-06-15

## 背景

C2 要证明的是 `namei_ext` 是否降低动态 path-resolution customization 的
setup/materialization/update 成本。此前 `20260615T-full-phase1-c2-setup-update-v1`
已经在 KVM full Phase 1 root 中写入 `namei_ext-setup` 和 `namei_ext-update`
raw rows，但每类只有单个 sample。随后
`20260615T-eval-c2-macrobench-ledger-v1` 正确地给出
`namei_ext_release_sample_budget_pass=false` 和 `macrobench_input_gate_pass=false`。

本步骤只解决一个窄问题：让 `namei_ext` 自身的 setup/source-update/policy-update
raw events 达到 release sample budget。它不直接证明 C2，因为仍缺 W1--W4
workload-equivalent macrobench comparison 和显式成功阈值。

## 修改内容

涉及文件：

- `bench/workloads/namei_ext_bench.c`
- `mk/report.mk`
- `mk/eval_osdi.mk`

`namei_ext_bench.c` 的变化：

- `namei_ext-setup` 和 `namei_ext-update` rows 增加 `sample` 字段。
- `sample=0` 沿用主 benchmark env，保证原有 functional/microbench 路径不变。
- `sample=1..SAMPLES-1` 为 setup/source-update 创建独立临时 bench env，执行真实
  backing tree setup 和 source update，并在结束后清理。
- `table_redirect_hit` 的 policy map update 从单次扩展为每个 sample 执行一次，产生
  `namei_ext-update variant=table_redirect_hit` 和 `bench_map_update` raw rows。
- policy attach 和实际 microbench suite 仍按原有路径执行，避免把 C2 setup/update
  repetition 误扩展成新的 latency/performance claim。

`mk/report.mk` 的变化：

- Phase 1 report gate 要求 `namei_ext-setup`、
  `namei_ext-update variant=backing_tree`、
  `namei_ext-update variant=table_redirect_hit` 和 `bench_map_update` 的 row 数都等于
  `SAMPLES`。
- gate 同时检查 sample id 覆盖 `0..SAMPLES-1`，防止重复 sample id 误过 release
  sample budget。

`mk/eval_osdi.mk` 的变化：

- C2 macrobench ledger 改为按 unique sample id 计算
  `namei_ext_release_sample_budget_pass`。
- 输出 `setup_samples`、`source_update_samples`、`policy_update_samples`，并在 summary
  中记录 `namei_ext_*_samples`。
- 对旧 root 兼容：缺失 `sample` 字段的历史 rows 视为 `sample=0`，所以旧
  single-sample root 仍能得到 `namei_ext_release_sample_budget_pass=false`。

## 验证

本地构建：

```text
make bench
```

结果：通过。

KVM smoke：

```text
make kvm-bench RUN_ID=20260615T-kvm-bench-c2-repetition-smoke-v1 SAMPLES=2 BENCH_ITERS=100 BENCH_LATENCY_SAMPLES=0
```

结果：通过。`bench.jsonl` 中：

- `namei_ext-setup`：2 rows，2 unique samples，sample id 为 0 和 1。
- `namei_ext-update variant=backing_tree`：2 rows，2 unique samples。
- `namei_ext-update variant=table_redirect_hit`：2 rows，2 unique samples。
- `bench_map_update`：2 rows。
- `bench` rows：70。
- benchmark failure rows：0。

向后兼容 ledger：

```text
make eval-osdi-macrobench-ledger RUN_ID=20260615T-eval-c2-macrobench-ledger-unique-sample-compat-v1 EVAL_OSDI_PHASE1_RUN_ID=20260615T-full-phase1-c2-setup-update-v1 EVAL_OSDI_MACROBENCH_BASELINE_RUN_ID=20260615T-kvm-external-baselines-batch64-v1
```

结果：通过。旧 root 被解释为每类 1 个 unique sample，release sample budget 仍为
false。

完整 Phase 1 release-sample root：

```text
make phase1 RUN_ID=20260615T-full-phase1-c2-release-sample-v1 SAMPLES=20 BENCH_ITERS=2000 BENCH_LATENCY_SAMPLES=0
```

结果：通过。该 root 的 `bench.jsonl` 中：

- `namei_ext-setup`：20 rows，20 unique samples，sample id 为 0 到 19。
- `namei_ext-update variant=backing_tree`：20 rows，20 unique samples，sample id 为 0 到 19。
- `namei_ext-update variant=table_redirect_hit`：20 rows，20 unique samples，sample id 为 0 到 19。
- `bench_map_update`：20 rows。
- `bench` rows：700。
- benchmark failure rows：0。

C2 macrobench ledger：

```text
make eval-osdi-macrobench-ledger RUN_ID=20260615T-eval-c2-release-sample-ledger-v1 EVAL_OSDI_PHASE1_RUN_ID=20260615T-full-phase1-c2-release-sample-v1 EVAL_OSDI_MACROBENCH_BASELINE_RUN_ID=20260615T-kvm-external-baselines-batch64-v1
```

结果：通过并写出
`results/eval-osdi/paper/20260615T-eval-c2-release-sample-ledger-v1/b3-macrobench/macrobench.jsonl`。
summary 中：

- `namei_ext_raw_gate_pass=true`
- `namei_ext_release_sample_budget_pass=true`
- `baseline_release_gate_pass=true`
- `baseline_unique_sample_budget_pass=true`
- `macrobench_input_gate_pass=true`
- `c2_supported=false`
- `release_gate_pass=false`
- `verdict=blocked_by_missing_thresholds`

C2 hard gate：

```text
make eval-osdi-macrobench RUN_ID=20260615T-eval-c2-release-sample-hardgate-v1 EVAL_OSDI_PHASE1_RUN_ID=20260615T-full-phase1-c2-release-sample-v1 EVAL_OSDI_MACROBENCH_BASELINE_RUN_ID=20260615T-kvm-external-baselines-batch64-v1
```

结果：按预期失败。失败原因是 ledger summary 没有
`release_gate_pass=true` 和 `c2_supported=true`。这说明 release sample budget
已经补齐，但 Make gate 没有把它误写成 C2 supported claim。

## 结论

本步骤把 C2 blocker 从“`namei_ext` 自身没有 release repetition”缩小为：

- 缺 W1--W4 workload-equivalent setup/storage/update macrobench。
- 缺与 copy tree、symlink forest、bind mount、OverlayFS、FUSE 等基线的同 workload
  feature-equivalent comparison。
- 缺明确的 C2 setup/update 成功阈值。

因此 C2 仍为 unsupported。论文可以写“C2 input gate 现在通过，hard gate 阻止 overclaim”，
不能写“`namei_ext` 已证明 setup/materialization 成本优势”。

## 剩余风险

- 当前 repetition 只覆盖 generic backing tree 和 table policy update，不覆盖 W1--W4
  的 workload-specific object graph、storage footprint、stale/update window 或 app-level
  correctness oracle。
- `BENCH_LATENCY_SAMPLES=0` 的 full Phase 1 root 不能替代 B2/B8 latency comparison root。
- C2 ledger 仍是 contract ledger，不是最终性能图表；下一步需要把 W1--W4 macrobench
  rows 纳入 `b3-macrobench/` 并定义阈值。
