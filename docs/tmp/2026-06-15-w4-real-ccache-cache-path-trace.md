# W4 真实 ccache cache-path trace KVM 见证实现记录

最近更新：2026-06-15
更新阶段：第一阶段实现
来源/命令：`make kvm-w4-ccache-trace RUN_ID=20260615T-parent-key-poc`
完整性：已完成非 C8 真实 ccache cache-path trace witness

## 动机

W4 cache-locality family 已有三类 Phase 1 证据：

1. `w4-oracle.jsonl`：KVM 中通过 `cache_locality_view.bpf.c` 和
   `table_redirect.bpf.c` 验证 manifest-derived lookup/readdir path oracle。
2. `w4-cache-content.jsonl`：KVM 中填充 `cache_rules` map，验证 verified hit、stale
   fallback、corrupt reject 和 miss canonical 的内容选择。
3. `w4-ccache-real.jsonl`：KVM 中运行真实 `ccache` cold/hot 编译，记录 Redis/nginx
   object hash、`cache_miss=2` 和 `direct_cache_hit=2`，再把 hot object 输入给
   W4 content oracle。

第三类证据证明了真实 ccache cold/hot transition，但没有观察 ccache hot path 自身是否
实际访问 cache directory。因此本步骤新增一个独立 KVM target，用 `strace -f -e
trace=%file` 跟踪真实 hot compile，并要求 trace 中确实出现 `CCACHE_DIR` 路径。

该步骤仍显式不是 C8 证据：它只证明真实 ccache hot path 访问 cache directory，不
attach `namei_ext` policy，也不证明 operation-weighted policy cache hit rate。

## 调研和检查的代码路径

- `mk/kvm.mk`：已有 W4 ccache transition target、KVM guest target 模式和结果根目录
  变量。
- `mk/report.mk`：Phase 1 hard gates、raw artifact 列表和 summary 生成路径。
- `Makefile`：默认 `phase1` dependency graph 和 `make help` 文案。
- `Dockerfile`：runtime image 依赖列表。
- `workload/w4-ccache-redis-nginx/evidence.md`：W4 ccache workload 的 source-to-signal
  ledger。
- `docs/research_plan.md`、`docs/experiment-plans/osdi-evaluation.md`、
  `docs/paper/evaluation.md`、`docs/paper/sections/04-implementation.tex` 和
  `docs/paper/sections/05-evaluation.tex`：长期计划、评估计划和论文中的 W4 状态。

宿主机预检查确认 `strace` 可用，版本为 6.8。KVM target 自身也用
`command -v strace` fail-fast 检查 guest 环境。

## 设计选择

新增 target 为 `make kvm-w4-ccache-trace`，依赖修改后的 kernel image、Redis workload
source build tree 和 nginx workload source build tree。guest target
`__phase1_guest_w4_ccache_trace` 执行以下流程：

1. 检查 Redis `src/crc64.c`、nginx `src/core/ngx_string.c`、`ccache` 和 `strace`。
2. 记录 `w4-ccache-trace-ccache.version` 和
   `w4-ccache-trace-strace.version`。
3. 写出 `w4-ccache-trace-inputs.sha256`，绑定两个源码文件和两个工具版本文件。
4. 清空独立 `CCACHE_DIR` 和 ccache stats。
5. 对 Redis 编译单元执行 cold compile 暖 cache，再用 `strace -f -e trace=%file`
   采集 hot compile。
6. 对 nginx 编译单元执行 cold compile 暖 cache，再用 `strace -f -e trace=%file`
   采集 hot compile。
7. 保存 `w4-ccache-trace-stats.txt`、两个 `.strace.log` 和
   `w4-ccache-trace-artifacts.sha256`。
8. 校验 Redis cold/hot object hash 一致、nginx cold/hot object hash 一致。
9. 校验两个 trace 都非空、两个 trace 都至少有一条 `CCACHE_DIR` file operation。
10. 校验 `cache_miss >= 2` 和 `direct_cache_hit >= 2`。
11. 写出 `w4-ccache-cache-path-trace`、`w4-ccache-trace-summary` 和
    `w4-ccache-trace-policy-scope` JSONL rows。
12. 保存 `dmesg-w4-ccache-trace.log`。

`Dockerfile` 增加 `strace`，使 Phase 1 runtime image 声明包含该工具；实际 KVM guest
仍以 target 内的 `command -v strace` 为准。

## 拒绝的替代方案

- 不把 trace 合并进 `kvm-w4-ccache-real`。transition witness 和 cache-path trace
  的 claim 边界不同，分开 target 可以让 report 和论文准确区分。
- 不把 trace witness 记为 `policy_executed=true`。这个 target 没有 attach
  `namei_ext` policy，只观察真实 ccache 文件访问。
- 不用 checked-in shell 脚本。所有流程都在 Make target 中表达，符合 Makefile-only
  项目约束。
- 不把 `CCACHE_DIR` trace 命中解释成 operation-weighted policy cache hit rate。当前
  trace 只说明 ccache 访问了 cache directory，尚未把真实 ccache 文件访问接入
  `namei_ext` policy decision。

## 实现细节

代码和配置变更：

- `Makefile`
  - 默认 `phase1` 增加 `kvm-w4-ccache-trace`。
  - `make help` 增加 `kvm-w4-ccache-trace`。
- `mk/kvm.mk`
  - 新增 `W4_CCACHE_TRACE_JSON`、`W4_CCACHE_TRACE_WORK_DIR`、
    `W4_CCACHE_TRACE_REDIS_LOG` 和 `W4_CCACHE_TRACE_NGINX_LOG`。
  - 新增 `kvm-w4-ccache-trace` 和 `__phase1_guest_w4_ccache_trace`。
- `mk/report.mk`
  - 新增 hard gates：检查 trace JSONL、input/artifact hashes、stats、version files、
    Redis/nginx strace logs、object hash equality、trace line counts、`CCACHE_DIR`
    hit counts、ccache hit/miss counts、policy-scope row 和 `qualified_for_c8=false`。
  - review 后进一步加固 report gate：从 raw Redis/nginx `.strace.log` 重新计算
    trace 行数和 `CCACHE_DIR` 命中数，并要求它们等于 JSONL 字段；同时要求每个 hot
    compile 至少有一个成功 `openat(..., O_RDONLY) = fd` 读取非 stats/config 的
    cache object path。
  - Summary 增加 `W4 Real Ccache Cache-Path Trace Witness` 小节。
  - Raw artifact 列表增加 trace JSONL、trace logs、stats、tool path/version files、
    hash manifests 和 dmesg。
- `Dockerfile`
  - 增加 `strace` 依赖。

新增 raw artifacts：

- `results/phase1/20260615T-parent-key-poc/w4-ccache-trace.jsonl`
- `results/phase1/20260615T-parent-key-poc/w4-ccache-trace-inputs.sha256`
- `results/phase1/20260615T-parent-key-poc/w4-ccache-trace-artifacts.sha256`
- `results/phase1/20260615T-parent-key-poc/w4-ccache-trace-stats.txt`
- `results/phase1/20260615T-parent-key-poc/w4-ccache-trace-redis.strace.log`
- `results/phase1/20260615T-parent-key-poc/w4-ccache-trace-nginx.strace.log`
- `results/phase1/20260615T-parent-key-poc/dmesg-w4-ccache-trace.log`

## 验证结果

已执行：

```text
make -n kvm-w4-ccache-trace RUN_ID=20260615T-parent-key-poc
make -n report RUN_ID=20260615T-parent-key-poc
make kvm-w4-ccache-trace RUN_ID=20260615T-parent-key-poc
sha256sum -c results/phase1/20260615T-parent-key-poc/w4-ccache-trace-inputs.sha256
sha256sum -c results/phase1/20260615T-parent-key-poc/w4-ccache-trace-artifacts.sha256
make report RUN_ID=20260615T-parent-key-poc
```

范围声明：本文档只记录单一非 C8 W4 ccache cache-path trace 增量的 scoped review。
这里的 weak accept 不代表整篇 OSDI paper、整个项目或 C1/C8 主张已经达到
weak accept。

当前结果：

- Redis hot compile trace：134 条 file operations。
- Redis `CCACHE_DIR` file operations：20 条。
- nginx hot compile trace：602 条 file operations。
- nginx `CCACHE_DIR` file operations：20 条。
- `cache_path_file_ops=40`。
- `cache_miss=2`。
- `direct_cache_hit=2`。
- `local_storage_hit=2`。
- `local_storage_write=4`。
- `policy_executed=false`。
- `qualified_for_c8=false`。

`w4-ccache-trace-policy-scope` 明确记录
`ccache_compile_policy_executed=false` 和 `policy_content_oracle_executed=false`，
防止后续把 trace witness 写成 policy execution evidence。

Subagent 对抗 review 给出 `weak accept for this non-C8 W4 increment`，无 must-fix。
review 后已完成 should-fix：report 从 raw trace 复算 JSONL 计数、gate 成功 cache
object read、summary raw artifact 列出 ccache/strace path/version provenance，并把本文档
顶部元信息改为中文。

## 仍然不计入 C8 的原因

该 gate 只能支撑以下窄结论：

- 真实 ccache hot compile 在修改 kernel 的 KVM guest 中访问 `CCACHE_DIR`；
- trace logs、stats、object hashes 和工具版本都被 raw artifact 和 SHA256 manifest
  绑定；
- Phase 1 report 可以机器检查该 witness 没有被过度声明。

它不能支撑：

- ccache 文件访问由 `namei_ext` policy 决策；
- operation-weighted policy cache hit rate；
- 真实 stale/corrupt cache transition；
- BuildKit/Prometheus Go cache workload；
- stale window、update writes 或 table/update budget counterfactual；
- C1/C8 的发布级性能或可编程性主张。

因此新增 row 必须保持 `policy_executed=false` 和 `qualified_for_c8=false`。
后续更新：`docs/tmp/2026-06-15-w4-ccache-trace-to-policy-bridge.md` 已补上
`ccache trace-to-policy bridge` 的非 C8 witness。W4 下一步应转向真实 ccache
compile under policy attach window、BuildKit cache-path trace、operation-weighted
policy cache hit-rate 和 table/update counterfactual。
