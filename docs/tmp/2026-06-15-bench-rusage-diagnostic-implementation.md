# bench rusage 诊断指标实现记录

Last updated: 2026-06-15
Stage at update: implementation/execute
Source/command: `bench/workloads/namei_ext_bench.c` raw collector update; `make bench`; `make kvm-bench RUN_ID=20260615T-kvm-bench-rusage-smoke-v1 ...`
Completeness: complete

## 动机

tail10 诊断已经显示 FUSE speedup gate 不再是主要 blocker，真正失败点是
`pass_only`、`readdir_alias_view` 和 `build_tree_stat_walk` 的 tail residual。
现有 `kvm-bench` 只在整个 benchmark 前后保存 `/proc/stat`、`/proc/vmstat`、
`/proc/meminfo` 和 `/proc/diskstats`，不能回答某个 bench/variant/sample 的 tail
是否伴随 CPU 时间、page fault 或 context switch 异常。

本步骤不改变 kernel ABI、eBPF policy、attach path 或 Make target，只在 raw
collector 的 `bench` 和 `bench_latency` JSONL 行中增加 per-batch `getrusage()`
delta。目标是给后续 no-hook/pass-only 归因提供原始观测，而不是在 collector 中计算论文结论。

## 设计选择

- 使用 `getrusage(RUSAGE_SELF)` 记录当前 benchmark 进程的 user/sys CPU、minor/major
  faults、voluntary/involuntary context switches。
- 同时记录 `getrusage(RUSAGE_CHILDREN)` delta，因为 `exec_tool_redirect` 会 fork 子进程；
  child delta 可以避免把 exec 子进程成本误判为 namei_ext lookup 本身。
- 指标写入每条 raw `bench`/`bench_latency` row，不新增独立聚合文件。
- `elapsed_ns` 仍只覆盖 benchmark loop 本身；`getrusage()` 调用放在计时窗口外，尽量避免污染
  ns/op。
- 如果 `getrusage()` 失败，benchmark 直接失败，保留 fail-fast 行为。

## 验证

- `make bench` 通过。
- `make kvm-bench RUN_ID=20260615T-kvm-bench-rusage-smoke-v1 SAMPLES=1 BENCH_ITERS=500 BENCH_LATENCY_SAMPLES=1 BENCH_LATENCY_BATCH=64 BENCH_RANDOMIZE_ORDER=1` 通过。
- `results/phase1/20260615T-kvm-bench-rusage-smoke-v1/bench.jsonl`：
  - `bench_rows=35`
  - `latency_rows=35`
  - `missing_rusage_bench=0`
  - `missing_rusage_latency=0`
  - `failing_ops=0`
  - `resource_errors=0`
  - `done_status=0`
- `dmesg-bench.log` 中 panic/oops/warning/hung-task gate pattern 数为 0。

## 后续使用

该实现随后用于 `20260615T-kvm-bench-rusage-tail10-v1`、no-hook baseline-only
和 baseline/pass-only matched diagnostics。诊断结论记录在
`docs/tmp/2026-06-15-rusage-nohook-tail-diagnostic.md`。
