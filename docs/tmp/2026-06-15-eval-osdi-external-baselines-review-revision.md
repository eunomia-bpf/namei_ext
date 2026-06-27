# External baseline scoped review 修复记录

Last updated: 2026-06-15
Stage at update: Phase 1 implementation review / OSDI baseline revision
Source/command: subagent Aquinas scoped review plus reruns listed below
Completeness: partial

## Review verdict

独立 subagent verdict：scoped Weak Accept。结论是 external baseline smoke
infrastructure 成立，但不能作为 C2/C3/C5 release performance evidence。

## P1 finding 和修复

P1 finding：baseline update 后只写入 `tool-updated\n`，但 measured ops 只覆盖
`stat/open/access/exec/readdir/tree stat`。`open()` 不读取内容，因此 stale alias 也可能
通过 smoke。

修复：

- `bench/workloads/namei_ext_baselines.c` 新增 `struct content_ctx` 和
  `op_read_content()`；
- `run_suite()` 新增 `read_tool_content` benchmark；
- `op_read_content()` 读取 alias 内容并要求等于 `tool-updated\n`；
- `mk/eval_osdi.mk` baseline ledger 新增 `content_rows` 和
  `has_update_content_oracle`；
- `qualified_for_baseline_smoke` 现在要求每个 baseline 至少有一个
  `read_tool_content` row。

验证：

```text
make bench
```

通过。

本地 sanity：

```text
.build/bench-workloads/namei_ext_baselines /tmp/namei_ext_baseline_sanity_v2.jsonl \
  sanity-v2 1 20 1 2 'copy_tree symlink_forest'
```

结果：`content_rows=2`、`failures=0`。

KVM rerun：

```text
make eval-osdi-baselines RUN_ID=20260615T-kvm-external-baselines-content-v1 \
  BASELINE_SAMPLES=1 BASELINE_ITERS=50 BASELINE_LATENCY_SAMPLES=1 \
  BASELINE_LATENCY_BATCH=2
```

关键 ledger：

```text
raw_rows=78
bench_rows=32
latency_rows=32
baselines_selected=4
baselines_passed=4
runner_failures=0
has_copy_tree_baseline=true
has_symlink_forest_baseline=true
has_bind_mount_baseline=true
has_overlayfs_baseline=true
has_fuse_redirect_baseline=false
baseline_smoke_gate_pass=true
release_gate_pass=false
```

每个 baseline row：

```text
bench_rows=8
content_rows=1
has_update_content_oracle=true
qualified_for_baseline_smoke=true
failing_ops=0
```

## P2 findings 和修复

### set_path error propagation

P2 finding：若干 setup path 用 chained `set_path(...) || mkdir_one(...)`，失败时
`return -errno` 可能丢失 `set_path()` 返回的 `-ENAMETOOLONG`。

修复：

- `create_common_non_overlay()` 和 `setup_overlayfs()` 改为逐步保存 `ret` 并直接
  return；
- `cleanup_env()` 现在保留 `rm_rf()` 的原始负错误码。

### baseline manifest dirty provenance

P2 finding：baseline manifest 只记录 HEAD，不记录 dirty 状态。

修复：

- `eval-osdi-baselines` manifest 的 `main_repo` 和 `kernel_repo` 增加 `dirty` 字段。

验证结果：

```text
main_repo.dirty=true
kernel_repo.dirty=true
```

### dmesg hard gate

P2 finding：`kvm-eval-osdi-baselines` 只保存 dmesg，没有对 BUG/WARNING/Oops/panic
模式 hard gate。

修复：

- guest target 在 runner 结束后保存 `dmesg-baselines.log`；
- 使用与 Phase 1 report 一致的 awk pattern 检查
  `BUG:|WARNING:|Oops:|Kernel panic|panic:|hung task|kernel BUG at`；
- dmesg issue 非 0 时 target fail。

## Performance ledger after revision

重新接入 performance ledger：

```text
make eval-osdi-performance-ledger \
  RUN_ID=20260615T-eval-ledger-content-baselines \
  EVAL_OSDI_PHASE1_RUN_ID=20260615T-full-phase1-bench-variants \
  EVAL_OSDI_PERFORMANCE_BASELINE_RUN_ID=20260615T-kvm-external-baselines-content-v1
```

关键结果：

```text
baseline_run_id=20260615T-kvm-external-baselines-content-v1
has_copy_tree_baseline=true
has_symlink_forest_baseline=true
has_bind_mount_baseline=true
has_overlayfs_baseline=true
has_fuse_redirect_baseline=false
missing_release_baselines=["fuse_redirect"]
release_gate_pass=false
```

## Remaining blockers

- FUSE redirect baseline 仍未实现。
- baseline 和 policy 的 release repetitions 仍未跑。
- canonical full Phase 1 root 仍没有 `bench_latency` rows。
- 仍缺 randomized run order 和 system metrics。
- W1-W4 workload-level setup/update/storage accounting 仍未完成。

## Final validation

release hard gate expected-fail：

```text
make eval-osdi-performance \
  RUN_ID=20260615T-eval-ledger-content-baselines-hardgate \
  EVAL_OSDI_PHASE1_RUN_ID=20260615T-full-phase1-bench-variants \
  EVAL_OSDI_PERFORMANCE_BASELINE_RUN_ID=20260615T-kvm-external-baselines-content-v1
```

结果：按预期失败在最终 jq hard gate，说明 C2/C3/C5 没有被 smoke baseline 放宽。

其他检查：

```text
git diff --check
make -C docs/paper check paper
awk '/] (BUG:|WARNING:|Oops:|Kernel panic|panic:|hung task)|kernel BUG at/ { n++ } END { print n + 0 }' \
  results/eval-osdi/baselines/20260615T-kvm-external-baselines-content-v1/dmesg-baselines.log
```

结果：

```text
git diff --check: pass
docs/paper check paper: pass
dmesg issue count: 0
```

## Subagent re-review

第二轮只读复审 verdict：scoped Weak Accept。

复审结论：

- P0：无。
- P1：已修复。`read_tool_content` 会读取 alias 并精确比对 `tool-updated\n`；
  `20260615T-kvm-external-baselines-content-v1` 的四个 baseline 均有
  `content_rows=1`、`has_update_content_oracle=true`、`failing_ops=0`。
- P2：已修复。`set_path` 错误码不再通过 chained expression 丢失；baseline manifest
  记录 main/kernel dirty；`kvm-eval-osdi-baselines` 已对 dmesg BUG/WARNING/Oops/panic
  模式 hard gate。
- Overclaim：未见。baseline 仍只声明 smoke pass，performance ledger 仍为
  `release_gate_pass=false` 和 `qualified_for_c2_c3_c5=false`。

复审仍保留的 release blockers：

- FUSE redirect baseline 缺失；
- `samples=1`，未达 `required_paper_samples=20`；
- canonical full root 无 raw latency rows、tail/CI artifact；
- 缺 randomized order 和 system metrics；
- 缺 W1-W4 workload-level setup/update/storage accounting。
