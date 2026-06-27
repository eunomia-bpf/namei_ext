# W4 attach-window operation trace 设计记录

更新日期：2026-06-15
阶段：补充 / 执行设计
来源/命令：Mencius Weak Accept 后继续推进 W4 release-level operation-weighted hit-rate blocker
完整性：设计完成；后续实现与 KVM 验证见
`docs/tmp/2026-06-15-w4-attach-window-optrace-implementation.md`

## 动机

W4 release counterfactual accounting 已经被 subagent 接受为负 C8 证据。它保留了一个关键
事实：sampled parent-scoped policy 能覆盖 4 个 trace-derived cache objects，但同一组
sampled objects 也能被 table-only exact redirects 解释，因此不能支撑 C8。

下一个 blocker 是 operation-weighted hit rate。当前已有
`w4-ccache-trace.jsonl` 记录未 attach policy 的真实 ccache hot compile file-op stream，
也有 `w4-ccache-parent-compile.jsonl` 记录 policy attach window 内的真实 ccache hot
compile output hash。缺口是：policy attach window 内没有对子进程 ccache/gcc file-op
stream 做 raw trace，因此无法定义“真实操作流中有多少 cache-path lookup/open 由 policy
命中”。

## 最小设计

本阶段不做完整 release-level C8。最小实现只给现有
`--ccache-parent-compile` 和 `--ccache-table-compile` runner 增加可审计 optrace：

1. 只追踪两次真实 `ccache gcc -c` 子进程，不追踪整个 runner；
2. 使用 `strace -f -e trace=%file -o <trace>` 包裹 `ccache gcc`；
3. trace 文件写入对应 workdir：
   - `redis-policy-compile.strace.log`
   - `nginx-policy-compile.strace.log`
4. runner 在 summary 里只新增 sampled attach-window 指标：
   - `attached_cache_path_file_ops`
   - `attached_policy_cache_object_ops`
   - `attached_sampled_operation_hit_rate`
   - `operation_weighted_policy_hit_rate_is_release=false`
5. 这些指标不能把 `qualified_for_c8` 改成 true。它们只是证明当前 sampled attach-window
   op stream 的分母/分子可以被 raw trace 复算。

## 分母和分子

分母：

```text
attached_cache_path_file_ops =
  count(strace lines containing CCACHE_DIR and a file syscall result)
```

分子：

```text
attached_policy_cache_object_ops =
  count(strace lines containing one of the trace-derived visible cache object names)
```

该分子仍是 proxy。真正 C8 需要 kernel-side policy decision count 或 release workload
operation stream 中的 policy hit count。当前 Phase 1 只能把它标记为 sampled
attach-window proxy。

## 为什么不直接计入 C8

- workload 仍只有 Redis/nginx 各一个 source file 的 hot compile，不是完整 release build；
- trace-derived object 集合只有 4 个；
- table-only comparator 仍能通过同一 output oracle；
- 没有 stale/corrupt/update transition，也没有 table update latency/stale window。

因此本步骤的正确结论是：采集机制可运行，raw trace 可复算 sampled operation ratio，
但 `qualified_for_c8=false` 不变。

## 需要改动的文件

- `tests/w1_oracle/namei_ext_w1_oracle.c`
  - 增加 `run_child_capture_trace()`；
  - 让 Redis/nginx ccache compile 可选地通过 strace 包裹；
  - 解析 trace logs 并在 summary 写入 sampled attach-window metrics。
- `mk/kvm.mk`
  - 将 trace logs 加入 parent/table compile 输入或输出 hash；
  - 对 summary 新字段增加 fail-fast hard check。
- `mk/report.mk`
  - 报告 sampled optrace 指标；
  - 明确 `operation_weighted_policy_hit_rate_is_release=false`。

## 风险

- `strace` 会改变少量 timing，但这里测的是 correctness/accounting，不是性能数字。
- strace 日志格式和 ccache 版本相关；parser 必须 fail-fast，不能把解析失败当 0。
- 分子只是基于 trace object name 的 proxy，不能替代 kernel-side decision counter。
