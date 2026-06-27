# KVM latency sampling review revision 记录

Last updated: 2026-06-15
Stage at update: Phase 1 implementation review / P2 revision
Reviewer: Hooke subagent `019ecac7-a56e-7de2-bf77-a05141b1427b`
Completeness: scoped review P2 addressed; no P0/P1 open

## Review scope

本次 review 只覆盖 KVM microbenchmark latency sampling plumbing：

- `bench/workloads/namei_ext_bench.c`
- `configs/benchmarks/phase1.mk`
- `mk/kvm.mk`
- `mk/report.mk`
- `mk/eval_osdi.mk`
- `docs/tmp/2026-06-15-kvm-bench-latency-sampling.md`
- `docs/research_plan.md`
- `docs/experiment-plans/osdi-evaluation.md`

review 问题聚焦 OSDI 实验纪律：raw latency rows 是否来自真实 KVM VFS 路径，是否会把
Phase 1 smoke 误计为 C2/C3/C5 release performance，Make/KVM knob 是否进入 guest，
report gate 是否 fail-fast，文档是否中文且不过度声明。

## Review verdict

Hooke 给出的 scoped verdict：

- P0：无。
- P1：无。
- P2：3 个 reviewer-facing 精度问题。
- Scoped verdict：Weak Accept for latency sampling plumbing。

Hooke 确认：

- `bench/workloads/namei_ext_bench.c` 走真实 `stat/open/access/execve/opendir/readdir`
  VFS 路径，policy 通过 `BPF_CGROUP_NAMEI_EXT` attach，不是 mock 或 object inspection。
- `BENCH_LATENCY_SAMPLES ?= 0` 保持默认 `make phase1` 为 smoke。
- `kvm-bench` 已显式把 benchmark knobs 传入 guest。
- `mk/eval_osdi.mk` 没有把 latency plumbing 升级成 C2/C3/C5。

## P2.1: latency hard gate 组合覆盖不够强

问题：`mk/report.mk` 只校验 latency row 总数和每个 variant 的 row 数。如果未来 collector
重复某个 bench 而漏掉另一个 bench，总数仍可能对齐。

修复：

- 增加 latency bench set hard gate，要求 latency bench set 等于 7 个 aggregate bench。
- 增加 `(bench, variant, sample, latency_sample)` key 唯一性检查。
- 增加 `sample` 和 `latency_sample` 范围检查。

修改位置：

- `mk/report.mk`

## P2.2: `has_tail_latency` 语义过强

问题：raw `bench_latency` rows 是原始 batch timing，不是已经计算好的 OSDI p95/p99
tail-latency artifact。`bench_latency_rows > 0` 时直接置 `has_tail_latency=true` 会造成
reviewer-facing 误解。

修复：

- 新增 `has_latency_raw_rows` 表示 raw latency batch rows 存在且无 failure。
- 保持 `has_tail_latency=false`。
- 新增 `has_tail_latency_artifact=false`。
- summary 中改写为 `latency_raw_rows=...` 和 `tail_latency_artifact=...`。
- Missing evidence 改为 `missing tail-latency artifact`。

修改位置：

- `mk/eval_osdi.mk`
- `docs/tmp/2026-06-15-kvm-bench-latency-sampling.md`
- `docs/research_plan.md`
- `docs/experiment-plans/osdi-evaluation.md`

## P2.3: batch timing 不能暗示单次 syscall p99

问题：当前 `bench_latency` row 的 `elapsed_ns / ops` 是 batch 平均 ns/op。它能作为后续
distribution 的 raw input，但若 `BENCH_LATENCY_BATCH>1`，不能称为单次 syscall tail。

修复：

- 文档明确 `bench_latency` 是 batch 级 raw observation。
- 文档要求 release experiment 若要报告单次操作 tail latency，需要设置
  `BENCH_LATENCY_BATCH=1`；否则只能声明 batch ns/op distribution。

修改位置：

- `docs/tmp/2026-06-15-kvm-bench-latency-sampling.md`
- `docs/experiment-plans/osdi-evaluation.md`

## 验证

P2 修复后重新验证：

```text
make bench
```

通过。

```text
git diff --check
```

通过。

```text
make eval-osdi-performance-ledger \
  RUN_ID=20260615T-eval-ledger-after-latency-code-p2fix \
  EVAL_OSDI_PHASE1_RUN_ID=20260615T-full-phase1-bench-variants
```

通过。

该 ledger 对当前 canonical full root 记录：

```json
{
  "bench_latency_rows": 0,
  "has_latency_raw_rows": false,
  "has_tail_latency": false,
  "has_tail_latency_artifact": false,
  "latency_failing_ops": 0,
  "release_gate_pass": false
}
```

还用 pilot root 直接检查新增 jq gate：

```text
results/phase1/20260615T-kvm-bench-latency-pilot/bench.jsonl
```

检查内容包括：

- latency bench set 等于 7 个 aggregate bench；
- `(bench, variant, sample, latency_sample)` key 无重复；
- `sample` 和 `latency_sample` 均在配置范围内。

上述检查通过。

## 剩余问题

本次 scoped review 不解决完整 OSDI performance gate。仍需后续实现：

- release-scale performance Make target；
- randomized order；
- system metrics；
- percentile/CI analysis target；
- FUSE、copy-tree、symlink-forest、bind mount、OverlayFS 外部 baseline。
