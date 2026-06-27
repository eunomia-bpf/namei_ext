# W1 KVM path oracle 实现记录

日期：2026-06-14

## 背景和目标

前一阶段已经能从 Redis `7.2.14` 和 nginx `1.26.3` 的真实源码构建中生成
host-side trace-witness manifest，但这些 manifest 明确标记
`policy_executed=false`、`kvm_validated=false` 和 `output_hash_oracle=false`。
它们只能证明候选 alias/backing 条目来自真实 trace，不能证明修改后的 kernel 和
eBPF policy 在 KVM guest 中真的执行这些 path-resolution 决策。

本步骤目标是补一个最小、Makefile-owned 的 W1 path oracle：

- 从现有 Redis/nginx alias manifests 生成固定 TSV 输入；
- 在 KVM guest 中为每个 entry 建独立 synthetic directory，并 materialize shadow backing files；
- 使用真实 `cgroup/namei_ext` attach path 加载 `build_graph_view.bpf.c`；
- 使用同一批 entries 跑 `table_redirect.bpf.c` 作为 table-only path baseline；
- 检查 lookup 和 readdir 语义，不把该结果冒充完整 build output oracle。

## 调研和代码路径

本步骤调研和复用的路径：

- `mk/workload.mk`：W1 workload run root、alias manifest 生成规则和 Makefile-only
  workflow；
- `bpf/policies/build_graph_view.bpf.c`：`build_graph_rules` map、硬编码
  `cc -> cc.real` fast path、lookup/readdir event handling；
- `bpf/policies/table_redirect.bpf.c`：`exact_redirects` map 和 table-only baseline；
- `bpf/include/namei_ext_policy.h`：map key/value layout；
- `tests/policy_semantic/namei_ext_policy_semantic.c`：现有 libbpf load/attach/detach
  runner 风格；
- `kernel/tools/testing/selftests/bpf/cgroup_helpers.c`：用 `name_to_handle_at()` 获取
  cgroup id 的方法；
- `mk/kvm.mk` 和 `mk/report.mk`：KVM guest target 和 Phase 1 report gate。

关键 kernel 约束是 `namei_ext` ctx 中的 `cgroup_id` 来自当前 task 的 default
cgroup。runner 因此解析 `/proc/self/cgroup`，再用 cgroup v2 path 的 file handle
获取当前 cgroup id，用它填充 BPF map key。

## 实现内容

新增或修改：

- `mk/workload.mk`
  - 新增 `workload-w1-oracle-entries`；
  - 从 Redis/nginx alias manifests 生成
    `results/workloads/runs/<run-id>/w1-build-graph-oracle-entries.tsv`；
  - TSV 包含 workload、branch、parent、visible、shadow、original backing path 和
    backing SHA256；
  - 生成时 fail-fast 校验行数、列数、源文件存在性和 SHA256。
- `tests/w1_oracle/Makefile`
  - 编译 `namei_ext_w1_oracle`，复用 kernel tree 的 libbpf。
- `tests/w1_oracle/namei_ext_w1_oracle.c`
  - 读取 TSV；
  - 在 `/tmp/namei-ext-w1-*` 下为每个 entry 建独立目录；
  - 复制真实 backing 文件作为 shadow；
  - 加载并填充 `build_graph_view.bpf.o` 和 `table_redirect.bpf.o` 的 map；
  - attach 到 `/sys/fs/cgroup`；
  - 对每个 entry 检查：
    - attach 前 alias 不存在；
    - attach 后 alias lookup 读取内容等于 effective backing；
    - readdir 可见 alias，且隐藏当前 policy 的 backing；
    - detach 后 alias 不再解析；
  - 写 raw JSONL，不计算论文结论；
  - JSONL 字符串字段统一转义，pre/post attach 的 alias-absent 失败记录实际
    checker errno，避免 raw artifact 中出现不可诊断的 `errno=0` 失败。
- `mk/kvm.mk`
  - 新增 `kvm-w1-oracle` 和 `__phase1_guest_w1_oracle`；
  - guest 内挂载 bpffs/debugfs/cgroup2，检查 TSV、alias manifest、policy source、
    policy object 和 runner 存在；
  - 在 guest 内重新校验 TSV 中 original backing path 的 SHA256；
  - 写出 `w1-oracle-inputs.sha256`，覆盖 TSV、Redis/nginx alias manifests、
    policy source、policy object、runner source 和 runner binary。
- `Makefile`
  - 新增 `w1-oracle`；
  - `phase1-smoke` 构建 runner；
  - `phase1` 纳入 `kvm-w1-oracle`。
- `mk/report.mk`
  - `report` 新增 `w1-oracle.jsonl` hard gate；
  - `report` 新增 `w1-oracle-inputs.sha256` hard gate，并运行 `sha256sum -c`；
  - `report` 机器检查 W1 sha 清单的固定 9 项路径集合，以及 `w1-oracle-input`
    指向 `w1-oracle-inputs.sha256`；
  - 要求 0 个 W1 failed case、2 个 passing policy summary、1 个 passing run summary；
  - 机器检查所有 `w1-oracle*` lifecycle/case/meta/summary/input events 都带
    `result_level=kvm_policy_path_oracle`、两个固定 policy、9 entries 和
    `qualified_for_c8=false`；
  - summary 中新增 W1 Path Oracle Cases 表。

## 设计选择

1. TSV 是 workload witness/materialization 输入，不是 policy 配置语言。
   Policy 仍然是 `bpf/policies/*.bpf.c` 下的 eBPF 程序。TSV 只连接真实 trace
   evidence 和 KVM materialization。
2. 每个 candidate entry 使用独立临时目录，避免 Redis/nginx 中重复的 `cc`、
   `stdio.h` 互相干扰。
3. `build_graph_view.bpf.c` 对 `cc` 有硬编码 `cc -> cc.real`，而 trace witness
   table entry 是 `cc -> gcc`。runner 显式记录 `shadow=gcc` 和
   `effective_shadow=cc.real`，table baseline 仍使用 `gcc`。
4. 该 gate 的 result level 是 `kvm_policy_path_oracle`，summary 保持
   `qualified_for_c8=false`。它验证真实 trace-derived entries 的 path-resolution
   语义，但不验证完整 Redis/nginx build output hash，也不证明 table/update budget
   失败。

## 被拒绝的替代方案

- 不把 W1 oracle 做成 host-only runner。Phase 1 validation 必须在修改后的 kernel
  KVM guest 内运行。
- 不用 bpftool object inspection 替代真实 attach。该项目要求功能测试和 benchmark
  走真实 `cgroup/namei_ext` attach path。
- 不引入 shell runner。项目控制平面必须是 Makefile-only。
- 不把 YAML/JSON/DSL 作为 policy。eBPF policy object 是唯一 policy 实体。
- 不把本 gate 标成 C8。当前还缺完整 workload oracle、poison/negative real trace 和
  table/update budget counterfactual。

## 验证结果

本步骤完成的验证：

```text
make workload-w1-oracle-entries RUN_ID=20260614T-workloads-git-ceiling
make w1-oracle RUN_ID=20260614T-workloads-git-ceiling
make kvm-w1-oracle RUN_ID=20260614T-workloads-git-ceiling
make phase1 RUN_ID=20260614T-workloads-git-ceiling SAMPLES=1 BENCH_ITERS=2000
```

关键 raw artifacts：

- `results/workloads/runs/20260614T-workloads-git-ceiling/w1-build-graph-oracle-entries.tsv`
- `results/phase1/20260614T-workloads-git-ceiling/w1-oracle.jsonl`
- `results/phase1/20260614T-workloads-git-ceiling/w1-oracle-inputs.sha256`
- `results/phase1/20260614T-workloads-git-ceiling/dmesg-w1-oracle.log`
- `results/phase1/20260614T-workloads-git-ceiling/summary.md`

结果摘要：

- W1 TSV：9 条 entries，源 backing path 和 SHA256 校验通过；
- KVM W1 oracle：`build_graph` 9 entries，0 failure；
- KVM W1 oracle：`table_redirect` 9 entries，0 failure；
- W1 run summary：2 policies，9 entries，0 failure；
- W1 input provenance：TSV、Redis/nginx alias manifests、policy source、policy
  object、runner source 和 runner binary 的 SHA256 已写入
  `w1-oracle-inputs.sha256`，report 运行 `sha256sum -c` 并校验固定 9 项路径集合；
- phase1 summary：guest smoke、ABI、policy-load、policy-semantic、
  table-conformance、W1 oracle、functional、bench、Docker 和 dmesg gates 均为 0
  failure；
- dmesg warning/oops/panic lines：0。

## 剩余风险和后续工作

- W1 仍是 path oracle，不是完整 build output oracle。下一步需要在 KVM guest 内运行
  Redis/nginx build 或 trace replay，并比较 build output hash。
- 当前 W1 entries 是手工候选 + trace witness，不是完整 trace parser 输出。
- W1 真实 trace 只覆盖 generated/source/toolchain/external-dep；undeclared poison 和
  negative fallback 还需要真实 workload probe 或明确 appendix/functional-only 处理。
- `table_redirect.bpf.c` 在本 path oracle 下通过，因此当前结果不能支撑 C8。C8 仍需要
  同等 table/update budget 下的 failure、over-materialization、stale window 或 oracle
  violation 证据。
- W2/W3/W4 还没有对应 KVM workload oracle。
