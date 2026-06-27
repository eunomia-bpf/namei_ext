最后更新：2026-06-15
更新阶段：Phase 1 implementation
来源命令：`make kvm-w1-branch-probes RUN_ID=20260615T-parent-key-poc`，`make report RUN_ID=20260615T-parent-key-poc`
完成度：已完成 Phase 1 W1 KVM branch-probe witness；不能计入 C1/C8

# W1 Build-Graph Branch Probes 实现记录

## 目标

W1 release-binary replay 已证明 Redis/nginx 在 attached `build_graph_view.bpf.c`
路径下可以完成规范化 release rebuild，并与 baseline binary hash 一致。但 W1 的
build-graph semantic witness 仍缺两个分支的 KVM raw evidence：

- undeclared dependency poison：`private.h -> poison.dep`
- negative fallback：`missing.h -> PASS/ENOENT`

本步骤新增一个最小 KVM gate，在真实 Redis/nginx source tree 的真实 parent
directory 副本里执行这两个 branch probes。它补的是分支语义 evidence，不是 release
build trace 中自然触发这些分支的 evidence，因此仍显式 `qualified_for_c8=false`。

## 修改文件

- `tests/w1_oracle/namei_ext_w1_oracle.c`
  - 新增 `--build-branch-probes` mode。
  - 在 Redis `src/` 和 nginx `src/core/` parent directory 副本中写入
    `poison.dep`，保持 `private.h` 和 `missing.h` 不存在。
  - attach 前验证 `private.h`/`missing.h` 都不可达。
  - attach `build_graph_view.bpf.c` 后验证：
    - `private.h` lookup 解析到 `poison.dep` sentinel；
    - `readdir` 显示 `private.h` 且隐藏 `poison.dep`；
    - `missing.h` lookup 仍为 `ENOENT`；
    - `readdir` 不显示 `missing.h`。
  - detach 后验证两个 visible names 再次不可达。
- `mk/kvm.mk`
  - 新增 `kvm-w1-branch-probes` 和 `__phase1_guest_w1_branch_probes`。
  - guest target 复制 Redis/nginx trace source 到 `/tmp`，写入
    `w1-branch-probes.jsonl`、`w1-branch-probes-inputs.sha256` 和
    `dmesg-w1-branch-probes.log`。
	  - 在 KVM artifact 中记录 host trace candidate hit rate：
	    `numerator_candidate_trace_hits=11330`，
	    `denominator_file_op_lines=3021315`，
	    `candidate_witness_hit_rate=0.0037500227549924453`，并显式标记
	    `artifact_environment=kvm`、`metric_basis_environment=host` 和
	    `operation_weighted_hit_rate_is_release=false`。
- `mk/report.mk`
  - 将 branch-probe JSONL、input SHA256 和 dmesg artifact 纳入 report gate。
	  - 强制检查 poison lookup、poison readdir、negative lookup、negative readdir 四类
	    attached probes 在 Redis/nginx 两个 parent dirs 中都通过。
	  - 强制检查 hit-rate row 的 artifact 环境和 metric basis 环境被拆分记录：
	    artifact 来自 KVM gate，metric basis 来自 host trace witness manifest。
	  - 强制检查 `qualified_for_c8=false`。
- `Makefile`
  - 将 `kvm-w1-branch-probes` 加入默认 `phase1`。
  - 在 `make help` 中公开该 target。

## 验证结果

执行过的关键命令：

```text
make w1-oracle
make kvm-w1-branch-probes RUN_ID=20260615T-parent-key-poc
make kvm-w1-oracle kvm-w1-build-replay kvm-w1-release-build-replay kvm-w1-branch-probes kvm-w2-oracle kvm-w2-nginx-real kvm-w3-oracle kvm-w4-oracle kvm-w4-cache-content RUN_ID=20260615T-parent-key-poc
make report RUN_ID=20260615T-parent-key-poc
```

Raw result:

```text
results/phase1/20260615T-parent-key-poc/w1-branch-probes.jsonl
results/phase1/20260615T-parent-key-poc/w1-branch-probes-inputs.sha256
results/phase1/20260615T-parent-key-poc/dmesg-w1-branch-probes.log
```

`w1-branch-probe-summary` 结果：

- `pass=true`
- `failures=0`
- `workloads=2`
- `branch_classes=2`
- `poison_probes=2`
- `negative_probes=2`
- `policy_executed=true`
- `kvm_validated=true`
- `qualified_for_c8=false`

`make report RUN_ID=20260615T-parent-key-poc` 已通过，summary 已包含
`W1 KVM branch probe failures: 0` 和 `W1 KVM Build-Graph Branch Probes` 表。

## 当前边界

该 gate 补上的是 KVM branch semantics，不是发布级 C8 证据。W1 仍不能计入 C1/C8，
原因是：

- `private.h`/`missing.h` 是 probe names，不是 Redis/nginx release build trace 中自然
  触发的 file operations；
- alias set 仍是手工候选 + trace witness，不是完整 trace-derived alias set；
- release-level operation-weighted redirected hit rate 仍未采集；
- table-only counterfactual 仍未证明在同等 table/update budget 下失败。

因此本文档完成的是 Phase 1 W1 branch-probe witness；下一步若要支持 C8，需要把
branch hit、redirected operation hit rate 和 table/update budget 都接到真实 workload
trace 或发布级 workload oracle 中。
