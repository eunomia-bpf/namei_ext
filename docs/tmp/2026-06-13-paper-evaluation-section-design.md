# 研究记录：论文形态 Evaluation Section 和真实 Workload 选择

日期：2026-06-13

## 动机

用户要求评估必须使用真实例子并可 cite，四个 policy family 都要完整实现并获取真实
workload，最终形成符合 OSDI/SOSP 标准的中文 evaluation section，并让独立 subagent
按顶会标准复审到通过为止。

本轮工作推进文档和评估设计层，不声称四个 policy 或 workload 已经实现完成。完整
completion 仍需要后续代码、workload、Make target、KVM run、raw results、analysis
和 subagent 结果级复审。

## 调研依据

本轮使用的外部真实系统依据包括：

- [Bazel sandboxing](https://bazel.build/docs/sandboxing)：真实 build action sandbox、
  known inputs、execroot、undeclared input 和 remote cache correctness。
- [Bazel hermeticity](https://bazel.build/basics/hermeticity)：真实 hermetic build
  依赖 action graph、tool/dependency 版本和 reproducible output。
- [Kubernetes projected volumes](https://kubernetes.io/docs/concepts/storage/projected-volumes/)：
  Secret、ConfigMap、serviceAccountToken、certificate 等真实 volume source 可以被投影
  到同一目录。
- [Kubernetes Secrets](https://kubernetes.io/docs/concepts/configuration/secret/)：
  Secret 可以作为文件暴露给 Pod，并有更新/缓存/传播语义。
- [Docker Compose secrets](https://docs.docker.com/compose/how-tos/use-secrets/)：
  secret 以文件挂入 `/run/secrets/<name>`，并按 service 授权。
- [CRIU checkpoint/restore](https://criu.org/Checkpoint/Restore)：restore 需要恢复
  files、memory mappings、socket、namespace 等进程资源。
- [Podman checkpoint](https://podman.io/docs/checkpoint)：container 可以 checkpoint、
  restore 和 migration，restore 后从 checkpoint 时刻继续运行。
- [ccache manual](https://ccache.dev/manual/4.13.1.html)：ccache 支持 local storage、
  remote storage、local miss remote hit、remote_only 等真实 cache hierarchy。
- [Docker BuildKit cache mounts](https://docs.docker.com/build/cache/optimize/)：
  cache mount 为 npm/pip/apt/go 等 package cache 提供跨 build 的持久缓存。
- [Nix content-addressed store](https://nix.dev/manual/nix/2.18/command-ref/new-cli/nix3-store-make-content-addressed)
  和 [Nix binary cache/substituter](https://nix.dev/manual/nix/2.26/package-management/binary-cache-substituter)：
  真实构建/包系统使用 content hash 验证 store path 或 binary cache。
- [Redis Makefile](https://github.com/redis/redis/blob/unstable/Makefile)、
  [Redis src Makefile](https://github.com/redis/redis/blob/unstable/src/Makefile)、
  [nginx docs](https://nginx.org/en/docs/beginners_guide.html)、
  [PostgreSQL server configuration](https://www.postgresql.org/docs/current/runtime-config.html)、
  [Prometheus repository](https://github.com/prometheus/prometheus) 和
  [Prometheus go.mod](https://github.com/prometheus/prometheus/blob/main/go.mod)：
  这些真实项目有源码构建、配置、服务启动、状态/恢复或 package cache 路径，适合作为
  workload，而不是玩具程序。

## Workload 选择原则

发布级 workload 必须同时满足：

- 来自真实公开项目、真实部署机制或真实系统文档；
- 能在 `workload/<workload-id>/evidence.md` 记录 URL、版本、hash、license、命令、
  trace、alias manifest 和 oracle；
- 能触发该 policy family 的 semantic witness，而不是只命中一个 hand-written alias；
- 能放大性能信号：大量 metadata operations、setup/teardown、alias fanout、
  path-class dispatch、restore sessions 或 cache state transitions；
- 有功能等价或明确不等价的 baseline；
- 可以在 KVM guest 中由 Make target 运行并产出 raw results。

## 选定的 primary workload

- `w1-redis-build` 和 `w1-nginx-build` 支撑 `build_graph_view.bpf.c`。它们是真实 C
  生产项目构建，能产生 source/header/generated/toolchain/deps 路径访问。
- `w2-nginx-fixture` 和 `w2-postgres-secret-fixture` 支撑
  `sandbox_fixture_view.bpf.c`。它们是真实服务启动路径，能覆盖 config、secret、
  certificate、endpoint、socket 和 poison path-class。
- `w3-redis-podman-criu` 和 `w3-nginx-podman-criu` 支撑
  `checkpoint_restore_view.bpf.c`。它们使用真实 Podman/CRIU checkpoint/restore 语义，
  能覆盖 checkpoint manifest、runtime-local remap 和 mixed epoch oracle。
- `w4-ccache-redis-nginx` 和 `w4-buildkit-prometheus-go-cache` 支撑
  `cache_locality_view.bpf.c`。它们使用真实 compiler/package cache hierarchy，
  能覆盖 hit/miss/stale/corrupt 和 content-hash correctness。

## 文档修订

- `docs/experiment-plans/osdi-evaluation.md` 新增发布级 primary workload 表，要求每个
  workload 有真实来源、性能信号、oracle 和主 baseline。
- `docs/paper/evaluation.md` 新增中文论文 evaluation section 草稿，按 OSDI rubric
  组织为 evaluation questions、setup、workloads、baselines、E1-E6 claim-first
  subsections、success gate 和降级规则。
- `docs/paper/evaluation.md` 明确没有 raw result 前不能写具体数字，只能写
  `TBD(result path)`。
- `workload/` 新增 primary workload evidence roots。每个 `evidence.md` 都标记为
  `planned; no raw results yet`，记录真实来源、后续 Make target、semantic witness、
  oracle 和 raw result path 约定。
- `configs/eval-osdi/workloads.mk` 新增发布级 workload ID 列表，后续 Make target
  只能从这里读取 workload 集合。
- `configs/eval-osdi/policy-budgets.mk` 新增 policy/verifier/map/table-only 预算，
  包括 checkpoint path-class 上限、restore transition hit-rate、cache hash witness
  上限和 cache state-transition hit-rate。
- 按 subagent 复审意见，checkpoint/restore workload 增加 critical path rule：
  只有 restore 后新发生的 VFS lookup/readdir 才能计入 `namei_ext` 证据，CRIU 已恢复
  fd/mmap/socket 不计数。
- 按 subagent 复审意见，BuildKit workload 从泛泛 package cache 收窄为
  `w4-buildkit-prometheus-go-cache`，绑定 Prometheus repository、`go.mod` 和 BuildKit
  Go cache mount paths。

## 剩余工作

- 创建 `workload/<workload-id>/` 子目录和 evidence/config/Makefile 片段。
- 实现四个 policy family：`build_graph_view.bpf.c`、`sandbox_fixture_view.bpf.c`、
  `checkpoint_restore_view.bpf.c`、`cache_locality_view.bpf.c`。
- 为每个 workload 写 Makefile-only fetch/build/trace/run/oracle target。
- 在 KVM guest 中运行 B1-B12，生成 raw results、manifest、dmesg 和 verifier logs。
- 从 raw results 生成 `docs/paper/evaluation.md` 中的图表和表格。
- 每轮结果写入 `docs/tmp/YYYY-MM-DD-*.md`，并让 subagent 复审到 pass。
