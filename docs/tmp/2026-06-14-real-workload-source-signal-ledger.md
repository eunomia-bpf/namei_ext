# 真实 workload 来源和性能信号台账

> 2026-06-29 baseline scope update: this note preserves historical reasoning and results, but older C8/B12 baseline-gate wording is superseded by `docs/tmp/2026-06-29-redirect-table-novelty-position.md`. Current evaluation uses claim-driven, workload-appropriate baselines. Exact-map diagnostics are optional and only relevant when precomputed mapping is the competing claim.

日期：2026-06-14
阶段：Phase 1 文档补强
类型：研究记录

## 动机

OSDI 级评估不能只证明一个小型 redirect demo 能运行。论文主张是一个通用
programmable path-resolution abstraction 可以承载多类 extension，因此 workload 必须来自
真实应用、真实部署机制或真实系统文档，并且每个 workload 都要说明它放大的性能信号、
正确性 oracle 和不能进入 C1/C8 的剩余 blocker。

本记录把分散在 `docs/experiment-plans/osdi-evaluation.md`、`docs/paper/` 和
`workload/<workload-id>/evidence.md` 中的依据整理成一个 source-to-signal ledger。
该 ledger 不引入新的性能数字；没有 raw result 的数字仍然不能写进论文主张。

## 检查过的文件

- `docs/experiment-plans/osdi-evaluation.md`
- `docs/paper/sections/01-introduction.tex`
- `docs/paper/sections/02-motivation.tex`
- `docs/paper/sections/05-evaluation.tex`
- `docs/paper/refs.bib`
- `workload/*/evidence.md`
- 最新完整 Phase 1 summary：
  `results/phase1/20260614T-w2-nginx-probes-phase1/summary.md`

## 外部来源基线

当前四类 policy family 依赖的外部依据必须来自官方文档、项目文档或论文：

| Policy family | 外部依据类型 | 真实问题 |
|---------------|--------------|----------|
| build graph | Bazel sandbox/hermeticity 文档、Redis/nginx 源码和构建文档 | action 只能看到声明输入、生成输出、工具链和依赖；未声明输入会破坏 reproducibility/cache correctness。 |
| sandbox fixture | Kubernetes projected volume/Secret 文档、Docker Compose secret/config 文档、nginx/PostgreSQL 配置文档 | 服务在测试、staging 和 CI 中经常把 config、secret、certificate 和 endpoint 作为文件替换。 |
| checkpoint/restore | Podman/CRIU checkpoint/restore 文档、外部 bind mount/path virtualization 文献、Redis/nginx 服务状态 | restore 后进程需要把 checkpointed state/config/cache 和 runtime-local socket/pid/log/temp path 重新连接。 |
| cache locality | ccache、Docker BuildKit、Bazel remote cache、Nix content-addressed store、Prometheus Go module graph | 构建缓存需要根据 content/state 在 local cache、remote/cache store 和 canonical backing 间选择，且 stale/corrupt 不能被使用。 |

## Workload 到性能信号映射

| Workload | 当前来源状态 | 放大的性能信号 | 当前 raw evidence | Release blocker |
|----------|--------------|----------------|-------------------|-----------------|
| `w1-redis-build` / `w1-nginx-build` | 固定 Redis `7.2.14` 与 nginx `1.26.3` source build；host strace 已记录真实 file operations。 | execroot/action view setup 成本、copy/symlink/mount materialization 成本、metadata `openat/statx/access/getdents64` p99、generated/source/toolchain/deps precedence。 | `results/workloads/runs/20260614T-workloads-git-ceiling/` 和 `results/phase1/20260614T-workloads-git-ceiling/w1-oracle.jsonl`。 | 仍缺完整 build output hash、trace-derived full alias set、undeclared poison/negative real hit、operation-weighted redirected hit rate 和 table/update budget counterfactual。 |
| `w2-nginx-fixture` / `w2-postgres-secret-fixture` | 固定 nginx/PostgreSQL provenance 和 workload-owned fixture；W2 nginx 已有真实 nginx endpoint health + fixture content probes。 | 服务 fixture setup、path-class dispatch、config/endpoint/secret/cert/poison branch coverage、startup/reload metadata p99、no-real-secret oracle。 | `results/phase1/20260614T-w2-nginx-probes-phase1/w2-nginx-real.jsonl` 和 `w2-oracle.jsonl`。 | 仍缺 PostgreSQL real app oracle、nginx trace-level no-real-open checker、release-level endpoint matrix、startup trace、operation-weighted hit rate 和 table/update budget counterfactual。 |
| `w3-redis-podman-criu` / `w3-nginx-podman-criu` | 固定 Redis/nginx provenance 绑定 checkpoint witness；Podman/CRIU 是发布级目标，当前未执行真实 restore。 | restore session switch 成本、post-restore fresh lookup/readdir、runtime-local socket/pid/log/temp remap、mixed-epoch reject。 | `results/phase1/20260614T-workloads-git-ceiling/w3-oracle.jsonl`。 | 仍缺真实 Podman/CRIU checkpoint archive、restore health、post-restore VFS trace、state/config/cache hash、0 mixed epoch oracle 和 table/update budget counterfactual。 |
| `w4-ccache-redis-nginx` / `w4-buildkit-prometheus-go-cache` | 固定 Redis/nginx/Prometheus provenance 绑定 cache witness；W4 已有 map-backed cache content oracle。 | cache view setup/update、verified-hit/stale-fallback/corrupt-reject/miss-canonical branch coverage、stale window、update writes、metadata p99。 | `results/phase1/20260614T-w2-nginx-probes-phase1/w4-cache-content.jsonl` 和 `w4-oracle.jsonl`。 | 仍缺真实 ccache/BuildKit run、compiler/go output hash、cache transition trace、operation-weighted hit rate、stale window/update writes 和 table/update budget counterfactual。 |

## 设计结论

1. 四类 policy 不能被写成“同一 redirect resolver 的四个实例”。每类必须在文档和
   raw result 中暴露不同的算法路径：precedence cascade、path-class dispatch、
   restore epoch consistency、content-state dispatch。
2. `table_redirect.bpf.c` 是强 baseline。只要它在同等 table/update budget 下通过某个
   release-level family，该 family 就不能计入 C8。
3. `functional_only` 证据可以证明 Phase 1 KVM attach/path oracle 能跑通，但不能支撑
   “需要 eBPF 可编程抽象”或“OSDI 级性能”结论。
4. Workload 目录是证据归属边界。每个 `workload/<id>/` 必须保留启动配置、fixture、
   manifest 生成说明和 raw result path；`docs/tmp/` 只保存 Markdown 研究/实现记录。

## 剩余风险

- 当前 W1/W3/W4 的真实应用部分仍主要是 provenance-bound witness，不是完整 app output
  oracle。
- W2 nginx 是当前最接近真实应用的 gate，但 direct cert/secret/poison probes 不是
  nginx worker trace-level no-real-open checker。
- W3 只有在真实 Podman/CRIU restore 后触发新的 VFS lookup/readdir 时，才可以作为
  `namei_ext` 的 restore 证据；CRIU 已恢复的 fd/mmap/socket 不能计入 path-resolution hit。
- W4 的 cache correctness 不能归功于 `namei_ext`。论文只能主张 per-workload path view
  setup/update、低 stale window 和 table-only 反事实，不能声称重新实现 ccache/BuildKit。

## 本次文档更新

- 在论文引言中把当前 artifact 进度从 W1-only 更新为 W1/W2/W3/W4 evidence-level 叙述。
- 在动机章节增加 workload 选择准则，明确真实来源和性能信号是 workload 入选门槛。
- 在 evaluation section 增加 source-to-signal 表，集中记录真实来源、性能信号、当前证据
  和 release blocker。
- 在 OSDI evaluation plan 中增加同样的 source-to-signal ledger，使 paper 和 plan 使用同一套
  降级规则。
