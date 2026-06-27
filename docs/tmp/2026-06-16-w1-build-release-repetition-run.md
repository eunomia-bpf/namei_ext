# W1 build graph release repetition 运行记录

日期：2026-06-16

## 动机

W1 build graph 已有 1-sample KVM proposed-system setup/update PoC，但 OSDI 级 C2 至少需要
release repetition 级 raw input。此步骤把 W1 proposed-system 侧从 smoke PoC 提升到
20-sample KVM release input。它仍不是 C2 supported evidence，因为 W1 baselines、storage
footprint 和 threshold ledger 还未完成，W3/W4 对等 workload macrobench 也未完成。

## 命令

```text
make kvm-w1-build-macrobench RUN_ID=20260616T-w1-build-macrobench-release-sample-v1 W1_BUILD_MACROBENCH_SAMPLES=20
sha256sum -c results/phase1/20260616T-w1-build-macrobench-release-sample-v1/w1-build-macrobench-inputs.sha256
```

## 真实 workload 与来源

该 run 使用 Redis `7.2.14` 和 nginx `1.26.3` 真实 source build trace。项目 Makefile 从固定
tarball 和固定 SHA256 生成 workload provenance、build logs、strace `%file` trace 和 alias
manifest。

外部来源：

- Redis release tarball index：https://download.redis.io/releases/
- nginx source download index：https://nginx.org/download/
- Bazel sandboxing motivation：https://bazel.build/docs/sandboxing
- Bazel hermeticity motivation：https://bazel.build/basics/hermeticity

## 结果路径

```text
results/phase1/20260616T-w1-build-macrobench-release-sample-v1/
results/workloads/runs/20260616T-w1-build-macrobench-release-sample-v1/
```

核心 artifacts：

- `w1-build-macrobench.jsonl`
- `w1-build-macrobench-inputs.sha256`
- `dmesg-w1-build-macrobench.log`
- `w1-build-macrobench-work/`

空间占用：

- phase1 result root：约 `1.4G`
- workload run root：约 `381M`

## Gate 结果

Make target 在 KVM guest 内完成以下 gate：

- setup pass rows：20
- update pass rows：20
- correctness pass rows：20
- summary `pass=true`
- summary `failures=0`
- summary `policy_executed=true`
- summary `kvm_validated=true`
- summary `c2_supported=false`
- summary `release_gate_pass=false`
- guest 内 `sha256sum -c w1-build-macrobench-inputs.sha256` 通过

host 侧复验 `sha256sum -c` 也通过。

## Raw row 摘要

这些数值来自 `w1-build-macrobench.jsonl` 的 raw rows 直接聚合；低层 collector 本身没有
写 paper interpretation。

| Metric | Count | Min | Avg | Max |
|---|---:|---:|---:|---:|
| `setup_ns` | 20 | 55,341,631 | 66,090,011.6 | 86,325,968 |
| `source_copy_ns` | 20 | 18,046,955,215 | 20,842,324,052.55 | 23,272,621,195 |
| `update_ns` | 20 | 42,591,328 | 52,416,038.25 | 72,923,188 |
| `bytes_copied` setup | 20 | 457,356 | 457,356 | 457,356 |
| `update_bytes_copied` | 20 | 412,813 | 412,813 | 412,813 |

Summary row：

```text
samples=20
setup_rows=20
update_rows=20
correctness_rows=20
pass=true
failures=0
policy_executed=true
kvm_validated=true
c2_supported=false
release_gate_pass=false
```

## 正确性 oracle

每个 sample：

1. 复制同一份 Redis/nginx source tree；
2. 未 attach policy 时生成 Redis/nginx baseline preprocessing output；
3. materialize W1 trace-derived shadow aliases；
4. attach `build_graph_view.bpf.c`；
5. 生成 Redis/nginx policy preprocessing output，并与 baseline byte-for-byte 比较；
6. refresh shadow backing；
7. 再次运行 policy preprocessing，作为 update correctness oracle。

最后一个 sample 的 Redis/nginx output compare 都为 `pass=true`；summary 为 0 failure。

## Claim 影响

该 run 让 W1 proposed-system release repetition input 成立。可以写：

```text
W1 build graph proposed-system setup/update rows have 20-sample KVM release input.
```

仍不能写：

```text
W1 supports C2 materialization advantage.
Global C2 is supported.
```

剩余 W1/C2 缺口：

- W1 feature-equivalent baselines；
- W1 storage footprint aggregation；
- W1 setup/update/materialization threshold ledger；
- W3/W4 对等 workload macrobench；
- claim-level hard gate，防止 W1 release input 被误写成 C2 supported。
