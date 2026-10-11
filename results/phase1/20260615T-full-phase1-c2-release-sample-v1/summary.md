# Phase 1 Report

- Date: 2026-06-16
- Scope: KVM smoke, policy load/semantic validation, table conformance, W1 trace-derived path oracle, W1 KVM policy build replay witness, W1 KVM policy release binary replay witness, W1 build-graph poison/negative branch probes, W2 fixture path oracle, W2 real nginx endpoint health plus fixture content probes oracle, W3 checkpoint path oracle, W3 Redis checkpoint replay witness, W4 cache path oracle, W4 cache content oracle, W4 real ccache transition witness, W4 real ccache cache-path trace witness, W4 trace-derived ccache policy bridge, W4 real ccache policy-attached compile witness, W4 parent-scoped ccache compile witness, W4 table-only ccache compile comparator, W4 release counterfactual accounting, table-only budget accounting, functional policy validation, and smoke-scale microbenchmarks
- Kernel image: /home/yunwei37/workspace/namei_ext/.build/kernel/arch/x86/boot/bzImage
- Kernel sha256: 8a5351a88c857c9bd15669ea4b401e013b384d31f652241ca05a8bed33d7fe43
- Main repo HEAD: 6fe308aa3a16a9ea160f634f60ed76427dcc1b7c
- Main repo dirty: true
- Kernel repo HEAD: 31a33d22c2122f0db82553fc5325cfc273fe22e0
- Kernel repo dirty: true
- Result directory: /home/yunwei37/workspace/namei_ext/results/phase1/20260615T-full-phase1-c2-release-sample-v1
- Samples: 20
- Benchmark iterations: 2000
- Benchmark latency samples: 0
- Benchmark latency batch: 64
- Benchmark config sha256: fe3f6b26b167d970c0a588848a917e096dc6bd8e32c37055c5738ff27e0f52f5
- W1 oracle input sha256 file: w1-oracle-inputs.sha256
- W1 host build-output oracle: /home/yunwei37/workspace/namei_ext/results/workloads/runs/20260615T-full-phase1-c2-release-sample-v1/w1-build-output-oracle.jsonl
- W1 KVM policy build replay input sha256 file: w1-build-replay-inputs.sha256
- W1 KVM policy build replay output sha256 file: w1-build-replay-outputs.sha256
- W1 KVM policy release build replay input sha256 file: w1-release-build-replay-inputs.sha256
- W1 KVM policy release build replay output sha256 file: w1-release-build-replay-outputs.sha256
- W1 KVM branch probes input sha256 file: w1-branch-probes-inputs.sha256
- W2 oracle input sha256 file: w2-oracle-inputs.sha256
- W2 nginx real input sha256 file: w2-nginx-real-inputs.sha256
- W3 oracle input sha256 file: w3-oracle-inputs.sha256
- W3 Redis checkpoint replay input sha256 file: w3-redis-replay-inputs.sha256
- W3 Redis table replay input sha256 file: w3-redis-table-replay-inputs.sha256
- W3 Redis counterfactual input sha256 file: w3-redis-counterfactual-inputs.sha256
- W4 oracle input sha256 file: w4-oracle-inputs.sha256
- W4 cache content input sha256 file: w4-cache-content-inputs.sha256
- W4 real ccache input sha256 file: w4-ccache-real-inputs.sha256
- W4 real ccache output sha256 file: w4-ccache-real-outputs.sha256
- W4 real ccache trace input sha256 file: w4-ccache-trace-inputs.sha256
- W4 real ccache trace artifact sha256 file: w4-ccache-trace-artifacts.sha256
- W4 trace-derived ccache policy bridge input sha256 file: w4-ccache-policy-bridge-inputs.sha256
- W4 real ccache policy compile input sha256 file: w4-ccache-policy-compile-inputs.sha256
- W4 real ccache policy compile output sha256 file: w4-ccache-policy-compile-outputs.sha256
- W4 parent-scoped ccache compile input sha256 file: w4-ccache-parent-compile-inputs.sha256
- W4 parent-scoped ccache compile output sha256 file: w4-ccache-parent-compile-outputs.sha256
- W4 table-only ccache compile input sha256 file: w4-ccache-table-compile-inputs.sha256
- W4 table-only ccache compile output sha256 file: w4-ccache-table-compile-outputs.sha256
- W4 release counterfactual input sha256 file: w4-ccache-release-counterfactual-inputs.sha256
- Table-budget input sha256 file: table-budget-inputs.sha256
- Docker image tar sha256: 96443303754614d0f74c84e4ea35b8d5c68322a493384e548a204d4b4e63612b
- Docker image ID: sha256:3a2779ef1ede153b08c51dddc5b595799f7f6f1595a4f6e2af44d14e2a2845dd

## Gates
- Guest smoke events: 2
- ABI failing cases: 0
- Policy-load failing cases: 0
- Policy-semantic failing cases: 0
- Policy-semantic summary failures: 0
- Table-conformance failing cases: 0
- W1 oracle failing cases: 0
- W1 oracle summary failures: 0
- W1 host build-output oracle failures: 0
- W1 KVM policy build replay failures: 0
- W1 KVM policy release build replay failures: 0
- W1 KVM branch probe failures: 0
- W2 oracle failing cases: 0
- W2 oracle summary failures: 0
- W2 nginx real-app failing cases: 0
- W2 nginx real-app summary failures: 0
- W3 oracle failing cases: 0
- W3 oracle summary failures: 0
- W3 Redis checkpoint replay failures: 0
- W3 Redis checkpoint replay loaded via policy: 1
- W3 Redis table replay failures: 0
- W3 Redis table replay loaded via table_redirect: 1
- W3 Redis counterfactual C8-qualified rows: 0
- W4 oracle failing cases: 0
- W4 oracle summary failures: 0
- W4 cache content failing cases: 0
- W4 cache content summary failures: 0
- W4 cache table content failing cases: 0
- W4 cache table content summary failures: 0
- W4 real ccache witness failures: 0
- W4 real ccache direct cache hits: 2
- W4 real ccache trace failures: 0
- W4 real ccache trace cache-path file ops: 40
- W4 trace-derived ccache policy bridge failures: 0
- W4 trace-derived ccache policy bridge objects: 4
- W4 real ccache policy compile failures: 0
- W4 real ccache policy redirected objects: 4
- W4 real ccache policy direct cache hits: 2
- W4 table-only ccache compile failures: 0
- W4 table-only ccache redirected objects: 4
- W4 table-only ccache direct cache hits: 2
- W4 release counterfactual C8-qualified rows: 0
- Table-budget failing accounting rows: 0
- Table-budget current oracle passes: 4
- Table-budget C8-qualified rows: 0
- Functional failing cases: 0
- Benchmark failing operations: 0
- Benchmark variants: baseline,pass_only,policy,table_redirect_empty,table_redirect_hit
- Benchmark table_redirect_hit map updates: 1320
- Benchmark policy attach successes: 4
- Benchmark latency rows: 0
- Docker failing cases: 0
- Dmesg warning/oops/panic lines: 0

## Docker Cases
| Case | Pass | Detail |
|---|---:|---|
| docker-smoke | true | runtime image Makefile BPF target passed without host workspace bind mount |

## ABI Cases
| Case | Pass | Detail |
|---|---:|---|
| uapi_layout | true | PASS/REDIRECT enum values and ctx layout match Phase 1 ABI |
| bpf_layout | true | PASS/REDIRECT enum values and ctx layout match Phase 1 ABI |
| uapi_header_sync | true | kernel and tools namei_ext UAPI blocks match |

## Policy Load Cases
| Policy | Pass | Errno | Detail |
|---|---:|---:|---|
| /home/yunwei37/workspace/namei_ext/.build/bpf/build_graph_view.bpf.o | true | 0 | policy loaded and attached |
| /home/yunwei37/workspace/namei_ext/.build/bpf/build_graph_view.bpf.o | true | 0 | policy detached |
| /home/yunwei37/workspace/namei_ext/.build/bpf/cache_locality_view.bpf.o | true | 0 | policy loaded and attached |
| /home/yunwei37/workspace/namei_ext/.build/bpf/cache_locality_view.bpf.o | true | 0 | policy detached |
| /home/yunwei37/workspace/namei_ext/.build/bpf/checkpoint_restore_view.bpf.o | true | 0 | policy loaded and attached |
| /home/yunwei37/workspace/namei_ext/.build/bpf/checkpoint_restore_view.bpf.o | true | 0 | policy detached |
| /home/yunwei37/workspace/namei_ext/.build/bpf/pass_only.bpf.o | true | 0 | policy loaded and attached |
| /home/yunwei37/workspace/namei_ext/.build/bpf/pass_only.bpf.o | true | 0 | policy detached |
| /home/yunwei37/workspace/namei_ext/.build/bpf/redirect_alias.bpf.o | true | 0 | policy loaded and attached |
| /home/yunwei37/workspace/namei_ext/.build/bpf/redirect_alias.bpf.o | true | 0 | policy detached |
| /home/yunwei37/workspace/namei_ext/.build/bpf/sandbox_fixture_view.bpf.o | true | 0 | policy loaded and attached |
| /home/yunwei37/workspace/namei_ext/.build/bpf/sandbox_fixture_view.bpf.o | true | 0 | policy detached |
| /home/yunwei37/workspace/namei_ext/.build/bpf/table_redirect.bpf.o | true | 0 | policy loaded and attached |
| /home/yunwei37/workspace/namei_ext/.build/bpf/table_redirect.bpf.o | true | 0 | policy detached |

## Policy Semantic Cases
| Family | Branch | Op | Pass | Errno | Detail |
|---|---|---|---:|---:|---|
| build_graph |  | setup | true | 0 | fixture directory created |
| build_graph | pre_attach | alias_absent | true | 0 | alias absent before attach |
| build_graph |  | attach | true | 0 | policy attached |
| build_graph | generated | lookup | true | 0 | redirected read matched |
| build_graph | generated | readdir | true | 0 | alias visible, backing hidden |
| build_graph | source_fallback | lookup | true | 0 | redirected read matched |
| build_graph | source_fallback | readdir | true | 0 | alias visible, backing hidden |
| build_graph | toolchain | lookup | true | 0 | redirected read matched |
| build_graph | toolchain | readdir | true | 0 | alias visible, backing hidden |
| build_graph | external_dep | lookup | true | 0 | redirected read matched |
| build_graph | external_dep | readdir | true | 0 | alias visible, backing hidden |
| build_graph | undeclared_poison | lookup | true | 0 | redirected read matched |
| build_graph | undeclared_poison | readdir | true | 0 | alias visible, backing hidden |
| build_graph | negative | lookup | true | 0 | negative lookup passed through |
| build_graph | pass_through | lookup | true | 0 | native pass-through matched |
| build_graph |  | detach | true | 0 | policy detached |
| build_graph | post_detach | alias_absent | true | 0 | alias absent after detach |
| build_graph |  | summary | true | 0 | family semantic passed |
| sandbox_fixture |  | setup | true | 0 | fixture directory created |
| sandbox_fixture | pre_attach | alias_absent | true | 0 | alias absent before attach |
| sandbox_fixture |  | attach | true | 0 | policy attached |
| sandbox_fixture | config | lookup | true | 0 | redirected read matched |
| sandbox_fixture | config | readdir | true | 0 | alias visible, backing hidden |
| sandbox_fixture | service_config | lookup | true | 0 | redirected read matched |
| sandbox_fixture | service_config | readdir | true | 0 | alias visible, backing hidden |
| sandbox_fixture | secret | lookup | true | 0 | redirected read matched |
| sandbox_fixture | secret | readdir | true | 0 | alias visible, backing hidden |
| sandbox_fixture | certificate | lookup | true | 0 | redirected read matched |
| sandbox_fixture | certificate | readdir | true | 0 | alias visible, backing hidden |
| sandbox_fixture | endpoint | lookup | true | 0 | redirected read matched |
| sandbox_fixture | endpoint | readdir | true | 0 | alias visible, backing hidden |
| sandbox_fixture | poison | lookup | true | 0 | redirected read matched |
| sandbox_fixture | poison | readdir | true | 0 | alias visible, backing hidden |
| sandbox_fixture | negative | lookup | true | 0 | negative lookup passed through |
| sandbox_fixture | pass_through | lookup | true | 0 | native pass-through matched |
| sandbox_fixture |  | detach | true | 0 | policy detached |
| sandbox_fixture | post_detach | alias_absent | true | 0 | alias absent after detach |
| sandbox_fixture |  | summary | true | 0 | family semantic passed |
| checkpoint_restore |  | setup | true | 0 | fixture directory created |
| checkpoint_restore | pre_attach | alias_absent | true | 0 | alias absent before attach |
| checkpoint_restore |  | attach | true | 0 | policy attached |
| checkpoint_restore | state | lookup | true | 0 | redirected read matched |
| checkpoint_restore | state | readdir | true | 0 | alias visible, backing hidden |
| checkpoint_restore | state_aof | lookup | true | 0 | redirected read matched |
| checkpoint_restore | state_aof | readdir | true | 0 | alias visible, backing hidden |
| checkpoint_restore | config | lookup | true | 0 | redirected read matched |
| checkpoint_restore | config | readdir | true | 0 | alias visible, backing hidden |
| checkpoint_restore | cache | lookup | true | 0 | redirected read matched |
| checkpoint_restore | cache | readdir | true | 0 | alias visible, backing hidden |
| checkpoint_restore | runtime_socket | lookup | true | 0 | redirected read matched |
| checkpoint_restore | runtime_socket | readdir | true | 0 | alias visible, backing hidden |
| checkpoint_restore | runtime_pid | lookup | true | 0 | redirected read matched |
| checkpoint_restore | runtime_pid | readdir | true | 0 | alias visible, backing hidden |
| checkpoint_restore | mixed_epoch | lookup | true | 0 | redirected read matched |
| checkpoint_restore | mixed_epoch | readdir | true | 0 | alias visible, backing hidden |
| checkpoint_restore | negative | lookup | true | 0 | negative lookup passed through |
| checkpoint_restore | pass_through | lookup | true | 0 | native pass-through matched |
| checkpoint_restore |  | detach | true | 0 | policy detached |
| checkpoint_restore | post_detach | alias_absent | true | 0 | alias absent after detach |
| checkpoint_restore |  | summary | true | 0 | family semantic passed |
| cache_locality |  | setup | true | 0 | fixture directory created |
| cache_locality | pre_attach | alias_absent | true | 0 | alias absent before attach |
| cache_locality |  | attach | true | 0 | policy attached |
| cache_locality | verified_hit | lookup | true | 0 | redirected read matched |
| cache_locality | verified_hit | readdir | true | 0 | alias visible, backing hidden |
| cache_locality | miss_canonical | lookup | true | 0 | redirected read matched |
| cache_locality | miss_canonical | readdir | true | 0 | alias visible, backing hidden |
| cache_locality | stale_canonical | lookup | true | 0 | redirected read matched |
| cache_locality | stale_canonical | readdir | true | 0 | alias visible, backing hidden |
| cache_locality | corrupt_reject | lookup | true | 0 | redirected read matched |
| cache_locality | corrupt_reject | readdir | true | 0 | alias visible, backing hidden |
| cache_locality | negative | lookup | true | 0 | negative lookup passed through |
| cache_locality | pass_through | lookup | true | 0 | native pass-through matched |
| cache_locality |  | detach | true | 0 | policy detached |
| cache_locality | post_detach | alias_absent | true | 0 | alias absent after detach |
| cache_locality |  | summary | true | 0 | family semantic passed |

## Table Conformance Cases
| Case | Pass | Detail |
|---|---:|---|
| source_readable | true | table_redirect.bpf.c is readable and non-empty |
| object_exists | true | table_redirect.bpf.o exists and is non-empty |
| source_stat | true | source stat succeeded |
| object_fresh | true | object mtime is not older than source mtime |
| policy_body_parse | true | single cgroup/namei_ext policy body parsed |
| single_attach_section | true | expected 1 occurrence(s), observed 1 |
| hash_map_only | true | expected 1 occurrence(s), observed 1 |
| single_exact_map_use | true | expected 2 occurrence(s), observed 2 |
| component_key_map_type | true | expected 2 occurrence(s), observed 2 |
| redirect_rule_map_type | true | expected 2 occurrence(s), observed 2 |
| component_key_builder | true | expected 1 occurrence(s), observed 1 |
| single_exact_lookup | true | expected 1 occurrence(s), observed 1 |
| pass_redirect_return | true | expected 1 occurrence(s), observed 1 |
| no_forbidden_source_helpers | true | no forbidden token present |
| no_policy_body_resolver_logic | true | no forbidden token present |

## W1 Path Oracle Cases
| Policy | Workload | Branch | Visible | Effective Shadow | Op | Pass | Errno | Detail |
|---|---|---|---|---|---|---:|---:|---|
| build_graph | w1-redis-build | generated_output | release.h | .namei_ext.generated.release.h | pre_attach_absent | true | 0 | alias absent before attach |
| build_graph | w1-redis-build | declared_source_fallback | server.c | .namei_ext.source.server.c | pre_attach_absent | true | 0 | alias absent before attach |
| build_graph | w1-redis-build | toolchain_selection | cc | cc.real | pre_attach_absent | true | 0 | alias absent before attach |
| build_graph | w1-redis-build | external_dependency | stdio.h | .namei_ext.external.stdio.h | pre_attach_absent | true | 0 | alias absent before attach |
| build_graph | w1-nginx-build | generated_output | ngx_auto_config.h | .namei_ext.generated.ngx_auto_config.h | pre_attach_absent | true | 0 | alias absent before attach |
| build_graph | w1-nginx-build | generated_output | ngx_auto_headers.h | .namei_ext.generated.ngx_auto_headers.h | pre_attach_absent | true | 0 | alias absent before attach |
| build_graph | w1-nginx-build | declared_source_fallback | nginx.c | .namei_ext.source.nginx.c | pre_attach_absent | true | 0 | alias absent before attach |
| build_graph | w1-nginx-build | toolchain_selection | cc | cc.real | pre_attach_absent | true | 0 | alias absent before attach |
| build_graph | w1-nginx-build | external_dependency | stdio.h | .namei_ext.external.stdio.h | pre_attach_absent | true | 0 | alias absent before attach |
| build_graph |  |  |  |  | load | true | 0 | policy loaded |
| build_graph |  |  |  |  | map_update | true | 0 | redirect map populated |
| build_graph |  |  |  |  | attach | true | 0 | policy attached |
| build_graph | w1-redis-build | generated_output | release.h | .namei_ext.generated.release.h | lookup | true | 0 | redirected lookup matched backing |
| build_graph | w1-redis-build | generated_output | release.h | .namei_ext.generated.release.h | readdir | true | 0 | alias visible and policy backing hidden |
| build_graph | w1-redis-build | declared_source_fallback | server.c | .namei_ext.source.server.c | lookup | true | 0 | redirected lookup matched backing |
| build_graph | w1-redis-build | declared_source_fallback | server.c | .namei_ext.source.server.c | readdir | true | 0 | alias visible and policy backing hidden |
| build_graph | w1-redis-build | toolchain_selection | cc | cc.real | lookup | true | 0 | redirected lookup matched backing |
| build_graph | w1-redis-build | toolchain_selection | cc | cc.real | readdir | true | 0 | alias visible and policy backing hidden |
| build_graph | w1-redis-build | external_dependency | stdio.h | .namei_ext.external.stdio.h | lookup | true | 0 | redirected lookup matched backing |
| build_graph | w1-redis-build | external_dependency | stdio.h | .namei_ext.external.stdio.h | readdir | true | 0 | alias visible and policy backing hidden |
| build_graph | w1-nginx-build | generated_output | ngx_auto_config.h | .namei_ext.generated.ngx_auto_config.h | lookup | true | 0 | redirected lookup matched backing |
| build_graph | w1-nginx-build | generated_output | ngx_auto_config.h | .namei_ext.generated.ngx_auto_config.h | readdir | true | 0 | alias visible and policy backing hidden |
| build_graph | w1-nginx-build | generated_output | ngx_auto_headers.h | .namei_ext.generated.ngx_auto_headers.h | lookup | true | 0 | redirected lookup matched backing |
| build_graph | w1-nginx-build | generated_output | ngx_auto_headers.h | .namei_ext.generated.ngx_auto_headers.h | readdir | true | 0 | alias visible and policy backing hidden |
| build_graph | w1-nginx-build | declared_source_fallback | nginx.c | .namei_ext.source.nginx.c | lookup | true | 0 | redirected lookup matched backing |
| build_graph | w1-nginx-build | declared_source_fallback | nginx.c | .namei_ext.source.nginx.c | readdir | true | 0 | alias visible and policy backing hidden |
| build_graph | w1-nginx-build | toolchain_selection | cc | cc.real | lookup | true | 0 | redirected lookup matched backing |
| build_graph | w1-nginx-build | toolchain_selection | cc | cc.real | readdir | true | 0 | alias visible and policy backing hidden |
| build_graph | w1-nginx-build | external_dependency | stdio.h | .namei_ext.external.stdio.h | lookup | true | 0 | redirected lookup matched backing |
| build_graph | w1-nginx-build | external_dependency | stdio.h | .namei_ext.external.stdio.h | readdir | true | 0 | alias visible and policy backing hidden |
| build_graph |  |  |  |  | detach | true | 0 | policy detached |
| build_graph | w1-redis-build | generated_output | release.h | .namei_ext.generated.release.h | post_detach_absent | true | 0 | alias absent after detach |
| build_graph | w1-redis-build | declared_source_fallback | server.c | .namei_ext.source.server.c | post_detach_absent | true | 0 | alias absent after detach |
| build_graph | w1-redis-build | toolchain_selection | cc | cc.real | post_detach_absent | true | 0 | alias absent after detach |
| build_graph | w1-redis-build | external_dependency | stdio.h | .namei_ext.external.stdio.h | post_detach_absent | true | 0 | alias absent after detach |
| build_graph | w1-nginx-build | generated_output | ngx_auto_config.h | .namei_ext.generated.ngx_auto_config.h | post_detach_absent | true | 0 | alias absent after detach |
| build_graph | w1-nginx-build | generated_output | ngx_auto_headers.h | .namei_ext.generated.ngx_auto_headers.h | post_detach_absent | true | 0 | alias absent after detach |
| build_graph | w1-nginx-build | declared_source_fallback | nginx.c | .namei_ext.source.nginx.c | post_detach_absent | true | 0 | alias absent after detach |
| build_graph | w1-nginx-build | toolchain_selection | cc | cc.real | post_detach_absent | true | 0 | alias absent after detach |
| build_graph | w1-nginx-build | external_dependency | stdio.h | .namei_ext.external.stdio.h | post_detach_absent | true | 0 | alias absent after detach |
| table_redirect | w1-redis-build | generated_output | release.h | .namei_ext.generated.release.h | pre_attach_absent | true | 0 | alias absent before attach |
| table_redirect | w1-redis-build | declared_source_fallback | server.c | .namei_ext.source.server.c | pre_attach_absent | true | 0 | alias absent before attach |
| table_redirect | w1-redis-build | toolchain_selection | cc | gcc | pre_attach_absent | true | 0 | alias absent before attach |
| table_redirect | w1-redis-build | external_dependency | stdio.h | .namei_ext.external.stdio.h | pre_attach_absent | true | 0 | alias absent before attach |
| table_redirect | w1-nginx-build | generated_output | ngx_auto_config.h | .namei_ext.generated.ngx_auto_config.h | pre_attach_absent | true | 0 | alias absent before attach |
| table_redirect | w1-nginx-build | generated_output | ngx_auto_headers.h | .namei_ext.generated.ngx_auto_headers.h | pre_attach_absent | true | 0 | alias absent before attach |
| table_redirect | w1-nginx-build | declared_source_fallback | nginx.c | .namei_ext.source.nginx.c | pre_attach_absent | true | 0 | alias absent before attach |
| table_redirect | w1-nginx-build | toolchain_selection | cc | gcc | pre_attach_absent | true | 0 | alias absent before attach |
| table_redirect | w1-nginx-build | external_dependency | stdio.h | .namei_ext.external.stdio.h | pre_attach_absent | true | 0 | alias absent before attach |
| table_redirect |  |  |  |  | load | true | 0 | policy loaded |
| table_redirect |  |  |  |  | map_update | true | 0 | redirect map populated |
| table_redirect |  |  |  |  | attach | true | 0 | policy attached |
| table_redirect | w1-redis-build | generated_output | release.h | .namei_ext.generated.release.h | lookup | true | 0 | redirected lookup matched backing |
| table_redirect | w1-redis-build | generated_output | release.h | .namei_ext.generated.release.h | readdir | true | 0 | alias visible and policy backing hidden |
| table_redirect | w1-redis-build | declared_source_fallback | server.c | .namei_ext.source.server.c | lookup | true | 0 | redirected lookup matched backing |
| table_redirect | w1-redis-build | declared_source_fallback | server.c | .namei_ext.source.server.c | readdir | true | 0 | alias visible and policy backing hidden |
| table_redirect | w1-redis-build | toolchain_selection | cc | gcc | lookup | true | 0 | redirected lookup matched backing |
| table_redirect | w1-redis-build | toolchain_selection | cc | gcc | readdir | true | 0 | alias visible and policy backing hidden |
| table_redirect | w1-redis-build | external_dependency | stdio.h | .namei_ext.external.stdio.h | lookup | true | 0 | redirected lookup matched backing |
| table_redirect | w1-redis-build | external_dependency | stdio.h | .namei_ext.external.stdio.h | readdir | true | 0 | alias visible and policy backing hidden |
| table_redirect | w1-nginx-build | generated_output | ngx_auto_config.h | .namei_ext.generated.ngx_auto_config.h | lookup | true | 0 | redirected lookup matched backing |
| table_redirect | w1-nginx-build | generated_output | ngx_auto_config.h | .namei_ext.generated.ngx_auto_config.h | readdir | true | 0 | alias visible and policy backing hidden |
| table_redirect | w1-nginx-build | generated_output | ngx_auto_headers.h | .namei_ext.generated.ngx_auto_headers.h | lookup | true | 0 | redirected lookup matched backing |
| table_redirect | w1-nginx-build | generated_output | ngx_auto_headers.h | .namei_ext.generated.ngx_auto_headers.h | readdir | true | 0 | alias visible and policy backing hidden |
| table_redirect | w1-nginx-build | declared_source_fallback | nginx.c | .namei_ext.source.nginx.c | lookup | true | 0 | redirected lookup matched backing |
| table_redirect | w1-nginx-build | declared_source_fallback | nginx.c | .namei_ext.source.nginx.c | readdir | true | 0 | alias visible and policy backing hidden |
| table_redirect | w1-nginx-build | toolchain_selection | cc | gcc | lookup | true | 0 | redirected lookup matched backing |
| table_redirect | w1-nginx-build | toolchain_selection | cc | gcc | readdir | true | 0 | alias visible and policy backing hidden |
| table_redirect | w1-nginx-build | external_dependency | stdio.h | .namei_ext.external.stdio.h | lookup | true | 0 | redirected lookup matched backing |
| table_redirect | w1-nginx-build | external_dependency | stdio.h | .namei_ext.external.stdio.h | readdir | true | 0 | alias visible and policy backing hidden |
| table_redirect |  |  |  |  | detach | true | 0 | policy detached |
| table_redirect | w1-redis-build | generated_output | release.h | .namei_ext.generated.release.h | post_detach_absent | true | 0 | alias absent after detach |
| table_redirect | w1-redis-build | declared_source_fallback | server.c | .namei_ext.source.server.c | post_detach_absent | true | 0 | alias absent after detach |
| table_redirect | w1-redis-build | toolchain_selection | cc | gcc | post_detach_absent | true | 0 | alias absent after detach |
| table_redirect | w1-redis-build | external_dependency | stdio.h | .namei_ext.external.stdio.h | post_detach_absent | true | 0 | alias absent after detach |
| table_redirect | w1-nginx-build | generated_output | ngx_auto_config.h | .namei_ext.generated.ngx_auto_config.h | post_detach_absent | true | 0 | alias absent after detach |
| table_redirect | w1-nginx-build | generated_output | ngx_auto_headers.h | .namei_ext.generated.ngx_auto_headers.h | post_detach_absent | true | 0 | alias absent after detach |
| table_redirect | w1-nginx-build | declared_source_fallback | nginx.c | .namei_ext.source.nginx.c | post_detach_absent | true | 0 | alias absent after detach |
| table_redirect | w1-nginx-build | toolchain_selection | cc | gcc | post_detach_absent | true | 0 | alias absent after detach |
| table_redirect | w1-nginx-build | external_dependency | stdio.h | .namei_ext.external.stdio.h | post_detach_absent | true | 0 | alias absent after detach |

## W1 Host Real Build Output Oracle
Host-only witness; not KVM policy build replay.
| Workload | Pass | Policy Executed | KVM Validated | Build Binary SHA256 | Trace File Ops | Qualified For C8 | Detail |
|---|---:|---:|---:|---|---:|---:|---|
| w1-redis-build | true | false | false | ee689b68c9340e5374a863a9187e7995bf431482bed69a8429f69b92678227e8 | 1236752 | false | host real Redis source build produced auditable binary hashes; this is not KVM policy replay |
| w1-nginx-build | true | false | false | d0bf615138b68d6f4a9ecafe8f463bca68e08629fda291dfa1fd836c26dfac6e | 1796526 | false | host real nginx source build produced auditable binary hashes; this is not KVM policy replay |

## W1 KVM Policy Build Replay Witness
KVM policy preprocessing witness; not release binary replay and not C8-qualified.
| Workload | Op | Pass | Policy Executed | KVM Validated | Output Scope | Qualified For C8 | Detail |
|---|---|---:|---:|---:|---|---:|---|
| w1-redis-build | baseline_preprocess | true | false | true | kvm_policy_preprocess | false | Redis baseline preprocessing passed |
| w1-nginx-build | baseline_preprocess | true | false | true | kvm_policy_preprocess | false | nginx baseline preprocessing passed |
| w1-redis-build | output_compare | true | true | true | kvm_policy_preprocess | false | Redis real-source preprocessing matched baseline through policy aliases |
| w1-nginx-build | output_compare | true | true | true | kvm_policy_preprocess | false | nginx real-source preprocessing matched baseline through policy aliases |

## W1 KVM Policy Release Binary Replay Witness
KVM policy full rebuild witness for Redis and nginx release binaries; not C8-qualified.
| Workload | Op | Pass | Policy Executed | KVM Validated | Binary Hash Match | Qualified For C8 | Detail |
|---|---|---:|---:|---:|---:|---:|---|
| w1-redis-build | baseline_release_build | true | false | true | false | false | Redis baseline release rebuild passed |
| w1-nginx-build | baseline_release_build | true | false | true | false | false | nginx baseline release rebuild passed |
| w1-redis-build | policy_release_build | true | true | true | false | false | Redis policy release rebuild passed |
| w1-nginx-build | policy_release_build | true | true | true | false | false | nginx policy release rebuild passed |
| w1-redis-build | output_compare | true | true | true | true | false | policy release binary matched baseline |
| w1-nginx-build | output_compare | true | true | true | true | false | policy release binary matched baseline |

## W1 KVM Build-Graph Branch Probes
KVM branch witness for undeclared-dependency poison and negative fallback in real Redis/nginx source parent directories; not C8-qualified.
| Workload | Branch | Op | Pass | Policy Executed | Qualified For C8 | Detail |
|---|---|---|---:|---:|---:|---|
| w1-redis-build | undeclared_dependency_poison | attached_poison_lookup | true | true | false | private.h resolved to poison.dep sentinel |
| w1-redis-build | undeclared_dependency_poison | attached_poison_readdir_alias | true | true | false | readdir exposed private.h and hid poison.dep |
| w1-redis-build | negative_fallback | attached_negative_lookup | true | true | false | path remained absent |
| w1-redis-build | negative_fallback | attached_negative_readdir_absent | true | true | false | missing.h stayed absent from readdir |
| w1-nginx-build | undeclared_dependency_poison | attached_poison_lookup | true | true | false | private.h resolved to poison.dep sentinel |
| w1-nginx-build | undeclared_dependency_poison | attached_poison_readdir_alias | true | true | false | readdir exposed private.h and hid poison.dep |
| w1-nginx-build | negative_fallback | attached_negative_lookup | true | true | false | path remained absent |
| w1-nginx-build | negative_fallback | attached_negative_readdir_absent | true | true | false | missing.h stayed absent from readdir |

## W2 Fixture Path Oracle Cases
| Policy | Workload | Branch | Visible | Effective Shadow | Op | Pass | Errno | Detail |
|---|---|---|---|---|---|---:|---:|---|
| sandbox_fixture | w2-nginx-fixture | config | nginx.conf | nginx.test.conf | pre_attach_absent | true | 0 | alias absent before attach |
| sandbox_fixture | w2-nginx-fixture | certificate | server.crt | server.fake.crt | pre_attach_absent | true | 0 | alias absent before attach |
| sandbox_fixture | w2-nginx-fixture | endpoint | upstream.sock | upstream.local | pre_attach_absent | true | 0 | alias absent before attach |
| sandbox_fixture | w2-nginx-fixture | poison | prod.token | poison.secret | pre_attach_absent | true | 0 | alias absent before attach |
| sandbox_fixture | w2-postgres-secret-fixture | service_config | postgresql.conf | postgres.test.conf | pre_attach_absent | true | 0 | alias absent before attach |
| sandbox_fixture | w2-postgres-secret-fixture | secret | db.password | db.fake.pass | pre_attach_absent | true | 0 | alias absent before attach |
| sandbox_fixture |  |  |  |  | load | true | 0 | policy loaded |
| sandbox_fixture |  |  |  |  | policy_state | true | 0 | literal fixture path-class rules active |
| sandbox_fixture |  |  |  |  | attach | true | 0 | policy attached |
| sandbox_fixture | w2-nginx-fixture | config | nginx.conf | nginx.test.conf | lookup | true | 0 | redirected lookup matched backing |
| sandbox_fixture | w2-nginx-fixture | config | nginx.conf | nginx.test.conf | readdir | true | 0 | alias visible and policy backing hidden |
| sandbox_fixture | w2-nginx-fixture | certificate | server.crt | server.fake.crt | lookup | true | 0 | redirected lookup matched backing |
| sandbox_fixture | w2-nginx-fixture | certificate | server.crt | server.fake.crt | readdir | true | 0 | alias visible and policy backing hidden |
| sandbox_fixture | w2-nginx-fixture | endpoint | upstream.sock | upstream.local | lookup | true | 0 | redirected lookup matched backing |
| sandbox_fixture | w2-nginx-fixture | endpoint | upstream.sock | upstream.local | readdir | true | 0 | alias visible and policy backing hidden |
| sandbox_fixture | w2-nginx-fixture | poison | prod.token | poison.secret | lookup | true | 0 | redirected lookup matched backing |
| sandbox_fixture | w2-nginx-fixture | poison | prod.token | poison.secret | readdir | true | 0 | alias visible and policy backing hidden |
| sandbox_fixture | w2-postgres-secret-fixture | service_config | postgresql.conf | postgres.test.conf | lookup | true | 0 | redirected lookup matched backing |
| sandbox_fixture | w2-postgres-secret-fixture | service_config | postgresql.conf | postgres.test.conf | readdir | true | 0 | alias visible and policy backing hidden |
| sandbox_fixture | w2-postgres-secret-fixture | secret | db.password | db.fake.pass | lookup | true | 0 | redirected lookup matched backing |
| sandbox_fixture | w2-postgres-secret-fixture | secret | db.password | db.fake.pass | readdir | true | 0 | alias visible and policy backing hidden |
| sandbox_fixture |  |  |  |  | detach | true | 0 | policy detached |
| sandbox_fixture | w2-nginx-fixture | config | nginx.conf | nginx.test.conf | post_detach_absent | true | 0 | alias absent after detach |
| sandbox_fixture | w2-nginx-fixture | certificate | server.crt | server.fake.crt | post_detach_absent | true | 0 | alias absent after detach |
| sandbox_fixture | w2-nginx-fixture | endpoint | upstream.sock | upstream.local | post_detach_absent | true | 0 | alias absent after detach |
| sandbox_fixture | w2-nginx-fixture | poison | prod.token | poison.secret | post_detach_absent | true | 0 | alias absent after detach |
| sandbox_fixture | w2-postgres-secret-fixture | service_config | postgresql.conf | postgres.test.conf | post_detach_absent | true | 0 | alias absent after detach |
| sandbox_fixture | w2-postgres-secret-fixture | secret | db.password | db.fake.pass | post_detach_absent | true | 0 | alias absent after detach |
| table_redirect | w2-nginx-fixture | config | nginx.conf | nginx.test.conf | pre_attach_absent | true | 0 | alias absent before attach |
| table_redirect | w2-nginx-fixture | certificate | server.crt | server.fake.crt | pre_attach_absent | true | 0 | alias absent before attach |
| table_redirect | w2-nginx-fixture | endpoint | upstream.sock | upstream.local | pre_attach_absent | true | 0 | alias absent before attach |
| table_redirect | w2-nginx-fixture | poison | prod.token | poison.secret | pre_attach_absent | true | 0 | alias absent before attach |
| table_redirect | w2-postgres-secret-fixture | service_config | postgresql.conf | postgres.test.conf | pre_attach_absent | true | 0 | alias absent before attach |
| table_redirect | w2-postgres-secret-fixture | secret | db.password | db.fake.pass | pre_attach_absent | true | 0 | alias absent before attach |
| table_redirect |  |  |  |  | load | true | 0 | policy loaded |
| table_redirect |  |  |  |  | map_update | true | 0 | redirect map populated |
| table_redirect |  |  |  |  | attach | true | 0 | policy attached |
| table_redirect | w2-nginx-fixture | config | nginx.conf | nginx.test.conf | lookup | true | 0 | redirected lookup matched backing |
| table_redirect | w2-nginx-fixture | config | nginx.conf | nginx.test.conf | readdir | true | 0 | alias visible and policy backing hidden |
| table_redirect | w2-nginx-fixture | certificate | server.crt | server.fake.crt | lookup | true | 0 | redirected lookup matched backing |
| table_redirect | w2-nginx-fixture | certificate | server.crt | server.fake.crt | readdir | true | 0 | alias visible and policy backing hidden |
| table_redirect | w2-nginx-fixture | endpoint | upstream.sock | upstream.local | lookup | true | 0 | redirected lookup matched backing |
| table_redirect | w2-nginx-fixture | endpoint | upstream.sock | upstream.local | readdir | true | 0 | alias visible and policy backing hidden |
| table_redirect | w2-nginx-fixture | poison | prod.token | poison.secret | lookup | true | 0 | redirected lookup matched backing |
| table_redirect | w2-nginx-fixture | poison | prod.token | poison.secret | readdir | true | 0 | alias visible and policy backing hidden |
| table_redirect | w2-postgres-secret-fixture | service_config | postgresql.conf | postgres.test.conf | lookup | true | 0 | redirected lookup matched backing |
| table_redirect | w2-postgres-secret-fixture | service_config | postgresql.conf | postgres.test.conf | readdir | true | 0 | alias visible and policy backing hidden |
| table_redirect | w2-postgres-secret-fixture | secret | db.password | db.fake.pass | lookup | true | 0 | redirected lookup matched backing |
| table_redirect | w2-postgres-secret-fixture | secret | db.password | db.fake.pass | readdir | true | 0 | alias visible and policy backing hidden |
| table_redirect |  |  |  |  | detach | true | 0 | policy detached |
| table_redirect | w2-nginx-fixture | config | nginx.conf | nginx.test.conf | post_detach_absent | true | 0 | alias absent after detach |
| table_redirect | w2-nginx-fixture | certificate | server.crt | server.fake.crt | post_detach_absent | true | 0 | alias absent after detach |
| table_redirect | w2-nginx-fixture | endpoint | upstream.sock | upstream.local | post_detach_absent | true | 0 | alias absent after detach |
| table_redirect | w2-nginx-fixture | poison | prod.token | poison.secret | post_detach_absent | true | 0 | alias absent after detach |
| table_redirect | w2-postgres-secret-fixture | service_config | postgresql.conf | postgres.test.conf | post_detach_absent | true | 0 | alias absent after detach |
| table_redirect | w2-postgres-secret-fixture | secret | db.password | db.fake.pass | post_detach_absent | true | 0 | alias absent after detach |

## W2 Nginx Real App Endpoint Health And Fixture Probe Cases
| Op | Pass | Exit Code | Detail | Stdout | Stderr |
|---|---:|---:|---|---|---|
| materialize | true | 0 | nginx prefix materialized from workload fixture config and endpoint fixture |  |  |
| pre_attach_nginx_test | true | 1 | nginx rejected missing alias before attach | /home/yunwei37/workspace/namei_ext/results/phase1/20260615T-full-phase1-c2-release-sample-v1/w2-nginx-real-app/pre-attach.stdout | /home/yunwei37/workspace/namei_ext/results/phase1/20260615T-full-phase1-c2-release-sample-v1/w2-nginx-real-app/pre-attach.stderr |
| load | true | 0 | sandbox policy loaded |  |  |
| policy_state | true | 0 | literal nginx.conf and upstream.sock redirects active |  |  |
| attach | true | 0 | sandbox policy attached |  |  |
| attached_nginx_test | true | 0 | nginx accepted redirected workload fixture config | /home/yunwei37/workspace/namei_ext/results/phase1/20260615T-full-phase1-c2-release-sample-v1/w2-nginx-real-app/attached.stdout | /home/yunwei37/workspace/namei_ext/results/phase1/20260615T-full-phase1-c2-release-sample-v1/w2-nginx-real-app/attached.stderr |
| attached_config_fixture_probe | true | 0 | nginx.conf resolved to workload fixture config and not production config decoy |  |  |
| attached_endpoint_fixture_probe | true | 0 | upstream.sock resolved to local endpoint fixture and not production endpoint decoy |  |  |
| attached_fake_cert_probe | true | 0 | server.crt resolved to fake certificate fixture and not production certificate decoy |  |  |
| attached_fake_secret_probe | true | 0 | db.password resolved to fake secret fixture and not production secret decoy |  |  |
| attached_poison_probe | true | 0 | prod.token resolved to poison sentinel and not production token decoy |  |  |
| attached_nginx_start | true | 0 | nginx daemon started with redirected config | /home/yunwei37/workspace/namei_ext/results/phase1/20260615T-full-phase1-c2-release-sample-v1/w2-nginx-real-app/attached-start.stdout | /home/yunwei37/workspace/namei_ext/results/phase1/20260615T-full-phase1-c2-release-sample-v1/w2-nginx-real-app/attached-start.stderr |
| attached_upstream_start | true | 0 | local upstream endpoint listening on 127.0.0.1:18080 |  |  |
| attached_http_health | true | 0 | nginx HTTP health returned expected body | /home/yunwei37/workspace/namei_ext/results/phase1/20260615T-full-phase1-c2-release-sample-v1/w2-nginx-real-app/attached-health.response |  |
| attached_endpoint_upstream | true | 0 | local upstream endpoint served nginx request through redirected include |  |  |
| attached_nginx_quit | true | 0 | nginx quit command succeeded | /home/yunwei37/workspace/namei_ext/results/phase1/20260615T-full-phase1-c2-release-sample-v1/w2-nginx-real-app/attached-quit.stdout | /home/yunwei37/workspace/namei_ext/results/phase1/20260615T-full-phase1-c2-release-sample-v1/w2-nginx-real-app/attached-quit.stderr |
| detach | true | 0 | sandbox policy detached |  |  |
| post_detach_nginx_test | true | 1 | nginx rejected alias after detach | /home/yunwei37/workspace/namei_ext/results/phase1/20260615T-full-phase1-c2-release-sample-v1/w2-nginx-real-app/post-detach.stdout | /home/yunwei37/workspace/namei_ext/results/phase1/20260615T-full-phase1-c2-release-sample-v1/w2-nginx-real-app/post-detach.stderr |

## W3 Checkpoint Path Oracle Cases
| Policy | Workload | Branch | Visible | Effective Shadow | Op | Pass | Errno | Detail |
|---|---|---|---|---|---|---:|---:|---|
| checkpoint_restore | w3-redis-podman-criu | state_rdb | dump.rdb | dump.ckpt | pre_attach_absent | true | 0 | alias absent before attach |
| checkpoint_restore | w3-redis-podman-criu | state_aof | appendonly.aof | aof.ckpt | pre_attach_absent | true | 0 | alias absent before attach |
| checkpoint_restore | w3-redis-podman-criu | runtime_socket | redis.sock | redis.sock.new | pre_attach_absent | true | 0 | alias absent before attach |
| checkpoint_restore | w3-redis-podman-criu | mixed_epoch_poison | epoch.bad | poison.epoch | pre_attach_absent | true | 0 | alias absent before attach |
| checkpoint_restore | w3-nginx-podman-criu | config | nginx.conf | nginx.ckpt | pre_attach_absent | true | 0 | alias absent before attach |
| checkpoint_restore | w3-nginx-podman-criu | cache | cache.db | cache.ckpt | pre_attach_absent | true | 0 | alias absent before attach |
| checkpoint_restore | w3-nginx-podman-criu | runtime_pid | nginx.pid | nginx.pid.new | pre_attach_absent | true | 0 | alias absent before attach |
| checkpoint_restore |  |  |  |  | load | true | 0 | policy loaded |
| checkpoint_restore |  |  |  |  | policy_state | true | 0 | literal checkpoint path-class rules active |
| checkpoint_restore |  |  |  |  | attach | true | 0 | policy attached |
| checkpoint_restore | w3-redis-podman-criu | state_rdb | dump.rdb | dump.ckpt | lookup | true | 0 | redirected lookup matched backing |
| checkpoint_restore | w3-redis-podman-criu | state_rdb | dump.rdb | dump.ckpt | readdir | true | 0 | alias visible and policy backing hidden |
| checkpoint_restore | w3-redis-podman-criu | state_aof | appendonly.aof | aof.ckpt | lookup | true | 0 | redirected lookup matched backing |
| checkpoint_restore | w3-redis-podman-criu | state_aof | appendonly.aof | aof.ckpt | readdir | true | 0 | alias visible and policy backing hidden |
| checkpoint_restore | w3-redis-podman-criu | runtime_socket | redis.sock | redis.sock.new | lookup | true | 0 | redirected lookup matched backing |
| checkpoint_restore | w3-redis-podman-criu | runtime_socket | redis.sock | redis.sock.new | readdir | true | 0 | alias visible and policy backing hidden |
| checkpoint_restore | w3-redis-podman-criu | mixed_epoch_poison | epoch.bad | poison.epoch | lookup | true | 0 | redirected lookup matched backing |
| checkpoint_restore | w3-redis-podman-criu | mixed_epoch_poison | epoch.bad | poison.epoch | readdir | true | 0 | alias visible and policy backing hidden |
| checkpoint_restore | w3-nginx-podman-criu | config | nginx.conf | nginx.ckpt | lookup | true | 0 | redirected lookup matched backing |
| checkpoint_restore | w3-nginx-podman-criu | config | nginx.conf | nginx.ckpt | readdir | true | 0 | alias visible and policy backing hidden |
| checkpoint_restore | w3-nginx-podman-criu | cache | cache.db | cache.ckpt | lookup | true | 0 | redirected lookup matched backing |
| checkpoint_restore | w3-nginx-podman-criu | cache | cache.db | cache.ckpt | readdir | true | 0 | alias visible and policy backing hidden |
| checkpoint_restore | w3-nginx-podman-criu | runtime_pid | nginx.pid | nginx.pid.new | lookup | true | 0 | redirected lookup matched backing |
| checkpoint_restore | w3-nginx-podman-criu | runtime_pid | nginx.pid | nginx.pid.new | readdir | true | 0 | alias visible and policy backing hidden |
| checkpoint_restore |  |  |  |  | detach | true | 0 | policy detached |
| checkpoint_restore | w3-redis-podman-criu | state_rdb | dump.rdb | dump.ckpt | post_detach_absent | true | 0 | alias absent after detach |
| checkpoint_restore | w3-redis-podman-criu | state_aof | appendonly.aof | aof.ckpt | post_detach_absent | true | 0 | alias absent after detach |
| checkpoint_restore | w3-redis-podman-criu | runtime_socket | redis.sock | redis.sock.new | post_detach_absent | true | 0 | alias absent after detach |
| checkpoint_restore | w3-redis-podman-criu | mixed_epoch_poison | epoch.bad | poison.epoch | post_detach_absent | true | 0 | alias absent after detach |
| checkpoint_restore | w3-nginx-podman-criu | config | nginx.conf | nginx.ckpt | post_detach_absent | true | 0 | alias absent after detach |
| checkpoint_restore | w3-nginx-podman-criu | cache | cache.db | cache.ckpt | post_detach_absent | true | 0 | alias absent after detach |
| checkpoint_restore | w3-nginx-podman-criu | runtime_pid | nginx.pid | nginx.pid.new | post_detach_absent | true | 0 | alias absent after detach |
| table_redirect | w3-redis-podman-criu | state_rdb | dump.rdb | dump.ckpt | pre_attach_absent | true | 0 | alias absent before attach |
| table_redirect | w3-redis-podman-criu | state_aof | appendonly.aof | aof.ckpt | pre_attach_absent | true | 0 | alias absent before attach |
| table_redirect | w3-redis-podman-criu | runtime_socket | redis.sock | redis.sock.new | pre_attach_absent | true | 0 | alias absent before attach |
| table_redirect | w3-redis-podman-criu | mixed_epoch_poison | epoch.bad | poison.epoch | pre_attach_absent | true | 0 | alias absent before attach |
| table_redirect | w3-nginx-podman-criu | config | nginx.conf | nginx.ckpt | pre_attach_absent | true | 0 | alias absent before attach |
| table_redirect | w3-nginx-podman-criu | cache | cache.db | cache.ckpt | pre_attach_absent | true | 0 | alias absent before attach |
| table_redirect | w3-nginx-podman-criu | runtime_pid | nginx.pid | nginx.pid.new | pre_attach_absent | true | 0 | alias absent before attach |
| table_redirect |  |  |  |  | load | true | 0 | policy loaded |
| table_redirect |  |  |  |  | map_update | true | 0 | redirect map populated |
| table_redirect |  |  |  |  | attach | true | 0 | policy attached |
| table_redirect | w3-redis-podman-criu | state_rdb | dump.rdb | dump.ckpt | lookup | true | 0 | redirected lookup matched backing |
| table_redirect | w3-redis-podman-criu | state_rdb | dump.rdb | dump.ckpt | readdir | true | 0 | alias visible and policy backing hidden |
| table_redirect | w3-redis-podman-criu | state_aof | appendonly.aof | aof.ckpt | lookup | true | 0 | redirected lookup matched backing |
| table_redirect | w3-redis-podman-criu | state_aof | appendonly.aof | aof.ckpt | readdir | true | 0 | alias visible and policy backing hidden |
| table_redirect | w3-redis-podman-criu | runtime_socket | redis.sock | redis.sock.new | lookup | true | 0 | redirected lookup matched backing |
| table_redirect | w3-redis-podman-criu | runtime_socket | redis.sock | redis.sock.new | readdir | true | 0 | alias visible and policy backing hidden |
| table_redirect | w3-redis-podman-criu | mixed_epoch_poison | epoch.bad | poison.epoch | lookup | true | 0 | redirected lookup matched backing |
| table_redirect | w3-redis-podman-criu | mixed_epoch_poison | epoch.bad | poison.epoch | readdir | true | 0 | alias visible and policy backing hidden |
| table_redirect | w3-nginx-podman-criu | config | nginx.conf | nginx.ckpt | lookup | true | 0 | redirected lookup matched backing |
| table_redirect | w3-nginx-podman-criu | config | nginx.conf | nginx.ckpt | readdir | true | 0 | alias visible and policy backing hidden |
| table_redirect | w3-nginx-podman-criu | cache | cache.db | cache.ckpt | lookup | true | 0 | redirected lookup matched backing |
| table_redirect | w3-nginx-podman-criu | cache | cache.db | cache.ckpt | readdir | true | 0 | alias visible and policy backing hidden |
| table_redirect | w3-nginx-podman-criu | runtime_pid | nginx.pid | nginx.pid.new | lookup | true | 0 | redirected lookup matched backing |
| table_redirect | w3-nginx-podman-criu | runtime_pid | nginx.pid | nginx.pid.new | readdir | true | 0 | alias visible and policy backing hidden |
| table_redirect |  |  |  |  | detach | true | 0 | policy detached |
| table_redirect | w3-redis-podman-criu | state_rdb | dump.rdb | dump.ckpt | post_detach_absent | true | 0 | alias absent after detach |
| table_redirect | w3-redis-podman-criu | state_aof | appendonly.aof | aof.ckpt | post_detach_absent | true | 0 | alias absent after detach |
| table_redirect | w3-redis-podman-criu | runtime_socket | redis.sock | redis.sock.new | post_detach_absent | true | 0 | alias absent after detach |
| table_redirect | w3-redis-podman-criu | mixed_epoch_poison | epoch.bad | poison.epoch | post_detach_absent | true | 0 | alias absent after detach |
| table_redirect | w3-nginx-podman-criu | config | nginx.conf | nginx.ckpt | post_detach_absent | true | 0 | alias absent after detach |
| table_redirect | w3-nginx-podman-criu | cache | cache.db | cache.ckpt | post_detach_absent | true | 0 | alias absent after detach |
| table_redirect | w3-nginx-podman-criu | runtime_pid | nginx.pid | nginx.pid.new | post_detach_absent | true | 0 | alias absent after detach |

## W3 Redis Checkpoint Replay Witness
KVM Redis server replay witness for checkpoint state loaded through checkpoint_restore policy; real Podman/CRIU restore is still not executed and this is not C8-qualified.
| Op | Pass | Policy Executed | Expected | Actual | Qualified For C8 | Detail |
|---|---:|---:|---|---|---:|---|
| generate_checkpoint_start | true | false | exit_code=0 | exit_code=0 | false | Redis checkpoint generator started |
| generate_checkpoint_set | true | false | +OK | +OK\r\n | false | Redis checkpoint value seeded |
| generate_checkpoint_save | true | false | +OK | +OK\r\n | false | Redis checkpoint file saved |
| checkpoint_file_exists | true | false | exists | exists | false | Redis checkpoint backing file exists |
| pre_attach_get_empty | true | false | $-1 | $-1\r\n | false | Redis did not load hidden checkpoint before attach |
| load | true | false | load | load | false | checkpoint replay policy loaded |
| attach | true | true | attach | attach | false | checkpoint replay policy attached |
| attached_get_checkpoint_value | true | true | checkpoint_restore_policy_loaded | $32\r\ncheckpoint_restore_policy_loaded\r\n | false | Redis loaded checkpoint value through visible dump.rdb |
| attached_readdir_alias | true | true | dump.rdb | dump.rdb | false | checkpoint backing appears as visible dump.rdb while attached |
| detach | true | true | detach | detach | false | checkpoint replay policy detached |
| post_detach_get_empty | true | false | $-1 | $-1\r\n | false | Redis no longer loaded hidden checkpoint after detach |

## W3 Redis Table-Only Replay Counterfactual
Same KVM Redis checkpoint replay under table_redirect. A pass is negative C8 evidence for this replay, not support for programmability.
| Op | Pass | Policy Family | Table Baseline | Expected | Actual | Qualified For C8 | Detail |
|---|---:|---|---:|---|---|---:|---|
| generate_checkpoint_start | true | table_redirect.bpf.c | true | exit_code=0 | exit_code=0 | false | Redis checkpoint generator started |
| generate_checkpoint_set | true | table_redirect.bpf.c | true | +OK | +OK\r\n | false | Redis checkpoint value seeded |
| generate_checkpoint_save | true | table_redirect.bpf.c | true | +OK | +OK\r\n | false | Redis checkpoint file saved |
| checkpoint_file_exists | true | table_redirect.bpf.c | true | exists | exists | false | Redis checkpoint backing file exists |
| pre_attach_get_empty | true | table_redirect.bpf.c | true | $-1 | $-1\r\n | false | Redis did not load hidden checkpoint before attach |
| load | true | table_redirect.bpf.c | true | load | load | false | checkpoint replay policy loaded |
| populate_table_rules | true | table_redirect.bpf.c | true | 2 | 2 | false | table_redirect checkpoint lookup and readdir rules populated |
| attach | true | table_redirect.bpf.c | true | attach | attach | false | checkpoint replay policy attached |
| attached_get_checkpoint_value | true | table_redirect.bpf.c | true | checkpoint_restore_policy_loaded | $32\r\ncheckpoint_restore_policy_loaded\r\n | false | Redis loaded checkpoint value through visible dump.rdb |
| attached_readdir_alias | true | table_redirect.bpf.c | true | dump.rdb | dump.rdb | false | checkpoint backing appears as visible dump.rdb while attached |
| detach | true | table_redirect.bpf.c | true | detach | detach | false | checkpoint replay policy detached |
| post_detach_get_empty | true | table_redirect.bpf.c | true | $-1 | $-1\r\n | false | Redis no longer loaded hidden checkpoint after detach |

## W3 Redis Counterfactual Accounting
| Workload | Policy Pass | Table Pass | Table Rules | Table Budget Failure | Qualified For C8 | Detail |
|---|---:|---:|---:|---:|---:|---|
| w3-redis-podman-criu | true | true | 2 | false | false | same Redis checkpoint replay passed with checkpoint_restore and table_redirect; this is negative C8 evidence until a release restore/update/stale oracle makes table-only fail or exceed budget |

## W4 Cache Path Oracle Cases
| Policy | Workload | Branch | Visible | Effective Shadow | Op | Pass | Errno | Detail |
|---|---|---|---|---|---|---:|---:|---|
| cache_locality | w4-ccache-redis-nginx | verified_hit | object.o | object.local | pre_attach_absent | true | 0 | alias absent before attach |
| cache_locality | w4-ccache-redis-nginx | stale_fallback | stale.o | stale.canon | pre_attach_absent | true | 0 | alias absent before attach |
| cache_locality | w4-ccache-redis-nginx | corrupt_reject | corrupt.o | corrupt.reject | pre_attach_absent | true | 0 | alias absent before attach |
| cache_locality | w4-buildkit-prometheus-go-cache | miss_canonical | pkg.mod | pkg.canon | pre_attach_absent | true | 0 | alias absent before attach |
| cache_locality |  |  |  |  | load | true | 0 | policy loaded |
| cache_locality |  |  |  |  | map_update | true | 0 | redirect map populated |
| cache_locality |  |  |  |  | attach | true | 0 | policy attached |
| cache_locality | w4-ccache-redis-nginx | verified_hit | object.o | object.local | lookup | true | 0 | redirected lookup matched backing |
| cache_locality | w4-ccache-redis-nginx | verified_hit | object.o | object.local | readdir | true | 0 | alias visible and policy backing hidden |
| cache_locality | w4-ccache-redis-nginx | stale_fallback | stale.o | stale.canon | lookup | true | 0 | redirected lookup matched backing |
| cache_locality | w4-ccache-redis-nginx | stale_fallback | stale.o | stale.canon | readdir | true | 0 | alias visible and policy backing hidden |
| cache_locality | w4-ccache-redis-nginx | corrupt_reject | corrupt.o | corrupt.reject | lookup | true | 0 | redirected lookup matched backing |
| cache_locality | w4-ccache-redis-nginx | corrupt_reject | corrupt.o | corrupt.reject | readdir | true | 0 | alias visible and policy backing hidden |
| cache_locality | w4-buildkit-prometheus-go-cache | miss_canonical | pkg.mod | pkg.canon | lookup | true | 0 | redirected lookup matched backing |
| cache_locality | w4-buildkit-prometheus-go-cache | miss_canonical | pkg.mod | pkg.canon | readdir | true | 0 | alias visible and policy backing hidden |
| cache_locality |  |  |  |  | detach | true | 0 | policy detached |
| cache_locality | w4-ccache-redis-nginx | verified_hit | object.o | object.local | post_detach_absent | true | 0 | alias absent after detach |
| cache_locality | w4-ccache-redis-nginx | stale_fallback | stale.o | stale.canon | post_detach_absent | true | 0 | alias absent after detach |
| cache_locality | w4-ccache-redis-nginx | corrupt_reject | corrupt.o | corrupt.reject | post_detach_absent | true | 0 | alias absent after detach |
| cache_locality | w4-buildkit-prometheus-go-cache | miss_canonical | pkg.mod | pkg.canon | post_detach_absent | true | 0 | alias absent after detach |
| table_redirect | w4-ccache-redis-nginx | verified_hit | object.o | object.local | pre_attach_absent | true | 0 | alias absent before attach |
| table_redirect | w4-ccache-redis-nginx | stale_fallback | stale.o | stale.canon | pre_attach_absent | true | 0 | alias absent before attach |
| table_redirect | w4-ccache-redis-nginx | corrupt_reject | corrupt.o | corrupt.reject | pre_attach_absent | true | 0 | alias absent before attach |
| table_redirect | w4-buildkit-prometheus-go-cache | miss_canonical | pkg.mod | pkg.canon | pre_attach_absent | true | 0 | alias absent before attach |
| table_redirect |  |  |  |  | load | true | 0 | policy loaded |
| table_redirect |  |  |  |  | map_update | true | 0 | redirect map populated |
| table_redirect |  |  |  |  | attach | true | 0 | policy attached |
| table_redirect | w4-ccache-redis-nginx | verified_hit | object.o | object.local | lookup | true | 0 | redirected lookup matched backing |
| table_redirect | w4-ccache-redis-nginx | verified_hit | object.o | object.local | readdir | true | 0 | alias visible and policy backing hidden |
| table_redirect | w4-ccache-redis-nginx | stale_fallback | stale.o | stale.canon | lookup | true | 0 | redirected lookup matched backing |
| table_redirect | w4-ccache-redis-nginx | stale_fallback | stale.o | stale.canon | readdir | true | 0 | alias visible and policy backing hidden |
| table_redirect | w4-ccache-redis-nginx | corrupt_reject | corrupt.o | corrupt.reject | lookup | true | 0 | redirected lookup matched backing |
| table_redirect | w4-ccache-redis-nginx | corrupt_reject | corrupt.o | corrupt.reject | readdir | true | 0 | alias visible and policy backing hidden |
| table_redirect | w4-buildkit-prometheus-go-cache | miss_canonical | pkg.mod | pkg.canon | lookup | true | 0 | redirected lookup matched backing |
| table_redirect | w4-buildkit-prometheus-go-cache | miss_canonical | pkg.mod | pkg.canon | readdir | true | 0 | alias visible and policy backing hidden |
| table_redirect |  |  |  |  | detach | true | 0 | policy detached |
| table_redirect | w4-ccache-redis-nginx | verified_hit | object.o | object.local | post_detach_absent | true | 0 | alias absent after detach |
| table_redirect | w4-ccache-redis-nginx | stale_fallback | stale.o | stale.canon | post_detach_absent | true | 0 | alias absent after detach |
| table_redirect | w4-ccache-redis-nginx | corrupt_reject | corrupt.o | corrupt.reject | post_detach_absent | true | 0 | alias absent after detach |
| table_redirect | w4-buildkit-prometheus-go-cache | miss_canonical | pkg.mod | pkg.canon | post_detach_absent | true | 0 | alias absent after detach |

## W4 Cache Content Oracle Cases
| Branch | Op | Pass | Errno | Expected | Path | Detail |
|---|---|---:|---:|---|---|---|
| setup | read_entries | true | 0 | /home/yunwei37/workspace/namei_ext/results/workloads/runs/20260615T-full-phase1-c2-release-sample-v1/w4-cache-oracle-entries.tsv |  | W4 cache oracle TSV loaded |
| setup | materialize | true | 0 | /home/yunwei37/workspace/namei_ext/results/workloads/runs/20260615T-full-phase1-c2-release-sample-v1/w4-cache-oracle-entries.tsv | /home/yunwei37/workspace/namei_ext/results/phase1/20260615T-full-phase1-c2-release-sample-v1/w4-cache-content-work | manifest-derived cache content workdir materialized |
| verified_hit | pre_attach_absent | true | 0 | ENOENT | /home/yunwei37/workspace/namei_ext/results/phase1/20260615T-full-phase1-c2-release-sample-v1/w4-cache-content-work/cache/object.o | visible cache alias absent |
| stale_fallback | pre_attach_absent | true | 0 | ENOENT | /home/yunwei37/workspace/namei_ext/results/phase1/20260615T-full-phase1-c2-release-sample-v1/w4-cache-content-work/cache/stale.o | visible cache alias absent |
| corrupt_reject | pre_attach_absent | true | 0 | ENOENT | /home/yunwei37/workspace/namei_ext/results/phase1/20260615T-full-phase1-c2-release-sample-v1/w4-cache-content-work/cache/corrupt.o | visible cache alias absent |
| miss_canonical | pre_attach_absent | true | 0 | ENOENT | /home/yunwei37/workspace/namei_ext/results/phase1/20260615T-full-phase1-c2-release-sample-v1/w4-cache-content-work/gomod/pkg.mod | visible cache alias absent |
| setup | current_cgroup_id | true | 0 | /sys/fs/cgroup |  | current cgroup id resolved |
| setup | load | true | 0 | /home/yunwei37/workspace/namei_ext/.build/bpf/cache_locality_view.bpf.o |  | cache-locality policy loaded |
| setup | map_update | true | 0 | /home/yunwei37/workspace/namei_ext/results/workloads/runs/20260615T-full-phase1-c2-release-sample-v1/w4-cache-oracle-entries.tsv |  | cache_rules populated from W4 TSV |
| setup | attach | true | 0 | /sys/fs/cgroup |  | cache-locality policy attached |
| verified_hit | attached_expected_match | true | 0 | object.local | /home/yunwei37/workspace/namei_ext/results/phase1/20260615T-full-phase1-c2-release-sample-v1/w4-cache-content-work/cache/object.o | visible alias matched expected backing |
| verified_hit | attached_forbidden_mismatch | true | 0 | object.bad | /home/yunwei37/workspace/namei_ext/results/phase1/20260615T-full-phase1-c2-release-sample-v1/w4-cache-content-work/cache/object.o | visible alias did not match forbidden cache content |
| stale_fallback | attached_expected_match | true | 0 | stale.canon | /home/yunwei37/workspace/namei_ext/results/phase1/20260615T-full-phase1-c2-release-sample-v1/w4-cache-content-work/cache/stale.o | visible alias matched expected backing |
| stale_fallback | attached_forbidden_mismatch | true | 0 | stale.local | /home/yunwei37/workspace/namei_ext/results/phase1/20260615T-full-phase1-c2-release-sample-v1/w4-cache-content-work/cache/stale.o | visible alias did not match forbidden cache content |
| corrupt_reject | attached_expected_match | true | 0 | corrupt.reject | /home/yunwei37/workspace/namei_ext/results/phase1/20260615T-full-phase1-c2-release-sample-v1/w4-cache-content-work/cache/corrupt.o | visible alias matched expected backing |
| corrupt_reject | attached_forbidden_mismatch | true | 0 | corrupt.local | /home/yunwei37/workspace/namei_ext/results/phase1/20260615T-full-phase1-c2-release-sample-v1/w4-cache-content-work/cache/corrupt.o | visible alias did not match forbidden cache content |
| miss_canonical | attached_expected_match | true | 0 | pkg.canon | /home/yunwei37/workspace/namei_ext/results/phase1/20260615T-full-phase1-c2-release-sample-v1/w4-cache-content-work/gomod/pkg.mod | visible alias matched expected backing |
| verified_hit | readdir_alias | true | 0 | object.o | /home/yunwei37/workspace/namei_ext/results/phase1/20260615T-full-phase1-c2-release-sample-v1/w4-cache-content-work/cache | cache alias visible and backing hidden |
| stale_fallback | readdir_alias | true | 0 | stale.o | /home/yunwei37/workspace/namei_ext/results/phase1/20260615T-full-phase1-c2-release-sample-v1/w4-cache-content-work/cache | cache alias visible and backing hidden |
| corrupt_reject | readdir_alias | true | 0 | corrupt.o | /home/yunwei37/workspace/namei_ext/results/phase1/20260615T-full-phase1-c2-release-sample-v1/w4-cache-content-work/cache | cache alias visible and backing hidden |
| miss_canonical | readdir_alias | true | 0 | pkg.mod | /home/yunwei37/workspace/namei_ext/results/phase1/20260615T-full-phase1-c2-release-sample-v1/w4-cache-content-work/gomod | cache alias visible and backing hidden |
| setup | detach | true | 0 | /sys/fs/cgroup |  | cache-locality policy detached |
| verified_hit | post_detach_absent | true | 0 | ENOENT | /home/yunwei37/workspace/namei_ext/results/phase1/20260615T-full-phase1-c2-release-sample-v1/w4-cache-content-work/cache/object.o | visible cache alias absent |
| stale_fallback | post_detach_absent | true | 0 | ENOENT | /home/yunwei37/workspace/namei_ext/results/phase1/20260615T-full-phase1-c2-release-sample-v1/w4-cache-content-work/cache/stale.o | visible cache alias absent |
| corrupt_reject | post_detach_absent | true | 0 | ENOENT | /home/yunwei37/workspace/namei_ext/results/phase1/20260615T-full-phase1-c2-release-sample-v1/w4-cache-content-work/cache/corrupt.o | visible cache alias absent |
| miss_canonical | post_detach_absent | true | 0 | ENOENT | /home/yunwei37/workspace/namei_ext/results/phase1/20260615T-full-phase1-c2-release-sample-v1/w4-cache-content-work/gomod/pkg.mod | visible cache alias absent |

## W4 Cache Table-Only Content Counterfactual
Same W4 cache content oracle through table_redirect; this is negative C8 evidence while it passes.
| Branch | Op | Pass | Table Oracle Pass | Errno | Expected | Path | Detail |
|---|---|---:|---:|---:|---|---|---|
| setup | read_entries | true | true | 0 | /home/yunwei37/workspace/namei_ext/results/workloads/runs/20260615T-full-phase1-c2-release-sample-v1/w4-cache-oracle-entries.tsv |  | W4 cache oracle TSV loaded |
| setup | materialize | true | true | 0 | /home/yunwei37/workspace/namei_ext/results/workloads/runs/20260615T-full-phase1-c2-release-sample-v1/w4-cache-oracle-entries.tsv | /home/yunwei37/workspace/namei_ext/results/phase1/20260615T-full-phase1-c2-release-sample-v1/w4-cache-table-content-work | manifest-derived cache content workdir materialized |
| verified_hit | pre_attach_absent | true | true | 0 | ENOENT | /home/yunwei37/workspace/namei_ext/results/phase1/20260615T-full-phase1-c2-release-sample-v1/w4-cache-table-content-work/cache/object.o | visible cache alias absent |
| stale_fallback | pre_attach_absent | true | true | 0 | ENOENT | /home/yunwei37/workspace/namei_ext/results/phase1/20260615T-full-phase1-c2-release-sample-v1/w4-cache-table-content-work/cache/stale.o | visible cache alias absent |
| corrupt_reject | pre_attach_absent | true | true | 0 | ENOENT | /home/yunwei37/workspace/namei_ext/results/phase1/20260615T-full-phase1-c2-release-sample-v1/w4-cache-table-content-work/cache/corrupt.o | visible cache alias absent |
| miss_canonical | pre_attach_absent | true | true | 0 | ENOENT | /home/yunwei37/workspace/namei_ext/results/phase1/20260615T-full-phase1-c2-release-sample-v1/w4-cache-table-content-work/gomod/pkg.mod | visible cache alias absent |
| setup | current_cgroup_id | true | true | 0 | /sys/fs/cgroup |  | current cgroup id resolved |
| setup | load | true | true | 0 | /home/yunwei37/workspace/namei_ext/.build/bpf/table_redirect.bpf.o |  | cache-locality policy loaded |
| setup | map_update | true | true | 0 | /home/yunwei37/workspace/namei_ext/results/workloads/runs/20260615T-full-phase1-c2-release-sample-v1/w4-cache-oracle-entries.tsv |  | cache_rules populated from W4 TSV |
| setup | attach | true | true | 0 | /sys/fs/cgroup |  | cache-locality policy attached |
| verified_hit | attached_expected_match | true | true | 0 | object.local | /home/yunwei37/workspace/namei_ext/results/phase1/20260615T-full-phase1-c2-release-sample-v1/w4-cache-table-content-work/cache/object.o | visible alias matched expected backing |
| verified_hit | attached_forbidden_mismatch | true | true | 0 | object.bad | /home/yunwei37/workspace/namei_ext/results/phase1/20260615T-full-phase1-c2-release-sample-v1/w4-cache-table-content-work/cache/object.o | visible alias did not match forbidden cache content |
| stale_fallback | attached_expected_match | true | true | 0 | stale.canon | /home/yunwei37/workspace/namei_ext/results/phase1/20260615T-full-phase1-c2-release-sample-v1/w4-cache-table-content-work/cache/stale.o | visible alias matched expected backing |
| stale_fallback | attached_forbidden_mismatch | true | true | 0 | stale.local | /home/yunwei37/workspace/namei_ext/results/phase1/20260615T-full-phase1-c2-release-sample-v1/w4-cache-table-content-work/cache/stale.o | visible alias did not match forbidden cache content |
| corrupt_reject | attached_expected_match | true | true | 0 | corrupt.reject | /home/yunwei37/workspace/namei_ext/results/phase1/20260615T-full-phase1-c2-release-sample-v1/w4-cache-table-content-work/cache/corrupt.o | visible alias matched expected backing |
| corrupt_reject | attached_forbidden_mismatch | true | true | 0 | corrupt.local | /home/yunwei37/workspace/namei_ext/results/phase1/20260615T-full-phase1-c2-release-sample-v1/w4-cache-table-content-work/cache/corrupt.o | visible alias did not match forbidden cache content |
| miss_canonical | attached_expected_match | true | true | 0 | pkg.canon | /home/yunwei37/workspace/namei_ext/results/phase1/20260615T-full-phase1-c2-release-sample-v1/w4-cache-table-content-work/gomod/pkg.mod | visible alias matched expected backing |
| verified_hit | readdir_alias | true | true | 0 | object.o | /home/yunwei37/workspace/namei_ext/results/phase1/20260615T-full-phase1-c2-release-sample-v1/w4-cache-table-content-work/cache | cache alias visible and backing hidden |
| stale_fallback | readdir_alias | true | true | 0 | stale.o | /home/yunwei37/workspace/namei_ext/results/phase1/20260615T-full-phase1-c2-release-sample-v1/w4-cache-table-content-work/cache | cache alias visible and backing hidden |
| corrupt_reject | readdir_alias | true | true | 0 | corrupt.o | /home/yunwei37/workspace/namei_ext/results/phase1/20260615T-full-phase1-c2-release-sample-v1/w4-cache-table-content-work/cache | cache alias visible and backing hidden |
| miss_canonical | readdir_alias | true | true | 0 | pkg.mod | /home/yunwei37/workspace/namei_ext/results/phase1/20260615T-full-phase1-c2-release-sample-v1/w4-cache-table-content-work/gomod | cache alias visible and backing hidden |
| setup | detach | true | true | 0 | /sys/fs/cgroup |  | cache-locality policy detached |
| verified_hit | post_detach_absent | true | true | 0 | ENOENT | /home/yunwei37/workspace/namei_ext/results/phase1/20260615T-full-phase1-c2-release-sample-v1/w4-cache-table-content-work/cache/object.o | visible cache alias absent |
| stale_fallback | post_detach_absent | true | true | 0 | ENOENT | /home/yunwei37/workspace/namei_ext/results/phase1/20260615T-full-phase1-c2-release-sample-v1/w4-cache-table-content-work/cache/stale.o | visible cache alias absent |
| corrupt_reject | post_detach_absent | true | true | 0 | ENOENT | /home/yunwei37/workspace/namei_ext/results/phase1/20260615T-full-phase1-c2-release-sample-v1/w4-cache-table-content-work/cache/corrupt.o | visible cache alias absent |
| miss_canonical | post_detach_absent | true | true | 0 | ENOENT | /home/yunwei37/workspace/namei_ext/results/phase1/20260615T-full-phase1-c2-release-sample-v1/w4-cache-table-content-work/gomod/pkg.mod | visible cache alias absent |

## W4 Real Ccache Transition Witness
KVM real ccache cold/hot compile witness over Redis/nginx source, followed by cache_locality policy content oracle over the ccache-derived object outputs; not C8-qualified.
| Workload | Cache Misses | Direct Hits | Object Hash Match | Policy Failures | Qualified For C8 | Detail |
|---|---:|---:|---:|---:|---:|---|
| w4-ccache-redis-nginx | 2 | 2 | true | 0 | false | real ccache cold/hot compiles over Redis and nginx source produced matching object hashes and cache hits |
| w4-ccache-redis-nginx | n/a | n/a | true | 0 | false | real ccache transition witness and cache_locality policy content oracle passed; release-level C8 remains blocked by operation-weighted policy cache hit rate and table/update counterfactual |

## W4 Real Ccache Cache-Path Trace Witness
KVM strace witness showing real ccache hot compiles touch CCACHE_DIR paths; not namei_ext policy execution and not C8-qualified.
| Workload | Trace File Ops | Cache-Path File Ops | Direct Hits | Policy Executed | Qualified For C8 | Detail |
|---|---:|---:|---:|---:|---:|---|
| w4-ccache-redis-nginx | 736 | 40 | 2 | false | false | real ccache hot compiles touched CCACHE_DIR paths under KVM; this is workload cache-path evidence, not namei_ext policy execution |

## W4 Trace-Derived Ccache Policy Bridge
KVM policy oracle over ccache cache object components extracted from real strace logs; real ccache compile still did not execute namei_ext policy and this is not C8-qualified.
| Workload | Trace Objects | Redis Objects | Nginx Objects | Policy Failures | Compile Policy Executed | Trace-Derived Policy Executed | Qualified For C8 | Detail |
|---|---:|---:|---:|---:|---:|---:|---:|---|
| w4-ccache-redis-nginx | 4 | 2 | 2 | 0 | false | true | false | trace-derived ccache cache object components executed cache_locality policy content oracle; real ccache compile still did not execute namei_ext policy |

## W4 Real Ccache Policy-Attached Compile Witness
KVM witness in which real ccache hot compiles run while cache_locality policy is attached; visible cache objects are absent, hidden backing objects are consumed through namei_ext, and this is still not C8-qualified because it is not an operation-weighted release workload.
| Workload | Redirected Objects | Redis Objects | Nginx Objects | Direct Hits | Cache Misses | Output Hash Match | Compile Policy Executed | Qualified For C8 | Detail |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
| w4-ccache-redis-nginx | 4 | 2 | 2 | 2 | 0 | true | true | false | real ccache hot compile consumed cache objects through attached cache_locality policy |

## W4 Parent-Scoped Ccache Compile Witness
KVM witness in which real ccache hot compiles run under a parent-scoped cache_locality lookup rule with ccache object-shape guard, metadata.txt PASS, valid-shape non-witness backing-absent, and valid-shape non-witness PASS hard gates; still not C8-qualified.
| Workload | Redirected Objects | Parent Rules | Readdir Rules | Direct Hits | Metadata PASS | Backing Absent | Valid-Shape PASS | Output Hash Match | Compile Policy Executed | Qualified For C8 | Detail |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| w4-ccache-redis-nginx | 4 | 4 | 4 | 2 | true | true | true | true | true | false | real ccache hot compile consumed cache objects through parent-scoped cache_locality policy |

## W4 Table-Only Ccache Compile Comparator
KVM comparator in which the same sampled ccache hot compiles run under table_redirect exact redirects; a pass here is negative evidence for C8 on this sampled witness, so it remains not C8-qualified.
| Workload | Redirected Objects | Redis Objects | Nginx Objects | Direct Hits | Output Hash Match | Table Pass | Qualified For C8 | Detail |
|---|---:|---:|---:|---:|---:|---:|---:|---|
| w4-ccache-redis-nginx | 4 | 2 | 2 | 2 | true | true | false | table-only baseline consumed sampled ccache cache objects through exact redirects |

## W4 Release Counterfactual Accounting
KVM accounting row over the real ccache trace, parent-scoped policy compile, and table-only comparator. It preserves the current negative evidence: table-only still passes and release-level operation-weighted policy hit rate is not established.
| Workload | Cache Path Ops | Trace Objects | Parent Rules | Table Rules | Object Hit Rate | Sampled Object/Ops Ratio | Attached Ops | Attached Object Ops | Attached Sampled Hit Rate | Table Pass | Qualified For C8 | Detail |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| w4-ccache-redis-nginx | 40 | 4 | 4 | 8 | 1 | 0.1 | 40 | 16 | 0.40000000000000002 | true | false | sampled ccache parent-rule accounting passed with attach-window optrace, but table-only also passed and release-level operation-weighted policy hit rate is not established |

## Table-Only Budget Accounting
| Family | Entries | Table Passes Current Oracle | Over-materialization | Accounted Update Writes | Qualified For C8 | Detail |
|---|---:|---:|---:|---:|---:|---|
| build_graph | 9 | true | 1 | 9 | false | table baseline path-oracle accounting recorded; release-level table/update counterfactual not satisfied |
| sandbox_fixture | 6 | true | 1 | 6 | false | table baseline path-oracle accounting recorded; release-level table/update counterfactual not satisfied |
| checkpoint_restore | 7 | true | 1 | 7 | false | table baseline path-oracle accounting recorded; release-level table/update counterfactual not satisfied |
| cache_locality | 4 | true | 1 | 4 | false | table baseline path-oracle accounting recorded; release-level table/update counterfactual not satisfied |

## Functional Cases
| Case | Pass | Errno | Detail |
|---|---:|---:|---|
| load_good_attach_type | true | 0 | expected attach type accepted |
| load_bad_attach_type | true | 22 | wrong attach type rejected |
| multi_attach_rejected | true | 22 | attach flag rejected |
| override_attach_rejected | true | 22 | attach flag rejected |
| replace_attach_rejected | true | 22 | attach flag rejected |
| link_create_rejected | true | 95 | cgroup link attach rejected |
| setup_files | true | 0 | native and backing files created |
| alias_before_attach | true | 2 | stat errno matched |
| backing_before_attach | true | 0 | stat matched |
| attach_policy | true | 0 | policy attached |
| native_stat | true | 0 | stat matched |
| native_open | true | 0 | open matched |
| native_access | true | 0 | access matched |
| alias_stat | true | 0 | stat matched |
| alias_open | true | 0 | open matched |
| alias_access | true | 0 | access matched |
| alias_read | true | 0 | read content matched |
| alias_exec | true | 8 | execve errno matched |
| backing_stat | true | 0 | stat matched |
| readdir_view | true | 0 | native and alias listed, backing name rewritten |
| detach_policy | true | 0 | policy detached |
| alias_after_detach | true | 2 | stat errno matched |
| backing_after_detach | true | 0 | stat matched |
| functional_summary | true | 0 | functional passed |

## Microbenchmarks
| Benchmark | Variant | Sample | Ops | Elapsed ns | ns/op | Fail |
|---|---|---:|---:|---:|---:|---:|
| lookup_native_hot | table_redirect_hit | 0 | 2000 | 965799 | 482.8995 | 0 |
| access_tool_redirect | table_redirect_hit | 0 | 2000 | 908652 | 454.326 | 0 |
| build_tree_stat_walk | table_redirect_hit | 0 | 1984 | 1542770 | 777.6058467741935 | 0 |
| open_tool_redirect | table_redirect_hit | 0 | 2000 | 1511363 | 755.6815 | 0 |
| readdir_alias_view | table_redirect_hit | 0 | 500 | 172034 | 344.068 | 0 |
| lookup_tool_redirect | table_redirect_hit | 0 | 2000 | 1007817 | 503.9085 | 0 |
| exec_tool_redirect | table_redirect_hit | 0 | 20 | 1385244 | 69262.2 | 0 |
| build_tree_stat_walk | table_redirect_hit | 1 | 1984 | 1529669 | 771.0025201612904 | 0 |
| access_tool_redirect | table_redirect_hit | 1 | 2000 | 895197 | 447.5985 | 0 |
| lookup_native_hot | table_redirect_hit | 1 | 2000 | 960123 | 480.0615 | 0 |
| open_tool_redirect | table_redirect_hit | 1 | 2000 | 1502025 | 751.0125 | 0 |
| lookup_tool_redirect | table_redirect_hit | 1 | 2000 | 993734 | 496.867 | 0 |
| readdir_alias_view | table_redirect_hit | 1 | 500 | 168968 | 337.936 | 0 |
| exec_tool_redirect | table_redirect_hit | 1 | 20 | 1556689 | 77834.45 | 0 |
| lookup_tool_redirect | table_redirect_hit | 2 | 2000 | 1014748 | 507.374 | 0 |
| build_tree_stat_walk | table_redirect_hit | 2 | 1984 | 1531377 | 771.8634072580645 | 0 |
| open_tool_redirect | table_redirect_hit | 2 | 2000 | 1517906 | 758.953 | 0 |
| readdir_alias_view | table_redirect_hit | 2 | 500 | 169127 | 338.254 | 0 |
| exec_tool_redirect | table_redirect_hit | 2 | 20 | 1298346 | 64917.3 | 0 |
| access_tool_redirect | table_redirect_hit | 2 | 2000 | 1264346 | 632.173 | 0 |
| lookup_native_hot | table_redirect_hit | 2 | 2000 | 1436963 | 718.4815 | 0 |
| lookup_tool_redirect | table_redirect_hit | 3 | 2000 | 1577984 | 788.992 | 0 |
| build_tree_stat_walk | table_redirect_hit | 3 | 1984 | 2300185 | 1159.367439516129 | 0 |
| access_tool_redirect | table_redirect_hit | 3 | 2000 | 1296040 | 648.02 | 0 |
| exec_tool_redirect | table_redirect_hit | 3 | 20 | 1481358 | 74067.9 | 0 |
| readdir_alias_view | table_redirect_hit | 3 | 500 | 269174 | 538.348 | 0 |
| lookup_native_hot | table_redirect_hit | 3 | 2000 | 1439879 | 719.9395 | 0 |
| open_tool_redirect | table_redirect_hit | 3 | 2000 | 2284981 | 1142.4905 | 0 |
| lookup_native_hot | table_redirect_hit | 4 | 2000 | 1426558 | 713.279 | 0 |
| exec_tool_redirect | table_redirect_hit | 4 | 20 | 1857764 | 92888.2 | 0 |
| build_tree_stat_walk | table_redirect_hit | 4 | 1984 | 2260361 | 1139.2948588709678 | 0 |
| lookup_tool_redirect | table_redirect_hit | 4 | 2000 | 1492946 | 746.473 | 0 |
| access_tool_redirect | table_redirect_hit | 4 | 2000 | 1285062 | 642.531 | 0 |
| readdir_alias_view | table_redirect_hit | 4 | 500 | 258315 | 516.63 | 0 |
| open_tool_redirect | table_redirect_hit | 4 | 2000 | 2281375 | 1140.6875 | 0 |
| readdir_alias_view | table_redirect_hit | 5 | 500 | 259220 | 518.44 | 0 |
| lookup_tool_redirect | table_redirect_hit | 5 | 2000 | 1454507 | 727.2535 | 0 |
| access_tool_redirect | table_redirect_hit | 5 | 2000 | 1276027 | 638.0135 | 0 |
| open_tool_redirect | table_redirect_hit | 5 | 2000 | 2304210 | 1152.105 | 0 |
| lookup_native_hot | table_redirect_hit | 5 | 2000 | 1425436 | 712.718 | 0 |
| build_tree_stat_walk | table_redirect_hit | 5 | 1984 | 2233840 | 1125.9274193548388 | 0 |
| exec_tool_redirect | table_redirect_hit | 5 | 20 | 1794807 | 89740.35 | 0 |
| access_tool_redirect | table_redirect_hit | 6 | 2000 | 1287619 | 643.8095 | 0 |
| build_tree_stat_walk | table_redirect_hit | 6 | 1984 | 2230816 | 1124.4032258064517 | 0 |
| exec_tool_redirect | table_redirect_hit | 6 | 20 | 1689694 | 84484.7 | 0 |
| lookup_native_hot | table_redirect_hit | 6 | 2000 | 1464907 | 732.4535 | 0 |
| readdir_alias_view | table_redirect_hit | 6 | 500 | 266905 | 533.81 | 0 |
| lookup_tool_redirect | table_redirect_hit | 6 | 2000 | 1462182 | 731.091 | 0 |
| open_tool_redirect | table_redirect_hit | 6 | 2000 | 2342202 | 1171.101 | 0 |
| readdir_alias_view | table_redirect_hit | 7 | 500 | 258258 | 516.516 | 0 |
| lookup_tool_redirect | table_redirect_hit | 7 | 2000 | 1437979 | 718.9895 | 0 |
| access_tool_redirect | table_redirect_hit | 7 | 2000 | 1270334 | 635.167 | 0 |
| exec_tool_redirect | table_redirect_hit | 7 | 20 | 1427536 | 71376.8 | 0 |
| open_tool_redirect | table_redirect_hit | 7 | 2000 | 2330047 | 1165.0235 | 0 |
| build_tree_stat_walk | table_redirect_hit | 7 | 1984 | 2343373 | 1181.1355846774193 | 0 |
| lookup_native_hot | table_redirect_hit | 7 | 2000 | 1485033 | 742.5165 | 0 |
| lookup_native_hot | table_redirect_hit | 8 | 2000 | 1439727 | 719.8635 | 0 |
| access_tool_redirect | table_redirect_hit | 8 | 2000 | 1325631 | 662.8155 | 0 |
| open_tool_redirect | table_redirect_hit | 8 | 2000 | 2354157 | 1177.0785 | 0 |
| exec_tool_redirect | table_redirect_hit | 8 | 20 | 1803390 | 90169.5 | 0 |
| readdir_alias_view | table_redirect_hit | 8 | 500 | 264954 | 529.908 | 0 |
| build_tree_stat_walk | table_redirect_hit | 8 | 1984 | 3046498 | 1535.5332661290322 | 0 |
| lookup_tool_redirect | table_redirect_hit | 8 | 2000 | 2456489 | 1228.2445 | 0 |
| lookup_native_hot | table_redirect_hit | 9 | 2000 | 1463696 | 731.848 | 0 |
| lookup_tool_redirect | table_redirect_hit | 9 | 2000 | 1454936 | 727.468 | 0 |
| readdir_alias_view | table_redirect_hit | 9 | 500 | 267674 | 535.348 | 0 |
| access_tool_redirect | table_redirect_hit | 9 | 2000 | 1279364 | 639.682 | 0 |
| exec_tool_redirect | table_redirect_hit | 9 | 20 | 1364620 | 68231 | 0 |
| open_tool_redirect | table_redirect_hit | 9 | 2000 | 2292435 | 1146.2175 | 0 |
| build_tree_stat_walk | table_redirect_hit | 9 | 1984 | 3323867 | 1675.336189516129 | 0 |
| exec_tool_redirect | table_redirect_hit | 10 | 20 | 1406568 | 70328.4 | 0 |
| build_tree_stat_walk | table_redirect_hit | 10 | 1984 | 1546675 | 779.5740927419355 | 0 |
| lookup_native_hot | table_redirect_hit | 10 | 2000 | 954018 | 477.009 | 0 |
| open_tool_redirect | table_redirect_hit | 10 | 2000 | 1520596 | 760.298 | 0 |
| readdir_alias_view | table_redirect_hit | 10 | 500 | 174303 | 348.606 | 0 |
| access_tool_redirect | table_redirect_hit | 10 | 2000 | 894775 | 447.3875 | 0 |
| lookup_tool_redirect | table_redirect_hit | 10 | 2000 | 990817 | 495.4085 | 0 |
| access_tool_redirect | table_redirect_hit | 11 | 2000 | 900105 | 450.0525 | 0 |
| exec_tool_redirect | table_redirect_hit | 11 | 20 | 1232134 | 61606.7 | 0 |
| lookup_tool_redirect | table_redirect_hit | 11 | 2000 | 994834 | 497.417 | 0 |
| build_tree_stat_walk | table_redirect_hit | 11 | 1984 | 1540720 | 776.5725806451613 | 0 |
| readdir_alias_view | table_redirect_hit | 11 | 500 | 184466 | 368.932 | 0 |
| lookup_native_hot | table_redirect_hit | 11 | 2000 | 980396 | 490.198 | 0 |
| open_tool_redirect | table_redirect_hit | 11 | 2000 | 1503294 | 751.647 | 0 |
| open_tool_redirect | table_redirect_hit | 12 | 2000 | 1539499 | 769.7495 | 0 |
| lookup_tool_redirect | table_redirect_hit | 12 | 2000 | 994029 | 497.0145 | 0 |
| build_tree_stat_walk | table_redirect_hit | 12 | 1984 | 1529428 | 770.8810483870968 | 0 |
| lookup_native_hot | table_redirect_hit | 12 | 2000 | 955170 | 477.585 | 0 |
| access_tool_redirect | table_redirect_hit | 12 | 2000 | 895426 | 447.713 | 0 |
| exec_tool_redirect | table_redirect_hit | 12 | 20 | 1276150 | 63807.5 | 0 |
| readdir_alias_view | table_redirect_hit | 12 | 500 | 170525 | 341.05 | 0 |
| lookup_tool_redirect | table_redirect_hit | 13 | 2000 | 1005934 | 502.967 | 0 |
| build_tree_stat_walk | table_redirect_hit | 13 | 1984 | 1528532 | 770.429435483871 | 0 |
| lookup_native_hot | table_redirect_hit | 13 | 2000 | 954398 | 477.199 | 0 |
| access_tool_redirect | table_redirect_hit | 13 | 2000 | 905729 | 452.8645 | 0 |
| exec_tool_redirect | table_redirect_hit | 13 | 20 | 1508967 | 75448.35 | 0 |
| readdir_alias_view | table_redirect_hit | 13 | 500 | 179063 | 358.126 | 0 |
| open_tool_redirect | table_redirect_hit | 13 | 2000 | 1522551 | 761.2755 | 0 |
| readdir_alias_view | table_redirect_hit | 14 | 500 | 176788 | 353.576 | 0 |
| open_tool_redirect | table_redirect_hit | 14 | 2000 | 1540531 | 770.2655 | 0 |
| exec_tool_redirect | table_redirect_hit | 14 | 20 | 1414586 | 70729.3 | 0 |
| access_tool_redirect | table_redirect_hit | 14 | 2000 | 918723 | 459.3615 | 0 |
| lookup_native_hot | table_redirect_hit | 14 | 2000 | 953223 | 476.6115 | 0 |
| build_tree_stat_walk | table_redirect_hit | 14 | 1984 | 1537481 | 774.9400201612904 | 0 |
| lookup_tool_redirect | table_redirect_hit | 14 | 2000 | 1022216 | 511.108 | 0 |
| lookup_tool_redirect | table_redirect_hit | 15 | 2000 | 998982 | 499.491 | 0 |
| access_tool_redirect | table_redirect_hit | 15 | 2000 | 892839 | 446.4195 | 0 |
| lookup_native_hot | table_redirect_hit | 15 | 2000 | 953281 | 476.6405 | 0 |
| readdir_alias_view | table_redirect_hit | 15 | 500 | 181380 | 362.76 | 0 |
| open_tool_redirect | table_redirect_hit | 15 | 2000 | 1525049 | 762.5245 | 0 |
| build_tree_stat_walk | table_redirect_hit | 15 | 1984 | 1522987 | 767.6345766129032 | 0 |
| exec_tool_redirect | table_redirect_hit | 15 | 20 | 1378855 | 68942.75 | 0 |
| readdir_alias_view | table_redirect_hit | 16 | 500 | 169907 | 339.814 | 0 |
| open_tool_redirect | table_redirect_hit | 16 | 2000 | 1534161 | 767.0805 | 0 |
| lookup_tool_redirect | table_redirect_hit | 16 | 2000 | 993913 | 496.9565 | 0 |
| lookup_native_hot | table_redirect_hit | 16 | 2000 | 953740 | 476.87 | 0 |
| build_tree_stat_walk | table_redirect_hit | 16 | 1984 | 1528125 | 770.2242943548387 | 0 |
| access_tool_redirect | table_redirect_hit | 16 | 2000 | 920301 | 460.1505 | 0 |
| exec_tool_redirect | table_redirect_hit | 16 | 20 | 1247181 | 62359.05 | 0 |
| lookup_native_hot | table_redirect_hit | 17 | 2000 | 956996 | 478.498 | 0 |
| access_tool_redirect | table_redirect_hit | 17 | 2000 | 915085 | 457.5425 | 0 |
| readdir_alias_view | table_redirect_hit | 17 | 500 | 182544 | 365.088 | 0 |
| lookup_tool_redirect | table_redirect_hit | 17 | 2000 | 1005824 | 502.912 | 0 |
| open_tool_redirect | table_redirect_hit | 17 | 2000 | 1501284 | 750.642 | 0 |
| build_tree_stat_walk | table_redirect_hit | 17 | 1984 | 1528942 | 770.6360887096774 | 0 |
| exec_tool_redirect | table_redirect_hit | 17 | 20 | 1924397 | 96219.85 | 0 |
| exec_tool_redirect | table_redirect_hit | 18 | 20 | 1415487 | 70774.35 | 0 |
| access_tool_redirect | table_redirect_hit | 18 | 2000 | 897663 | 448.8315 | 0 |
| readdir_alias_view | table_redirect_hit | 18 | 500 | 171276 | 342.552 | 0 |
| lookup_native_hot | table_redirect_hit | 18 | 2000 | 960989 | 480.4945 | 0 |
| build_tree_stat_walk | table_redirect_hit | 18 | 1984 | 1535580 | 773.9818548387096 | 0 |
| open_tool_redirect | table_redirect_hit | 18 | 2000 | 1542582 | 771.291 | 0 |
| lookup_tool_redirect | table_redirect_hit | 18 | 2000 | 1023153 | 511.5765 | 0 |
| lookup_native_hot | table_redirect_hit | 19 | 2000 | 956569 | 478.2845 | 0 |
| access_tool_redirect | table_redirect_hit | 19 | 2000 | 896134 | 448.067 | 0 |
| exec_tool_redirect | table_redirect_hit | 19 | 20 | 1264982 | 63249.1 | 0 |
| lookup_tool_redirect | table_redirect_hit | 19 | 2000 | 1033328 | 516.664 | 0 |
| build_tree_stat_walk | table_redirect_hit | 19 | 1984 | 1542941 | 777.6920362903226 | 0 |
| readdir_alias_view | table_redirect_hit | 19 | 500 | 173281 | 346.562 | 0 |
| open_tool_redirect | table_redirect_hit | 19 | 2000 | 1530337 | 765.1685 | 0 |
| readdir_alias_view | policy | 0 | 500 | 139840 | 279.68 | 0 |
| lookup_native_hot | policy | 0 | 2000 | 790031 | 395.0155 | 0 |
| exec_tool_redirect | policy | 0 | 20 | 1358098 | 67904.9 | 0 |
| access_tool_redirect | policy | 0 | 2000 | 1102309 | 551.1545 | 0 |
| build_tree_stat_walk | policy | 0 | 1984 | 1796369 | 905.4279233870968 | 0 |
| open_tool_redirect | policy | 0 | 2000 | 1988985 | 994.4925 | 0 |
| lookup_tool_redirect | policy | 0 | 2000 | 1253881 | 626.9405 | 0 |
| access_tool_redirect | policy | 1 | 2000 | 1065804 | 532.902 | 0 |
| readdir_alias_view | policy | 1 | 500 | 226601 | 453.202 | 0 |
| open_tool_redirect | policy | 1 | 2000 | 1997024 | 998.512 | 0 |
| exec_tool_redirect | policy | 1 | 20 | 1389946 | 69497.3 | 0 |
| lookup_tool_redirect | policy | 1 | 2000 | 1235944 | 617.972 | 0 |
| lookup_native_hot | policy | 1 | 2000 | 1242885 | 621.4425 | 0 |
| build_tree_stat_walk | policy | 1 | 1984 | 1782961 | 898.6698588709677 | 0 |
| exec_tool_redirect | policy | 2 | 20 | 1334175 | 66708.75 | 0 |
| lookup_tool_redirect | policy | 2 | 2000 | 1251245 | 625.6225 | 0 |
| open_tool_redirect | policy | 2 | 2000 | 2022277 | 1011.1385 | 0 |
| build_tree_stat_walk | policy | 2 | 1984 | 1759741 | 886.9662298387096 | 0 |
| lookup_native_hot | policy | 2 | 2000 | 1236828 | 618.414 | 0 |
| readdir_alias_view | policy | 2 | 500 | 215196 | 430.392 | 0 |
| access_tool_redirect | policy | 2 | 2000 | 1085987 | 542.9935 | 0 |
| access_tool_redirect | policy | 3 | 2000 | 1093293 | 546.6465 | 0 |
| lookup_native_hot | policy | 3 | 2000 | 1249778 | 624.889 | 0 |
| exec_tool_redirect | policy | 3 | 20 | 1285035 | 64251.75 | 0 |
| open_tool_redirect | policy | 3 | 2000 | 1995006 | 997.503 | 0 |
| readdir_alias_view | policy | 3 | 500 | 208648 | 417.296 | 0 |
| build_tree_stat_walk | policy | 3 | 1984 | 1773429 | 893.8654233870968 | 0 |
| lookup_tool_redirect | policy | 3 | 2000 | 1254105 | 627.0525 | 0 |
| lookup_native_hot | policy | 4 | 2000 | 1272446 | 636.223 | 0 |
| exec_tool_redirect | policy | 4 | 20 | 1416992 | 70849.6 | 0 |
| readdir_alias_view | policy | 4 | 500 | 211779 | 423.558 | 0 |
| lookup_tool_redirect | policy | 4 | 2000 | 1269233 | 634.6165 | 0 |
| open_tool_redirect | policy | 4 | 2000 | 1994454 | 997.227 | 0 |
| build_tree_stat_walk | policy | 4 | 1984 | 1823596 | 919.1512096774194 | 0 |
| access_tool_redirect | policy | 4 | 2000 | 1075316 | 537.658 | 0 |
| build_tree_stat_walk | policy | 5 | 1984 | 1777619 | 895.9773185483871 | 0 |
| exec_tool_redirect | policy | 5 | 20 | 1357166 | 67858.3 | 0 |
| access_tool_redirect | policy | 5 | 2000 | 1066887 | 533.4435 | 0 |
| readdir_alias_view | policy | 5 | 500 | 214354 | 428.708 | 0 |
| open_tool_redirect | policy | 5 | 2000 | 2005603 | 1002.8015 | 0 |
| lookup_native_hot | policy | 5 | 2000 | 1244827 | 622.4135 | 0 |
| lookup_tool_redirect | policy | 5 | 2000 | 1343647 | 671.8235 | 0 |
| open_tool_redirect | policy | 6 | 2000 | 1999859 | 999.9295 | 0 |
| build_tree_stat_walk | policy | 6 | 1984 | 1787877 | 901.1476814516129 | 0 |
| access_tool_redirect | policy | 6 | 2000 | 1082731 | 541.3655 | 0 |
| lookup_tool_redirect | policy | 6 | 2000 | 1277935 | 638.9675 | 0 |
| readdir_alias_view | policy | 6 | 500 | 211017 | 422.034 | 0 |
| exec_tool_redirect | policy | 6 | 20 | 1377645 | 68882.25 | 0 |
| lookup_native_hot | policy | 6 | 2000 | 1261079 | 630.5395 | 0 |
| lookup_native_hot | policy | 7 | 2000 | 1264775 | 632.3875 | 0 |
| exec_tool_redirect | policy | 7 | 20 | 1428988 | 71449.4 | 0 |
| lookup_tool_redirect | policy | 7 | 2000 | 1259318 | 629.659 | 0 |
| build_tree_stat_walk | policy | 7 | 1984 | 4351875 | 2193.485383064516 | 0 |
| access_tool_redirect | policy | 7 | 2000 | 703027 | 351.5135 | 0 |
| readdir_alias_view | policy | 7 | 500 | 147061 | 294.122 | 0 |
| open_tool_redirect | policy | 7 | 2000 | 1338391 | 669.1955 | 0 |
| open_tool_redirect | policy | 8 | 2000 | 1358800 | 679.4 | 0 |
| lookup_tool_redirect | policy | 8 | 2000 | 822037 | 411.0185 | 0 |
| readdir_alias_view | policy | 8 | 500 | 145752 | 291.504 | 0 |
| exec_tool_redirect | policy | 8 | 20 | 1552989 | 77649.45 | 0 |
| lookup_native_hot | policy | 8 | 2000 | 808050 | 404.025 | 0 |
| access_tool_redirect | policy | 8 | 2000 | 722547 | 361.2735 | 0 |
| build_tree_stat_walk | policy | 8 | 1984 | 1168125 | 588.7726814516129 | 0 |
| open_tool_redirect | policy | 9 | 2000 | 1326992 | 663.496 | 0 |
| exec_tool_redirect | policy | 9 | 20 | 1425217 | 71260.85 | 0 |
| lookup_tool_redirect | policy | 9 | 2000 | 817479 | 408.7395 | 0 |
| build_tree_stat_walk | policy | 9 | 1984 | 1167156 | 588.2842741935484 | 0 |
| lookup_native_hot | policy | 9 | 2000 | 778797 | 389.3985 | 0 |
| access_tool_redirect | policy | 9 | 2000 | 718659 | 359.3295 | 0 |
| readdir_alias_view | policy | 9 | 500 | 155278 | 310.556 | 0 |
| access_tool_redirect | policy | 10 | 2000 | 728919 | 364.4595 | 0 |
| lookup_tool_redirect | policy | 10 | 2000 | 813384 | 406.692 | 0 |
| exec_tool_redirect | policy | 10 | 20 | 1332728 | 66636.4 | 0 |
| readdir_alias_view | policy | 10 | 500 | 137974 | 275.948 | 0 |
| open_tool_redirect | policy | 10 | 2000 | 1329448 | 664.724 | 0 |
| build_tree_stat_walk | policy | 10 | 1984 | 1170267 | 589.8523185483871 | 0 |
| lookup_native_hot | policy | 10 | 2000 | 788153 | 394.0765 | 0 |
| build_tree_stat_walk | policy | 11 | 1984 | 1172831 | 591.1446572580645 | 0 |
| access_tool_redirect | policy | 11 | 2000 | 728696 | 364.348 | 0 |
| lookup_native_hot | policy | 11 | 2000 | 814630 | 407.315 | 0 |
| open_tool_redirect | policy | 11 | 2000 | 1350356 | 675.178 | 0 |
| readdir_alias_view | policy | 11 | 500 | 143401 | 286.802 | 0 |
| lookup_tool_redirect | policy | 11 | 2000 | 799145 | 399.5725 | 0 |
| exec_tool_redirect | policy | 11 | 20 | 1386928 | 69346.4 | 0 |
| exec_tool_redirect | policy | 12 | 20 | 1253654 | 62682.7 | 0 |
| build_tree_stat_walk | policy | 12 | 1984 | 1180412 | 594.9657258064516 | 0 |
| readdir_alias_view | policy | 12 | 500 | 146820 | 293.64 | 0 |
| lookup_native_hot | policy | 12 | 2000 | 777297 | 388.6485 | 0 |
| access_tool_redirect | policy | 12 | 2000 | 746461 | 373.2305 | 0 |
| open_tool_redirect | policy | 12 | 2000 | 1343071 | 671.5355 | 0 |
| lookup_tool_redirect | policy | 12 | 2000 | 824706 | 412.353 | 0 |
| lookup_native_hot | policy | 13 | 2000 | 772817 | 386.4085 | 0 |
| readdir_alias_view | policy | 13 | 500 | 144753 | 289.506 | 0 |
| access_tool_redirect | policy | 13 | 2000 | 718325 | 359.1625 | 0 |
| exec_tool_redirect | policy | 13 | 20 | 1335505 | 66775.25 | 0 |
| open_tool_redirect | policy | 13 | 2000 | 1379287 | 689.6435 | 0 |
| lookup_tool_redirect | policy | 13 | 2000 | 795338 | 397.669 | 0 |
| build_tree_stat_walk | policy | 13 | 1984 | 1185189 | 597.3734879032259 | 0 |
| build_tree_stat_walk | policy | 14 | 1984 | 1158552 | 583.9475806451613 | 0 |
| readdir_alias_view | policy | 14 | 500 | 142952 | 285.904 | 0 |
| access_tool_redirect | policy | 14 | 2000 | 721477 | 360.7385 | 0 |
| exec_tool_redirect | policy | 14 | 20 | 1219845 | 60992.25 | 0 |
| lookup_native_hot | policy | 14 | 2000 | 815964 | 407.982 | 0 |
| lookup_tool_redirect | policy | 14 | 2000 | 838416 | 419.208 | 0 |
| open_tool_redirect | policy | 14 | 2000 | 1325952 | 662.976 | 0 |
| lookup_tool_redirect | policy | 15 | 2000 | 813967 | 406.9835 | 0 |
| build_tree_stat_walk | policy | 15 | 1984 | 1179461 | 594.4863911290323 | 0 |
| exec_tool_redirect | policy | 15 | 20 | 1255382 | 62769.1 | 0 |
| lookup_native_hot | policy | 15 | 2000 | 818850 | 409.425 | 0 |
| access_tool_redirect | policy | 15 | 2000 | 753115 | 376.5575 | 0 |
| open_tool_redirect | policy | 15 | 2000 | 1329676 | 664.838 | 0 |
| readdir_alias_view | policy | 15 | 500 | 149436 | 298.872 | 0 |
| lookup_tool_redirect | policy | 16 | 2000 | 832630 | 416.315 | 0 |
| readdir_alias_view | policy | 16 | 500 | 145260 | 290.52 | 0 |
| exec_tool_redirect | policy | 16 | 20 | 1313812 | 65690.6 | 0 |
| access_tool_redirect | policy | 16 | 2000 | 722725 | 361.3625 | 0 |
| open_tool_redirect | policy | 16 | 2000 | 1336035 | 668.0175 | 0 |
| build_tree_stat_walk | policy | 16 | 1984 | 1192406 | 601.0110887096774 | 0 |
| lookup_native_hot | policy | 16 | 2000 | 780046 | 390.023 | 0 |
| build_tree_stat_walk | policy | 17 | 1984 | 1156966 | 583.148185483871 | 0 |
| access_tool_redirect | policy | 17 | 2000 | 731910 | 365.955 | 0 |
| readdir_alias_view | policy | 17 | 500 | 149072 | 298.144 | 0 |
| open_tool_redirect | policy | 17 | 2000 | 1345000 | 672.5 | 0 |
| lookup_tool_redirect | policy | 17 | 2000 | 804983 | 402.4915 | 0 |
| lookup_native_hot | policy | 17 | 2000 | 793105 | 396.5525 | 0 |
| exec_tool_redirect | policy | 17 | 20 | 1536096 | 76804.8 | 0 |
| lookup_native_hot | policy | 18 | 2000 | 797773 | 398.8865 | 0 |
| lookup_tool_redirect | policy | 18 | 2000 | 795120 | 397.56 | 0 |
| access_tool_redirect | policy | 18 | 2000 | 730811 | 365.4055 | 0 |
| exec_tool_redirect | policy | 18 | 20 | 1062292 | 53114.6 | 0 |
| build_tree_stat_walk | policy | 18 | 1984 | 1202454 | 606.0756048387096 | 0 |
| readdir_alias_view | policy | 18 | 500 | 138686 | 277.372 | 0 |
| open_tool_redirect | policy | 18 | 2000 | 1361391 | 680.6955 | 0 |
| lookup_native_hot | policy | 19 | 2000 | 779615 | 389.8075 | 0 |
| open_tool_redirect | policy | 19 | 2000 | 1358072 | 679.036 | 0 |
| exec_tool_redirect | policy | 19 | 20 | 1320016 | 66000.8 | 0 |
| readdir_alias_view | policy | 19 | 500 | 149839 | 299.678 | 0 |
| access_tool_redirect | policy | 19 | 2000 | 741419 | 370.7095 | 0 |
| lookup_tool_redirect | policy | 19 | 2000 | 837479 | 418.7395 | 0 |
| build_tree_stat_walk | policy | 19 | 1984 | 1191915 | 600.7636088709677 | 0 |
| access_tool_redirect | table_redirect_empty | 0 | 2000 | 893950 | 446.975 | 0 |
| exec_tool_redirect | table_redirect_empty | 0 | 20 | 1355862 | 67793.1 | 0 |
| lookup_tool_redirect | table_redirect_empty | 0 | 2000 | 973746 | 486.873 | 0 |
| open_tool_redirect | table_redirect_empty | 0 | 2000 | 1503108 | 751.554 | 0 |
| lookup_native_hot | table_redirect_empty | 0 | 2000 | 960380 | 480.19 | 0 |
| build_tree_stat_walk | table_redirect_empty | 0 | 1984 | 1506667 | 759.4087701612904 | 0 |
| readdir_alias_view | table_redirect_empty | 0 | 500 | 175299 | 350.598 | 0 |
| access_tool_redirect | table_redirect_empty | 1 | 2000 | 894730 | 447.365 | 0 |
| open_tool_redirect | table_redirect_empty | 1 | 2000 | 1509264 | 754.632 | 0 |
| lookup_native_hot | table_redirect_empty | 1 | 2000 | 995810 | 497.905 | 0 |
| build_tree_stat_walk | table_redirect_empty | 1 | 1984 | 1517136 | 764.6854838709677 | 0 |
| readdir_alias_view | table_redirect_empty | 1 | 500 | 169455 | 338.91 | 0 |
| lookup_tool_redirect | table_redirect_empty | 1 | 2000 | 982407 | 491.2035 | 0 |
| exec_tool_redirect | table_redirect_empty | 1 | 20 | 1414693 | 70734.65 | 0 |
| build_tree_stat_walk | table_redirect_empty | 2 | 1984 | 1539428 | 775.921370967742 | 0 |
| open_tool_redirect | table_redirect_empty | 2 | 2000 | 1491200 | 745.6 | 0 |
| readdir_alias_view | table_redirect_empty | 2 | 500 | 168917 | 337.834 | 0 |
| access_tool_redirect | table_redirect_empty | 2 | 2000 | 917457 | 458.7285 | 0 |
| lookup_native_hot | table_redirect_empty | 2 | 2000 | 995919 | 497.9595 | 0 |
| lookup_tool_redirect | table_redirect_empty | 2 | 2000 | 964149 | 482.0745 | 0 |
| exec_tool_redirect | table_redirect_empty | 2 | 20 | 1329569 | 66478.45 | 0 |
| exec_tool_redirect | table_redirect_empty | 3 | 20 | 1076494 | 53824.7 | 0 |
| build_tree_stat_walk | table_redirect_empty | 3 | 1984 | 1520337 | 766.2988911290323 | 0 |
| lookup_tool_redirect | table_redirect_empty | 3 | 2000 | 1008630 | 504.315 | 0 |
| lookup_native_hot | table_redirect_empty | 3 | 2000 | 992231 | 496.1155 | 0 |
| open_tool_redirect | table_redirect_empty | 3 | 2000 | 1495446 | 747.723 | 0 |
| readdir_alias_view | table_redirect_empty | 3 | 500 | 171695 | 343.39 | 0 |
| access_tool_redirect | table_redirect_empty | 3 | 2000 | 902485 | 451.2425 | 0 |
| build_tree_stat_walk | table_redirect_empty | 4 | 1984 | 1491797 | 751.913810483871 | 0 |
| exec_tool_redirect | table_redirect_empty | 4 | 20 | 1304293 | 65214.65 | 0 |
| access_tool_redirect | table_redirect_empty | 4 | 2000 | 900059 | 450.0295 | 0 |
| lookup_native_hot | table_redirect_empty | 4 | 2000 | 957804 | 478.902 | 0 |
| lookup_tool_redirect | table_redirect_empty | 4 | 2000 | 958990 | 479.495 | 0 |
| open_tool_redirect | table_redirect_empty | 4 | 2000 | 1507318 | 753.659 | 0 |
| readdir_alias_view | table_redirect_empty | 4 | 500 | 183106 | 366.212 | 0 |
| open_tool_redirect | table_redirect_empty | 5 | 2000 | 1508306 | 754.153 | 0 |
| readdir_alias_view | table_redirect_empty | 5 | 500 | 166903 | 333.806 | 0 |
| build_tree_stat_walk | table_redirect_empty | 5 | 1984 | 1500242 | 756.1703629032259 | 0 |
| exec_tool_redirect | table_redirect_empty | 5 | 20 | 1384629 | 69231.45 | 0 |
| access_tool_redirect | table_redirect_empty | 5 | 2000 | 894841 | 447.4205 | 0 |
| lookup_tool_redirect | table_redirect_empty | 5 | 2000 | 979948 | 489.974 | 0 |
| lookup_native_hot | table_redirect_empty | 5 | 2000 | 988911 | 494.4555 | 0 |
| access_tool_redirect | table_redirect_empty | 6 | 2000 | 911343 | 455.6715 | 0 |
| lookup_tool_redirect | table_redirect_empty | 6 | 2000 | 960251 | 480.1255 | 0 |
| build_tree_stat_walk | table_redirect_empty | 6 | 1984 | 1493486 | 752.765120967742 | 0 |
| readdir_alias_view | table_redirect_empty | 6 | 500 | 169213 | 338.426 | 0 |
| open_tool_redirect | table_redirect_empty | 6 | 2000 | 1509722 | 754.861 | 0 |
| lookup_native_hot | table_redirect_empty | 6 | 2000 | 971424 | 485.712 | 0 |
| exec_tool_redirect | table_redirect_empty | 6 | 20 | 1405768 | 70288.4 | 0 |
| lookup_native_hot | table_redirect_empty | 7 | 2000 | 971294 | 485.647 | 0 |
| readdir_alias_view | table_redirect_empty | 7 | 500 | 180295 | 360.59 | 0 |
| access_tool_redirect | table_redirect_empty | 7 | 2000 | 885223 | 442.6115 | 0 |
| lookup_tool_redirect | table_redirect_empty | 7 | 2000 | 993816 | 496.908 | 0 |
| exec_tool_redirect | table_redirect_empty | 7 | 20 | 1275430 | 63771.5 | 0 |
| open_tool_redirect | table_redirect_empty | 7 | 2000 | 1521512 | 760.756 | 0 |
| build_tree_stat_walk | table_redirect_empty | 7 | 1984 | 1502811 | 757.4652217741935 | 0 |
| readdir_alias_view | table_redirect_empty | 8 | 500 | 168773 | 337.546 | 0 |
| lookup_tool_redirect | table_redirect_empty | 8 | 2000 | 996889 | 498.4445 | 0 |
| build_tree_stat_walk | table_redirect_empty | 8 | 1984 | 1497279 | 754.6769153225806 | 0 |
| lookup_native_hot | table_redirect_empty | 8 | 2000 | 991923 | 495.9615 | 0 |
| exec_tool_redirect | table_redirect_empty | 8 | 20 | 1234153 | 61707.65 | 0 |
| access_tool_redirect | table_redirect_empty | 8 | 2000 | 893452 | 446.726 | 0 |
| open_tool_redirect | table_redirect_empty | 8 | 2000 | 1487072 | 743.536 | 0 |
| build_tree_stat_walk | table_redirect_empty | 9 | 1984 | 1490234 | 751.1260080645161 | 0 |
| readdir_alias_view | table_redirect_empty | 9 | 500 | 169171 | 338.342 | 0 |
| access_tool_redirect | table_redirect_empty | 9 | 2000 | 874213 | 437.1065 | 0 |
| exec_tool_redirect | table_redirect_empty | 9 | 20 | 1346651 | 67332.55 | 0 |
| lookup_tool_redirect | table_redirect_empty | 9 | 2000 | 961042 | 480.521 | 0 |
| open_tool_redirect | table_redirect_empty | 9 | 2000 | 1482511 | 741.2555 | 0 |
| lookup_native_hot | table_redirect_empty | 9 | 2000 | 963209 | 481.6045 | 0 |
| exec_tool_redirect | table_redirect_empty | 10 | 20 | 1199759 | 59987.95 | 0 |
| build_tree_stat_walk | table_redirect_empty | 10 | 1984 | 1523913 | 768.101310483871 | 0 |
| access_tool_redirect | table_redirect_empty | 10 | 2000 | 873378 | 436.689 | 0 |
| lookup_native_hot | table_redirect_empty | 10 | 2000 | 960404 | 480.202 | 0 |
| open_tool_redirect | table_redirect_empty | 10 | 2000 | 1503591 | 751.7955 | 0 |
| lookup_tool_redirect | table_redirect_empty | 10 | 2000 | 961491 | 480.7455 | 0 |
| readdir_alias_view | table_redirect_empty | 10 | 500 | 173147 | 346.294 | 0 |
| access_tool_redirect | table_redirect_empty | 11 | 2000 | 891271 | 445.6355 | 0 |
| build_tree_stat_walk | table_redirect_empty | 11 | 1984 | 1482493 | 747.2242943548387 | 0 |
| lookup_native_hot | table_redirect_empty | 11 | 2000 | 975177 | 487.5885 | 0 |
| exec_tool_redirect | table_redirect_empty | 11 | 20 | 1225581 | 61279.05 | 0 |
| readdir_alias_view | table_redirect_empty | 11 | 500 | 172545 | 345.09 | 0 |
| open_tool_redirect | table_redirect_empty | 11 | 2000 | 1526548 | 763.274 | 0 |
| lookup_tool_redirect | table_redirect_empty | 11 | 2000 | 959583 | 479.7915 | 0 |
| readdir_alias_view | table_redirect_empty | 12 | 500 | 166779 | 333.558 | 0 |
| build_tree_stat_walk | table_redirect_empty | 12 | 1984 | 1495174 | 753.6159274193549 | 0 |
| open_tool_redirect | table_redirect_empty | 12 | 2000 | 1483066 | 741.533 | 0 |
| exec_tool_redirect | table_redirect_empty | 12 | 20 | 1444252 | 72212.6 | 0 |
| lookup_tool_redirect | table_redirect_empty | 12 | 2000 | 976516 | 488.258 | 0 |
| access_tool_redirect | table_redirect_empty | 12 | 2000 | 899641 | 449.8205 | 0 |
| lookup_native_hot | table_redirect_empty | 12 | 2000 | 988283 | 494.1415 | 0 |
| lookup_native_hot | table_redirect_empty | 13 | 2000 | 961552 | 480.776 | 0 |
| build_tree_stat_walk | table_redirect_empty | 13 | 1984 | 1494302 | 753.1764112903226 | 0 |
| exec_tool_redirect | table_redirect_empty | 13 | 20 | 1267253 | 63362.65 | 0 |
| access_tool_redirect | table_redirect_empty | 13 | 2000 | 894943 | 447.4715 | 0 |
| open_tool_redirect | table_redirect_empty | 13 | 2000 | 1497161 | 748.5805 | 0 |
| readdir_alias_view | table_redirect_empty | 13 | 500 | 171771 | 343.542 | 0 |
| lookup_tool_redirect | table_redirect_empty | 13 | 2000 | 980986 | 490.493 | 0 |
| open_tool_redirect | table_redirect_empty | 14 | 2000 | 1490809 | 745.4045 | 0 |
| lookup_native_hot | table_redirect_empty | 14 | 2000 | 959120 | 479.56 | 0 |
| readdir_alias_view | table_redirect_empty | 14 | 500 | 178520 | 357.04 | 0 |
| exec_tool_redirect | table_redirect_empty | 14 | 20 | 1295349 | 64767.45 | 0 |
| lookup_tool_redirect | table_redirect_empty | 14 | 2000 | 974275 | 487.1375 | 0 |
| build_tree_stat_walk | table_redirect_empty | 14 | 1984 | 1487888 | 749.9435483870968 | 0 |
| access_tool_redirect | table_redirect_empty | 14 | 2000 | 892207 | 446.1035 | 0 |
| lookup_tool_redirect | table_redirect_empty | 15 | 2000 | 983820 | 491.91 | 0 |
| readdir_alias_view | table_redirect_empty | 15 | 500 | 179684 | 359.368 | 0 |
| exec_tool_redirect | table_redirect_empty | 15 | 20 | 1311738 | 65586.9 | 0 |
| build_tree_stat_walk | table_redirect_empty | 15 | 1984 | 1508919 | 760.5438508064516 | 0 |
| access_tool_redirect | table_redirect_empty | 15 | 2000 | 888512 | 444.256 | 0 |
| lookup_native_hot | table_redirect_empty | 15 | 2000 | 978664 | 489.332 | 0 |
| open_tool_redirect | table_redirect_empty | 15 | 2000 | 1533840 | 766.92 | 0 |
| open_tool_redirect | table_redirect_empty | 16 | 2000 | 1521412 | 760.706 | 0 |
| exec_tool_redirect | table_redirect_empty | 16 | 20 | 1443941 | 72197.05 | 0 |
| lookup_tool_redirect | table_redirect_empty | 16 | 2000 | 984571 | 492.2855 | 0 |
| lookup_native_hot | table_redirect_empty | 16 | 2000 | 996226 | 498.113 | 0 |
| access_tool_redirect | table_redirect_empty | 16 | 2000 | 873945 | 436.9725 | 0 |
| build_tree_stat_walk | table_redirect_empty | 16 | 1984 | 1483523 | 747.7434475806451 | 0 |
| readdir_alias_view | table_redirect_empty | 16 | 500 | 182853 | 365.706 | 0 |
| open_tool_redirect | table_redirect_empty | 17 | 2000 | 1494444 | 747.222 | 0 |
| access_tool_redirect | table_redirect_empty | 17 | 2000 | 913623 | 456.8115 | 0 |
| lookup_native_hot | table_redirect_empty | 17 | 2000 | 992945 | 496.4725 | 0 |
| exec_tool_redirect | table_redirect_empty | 17 | 20 | 1243083 | 62154.15 | 0 |
| lookup_tool_redirect | table_redirect_empty | 17 | 2000 | 972678 | 486.339 | 0 |
| build_tree_stat_walk | table_redirect_empty | 17 | 1984 | 1530037 | 771.188004032258 | 0 |
| readdir_alias_view | table_redirect_empty | 17 | 500 | 169418 | 338.836 | 0 |
| lookup_native_hot | table_redirect_empty | 18 | 2000 | 981605 | 490.8025 | 0 |
| open_tool_redirect | table_redirect_empty | 18 | 2000 | 1486192 | 743.096 | 0 |
| exec_tool_redirect | table_redirect_empty | 18 | 20 | 1301703 | 65085.15 | 0 |
| readdir_alias_view | table_redirect_empty | 18 | 500 | 183042 | 366.084 | 0 |
| lookup_tool_redirect | table_redirect_empty | 18 | 2000 | 973017 | 486.5085 | 0 |
| access_tool_redirect | table_redirect_empty | 18 | 2000 | 890718 | 445.359 | 0 |
| build_tree_stat_walk | table_redirect_empty | 18 | 1984 | 1509630 | 760.9022177419355 | 0 |
| open_tool_redirect | table_redirect_empty | 19 | 2000 | 1477313 | 738.6565 | 0 |
| build_tree_stat_walk | table_redirect_empty | 19 | 1984 | 1497833 | 754.9561491935484 | 0 |
| access_tool_redirect | table_redirect_empty | 19 | 2000 | 892146 | 446.073 | 0 |
| exec_tool_redirect | table_redirect_empty | 19 | 20 | 1433177 | 71658.85 | 0 |
| readdir_alias_view | table_redirect_empty | 19 | 500 | 180189 | 360.378 | 0 |
| lookup_native_hot | table_redirect_empty | 19 | 2000 | 960374 | 480.187 | 0 |
| lookup_tool_redirect | table_redirect_empty | 19 | 2000 | 970415 | 485.2075 | 0 |
| exec_tool_redirect | baseline | 0 | 20 | 1153845 | 57692.25 | 0 |
| build_tree_stat_walk | baseline | 0 | 1984 | 696881 | 351.25050403225805 | 0 |
| open_tool_redirect | baseline | 0 | 2000 | 936760 | 468.38 | 0 |
| lookup_tool_redirect | baseline | 0 | 2000 | 519602 | 259.801 | 0 |
| readdir_alias_view | baseline | 0 | 500 | 104780 | 209.56 | 0 |
| access_tool_redirect | baseline | 0 | 2000 | 390057 | 195.0285 | 0 |
| lookup_native_hot | baseline | 0 | 2000 | 497889 | 248.9445 | 0 |
| lookup_tool_redirect | baseline | 1 | 2000 | 482517 | 241.2585 | 0 |
| readdir_alias_view | baseline | 1 | 500 | 99027 | 198.054 | 0 |
| lookup_native_hot | baseline | 1 | 2000 | 481726 | 240.863 | 0 |
| build_tree_stat_walk | baseline | 1 | 1984 | 648641 | 326.9359879032258 | 0 |
| exec_tool_redirect | baseline | 1 | 20 | 1187362 | 59368.1 | 0 |
| access_tool_redirect | baseline | 1 | 2000 | 394161 | 197.0805 | 0 |
| open_tool_redirect | baseline | 1 | 2000 | 973695 | 486.8475 | 0 |
| access_tool_redirect | baseline | 2 | 2000 | 400494 | 200.247 | 0 |
| build_tree_stat_walk | baseline | 2 | 1984 | 669114 | 337.25504032258067 | 0 |
| lookup_native_hot | baseline | 2 | 2000 | 510253 | 255.1265 | 0 |
| readdir_alias_view | baseline | 2 | 500 | 99121 | 198.242 | 0 |
| open_tool_redirect | baseline | 2 | 2000 | 967368 | 483.684 | 0 |
| exec_tool_redirect | baseline | 2 | 20 | 1346815 | 67340.75 | 0 |
| lookup_tool_redirect | baseline | 2 | 2000 | 514748 | 257.374 | 0 |
| exec_tool_redirect | baseline | 3 | 20 | 1190775 | 59538.75 | 0 |
| build_tree_stat_walk | baseline | 3 | 1984 | 679852 | 342.66733870967744 | 0 |
| open_tool_redirect | baseline | 3 | 2000 | 944740 | 472.37 | 0 |
| lookup_native_hot | baseline | 3 | 2000 | 480324 | 240.162 | 0 |
| readdir_alias_view | baseline | 3 | 500 | 105139 | 210.278 | 0 |
| lookup_tool_redirect | baseline | 3 | 2000 | 479235 | 239.6175 | 0 |
| access_tool_redirect | baseline | 3 | 2000 | 417322 | 208.661 | 0 |
| lookup_tool_redirect | baseline | 4 | 2000 | 481912 | 240.956 | 0 |
| access_tool_redirect | baseline | 4 | 2000 | 409145 | 204.5725 | 0 |
| lookup_native_hot | baseline | 4 | 2000 | 483742 | 241.871 | 0 |
| readdir_alias_view | baseline | 4 | 500 | 102783 | 205.566 | 0 |
| open_tool_redirect | baseline | 4 | 2000 | 943316 | 471.658 | 0 |
| exec_tool_redirect | baseline | 4 | 20 | 1288424 | 64421.2 | 0 |
| build_tree_stat_walk | baseline | 4 | 1984 | 670305 | 337.8553427419355 | 0 |
| open_tool_redirect | baseline | 5 | 2000 | 936039 | 468.0195 | 0 |
| access_tool_redirect | baseline | 5 | 2000 | 407338 | 203.669 | 0 |
| build_tree_stat_walk | baseline | 5 | 1984 | 669507 | 337.453125 | 0 |
| lookup_tool_redirect | baseline | 5 | 2000 | 504137 | 252.0685 | 0 |
| exec_tool_redirect | baseline | 5 | 20 | 1293405 | 64670.25 | 0 |
| lookup_native_hot | baseline | 5 | 2000 | 517045 | 258.5225 | 0 |
| readdir_alias_view | baseline | 5 | 500 | 104729 | 209.458 | 0 |
| readdir_alias_view | baseline | 6 | 500 | 98279 | 196.558 | 0 |
| lookup_tool_redirect | baseline | 6 | 2000 | 486977 | 243.4885 | 0 |
| access_tool_redirect | baseline | 6 | 2000 | 426826 | 213.413 | 0 |
| build_tree_stat_walk | baseline | 6 | 1984 | 649861 | 327.5509072580645 | 0 |
| open_tool_redirect | baseline | 6 | 2000 | 979859 | 489.9295 | 0 |
| exec_tool_redirect | baseline | 6 | 20 | 1194520 | 59726 | 0 |
| lookup_native_hot | baseline | 6 | 2000 | 507777 | 253.8885 | 0 |
| exec_tool_redirect | baseline | 7 | 20 | 1232063 | 61603.15 | 0 |
| readdir_alias_view | baseline | 7 | 500 | 105275 | 210.55 | 0 |
| access_tool_redirect | baseline | 7 | 2000 | 405116 | 202.558 | 0 |
| open_tool_redirect | baseline | 7 | 2000 | 960674 | 480.337 | 0 |
| lookup_native_hot | baseline | 7 | 2000 | 485258 | 242.629 | 0 |
| lookup_tool_redirect | baseline | 7 | 2000 | 496465 | 248.2325 | 0 |
| build_tree_stat_walk | baseline | 7 | 1984 | 681992 | 343.7459677419355 | 0 |
| readdir_alias_view | baseline | 8 | 500 | 102811 | 205.622 | 0 |
| build_tree_stat_walk | baseline | 8 | 1984 | 680210 | 342.8477822580645 | 0 |
| lookup_tool_redirect | baseline | 8 | 2000 | 481225 | 240.6125 | 0 |
| lookup_native_hot | baseline | 8 | 2000 | 486275 | 243.1375 | 0 |
| open_tool_redirect | baseline | 8 | 2000 | 987484 | 493.742 | 0 |
| exec_tool_redirect | baseline | 8 | 20 | 1276421 | 63821.05 | 0 |
| access_tool_redirect | baseline | 8 | 2000 | 410906 | 205.453 | 0 |
| lookup_tool_redirect | baseline | 9 | 2000 | 478535 | 239.2675 | 0 |
| access_tool_redirect | baseline | 9 | 2000 | 390478 | 195.239 | 0 |
| readdir_alias_view | baseline | 9 | 500 | 98856 | 197.712 | 0 |
| open_tool_redirect | baseline | 9 | 2000 | 932251 | 466.1255 | 0 |
| lookup_native_hot | baseline | 9 | 2000 | 495001 | 247.5005 | 0 |
| build_tree_stat_walk | baseline | 9 | 1984 | 650376 | 327.81048387096774 | 0 |
| exec_tool_redirect | baseline | 9 | 20 | 1249937 | 62496.85 | 0 |
| readdir_alias_view | baseline | 10 | 500 | 104454 | 208.908 | 0 |
| open_tool_redirect | baseline | 10 | 2000 | 937323 | 468.6615 | 0 |
| lookup_tool_redirect | baseline | 10 | 2000 | 506541 | 253.2705 | 0 |
| lookup_native_hot | baseline | 10 | 2000 | 497063 | 248.5315 | 0 |
| build_tree_stat_walk | baseline | 10 | 1984 | 686631 | 346.08417338709677 | 0 |
| access_tool_redirect | baseline | 10 | 2000 | 424658 | 212.329 | 0 |
| exec_tool_redirect | baseline | 10 | 20 | 1389560 | 69478 | 0 |
| access_tool_redirect | baseline | 11 | 2000 | 410682 | 205.341 | 0 |
| exec_tool_redirect | baseline | 11 | 20 | 1181516 | 59075.8 | 0 |
| readdir_alias_view | baseline | 11 | 500 | 105944 | 211.888 | 0 |
| open_tool_redirect | baseline | 11 | 2000 | 934510 | 467.255 | 0 |
| lookup_native_hot | baseline | 11 | 2000 | 493370 | 246.685 | 0 |
| build_tree_stat_walk | baseline | 11 | 1984 | 650801 | 328.0246975806452 | 0 |
| lookup_tool_redirect | baseline | 11 | 2000 | 483760 | 241.88 | 0 |
| lookup_tool_redirect | baseline | 12 | 2000 | 516336 | 258.168 | 0 |
| open_tool_redirect | baseline | 12 | 2000 | 943088 | 471.544 | 0 |
| lookup_native_hot | baseline | 12 | 2000 | 513920 | 256.96 | 0 |
| readdir_alias_view | baseline | 12 | 500 | 104207 | 208.414 | 0 |
| exec_tool_redirect | baseline | 12 | 20 | 1238276 | 61913.8 | 0 |
| access_tool_redirect | baseline | 12 | 2000 | 408974 | 204.487 | 0 |
| build_tree_stat_walk | baseline | 12 | 1984 | 652695 | 328.97933467741933 | 0 |
| exec_tool_redirect | baseline | 13 | 20 | 1291359 | 64567.95 | 0 |
| readdir_alias_view | baseline | 13 | 500 | 105715 | 211.43 | 0 |
| access_tool_redirect | baseline | 13 | 2000 | 402412 | 201.206 | 0 |
| open_tool_redirect | baseline | 13 | 2000 | 946246 | 473.123 | 0 |
| build_tree_stat_walk | baseline | 13 | 1984 | 647791 | 326.507560483871 | 0 |
| lookup_native_hot | baseline | 13 | 2000 | 481143 | 240.5715 | 0 |
| lookup_tool_redirect | baseline | 13 | 2000 | 482604 | 241.302 | 0 |
| access_tool_redirect | baseline | 14 | 2000 | 424688 | 212.344 | 0 |
| build_tree_stat_walk | baseline | 14 | 1984 | 652132 | 328.695564516129 | 0 |
| open_tool_redirect | baseline | 14 | 2000 | 935907 | 467.9535 | 0 |
| readdir_alias_view | baseline | 14 | 500 | 96382 | 192.764 | 0 |
| lookup_tool_redirect | baseline | 14 | 2000 | 479351 | 239.6755 | 0 |
| exec_tool_redirect | baseline | 14 | 20 | 1219146 | 60957.3 | 0 |
| lookup_native_hot | baseline | 14 | 2000 | 482685 | 241.3425 | 0 |
| open_tool_redirect | baseline | 15 | 2000 | 950975 | 475.4875 | 0 |
| readdir_alias_view | baseline | 15 | 500 | 104481 | 208.962 | 0 |
| exec_tool_redirect | baseline | 15 | 20 | 1439590 | 71979.5 | 0 |
| build_tree_stat_walk | baseline | 15 | 1984 | 667192 | 336.28629032258067 | 0 |
| lookup_native_hot | baseline | 15 | 2000 | 480512 | 240.256 | 0 |
| lookup_tool_redirect | baseline | 15 | 2000 | 497656 | 248.828 | 0 |
| access_tool_redirect | baseline | 15 | 2000 | 397185 | 198.5925 | 0 |
| build_tree_stat_walk | baseline | 16 | 1984 | 658761 | 332.0367943548387 | 0 |
| open_tool_redirect | baseline | 16 | 2000 | 940712 | 470.356 | 0 |
| exec_tool_redirect | baseline | 16 | 20 | 1232744 | 61637.2 | 0 |
| access_tool_redirect | baseline | 16 | 2000 | 402602 | 201.301 | 0 |
| lookup_native_hot | baseline | 16 | 2000 | 514030 | 257.015 | 0 |
| lookup_tool_redirect | baseline | 16 | 2000 | 491543 | 245.7715 | 0 |
| readdir_alias_view | baseline | 16 | 500 | 104993 | 209.986 | 0 |
| lookup_native_hot | baseline | 17 | 2000 | 481029 | 240.5145 | 0 |
| access_tool_redirect | baseline | 17 | 2000 | 407268 | 203.634 | 0 |
| lookup_tool_redirect | baseline | 17 | 2000 | 484449 | 242.2245 | 0 |
| build_tree_stat_walk | baseline | 17 | 1984 | 651495 | 328.37449596774195 | 0 |
| open_tool_redirect | baseline | 17 | 2000 | 960590 | 480.295 | 0 |
| exec_tool_redirect | baseline | 17 | 20 | 1314830 | 65741.5 | 0 |
| readdir_alias_view | baseline | 17 | 500 | 105232 | 210.464 | 0 |
| exec_tool_redirect | baseline | 18 | 20 | 1194944 | 59747.2 | 0 |
| readdir_alias_view | baseline | 18 | 500 | 105272 | 210.544 | 0 |
| open_tool_redirect | baseline | 18 | 2000 | 942476 | 471.238 | 0 |
| lookup_native_hot | baseline | 18 | 2000 | 482489 | 241.2445 | 0 |
| lookup_tool_redirect | baseline | 18 | 2000 | 500100 | 250.05 | 0 |
| access_tool_redirect | baseline | 18 | 2000 | 388829 | 194.4145 | 0 |
| build_tree_stat_walk | baseline | 18 | 1984 | 649353 | 327.29485887096774 | 0 |
| open_tool_redirect | baseline | 19 | 2000 | 931346 | 465.673 | 0 |
| build_tree_stat_walk | baseline | 19 | 1984 | 646410 | 325.81149193548384 | 0 |
| exec_tool_redirect | baseline | 19 | 20 | 1312761 | 65638.05 | 0 |
| access_tool_redirect | baseline | 19 | 2000 | 406860 | 203.43 | 0 |
| readdir_alias_view | baseline | 19 | 500 | 105097 | 210.194 | 0 |
| lookup_native_hot | baseline | 19 | 2000 | 489175 | 244.5875 | 0 |
| lookup_tool_redirect | baseline | 19 | 2000 | 482132 | 241.066 | 0 |
| access_tool_redirect | pass_only | 0 | 2000 | 728795 | 364.3975 | 0 |
| lookup_native_hot | pass_only | 0 | 2000 | 778144 | 389.072 | 0 |
| open_tool_redirect | pass_only | 0 | 2000 | 1316102 | 658.051 | 0 |
| exec_tool_redirect | pass_only | 0 | 20 | 1226008 | 61300.4 | 0 |
| lookup_tool_redirect | pass_only | 0 | 2000 | 792030 | 396.015 | 0 |
| readdir_alias_view | pass_only | 0 | 500 | 140341 | 280.682 | 0 |
| build_tree_stat_walk | pass_only | 0 | 1984 | 1155911 | 582.6164314516129 | 0 |
| access_tool_redirect | pass_only | 1 | 2000 | 688658 | 344.329 | 0 |
| lookup_native_hot | pass_only | 1 | 2000 | 797524 | 398.762 | 0 |
| open_tool_redirect | pass_only | 1 | 2000 | 1337040 | 668.52 | 0 |
| readdir_alias_view | pass_only | 1 | 500 | 143874 | 287.748 | 0 |
| exec_tool_redirect | pass_only | 1 | 20 | 1365257 | 68262.85 | 0 |
| build_tree_stat_walk | pass_only | 1 | 1984 | 1142760 | 575.9879032258065 | 0 |
| lookup_tool_redirect | pass_only | 1 | 2000 | 807308 | 403.654 | 0 |
| lookup_native_hot | pass_only | 2 | 2000 | 808751 | 404.3755 | 0 |
| lookup_tool_redirect | pass_only | 2 | 2000 | 811959 | 405.9795 | 0 |
| access_tool_redirect | pass_only | 2 | 2000 | 687690 | 343.845 | 0 |
| exec_tool_redirect | pass_only | 2 | 20 | 1291136 | 64556.8 | 0 |
| readdir_alias_view | pass_only | 2 | 500 | 138181 | 276.362 | 0 |
| open_tool_redirect | pass_only | 2 | 2000 | 1320567 | 660.2835 | 0 |
| build_tree_stat_walk | pass_only | 2 | 1984 | 1139816 | 574.5040322580645 | 0 |
| build_tree_stat_walk | pass_only | 3 | 1984 | 1173979 | 591.7232862903226 | 0 |
| lookup_native_hot | pass_only | 3 | 2000 | 822120 | 411.06 | 0 |
| readdir_alias_view | pass_only | 3 | 500 | 134758 | 269.516 | 0 |
| access_tool_redirect | pass_only | 3 | 2000 | 703067 | 351.5335 | 0 |
| exec_tool_redirect | pass_only | 3 | 20 | 1257554 | 62877.7 | 0 |
| open_tool_redirect | pass_only | 3 | 2000 | 1326112 | 663.056 | 0 |
| lookup_tool_redirect | pass_only | 3 | 2000 | 776172 | 388.086 | 0 |
| access_tool_redirect | pass_only | 4 | 2000 | 725391 | 362.6955 | 0 |
| lookup_tool_redirect | pass_only | 4 | 2000 | 779054 | 389.527 | 0 |
| build_tree_stat_walk | pass_only | 4 | 1984 | 1152650 | 580.9727822580645 | 0 |
| exec_tool_redirect | pass_only | 4 | 20 | 1258835 | 62941.75 | 0 |
| lookup_native_hot | pass_only | 4 | 2000 | 796056 | 398.028 | 0 |
| open_tool_redirect | pass_only | 4 | 2000 | 1335903 | 667.9515 | 0 |
| readdir_alias_view | pass_only | 4 | 500 | 148749 | 297.498 | 0 |
| access_tool_redirect | pass_only | 5 | 2000 | 688413 | 344.2065 | 0 |
| exec_tool_redirect | pass_only | 5 | 20 | 1283760 | 64188 | 0 |
| lookup_tool_redirect | pass_only | 5 | 2000 | 775167 | 387.5835 | 0 |
| build_tree_stat_walk | pass_only | 5 | 1984 | 1168773 | 589.0992943548387 | 0 |
| readdir_alias_view | pass_only | 5 | 500 | 148106 | 296.212 | 0 |
| open_tool_redirect | pass_only | 5 | 2000 | 1304453 | 652.2265 | 0 |
| lookup_native_hot | pass_only | 5 | 2000 | 772926 | 386.463 | 0 |
| lookup_tool_redirect | pass_only | 6 | 2000 | 801130 | 400.565 | 0 |
| access_tool_redirect | pass_only | 6 | 2000 | 709221 | 354.6105 | 0 |
| readdir_alias_view | pass_only | 6 | 500 | 135336 | 270.672 | 0 |
| open_tool_redirect | pass_only | 6 | 2000 | 1345440 | 672.72 | 0 |
| lookup_native_hot | pass_only | 6 | 2000 | 777519 | 388.7595 | 0 |
| exec_tool_redirect | pass_only | 6 | 20 | 1259880 | 62994 | 0 |
| build_tree_stat_walk | pass_only | 6 | 1984 | 1156879 | 583.1043346774194 | 0 |
| lookup_native_hot | pass_only | 7 | 2000 | 811606 | 405.803 | 0 |
| open_tool_redirect | pass_only | 7 | 2000 | 1329672 | 664.836 | 0 |
| build_tree_stat_walk | pass_only | 7 | 1984 | 1145306 | 577.2711693548387 | 0 |
| access_tool_redirect | pass_only | 7 | 2000 | 702390 | 351.195 | 0 |
| exec_tool_redirect | pass_only | 7 | 20 | 1237727 | 61886.35 | 0 |
| readdir_alias_view | pass_only | 7 | 500 | 153898 | 307.796 | 0 |
| lookup_tool_redirect | pass_only | 7 | 2000 | 822836 | 411.418 | 0 |
| access_tool_redirect | pass_only | 8 | 2000 | 693755 | 346.8775 | 0 |
| open_tool_redirect | pass_only | 8 | 2000 | 1316547 | 658.2735 | 0 |
| build_tree_stat_walk | pass_only | 8 | 1984 | 1132510 | 570.8215725806451 | 0 |
| exec_tool_redirect | pass_only | 8 | 20 | 1375716 | 68785.8 | 0 |
| readdir_alias_view | pass_only | 8 | 500 | 150584 | 301.168 | 0 |
| lookup_tool_redirect | pass_only | 8 | 2000 | 782613 | 391.3065 | 0 |
| lookup_native_hot | pass_only | 8 | 2000 | 776663 | 388.3315 | 0 |
| access_tool_redirect | pass_only | 9 | 2000 | 702594 | 351.297 | 0 |
| build_tree_stat_walk | pass_only | 9 | 1984 | 1181615 | 595.5720766129032 | 0 |
| readdir_alias_view | pass_only | 9 | 500 | 144607 | 289.214 | 0 |
| lookup_native_hot | pass_only | 9 | 2000 | 814886 | 407.443 | 0 |
| exec_tool_redirect | pass_only | 9 | 20 | 1239476 | 61973.8 | 0 |
| lookup_tool_redirect | pass_only | 9 | 2000 | 815192 | 407.596 | 0 |
| open_tool_redirect | pass_only | 9 | 2000 | 1311960 | 655.98 | 0 |
| lookup_native_hot | pass_only | 10 | 2000 | 778191 | 389.0955 | 0 |
| lookup_tool_redirect | pass_only | 10 | 2000 | 802688 | 401.344 | 0 |
| exec_tool_redirect | pass_only | 10 | 20 | 1217235 | 60861.75 | 0 |
| readdir_alias_view | pass_only | 10 | 500 | 146672 | 293.344 | 0 |
| access_tool_redirect | pass_only | 10 | 2000 | 717817 | 358.9085 | 0 |
| open_tool_redirect | pass_only | 10 | 2000 | 1307557 | 653.7785 | 0 |
| build_tree_stat_walk | pass_only | 10 | 1984 | 1155691 | 582.5055443548387 | 0 |
| build_tree_stat_walk | pass_only | 11 | 1984 | 1137113 | 573.1416330645161 | 0 |
| readdir_alias_view | pass_only | 11 | 500 | 145225 | 290.45 | 0 |
| exec_tool_redirect | pass_only | 11 | 20 | 1306939 | 65346.95 | 0 |
| access_tool_redirect | pass_only | 11 | 2000 | 744561 | 372.2805 | 0 |
| open_tool_redirect | pass_only | 11 | 2000 | 1316017 | 658.0085 | 0 |
| lookup_tool_redirect | pass_only | 11 | 2000 | 796121 | 398.0605 | 0 |
| lookup_native_hot | pass_only | 11 | 2000 | 807378 | 403.689 | 0 |
| lookup_native_hot | pass_only | 12 | 2000 | 779877 | 389.9385 | 0 |
| readdir_alias_view | pass_only | 12 | 500 | 142352 | 284.704 | 0 |
| exec_tool_redirect | pass_only | 12 | 20 | 1204099 | 60204.95 | 0 |
| lookup_tool_redirect | pass_only | 12 | 2000 | 801939 | 400.9695 | 0 |
| access_tool_redirect | pass_only | 12 | 2000 | 711090 | 355.545 | 0 |
| build_tree_stat_walk | pass_only | 12 | 1984 | 1135876 | 572.5181451612904 | 0 |
| open_tool_redirect | pass_only | 12 | 2000 | 1345152 | 672.576 | 0 |
| exec_tool_redirect | pass_only | 13 | 20 | 1302386 | 65119.3 | 0 |
| readdir_alias_view | pass_only | 13 | 500 | 148171 | 296.342 | 0 |
| access_tool_redirect | pass_only | 13 | 2000 | 698750 | 349.375 | 0 |
| build_tree_stat_walk | pass_only | 13 | 1984 | 1137316 | 573.2439516129032 | 0 |
| lookup_native_hot | pass_only | 13 | 2000 | 808317 | 404.1585 | 0 |
| lookup_tool_redirect | pass_only | 13 | 2000 | 810035 | 405.0175 | 0 |
| open_tool_redirect | pass_only | 13 | 2000 | 1314486 | 657.243 | 0 |
| access_tool_redirect | pass_only | 14 | 2000 | 730523 | 365.2615 | 0 |
| open_tool_redirect | pass_only | 14 | 2000 | 1310763 | 655.3815 | 0 |
| lookup_tool_redirect | pass_only | 14 | 2000 | 776507 | 388.2535 | 0 |
| exec_tool_redirect | pass_only | 14 | 20 | 1486098 | 74304.9 | 0 |
| lookup_native_hot | pass_only | 14 | 2000 | 787424 | 393.712 | 0 |
| readdir_alias_view | pass_only | 14 | 500 | 148453 | 296.906 | 0 |
| build_tree_stat_walk | pass_only | 14 | 1984 | 1132632 | 570.883064516129 | 0 |
| lookup_tool_redirect | pass_only | 15 | 2000 | 802613 | 401.3065 | 0 |
| readdir_alias_view | pass_only | 15 | 500 | 143621 | 287.242 | 0 |
| open_tool_redirect | pass_only | 15 | 2000 | 1335386 | 667.693 | 0 |
| build_tree_stat_walk | pass_only | 15 | 1984 | 1176920 | 593.2056451612904 | 0 |
| access_tool_redirect | pass_only | 15 | 2000 | 731260 | 365.63 | 0 |
| exec_tool_redirect | pass_only | 15 | 20 | 1335316 | 66765.8 | 0 |
| lookup_native_hot | pass_only | 15 | 2000 | 810697 | 405.3485 | 0 |
| exec_tool_redirect | pass_only | 16 | 20 | 1203771 | 60188.55 | 0 |
| access_tool_redirect | pass_only | 16 | 2000 | 735160 | 367.58 | 0 |
| build_tree_stat_walk | pass_only | 16 | 1984 | 1135006 | 572.0796370967741 | 0 |
| lookup_tool_redirect | pass_only | 16 | 2000 | 826885 | 413.4425 | 0 |
| readdir_alias_view | pass_only | 16 | 500 | 154486 | 308.972 | 0 |
| lookup_native_hot | pass_only | 16 | 2000 | 776931 | 388.4655 | 0 |
| open_tool_redirect | pass_only | 16 | 2000 | 1332961 | 666.4805 | 0 |
| access_tool_redirect | pass_only | 17 | 2000 | 689870 | 344.935 | 0 |
| build_tree_stat_walk | pass_only | 17 | 1984 | 1134505 | 571.8271169354839 | 0 |
| lookup_tool_redirect | pass_only | 17 | 2000 | 797229 | 398.6145 | 0 |
| open_tool_redirect | pass_only | 17 | 2000 | 1305205 | 652.6025 | 0 |
| lookup_native_hot | pass_only | 17 | 2000 | 810003 | 405.0015 | 0 |
| exec_tool_redirect | pass_only | 17 | 20 | 1479025 | 73951.25 | 0 |
| readdir_alias_view | pass_only | 17 | 500 | 146276 | 292.552 | 0 |
| lookup_native_hot | pass_only | 18 | 2000 | 777284 | 388.642 | 0 |
| open_tool_redirect | pass_only | 18 | 2000 | 1342560 | 671.28 | 0 |
| access_tool_redirect | pass_only | 18 | 2000 | 724289 | 362.1445 | 0 |
| lookup_tool_redirect | pass_only | 18 | 2000 | 790200 | 395.1 | 0 |
| readdir_alias_view | pass_only | 18 | 500 | 146870 | 293.74 | 0 |
| build_tree_stat_walk | pass_only | 18 | 1984 | 1167963 | 588.6910282258065 | 0 |
| exec_tool_redirect | pass_only | 18 | 20 | 1322111 | 66105.55 | 0 |
| exec_tool_redirect | pass_only | 19 | 20 | 1192662 | 59633.1 | 0 |
| open_tool_redirect | pass_only | 19 | 2000 | 1321124 | 660.562 | 0 |
| build_tree_stat_walk | pass_only | 19 | 1984 | 1157110 | 583.2207661290323 | 0 |
| lookup_tool_redirect | pass_only | 19 | 2000 | 808041 | 404.0205 | 0 |
| access_tool_redirect | pass_only | 19 | 2000 | 688951 | 344.4755 | 0 |
| lookup_native_hot | pass_only | 19 | 2000 | 814221 | 407.1105 | 0 |
| readdir_alias_view | pass_only | 19 | 500 | 146457 | 292.914 | 0 |

## Microbenchmark Latency Samples
| Benchmark | Variant | Sample | Latency Sample | Ops | Elapsed ns | ns/op | Fail |
|---|---|---:|---:|---:|---:|---:|---:|

## Raw Artifacts
- `guest-smoke.jsonl`
- `abi.jsonl`
- `policy-load.jsonl`
- `policy-semantic.jsonl`
- `table-conformance.jsonl`
- `table-budget.jsonl`
- `table-budget-inputs.sha256`
- `w1-oracle.jsonl`
- `w1-oracle-inputs.sha256`
- `/home/yunwei37/workspace/namei_ext/results/workloads/runs/20260615T-full-phase1-c2-release-sample-v1/w1-build-output-oracle.jsonl`
- `w1-build-replay.jsonl`
- `w1-build-replay-inputs.sha256`
- `w1-build-replay-outputs.sha256`
- `w1-release-build-replay.jsonl`
- `w1-release-build-replay-inputs.sha256`
- `w1-release-build-replay-outputs.sha256`
- `w1-branch-probes.jsonl`
- `w1-branch-probes-inputs.sha256`
- `w2-oracle.jsonl`
- `w2-oracle-inputs.sha256`
- `w2-nginx-real.jsonl`
- `w2-nginx-real-inputs.sha256`
- `w3-oracle.jsonl`
- `w3-oracle-inputs.sha256`
- `w3-redis-replay.jsonl`
- `w3-redis-replay-inputs.sha256`
- `w3-redis-table-replay.jsonl`
- `w3-redis-table-replay-inputs.sha256`
- `w3-redis-counterfactual.jsonl`
- `w3-redis-counterfactual-inputs.sha256`
- `w4-oracle.jsonl`
- `w4-oracle-inputs.sha256`
- `w4-cache-content.jsonl`
- `w4-cache-content-inputs.sha256`
- `w4-cache-table-content.jsonl`
- `w4-cache-table-content-inputs.sha256`
- `w4-ccache-real.jsonl`
- `w4-ccache-real-inputs.sha256`
- `w4-ccache-real-outputs.sha256`
- `w4-ccache-real-stats.txt`
- `w4-ccache-real-entries.tsv`
- `w4-ccache-trace.jsonl`
- `w4-ccache-trace-inputs.sha256`
- `w4-ccache-trace-artifacts.sha256`
- `w4-ccache-trace-stats.txt`
- `w4-ccache-trace-ccache.path`
- `w4-ccache-trace-strace.path`
- `w4-ccache-trace-ccache.version`
- `w4-ccache-trace-strace.version`
- `w4-ccache-trace-redis.strace.log`
- `w4-ccache-trace-nginx.strace.log`
- `w4-ccache-policy-bridge.jsonl`
- `w4-ccache-policy-bridge-inputs.sha256`
- `w4-ccache-policy-bridge-trace-objects.txt`
- `w4-ccache-policy-bridge-entries.tsv`
- `w4-ccache-policy-compile.jsonl`
- `w4-ccache-policy-compile-inputs.sha256`
- `w4-ccache-policy-compile-outputs.sha256`
- `w4-ccache-policy-compile-stats.txt`
- `w4-ccache-policy-compile-ccache.path`
- `w4-ccache-policy-compile-ccache.version`
- `w4-ccache-parent-compile.jsonl`
- `w4-ccache-parent-compile-inputs.sha256`
- `w4-ccache-parent-compile-outputs.sha256`
- `w4-ccache-parent-compile-stats.txt`
- `w4-ccache-parent-compile-ccache.path`
- `w4-ccache-parent-compile-ccache.version`
- `w4-ccache-table-compile.jsonl`
- `w4-ccache-table-compile-inputs.sha256`
- `w4-ccache-table-compile-outputs.sha256`
- `w4-ccache-table-compile-stats.txt`
- `w4-ccache-table-compile-ccache.path`
- `w4-ccache-table-compile-ccache.version`
- `w4-ccache-release-counterfactual.jsonl`
- `w4-ccache-release-counterfactual-inputs.sha256`
- `functional.jsonl`
- `bench.jsonl`
- `docker.jsonl`
- `metadata.json`
- `main-repo-head.txt`
- `main-repo-status.txt`
- `kernel-repo-head.txt`
- `kernel-repo-status.txt`
- `kernel-image.sha256`
- `docker-image-tar.sha256`
- `docker-image-id.txt`
- `kernel-config.sha256`
- `kernel-config-fragment.sha256`
- `benchmark-config.sha256`
- `kvm-config.sha256`
- `project-config.sha256`
- `host-cpu.txt`
- `kernel.config`
- `kernel-cmdline.txt`
- `dmesg-smoke.log`
- `dmesg-policy-load.log`
- `dmesg-policy-semantic.log`
- `dmesg-w1-oracle.log`
- `dmesg-w1-build-replay.log`
- `dmesg-w1-release-build-replay.log`
- `dmesg-w1-branch-probes.log`
- `dmesg-w2-oracle.log`
- `dmesg-w2-nginx-real.log`
- `dmesg-w3-oracle.log`
- `dmesg-w3-redis-replay.log`
- `dmesg-w3-redis-table-replay.log`
- `dmesg-w3-redis-counterfactual.log`
- `dmesg-w4-oracle.log`
- `dmesg-w4-cache-content.log`
- `dmesg-w4-cache-table-content.log`
- `dmesg-w4-ccache-real.log`
- `dmesg-w4-ccache-trace.log`
- `dmesg-w4-ccache-policy-bridge.log`
- `dmesg-w4-ccache-policy-compile.log`
- `dmesg-w4-ccache-parent-compile.log`
- `dmesg-w4-ccache-table-compile.log`
- `dmesg-w4-ccache-release-counterfactual.log`
- `dmesg-functional.log`
- `dmesg-bench.log`
