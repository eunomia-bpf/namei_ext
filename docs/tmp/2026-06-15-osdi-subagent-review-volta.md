# OSDI subagent 对抗 review 记录

日期：2026-06-15

## Review 范围

独立 subagent `Volta` 对当前 Phase 1、OSDI evaluation 文档和 W3 Redis checkpoint replay
增量做只读 adversarial review。review 标准要求使用 OSDI/SOSP 系统实验口径，重点检查：

- 是否把 `functional_only` 或 W3 Redis replay 误写成 C1/C8、Podman/CRIU restore；
- 四类 policy family 是否真的证明了 programmable path-resolution diversity；
- workload 是否来自真实来源；
- Makefile-only、KVM、raw results 和 `docs/tmp/` 约束是否一致；
- 当前是否达到 OSDI weak accept 门槛。

## Subagent 结论

结论：`blocked`。

Volta 没有发现当前文档把 W3 Redis replay 直接 overclaim 成 C1/C8 或真实
Podman/CRIU restore。它认为 Phase 1 PoC 可审计、能跑通，OSDI evaluation contract
已有雏形，但还没有达到 OSDI weak accept。主要 blocker 是 release-level workload
oracle、table-only counterfactual、repetition/performance distributions、dirty tree 和
文档一致性。

## Must-fix 和处理状态

1. `docs/phase1_design.md` 和 `docs/experiment-plans/phase1.md` 过期且英文。
   - 处理：已在两个文件顶部加中文历史/过期横幅，明确当前规范以
     `docs/research_plan.md` 和 `docs/experiment-plans/osdi-evaluation.md` 为准。
   - 原因：保留历史记录，同时避免它们被误读成当前 Phase 1 规范。

2. `docs/research_plan.md` 后半部分仍有大段英文。
   - 处理：已把设计目标、设计位置、内核放置点、拟议接口、安全契约、初始范围、
     评估计划、相关工作边界、研究问题和里程碑中的英文叙述翻成中文。
   - 原因：满足“文档全部中文写”的项目要求，并保持 parent-aware ABI 和当前 W1/W2/W3/W4
     evidence 口径。

3. Policy diversity 仍只是计划强，当前 release-level 证据不足。
   - 处理：未把该项标为已解决。现有文档继续明确 `qualified_for_c8=false`，并要求 B12
     补每个 family 至少两个真实 workload/trace row、算法路径触发和 table-only
     budget failure/over-materialization/stale-window 证据。
   - 原因：这是后续实验 blocker，不是文档措辞可以解决的 blocker。

4. W3 Redis replay 与 `w3-redis-podman-criu` workload ID 有误导风险。
   - 处理：已在 `workload/w3-redis-podman-criu/evidence.md` 增加命名说明：目录名保留
     发布级 Podman/CRIU 目标，当前 Phase 1 增量 witness 应称为
     `w3-redis-rdb-load-replay` 或 W3 Redis checkpoint replay witness。论文 evaluation
     表格也拆开“当前 witness”和“发布级目标”。
   - 原因：防止审稿人把 Redis RDB load replay 误解为真实 Podman/CRIU restore。

5. 局部 `scoped weak accept` 历史记录可能被误读成全项目 weak accept。
   - 处理：已在 W2 endpoint review 和 W4 ccache cache-path trace review 文档中加入
     范围声明，说明它们只覆盖单一非 C8 增量，不代表整篇 OSDI paper、整个项目或 C1/C8
     主张达到 weak accept。

## 当前剩余 blocker

- 没有任何 `qualified_for_c8=true` row。
- `table_redirect.bpf.c` 在当前 path/probe oracle 上仍能通过，table-budget C8-qualified
  rows 为 0，不能证明必须需要 eBPF programmable abstraction。
- 当前 Phase 1 run 是 `SAMPLES=1` smoke-scale，不是发布级 repetition/performance result。
- W3 Redis replay 明确记录 `podman_criu_restore_executed=false`，仍缺真实 checkpoint
  archive、restore health、post-restore VFS trace、state/config/cache hash 和
  0 mixed epoch oracle。
- Worktree 仍是 dirty 状态，不能作为干净发布 artifact 口径。

## 结论

本轮修复解决的是文档一致性和 overclaim 风险，不解决 OSDI weak accept 的实验 blocker。
当前状态仍是 Phase 1 PoC / early OSDI evaluation contract，不能把 goal 标为 complete。
