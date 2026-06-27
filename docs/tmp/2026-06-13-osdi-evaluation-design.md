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
  - 服务启动 selected executable/library/config aliases；
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
- 当时曾把论文主线设想为单个通用 map-driven policy；这个判断已被后续
  “Policy family 多样性”修订取代。
- 保留 `pass_only.bpf.c` 作为开销下界，保留 `redirect_alias.bpf.c` 作为 Phase 1
  回归 policy。
- 不引入 YAML、JSON、自定义 DSL 或用户态 policy 解释器。复杂性必须留在
  verifier-safe eBPF 逻辑和 maps 中。
- 评估文档新增“Policy 评估方法”，明确 policy correctness、policy performance、
  policy complexity、epoch update、target registry、failure semantics 和 ablation
  的指标与通过条件。

## 本轮补充：Policy family 多样性

用户进一步指出：如果只有一个通用 map-driven policy，本质上仍可能只是内核
redirect table，不能证明一定需要 eBPF 或通用 programmable path-resolution
abstraction。对应修订为：

- `table_redirect.bpf.c` 被降级为强 baseline/ablation，不再支撑主论文主张。
- OSDI 主线改成“同一个内核 ABI 支持多类语义不同的 eBPF extension policy”。
- 当时新增四个候选 policy family：
  - `build_graph_view.bpf.c`：priority cascade，表达 generated/source/toolchain/
    external deps precedence 和 action-specific fallback。
  - `language_resolver_view.bpf.c`：parent-class dispatch + bounded resolver
    fallback，表达 Python/Node/pkg-config/dynamic-loader 类 resolver 语义。
  - `rollout_epoch_view.bpf.c`：stateful epoch selection，表达 canary、rollback、
    epoch pinning 和 binary/config/library consistency。
  - `legacy_profile_view.bpf.c`：caller/cgroup/profile dispatch + bounded fallback，
    表达 legacy path compatibility 和 backing internal name non-leakage。
- 新增 policy family 多样性门槛：四个 family 至少覆盖三种不同有界决策复杂度。
- 新增真实存在性门槛：每个支撑主张的 workload 必须在 `workload/<workload-id>/`
  下记录 `evidence.md` 或等价 Markdown，说明真实系统来源、上游 URL/release、
  为什么该系统需要这种 path-resolution 逻辑，以及 trace/workload 构造命令。
- 新增 B12 `Policy family programmability`，并在 run order 中新增
  `make eval-osdi-policy-family SAMPLES=20`。
- 新增 C8 claim gate：若四个 policy family 都退化成同一个 table lookup，或
  `table_redirect.bpf.c` 能覆盖全部主 oracle，则不能声称需要通用 programmable
  path-resolution abstraction。

## 本轮补充：Policy family 对抗评审

按用户要求，独立 subagent 使用 `osdi-experiment-design` skill 对
`docs/experiment-plans/osdi-evaluation.md`、`docs/research_plan.md` 和本记录做了
敌对 OSDI reviewer 式审查。审查结论是：当前计划是强 Level 3，接近 Level 4，但
`programmable abstraction` 主张仍可能被攻击为“只是换名字的 redirect table”。

必须修复的问题：

1. C8 不能只写“eBPF 可编程性必要”，必须定义 table-only 反事实的 key space、
   update 能力、内存预算、更新预算和过度物化门槛。
2. 四个 policy family 不能只共用泛化 checker，必须有逐 family 的 semantic
   witness、必须触发的分支、oracle、table-only 预期失败和降级规则。
3. 真实 workload 不能只是“真实项目名字 + 自造 alias manifest”，必须记录 alias
   manifest 来源、生成命令、trace/lock/resolver/service layout/probe provenance
   和 alias 命中率。
4. C1 的无条件强 abstraction wording 必须收窄到已实现并通过 KVM gate 的
   ABI 能力。
5. B12 / `make eval-osdi-policy-family` 必须有固定结果路径、row-level
   reproducibility contract、oracle binary/checker、table-only comparator 和失败
   降级矩阵。

## 本轮修订：B12 和 C8 反事实门槛

根据对抗评审，评估文档补充了以下内容：

- C1 改为“同一窄 VFS path-resolution ABI 能在已测读多写少、元数据密集场景中
  承载多类真实 eBPF policy family”，避免把尚未实现的 target registry、cross-
  directory redirect 或 update epoch 直接纳入主张。
- C8 改为“在同等 table budget 和 update budget 下，静态 table-only baseline
  无法同时满足已测 policy-family oracle 和成本门槛”。
- `table_redirect.bpf.c` 被明确定义为公平的 table-only baseline：可以使用 ABI
  暴露的上下文 key，但只能 exact map lookup，不能实现 fallback、resolver、epoch
  state machine、隐藏 rule engine 或用户态 policy 解释器。
- 新增 table-only 反事实指标：table entries、map memory、update writes、update
  latency、stale window、oracle violation 和 budget result。
- 新增默认 over-materialization 门槛：table-only 为通过同一 oracle 需要超过
  programmable policy 10x 的 map entries、map memory、update writes，或超过
  workload 声明的 update latency/stale-window 门槛。
- 新增逐 family semantic witness 表：
  - build graph 必须触发 generated hit、source fallback、toolchain selection、
    external dep 和 negative miss；
  - language resolver 必须触发 project override、profile fallback、ABI/platform
    package、loader/pkg-config parent class 和 negative miss；
  - rollout epoch 必须触发 stable、canary、rollback 和 same-group epoch
    consistency；update epoch 未实现时该 family 只能 blocked/appendix；
  - legacy profile 必须触发 caller-specific override、compat fallback、direct
    pass-through 和 internal-name filtering。
- 新增真实 workload 真实性门槛：`workload/<workload-id>/evidence.md` 必须记录
  alias manifest 来源、生成 Make target、输入/输出 hash、redirected operation 的
  operation-weighted hit rate 和 raw result path。支撑 C1/C8 的 run 中，至少
  80% redirected operations 必须命中 provenance-derived aliases。
- B12 的结果根目录固定为
  `results/eval-osdi/paper/<run-id>/b12-policy-family/`，每个 family/workload row
  必须记录 seed、repetition、variant order、oracle/checker、table-only comparator
  config、decision gate 和 raw failure path。
- `manifest.json` 增加 `policy.branch_coverage`、`workload.alias_manifest_source`、
  `workload.alias_hit_rate`、`workload.evidence_path` 和 `table_counterfactual.*`
  字段。
- `docs/research_plan.md` 中较强的 container/rootfs 语言被收窄为 service startup
  selected executable/library/config aliases；完整 rootfs composition 需要单独 oracle。

## 第二轮对抗评审

独立 subagent 再次使用 `osdi-experiment-design` skill 审查修订后的文档，结论是：

- 成熟度：Level 4（计划级，条件通过第二轮评审）。
- Must-fix：无。
- 关键条件：不能把 `rollout_epoch_view.bpf.c` 在 update epoch 未实现时硬算进四类
  C8 证据；如果 update epoch 没实现且没有替代的第四个 qualifying family，C8 只能
  partial。

第二轮建议继续收紧：

1. 把 C1/B12 的“四类 policy family”改成“四类已实现并通过 KVM gate 的
   qualifying family”。
2. 给 table/update budget 增加显式字段：`max_entries`、`max_memory_bytes`、
   `max_update_writes`、`max_update_latency_ms`、`max_stale_window_ms` 和
   `budget_basis`。
3. 删除或收窄残留的 root/container-view 类术语和 B12 中的无条件强 abstraction
   wording。
4. B12 增加 row result enum：
   `qualified_for_c8`、`functional_only`、`appendix`、`blocked`、`unsupported`。
5. 为 `table_redirect.bpf.c` 增加 conformance check，证明它只做 exact map lookup，
   没有偷偷实现 fallback、resolver、epoch state machine 或 rule interpreter。

## 第二轮修订

根据第二轮评审，文档进一步修订为：

- C1 和 B12 成功标准改为只统计 qualifying policy family。qualifying 的定义是：
  已实现、通过 B1/B10/B12 KVM gate、满足 semantic witness、真实来源证据、
  alias hit-rate 和 table-only counterfactual，并在 B12 row 中标记
  `qualified_for_c8`。
- `rollout_epoch_view.bpf.c` 在 update epoch 未实现前只能是 `blocked` 或
  `appendix`，不能填补 C8 四类 family 证据门槛。
- B12 的目的改成“同一个窄 VFS path-resolution ABI 支持已测多类读多写少、
  元数据密集的 eBPF path-resolution extensions”，不再使用无条件“通用
  programmable abstraction”表述。
- table-only budget 在 manifest 中增加 `max_entries`、`max_memory_bytes`、
  `max_update_writes`、`max_update_latency_ms`、`max_stale_window_ms` 和
  `budget_basis`。
- table-only 反事实增加 `conformance_check_path`，发布级 run 必须保存 source
  hash、object hash、verifier log 和 checker output，证明 `table_redirect.bpf.c`
  只做 exact map lookup 和 `PASS/REDIRECT`。
- B12 row 增加 `row_result`，只允许
  `qualified_for_c8`、`functional_only`、`appendix`、`blocked`、`unsupported`；
  只有 `qualified_for_c8` 可以被 C1/C8 计数。
- B4、W3、R060 和 use case wording 从早期 container/root-style wording 收窄为
  service startup selected aliases；早期 container-named target 被计划级 target
  `make eval-osdi-service-startup` 取代。

## 最终快速复审

同一 subagent 对第二轮修订后的当前工作区做最终快速复审，结论是：

- 通过 Level 4 计划级评审。
- Must-fix：无。
- 没有会阻止开始 Phase 1 实现的评估设计问题。
- 剩余风险：C8 仍取决于最终能否拿到至少四个 `qualified_for_c8` family；尤其是
  `rollout_epoch_view.bpf.c` 需要 update epoch，或需要另一个替代 qualifying
  family，才能计入四类证据门槛。

## 剩余风险

- 真实工作负载的具体 URL、commit、发布版和 SHA256 仍需在实现评估时写入
  `configs/eval-osdi/workloads.lock` 或等价 Makefile 配置。
- 若 target registry、cross-directory redirect 或 update epoch 没有实现，
  相关使用场景只能作为附录或残余不确定性，不能支撑主结论。
- 基线实现必须真正满足功能等价门槛，否则不能作为主比较对象。

## 本轮补充：从 fault injection/rollout 替换为 checkpoint/restore

本节覆盖前面“最终快速复审”之后的新决策；此前通过结论只适用于旧四类 family，
不再作为当前 revision 的通过状态。

用户指出 `fault_injection_view` 更像测试方法，而不是一个能支撑主论文 claim 的
独立 policy family，并建议换成 checkpoint/restore。对应判断是：应该替换。
原因如下：

- fault injection 属于 B10 健壮性和失败语义，用来证伪系统边界；它本身不自然形成
  一个 production path-resolution extension。
- checkpoint/restore 是真实系统功能路径：恢复后的 workload 需要同时满足
  checkpointed state/config/cache 一致性和 runtime-local socket/pid/temp path
  重绑定。
- `checkpoint_restore_view.bpf.c` 的算法语义与 build graph、test fixture 和 cache
  locality 都不同：它以 `restore_id`、`checkpoint_epoch`、path class 和 checkpoint
  manifest 为输入，要求 0 mixed checkpoint/current view。
- update epoch 未实现前，checkpoint 的 `epoch` 只能表示 restore session 内的一致性
  检查，不能借此声称支持 dynamic rollout 或在线版本切换。

本轮资料搜索和外部依据：

- Build graph：Bazel sandboxing、hermeticity、dependencies 和 toolchains 文档说明
  真实构建系统需要 known inputs、declared dependencies、toolchain selection 和
  reproducibility/cache correctness。
- Sandbox fixture：Kubernetes projected volumes、Kubernetes Secrets、Docker Compose
  configs/secrets 说明真实部署和测试环境会把 config、secret、token 或 host-provided
  files 注入 workload。
- Checkpoint/restore：CRIU checkpoint/restore、CRIU external bind mounts、Podman
  checkpoint/restore 和 DMTCP path virtualization 论文说明 restore 常需要把 checkpoint
  image 中的路径和新运行环境中的 external/runtime-local path 重新对应起来。
- Cache locality：Bazel remote caching、Bazel remote execution API、ccache、Nix
  binary cache/substituter 和 Nix content-addressed store 说明真实构建/包系统普遍依赖
  content-addressed cache，且必须用 hash/canonical output 判定 stale/corrupt cache。

本轮修订：

- `docs/experiment-plans/osdi-evaluation.md` 的四个主线 policy family 改为
  `build_graph_view.bpf.c`、`sandbox_fixture_view.bpf.c`、
  `checkpoint_restore_view.bpf.c` 和 `cache_locality_view.bpf.c`。
- 删除主矩阵中 `language_resolver_view.bpf.c`、`rollout_epoch_view.bpf.c` 和
  `legacy_profile_view.bpf.c` 的主线位置；它们只保留为 appendix/candidate family，
  不能填补 C8 四类证据门槛。
- B12 矩阵、semantic witness、policy evaluation、workload W1-W5、baseline 表、
  B3-B6 细节、run order、manifest 字段和残余不确定性同步更新。
- `docs/research_plan.md` 的 OSDI-style framing、motivation、use cases、
  evaluation macrobenchmarks 和 research questions 同步更新为 build graph、
  fixture substitution、checkpoint/restore 和 content-verified cache locality。

本轮独立 subagent 搜索和审查结论：

- Subagent 认为四类 family 比旧版本更真实、更分散，也更能支撑“一个通用
  programmable path-resolution abstraction 支持多类 extension”的 claim。
- Subagent 的 must-fix 是：每类 family 必须写清 claim、oracle、baseline、failure
  gate、至少两个真实 workload/trace rows、table-only counterfactual 和 KVM
  verifier/dmesg 证据。
- 本轮文档已补齐这些字段，并已再次让 subagent 按 OSDI rubric 复审当前 revision。

## 本轮最终复审结论

独立 subagent 对当前 revision 的只读复审结论是：`pass`，达到 OSDI Level 4 计划级。
该结论不是结果级支持；C1/C8 仍然必须等真实 KVM 运行、verifier/dmesg 证据、
workload provenance、semantic witness 和 table-only counterfactual 全部通过后才能
写成论文结果。

Must-fix：无。

复审确认：

- `checkpoint_restore_view.bpf.c` 比 `fault_injection_view` 更适合作为独立 policy
  family；fault injection 留在 B10 健壮性/失败语义。
- 当前四类主线 family 覆盖 priority cascade、path-class fixture substitution、
  restore-session/checkpoint consistency 和 content-hash/cache-state dispatch，足以在
  计划级支撑多类 extension claim。
- 旧的 `language_resolver_view.bpf.c`、`rollout_epoch_view.bpf.c` 和
  `legacy_profile_view.bpf.c` 只作为 appendix/candidate 出现，不计入 C8。
- 文档已为每类 family 规定真实来源、oracle、baseline、table-only counterfactual、
  failure gate、workload provenance、KVM/verifier/dmesg 证据和降级规则。
