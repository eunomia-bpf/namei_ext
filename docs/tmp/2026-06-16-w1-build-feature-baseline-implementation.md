# W1 build graph feature baseline 实现记录

## 实现范围

本步骤实现 W1 build graph 的 KVM feature-equivalent baseline macrobench。新增能力：

- `namei_ext_w1_oracle --w1-build-baseline-macrobench`
- `make kvm-w1-build-baseline-macrobench`
- baseline families：`copy_tree`、`symlink_forest`、`bind_mount`
- raw JSONL events：
  - `w1-build-baseline-setup`
  - `w1-build-baseline-update`
  - `w1-build-baseline-correctness`
  - `w1-build-baseline-summary`

本实现不加载、不 attach eBPF policy。它使用普通 VFS 物化方案运行与 W1 proposed-system
相同的 Redis/nginx preprocessing oracle，并把 `policy_executed=false`、
`feature_equivalent_baseline=true`、`c2_supported=false` 和 `release_gate_pass=false`
写入 raw rows。

## 修改文件

- `tests/w1_oracle/namei_ext_w1_oracle.c`
  - 增加 W1 baseline selection parser。
  - 增加 baseline setup/update/correctness/summary emitters。
  - 增加 copy/symlink/bind materialization helpers。
  - 增加同路径 alias 去重，避免 Redis 和 nginx 共用 replay include directory 时重复
    materialize `stdio.h`。
  - 增加 `--w1-build-baseline-macrobench` CLI mode。
- `mk/kvm.mk`
  - 增加 `W1_BUILD_BASELINE_MACROBENCH_*` 变量。
  - 增加 `kvm-w1-build-baseline-macrobench` 和
    `__phase1_guest_w1_build_baseline_macrobench`。
  - guest target 校验 input artifacts、写 input sha256、运行 runner、校验 summary rows、
    复验 sha256、保存 dmesg。
- `Makefile`
  - 将 `kvm-w1-build-baseline-macrobench` 加入 `.PHONY` 和 `make help`。

## 验证

编译：

```text
make w1-oracle
```

结果：通过，`namei_ext_w1_oracle.c` 以 `-Wall -Wextra` 编译。

第一次 KVM smoke：

```text
make kvm-w1-build-baseline-macrobench \
  RUN_ID=20260616T-w1-build-baseline-smoke-v1 \
  W1_BUILD_BASELINE_MACROBENCH_SAMPLES=1 \
  W1_BUILD_BASELINES='copy_tree symlink_forest bind_mount'
```

结果：失败。`copy_tree` 和 `symlink_forest` 通过；`bind_mount` setup row 失败：

```text
baseline=bind_mount
pass=false
errno=16
detail="failed to materialize W1 build baseline view"
```

原因：W1 entries 同时包含 Redis 和 nginx 的 `external_dependency`，两者在 replay 中都映射到
同一个 include directory 下的 `stdio.h`。runner 对同一路径做第二次 bind mount，触发
`EBUSY`。这是 runner 去重 bug，不是内核 namei_ext 或 guest mount capability 失败。

修复：对 `entries[i].dir + entries[i].visible` 做已见 alias 去重；baseline setup/update
只物化一次同一路径。

第二次 KVM smoke：

```text
make kvm-w1-build-baseline-macrobench \
  RUN_ID=20260616T-w1-build-baseline-smoke-v2 \
  W1_BUILD_BASELINE_MACROBENCH_SAMPLES=1 \
  W1_BUILD_BASELINES='copy_tree symlink_forest bind_mount'
```

结果：通过。artifact：

```text
results/phase1/20260616T-w1-build-baseline-smoke-v2/w1-build-baseline-macrobench.jsonl
results/phase1/20260616T-w1-build-baseline-smoke-v2/w1-build-baseline-macrobench-inputs.sha256
results/phase1/20260616T-w1-build-baseline-smoke-v2/dmesg-w1-build-baseline-macrobench.log
```

summary：

```text
baseline_count=3
samples=1
setup_rows=3
update_rows=3
correctness_rows=3
pass=true
failures=0
c2_supported=false
release_gate_pass=false
```

smoke raw measurements：

```text
copy_tree: setup_ns=13407584, source_copy_ns=24349799952, update_ns=39043402
symlink_forest: setup_ns=65574900, source_copy_ns=20883966969, update_ns=55153521
bind_mount: setup_ns=66540193, source_copy_ns=20505218554, update_ns=37475805
```

## 仍未完成

- 该 smoke 只有 1 sample，不是 release-sample evidence。
- W1 ledger 还未把 proposed-system 20-sample run 和 baseline run 合并。
- FUSE/projected-volume baseline 尚未实现；因此 W1 C2 slice 仍不能声明 supported。
- 全局 C2 仍缺 W1 release baseline、W1 threshold ledger 和 W3/W4 macrobench。
