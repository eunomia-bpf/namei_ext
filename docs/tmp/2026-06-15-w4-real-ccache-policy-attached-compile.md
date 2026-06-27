# W4 真实 ccache policy-attached compile witness 实现记录

日期：2026-06-15

来源/命令：

```text
make kvm-w4-ccache-policy-compile RUN_ID=20260615T-parent-key-poc
make phase1 RUN_ID=20260615T-parent-key-poc SAMPLES=1 BENCH_ITERS=2000
make report RUN_ID=20260615T-parent-key-poc SAMPLES=1 BENCH_ITERS=2000
```

完整性：已完成 Phase 1 W4 真实 ccache 编译期间 policy attach witness；仍不能计入 C8。

## 动机

上一阶段的 W4 evidence 已经有三段链路：

- `kvm-w4-ccache-real`：真实 `ccache gcc -c` cold/hot transition，证明 Redis/nginx
  object hash 和 ccache hit/miss stats 可审计。
- `kvm-w4-ccache-trace`：真实 hot compile 的 file-operation trace，证明 KVM guest 中
  ccache 确实触碰 `CCACHE_DIR`。
- `kvm-w4-ccache-policy-bridge`：从真实 trace 中抽取成功读取的 cache object path，
  再让 `cache_locality_view.bpf.c` 消费这些 trace-derived object component。

这个链路仍有一个明显缺口：真实 ccache 编译阶段本身没有在 `namei_ext` policy attach
window 内运行。OSDI 风格 review 会把它判成 trace-derived bridge，而不是 workload
执行期间的 policy evidence。

本步骤补上最小 witness：复用真实 trace 产生的 `CCACHE_DIR` 和 trace-derived cache
object list，把 cache object 从 visible name 移到 hidden `.local` backing，然后在
attach `cache_locality_view.bpf.c` 时运行真实 Redis/nginx ccache hot compile。若 ccache
仍能命中 cache、输出 object hash 与 baseline hot object 一致，说明真实 ccache compile
确实通过 `namei_ext` policy 解析到 cache backing object。

## 检查的代码路径和文件

- `tests/w1_oracle/namei_ext_w1_oracle.c`
  - 已有 W4 cache content oracle、ccache trace parser、policy attach helper、
    map update helper 和 ccache compile helper。
  - 新增 `--ccache-policy-compile` runner mode。
- `mk/kvm.mk`
  - 已有 `kvm-w4-ccache-real`、`kvm-w4-ccache-trace` 和
    `kvm-w4-ccache-policy-bridge`。
  - 新增 `kvm-w4-ccache-policy-compile` 和
    `__phase1_guest_w4_ccache_policy_compile`。
- `mk/report.mk`
  - 已有 W4 real/trace/bridge hard gates。
  - 新增 policy-attached compile artifact、hash、summary 和 stats gates。
- `bpf/policies/cache_locality_view.bpf.c`
  - 复用 `cache_rules` map-backed verified-hit 语义。
- `results/phase1/20260615T-parent-key-poc/`
  - 作为本次 KVM witness 的 raw result root。

## 设计选择

新增 runner mode：

```text
namei_ext_w1_oracle --ccache-policy-compile \
  OUT_JSONL CGROUP_MOUNT WORK_DIR CACHE_DIR TRACE_CACHE_DIR ENTRIES_TSV \
  REDIS_SRC REDIS_BUILD_SRC NGINX_SRC NGINX_BUILD_SRC \
  REDIS_BASELINE_OBJ NGINX_BASELINE_OBJ CACHE_POLICY STATS_PATH
```

流程如下：

1. 读取 `w4-ccache-policy-bridge-entries.tsv`，每个 entry 都来自真实 ccache trace 中
   成功读取的 cache object path。
2. 复制上一阶段真实 trace 的 `CCACHE_DIR` 到本 witness 的 workdir。
3. 对每个 trace-derived object，计算其相对 `CCACHE_DIR` 的路径，把 visible cache
   object rename 成 hidden `.local` backing，并在相同 parent directory 下保留同父目录
   redirect 可表达性。
4. attach 前确认 visible cache object 不可达，避免 ccache 绕过 policy 直接读到 object。
5. attach `cache_locality_view.bpf.c`，向 `cache_rules` map 写入 visible -> hidden
   backing 的 verified-hit rule。
6. attach 后先用普通 VFS open/read/readdir 验证每个 cache object alias 可达且 backing
   被隐藏。
7. 在 policy 仍 attached 时运行真实 Redis `src/crc64.c` 和 nginx
   `src/core/ngx_string.c` 的 `ccache gcc -c` hot compile。
8. 把 policy compile output object 与上一阶段 baseline hot object 做 SHA256 对比。
9. detach policy 后确认 visible cache objects 再次不可达。
10. 保存 ccache stats、input/output SHA256、dmesg 和 raw JSONL。

该设计刻意不引入 YAML/JSON/DSL policy language。输入 TSV 是 workload/oracle material，
policy 仍是 `bpf/policies/cache_locality_view.bpf.c` 下的 eBPF 程序。

## 拒绝的替代方案

- 不把 `ccache` 放入 policy attach window，只跑 trace bridge。这已经完成，但不足以回答
  “真实 workload compile 是否消费 policy”。
- 直接构造假的 cache directory。这样会回退到 fixture，不再证明真实 ccache cache layout。
- 手写 `.sh` 包装 ccache。项目规范要求 orchestration 走 Makefile-only，因此新增的是
  Make target 和 C runner mode。
- 把这个 witness 直接计入 C8。当前只覆盖两个 compile units 和 trace-derived object，
  没有 release-level operation-weighted hit rate、stale/corrupt transition 或
  table/update counterfactual。

## 实现细节

`tests/w1_oracle/namei_ext_w1_oracle.c` 新增的关键 helper 包括：

- `run_ccache_redis_compile`
- `run_ccache_nginx_compile`
- `prepare_ccache_policy_entry`
- `emit_ccache_policy_compile_case`
- `ccache_policy_expect_absent`
- `ccache_policy_expect_equal`
- `ccache_policy_expect_readdir`
- `run_ccache_policy_compile`

`mk/kvm.mk` 新增 artifact 变量：

- `W4_CCACHE_POLICY_COMPILE_JSON`
- `W4_CCACHE_POLICY_COMPILE_WORK_DIR`
- `W4_CCACHE_POLICY_COMPILE_STATS`

`phase1` 默认流水线现在在 `kvm-w4-ccache-policy-bridge` 之后运行
`kvm-w4-ccache-policy-compile`，再运行 `table-budget`、functional、bench、Docker 和
report。

`mk/report.mk` 新增 hard gates：

- `w4-ccache-policy-compile-inputs.sha256` 必须存在、可校验，并精确包含 14 个输入。
- `w4-ccache-policy-compile-outputs.sha256` 必须存在、可校验，并证明 Redis/nginx
  baseline hot object 和 policy output object hash 分别相等。
- `w4-ccache-policy-compile-summary` 必须记录：
  - `real_ccache_run=true`
  - `policy_executed=true`
  - `ccache_compile_policy_executed=true`
  - `output_hash_match=true`
  - `policy_redirected_cache_objects=4`
  - `failures=0`
  - `qualified_for_c8=false`
- ccache stats 必须记录 `direct_cache_hit >= 2`。
- 每个 trace-derived entry 都必须通过 pre-attach absent、attached visible match、
  attached readdir alias 和 post-detach absent。

## 验证结果

本次在修改后的 kernel KVM guest 内完成：

```text
make kvm-w4-ccache-policy-compile RUN_ID=20260615T-parent-key-poc
```

关键 raw evidence：

- `results/phase1/20260615T-parent-key-poc/w4-ccache-policy-compile.jsonl`
- `results/phase1/20260615T-parent-key-poc/w4-ccache-policy-compile-inputs.sha256`
- `results/phase1/20260615T-parent-key-poc/w4-ccache-policy-compile-outputs.sha256`
- `results/phase1/20260615T-parent-key-poc/w4-ccache-policy-compile-stats.txt`
- `results/phase1/20260615T-parent-key-poc/dmesg-w4-ccache-policy-compile.log`

summary 关键字段：

```json
{
  "event": "w4-ccache-policy-compile-summary",
  "result_level": "kvm_real_ccache_policy_compile_witness",
  "workload": "w4-ccache-redis-nginx",
  "real_ccache_run": true,
  "policy_executed": true,
  "ccache_compile_policy_executed": true,
  "output_hash_match": true,
  "policy_redirected_cache_objects": 4,
  "redis_trace_objects": 2,
  "nginx_trace_objects": 2,
  "pass": true,
  "failures": 0,
  "operation_weighted_policy_cache_hit_rate": false,
  "operation_weighted_policy_hit_rate_is_release": false,
  "qualified_for_c8": false
}
```

stats 关键字段：

```json
{
  "event": "w4-ccache-policy-compile-stats",
  "cache_miss": 0,
  "direct_cache_hit": 2,
  "local_storage_hit": 2,
  "local_storage_write": 0,
  "policy_redirected_cache_objects": 4
}
```

随后完整 Phase 1 和 report gate 通过：

```text
make phase1 RUN_ID=20260615T-parent-key-poc SAMPLES=1 BENCH_ITERS=2000
make report RUN_ID=20260615T-parent-key-poc SAMPLES=1 BENCH_ITERS=2000
```

`results/phase1/20260615T-parent-key-poc/summary.md` 新增
`W4 Real Ccache Policy-Attached Compile Witness` 小节，并把该 witness 的 raw artifacts
列入 report。

## 仍然不计入 C8 的原因

这个 witness 消除了 “真实 ccache compile 阶段完全没有执行 `namei_ext` policy” 的缺口，
但仍不满足 C8：

- 只覆盖 Redis/nginx 各一个 compile unit，不是发布级完整 build。
- 当前 hit rate 是 trace-derived object witness，不是 release-level
  operation-weighted policy cache hit rate。
- 只覆盖 verified-hit path，没有真实 stale/corrupt ccache transition。
- 尚未测 update writes、update latency 和 stale window。
- `table_redirect.bpf.c` 还没有同等 content-equivalent table oracle 和 table/update
  budget counterfactual。
- BuildKit/Prometheus Go cache workload 仍只有 witness/path oracle，没有真实
  policy-attached build/cache trace。

因此，W4 当前状态应更新为：

```text
functional_only:
  KVM path oracle
  cache content oracle
  real ccache cold/hot transition witness
  real ccache cache-path trace witness
  trace-derived policy bridge witness
  real ccache policy-attached compile witness

not C8:
  no release operation-weighted policy hit rate
  no real stale/corrupt transition
  no table/update budget counterfactual
  no BuildKit/Prometheus policy-attached workload
```

## 后续工作

1. 把 policy-attached ccache witness 扩展到更多 source files 或完整 Redis/nginx build，
   记录 operation-weighted policy hit rate。
2. 为真实 stale/corrupt ccache state 构造 workload-level transition，而不是只依赖
   fixture-backed cache content oracle。
3. 为 `table_redirect.bpf.c` 构造 content-equivalent table oracle，记录 table entries、
   map memory、update writes、update latency 和 stale window。
4. 补 BuildKit/Prometheus Go cache path trace 和 policy-attached build witness。
5. 在 release run 中提高 repetitions，并把当前 smoke-level `SAMPLES=1` 结果明确保持为
   Phase 1 functional evidence。
