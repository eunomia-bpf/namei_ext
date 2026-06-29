# W4 parent-scoped ccache report gate 实现记录

> 2026-06-29 baseline scope update: this historical record preserves prior reasoning and results. Current C8/B12 guidance is claim-driven baseline selection; exact-map diagnostics are optional boundary evidence only when precomputed mapping is the competing claim.

日期：2026-06-15

## 动机

`2026-06-15-w4-parent-object-shape-review-revision.md` 的 subagent review 指出：
parent object-shape PoC 虽然有 KVM raw result，但当时还不是主 `make phase1` / `make report`
summary gate 的一部分。这样会让结果停留在 standalone artifact，后续改动可能绕过
`attached_parent_sibling_pass` 负例。

本步骤把 W4 parent-scoped ccache compile witness 纳入 Phase 1 Makefile flow 和 report hard gate。

## 实现内容

改动文件：

- `Makefile`
  - `phase1` 依赖加入 `kvm-w4-ccache-parent-compile`，位置在
    `kvm-w4-ccache-policy-compile` 和 `kvm-w4-ccache-table-compile` 之间。
- `mk/report.mk`
  - report artifact 存在性检查加入：
    `w4-ccache-parent-compile.jsonl`、`w4-ccache-parent-compile-inputs.sha256`、
    `w4-ccache-parent-compile-outputs.sha256`、`w4-ccache-parent-compile-stats.txt`、
    ccache path/version 和 `dmesg-w4-ccache-parent-compile.log`。
  - report hard-check 加入 parent input SHA256 校验、output SHA256 校验、summary
    `pass=true/failures=0/output_hash_match=true/qualified_for_c8=false` 校验、
    `attached_parent_sibling_pass` 事件校验和 stats 中 `parent_sibling_pass=true` 校验。
  - report Markdown 增加 `W4 Parent-Scoped Ccache Compile Witness` 表格。
  - raw artifact list 增加 parent compile artifacts。

## 验证

- `make -n report RUN_ID=20260615T-report-syntax-check`：通过，验证 Makefile 语法和 report
  recipe 展开。
- 对 `results/phase1/20260615T-w4-parent-shape-hardgate/w4-ccache-parent-compile.jsonl`
  手工执行与 report 新增 hard-check 等价的 jq 条件：通过。
- `sha256sum -c results/phase1/20260615T-w4-parent-shape-hardgate/w4-ccache-parent-compile-inputs.sha256`：通过。
- `sha256sum -c results/phase1/20260615T-w4-parent-shape-hardgate/w4-ccache-parent-compile-outputs.sha256`：通过。

没有直接在旧 full-run RUN_ID 上执行 `make report`，因为旧 RUN_ID 下的 W4 trace/bridge/policy/table
artifacts 有输入 SHA 链；对同一 RUN_ID 只重跑 parent target 会重写 W4 trace/bridge，可能破坏旧
policy/table input SHA 的一致性。下一次完整 `make phase1` 会自然覆盖该 gate。

## 当前结论

W4 parent-scoped ccache witness 现在是 Phase 1 默认流程和 report gate 的一部分。该 gate 仍明确
`qualified_for_c8=false`，只证明一个 parent object-shape PoC 和 `metadata.txt` sibling PASS 负例，
不证明 C8、table-only 不足或 operation-weighted release workload coverage。

## 后续工作

- 下一次完整 `make phase1 RUN_ID=...` 需要确认 parent section 出现在 `summary.md` 中。
- 继续补 release-scale workload、same-run table comparator、operation-weighted redirect counter、
  valid-shape decoy、missing backing、stale/corrupt 和 update-window evidence。
