# w4-buildkit-prometheus-go-cache 证据

状态：`functional_only_kvm_path_oracle` + `kvm_cache_content_oracle`；不能计入 C1/C8。

Policy family：`cache_locality_view.bpf.c`

## 真实来源

- Prometheus repository: https://github.com/prometheus/prometheus
- Prometheus go.mod: https://github.com/prometheus/prometheus/blob/main/go.mod
- Docker BuildKit cache mounts: https://docs.docker.com/build/cache/optimize/

## 已固定的 provenance

- 固定 Prometheus 版本：`v2.55.1`
- 固定 tag commit：`6d7569113f1ca814f1e149f74176656540043b8d`
- Source tarball SHA256：`f48251f5c89eea6d3b43814499d558bacc4829265419ee69be49c5af98f79573`
- `go.mod` SHA256：`9f4ce6feb314691b5570d0ce21dbbf91e40c47f82dd5e965c091e184ab0ad3d4`
- `go.sum` SHA256：`0686d2e7b0db939fb52c606ba56c87e2918ec229883e580a4bd866529f6ef4d3`
- Source provenance target：`make workload-prometheus-go-cache-fetch`
- Source provenance result：`results/workloads/provenance/prometheus-source.json`

## 当前 path/content oracle witness

当前实现还没有真实 BuildKit run、Go build/test output hash、module cache trace 或
cache transition trace。Phase 1 只把固定 Prometheus `go.mod` 作为 canonical cache
witness，并在 KVM guest 中验证 lookup/readdir redirect。新增的 cache content
oracle 在同一修改内核 KVM guest 内读取 `w4-cache-oracle-entries.tsv`，把
Prometheus `go.mod` witness materialize 为 `pkg.canon`，填充
`cache_locality_view.bpf.c` 的 `cache_rules` map，并检查 `pkg.mod -> pkg.canon` 的
miss canonical 分支；同时和 ccache row 一起覆盖 verified hit、stale fallback 和
corrupt reject。

- Cache witness manifest target：`make workload-buildkit-manifest`
- Combined W4 TSV target：`make workload-w4-oracle-entries`
- KVM path oracle target：`make kvm-w4-oracle`
- KVM cache content oracle target：`make kvm-w4-cache-content`
- Cache witness manifest：
  `results/workloads/runs/20260614T-workloads-git-ceiling/w4-buildkit-prometheus-go-cache/cache-manifest.json`
- Combined W4 TSV：
  `results/workloads/runs/20260614T-workloads-git-ceiling/w4-cache-oracle-entries.tsv`
- KVM raw result：
  `results/phase1/20260614T-workloads-git-ceiling/w4-oracle.jsonl`
- KVM input hash manifest：
  `results/phase1/20260614T-workloads-git-ceiling/w4-oracle-inputs.sha256`
- KVM cache content raw result：
  `results/phase1/20260614T-w2-nginx-probes-phase1/w4-cache-content.jsonl`
- KVM cache content input hash manifest：
  `results/phase1/20260614T-w2-nginx-probes-phase1/w4-cache-content-inputs.sha256`

当前 witness entry：

- `gomod/pkg.mod -> pkg.canon`，分支 `miss_canonical`，backing 内容为固定
  Prometheus `go.mod`

当前 path oracle 只检查 attach 前 alias 不存在、attach 后 lookup 内容匹配、
readdir alias/backing 一致性和 detach 后 alias 不可达。`cache_locality_view.bpf.c`
和 `table_redirect.bpf.c` 在 W4 全部 4 个 entries 上均为 0 failure；summary
显式记录 `qualified_for_c8=false`。修订后的 cache content oracle 额外要求
`cache_rules` map update 成功，且 input hash manifest 必须包含 W4 TSV、两个 cache
manifest、policy source/object 和 runner source/binary。

Cache content oracle 额外证明 `pkg.mod` 在 attach 后读取到 `pkg.canon`，readdir
中显示 `pkg.mod` 而隐藏 `pkg.canon`，detach 后 `pkg.mod` 不再可达。该 oracle 的
summary 为 0 failure，但仍显式记录 `qualified_for_c8=false`，因为它不是真实
BuildKit/Prometheus build/test，也没有 Go output hash、cache mount transition
trace、stale window、update writes 或 table/update budget counterfactual。

## 发布级 oracle 仍需完成

- 固定 BuildKit version、Go version、cache mount contents 和 cache manifest SHA256。
- Makefile-owned 真实 BuildKit/Prometheus build or test run/trace target。
- `go build` 或 `go test` output hash、module cache manifest hash、hit/miss/stale/corrupt
  state-transition coverage、stale/corrupt 0 unexpected hit、update writes 和 stale window。
- `table_redirect.bpf.c` 的同等 table/update budget counterfactual。
