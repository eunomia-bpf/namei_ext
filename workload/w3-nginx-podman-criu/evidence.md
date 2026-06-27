# w3-nginx-podman-criu 证据

状态：`functional_only_kvm_path_oracle`；不能计入 C1/C8。

Policy family：`checkpoint_restore_view.bpf.c`

## 真实来源

- nginx official image: https://hub.docker.com/_/nginx
- nginx reload/config documentation: https://nginx.org/en/docs/beginners_guide.html
- Podman checkpoint documentation: https://podman.io/docs/checkpoint
- CRIU checkpoint/restore design: https://criu.org/Checkpoint/Restore

## 已固定的 provenance

- 固定源码版本：nginx `1.26.3`
- 源码 tarball SHA256：`69ee2b237744036e61d24b836668aad3040dda461fe6f570f1787eab570c75aa`
- Source provenance target：`make workload-nginx-build-fetch`
- Source provenance result：`results/workloads/provenance/nginx-source.json`

## 当前 path-oracle witness

当前实现还没有真实 nginx Podman/CRIU restore，也没有固定
`docker.io/library/nginx:<digest>`。Phase 1 只生成 checkpoint witness manifest，
其中 `nginx.conf` 使用固定 nginx 源码包里的 upstream sample config，其余 cache/pid
是 Make-owned fixtures；随后在 KVM guest 中验证 lookup/readdir redirect。

- Checkpoint witness manifest target：`make workload-nginx-checkpoint-manifest`
- Combined W3 TSV target：`make workload-w3-oracle-entries`
- KVM path oracle target：`make kvm-w3-oracle`
- Checkpoint witness manifest：
  `results/workloads/runs/20260614T-workloads-git-ceiling/w3-nginx-podman-criu/checkpoint-manifest.json`
- Combined W3 TSV：
  `results/workloads/runs/20260614T-workloads-git-ceiling/w3-checkpoint-oracle-entries.tsv`
- KVM raw result：
  `results/phase1/20260614T-workloads-git-ceiling/w3-oracle.jsonl`
- KVM input hash manifest：
  `results/phase1/20260614T-workloads-git-ceiling/w3-oracle-inputs.sha256`

当前 witness entries：

- `conf/nginx.conf -> nginx.ckpt`，分支 `config`，backing 来自 nginx upstream sample config
- `cache/cache.db -> cache.ckpt`，分支 `cache`
- `runtime/nginx.pid -> nginx.pid.new`，分支 `runtime_pid`

当前 oracle 只检查 attach 前 alias 不存在、attach 后 lookup 内容匹配、readdir
alias/backing 一致性和 detach 后 alias 不可达。`checkpoint_restore_view.bpf.c`
和 `table_redirect.bpf.c` 在 W3 全部 7 个 entries 上均为 0 failure；summary
显式记录 `qualified_for_c8=false`。

## 发布级 oracle 仍需完成

- 固定 nginx container image digest、Podman version、CRIU version 和 checkpoint archive SHA256。
- Makefile-owned 真实 restore/run/trace target。
- 只统计 restore 之后由 `nginx -s reload`、static file request、log reopen、
  pid/socket path check 或 directory enumeration 触发的新 VFS lookup/readdir。
- HTTP health、checkpoint config/static content hash、runtime pid/socket/log path checker、
  post-restore lookup/readdir trace coverage 和 0 mixed checkpoint/current epoch。
- `table_redirect.bpf.c` 的同等 table/update budget counterfactual。
