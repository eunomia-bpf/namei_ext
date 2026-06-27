# W4 ccache trace-to-policy bridge KVM 见证实现记录

最近更新：2026-06-15
更新阶段：第一阶段实现
来源/命令：`make kvm-w4-ccache-policy-bridge RUN_ID=20260615T-parent-key-poc`
完整性：已完成非 C8 trace-derived policy oracle bridge

## 动机

上一阶段的 `kvm-w4-ccache-trace` 已证明真实 `ccache` hot compile 在修改后的
kernel KVM guest 中会访问 `CCACHE_DIR`，但它没有 attach `namei_ext` policy，因此
只能说明真实 workload path 存在，不能说明这些 cache object component 能被
`cache_locality_view.bpf.c` 消费。

本步骤补一个最小 bridge：从真实 `strace` raw log 中抽取成功读取的 cache object
path，把这些 path 转换为 W4 content oracle TSV，再在 KVM guest 中 attach
`cache_locality_view.bpf.c` 跑 lookup、readdir 和 detach oracle。它的目标是建立
“真实 ccache trace object -> policy map key/value -> VFS oracle”的证据链。

该步骤仍不是 C8 证据。真实 ccache 编译阶段没有执行 `namei_ext` policy；policy 只在
trace-derived content oracle 中执行。因此它不能被写成 operation-weighted policy
cache hit rate。

## 调研和检查的代码路径

- `mk/kvm.mk`：已有 `kvm-w4-ccache-trace`、KVM guest target 模式、W4 ccache 结果路径。
- `tests/w1_oracle/namei_ext_w1_oracle.c`：`--cache-content` runner 的 TSV schema、
  workdir materialization、`cache_rules` map 填充、lookup/readdir/detach oracle。
- `bpf/policies/cache_locality_view.bpf.c`：`verified_hit`、`miss`、`stale` 和
  `corrupt` 的 `cache_rules` dispatch。
- `mk/report.mk`：Phase 1 hard gate、summary 和 raw artifact 列表。
- `docs/research_plan.md`、`docs/experiment-plans/osdi-evaluation.md`、
  `docs/paper/sections/04-implementation.tex`、
  `docs/paper/sections/05-evaluation.tex` 和
  `workload/w4-ccache-redis-nginx/evidence.md`：W4 evidence ledger 和 overclaim 边界。

## 设计选择

新增 target 为 `make kvm-w4-ccache-policy-bridge`，依赖
`kvm-w4-ccache-trace`、`bpf` 和 `w1-oracle`。单独执行该 target 时会先在 KVM 中刷新
真实 ccache trace，然后再次启动 KVM guest 执行 bridge oracle。

guest target `__phase1_guest_w4_ccache_policy_bridge` 执行以下流程：

1. 检查 trace JSONL、trace input/artifact SHA256、Redis/nginx strace log、真实
   `CCACHE_DIR`、policy source/object 和 oracle runner source/binary。
2. 从 Redis/nginx strace log 中抽取满足以下条件的 path：位于 `CCACHE_DIR`、
   `openat(...)`、包含 `O_RDONLY`、返回成功文件描述符，并排除 `ccache.conf`、stats、
   lock 和 tmp 文件。
3. 写出 `w4-ccache-policy-bridge-trace-objects.txt`，每行记录 workload label 和真实
   cache object path。
4. 要求 Redis 和 nginx 都至少有一个 trace object，总数不超过 runner 上限。
5. 将 trace object 转换成
   `w4-ccache-policy-bridge-entries.tsv`。每行使用
   `verified_hit` 分支、`trace-derived/<redis|nginx>/<ccache-parent>` parent-relative
   目录、真实 cache object basename 作为 visible component、`<basename>.local`
   作为 shadow component，并用真实 cache object SHA256 绑定 backing。
6. 检查 TSV 8 列 schema、component 长度、路径不越界、每个 original path 存在且
   SHA256 匹配。
7. 写出 `w4-ccache-policy-bridge-inputs.sha256`，覆盖 trace JSONL、trace SHA256
   manifests、raw strace logs、trace object list、generated TSV、policy source/object 和
   runner source/binary。
8. 调用现有 runner：
   `namei_ext_w1_oracle --cache-content ... cache_locality_view.bpf.o`。
9. 要求 attached expected match、forbidden mismatch、readdir alias、pre-attach absent
   和 post-detach absent 的数量都等于 trace-derived entry 数量。
10. 写出 `w4-ccache-policy-bridge-summary` 和
    `w4-ccache-policy-bridge-policy-scope`，明确
    `ccache_compile_policy_executed=false`、
    `trace_derived_policy_oracle_executed=true` 和
    `qualified_for_c8=false`。

## 拒绝的替代方案

- 不直接把真实 ccache 编译包在 policy attach window 里伪称 release hit rate。当前
  ABI 和 workload harness 尚未把 ccache 的真实 cache directory operations 映射成
  release-level policy hit-rate 计数。
- 不手写新的 C runner。已有 `--cache-content` runner 已覆盖 map update、attach、
  lookup、readdir 和 detach；新增逻辑只负责从 raw trace 生成 TSV。
- 不引入 shell 脚本或 YAML/JSON policy 配置。所有 orchestration 仍在 Makefile 中，
  policy 仍是 `bpf/policies/cache_locality_view.bpf.c`。
- 不把该 bridge 计入 C8。它只证明 trace-derived cache object component 可被 policy
  oracle 消费，不能证明真实 ccache compile 的 operation-weighted policy cache hit rate。

## 实现细节

代码变更：

- `Makefile`
  - 默认 `phase1` 增加 `kvm-w4-ccache-policy-bridge`。
  - `make help` 增加该 target。
- `mk/kvm.mk`
  - 新增 `W4_CCACHE_BRIDGE_JSON`、`W4_CCACHE_BRIDGE_WORK_DIR`、
    `W4_CCACHE_BRIDGE_ENTRIES_TSV` 和 `W4_CCACHE_BRIDGE_TRACE_OBJECTS`。
  - 新增 `kvm-w4-ccache-policy-bridge` 与
    `__phase1_guest_w4_ccache_policy_bridge`。
- `mk/report.mk`
  - 新增 raw artifact 存在性检查和 `w4-ccache-policy-bridge-inputs.sha256`
    校验。
  - 从 raw Redis/nginx strace logs 重新抽取成功 cache object reads，并要求与
    `w4-ccache-policy-bridge-trace-objects.txt` 完全一致。
  - 检查 generated TSV schema、original file SHA256、Redis/nginx entry count、KVM
    policy oracle 的 per-op 数量、summary row 和 policy-scope row。
  - Summary 增加 `W4 Trace-Derived Ccache Policy Bridge` 小节和 raw artifacts。

新增 raw artifacts：

- `results/phase1/20260615T-parent-key-poc/w4-ccache-policy-bridge.jsonl`
- `results/phase1/20260615T-parent-key-poc/w4-ccache-policy-bridge-inputs.sha256`
- `results/phase1/20260615T-parent-key-poc/w4-ccache-policy-bridge-trace-objects.txt`
- `results/phase1/20260615T-parent-key-poc/w4-ccache-policy-bridge-entries.tsv`
- `results/phase1/20260615T-parent-key-poc/dmesg-w4-ccache-policy-bridge.log`

## 验证结果

已执行：

```text
make kvm-w4-ccache-policy-bridge RUN_ID=20260615T-parent-key-poc
make report RUN_ID=20260615T-parent-key-poc
```

当前结果：

- Redis trace-derived cache objects：2 个。
- nginx trace-derived cache objects：2 个。
- 总 trace-derived entries：4 个。
- `w4-cache-content` 的 `attached_expected_match`：4 个。
- `w4-cache-content` 的 `attached_forbidden_mismatch`：4 个。
- `w4-cache-content` 的 `readdir_alias`：4 个。
- `w4-cache-content-summary.failures=0`。
- `w4-ccache-policy-bridge-summary.policy_content_oracle_failures=0`。
- `ccache_compile_policy_executed=false`。
- `trace_derived_policy_oracle_executed=true`。
- `qualified_for_c8=false`。

`make report` 通过，说明 raw trace 重新抽取、trace object list、generated TSV、SHA256、
policy oracle JSONL 和 summary row 已经被 hard gate 覆盖。

## 仍然不计入 C8 的原因

该 gate 可以支撑以下窄结论：

- 真实 ccache hot compile trace 中的 cache object path 可以被抽取成可审计 TSV；
- 这些真实 cache object component 能在 KVM guest 中作为
  `cache_locality_view.bpf.c` map-backed verified-hit entries 执行；
- lookup、readdir 和 detach 行为均通过现有 content oracle；
- report 会从 raw trace 重新计算关键输入，避免 JSONL 自证。

它不能支撑：

- 真实 ccache 编译期间执行了 `namei_ext` policy；
- operation-weighted policy cache hit rate；
- 真实 stale/corrupt ccache transition；
- BuildKit/Prometheus Go cache workload；
- stale window、update writes 或 table/update budget counterfactual；
- C1/C8 发布级性能或可编程性主张。

下一步应转向 release-level cache-locality workload：要么把真实 ccache cache path
operation 接入 policy attach window 并记录 operation-weighted hit rate，要么补
BuildKit/Prometheus Go cache-path trace 与 output hash oracle。上述任一路径都还需要
table/update budget counterfactual。

## 后续状态更新

同日后续实现 `make kvm-w4-ccache-policy-compile
RUN_ID=20260615T-parent-key-poc` 已把真实 Redis/nginx ccache hot compile 放进
`cache_locality_view.bpf.c` attach window。该更新记录在
`docs/tmp/2026-06-15-w4-real-ccache-policy-attached-compile.md`。它证明 sampled hot
compile 可以通过 `namei_ext` policy 消费 trace-derived cache objects，并保持 output
object hash 与 baseline hot object 一致。

这不改变本文档的 C8 判断：新的 compile witness 仍不是 release-level
operation-weighted policy cache hit rate，也没有真实 stale/corrupt transition、
BuildKit/Prometheus Go cache workload 或 table/update budget counterfactual。
