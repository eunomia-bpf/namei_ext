## Current Effective Instructions (2026-07-24)

- Treat `namei_ext` as a `sched_ext`-style VFS name-resolution extension
  point positioned between eBPF LSM and FUSE/custom filesystem ownership. The
  central contribution is the design plus Linux implementation of this systems
  boundary, not a table mechanism or a BPF filesystem.
- The strongest story is positive and systems-facing: many real workloads need
  programmable path views while preserving lower-filesystem semantics. Do not
  shrink the hypothesis around incomplete prototype evidence unless a valid
  final result makes the hypothesis impossible.
- RQ1 asks whether the narrow name-resolution boundary is expressive/sufficient
  for real source-derived path-view policies. RQ2 compares cost and overhead
  against feature-equivalent FUSE. RQ3 compares safety and ownership boundary
  against custom or stackable filesystems; bind, Overlay, projected volumes,
  copy/symlink/materialized views are background or cited mechanisms unless a
  selected source oracle makes one load-bearing.
- Stop making table-only insufficiency the main novelty line. Static table,
  table redirect, materialized namespace, and other non-programmable mechanisms
  may remain archived diagnostics or background, but they should not drive the
  main experiment plan.
- Experiments must be complete integrated matrices, not scattered smoke tests
  or a long list of weak baselines. Prefer one strong same-oracle comparison:
  feature-equivalent FUSE for RQ2, native/source behavior as oracle/control,
  and custom/stackable filesystem ownership evidence for RQ3.
- Search experiment directions breadth-first before deepening one path: run a
  bounded set of small real probes across plausible high-value branches, then
  promote the strongest branch to release-scale evidence. Do not spend a full
  run budget polishing one candidate before adjacent candidates have been
  checked.
- Current primary workload families are Agent workspace lifecycle and
  traditional build/cache. Service/config rotation and checkpoint/restart path
  remapping are conditional breadth workloads only after a concrete source
  oracle is admitted.
- For build/cache, use traditional Redis/nginx/ccache-style workloads and make
  the exact covered cache state explicit. If a release run covers only
  verified hot-cache hits, say that; stale, corrupt, miss, and epoch-switch rows
  require their own real same-oracle cells before becoming claims.
- For LPC/upstream-facing work, prioritize a practical use case, a runnable
  Make/KVM command, raw results, dmesg/kernel provenance, and a small boundary
  argument that explains why this belongs at VFS name resolution rather than in
  eBPF LSM or a userspace/full filesystem daemon.
- Do not edit the current skills. Use them only when they materially help the
  requested phase; do not let skill-driven process replace the user's latest
  scientific direction or add unnecessary constraints.

你觉得这个论文的 idea 和 novelty 是什么? 合适吗? 有价值吗

多类真实 workload 需要 eBPF policy logic, 现有的扩展文件系统的方案要么不安全, 要么不 expressive, 要么性能不好. 我们尝试找到一个平衡点. A general programmable filesystem abstraction 是这样的. 接下来实验应该怎么做?

先做 C8 killer experiment：table-only 到底够不够
这是 novelty 的核心。每个 workload 都要和 table_redirect.bpf.c 做 feature-equivalent 对照：
static exact table
externally-updated exact table
namei_ext eBPF policy
FUSE policy implementation
materialized view: copy/symlink/bind/projected/Overlay where applicable
成功标准不能只是“eBPF 能跑”。必须证明 table-only 在真实动态条件下至少一个失败：
correctness oracle fail
table/update writes 超预算
stale window 超预算
operation-weighted policy branch 不能被静态 table 表达
同等 correctness 下 setup/update/materialization 明显更差 . 先做 C8 killer experiment：table-only 到底够不够
这是 novelty 的核心。每个 workload 都要和 table_redirect.bpf.c 做 feature-equivalent 对照：
static exact table
externally-updated exact table
namei_ext eBPF policy
FUSE policy implementation
materialized view: copy/symlink/bind/projected/Overlay where applicable
成功标准不能只是“eBPF 能跑”。必须证明 table-only 在真实动态条件下至少一个失败：
correctness oracle fail
table/update writes 超预算
stale window 超预算
operation-weighted policy branch 不能被静态 table 表达
同等 correctness 下 setup/update/materialization 明显更差

把 W4 cache locality 作为最强 novelty workload
W4 最像“需要 policy logic”的场景。实验应该触发真实动态分支：
hit -> local verified cache
miss -> canonical backing
stale -> reject local / fallback
corrupt -> reject local / fallback
update epoch changes backing choice
用真实 ccache 或 BuildKit trace，报告 operation-weighted branch hit rate。关键 oracle 是 output hash、stale/corrupt reject、cache state transition、compile success。若 table-only 在同等 update budget 下也过，这个 claim 就要降级。  我们有做足够的 litrature survey 吗? 这些问题是不是不需要我们自己做实验回答? 你能不能补充一下? 比如说别人什么场景用 fuse, 什么场景自己造了文件系统? 如果别人造了那我不需要自己验证一遍吧.

不是不是. 你得看看别人为啥要用 fuse / 自己写 fs? 为啥 redirect table 不够> 没去调研过?

看看 deltafs/yolofs?

你刚刚调研到的相关论文能不能下载下来? 放到 docs/reference 里面. 不能替我们证明 table_redirect.bpf.c 对 W4/W3 不够啥意思? 那你去实验回答一下, 设计一些专门针对性的实验, 你想想怎样针对性实验回答 table-only 不够? 要用 skills, 让 osdi 审稿人信服. 先做 C8 killer experiment：table-only 到底够不够
这是 novelty 的核心。每个 workload 都要和 table_redirect.bpf.c 做 feature-equivalent 对照：
static exact table
externally-updated exact table
namei_ext eBPF policy
FUSE policy implementation
materialized view: copy/symlink/bind/projected/Overlay where applicable
成功标准不能只是“eBPF 能跑”。必须证明 table-only 在真实动态条件下至少一个失败：
correctness oracle fail
table/update writes 超预算
stale window 超预算
operation-weighted policy branch 不能被静态 table 表达
同等 correctness 下 setup/update/materialization 明显更差 . 先做 C8 killer experiment：table-only 到底够不够
这是 novelty 的核心。每个 workload 都要和 table_redirect.bpf.c 做 feature-equivalent 对照：
static exact table
externally-updated exact table
namei_ext eBPF policy
FUSE policy implementation
materialized view: copy/symlink/bind/projected/Overlay where applicable
成功标准不能只是“eBPF 能跑”。必须证明 table-only 在真实动态条件下至少一个失败：
correctness oracle fail
table/update writes 超预算
stale window 超预算
operation-weighted policy branch 不能被静态 table 表达
同等 correctness 下 setup/update/materialization 明显更差
去写一些非常明显动态的, 证明 table 做不了的, 也再去下载一些别的 paper, 最后更新文档.

现在情况如何?

系欸下来应该怎么做? 我们做了啥?

我没懂你在说什么

我们是不是不要再纠结 table 了? 你看别人的 usecase 也没用 table 啊? 文档都更新了吗? 我们能不能挑一些正式 workload, 反正我们挑的 workload 都是真实 workload 都用不了 table 的? 去挑, 根据这些论文去挑, 然后更新文档, 确保我们已经证明我们这里提及的所有真实 workload 都必须用 eBPF policy logic。

我们是不是不要再纠结 table 了? 你看别人的 usecase 也没用 table 啊? 文档都更新了吗? 我们能不能挑一些正式 workload, 反正我们挑的 workload 都是真实 workload 都用不了 table 的? 去挑, 根据这些论文去挑, 然后更新文档, 确保我们已经证明我们这里提及的所有真实 workload 都必须用 eBPF policy logic。按照这个写清楚，文档都更新，不要再折腾不是可编程接口的方法了。你看看有什么 paper 有 代码可以复现，用来实现我们的 usecase？去搜索分析一下？包括 ai agent 相关的。

别的没法复现？能复现什么？

适合证明 per-agent workspace setup/update 不是静态 table 问题 严格记住别再证明这个玩意了，没有意义，记录到更多文档里面去，把误导的都删掉

证明这些 workload 需要动态、状态相关的 name-resolution polic 也没必要证明，删掉？

你仔细想想需要证明什么？

我觉得这些得再看看，你提出来的基本上无意义

DeltaFS YoloFS 你确定没法实现一个？也搜索不到？再去仔细看看？AgentFS也需要看看？DeltaFS / IndexFS / TableFS 这些用了啥 workload？

都去研究并且复现，然后写一个复现报告，看看怎么用起来？

哪些能被复用? 分析一下? 我们的 idea 是什么?

文档要按照 skills 要求的布局去收敛

代码要 commit push, 文档和 pdf 也需要 commit push. 要整理成我们想要的形态, 而不是现在这个和我们 research skills 里面定义的不一样的

进度如何? 讲解一下?

[$iter-refine-writing-idea](/home/yunwei37/workspace/my-paper-work/academic-writing-skills/skills/iter-refine-writing-idea/SKILL.md) 

[$iter-refine-writing-idea](/home/yunwei37/workspace/my-paper-work/academic-writing-skills/skills/iter-refine-writing-idea/SKILL.md) 

[$iter-refine-writing](/home/yunwei37/workspace/my-paper-work/academic-writing-skills/skills/iter-refine-writing/SKILL.md) 这个也要跑, 交替完整的流程

这个的 idea 是不是也被整的越来越小越来越不 interesting 了?为啥会发生这种事情? 分析这个 repo 里面的完整执行轨迹? 看看具体是什么带来的问题; 也要看看文档和不必要的约束

别改当前 skills

现在的故事是啥? 进度如何了? RQ 是啥? 完整的故事, contribution, 设计, 实现, 实验是啥

现在的故事是啥? 进度如何了? RQ 是啥? 完整的故事, contribution, 设计, 实现, 实验是啥? OSDI/systedm 会议需要的 RQ 是这些吗? 我们的 contribution 应该长这样? 乱七八糟的

这个 skills 是不是不应该任何时候都触发

现在的故事是啥? 进度如何了? RQ 是啥? 完整的故事, contribution, 设计, 实现, 实验是啥? OSDI/systedm 会议需要的 RQ 是这些吗? 我们的 contribution 应该长这样? 乱七八糟的

contribution 对, 就是 design/impl 合起来. 但是 RQ 还是不对

**RQ1: Expressiveness / Sufficiency**
Can a narrow VFS name-resolution extension express real state-dependent path-view policies without taking over filesystem semantics?  **RQ2: Cost / Overhead**
What is the cost of putting programmable policy on the VFS name-resolution path  RQ3 不应该是对比 custom fs 安全吗? 为什么不是 bind/Overlay/projected/copy/symlink 不应该是 cite 别人的 paper 吗? 记录user insn

RQ2 对比 FUSE

我们现在的文档和数据和论文是不是都要这样组织? 把误导性的清理干净, 让 subagent review 直到不会出现类似的问题/

论文也不应该放负面结果, 故事越吸引人越好, 我们应该根据 hyposis 改实验尝试能不能证明, 而不是根据实验目前的设计问题修改 hyposis / claim, 除非这个 hyposis 本身完全不可能成立, 不然不应该改变 我们的 hyposis

你现在 experiment 设计 skill 有没有要求你注意 baseline? 我们现在有没有倾向说是说了好多个零碎的实验, 有许多 baseline, 但这些baseline 本身没有意义? 比如说已经被人证明过了, 或者过于零碎弱小? 或者么有跑完完整实验, 不停换 baseline? 你是不是要避免这个问题?

故事要变得更强更吸引人

你的user insn?

namei_ext 是一个 sched_ext-style VFS extension point，位于bind/Overlay/materialization < eBPF LSM <  namei_ext  < FUSE/custom FS 之间

你需要分析一下我们过去完整的这个 repo 里面的用户指令和对话, 重要的加进 user insn, 能从你的聊天记录看出来吗

对比一下之前的故事, 有没有出现漂移?

按照新的 skills 重新回到 BOOTSTRAP 阶段

你需要分析一下我们过去完整的这个 repo 里面的用户指令和对话, 重要的加进 user insn. 现在实验设计, 系统设计都整理好了吗? 符合 OSDI/SOSP 的要求吗? 继续做? 实验不要零散的实验, 要是完整的实验.

论文重新整理了吗

按照新的 skills 重新回到 BOOTSTRAP 阶段, 重新整理完善论文

继续, 去把我要求的 RQ1 RQ2 RQ3 改进做一下, 至少到 ebpf workshop accept 的水评
