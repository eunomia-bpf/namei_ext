# W2 nginx storage/threshold ledger 设计记录

日期：2026-06-16

## 动机

W2 nginx workload 已有：

- `namei_ext` proposed-system 20-sample KVM setup/update/correctness raw rows；
- 同 workload `copy_tree`、`symlink_forest`、`bind_mount`、`projected_volume` 和
  `fuse_redirect` 五类 feature baseline 20-sample KVM raw rows；
- W2 claim-level expected-fail ledger。

v4 ledger 仍把 `storage_footprint_pass=false` 和 `threshold_pass=false` 写死，因此它只能说明
五类 baseline input 已存在，不能回答 C2 reviewer 会问的两个问题：

1. `namei_ext` 是否真的减少或不增加 materialized filesystem footprint？
2. 当前 W2 数据是否满足一个明确、可复查的 setup/update 成功阈值？

这一步只解决 W2 slice 的 C2 input gate，不升级全局 C2。全局 C2 仍需要 W1/W3/W4 对等
workload macrobench。

## 已检查代码和数据

- `mk/eval_osdi.mk`：`eval-osdi-w2-nginx-workload-macrobench-ledger` 读取 proposed-system
  与 baseline JSONL，并写出 W2 summary。
- `tests/w1_oracle/namei_ext_w1_oracle.c`：W2 raw rows 已包含 `setup_ns`、`update_ns`、
  `created_dirs`、`created_files`、`created_symlinks`、`bind_mounts`、`fuse_mounts`、
  `bytes_written`、`bytes_copied`、`source_update_writes`、`baseline_update_writes`、
  `policy_update_writes`、`update_bytes_written` 和 `update_bytes_copied`。
- `results/phase1/20260615T-w2-nginx-c2-macrobench-release-sample-v1/w2-nginx-macrobench.jsonl`
  proposed-system rows：setup objects 为 17，setup bytes 为 5931，policy update writes 为 0。
- `results/phase1/20260616T-w2-nginx-baseline-macrobench-release-sample-v4/w2-nginx-baseline-macrobench.jsonl`
  baseline rows：五类 baseline setup objects 为 19 到 30；setup bytes 最小为 5931；
  copy/projected baseline 有额外 update writes/bytes，symlink/bind/FUSE 与 proposed-system
  一样无需 baseline-side update writes。

## 阈值定义

W2 ledger 新增一组只由 raw rows 派生的阈值：

- `storage_footprint_pass`：
  - proposed-system 平均 setup objects 不大于五类 baseline 中最小平均 setup objects；
  - proposed-system 平均 setup bytes 不大于五类 baseline 中最小平均 setup bytes。
- `setup_latency_threshold_pass`：
  - proposed-system 平均 `setup_ns` 不大于五类 baseline 中最小平均 `setup_ns`。
- `update_latency_threshold_pass`：
  - proposed-system 平均 `update_ns` 不大于五类 baseline 中最小平均 `update_ns`。
- `update_materialization_threshold_pass`：
  - proposed-system 平均 total update writes 不大于五类 baseline 中最小平均 total update writes；
  - proposed-system 平均 policy-side update writes 不大于五类 baseline 中最小 baseline-side update writes；
  - proposed-system 平均 update bytes 不大于五类 baseline 中最小平均 update bytes。
- `threshold_pass`：
  - setup latency、update latency 和 update materialization 三项全通过。
- `w2_c2_slice_supported`：
  - proposed-system release input、baseline release input、五类 baseline、storage footprint 和
    threshold 全通过。

`c2_supported` 和 `release_gate_pass` 仍保持 false，因为这个 target 只覆盖 W2，不覆盖
W1/W3/W4。summary 的 `missing_evidence` 在 W2 slice 通过后应只列出
`W1/W3/W4 workload setup/storage/update macrobench`。

## 设计选择

- 不修改 KVM guest runner：已有 raw rows 足够表达 setup/storage/update footprint；避免扩大
  guest-side C 代码。
- 使用 Makefile-owned `jq` filter：不新增 shell script；Make target 仍是唯一入口。把巨型
  inline jq 拆到 `configs/eval-osdi/w2-nginx-workload-macrobench.jq`，便于 code review 和后续
  阈值审计。
- filter 文件纳入 input sha256：阈值逻辑变化会使 ledger provenance 变化。
- 不把 W2 slice 写成全局 C2：避免把单一 workload 的正结果误写成 OSDI C2 claim。

## 拒绝的替代方案

- 只在 Markdown 里解释 v4 raw rows：不可审计，无法让 Make gate 机械化。
- 修改 guest runner 加 `du` 或 filesystem block usage：当前 raw bytes/object/write 已能覆盖
  W2 C2 的 materialization footprint；block usage 会引入 filesystem allocation 噪声，留给
  后续 release storage experiment。
- 让 W2 hardgate 通过并设置 `c2_supported=true`：会把单 workload slice 误升级成全局 C2。

## 验证计划

1. 运行 `make eval-osdi-w2-nginx-workload-macrobench-ledger` 生成 v5 ledger。
2. 检查 summary 中 `storage_footprint_pass=true`、`threshold_pass=true`、
   `w2_c2_slice_supported=true`，但 `c2_supported=false` 和 `release_gate_pass=false`。
3. 运行 `make eval-osdi-w2-nginx-workload-macrobench` 并确认它仍按预期非零退出。
4. 校验 v5 ledger/hardgate input sha256。
5. 运行 `make w1-oracle`、`make -C docs/paper check`、`make -C docs/paper paper` 和
   `git diff --check`。
