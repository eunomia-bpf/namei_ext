# Workload 证据目录

本目录保存 OSDI evaluation 的 release-level 真实 workload 证据。

规则：

- 每个 workload 都有自己的 `workload/<workload-id>/` 目录。
- 项目自有 orchestration 必须是 Makefile-only；不要在这里新增项目自有 `.sh`
  文件。
- 每个 workload 必须保留 `evidence.md`，记录上游 URL、版本或 commit、下载
  hash、license、Make targets、trace 输入、alias manifest provenance、oracle 和
  raw result paths。
- workload 只有在 `evidence.md` 状态从 `planned` 改成 `validated`，并且引用的
  KVM raw results 已经存在于 `results/` 下之后，才能支撑 C1/C8。

Makefile-owned workload 入口：

- `make workloads`
- `make workload-fetch`
- `make workload-provenance`
- `make workload-build-graph`
- `make workload-redis-build`
- `make workload-redis-build-trace`
- `make workload-redis-build-manifest`
- `make workload-redis-build-alias-manifest`
- `make workload-nginx-build`
- `make workload-nginx-build-trace`
- `make workload-nginx-build-manifest`
- `make workload-nginx-build-alias-manifest`

source targets 会把固定上游输入下载到 `.cache/workloads/`，解压到
`.build/workloads/`，并把 provenance JSON 写到
`results/workloads/provenance/`。archive SHA256 固定在
`configs/eval-osdi/workload-sources.mk`；Make 每次解压前都会校验 archive hash，
hash 不匹配是 hard failure。

W1 build-graph targets 会从干净的 per-run source trees 构建并 trace 固定的
Redis/nginx release。source trees 位于
`.build/workloads/runs/<run-id>/`，raw build logs、strace logs、JSON summaries
和 manifests 位于 `results/workloads/runs/<run-id>/`。

W1 alias-manifest targets 保留手工选择的 candidate policy entries，并用 raw
strace logs 和 source hashes 约束这些 candidates，记录 semantic branch hits 和
`candidate_witness_hit_rate`。它们不执行 BPF policy，不创建 shadow backing files，
也不在 KVM 中验证结果。

source provenance 和 host-side build traces 不会让 workload 变成 `validated`。
workload 只有在修改后的 kernel、真实 policy attach path、workload-specific oracle
和 table-only counterfactual 都在 KVM 中通过，并把 raw results 写到 `results/`
之后，才能支撑 C1/C8。

清理规则：

- `make workload-clean` 删除 workload build/cache outputs，但保留
  `results/workloads/`。
- `make workload-clean-results` 显式删除 workload provenance 和 run results。
