# W1 build workload setup/update macrobench 设计

日期：2026-06-16

## 动机

当前 C2 的剩余缺口已经从 W2 nginx fixture 的 storage/threshold 缺失缩小为
W1/W3/W4 对等 workload setup/storage/update macrobench。W1 是最适合先补的下一个
workload，因为现有代码已经有：

- 真实 Redis/nginx source build provenance 和 trace；
- `build_graph_view.bpf.c` policy；
- KVM path oracle；
- KVM release-binary replay witness；
- `copy_tree`、`symlink_forest`、`bind_mount`、`projected_volume`、`fuse_redirect`
  这些 W2 baseline 的 measurement schema 可以复用为 C2 comparison 口径。

## 目标

本阶段只做 W1 的最小 KVM proposed-system macrobench PoC，不直接升级全局 C2：

- 新增 `make kvm-w1-build-macrobench`；
- 在修改内核 KVM guest 内执行；
- 使用真实 `build_graph_view.bpf.c` 和真实 `cgroup/namei_ext` attach path；
- 每个 sample 记录 setup、update、correctness 三类 raw rows；
- default sample 数保持小，release sample 可以由 `W1_BUILD_MACROBENCH_SAMPLES=20`
  显式触发；
- raw result 写到 `results/phase1/<run>/w1-build-macrobench.jsonl`；
- input hash 写到 `results/phase1/<run>/w1-build-macrobench-inputs.sha256`；
- hard gate 只检查 rows 完整和 correctness 通过，`c2_supported` 仍为 false。

## 非目标

- 不在本步骤实现 W1 feature-equivalent baselines；
- 不修改 kernel ABI；
- 不新增 shell 脚本；
- 不把 W1 PoC 写成 C2 支持证据；
- 不把 W1/W2 合并成全局 C2 ledger，等 W3/W4 或收窄 C2 后再做。

## 拟复用代码路径

Runner：`tests/w1_oracle/namei_ext_w1_oracle.c`

可复用的现有 helper：

- `prepare_release_tree()`：复制真实 Redis/nginx source tree；
- `prepare_replay_toolchain()`：构造 toolchain alias；
- `prepare_replay_include()`：构造 include alias；
- `assign_build_replay_parent_dirs()`：填充 parent-aware map key；
- `populate_policy_map()`：填充 `build_graph_rules`；
- `prepare_replay_aliases()`：创建 visible alias placeholders；
- `run_redis_replay()` / `run_nginx_replay()`：运行真实 Redis/nginx 源码的
  preprocessing replay，并比较 baseline/policy preprocessed output。

Makefile：`mk/kvm.mk`

新增变量：

- `W1_BUILD_MACROBENCH_JSON`
- `W1_BUILD_MACROBENCH_INPUTS`
- `W1_BUILD_MACROBENCH_WORK_DIR`
- `W1_BUILD_MACROBENCH_SAMPLES`

新增 targets：

- `kvm-w1-build-macrobench`
- `__phase1_guest_w1_build_macrobench`

## Row schema

Proposed-system rows：

- `w1-build-macrobench-setup`
  - `sample`
  - `setup_ns`
  - `created_dirs`
  - `created_files`
  - `created_symlinks`
  - `bytes_copied`
  - `entries`
  - `workloads=2`
- `w1-build-macrobench-update`
  - `sample`
  - `update_ns`
  - `source_update_writes`
  - `policy_update_writes`
  - `update_bytes_written`
  - `update_bytes_copied`
  - 更新对象先限定为 generated/source/toolchain/include alias backing 的小集合；
    该 row 是 update materialization PoC，不代表完整 build graph churn。
- `w1-build-macrobench-correctness`
  - Redis baseline/policy preprocessing output match；
  - nginx baseline/policy preprocessing output match；
  - policy load/map_update/attach 通过；
  - `policy_executed=true`；
  - `kvm_validated=true`。
- `w1-build-macrobench-summary`
  - `samples`
  - `setup_rows`
  - `update_rows`
  - `correctness_rows`
  - `pass`
  - `failures`
  - `c2_supported=false`
  - `release_gate_pass=false`

## 正确性 oracle

每个 sample 复制一份真实 Redis/nginx source tree。runner 必须先在未 attach policy 时
对 Redis `src/server.c` 和 nginx `src/core/nginx.c` 生成 baseline preprocessed
output；随后在同一份 source tree 中 materialize trace-derived shadow aliases，attach
`build_graph_view.bpf.c`，再生成 policy preprocessed output，并做 byte-for-byte
比较。使用同一份 source tree 是必要约束，因为 Redis/nginx 构建会把源文件绝对路径嵌入
`__FILE__` 相关断言字符串；用 baseline/policy 两个临时目录比较会把目录名差异误报成
policy 语义失败。任何 preprocessing failure、output mismatch、policy
load/map/attach failure、输入缺失或 result write failure 都是 hard failure。

该 oracle 复用现有 `kvm_policy_build_replay_witness`，不是完整 release-binary build
oracle；因此即使 PoC 通过，仍必须记录 `c2_supported=false` 和
`release_gate_pass=false`。

## 设计约束

- Makefile-only orchestration；
- 不新增 `.sh`；
- KVM 是 Phase 1 validation path；
- policy 是 eBPF program，不引入 YAML/JSON/DSL policy；
- raw rows 只记录观测值，不在 runner 内做 paper interpretation；
- 该 PoC 不 silently skip Redis 或 nginx；两个 workload 都必须通过。

## 风险

- 真实 build 在 KVM 内可能较慢；默认 samples 应保持 1--2，release run 再调到 20。
- 当前 W1 alias set 是 sampled trace-derived，不是完整 build graph；因此该 PoC 只能支撑
  W1 setup/update plumbing，不能支撑 C1/C8。
- W1 baselines 还没做，后续仍需 copy/symlink/bind/projected/FUSE 或合理收窄 C2。
