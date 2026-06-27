# research lifecycle artifact review revision

Date: 2026-06-15
Stage: execute/gate loop
Scope: `research/STATE.md`, `research/EXPERIMENT_PLAN.md`, `research/EXPERIMENT_TRACKER.md`

## 动机

Hooke subagent 对 research lifecycle artifacts 做 scoped review 后给出 Weak Accept，但指出
三个 P2 问题：`STATE.md` 的 latest artifact 没有反映本轮实际产生的 follow-up/gate 文档；
`EXPERIMENT_TRACKER.md` 中 R002-R006 使用 `same dirty state as R001`，不够自包含；`EXPERIMENT_PLAN.md`
的 thesis 句子容易被误读为当前已经成立的性能结论。

这些问题不会改变当前 gate 结论，但会影响后续 resume、审计和 paper claim narrowing，所以需要立即修正。

## 修改

- `research/STATE.md`：把 latest artifact 改为 `research/FOLLOWUP_PLAN.md`，同时列出本轮同步更新的
  tracker、verdict 和 follow-up artifact。
- `research/EXPERIMENT_PLAN.md`：把 thesis 标记为“待验证 thesis”，避免把未通过 release gate 的
  性能和可编程性主张写成事实。
- `research/EXPERIMENT_TRACKER.md`：增加 provenance basis，并把 R002-R006 的 commit、machine 和
  seed/repetition 字段展开为可独立审计的信息。

## 当前 gate 解释

本次 revision 只修文档一致性，不改变证据状态：

- B12 policy-family gate 仍然失败：`qualified_families=0`。
- B2/B8 performance gate 仍然失败：缺 release repetitions、tail-latency artifact、CI、随机化顺序、
  系统指标和 named external baselines。
- 当前不能进入 submission polish，也不能把中文 paper 写成 OSDI weak-accept-ready。

## 后续

下一步应继续实现 release performance/baseline infrastructure，让 `make eval-osdi-performance` 不只是
ledger contract，而是消费真实 release-scale KVM runs、baseline rows、percentile/CI artifact 和系统指标。
