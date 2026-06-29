Last updated: 2026-06-15

> 2026-06-29 baseline scope update: this historical record preserves prior reasoning and results. Current C8/B12 guidance is claim-driven baseline selection; exact-map diagnostics are optional boundary evidence only when precomputed mapping is the competing claim.

Stage at update: Phase 1 implementation
Source/command: `make kvm-w1-release-build-replay RUN_ID=20260615T-parent-key-poc`, `make report RUN_ID=20260615T-parent-key-poc`
Completeness: complete for Phase 1 W1 release-binary replay witness; not C1/C8 qualifying

# W1 Release Binary Replay 实现记录

## 目标

本步骤把 W1 build-graph family 从“真实源码 preprocessing replay”推进到“真实
Redis/nginx release binary rebuild witness”。目标不是声明 C8，而是在修改后的
kernel/KVM guest 中证明：

- `build_graph_view.bpf.c` 通过真实 `cgroup/namei_ext` attach path 执行；
- Redis `7.2.14` 和 nginx `1.26.3` 的真实源码树在 policy attach 期间完成 rebuild；
- policy 源树的输出二进制与未 attach policy 的 baseline 二进制在规范化后 byte-for-byte
  一致；
- 所有输入、输出、stdout/stderr、dmesg 和 report gate 都由 Makefile 管理。

## 修改文件

- `tests/w1_oracle/namei_ext_w1_oracle.c`
  - 新增 `--release-build-replay` CLI mode。
  - 新增 Redis/nginx release rebuild runner。
  - policy 源树在 attach 前完成 rebuild cleanup，避免 cleanup 自身被 readdir alias 干扰。
  - child build 固定 `SOURCE_DATE_EPOCH=0`，避免 Redis `mkreleasehdr.sh` 用 wall-clock
    时间生成不同 `REDIS_BUILD_ID`。
  - 保存二进制后执行 `strip --strip-debug --remove-section=.note.gnu.build-id`，移除
    debug path 和 GNU build-id 这两类非语义构建元数据，再进行 hash 比较。
- `mk/kvm.mk`
  - 新增 `W1_RELEASE_REPLAY_JSON`、`W1_RELEASE_REPLAY_RESULT_DIR`、
    `W1_RELEASE_REPLAY_WORK_DIR`。
  - 新增 `kvm-w1-release-build-replay` 和
    `__phase1_guest_w1_release_build_replay`。
  - guest target 复制 Redis/nginx trace source 为 baseline/policy 两套源码树，运行
    runner，写入 input/output SHA256、dmesg 和 JSONL。
- `mk/report.mk`
  - 将 release replay JSONL、input SHA256、output SHA256 和四个二进制纳入
    `make report` 硬校验。
  - 校验 Redis baseline/policy hash 相等、nginx baseline/policy hash 相等。
  - 校验 release replay summary 为 `pass=true`、`failures=0`、
    `policy_executed=true`、`kvm_validated=true`、
    `release_binary_hash_match=true`、`qualified_for_c8=false`。
- `Makefile`
  - 将 `kvm-w1-release-build-replay` 加入默认 `phase1`。
  - 在 `make help` 中公开该 target。

## 失败与修正

第一次 KVM 运行失败暴露出两个真实问题：

1. nginx policy build 在 attach 后执行 cleanup，cleanup 的 recursive `readdir/lstat`
   会观察到 policy alias view，导致清理阶段遇到 `ENOENT`。修正是把 policy 源树的
   rebuild cleanup 移到 attach 前，attach window 内只运行真实 rebuild 和 output
   compare。
2. Redis baseline/policy 二进制初始 hash 不一致。定位发现差异来自两类非语义元数据：
   Redis release header 的 wall-clock build id，以及 debug/build-id metadata 中的
   临时源码路径或链接器 build-id。修正是固定 `SOURCE_DATE_EPOCH=0`，并在保存
   baseline/policy 二进制后移除 debug section 和 `.note.gnu.build-id`。

这些修正不改变 policy 语义：policy attach 期间仍然运行完整 Redis/nginx rebuild；
比较对象仍是可执行 ELF，只是不把临时构建路径和链接器标识作为 workload output
语义的一部分。

## 验证结果

执行过的关键命令：

```text
make w1-oracle
make kvm-w1-release-build-replay RUN_ID=20260615T-parent-key-poc
make kvm-w1-oracle kvm-w1-build-replay kvm-w1-release-build-replay kvm-w2-oracle kvm-w2-nginx-real kvm-w3-oracle kvm-w4-oracle kvm-w4-cache-content RUN_ID=20260615T-parent-key-poc
make report RUN_ID=20260615T-parent-key-poc
```

最终 report 通过，summary 位于：

```text
results/phase1/20260615T-parent-key-poc/summary.md
```

关键 gate 结果：

- W1 KVM policy release build replay failures: 0
- W1 oracle summary failures: 0
- W1 KVM policy build replay failures: 0
- W2/W3/W4 oracle summary failures: 0
- W2 nginx real-app summary failures: 0
- W4 cache content summary failures: 0
- Functional failing cases: 0
- Benchmark failing operations: 0
- Docker failing cases: 0
- Dmesg warning/oops/panic lines: 0
- Table-budget C8-qualified rows: 0

Release replay output hashes：

```text
65c8f5155d78a1a04ebb937cf7c85483b8320e1444686a691694c46e83f2de8b  redis.baseline.bin
65c8f5155d78a1a04ebb937cf7c85483b8320e1444686a691694c46e83f2de8b  redis.policy.bin
f9e214c23512996723d8409b0d0eda40070c135fc28f25d6f207ea85b4974544  nginx.baseline.bin
f9e214c23512996723d8409b0d0eda40070c135fc28f25d6f207ea85b4974544  nginx.policy.bin
```

对应 raw artifacts：

- `results/phase1/20260615T-parent-key-poc/w1-release-build-replay.jsonl`
- `results/phase1/20260615T-parent-key-poc/w1-release-build-replay-inputs.sha256`
- `results/phase1/20260615T-parent-key-poc/w1-release-build-replay-outputs.sha256`
- `results/phase1/20260615T-parent-key-poc/dmesg-w1-release-build-replay.log`

## 当前边界

该 gate 仍显式记录 `qualified_for_c8=false`，原因是：

- W1 alias set 仍来自手工候选 + trace witness，不是完整 trace-derived alias set；
- undeclared poison 和 negative fallback 仍没有真实 workload hit；
- 当前结果没有 operation-weighted redirected hit rate；
- table-only counterfactual 仍只是在当前 path oracle 上通过，并未证明同等
  table/update budget 下失败；
- release binary replay 只覆盖 Redis/nginx 两个 W1 build workload，不能替代 W2/W3/W4
  的 release-level workload oracles。

因此本步骤完成的是 Phase 1 release-binary witness，不是 OSDI 主结论中的 C1/C8
qualifying evidence。

## 后续补充

同日后续实现记录
`docs/tmp/2026-06-15-w1-branch-probes-implementation.md` 已补上 W1 KVM
poison/negative branch probes：`private.h -> poison.dep` 和
`missing.h -> PASS/ENOENT` 在 Redis/nginx 真实 source parent directory 副本中通过。
这更新的是 branch semantics evidence；release-level natural workload hit、
完整 trace-derived alias set、operation-weighted hit rate 和 table/update budget
counterfactual 仍未完成，因此 C8 仍不成立。
