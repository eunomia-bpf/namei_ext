# 2026-06-14 论文 Subagent Review 第二轮修订记录

> 2026-06-29 baseline scope update: this historical record preserves prior reasoning and results. Current C8/B12 guidance is claim-driven baseline selection; exact-map diagnostics are optional boundary evidence only when precomputed mapping is the competing claim.

## 动机

第二轮 subagent review 判断第一轮的结构性 blocker 大多已解决，但仍指出三类必须立即修订的
论文问题：

- 摘要中的 policy family 表述还应显式标为 POC。
- Artifact evidence 表没有暴露 `main repo dirty=true`、`samples=1` 和 benchmark iterations，
  可能让读者误读为 release artifact。
- Table-only budget 已有规则，但需要明确 committed budget config 和 conformance checker
  target 的当前状态。

本步骤继续只修论文和文档，不新增实验结果。

## 修订内容

修改 `docs/paper/main.tex`：

- 摘要改为“四类可构建的 POC eBPF policy family”。
- 将 limitations 输入文件改为 `sections/07-limitations.tex`。

重命名章节文件：

- `docs/paper/sections/06-limitations.tex` -> `docs/paper/sections/07-limitations.tex`。
- 保持 `docs/paper/sections/06-related-work.tex` 为相关工作。

修改 `docs/paper/sections/04-implementation.tex`：

- Artifact evidence 表中为 `make phase1` 行补充：
  - `samples=1`
  - `benchmark iterations=2000`
  - `main repo dirty=true`
- 明确这些因素进入“仍缺少”列，不能支撑 release-level result。

修改 `docs/paper/sections/05-evaluation.tex`：

- 新增 committed budget 表，指向 `configs/eval-osdi/policy-budgets.mk`。
- 写入当前已提交预算：
  - `OSDI_MAX_POLICY_INSTRUCTIONS=10000`
  - `OSDI_MAX_POLICY_MAPS=8`
  - `OSDI_MAX_POLICY_MAP_ENTRIES=131072`
  - `OSDI_MAX_POLICY_MAP_MEMORY_BYTES=67108864`
  - `OSDI_CHECKPOINT_MAX_PATH_CLASSES=8`
  - `OSDI_CHECKPOINT_MAX_RESTORE_SESSIONS=100`
  - checkpoint restore switch/post-restore VFS hit-rate 下限 0.80
  - `OSDI_CACHE_MAX_HASH_WITNESSES=4`
  - cache state-transition hit-rate 下限 0.80
  - table-only over-materialization ratio 10
  - table-only stale-window 上限 100 ms
  - table-only update-latency 上限 1000 ms
- 明确发布级 run 仍需要 Makefile-owned table-only conformance target，而该 target 当前尚未实现。

## 验证

已运行：

```text
make -C docs/paper paper
make -C docs/paper check
grep -n -E 'undefined|Overfull|LaTeX Warning: There were undefined|Citation .* undefined' .build/paper/main.log || true
find docs/paper/sections -maxdepth 1 -type f | sort
find docs/paper -maxdepth 1 -type f | sort
grep -R --line-number -E 'host witness|host evidence|operation_weighted_alias_hit_rate|weak accept|TODO write' docs/paper || true
```

验证结果：

- `make -C docs/paper paper` 通过。
- `make -C docs/paper check` 通过。
- `.build/paper/main.log` 中没有 undefined reference、undefined citation 或 Overfull。
- 章节文件编号为 `01` 到 `07`，没有遗留 `06-limitations.tex`。
- `docs/paper/` 顶层只有源码文件，没有 LaTeX 生成物。
- 禁用指标名和术语漂移 grep 仅命中 Makefile check 自身。

## 剩余 blocker

- 仍没有 release-level KVM workload oracle。
- 仍没有真实 table-only counterfactual 运行结果。
- 仍没有 Makefile-owned table-only conformance checker target。
- 仍没有四类 family 每类两个 `qualified_for_c8` workload row。

第二轮 review 的结论是：当前稿件已经从早期 skeleton 提升到 OSDI 风格的 design/evaluation
contract，但仍不是 weak accept paper。下一步应优先实现第一个 KVM workload oracle row。
