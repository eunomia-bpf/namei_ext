# 2026-06-14 论文 Subagent Review 第一轮修订记录

> 2026-06-29 baseline scope update: this historical record preserves prior reasoning and results. Current C8/B12 guidance is claim-driven baseline selection; exact-map diagnostics are optional boundary evidence only when precomputed mapping is the competing claim.

## 动机

用户要求论文在 `docs/paper/` 中长期维护，并让独立 subagent 按 OSDI 顶会标准 review，
持续 revision/review。第一轮 subagent review 判断当前稿件没有把 planned 或 host
trace-witness 误写成 KVM workload 结果，但仍不接近 weak accept，主要问题是正文缺少
可审计 artifact evidence、table-only budget、use-case expressibility 和 related work。

本步骤不新增实验结果，也不把 POC 结果升级为论文结论。目标是把已有证据和评估门槛写得更
可审计、更符合 OSDI claim-first 风格。

## Review 结论摘要

Subagent 的 blocker/major 包括：

- KVM load/semantic gate 的 raw result path、kernel hash 和 dmesg/verifier 边界没有写进正文。
- 引言贡献把四类 policy family 写得过强，容易被读成完整 workload 结果。
- W1 host trace-witness 与 W2--W4 planned 状态是投稿级 blocker，不能只放在普通 limitation。
- `table_redirect.bpf.c` 的同等预算、conformance 和降级规则没有在论文正文中定义。
- Phase 1 same-parent redirect 与 W2/W3/W4 可能需要 target registry 的关系没有表格化。
- workload 表缺少若干真实来源引用。
- W1 当前表缺少 `candidate_witness_hit_rate` 和该指标的非性能解释。
- LaTeX 论文缺少相关工作节。

## 修订内容

修改 `docs/paper/sections/01-introduction.tex`：

- 将贡献表述改为“四类 POC eBPF policy family + KVM load/attach 和 semantic gate”。
- 明确真实 workload oracle 尚未完成。

修改 `docs/paper/sections/03-design.tex`：

- 新增 evidence level 表，区分 POC semantic gate、host trace-witness、KVM workload
  oracle 和 release-level result。
- 新增 requirement/challenge -> policy mechanism -> oracle 映射表。

修改 `docs/paper/sections/04-implementation.tex`：

- 新增 artifact evidence 表，引用当前完整 KVM Phase 1 result：
  `results/phase1/20260614T045335Z-a476f6e2/`。
- 记录 `policy-load.jsonl`、`policy-semantic.jsonl`、`summary.md`、kernel image sha256
  和 dmesg 0 warning/oops/panic。
- 明确当前缺少 per-policy object hash、verifier 摘要、真实 workload oracle 和 C8 budget。
- 统一 W1 证据术语为 host trace-witness。

修改 `docs/paper/sections/05-evaluation.tex`：

- 新增 use case expressibility 表，明确 Phase 1 same-parent 子集、blocked row 和进入主结果条件。
- workload 表补充真实来源 citation。
- W1 host trace-witness 表新增 `candidate_witness_hit_rate` 数值：
  Redis 0.461%，nginx 0.314%。
- 明确该 rate 不是 redirected operation hit rate。
- 新增 table-only counterfactual 预算规则：允许 exact map lookup，禁止 fallback/resolver/epoch
  state machine/隐藏 rule engine；manifest 必须记录 entries、memory、update writes、update
  latency、stale window 和 budget basis；若 table-only 在同等预算内通过，相关 family 降级。

新增 `docs/paper/sections/06-related-work.tex`：

- 覆盖 FUSE、FUSE passthrough、ExtFUSE、Bento。
- 覆盖 OverlayFS/bind/symlink/copy tree 作为 kernel/materialized baseline。
- 覆盖 Landlock、BPF LSM、fanotify，说明它们是安全或事件机制，不是 path-resolution backing
  selection。
- 覆盖 sched_ext，说明 \namei 借鉴窄 eBPF kernel policy 扩展点，但 oracle 不同。

修改 `docs/paper/refs.bib`：

- 补充 Redis、nginx、PostgreSQL、Docker Compose secrets、CRIU Checkpoint/Restore、
  Prometheus、Bazel remote cache、Nix store、Linux FUSE/OverlayFS/Landlock/BPF LSM/fanotify/
  sched_ext、ExtFUSE、Bento 等引用。

修改 `docs/paper/Makefile`：

- `check` 增加 `sections/06-related-work.tex` 存在性检查。

## 验证

已运行：

```text
make -C docs/paper paper
make -C docs/paper check
grep -n -E 'undefined|Overfull|LaTeX Warning: There were undefined|Citation .* undefined' .build/paper/main.log || true
grep -R --line-number -E 'host witness|host evidence|operation_weighted_alias_hit_rate|weak accept|TODO write' docs/paper || true
find docs/paper -maxdepth 1 -type f | sort
```

验证结果：

- `make -C docs/paper paper` 通过。
- `make -C docs/paper check` 通过。
- `.build/paper/main.log` 中没有 undefined reference、undefined citation 或 Overfull。
- `docs/paper/` 顶层只保留源码文件，没有 LaTeX 生成物。
- PDF 生成在 `.build/paper/main.pdf`。
- 仍有 TeX Live Fandol 字体 warning 和 bibliography URL 的 underfull warning；它们不影响当前构建。

## 剩余 blocker

- 仍缺 release-level KVM workload oracle；W1 仍是 host trace-witness，W2--W4 仍是 planned。
- 当前 KVM artifact evidence 缺少 per-policy object hash 和 verifier 摘要，需要 report target 补齐。
- 仍缺 table-only counterfactual 的真实运行结果。
- 仍缺四类 family 每类至少两个 `qualified_for_c8` workload row。
- 论文还不是 weak accept；当前更接近 OSDI 风格的 design/evaluation contract。
