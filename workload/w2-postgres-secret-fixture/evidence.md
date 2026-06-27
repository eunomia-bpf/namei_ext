# w2-postgres-secret-fixture 证据

状态：`functional_only_kvm_path_oracle`；不能计入 C1/C8。

Policy family：`sandbox_fixture_view.bpf.c`

## 真实来源

- PostgreSQL server configuration: https://www.postgresql.org/docs/current/runtime-config.html
- Docker Compose secrets: https://docs.docker.com/compose/how-tos/use-secrets/
- Kubernetes Secrets: https://kubernetes.io/docs/concepts/configuration/secret/

## 当前已实现的 provenance 和 gates

- 固定 PostgreSQL 源码版本：PostgreSQL `16.6`
- Source tarball SHA256：`520d173632e93507f26eb66713d953b687cfba5e72c467d3adbc8ec4dbb8148f`
- PostgreSQL sample config SHA256：`263421e9f1d37ce2be6cc86efd404764c23d85d85c3312e86e660b26d83a0ea6`
- Source provenance target：`make workload-postgres-fixture-fetch`
- Source provenance result：`results/workloads/provenance/postgres-source.json`
- Fixture manifest result：
  `results/workloads/runs/20260614T-workloads-git-ceiling/w2-postgres-secret-fixture/fixture-manifest.json`
- KVM path oracle result：
  `results/phase1/20260614T-workloads-git-ceiling/w2-oracle.jsonl`
- Input hash manifest：
  `results/phase1/20260614T-workloads-git-ceiling/w2-oracle-inputs.sha256`
- Fixture manifest target：`make workload-postgres-fixture-manifest`
- Combined W2 TSV target：`make workload-w2-oracle-entries`
- KVM path oracle target：`make kvm-w2-oracle`

## 当前 path-oracle witness

- production config -> fixture
- production password/secret -> fake secret file

## 当前 oracle

- fixture manifest 结构和 source hash 检查
- 通过真实 `cgroup/namei_ext` attach path 在 KVM guest 中执行
- 每个声明 fixture entry 的 lookup 内容匹配
- readdir visible set 包含 alias，并按当前 oracle 检查 backing 处理
- detach 后 alias 再次不可达
- `w2-oracle-inputs.sha256` 固定 TSV、manifests、policy source/object 和 runner source/binary

## 进入 C1/C8 前仍需完成的发布级 oracle

- PostgreSQL health/query result
- fake password used
- real secret hash never opened
- poison access report
- startup trace 和 operation-weighted redirected hit rate
- table/update budget counterfactual

## 当前 raw results

- `results/workloads/runs/20260614T-workloads-git-ceiling/w2-postgres-secret-fixture/`
- `results/phase1/20260614T-workloads-git-ceiling/w2-oracle.jsonl`

## 当前限制

- 这是 per-entry synthetic-directory KVM path oracle。
- 它不启动 PostgreSQL。
- 它尚未证明 health/query result、no-real-secret、fake password use 或 table/update budget。
