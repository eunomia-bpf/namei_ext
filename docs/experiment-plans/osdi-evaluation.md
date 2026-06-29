# namei_ext 的 OSDI 级评估设计

2026-06-29 story scope update：本文档中较早版本把 C8/B12 强绑定到
单一 exact-map diagnostic outcome 或 workload-specific baseline failure。该口径已被
`docs/tmp/2026-06-29-paper-story-scope-update.md` 覆盖。当前 C8 规则是 balanced dynamic
path-view abstraction：`namei_ext` 必须在 expressiveness、safety 和 efficiency 之间形成
可证平衡。FUSE/custom FS、kernel modification 和 static/materialized mechanisms 是
conceptual comparisons；copy/symlink/bind/projected/OverlayFS/materialized/native cache 等
只作为 workload-specific baselines；exact-map diagnostics 只在 claim 明确讨论预计算映射
是否足够时使用。旧段落中“必须证明某个单一 diagnostic baseline 失败”应读作历史计划，
不是当前 OSDI gate。

2026-06-18 同步：当前 scoped paper verdict 已经闭合，但 full release 仍未闭合。W2 nginx
sandbox fixture 是唯一 threshold-positive C2 workload slice；W3 Redis checkpoint-view
现在有 materialized/FUSE baselines，但 setup/update threshold 为负，且仍不是真实
Podman/CRIU restore。后续 OSDI 级 benchmark 应优先补强 W2 sandbox trace/endpoint/secret
matrix 或实现真实 W3 restore benchmark；不能把当前 Redis RDB replay 写成 restore
result，也不能用 static exact-map smoke 直接支撑 C8。详细计划见
`docs/tmp/2026-06-18-sandbox-checkpoint-benchmark-plan.md`。

2026-06-18 use-case scope update：如果后续重构成更强投稿叙事，顶层 use case 收敛为
agent sandbox lifecycle、service fixture sandbox 和 content-verified cache view。agent
sandbox lifecycle 包含 fork/fanout、checkpoint rollback/restore、workspace
materialization/update 和 deterministic trace replay，但不包含 eval isolation；该项会引入
额外的安全/benchmark-harness claim，不是当前论文必须证明的内容。

最后更新：2026-06-16
阶段：实验设计
来源：用户要求把多使用场景评估设计改成中文，并要求工作负载来自真实应用或真实生产来源，而不是自造玩具程序。

## 论文主张

`namei_ext` 的目标不是实现一个新的文件系统，也不是做访问控制。它是在 VFS
路径解析和目录枚举路径上提供一个 eBPF 决策点，为动态 path view 提供一个 general but
narrow programmable abstraction：同一个路径名可以按工作负载、依赖图、
checkpoint/restore session、cache 状态和执行上下文解析到不同 backing object，同时让内核继续拥有
dentry、inode、permission、mount traversal、page cache 和 lower filesystem
file operations。

论文级主张是：

```text
对元数据密集、读多写少的动态 path-view 定制，namei_ext
尝试在 expressiveness、safety 和 efficiency 之间取得更好平衡：用 VFS 内的 eBPF
path-resolution policy 表达真实系统中的动态路径解析需求，同时避免完整用户态文件系统或
自定义内核文件系统的扩展面，并保留 lower filesystem 的语义。
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
9. 论文形态的中文 evaluation section 草稿维护在
   [../paper/evaluation.md](../paper/evaluation.md)。该草稿只能使用本文档定义的
   claim、workload、baseline、oracle 和结果门禁；没有原始结果前不得写具体性能数字。

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

默认阈值如下；如果运行前需要调整，必须先修改本文档和 tracker。这些阈值是
reviewer-facing gate，而不是结果后调参：`5x` setup/materialization 用来确保收益不是
小常数噪声或测量 artifact；`1.5x` kernel p99 用来约束内核路径上新增 policy 的尾延迟；
`2x` FUSE p99 用来检验“避免用户态文件系统路径成本”的核心设计动机。若发布级运行不满足
这些阈值，论文必须降级为功能机制或局部权衡主张，并在 sensitivity/appendix 中报告
实际阈值交叉点。

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
- 统计：Phase 1 B2/B8 release-input 和负 verdict gate 与 Makefile 保持一致，
  微基准至少 20 次重复、每条 latency row 至少 64 个操作；宏基准至少 20 次重复。
  这些输入足以阻止或拒绝 C2/C3/C5，但不能单独支持正向性能主张。若后续要把
  C3/C5 写成投稿级正向结论，最终 paper figure 应升级到至少 30 次微基准重复，
  或在 artifact audit 中显式说明较低重复数的统计风险。所有发布级结果必须报告
  median、p95、p99、95% bootstrap 置信区间、绝对值和相对值。置信区间跨过阈值边界时，
  主张必须标为部分支持或结论不充分。

## 论文主张台账

| ID | 主张 | 范围 | 必需证据 | 状态 |
|----|------|------|----------|------|
| C1 | 同一窄 VFS path-resolution ABI 能在已测读多写少、元数据密集场景中承载多类真实 eBPF path-resolution policy family，而不实现文件数据路径。 | 构建依赖图、受控测试沙箱、checkpoint/restore、content-verified cache locality；读多写少；元数据密集；只覆盖已实现并通过 KVM gate 的 ABI 能力。 | 至少四类语义不同的 qualifying eBPF policy family；每类已实现、通过 B1/B10/B12 KVM gate，跑多个真实应用或真实 trace，并通过正确性判定器、逐 family semantic witness、宏基准或 trace replay、目录视图一致性。 | 部分实现：policy object、parent-aware ABI PoC、KVM load/attach gate、POC semantic gate、W1 host build-output oracle、W1 KVM policy preprocessing replay witness、W1 KVM policy release-binary replay witness、W1 KVM poison/negative branch probes、W1/W2/W3/W4 KVM path oracle、W2 nginx real endpoint health + fixture content probes oracle、W3 Redis checkpoint replay witness、W3 Redis exact-map diagnostic、W4 cache content oracle、W4 cache-content diagnostic comparator、W4 真实 ccache transition witness、W4 真实 ccache cache-path trace witness、W4 trace-derived ccache policy bridge、W4 真实 ccache policy-attached compile witness、W4 parent-scoped ccache compile witness、W4 exact-map ccache compile diagnostic 和 W4 release counterfactual accounting 已完成；尚无 qualifying family |
| C2 | 对动态路径解析定制，`namei_ext` 的 setup/materialization 成本低于复制目录树、符号链接森林和 mount-heavy 设计。 | 真实应用上的 100 到 100k aliases/components；1 到 512 个并发工作负载。 | setup latency、created files/symlinks/mounts、disk writes、memory、CPU。 | W2 nginx slice 已实现：20-sample KVM proposed-system setup/update rows、同 workload copy/symlink/bind/projected-volume/FUSE baseline rows、storage footprint aggregation 和显式阈值均通过，`w2_c2_slice_supported=true`；W1 build graph 已有 20-sample KVM proposed-system setup/update release input和 copy/symlink/bind baseline release input，但 W1 ledger 为负，`w1_c2_slice_supported=false`；W4 ccache 已有 parent-rule/table/materialized baseline release input，materialized external baseline 更快，`w4_c2_slice_supported=false`；新增 bulk ccache trace/bridge smoke 已把 W4 扩到 20 个真实 source 和 40 个 trace-derived cache objects，并已有同 bulk shape 的 20-sample materialized baseline raw input，但还没有 bulk proposed-system policy-attached compile、FUSE/cache-remap/native ccache 或 BuildKit baseline、stale/update gate 和 operation-weighted metric；全局 C2 仍缺 W1 projected/FUSE/threshold 或范围收窄、W3 对等 workload macrobench，以及 W4 bulk proposed-system/strong-baseline comparison 或范围收窄。 |
| C3 | 在元数据密集执行中，`namei_ext` 的 p99 元数据开销满足 kernel/FUSE 阈值。 | 热/冷缓存 lookup、open、stat、access、exec、getdents、真实宏基准工作负载。 | p50/p95/p99、throughput、context switches、CPU cycles、cache/resource metrics。 | 已规划 |
| C4 | lookup 和 readdir 由同一 path-resolution policy 决定，可以保持路径解析和目录枚举一致。 | 所有主场景的 alias/backing mapping；并发 lookup/readdir/update stress。 | property checker：lookup 可达集合等于 readdir 可见集合。 | 已规划 |
| C5 | 主要收益来自 VFS-level policy placement 和 lower-FS ownership，而不是 benchmark artifact。 | no-hook、pass-only、redirect、no-readdir、FUSE、symlink、bind/OverlayFS 消融。 | 机制隔离实验；每个消融回答一个审稿人问题。 | 已规划 |
| C6 | 系统在规模、churn、缓存状态和对抗性路径下有明确边界和快速失败语义。 | aliases、path depth、workers/cgroups、policy size、热/冷缓存、unsupported mutations。 | 规模曲线、饱和点、失败语义、dmesg/verifier/runtime evidence。 | 已规划 |
| C7 | artifact 可以由独立审稿人从 Makefile 复现。 | KVM、Docker runtime、配置即代码、原始结果采集。 | `make eval-osdi-smoke` 和 `make eval-osdi-paper` 的结果根目录、哈希、镜像 ID、报告门禁。 | 已规划 |
| C8 | `namei_ext` 在动态 path view 上提供比现有扩展方式更好的 expressiveness/safety/efficiency 平衡。 | 多个 policy family；FUSE/custom FS、kernel modification 和 static/materialized mechanisms 作为 conceptual comparisons；workload-native baselines；exact-map diagnostics 只在预计算映射是相关替代方案时使用。 | policy-family oracle、真实 workload evidence、claim-specific comparison、safety/semantic-boundary evidence、instruction/map/verifier evidence、KVM run。 | 当前 scoped out：已有若干 exact-map diagnostics 和 W3/W4 negative/boundary evidence，但它们不构成主结论；C8 需要真实 workload oracle、自然 baseline comparison 和安全/语义边界证据支持，不能由单一 baseline outcome 定义。 |

## 主张到实验的映射

| 主张 | 必需证据 | 主实验块 | 证伪结果 | 部分支持时的降级表述 |
|-------|----------|----------|----------|----------------------|
| C1 | 至少四类 qualifying policy family 都通过正确性 oracle，且 U1-U4 都有真实应用宏基准或真实 trace replay，并触发各自的 semantic witness。 | B1, B3, B4, B5, B6, B7, B12 | 某场景只能用合成循环表达，只能靠同一个 table policy 表达，依赖尚未实现的 ABI 能力，或 family 状态不是 `qualified_for_c8`。 | `namei_ext` 支持若干已测读多写少的 path-resolution extensions，不声称覆盖全部文件系统语义。 |
| C2 | setup/materialization 至少 5x 优于物化基线，并有原始 artifact 证明对象数量。 | B3, B4, B5, B6, B9 | setup 开销不低于基线，或需要等量 materialization。 | 只声称特定工作负载的机制可行，不声称 materialization 优势。 |
| C3 | p99 满足 1.5x 内核基线和 2x FUSE 阈值，并报告尾延迟。 | B2, B3, B4, B5, B6, B8 | p99 或吞吐明显差于内核基线且无法解释。 | 收窄为功能机制，不主张接近内核基线。 |
| C4 | checker 在宏基准和压力测试中证明 lookup/readdir view 一致。 | B1, B7 | readdir 列出不可 lookup 的 alias，或 lookup 可达但 readdir 缺失。 | 只声称 lookup redirect，不声称目录视图一致性。 |
| C5 | 消融证明 VFS hook placement 和 lower-FS data path 是主要机制。 | B8 | 更简单基线在主要工作负载上同样满足 oracle 和阈值。 | 改成权衡或 artifact 主张。 |
| C6 | 规模/压力/失败测试证明边界清楚，且不 panic、不静默降级。 | B9, B10 | fail-open、kernel warning/oops、或静默错误结果。 | 收窄规模，或把失败模式列为限制。 |
| C7 | 干净 checkout 能用一条 Make pipeline 复现发布级产物。 | B11 | 依赖手动状态、dirty tree、缺配置或缺原始结果。 | artifact 主张降级为 prototype-only。 |
| C8 | 多个语义不同的 policy families 在同一 ABI 上运行，并在 expressiveness/safety/efficiency 上体现动态 path-view abstraction 的 tradeoff。 | B8, B12 | FUSE/custom FS、kernel modification 或更简单自然替代机制在主要 oracle、成本和安全边界上同等满足，或每个 policy 只是 benchmark-specific hardcode。 | 降级为“特定 path-resolution use cases 的 kernel artifact”，不主张 balanced programmable abstraction。 |

## 被测系统模型

- 组件：改过的 Linux kernel、VFS lookup/readdir hooks、cgroup BPF attach
  path、BPF policy object、可选 BPF maps、benchmark harness、真实工作负载
  runner、result collector、analysis target。
- 持久状态：lower filesystem 的真实应用源码、依赖树、fixture 目录、checkpoint
  archive、cache store、trace files；`results/eval-osdi/<run-id>/` 下的原始
  artifacts。
- 信任边界：BPF 只能返回 `PASS` 或受限 `REDIRECT`；kernel 负责 redirect 输出
  校验、lookup、permission、dcache、inode、file operations、mount traversal。
- 保证：lookup/readdir 一致性、lower filesystem permission preservation、
  verifier/runtime/load/attach failure fail-fast。除非后续实现并测试，不声称
  writable union semantics。

## 使用场景可表达性门槛

| 场景 | 需要的最小 ABI 能力 | 当前 Phase 1 状态 | 论文评估门槛 |
|------|--------------------|------------------|--------------|
| U1 构建依赖图 / hermetic build action | 合成包目录树可用 same-parent redirect；真实共享 store 通常需要 target registry 或 cross-directory redirect。 | 合成子集可表达；真实 store mapping 被阻塞。 | 若使用真实 store path，必须先实现 target-registry ABI，并通过 B1/B10。 |
| U2 受控测试沙箱 / fixture substitution | production config、secret、socket、endpoint aliases 可用 same-parent redirect 到 test fixture、fake secret 或 poison sentinel；不做 deny/hide。 | selected fixture 子集可表达；不声称安全隔离。 | B4 必须证明真实应用在 staging/test fixture 下启动，且没有真实 secret/config backing 被打开。 |
| U3 checkpoint/restore path view | checkpointed state/config/cache aliases 可用 same-parent redirect；跨目录 checkpoint image 通常需要 target registry。 | 同父目录 checkpoint fixture 子集可表达；完整 CRIU restore 需要后续集成。 | 若使用真实 checkpoint image 或跨目录 restore tree，必须先实现 target registry；restore epoch/update 需要对应 gate。 |
| U4 content-verified cache locality | cache hit/miss/stale aliases 可用 same-parent redirect 到 local verified cache 或 canonical backing。 | 本地 cache/canonical 子集可表达；远程 cache fetch 不在内核 policy 中实现。 | B6 必须证明 content hash 等于 canonical，stale/corrupt cache 不被使用。 |

## Policy 设计范围

本项目的 policy 是 `bpf/policies/*.bpf.c` 下的 eBPF 程序，不是 YAML、JSON 或
自定义 DSL。论文目标是证明 `namei_ext` 是一个 programmable VFS path-resolution
abstraction：像 FUSE 一样给系统提供扩展点，但 extension 在内核 path-resolution
位置执行，并且不拥有 inode、dentry、file operations 或 data path。发布级主张
必须收窄到已实现、已测、已通过 KVM gate 的 ABI 能力；target registry、cross-
directory redirect、update epoch 只有实现并通过 B1/B10/B12 后，才能支撑更强的
“通用多类 extension”表述。可编程性必须体现在多个语义不同的 verifier-safe eBPF
policy programs、BPF maps、per-workload context 和版本化 state 上，而不是体现在
用户态 policy 解释器或无限制动作集合上。

核心原则是：

```text
动作集合受限：PASS / REDIRECT
决策逻辑可编程：event + parent + component + view_id + epoch + maps
文件系统语义仍由内核和 lower filesystem 拥有
```

计划中需要两类辅助 policy、一个可选 exact-map diagnostic，以及四类算法结构不同的主
policy family：

- `pass_only.bpf.c`：只返回 `PASS`，用于度量 attach/static-branch 和 BPF 调用
  之后的剩余开销。
- `redirect_alias.bpf.c`：Phase 1 回归 policy，对固定 `(event, component)` 做
  精确匹配，返回 `PASS` 或 same-parent `REDIRECT`。
- `table_redirect.bpf.c`：可选 exact-map diagnostic，只做 generic map lookup。它不是
  论文主力；只有当 claim 明确讨论预计算映射是否足够时才作为边界证据。
- `build_graph_view.bpf.c`：构建依赖图 policy family。它表达 action-aware path
  resolution：generated output 优先、declared source fallback、toolchain
  selection、external dependency graph、undeclared dependency poison 和 negative
  lookup behavior。
- `sandbox_fixture_view.bpf.c`：受控测试沙箱 policy family。它表达 staging/test
  execution 的 fixture substitution：production config、secret、certificate、
  service endpoint 和 socket path 被解析到 test fixture、fake secret、local fake
  service config 或 poison sentinel；它不是 deny/hide，也不声称安全隔离。
- `checkpoint_restore_view.bpf.c`：checkpoint/restore policy family。它表达
  restore session 的 checkpoint epoch consistency：checkpointed state/config/cache
  路径解析到同一 checkpoint manifest，runtime-local socket/pid/temp 路径解析到新
  restore 环境的 fixture，避免 mixed checkpoint epoch。
- `cache_locality_view.bpf.c`：content-verified cache locality policy family。它
  表达 cache hit/miss/stale steering：verified local cache hit 解析到本地 backing，
  stale/corrupt cache 解析到 canonical backing 或 fail-fast fixture，missing cache
  走 canonical/pass-through。

这些 policy family 可以共享 target registry、epoch map、通用 key structs、
helper macro 和用户态 loader，但主决策逻辑必须不同。每个 family 必须至少覆盖一个
use case class，且同一个 family 必须跑多个真实应用或真实 trace，避免变成
benchmark-specific hardcode。

Policy family 的多样性是主张门槛，不是实现细节：

| Policy family | 真实系统来源 | 决策结构 | 有界复杂度 | claim-specific baseline concern |
|---------------|--------------|----------|------------|--------------------------|
| `build_graph_view.bpf.c` | Bazel/Buck/Ninja/Nix 风格 action sandbox；真实 Redis/nginx/SQLite/BusyBox 构建 trace。 | priority cascade：generated > declared source > toolchain > external deps > undeclared poison > negative fallback；按 action/view 选择。 | `O(P)` bounded precedence checks + `O(1)` map lookup，`P` 由 config 固定。 | 应比较 action view setup 的自然机制：copy/symlink/bind/FUSE/materialized execroot；exact-map diagnostic 只用于预计算映射边界。 |
| `sandbox_fixture_view.bpf.c` | Kubernetes ConfigMap/Secret/projected-volume、Docker bind/secret mount、CI/staging fixture injection；真实 nginx/PostgreSQL/Redis/Grafana/Git 服务配置和 secret paths。 | path-class dispatch：prod config/secret/cert/socket/endpoint -> test fixture/fake secret/local endpoint/poison sentinel。 | `O(C)` bounded path-class checks + `O(1)` map lookup。 | 应比较 projected volume、bind/symlink、FUSE 和 service-native fixture setup；exact-map diagnostic 只用于预计算映射边界。 |
| `checkpoint_restore_view.bpf.c` | CRIU/Podman checkpoint-restore、serverless snapshot restore、Redis/PostgreSQL/nginx/Grafana state/config/cache snapshot。 | restore-session dispatch：checkpoint epoch state/config/cache -> snapshot backing；runtime-local socket/pid/temp -> restore fixture；post-restore pass/fail。只统计 restore 后新发生的 VFS lookup/readdir，例如 config reload、static file open、RDB/AOF/config rewrite、log reopen；CRIU 已恢复的 fd/mmap/socket 不计为 `namei_ext` 证据。 | `O(1)` restore/session lookup + `O(K)` bounded epoch/path-class consistency checks；`K` 是 `configs/eval-osdi/policy-budgets.mk` 的 `OSDI_CHECKPOINT_MAX_PATH_CLASSES`，默认上限 8，并进入 verifier/map budget。 | 应比较 Podman/CRIU、materialized restore tree、copy/bind 和 FUSE；exact-map diagnostic 只用于预计算映射边界。 |
| `cache_locality_view.bpf.c` | Bazel remote cache CAS/action cache、ccache compiler cache、Docker BuildKit cache mounts、Nix content-addressed store。 | content-hash dispatch：verified local hit -> local backing；stale/corrupt -> canonical/fail-fast；miss -> canonical/pass-through。`namei_ext` 的独立贡献是 per-workload path view setup/update、低 stale window，不声称重新实现 ccache/BuildKit 的 cache correctness。 | `O(1)` cache-state lookup + `O(H)` bounded hash/metadata checks；`H` 是 `configs/eval-osdi/policy-budgets.mk` 的 `OSDI_CACHE_MAX_HASH_WITNESSES`，默认上限 4，并进入 verifier/map budget。 | 应比较 native cache tools、materialized cache mirrors、FUSE 和 BuildKit/ccache mechanisms；exact-map diagnostic 只用于预计算映射边界。 |

每个主 policy family 必须记录它实际使用的算法路径，而不仅仅记录 map 大小。若最终
四个 family 都只能作为 benchmark-specific mapping，dynamic-policy claim 必须判为
unsupported。

逐 family 的 semantic witness 是 B12 的硬门槛。每个 family 至少两个真实 workload
row 必须触发下表的必要分支；没有触发的分支不能用“代码支持”代替实验证据：

| Policy family | 输入状态 | 必须触发的分支 | 判定器 | optional diagnostic | 降级规则 |
|---------------|----------|----------------|--------|--------------------|----------|
| `build_graph_view.bpf.c` | `action_id`/cgroup、parent class、generated manifest、declared source tree、toolchain/deps lock。 | generated hit、declared source fallback、toolchain selection、external dep、undeclared poison、negative miss。 | build output hash、undeclared dep poison checker、dependency leak checker、readdir visible set、branch coverage。 | 只在预计算 action view 是相关替代方案时估算 exact-map cost。 | 若自然 baselines 同等通过，只能证明已测 build aliases，不计入 balanced dynamic path-view claim。 |
| `sandbox_fixture_view.bpf.c` | test profile、path class、fixture manifest、fake secret/config/cert/service endpoint、poison sentinel。 | prod config -> fixture、prod secret -> fake secret、external endpoint -> local fake service、dangerous path -> poison、pass-through。 | app health/output、no real secret/config hash opened、endpoint checker、poison access report、branch coverage。 | 只在预计算 fixture view 是相关替代方案时估算 exact-map cost。 | 若 workload 只替换单个 hand-written file，或没有真实 config/secret provenance，只能 appendix。 |
| `checkpoint_restore_view.bpf.c` | restore_id、checkpoint_epoch、path class、checkpoint manifest、runtime-local fixture map。 | checkpointed state/config/cache hit、runtime socket/pid/temp remap、post-restore fresh lookup/readdir、mixed-epoch reject。 | restore health check、state/config/cache hash equals checkpoint manifest、post-restore VFS trace coverage、runtime path checker、0 mixed checkpoint epoch、branch coverage。 | 只在预计算 restore view 是相关替代方案时估算 exact-map cost。 | 若只做静态 copy-tree restore、没有 restore manifest provenance，或 fresh lookup/readdir 不在 restore 后发生，只能 functional/appendix。 |
| `cache_locality_view.bpf.c` | content hash、cache state、node/profile、canonical manifest、local cache manifest。 | verified hit、stale/corrupt reject、miss -> canonical、pass-through。 | content hash equals canonical、stale/corrupt cache not used、hit/miss/stale/corrupt state-transition coverage、per-workload setup/update cost、stale window、p99。 | 只在预计算 cache-state view 是相关替代方案时估算 exact-map cost。 | 若没有 content-hash checker、没有真实 cache transition provenance，或只测 always-hit cache，不支撑 C8。 |

每个 use case 还必须有真实存在性证据。对应 `workload/<workload-id>/` 下必须有
`evidence.md` 或等价 Markdown 记录，至少包含真实系统来源、上游 URL 或固定 release、
为什么该系统需要这种 path-resolution 逻辑、alias manifest 的生成来源、采集 trace
或构造 workload 的 Make target、以及哪些 oracle 能证明这个需求不是自造的。用于
宏基准和 C1/C8 的 alias manifest 必须来自真实 build trace、fixture/projected-
volume/config/secret manifest、checkpoint manifest、restore trace、cache manifest、
content-hash log 或真实 workload trace；
手写 alias 只能用于 B1/B9/B10 的机制、scale 或 failure 覆盖。每个发布级 run 必须
报告 operation-weighted alias hit rate；若主 run 中少于 80% 的 redirected operations
命中 provenance-derived aliases，该 workload 只能进入 appendix/scale，不能支撑
C1/C8。没有真实来源证据的 workload 只能进 B1/B9/B10 的机制测试，不能支撑 C1/C8。

主线 use case 的外部依据必须来自官方文档、项目文档或论文，而不是只靠项目内假设。
当前计划锁定的依据如下，后续替换 use case 时必须同步替换引用：

| Policy family | 外部依据 | 该依据说明的真实问题 |
|---------------|----------|----------------------|
| `build_graph_view.bpf.c` | [Bazel sandboxing](https://bazel.build/docs/sandboxing)、[Bazel hermeticity](https://bazel.build/basics/hermeticity)、[Bazel dependencies](https://bazel.build/concepts/dependencies)、[Bazel toolchains](https://bazel.build/extending/toolchains) | Bazel 的 sandbox 只让 action 在包含 known inputs 的 execroot 中运行，用来暴露 undeclared inputs、保证 reproducibility 和 cache correctness；依赖和 toolchain 选择说明 build graph view 不是普通 alias 表。 |
| `sandbox_fixture_view.bpf.c` | [Kubernetes projected volumes](https://kubernetes.io/docs/concepts/storage/projected-volumes/)、[Kubernetes Secrets](https://kubernetes.io/docs/concepts/configuration/secret/)、[Docker Compose configs](https://docs.docker.com/reference/compose-file/configs/)、[Docker Compose secrets](https://docs.docker.com/compose/how-tos/use-secrets/) | Kubernetes 和 Docker 都把 config、secret、service-account token 或 host-provided files 作为文件注入 workload；这说明 staging/test fixture substitution 是真实部署模式，而不是安全隔离 claim。 |
| `checkpoint_restore_view.bpf.c` | [CRIU checkpoint/restore design](https://criu.org/Checkpoint/Restore)、[CRIU external bind mounts](https://criu.org/External_bind_mounts)、[Podman checkpoint/restore](https://podman.io/docs/checkpoint)、[DMTCP path virtualization paper](https://dmtcp.sourceforge.io/papers/cluster16.pdf) | CRIU/Podman restore 需要从 checkpoint image 恢复资源、文件、namespace、socket 等状态；外部 bind mount 和 path virtualization 文献说明 restore 常需要把 checkpoint 时路径重新绑定到新运行环境。 |
| `cache_locality_view.bpf.c` | [Bazel remote caching](https://bazel.build/remote/caching)、[Bazel remote execution API](https://github.com/bazelbuild/remote-apis/blob/main/build/bazel/remote/execution/v2/remote_execution.proto)、[ccache manual](https://ccache.dev/manual/4.13.1.html)、[Nix binary cache/substituter](https://nix.dev/manual/nix/2.26/package-management/binary-cache-substituter)、[Nix content-addressed store](https://nix.dev/manual/nix/2.18/command-ref/new-cli/nix3-store-make-content-addressed) | 真实构建系统普遍使用 action cache、CAS、compiler cache、binary cache 或 content-addressed store；正确性要求 cached content 与 canonical output 等价，stale/corrupt cache 不能被使用。 |

2026-06-16 citation audit 结论：论文正文和 claim ledger 必须引用这些 primary sources 的
BibTeX key，而不是只在计划文档中保留 URL。当前锁定 key 为：
`bazel_sandboxing`、`bazel_hermeticity`、`bazel_dependencies`、`bazel_toolchains`、
`kubernetes_projected_volumes`、`kubernetes_secrets`、`docker_compose_configs`、
`docker_compose_secrets`、`podman_checkpoint`、`criu_checkpoint_restore`、
`criu_external_bind_mounts`、`dmtcp_path_virtualization`、`docker_buildkit_cache`、
`ccache_manual`、`bazel_remote_cache`、`bazel_remote_execution_api`、
`nix_binary_cache_substituter` 和 `nix_content_addressed_store`。这些来源只证明
workload/use case 是真实存在的问题；它们不自动证明 `namei_ext` 性能 claim。每个
workload 仍必须用 `workload/<workload-id>/evidence.md` 记录固定版本、下载哈希、
启动/构建/checkpoint/cache 配置、Make target、raw result path、oracle 和
operation-weighted signal。

发布级 workload 选择必须优先能放大 `namei_ext` 的机制收益：大量元数据访问、大量
alias 或 path-class、频繁 setup/teardown、明确的 correctness oracle、以及
workload-native、materialized、copy/symlink/bind、FUSE 等自然基线。当前锁定的 primary workload 如下：

| Workload ID | Policy family | 真实 workload 和来源 | 为什么能放大性能信号 | 主 oracle | 主基线 |
|-------------|---------------|----------------------|----------------------|-----------|--------|
| `w1-redis-build` | `build_graph_view.bpf.c` | Redis 源码构建；固定 commit 的 [Redis top-level Makefile](https://github.com/redis/redis/blob/f2262eccb855eadd1afb0c457ea583ef9d5400b5/Makefile) 委派到 `src/Makefile`，[Redis src Makefile](https://github.com/redis/redis/blob/f2262eccb855eadd1afb0c457ea583ef9d5400b5/src/Makefile) 定义真实 build graph；[Redis configuration](https://redis.io/docs/latest/operate/oss_and_stack/management/config/) 说明版本化配置文件。 | C 项目构建反复访问 source/header/generated/toolchain paths，适合测 sandbox/view setup、metadata p99 和 undeclared dep poison。`workload/w1-redis-build/evidence.md` 必须从固定源码 tarball、Makefile 和 trace 证明 generated/source/toolchain/deps precedence。 | build output hash、declared input manifest、generated/source precedence、poison sentinel。 | `copy-tree-cp`、`symlink-forest-ln`、`bind-fanout-mount`、`fuse-redirectfs`、materialized execroot。 |
| `w1-nginx-build` | `build_graph_view.bpf.c` | nginx 源码构建；[nginx beginner's guide](https://nginx.org/en/docs/beginners_guide.html) 说明 nginx 由配置文件控制，源码构建和模块配置会生成构建产物。 | nginx `configure`/build 有 generated config/header、module/toolchain checks 和大量 include lookups，适合触发 precedence/fallback 分支。 | configure/build exit、output hash、dependency leak checker、readdir visible set。 | 同 `w1-redis-build`。 |
| `w2-nginx-fixture` | `sandbox_fixture_view.bpf.c` | nginx 真实服务配置；[nginx beginner's guide](https://nginx.org/en/docs/beginners_guide.html) 描述 `nginx.conf`、`root`、`proxy_pass`、reload 和 worker 模型。 | 服务启动和 reload 会读 config、cert、static root、upstream endpoint；多 worker/test profile 能放大 fixture setup 和 path-class dispatch。当前已有真实 nginx endpoint health oracle、attach 期间 fixture content probes、20-sample KVM setup/update macrobench raw input、同 workload copy/symlink/bind/projected-volume/FUSE baseline raw input，以及 W2 storage/threshold-supported ledger，证明 config/endpoint 被真实 nginx 路径消费，并证明 config/endpoint/cert/secret/poison aliases 能经普通 VFS open/read 解析到 fixture/fake/poison backing；但还不是 trace-level no-real-open、release-level endpoint matrix、W1 projected/FUSE/threshold 加 W3/W4 macrobench 支撑的 global C2 result 或 claim-specific comparison oracle。 | health response、config/cert hash、endpoint 指向 local fake service、no real secret/config open。 | `k8s-projected-volume`、`copy-tree-cp`、`symlink-forest-ln`、`bind-fanout-mount`、FUSE。 |
| `w2-postgres-secret-fixture` | `sandbox_fixture_view.bpf.c` | PostgreSQL 服务配置与 Docker/Kubernetes secret 文件注入；[PostgreSQL server configuration](https://www.postgresql.org/docs/current/runtime-config.html) 说明 server configuration，[Docker Compose secrets](https://docs.docker.com/compose/how-tos/use-secrets/) 说明 secret 以文件挂载。 | 数据库启动会读 config、auth、secret/password 和 data path；真实应用会把 `_FILE` secret convention 用在官方镜像，适合 no-real-secret oracle。 | PostgreSQL health/query、secret hash never opened、fixture password used、poison path report。 | `k8s-projected-volume`、Docker Compose secrets materialization、copy/symlink/bind、FUSE。 |
| `w3-redis-podman-criu` | `checkpoint_restore_view.bpf.c` | Redis 服务在 Podman/CRIU checkpoint archive 中恢复；[Podman checkpoint](https://podman.io/docs/checkpoint) 说明 checkpoint 后可 restore 并从 checkpoint 时刻继续运行，[CRIU checkpoint/restore](https://criu.org/Checkpoint/Restore) 说明 restore 会恢复文件、socket、namespace 等资源。当前 Phase 1 另有真实 `redis-server` RDB load replay witness，用可见 `dump.rdb` alias 加载 hidden checkpoint backing。 | Redis 有 state/config/cache paths，restore session 数可扩展到 1/10/100。只统计 restore 后触发的新 VFS operations：`CONFIG REWRITE`、`BGSAVE`、AOF/RDB open、log/config/stat/readdir；CRIU 已恢复 fd 不计入 path-resolution 证据。 | restored health、RDB/AOF/config hash 等于 checkpoint manifest、runtime-local socket/temp remap、post-restore lookup/readdir trace、0 mixed epoch。 | `podman-criu-restore`、materialized restore tree、copy/bind、FUSE。 |
| `w3-nginx-podman-criu` | `checkpoint_restore_view.bpf.c` | 固定 `docker.io/library/nginx:<version-or-digest>` 的 Podman checkpoint/restore；[nginx official image](https://hub.docker.com/_/nginx)、[Podman checkpoint](https://podman.io/docs/checkpoint) 和 [nginx reload/config docs](https://nginx.org/en/docs/beginners_guide.html) 共同定义 workload。 | HTTP 服务 health check 快，适合大量 restore session。只统计 restore 后 `nginx -s reload`、static file request、log reopen、config/stat/readdir 等新 VFS operations；必须保存 checkpoint archive hash、restore trace 和 post-restore path trace。 | HTTP health、checkpoint config/static hash、runtime pid/socket/log path checker、post-restore lookup/readdir trace、0 mixed epoch。 | `podman-criu-restore`、materialized restore tree、copy/bind、FUSE。 |
| `w4-ccache-redis-nginx` | `cache_locality_view.bpf.c` | Redis/nginx 编译结合 ccache local/remote storage；[ccache manual](https://ccache.dev/manual/4.13.1.html) 说明 local cache、remote storage、local miss remote hit、remote_only 等状态。 | 编译 cache 反复访问 object/cache manifest，hit/miss/stale/corrupt 状态明确，适合测 content-hash dispatch、cache-path file ops、policy-attached hot compile、update writes 和 stale window。 | compiler output hash、cache hit/miss/stale/corrupt coverage、cache-path trace、policy-attached hot compile output hash、stale/corrupt 0 unexpected hit。 | ccache native、local-only、remote-only、materialized cache mirror、FUSE。 |
| `w4-buildkit-prometheus-go-cache` | `cache_locality_view.bpf.c` | Prometheus Go module/build cache workload；[Prometheus repository](https://github.com/prometheus/prometheus) 是真实监控系统，[Prometheus go.mod](https://github.com/prometheus/prometheus/blob/main/go.mod) 锁定 Go module graph，[Docker BuildKit cache mounts](https://docs.docker.com/build/cache/optimize/) 支持 `/go/pkg/mod` 和 `/root/.cache/go-build` 持久缓存。 | Go module/build cache metadata 和 object entries 多，反复 rebuild 可放大 setup、hit path p99、update writes、stale window 和 stale/corrupt reject。 | `go build`/`go test` output hash、module cache manifest hash、miss fallback、stale/corrupt reject、cache state transition coverage。 | BuildKit native cache mount、copy/cache mirror、bind mount、FUSE。 |

同一组 workload 还必须维护 source-to-signal ledger，避免把真实来源、性能信号和当前
Phase 1 证据混在一起：

| Policy family | 真实来源 | 被放大的性能信号 | 当前 evidence level | Release blocker |
|---------------|----------|------------------|----------------------|-----------------|
| `build_graph_view.bpf.c` | Bazel sandbox/hermeticity 机制；Redis `7.2.14` 与 nginx `1.26.3` 真实源码构建和 file-operation trace。 | execroot/action view setup、copy/symlink/mount materialization 成本、metadata `openat/statx/access/getdents64` p99、generated/source/toolchain/deps precedence。 | W1 host trace-witness + host build-output oracle + KVM path oracle + KVM policy preprocessing replay witness + KVM policy release-binary replay witness + KVM poison/negative branch probes + 1-sample KVM setup/update macrobench PoC + 20-sample KVM proposed-system setup/update release input + 20-sample KVM copy/symlink/bind baseline release input；W1 ledger 当前 `w1_c2_slice_supported=false`、`qualified_for_c8=false`、`c2_supported=false`。 | W1 projected/FUSE、storage/threshold-supported ledger 或 C2 scope narrowing、trace-derived full alias set、release-level poison/negative natural workload hit、operation-weighted redirected hit rate、claim-specific comparison 和 safety/semantic-boundary evidence。 |
| `sandbox_fixture_view.bpf.c` | Kubernetes projected volume/Secret、Docker Compose secret/config、nginx/PostgreSQL 配置和服务启动路径。 | fixture setup、path-class dispatch、config/endpoint/secret/cert/poison branch coverage、startup/reload metadata p99、no-real-secret oracle。 | W2 fixture witness + KVM path oracle + nginx endpoint health + direct fixture content probes + W2 nginx 20-sample KVM setup/update macrobench raw input + W2 copy/symlink/bind/projected-volume/FUSE baseline raw input + W2 storage/threshold ledger；summary 中 proposed-system、五类 feature baseline、storage footprint 和显式阈值均 pass，`w2_c2_slice_supported=true`，但全局 `c2_supported=false`、`release_gate_pass=false`；`qualified_for_c8=false`。 | PostgreSQL real app oracle、nginx trace-level no-real-open checker、release-level endpoint matrix、startup trace、operation-weighted hit rate、W1 projected/FUSE/threshold 或 scope narrowing、W3/W4 对等 C2 macrobench、claim-specific comparison 和 safety/semantic-boundary evidence。 |
| `checkpoint_restore_view.bpf.c` | Podman/CRIU checkpoint/restore；Redis/nginx state/config/cache/runtime paths。 | restore session switch、post-restore fresh lookup/readdir、runtime-local socket/pid/log/temp remap、mixed-epoch reject。 | W3 checkpoint witness + KVM path oracle + Redis checkpoint replay witness + same-workload exact-map diagnostic；`qualified_for_c8=false`。 | 真实 Podman/CRIU checkpoint archive、restore health、post-restore VFS trace、state/config/cache hash、0 mixed epoch/update/stale-window oracle、claim-specific comparison 和 safety/semantic-boundary evidence；当前 Redis exact-map diagnostic 是负证据。 |
| `cache_locality_view.bpf.c` | ccache、Docker BuildKit、Bazel remote cache、Nix content-addressed store、Prometheus Go module graph。 | cache view setup/update、verified-hit/stale-fallback/corrupt-reject/miss-canonical branch coverage、stale window、update writes、metadata p99。 | W4 cache witness + KVM path oracle + map-backed cache content oracle + cache-content diagnostic comparator + 真实 ccache cold/hot transition witness + 真实 ccache cache-path trace witness + trace-derived ccache policy bridge + 真实 ccache policy-attached compile witness + parent-scoped compile witness（metadata sibling PASS + valid-shape non-witness backing-absent + valid-shape non-witness sibling exact-text content oracle PASS）+ sampled exact-map compile diagnostic + release counterfactual accounting（40 个 cache-path file ops、4 个 trace objects、parent/exact-map 规则 4/8、sampled attach-window ops/object ops 40/16、sampled hit rate 0.4）+ bulk trace/bridge（20 source、400 cache-path file ops、40 trace objects）+ bulk materialized baseline release input（20 samples，setup/update 平均 484.83 ms/3.12 ms）；`qualified_for_c8=false`。 | release-level operation-weighted policy cache hit rate、真实 stale/corrupt transition、BuildKit cache-path trace、compiler/go output hash 的发布级 oracle、stale window/update writes、FUSE/cache-remap/native cache baseline、claim-specific comparison 和 safety/semantic-boundary evidence；当前 cache-content diagnostic comparator、sampled diagnostic comparator、release counterfactual accounting 和 materialized baseline 都是负/blocked evidence，因此不能作为 C8 证据。 |

这些 workload 的初始 `workload/<workload-id>/evidence.md` 必须包含上述来源链接、
固定版本、下载哈希、构建/启动/checkpoint/cache 命令、trace 采集 Make target、
alias manifest 生成 Make target、operation-weighted alias hit rate 和 oracle raw
result path。checkpoint workload 还必须记录 restore session switch hit rate 和
post-restore VFS operation hit rate；cache workload 还必须记录 hit/miss/stale/corrupt
state-transition hit rate。没有这些字段时，该 workload 只能作为开发诊断或 appendix，
不能计入 C1/C8。
Workload ID 列表由 `configs/eval-osdi/workloads.mk` 固定；policy budget、path-class
上限、content-hash witness 上限、transition hit-rate 门槛和 optional exact-map diagnostic 预算由
`configs/eval-osdi/policy-budgets.mk` 固定。

当前 canonical 完整 Phase 1 root 是
`results/phase1/20260615T-full-phase1-bench-variants/`，由
`make phase1 RUN_ID=20260615T-full-phase1-bench-variants` 生成。该 root 把 W1/W2/W3/W4
KVM oracle、W1 release replay/branch probes、W2 nginx real、W3 Redis checkpoint
replay、W4 ccache trace/policy bridge/policy-attached compile、W4 parent-scoped
compile、W4 exact-map compile diagnostic、W4 release counterfactual accounting、
functional、Docker、dmesg 和 microbenchmark variant gates 放入同一份 `summary.md`。
该 root 的 `bench.jsonl` 含 `baseline`、`pass_only`、`table_redirect_empty`、
`table_redirect_hit` 和 `policy` 五组 variant，35 个 bench row、0 failure，
并在 `table_redirect_hit` 中成功写入 66 条 `exact_redirects` map rule。该 root 只解决
Phase 1 artifact 完整性和 provenance 问题；其中 `qualified_for_c8=true` row 仍为 0。

截至 2026-06-15，W1 已经有 host-side source-build-trace、trace-witness
manifest、host build-output oracle、KVM path oracle 和 KVM policy preprocessing replay witness：
`make workload-build-graph RUN_ID=20260615T-parent-key-poc` 从干净源码树
构建并 strace Redis `7.2.14` 与 nginx `1.26.3`。Redis trace 记录 `1,224,839`
行 file-operation trace，nginx trace 记录 `1,796,476` 行 file-operation trace。
对应 manifest 位于
`results/workloads/runs/20260615T-parent-key-poc/`，并带有机器可判定字段：
`run_environment=host`、`policy_executed=false`、`kvm_validated=false` 和
`output_hash_oracle=false`。Redis recipe 设置 `GIT_CEILING_DIRECTORIES`，避免
Redis release-header 生成过程向上扫描父项目 git repository 并污染 trace。

`make workload-w1-build-output-oracle RUN_ID=20260615T-parent-key-poc`
生成 `w1-build-output-oracle.jsonl`，把 Redis/nginx 两个真实 host source build 的
binary SHA256、build duration、trace binary SHA256、trace duration、trace
file-operation 行数和 source manifest hash 写成 raw JSONL。该 artifact 的 row
满足 `result_level=host_real_build_output_oracle`、`output_hash_oracle=false`、
`host_output_hash_oracle=true`、`release_output_hash_oracle=false`、
`output_hash_oracle_scope=host`、`policy_executed=false`、`kvm_validated=false`
和 `qualified_for_c8=false`。它证明真实构建输出哈希可审计，但不是 KVM policy
build replay；不能单独支撑 C1/C8。

`make kvm-w1-build-replay RUN_ID=20260615T-parent-key-poc`
在修改后的 kernel guest 中复制真实 Redis/nginx source tree，先在未 attach policy
时对 Redis `src/server.c` 和 nginx `src/core/nginx.c` 生成 baseline preprocessed
output，再 materialize W1 trace-derived shadow aliases，load/attach
`build_graph_view.bpf.c`，随后通过同一路径生成 policy preprocessed output 并进行
byte-for-byte 比较。raw result 是
`results/phase1/20260615T-parent-key-poc/w1-build-replay.jsonl`；
`w1-build-replay-outputs.sha256` 记录 Redis baseline/policy 都是
`c4fc64fce52917575d2e4c7d0735a45685f54be29f68303a730f69bfeb588422`，nginx
baseline/policy 都是
`dbb253e0d661fce0dabbd9b0ad2c42e349ed99277dc6f9168974a589e3048c5e`。该 target
的 summary 为 0 failure，`run_environment=kvm`、`policy_executed=true`、
`policy_replay_output_hash_oracle=true`、`output_hash_oracle_scope=kvm_policy_preprocess`，
但仍强制 `output_hash_oracle=false`、`release_output_hash_oracle=false` 和
`qualified_for_c8=false`。它是 KVM policy preprocessing witness，不是完整
`make redis-server` 或 nginx release binary replay，不能单独支撑 C1/C8。

当前 alias manifests 是手工候选 + trace-witness，不是 trace parser 生成的完整
alias set：Redis 产生 4 个候选 entries、
5,692 个候选 trace hits、`candidate_witness_hit_rate=0.004647141379397619`；
nginx 产生 5 个候选 entries、5,638 个候选 trace hits、
`candidate_witness_hit_rate=0.00313836644630933`。二者都只命中
generated/source/toolchain/external-dep 分支；后续 KVM branch probes 已在真实
Redis/nginx source parent directories 副本中验证 undeclared-poison 和 negative
fallback 的 lookup/readdir 语义，但这仍不是 release build trace 中自然触发的
workload hit。alias manifests 还显式记录
`release_gate_eligible=false` 和 `policy_execution_basis=host_trace_only`。

2026-06-15 的 W1 release binary replay gap analysis
（`docs/tmp/2026-06-15-w1-release-binary-replay-gap-analysis.md`）把 release-level
缺口作为独立 gate 记录；同日的 parent-aware ABI 调研和实现记录
（`docs/tmp/2026-06-15-parent-aware-namei-abi-survey.md`、
`docs/tmp/2026-06-15-parent-aware-namei-abi-implementation.md`）补上了第一层 rule
identity blocker。当前 kernel ctx 以 append-only 方式暴露 `parent_dev`、
`parent_ino`、`parent_generation` 和 `parent_flags`，map-backed policy key 使用
`(event, cgroup_id, parent_dev, parent_ino, component name)`。`make phase1
RUN_ID=20260615T-full-phase1-bench-variants` 已在修改后的 kernel/KVM 路径下通过当前
canonical 完整 Phase 1 gate，
`results/phase1/20260615T-full-phase1-bench-variants/summary.md` 中 W1/W2/W3/W4 oracle、
W1 preprocessing/release replay、W1 branch probes、W2 nginx real、W3 Redis checkpoint
replay、W4 cache content、W4 真实 ccache transition、W4 真实 ccache cache-path trace、
W4 trace-derived ccache policy bridge、W4 真实 ccache policy-attached compile、W4
parent-scoped compile、W4 exact-map compile diagnostic、W4 release counterfactual
accounting、functional、bench variants、Docker 和 dmesg gate 均为 0 failure，table-budget
C8-qualified rows 仍为 0。
后续 `make kvm-w1-release-build-replay RUN_ID=20260615T-parent-key-poc` 又在同一
modified-kernel KVM 路径下完成 release-binary replay witness：Redis baseline/policy
规范化后 hash 均为
`65c8f5155d78a1a04ebb937cf7c85483b8320e1444686a691694c46e83f2de8b`，nginx
baseline/policy 规范化后 hash 均为
`f9e214c23512996723d8409b0d0eda40070c135fc28f25d6f207ea85b4974544`，
`w1-release-build-replay-summary` 为 0 failure。该 gate 支持 “policy attach 下
真实 Redis/nginx release rebuild 的规范化 output equivalence” 结论，但仍显式记录
`qualified_for_c8=false`。同一 run id 下的 `make kvm-w1-branch-probes` 还验证了
`private.h -> poison.dep` 和 `missing.h -> PASS/ENOENT` 两个 branch probes，
summary 为 0 failure，并记录 host trace candidate hit rate
`11330/3021315=0.0037500227549924453`，但
`operation_weighted_hit_rate_is_release=false`。W1 要进入 C1/C8 主结果，仍需要完整
trace-derived alias set、真实 release-level poison/negative workload hit、
operation-weighted redirected hit rate 和
claim-specific comparison 和 safety/semantic-boundary evidence。

新增 `make kvm-w1-oracle RUN_ID=20260615T-parent-key-poc` 会从上述 alias
manifests 生成 `w1-build-graph-oracle-entries.tsv`，在 KVM guest 中为每个 entry
创建独立 synthetic directory 并 materialize shadow backing file，然后用同一组
9 个 trace-derived entries 跑
`build_graph_view.bpf.c` 和 `table_redirect.bpf.c`。oracle 检查 attach 前 alias 不存在、
attach 后 lookup 读到 backing 内容、readdir 显示 alias 且隐藏该 policy 的 backing、
detach 后 alias 再次不可达。raw result 位于
`results/phase1/20260615T-parent-key-poc/w1-oracle.jsonl`，输入哈希位于
`w1-oracle-inputs.sha256`，且输入哈希清单包含 `w1-build-output-oracle.jsonl`；
两个 policy summary 均为 0 failure。该结果是
`kvm_policy_path_oracle`，验证 per-entry path semantics，不验证真实 Redis/nginx
source tree 的 parent/path interaction；每条 summary 仍记录
`qualified_for_c8=false`：完整 trace-derived alias set、release-level poison/negative
natural workload hit、发布级 operation-weighted alias hit rate、claim-specific comparison 和 safety/semantic-boundary evidence
通过前，W1 仍不能计入 C1/C8 主结论。

新增 `make workload-w2-oracle-entries RUN_ID=20260614T-workloads-git-ceiling`
会生成 W2 fixture witness manifests 和 `w2-sandbox-fixture-oracle-entries.tsv`。
nginx row 使用固定 nginx `1.26.3` source provenance 和
`workload/w2-nginx-fixture/nginx.test.conf` workload fixture config，并由 Makefile 生成
fake certificate、local endpoint 和 poison sentinel；PostgreSQL row 使用固定
PostgreSQL `16.6` upstream sample config，并由 Makefile 生成 fake password fixture。
这些 manifests 的 `result_level=host_fixture_witness_manifest`、`policy_executed=false`、
`kvm_validated=false` 和 `output_hash_oracle=false`，只说明 fixture inputs 与真实
upstream config/provenance 绑定，不说明服务已经启动或 policy 已执行。

`make kvm-w2-oracle RUN_ID=20260614T-workloads-git-ceiling` 在 KVM guest 中为 6 个
fixture witness entries 建立独立 synthetic directory，并分别运行
`sandbox_fixture_view.bpf.c` 和 `table_redirect.bpf.c`。oracle 检查 attach 前 alias
不存在、attach 后 lookup 内容匹配、readdir alias/backing 一致性和 detach 后 alias
不可达。raw result 位于
`results/phase1/20260614T-workloads-git-ceiling/w2-oracle.jsonl`，输入哈希位于
`w2-oracle-inputs.sha256`，两个 policy summary 均为 0 failure。该结果仍是
`kvm_policy_path_oracle`，不启动 nginx/PostgreSQL，不验证 health/no-real-secret
oracle，不支撑 balanced dynamic path-view claim；每条 summary 记录
`qualified_for_c8=false`，因此 W2 仍不能计入 C1/C8 主结论。

`make kvm-w2-nginx-real RUN_ID=20260614T-w2-nginx-probes-phase1` 进一步把真实 nginx
`1.26.3` binary 的 config parser、worker start、redirected endpoint HTTP health check
和 worker quit 放进 KVM oracle：runner 在 guest `/tmp` 中构造 nginx prefix，把
`workload/w2-nginx-fixture/nginx.test.conf` materialize 为 `conf/nginx.test.conf`，
把 Makefile 生成的 endpoint fixture materialize 为 `conf/upstream.local`，并保证
`conf/nginx.conf` 和 `conf/upstream.sock` 不直接存在。attach 前，
`nginx -t -p <prefix>/ -c conf/nginx.conf` 因 alias 缺失失败；attach 后，
`sandbox_fixture_view.bpf.c` 把 `nginx.conf` 重定向到 `nginx.test.conf`，并把 fixture
config 中的 `include upstream.sock` 重定向到 `upstream.local`。同一条真实 nginx
config test 成功，随后 worker 启动，HTTP GET `/` 通过 nginx 代理到 runner 启动的
`127.0.0.1:18080` local upstream，返回 `200 OK` 和 `namei_ext nginx health`；
raw result 中 `attached_endpoint_upstream=true` 证明 local upstream 收到了 nginx 请求。
worker 在 policy 仍 attached 时通过 `nginx -s quit` 退出；detach 后配置测试再次失败。
同一 attach window 内，runner 还执行五个 direct content probes：
`attached_config_fixture_probe`、`attached_endpoint_fixture_probe`、
`attached_fake_cert_probe`、`attached_fake_secret_probe` 和 `attached_poison_probe`。
这些 probe 使用普通 VFS `open/read`，要求 visible alias 内容等于 fixture/fake/poison
backing，并且不等于同目录 production-like decoy。
raw result 位于
`results/phase1/20260614T-w2-nginx-probes-phase1/w2-nginx-real.jsonl`，输入哈希位于
`w2-nginx-real-inputs.sha256`。该结果是 `kvm_real_app_health_oracle` + direct fixture
content probes，证明真实 nginx 配置解析、endpoint include 和服务请求路径能观察到
`namei_ext` 决策，并证明 sandbox fixture policy 的 config/endpoint/cert/secret/poison
分支能在 attach 期间影响普通 VFS open/read；它仍不做 trace-level no-real-open
checker、release-level endpoint matrix，也不证明 startup trace、operation-weighted hit rate
或 balanced dynamic path-view evidence，因此不能计入 C1/C8。

`make kvm-w2-nginx-macrobench RUN_ID=20260615T-w2-nginx-c2-macrobench-release-sample-v1
W2_NGINX_MACROBENCH_SAMPLES=20` 进一步把同一个 nginx fixture 放入 C2 setup/update
raw-row path。guest 每个 sample 构造 nginx prefix，记录 setup object count、bytes
written/copied、attach 前后 `nginx -t`、config/endpoint/cert/secret/poison probes，
并在 update 阶段修改 `upstream.local`、`server.fake.crt` 和 `db.fake.pass` 后再次运行
`nginx -t` 与 post-update probes。raw result 位于
`results/phase1/20260615T-w2-nginx-c2-macrobench-release-sample-v1/w2-nginx-macrobench.jsonl`：
20 条 setup row、20 条 update row、20 条 correctness row 和 1 条 summary；summary
为 `pass=true`、`failures=0`、`policy_executed=true`、`kvm_validated=true`、
`c2_supported=false`、`release_gate_pass=false`。该 run 是 C2 发布级输入补强，不是
C2 结论。随后 `make kvm-w2-nginx-baseline-macrobench
RUN_ID=20260616T-w2-nginx-baseline-macrobench-release-sample-v4
W2_NGINX_BASELINE_MACROBENCH_SAMPLES=20` 在同一 workload 上补了 `copy_tree`、
`symlink_forest`、`bind_mount`、`projected_volume` 和 `fuse_redirect` 五类
materialization/bind/projected/FUSE baseline：每类都有 20 条
setup rows、20 条 update rows 和 20 条 correctness rows，summary 为
`baseline_count=5`、`setup_rows=100`、`update_rows=100`、`correctness_rows=100`、
`pass=true`、`failures=0`、`feature_equivalent_baseline=true`、
`policy_executed=false`、`kvm_validated=true`、`c2_supported=false`、
`release_gate_pass=false`。新的
`make eval-osdi-w2-nginx-workload-macrobench-ledger
RUN_ID=20260616T-eval-w2-nginx-workload-macrobench-ledger-v5` 把 proposed-system rows 和
copy/symlink/bind/projected/FUSE baseline rows 合并到
`results/eval-osdi/paper/20260616T-eval-w2-nginx-workload-macrobench-ledger-v5/b3-macrobench/w2-nginx-workload-macrobench.jsonl`，
summary 为 `policy_release_input_pass=true`、`baseline_release_input_pass=true`、
`copy_symlink_baselines_pass=true`、`bind_baseline_pass=true` 和
`projected_volume_baseline_pass=true`、`fuse_baseline_pass=true`、
`all_feature_baselines_pass=true`、`full_feature_equivalent_baseline_pass=true`、
`storage_footprint_pass=true`、`setup_latency_threshold_pass=true`、
`update_latency_threshold_pass=true`、`update_materialization_threshold_pass=true`、
`threshold_pass=true`、`w2_c2_slice_supported=true`，但全局
`c2_supported=false` 和 `release_gate_pass=false`。因此当前 W2 已有五类 feature
baseline、storage footprint aggregation 和显式 setup/update/materialization 阈值；后续
W1 已补 copy/symlink/bind baseline release input，但 W1 ledger 为负，全局 C2 仍缺
W1 projected/FUSE/threshold 和 W3/W4 对等 macrobench。

2026-06-16 新增 `make kvm-w1-build-macrobench
RUN_ID=20260616T-w1-build-macrobench-smoke-v3 W1_BUILD_MACROBENCH_SAMPLES=1`，
在修改后的内核 KVM guest 中写出 W1 build graph proposed-system setup/update PoC：
`results/phase1/20260616T-w1-build-macrobench-smoke-v3/w1-build-macrobench.jsonl`
中 summary 为 `samples=1`、`setup_rows=1`、`update_rows=1`、
`correctness_rows=1`、`pass=true`、`failures=0`、`policy_executed=true`、
`kvm_validated=true`、`c2_supported=false`、`release_gate_pass=false`。该 run
使用真实 Redis/nginx trace source、9 个 W1 trace-derived entries 和
`build_graph_view.bpf.c`，correctness oracle 是 baseline/policy preprocessing
output 等价。它证明 W1 macrobench plumbing 可运行，但不是 W1 release comparison；
第一次 smoke `20260616T-w1-build-macrobench-smoke-v1` 的 Redis output compare
false-negative 失败证据也保留在 `results/phase1/20260616T-w1-build-macrobench-smoke-v1/`。

2026-06-16 随后新增 `make kvm-w1-build-macrobench
RUN_ID=20260616T-w1-build-macrobench-release-sample-v1 W1_BUILD_MACROBENCH_SAMPLES=20`，
在修改后的内核 KVM guest 中把 W1 proposed-system setup/update 提升到 release input：
`results/phase1/20260616T-w1-build-macrobench-release-sample-v1/w1-build-macrobench.jsonl`
中有 20 条 setup rows、20 条 update rows、20 条 correctness rows 和 1 条 summary；
summary 为 `samples=20`、`pass=true`、`failures=0`、`policy_executed=true`、
`kvm_validated=true`、`c2_supported=false`、`release_gate_pass=false`。host 侧
`sha256sum -c` 通过。该 run 仍不是 W1 C2 comparison；它只把 W1 从
1-sample plumbing 提升到 proposed-system release input。

2026-06-16 继续新增 `make kvm-w1-build-baseline-macrobench
RUN_ID=20260616T-w1-build-baseline-release-sample-v1
W1_BUILD_BASELINE_MACROBENCH_SAMPLES=20 W1_BUILD_BASELINES='copy_tree symlink_forest bind_mount'`，
在修改后的内核 KVM guest 中把 W1 同 workload `copy_tree`、`symlink_forest` 和
`bind_mount` baseline 提升到 release input：
`results/phase1/20260616T-w1-build-baseline-release-sample-v1/w1-build-baseline-macrobench.jsonl`
中 summary 为 `baseline_count=3`、`samples=20`、`setup_rows=60`、`update_rows=60`、
`correctness_rows=60`、`pass=true`、`failures=0`、`feature_equivalent_baseline=true`、
`c2_supported=false`、`release_gate_pass=false`。随后
`make eval-osdi-w1-build-workload-macrobench-ledger
RUN_ID=20260616T-eval-w1-build-workload-macrobench-ledger-release-v1` 把 W1
proposed-system release input 与三类 baseline release input 合并：
`policy_release_input_pass=true`、`baseline_release_input_pass=true`、
`copy_tree_baseline_pass=true`、`symlink_forest_baseline_pass=true`、
`bind_mount_baseline_pass=true`，但 `projected_volume_baseline_pass=false`、
`fuse_baseline_pass=false`、`storage_footprint_pass=false`、`threshold_pass=false`、
`w1_c2_slice_supported=false`。该 ledger 记录 `best_baseline_setup_ns_avg=18326753.1`
小于 `policy_setup_ns_avg=66090011.6`，`best_baseline_update_ns_avg=40165924.95`
小于 `policy_update_ns_avg=52416038.25`。因此 W1 当前是 release-level negative
evidence，不支持 C2；hard gate
`20260616T-eval-w1-build-workload-macrobench-hardgate-release-v1` 按预期失败。

新增 `make workload-w3-oracle-entries RUN_ID=20260614T-workloads-git-ceiling`
会生成 W3 checkpoint witness manifests 和 `w3-checkpoint-oracle-entries.tsv`。Redis
row 使用固定 Redis `7.2.14` provenance，并由 Makefile 生成 RDB、AOF、runtime socket
和 mixed-epoch poison witness；nginx row 使用固定 nginx `1.26.3` upstream sample
config，并由 Makefile 生成 checkpoint cache 和 runtime pid witness。这些 manifests
的 `result_level=host_checkpoint_witness_manifest`、`policy_executed=false`、
`kvm_validated=false` 和 `output_hash_oracle=false`，只说明 checkpoint/cache/runtime
路径 witness 与真实 provenance 绑定，不说明真实 Podman/CRIU restore 已执行。

`make kvm-w3-oracle RUN_ID=20260614T-workloads-git-ceiling` 在 KVM guest 中为 7 个
checkpoint witness entries 建立独立 synthetic directory，并分别运行
`checkpoint_restore_view.bpf.c` 和 `table_redirect.bpf.c`。oracle 检查 attach 前
alias 不存在、attach 后 lookup 内容匹配、readdir alias/backing 一致性和 detach 后
alias 不可达。raw result 位于
`results/phase1/20260614T-workloads-git-ceiling/w3-oracle.jsonl`，输入哈希位于
`w3-oracle-inputs.sha256`，两个 policy summary 均为 0 failure。该结果仍是
`kvm_policy_path_oracle`，不运行真实 restore，不验证 health、post-restore VFS trace、
state/config/cache hash 或 0 mixed epoch oracle；每条 summary 记录
`qualified_for_c8=false`，因此 W3 仍不能计入 C1/C8 主结论。

`make kvm-w3-redis-replay RUN_ID=20260615T-parent-key-poc` 在修改后的 kernel
KVM guest 中运行真实 `redis-server` RDB load replay。target 先生成包含
`checkpoint_restore_policy_loaded` 的 hidden checkpoint backing `dump.ckpt`，证明 attach
前可见路径 `dump.rdb` 不会加载 hidden state；attach `checkpoint_restore_view.bpf.c`
后，同一 Redis `dbfilename dump.rdb` 通过 policy redirect 读取到 `dump.ckpt`，
`GET namei_ext:w3:checkpoint` 返回 checkpoint value，readdir 只显示 `dump.rdb` 并隐藏
`dump.ckpt`；detach 后再次不加载 hidden checkpoint。raw result 位于
`results/phase1/20260615T-parent-key-poc/w3-redis-replay.jsonl`，summary 为 0 failure，
`redis_checkpoint_loaded_via_policy=true`、`post_restore_vfs_replay=true`、
`podman_criu_restore_executed=false` 和 `qualified_for_c8=false`。该 witness 证明
真实 Redis RDB load path 可以观察到 checkpoint policy 决策，但不是 Podman/CRIU
restore health、restore trace、0 mixed epoch 或 C8 证据。

`make kvm-w3-redis-counterfactual RUN_ID=20260615T-w3-redis-counterfactual-smoke-v1`
在同一修改内核 KVM 路径中补上 same-workload diagnostic comparator。该 target 先跑
`checkpoint_restore_view.bpf.c` Redis replay，再跑 `table_redirect.bpf.c` Redis replay，
最后生成 `w3-redis-counterfactual.jsonl`。table replay 只写两条 exact redirect rule：
lookup `dump.rdb -> dump.ckpt` 和 readdir `dump.ckpt -> dump.rdb`，但仍通过相同
Redis GET、readdir 和 detach oracle。counterfactual row 记录
`policy_replay_pass=true`、`table_replay_pass=true`、
`table_baseline_current_oracle_pass=true`、`table_rule_writes=2`、
`table_budget_failure=false`、`zero_mixed_epoch_checker=false`、
`restore_trace_checker=false` 和 `qualified_for_c8=false`。因此 W3 当前不能被写成
“exact-map diagnostic 不足”的正证据；它只能说明当前 Redis RDB replay oracle 太窄，后续 C8
需要真实 Podman/CRIU restore、post-restore VFS trace、0 mixed epoch/update/stale-window
checker，或其它 release-level claim-specific comparison 和 safety/semantic-boundary evidence。

新增 `make workload-w4-oracle-entries RUN_ID=20260614T-workloads-git-ceiling`
会生成 W4 cache witness manifests 和 `w4-cache-oracle-entries.tsv`。ccache row 使用
固定 Redis/nginx source hash 派生 Make-owned local-hit、stale-fallback 和 corrupt-reject
witness；BuildKit row 使用固定 Prometheus `go.mod` 作为 canonical cache witness。
这些 manifests 的 `result_level=host_cache_witness_manifest`、`policy_executed=false`、
`kvm_validated=false` 和 `output_hash_oracle=false`，只说明 cache witness inputs 与
真实 provenance 绑定，不说明真实 ccache、BuildKit、Go build/test 或 cache state
transition 已执行。

`make kvm-w4-oracle RUN_ID=20260614T-workloads-git-ceiling` 在 KVM guest 中为 4 个
cache witness entries 建立独立 synthetic directory，并分别运行
`cache_locality_view.bpf.c` 和 `table_redirect.bpf.c`。raw result 位于
`results/phase1/20260614T-workloads-git-ceiling/w4-oracle.jsonl`，输入哈希位于
`w4-oracle-inputs.sha256`，两个 policy summary 均为 0 failure。该结果仍是
`kvm_policy_path_oracle`，不验证 compiler/go output hash、cache transition trace、
stale/corrupt reject、update writes 或 stale window；每条 summary 记录
`qualified_for_c8=false`，因此 W4 仍不能计入 C1/C8 主结论。

`make kvm-w4-cache-content RUN_ID=20260614T-w4-cache-content-map` 新增并修订一个
`kvm_cache_content_oracle`。该 gate 在修改内核 guest 中读取
`w4-cache-oracle-entries.tsv`，按 `parent_relative` materialize workdir，把 manifest
中的 `original_backing_path` 复制成 `shadow_backing_component`，填充
`cache_locality_view.bpf.c` 的 `cache_rules` map，并通过普通 VFS open/read/readdir
检查四类分支：verified hit 只读到 `object.local` 且不读到 `object.bad`，stale
fallback 只读到 `stale.canon` 且不读到 `stale.local`，corrupt reject 只读到
`corrupt.reject` 且不读到 `corrupt.local`，miss canonical 读到 `pkg.canon`；同时检查
readdir alias/backing 一致性和 detach 后 alias 不可达。raw result 位于
`results/phase1/20260614T-w4-cache-content-map/w4-cache-content.jsonl`，其中
`map_update=1`、summary 为 0 failure，仍记录 `qualified_for_c8=false`。完整 Phase 1
run 的同类结果位于
`results/phase1/20260614T-w2-nginx-probes-phase1/w4-cache-content.jsonl`。该 gate
证明 manifest-derived W4 entries 能沿 `cache_rules` map-backed state dispatch，在真实
attach path 中影响普通 VFS open/read/readdir；但该 cache-content gate 本身仍不运行
真实 ccache/BuildKit，不测 compiler/go output hash、cache transition trace、
update/stale window，也没有 claim-specific comparison。

`make kvm-w4-cache-table-content RUN_ID=20260615T-w4-cache-table-content-smoke-v1`
随后用同一 W4 cache-content oracle 运行 `table_redirect.bpf.c`。该 target 复用
`w4-cache-oracle-entries.tsv` 和同一内容检查，只把 policy object 换成 exact-map
exact redirect。raw result 位于
`results/phase1/20260615T-w4-cache-table-content-smoke-v1/w4-cache-table-content.jsonl`，
输入哈希位于 `w4-cache-table-content-inputs.sha256`。summary 记录
`branches=4`、`pass=true`、`failures=0`、
`table_baseline_current_oracle_pass=true`、
`content_equivalent_table_oracle=true` 和 `qualified_for_c8=false`；逐 case 有
4 个 `attached_expected_match`、3 个 `attached_forbidden_mismatch` 和 4 个
`readdir_alias`。因此 W4 cache-content 当前是更强的负证据：verified hit、
stale fallback、corrupt reject 和 miss canonical 的 manifest-derived content oracle
仍可被 exact table 表达。后续 C8 必须依赖真实 stale/corrupt transition、
release-level operation-weighted hit rate、BuildKit/Prometheus cache trace、update/stale
window、claim-specific comparison 或 safety/semantic-boundary evidence。

`make kvm-w4-ccache-real RUN_ID=20260615T-parent-key-poc` 进一步新增一个
`kvm_real_ccache_workload_witness`。该 gate 在修改后的 kernel KVM guest 中运行真实
`ccache`，对 Redis `src/crc64.c` 和 nginx `src/core/ngx_string.c` 分别执行 cold/hot
两次 `ccache gcc -c`，要求 cold/hot object hash 一致，并从 `ccache --print-stats`
中检查 `cache_miss=2` 和 `direct_cache_hit=2`。raw result 位于
`results/phase1/20260615T-parent-key-poc/w4-ccache-real.jsonl`，object hash 位于
`w4-ccache-real-outputs.sha256`，ccache stats 位于 `w4-ccache-real-stats.txt`。
该 gate 随后把两个 hot object 写成
`w4-ccache-real-entries.tsv`，并用同一个 `cache_locality_view.bpf.c` content oracle
验证两个 ccache-derived object aliases 的 attached expected match、forbidden mismatch、
readdir alias 和 detach 行为；summary 中 `policy_content_oracle_failures=0`。
该结果比 Make-owned fixtures 更接近真实 W4 workload，但它仍不是 C8 证据：它没有
trace ccache 自身 cache path 如何通过 `namei_ext` 解析，没有 operation-weighted
policy cache hit rate，没有真实 stale/corrupt cache transition，也没有 table/update
budget counterfactual。

`make kvm-w4-ccache-trace RUN_ID=20260615T-parent-key-poc` 再补一个
`kvm_real_ccache_cache_path_trace_witness`。该 gate 复用 Redis `src/crc64.c` 和 nginx
`src/core/ngx_string.c`，先在独立 `CCACHE_DIR` 中完成 cold compile，再用
`strace -f -e trace=%file` 采集两个真实 hot compile。raw result 位于
`results/phase1/20260615T-parent-key-poc/w4-ccache-trace.jsonl`，trace logs 位于
`w4-ccache-trace-redis.strace.log` 和 `w4-ccache-trace-nginx.strace.log`。当前 run
记录 Redis hot compile 134 条 file-op trace、20 条 cache-path file ops；nginx hot
compile 602 条 file-op trace、20 条 cache-path file ops；ccache stats 仍为
`cache_miss=2` 和 `direct_cache_hit=2`。该结果证明真实 ccache hot path 在修改内核的
KVM guest 中确实触碰 cache directory，但 `policy_executed=false`，所以它只是 W4
真实 workload path evidence，不是 operation-weighted policy cache hit rate，也不能
计入 C8。

`make kvm-w4-ccache-policy-bridge RUN_ID=20260615T-parent-key-poc` 随后补一个
`kvm_real_ccache_policy_bridge_witness`。该 gate 从 Redis/nginx raw strace logs 中
抽取成功读取的真实 ccache cache object paths，生成
`w4-ccache-policy-bridge-trace-objects.txt` 和
`w4-ccache-policy-bridge-entries.tsv`，并在 KVM guest 中 attach
`cache_locality_view.bpf.c` 跑 verified-hit content oracle。当前 run 记录 4 个
trace-derived entries：Redis 2 个、nginx 2 个；`attached_expected_match=4`、
`attached_forbidden_mismatch=4`、`readdir_alias=4`、
`policy_content_oracle_failures=0`。该 bridge 证明真实 trace object component 能被
W4 policy oracle 消费，但 `ccache_compile_policy_executed=false` 且
`operation_weighted_policy_cache_hit_rate=false`，仍不能计入 C8。

`make kvm-w4-ccache-policy-compile RUN_ID=20260615T-parent-key-poc` 再补一个
`kvm_real_ccache_policy_compile_witness`。该 gate 复制上一阶段真实 `CCACHE_DIR`，
把 4 个 trace-derived cache objects 从 visible cache path rename 成 hidden `.local`
backing，然后在 attach `cache_locality_view.bpf.c` 后填充 `cache_rules` map，并运行
真实 Redis `src/crc64.c` 和 nginx `src/core/ngx_string.c` 的
`ccache gcc -c` hot compile。raw result 位于
`results/phase1/20260615T-parent-key-poc/w4-ccache-policy-compile.jsonl`，输入哈希位于
`w4-ccache-policy-compile-inputs.sha256`，输出哈希位于
`w4-ccache-policy-compile-outputs.sha256`。当前 run 记录
`policy_redirected_cache_objects=4`、`redis_trace_objects=2`、
`nginx_trace_objects=2`、`ccache_compile_policy_executed=true`、
`output_hash_match=true`、`failures=0`；ccache stats 记录 `cache_miss=0`、
`direct_cache_hit=2`、`local_storage_hit=2` 和 `local_storage_write=0`。该 witness
证明真实 ccache hot compile 能在 policy attach window 内通过 `namei_ext` 解析
trace-derived cache objects，并保持 Redis/nginx output object hash 与 baseline hot
object 一致。它仍是 `functional_only`：当前 hit rate 不是 release-level
operation-weighted metric，没有真实 stale/corrupt ccache transition、update/stale
window、BuildKit/Prometheus Go cache workload、claim-specific comparison 或 safety/semantic-boundary evidence，
因此仍记录 `qualified_for_c8=false`。

`make kvm-w4-ccache-table-compile RUN_ID=20260615T-parent-key-poc` 再补一个
`kvm_real_ccache_table_compile_witness`。该 gate 复用同一份真实 `CCACHE_DIR`、
同一组 Redis/nginx source file、同一组 4 个 trace-derived cache objects 和同一套
output hash oracle，只把 policy 换成 `table_redirect.bpf.c` 的 precomputed mapping。
raw result 位于
`results/phase1/20260615T-parent-key-poc/w4-ccache-table-compile.jsonl`，输入哈希位于
`w4-ccache-table-compile-inputs.sha256`，输出哈希位于
`w4-ccache-table-compile-outputs.sha256`。当前 run 记录
`policy_redirected_cache_objects=4`、`redis_trace_objects=2`、
`nginx_trace_objects=2`、`ccache_compile_policy_executed=true`、
`table_baseline_current_oracle_pass=true`、`content_equivalent_table_oracle=true`、
`output_hash_match=true` 和 `failures=0`；ccache stats 记录 `cache_miss=0`、
`direct_cache_hit=2`、`local_storage_hit=2` 和 `local_storage_write=0`。该 comparator
证明当前 sampled Redis/nginx ccache hot compile witness 能被 exact-map redirect
解释，因此它是 C8 的负面证据，而不是 C8 支持证据。

`make kvm-w4-ccache-release-counterfactual RUN_ID=20260615T-full-phase1-bench-variants`
把真实 ccache trace、trace-derived policy bridge、parent-scoped compile witness 和
exact-map compile diagnostic 放入同一个修改内核 KVM accounting gate。raw result 位于
`results/phase1/20260615T-full-phase1-bench-variants/w4-ccache-release-counterfactual.jsonl`，
输入哈希位于 `w4-ccache-release-counterfactual-inputs.sha256`。当前 row 记录
`trace_cache_path_file_ops=40`、`trace_cache_objects=4`、`parent_rule_writes=4`、
`exact_readdir_rule_writes=4`、`table_rule_writes=8`、
`eligible_object_policy_hit_rate=1`、`cache_path_policy_coverage=0.1`、
`attached_cache_path_file_ops=40`、`attached_policy_cache_object_ops=16`、
`attached_sampled_operation_hit_rate=0.4`、
`attached_sampled_operation_hit_rate_is_release=false`、
`table_baseline_current_oracle_pass=true`、
`operation_weighted_policy_cache_hit_rate=false` 和 `qualified_for_c8=false`。该 target
使 W4 当前负证据进入可审计 raw artifact：sampled object 覆盖不是 release-level
operation-weighted hit rate，且 exact-map diagnostic 仍通过。report gate 还重新检查 6 行
parent/table output sha、strace log 路径和非空性，并从 parent raw strace replay 复算
Redis/nginx sampled ops 与 object ops。

`make table-budget RUN_ID=20260614T-w2-nginx-probes-phase1` 读取 W1/W2/W3/W4 KVM path
oracle JSONL 和对应 TSV，生成 `table-budget.jsonl` 和
`table-budget-inputs.sha256`。该 artifact 记录每个 family 的 `entries`、
`table_entries_required`、`programmable_entries_observed`、`over_materialization_ratio`、
`update_writes_accounted`、`update_writes_basis=entry_count_from_phase1_table_load`、
committed budget 字段和 `qualified_for_c8=false`。当前 4 个 family 的
`table_baseline_current_oracle_pass` 均为 `true`，因此它只证明 accounting
infrastructure 和当前 path oracle 下的 table baseline 行为，不证明 C8。W4 cache-content
diagnostic comparator 还证明 table baseline 在当前 verified-hit/stale/corrupt/miss
content oracle 上也能通过；W4 exact-map ccache compile diagnostic 又证明 table
baseline 在当前 sampled ccache output oracle 上也能通过。真正 C8 仍需要 release-level
workload oracle、balanced dynamic path-view evidence、stale/update window 和 latency evidence。

不进入 Phase 1 主线的语义包括 hide、deny、权限决策、文件数据路径、writable
union、递归路径解析、用户态 policy 解释器和 YAML/JSON policy DSL。评估可以有
alias manifest、trace 参数和 oracle 配置，但这些是 workload 输入和实验判定材料，
不是 `policies/` 下的 policy 语言。

因此论文的设计目标是证明：在已实现并通过 KVM gate 的 ABI 能力范围内，同一个内核
ABI 能承载多类语义不同的 eBPF path-resolution extensions；每个 extension 只返回
受限 `PASS/REDIRECT`，但能用不同 policy logic 表达真实生产场景，并且比 FUSE 或
物化目录树更接近内核机制。

## Policy 评估方法

Policy evaluation 不是只看 BPF object 能否加载。它必须回答两个 reviewer 问题：

1. 对这个 workload，为什么窄 VFS/eBPF hook 比 FUSE、materialized tree、
   bind/symlink projection、OverlayFS 或 workload-native runtime 更合适？
2. 复杂 policy 是否仍然可验证、可复现、低开销，并且不破坏 VFS/lower filesystem
   语义？

每个发布级运行至少包含以下 policy 变体：

| Policy | 目的 | 必测场景 | 关键指标 | 通过条件 |
|--------|------|----------|----------|----------|
| `no_policy` | 无 attach 下界。 | B2, B8 | lookup/readdir p99、throughput。 | 作为下界，不支撑功能主张。 |
| `pass_only.bpf.c` | 隔离 static branch、attach 和 BPF call 开销。 | B2, B8 | p50/p99、cycles、instructions。 | p99 不超过 `no_policy` 1.1x，否则需要解释或优化。 |
| `redirect_alias.bpf.c` | Phase 1 same-parent 回归。 | B1, B2, B11 | correctness、readdir coherence、KVM gate。 | 0 checker failure，0 dmesg failure。 |
| `table_redirect.bpf.c` | 可选 exact-map diagnostic，只在 claim 明确讨论预计算映射时使用。 | B1, B12 | oracle pass/fail、setup、p99、map memory。 | 只解释 exact-map 边界，不是默认主 baseline。 |
| `build_graph_view.bpf.c` | 证明 build graph / declared-deps extension。 | B3, B12 | output hash、undeclared dep poison、generated/source precedence、p99。 | Redis/nginx/SQLite/BusyBox 中至少两个真实构建通过 oracle。 |
| `sandbox_fixture_view.bpf.c` | 证明 staging/test fixture substitution extension。 | B4, B12 | no-real-secret/config hash、endpoint checker、poison access、startup p99。 | nginx/PostgreSQL/Redis/Grafana/Git 中至少两个真实应用通过 oracle。 |
| `checkpoint_restore_view.bpf.c` | 证明 checkpoint/restore path view extension。 | B5, B7, B10, B12 | restore health、state/config/cache hash、0 mixed epoch、runtime path correctness。 | Redis/PostgreSQL/nginx/Grafana/Podman/CRIU trace 中至少两个通过 oracle。 |
| `cache_locality_view.bpf.c` | 证明 content-verified cache locality extension。 | B6, B12 | content hash、stale/corrupt rejection、hit/miss/stale coverage、p99/setup。 | Bazel remote cache、ccache、BuildKit cache、Nix store 中至少两个通过 oracle。 |

当 exact-map diagnostic 被纳入某个 claim 时，`table_redirect.bpf.c` 不是故意削弱的
strawman。默认定义如下：

- 允许 key 包含 ABI 暴露的离散上下文，例如 `event`、`parent_id`、`component`、
  `view_id`、`epoch`、`profile`、`parent_class` 和 `cgroup_id`。
- 不允许除 map lookup、exact match 和返回 `PASS/REDIRECT` 之外的 policy 分支；
  不允许实现 fallback chain、resolver、epoch state machine、branch coverage
  counter、用户态 policy 解释器或隐藏 rule engine。
- 允许在 workload state change 前通过 Make-owned loader 批量更新 maps，但每次
  update 的 entries、bytes、syscalls、latency 和 stale window 必须写入原始结果。
- 不允许根据同一 repetition 中未来会发生的 path sequence 手工生成 entries；trace
  replay workload 可以使用冻结 trace 作为公开输入，但这类结果只能证明 replay
  成本，不能单独支撑 C8。
- `over-materialization` 的默认门槛是：如果 claim 纳入 exact-map diagnostic，则预计算映射需要超过
  programmable policy 10x 的 map entries、map memory、update writes，或超过同一
  workload 声明的 update latency/stale-window 门槛。若运行前要改阈值，必须先改
  本文档和 tracker。
- 每个 exact-map diagnostic run 必须在 manifest 中写入 `max_entries`、`max_memory_bytes`、
  `max_update_writes`、`max_update_latency_ms`、`max_stale_window_ms` 和
  `budget_basis`。默认 budget basis 是同一 workload 上对应 programmable policy
  的 observed footprint；若使用固定硬件或产品 SLO 预算，必须在 run 前写入
  committed config。
- 如果 claim 使用 exact-map diagnostic，则对应 run 必须执行 `table_redirect.bpf.c`
  conformance check，证明该 BPF
  object 的 policy path 只包含 exact map lookup 和 `PASS/REDIRECT` 返回，不包含
  fallback/resolver/epoch state machine、branch-specific helpers 或用户态 rule
  interpreter。conformance check 的 source hash、object hash、verifier log 和
  checker output 必须进入 B12 原始结果。

某个 family 是否计入 C8 由该 family 的真实 workload oracle、claim-specific comparison 和
safety/semantic-boundary evidence 决定。若 exact-map 是相关替代方案，则上述 diagnostic 可以作为边界证据；
若不是，就不应把 table failure 作为默认 gate。

Policy correctness 使用 materialized oracle。对每个真实 workload，先生成一个
feature-equivalent 的 materialized ground truth（copy/symlink/bind 中能表达者），
再比较 `namei_ext` 下的：

- `statx/open/access/read/execve` 的 errno、内容 hash 和目标版本；
- `getdents64/find/glob` 的 visible name set；
- negative lookup 和 fallback 行为；
- lower filesystem permission failure；
- checkpoint restore session、cache state 变化和 workload profile 切换前后的
  lookup/readdir 一致性。

Policy performance 必须拆成四层：

- policy dispatch overhead：`no_policy` vs `pass_only.bpf.c`；
- simple redirect overhead：`pass_only.bpf.c` vs `redirect_alias.bpf.c`；
- exact-map diagnostic overhead：`redirect_alias.bpf.c` vs `table_redirect.bpf.c`；
- programmable extension overhead：`table_redirect.bpf.c` vs `build_graph_view.bpf.c`、
  `sandbox_fixture_view.bpf.c`、`checkpoint_restore_view.bpf.c`、
  `cache_locality_view.bpf.c`。

Policy complexity 不能只用代码行数描述，必须记录：

- BPF instruction count；
- verifier time；
- map 数量、map entry 数量、map memory；
- 每次 lookup/readdir 的 map lookup 次数；
- tail latency 随 alias entries、parent fanout、path depth、cgroup 数的变化；
- rejected program、invalid map update、invalid target 和 missing entry 的失败证据。

Policy ablation 必须能证伪“复杂可编程性有必要”：

- 去掉 `view_id`：不同 workload 或 test profile 是否会互相污染；
- 去掉 path-class dispatch：fixture substitution 是否退化成单文件替换，no-real-secret
  和 poison oracle 是否失效；
- 去掉 checkpoint epoch/session check：restore 后是否出现 checkpoint/current mixed view；
- 去掉 content-hash/cache-state check：stale/corrupt cache 是否会被错误使用；
- 去掉 target registry：真实 build/checkpoint/cache workload 是否被迫退化到 same-parent；
- 去掉 readdir handling：`open()` 和 `ls/find/glob` 是否不一致；
- 把 policy 固化成静态 table：是否失去 usecase-specific semantics、
  per-workload/per-session/per-cache-state update 能力，或需要内核内置越来越复杂的
  rule engine。

这些结果进入 B8 机制消融、B9 规模压力、B10 失败语义和 B12 policy-family
实验。若 qualifying policy families 不能展示出不同逻辑，或自然替代机制在真实 workload
上等价覆盖全部主 oracle、成本门槛和 safety/semantic boundary，论文主张必须从
balanced dynamic path-view abstraction 降级为更窄的 artifact 或机制探索主张。

## 真实工作负载清单

发布级运行必须使用真实公开来源或真实 trace。下表是计划级锁定清单；实现时必须
在 `configs/eval-osdi/workloads.lock` 或等价 Makefile 配置中记录 URL、commit 或
发布版、tarball SHA256、依赖版本、命令、trace 命令和许可证。替换任何条目都
会开启新的 run family，不能与旧数字直接混用。

真实项目名称本身不构成真实 workload 证据。每个主 workload 必须证明 alias/view
关系来自该系统的实际构建、依赖、fixture 注入、restore 或 cache 行为，而不是作者
手工为论文构造的路径集合。`workload/<workload-id>/evidence.md` 至少记录：

- `upstream_url`、`version_or_commit`、tarball SHA256 和许可证；
- `alias_manifest_source`：build trace、fixture/projected-volume/config/secret
  manifest、checkpoint manifest、restore trace、cache manifest、content-hash log 或
  冻结 trace；
- 生成 alias manifest 的 Make target、输入文件和输出 SHA256；
- redirected operation 的 operation-weighted hit rate；
- 未被真实 trace、manifest、restore log 或 cache log 命中的 alias 数量，以及它们
  是否只用于 scale/failure；
- checkpoint workload 的 `restore_session_switch_hit_rate` 和 post-restore VFS
  operation hit rate；
- cache workload 的 hit/miss/stale/corrupt state-transition hit rate；
- 对应 oracle 和 exact-map diagnostic 的 raw result path。

默认门槛是：支撑宏基准和 C1/C8 的运行中，至少 80% 的 redirected operations 必须
命中 provenance-derived aliases。低于该阈值的 workload 只能进入 appendix、B9 规模
或 B10 失败语义，不能支撑“真实生产路径解析需求”。

| ID | 场景 | 真实来源 | 规模和操作混合 | 冻结方式 | 代表性 |
|----|------|----------|----------------|----------|--------|
| W1 | U1 | Redis、nginx、SQLite 或 BusyBox 的固定发布版源码构建和真实 build trace。 | 小/中型 C/C++ 生产项目；100、1k、10k alias manifests；1/16/64/256 action cgroups。 | source SHA256、compiler version、build command、declared input manifest、generated output manifest、`strace -f -e trace=%file` trace。 | 真实 CI/build action 会反复构造 declared input、generated output、toolchain 和 external dep view。 |
| W2 | U2 | 真实服务的 staging/test fixture workload：nginx、PostgreSQL、Redis、Grafana 或 Git，使用 ConfigMap/Secret/projected-volume/Docker bind/secret mount 形式的配置、secret、cert、endpoint 或 socket files。 | 10/100/1k fixture aliases；1/32/128 workers；test profile、path class、poison sentinel。 | upstream release、service config、fake secret/cert、local endpoint config、poison manifest、startup trace、expected health/output hash。 | 真实生产应用常通过文件注入配置和 secret；测试环境需要替换危险路径而不是 deny/hide。 |
| W3 | U3 | checkpoint/restore workload：CRIU/Podman checkpoint archive、Redis/PostgreSQL/nginx/Grafana state/config/cache snapshot 或真实 restore trace。 | 1/10/100 restore sessions；state/config/cache/runtime-local path classes；冷/热 restore。 | checkpoint manifest、restore id、checkpoint epoch、state/config/cache hash、runtime socket/pid/temp fixture、health check command。 | checkpoint/restore 需要同一 restore session 内 state/config/cache 一致，并把 runtime-local paths 绑定到新环境。 |
| W4 | U4 | content-verified cache locality workload：Bazel remote cache trace、ccache compile workload、Docker BuildKit cache mount 或 Nix content-addressed store paths。 | 100、10k、100k cache entries；hit/miss/stale/corrupt states；1/16/64 workers。 | cache manifest、canonical manifest、content hashes、cache state log、command output hash、cache hit/miss/stale trace。 | 真实构建和包系统普遍使用 local/remote cache；正确性要求 local cache content 等于 canonical output。 |
| W5 | U1-U4 | W1-W4 产生的真实 file-operation trace replay。 | 至少 1M path operations；lookup/open/stat/access/getdents 比例来自 trace；cache-hot/cold。 | trace JSONL 包含 op、path、cwd、result class、timestamp order、seed、family id。 | 去掉 app nondeterminism，保留真实路径访问分布，用于 B2/B7/B9/B12 replay。 |

禁止把自造 hello-world HTTP 服务、手写玩具构建、随机生成包目录树作为 B3-B6
的主性能结论。它们只能用于 B1/B2/B7/B9/B10 的机制、scale 或 failure 覆盖。

## 工作负载目录布局

发布级评估的真实工作负载统一放在顶层 `workload/` 目录。每个具体工作负载必须
有自己的子目录，例如 `workload/w1-redis-build/`、`workload/w2-nginx-fixture/`
或 `workload/w3-redis-checkpoint/`。`bench/workloads/` 只保留项目自带的低层基准
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
| `overlayfs-kernel` | Linux OverlayFS。 | committed lower/upper/workdir layout；mount options 记录。 | 只在能表达同一 fixture/materialized view 时作为强 kernel baseline；除非 namei_ext 实现完整 rootfs surface，否则不做完整 rootfs 等价 claim。 |
| `fuse-redirectfs` | 项目自带 libfuse low-level path-remapping filesystem，由 Make 构建。 | FUSE mount options、cache flags、worker count、source hash 记录。 | 灵活 path-resolution 基线；任何 unsupported operation 是 hard failure。 |
| `k8s-projected-volume` | Kubernetes ConfigMap/Secret/projected-volume 或等价 materialized directory。 | object YAML、projected sources、mount layout、readOnly flag、source hash 记录。 | 只对 U2 等价；只能作为 fixture projection/materialization baseline。 |
| `podman-criu-restore` | Podman/CRIU checkpoint/restore 产物或 materialized checkpoint restore tree。 | checkpoint archive hash、restore command、runtime config、health check 记录。 | 只对 U3 等价；unsupported restore operation 是 hard failure。 |
| `cache-tool-native` | Bazel remote cache、ccache、BuildKit cache mount 或 Nix store 原生机制。 | exact command、cache config、manifest、hit/miss/stale log 记录。 | 只对 U4 等价。 |

每个基线行必须记录 `feature_equivalent=true/false`。非等价基线可以作为上下文，
但不能作为主张的主比较对象。unsupported baseline operation 是 hard failure，
除非在运行前明确标为范围外。

## 实验矩阵

| 块 | 主张 | 实验 | 基线/变体 | 指标 | 判定器 | 图表 | 优先级 |
|----|-------|------|-----------|------|--------|------|--------|
| B1 | C1,C4 | 路径解析正确性和一致性矩阵 | U1-U4 的 namei_ext policies | pass/fail、errno、listed set、content hash | lookup/readdir/access/exec property checker | 表 1 | 必须 |
| B2 | C3 | 微基准成本拆分 | native、no-policy、pass-only、redirect、bind、OverlayFS、symlink、FUSE | p50/p95/p99、throughput、CPU、ctx switches | 0 个语义失败 + 置信区间 | 图 1 | 必须 |
| B3 | C1-C3 | 构建依赖图宏基准 | copy、symlink、bind、FUSE、namei_ext | setup、构建 wall time、disk writes、objects、p99 metadata | output hash + undeclared dep poison + dependency manifest | 图 2 | 必须 |
| B4 | C1-C3 | 受控测试沙箱 fixture 宏基准 | k8s-projected-volume、bind、symlink、FUSE、namei_ext | fixture setup、startup、memory/worker、disk writes、p99 metadata | health/output + no-real-secret + endpoint + poison checker | 图 3 | 必须 |
| B5 | C1-C3 | checkpoint/restore path view 宏基准 | podman-criu-restore、copy、bind、FUSE、namei_ext | restore setup、health latency、p99 metadata、objects、stale window | restore health + checkpoint hash + runtime path + 0 mixed epoch checker | 图 4 | 必须 |
| B6 | C1-C3 | content-verified cache locality 宏基准 | cache-tool-native、copy、bind、FUSE、namei_ext | cache setup、hit/miss/stale latency、p99 metadata、storage | content hash + stale/corrupt reject + hit/miss/stale checker | 图 5 | 必须 |
| B7 | C4 | 并发下的目录视图一致性 | static mapping；若实现 update epoch 则一并测试 | checker failures、stale/mixed views、errno | lookup-set equals readdir-set per epoch | 表 2 | 必须 |
| B8 | C5 | 机制消融 | no hook、pass-only、redirect、no readdir、FUSE、symlink、每个场景的最佳简单基线 | overhead deltas、failed properties | ablation-specific oracle | 图 6 | 必须 |
| B9 | C6 | 规模和压力扫描 | aliases 10-100k、path depth 1-64、cgroups 1-512、热/冷缓存 | saturation、p99、memory、CPU、failures | 不允许静默错误结果 | 图 7 | 必须 |
| B10 | C6 | 健壮性和失败语义 | invalid redirect、verifier、unsupported mutation、detach/reload、cgroup migration | errno、dmesg、status | fail-fast、no panic/oops、no fail-open | 表 3 | 必须 |
| B11 | C7 | 可复现性和产物门禁 | 干净 checkout、Docker、KVM | exit status、manifest completeness | Make exit 0 + report gates | artifact 附录 | 必须 |
| B12 | C1,C8 | Policy family programmability | `build_graph_view`、`sandbox_fixture_view`、`checkpoint_restore_view`、`cache_locality_view`、FUSE/materialized/workload-native baselines | oracle pass/fail、algorithm path、verifier stats、map stats、p99 | 每个 policy family 的 usecase-specific oracle + claim-specific comparison + safety/semantic-boundary evidence + 真实存在性证据 | 图 8 / 表 4 | 必须 |

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
- 指标：p50/p95/p99、throughput、cycles、instructions、context switches、
  page faults、dentry/inode cache stats。
- 成功标准：
  - no-policy/pass-only p99 不超过 `native-direct` 的 1.1x；
  - redirect p99 不超过最佳功能等价内核基线的 1.5x；
  - redirect p99 至少比 `fuse-redirectfs` 好 2x，或删除 FUSE 性能主张。
- 失败解释：若 namei_ext 比 FUSE 或 symlink forest 更差，性能主张必须降级。

### B3. 构建依赖图宏基准

- 真实来源：W1/W2 的生产级开源项目构建和真实 file-operation trace。
- 指标：sandbox setup/teardown、build wall time、metadata p99、disk writes、
  created files/symlinks/mounts、CPU、memory、context switches。
- 判定器：build exit status 相同；deterministic outputs hash-identical；undeclared
  include/lib/tool 触发 poison sentinel；依赖 manifest 不泄露 backing-only names；
  lookup/readdir checker 通过。
- 成功标准：medium/large manifests 上 setup p50 或创建对象数至少 5x 优于
  copy/symlink/mount-heavy baseline；build wall-time p95 不超过最佳 feature-
  equivalent kernel baseline 的 1.1x，否则只能声称 materialization improvement。

### B4. 受控测试沙箱 fixture 宏基准

- 真实来源：W2 的真实服务发布版、配置、secret/cert fixture、local fake service
  endpoint 和 startup trace。禁止用 hello-world 服务支撑主结论。
- 范围：只评估 fixture substitution，不做访问控制、安全隔离、hide 或 deny claim。
- 指标：fixture setup、startup 到首次成功响应、metadata p99、disk writes、
  memory/worker、poison sentinel hit/miss、真实 secret/config open count。
- 判定器：health/output 匹配；production secret/config/cert backing hash 从未被打开；
  endpoint 指向 local fake service；dangerous/prod-only path 触发 poison sentinel；
  lookup/readdir checker 通过。
- 成功标准：fixture setup 至少 5x 优于 symlink/copy/projected-volume materialization；
  startup p99 不超过最佳 feature-equivalent kernel baseline 的 1.5x；相对 FUSE 至少
  2x。

### B5. checkpoint/restore path view 宏基准

- 真实来源：W3 的 CRIU/Podman checkpoint archive、真实 service snapshot manifest
  或 restore trace。不要求 Phase 1 完整实现 CRIU，但主结论必须来自真实 checkpoint
  layout 或 restore manifest。
- 指标：restore view setup、health-check latency、metadata p99、checkpoint state/
  config/cache file count、runtime-local path remap latency、stale window。
- 判定器：restored service health check 通过；state/config/cache hash 等于 checkpoint
  manifest；socket/pid/temp 等 runtime-local paths 解析到 restore fixture；同一
  restore session 内 0 mixed checkpoint epoch；lookup/readdir checker 通过。
- 成功标准：restore view setup 或创建对象数至少 5x 优于 copy/bind/materialized
  restore tree；health-check p99 不超过最佳 feature-equivalent baseline 的 1.5x。

### B6. content-verified cache locality 宏基准

- 真实来源：W4 的 Bazel remote cache trace、ccache compile workload、Docker
  BuildKit cache mount workload 或 Nix content-addressed store paths。
- 指标：cache view setup、hit/miss/stale/corrupt path p99、content hash check
  latency、storage、canonical fetch count、cache update writes。
- 判定器：local cache hit content hash 等于 canonical；stale/corrupt cache 不被使用；
  miss 走 canonical/pass-through；hit/miss/stale/corrupt 分支均有 coverage；
  command output hash 匹配。
- 成功标准：hit path p99 不超过 native cache-tool baseline 的 1.5x；stale/corrupt
  0 unexpected hit；setup 或 update writes 明显低于 table/materialized baseline。
- 失败解释：若没有 content-hash checker 或只测 always-hit cache，U4 不能支撑 C8。

### B7. 并发下的目录视图一致性

- 目的：证明 `open` 能看到的 alias 和 `ls/find/glob` 看到的名字一致。
- 工作负载：真实树上的并发 `open/stat/access/readdir/glob/find`；update epoch
  只在实现后进入主 run。
- 判定器：同一 policy state、checkpoint restore session 或 cache state 内，
  `readdir(parent)` 的 visible aliases 等于可 lookup 集合。
- 成功标准：发布级运行中 0 个一致性违规。

### B8. 机制消融

每个消融必须回答一个审稿人问题：

- no-policy vs pass-only：static branch 和 attach residual overhead 是多少？
- pass-only vs redirect：policy decision 和 redirected lookup 成本是多少？
- redirect without readdir：readdir hook 是否真的提供 coherence？
- build_graph no precedence：generated/source/toolchain/deps precedence 是否真的必要？
- sandbox_fixture no path-class：config/secret/cert/socket/endpoint 分流是否真的必要？
- checkpoint_restore no session/epoch check：restore 后是否会出现 mixed checkpoint/current
  view？
- cache_locality no content-hash：stale/corrupt cache 是否会被错误接受？
- 每个使用场景的最佳简单基线：symlink、bind、OverlayFS、native tool、wrapper 是否
  已经足够？
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
- 当前实现新增了 B12 release contract 的 Make targets。`make eval-osdi-smoke`
  默认先运行 `phase1`，再从同一 `RUN_ID` 的 Phase 1 full root 生成
  `results/eval-osdi/paper/<run-id>/b12-policy-family/`；复用已有 full root 时使用
  `make eval-osdi-policy-family-ledger RUN_ID=<eval-run> EVAL_OSDI_PHASE1_RUN_ID=<phase1-run>`。
  `make eval-osdi-policy-family` 和 `make eval-osdi-paper` 是 hard gate：若四个
  policy family 没有全部达到 `qualified_for_c1_c8=true`，目标必须失败。
- 当前实现也新增了 B2/B8 performance input contract 和 comparison verdict。
  `make eval-osdi-performance-ledger` 从已有 Phase 1/KVM bench root 生成
  `results/eval-osdi/paper/<run-id>/b2-performance/`，记录 `baseline`、
  `pass_only`、`table_redirect_empty`、`table_redirect_hit` 和 `policy`
  五组 variant；`pass_only` 衡量 attach/static-branch/BPF-call 剩余开销；
  `table_redirect_empty` 衡量通用 exact-table miss path 的 map lookup 开销，不代表
  populated table-hit baseline；`table_redirect_hit` 在 KVM guest 中填充
  `exact_redirects` 后衡量 populated table hit redirect path；`policy` 仍是
  redirect-alias 功能路径。随后 `make eval-osdi-performance-comparison`
  读取 20-sample KVM microbench、tail/CI、随机化顺序、system metrics 和
  copy/symlink/bind/OverlayFS/FUSE release baselines，生成
  `performance-comparison.jsonl`。comparison gate 还要求 internal 和 external latency
  rows 至少使用 `EVAL_OSDI_REQUIRED_LATENCY_BATCH=64`。旧 20-sample pilots 的唯一样本数
  足够，但每条 latency row 只有 4 个操作，因此被降级为 diagnostic negative evidence。
  原始 batch=64 rerun 已让 `input_gate_pass=true`，但 threshold verdict 仍为负：
  `kernel_p99_threshold_pass=false`、`fuse_speedup_threshold_pass=false`、
  `pass_only_threshold_pass=false`。该 run 说明 B2/B8 已不再是 input-blocked。
- RCU-pass fastpath 已作为优化候选测试并拒绝。第一版允许 PASS 在 RCU-walk 中继续，
  REDIRECT 退回 `-ECHILD`；第二版对 REDIRECT 尝试 `try_to_unlazy(nd)` 并复用 decision。
  两版都能在修改内核 KVM 中跑通 batch=64 release input，且 pass-only/native residual
  分别降到 1.48x 和 1.38x；但最差 policy/native p99 分别恶化到 2.49x 和 2.43x，
  所以不能保留为主线优化，也不能支持 C3/C5。
- ctx 初始化拆分 PoC 随后作为 no-UAPI-change 优化候选完成。它移除
  `namei_ext_init_ctx()` 的整块 `memset()`，改为显式初始化字段、只清零 copied
  name tail 和完整 `redirect_name[]` output buffer。KVM release comparison
  `20260615T-eval-comparison-ctx-init-split-batch64-v1` 中 `input_gate_pass=true`、
  `pass_only_threshold_pass=true`，max pass-only/native p99 降到 1.095x；但
  `kernel_p99_threshold_pass=false`、`fuse_speedup_threshold_pass=false`，max
  policy/native p99 为 1.81x，min policy/FUSE p99 speedup 为 1.64x。因此它只能
  作为 pass-only residual attribution evidence，不能支持 C3/C5。hard gate
  `20260615T-eval-comparison-ctx-init-split-batch64-hardgate-v1` 按预期失败。
- tail sample-density diagnostic 随后把每组 latency rows 从 20 增到 200：
  `20260615T-eval-comparison-ctx-init-split-tail10-v1` 中 `input_gate_pass=true`、
  `fuse_speedup_threshold_pass=true`，min policy/FUSE p99 speedup 为 2.26x；但
  `kernel_p99_threshold_pass=false`、`pass_only_threshold_pass=false`，max
  policy/native p99 为 4.37x，max pass-only/native p99 为 2.62x。该结果说明
  FUSE 2x 已不是主要 blocker，下一步应定位 pass-only/readdir/tree-walk tail
  residual。hard gate
  `20260615T-eval-comparison-ctx-init-split-tail10-hardgate-v1` 按预期失败。
- rusage/no-hook diagnostic 随后补齐 per-row CPU/fault/context-switch 和 Make-owned
  no-hook baseline-only selector。`20260615T-kvm-bench-rusage-tail10-v1` 显示非 exec
  p99 rows 基本没有 fault/context-switch，pass-only 与 policy 的 self CPU/op 同步上升；
  `20260615T-kvm-bench-nohook-baseline-tail10-v1` 中 max pass-only/nohook p99 ratio 为
  1.306x；`20260615T-kvm-bench-baseline-passonly-tail10-v1` 中 matched
  pass-only/native worst case 为 1.323x。该结果说明 C5 residual 主要是 common
  hook/dispatch CPU，并且仍未过 1.1x threshold；因此 C5 仍 unsupported。
- 当前实现还新增了默认关闭的 raw latency sampling plumbing。设置
  `BENCH_LATENCY_SAMPLES>0` 后，`make kvm-bench` 会在真实 KVM guest attach 路径下为
  每个 `(bench, variant, sample)` 追加 `event=bench_latency` row，记录
  `latency_sample`、`ops`、`elapsed_ns`、`ok` 和 `fail`。pilot run
  `20260615T-kvm-bench-latency-pilot` 产生 70 条 latency row 且 0 failure；但该 run
  只是 `kvm-bench` 子集，不含完整 Phase 1 `metadata.json`，不能作为 B2/B8 release
  ledger root。`bench_latency` row 是 batch ns/op raw observation，不是已经计算好的
  p95/p99 tail-latency artifact；后续 20-sample release-sample run 已补齐
  repetition、CI、randomized order、system metrics、percentile analysis 和外部
  baseline input，但该批 raw latency row 的 batch size 只有 4。后续
  `BENCH_LATENCY_BATCH=64` 和 `BASELINE_LATENCY_BATCH=64` rerun 已消除该方法学阻塞；
  当前 C2/C3/C5 失败在性能阈值和 C2 macrobench 缺口，而不是 latency input。
- 完整 Phase 1 report 已把上述 variant set、每个 variant 的 7 个 bench row、
  `bench-start.policy_variants`、policy attach/detach 和 `table_redirect_hit`
  的 66 条 map update 写成 hard gate。因此旧的
  `20260615T-full-phase1-gatefix` 不能再作为当前 canonical Phase 1 closure。
  `make eval-osdi-performance` 仍是 hard gate；当前必须失败，不能把 release
  input evidence 或 threshold-failing comparison 写成 OSDI 性能结论。

### B12. Policy family programmability

- 目的：证明同一个窄 VFS path-resolution ABI 支持已测多类读多写少、元数据密集的
  eBPF path-resolution extensions，而不是一个固定 redirect table 或为每个
  benchmark 手写的特殊路径。发布级 wording 只覆盖 qualifying family。
- 工作负载：W1-W5 中每个 qualifying policy family 至少两个真实应用或真实 trace。
  若某类 family 暂时只有一个真实应用通过，C8 只能标为 partial。
- 结果根目录：`results/eval-osdi/paper/<run-id>/b12-policy-family/`。该目录必须
  包含每个 family/workload row 的 raw JSONL、stdout/stderr、dmesg、policy verifier
  log、branch coverage、diagnostic comparator output、oracle output 和 manifest。
- 当前 contract ledger 已可从完整 Phase 1 root 生成：
  `results/eval-osdi/paper/20260615T-eval-contract-bench-variants/b12-policy-family/policy-family.jsonl`。
  该 ledger 的输入哈希位于
  `results/eval-osdi/paper/20260615T-eval-contract-bench-variants/b12-policy-family/policy-family-inputs.sha256`。
  它记录四类 family 的 `semantic_witness_pass=true`，但
  `release_metric_pass=false`、`table_counterfactual_support=false`、
  `qualified_for_c1_c8=false`，summary 中 `qualified_families=0`、
  `release_gate_pass=false`。因此当前 B12 hard gate 正确失败，不能支撑 C1/C8。
  后续 W3 Redis same-workload counterfactual 已经进入 Make/report/ledger 输入契约：
  当前结果是 `table_baseline_current_oracle_pass=true`、`table_rule_writes=2`、
  `qualified_for_c8=false`，因此它只会继续阻止 checkpoint/restore family 被误计为
  C8-qualified。
- Policy families：
  - `build_graph_view.bpf.c`：构建 action 逻辑，测试 generated/source/toolchain/deps
    precedence、undeclared dependency poison 和 action-specific fallback。
  - `sandbox_fixture_view.bpf.c`：受控测试沙箱逻辑，测试 config/secret/cert/socket/
    endpoint path-class substitution、fake fixture、local fake service 和 poison
    sentinel。
  - `checkpoint_restore_view.bpf.c`：checkpoint/restore 逻辑，测试 checkpoint epoch
    consistency、state/config/cache restore view、runtime-local path remap 和 mixed
    epoch rejection。
  - `cache_locality_view.bpf.c`：content-verified cache locality 逻辑，测试 cache
    hit/miss/stale/corrupt 分支、canonical fallback 和 content hash correctness。
- 对照：`table_redirect.bpf.c`、FUSE path-remapping、symlink/copy/bind 中可表达的
  materialized oracle。
- 指标：每个 policy 的 oracle pass/fail、真实存在性证据、实际算法路径、
  bounded step count、BPF instruction count、verifier time、map count、map entries、
  map memory、每次 lookup/readdir map lookup 次数、p50/p95/p99、setup latency、
  update latency、dmesg/verifier/runtime failures。diagnostic comparator 还必须报告
  table entries、map memory、update writes、update latency、stale window、oracle
  violation 和是否超过对应自然机制。
- 每个 family/workload row 必须记录：policy source/object hash、workload evidence
  path、input lock/trace hash、seed、repetition、variant order、oracle binary 或
  checker target、diagnostic comparator config、decision gate、raw failure path 和
  `row_result`。`row_result` 只能取
  `qualified_for_c8`、`functional_only`、`appendix`、`blocked`、`unsupported`。
  只有 `qualified_for_c8` row 可以被 C1/C8 计数。
- 成功标准：
  - 至少四个 qualifying policy family 都在同一 kernel ABI 上加载、attach、运行，
    不需要 kernel rebuild 或新增内核特例；
  - 至少四个 qualifying family 达到 `qualified_for_c8`，每个 family 至少两个真实
    应用或真实 trace 通过 usecase-specific oracle；
  - 每个 family 的 `workload/<workload-id>/evidence.md` 记录真实系统来源和为什么
    需要该算法语义；
  - 每个 family 的必要 semantic witness 分支都在真实 workload 或真实 trace 中命中；
  - 支撑 C1/C8 的 workload 满足 provenance-derived alias hit-rate 门槛；
  - 四个 family 至少覆盖三种不同有界决策复杂度：priority cascade、path-class
    fixture substitution、checkpoint epoch consistency、content-hash/cache-state
    dispatch；
  - claim-specific comparisons 覆盖 workload-native、materialized、FUSE 或 copy/bind/symlink
    等自然替代方案；exact-map diagnostic 只在预计算映射是相关替代方案时作为边界证据；
  - FUSE 能表达的场景必须报告开销，FUSE 不能表达或失败的场景必须记录原始失败。
- 失败解释：若所有主场景都能由简单自然基线等价满足 oracle 和成本门槛，论文不能声称需要
  eBPF 可编程性；若每个 policy 只服务一个 benchmark，论文不能声称同一个窄 ABI
  支持多类 extension；
  旧的 `language_resolver_view.bpf.c`、`rollout_epoch_view.bpf.c` 和
  `legacy_profile_view.bpf.c` 可以作为 appendix/candidate families，但不能替代
  上述四个主线 family，除非重新通过同样的 citation、semantic witness、claim-driven
  baseline review 和 subagent review。

## 运行顺序

| Run ID | 阶段 | 目的 | 配置 | seed/reps | 决策门槛 | 风险 |
|--------|------|------|------|-----------|----------|------|
| R001 | 健康检查 | Phase 1 回归 | `make phase1` | 1 次冒烟 | 0 个 report failure | 只做 sanity，永远不支撑论文主张 |
| R010 | 健康检查 | 构建 OSDI policies 和工作负载二进制 | `make eval-osdi-build` | 不适用 | compile/verifier pass | 可能漏运行时错误 |
| R020 | 正确性 | B1 小规模正确性矩阵 | `make eval-osdi-correctness SAMPLES=1` | 固定 seed | 0 个 checker failure | 小树 |
| R030 | 试运行 | B2 微基准试运行 | `make eval-osdi-micro SAMPLES=5` | 5 次重复 | 0 个语义失败 | pilot 不支撑论文主张 |
| R040 | 基线 | 复现 U1-U4 基线 | `make eval-osdi-baselines` | 5 次试运行重复 | 所有基线 oracle 通过 | 基线可能不等价 |
| R050 | 主实验 | 构建沙箱发布级运行 | `make eval-osdi-build-sandbox SAMPLES=20` | 随机顺序 | hash/checker/CI pass | 构建时间长 |
| R060 | 主实验 | 受控测试沙箱 fixture 发布级运行 | `make eval-osdi-sandbox-fixture SAMPLES=20` | 随机顺序 | health + no-real-secret + poison checker pass | fixture provenance 难 |
| R070 | 主实验 | checkpoint/restore path view 发布级运行 | `make eval-osdi-checkpoint-restore SAMPLES=20` | 随机顺序 | restore health + hash + runtime path checker pass | checkpoint 集成范围 |
| R075 | 主实验 | content-verified cache locality 发布级运行 | `make eval-osdi-cache-locality SAMPLES=20` | 随机顺序 | content hash + stale/corrupt reject pass | cache state 控制难 |
| R080 | 决策 | 一致性压力测试 | `make eval-osdi-coherence SAMPLES=10` | 固定 seed，5 分钟 | no checker violation | 可能暴露设计 bug |
| R090 | 决策 | 机制消融 | `make eval-osdi-ablation SAMPLES=30` | 随机顺序 | ablation oracle pass | 简单基线可能胜出 |
| R095 | 决策 | policy family 多样性 release | `make eval-osdi-policy-family SAMPLES=20`，结果根目录 `results/eval-osdi/paper/<run-id>/b12-policy-family/` | 每个 family 至少两个 workload row，随机顺序 | semantic witness + evidence + alias hit rate + exact-map diagnostic + budget gate | 可能证明不了 balanced dynamic path-view claim |
| R096 | 决策 | performance/baseline release gate | `make eval-osdi-performance SAMPLES=20`，结果根目录 `results/eval-osdi/paper/<run-id>/b2-performance/` | 至少 20 次重复，随机顺序 | p50/p95/p99 + CI + named baselines + correctness oracle pass | 当前 Phase 1 bench 只是 smoke |
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
- `policy.name`、`policy.family`、`policy.algorithm_class`、
  `policy.object_sha256`、`policy.source_sha256`、可选
  `policy.map_schema_sha256`、`policy.instruction_count`、`policy.verifier_time_ms`、
  `policy.branch_coverage`；
- `workload.id`、`workload.upstream_url`、`workload.version_or_commit`、
  `workload.input_manifest_sha256`、`workload.trace_sha256`、
  `workload.alias_manifest_sha256`、`workload.alias_manifest_source`、
  `workload.alias_hit_rate`、`workload.evidence_path`、
  `workload.source_citations`、可选 `workload.fixture_manifest_sha256`、
  `workload.checkpoint_manifest_sha256`、`workload.restore_trace_sha256`、
  `workload.cache_manifest_sha256`、`workload.content_hash_manifest_sha256`；
- `baseline.id`、`baseline.config_sha256`、`baseline.feature_equivalent`；
- `table_counterfactual.key_schema_sha256`、`table_counterfactual.entries`、
  `table_counterfactual.map_memory_bytes`、`table_counterfactual.update_writes`、
  `table_counterfactual.update_latency_ms`、`table_counterfactual.stale_window_ms`、
  `table_counterfactual.max_entries`、`table_counterfactual.max_memory_bytes`、
  `table_counterfactual.max_update_writes`、
  `table_counterfactual.max_update_latency_ms`、
  `table_counterfactual.max_stale_window_ms`、`table_counterfactual.budget_basis`、
  `table_counterfactual.conformance_check_path`、
  `table_counterfactual.budget_result`；
- `b12.row_result`：`qualified_for_c8`、`functional_only`、`appendix`、`blocked` 或
  `unsupported`；
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
- C5 转向触发条件：如果简单基线在主场景上满足同样 oracle 和阈值，该 use case
  不能再支撑机制优势；论文必须删除该 use case 的优势 claim，或改成明确的
  tradeoff/case-study，不得继续声称广泛性能收益。
- C8 限制：只有通过 semantic witness、真实来源证据、claim-specific comparison
  和 safety/semantic-boundary evidence 的 family 才能计入 balanced dynamic
  path-view abstraction claim。旧的 resolver/rollout/legacy family
  只能作为 appendix/candidate，不能在没有重新评审的情况下填补四类证据门槛。
- C7 限制：pilot/smoke 或 dirty run 不能支撑论文主张。

## 结果后的主张门禁

最终结论必须在原始结果存在后产生。

| 主张 | 证据文件 | 结论 | 可使用表述 |
|-------|----------|---------|------------|
| C1 | B1、B3-B6、B12 原始/checker outputs | 支持 / 部分支持 / 不支持 | `namei_ext` 对已测真实场景表达多类读多写少的 programmable path-resolution extensions，且不实现 file data path。 |
| C2 | B3-B6 setup/storage/resource outputs | 支持 / 部分支持 / 不支持 | `namei_ext` 降低已测动态 path-resolution customization 的物化成本。 |
| C3 | B2-B6 latency/resource outputs | 支持 / 部分支持 / 不支持 | `namei_ext` 在已测工作负载中满足声明的 p99 kernel/FUSE 阈值。 |
| C4 | B1/B7 checker outputs | 支持 / 部分支持 / 不支持 | lookup 和 readdir 对声明的 redirect policies 保持一致。 |
| C5 | B8 ablation outputs | 支持 / 部分支持 / 不支持 | VFS-level placement 和 lower-FS ownership 解释了测得收益。 |
| C6 | B9/B10 stress/failure outputs | 支持 / 部分支持 / 不支持 | `namei_ext` 有测得的规模边界和 fail-fast 行为。 |
| C7 | B11 artifact outputs | 支持 / 部分支持 / 不支持 | artifact 能从 Makefile-owned KVM/Docker workflows 和 raw provenance 复现。 |
| C8 | B8/B12 policy-family outputs、workload evidence、claim-specific comparison、safety/semantic-boundary evidence | 支持 / 部分支持 / 不支持 | 同一个 `namei_ext` ABI 承载多个真实、算法结构不同的 eBPF path-resolution policy families，并在动态 path view 上体现 expressiveness、safety 和 efficiency 的平衡。 |
