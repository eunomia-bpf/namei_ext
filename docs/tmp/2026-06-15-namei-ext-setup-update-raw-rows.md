# namei_ext setup/update 原始行

日期：2026-06-15
阶段：Phase 1 实现记录
状态：实现已完成，release comparison 仍缺失

## 动机

C2 之前只记录了 microbenchmark open/stat/access/exec/readdir 等 steady-state path walk
成本，以及外部 baseline 的 setup/update smoke rows。OSDI evaluation audit 指出这不足以
支撑 setup/storage/update claim：`namei_ext` 自身也必须在修改内核 KVM 内输出原始
setup/update 观测，且这些观测必须先作为 raw rows 保存，不能在 collector 内直接解释成
paper 结论。

本步骤的目标很窄：把 Phase 1 bench runner 中已有的 backing tree 创建、source backing
更新和 table map population 显式记录成 `namei_ext.eval_osdi.namei_ext_raw.v1` rows。
这不是 C2 release macrobench，也不与 copy/symlink/bind/OverlayFS/FUSE 做等价比较。

## 检查过的文件

- `bench/workloads/namei_ext_bench.c`
- `mk/kvm.mk`
- `mk/report.mk`
- `configs/benchmarks/phase1.mk`
- `results/phase1/20260615T-full-phase1-c2-setup-update-v1/bench.jsonl`

## 实现

`bench/workloads/namei_ext_bench.c` 新增三类 raw rows：

- `namei_ext-setup`：记录 `backing_tree` setup 的 KVM run id、环境、耗时、创建目录数、
  创建文件数、写入字节数，以及 symlink/bind/overlay/fuse/copy 计数。当前 full run 中
  为 `created_dirs=67`、`created_files=66`、`bytes_written=132`。
- `namei_ext-update` / `backing_tree`：记录 source backing 文件更新。当前 full run 中为
  `source_update_writes=65`、`policy_update_writes=0`、`update_bytes_written=845`。
- `namei_ext-update` / `table_redirect_hit`：记录 table policy map population。当前 full
  run 中为 `source_update_writes=0`、`policy_update_writes=66`、`update_bytes_written=0`。

`mk/kvm.mk` 在 guest bench target 中传入 `NAMEI_EXT_RUN_ID="$(RUN_ID)"`，保证 raw rows
能和 Phase 1 result root 对齐。

`mk/report.mk` 的 Phase 1 report gate 新增 hard checks，要求 full Phase 1 root 中存在：

- 一个 KVM `namei_ext-setup` row，`variant=="backing_tree"` 且创建 67 个目录、66 个文件；
- 一个 source update row，`source_update_writes==65`、`policy_update_writes==0`；
- 一个 table update row，`source_update_writes==0`、`policy_update_writes==66`。

## 验证

本步骤已运行：

```text
make bench
make kvm-bench RUN_ID=20260615T-kvm-bench-namei-ext-setup-update-smoke-v1 SAMPLES=1 BENCH_ITERS=200 BENCH_LATENCY_SAMPLES=1 BENCH_LATENCY_BATCH=64 BENCH_RANDOMIZE_ORDER=1
make phase1 RUN_ID=20260615T-full-phase1-c2-setup-update-v1
make eval-osdi-policy-family-ledger RUN_ID=20260615T-eval-b12-c2-setup-update-v1 EVAL_OSDI_PHASE1_RUN_ID=20260615T-full-phase1-c2-setup-update-v1
make eval-osdi-policy-family RUN_ID=20260615T-eval-b12-c2-setup-update-hardgate-v1 EVAL_OSDI_PHASE1_RUN_ID=20260615T-full-phase1-c2-setup-update-v1
```

结果：

- `make bench` 通过。
- `make kvm-bench ...setup-update-smoke-v1` 通过，并产生 1 条 setup row、2 条 update rows。
- `make phase1 ...c2-setup-update-v1` 完整通过，result root 为
  `results/phase1/20260615T-full-phase1-c2-setup-update-v1/`。
- B12 ledger over 新 root 通过写出：
  `results/eval-osdi/paper/20260615T-eval-b12-c2-setup-update-v1/b12-policy-family/policy-family.jsonl`。
- B12 hard gate 按预期失败，因为 `qualified_families=0`、`release_gate_pass=false`。

## 结论

这一步只解决 C2 的一个输入缺口：`namei_ext` 侧 raw setup/update rows 现在进入
Makefile-owned KVM Phase 1 root，并由 report gate 强制存在。

这一步不支持 C2 release claim。仍缺：

- 同 workload 的 setup/storage/update macrobench comparison；
- copy tree、symlink forest、bind mount、OverlayFS、FUSE/projected-volume 等 feature-equivalent
  baselines 的同口径比较；
- 多次重复、CI/tail、资源指标和输出正确性 oracle；
- W1--W4 macrobench 级别的 release result table。

因此 claim verdict 应更新为：C2 仍 unsupported，但 blocker 从“完全缺 namei_ext raw
setup/update rows”缩小为“缺 release macrobench comparison”。
