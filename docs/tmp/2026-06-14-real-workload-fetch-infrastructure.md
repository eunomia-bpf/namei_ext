# 真实 workload 获取基础设施记录

日期：2026-06-14

## 动机

evaluation plan 已经命名真实 workload，但 planned evidence 不足以满足 OSDI 风格
可复现性要求。本步骤增加 Makefile-owned 的固定上游源码获取和 provenance 记录，
服务于 build、fixture、checkpoint/restore 和 cache-locality workloads。

这还不是 validated workload run。它只获取固定真实 source inputs，校验预期文件，
并把 hash 记录到 `results/`。

## 修改文件

- `configs/eval-osdi/workload-sources.mk`
- `mk/workload.mk`
- `Makefile`

## 固定输入

- Redis `7.2.14`，tag commit
  `f2262eccb855eadd1afb0c457ea583ef9d5400b5`
- nginx `1.26.3`
- PostgreSQL `16.6`
- Prometheus `v2.55.1`，tag commit
  `6d7569113f1ca814f1e149f74176656540043b8d`

这些输入故意 pin 到固定版本，而不是跟随 upstream `latest`。修改版本是新的实验输入，
必须改变 provenance 输出。

## Make targets

- `make workloads`
- `make workload-fetch`
- `make workload-provenance`
- `make workload-redis-build-fetch`
- `make workload-nginx-build-fetch`
- `make workload-postgres-fixture-fetch`
- `make workload-prometheus-go-cache-fetch`

所有 orchestration 都由 Makefile 拥有，没有新增项目自有 shell scripts。

## 产物

- downloaded archives：`.cache/workloads/`
- extracted sources：`.build/workloads/`
- provenance JSON：`results/workloads/provenance/`

provenance files 记录 upstream URL、固定 version 或 commit、expected archive
SHA256、observed archive SHA256、source directory、license hash，以及 workload
相关 evidence hash，例如 Redis Makefiles、nginx sample config、PostgreSQL sample
config、Prometheus `go.mod`/`go.sum`。

## 验证

观察到的结果：

- `make workload-provenance` 在修正 nginx source layout check 后通过；nginx 的
  configure 文件位于 source root `configure`，不是 `auto/configure`。
- 后续 `make -B workload-provenance` 在加入 fail-fast archive SHA256 checks 后通过。
  Redis、nginx、PostgreSQL 和 Prometheus 都报告 `sha256sum -c` `OK`。
- downloaded archives：
  - `.cache/workloads/redis-7.2.14.tar.gz`
  - `.cache/workloads/nginx-1.26.3.tar.gz`
  - `.cache/workloads/postgresql-16.6.tar.gz`
  - `.cache/workloads/prometheus-v2.55.1.tar.gz`
- extracted source roots：
  - `.build/workloads/redis-7.2.14`
  - `.build/workloads/nginx-1.26.3`
  - `.build/workloads/postgresql-16.6`
  - `.build/workloads/prometheus-2.55.1`
- provenance results：
  - `results/workloads/provenance/redis-source.json`
  - `results/workloads/provenance/nginx-source.json`
  - `results/workloads/provenance/postgres-source.json`
  - `results/workloads/provenance/prometheus-source.json`

`workload/*/evidence.md` 现在指向固定 upstream versions 和这些 provenance files。
source acquisition 本身仍不能产生 C1/C8 validation。

## 后续更新

同日，`make workloads` 后续扩展为同时运行 W1 host-side source-build-trace 和
trace-witness manifest。原始 fetch/provenance-only 行为仍可通过
`make workload-fetch` 和 `make workload-provenance` 单独执行。W1 实现记录见：

- `docs/tmp/2026-06-14-real-build-graph-workload-trace.md`
- `docs/tmp/2026-06-14-w1-trace-witness-manifest.md`

这个更新不改变 C1/C8 限制：host build traces 和 host-derived manifests 不是 KVM
policy validation。

## Subagent review 后的修正

OSDI 风格 subagent review 发现 `make clean` 曾经调用 `workload-clean`，而
`workload-clean` 会删除 workload result roots。这违反 raw observation preservation
规则。修正如下：

- `make workload-clean` 现在只删除 workload build/cache outputs。
- `make workload-clean-results` 显式删除 `results/workloads/provenance/` 和
  `results/workloads/runs/`。
- top-level `make clean` 保留 workload results。

同一个 review 还发现 archive hashes 只被记录，没有作为 fail-fast checks 使用。
修正是在 `configs/eval-osdi/workload-sources.mk` 增加 `*_ARCHIVE_SHA256` 变量，
每次 extraction 前使用 `sha256sum -c` 校验 archive，并在 provenance JSON 中同时
记录 expected 和 observed archive hashes。

## 剩余工作

- 对 W2/W3/W4 实现各自真实 workload 的 manifest/oracle。
- 实现 W1 materializer/loader，让 trace-witness manifest 在 KVM guest 中变成
  真实 BPF map state 和 shadow backing files。
- 运行真实 KVM workload oracles，并且只有 raw KVM results 存在后，才把单个
  `evidence.md` 状态从 `planned` 或 `source-build-trace` 改成 `validated`。
