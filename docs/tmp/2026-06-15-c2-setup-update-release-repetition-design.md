# C2 setup/update release repetition 设计

日期：2026-06-15
阶段：Phase 1 实现前设计记录
状态：准备实现

## 动机

C2 macrobench ledger 已经能读取 `namei_ext-setup`、`namei_ext-update` 和 external baseline
release rows，但当前 `namei_ext` 侧只有 1 组 setup/source-update/policy-update raw rows。
因此 ledger 正确给出 `namei_ext_release_sample_budget_pass=false`。下一步最低风险改动是让
`namei_ext` 侧 setup/update raw rows 和现有 `SAMPLES` 语义一致，先满足 release sample
budget 的输入条件。

这一步仍不声称 C2 supported。即便 release sample budget 通过，C2 还缺 W1--W4
workload-equivalent setup/storage/update macrobench 和明确成功阈值。

## 检查过的代码路径

- `bench/workloads/namei_ext_bench.c`
  - `setup_env()` 创建 backing tree。
  - `update_env_backing()` 执行 source backing update。
  - `run_table_hit_variant()` load/attach `table_redirect.bpf.c` 并填充 66 条 map rule。
  - `run_suite()` 已按 `samples` 生成 performance rows。
- `mk/report.mk`
  - 当前 Phase 1 report hard gate 要求 setup/source-update/table-update rows 各 1 条。
- `mk/eval_osdi.mk`
  - 当前 C2 macrobench ledger 用 row count 判断 `namei_ext_release_sample_budget_pass`。

## 设计

1. 给 `namei_ext-setup` 和 `namei_ext-update` raw rows 增加 `sample` 字段。
2. 主 benchmark 使用 sample 0 的环境，保持现有 performance benchmark 行为不变。
3. 对 sample 1 到 `SAMPLES-1`，创建独立临时 backing tree，真实执行 setup 和 source update，
   写出 raw rows，然后清理临时环境。这样不会污染主 benchmark 环境，也不是复制旧观测。
4. 对 `table_redirect_hit` policy map update，在同一个 attached policy 上按 sample 重复执行
   `populate_table_hit_policy()`。每次仍真实写 66 条 map rule，并写出一条
   `namei_ext-update` raw row 和一条 `bench_map_update` row。
5. `mk/report.mk` 的 hard gate 从“各 1 条”改为“各 `SAMPLES` 条”，并检查 sample id 落在
   `[0, SAMPLES)`。
6. `mk/eval_osdi.mk` 的 C2 release sample budget 用唯一 sample id 计数，而不是只看 row
   count，避免重复写同一个 sample id 误过。

## 不做的事

- 不把 C2 标记为 supported。
- 不新增 shell 脚本；所有验证仍通过 Make target。
- 不把 W1--W4 workload-specific macrobench 混入本小步。
- 不改变 kernel ABI 或 policy ABI。

## 验证计划

- `make bench`
- `make kvm-bench RUN_ID=20260615T-kvm-bench-c2-repetition-smoke-v1 SAMPLES=2 BENCH_ITERS=100 BENCH_LATENCY_SAMPLES=0`
- `make eval-osdi-macrobench-ledger RUN_ID=20260615T-eval-c2-repetition-smoke-v1 EVAL_OSDI_PHASE1_RUN_ID=20260615T-kvm-bench-c2-repetition-smoke-v1 EVAL_OSDI_MACROBENCH_BASELINE_RUN_ID=20260615T-kvm-external-baselines-batch64-v1`
- `git diff --check`

