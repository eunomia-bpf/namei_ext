# W1 build graph release repetition 设计

日期：2026-06-16

## 动机

W1 build graph 已有 `make kvm-w1-build-macrobench` 的 1-sample KVM proposed-system
PoC，但 OSDI 级 C2 不能用单样本 plumbing 支持。下一步必须先把 proposed-system 侧
提升到 release repetition，再补 feature-equivalent baselines 和 threshold ledger。

该步骤仍然不声明 C2 支持；它只补 W1 的 proposed-system release input。

## 真实 workload 来源

W1 选择 Redis `7.2.14` 和 nginx `1.26.3`，因为二者都是真实开源服务端软件，源码构建
会自然触发 generated output、declared source fallback、toolchain selection 和 external
dependency/include path resolution。

外部来源：

- Redis 官方 release tarball 索引包含 `redis-7.2.14.tar.gz`，时间和大小由上游下载站点
  暴露；项目内 `configs/eval-osdi/workload-sources.mk` 固定其 SHA256。
  来源：https://download.redis.io/releases/
- nginx 官方 download/source index 暴露 `nginx-1.26.3.tar.gz`；项目内同样固定 SHA256。
  来源：https://nginx.org/download/
- Bazel sandboxing 文档把 sandbox 目标描述为限制构建动作文件系统可见性，使 action
  working directory 只包含已知输入。这是 W1 build graph view 的真实系统动机，而不是
  人工 invented workload。
  来源：https://bazel.build/docs/sandboxing
- Bazel hermeticity 文档将 hermetic build 作为可复现、缓存和远程执行的前提，支撑 W1
  generated/source/toolchain/dependency path-resolution policy 的场景定位。
  来源：https://bazel.build/basics/hermeticity

## Claim mapping

- Claim：C2 setup/materialization cost。
- Block：B3-B6 workload macrobench。
- 本步骤能补强：W1 proposed-system KVM setup/update release repetition input。
- 本步骤不能补强：W1 feature-equivalent baseline、W1 storage/threshold verdict、C1/C8
  programmability necessity、全局 C2 supported verdict。

## 实验规范

命令：

```text
make kvm-w1-build-macrobench RUN_ID=20260616T-w1-build-macrobench-release-sample-v1 W1_BUILD_MACROBENCH_SAMPLES=20
```

输入：

- `results/workloads/runs/<run>/w1-build-graph-oracle-entries.tsv`
- Redis/nginx host source build and trace manifests；
- Redis/nginx alias manifests；
- `bpf/policies/build_graph_view.bpf.c` 和 `.build/bpf/build_graph_view.bpf.o`；
- `tests/w1_oracle/namei_ext_w1_oracle.c` 和 `.build/w1-oracle/namei_ext_w1_oracle`；
- `docs/tmp/2026-06-16-w1-build-macrobench-design.md`；
- `mk/kvm.mk`。

输出：

- `results/phase1/<run>/w1-build-macrobench.jsonl`
- `results/phase1/<run>/w1-build-macrobench-inputs.sha256`
- `results/phase1/<run>/dmesg-w1-build-macrobench.log`

Gate：

- setup rows = 20；
- update rows = 20；
- correctness rows = 20；
- summary `pass=true`；
- summary `failures=0`；
- summary `policy_executed=true`；
- summary `kvm_validated=true`；
- summary `c2_supported=false`；
- summary `release_gate_pass=false`；
- host 侧重新执行 `sha256sum -c w1-build-macrobench-inputs.sha256` 必须通过。

## 正确性 oracle

每个 sample 使用同一份 Redis/nginx source tree。runner 先在未 attach policy 时生成
baseline preprocessed output，再 materialize W1 trace-derived shadow aliases，attach
`build_graph_view.bpf.c`，生成 policy preprocessed output 并 byte-for-byte 比较。随后刷新
shadow backing，再次执行 policy preprocessing，作为 update correctness oracle。

该 oracle 是 preprocessing replay oracle，不是完整 release-binary rebuild oracle。已有
`kvm-w1-release-build-replay` 覆盖 release binary witness，但本步骤不把二者合并成
C8 或 C2 支持结论。

## OSDI 级限制

即使 20 samples 全部通过，也只能说明 W1 proposed-system release repetition input 存在。
OSDI 级 C2 仍至少需要：

1. W1 同 workload feature-equivalent baselines；
2. W1 storage footprint aggregation；
3. W1 setup/update/materialization threshold；
4. W3/W4 对等 setup/update workload macrobench；
5. claim-level ledger 和 expected-fail hard gate，防止 partial input 被误写为 supported。

## 风险

- 每个 sample 会复制真实 Redis/nginx source tree，20 samples 可能耗时较长并占用较多
  result/work directory 空间。
- 当前 W1 entries 是 trace-witness 候选集合，不是完整 trace-derived alias set；这会继续限制
  C1/C8。
- `v1` 曾暴露 Redis 绝对源码路径 false negative；当前 runner 已改为同一 source tree replay，
  但后续若改回双树比较必须重新处理 `__FILE__` path normalization。
