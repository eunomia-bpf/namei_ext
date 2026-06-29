# W2 KVM fixture path oracle 实现记录

> 2026-06-29 baseline scope update: this historical record preserves prior reasoning and results. Current C8/B12 guidance is claim-driven baseline selection; exact-map diagnostics are optional boundary evidence only when precomputed mapping is the competing claim.

日期：2026-06-14

## 背景和目标

W2 的目标是验证 `sandbox_fixture_view.bpf.c` 这类受控测试沙箱 policy family
能表达真实服务配置、secret、certificate、endpoint 和 poison sentinel 的
fixture substitution。上一阶段只有 policy-semantic POC：它证明 hard-coded 分支能在
synthetic directory 中 lookup/readdir，但没有把这些 entries 绑定到真实 upstream
workload provenance，也没有放进 Phase 1 KVM/report gate。

本步骤实现一个最小 W2 path oracle：

- 从固定 nginx `1.26.3` 和 PostgreSQL `16.6` source provenance 生成 fixture witness；
- 由 Makefile 生成 fake certificate、local endpoint、poison sentinel 和 fake password fixture；
- 生成 `w2-sandbox-fixture-oracle-entries.tsv`；
- 在 KVM guest 内通过真实 `cgroup/namei_ext` attach path 运行 `sandbox_fixture_view.bpf.c`；
- 用同一组 entries 跑 `table_redirect.bpf.c` 作为 table-only path baseline；
- 明确保持 `qualified_for_c8=false`，不把 path oracle 冒充服务 health/no-real-secret oracle。

## 调研和代码路径

本步骤调研和复用的路径：

- `bpf/policies/sandbox_fixture_view.bpf.c`：config、service config、secret、certificate、
  endpoint 和 poison 的 lookup/readdir hard-coded POC 分支；
- `tests/policy_semantic/namei_ext_policy_semantic.c`：sandbox fixture POC cases；
- `tests/w1_oracle/namei_ext_w1_oracle.c`：可复用的 libbpf load/attach、cgroup id、
  materialization、lookup/readdir 和 detach oracle；
- `mk/workload.mk`：workload source provenance、W1 TSV 生成模式；
- `mk/kvm.mk`：KVM guest target 模式和 input sha256 provenance；
- `mk/report.mk`：Phase 1 report hard gates。

关键约束是 W2 仍然使用 Phase 1 的 same-parent component redirect。fixture files
必须被 materialize 到每个 per-entry synthetic directory 的同一父目录下；跨目录 projected
volume、完整 service rootfs composition、真实服务启动和 secret leakage checker 不在本
gate 中完成。

## 实现内容

新增或修改：

- `mk/workload.mk`
  - 新增 `workload-sandbox-fixture`、`workload-nginx-fixture-manifest`、
    `workload-postgres-fixture-manifest` 和 `workload-w2-oracle-entries`；
  - 生成 nginx fixture manifest：upstream `conf/nginx.conf`、fake cert、local endpoint、
    poison sentinel；
  - 生成 PostgreSQL fixture manifest：upstream `postgresql.conf.sample`、fake password；
  - 生成 `w2-sandbox-fixture-oracle-entries.tsv`，并 fail-fast 校验行数、列数、
    backing path 和 SHA256。
- `tests/w1_oracle/namei_ext_w1_oracle.c`
  - 扩展为共享 path oracle runner；
  - 保持原 W1 CLI 不变；
  - 新增 `--sandbox-fixture` mode，输出 `w2-oracle*` events；
  - 对 sandbox policy 记录 `policy_state`，不伪称 map update；
  - 保留 table baseline 的 map-driven exact redirects；
  - 所有 W1/W2 JSONL event 都带 `result_level=kvm_policy_path_oracle`；
  - W2 per-policy summary 使用 `fixture witness path oracle passed`，不复用
    W1 的 `trace-derived` 文案。
- `mk/kvm.mk`
  - 新增 `kvm-w2-oracle` 和 `__phase1_guest_w2_oracle`；
  - guest 内校验 TSV、fixture manifests、policy source、policy object、runner source
    和 runner binary；
  - 写出 `w2-oracle-inputs.sha256` 固定 9 项输入清单；
  - 运行共享 runner 的 `--sandbox-fixture` mode；
  - 保存 `dmesg-w2-oracle.log`。
- `mk/report.mk`
  - 新增 W2 raw artifact hard gates；
  - 运行 `sha256sum -c w2-oracle-inputs.sha256`；
  - 检查 W2 sha 清单固定 9 项路径集合；
  - 检查所有 `w2-oracle*` events 的 `result_level`；
  - 要求 2 个 passing summaries、每个 6 entries、policy set 恰好为
    `sandbox_fixture` 和 `table_redirect`、`qualified_for_c8=false`。
- `Makefile`
  - `phase1` 纳入 `kvm-w2-oracle`；
  - `help` 增加 W2 oracle targets。
- `workload/w2-nginx-fixture/evidence.md` 和
  `workload/w2-postgres-secret-fixture/evidence.md`
  - 区分当前已实现的 fixture manifest / TSV / KVM path oracle targets；
  - 把 health、no-real-secret、startup trace 和 table/update budget 记录为
    release-level 缺口，避免把当前 fixture path oracle 误写成真实服务运行结果。
- `docs/paper/sections/05-evaluation.tex`
  - 收紧 W2 workload 表格中的当前来源列，只写当前 raw evidence 覆盖的 upstream
    sample config 和 Make-owned fixtures；
  - reload、static/proxy、projected volume 和 Compose secret 仍保留在发布级计划文档，
    但不作为当前 W2 path oracle 结果表述。

## 设计选择

1. W2 fixture manifest 是 workload/oracle 输入，不是 policy 配置语言。policy 仍然是
   `bpf/policies/sandbox_fixture_view.bpf.c`。
2. 当前 W2 使用 per-entry synthetic directory。它验证 path-resolution semantics，
   不验证真实 nginx/PostgreSQL source tree parent/path interaction。
3. `sandbox_fixture_view.bpf.c` 先使用 hard-coded POC branches。`fixture_rules` map
   仍被加载并验证存在，但本 W2 path oracle 不把它写成 map-driven result。
4. `table_redirect.bpf.c` 仍作为强 path baseline。它在 W2 path oracle 下通过，因此 W2
   不能支撑 C8。
5. W2 的 nginx/PostgreSQL fixture witness 绑定到真实 upstream config provenance，但
   fake cert、fake password、local endpoint 和 poison sentinel 是 Makefile-owned
   test fixture，不是生产 secret。

## 被拒绝的替代方案

- 不用项目 `.sh` runner。所有新增 workflow 均由 Make target 驱动。
- 不把 fixture manifest 解释成 policy DSL。它只生成 oracle TSV 和 provenance。
- 不在 host 上直接 attach policy。Phase 1 validation 必须进入 KVM guest。
- 不把 W2 标成 release-level service result。当前没有启动真实服务、没有 health response、
  no-real-secret checker、startup trace 或 table/update budget counterfactual。

## 验证结果

本步骤完成的验证：

```text
make w1-oracle RUN_ID=20260614T-workloads-git-ceiling
make workload-w2-oracle-entries RUN_ID=20260614T-workloads-git-ceiling
make kvm-w2-oracle RUN_ID=20260614T-workloads-git-ceiling
make kvm-w1-oracle RUN_ID=20260614T-workloads-git-ceiling
make report RUN_ID=20260614T-workloads-git-ceiling SAMPLES=1 BENCH_ITERS=2000
make -C docs/paper paper
make -C docs/paper check
```

关键 raw artifacts：

- `results/workloads/runs/20260614T-workloads-git-ceiling/w2-nginx-fixture/fixture-manifest.json`
- `results/workloads/runs/20260614T-workloads-git-ceiling/w2-postgres-secret-fixture/fixture-manifest.json`
- `results/workloads/runs/20260614T-workloads-git-ceiling/w2-sandbox-fixture-oracle-entries.tsv`
- `results/phase1/20260614T-workloads-git-ceiling/w2-oracle.jsonl`
- `results/phase1/20260614T-workloads-git-ceiling/w2-oracle-inputs.sha256`
- `results/phase1/20260614T-workloads-git-ceiling/dmesg-w2-oracle.log`

结果摘要：

- W2 TSV：6 条 entries，源 backing path 和 SHA256 校验通过；
- KVM W2 oracle：`sandbox_fixture` 6 entries，0 failure；
- KVM W2 oracle：`table_redirect` 6 entries，0 failure；
- W2 run summary：2 policies，6 entries，0 failure；
- W2 per-policy summary detail 已重新生成为 `fixture witness path oracle passed`；
- W2 input provenance：TSV、两个 fixture manifests、policy source/object、runner source
  和 runner binary 的 SHA256 已写入 `w2-oracle-inputs.sha256`，report 运行
  `sha256sum -c` 并校验固定 9 项路径集合；
- `make report` 通过 W1/W2 oracle hard gates。

## 剩余风险和后续工作

- W2 仍是 path oracle，不是完整 service health oracle。下一步需要启动 nginx/PostgreSQL
  或等价服务 harness，并验证 health response、endpoint 指向 local fake service、
  fake secret 被使用、真实 secret/config hash 未被打开。
- 当前 W2 不包含 startup trace 和 operation-weighted redirected hit rate。
- `table_redirect.bpf.c` 在本 path oracle 下通过，因此 W2 不能支撑 C8。C8 仍需要
  table/update budget、materialization cost、stale/poison window 或 oracle violation 证据。
- W3/W4 还没有对应 KVM workload oracle。
