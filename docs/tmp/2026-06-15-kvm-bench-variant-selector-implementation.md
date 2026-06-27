# kvm-bench variant selector 实现记录

Last updated: 2026-06-15
Stage at update: implementation/execute
Source/command: `BENCH_VARIANTS` Make knob and `NAMEI_EXT_BENCH_VARIANTS` collector selector; `make bench`; full/default and baseline-only KVM smoke
Completeness: complete

## 动机

tail10 和 rusage 诊断都指向同一个问题：`pass_only` 的 p99 residual 与真实 policy
非常接近，说明主要成本可能在 attach/static-branch/cgroup dispatch/BPF call common path，
而不是 redirect policy 的分支逻辑。当前 `kvm-bench` 默认在同一个 benchmark 进程里随机运行
`baseline`、`pass_only`、`table_redirect_empty`、`table_redirect_hit` 和 `policy`。
虽然 `baseline` 行本身没有 attach policy，但它不能单独证明“整个进程从未 attach 过
`cgroup/namei_ext` policy”的 no-hook/static-key-off 下界。

本步骤增加一个 Makefile 变量 `BENCH_VARIANTS`，默认仍运行完整 variant set；诊断时可用：

```text
make kvm-bench BENCH_VARIANTS=baseline ...
```

这仍然完全通过 Make target 执行，不引入 shell 脚本。

## 设计选择

- `BENCH_VARIANTS` 默认值为
  `baseline pass_only table_redirect_empty table_redirect_hit policy`，因此默认 Phase 1 行为不变。
- `mk/kvm.mk` 把 `BENCH_VARIANTS` 写入 metadata 和 guest command，并通过
  `NAMEI_EXT_BENCH_VARIANTS` 传给 C collector。
- C collector 在构造 variant list 前校验 filter token；未知 token 或空选择直接返回错误。
- filter 支持空格、逗号、冒号分隔，方便 Make 变量和手工诊断。
- 不改变 policy ABI、policy object、bench case、latency sampling 或 result root 约定。

## 验证

- `make bench` 通过。
- full-default smoke：
  `make kvm-bench RUN_ID=20260615T-kvm-bench-variant-selector-full-smoke-v1 SAMPLES=1 BENCH_ITERS=500 BENCH_LATENCY_SAMPLES=1 BENCH_LATENCY_BATCH=64 BENCH_RANDOMIZE_ORDER=1`
  通过。
  - `bench_rows=35`
  - `latency_rows=35`
  - `variants=["baseline","pass_only","policy","table_redirect_empty","table_redirect_hit"]`
  - `attach_rows=4`
  - `failing_ops=0`
  - `resource_errors=0`
  - `done_status=0`
- no-hook smoke：
  `make kvm-bench RUN_ID=20260615T-kvm-bench-nohook-baseline-smoke-v1 BENCH_VARIANTS=baseline SAMPLES=1 BENCH_ITERS=500 BENCH_LATENCY_SAMPLES=1 BENCH_LATENCY_BATCH=64 BENCH_RANDOMIZE_ORDER=1`
  通过。
  - `bench_rows=7`
  - `latency_rows=7`
  - `variants=["baseline"]`
  - `attach_rows=0`
  - `failing_ops=0`
  - `resource_errors=0`
  - `done_status=0`
  - metadata 中 `config.bench_variants="baseline"`
- 两个 smoke 的 dmesg gate pattern 数均为 0。

## 后续使用

该 selector 随后用于 baseline-only no-hook tail10 和 baseline/pass-only matched tail10
诊断。诊断结论记录在 `docs/tmp/2026-06-15-rusage-nohook-tail-diagnostic.md`。
