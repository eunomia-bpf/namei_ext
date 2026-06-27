# eval-osdi tail latency review revision

Date: 2026-06-15
Stage: Phase 1 B2/B8 performance gate review
Scope: `mk/eval_osdi.mk`, `docs/research_plan.md`, `research/RESULTS_SUMMARY.md`

## Review result

Hooke subagent reviewed the tail latency artifact implementation under OSDI experiment-design criteria.
Verdict: scoped Weak Accept. P0/P1: none.

## P2 fixes

- P2.1：声明采集 latency rows 时，target 不能只写 `has_tail_latency_artifact=false`。修复后，
  `eval-osdi-performance-tail` 在 `bench-start.latency_samples > 0` 时要求 rows/groups 完整且
  failures 为 0，否则 Make target 直接失败。`latency_samples=0` 的 smoke root 仍允许生成
  negative/empty artifact。
- P2.2：standalone tail artifact provenance 不够自包含。修复后新增
  `bench-latency-tail-manifest.json`，记录 run id、phase1 root、main/kernel repo HEAD、dirty state
  和 artifact paths。
- P2.3：pilot 的 `has_confidence_interval=true` 容易被误读成 release CI。修复后中文文档统一把它
  描述为 pilot-scale CI plumbing；release claim 仍要求 release sample budget、randomized order、
  system metrics 和 external baselines。

## Gate status

本次 revision 不放宽 performance gate。`eval-osdi-performance` 仍要求
`release_gate_pass=true`、`c2_supported=true`、`c3_supported=true` 和 `c5_supported=true`。
当前 canonical full root 仍然是 `bench_latency_rows=0`、`has_tail_latency_artifact=false`、
`release_gate_pass=false`。

## Re-review

修复后 Hooke quick re-review 仍给出 scoped Weak Accept，P0/P1 无，三个 P2 均关闭：

- incomplete declared latency rows hard fail；
- `bench-latency-tail-manifest.json` 已接入 tail artifact 和 performance ledger provenance；
- pilot CI 文档措辞已限定为 pilot-scale CI plumbing。
