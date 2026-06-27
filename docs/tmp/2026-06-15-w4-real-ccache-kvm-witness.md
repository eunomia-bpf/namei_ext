# W4 真实 ccache KVM 见证实现记录

Last updated: 2026-06-15
Stage at update: Phase 1 implementation
Source/command: `make kvm-w4-ccache-real RUN_ID=20260615T-parent-key-poc`
Completeness: complete for a non-C8 real ccache transition witness

## 动机

W4 cache-locality family 此前已经有两类 KVM 证据：一类是
`w4-cache-oracle-entries.tsv` 上的 path oracle，另一类是 map-backed
`cache_rules` content oracle。它们可以证明 `cache_locality_view.bpf.c` 能沿真实
`cgroup/namei_ext` attach path 执行 verified-hit、stale-fallback、corrupt-reject 和
miss-canonical 分支，但它们的输入仍是 Make-owned cache fixtures，不是 ccache 真实
cold/hot 编译过程产生的 cache transition。

本步骤的目标是把 W4 向真实 workload 证据推进一步：在修改后的 kernel 的 KVM guest
中运行真实 `ccache`，对 Redis 和 nginx 的真实源码文件分别做 cold/hot 编译，记录
ccache 统计、object hash 和输入哈希；随后把 hot object 作为 ccache-derived backing
输入给现有 `cache_locality_view.bpf.c` content oracle。该步骤仍显式保持
`qualified_for_c8=false`，因为它还不是发布级 ccache cache-path trace，也没有证明
ccache 自身通过 `namei_ext` 访问 cache。

## 调研和检查的代码路径

- `mk/kvm.mk`：已有 KVM guest target、W4 path/content oracle 和共享
  `w1_oracle` runner。
- `mk/report.mk`：Phase 1 report hard gates、summary 生成和 dmesg/raw artifact
  列表。
- `Dockerfile`：runtime image 依赖列表。
- `Makefile`：`phase1` dependency graph 和 `make help` 文案。
- `workload/w4-ccache-redis-nginx/evidence.md`：W4 ccache workload 的真实来源和
  当前证据边界。
- `docs/research_plan.md`、`docs/experiment-plans/osdi-evaluation.md`、
  `docs/paper/evaluation.md`、`docs/paper/sections/04-implementation.tex` 和
  `docs/paper/sections/05-evaluation.tex`：长期计划和论文中的 W4 状态表述。

宿主机预检查确认：

- `ccache` 可用，版本为 4.9.1；
- `ccache --print-stats` 可用，当前版本不支持 `--format=json`；
- Redis `src/crc64.c` 和 nginx `src/core/ngx_string.c` 可以用 `ccache gcc -c`
  独立编译。

## 设计选择

新增 target 为 `make kvm-w4-ccache-real`。它依赖：

- 修改后的 kernel image；
- BPF policy build；
- W1 oracle/native workload source trees；
- Redis/nginx workload source build 目录。

guest target `__phase1_guest_w4_ccache_real` 在 KVM guest 中执行以下流程：

1. 挂载 bpffs、debugfs 和 cgroupfs。
2. 检查 `ccache`、Redis 源文件、nginx 源文件、`cache_locality_view.bpf.o` 和
   oracle runner 都存在。
3. 使用独立 `CCACHE_DIR` 清空 cache 和统计。
4. 对 Redis `src/crc64.c` 执行 cold/hot 两次 `ccache gcc -c`。
5. 对 nginx `src/core/ngx_string.c` 执行 cold/hot 两次 `ccache gcc -c`。
6. 保存 `w4-ccache-real-stats.txt`、`w4-ccache-real-outputs.sha256` 和
   `w4-ccache-real-ccache.version`。
7. 校验 Redis cold/hot object hash 相等、nginx cold/hot object hash 相等，并要求
   `cache_miss >= 2`、`direct_cache_hit >= 2`。
8. 生成 `w4-ccache-real-entries.tsv`，把两个 hot object 作为
   `verified_hit` backing。
9. 调用现有 `--cache-content` runner，attach `cache_locality_view.bpf.c`，验证两个
   ccache-derived object aliases 的 lookup/open/read/readdir/detach 语义。
10. 写出 `w4-ccache-real.jsonl`、`w4-ccache-real-inputs.sha256` 和
    `dmesg-w4-ccache-real.log`。

## 拒绝的替代方案

- 不把 ccache 统计写成 JSON。当前 ccache 4.9.1 没有 `--format=json`，因此 target
  使用 `ccache --print-stats` 的 key/value 输出，并在 Make target 中 fail-fast 解析
  必需字段。
- 不把真实 ccache 编译直接写成 C8 证据。该步骤没有 trace ccache 自身 cache path
  访问，也没有 operation-weighted hit rate、stale window、update writes 或 table-only
  counterfactual。
- 不新增 shell 脚本。所有流程都在 Makefile target 中表达，符合项目 Makefile-only
  约束。
- 不新增 YAML/JSON policy 配置。policy 仍是 `bpf/policies/cache_locality_view.bpf.c`；
  TSV 和 JSONL 是 workload/oracle 输入与 raw result，不是 policy language。

## 实现细节

新增和修改的 Makefile 入口：

- `Makefile`：`phase1` 现在包含 `kvm-w4-ccache-real`；`make help` 增加该 target。
- `mk/kvm.mk`：新增 `W4_CCACHE_REAL_*` 变量、`kvm-w4-ccache-real` 和
  `__phase1_guest_w4_ccache_real`。
- `mk/report.mk`：新增 hard gates，检查 ccache raw JSONL、input/output hashes、
  stats、entries TSV、object hash equality、cache miss/direct hit 数量、policy content
  oracle failure 数和 summary row。
- `Dockerfile`：runtime image 增加 `ccache`，使 Docker smoke 和 KVM guest 的
  package set 一致。

新的 raw artifacts 位于：

- `results/phase1/20260615T-parent-key-poc/w4-ccache-real.jsonl`
- `results/phase1/20260615T-parent-key-poc/w4-ccache-real-stats.txt`
- `results/phase1/20260615T-parent-key-poc/w4-ccache-real-outputs.sha256`
- `results/phase1/20260615T-parent-key-poc/w4-ccache-real-inputs.sha256`
- `results/phase1/20260615T-parent-key-poc/w4-ccache-real-entries.tsv`
- `results/phase1/20260615T-parent-key-poc/dmesg-w4-ccache-real.log`

## 验证结果

命令：

```text
make kvm-w4-ccache-real RUN_ID=20260615T-parent-key-poc
make docker-smoke RUN_ID=20260615T-parent-key-poc
make report RUN_ID=20260615T-parent-key-poc
```

当前结果：

- Redis `crc64.c` cold/hot object SHA256 均为
  `d242984f49cd453b93273ec4a67567dc1c71109ca283d3e13f2c39250291793b`。
- nginx `ngx_string.c` cold/hot object SHA256 均为
  `bd61b93452ad3a9af9a6b7f6357d8f15a88a4b98150b40958908ca7c6a569e73`。
- ccache stats：`cache_miss=2`、`direct_cache_hit=2`、`local_storage_hit=2`、
  `local_storage_write=4`、`files_in_cache=4`。
- `w4-cache-content-summary`：2 个 ccache-derived verified-hit branches，0 failure。
- `w4-ccache-real-summary`：`real_ccache_run=true`、`policy_executed=true`、
  `kvm_validated=true`、`output_hash_match=true`、`policy_content_oracle_failures=0`、
  `qualified_for_c8=false`。
- `w4-ccache-real-policy-scope`：`ccache_compile_policy_executed=false`、
  `policy_content_oracle_executed=true`、`qualified_for_c8=false`，用于机器可判定地区分
  ccache 编译阶段和后续 content oracle 阶段。
- `make report RUN_ID=20260615T-parent-key-poc` 已通过，summary 纳入
  `W4 Real Ccache Transition Witness`。

## 仍然不计入 C8 的原因

该 gate 只能说明两件事：

1. 真实 ccache cold/hot 编译在修改 kernel 的 KVM guest 中发生，并产生可审计的
   miss/hit 统计和 object hash equivalence；
2. `cache_locality_view.bpf.c` 能对这些 ccache-derived hot object 执行
   verified-hit content oracle。

它不能说明：

- ccache 自身的 cache file lookup 是通过 `namei_ext` policy 解析的；
- 发布级 workload 中有 operation-weighted policy cache hit rate；
- stale/corrupt state 来自真实 cache transition，而不是独立 content oracle；
- table-only baseline 在同等 table/update budget 下失败；
- W4 已经达到发布级 repetition、latency、stale-window 或 update-write 门槛。

因此所有新增 row 必须继续记录 `qualified_for_c8=false`。W4 进入 C1/C8 主结论前，
仍需补齐真实 ccache/BuildKit cache-path trace、compiler/go output hash 的发布级
oracle、operation-weighted hit rate、stale/corrupt transition provenance、
update/stale-window measurement 和 table/update budget counterfactual。
