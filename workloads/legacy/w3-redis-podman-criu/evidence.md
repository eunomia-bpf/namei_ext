# w3-redis-podman-criu 证据

> 2026-06-29 baseline scope update: older gate language is superseded by claim-driven baseline selection. Exact-map diagnostics are optional and only relevant when precomputed mapping is the competing claim.


状态：`functional_only_kvm_path_oracle` + `kvm_checkpoint_restore_replay_witness`；
不能计入 C1/C8。

Policy family：`checkpoint_restore_view.bpf.c`

命名说明：本目录名保留发布级目标 `w3-redis-podman-criu`，因为最终 workload 要运行
Redis Podman/CRIU checkpoint/restore。当前 Phase 1 已实现的增量 witness 应称为
`w3-redis-rdb-load-replay` 或 `W3 Redis checkpoint replay witness`；它只覆盖真实
Redis RDB load path 经 policy redirect 读取 hidden checkpoint backing，不等同于
Podman/CRIU restore。

## 真实来源

- Redis repository: https://github.com/redis/redis
- Redis configuration documentation: https://redis.io/docs/latest/operate/oss_and_stack/management/config/
- Podman checkpoint documentation: https://podman.io/docs/checkpoint
- CRIU checkpoint/restore design: https://criu.org/Checkpoint/Restore

## 已固定的 provenance

- 固定源码版本：Redis `7.2.14`
- 固定 tag commit：`f2262eccb855eadd1afb0c457ea583ef9d5400b5`
- 源码 tarball SHA256：`704bfac84ab1c0771ddc08c8bea72e2203e3ce64c1fc6750e76b8ce2c00f3145`
- Source provenance target：`make workload-redis-build-fetch`
- Source provenance result：`results/workloads/provenance/redis-source.json`

## 当前 path-oracle witness

当前实现还没有真实 Podman/CRIU restore。Phase 1 只生成 Make-owned checkpoint witness
fixtures，并在 KVM guest 中验证这些 entries 能通过真实 `cgroup/namei_ext` attach path
执行 lookup/readdir redirect。

- Checkpoint witness manifest target：`make workload-redis-checkpoint-manifest`
- Combined W3 TSV target：`make workload-w3-oracle-entries`
- KVM path oracle target：`make kvm-w3-oracle`
- Checkpoint witness manifest：
  `results/workloads/runs/20260614T-workloads-git-ceiling/w3-redis-podman-criu/checkpoint-manifest.json`
- Combined W3 TSV：
  `results/workloads/runs/20260614T-workloads-git-ceiling/w3-checkpoint-oracle-entries.tsv`
- KVM raw result：
  `results/phase1/20260614T-workloads-git-ceiling/w3-oracle.jsonl`
- KVM input hash manifest：
  `results/phase1/20260614T-workloads-git-ceiling/w3-oracle-inputs.sha256`

当前 witness entries：

- `checkpoint/dump.rdb -> dump.ckpt`，分支 `state_rdb`
- `checkpoint/appendonly.aof -> aof.ckpt`，分支 `state_aof`
- `runtime/redis.sock -> redis.sock.new`，分支 `runtime_socket`
- `checkpoint/epoch.bad -> poison.epoch`，分支 `mixed_epoch_poison`

当前 oracle 只检查 attach 前 alias 不存在、attach 后 lookup 内容匹配、readdir
alias/backing 一致性和 detach 后 alias 不可达。`checkpoint_restore_view.bpf.c`
和 `table_redirect.bpf.c` 在同一 4 个 Redis entries 上均为 0 failure；summary
显式记录 `qualified_for_c8=false`。

## 当前 Redis checkpoint replay witness

`make kvm-w3-redis-replay RUN_ID=20260615T-parent-key-poc` 在修改后的 kernel KVM guest
中运行真实 `redis-server` RDB load path：

- 先生成 hidden checkpoint backing `dump.ckpt`，其中 key
  `namei_ext:w3:checkpoint` 的值是 `checkpoint_restore_policy_loaded`。
- attach 前同一 workdir 中没有可见 `dump.rdb`，Redis 启动后 `GET` 返回 nil。
- attach `checkpoint_restore_view.bpf.c` 后，Redis 仍按可见 `dump.rdb` 启动，但
  policy 把 lookup redirect 到 `dump.ckpt`，`GET` 返回 checkpoint value。
- attach window 内 readdir 只显示 `dump.rdb`，隐藏 backing `dump.ckpt`。
- detach 后再次启动 Redis，`GET` 又返回 nil。

Raw result：
`results/phase1/20260615T-parent-key-poc/w3-redis-replay.jsonl`

Input hash manifest：
`results/phase1/20260615T-parent-key-poc/w3-redis-replay-inputs.sha256`

Summary 字段：

- `result_level=kvm_checkpoint_restore_replay_witness`
- `run_environment=kvm`
- `policy_executed=true`
- `redis_checkpoint_loaded_via_policy=true`
- `post_restore_vfs_replay=true`
- `podman_criu_restore_executed=false`
- `qualified_for_c8=false`

这个 witness 证明真实 Redis RDB load path 能观察到 `namei_ext` checkpoint policy
redirect；它仍不是 Podman/CRIU restore，不验证 restored service health、restore
trace、state/config/cache hash 或 0 mixed epoch。

## 发布级 oracle 仍需完成

- 固定 Redis container image digest、Podman version、CRIU version 和 checkpoint archive SHA256。
- Makefile-owned 真实 restore/run/trace target，而不是项目自有 shell 脚本。
- 只统计 restore 之后新发生的 VFS lookup/readdir，例如 `CONFIG REWRITE`、`BGSAVE`、
  AOF/RDB open/stat、log/config stat 和 restore-session directory enumeration。
- Redis health check、RDB/AOF/config hash 等于 checkpoint manifest、runtime-local
  socket/temp path remap、post-restore lookup/readdir trace coverage 和 0 mixed
  checkpoint/current epoch。
- claim-driven baseline comparison or optional exact-map diagnostic。

CRIU 已恢复的 fd、mmap mapping 和 socket 不计为 `namei_ext` 证据，除非 workload
在 restore 之后再次通过 VFS lookup/readdir 访问这些路径。
