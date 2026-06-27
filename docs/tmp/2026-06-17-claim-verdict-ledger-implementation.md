# Claim verdict ledger 实现记录

日期：2026-06-17

## 背景

当前论文已经有 W1/W2/W3/W4 workload ledgers、performance comparison、
W4 cache transition counterfactual 和 W4 table-content comparator。它们分散地记录
C2、C3、C5 和 C8 的正负证据，但还没有一个 Make-owned artifact 将 C1--C8 的当前
verdict 统一为 `supported`、`partial`、`unsupported` 或 `scoped_out`。

这会让论文进入 paper-claim 阶段时缺少可审计的 claim verdict。OSDI 级评审需要看到：
哪些 claim 当前能被证据支持，哪些只能作为负结果或范围限制，哪些需要后续实验。

## 实现

本次新增 Makefile-owned analysis target：

- `configs/eval-osdi/claim-verdict.jq`
  - 读取 W1/W2/W3/W4 workload macrobench summary、performance comparison summary、
    W4 cache transition summary、W4 cache table-content summary 和 C7 artifact audit
    summary。
  - 输出 C1--C8 每个 claim 的 `active_main_claim`、verdict、supported wording、
    supporting paths、missing evidence、`slice_gate_pass`、`paper_release_gate_pass`
    和 `release_gate_pass`。`slice_gate_pass` 只表示命名子范围通过；paper-level
    release readiness 由 `paper_release_gate_pass=false` 和 summary
    `release_gate_pass=false` 约束。
  - 输出 `eval-osdi-claim-verdict-summary`，固定记录
    `weak_accept_ready=false` 和 `release_gate_pass=false`。
- `mk/eval_osdi.mk`
  - 增加 `eval-osdi-claim-verdict-ledger`。
  - target 先检查所有 input JSONL、filter、实现记录和 Makefile 存在，再写
    `claim-verdict-inputs.sha256` 并立即 `sha256sum -c`。
  - target 现在还会递归执行 W1/W2/W3/W4 workload ledger、performance comparison、
    tool-redirect scope、W4 cache transition 和 W4 cache table-content 的
    `inputs_sha256_file` 校验；任何下游 evidence ledger stale 都会让 claim verdict
    target 失败。
  - target 生成 raw JSONL、manifest 和 Markdown summary。
- `Makefile`
  - 将 target 加入 `.PHONY` 和 help 文本。

该 target 不是 hard-gate 成功声明。它的作用是把当前负结论作为 raw analysis artifact
固定下来，防止论文正文在没有证据时扩大 claim。

## 当前结论范围

预期 verdict：

- C1 作为 Phase 1 KVM functional slices 是 supported；C1 release-level
  programmability 和 release-wide end-to-end family 被保留为 scope boundary。
- C2 作为 W2 nginx fixture slice 是 supported；global C2 被保留为 scope boundary。
- C3 作为 tool-redirect lookup/access/open/exec slice 是 supported；full metadata suite
  被保留为 scope boundary。
- C5 scoped out：residual-overhead gate 为负，所以当前论文不再把 VFS-placement
  attribution 写成 active main claim。
- C6 scoped out：当前只有 Phase 1 fail-fast diagnostics，没有 release-level stress 或
  scalability sweep。
- C7 scoped out：当前已有 Make-owned provenance、sha manifests、sanitized artifact
  package、package-root paper replay 和 anonymization gate；缺口已收窄为 clean-checkout
  reproduction。
- C8 scoped out：W4 table-content comparator 仍通过，cache transition counterfactual
  没有产生 equal-budget table-only failure，所以当前论文只把它保留为负证据和 future gate。
- `weak_accept_ready=false`，不能声明 OSDI weak accept readiness。

## 验证结果

运行命令：

```text
make eval-osdi-claim-verdict-ledger \
  RUN_ID=20260617T-eval-claim-verdict-ledger-v6 \
  EVAL_OSDI_CLAIM_W1_RUN_ID=20260617T-eval-w1-build-workload-macrobench-ledger-fuse-test-hardgate-v2 \
  EVAL_OSDI_CLAIM_W2_RUN_ID=20260616T-eval-w2-nginx-workload-macrobench-hardgate-v5 \
  EVAL_OSDI_CLAIM_W3_RUN_ID=20260616T-eval-w3-redis-workload-macrobench-ledger-v2 \
  EVAL_OSDI_CLAIM_W4_RUN_ID=20260616T-eval-w4-ccache-workload-macrobench-ledger-v10 \
  EVAL_OSDI_CLAIM_PERFORMANCE_RUN_ID=20260615T-eval-comparison-ctx-init-split-tail10-hardgate-v1 \
  EVAL_OSDI_CLAIM_PERFORMANCE_SCOPE_RUN_ID=20260617T-eval-performance-tool-redirect-scope-v1 \
  EVAL_OSDI_CLAIM_W4_TRANSITION_RUN_ID=20260617T-w4-cache-transition-hardgate-release-v1 \
  EVAL_OSDI_CLAIM_W4_CACHE_TABLE_RUN_ID=20260617T-w4-cache-table-content-hardgate-smoke-v2
```

## 2026-06-17 C7 artifact audit 接入和 v17 刷新

C7 artifact audit v11 生成 sanitized evidence package、package-root paper replay 和
anonymization checklist 后，claim verdict ledger 追加读取 C7 audit summary，避免继续报告
“缺 artifact packaging/anonymization checklist”的旧缺口。

本轮刷新了所有受 `mk/eval_osdi.mk` input hash 影响的 Make-owned analysis ledgers：

- W1: `20260617T-eval-w1-build-workload-macrobench-ledger-fuse-test-hardgate-v7`
- W2: `20260617T-eval-w2-nginx-workload-macrobench-hardgate-v11`
- W3: `20260617T-eval-w3-redis-workload-macrobench-ledger-v7`
- W4: `20260617T-eval-w4-ccache-workload-macrobench-ledger-v15`
- Performance comparison: `20260617T-eval-comparison-ctx-init-split-tail10-hardgate-v6`
- Tool-redirect scope: `20260617T-eval-performance-tool-redirect-scope-v7`
- W2 paper-release gate: `20260617T-eval-w2-tool-redirect-paper-release-v6`
- C4 matrix: `20260617T-eval-c4-lookup-readdir-matrix-v4`
- C7 artifact audit: `20260617T-eval-c7-artifact-audit-v11`

新 claim verdict command 是：

```text
make eval-osdi-claim-verdict-ledger \
  RUN_ID=20260617T-eval-claim-verdict-ledger-v17 \
  EVAL_OSDI_CLAIM_W1_RUN_ID=20260617T-eval-w1-build-workload-macrobench-ledger-fuse-test-hardgate-v7 \
  EVAL_OSDI_CLAIM_W2_RUN_ID=20260617T-eval-w2-nginx-workload-macrobench-hardgate-v11 \
  EVAL_OSDI_CLAIM_W3_RUN_ID=20260617T-eval-w3-redis-workload-macrobench-ledger-v7 \
  EVAL_OSDI_CLAIM_W4_RUN_ID=20260617T-eval-w4-ccache-workload-macrobench-ledger-v15 \
  EVAL_OSDI_CLAIM_PERFORMANCE_RUN_ID=20260617T-eval-comparison-ctx-init-split-tail10-hardgate-v6 \
  EVAL_OSDI_CLAIM_PERFORMANCE_SCOPE_RUN_ID=20260617T-eval-performance-tool-redirect-scope-v7 \
  EVAL_OSDI_CLAIM_PAPER_RELEASE_RUN_ID=20260617T-eval-w2-tool-redirect-paper-release-v6 \
  EVAL_OSDI_CLAIM_C4_RUN_ID=20260617T-eval-c4-lookup-readdir-matrix-v4 \
  EVAL_OSDI_CLAIM_W4_TRANSITION_RUN_ID=20260617T-w4-cache-transition-hardgate-release-v2 \
  EVAL_OSDI_CLAIM_W4_CACHE_TABLE_RUN_ID=20260617T-w4-cache-table-content-hardgate-smoke-v3 \
  EVAL_OSDI_CLAIM_C7_AUDIT_RUN_ID=20260617T-eval-c7-artifact-audit-v11
```

生成 artifact：

- `results/eval-osdi/paper/20260617T-eval-claim-verdict-ledger-v17/claim-verdict/claim-verdict.jsonl`
- `results/eval-osdi/paper/20260617T-eval-claim-verdict-ledger-v17/claim-verdict/claim-verdict-inputs.sha256`
- `results/eval-osdi/paper/20260617T-eval-claim-verdict-ledger-v17/claim-verdict/claim-verdict-manifest.json`
- `results/eval-osdi/paper/20260617T-eval-claim-verdict-ledger-v17/claim-verdict/claim-verdict-summary.md`

验证结果：

- target 通过，并递归校验 W1/W2/W3/W4 workload ledgers、performance comparison、
  tool-redirect scope、W2 paper-release gate、C4 matrix、W4 transition、W4 table-content
  和 C7 artifact audit 的 input manifests。
- summary 为 `weak_accept_ready=true`、`paper_release_gate_pass=true`、
  `release_gate_pass=false`、`active_main_claims=4`、`scoped_out_claims=4`、
  `supported_claims=4`、`partial_claims=0`、`unsupported_claims=0`。
- C7 仍为 `scoped_out`，但 evidence 现在包含 artifact package/replay/anonymization gate；
  `missing_evidence` 只剩 `clean checkout reproduction`。
- `highest_risk_claims` 现在是 `C7, C8`，对应 C7 reproducibility 和 C8 table-only
  insufficiency 两个剩余 release-level 缺口。

生成 artifact：

- `results/eval-osdi/paper/20260617T-eval-claim-verdict-ledger-v6/claim-verdict/claim-verdict.jsonl`
- `results/eval-osdi/paper/20260617T-eval-claim-verdict-ledger-v6/claim-verdict/claim-verdict-inputs.sha256`
- `results/eval-osdi/paper/20260617T-eval-claim-verdict-ledger-v6/claim-verdict/claim-verdict-manifest.json`
- `results/eval-osdi/paper/20260617T-eval-claim-verdict-ledger-v6/claim-verdict/claim-verdict-summary.md`

验证结果：

- target 通过，并在 target 内对输入 manifest 执行 `sha256sum -c`；递归校验也覆盖
  W1/W2/W3/W4 workload ledgers、performance comparison、tool-redirect scope、
  W4 cache transition 和 W4 cache table-content 的下游 input manifests。
- 手动复查 `claim-verdict-inputs.sha256`：全部输入为 `OK`。
- summary 保持 `weak_accept_ready=false`、`release_gate_pass=false`、
  `active_main_claims=4`、`scoped_out_claims=4`、`supported_claims=3`、
  `partial_claims=1`、`unsupported_claims=0`。C1、C2 和 C3 为 supported；C4 仍 partial。
- C1、C2 和 C3 的 per-claim rows 现在写入 `slice_gate_pass=true`、
  `paper_release_gate_pass=false` 和 `release_gate_pass=false`，避免把 functional、
  W2 或 tool-redirect slice 误读成投稿级 release gate。
- C3 的 supported wording 收窄到 tool-redirect lookup/access/open/exec slice；
  full-suite C3 仍保留为缺失证据。
- C5/C6/C7/C8 的负证据或未完成证据没有删除；它们以 `scoped_out` 保留在 verdict
  JSONL 中，并写明为什么不能作为当前 main claim。
- 每个输入 JSONL 现在都有 Make-owned hard gate，要求恰好一个预期 summary event；
  W1/W2/W3/W4/performance/scoped performance 还检查 schema，W4 transition 和
  W4 table-content 检查 summary event 及 `qualified_for_c8` 字段类型。
- `configs/eval-osdi/claim-verdict.jq` 使用实际的
  `w4-cache-transition-summary` event，而不是把 transition summary 当作缺失证据。
- `git diff --check -- Makefile mk/eval_osdi.mk configs/eval-osdi/claim-verdict.jq
  docs/tmp/2026-06-17-claim-verdict-ledger-implementation.md
  docs/paper/sections/05-evaluation.tex` 通过。
- `make -C docs/paper check` 通过。
- `make -C docs/paper paper` 通过；仍有长路径和长字段造成的 overfull warning，
  包括 claim-verdict 路径附近的一条 warning，但没有构建失败。

只读 OSDI reviewer subagent 复审发现两个问题：输入 summary 缺失时原实现会生成负
verdict 而不是 fail-fast，以及本记录缺少实际验证结果。当前版本已修复两者。

## 2026-06-17 paper-release gate 接入

后续新增了 `eval-osdi-w2-tool-redirect-paper-release-gate`，将 W2 nginx real-app
no-production-open trace、W2 nginx setup/materialization ledger 和 tool-redirect
lookup/access/open/exec scoped C3 ledger 合成为一个 scoped paper-release gate。
因此 claim verdict ledger 也追加读取该 gate：

- 新增 `EVAL_OSDI_CLAIM_PAPER_RELEASE_RUN_ID`、`EVAL_OSDI_CLAIM_PAPER_RELEASE_JSON`
  和 `EVAL_OSDI_CLAIM_PAPER_RELEASE_INPUTS_SHA256`。
- target 对 paper-release JSONL 要求恰好一个
  `eval-osdi-w2-tool-redirect-paper-release-summary`，且
  `paper_release_gate_pass=true`、scope 为
  `w2_nginx_fixture_plus_tool_redirect_metadata`。
- target 递归执行 paper-release gate 的 input manifest 校验，并把 JSONL 和 manifest
  纳入 claim-verdict 自身 input manifest。
- `configs/eval-osdi/claim-verdict.jq` 将 C2 和 C3 标记为
  `paper_release_gate_pass=true`，因为该 gate 同时覆盖 W2 C2 slice 和
  tool-redirect scoped C3 slice。
- summary 新增 `paper_release_gate_pass=true`，并将 `weak_accept_ready=true` 绑定到
  该 scoped paper-release gate。
- `release_gate_pass` 仍保持 `false`，C4 仍为 partial，C8 仍 scoped out；该 gate
  不声明 global C2、full-suite C3、release-wide C4 或 C8。

该接入的预期新 ledger 是：

```text
make eval-osdi-claim-verdict-ledger \
  RUN_ID=20260617T-eval-claim-verdict-ledger-v7 \
  EVAL_OSDI_CLAIM_W1_RUN_ID=20260617T-eval-w1-build-workload-macrobench-ledger-fuse-test-hardgate-v2 \
  EVAL_OSDI_CLAIM_W2_RUN_ID=20260617T-eval-w2-nginx-workload-macrobench-hardgate-v6 \
  EVAL_OSDI_CLAIM_W3_RUN_ID=20260616T-eval-w3-redis-workload-macrobench-ledger-v2 \
  EVAL_OSDI_CLAIM_W4_RUN_ID=20260616T-eval-w4-ccache-workload-macrobench-ledger-v10 \
  EVAL_OSDI_CLAIM_PERFORMANCE_RUN_ID=20260615T-eval-comparison-ctx-init-split-tail10-hardgate-v1 \
  EVAL_OSDI_CLAIM_PERFORMANCE_SCOPE_RUN_ID=20260617T-eval-performance-tool-redirect-scope-v2 \
  EVAL_OSDI_CLAIM_PAPER_RELEASE_RUN_ID=20260617T-eval-w2-tool-redirect-paper-release-v1 \
  EVAL_OSDI_CLAIM_W4_TRANSITION_RUN_ID=20260617T-w4-cache-transition-hardgate-release-v1 \
  EVAL_OSDI_CLAIM_W4_CACHE_TABLE_RUN_ID=20260617T-w4-cache-table-content-hardgate-smoke-v2
```
