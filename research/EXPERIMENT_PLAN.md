# 实验计划：namei_ext

## 2026-06-18 scoped-paper update

当前 paper thesis 必须收窄为：`namei_ext` 在修改内核 KVM 中展示一个窄 VFS path-resolution eBPF extension point；现有正结果只覆盖 W2 nginx sandbox fixture 的 setup/materialization slice、tool-redirect lookup/access/open/exec metadata latency slice，以及声明 W1-W4 Phase 1 lookup/readdir oracle matrix。FUSE 是当前最重要的 feature-equivalent programmable baseline；native/no-hook 是 overhead reference，不是功能等价竞争者。

Sandbox fixture 当前状态：W2 nginx fixture 已有 real trace、no-production-open gate、五类 baseline 和 thresholded C2 ledger，可以作为主稿局部正结果。下一步若要升级到更强 OSDI result，应扩展到 trace-level cert/secret/poison coverage、endpoint matrix、reload/update trace、PostgreSQL secret fixture、operation-weighted redirected hit rate 和 claim-driven baseline gate。

Checkpoint/restore 当前状态：W3 Redis 现在只有 RDB load/replay 和 checkpoint-view macrobench，不是 Podman/CRIU restore。W3 已有 materialized 和 FUSE checkpoint-view baselines，但 setup/update thresholds 失败。下一步若要把 W3 写成 release result，必须先让 `make workload-w3-podman-criu-capability` 通过，再做真实 Redis 或 nginx Podman/CRIU restore、post-restore VFS trace、0 mixed epoch oracle、restore health oracle 和 feature-equivalent baselines。

若重构为更强 OSDI 叙事，顶层 use case 应收敛为三个：agent sandbox lifecycle、service fixture sandbox 和 content-verified cache view。agent sandbox lifecycle 内部可以包含 fork/fanout、checkpoint rollback/restore 和 deterministic trace replay，但不包含 eval isolation；eval isolation 会引入额外的安全/benchmark-harness 主张，不是当前证据需要证明的内容。W1 build graph 应折叠进 agent sandbox trace replay 或降为附录/负结果；当前 W3 Redis replay 不能作为主线 restore，除非重做成真实 sandbox checkpoint/rollback 或 Podman/CRIU restore workflow。

Last updated: 2026-06-16
Stage at update: experiment-design/execute
Source/command: summarized from `docs/experiment-plans/osdi-evaluation.md`
Completeness: partial

## 待验证 Thesis

待验证 thesis：`namei_ext` 在 Linux VFS path-resolution hot path 中提供一个窄 eBPF decision hook，使真实读多写少的 build、fixture、checkpoint/restore 和 cache locality workloads 能以低于 FUSE 或物化目录视图的成本表达可编程路径解析，同时保持 lower filesystem 语义由内核拥有。

## Paper Type

- Type：new system / kernel extension point / systems artifact。
- Target venue：OSDI/SOSP 级 systems venue。
- Artifact status：prototype in modified kernel + KVM validation + Docker packaging。
- Main reviewer risk：当前 release gates 失败。C2/C3/C5 已有 batch=64 的 20-sample KVM microbench、tail/CI、随机化顺序、系统指标和五个 external baseline release rows，B2/B8 `input_gate_pass=true`。RCU-pass fastpath 两轮 PoC 均被负结果拒绝；ctx 初始化拆分提供部分 residual attribution；tail10 diagnostic 让 `fuse_speedup_threshold_pass=true`，但 `kernel_p99_threshold_pass=false`、`pass_only_threshold_pass=false` 仍失败。C2 已有 W2 proposed-system 与 copy/symlink/bind/projected-volume/FUSE baseline release inputs，且 W2 storage/threshold slice 已通过；W1 已有 20-sample proposed-system release input 和 copy/symlink/bind/projected-volume/FUSE baseline release input，但 W1 ledger 为负。W3 已有 20-sample proposed-system release input、materialized checkpoint-view baseline 和 FUSE checkpoint-view baseline，但 W3 ledger 为负。W4 已有 parent-rule/materialized release input、bulk materialized baseline、bulk FUSE cache-view baseline、bulk policy-attached compile smoke witness 和 bulk policy setup/update release input；v6 bulk ledger 仍为负，因为 update latency 输给 best external baseline，且仍缺更强 cache/native/BuildKit/complete-FUSE 对照。全局 C2 需要把 W1/W3/W4 负结果写清或收窄。C8 仍缺真实 workload oracle 和 claim-driven baseline evidence。

## Claim-To-Experiment Map

| Claim | Required evidence | Primary block | Falsifying result | Supported wording if partial |
|---|---|---|---|---|
| C1 | 四类 policy family 的真实 workload 通过 release oracle | B1, B3-B6, B12 | 真实 workload 不命中 policy 或更简单自然替代机制同等通过 | “可表达已测 policy prototypes”，不能说通用抽象。 |
| C2 | setup/storage/update 成本优于物化 baseline | B3-B6 | copy/symlink/bind/projected-volume/FUSE 在成本内同等通过 | “避免部分物化成本”，不能说整体更优。 |
| C3 | p50/p95/p99、CPU、CI 优于 FUSE 或接近 kernel baselines | B2-B6 | FUSE/symlink/bind 更快或差异无统计意义 | “功能路径可运行”，不能写性能优势。 |
| C4 | lookup/readdir/access/exec consistency checker 通过 | B1, B7 | lookup/readdir 可见集合不一致 | 缩小为 lookup-only 或删除 readdir claim。 |
| C5 | ablation 证明 VFS placement 解释收益 | B8 | pass-only/table/FUSE/materialization 消融不能解释差异 | 删除机制归因，改成实现观察。 |
| C6 | scale/failure/stress matrix 通过 | B9, B10 | dmesg warning、fail-open、unsupported path 静默成功 | 缩小支持范围。 |
| C7 | clean Make/KVM/Docker artifact 复现 | B11 | dirty tree、缺输入 hash、手工步骤 | 只作为 prototype artifact。 |
| C8 | dynamic policy 相比 workload-appropriate baseline 有必要且收益明确 | B8, B12 | 更简单自然替代机制在预算内通过主要 oracle | 删除“需要可编程性”主张。 |

## System-Under-Test Model

- Components：VFS name resolution hook、`cgroup/namei_ext` BPF attach、policy maps、BPF policies、KVM guest runners、Make/Docker orchestration。
- Durable state：lower filesystem objects、BPF maps、result roots、workload provenance manifests。
- Trust/failure boundaries：内核拥有 dentry/inode/file semantics；policy 只返回受限 decision；unsupported capability 必须 fail-fast。
- Guarantees：只声明已实现的 lookup/readdir PASS/REDIRECT 一致性和 attach-scoped behavior。
- Workloads：Redis/nginx build graph；nginx/PostgreSQL fixture; Redis/nginx Podman/CRIU target；ccache/Prometheus BuildKit cache target。
- Observability：JSONL rows、stdout/stderr、dmesg、input/output sha256、kernel/Docker identity、policy verifier/load result。
- Assumptions：release claims 只可由完整 KVM roots 和 release eval ledgers 支撑。

## Experiment Matrix

| Block | Claim | Experiment | Baselines/variants | Metric(s) | Oracle | Figure/table | Priority |
|---|---|---|---|---|---|---|---|
| B1 | C1,C4 | path semantics correctness | namei_ext policies、table_redirect | pass/fail、errno、content hash | lookup/readdir/access/exec checker | 表 1 | must |
| B2 | C3 | microbenchmark cost split | native、pass-only、table-hit、policy、FUSE、copy、symlink、bind、OverlayFS | p50/p95/p99、CPU、ctx switches、CI | 0 semantic failure + stats artifact | 图 1 | must |
| B3 | C1-C3 | build graph macrobench | copy、symlink、bind、FUSE、namei_ext | setup、build wall time、disk writes、metadata p99 | output hash + poison/negative checker | 图 2 | must |
| B4 | C1-C3 | sandbox fixture macrobench | projected-volume、bind、symlink、FUSE、namei_ext | setup、startup、memory、metadata p99 | health + no-real-secret checker | 图 3 | must |
| B5 | C1-C3 | checkpoint/restore macrobench | podman-criu materialization、copy、bind、FUSE、namei_ext | restore setup、health latency、stale window | restore health + 0 mixed epoch checker | 图 4 | must |
| B6 | C1-C3 | cache locality macrobench | native cache tool、copy、bind、FUSE、optional exact-map diagnostic、namei_ext | hit/miss/stale latency、storage、update writes | content hash + stale/corrupt checker | 图 5 | must |
| B7 | C4 | directory view consistency | static mapping、epoch if implemented | checker failures、stale/mixed views | lookup-set equals readdir-set | 表 2 | must |
| B8 | C5,C8 | mechanism ablation | no hook、pass-only、optional exact-map diagnostic、FUSE、symlink、best simple baseline | overhead deltas、failed properties | ablation-specific oracle | 图 6 | must |
| B9 | C6 | scale/stress | alias fanout、path depth、cgroups、hot/cold cache | p99、memory、CPU、failures | no silent wrong result | 图 7 | must |
| B10 | C6 | failure semantics | invalid redirect、verifier failure、detach/reload、migration | errno、dmesg、status | fail-fast、no panic/oops | 表 3 | must |
| B11 | C7 | reproducibility | clean checkout、Docker、KVM | exit status、manifest completeness | Make exit 0 + report gates | artifact appendix | must |
| B12 | C1,C8 | policy family programmability | four policy families、claim-driven baselines、optional exact-map diagnostic | oracle pass/fail、algorithm path、map stats、p99 | usecase oracle + workload-appropriate baseline | 图 8 / 表 4 | must |

## Run Order

| Run ID | Stage | Purpose | Config | Seed/reps | Decision gate | Cost | Risk |
|---|---|---|---|---|---|---|---|
| R001 | sanity | Phase 1 KVM smoke closure | `make phase1 RUN_ID=<id>` | `SAMPLES=1` | summary gates pass | high | dirty tree/pilot only |
| R020 | baseline | release microbench raw distribution | `make kvm-bench RUN_ID=<id> SAMPLES=20 BENCH_LATENCY_SAMPLES=1 BENCH_LATENCY_BATCH=64 BENCH_RANDOMIZE_ORDER=1` | at least 20 reps | raw latency rows complete and `min_ops_per_latency_row>=64` | medium | completed as R032 |
| R030 | baseline | external baseline build and correctness | `make eval-osdi-baselines RUN_ID=<id> BASELINE_SAMPLES=20 BASELINE_LATENCY_SAMPLES=1 BASELINE_LATENCY_BATCH=64` | 5 release baselines, at least 20 reps | all baseline oracles pass and `min_ops_per_latency_row>=64` | high | completed as R033 |
| R045-R049 | main | ctx 初始化拆分 B2 remediation attempt | `make kernel`; `make kvm-bench ...ctx-init-split...`; `make eval-osdi-baselines ...ctx-init-split...`; `make eval-osdi-performance-comparison ...ctx-init-split...`; hard gate | 20 reps, randomized, latency batch 64 | `pass_only_threshold_pass=true` but C3 thresholds still fail | high | completed; mixed result, not C3/C5-supported |
| R050-R053 | decision | tail sample-density diagnostic | `BENCH_LATENCY_SAMPLES=10` and `BASELINE_LATENCY_SAMPLES=10` comparison + hard gate | 20 reps, 10 latency rows/sample | `fuse_speedup_threshold_pass=true`, but kernel/pass-only thresholds fail | medium | completed; FUSE blocker gone, pass-only/readdir/tree-walk residual remains |
| R060 | decision | B12 family qualification | `make eval-osdi-policy-family` | per family release rows | `qualified_families>=4` | high | currently 0 |
| R070 | paper | paper logic review after claim verdict | `make -C docs/paper check paper` + subagent review | n/a | no must-fix evidence gaps | low | premature until gates pass |

## Tracker Handoff

- Update path：`research/EXPERIMENT_TRACKER.md`。
- Result path convention：`results/phase1/<run-id>/` 和 `results/eval-osdi/paper/<run-id>/`。
- Required tracker columns：Run ID、Claim、Block、Purpose、Command/config、Commit、Machine、Seed/reps、Oracle、Decision gate、Result path、Status。
- Next rows to add：R097 W4 stronger cache/native/BuildKit/complete-FUSE comparison or C2 scope narrowing、R098 B12 policy-family qualification、以及 no-hook/static-key-off 或 per-variant CPU/context-switch/fault diagnostic rows。

## Baseline Fairness

- Named baselines：native/no-hook、pass-only、table-redirect-hit、FUSE redirectfs、copy tree、symlink forest、bind mount、OverlayFS、projected-volume where applicable。
- Tuning policy：每个 baseline 使用 feature-equivalent checker；unsupported operation 是 hard failure，不可静默跳过。
- What each baseline proves：FUSE 证明 user-space programmable remap 代价；copy/symlink/bind/OverlayFS 证明物化或现有 kernel path 能否同等表达；exact-map diagnostic 只在预计算映射是相关替代方案时使用。
- Omitted baselines：当前没有可接受 omission；若某 baseline 不可表达某 use case，必须输出 raw failure row。

## Reproducibility

- Hardware/software versions：记录在 Phase 1 metadata、kernel config、Docker image id 和 host CPU 文件中。
- Seeds/repetitions：release target 必须记录至少 20 次 repetitions 和 randomized order。
- Workload generation：必须来自 `workload/` 子目录和 `configs/eval-osdi/workload-sources.mk` pinned inputs。
- Data/traces：raw JSONL、logs、strace、dmesg、sha256 manifests 保存在 `results/`。
- Scripts/configs：项目控制面只能是 Makefile 和 committed configs，不新增 shell scripts。
- Result file paths：所有 paper 数字必须从 `results/` 或 analysis target 生成。

## Residual Uncertainty

- 当前有 batch=64 的 20-sample KVM microbench root、五个 external baseline release rows 和 B2/B8 head-to-head release threshold verdict；tail10 diagnostic 后 input gate 与 FUSE speedup threshold 已通过，但 kernel p99/pass-only residual 阈值失败，没有统一的 full `make phase1` release root，也没有 paper-number audit。
- 当前已尝试并拒绝 RCU-pass fastpath：两个 PoC 均能通过 KVM input gate，但最差 policy/native p99 从原始 1.77x 恶化到 2.49x 或 2.43x；后续优化不能再把该路径当作未验证假设。
- 当前 ctx 初始化拆分 PoC 是混合结果：1-sample batch64 中 max pass-only/native p99 降到 1.095x，但 tail10 diagnostic 说明该结论不够稳健，pass-only/native worst case 为 2.62x。
- 当前 tail10 diagnostic 说明 `exec_tool_redirect`/FUSE speedup 不再是主要 blocker；`readdir_alias_view`、`build_tree_stat_walk` 和 pass-only tail residual 是下一步焦点。
- 当前 W1-W4 都已有至少一个 release setup/storage/update baseline comparison 路径，但只有 W2 storage/threshold slice 为正。W1 已有 proposed-system 和 copy/symlink/bind/projected-volume/FUSE baseline release input，但 W1 ledger 为负；W3 已有 proposed-system、materialized checkpoint-view 和 FUSE checkpoint-view baseline release input，但 W3 ledger 为负；W4 已有 parent-rule/materialized release comparison、bulk materialized baseline、bulk FUSE cache-view baseline、bulk policy-attached compile smoke witness 和 bulk policy setup/update release input，但 v6 bulk comparison 仍失败，且仍缺 cache-remap/native ccache/BuildKit 或完整 compile-through-FUSE baseline。
- 当前 B12 exact-map diagnostics 多处为负/边界证据，尤其 W4 sampled ccache comparator 通过。
- 当前 W3 还没有真实 Podman/CRIU restore，W4 Prometheus/BuildKit 还没有真实 Go cache run。
- 当前 paper 可以作为 claim/evidence contract，但不能作为 submission-ready paper。

## Claim Gate After Results

正式 verdict 见 `research/CLAIM_VERDICT.md`。当前 verdict 不允许强化 abstract、intro 或 conclusion 中的性能和 programmability 主张。
