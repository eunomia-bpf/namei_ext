# 真实 workload 来源与 citation 审计

日期：2026-06-16

阶段：Phase 1 research documentation

## 动机

本轮审计回应两个评审级要求：

1. workload 必须来自真实系统、真实应用或真实工具链，不能由项目自造 synthetic app 来支撑
   C1/C8。
2. 真实来源只能证明 use case 存在；是否支持 `namei_ext` 的性能、通用性或可编程性，
   必须由 KVM raw results、oracle、baseline 和 table-only counterfactual 证明。

因此，本轮把 W1--W4 的 primary sources 锁定到论文 BibTeX、claim ledger、eval plan 和
workload evidence 中，并明确当前证据等级。

## 调研和检查过的项目文件

- `docs/experiment-plans/osdi-evaluation.md`
- `docs/paper/sections/02-motivation.tex`
- `docs/paper/sections/05-evaluation.tex`
- `docs/paper/refs.bib`
- `research/CLAIM_LEDGER.md`
- `workload/w2-nginx-fixture/evidence.md`
- `results/phase1/20260615T-w2-nginx-c2-macrobench-release-sample-v1/w2-nginx-macrobench.jsonl`

## 外部来源和它们能证明什么

| Family | 锁定来源 | 能证明的真实问题 | 不能证明的内容 |
|--------|----------|------------------|----------------|
| W1 build graph | Bazel sandboxing、hermeticity、dependencies、toolchains；Redis/nginx source builds | 构建系统需要 declared inputs、actual dependencies、generated outputs 和 platform toolchain selection。 | 不能证明 `build_graph_view.bpf.c` 必然优于 copy/symlink/bind/FUSE/table-only。 |
| W2 sandbox fixture | Kubernetes projected volumes/secrets；Docker Compose configs/secrets；nginx/PostgreSQL config paths | 真实部署会把 config、secret、token、cert 或 endpoint 作为文件注入 workload，测试环境需要 fixture substitution。 | 不能证明这是安全隔离；也不能证明 table-only 无法覆盖当前 hand-written fixture。 |
| W3 checkpoint/restore | Podman checkpoint；CRIU checkpoint/restore 和 external bind mounts；DMTCP path virtualization | restore 后常需要把 checkpoint image 中的路径、mount、socket、pid、log 或 runtime state 映射到新环境。 | 不能替代真实 Podman/CRIU KVM restore、post-restore VFS trace 和 mixed-epoch oracle。 |
| W4 cache locality | ccache；Docker BuildKit cache mounts；Bazel remote cache / remote execution API；Nix binary cache/content-addressed store；Prometheus Go module graph | 真实构建系统有 cache key、content digest、hit/miss/stale/corrupt 和 fallback correctness 问题。 | 不能证明当前 W4 必须用 eBPF；当前 table-only comparator 仍是负证据。 |

## 设计结论

1. W1--W4 可以作为四个差异足够大的 policy family：build graph precedence、sandbox
   fixture path-class dispatch、checkpoint/restore epoch/session consistency、content-verified
   cache locality。
2. 这些 family 的真实来源已经足以进入 OSDI 级 evaluation plan，但还不足以支持论文主
   claim。它们必须继续绑定到 `workload/<workload-id>/evidence.md` 中的固定版本、下载哈希、
   Make target、raw result、operation-weighted hit rate 和 correctness oracle。
3. workload 目录规则保持不变：每个 workload 的启动脚本、配置、fixture、manifest 和
   evidence 必须放在 `workload/<workload-id>/` 下；项目 orchestration 仍必须走 Makefile，
   不能新增项目自有 `.sh` control plane。
4. W2 nginx 已经有 20-sample KVM setup/update macrobench raw input，但它只能说明
   `kvm-w2-nginx-macrobench` 在修改内核 KVM 中可运行；因为缺 feature-equivalent baseline、
   storage footprint、成功阈值以及 W1/W3/W4 对等 macrobench，它不能升级 C2。
5. C8 仍然 unsupported。W3 Redis same-workload table-only replay、W4 cache-content table-only
   comparator 和 W4 ccache table-only comparator 都是负证据；后续必须找到真实 release
   workload 中 table-only 失败、超预算、update 写放大或 stale window 不可接受的证据。

## 本轮文档改动

- `docs/paper/refs.bib` 新增缺失的 BibTeX key：
  `bazel_dependencies`、`bazel_toolchains`、`docker_compose_configs`、
  `criu_external_bind_mounts`、`dmtcp_path_virtualization`、
  `bazel_remote_execution_api`、`nix_binary_cache_substituter`、
  `nix_content_addressed_store`。
- `docs/paper/sections/02-motivation.tex` 将四个 policy family 的动机段落改为引用
  primary sources。
- `docs/experiment-plans/osdi-evaluation.md` 新增 2026-06-16 citation audit 规则，并把
  W2 20-sample KVM setup/update macrobench 写入 source-to-signal ledger。
- `research/CLAIM_LEDGER.md` 更新 C2 状态和 W1--W4 可引用来源列表。
- `workload/w2-nginx-fixture/evidence.md` 新增 Docker Compose 来源、macrobench Make target、
  20-sample result path 和 C2 release blocker。

## 本轮验证

- `git diff --check` 通过。
- `make -C docs/paper check` 通过。
- `make -C docs/paper paper` 通过，生成
  `.build/paper/main.pdf`。构建日志仍有已有长路径和长 `\code{}` 字段导致的
  overfull/underfull 排版警告，但没有因为新增 citation key 或 BibTeX entry 失败。
- `rg` 检查确认新增 BibTeX key 已同时出现在 `docs/paper/refs.bib`、论文动机段落、
  eval plan、claim ledger 和 W2 evidence 中。
- 本轮没有重新运行 KVM；KVM 结果引用的是
  `results/phase1/20260615T-w2-nginx-c2-macrobench-release-sample-v1/w2-nginx-macrobench.jsonl`
  中已经存在的 20-sample W2 run。

## 剩余风险

- W1 仍缺完整 trace-derived alias set、natural poison/negative hit 和 operation-weighted
  release metric。
- W2 仍缺 PostgreSQL real oracle、nginx trace-level no-real-open、endpoint matrix、
  feature-equivalent setup/storage/update baseline 和 C2 阈值。
- W3 当前还没有真实 Podman/CRIU restore KVM run；checkpoint/restore family 不能只靠
  Redis RDB replay 支撑。
- W4 当前的 ccache/BuildKit 方向还没有 release-level stale/corrupt transition、operation-weighted
  cache hit rate 和 table/update budget failure。

## 下一步建议

优先级最高的是 W2：补同一 nginx fixture workload 的 projected-volume/copy/symlink/bind/FUSE
feature-equivalent baseline，并让 `eval-osdi-workload-macrobench-ledger` 读取 W2 KVM raw rows。
这会直接推进 C2。并行但次优先的是 W4：补真实 stale/corrupt transition 或 BuildKit/Prometheus
cache trace，因为它最可能产生 C8 所需的 table-only failure 或 update-budget failure。
