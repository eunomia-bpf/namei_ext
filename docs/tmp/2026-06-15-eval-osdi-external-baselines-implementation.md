# OSDI external baseline KVM smoke 实现记录

Last updated: 2026-06-15
Stage at update: Phase 1 implementation / OSDI performance baseline plumbing
Source/command: `make eval-osdi-baselines RUN_ID=20260615T-kvm-external-baselines-smoke-v4 BASELINE_SAMPLES=1 BASELINE_ITERS=50 BASELINE_LATENCY_SAMPLES=1 BASELINE_LATENCY_BATCH=2`
Completeness: partial

## 动机

B2/B8 performance ledger 之前只能看到 `baseline`、`pass_only`、`table_redirect_empty`、
`table_redirect_hit` 和 `policy` 这些项目内变体。它能证明 modified kernel KVM
microbenchmark plumbing，但不能回答 OSDI reviewer 会问的外部 baseline 问题：

- 复制 materialization 的 setup/storage/update 成本是多少？
- symlink forest 是否已经足够？
- bind mount fanout 是否能用现有 kernel path 表达同样 view？
- OverlayFS 这类已有 kernel view 机制是否能作为强 baseline？
- FUSE redirectfs 是否仍缺，是否不能把缺失项写成 pass？

本步骤的目标是补一个最小、Makefile-owned、KVM 内运行的 external baseline
infrastructure。它只产生 raw observations 和 derived ledger，不把 smoke 结果升级成
release 性能结论。

## 调研和读取的代码

- `bench/workloads/namei_ext_bench.c`：复用同一组 realistic VFS 操作语义：
  `stat/open/access/exec/readdir/tree stat walk`。
- `bench/workloads/Makefile`：确认 benchmark binary 构建入口，新增 runner 必须由
  `make bench` 构建。
- `mk/kvm.mk`：复用现有 `vng --run $(KERNEL_IMAGE)` KVM 启动模式；Phase 1
  validation 不能用 host-only run 计数。
- `mk/eval_osdi.mk`：现有 B2/B8 ledger 已有 tail-latency artifact 和 hard gate，
  新 baseline evidence 必须接入这里，但不能放宽 release gate。
- `configs/benchmarks/phase1.mk`：新增默认 baseline knobs，避免依赖 shell history。

## 设计选择

新增 `bench/workloads/namei_ext_baselines.c`，它不 attach BPF，不链接 libbpf。每个
baseline 都在独立临时 root 中构造同一组 alias view，然后跑与 `namei_ext_bench`
一致的 VFS 操作：

- `copy_tree`：把 backing file materialize 到 alias path，记录 copied bytes 和
  update copy writes。
- `symlink_forest`：用 symlink 指向 backing，记录 symlink 数量，source update 不需要
  alias rewrite。
- `bind_mount`：把 backing file bind 到 alias path，记录 mount 数量。
- `overlayfs`：用 OverlayFS merged view 呈现 alias，记录一个 overlay mount 和 copied
  bytes。

runner 只写 raw JSONL：

- `baseline-start`
- `baseline-setup`
- `baseline-update`
- `baseline`
- `baseline_latency`
- `baseline-cleanup`
- `baseline-summary`

`make eval-osdi-baselines` 再写 derived artifacts：

- `baseline-ledger.jsonl`
- `baseline-inputs.sha256`
- `manifest.json`
- `summary.md`

`mk/eval_osdi.mk` 增加 `EVAL_OSDI_PERFORMANCE_BASELINE_RUN_ID`，让
`eval-osdi-performance-ledger` 能读取 external baseline ledger，并把
copy/symlink/bind/OverlayFS 的 presence 写入 B2/B8 performance row。hard gate 仍固定为
false，直到 release repetitions、tail/CI、随机化顺序、系统指标和 FUSE baseline 都存在。

## 备选方案和拒绝原因

- 在 `namei_ext_bench.c` 中直接塞外部 baseline：拒绝。该 runner 强绑定 BPF attach
  path；外部 filesystem baseline 不应依赖 BPF policy 才能运行。
- 用 shell 脚本拼 mount/copy/symlink：拒绝。项目规则要求 project-owned orchestration
  Makefile-only，不能新增 checked-in `.sh` 控制面。
- 默认声明 FUSE 但让其 skipped：拒绝。缺失 capability 必须 hard fail 或保持未声明；
  当前默认只声明能在 KVM 内实现并通过的四个 baseline，FUSE 明确保留为 missing
  release baseline。
- 把 smoke baseline 直接计入 C2/C3/C5：拒绝。当前只有 1 sample，且 canonical
  Phase 1 root 没有 raw `bench_latency` rows、随机化顺序和系统指标。

## 实现细节

- `bench/workloads/namei_ext_baselines.c`
  - 每个 baseline 独立创建临时树；
  - 默认通过 `NAMEI_EXT_BASELINE_TMPDIR` 选择 scratch root；
  - `copy_tree`/`overlayfs` 记录 bytes copied 和 update bytes；
  - `symlink_forest`/`bind_mount` 记录 source update 不需要 alias rewrite；
  - `bind_mount` 和 `overlayfs` cleanup 会反向 `umount2(..., MNT_DETACH)`；
  - unsupported baseline token 会输出 failing `baseline-setup` row 并返回非零。
- `mk/kvm.mk`
  - 新增 `kvm-eval-osdi-baselines` 和 guest target；
  - 在 guest 中挂载 `/run/namei-ext-baselines` tmpfs，避免 virtme-ng `/tmp` rw overlay
    不能作为 OverlayFS upperdir；
  - runner 失败时仍抓取 `dmesg-baselines.log`，随后保持 target 失败。
- `configs/benchmarks/phase1.mk`
  - 新增 `BASELINE_SAMPLES`、`BASELINE_ITERS`、`BASELINE_LATENCY_SAMPLES`、
    `BASELINE_LATENCY_BATCH` 和 `EVAL_OSDI_BASELINES`。
- `mk/eval_osdi.mk`
  - 新增 `eval-osdi-baselines`；
  - performance ledger 接入 baseline run id；
  - missing baseline list 现在由真实 ledger flags 生成。

## 验证记录

本地编译：

```text
make bench
```

通过，新增 `.build/bench-workloads/namei_ext_baselines`。

本地非特权 sanity：

```text
.build/bench-workloads/namei_ext_baselines /tmp/namei_ext_baseline_sanity.jsonl sanity 1 20 1 2 'copy_tree symlink_forest'
```

copy/symlink subset 0 failure。

KVM OverlayFS 初次失败：

```text
make kvm-eval-osdi-baselines RUN_ID=20260615T-kvm-overlayfs-diagnose \
  BASELINE_SAMPLES=1 BASELINE_ITERS=10 BASELINE_LATENCY_SAMPLES=0 \
  EVAL_OSDI_BASELINES=overlayfs
```

失败原因来自 dmesg：

```text
overlay: filesystem on /tmp/namei-ext-baseline-.../upper not supported as upperdir
```

修复后改用 guest tmpfs scratch root，OverlayFS 单项通过：

```text
make kvm-eval-osdi-baselines RUN_ID=20260615T-kvm-overlayfs-tmpfs \
  BASELINE_SAMPLES=1 BASELINE_ITERS=10 BASELINE_LATENCY_SAMPLES=0 \
  EVAL_OSDI_BASELINES=overlayfs
```

完整 external baseline smoke 初版通过：

```text
make eval-osdi-baselines RUN_ID=20260615T-kvm-external-baselines-smoke-v4 \
  BASELINE_SAMPLES=1 BASELINE_ITERS=50 BASELINE_LATENCY_SAMPLES=1 \
  BASELINE_LATENCY_BATCH=2
```

关键结果：

```text
raw_rows=70
bench_rows=28
latency_rows=28
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

接入 performance ledger：

```text
make eval-osdi-performance-ledger \
  RUN_ID=20260615T-eval-ledger-with-baselines-smoke \
  EVAL_OSDI_PHASE1_RUN_ID=20260615T-full-phase1-bench-variants \
  EVAL_OSDI_PERFORMANCE_BASELINE_RUN_ID=20260615T-kvm-external-baselines-smoke-v4
```

关键结果：

```text
copy_tree=true
symlink_forest=true
bind_mount=true
overlayfs=true
fuse_redirect=false
missing_release_baselines=["fuse_redirect"]
release_gate_pass=false
has_tail_latency_artifact=false
has_confidence_interval=false
```

subagent scoped review 后发现 P1：update 后只做 stat/open/access/exec/readdir/tree stat，
没有读取 alias 内容，stale alias 也可能通过 smoke。修复后新增 `read_tool_content`
content oracle，并重新运行：

```text
make eval-osdi-baselines RUN_ID=20260615T-kvm-external-baselines-content-v1 \
  BASELINE_SAMPLES=1 BASELINE_ITERS=50 BASELINE_LATENCY_SAMPLES=1 \
  BASELINE_LATENCY_BATCH=2
```

关键结果：

```text
raw_rows=78
bench_rows=32
latency_rows=32
baselines_selected=4
baselines_passed=4
runner_failures=0
content_rows=1 per baseline
has_update_content_oracle=true per baseline
baseline_smoke_gate_pass=true
release_gate_pass=false
```

新的 performance ledger：

```text
make eval-osdi-performance-ledger \
  RUN_ID=20260615T-eval-ledger-content-baselines \
  EVAL_OSDI_PHASE1_RUN_ID=20260615T-full-phase1-bench-variants \
  EVAL_OSDI_PERFORMANCE_BASELINE_RUN_ID=20260615T-kvm-external-baselines-content-v1
```

仍保持 `missing_release_baselines=["fuse_redirect"]` 和 `release_gate_pass=false`。

release hard gate 仍按预期失败：

```text
make eval-osdi-performance \
  RUN_ID=20260615T-eval-ledger-with-baselines-smoke-hardgate \
  EVAL_OSDI_PHASE1_RUN_ID=20260615T-full-phase1-bench-variants \
  EVAL_OSDI_PERFORMANCE_BASELINE_RUN_ID=20260615T-kvm-external-baselines-smoke-v4
```

失败点是 `eval-osdi-performance` 的最终 jq hard gate：`release_gate_pass`、
`c2_supported`、`c3_supported` 和 `c5_supported` 仍为 false。

## 剩余风险和后续工作

- FUSE redirectfs baseline 仍未实现，不能声称 external baseline suite 完整。
- 当前 baseline run 是 smoke：`BASELINE_SAMPLES=1`，不能支撑 C2/C3/C5 性能 claim。
- canonical full Phase 1 root 仍没有 raw `bench_latency` rows，因此 performance tail
  artifact 在 release ledger 中仍为 false。
- 还没有 randomized run order、CPU/context-switch/memory/disk metrics。
- copy/symlink/bind/OverlayFS 目前只覆盖 microbench alias view；后续还要接真实
  W1-W4 workload-level setup/update/storage accounting。
