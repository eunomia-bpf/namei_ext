# W4 合法形状 sibling 结构化内容 oracle 实现记录

Last updated: 2026-06-15
Stage at update: execute / claim-gate
Source/command: `make kvm-w4-ccache-parent-compile RUN_ID=20260615T-w4-valid-sibling-structured-oracle`
Completeness: partial

## 动机

上一轮 W4 parent-scoped ccache gate 已经证明合法 ccache object 形状、但不在
trace-derived witness 集合中的 sibling 在 attach 后仍然 PASS，并且 `.local` backing
不存在。Subagent review 给出 scoped weak accept，但指出 raw artifact 主要依赖
`detail` 字符串表达“content passed”，缺少结构化字段。这个问题不会推翻结论，但会降低
后续 report gate 和审稿人复核的机械可靠性。

本步骤的目标是把“读到预写 sibling 内容”变成机器可判定 raw evidence，而不是只靠
human-readable detail。

## 实现细节

- `tests/w1_oracle/namei_ext_w1_oracle.c`
  - 新增 `struct file_content_oracle`。
  - 新增 streaming FNV-1a helper，用现有 ccache name witness hash 常量记录内容 hash；
    这避免引入 OpenSSL 或外部 sha256 依赖。
  - `compare_file_text_hash()` 读取 observed file，比较 exact text，同时记录
    expected/observed 长度和 FNV-1a hash。
  - `attached_parent_valid_sibling_pass` raw event 现在包含：
    `content_oracle=true`、`content_oracle_kind=exact-text`、
    `expected_content_len`、`observed_content_len`、
    `expected_content_fnv1a64` 和 `observed_content_fnv1a64`。
- `mk/kvm.mk`
  - parent compile guest hard gate 不再只检查 detail 字符串，而是要求
    `content_oracle=true`、kind 为 `exact-text`、长度相等、内容 hash 相等。
  - `w4-ccache-parent-compile-stats` 增加
    `valid_shape_sibling_prepare_count`、
    `valid_shape_sibling_backing_absent_count`、
    `valid_shape_sibling_content_oracle` 和
    `valid_shape_sibling_content_pass_count`。
- `mk/report.mk`
  - report hard gate 使用同样的结构化内容 oracle 条件。
  - W4 parent-scoped report row 的 `Valid-Shape PASS` 来自结构化内容 oracle。

## 验证

已运行：

```text
make bpf w1-oracle
make kvm-w4-ccache-parent-compile RUN_ID=20260615T-w4-valid-sibling-structured-oracle
```

结果：

- `results/phase1/20260615T-w4-valid-sibling-structured-oracle/w4-ccache-parent-compile.jsonl`
  中 `attached_parent_valid_sibling_pass` 为 `pass=true`、
  `policy_executed=true`、`qualified_for_c8=false`。
- 同一 event 记录 `content_oracle=true`、`content_oracle_kind=exact-text`、
  `expected_content_len=observed_content_len=37`，且
  `expected_content_fnv1a64=observed_content_fnv1a64`。
- `parent_valid_sibling_backing_absent` 为 `pass=true`。
- `w4-ccache-parent-compile-stats` 记录
  `valid_shape_sibling_prepare_count=1`、
  `valid_shape_sibling_backing_absent_count=1`、
  `valid_shape_sibling_content_oracle=true` 和
  `valid_shape_sibling_content_pass_count=1`。
- `w4-ccache-parent-compile-inputs.sha256` 与
  `w4-ccache-parent-compile-outputs.sha256` 均通过 `sha256sum -c`。

## 剩余风险

这仍然不是 C8 证据。它只强化 sampled parent-rule PoC 的负例 oracle；W4 仍缺
release-level operation-weighted policy cache hit rate、真实 stale/corrupt transition、
BuildKit/Prometheus Go cache workload、update/stale window 和 table/update budget
failure。
