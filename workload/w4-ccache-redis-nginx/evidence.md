# w4-ccache-redis-nginx 证据

> 2026-06-29 baseline scope update: older gate language is superseded by claim-driven baseline selection. Exact-map diagnostics are optional and only relevant when precomputed mapping is the competing claim.


状态：`functional_only_kvm_path_oracle` + `kvm_cache_content_oracle` +
`kvm_real_ccache_workload_witness` + `kvm_real_ccache_cache_path_trace_witness` +
`kvm_real_ccache_policy_bridge_witness` + `kvm_real_ccache_policy_compile_witness` +
`kvm_real_ccache_parent_rule_compile_witness` + `kvm_real_ccache_table_compile_witness` +
`kvm_release_counterfactual_accounting`；
不能计入 C1/C8。

Policy family：`cache_locality_view.bpf.c`

## 真实来源

- ccache manual: https://ccache.dev/manual/4.13.1.html
- Redis repository: https://github.com/redis/redis
- nginx source downloads: https://nginx.org/en/download.html

## 已固定的 provenance

- 固定 Redis 源码版本：Redis `7.2.14`
- Redis source tarball SHA256：`704bfac84ab1c0771ddc08c8bea72e2203e3ce64c1fc6750e76b8ce2c00f3145`
- 固定 nginx 源码版本：nginx `1.26.3`
- nginx source tarball SHA256：`69ee2b237744036e61d24b836668aad3040dda461fe6f570f1787eab570c75aa`
- Source provenance targets：`make workload-redis-build-fetch`、`make workload-nginx-build-fetch`
- Source provenance results：`results/workloads/provenance/redis-source.json`、
  `results/workloads/provenance/nginx-source.json`

## 当前 path/content/ccache oracle witness

Phase 1 已有八层 W4 witness。

第一层是 Make-owned cache witness fixtures。它们把 hit/stale entries 的内容绑定到
固定 Redis/nginx source hash，并在 KVM guest 中验证 lookup/readdir redirect。

第二层是 cache content oracle：它在同一修改内核 KVM guest 内读取
`w4-cache-oracle-entries.tsv`，按 `parent_relative` 构造 workdir，把 manifest 中的
`original_backing_path` materialize 成 `shadow_backing_component`，再填充
`cache_locality_view.bpf.c` 的 `cache_rules` map，检查 verified hit、stale fallback、
corrupt reject 和 miss canonical 四类分支的内容选择。

第三层是新增的真实 ccache transition witness：`make kvm-w4-ccache-real
RUN_ID=20260615T-full-phase1-gatefix` 在修改后的 kernel KVM guest 中运行真实 `ccache`，
对 Redis `src/crc64.c` 和 nginx `src/core/ngx_string.c` 分别执行 cold/hot 两次
`ccache gcc -c`。该 target 保存 ccache 统计、cold/hot object hash 和输入哈希，然后
把 hot object 作为 ccache-derived backing 写入 `w4-ccache-real-entries.tsv`，并用
`cache_locality_view.bpf.c` 跑 verified-hit content oracle。

第四层是真实 ccache cache-path trace witness：`make kvm-w4-ccache-trace
RUN_ID=20260615T-full-phase1-gatefix` 在同一修改内核 KVM guest 中先用独立
`CCACHE_DIR` 对 Redis/nginx 编译单元完成 cold compile 暖 cache，再用
`strace -f -e trace=%file` 采集两个 hot compile 的真实 file operations，并要求两个
trace 都实际触碰 `CCACHE_DIR`。该 target 不 attach `namei_ext` policy，记录
`policy_executed=false`。

第五层是 trace-derived ccache policy bridge：`make kvm-w4-ccache-policy-bridge
RUN_ID=20260615T-full-phase1-gatefix` 从第四层 raw strace logs 中抽取成功读取的真实
ccache cache object paths，生成 `w4-ccache-policy-bridge-entries.tsv`，再在 KVM guest
中 attach `cache_locality_view.bpf.c` 跑 content oracle。该 target 证明真实 trace
object component 能被 policy oracle 消费，但真实 ccache compile 阶段仍没有执行
`namei_ext` policy。

第六层是真实 ccache policy-attached compile witness：`make kvm-w4-ccache-policy-compile`
在修改后的 kernel KVM guest 中复制真实 `CCACHE_DIR`，把 trace-derived visible object
renamed 成 policy backing，并在 attach `cache_locality_view.bpf.c` 的窗口内运行真实
Redis/nginx hot compile。该 target 比 bridge 更强，因为真实 `ccache gcc -c` 子进程在
policy attach window 内运行，输出 object 与 baseline hot object byte-for-byte 一致；但它仍是
sampled compile witness，不是 release-level operation-weighted policy cache hit rate。

第七层是 parent-scoped ccache compile witness：`make kvm-w4-ccache-parent-compile`
使用 parent-scoped cache rule，而不是每个 object 一条 exact lookup rule。该 target
保留 output hash oracle，同时检查 `metadata.txt` 这类非 object-shape sibling PASS、合法形状
但非 witness sibling 在 `.local` backing 不存在时 PASS，以及一个合法形状 sibling exact-text
content oracle PASS。该 witness 证明 parent-scoped policy 的边界，但仍只有 4 个 sampled
trace objects。

第八层是 exact-map diagnostic comparator 与 release counterfactual accounting：
`make kvm-w4-ccache-table-compile` 用同一份 sampled ccache witness 运行
`table_redirect.bpf.c` exact redirects；该 comparator 通过，因而是 C8 的负面证据。
`make kvm-w4-ccache-release-counterfactual RUN_ID=20260615T-full-phase1-gatefix`
把真实 ccache trace、parent-scoped compile、exact-map diagnostic comparator 和 attach-window
optrace 汇总成 accounting row，并保持 `qualified_for_c8=false`。

- Cache witness manifest target：`make workload-ccache-manifest`
- Combined W4 TSV target：`make workload-w4-oracle-entries`
- KVM path oracle target：`make kvm-w4-oracle`
- KVM cache content oracle target：`make kvm-w4-cache-content`
- KVM real ccache transition target：`make kvm-w4-ccache-real`
- KVM real ccache cache-path trace target：`make kvm-w4-ccache-trace`
- KVM trace-derived ccache policy bridge target：`make kvm-w4-ccache-policy-bridge`
- KVM real ccache policy-attached compile target：`make kvm-w4-ccache-policy-compile`
- KVM parent-scoped ccache compile target：`make kvm-w4-ccache-parent-compile`
- KVM exact-map ccache compile diagnostic target：`make kvm-w4-ccache-table-compile`
- KVM release counterfactual accounting target：`make kvm-w4-ccache-release-counterfactual`
- Cache witness manifest：
  `results/workloads/runs/20260615T-full-phase1-gatefix/w4-ccache-redis-nginx/cache-manifest.json`
- Combined W4 TSV：
  `results/workloads/runs/20260615T-full-phase1-gatefix/w4-cache-oracle-entries.tsv`
- KVM raw result：
  `results/phase1/20260615T-full-phase1-gatefix/w4-oracle.jsonl`
- KVM input hash manifest：
  `results/phase1/20260615T-full-phase1-gatefix/w4-oracle-inputs.sha256`
- KVM cache content raw result：
  `results/phase1/20260615T-full-phase1-gatefix/w4-cache-content.jsonl`
- KVM cache content input hash manifest：
  `results/phase1/20260615T-full-phase1-gatefix/w4-cache-content-inputs.sha256`
- KVM real ccache raw result：
  `results/phase1/20260615T-full-phase1-gatefix/w4-ccache-real.jsonl`
- KVM real ccache stats：
  `results/phase1/20260615T-full-phase1-gatefix/w4-ccache-real-stats.txt`
- KVM real ccache output hash manifest：
  `results/phase1/20260615T-full-phase1-gatefix/w4-ccache-real-outputs.sha256`
- KVM real ccache policy entries：
  `results/phase1/20260615T-full-phase1-gatefix/w4-ccache-real-entries.tsv`
- KVM real ccache trace raw result：
  `results/phase1/20260615T-full-phase1-gatefix/w4-ccache-trace.jsonl`
- KVM real ccache trace logs：
  `results/phase1/20260615T-full-phase1-gatefix/w4-ccache-trace-redis.strace.log`、
  `results/phase1/20260615T-full-phase1-gatefix/w4-ccache-trace-nginx.strace.log`
- KVM real ccache trace artifact hash manifest：
  `results/phase1/20260615T-full-phase1-gatefix/w4-ccache-trace-artifacts.sha256`
- KVM trace-derived ccache policy bridge raw result：
  `results/phase1/20260615T-full-phase1-gatefix/w4-ccache-policy-bridge.jsonl`
- KVM trace-derived ccache policy bridge trace objects：
  `results/phase1/20260615T-full-phase1-gatefix/w4-ccache-policy-bridge-trace-objects.txt`
- KVM trace-derived ccache policy bridge entries：
  `results/phase1/20260615T-full-phase1-gatefix/w4-ccache-policy-bridge-entries.tsv`
- KVM trace-derived ccache policy bridge input hash manifest：
  `results/phase1/20260615T-full-phase1-gatefix/w4-ccache-policy-bridge-inputs.sha256`
- KVM parent/table/release counterfactual canonical full-root raw results：
  `results/phase1/20260615T-full-phase1-gatefix/w4-ccache-parent-compile.jsonl`、
  `results/phase1/20260615T-full-phase1-gatefix/w4-ccache-table-compile.jsonl`、
  `results/phase1/20260615T-full-phase1-gatefix/w4-ccache-release-counterfactual.jsonl`

当前 witness entries：

- `cache/object.o -> object.local`，分支 `verified_hit`
- `cache/stale.o -> stale.canon`，分支 `stale_fallback`
- `cache/corrupt.o -> corrupt.reject`，分支 `corrupt_reject`

当前 path oracle 只检查 attach 前 alias 不存在、attach 后 lookup 内容匹配、
readdir alias/backing 一致性和 detach 后 alias 不可达。`cache_locality_view.bpf.c`
和 `table_redirect.bpf.c` 在 W4 全部 4 个 entries 上均为 0 failure；summary
显式记录 `qualified_for_c8=false`。修订后的 cache content oracle 额外要求
`cache_rules` map update 成功，且 input hash manifest 必须包含 W4 TSV、两个 cache
manifest、policy source/object 和 runner source/binary。

Cache content oracle 额外检查：

- `object.o` 只能解析到 `object.local`，并且不等于 `object.bad`；
- `stale.o` 只能解析到 `stale.canon`，并且不等于 `stale.local`；
- `corrupt.o` 只能解析到 `corrupt.reject`，并且不等于 `corrupt.local`；
- `pkg.mod` 解析到 `pkg.canon`；
- 四个 alias 在 readdir 中可见，对应 backing name 被隐藏；
- detach 后四个 alias 都重新不可达。

`w4-cache-content.jsonl` 的 summary 为 0 failure，仍显式记录
`qualified_for_c8=false`。它证明 manifest-derived W4 entries 能沿 `cache_rules`
map-backed state dispatch，在真实 KVM attach path 中影响普通 VFS open/read/readdir；
该 cache-content gate 本身不证明真实 ccache hit/miss 统计、BuildKit cache mount 行为、
compiler/go output hash、cache transition trace、stale window、update writes 或
workload-appropriate baseline gap。

`w4-ccache-real.jsonl` 的 ccache row 记录：

- `real_ccache_run=true`
- `run_environment=kvm`
- `cache_miss=2`
- `direct_cache_hit=2`
- `local_storage_hit=2`
- `local_storage_write=4`
- `files_in_cache=4`
- Redis cold/hot object hash：
  `d242984f49cd453b93273ec4a67567dc1c71109ca283d3e13f2c39250291793b`
- nginx cold/hot object hash：
  `bd61b93452ad3a9af9a6b7f6357d8f15a88a4b98150b40958908ca7c6a569e73`

随后同一 JSONL 中的 `w4-cache-content-summary` 记录两个 ccache-derived
`verified_hit` branches，0 failure；`w4-ccache-real-summary` 记录
`policy_executed=true`、`kvm_validated=true`、`output_hash_match=true` 和
`policy_content_oracle_failures=0`；`w4-ccache-real-policy-scope` 记录
`ccache_compile_policy_executed=false` 和 `policy_content_oracle_executed=true`。
该结果证明真实 ccache cold/hot transition 能产生
可审计的 Redis/nginx object，并且这些 object 可以被 W4 policy content oracle 消费。
它仍不证明 ccache 自身的 cache path 通过 `namei_ext` 解析，也不证明
operation-weighted policy cache hit rate、真实 stale/corrupt transition、
stale/update window 或 workload-appropriate baseline gap。

`w4-ccache-trace.jsonl` 的 trace row 记录：

- `real_ccache_run=true`
- `ccache_cache_path_trace=true`
- `policy_executed=false`
- Redis hot compile：134 条 file-op trace，其中 20 条触碰 `CCACHE_DIR`
- nginx hot compile：602 条 file-op trace，其中 20 条触碰 `CCACHE_DIR`
- `cache_path_file_ops=40`
- `cache_miss=2`
- `direct_cache_hit=2`
- `operation_weighted_policy_cache_hit_rate=false`
- `qualified_for_c8=false`

该结果证明真实 ccache hot path 在修改内核的 KVM guest 中实际访问 cache directory；
它仍不证明这些访问由 `namei_ext` policy 决策，也不提供 operation-weighted policy
cache hit rate。

`w4-ccache-policy-bridge.jsonl` 的 bridge summary 记录：

- `real_ccache_trace_basis=true`
- `trace_derived_policy_oracle_executed=true`
- `ccache_compile_policy_executed=false`
- Redis trace-derived cache objects：2 个
- nginx trace-derived cache objects：2 个
- 总 trace-derived entries：4 个
- `policy_content_oracle_failures=0`
- `qualified_for_c8=false`

该结果证明第四层 raw trace 中真实成功读取的 ccache cache object component 可以生成
policy TSV，并在 KVM 中通过 `cache_locality_view.bpf.c` 的 verified-hit content
oracle：4 个 attached expected match、4 个 forbidden mismatch、4 个 readdir alias
和 4 个 detach 后 absent 检查全部通过。后续 policy-attached compile、parent-scoped
compile、exact-map diagnostic comparator 和 release counterfactual accounting 已经补上真实
`ccache gcc -c` attach-window witness；但它们仍不提供 release-level operation-weighted
policy cache hit rate。

## 发布级 oracle 仍需完成

- 固定 ccache version、compiler version、cache manifest SHA256 和 build input lock 到
  release-level run manifest。
- release-level operation-weighted policy cache hit rate，而不是当前 sampled attach-window
  proxy。
- BuildKit/Prometheus Go cache-path trace 与 output hash oracle。
- 发布级 compiler output hash、local/remote cache hit/miss/stale/corrupt branch coverage、
  stale/corrupt 0 unexpected hit、update writes、stale window 和 lookup/readdir visible set checker。
- claim-driven baseline comparison or optional exact-map diagnostic。
