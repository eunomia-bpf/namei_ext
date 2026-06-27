# W3 Redis checkpoint replay witness 实现记录

日期：2026-06-15

## 动机

W3 checkpoint/restore family 原先只有 host checkpoint-witness manifest 和 KVM
per-entry path oracle。它能证明 `checkpoint_restore_view.bpf.c` 的 lookup/readdir
语义可沿真实 `cgroup/namei_ext` attach path 运行，但不能证明真实应用的文件加载路径会
消费这个 redirect。为了向真实 workload 靠近一步，本步骤新增 Redis checkpoint replay
witness：用真实 `redis-server` 生成 checkpoint backing，并让 Redis 通过可见
`dump.rdb` 路径经 policy redirect 加载 hidden `dump.ckpt`。

该 witness 仍明确不是 Podman/CRIU restore，也不能计入 C1/C8。

## 调研和检查的代码路径

- `tests/w1_oracle/namei_ext_w1_oracle.c`：复用现有 W1/W2/W3/W4 path-oracle runner，
  增加 Redis RESP helper 和 `--checkpoint-redis-replay` mode。
- `mk/kvm.mk`：增加 `kvm-w3-redis-replay` 和 guest target，把 Redis binary、policy
  object、W3 TSV、checkpoint manifest、runner source/binary 纳入 input hash。
- `mk/report.mk`：把 `w3-redis-replay.jsonl`、input hash、summary 字段和 raw artifact
  纳入 report hard gate。
- `Makefile`：把 `kvm-w3-redis-replay` 纳入 `phase1` 默认流程。
- `bpf/policies/checkpoint_restore_view.bpf.c`：不改 policy 逻辑；新增测试只验证现有
  checkpoint policy 的真实 Redis RDB load witness。

## 设计选择

Runner 在 guest 临时目录中启动真实 `redis-server`，先写入 key
`namei_ext:w3:checkpoint=checkpoint_restore_policy_loaded` 并执行 `SAVE`，把生成的
`dump.rdb` 改名为 hidden backing `dump.ckpt`。随后执行三段对照：

1. attach 前：可见 `dump.rdb` 不存在，Redis 启动后 `GET` 返回 nil。
2. attach 后：load/attach `checkpoint_restore_view.bpf.o`，同一 Redis `dbfilename
   dump.rdb` 通过 policy redirect 读取 `dump.ckpt`，`GET` 返回 checkpoint value，
   readdir 显示 `dump.rdb` 且隐藏 `dump.ckpt`。
3. detach 后：同一路径再次不加载 hidden checkpoint，`GET` 返回 nil。

结果格式保持 raw JSONL，不在 collector 中计算论文结论。summary 显式写入：
`result_level=kvm_checkpoint_restore_replay_witness`、`run_environment=kvm`、
`redis_checkpoint_loaded_via_policy=true`、`post_restore_vfs_replay=true`、
`podman_criu_restore_executed=false` 和 `qualified_for_c8=false`。

## 拒绝的替代方案

- 不在 Phase 1 中假装执行 Podman/CRIU restore。当前 Docker/runtime 镜像没有发布级
  Podman/CRIU/Redis restore pipeline，直接把 RDB replay 写成 restore 会 overclaim。
- 不新增 shell 脚本。所有入口继续由 Makefile target 驱动。
- 不新增 YAML/JSON policy 配置。policy 仍是 `bpf/policies/checkpoint_restore_view.bpf.c`。
- 不把 replay 计入 C8。它没有 restore health、post-restore VFS trace、0 mixed epoch
  或 table/update budget counterfactual。

## 验证

单项 KVM gate：

```text
make kvm-w3-redis-replay RUN_ID=20260615T-parent-key-poc
```

完整 Phase 1：

```text
make phase1 RUN_ID=20260615T-parent-key-poc SAMPLES=1 BENCH_ITERS=2000
```

报告和收尾检查：

```text
make -C docs/paper check
make -C docs/paper paper
git diff --check
rg --files -g '*.sh' -g '!kernel/**' -g '!results/**' -g '!.git/**' -g '!.build/**' -g '!.cache/**'
rg -n 'BUG:|Oops|Kernel panic|WARNING:|KASAN|UBSAN|general protection fault|segfault' results/phase1/20260615T-parent-key-poc/dmesg-*.log
```

结果：

- `make kvm-w3-redis-replay` 通过。
- `make phase1 RUN_ID=20260615T-parent-key-poc SAMPLES=1 BENCH_ITERS=2000` 通过。
- `make -C docs/paper check` 通过。
- `make -C docs/paper paper` up-to-date 且未失败。
- `git diff --check` 通过。
- 源码区 `.sh` 扫描没有发现 project-owned shell scripts。
- 精确 dmesg 错误扫描没有发现 `BUG/Oops/Kernel panic/WARNING/KASAN/UBSAN`。

关键 raw artifacts：

- `results/phase1/20260615T-parent-key-poc/w3-redis-replay.jsonl`
- `results/phase1/20260615T-parent-key-poc/w3-redis-replay-inputs.sha256`
- `results/phase1/20260615T-parent-key-poc/dmesg-w3-redis-replay.log`
- `results/phase1/20260615T-parent-key-poc/summary.md`

## 剩余风险

- 这不是 Podman/CRIU restore；C8 仍需要真实 checkpoint archive、restore health、
  post-restore VFS trace、state/config/cache hash、0 mixed epoch oracle 和
  table/update budget counterfactual。
- 当前 replay 只覆盖 Redis RDB load path，不覆盖 AOF、CONFIG REWRITE、BGSAVE、
  socket/temp remap 或 nginx restore row。
- W3 table-only 在当前 path/replay oracle 上没有失败，因此不能用它证明必须需要
  eBPF programmable abstraction。
