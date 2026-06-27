# W1 build graph feature baseline 与 threshold ledger 设计

## 背景

W1 build graph 已经有 `make kvm-w1-build-macrobench` 的 20-sample KVM
proposed-system release input。该 run 证明修改后的内核、`cgroup/namei_ext`
attach、`build_graph_view.bpf.c`、Redis/nginx release source preprocessing oracle 和
post-update shadow refresh 能一起跑通，但它还不是 C2 结论。C2 需要同 workload 的
feature-equivalent baseline、storage/update accounting 和 threshold ledger。

本步骤补 W1 的第一批 feature baseline，使 W1 和 W2 一样具有 proposed-system rows
之外的 baseline rows。设计必须保守：runner 只写 raw observations，jq ledger 再做
门控；在 FUSE/projected-volume、W3/W4 macrobench 未补齐前，全局 `c2_supported` 和
`release_gate_pass` 必须保持 `false`。

## 研究问题

RQ-W1-BL：对于真实 Redis 和 nginx release source preprocessing workload，`namei_ext`
的 programmable path-resolution 能否用比常见物化方案更少的 setup/update materialization
来表达 build graph view，同时保持输出等价？

该问题拆为三类证据：

1. correctness：每个 baseline sample 必须运行同一组 Redis/nginx preprocessing oracle，
   并与 baseline output byte-for-byte 一致。
2. setup/storage：记录 source tree copy、额外目录、文件、symlink、bind mount、
   bytes copied/written。
3. update：记录 source update、baseline materialization update、policy update 和
   update bytes。copy baseline 必须重新复制可见 alias；symlink/bind baseline 应该只更新
   backing 文件，除非底层语义要求重新物化。

## Baseline 范围

本步实现三类 W1 baseline：

- `copy_tree`：把需要被 path resolution 看到的 visible name 实体化为普通文件。外部
  include (`stdio.h`) 被复制到 replay include directory；source-tree visible files 保持
  普通文件；toolchain `cc` 由 replay toolchain 中的 `cc -> cc.real -> /usr/bin/gcc`
  表达。
- `symlink_forest`：visible name 用 symlink 指向对应 backing name。该形态模拟构建系统、
  包管理器或 sandbox 常见的 symlink forest view。
- `bind_mount`：visible name 用 per-file bind mount 指向 backing name。该形态模拟不复制
  文件内容但依赖内核 mount table 的物化方案。

暂不把 `fuse_redirect` 和 projected-volume 计入 W1 C2 slice。原因是 W1 包含多个 source
subtree、toolchain directory 和 include directory；FUSE/projected-volume 需要覆盖多个
lookup parents，和 W2 的单一 nginx `conf/` 目录不同。缺口会由 ledger 明确记录，而不是
通过 `skipped` 或 partial success 隐藏。

## 运行路径

新增 Make target：

```text
make kvm-w1-build-baseline-macrobench \
  RUN_ID=<run> \
  W1_BUILD_BASELINE_MACROBENCH_SAMPLES=20 \
  W1_BUILD_BASELINES='copy_tree symlink_forest bind_mount'
```

该 target 在 KVM guest 内执行：

1. 校验 Redis/nginx workload manifests、alias manifests、oracle TSV、runner source 和
   runner binary。
2. 写 `w1-build-baseline-macrobench-inputs.sha256`。
3. 调用 `namei_ext_w1_oracle --w1-build-baseline-macrobench`。
4. 校验每个 baseline 都有 `samples` 条 setup/update/correctness pass rows。
5. 写 `dmesg-w1-build-baseline-macrobench.log`。

所有 orchestration 均在 Makefile 中；不新增项目自有 shell script。

## Runner 设计

Runner 复用 W1 proposed-system macrobench 的源树复制、entries TSV 读取、toolchain/include
helper、Redis/nginx preprocessing command 和 file comparison oracle。区别是 baseline
mode 不加载、不 attach eBPF program。

每个 baseline/sample 输出：

- `w1-build-baseline-setup`
- `w1-build-baseline-update`
- `w1-build-baseline-correctness`
- `w1-build-baseline-summary`

每条 row 都包含：

- `run_environment="kvm"`
- `workload="w1-build-graph"`
- `policy_executed=false`
- `feature_equivalent_baseline=true`
- `kvm_validated=true`
- `c2_supported=false`
- `release_gate_pass=false`

Correctness oracle：

1. source tree copy 后先运行 Redis/nginx baseline preprocessing，生成 reference output。
2. baseline materialization 后用 policy-mode argv 但不 attach policy，确保 ordinary VFS
   lookup 能解析相同 visible names。
3. update 后再次运行 preprocessing，并与 reference output 比较。

## Ledger 设计

新增 W1 workload ledger filter 读取：

- proposed-system JSON：`w1-build-macrobench.jsonl`
- baseline JSON：`w1-build-baseline-macrobench.jsonl`

ledger 计算：

- proposed release input gate：samples、setup/update/correctness rows、summary pass。
- baseline release input gate：每个 observed baseline 的 setup/update/correctness rows。
- storage footprint gate：proposed setup objects/bytes 不高于 observed baselines 的最小值。
- setup latency gate：proposed average setup latency 不高于最快 observed baseline。
- update materialization gate：proposed update writes/bytes 不高于 observed baselines 的最小值。

本步 ledger 的 W1 slice 仍不应自动变成完整 C2，除非 future step 明确把 required baseline
families 扩展并跑通 FUSE/projected-volume 或给出可审计的排除理由。全局 C2 还依赖 W3/W4
KVM per-sample setup/storage/update macrobench。

## 风险和后续

- `bind_mount` 需要 guest root 和支持 file bind mount；失败必须使 owning target 失败。
- W1 `copy_tree` 对 source-tree visible file 的额外 materialization 可能低估全树物化成本；
  ledger 解释必须把 `source_copy_ns` 和 `source_copy_bytes` 作为独立 raw metric 保留。
- FUSE/projected-volume 是 W1 的后续 baseline family，不在本步里伪装为 pass。
- 旧 `20260616T-w1-build-macrobench-release-sample-v1` input hash 只代表当时源树；修改 runner
  或 Makefile 后不能复用该 hash 作为当前源码验证。
