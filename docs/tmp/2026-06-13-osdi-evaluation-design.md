# 研究记录：OSDI 级评估设计

日期：2026-06-13

## 动机

Phase 1 已经证明 `PASS/REDIRECT` 原型可以在 KVM 中构建、启动、加载 policy、
运行功能测试、运行冒烟微基准，并生成原始 artifacts。但这还不是 OSDI/SOSP
论文级评估。论文级评估必须从主张出发，使用真实工作负载、明确基线、正确性
判定器、性能分布、机制消融、规模压力、失败语义和可复现 artifact
来支撑结论。

这一步创建并重写 `docs/experiment-plans/osdi-evaluation.md`。用户进一步要求：

- 文档主体必须用中文写；
- 主工作负载必须来自真实来源和真实生产应用；
- 不能用自造玩具应用或随机生成工作负载支撑论文主结论。

## 调研和参考文件

- `docs/research_plan.md`
- `docs/phase1_design.md`
- `docs/experiment-plans/phase1.md`
- `bpf/policies/redirect_alias.bpf.c`
- `tests/functional/namei_ext_functional.c`
- `bench/workloads/namei_ext_bench.c`
- `/home/yunwei37/.codex/skills/osdi-experiment-design/SKILL.md`
- `/home/yunwei37/.codex/skills/osdi-experiment-design/references/plan-template.md`
- `/home/yunwei37/.codex/skills/osdi-experiment-design/references/evaluation-rubric.md`
- `/home/yunwei37/.codex/skills/osdi-experiment-design/references/technique-catalog.md`

## 设计选择

- 长期评估计划放在 `docs/experiment-plans/osdi-evaluation.md`。
- 文档改为中文主文档，只保留必要的代码名、命令名和 benchmark ID。
- Phase 1 冒烟测试只作为健康检查，不支撑论文主张。
- 主宏基准工作负载必须来自真实公开应用、真实发布版、真实依赖树或真实
  trace replay。
- 合成数据只用于正确性边界、规模/饱和测试和失败语义，不支撑主性能结论。
- 使用四个主使用场景：
  - 构建沙箱 / CI action view；
  - 容器或服务启动中的 selected root-view aliases；
  - 包和开发环境视图；
  - 遗留路径迁移 / 兼容视图。
- 避免 hide/deny 语义；所有使用场景都围绕 programmable path resolution。
- 基线必须是命名实现和冻结配置，而不是泛称类别。

## 第一轮独立审查

独立 subagent 按 OSDI evaluation rubric 审查了第一版计划，结论是 Level 3。

必须修复的问题：

1. U4 出现在主张范围中，但没有宏基准证据。
2. C2/C3 使用定性表述，缺少可证伪阈值。
3. 基线仍是类别名，不是具体实现、版本、配置和功能等价门槛。
4. 当前 same-parent redirect 与真实 use case 所需 target registry/cross-directory
   redirect 的关系没有闭环。
5. 工作负载只是示例，不是可复现的真实输入。
6. 失败语义被标为“应该做”，但 C6 依赖它。

建议修复的问题：

- 消融需要直接回答审稿人问题；
- U2 需要避免声称替代完整 container rootfs；
- 残余不确定性需要绑定到具体主张；
- artifact 门禁需要发布级结果清单结构；
- Phase 1 冒烟测试需要明确不能支撑论文主张。

## 第一轮修订

根据审查意见，计划被修订为：

- 增加使用场景能力门槛，说明每个场景需要哪些 ABI 能力，当前 Phase 1
  哪些子集可表达，哪些必须等 target registry 或 update epoch。
- 增加真实工作负载清单 W1-W5，要求记录真实来源、发布版/commit、SHA256、
  trace 命令、输入 manifest 和代表性理由。
- 增加具体基线身份表，包括 `native-direct`、`copy-tree-cp`、
  `symlink-forest-ln`、`bind-fanout-mount`、`overlayfs-kernel`、
  `fuse-redirectfs`、`language-native-env`、`wrapper-rewrite`。
- 增加 B6 遗留路径迁移宏基准。
- 将失败语义升级为必需的 B10。
- 增加定量阈值：5x setup/materialization、1.5x p99 内核基线边界、2x FUSE
  阈值和置信区间门槛。
- 增加消融到审稿人问题的映射。
- 增加发布级 `manifest.json` 结构，要求每个论文图表单元追到
  原始路径、commit、kernel config、policy hash、baseline config、seed、
  repetition 和 analysis version。
- 把残余不确定性绑定到 C1-C7。
- 标记 Phase 1 `make phase1` 为只做健康检查，永远不支撑论文主张。

## 第二轮独立审查

独立 subagent 重新审查修订版，结论是：

- 当前成熟度：Level 4（计划标准）。
- 必须修复的问题：无。

审查确认：

- U4 宏基准证据已由 W5、B6、R075 覆盖。
- 量化成功标准已包含 5x、1.5x、2x 和置信区间门槛。
- 基线身份和功能等价门槛已明确。
- same-parent vs target-registry capability gate 已明确。
- 冻结工作负载套件已达到计划层要求。
- B10 失败语义是必需项。
- 消融审稿问题、U2 范围、残余不确定性、发布清单结构和 Phase 1 冒烟测试声明
  均已接受。

## 本轮中文重写

用户要求“文档要全部中文写”，并指出工作负载应来自真实来源和生产应用，不能靠
自造工作负载。对应修订为：

- 删除英文模板式标题，改为中文标题和中文解释。
- 将工作负载规则提前到评估原则中：主实验必须来自真实应用、真实构建、真实包
  环境、真实启动路径或真实 trace replay。
- 明确禁止用 hello-world 服务、玩具构建、随机包目录树支撑 B3-B6 的
  主性能结论。
- 将真实工作负载表改为 W1-W5：
  - W1：Redis、nginx、SQLite、BusyBox 等真实开源项目构建；
  - W2：W1 生成的真实 file-operation trace replay；
  - W3：nginx、Redis、PostgreSQL、Grafana、Ghost 等真实服务启动/root tree；
  - W4：Apache Airflow、JupyterLab、Ghost、Next.js、PostgreSQL tooling 等真实
    包和开发环境；
  - W5：Git、PostgreSQL、FFmpeg、nginx modules 或 autotools projects 的真实
    configure/plugin/config 路径工作负载。
- 保留合成输入的合法位置：B1 正确性边界、B2 机制微基准、B7 一致性、
  B9 规模、B10 失败语义。

## 本轮补充：工作负载目录布局

用户要求记录：工作负载放在 workload 文件夹，每个 workload 的所有启动脚本和
配置都放在该 workload 对应的子文件夹内。对应修订为：

- 评估文档新增“工作负载目录布局”。
- 发布级真实工作负载统一放在顶层 `workload/`。
- 每个具体工作负载使用 `workload/<workload-id>/` 子目录。
- workload 子目录保存自己的启动入口、Makefile 片段、服务配置、构建配置、
  lock file、输入 manifest、alias manifest、oracle 配置、trace 参数、版本、
  URL、SHA256、许可证和 provenance。
- `bench/workloads/` 只保留项目自带低层基准源码，不作为真实应用 workload 的
  配置根目录。
- 为了符合项目 Makefile-only 规则，workload 子目录不新增项目自有 `.sh` 控制面。
  若真实上游应用自带脚本，只能作为上游源码 artifact 记录版本和哈希。

## 本轮补充：术语重写和 Policy 复杂度边界

用户进一步指出：旧的“命名空间视图”术语容易误导，主线应定义为
`programmable path resolution`，并且 OSDI 级 claim 需要复杂 use case 来 motivate
eBPF 可编程性。对应修订为：

- `docs/` 下作为主概念的“命名空间视图 / 命名空间策略 / 命名空间重定向”
  被重写为 `programmable path resolution`、`path-resolution policy`
  或 `path-resolution decision`。
- Linux `mount namespace` 作为既有内核机制名保留，只用于基线或相关工作对比。
- 论文主张从“命名空间重定向”改成“VFS 内的可编程路径解析”。
- 旧的“OSDI 主线只需要简单 policy”的判断被废弃。
- 新判断是：动作集合受限为 `PASS/REDIRECT`，但决策逻辑必须复杂、map-driven、
  per-workload、epoch-aware，并由 eBPF 和 BPF maps 实现。
- OSDI 主力 policy 命名为 `view_redirect.bpf.c`：使用 `view_id`、`epoch`、
  `event`、parent key、component hash/name、large alias map 和 target registry
  来计算路径解析结果。
- 保留 `pass_only.bpf.c` 作为开销下界，保留 `redirect_alias.bpf.c` 作为 Phase 1
  回归 policy。
- 不引入 YAML、JSON、自定义 DSL 或用户态 policy 解释器。复杂性必须留在
  verifier-safe eBPF 逻辑和 maps 中。
- 评估文档新增“Policy 评估方法”，明确 policy correctness、policy performance、
  policy complexity、epoch update、target registry、failure semantics 和 ablation
  的指标与通过条件。

## 剩余风险

- 真实工作负载的具体 URL、commit、发布版和 SHA256 仍需在实现评估时写入
  `configs/eval-osdi/workloads.lock` 或等价 Makefile 配置。
- 若 target registry、cross-directory redirect 或 update epoch 没有实现，
  相关使用场景只能作为附录或残余不确定性，不能支撑主结论。
- 基线实现必须真正满足功能等价门槛，否则不能作为主比较对象。
