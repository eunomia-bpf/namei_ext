# W4 Cache Content Oracle 实现记录

## 动机

W4 cache-locality family 原先只有 host cache witness manifest 和 KVM lookup/readdir
path oracle。它能证明 `cache_locality_view.bpf.c` 可以沿真实 `cgroup/namei_ext`
attach path 把 `object.o`、`stale.o`、`corrupt.o` 和 `pkg.mod` 解析到 backing
component，但第一版 content oracle 仍有两个证据缺口：runner 构造固定文件名，而不是从
`workload-w4-oracle-entries` 读取 entries；policy 也主要依赖 literal fallback，而不是
`cache_rules` map 的 cache-state dispatch。

本步骤增加并修订一个最小 KVM content oracle。目标不是声称真实 ccache/BuildKit 发布级
实验已经完成，而是把 W4 从纯 path oracle 推进到能验证 manifest-derived entries 沿
`cache_rules` map-backed state dispatch 影响普通 VFS open/read/readdir 的 Phase 1
functional evidence。

## 调研文件

- `bpf/policies/cache_locality_view.bpf.c`：确认 policy 有 `cache_rules` map、
  verified-hit、miss、stale 和 corrupt state dispatch，并保留 literal fallback 作为
  诊断路径。修订后 lookup/readdir 都先查 `cache_rules`，只有 map miss 才进入 literal
  fallback。
- `tests/w1_oracle/namei_ext_w1_oracle.c`：复用现有 libbpf open/load/attach/detach、
  JSONL emit、TSV parser、路径 materialization、map update 和 file comparison 代码。
- `mk/kvm.mk`：现有 KVM guest target 都在 guest 内 mount bpffs/debugfs/cgroup2，
  然后执行 runner。
- `mk/report.mk`：现有 report gate 以 JSONL hard checks 和 input sha256 manifest
  为准，失败即 fail-fast。
- `workload/w4-ccache-redis-nginx/evidence.md` 和
  `workload/w4-buildkit-prometheus-go-cache/evidence.md`：记录 W4 仍不能计入 C1/C8
  的证据边界。

## 设计选择

新增 target 是 `make kvm-w4-cache-content`，结果文件是
`results/phase1/<run-id>/w4-cache-content.jsonl`。该 target 依赖现有 BPF build、
共享 oracle runner 和 `workload-w4-oracle-entries`，而后者由
`workload-ccache-manifest` 和 `workload-buildkit-manifest` 生成。guest 内会校验 TSV
中每个 `original_backing_path` 的 SHA256，并写入包含 7 个输入的
`w4-cache-content-inputs.sha256`：W4 TSV、两个 cache manifest、policy source/object、
runner source/binary。

runner 新增 `--cache-content` 模式，在 guest 中读取
`w4-cache-oracle-entries.tsv`，按每条 entry 的 `parent_relative` 创建 workdir 子目录，
把 `original_backing_path` 复制成 `shadow_backing_component`，并保持
`visible_component` 在 attach 前不存在。runner 随后打开 `cache_locality_view.bpf.c`，
根据 entry branch 写入 `cache_rules`：

- `verified_hit` -> `CACHE_STATE_VERIFIED_HIT`；
- `stale_fallback`/`stale_canonical` -> `CACHE_STATE_STALE`；
- `corrupt_reject` -> `CACHE_STATE_CORRUPT`；
- `miss_canonical` -> `CACHE_STATE_MISS`。

同一 entry 会写 lookup 和 readdir 两个 map key：lookup key 从 visible component
指向 shadow backing，readdir key 从 shadow backing 指回 visible component。map value
还带一个来自 manifest SHA256 prefix 的 bounded hash witness；当前只验证 witness
一致性，不验证真实 compiler/go output hash。

为了提供负控，runner 为有明确反例的分支额外创建 forbidden decoy：

- `verified_hit` 的 `object.bad`；
- `stale_fallback` 的 `stale.local`；
- `corrupt_reject` 的 `corrupt.local`。

attach `cache_locality_view.bpf.c` 后，runner 用普通 VFS open/read/readdir 检查：

- `object.o` 匹配 `object.local`，且不匹配 `object.bad`；
- `stale.o` 匹配 `stale.canon`，且不匹配 `stale.local`；
- `corrupt.o` 匹配 `corrupt.reject`，且不匹配 `corrupt.local`；
- `pkg.mod` 匹配 `pkg.canon`；
- 四个 alias 在各自 TSV parent directory 的 readdir 中可见，对应 backing name 被隐藏；
- detach 后四个 alias 都不可达。

所有 case 的 `result_level` 是 `kvm_cache_content_oracle`。summary 仍写
`qualified_for_c8=false`，因为该 oracle 仍不运行真实 ccache/BuildKit，也不测真实
cache transition、output hash、update writes、stale window 或 table/update budget。

## 拒绝的替代方案

- 不把该 oracle 写成 host-only test。Phase 1 validation 必须跑修改内核 KVM。
- 不通过直接检查 `.bpf.o` 或 verifier log 来替代 VFS open/read/readdir。该 oracle 必须
  经过真实 `cgroup/namei_ext` attach path。
- 不新增 shell 脚本。所有入口都由 Make target 管理。
- 不把 W4 升级为 `qualified_for_c8`。当前结果没有真实 ccache/BuildKit run、compiler/go
  output hash、cache transition trace、update writes、stale window 或 table/update
  budget counterfactual。
- 不把 literal fallback 当成 Phase 1 W4 content gate。fallback 可以保留为诊断路径，
  但 `kvm-w4-cache-content` 必须从 W4 TSV 填充 `cache_rules` 并检查 `map_update`。

## 实现内容

- `tests/w1_oracle/namei_ext_w1_oracle.c`
  - 新增 `--cache-content` mode；
  - 新增 `emit_cache_case`；
  - 新增 `struct cache_rule`、branch-to-state 映射和 `cache_rules` map update；
  - 新增 TSV-derived cache workdir materialization；
  - 新增 expected-content match、forbidden-content mismatch、readdir alias 和 post-detach
    checks。
- `bpf/policies/cache_locality_view.bpf.c`
  - lookup/readdir 改为 map-first：先查 `cache_rules`，map miss 再进入 literal fallback。
- `mk/kvm.mk`
  - 新增 `W4_CACHE_CONTENT_JSON` 和 `W4_CACHE_CONTENT_WORK_DIR`；
  - 新增 `kvm-w4-cache-content` 和 `__phase1_guest_w4_cache_content`；
  - target 依赖 `workload-w4-oracle-entries`；
  - guest 内校验 TSV backing SHA256，写入 `w4-cache-content-inputs.sha256` 并执行 runner。
- `Makefile`
  - `phase1` 默认流程加入 `kvm-w4-cache-content`；
  - `help` 加入对应 target。
- `mk/report.mk`
  - 新增 `w4-cache-content.jsonl` 和 `w4-cache-content-inputs.sha256` 存在性检查；
  - 校验 7 个输入哈希精确匹配，并要求 JSON input event 记录 `entries_tsv`；
  - gate `w4-cache-content-start=1`、`map_update=1` 和 `w4-cache-content-done=1`；
  - gate `pre_attach_absent=4`、`attached_expected_match=4`、
    `attached_forbidden_mismatch=3`、`readdir_alias=4`、`post_detach_absent=4`、
    summary 0 failure；
  - summary report 增加 W4 cache content section 和 raw artifact 列表。
- 文档
  - 更新 W4 workload evidence、research plan、OSDI evaluation plan 和 paper sections，
    明确该 oracle 的价值和边界。

## 验证

本步骤已运行：

```text
make w1-oracle
make kvm-w4-cache-content RUN_ID=20260614T-w4-cache-content-map
sha256sum -c results/phase1/20260614T-w4-cache-content-map/w4-cache-content-inputs.sha256
make phase1 RUN_ID=20260614T-w4-cache-content-map-phase1 SAMPLES=1 BENCH_ITERS=2000
make -C docs/paper paper
make -C docs/paper check
rg -n "Undefined control sequence|LaTeX Warning: Reference|Citation.*undefined|Overfull|Fatal error|Emergency stop" .build/paper/main.log
git diff --check
find . -path ./kernel -prune -o -path ./.build -prune -o -path ./.cache -prune -o -path ./results -prune -o -name '*.sh' -print
```

`w4-cache-content.jsonl` 的 summary：

```text
event=w4-cache-content-summary
branches=4
pass=true
failures=0
qualified_for_c8=false
detail=manifest-derived W4 cache content oracle passed
```

Targeted KVM run 的对应结果位于：

```text
results/phase1/20260614T-w4-cache-content-map/w4-cache-content.jsonl
results/phase1/20260614T-w4-cache-content-map/w4-cache-content-inputs.sha256
```

完整 Phase 1 run 的对应结果位于：

```text
results/phase1/20260614T-w4-cache-content-map-phase1/w4-cache-content.jsonl
results/phase1/20260614T-w4-cache-content-map-phase1/w4-cache-content-inputs.sha256
results/phase1/20260614T-w4-cache-content-map-phase1/summary.md
```

raw case 覆盖：

- 1 个 TSV read；
- 1 个 manifest-derived workdir materialize；
- 4 个 pre-attach absent；
- 1 个 `cache_rules` map update；
- 4 个 expected content match；
- 3 个 forbidden content mismatch；
- 4 个 readdir alias；
- 4 个 post-detach absent。

完整 Phase 1 report 还记录：

- `W4 cache content failing cases: 0`；
- `W4 cache content summary failures: 0`；
- `Dmesg warning/oops/panic lines: 0`。

LaTeX build 和 check 均通过；log grep 没有 undefined reference/citation、overfull 或
fatal error；`git diff --check` 没有输出；项目源码树中没有新增 project-owned `.sh`。

## 剩余风险

- 该 oracle 使用 Make-owned fixture，不是真实 ccache 或 BuildKit 执行。
- 当前没有 compiler/go output hash，也没有 cache hit/miss/stale transition log。
- 当前没有 table-only 同等 table/update budget counterfactual；`table_redirect.bpf.c` 已能通过
  W4 path oracle，因此 C8 仍不能成立。
- 当前没有多 worker、cache churn、stale window 或 corrupted-cache stress。
