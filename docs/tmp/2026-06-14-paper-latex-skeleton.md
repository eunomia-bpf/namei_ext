# 2026-06-14 论文 LaTeX 骨架实现记录

> 2026-06-29 baseline scope update: this historical record preserves prior reasoning and results. Current C8/B12 guidance is claim-driven baseline selection; exact-map diagnostics are optional boundary evidence only when precomputed mapping is the competing claim.

## 动机

Phase 1 要求项目不仅有设计计划和 evaluation 计划，还要开始维护真实论文稿件。
此前 `docs/paper/` 只有 Markdown 版 evaluation 说明，不能作为可持续迭代的论文源。
本步骤把论文转为中文 LaTeX 源码，并把当前证据边界明确写入正文，避免把计划、POC
或 host trace-witness 误写成发布级 KVM 结果。

## 检查过的文件和约束

- `AGENTS.md`：确认 Phase 1 每个实现步骤都要在 `docs/tmp/` 下留下日期开头的独立记录。
- `docs/paper/evaluation.md`：保留已有 Markdown evaluation 说明，不做 wholesale rewrite。
- `docs/experiment-plans/osdi-evaluation.md`：沿用 claim-first、真实 workload、KVM raw result
  和 table-only ablation 的评估边界。
- `workload/*/evidence.md`：引用 W1 Redis/nginx source-build trace-witness 的当前状态。

## 实现内容

新增中文 LaTeX 论文源：

- `docs/paper/main.tex`
- `docs/paper/sections/01-introduction.tex`
- `docs/paper/sections/02-motivation.tex`
- `docs/paper/sections/03-design.tex`
- `docs/paper/sections/04-implementation.tex`
- `docs/paper/sections/05-evaluation.tex`
- `docs/paper/sections/06-limitations.tex`
- `docs/paper/refs.bib`

新增 `docs/paper/Makefile`：

- `make -C docs/paper paper` 使用 `latexmk -xelatex` 构建论文。
- 论文 PDF 和 LaTeX 中间文件输出到仓库根目录 `.build/paper/`。
- `make -C docs/paper check` 检查核心源文件存在，并阻止明显的占位文本或被废弃指标名进入论文。
- `make -C docs/paper clean` 删除 `.build/paper/`。

论文正文当前只写已经可以 defend 的内容：

- 把项目定义为窄 VFS path-resolution eBPF 扩展点，而不是 BPF filesystem。
- 明确 kernel 继续拥有 dentry、inode、权限检查、mount traversal 和 lower filesystem data path。
- 明确 policy 是 eBPF 程序，不是 YAML/JSON/DSL。
- 明确当前四类 policy family 是 POC，W1 只是 host trace-witness，不是 KVM policy oracle。
- 明确发布级结果必须来自 KVM guest raw result。
- 明确如果 table-only baseline 通过所有 oracle，论文必须降级，不能声称需要 eBPF programmable logic。

## 真实来源引用

`refs.bib` 记录了当前 motivation 和 workload 计划依赖的公开来源：

- Bazel sandboxing 和 hermeticity 文档。
- Kubernetes projected volumes 和 Secret 文档。
- Podman checkpoint/restore 文档。
- CRIU 项目文档。
- Docker BuildKit cache 文档。
- ccache 手册。

这些引用只用于说明真实系统需求和 workload 来源，不等价于实验结果。

## 验证

已运行：

```text
make -C docs/paper paper
make -C docs/paper check
grep -n 'Overfull' .build/paper/main.log || true
```

验证结果：

- PDF 生成在 `.build/paper/main.pdf`。
- `docs/paper/` 目录只保留源码文件，没有 `aux`、`log`、`pdf`、`xdv` 等编译生成物。
- `make -C docs/paper check` 通过。
- LaTeX log 中没有 `Overfull`。
- 仍有 TeX Live Fandol 字体 warning 和 bibliography URL 的 underfull warning；它们不影响当前 PDF 构建。

## 剩余风险和后续工作

- 当前论文是 skeleton，不是可投稿完整稿；缺少相关工作、完整实现细节、最终性能图表和威胁分析。
- 当前 W1 证据仍是 host trace-witness，不能支撑 C1/C8 或性能主张。
- W2/W3/W4 仍需真实 workload runner、KVM materializer、raw result 和 checker。
- 后续需要使用 `osdi-experiment-design`、`paper-logic` 和 `paper-review` 标准进行 subagent 对抗 review，
  并根据 blocker/major finding 继续 revision。
