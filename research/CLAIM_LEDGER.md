# 主张台账

Last updated: 2026-06-16
Stage at update: claims/gate
Source/command: derived from `docs/experiment-plans/osdi-evaluation.md`, `docs/paper/sections/*.tex`, and current eval ledgers
Completeness: partial

## 论文 thesis

`namei_ext` 是一个窄 VFS path-resolution eBPF extension point：内核保留 VFS object 和 lower filesystem 语义，eBPF policy 只在路径解析时返回受限 `PASS/REDIRECT` decision。目标是在真实读多写少、元数据密集的 workload 中，用比 FUSE 或物化目录视图更低的开销表达多类可编程 path-resolution extensions。

## Claim 表

| ID | Claim | Scope | Metric/evidence needed | Status |
|---|---|---|---|---|
| C1 | 一个通用 programmable path-resolution ABI 能表达多类真实 extension。 | 只覆盖已实现的 lookup/readdir PASS/REDIRECT，不覆盖 file data path、create/unlink/rename 或安全隔离。 | 四个 policy family 每个至少两个真实 workload；semantic witness、真实来源证据、table-only counterfactual、`qualified_for_c1_c8=true`。 | blocked：B12 ledger 中 `qualified_families=0`。 |
| C2 | 相比 copy/symlink/bind/projected-volume/FUSE 等方案，`namei_ext` 降低动态 path view 的 setup/storage/update 成本。 | W1-W4 read-mostly workload。 | setup time、created objects、disk writes、update writes、storage footprint，和 feature-equivalent baseline 比较。 | unsupported：已有 external baseline setup/update rows；W2 nginx 已有 20-sample KVM proposed-system setup/update raw input、同 workload `copy_tree`/`symlink_forest`/`bind_mount`/`projected_volume`/`fuse_redirect` baseline，以及 v5 thresholded W2 ledger，`w2_c2_slice_supported=true`。W1 build graph 已有 20-sample KVM proposed-system setup/update release input 和完整五类 baseline release input；v2 ledger 记录 `full_feature_equivalent_baseline_pass=true`，但 `w1_c2_slice_supported=false`。W3 Redis checkpoint replay 已有 20-sample KVM proposed-system setup/update release input、`materialized_checkpoint_view` baseline 和 `fuse_redirect` baseline；v1 ledger 记录 `full_feature_equivalent_baseline_pass=true`、`storage_footprint_pass=true`，但 `setup_latency_threshold_pass=false`、`update_latency_threshold_pass=false`、`w3_c2_slice_supported=false`。W4 ccache 已有 parent-rule/table/materialized baseline 20-sample KVM release input；v6 W4 ledger 进一步合并 bulk policy-attached compile smoke、bulk policy setup/update release input、bulk materialized baseline 和 bulk FUSE cache-view baseline，记录 `bulk_policy_release_input_pass=true`、`bulk_external_baseline_release_input_pass=true` 和 `bulk_release_comparison_pass=false`。因此当前只有 W2 slice 为正；W1/W3/W4 都是完整或更强 baseline 下的负结果。全局 C2 只能通过 scope narrowing、W4 更强同 shape cache-remap/native ccache/BuildKit 或完整 compile-through-FUSE baseline、或新的 workload evidence 改变。 |
| C3 | `namei_ext` 在路径解析热路径上保持接近内核 baseline，且明显优于 FUSE remap。 | lookup/open/access/exec/readdir/tree-walk microbench 和真实 workload metadata path。 | p50/p95/p99、throughput、CPU、context switches、CI、随机化顺序、FUSE/copy/symlink/bind/OverlayFS baselines。 | unsupported：最新 release-level tail10 comparison 已 `input_gate_pass=true`、`fuse_speedup_threshold_pass=true`，但 `kernel_p99_threshold_pass=false`；rusage/no-hook 只提供归因，不改变 C3 verdict。 |
| C4 | 对声明的 redirect policy，lookup 与 readdir 的可见视图一致。 | 已声明 `PASS/REDIRECT` policy 和当前 same-parent redirect ABI。 | property checker：lookup 内容、readdir visible set、detach 后不可达、0 semantic failure。 | partial：Phase 1 KVM oracles 通过，但动态 epoch/update consistency 仍未覆盖。 |
| C5 | VFS-level placement 和 lower-FS ownership 是测得收益的主要机制。 | 与 FUSE、symlink/copy/bind、table-only、pass-only、no-hook 的消融比较。 | no-hook/pass-only/table-hit/FUSE/materialization ablations；同一 correctness oracle；机制归因。 | unsupported：tail10 comparison 中 `pass_only_threshold_pass=false`；no-hook 和 matched baseline/pass-only diagnostics 将 worst case 降到 1.306x/1.323x，但仍超过 1.1x，机制归因仍不能成立。 |
| C6 | 系统有明确规模边界和 fail-fast 失败语义。 | verifier failure、invalid redirect、map exhaustion、detach/reload、cgroup migration、path depth/fanout/cgroups scale。 | stress/robustness matrix、errno、dmesg、0 panic/oops、无 fail-open。 | partial：Phase 1 smoke 和 dmesg gate 存在；release stress/failure matrix 未完成。 |
| C7 | Artifact 能用 Makefile-owned KVM/Docker workflows 复现。 | 当前 repo、kernel submodule、Docker image、KVM guest、raw result roots。 | one-command reproduction、provenance hashes、kernel/Docker identity、clean tree audit、artifact checklist。 | partial：`make phase1` full root 已存在，但工作树 dirty，artifact checklist 未完成。 |
| C8 | 多个真实 policy family 的算法结构和 update/budget 需求不能被一个静态 exact redirect table 同时替代。 | `build_graph_view`、`sandbox_fixture_view`、`checkpoint_restore_view`、`cache_locality_view`。 | 每个 family 的真实 workload oracle、algorithm path、table-only baseline fail 或超预算、operation-weighted release metric。 | unsupported：当前 table-only 多处通过，是负证据；W3 Redis same-workload table-only replay 也通过；W4 cache-content same-workload table-only comparator 也通过；W4 ccache table baseline 在 rule macrobench 中仍 feature-equivalent 且 rule writes 与 parent-rule policy 相同。W4 bulk policy-attached compile smoke 证明真实 hot compile 可以经 attached `cache_locality_view.bpf.c` 消费 40 个 trace-derived cache objects；bulk policy setup/update release input、materialized baseline 和 FUSE cache-view baseline 证明同 shape proposed-system 与外部 baselines 可运行；v6 W4 ledger 已把这些 inputs 合并进 claim-level artifact，但仍记录 `bulk_release_comparison_pass=false`。因此 `operation_weighted_policy_cache_hit_rate=false`、`qualified_for_c8=false`，且还缺 table-only failure、budget violation、外部 baseline weakness、完整 compile-through-FUSE/native/cache-remap 对照或 release operation-weighted metric。B12 gate 中 `table_counterfactual_support=false`。 |

## 真实 workload 和可引用来源

当前使用或计划使用的 workload 必须保持来自真实系统或真实工具链：

- W1 build graph：Redis `7.2.14` 与 nginx `1.26.3` 真实源码构建和 strace，引用 `redis_repo`、`nginx_docs`、`bazel_sandboxing`、`bazel_hermeticity`、`bazel_dependencies`、`bazel_toolchains`。
- W2 sandbox fixture：nginx、PostgreSQL、Kubernetes projected volumes/secrets、Docker Compose configs/secrets，引用 `nginx_docs`、`postgres_file_locations`、`kubernetes_projected_volumes`、`kubernetes_secrets`、`docker_compose_configs`、`docker_compose_secrets`。
- W3 checkpoint/restore：Redis/nginx、Podman checkpoint、CRIU、external bind mount 和 DMTCP path virtualization，引用 `podman_checkpoint`、`criu_main`、`criu_checkpoint_restore`、`criu_external_bind_mounts`、`dmtcp_path_virtualization`。
- W4 cache locality：ccache、Redis/nginx hot compile、Prometheus/BuildKit Go cache、Bazel remote cache/remote execution、Nix binary cache/content-addressed store，引用 `ccache_manual`、`docker_buildkit_cache`、`prometheus_repo`、`prometheus_go_mod`、`bazel_remote_cache`、`bazel_remote_execution_api`、`nix_binary_cache_substituter`、`nix_content_addressed_store`。
- Baselines：FUSE、OverlayFS、bind mount、symlink/copy materialization，引用 `linux_fuse`、`linux_fuse_passthrough`、`linux_overlayfs`，并保留 ExtFUSE/Bento 相关工作引用。

## Open questions

- 如果 table-only baseline 在某个 family 的 release workload 中满足 oracle 且未超预算，该 family 不能支持 C8，只能作为功能实例或 appendix。
- 如果 FUSE 或 symlink forest 在主要 workload 上性能接近或优于 `namei_ext`，C3/C5 必须降级。
- 如果真实 Podman/CRIU 或 BuildKit/Prometheus workload 无法在 KVM flow 中稳定复现，应缩小 claim，而不是使用 synthetic fixture 代替 release evidence。
