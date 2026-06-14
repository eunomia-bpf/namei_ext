# namei_ext 的 OSDI 级评估设计

最后更新：2026-06-13
阶段：实验设计
来源：用户要求把多使用场景评估设计改成中文，并要求工作负载来自真实应用或真实生产来源，而不是自造玩具程序。

## 论文主张

`namei_ext` 的目标不是实现一个新的文件系统，也不是做访问控制。它是在 VFS
路径解析和目录枚举路径上提供一个 eBPF 决策点，让同一个路径名可以按工作负载、
版本 epoch、依赖图和执行上下文解析到不同 backing object，同时让内核继续拥有
dentry、inode、permission、mount traversal、page cache 和 lower filesystem
file operations。

论文级主张是：

```text
对元数据密集、读多写少的生产级路径解析定制，namei_ext
可以用 VFS 内的 eBPF path-resolution policy 表达真实系统中的动态路径解析需求，
减少复制目录树、符号链接森林、mount fanout 或 FUSE 路径重映射的物化成本和
用户态文件系统成本，同时保留 lower filesystem 的语义。
```

这不是 Phase 1 冒烟测试结论。Phase 1 只证明 `PASS/REDIRECT` ABI、KVM
产物流、同父目录重定向、lookup/readdir 一致性的最小 PoC 能跑通。任何进入
论文的性能或通用性结论，都必须来自本文档定义的发布级实验。

## 评估原则

1. 主实验必须来自真实应用、真实构建、真实包环境、真实启动路径或真实 trace
   replay。不能用自造玩具应用支撑论文主结论。
2. 合成数据只允许用于三类目的：ABI/正确性覆盖、规模/饱和测试、失败语义。
   合成数据不能支撑“对真实工作负载更快”这种主结论。
3. 每个论文主张必须有可证伪实验、明确判定器和降级规则。
4. `native-direct` 只能作为下界对照，不是功能等价基线。
5. 所有发布级结果必须在改过的内核的 KVM guest 中产生；host-only
   结果只能作为开发诊断。
6. Policy 是 `bpf/policies/*.bpf.c` 下的 eBPF 程序。评估配置可以是 Makefile
   或 lock file，但不能把 YAML/JSON policy 语言引入项目语义。
7. 所有构建、运行、benchmark、分析、报告都必须由 Make target 驱动。
8. 原始 JSONL、日志、dmesg、配置、哈希和 provenance 必须保存在 `results/`；
   论文表格、比例、置信区间和解释只能由显式分析/报告 target 生成。

## 论文主张前置门槛

任何使用场景进入论文主张前，必须先通过这些门槛：

1. **可表达性门槛**：该场景的 alias/backing 关系能由已实现 ABI 表达。若需要
   target registry、cross-directory redirect 或 update epoch，必须先有设计
   文档、ABI 测试、功能测试、失败测试和 KVM 干净运行。
2. **正确性门槛**：`lookup`、`open`、`access`、`read`、`execve`、`readdir`
   的判定器全部通过，lower filesystem permission 行为不能被绕过。
3. **基线门槛**：至少包含一个功能等价的物化基线和一个强内核基线；
   native direct path 只能作为下界对照。
4. **重复门槛**：论文数字来自发布级运行，不来自 `SAMPLES=1` 冒烟运行。
5. **完整性门槛**：每个图表单元都能追到原始路径、commit、dirty 状态、内核镜像
   哈希、policy 哈希、基线配置、seed/repetition、dmesg 和分析版本。

默认阈值如下；如果运行前需要调整，必须先修改本文档和 tracker：

- 正确性：0 个 checker failure，0 个 unexpected errno，0 条 dmesg warning、
  oops、panic。
- setup/materialization：在中型/大型真实工作负载上，`namei_ext` 的 p50
  setup 延迟或创建对象数量至少比 `copy-tree-cp`、`symlink-forest-ln` 或
  mount-heavy 基线好 5x，否则不能声称物化成本优势。
- 稳态运行：主要元数据操作的 p99 延迟不超过最佳功能等价内核基线的 1.5x，
  并且相对 `fuse-redirectfs` 至少有 2x p99 优势；否则不能声称接近内核机制或
  优于 FUSE。
- 宏基准端到端：必须同时报告 setup 和 execution。若总 wall time 没有改善，
  只能声称减少物化成本，不能声称端到端加速。
- 规模：论文主张只能覆盖 0 个语义失败时的最大 alias 数、
  cgroup/worker 数和 path depth。
- 统计：微基准至少 30 次重复，宏基准至少 20 次重复，报告 median、p95、p99、
  95% bootstrap 置信区间、绝对值和相对值。置信区间跨过阈值边界时，主张必须
  标为部分支持或结论不充分。

## 论文主张台账

| ID | 主张 | 范围 | 必需证据 | 状态 |
|----|------|------|----------|------|
| C1 | `namei_ext` 能表达真实的每工作负载可编程路径解析场景，而不实现文件数据路径。 | 构建沙箱、容器/服务启动的选定路径别名、包和开发环境、遗留路径迁移；读多写少。 | 每个场景的真实应用或真实 trace、正确性判定器、宏基准或 trace replay、目录视图一致性。 | 已规划 |
| C2 | 对动态路径解析定制，`namei_ext` 的 setup/materialization 成本低于复制目录树、符号链接森林和 mount-heavy 设计。 | 真实应用上的 100 到 100k aliases/components；1 到 512 个并发工作负载。 | setup latency、created files/symlinks/mounts、disk writes、memory、CPU。 | 已规划 |
| C3 | 在元数据密集执行中，`namei_ext` 的 p99 元数据开销满足 kernel/FUSE 阈值。 | 热/冷缓存 lookup、open、stat、access、exec、getdents、真实宏基准工作负载。 | p50/p95/p99、throughput、context switches、CPU cycles、cache/resource metrics。 | 已规划 |
| C4 | lookup 和 readdir 由同一 path-resolution policy 决定，可以保持路径解析和目录枚举一致。 | 所有主场景的 alias/backing mapping；并发 lookup/readdir/update stress。 | property checker：lookup 可达集合等于 readdir 可见集合。 | 已规划 |
| C5 | 主要收益来自 VFS-level policy placement 和 lower-FS ownership，而不是 benchmark artifact。 | no-hook、pass-only、redirect、no-readdir、FUSE、symlink、bind/OverlayFS 消融。 | 机制隔离实验；每个消融回答一个审稿人问题。 | 已规划 |
| C6 | 系统在规模、churn、缓存状态和对抗性路径下有明确边界和快速失败语义。 | aliases、path depth、workers/cgroups、policy size、热/冷缓存、unsupported mutations。 | 规模曲线、饱和点、失败语义、dmesg/verifier/runtime evidence。 | 已规划 |
| C7 | artifact 可以由独立审稿人从 Makefile 复现。 | KVM、Docker runtime、配置即代码、原始结果采集。 | `make eval-osdi-smoke` 和 `make eval-osdi-paper` 的结果根目录、哈希、镜像 ID、报告门禁。 | 已规划 |

## 主张到实验的映射

| 主张 | 必需证据 | 主实验块 | 证伪结果 | 部分支持时的降级表述 |
|-------|----------|----------|----------|----------------------|
| C1 | 四个场景都通过正确性 oracle，且 U1-U4 都有真实应用宏基准或真实 trace replay。 | B1, B3, B4, B5, B6, B7 | 某场景只能用合成循环表达，或当前 ABI 不可表达。 | `namei_ext` 支持若干读多写少的可编程路径解析场景，不声称覆盖全部文件系统语义。 |
| C2 | setup/materialization 至少 5x 优于物化基线，并有原始 artifact 证明对象数量。 | B3, B4, B5, B6, B9 | setup 开销不低于基线，或需要等量 materialization。 | 只声称特定工作负载的机制可行，不声称 materialization 优势。 |
| C3 | p99 满足 1.5x 内核基线和 2x FUSE 阈值，并报告尾延迟。 | B2, B3, B4, B5, B6, B8 | p99 或吞吐明显差于内核基线且无法解释。 | 收窄为功能机制，不主张接近内核基线。 |
| C4 | checker 在宏基准和压力测试中证明 lookup/readdir view 一致。 | B1, B7 | readdir 列出不可 lookup 的 alias，或 lookup 可达但 readdir 缺失。 | 只声称 lookup redirect，不声称目录视图一致性。 |
| C5 | 消融证明 VFS hook placement 和 lower-FS data path 是主要机制。 | B8 | 更简单基线在主要工作负载上同样满足 oracle 和阈值。 | 改成权衡或 artifact 主张。 |
| C6 | 规模/压力/失败测试证明边界清楚，且不 panic、不静默降级。 | B9, B10 | fail-open、kernel warning/oops、或静默错误结果。 | 收窄规模，或把失败模式列为限制。 |
| C7 | 干净 checkout 能用一条 Make pipeline 复现发布级产物。 | B11 | 依赖手动状态、dirty tree、缺配置或缺原始结果。 | artifact 主张降级为 prototype-only。 |

## 被测系统模型

- 组件：改过的 Linux kernel、VFS lookup/readdir hooks、cgroup BPF attach
  path、BPF policy object、可选 BPF maps、benchmark harness、真实工作负载
  runner、result collector、analysis target。
- 持久状态：lower filesystem 的真实应用源码、依赖树、root view、package
  store、trace files；`results/eval-osdi/<run-id>/` 下的原始 artifacts。
- 信任边界：BPF 只能返回 `PASS` 或受限 `REDIRECT`；kernel 负责 redirect 输出
  校验、lookup、permission、dcache、inode、file operations、mount traversal。
- 保证：lookup/readdir 一致性、lower filesystem permission preservation、
  verifier/runtime/load/attach failure fail-fast。除非后续实现并测试，不声称
  writable union semantics。

## 使用场景可表达性门槛

| 场景 | 需要的最小 ABI 能力 | 当前 Phase 1 状态 | 论文评估门槛 |
|------|--------------------|------------------|--------------|
| U1 构建沙箱 / CI action view | 合成包目录树可用 same-parent redirect；真实共享 store 通常需要 target registry 或 cross-directory redirect。 | 合成子集可表达；真实 store mapping 被阻塞。 | 若使用真实 store path，必须先实现 target-registry ABI，并通过 B1/B10。 |
| U2 容器/服务启动 selected root-view alias | 选定 executable/library/config aliases 可用 same-parent redirect；完整 rootfs composition 不在当前主张范围内。 | selected-alias 子集可表达；不声称替代完整 container rootfs。 | B4 只能声称 selected path aliases；OverlayFS 是上下文和强基线，不是完整等价替代。 |
| U3 包和开发环境 | generated per-directory aliases 可用 same-parent redirect；直接 store-to-project mapping 通常需要 target registry。 | generated package view 可表达；global store mapping 被阻塞。 | 若评估真实 store paths，必须先实现 target registry。 |
| U4 遗留路径迁移 | 静态本地兼容 alias 可用 same-parent redirect；在线版本切换需要 update epoch。 | 静态本地 alias 可表达；在线切换主张被阻塞。 | B6 静态宏基准必须跑；policy-switch 行只有实现 update epoch 后才能进入主张。 |

## Policy 设计范围

本项目的 policy 是 `bpf/policies/*.bpf.c` 下的 eBPF 程序，不是 YAML、JSON 或
自定义 DSL。OSDI 主张需要可编程性，但可编程性应该体现在 verifier-safe eBPF
逻辑、BPF maps、per-workload context 和版本化 view state 上，而不是体现在用户态
policy 解释器或无限制动作集合上。

核心原则是：

```text
动作集合受限：PASS / REDIRECT
决策逻辑可编程：event + parent + component + view_id + epoch + maps
文件系统语义仍由内核和 lower filesystem 拥有
```

计划中需要三类 policy：

- `pass_only.bpf.c`：只返回 `PASS`，用于度量 attach/static-branch 和 BPF 调用
  之后的剩余开销。
- `redirect_alias.bpf.c`：Phase 1 回归 policy，对固定 `(event, component)` 做
  精确匹配，返回 `PASS` 或 same-parent `REDIRECT`。
- `view_redirect.bpf.c`：OSDI 主力 policy。它是 map-driven 的可编程路径解析
  policy，用 `view_id`、`epoch`、`event`、parent key、component hash/name 和
  target registry 计算 `PASS/REDIRECT`。lookup 和 readdir 必须通过同一套 view
  state 保持一致。

`view_redirect.bpf.c` 必须覆盖真实 workload 所需的复杂性：

- 每个 cgroup/workload 有独立 `view_id`；
- 支持 epoch，用于 canary、rollout、rollback 和 atomic view switch；
- 支持大规模 alias map，目标规模覆盖 100、1k、10k、100k entries；
- 支持 parent-specific rule，而不是全局 component rewrite；
- 支持 target registry，用于 cross-directory backing；
- 支持 lookup/readdir 共用 view state，避免 `open()` 能看到而 `ls/find/glob`
  看不到；
- 支持 collision handling、missing-entry fallback、invalid-target fail-fast；
- 支持 verifier-safe bounded logic，不能依赖递归路径解析或用户态回调。

不进入 Phase 1 主线的语义包括 hide、deny、权限决策、文件数据路径、writable
union、递归路径解析、用户态 policy 解释器和 YAML/JSON policy DSL。评估可以有
alias manifest、trace 参数和 oracle 配置，但这些是 workload 输入和实验判定材料，
不是 `policies/` 下的 policy 语言。

因此论文的设计目标是证明：受限动作集合加上复杂、map-driven、per-workload 的
eBPF path-resolution decision，足以覆盖若干真实、读多写少、元数据密集的生产
场景，并且比 FUSE 或物化目录树更接近内核机制。

## Policy 评估方法

Policy evaluation 不是只看 BPF object 能否加载。它必须回答两个 reviewer 问题：

1. 为什么必须用 eBPF 可编程路径解析，而不是静态 redirect table、mount、symlink
   或 FUSE？
2. 复杂 policy 是否仍然可验证、可复现、低开销，并且不破坏 VFS/lower filesystem
   语义？

每个发布级运行至少包含以下 policy 变体：

| Policy | 目的 | 必测场景 | 关键指标 | 通过条件 |
|--------|------|----------|----------|----------|
| `no_policy` | 无 attach 下界。 | B2, B8 | lookup/readdir p99、throughput。 | 作为下界，不支撑功能主张。 |
| `pass_only.bpf.c` | 隔离 static branch、attach 和 BPF call 开销。 | B2, B8 | p50/p99、cycles、instructions。 | p99 不超过 `no_policy` 1.1x，否则需要解释或优化。 |
| `redirect_alias.bpf.c` | Phase 1 same-parent 回归。 | B1, B2, B11 | correctness、readdir coherence、KVM gate。 | 0 checker failure，0 dmesg failure。 |
| `view_redirect.bpf.c` basic | 证明 generic map-driven path resolution。 | B1, B3-B7 | oracle pass、setup、p99、map memory。 | 所有真实 workload oracle 通过。 |
| `view_redirect.bpf.c` epoch | 证明 canary/rollback/update 复杂性。 | B4, B6, B7, B10 | update latency、mixed-epoch violation、rollback latency。 | 0 mixed epoch，update/rollback 有 raw latency。 |
| `view_redirect.bpf.c` target registry | 证明 cross-directory backing。 | B3, B5, B6, B10 | registry lookup p99、invalid-target failure、permission preservation。 | invalid target fail-fast，lower permission 不被绕过。 |

Policy correctness 使用 materialized oracle。对每个真实 workload，先生成一个
feature-equivalent 的 materialized ground truth（copy/symlink/bind 中能表达者），
再比较 `namei_ext` 下的：

- `statx/open/access/read/execve` 的 errno、内容 hash 和目标版本；
- `getdents64/find/glob` 的 visible name set；
- negative lookup 和 fallback 行为；
- lower filesystem permission failure；
- epoch 切换前后的 lookup/readdir 一致性。

Policy performance 必须拆成三层：

- policy dispatch overhead：`no_policy` vs `pass_only.bpf.c`；
- simple redirect overhead：`pass_only.bpf.c` vs `redirect_alias.bpf.c`；
- programmable decision overhead：`redirect_alias.bpf.c` vs `view_redirect.bpf.c`
  的 basic、epoch、target-registry 变体。

Policy complexity 不能只用代码行数描述，必须记录：

- BPF instruction count；
- verifier time；
- map 数量、map entry 数量、map memory；
- 每次 lookup/readdir 的 map lookup 次数；
- tail latency 随 alias entries、parent fanout、path depth、cgroup 数的变化；
- rejected program、invalid map update、invalid target 和 missing entry 的失败证据。

Policy ablation 必须能证伪“复杂可编程性有必要”：

- 去掉 `view_id`：不同 workload 是否会互相污染；
- 去掉 `epoch`：rollout/rollback 是否出现 mixed view；
- 去掉 target registry：真实 package/build workload 是否被迫退化到 same-parent；
- 去掉 readdir handling：`open()` 和 `ls/find/glob` 是否不一致；
- 把 policy 固化成静态 table：是否失去 per-workload/per-epoch update 能力。

这些结果进入 B8 机制消融、B9 规模压力和 B10 失败语义。若 `view_redirect.bpf.c`
在真实 workload 上没有比静态 table、symlink、bind 或 FUSE 展示出明确收益，
论文主张必须从“programmable path resolution is needed”降级为更窄的 artifact
或机制探索主张。

## 真实工作负载清单

发布级运行必须使用真实公开来源或真实 trace。下表是计划级锁定清单；实现时必须
在 `configs/eval-osdi/workloads.lock` 或等价 Makefile 配置中记录 URL、commit 或
发布版、tarball SHA256、依赖版本、命令、trace 命令和许可证。替换任何条目都
会开启新的 run family，不能与旧数字直接混用。

| ID | 场景 | 真实来源 | 规模和操作混合 | 冻结方式 | 代表性 |
|----|------|----------|----------------|----------|--------|
| W1 | U1 | Redis、nginx、SQLite 或 BusyBox 的固定发布版源码构建。 | 小/中型 C/C++ 生产项目；100、1k、10k alias manifests；1/16/64/256 action cgroups。 | source SHA256、compiler version、build command、alias manifest、`strace -ff -e trace=file` trace。 | 真实 CI/build action 会反复构造 tool/include/lib view。 |
| W2 | U1 | W1 构建产生的真实 file-operation trace replay。 | 至少 1M path operations；lookup/open/stat/access/getdents 比例来自 trace；cache-hot/cold。 | trace JSONL 包含 op、path、cwd、result class、timestamp order、seed。 | 去掉 compiler nondeterminism，保留真实路径访问分布。 |
| W3 | U2 | 真实生产服务启动：nginx、Redis、PostgreSQL、Grafana 或 Ghost 的固定发布版/container root。 | 1/32/128/512 workers；selected executable、library、config aliases；冷/热缓存。 | root tree manifest、service config、request/check command、response checksum、startup trace。 | 服务启动和依赖加载是容器/serverless 的真实元数据密集路径。 |
| W4 | U3 | 真实包和开发环境：Apache Airflow、JupyterLab、Ghost、Next.js、PostgreSQL client/tooling 等固定发布版的依赖环境。 | 100、10k、100k files；1/100/1000 env creations；command startup/import/configure。 | lock file、package manifest、generated view manifest、command output hash、loader/pkg-config trace。 | 生产项目的开发环境会把稳定项目路径映射到版本化依赖。 |
| W5 | U4 | 真实 configure/plugin/config 路径工作负载：Git、PostgreSQL、FFmpeg、nginx modules 或 autotools projects 的固定发布版。 | 10/100/1k legacy aliases；static mapping；可选 version-switch epoch。 | configure script version、plugin/config tree manifest、alias epoch log、output hash。 | 真实遗留应用会探测固定 tool/config/plugin 名字。 |

禁止把自造 hello-world HTTP 服务、手写玩具构建、随机生成包目录树作为 B3-B6
的主性能结论。它们只能用于 B1/B2/B7/B9/B10 的机制、scale 或 failure 覆盖。

## 工作负载目录布局

发布级评估的真实工作负载统一放在顶层 `workload/` 目录。每个具体工作负载必须
有自己的子目录，例如 `workload/w1-redis-build/`、`workload/w3-nginx-startup/`
或 `workload/w4-airflow-env/`。`bench/workloads/` 只保留项目自带的低层基准
源码，不作为真实应用 workload 的配置根目录。

每个 `workload/<workload-id>/` 子目录必须包含该工作负载自己的全部启动入口和
配置，包括：

- workload-local `Makefile` 或被顶层 Make target include 的 Makefile 片段；
- 服务配置、构建配置、lock file、输入 manifest、alias manifest 和 oracle 配置；
- trace 采集或 replay 的参数文件；
- 固定版本、上游 URL、commit/release、tarball SHA256、许可证和 provenance 记录；
- 预期输出 hash 或 checker 所需的参考文件。

启动逻辑仍然必须由 Make 驱动。不要在 workload 子目录里新增项目自有 `.sh`
脚本作为控制面；如果某个上游真实应用自带脚本，必须作为上游源码的一部分记录
其版本和哈希，不能把它变成项目的 orchestration API。生成的源码包、解压树、
构建产物、trace 和结果分别进入 `.cache/`、`.build/` 或 `results/`，不要混进
`workload/`。

## 基线身份和公平性

| 基线 ID | 实现身份 | 发布配置 | 等价性规则 |
|---------|----------|--------------|------------|
| `native-direct` | 同一 KVM guest 内直接访问 lower filesystem path。 | ext4 lower tree；无 path-resolution policy；相同 cache mode。 | 只作为下界对照，不是功能等价基线。 |
| `copy-tree-cp` | Make target 使用 `cp -a --reflink=never --preserve=all` 按 alias manifest 复制。 | 每个工作负载/cgroup 一个 copy；setup/teardown 分开计时。 | 当复制树暴露相同 alias 名字并保留 lower permissions 时等价。 |
| `symlink-forest-ln` | Make target 为每个 alias 创建 `ln -s`。 | absolute/relative mode 固定；symlink 数记录到 manifest。 | 对 read-mostly alias view 等价；symlink 语义差异必须由 checker 记录。 |
| `bind-fanout-mount` | Linux bind mounts in private mount namespace。 | `MS_BIND`、recursive/private propagation flags、mount count 记录。 | 只对可表示为 mount point 的 aliases 等价。不可表示项是显式基线缺口。 |
| `overlayfs-kernel` | Linux OverlayFS。 | committed lower/upper/workdir layout；mount options 记录。 | U2 的强 kernel baseline；除非 namei_ext 实现完整 rootfs surface，否则不做完整 rootfs 等价 claim。 |
| `fuse-redirectfs` | 项目自带 libfuse low-level path-remapping filesystem，由 Make 构建。 | FUSE mount options、cache flags、worker count、source hash 记录。 | 灵活命名空间基线；任何 unsupported operation 是 hard failure。 |
| `language-native-env` | venv、npm/pnpm、profile-style symlink 等生态内置机制。 | exact command、lock file、package manifest 记录。 | 只对 U3 等价。 |
| `wrapper-rewrite` | 项目自带 wrapper，在 exec 前重写 legacy path。 | wrapper source hash 和 rewrite table 记录。 | 只对 U4 等价；不是 VFS path-resolution baseline。 |

每个基线行必须记录 `feature_equivalent=true/false`。非等价基线可以作为上下文，
但不能作为主张的主比较对象。unsupported baseline operation 是 hard failure，
除非在运行前明确标为范围外。

## 实验矩阵

| 块 | 主张 | 实验 | 基线/变体 | 指标 | 判定器 | 图表 | 优先级 |
|----|-------|------|-----------|------|--------|------|--------|
| B1 | C1,C4 | 路径解析正确性和一致性矩阵 | U1-U4 的 namei_ext policies | pass/fail、errno、listed set、content hash | lookup/readdir/access/exec property checker | 表 1 | 必须 |
| B2 | C3 | 微基准成本拆分 | native、no-policy、pass-only、redirect、bind、OverlayFS、symlink、FUSE | p50/p95/p99、throughput、CPU、ctx switches | 0 个语义失败 + 置信区间 | 图 1 | 必须 |
| B3 | C1-C3 | 构建沙箱宏基准 | copy、symlink、bind、FUSE、namei_ext | setup、构建 wall time、disk writes、objects、p99 metadata | output hash + dependency manifest | 图 2 | 必须 |
| B4 | C1-C3 | 容器/服务启动的选定根视图别名宏基准 | OverlayFS、bind、symlink、FUSE、namei_ext | cold start、startup、memory/worker、disk writes | response/path version checker | 图 3 | 必须 |
| B5 | C1-C3 | 包和开发环境宏基准 | native env、symlink、copy、FUSE、namei_ext | env creation、command startup、traversal、storage | version/output/listing checker | 图 4 | 必须 |
| B6 | C1-C3 | 遗留路径迁移宏基准 | symlink、bind、wrapper、FUSE、namei_ext | setup/switch、p99 metadata、output/version | legacy output + epoch checker | 图 5 | 必须 |
| B7 | C4 | 并发下的目录视图一致性 | static mapping；若实现 update epoch 则一并测试 | checker failures、stale/mixed views、errno | lookup-set equals readdir-set per epoch | 表 2 | 必须 |
| B8 | C5 | 机制消融 | no hook、pass-only、redirect、no readdir、FUSE、symlink、每个场景的最佳简单基线 | overhead deltas、failed properties | ablation-specific oracle | 图 6 | 必须 |
| B9 | C6 | 规模和压力扫描 | aliases 10-100k、path depth 1-64、cgroups 1-512、热/冷缓存 | saturation、p99、memory、CPU、failures | 不允许静默错误结果 | 图 7 | 必须 |
| B10 | C6 | 健壮性和失败语义 | invalid redirect、verifier、unsupported mutation、detach/reload、cgroup migration | errno、dmesg、status | fail-fast、no panic/oops、no fail-open | 表 3 | 必须 |
| B11 | C7 | 可复现性和产物门禁 | 干净 checkout、Docker、KVM | exit status、manifest completeness | Make exit 0 + report gates | artifact 附录 | 必须 |

## 实验块细节

### B1. 路径解析正确性和一致性矩阵

- 目的：先证明 path-resolution policy 语义正确，否则所有性能数字都没有意义。
- 工作负载：来自 W1-W5 的真实树和真实 trace，再加生成树做边界覆盖。
- 操作：`statx`、`openat`、`access`、`read`、`execve`、`getdents64`、symlink、
  hardlink、mount crossing（仅在场景声明时）。
- 判定器：对每个 alias `a -> b`，`a` 的 lookup/open/access/read/exec 行为必须
  等于 lower path `b` 的行为；`readdir(parent)` 可见集合必须等于 policy 声明
  的 alias 集合和 pass-through 集合。
- 成功标准：0 checker failure，0 unexpected errno，0 dmesg warning/oops/panic。
- 失败解释：不能声称目录视图一致性，也不能解释宏基准结果。

### B2. 微基准成本拆分

- 目的：分离 VFS hook、BPF policy、redirect lookup、readdir rewrite 的成本。
- 工作负载：真实 trace 中抽取的操作比例，加固定 path depth/cache-state sweep。
- 指标：p50/p95/p99/p99.9、throughput、cycles、instructions、context switches、
  page faults、dentry/inode cache stats。
- 成功标准：
  - no-policy/pass-only p99 不超过 `native-direct` 的 1.1x；
  - redirect p99 不超过最佳功能等价内核基线的 1.5x；
  - redirect p99 至少比 `fuse-redirectfs` 好 2x，或删除 FUSE 性能主张。
- 失败解释：若 namei_ext 比 FUSE 或 symlink forest 更差，性能主张必须降级。

### B3. 构建沙箱宏基准

- 真实来源：W1/W2 的生产级开源项目构建和真实 file-operation trace。
- 指标：sandbox setup/teardown、build wall time、metadata p99、disk writes、
  created files/symlinks/mounts、CPU、memory、context switches。
- 判定器：build exit status 相同；deterministic outputs hash-identical；依赖
  manifest 不泄露 backing-only names；lookup/readdir checker 通过。
- 成功标准：medium/large manifests 上 setup p50 或创建对象数至少 5x 优于
  copy/symlink/mount-heavy baseline；build wall-time p95 不超过最佳 feature-
  equivalent kernel baseline 的 1.1x，否则只能声称 materialization improvement。

### B4. 容器/服务启动中的选定根视图别名宏基准

- 真实来源：W3 中的真实生产服务发布版/root tree。禁止用 hello-world 服务支撑
  主结论。
- 范围：只评估 selected executable/library/config aliases，不声称替代完整
  container rootfs。
- 指标：cold start 到首次成功响应、process startup、import/load latency、
  memory/worker、page-cache sharing proxy、disk writes、p95/p99 startup。
- 判定器：response/status/checksum 匹配；selected path 解析到预期版本；
  directory checker 通过。
- 成功标准：selected view setup 至少 5x 优于 symlink/copy；cold-start p99 不超过
  `overlayfs-kernel` 或 `bind-fanout-mount` 的 1.5x；相对 FUSE 至少 2x。

### B5. 包和开发环境宏基准

- 真实来源：W4 的真实包和开发环境，来自生产项目的 lock file 和依赖图，不使用
  随机生成包目录树支撑主结论。
- 指标：environment creation、command startup/import/configure、find/stat/getdents
  traversal、storage、inode/symlink count。
- 判定器：command output、package version、dynamic loader、pkg-config resolution、
  directory listing 均匹配预期。
- 成功标准：中型/大型包集合上的 creation p50 或创建对象数至少 5x 优于
  native env/copy/symlink；command p99 不超过最佳功能等价基线的 1.5x。

### B6. 遗留路径迁移宏基准

- 真实来源：W5 的真实 configure scripts、plugin/config lookup、legacy path probe。
- 指标：compatibility view setup、可选 backing switch latency、probe p99、created
  objects、mount count、disk writes。
- 判定器：legacy app/configure output 匹配；alias reach expected backing；
  readdir 暴露 legacy alias；若启用 update epoch，不允许 mixed epoch view。
- 成功标准：static mapping 0 checker failure；medium/large alias sets 上 setup
  p50 或创建对象数至少 5x 优于 symlink/bind；p99 不超过最佳 kernel baseline 的
  1.5x。
- 失败解释：若只通过正确性而达不到宏基准阈值，U4 只能进入附录。

### B7. 并发下的目录视图一致性

- 目的：证明 `open` 能看到的 alias 和 `ls/find/glob` 看到的名字一致。
- 工作负载：真实树上的并发 `open/stat/access/readdir/glob/find`；update epoch
  只在实现后进入主 run。
- 判定器：同一 epoch 内 `readdir(parent)` 的 visible aliases 等于可 lookup 集合。
- 成功标准：发布级运行中 0 个一致性违规。

### B8. 机制消融

每个消融必须回答一个审稿人问题：

- no-policy vs pass-only：static branch 和 attach residual overhead 是多少？
- pass-only vs redirect：policy decision 和 redirected lookup 成本是多少？
- redirect without readdir：readdir hook 是否真的提供 coherence？
- 每个使用场景的最佳简单基线：symlink、bind、OverlayFS、wrapper 是否已经足够？
- FUSE remap：把 programmable path resolution 放到用户态的代价是多少？

若某个简单基线满足同样 oracle 并达到同样阈值，该场景不能支撑广泛性能结论，
必须改成权衡结论或 artifact 结论。

### B9. 规模和压力扫描

- 维度：aliases/components 10、100、1k、10k、100k；path depth 1、4、16、64；
  cgroups/workers 1、16、64、256、512；热/冷缓存；policy/map size。
- 指标：p99、throughput、memory、CPU、load/attach/verifier time、saturation point。
- 判定器：声明范围内 0 个语义失败；超出范围时必须使用文档化 errno 快速失败，
  不能静默降级。

### B10. 健壮性和失败语义

- 失败场景：invalid redirect（empty、too long、slash、NUL、`.`、`..`）、
  verifier rejection、wrong attach type/flags、unsupported create/unlink/rename、
  backing rename/delete、permission changes、policy map exhaustion/update race、
  cgroup migration/fork/exec、工作负载运行期间 detach/reload。
- 判定器：errno 符合文档；permission failure 匹配 lower FS；detach/reload 后
  post-fault checker 通过或返回 documented failure；0 dmesg warning/oops/panic。
- 成功标准：0 unexpected pass，0 kernel warning，0 fail-open。

### B11. 可复现性和产物门禁

- Make 目标：`make eval-osdi-smoke`、`make eval-osdi-paper`、
  `make eval-osdi-paper-report`。
- 发布级结果根目录：`results/eval-osdi/paper/<run-id>/`。
- 判定器：干净 checkout 一条 Make pipeline 产生完整原始 artifacts、manifest、
  config hashes、kernel/Docker image identity、dmesg、analysis outputs；report 在
  missing capability、failed operation、dirty release tree、parse error 时失败。

## 运行顺序

| Run ID | 阶段 | 目的 | 配置 | seed/reps | 决策门槛 | 风险 |
|--------|------|------|------|-----------|----------|------|
| R001 | 健康检查 | Phase 1 回归 | `make phase1` | 1 次冒烟 | 0 个 report failure | 只做 sanity，永远不支撑论文主张 |
| R010 | 健康检查 | 构建 OSDI policies 和工作负载二进制 | `make eval-osdi-build` | 不适用 | compile/verifier pass | 可能漏运行时错误 |
| R020 | 正确性 | B1 小规模正确性矩阵 | `make eval-osdi-correctness SAMPLES=1` | 固定 seed | 0 个 checker failure | 小树 |
| R030 | 试运行 | B2 微基准试运行 | `make eval-osdi-micro SAMPLES=5` | 5 次重复 | 0 个语义失败 | pilot 不支撑论文主张 |
| R040 | 基线 | 复现 U1-U4 基线 | `make eval-osdi-baselines` | 5 次试运行重复 | 所有基线 oracle 通过 | 基线可能不等价 |
| R050 | 主实验 | 构建沙箱发布级运行 | `make eval-osdi-build-sandbox SAMPLES=20` | 随机顺序 | hash/checker/CI pass | 构建时间长 |
| R060 | 主实验 | 服务启动发布级运行 | `make eval-osdi-container SAMPLES=20` | 随机顺序 | response/path checker pass | 冷缓存控制难 |
| R070 | 主实验 | 包和开发环境发布级运行 | `make eval-osdi-package SAMPLES=20` | 随机顺序 | version/checker pass | 依赖 nondeterminism |
| R075 | 主实验 | 遗留迁移发布级运行 | `make eval-osdi-legacy SAMPLES=20` | 随机顺序 | output/version/checker pass | update epoch 可能范围外 |
| R080 | 决策 | 一致性压力测试 | `make eval-osdi-coherence SAMPLES=10` | 固定 seed，5 分钟 | no checker violation | 可能暴露设计 bug |
| R090 | 决策 | 机制消融 | `make eval-osdi-ablation SAMPLES=30` | 随机顺序 | ablation oracle pass | 简单基线可能胜出 |
| R100 | 决策 | 规模/压力测试 | `make eval-osdi-scale SAMPLES=10` | 固定 seed | 不允许静默错误结果 | 资源重 |
| R110 | 决策 | 失败语义 | `make eval-osdi-failure` | 固定 case | expected errno + clean dmesg | 可能暴露 kernel bug |
| R120 | 整理 | 论文报告 | `make eval-osdi-paper-report` | 已完成原始结果 | 每个图都追到原始文件 | analysis bug |

## 发布运行清单结构

每个发布级运行必须写 `manifest.json`。论文 figure/table 只能消费 manifest 中
引用的原始路径。

必需字段：

- `run_id`、`generated_at`、`paper_claims`、`result_level`；
- `main_repo.head`、`main_repo.dirty`、`kernel_repo.head`、`kernel_repo.dirty`；
- `kernel.image_sha256`、`kernel.config_sha256`、`kernel.cmdline`；
- `docker.image_id`、`docker.tar_sha256`；
- `policy.name`、`policy.object_sha256`、`policy.source_sha256`、可选
  `policy.map_schema_sha256`；
- `workload.id`、`workload.upstream_url`、`workload.version_or_commit`、
  `workload.input_manifest_sha256`、`workload.trace_sha256`、
  `workload.alias_manifest_sha256`；
- `baseline.id`、`baseline.config_sha256`、`baseline.feature_equivalent`；
- `measurement.seed`、`measurement.repetition`、`measurement.variant_order`、
  `measurement.warmup`、`measurement.cache_mode`；
- `raw_paths`、`analysis.version`、`analysis.input_manifest_sha256`、
  `analysis.output_sha256`；
- `figure_table_refs`：每个论文图表单元格指向 raw paths 和 analysis output。

发布级 report 必须在字段缺失、dirty release tree、图表缺 raw reference、
解析失败、dmesg failure、checker failure 时失败。

## 残余不确定性

- C1-C3 阻塞项：当前 Phase 1 只有 same-parent redirect。任何需要 cross-
  directory backing、target registry 或 update epoch 的行，必须先实现并通过
  ABI/functional/KVM/failure gates，否则不能支撑主结论。
- C1-C4 限制：不声称 writable path mutation。create/unlink/rename
  只有后续设计和测试完成后才能进入主张。
- C6 限制：不声称安全隔离，只声称 cgroup-scoped policy attachment 和
  lower filesystem permission preservation。
- 可移植性限制：主实验先限定本地 filesystem。network/remote filesystem
  只能作为 appendix/future work。
- C5 转向触发条件：如果简单基线在主场景上满足同样 oracle 和阈值，论文
  必须转向，不能继续声称广泛性能收益。
- C7 限制：pilot/smoke 或 dirty run 不能支撑论文主张。

## 结果后的主张门禁

最终结论必须在原始结果存在后产生。

| 主张 | 证据文件 | 结论 | 可使用表述 |
|-------|----------|---------|------------|
| C1 | B1、B3-B6 原始/checker outputs | 支持 / 部分支持 / 不支持 | `namei_ext` 对已测真实场景表达读多写少的 programmable path resolution，且不实现 file data path。 |
| C2 | B3-B6 setup/storage/resource outputs | 支持 / 部分支持 / 不支持 | `namei_ext` 降低已测动态 path-resolution customization 的物化成本。 |
| C3 | B2-B6 latency/resource outputs | 支持 / 部分支持 / 不支持 | `namei_ext` 在已测工作负载中满足声明的 p99 kernel/FUSE 阈值。 |
| C4 | B1/B7 checker outputs | 支持 / 部分支持 / 不支持 | lookup 和 readdir 对声明的 redirect policies 保持一致。 |
| C5 | B8 ablation outputs | 支持 / 部分支持 / 不支持 | VFS-level placement 和 lower-FS ownership 解释了测得收益。 |
| C6 | B9/B10 stress/failure outputs | 支持 / 部分支持 / 不支持 | `namei_ext` 有测得的规模边界和 fail-fast 行为。 |
| C7 | B11 artifact outputs | 支持 / 部分支持 / 不支持 | artifact 能从 Makefile-owned KVM/Docker workflows 和 raw provenance 复现。 |
