# W4 attach-window operation trace 实现记录

更新日期：2026-06-15
阶段：执行 / 主张门禁
来源/命令：`make kvm-w4-ccache-release-counterfactual RUN_ID=20260615T-w4-attach-window-optrace`
完整性：sampled attach-window optrace 完成，C8 仍未完成

后续补强：`docs/tmp/2026-06-15-w4-attach-window-report-gate-fix.md` 将 report
hard gate 对齐到 6 行 output sha，并用
`RUN_ID=20260615T-w4-attach-window-optrace-gatefix` 重新完成 KVM 验证。

## 动机

W4 已经有 parent-scoped ccache compile witness 和 release counterfactual accounting，但此前
只能说明 4 个 trace-derived cache objects 被 policy 覆盖，不能说明 policy attach window
内真实 `ccache gcc -c` 子进程的 file-op stream。为了靠近 operation-weighted hit rate
blocker，本步骤给现有 parent/table compile witness 增加 ccache 子进程级 `strace`。

## 实现

- `tests/w1_oracle/namei_ext_w1_oracle.c`
  - 新增 `run_child_capture_trace()`，在保持 stdout/stderr capture 的同时可选地用
    `strace -f -e trace=%file -o <trace>` 包裹子命令；
  - Redis/nginx 两个 `ccache gcc -c` helper 接受可选 trace path；
  - `run_ccache_policy_compile()` 为 Redis/nginx policy compile 生成
    `redis-policy-compile.strace.log` 和 `nginx-policy-compile.strace.log`；
  - 新增 `count_ccache_optrace()`，从 strace log 中统计 attach window 内触碰
    `CCACHE_DIR` 的 file-op 行，以及包含 trace-derived cache object visible name 的行；
  - summary 写入 `attached_optrace_collected=true`、
    `attached_cache_path_file_ops`、`attached_policy_cache_object_ops`、
    `attached_sampled_operation_hit_rate` 和
    `operation_weighted_policy_hit_rate_is_release=false`。
- `mk/kvm.mk`
  - parent/table compile 输出哈希增加 Redis/nginx policy compile strace logs；
  - release counterfactual guest target 从 parent summary 读取 attach-window optrace 字段，
    fail-fast 校验 trace 已采集且计数大于 0；
  - release counterfactual row 写入 sampled attach-window metrics，但仍保持
    `operation_weighted_policy_cache_hit_rate=false`、`qualified_for_c8=false`。
- `mk/report.mk`
  - release counterfactual hard gate 要求 attach optrace 字段存在且为 sampled scope；
  - report 表格显示 attached ops、attached object ops 和 sampled hit rate。

## 验证

命令：

```text
make bpf w1-oracle
make kvm-w4-ccache-release-counterfactual RUN_ID=20260615T-w4-attach-window-optrace
```

结果：

- KVM target 退出码为 0；
- `w4-ccache-parent-compile-outputs.sha256` 和
  `w4-ccache-table-compile-outputs.sha256` 均有 6 行，新增两份 policy compile strace log；
- `sha256sum -c w4-ccache-release-counterfactual-inputs.sha256` 的 11 个输入全部 OK；
- report 等价 hard gate 通过：release event 1 条、summary 1 条、
  `qualified_for_c8` 非 false 的行 0 条、release hit true 行 0 条、主 hardgate row 1 条。

关键 raw 字段：

```text
attached_optrace_collected=true
redis_attached_cache_path_file_ops=20
nginx_attached_cache_path_file_ops=20
attached_cache_path_file_ops=40
redis_attached_policy_cache_object_ops=8
nginx_attached_policy_cache_object_ops=8
attached_policy_cache_object_ops=16
attached_sampled_operation_hit_rate=0.4
operation_weighted_policy_hit_rate_is_release=false
qualified_for_c8=false
```

## 结论

本步骤证明 sampled W4 parent-scoped policy attach window 可以保存可复算的 ccache 子进程
file-op stream，并从中得到 sampled operation ratio。它仍不是 C8：样本只有 Redis/nginx
各一个 source file 的 hot compile，table-only comparator 仍通过，且没有 release build、
stale/corrupt transition、update latency 或 stale window。
