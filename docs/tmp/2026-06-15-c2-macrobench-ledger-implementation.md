# C2 macrobench ledger 实现

日期：2026-06-15
阶段：Phase 1 实现记录
状态：ledger 已实现，hard gate 按预期失败

## 动机

在 `namei_ext` setup/update raw rows 进入 KVM full Phase 1 root 之后，C2 仍然不能直接升级。
原因是 OSDI 级 C2 需要同 workload 的 setup/storage/update macrobench comparison：至少要把
`namei_ext` 自身的 setup/update 原始观测和 copy tree、symlink forest、bind mount、
OverlayFS、FUSE redirect 等 feature-equivalent baselines 放在同一份 release contract
里，并且明确区分 raw-input plumbing 和 claim support。

本步骤新增一个最小 Makefile-owned ledger：

- `make eval-osdi-macrobench-ledger`
- `make eval-osdi-macrobench`

前者写出 C2 macrobench contract；后者是 hard gate，只有 summary 同时满足
`release_gate_pass=true` 和 `c2_supported=true` 才能通过。当前 hard gate 应该失败。

## 检查过的文件

- `mk/eval_osdi.mk`
- `bench/workloads/namei_ext_bench.c`
- `bench/workloads/namei_ext_baselines.c`
- `results/phase1/20260615T-full-phase1-c2-setup-update-v1/bench.jsonl`
- `results/eval-osdi/baselines/20260615T-kvm-external-baselines-batch64-v1/baseline-ledger.jsonl`

## 实现

`mk/eval_osdi.mk` 新增 B3-B6/C2 macrobench 变量：

- `EVAL_OSDI_MACROBENCH_DIR`
- `EVAL_OSDI_MACROBENCH_JSON`
- `EVAL_OSDI_MACROBENCH_INPUTS_SHA256`
- `EVAL_OSDI_MACROBENCH_SUMMARY`
- `EVAL_OSDI_MACROBENCH_MANIFEST`
- `EVAL_OSDI_MACROBENCH_BASELINE_RUN_ID`
- `EVAL_OSDI_MACROBENCH_BASELINE_LEDGER_JSON`

`eval-osdi-macrobench-ledger` 只读既有 result roots，不重新运行 KVM。它要求：

- Phase 1 root 中存在 `bench.jsonl`、`summary.md`、`metadata.json`；
- baseline root 中存在 `baseline-ledger.jsonl` 和 `baseline-inputs.sha256`；
- 输入文件写入 `macrobench-inputs.sha256` 并通过 `sha256sum -c`。

ledger 输出三类 JSONL row：

- `eval-osdi-macrobench-namei-ext`：记录 `namei_ext-setup`、source update、policy update
  rows 的计数和原始字段。
- `eval-osdi-macrobench-baseline`：逐 baseline 记录 setup/update 时间、文件数、symlink、
  bind/overlay/fuse mount 计数、copy/update 写入量，并计算相对当前 `namei_ext` raw row
  的 setup/update 比值。
- `eval-osdi-macrobench-summary`：汇总 C2 gate。当前必须满足 release sample budget、
  baseline release gate、W1-W4 workload-equivalent macrobench 和明确阈值，才可能支持 C2。

## 验证

本步骤已运行：

```text
make eval-osdi-macrobench-ledger RUN_ID=20260615T-eval-c2-macrobench-ledger-v1 EVAL_OSDI_PHASE1_RUN_ID=20260615T-full-phase1-c2-setup-update-v1 EVAL_OSDI_MACROBENCH_BASELINE_RUN_ID=20260615T-kvm-external-baselines-batch64-v1
make eval-osdi-macrobench RUN_ID=20260615T-eval-c2-macrobench-hardgate-v1 EVAL_OSDI_PHASE1_RUN_ID=20260615T-full-phase1-c2-setup-update-v1 EVAL_OSDI_MACROBENCH_BASELINE_RUN_ID=20260615T-kvm-external-baselines-batch64-v1
```

结果：

- ledger target 通过，输出：
  `results/eval-osdi/paper/20260615T-eval-c2-macrobench-ledger-v1/b3-macrobench/macrobench.jsonl`。
- summary 中 `namei_ext_raw_gate_pass=true`。
- summary 中 `baseline_release_gate_pass=true`、`baselines_release_passed=5`。
- summary 中 `namei_ext_release_sample_budget_pass=false`，因为当前 `namei_ext` setup/update
  rows 只有 1 组，而 release contract 要求 20 组。
- summary 中 `macrobench_input_gate_pass=false`、`c2_supported=false`、
  `release_gate_pass=false`。
- hard gate 按预期失败，输出：
  `results/eval-osdi/paper/20260615T-eval-c2-macrobench-hardgate-v1/b3-macrobench/macrobench.jsonl`。

## 结论

这一步把 C2 从“缺少 ledger”推进到“有 fail-fast release contract”。当前它提供的是负面
gate evidence：`namei_ext` raw setup/update rows 和 external baseline release rows 都能被
同一份 ledger 读取，但样本预算、W1-W4 workload-equivalent macrobench 和 C2 成功阈值仍缺失。

下一步如果继续 C2，需要让 `namei_ext` setup/update 以 release repetition 方式运行，并把
W1--W4 workload-specific setup/storage/update 成本纳入同一 schema；否则论文只能声明
Phase 1 raw plumbing，不能声明 materialization/setup/update advantage。
