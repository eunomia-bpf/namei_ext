# W4 ccache rule macrobench 实现记录

日期：2026-06-16

## 动机

本步骤实现 `2026-06-16-w4-ccache-rule-macrobench-design.md` 中定义的 W4
setup/update raw-input path。目标是让 W4 ccache workload 不再只停留在 correctness 和
table-only counterfactual witness，而是能通过 Makefile-owned KVM target 产出重复 sample 的
setup/update/correctness rows。

该结果不升级 C2/C8 claim。当前 W4 trace 的 cache objects 分布在 4 个不同 parent 中，因此
parent-scoped policy 和 exact table baseline 的 lookup rule writes 在 setup 上相同；总 rule
writes 也相同。这是负面或 mixed evidence，必须保留。

## 修改文件

- `tests/w1_oracle/namei_ext_w1_oracle.c`
  - 新增 `--ccache-rule-macrobench` runner 模式；
  - 新增 `w4-ccache-rule-macrobench-{setup,update,correctness,summary}` JSONL rows；
  - 每个 sample 分别执行：
    - proposed-system：`cache_locality_view.bpf.c` parent-rule policy；
    - feature baseline：`table_redirect.bpf.c` exact-rule table baseline；
  - 每个系统都在 KVM 中 load、populate map、attach policy，执行 lookup/readdir oracle，追加一个
    sample-local ccache object，更新规则，再检查 post-detach alias absent。
- `mk/kvm.mk`
  - 新增 `W4_CCACHE_RULE_MACROBENCH_*` 变量；
  - 新增 `kvm-w4-ccache-rule-macrobench` 和
    `__phase1_guest_w4_ccache_rule_macrobench` targets；
  - target 依赖 `kvm-w4-ccache-policy-bridge`，确保 entries 来自真实 ccache trace；
  - target 写出 `w4-ccache-rule-macrobench-inputs.sha256` 并在 guest 中复验。
- `Makefile`
  - `make help` 增加 `kvm-w4-ccache-rule-macrobench` 入口。
- `docs/tmp/2026-06-16-w4-ccache-rule-macrobench-design.md`
  - 新增本步骤设计记录。

## 验证命令

编译 runner：

```text
make w1-oracle
```

KVM smoke：

```text
make kvm-w4-ccache-rule-macrobench \
  RUN_ID=20260616T-w4-ccache-rule-macrobench-smoke-v1 \
  W4_CCACHE_RULE_MACROBENCH_SAMPLES=1
```

input hash 复验：

```text
sha256sum -c \
  results/phase1/20260616T-w4-ccache-rule-macrobench-smoke-v1/w4-ccache-rule-macrobench-inputs.sha256
```

## Smoke 结果

结果文件：

- `results/phase1/20260616T-w4-ccache-rule-macrobench-smoke-v1/w4-ccache-rule-macrobench.jsonl`
- `results/phase1/20260616T-w4-ccache-rule-macrobench-smoke-v1/w4-ccache-rule-macrobench-inputs.sha256`
- `results/phase1/20260616T-w4-ccache-rule-macrobench-smoke-v1/dmesg-w4-ccache-rule-macrobench.log`

summary：

- `samples=1`
- `systems=2`
- `setup_rows=2`
- `update_rows=2`
- `correctness_rows=2`
- `pass=true`
- `failures=0`
- `policy_executed=true`
- `kvm_validated=true`
- `c2_supported=false`
- `release_gate_pass=false`

proposed-system row：

- `system=parent_rule_policy`
- `setup_ns=102802203`
- `created_dirs=4`
- `created_files=4`
- `bytes_copied=21171`
- `cache_objects=4`
- `cache_leaf_parents=4`
- `lookup_rule_writes=4`
- `readdir_rule_writes=4`
- `total_rule_writes=8`
- `update_ns=5662438`
- `policy_update_writes=2`
- `update_total_rule_writes=2`

table baseline row：

- `system=table_redirect`
- `setup_ns=90480593`
- `created_dirs=4`
- `created_files=4`
- `bytes_copied=21171`
- `cache_objects=4`
- `cache_leaf_parents=4`
- `lookup_rule_writes=4`
- `readdir_rule_writes=4`
- `total_rule_writes=8`
- `update_ns=5057563`
- `baseline_update_writes=2`
- `update_total_rule_writes=2`

## 解释

这个 smoke 证明新的 infrastructure 能在修改内核 KVM 中跑通真实 ccache trace-derived entries
的 rule setup/update path。它同时证明当前 sampled W4 trace 不是 C2 正结果：

- parent policy 与 table baseline 的 setup materialization 相同；
- parent policy 与 table baseline 的 setup total rule writes 相同；
- parent policy 与 table baseline 的 update rule writes 相同；
- 1-sample smoke 中 table baseline setup/update 还更快。

因此本步骤只能消除 “W4 没有 KVM setup/update runner” 这个工程缺口。后续仍需要：

- 20-sample release run；
- W4 workload ledger，把 W4 raw rows 接入 C2 claim accounting；
- 如果要支持 C8，需要真实 same-parent cache object shape、operation-weighted release hit rate、
  stale/corrupt transition 或 table-only failure/over-budget evidence。

## 剩余风险

- 上述 smoke sample 不是 release evidence；release evidence 见下一节。
- 当前 ccache trace 只有 4 个 cache objects，且分别落在 4 个 leaf parent；它不展示
  parent-rule policy 的 rule-count advantage。
- update object 是 sample-local object，用于测 rule update path；它仍在真实 trace-derived
  parent 下运行，但不是 ccache 自然生成的新 cache entry。
- 当前 target 依赖 bridge target，第一次新 RUN_ID 会重建 Redis/nginx source 和 ccache trace；
  后续可以考虑更细粒度复用，但不能牺牲 Makefile provenance。

## Release 结果

release repetition command：

```text
make kvm-w4-ccache-rule-macrobench \
  RUN_ID=20260616T-w4-ccache-rule-macrobench-release-v1 \
  W4_CCACHE_RULE_MACROBENCH_SAMPLES=20
```

input hash 复验：

```text
sha256sum -c \
  results/phase1/20260616T-w4-ccache-rule-macrobench-release-v1/w4-ccache-rule-macrobench-inputs.sha256
```

结果文件：

- `results/phase1/20260616T-w4-ccache-rule-macrobench-release-v1/w4-ccache-rule-macrobench.jsonl`
- `results/phase1/20260616T-w4-ccache-rule-macrobench-release-v1/w4-ccache-rule-macrobench-inputs.sha256`
- `results/phase1/20260616T-w4-ccache-rule-macrobench-release-v1/dmesg-w4-ccache-rule-macrobench.log`

summary：

- `samples=20`
- `systems=2`
- `setup_rows=40`
- `update_rows=40`
- `correctness_rows=40`
- `pass=true`
- `failures=0`
- `policy_executed=true`
- `kvm_validated=true`
- `c2_supported=false`
- `release_gate_pass=false`

20-sample 平均值：

- parent-rule policy：`setup_ns_avg=110545949.3`、`update_ns_avg=6518131.3`、
  `total_rule_writes_avg=8`、`update_total_rule_writes_avg=2`
- table baseline：`setup_ns_avg=104058982.65`、`update_ns_avg=6308357.65`、
  `total_rule_writes_avg=8`、`update_total_rule_writes_avg=2`

## Release 解释

release run 证明 W4 ccache trace-derived rule setup/update path 已经能在修改内核 KVM 中
跑 20 个 samples，并且每个 sample 都执行真实 `cgroup/namei_ext` attach path、lookup
oracle、readdir oracle、update oracle 和 detach 后 alias absence check。

这个 release run 同时是 C2 负证据：

- parent-rule policy setup 平均慢于 table baseline；
- parent-rule policy update 平均慢于 table baseline；
- parent-rule policy setup rule writes 与 table baseline 相同；
- parent-rule policy update rule writes 与 table baseline 相同；
- 当前 trace 的 4 个 cache objects 位于 4 个不同 leaf parent，因此没有展示 parent-rule
  的 rule-count advantage。

因此该 run 只能作为 W4 workload ledger 的 raw input，不能单独支持 W4 C2 slice、C8
programmability claim，或全局 performance claim。
