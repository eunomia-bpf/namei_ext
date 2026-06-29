# W3/W4 KVM Path Oracle 实现记录

> 2026-06-29 baseline scope update: this historical record preserves prior reasoning and results. Current C8/B12 guidance is claim-driven baseline selection; exact-map diagnostics are optional boundary evidence only when precomputed mapping is the competing claim.

日期：2026-06-14

## 动机

Phase 1 已经有 W1 build-graph 和 W2 sandbox-fixture 的 KVM path oracle，但 W3
checkpoint/restore 和 W4 cache-locality 仍停留在计划文档中。为了让四类 policy family
都至少通过真实修改内核中的 `cgroup/namei_ext` attach path，本步骤补齐 W3/W4 的
最小 KVM path oracle。

本步骤的目标不是声称已经完成真实 CRIU restore、真实 ccache/BuildKit workload 或 C8
table/update budget。当前目标更窄：把真实来源固定到 provenance 和 manifest，生成
可审计的 witness entries，并在 KVM guest 中用对应 eBPF policy 与 `table_redirect.bpf.c`
跑同一组 lookup/readdir oracle。

## 调研和检查的代码路径

实现前检查了以下路径：

- `bpf/policies/checkpoint_restore_view.bpf.c`：确认 W3 policy object 已有 literal POC
  分支和 `checkpoint_rules` map。
- `bpf/policies/cache_locality_view.bpf.c`：确认 W4 policy object 已有 literal POC
  分支和 `cache_rules` map。
- `bpf/include/namei_ext_policy.h`：确认 user/kernel 共享的 policy key、value 和 event
  常量。
- `tests/w1_oracle/namei_ext_w1_oracle.c`：确认现有 W1/W2 runner 可以复用真实
  attach、lookup、readdir、detach 路径。
- `mk/workload.mk`：确认 workload manifest、TSV 和 provenance 生成位置。
- `mk/kvm.mk`：确认 KVM guest 调用、结果目录、输入哈希和 dmesg 采集模式。
- `mk/report.mk`：确认 Phase 1 summary hard gates 和 raw artifact 校验模式。
- `Makefile`：确认 `phase1` 和 help 中的顶层 target 组织方式。

## 设计选择

W3/W4 采用和 W1/W2 相同的最小 oracle 结构：

1. Host side Make target 生成 witness manifest 和合并 TSV。
2. KVM target 把 TSV、manifest、policy source/object、runner source/binary 都纳入
   `*-oracle-inputs.sha256`。
3. Guest 内为每个 entry 创建独立 synthetic directory，materialize backing file，
   attach policy，检查 lookup 内容、readdir visible set 和 detach 后不可达。
4. 同一组 entries 同时跑主 policy 和 `table_redirect.bpf.c`。
5. JSONL summary 必须记录 `qualified_for_c8=false`。

选择这个路径的原因是 Phase 1 的硬要求是“改过的内核在 KVM 里跑通”。Host manifest 只能
证明输入固定，不能证明 policy 沿真实 kernel attach path 运行；KVM path oracle 可以填补
这个缺口，同时不把尚未完成的真实 workload oracle 伪装成发布级结果。

## 拒绝的替代方案

- 不把 W3/W4 写成 YAML/JSON/DSL policy。policy 仍然是
  `bpf/policies/*.bpf.c` 下的 eBPF 程序；JSON 只作为结果和 witness manifest。
- 不增加项目自有 shell 脚本。所有入口都通过 Make target。
- 不把 host manifest 当作 KVM evidence。manifest 的 `policy_executed=false` 和
  `kvm_validated=false` 保留，真正的 KVM evidence 只来自 `w3-oracle.jsonl` 和
  `w4-oracle.jsonl`。
- 不把 table baseline 失败写成事实。当前 `table_redirect.bpf.c` 在 W3/W4 path oracle
  上通过，因此它是反 C8 的证据，后续必须用真实 workload oracle 和 budget gate 重新证明。
- 不实现真实 CRIU/Podman、ccache 或 BuildKit runner，因为这会引入更大的依赖面；
  当前步骤只交付最小 KVM path oracle。

## 实现内容

`tests/w1_oracle/namei_ext_w1_oracle.c` 增加了两个 runner mode：

- `--checkpoint-restore OUT_JSONL CGROUP_MOUNT ENTRIES_TSV CHECKPOINT_POLICY TABLE_POLICY`
- `--cache-locality OUT_JSONL CGROUP_MOUNT ENTRIES_TSV CACHE_POLICY TABLE_POLICY`

runner 复用同一 attach/path/readdir/detach 流程。W3 主 policy 名称为
`checkpoint_restore`，W4 主 policy 名称为 `cache_locality`；两者都和
`table_redirect` 运行同一组 entries。对 W3/W4 主 policy，runner 依赖 BPF 程序中的
literal POC 分支；table baseline 仍填充 map。

`mk/workload.mk` 新增了以下 Make targets：

- `workload-checkpoint-restore`
- `workload-redis-checkpoint-manifest`
- `workload-nginx-checkpoint-manifest`
- `workload-w3-oracle-entries`
- `workload-cache-locality`
- `workload-ccache-manifest`
- `workload-buildkit-manifest`
- `workload-w4-oracle-entries`

W3 当前生成 7 个 checkpoint witness entries：

- Redis：`dump.rdb`、`appendonly.aof`、`redis.sock`、`epoch.bad`
- nginx：`nginx.conf`、`cache.db`、`nginx.pid`

W4 当前生成 4 个 cache witness entries：

- ccache/Redis/nginx：`object.o`、`stale.o`、`corrupt.o`
- BuildKit/Prometheus：`pkg.mod`

`mk/kvm.mk` 新增：

- `kvm-w3-oracle`
- `kvm-w4-oracle`
- `__phase1_guest_w3_oracle`
- `__phase1_guest_w4_oracle`

这两个 KVM targets 会校验 manifest/TSV/policy/runner 文件存在、校验 TSV 中所有
original backing SHA256、写入固定输入哈希清单，并保存 `dmesg-w3-oracle.log` 与
`dmesg-w4-oracle.log`。

`mk/report.mk` 新增 W3/W4 hard gates：

- `w3-oracle.jsonl`、`w4-oracle.jsonl` 必须存在。
- `w3-oracle-inputs.sha256`、`w4-oracle-inputs.sha256` 必须通过 `sha256sum -c`。
- 输入哈希清单必须正好包含 TSV、manifest、policy source/object、table source/object、
  runner source/binary。
- W3 summary 必须有 2 条、entries 必须为 7、policy set 必须是
  `checkpoint_restore` 与 `table_redirect`。
- W4 summary 必须有 2 条、entries 必须为 4、policy set 必须是
  `cache_locality` 与 `table_redirect`。
- W3/W4 summary 都必须 `qualified_for_c8=false` 且 0 failure。

顶层 `Makefile` 的 `phase1` 现在包含 `kvm-w3-oracle` 和 `kvm-w4-oracle`，help
也列出对应 targets。

## 验证

已运行并通过：

```text
make workload-w3-oracle-entries workload-w4-oracle-entries RUN_ID=20260614T-workloads-git-ceiling
make kvm-w3-oracle kvm-w4-oracle RUN_ID=20260614T-workloads-git-ceiling
make kvm-w1-oracle kvm-w2-oracle report RUN_ID=20260614T-workloads-git-ceiling SAMPLES=1 BENCH_ITERS=2000
```

关键 raw artifacts：

- `results/workloads/runs/20260614T-workloads-git-ceiling/w3-checkpoint-oracle-entries.tsv`
- `results/workloads/runs/20260614T-workloads-git-ceiling/w4-cache-oracle-entries.tsv`
- `results/phase1/20260614T-workloads-git-ceiling/w3-oracle.jsonl`
- `results/phase1/20260614T-workloads-git-ceiling/w4-oracle.jsonl`
- `results/phase1/20260614T-workloads-git-ceiling/w3-oracle-inputs.sha256`
- `results/phase1/20260614T-workloads-git-ceiling/w4-oracle-inputs.sha256`
- `results/phase1/20260614T-workloads-git-ceiling/summary.md`

当前 W3 summary：`checkpoint_restore` 和 `table_redirect` 各 7 个 entries，0 failure，
`qualified_for_c8=false`。

当前 W4 summary：`cache_locality` 和 `table_redirect` 各 4 个 entries，0 failure，
`qualified_for_c8=false`。

## 剩余风险和后续工作

W3/W4 现在只是 functional path-oracle witness，不能计入 C1/C8。主要缺口如下：

- W3 没有真实 Podman/CRIU restore、checkpoint archive hash、post-restore VFS trace、
  health check、state/config/cache hash oracle 或 0 mixed epoch oracle。
- W4 没有真实 ccache/BuildKit run、compiler/go output hash、cache transition trace、
  stale/corrupt reject oracle、update writes 或 stale-window measurement。
- `table_redirect.bpf.c` 在当前 W3/W4 path oracle 上通过，所以当前证据不能证明需要
  eBPF programmable logic。后续必须在真实 workload oracle 和同等 table/update budget
  下证明 table-only 失败、过度物化或违反 stale/update 门槛。
- W3/W4 manifest 中的 fixtures 绑定了真实 source provenance，但它们仍是 Make-owned
  witness 文件，不是生产 workload 原生生成的 checkpoint/cache artifacts。
