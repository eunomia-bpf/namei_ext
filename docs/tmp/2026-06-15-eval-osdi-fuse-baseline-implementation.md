# FUSE Redirect External Baseline 实现记录

Last updated: 2026-06-15
Stage at update: execute
Source/command: `make eval-osdi-baselines RUN_ID=20260615T-kvm-external-baselines-fuse-smoke-v2 BASELINE_SAMPLES=1 BASELINE_ITERS=50 BASELINE_LATENCY_SAMPLES=1 BASELINE_LATENCY_BATCH=2`
Completeness: partial

## 动机

B2/B8 performance gate 需要 named external baselines。上一轮只完成了
copy tree、symlink forest、bind mount 和 OverlayFS 的 KVM smoke rows，performance
ledger 仍记录 `missing_release_baselines=["fuse_redirect"]`。这会让 OSDI 评审认为
用户态 path-remapping filesystem 对照缺失，无法支持“内核内 programmable
path-resolution extension point 相对用户态 FUSE path resolver 的性能/语义取舍”。

本步骤目标是补齐 FUSE redirect baseline，但仍保持代码量最小、Makefile-only
orchestration、KVM 修改内核验证和 fail-fast。

## 调研和检查的代码路径

- `bench/workloads/namei_ext_baselines.c`：现有 external baseline runner，负责 raw
  baseline JSONL、setup/update/content oracle、cleanup 和 microbench operations。
- `bench/workloads/Makefile`：runner 构建入口。
- `mk/kvm.mk`：`kvm-eval-osdi-baselines` 和 `__eval_osdi_guest_baselines`，负责 boot
  修改内核、tmpfs scratch root、raw JSONL、dmesg hard gate。
- `mk/eval_osdi.mk`：`eval-osdi-baselines` ledger、manifest、summary，以及
  `eval-osdi-performance-ledger` 的 baseline linkage。
- `configs/benchmarks/phase1.mk`：external baseline 默认列表。
- `configs/kernel/x86_64_phase1.config` 和 `mk/kernel.mk`：KVM bzImage 的基础设施即代码。
- `/usr/include/fuse.h`、`/usr/include/fuse/fuse.h`：本机 libfuse2 high-level API。

## 设计选择

FUSE baseline 是一个项目内最小 high-level libfuse filesystem，直接编进
`namei_ext_baselines` runner：

- visible path `/tool` 映射到 backing path `tool.real`；
- visible path `tree/include/pkgXX/tool` 映射到对应 backing file；
- `/native` 映射到独立 backing file，用来保留 native lookup 对照；
- `readdir("/")` 只暴露 `native`、`tool`、`tree`，不暴露 `tool.real`；
- update 阶段只写 backing file，随后 `read_tool_content` 必须从 visible alias 读到
  `tool-updated\n`；
- 每个 FUSE setup row 记录 `fuse_mounts=1`，ledger 要求 FUSE row 的
  `qualified_for_baseline_smoke=true` 且 `fuse_mounts>0`。

这样 FUSE baseline 不是一次性 materialization，也不是 symlink/bind 的别名包装，而是
真实走 Linux FUSE kernel module 和用户态 daemon 的 path-remapping 对照。

## 拒绝的替代方案

- 只把 `fuse_redirect` 加入 missing-baseline 白名单：会把缺失能力伪装成通过，违反
  fail-fast。
- 使用项目外 shell script 启动 FUSE daemon：违反 Makefile-only orchestration。
- 依赖 guest 内 `modprobe fuse`：当前 KVM 使用 `--skip-modules`，Phase 1 要求配置写入
  文件，因此改为 `CONFIG_FUSE_FS=y`。
- 手写 `/dev/fuse` 协议：可行但代码量更大；libfuse high-level API 已足够表达本 baseline
  的真实 VFS path。
- 让 FUSE baseline 复用 symlink forest：不能证明用户态 resolver baseline。

## 实现细节

- `bench/workloads/namei_ext_baselines.c`
  - 新增 `fuse_redirect` baseline definition；
  - 新增 FUSE callbacks：`getattr`、`access`、`open`、`read`、`release`、`readdir`；
  - 新增 `fuse_mounts` raw setup counter；
  - cleanup 先 `umount2(MNT_DETACH)`，非 root FUSE mount 再用 `fusermount3 -u -z`
    或 `fusermount -u -z` 作为无 shell fallback；
  - 保留 unsupported 写入/创建为失败，不实现伪成功。
- `bench/workloads/Makefile`
  - `namei_ext_baselines` 使用 `-D_FILE_OFFSET_BITS=64 -I/usr/include/fuse -lfuse -pthread`。
- `Dockerfile`
  - 增加 `libfuse-dev` 和 `fuse3`，让镜像内声明构建/运行依赖。
- `configs/benchmarks/phase1.mk`
  - 默认 `EVAL_OSDI_BASELINES` 扩为 `copy_tree symlink_forest bind_mount overlayfs fuse_redirect`。
- `configs/kernel/x86_64_phase1.config`
  - 新增 `CONFIG_FUSE_FS=y`。
- `mk/kernel.mk`
  - `kernel-config` 检查 `CONFIG_FUSE_FS=y`；
  - `kernel-objects` 和 `$(KERNEL_IMAGE)` 显式依赖 `.config`，避免 `.config` 更新而
    bzImage 未重建。
- `mk/eval_osdi.mk`
  - `EVAL_OSDI_REQUIRED_BASELINES=5`；
  - baseline ledger 输出 FUSE row 和 `fuse_mounts`；
  - summary 中 `has_fuse_redirect_baseline` 由 FUSE row 和 `fuse_mounts>0` 决定；
  - performance ledger 现在能读取 5-baseline ledger 并清空 `missing_release_baselines`。

## 验证

本地非 Phase 1 sanity：

```text
.build/bench-workloads/namei_ext_baselines \
  /tmp/namei_ext_fuse_baseline_sanity.jsonl sanity-fuse-v2 \
  1 20 1 2 fuse_redirect
```

结果：`baseline-summary.pass=true`，FUSE setup row 有 `fuse_mounts=1`，
`read_tool_content` 为 `ok=20, fail=0`，cleanup 后无残留 FUSE mount/daemon。

第一次 KVM 尝试：

```text
make eval-osdi-baselines RUN_ID=20260615T-kvm-external-baselines-fuse-smoke-v1 \
  BASELINE_SAMPLES=1 BASELINE_ITERS=50 BASELINE_LATENCY_SAMPLES=1 \
  BASELINE_LATENCY_BATCH=2
```

结果：失败，guest 中 FUSE daemon 报错 `fuse: device not found, try 'modprobe fuse'
first`。根因是 `.build/kernel/.config` 中 `CONFIG_FUSE_FS` unset，且 vng 使用
`--skip-modules`。该失败被保留为 R011。

修复后重新生成 config 并重建 bzImage：

```text
make kernel-config
make kernel
```

关键证据：

```text
CONFIG_FUSE_FS=y
fs/fuse/built-in.a
Kernel: arch/x86/boot/bzImage is ready (#4)
```

通过的 KVM baseline smoke：

```text
make eval-osdi-baselines RUN_ID=20260615T-kvm-external-baselines-fuse-smoke-v2 \
  BASELINE_SAMPLES=1 BASELINE_ITERS=50 BASELINE_LATENCY_SAMPLES=1 \
  BASELINE_LATENCY_BATCH=2
```

关键 ledger：

```text
raw_rows=97
bench_rows=40
latency_rows=40
baselines_selected=5
baselines_passed=5
runner_failures=0
has_copy_tree_baseline=true
has_symlink_forest_baseline=true
has_bind_mount_baseline=true
has_overlayfs_baseline=true
has_fuse_redirect_baseline=true
missing_release_baselines=[]
baseline_smoke_gate_pass=true
release_gate_pass=false
```

FUSE row：

```text
baseline=fuse_redirect
setup_pass=true
update_pass=true
cleanup_pass=true
fuse_mounts=1
content_rows=1
latency_rows=8
failing_ops=0
qualified_for_baseline_smoke=true
```

dmesg hard gate：0 issue。

performance ledger linkage：

```text
make eval-osdi-performance-ledger \
  RUN_ID=20260615T-eval-ledger-fuse-baselines-smoke \
  EVAL_OSDI_PHASE1_RUN_ID=20260615T-full-phase1-bench-variants \
  EVAL_OSDI_PERFORMANCE_BASELINE_RUN_ID=20260615T-kvm-external-baselines-fuse-smoke-v2
```

结果：copy/symlink/bind/OverlayFS/FUSE baseline flags 全为 true，
`missing_release_baselines=[]`，但 `release_gate_pass=false`。

hard gate expected-fail：

```text
make eval-osdi-performance \
  RUN_ID=20260615T-eval-ledger-fuse-baselines-hardgate \
  EVAL_OSDI_PHASE1_RUN_ID=20260615T-full-phase1-bench-variants \
  EVAL_OSDI_PERFORMANCE_BASELINE_RUN_ID=20260615T-kvm-external-baselines-fuse-smoke-v2
```

结果：最终 jq hard gate 按预期失败，因为 release repetitions、tail/CI、随机化顺序和系统指标仍缺。

## 剩余风险和后续工作

- 该 run 仍是 smoke：`BASELINE_SAMPLES=1`，不能支撑 C2/C3/C5 release performance claim。
- canonical full Phase 1 root `20260615T-full-phase1-bench-variants` 仍无 raw
  `bench_latency` rows，因此 performance tail/CI artifact 仍为 false。
- baseline runner 还没有 randomized run order 和 system metrics capture。
- FUSE baseline 只覆盖当前 microbench alias view；后续需要扩展到 W1-W4 workload-level
  setup/update/storage accounting。
- `Dockerfile` 已声明 FUSE 依赖，但本步骤未运行 Docker build/smoke。
