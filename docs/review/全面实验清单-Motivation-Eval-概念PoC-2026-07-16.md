# namei_ext 全面实验清单——Motivation / Evaluation / 概念性 PoC

**日期：** 2026-07-16
**基于：** origin/main 179e642（2026-07-15 最新计划）

本清单把合作者当前计划里已有的实验（标 **[已计划]**，附来源 file:line）与我们基于担忧分析建议补充的实验（标 **[我方补充]**）合在一处，给出每条实验的目的、判定标准与指标、基线对照、当前状态、优先级，供投稿前排期使用。

## 背景：三个研究问题

论文围绕三个 RQ 组织评估：

- **RQ1（表达力/充分性）：** Can a narrow VFS name-resolution extension express real state-dependent path-view policies without taking over filesystem semantics?
- **RQ2（成本 vs 功能等价的 FUSE）：** What is the cost of putting programmable policy on the VFS name-resolution path compared with a feature-equivalent FUSE policy implementation?
- **RQ3（边界/安全）：** Does namei_ext provide a narrower verifier-bounded, fail-closed ownership boundary than building a custom or stackable filesystem when the needed policy is only name resolution?

（来源：evaluation.md:29-33）

论文的定位序列：bind/Overlay/materialization < eBPF LSM < namei_ext < FUSE/custom（evaluation.md:11-13）。

### 术语速查

下文涉及的术语在此统一说明，后文不再重复解释：

| 术语 | 含义 |
|------|------|
| oracle | 判定标准——预先定义好的"正确行为是什么"，实验结果必须满足这些条件才算通过。例如"文件 A 在删除后 lookup 必须返回 ENOENT"就是一条 oracle。 |
| pass-through | 直接放行——策略不做任何修改、把路径查找原样交给底层文件系统完成。 |
| RCU-walk | Linux VFS 查找路径名时的一种无锁快路径：不拿 dentry（目录项缓存条目）的锁，靠 RCU（一种读多写少场景的内核同步机制）保护，速度快但遇到需要特殊处理的路径时必须退回到加锁的慢路径（ref-walk）。 |
| static key | 内核的一种编译期可选分支机制：关闭时分支指令被 NOP 覆盖、零运行时开销，打开时跳转到实际代码。 |
| cgroup | Linux 的控制组——把一组进程归到同一个组里、对它们统一施加资源或策略限制。namei_ext 的策略按 cgroup 粒度附着。 |
| whiteout | overlayfs 里用来标记"这个文件已被删除"的特殊条目——上层放一个 whiteout 条目后，即使下层还有同名文件也不再可见。 |
| symlink | 符号链接——一个文件只存一个路径字符串，访问它时内核自动跳转到那个路径指向的真实文件。 |
| feature-equivalent FUSE | 功能等价的 FUSE 实现——用 FUSE（一种让用户态程序实现文件系统的内核框架，每次操作需要内核态和用户态之间来回切换）写一份策略，让它处理同一套状态、同一棵源树、同样的操作组合、通过同一套 oracle，作为开销对比的公平对照。 |
| fail-closed | 安全拒绝——遇到畸形输入、不认识的决策、加载失败时，默认行为是拒绝而不是放行。例如策略返回一个未注册的 target，内核返回 ENOENT 而不是放行访问。 |
| bootstrap CI | 从已有样本中有放回地重新抽样数千次，用这些重抽样本的统计量（如中位数）算出的置信区间，不依赖正态分布假设。 |
| submodule / gitlink | Git 的子模块机制——主仓库里记录一个指向另一个 Git 仓库某个 commit 的指针（gitlink），`git submodule update` 时按这个指针检出对应版本的代码。 |
| artifact evaluation | 会议论文接收后，由审稿委员会从零复现实验、验证结果可重复的审查环节。 |

---

## 一、Motivation 实验（建立"问题真实"的证据）

**现状：** 动机章节（02-motivation.tex）全节无任何定量证据，只有定性断言加来源系统引用；论文自述「We use source systems to choose workloads and correctness conditions, not as separate contributions.」（02-motivation.tex:35-38）。示例表 tab:path-view-examples（:65-88）没有数字。因此动机侧目前不存在实验，以下 M1/M2 是我方建议补充的定量测量，M3 是纯引用工作（不需要做实验）。

| 编号 | 来源 | 目的 | oracle / 指标 | 基线臂 | 状态 | 优先级 |
|------|------|------|-------------|--------|------|--------|
| M1 | **[我方补充]** | 测量"为什么不直接把视图提前构建好再用"——在真实负载下证明视图的切换足够频繁、或每次构建视图的成本足够高，使得"提前构建好"在时间上来不及。 | 在真实负载（可复用实验 A 的 AgentFS trace / 实验 B 的 SWE 行）中测量：单次视图构建（overlay 重新挂载 / bind 换绑 / symlink 森林重建）的耗时 + 单位时间的视图切换次数。产出一张"切换频率 x 单次构建成本"的端到端时间占比图。 | overlay remount / bind rebind / symlink forest rebuild | 无代码、无数据 | 中——可与 E7 复用同一批测量 |
| M2 | **[我方补充]** | 回答 so-what：这点成本差对谁来说重要、在什么切换频率下动态策略才划算。 | 总成本 = 切换成本 x 切换频率 + 每次查找开销 x 查找总数；横轴 = 每两次切换之间的 lookup 次数；画 namei_ext / overlay-remount / FUSE 三条成本线，标出交叉点；实测数据画实线、推算区间画虚线并在图上注明"推算值、非实测"。 | namei_ext / overlay-remount / FUSE | 无代码、无数据 | 中——依赖 M1 数据 |
| M3 | **[我方补充，纯搬运、非实验]** | 把动机从假设句（01-introduction.tex:12-15 使用 "can" 条件句式）升级为"有人确实为此付出了大量工程代价"。搬运 doc 24 已备好的实际工程案例：DeltaBox 定制 6.8 内核 + 565 行 ioctl；TClone 改内核 + CRIU；YoloFS 2.5kLoC 内核模块；Bazel 五代沙箱 + sandboxfs 在 7.0.0 被移除归档。 | 不适用——属引用工作 | 不适用 | 已备好，零研究成本 | 高（先做，马上可用） |

---

## 二、Evaluation 实验（RQ1 / RQ2 / RQ3）

**总状态：** 05-evaluation.tex 中 RQ1 x 2、RQ2 x 2、RQ3 x 2 共 6 个 `\textbf{[Result]}` 结果单元格全部空缺。论文自述（:193-195）：「This draft has not yet completed the reviewed KVM source-oracle rows, the correctness-gated namei_ext/FUSE latency and macro-runtime rows, or the workload-specific ownership and invalid-policy rows required to answer the RQs.」no-hook / lower-FS 行定位为校准行：「They are not competing baselines.」（05-evaluation.tex:42-47）。

### RQ1 表达力/充分性

| 编号 | 来源 | 目的 | oracle / 指标 | 基线臂 | 状态 | 优先级 |
|------|------|------|-------------|--------|------|--------|
| E1 | **[已计划]** evaluation.md:114；plan A:128-137 | **实验 A：Agent workspace lifecycle oracle 通过。** 角色 = headline（最核心的实验）。证明 namei_ext 能正确表达 AgentFS 来源的工作区生命周期视图策略。 | oracle 要点（plan A:128-137，逐字）：final logical tree = AgentFS-derived expected tree；edited 文件走 upper、unchanged 走 base；deleted/whiteout 条目在 lookup+readdir 中不可见；symlink 行为匹配；cached-negative 在切换后可见；host/base 树除声明的 lower-FS state 文件外不变；lower-FS 的 permission/data-path/write/page-cache/persistence 保全。 | native（无策略的原始行为）+ feature-equivalent FUSE 同 oracle | 原型矩阵已多次跑过，最新评审为 supporting-only/incomplete（evaluation.md:97-98、185-194）。底层机制 HIDE 已 KVM-validated（`make kvm-functional`，results/phase1/20260713T014740Z-efb9dc00）；SELECT_TARGET 初步验证；目录别名 + final-object selection「remain workload-oracle dependent」。**缺：** AgentFS-derived rename/unlink/cached-negative、bash/git command-sequence trace、source-tied RQ3 boundary rows、broader invalid-policy containment、per-op raw samples、uncertainty、macro runtime。 | 最高 |
| E2 | **[已计划]** evaluation.md:115；plan B:134-150 | **实验 B：Environment/cache 五态 oracle 通过。** 角色 = decisive（决定论文能不能成立的关键实验）。证明 namei_ext 能正确处理环境缓存的五种状态。 | 五态 oracle（plan B:134-150，逐字）：hit = select verified local，输出 hash 匹配 canonical；miss = select canonical backing，不读未验证对象；stale/corrupt = hide/reject 后 select canonical，「stale/corrupt object is not read; source oracle passes」；epoch update = 切换到 registered target，「old epoch does not leak into new source oracle」。预注册 6 行套件：MEnvData-SWE 的 python-attrs__attrs-586 / go-task__task-1814 / sindresorhus__type-fest-818 / CLIUtils__CLI11-926 / cobalt-org__liquid-rust-403 + SWE-Factory-Gym 的 pallets__click-2622（evaluation.md:233-240）。 | native + feature-equivalent FUSE 同 oracle | `make experiment-env-cache` = `@false` 占位（Makefile:59-62），无 runner/BPF/results。**先决条件（计划自写）：**「If the admitted oracle requires final-object target selection or synthetic directory aliases, those actions must be implemented and KVM-validated before this experiment can count as a paper result.」（plan B:149-150） | 最高 |

### RQ2 成本 vs feature-equivalent FUSE

| 编号 | 来源 | 目的 | oracle / 指标 | 基线臂 | 状态 | 优先级 |
|------|------|------|-------------|--------|------|--------|
| E3 | **[已计划]** plan A:140-144 | **功能等价 FUSE 对照。** 用 FUSE 实现一份功能等价的策略——同一棵源树、同一个状态机、同样的逻辑路径、同样的操作组合、通过同一套 oracle——作为延迟和开销对比的公平对照。 | lookup/open/stat/access/exec/readdir 逐操作延迟 + macro runtime（plan A:194-201）。 | namei_ext vs FUSE（同 oracle、同 source tree）。公平条款（逐字）：「If the FUSE row is incomplete, the RQ2 result is incomplete rather than a win for namei_ext.」 | FUSE runner 已 checked in（namei_ext_agent_workspace_fuse.c）；当前报出的 21x/13x 差距建立在最悲观 FUSE 配置上（fuse.c:1127-1128）。 | 最高 |
| E4 | **[我方补充]** | **三层 pass-through 开销对照（兼 RCU 问题）。** 回答审稿人第一问"挂上策略后，不使用视图的进程/路径要付多少额外开销"。 | 三臂同测一条路径（组件数、冷/热 dentry 缓存状态对齐），唯一变量是策略附着状态：**T0** 无附着（hook 编译进内核、全机零策略）；**T1** 旁观者（另一个 cgroup 挂了策略、被测进程的 cgroup 没挂）；**T2** 附着 pass_only（被测 cgroup 挂了一个只返回"放行"的策略）。**硬闸门：** T1 旁观者 p99 <= 1.05x，失守则内核侧需要把退出 RCU-walk 的条件从全局收紧为 per-cgroup。历史数字纳入正文：pass-only/native p99 旧 batch=64 协议 1.71x、ctx-init-split 1.095x、密尾采样最大 2.624x。 | T0 无附着 / T1 旁观者 / T2 pass_only | 旁观者开销从未单独测过；取决于 P1（RCU-safe PASS 可行性）的结果。 | 高 |
| E5 | **[我方补充]** | **FUSE 缓存配置矩阵。** 避免"只跟故意配到最慢的 FUSE 比"的质疑。 | 同一套 oracle 下三行并排：**coherent**（attr/entry/negative_timeout=0，即当前配置，唯一能满足世代切换立即可见）；**default**（libfuse 默认 1 秒 timeout，如实报告 oracle 在此配置下 fail——这本身就是一致性证据）；**FUSE passthrough**（内核 6.9+ 的新功能：让 FUSE 直接转发读写、绕过守护进程往返；若当前内核不支持则明确说明并降级）。同时把 libfuse2（FUSE_USE_VERSION 26）升级到 libfuse3。 | namei_ext vs FUSE-coherent / FUSE-default / FUSE-passthrough | 当前 21x/13x 数字建立在最悲观配置（fuse.c:1127-1128）。 | 高 |
| E6 | **[我方补充]** | **指标对称化。** 当前 FUSE 侧只测了 stat/readdir，而 FUSE 差距最小的 exec 恰好没在 FUSE 侧测过——补齐 open/access/exec/macro 的对称计时。 | 计划里 RQ2 指标本就包含 lookup/open/stat/access/exec/readdir 延迟 + macro runtime（plan A:194-201），在两侧都测齐即可。 | namei_ext 侧 vs FUSE 侧各操作逐一对称 | FUSE 侧缺 open/access/exec/macro 计时。 | 中 |
| E7 | **[我方补充]** 兼 M1 | **物化方案参照行。** overlay / bind 同 oracle 的校准行——测端到端宏观时间 + 视图构建/切换成本。 | 明文标注此行不是 RQ2 对照，用途是检查假设 H2 的证伪条件第二支：「or another mechanism is a stronger direct cost opponent」（idea-story.md:101）。 | overlay remount / bind mount / 同 oracle | 无代码、无数据；可与 M1/M2 复用同一批测量。 | 中 |

### RQ3 边界/安全

| 编号 | 来源 | 目的 | oracle / 指标 | 基线臂 | 状态 | 优先级 |
|------|------|------|-------------|--------|------|--------|
| E8 | **[已计划]** kvm.mk:294-296，但须改造 | **所有权与边界证据。** 证明 namei_ext 的所有权边界比自建/可叠加文件系统窄。 | 当前实现（kvm.mk:294-296）用内联 JSON（printf）写三条 boundary 行：namei_ext（owns_filesystem_methods:false, requires_daemon:false, policy_verified:true）、feature_equivalent_fuse（owns_filesystem_methods:true, requires_daemon:true）、custom_or_stackable_fs（owns_filesystem_methods:true）。其中 custom_or_stackable_fs 那行无任何代码执行支撑。**修法：** 换成有代码/构建支撑的真实所有权对照——例如实际统计各方案需要实现的文件系统方法数目、特权代码的代码面积、守护进程的责任范围。否则 artifact evaluation 阶段审稿人会发现这是手写主张。 | namei_ext / feature-equivalent FUSE / custom or stackable FS | printf 占位，无代码执行支撑。 | 高 |
| E9 | **[已计划]** kvm.mk:113-114；05-evaluation.tex:151-164 | **invalid-policy fail-closed。** 证明畸形/坏 target 决策被安全拒绝而不是放行。 | 已有用例 invalid_unregistered_target_contained =「unregistered target fails closed to ENOENT」（kvm.mk:113-114）。RQ3 表（05-evaluation.tex:151-164）承诺「invalid action, bad target, and malformed-name rejection on the real attach path」，当前全是 [Result] 占位。 | 无——这是单臂的安全属性验证 | 已有一条用例，其余占位。 | 高 |
| E10 | **[我方补充]** | **策略多样性 R1–R6。** 让"可编程"这一核心卖点有证据支撑，而不只靠单一策略。跑多个策略族，每族给出代码行数（LoC）、BPF map 规格、被替代的现成机制，证明同一个扩展点能表达多种路径视图策略。这也是扩展点类论文（如 cache_ext 等）的常规准入证据之一。 | 策略族数量 >= 3（各有不同的状态机结构）；每族的 LoC、map 规格、对应的现有替代方案 | native 机制（bind mount / overlay / symlink / LSM rule 等）各自对应的做法 | 无代码。 | 中 |

### 横切：统计与测量环境（适用所有 RQ2/RQ1 数字）

| 编号 | 来源 | 内容 | 当前状态 | 优先级 |
|------|------|------|---------|--------|
| E11 | **[我方补充，部分已被论文承诺]** | **统计口径与环境卫生。** 具体包括：**(1)** 预注册具体重复次数——微基准 >= 30 reps、宏基准 >= 20 reps（计划目前只写「repetitions and uncertainty」/「a Make variable committed before the full run」，未写死数字；plan A:201、plan B:189-191）。**(2)** 报 p50/p95/p99 + 95% bootstrap CI。**(3)** 显式 warmup。**(4)** 在磁盘文件系统（ext4）而非 KVM 的 tmpfs（内存盘）上产出至少一组数字——论文声称保留持久化所有权，至少要在持久化存储上验证一次。**(5)** 在 6.12+ 裸机上复测，不跨内核版本/虚拟化层画同一张图。论文已承诺 confidence intervals（05-evaluation.tex:113），但计划未写死 reps。 | reps 未写死；ext4 测量未做；裸机复测未做。 | 高——必须在全部数字产出前敲定 |

---

## 三、概念性 / PoC 实验（可能不进论文，但十分重要）

这些实验多数不会作为论文结果行出现，但它们决定"论文能不能投"或"某个主实验的前提条件成不成立"，应当优先做。

| 编号 | 来源 | 目的与问题 | 判定标准 | 当前状态 | 优先级 |
|------|------|-----------|---------|---------|--------|
| P1 | **[我方补充]** | **RCU-safe PASS 可行性——全项目的单点故障。** 问题：挂了策略之后，pass_only（只返回"放行"的策略）能不能留在 RCU-walk 无锁快路径里完成、不退到加锁的慢路径？尝试的方案：在目录项（dentry）上设一个标志位，没有标志位的路径组件永远不调 BPF 程序、只有返回 REDIRECT 的情况才退出快路径。 | 同一条路径 pass-only 对无策略的 p99 <= 1.1x。两轮旧 PoC（pass-only 1.48x / 1.38x）因 redirect 恶化到 2.49x / 2.43x 后撤回。dentry 标志位方案尚未尝试。 | 旧 PoC 撤回；新方案未实现。 | **最高——E4 能不能过闸门的前提** |
| P2 | **[我方补充]** 兼 E4 | **旁观者开销。** 问题：另一个 cgroup 挂了策略时，完全没挂策略的 cgroup 里的进程做 stat/lookup 会不会性能下降、下降多少？现有实现把策略挂在 cgroup 根（namei_ext_agent_workspace.c:725；mk/kvm.mk:292），旁观者开销从未单独测过。 | T1 旁观者 p99 <= 1.05x（与 E4 共用闸门值）。 | 从未测过。 | 高 |
| P3 | **[我方补充]** | **实验 B 的 symlink 判别性——决定 B 是否真的具有区分力。** 问题：写一个纯用户态的"标签管理器 + 原子 symlink 翻转"，看它能不能通过实验 B 的五态 oracle。理由：内容验证发生在策略之外，两种方案拿到的是同一份标签，如果 symlink 方案也能通过 → 实验 B 的 oracle 现有定义无法区分 namei_ext 和一行 symlink 命令，B 的 decisive 地位就不成立。那时必须补充一个判别条件，例如"多个 cgroup 在同一路径前缀下并行使用不同 epoch"。 | symlink 方案能否通过五态 oracle。若通过 → 必须加判别条件；若不通过 → B 的判别力得到确认。 | 未实现。 | **最高——最便宜的"救或杀实验 B"** |
| P4 | **[我方补充]** | **目标注册控制面刻画。** 问题：实验里用来做世代切换的那个 debugfs 注册接口（用户态写 debugfs 来重新注册 target）——它需要什么特权才能操作、运行时能不能被修改、并发和规模行为如何？产出一张表，把这个"特权注册面"的责任记进 namei_ext 自身的可信计算基（TCB，即"哪些代码/接口出了问题就整个安全保证都不成立"的最小集合）账上，补 RQ3 责任记账中目前缺失的一列（05-evaluation.tex:152-153）。 | 特权等级、运行时可变性、并发安全、规模行为的完整刻画表 | 未做。 | 中 |
| P5 | **[我方补充]** | **干净检出可复现性——artifact evaluation 的底线，也是防数据丢失。** 问题：从零 `git clone`（含 kernel submodule）能不能不做任何手工操作就重建全部实验？先决条件 = 把 07-13 起的内核侧 HIDE/SELECT_TARGET 实现提交进 kernel_nameiext 仓库并更新 gitlink（当前 gitlink 与 kernel_nameiext master 都停在 9f6695a，该 commit 的 fs/namei_ext.c 只有 PASS/REDIRECT）。这也是防丢失的紧急措施——唯一的代码副本在共用的 6787p 机器上，那台机器随时可能被重启。 | `git clone --recurse-submodules` + `make kvm-functional` 从零通过。 | gitlink 过期；内核侧新代码未入库。 | **最高——必须最先做** |
| P6 | **[我方补充]** | **多视图密度 sanity。** 问题：100 个 cgroup 各挂各的策略时，旁观者开销是否不随挂载策略的 cgroup 数量增长。作为 E4 的一个规模化检查点即可，不需要做成大实验（新故事线不再有密度主张）。 | 100-cgroup 配置下旁观者 p99 相对 1-cgroup 旁观者 p99 无显著增长。 | 未做。 | 低 |

---

## 四、排期建议（按依赖关系与性价比）

### 第一梯队：最先做（几分钟到一周，解锁其它实验的前提）

| 实验 | 理由 |
|------|------|
| **P5** 内核代码入库 + 干净检出可复现 | 紧急——防唯一副本丢失，也是所有后续实验能从零复现的前提。 |
| **P1** RCU-safe PASS 可行性 | 全项目的单点故障：如果 pass-only 留不住无锁快路径，所有延迟数字都不成立，E4 闸门过不了。 |
| **P3** symlink 判别性 | 最便宜的一步决策：如果 symlink 方案通过了五态 oracle，实验 B 必须补判别条件才能保住 decisive 地位；如果通不过，B 的地位得到确认。无论结果如何都节省后续返工。 |

### 第二梯队：一周内（纯搬运或低成本修缮）

| 实验 | 理由 |
|------|------|
| **M3** 具名工程代价案例 | 零研究成本——从 doc 24 搬运现成引用即可。 |
| **E8** 所有权边界行从 printf 改为真实代码/数据支撑 | 低成本修缮——当前 printf 写死的 JSON 在 artifact evaluation 里会被直接看穿。 |
| **E6** FUSE 侧指标对称化 | 补齐 open/access/exec/macro 计时，FUSE runner 已 checked in，工作量不大。 |
| **E11** 统计口径写死 | 必须在全部数字产出前敲定 reps（微基准 >= 30、宏基准 >= 20）、bootstrap CI 参数、warmup 协议。 |

### 第三梯队：二到四周（核心证据产出）

| 实验 | 依赖 |
|------|------|
| **E2** 实验 B 完整实现 | 需先 P1（确认 pass-only 延迟可接受）+ P3（确认 oracle 判别力）+ final-file SELECT_TARGET KVM-validated。 |
| **E4** 三臂 pass-through 开销测量 | 需先 P1。 |
| **E5** FUSE 缓存配置矩阵 | 需先 E3（FUSE runner 跑通同 oracle）。 |
| **E7** 物化方案参照行 | 可与 M1/M2 复用同一批测量。 |
| **E1** 实验 A 完整版补齐 | 原型已有，补 rename/unlink/cached-negative、bash/git command-sequence trace、per-op raw samples、uncertainty、macro runtime。 |
| **E10** 策略多样性 | 需要设计并实现多个策略族。 |
| **M1/M2** 动机定量测量 | 可与 E7 并行。 |

### 条件/备选（不投重点资源）

实验 C（Service/config 场景）仅当有具体的 source oracle 依赖查找时对象选择才达到准入门槛（evaluation.md:270-287），目前无计划、无代码，不投重点资源。
