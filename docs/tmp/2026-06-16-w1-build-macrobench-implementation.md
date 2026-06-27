# W1 build workload macrobench 实现记录

日期：2026-06-16

## 动机

C2 目前已有 W2 nginx fixture 的 20-sample proposed-system setup/update rows、
五类 feature-equivalent baseline rows、storage footprint aggregation 和显式阈值判定；
但全局 C2 仍缺 W1/W3/W4 对等 workload setup/storage/update macrobench。W1 build
graph 是下一步最小可运行路径，因为它已经有真实 Redis/nginx source build trace、
`build_graph_view.bpf.c`、KVM path oracle、KVM preprocessing replay witness、release-binary
replay witness 和 branch probes。

本步骤实现的是 W1 proposed-system KVM macrobench PoC，不是 W1 release comparison，也不支持
全局 C2。

## 修改范围

- `tests/w1_oracle/namei_ext_w1_oracle.c`
  - 新增 `--w1-build-macrobench` mode；
  - 写出 `w1-build-macrobench-setup`、`w1-build-macrobench-update`、
    `w1-build-macrobench-correctness` 和 `w1-build-macrobench-summary` raw rows；
  - 复用真实 Redis/nginx source tree、trace-derived W1 entries、`build_graph_view.bpf.c`
    load/map/attach path 和现有 preprocessing replay oracle；
  - setup row 记录 alias materialization 对象数、`setup_ns`、`source_copy_ns` 和
    `bytes_copied`；
  - update row 记录 refresh shadow backing 的 `update_ns`、copy bytes 和 write counts。
- `mk/kvm.mk`
  - 新增 `kvm-w1-build-macrobench` 和 `__phase1_guest_w1_build_macrobench`；
  - guest 内检查 W1 workload manifests、alias manifests、policy object、runner、
    设计文档和 source trees；
  - guest 内写 `w1-build-macrobench-inputs.sha256`，运行 runner，校验 setup/update/correctness
    rows 均达到 sample 数，summary 必须 `pass=true`、`c2_supported=false`、
    `release_gate_pass=false`。
- `Makefile`
  - 增加 top-level phony target 和 help 文本。
- `docs/tmp/2026-06-16-w1-build-macrobench-design.md`
  - 记录设计目标、非目标、row schema、oracle 和限制。

## v1 失败和根因

第一次 KVM smoke：

```text
make kvm-w1-build-macrobench RUN_ID=20260616T-w1-build-macrobench-smoke-v1 W1_BUILD_MACROBENCH_SAMPLES=1
```

结果 root：

```text
results/phase1/20260616T-w1-build-macrobench-smoke-v1/
```

runner 成功写出 1 条 setup row，但 Redis policy preprocessing output compare 失败：

```text
event=w1-build-replay
workload_id=w1-redis-build
op=output_compare
pass=false
errno=22
detail=Redis policy output differed from baseline
```

diff 显示差异来自 Redis 预处理输出中嵌入的绝对路径字符串，例如 baseline 使用
`redis-baseline-src/src/server.c`，policy 使用 `redis-policy-src/src/server.c`。
这不是 path-resolution 语义差异，而是 runner 把 baseline 和 policy 放在两个不同临时
源码目录导致的 false negative。nginx 在该 run 中通过，只是 Redis 更明显地暴露了
`__FILE__`/assert path 差异。

## 修复

runner 改为每个 sample 只复制一份 Redis source tree 和一份 nginx source tree：

1. 先准备 result/toolchain/include helper；
2. 在未 attach policy 时，用同一份 source tree 生成 baseline preprocessed output；
3. 在同一份 source tree 中 materialize trace-derived shadow aliases；
4. attach `build_graph_view.bpf.c`；
5. 再用同一份 source tree 生成 policy preprocessed output；
6. refresh shadow backing 后重复 policy replay，作为 update correctness oracle。

这样 correctness oracle 比较的是 policy path-resolution 行为，而不是临时目录名。
该修复不改变 kernel ABI、不改变 policy 语义，也不引入 shell 脚本。

## v2/v3 验证

命令：

```text
make w1-oracle
make kvm-w1-build-macrobench RUN_ID=20260616T-w1-build-macrobench-smoke-v3 W1_BUILD_MACROBENCH_SAMPLES=1
sha256sum -c results/phase1/20260616T-w1-build-macrobench-smoke-v3/w1-build-macrobench-inputs.sha256
```

结果 root：

```text
results/phase1/20260616T-w1-build-macrobench-smoke-v3/
```

`20260616T-w1-build-macrobench-smoke-v2` 已经通过 KVM row gate，但随后设计文档被修正为
preprocessing replay oracle，因此 v2 的 `w1-build-macrobench-inputs.sha256` 对当前设计
文档不再匹配。`v3` 是当前 canonical run，guest 内和 host 侧 input hash 校验均通过。

关键 raw rows：

- setup：`pass=true`、`setup_ns=57973895`、`source_copy_ns=20927589150`、`entries=9`、
  `created_dirs=2`、`created_files=10`、`created_symlinks=2`、`bytes_copied=457338`。
- update：`pass=true`、`update_ns=66338828`、`source_update_writes=7`、
  `update_bytes_copied=412795`、`policy_executed=true`。
- correctness：`pass=true`、`baseline_replay_pass=true`、`policy_replay_pass=true`、
  `post_update_replay_pass=true`、`policy_executed=true`、`kvm_validated=true`。
- summary：`samples=1`、`setup_rows=1`、`update_rows=1`、`correctness_rows=1`、
  `pass=true`、`failures=0`、`c2_supported=false`、`release_gate_pass=false`。

输入 manifest 的 `sha256sum -c` 在 host 复验通过。guest target 内也已经执行同一
input hash 校验。

## 当前证据等级

该实现把 W1 从“只有 replay/path oracle”推进到“有修改内核 KVM 中的 proposed-system
setup/update PoC rows”。它可以作为 C2 下一步基础设施证据，但还不能支持 C2 论文结论：

- sample 数只有 1，不是 release repetition；
- 还没有 W1 feature-equivalent baselines；
- 还没有 W1 storage footprint aggregation 或阈值判定；
- correctness oracle 是 preprocessing replay，不是本步骤内完整 release binary rebuild；
- W3/W4 对等 macrobench 仍未完成。

因此所有 W1 macrobench summary 必须保持 `c2_supported=false` 和
`release_gate_pass=false`。

## 后续工作

1. 将 W1 proposed-system PoC 扩展到 release sample budget。
2. 设计 W1 feature-equivalent baselines，至少覆盖 copy-tree、symlink-forest、bind-mount、
   projected-volume/FUSE 中合理适配 build graph 的子集。
3. 为 W1 增加 storage footprint、setup/update threshold ledger，或明确把全局 C2 收窄。
4. 继续补 W3/W4 对等 setup/update macrobench，避免 W2-only slice 被误写成全局 C2。
