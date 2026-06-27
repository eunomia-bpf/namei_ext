# FUSE Redirect Baseline Scoped Review 与修订记录

Last updated: 2026-06-15
Stage at update: gate
Source/command: subagent Ohm scoped review of FUSE redirect external baseline
Completeness: partial

## Review verdict

独立 subagent 对 FUSE redirect external baseline 的 scoped verdict 是
`Scoped Weak Accept`。

审查范围包括：

- `bench/workloads/namei_ext_baselines.c`
- `bench/workloads/Makefile`
- `configs/kernel/x86_64_phase1.config`
- `mk/kernel.mk`
- `mk/eval_osdi.mk`
- `docs/tmp/2026-06-15-eval-osdi-fuse-baseline-implementation.md`
- `research/STATE.md`
- `results/eval-osdi/baselines/20260615T-kvm-external-baselines-fuse-smoke-v2/`
- `results/eval-osdi/paper/20260615T-eval-ledger-fuse-baselines-smoke/b2-performance/`

## Findings

P0：无。

P1：

- release performance 仍 blocked：
  `performance.jsonl` 记录 `samples=1`、`bench_latency_rows=0`、
  `has_tail_latency_artifact=false`、`has_confidence_interval=false`、
  `has_randomized_order=false`、`has_system_metrics=false`、
  `release_gate_pass=false` 和 `qualified_for_c2_c3_c5=false`。
- 当前 baseline run 是固定顺序 smoke，不是公平发布级比较。
- FUSE 只覆盖当前 microbench alias view，不覆盖 W1-W4 workload-level
  setup/update/storage accounting。
- manifest 仍记录 main/kernel dirty，不能作为 final artifact claim。

P2：

- paper draft 需要把 “FUSE smoke rows exist” 和 “release baseline comparison absent”
  分开写，避免读者误解为 FUSE baseline 完全缺失。
- dmesg gate 当前只硬拦截 `BUG/WARNING/Oops/panic/hung task/kernel BUG` 模式；
  发布 artifact 需要说明普通 virtme/9p 启动噪声不计为内核错误。

## Revision

已修订 `docs/paper/sections/05-evaluation.tex`：

- 删除“也没有 FUSE、copy tree、symlink forest、bind mount 和 OverlayFS 等发布级
  baseline”这种容易误读为完全没有 FUSE baseline 的表达；
- 改为明确写出 copy tree、symlink forest、bind mount、OverlayFS 和 FUSE redirect
  的 KVM smoke rows 已存在，且 FUSE row 证明真实走了 FUSE mount；
- 同时保持这些 rows 是 1-sample smoke，不能作为发布级 FUSE/copy/symlink/bind/OverlayFS
  性能对照。

## Remaining gate

本 review 没有改变 release gate：

- B2/B8 仍需要 release KVM latency root、每组至少 20 rows、p50/p95/p99/CI、随机化顺序、
  system metrics，以及 baseline release repetitions。
- B12 仍需要四个 policy family 的 release metric 和 table/update budget counterfactual。

下一步按 reviewer value 排序：

1. 增加 microbench run-order artifact 和 system metrics capture。
2. 跑 release-oriented KVM `kvm-bench` root，启用 `BENCH_LATENCY_SAMPLES`。
3. 将五个 external baselines 从 smoke 扩展到 release repetitions。
4. 再运行 `eval-osdi-performance` hard gate，只有真实满足条件才允许 C2/C3/C5 升级。
