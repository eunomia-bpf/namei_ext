# 评估草稿

状态：计划级草稿，不能包含未由原始结果证明的数字。

2026-06-29 story scope update：当前权威口径是 balanced dynamic path-view abstraction。
本文档较早段落中所有把 `optional exact-map diagnostic`、workload-specific baseline
advantage 或单一 claim-specific comparison 写成默认 C8/B12 gate 的表述都已被
`docs/tmp/2026-06-29-paper-story-scope-update.md` 覆盖。FUSE/custom FS、kernel
modification 和 static/materialized mechanisms 是 conceptual comparisons；
workload-specific baselines 只服务各自 claim；exact-map diagnostics 只在 claim 明确讨论
预计算映射时使用。

2026-06-18 同步说明：当前权威论文正文是 `docs/paper/sections/05-evaluation.tex`。本 Markdown 仍作为计划和 handoff 文档保留；它不能覆盖 claim verdict v17 的边界。当前可写正结果只包括 W2 nginx sandbox fixture setup/materialization slice、tool-redirect lookup/access/open/exec latency slice 和 W1-W4 Phase 1 lookup/readdir matrix；W3 Redis checkpoint-view macrobench 是阈值负结果，且不等同于真实 Podman/CRIU restore。

来源文档：

- [OSDI 级评估设计](../experiment-plans/osdi-evaluation.md)
- [研究计划](../research_plan.md)

## 评估问题

最终发布级评估将评估 `namei_ext` 是否能作为一个窄 VFS path-resolution eBPF
extension point，在不实现文件系统 data path 的前提下，为动态 path views 提供
expressiveness、safety 和 efficiency 的更好平衡。当前本文只报告 Phase 1 functional
evidence，并把性能、C8 和 artifact reproducibility 作为尚未完成的 gates。

发布级评估将回答五个问题：

1. **表达力**：同一个 kernel ABI 能否承载四类语义不同的 eBPF policy family：
   build graph、sandbox fixture、checkpoint/restore 和 content-verified cache
   locality？
2. **正确性**：lookup、open、access、exec 和 readdir 是否在每个 policy family
   下满足 usecase-specific oracle，并保留 lower filesystem permission 语义？
3. **性能**：相比 conceptual alternatives 和 workload-specific baselines，`namei_ext`
   是否在已测 slice 中降低 setup/materialization 成本，并保持可接受的 p99 metadata latency？
4. **平衡点**：`namei_ext` 是否能在动态 path view 上同时保留表达力、内核拥有的
   filesystem safety boundary 和效率？exact-map counterfactual 只在 claim 明确讨论预计算映射时使用。
5. **边界和 artifact**：系统在规模、失败语义、verifier/runtime failure 和干净
   checkout KVM 复现上是否有明确边界？

## Claim 和 gate 速查

`C1` 表示同一窄 VFS path-resolution ABI 承载多类真实 eBPF policy family；`C8`
表示动态 path view abstraction 在 expressiveness/safety/efficiency 上的平衡。当前
W1-W4 都是 `functional_only`，尚无 `qualified_for_c8` row。`B1` 是路径解析正确性和
lookup/readdir 一致性矩阵，`B10` 是健壮性和失败语义，`B12` 是 policy-family
programmability 与 exact-map diagnostic。

## 实验设置

所有发布级结果必须在改过的 kernel 的 KVM guest 中产生。Host-only 结果只能用于
开发诊断，不能进入主表或主图。每个 run 必须记录：

- main repo 和 kernel submodule commit、dirty 状态；
- kernel image SHA256、kernel config SHA256、boot command line；
- Docker image ID/tar SHA256；
- policy source/object SHA256、verifier log、instruction count、map schema；
- workload source URL、version/commit、input manifest、trace hash、alias manifest；
- baseline config、feature-equivalence decision、seed、repetition、variant order；
- dmesg、stdout/stderr、raw JSONL、checker output 和 analysis version。

发布级 repetition 策略与评估设计保持一致：Phase 1 B2/B8 release-input 和负 verdict
gate 使用至少 20 次微基准重复、每条 latency row 至少 64 个操作；宏基准至少 20 次重复。
这些输入足以阻止或拒绝 C2/C3/C5，但不能单独支持正向性能主张。若后续要把 C3/C5 写成
投稿级正向结论，最终 paper figure 应升级到至少 30 次微基准重复，或在 artifact audit
中显式说明较低重复数的统计风险。所有发布级结果都必须随机化 variant 顺序，并报告
median、p95、p99、95% bootstrap confidence interval、绝对值和相对值。任何
checker failure、unexpected errno、dmesg warning/oops/panic 或 manifest 缺字段都会使
对应 figure/table cell 失败。

## 工作负载

所有 workload 都必须来自真实项目、真实部署机制或真实系统文档，不能用
hello-world 程序或随机目录树支撑主结论。下表描述的是发布级计划 workload；
“当前状态”列记录截至 2026-06-15 已经实现的证据级别，不能把发布级计划误读成当前结果。

| ID | Family | 发布级计划 workload | 当前状态 | 真实依据 | Evidence path | 发布级主要信号 |
|----|--------|---------------------|----------|----------|---------------|----------------|
| `w1-redis-build` | build graph | Redis 源码构建和 file-operation trace | `functional_only` host build-output oracle + KVM path oracle + KVM policy preprocessing replay witness + KVM policy release-binary replay witness + KVM branch probes | 固定 commit 的 [Redis Makefile](https://github.com/redis/redis/blob/f2262eccb855eadd1afb0c457ea583ef9d5400b5/Makefile)、[Redis src Makefile](https://github.com/redis/redis/blob/f2262eccb855eadd1afb0c457ea583ef9d5400b5/src/Makefile) 和 [Redis configuration](https://redis.io/docs/latest/operate/oss_and_stack/management/config/)。 | `workload/w1-redis-build/evidence.md` | generated/source/toolchain/deps precedence、release binary build replay 下的 build output hash、branch semantics、metadata p99。 |
| `w1-nginx-build` | build graph | nginx `configure` + build trace | `functional_only` host build-output oracle + KVM path oracle + KVM policy preprocessing replay witness + KVM policy release-binary replay witness + KVM branch probes | [nginx beginner's guide](https://nginx.org/en/docs/beginners_guide.html) 说明 `nginx.conf`、module/config structure 和 worker model。 | `workload/w1-nginx-build/evidence.md` | configure-generated artifacts、include/toolchain fallback、dependency leak、branch semantics。 |
| `w2-nginx-fixture` | sandbox fixture | nginx config/cert/upstream fixture startup | `functional_only` KVM path oracle + real nginx endpoint health + fixture content probes oracle | [Kubernetes projected volumes](https://kubernetes.io/docs/concepts/storage/projected-volumes/) 可投影 Secret/ConfigMap/token/cert；[nginx docs](https://nginx.org/en/docs/beginners_guide.html) 说明 config/root/proxy path。 | `workload/w2-nginx-fixture/evidence.md` | fixture setup、health response、endpoint remap、trace-level no-real-secret oracle。 |
| `w2-postgres-secret-fixture` | sandbox fixture | PostgreSQL config/auth/secret fixture startup | `functional_only` KVM path oracle | [PostgreSQL server configuration](https://www.postgresql.org/docs/current/runtime-config.html) 和 [Docker Compose secrets](https://docs.docker.com/compose/how-tos/use-secrets)。 | `workload/w2-postgres-secret-fixture/evidence.md` | secret file substitution、auth/config oracle、poison sentinel。 |
| `w3-redis-podman-criu` | checkpoint/restore | 发布级目标是 Redis Podman/CRIU checkpoint archive 和 restore trace；当前 witness 名称是 `w3-redis-rdb-load-replay` | `functional_only` KVM path oracle + Redis RDB load replay witness；当前没有真实 CRIU restore | [Podman checkpoint](https://podman.io/docs/checkpoint) 和 [CRIU checkpoint/restore](https://criu.org/Checkpoint/Restore)。 | `workload/w3-redis-podman-criu/evidence.md` | post-restore VFS trace、checkpoint manifest hash、runtime-local remap、0 mixed epoch。 |
| `w3-nginx-podman-criu` | checkpoint/restore | pinned nginx image checkpoint/restore health trace | `functional_only` KVM path oracle；当前只有 checkpoint witness | [nginx official image](https://hub.docker.com/_/nginx)、[Podman checkpoint](https://podman.io/docs/checkpoint) 和 [nginx reload/config docs](https://nginx.org/en/docs/beginners_guide.html)。 | `workload/w3-nginx-podman-criu/evidence.md` | post-restore reload/static-file VFS trace、health latency、pid/socket/log remap。 |
| `w4-ccache-redis-nginx` | cache locality | Redis/nginx 编译结合 ccache local/remote storage | `functional_only` KVM path oracle + cache content oracle + 真实 ccache cold/hot transition witness + 真实 ccache cache-path trace witness + trace-derived policy bridge witness + 真实 ccache policy-attached compile witness + parent-scoped compile witness + diagnostic compile comparator | [ccache manual](https://ccache.dev/manual/4.13.1.html) 说明 local cache、remote storage 和 local/remote hit/miss 行为。 | `workload/w4-ccache-redis-nginx/evidence.md` | hit/miss/stale/corrupt branch coverage、content hash oracle、cache-path file-op trace、policy-attached hot compile output hash、parent-scoped PoC、exact-map diagnostic boundary evidence。 |
| `w4-buildkit-prometheus-go-cache` | cache locality | Prometheus Go module/build cache with BuildKit | `functional_only` KVM path oracle + cache content oracle；当前只有 cache witness | [Prometheus repository](https://github.com/prometheus/prometheus)、[Prometheus go.mod](https://github.com/prometheus/prometheus/blob/main/go.mod) 和 [Docker BuildKit cache mounts](https://docs.docker.com/build/cache/optimize/)。 | `workload/w4-buildkit-prometheus-go-cache/evidence.md` | Go module cache setup、cache state transitions、stale/corrupt reject。 |

当前 `w3-redis-podman-criu` 的新增 Redis checkpoint replay witness 会在 KVM guest 中
启动真实 `redis-server`，生成 hidden `dump.ckpt`，并证明 attach
`checkpoint_restore_view.bpf.c` 后 Redis 通过可见 `dump.rdb` 加载该 checkpoint value；
detach 后同一路径再次不能加载 hidden state。这个 witness 的 summary 记录
`redis_checkpoint_loaded_via_policy=true`、`post_restore_vfs_replay=true`、
`podman_criu_restore_executed=false` 和 `qualified_for_c8=false`，因此只能说明真实
Redis RDB load path 能观察到 policy redirect，不能写成 Podman/CRIU restore 或 C8 证据。

当前 `w4-ccache-redis-nginx` 的真实 ccache 证据覆盖 cold/hot hit/miss transition、
cache-path trace、trace-derived policy bridge，以及真实 ccache hot compile 在
`namei_ext` policy attach window 内消费 cache object 的 witness。新增
`w4-ccache-policy-compile.jsonl` 复制真实 `CCACHE_DIR`，把 trace-derived cache object
改成 hidden `.local` backing，在 attach `cache_locality_view.bpf.c` 后运行 Redis/nginx
两个真实 `ccache gcc -c` hot compile，并证明 output object hash 与 baseline hot
object 相同。`w4-ccache-parent-compile.jsonl` 进一步把 sampled hot compile 的 lookup
规则改成每个 ccache leaf parent 一条 `name_len=0` wildcard rule：policy 只对 32 字节
ccache object-shape component 且名称匹配 trace-derived bounded witness 时追加 `.local`，
并 hard-check 同一 parent 下的 `metadata.txt` sibling PASS 和合法形状 non-witness
sibling 的 `.local` backing absent + exact-text content oracle PASS。该 run 记录 `output_hash_match=true`、
`policy_redirected_cache_objects=4`、`cache_leaf_parents=4`、
`parent_rule_updates=4`、`exact_readdir_updates=4`、
`table_equivalent_rule_updates=8`、`parent_sibling_pass=true`、
`parent_valid_sibling_backing_absent=true`、`attached_parent_valid_sibling_pass=true`、
`content_oracle=true`、内容长度/hash 匹配和 0 failure，但它仍只是 sampled parent suffix
PoC，不是 content-verified cache decision，也不覆盖多 sibling safety、stale/corrupt、
witness object 缺 backing 或 update-window。
`table_equivalent_rule_updates` 只估算这个 sampled object set 若用 exact table 表达所需的
lookup entries 加 readdir aliases，不是 release-scale table-budget failure。
`w4-ccache-table-compile.jsonl` 随后用同一份真实 `CCACHE_DIR`、同一组
Redis/nginx source file 和同一组 4 个 trace-derived cache objects 运行
`optional exact-map diagnostic` exact redirects；它同样记录 output hash match、2 次 direct hit
和 0 failure。这个 exact-map diagnostic pass 是 C8 的负面证据：当前 sampled W4 witness 能被
static exact-map diagnostic 解释。stale/corrupt 分支仍来自 fixture-backed cache content oracle，
不能被写成真实 ccache stale/corrupt transition；当前 policy-attached hit 也不是
release-level operation-weighted policy cache hit rate。因此 W4 仍只能作为
`functional_only`，不能计入 C1/C8。
`w4-ccache-release-counterfactual.jsonl` 把同一 RUN_ID 下的真实 ccache trace、
parent-scoped compile witness 和 diagnostic compile comparator 汇总成 KVM accounting
row：`trace_cache_path_file_ops=40`、`trace_cache_objects=4`、
`parent_rule_writes=4`、`table_rule_writes=8`、
`eligible_object_policy_hit_rate=1`、`cache_path_policy_coverage=0.1`、
`attached_cache_path_file_ops=40`、`attached_policy_cache_object_ops=16`、
`attached_sampled_operation_hit_rate=0.4`、
`attached_sampled_operation_hit_rate_is_release=false`、
`table_baseline_current_oracle_pass=true`，并显式记录
`operation_weighted_policy_cache_hit_rate=false` 和 `qualified_for_c8=false`。这条 row
只是把当前负证据机械化，不能升级成 C8。

`docs/tmp/2026-06-14-real-workload-source-signal-ledger.md` 进一步把每个 family 的真实来源、
被放大的性能信号、当前 raw evidence 和 release blocker 绑定在一起。主论文表格只能沿用
该 ledger 中已经通过 KVM raw result 和 release blocker gate 的 row；不能把
`functional_only` row 写成 C1/C8 或性能结论。

截至 2026-06-15，W1/W2/W3/W4 都仍是 `functional_only` 级别。W1 额外有
`w1-build-output-oracle.jsonl`：它校验 Redis/nginx 真实 host source build 的
binary SHA256、trace build binary SHA256、duration、trace file-op lines 和 source
manifest hash，并明确记录 `policy_executed=false`、`kvm_validated=false`、
`qualified_for_c8=false`。该 artifact 已被纳入 W1 KVM path oracle 的
`w1-oracle-inputs.sha256`。W1 还新增
`w1-build-replay.jsonl`：它在 KVM guest 中 load/attach `build_graph_view.bpf.c`，
对真实 Redis `src/server.c` 和 nginx `src/core/nginx.c` 运行 policy preprocessing，
并和未 attach policy 的 baseline preprocessing byte-for-byte 比较；Redis
baseline/policy SHA256 都是
`c4fc64fce52917575d2e4c7d0735a45685f54be29f68303a730f69bfeb588422`，nginx
baseline/policy SHA256 都是
`dbb253e0d661fce0dabbd9b0ad2c42e349ed99277dc6f9168974a589e3048c5e`。这个 witness
是 `output_hash_oracle_scope=kvm_policy_preprocess`，不是完整 release binary
replay；仍记录 `release_output_hash_oracle=false` 和 `qualified_for_c8=false`，
不能支撑 C1/C8。2026-06-15 的 parent-aware ABI PoC 进一步把 kernel ctx 扩展为
append-only `parent_dev`、`parent_ino`、`parent_generation` 和 `parent_flags`，并让
map-backed policy key 使用 `(event, cgroup_id, parent_dev, parent_ino, component)`。
`make report RUN_ID=20260615T-parent-key-poc` 已在该 ABI 下通过完整 Phase 1 gate。这解除
component-only key 的第一层 blocker。W1 进一步新增
`w1-release-build-replay.jsonl`：它在 KVM guest 中对 Redis/nginx 两套真实 trace
source tree 分别运行 baseline rebuild 和 attached-policy rebuild，保存并规范化
debug section/GNU build-id 后比较 release binary。Redis baseline/policy SHA256 都是
`65c8f5155d78a1a04ebb937cf7c85483b8320e1444686a691694c46e83f2de8b`，nginx
baseline/policy SHA256 都是
`f9e214c23512996723d8409b0d0eda40070c135fc28f25d6f207ea85b4974544`。
该 witness 仍记录 `qualified_for_c8=false`，因为它还缺完整 trace-derived alias set、
release-level poison/negative natural workload hit、operation-weighted redirected hit
rate 和 claim-specific comparison。W1 还新增
`w1-branch-probes.jsonl`：它在 KVM guest 中的 Redis `src/` 和 nginx `src/core/`
真实 source parent directory 副本内验证 `private.h -> poison.dep` 和
`missing.h -> PASS/ENOENT`，summary 为 0 failure，并记录 host trace candidate hit
rate `11330/3021315 = 0.00375`，即 `0.375%`；但它仍标记
`operation_weighted_hit_rate_is_release=false`，因此只是 branch semantics witness，
不是 C8 evidence。W2 nginx 额外有
`w2-nginx-real.jsonl`：真实 nginx `1.26.3` binary 在 KVM guest 内执行配置测试、
启动 worker、对 nginx listener 发起 HTTP health check，并通过 `nginx -s quit` 退出。
attach 前和 detach 后因 `conf/nginx.conf` 缺失失败；attach 后经
`sandbox_fixture_view.bpf.c` 重定向到 `nginx.test.conf`，配置测试成功；
fixture config 中的 `include upstream.sock` 被重定向到 `upstream.local`，nginx 将请求代理到
runner 的 `127.0.0.1:18080` local upstream，HTTP 响应包含 `200 OK` 和
`namei_ext nginx health`，raw evidence 记录 `attached_endpoint_upstream=true`。同一 attach
window 内还运行五个 direct fixture content probes：config、endpoint、fake cert、fake
secret 和 poison aliases 均通过普通 VFS `open/read` 解析到 fixture/fake/poison backing，
且不等于 production-like decoy。这个结果证明
真实 nginx config parser、worker 启动和一次 endpoint 请求路径能观察到 `namei_ext`
path-resolution 决策，并证明 sandbox fixture 的五类 aliases 能影响普通 VFS open/read；
后续 W2 real trace gate 已检查 attach 期间 production decoy path open 次数为 0；
但它仍不是 release-level endpoint/startup matrix 或 claim-specific comparison oracle。W3 的当前
artifact 是 Redis/nginx provenance 绑定的 checkpoint witness manifest、
`w3-checkpoint-oracle-entries.tsv`、`w3-oracle.jsonl` 和
`w3-redis-replay.jsonl`；其中 Redis replay 运行真实 Redis RDB load path，但仍记录
`podman_criu_restore_executed=false`，不是真实 Podman/CRIU restore 结果。W4 的当前 artifact 是 ccache/BuildKit 场景的 cache witness manifest、
`w4-cache-oracle-entries.tsv`、`w4-oracle.jsonl`、`w4-cache-content.jsonl`、
`w4-ccache-real.jsonl`、`w4-ccache-trace.jsonl`、
`w4-ccache-policy-bridge.jsonl`、`w4-ccache-policy-compile.jsonl`、
`w4-ccache-parent-compile.jsonl`、`w4-ccache-table-compile.jsonl` 和
`w4-ccache-release-counterfactual.jsonl`。
其中 `w4-cache-content.jsonl` 在 KVM guest 中读取 `w4-cache-oracle-entries.tsv`，
按 manifest materialize backing content，填充 `cache_rules` map，并通过
`cache_locality_view.bpf.c` 检查 verified hit、stale fallback、corrupt reject 和 miss
canonical 的内容选择：命中分支不能读到 wrong local object，stale 分支不能读到
stale local object，corrupt 分支不能读到 corrupt local object。新增
`w4-ccache-real.jsonl` 在 KVM guest 中运行真实 `ccache`，对 Redis `src/crc64.c` 和
nginx `src/core/ngx_string.c` 分别执行 cold/hot 两次 `ccache gcc -c`，记录
`cache_miss=2`、`direct_cache_hit=2`、Redis cold/hot object hash 相等和 nginx
cold/hot object hash 相等；随后把两个 hot object 作为 ccache-derived backing 输入
`cache_locality_view.bpf.c` content oracle，并得到 0 policy content oracle failure。
`w4-ccache-trace.jsonl` 进一步在 KVM guest 中用 `strace -f -e trace=%file` 跟踪
真实 ccache hot compile，记录 Redis 134 条 file-op trace 中 20 条触碰
`CCACHE_DIR`，nginx 602 条 file-op trace 中 20 条触碰 `CCACHE_DIR`，同时保留
`cache_miss=2` 和 `direct_cache_hit=2`。`w4-ccache-policy-bridge.jsonl` 再从
Redis/nginx raw strace logs 中抽取 4 个真实成功读取的 ccache cache object paths
（Redis 2 个、nginx 2 个），生成 trace-derived TSV，并在 KVM 中 attach
`cache_locality_view.bpf.c` 验证 4 个 verified-hit content aliases：
`attached_expected_match=4`、`attached_forbidden_mismatch=4`、`readdir_alias=4`、
`policy_content_oracle_failures=0`。该 bridge 仍明确记录
`ccache_compile_policy_executed=false` 和 `qualified_for_c8=false`。
`w4-ccache-policy-compile.jsonl` 随后把真实 ccache hot compile 放入
`cache_locality_view.bpf.c` attach window：4 个 trace-derived cache objects 被 policy
重定向，Redis/nginx 各 2 个 trace objects；summary 记录
`ccache_compile_policy_executed=true`、`output_hash_match=true`、`failures=0`，
stats 记录 `cache_miss=0`、`direct_cache_hit=2`、`local_storage_hit=2` 和
`local_storage_write=0`。`w4-ccache-parent-compile.jsonl` 又把同一类 sampled hot
compile 改成 parent-scoped lookup PoC，记录 `parent_rule_policy=true`、
`cache_leaf_parents=4`、`parent_rule_updates=4`、`exact_readdir_updates=4`、
`table_equivalent_rule_updates=8`、`attached_parent_sibling_pass=true`、
`parent_valid_sibling_backing_absent=true`、`attached_parent_valid_sibling_pass=true`、
`content_oracle=true`、内容长度/hash 匹配、`parent_sibling_pass=true`、
`output_hash_match=true` 和 0 failure；Makefile/report recipes 已纳入该 target 的
hard-check，但本文只引用独立 hardgate raw artifact，尚未引用 post-parent full report
artifact；该 row 仍标记 `qualified_for_c8=false`。
`w4-ccache-table-compile.jsonl` 用
`optional exact-map diagnostic` 重复同一 sampled hot compile，summary 记录
`table_baseline_current_oracle_pass=true`、`content_equivalent_table_oracle=true`、
`output_hash_match=true` 和 `failures=0`，stats 同样记录 `direct_cache_hit=2`。该 W4
结果仍不是真实 BuildKit 或 Go build/test 结果，也没有 release-level
operation-weighted policy cache hit rate、真实 stale/corrupt transition、stale window、
update writes 或 claim-specific comparison；相反，当前 diagnostic comparator
通过说明这组样本不能支撑 C8。新增
`w4-ccache-release-counterfactual.jsonl` 进一步把同一个 KVM run 中的
`w4-ccache-trace.jsonl`、trace objects、bridge TSV、parent/table compile JSONL、
parent/table input hashes、parent/table output hashes、budget config 和 KVM Makefile
写入 11 项输入哈希，并生成 release counterfactual accounting row。该 row 显示
4 个 trace cache objects 都被 parent policy 覆盖，但它们只对应 40 个 cache-path file
ops 中的 sampled object subset，`cache_path_policy_coverage=0.1`；新增 attach-window
optrace 又显示 parent policy compile 的 40 个 cache-path file ops 中有 16 个匹配
sampled policy cache objects，sampled hit rate 为 0.4，但它仍不是 release-level
operation-weighted hit rate。sampled exact-map diagnostic 也通过，所以仍为
`qualified_for_c8=false`。新增
`table-budget.jsonl` 会把 W1/W2/W3/W4 当前 path oracle 中 exact-map diagnostic 的 entries、
static-load accounted update writes、input hash 和 committed budget 字段写成 raw
accounting artifact，并明确所有 row 仍为 `qualified_for_c8=false`；它不替代
release-level workload-specific comparison。
所有这些 row 都不能计入 C1/C8，直到对应 workload-specific oracle、claim-specific comparison、
safety/semantic-boundary evidence 和发布级 repetition 通过。

每个 `workload/<workload-id>/evidence.md` 必须记录上游 URL、版本、下载哈希、许可证、
真实来源说明、Make target、trace 命令、alias manifest 生成过程、operation-weighted
alias hit rate 和 raw result path。低于 80% provenance-derived alias hit rate 的
run 只能进入 appendix 或 scale/failure 实验。

## 基线

所有 baseline 都必须通过 feature-equivalence gate。非等价 baseline 可以作为背景，
但不能作为主张的主要比较对象。

- `native-direct`：无 policy 的 lower filesystem 下界，只用于开销下界。
- `copy-tree-cp`：按 alias manifest 复制目录树。
- `symlink-forest-ln`：按 alias manifest 创建符号链接森林。
- `bind-fanout-mount`：在 private mount namespace 中构造 bind mount fanout。
- `overlayfs-kernel`：仅在能表达同一 fixture/materialized view 时作为强 kernel
  baseline。
- `fuse-redirectfs`：用户态 path-remapping filesystem，衡量把 path-resolution 放到
  用户态的代价。
- `k8s-projected-volume` / Docker secrets materialization：仅用于 sandbox fixture。
- `podman-criu-restore`：仅用于 checkpoint/restore。
- `cache-tool-native`：ccache、Bazel remote cache、BuildKit cache mount 或 Nix store
  的原生机制，仅用于 cache locality。
- `optional exact-map diagnostic`：只允许 exact map lookup 和 `PASS/REDIRECT`，
  用于检查预计算映射是否已足够解释某个特定 witness。

Unsupported baseline operation 是 hard failure，不能被静默过滤或记作 partial success。

## E1. 正确性和表达力

**Claim.** `namei_ext` 的单一 BPF decision function 能在 lookup 和 readdir 上实现四类
语义不同的 path-resolution policy family。

**Setup.** 对每个 family 至少运行两个真实 workload row。每个 row 在同一 KVM run 中
加载对应 `bpf/policies/*.bpf.c`，attach 到 cgroup，执行 lookup/open/access/exec/readdir
checker，并保存 verifier log、dmesg 和 branch coverage。

**Oracle.**

- build graph：build output hash、declared input manifest、generated/source precedence、
  undeclared dependency poison。
- sandbox fixture：health/output、no-real-secret/config hash、endpoint checker、
  poison sentinel。
- checkpoint/restore：state/config/cache hash、runtime-local remap、0 mixed epoch、
  restore health。
- cache locality：content hash、stale/corrupt reject、hit/miss/stale/corrupt branch
  coverage。

**Figure/Table.** 表 1：四类 family x workload rows 的 correctness、branch coverage、
verifier stats 和 row result。

**Expected result artifact.** `results/eval-osdi/paper/<run-id>/b12-policy-family/*`，
每个 row 包含 checker JSONL、branch coverage、verifier log、dmesg、manifest 和
`row_result`。

**Success gate.** 所有主 row 为 `qualified_for_c8`；0 checker failure；0 dmesg failure。
若某 family 只有一个真实 row 或只能靠 synthetic manifest，C1/C8 降级为 partial。

**Claim downgrade text.** 若少于四类 family 达到 `qualified_for_c8`，本节只能写
“`namei_ext` 支持已测若干 path-resolution extensions”，不能写通用 programmable
abstraction。

## E2. 准备和物化成本

**Claim.** 对动态 path-resolution customization，`namei_ext` 比 copy tree、symlink
forest、bind fanout 和 FUSE 降低 setup/materialization 成本。

**Setup.** 对 W1-W4 的 primary workload 运行 100、1k、10k、100k alias/components 或
path-class entries；并发 cgroup/worker 数为 1、16、64、256。每个 variant 报告 setup、
teardown、created objects、disk writes、map entries 和 update writes。

**Figure/Table.** 图 2：setup p50/p95/p99 和 created objects；表 2：每个 baseline 的
feature-equivalence decision。

**Expected result artifact.** `results/eval-osdi/paper/<run-id>/b3-build/`、
`b4-fixture/`、`b5-checkpoint-restore/`、`b6-cache-locality/` 下的 setup JSONL、
object-count manifests、baseline config 和 raw stdout/stderr。

**Success gate.** 中型/大型真实 workload 上，`namei_ext` setup p50 或创建对象数至少
比最佳物化 baseline 好 5x。若只减少 created objects 但 end-to-end wall time 不改善，
论文只声称 materialization improvement，不声称端到端加速。

**Claim downgrade text.** 若 setup 不优于物化 baseline，本节改写为功能 case study，
删除 materialization advantage claim。

## E3. 稳态元数据性能

**Claim.** `namei_ext` 把 policy 放在 VFS path-resolution 路径，可以避免 FUSE 式
用户态 filesystem 开销，并保持接近内核机制的 metadata tail latency。

**Setup.** 从真实 trace 中抽取 `openat/statx/access/execve/getdents64` 操作比例，分别
测 cache-hot、cache-cold、path depth 1/4/16/64、parent fanout、policy map size 和
cgroup 数。使用 open-loop generator 避免 coordinated omission。

**Figure/Table.** 图 3：p50/p95/p99 latency；图 4：throughput 和 CPU cycles；
图 5：resource attribution。

**Expected result artifact.** `results/eval-osdi/paper/<run-id>/b2-micro/` 和每个
macro run 的 trace-replay raw latency histograms、HdrHistogram/exported JSONL、
CPU/resource counters、cache mode 和 variant order。

**Success gate.** redirect p99 不超过最佳 feature-equivalent kernel baseline 的 1.5x，
且相对 `fuse-redirectfs` 至少有 2x p99 优势。否则删除接近内核/FUSE 优势主张。

**Claim downgrade text.** 若 p99 未达阈值，本节只保留 expressiveness/correctness，
不主张低开销或优于 FUSE。

## E4. 为什么需要窄 VFS/eBPF hook

**Claim.** 对目标 workload，窄 VFS name-resolution hook 在表达力、安全边界和效率之间提供
更好的平衡；conceptual alternatives 包括 FUSE/custom FS 和 kernel modification，
workload-specific alternatives 包括 materialized tree、bind/symlink projection、OverlayFS
或 workload-native cache/runtime 机制。

**Setup.** 对每个 family 选择 claim-specific comparison。exact-map counterfactual 只在预计算映射
是该 family 的相关替代方案时运行；否则不把它作为默认主 baseline。

**Ablations.**

- build graph：移除 precedence 后 generated/source/toolchain/deps oracle 是否失败。
- sandbox fixture：移除 path-class 后 no-real-secret 和 poison oracle 是否失败。
- checkpoint/restore：移除 session/epoch check 后是否出现 mixed checkpoint/current view。
- cache locality：移除 content-hash/cache-state 后 stale/corrupt cache 是否被接受。

**Figure/Table.** 图 6：exact-map diagnostic budget ratio；表 3：每个 family 的 semantic witness、
oracle result、budget result 和降级结论。

**Expected result artifact.** `results/eval-osdi/paper/<run-id>/b12-policy-family/` 中的
diagnostic comparator output、conformance check、budget config、stale-window log 和
oracle diff。

**Success gate.** 至少四个 qualifying family 在同一 ABI 上通过真实 workload oracle，
并且 conceptual alternatives 与 workload-specific baselines 不能同时满足关键 oracle、
成本门槛、安全/语义边界和一致性要求。
如果某 family 只被 sampled diagnostic 解释，它只能作为 `functional_only`，不能计入 C8。

**Claim downgrade text.** 若 workload-specific baseline 覆盖全部主 oracle，或 safety/semantic
boundary 没有比替代方案更清楚，本节必须改成“kernel path-resolution artifact”，删除
“balanced programmable abstraction”。

## E5. 规模、压力和失败语义

**Claim.** `namei_ext` 的边界可测，失败语义是 fail-fast，而不是 silent fallback。

**Setup.** 扫描 aliases/components 10、100、1k、10k、100k；path depth 1、4、16、64；
cgroups/workers 1、16、64、256、512；policy/map size；cache hot/cold；invalid redirect；
verifier rejection；map exhaustion；backing rename/delete；detach/reload；cgroup
migration/fork/exec。

**Figure/Table.** 图 7：scale saturation；表 4：failure case、expected errno、
dmesg status、post-fault checker。

**Expected result artifact.** `results/eval-osdi/paper/<run-id>/b9-scale/` 和
`b10-failure/` 下的 failure landing evidence、errno matrix、dmesg、post-fault
checker output 和 saturated resource counters。

**Success gate.** 声明范围内 0 semantic failure。超出范围必须返回 documented errno
或 explicit non-Phase-1 diagnostic mode；0 warning/oops/panic；0 fail-open。

**Claim downgrade text.** 若出现 fail-open、panic 或 silent fallback，删除 robustness
claim，并把对应 failure mode 写入 limitations。

## E6. 产物和复现性

**Claim.** 独立审稿人可以从干净 checkout 通过 Makefile-owned KVM/Docker workflow
复现发布级结果。

**Setup.** `make eval-osdi-paper` 生成 `results/eval-osdi/paper/<run-id>/`，随后
`make eval-osdi-paper-report` 从 raw results 生成本节图表和表格。

**Success gate.** report 在缺字段、dirty release tree、缺 raw reference、parse error、
checker failure、dmesg failure、baseline unsupported operation 或 subagent audit
failure 时失败。

**Expected result artifact.** `results/eval-osdi/paper/<run-id>/manifest.json`、
`report.md`、`figures/`、`tables/`、kernel/Docker identity、source hashes 和 subagent
audit transcript。

**Claim downgrade text.** 若干净 checkout 不能一条 Make pipeline 复现，本节只能声称
prototype artifact，不能声称可复现评估。

## 写作规则

- 没有 raw result 的数字一律作为计划项或范围边界处理，不能写估计值。
- 每个段落的 takeaway 必须指向 C1-C8 中的某个 claim。
- 负面结果不能删除；如果某 baseline 通过主 oracle，必须按 plan 降级 claim。
- 每次更新本节都要让独立 subagent 按 OSDI rubric 审查。复审结论和 must-fix 记录在
  `docs/tmp/YYYY-MM-DD-*.md`。
