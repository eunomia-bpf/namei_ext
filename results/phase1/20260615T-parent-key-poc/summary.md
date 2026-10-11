# Phase 1 Report

- Date: 2026-06-15
- Scope: KVM smoke, policy load/semantic validation, table conformance, W1 trace-derived path oracle, W1 KVM policy build replay witness, W1 KVM policy release binary replay witness, W1 build-graph poison/negative branch probes, W2 fixture path oracle, W2 real nginx endpoint health plus fixture content probes oracle, W3 checkpoint path oracle, W3 Redis checkpoint replay witness, W4 cache path oracle, W4 cache content oracle, W4 real ccache transition witness, W4 real ccache cache-path trace witness, W4 trace-derived ccache policy bridge, W4 real ccache policy-attached compile witness, W4 table-only ccache compile comparator, table-only budget accounting, functional policy validation, and smoke-scale microbenchmarks
- Kernel image: /home/yunwei37/workspace/namei_ext/.build/kernel/arch/x86/boot/bzImage
- Kernel sha256: a312a2bc8ff68aa1c6fc4b935fa4738810388de4385470b559603685b56460f3
- Main repo HEAD: 6fe308aa3a16a9ea160f634f60ed76427dcc1b7c
- Main repo dirty: true
- Kernel repo HEAD: 31a33d22c2122f0db82553fc5325cfc273fe22e0
- Kernel repo dirty: true
- Result directory: /home/yunwei37/workspace/namei_ext/results/phase1/20260615T-parent-key-poc
- Samples: 1
- Benchmark iterations: 2000
- Benchmark config sha256: 596f0c991c5b145e341764d7a3042dadfd3d29f38be8c4e918ec61ef9900ece5
- W1 oracle input sha256 file: w1-oracle-inputs.sha256
- W1 host build-output oracle: /home/yunwei37/workspace/namei_ext/results/workloads/runs/20260615T-parent-key-poc/w1-build-output-oracle.jsonl
- W1 KVM policy build replay input sha256 file: w1-build-replay-inputs.sha256
- W1 KVM policy build replay output sha256 file: w1-build-replay-outputs.sha256
- W1 KVM policy release build replay input sha256 file: w1-release-build-replay-inputs.sha256
- W1 KVM policy release build replay output sha256 file: w1-release-build-replay-outputs.sha256
- W1 KVM branch probes input sha256 file: w1-branch-probes-inputs.sha256
- W2 oracle input sha256 file: w2-oracle-inputs.sha256
- W2 nginx real input sha256 file: w2-nginx-real-inputs.sha256
- W3 oracle input sha256 file: w3-oracle-inputs.sha256
- W3 Redis checkpoint replay input sha256 file: w3-redis-replay-inputs.sha256
- W4 oracle input sha256 file: w4-oracle-inputs.sha256
- W4 cache content input sha256 file: w4-cache-content-inputs.sha256
- W4 real ccache input sha256 file: w4-ccache-real-inputs.sha256
- W4 real ccache output sha256 file: w4-ccache-real-outputs.sha256
- W4 real ccache trace input sha256 file: w4-ccache-trace-inputs.sha256
- W4 real ccache trace artifact sha256 file: w4-ccache-trace-artifacts.sha256
- W4 trace-derived ccache policy bridge input sha256 file: w4-ccache-policy-bridge-inputs.sha256
- W4 real ccache policy compile input sha256 file: w4-ccache-policy-compile-inputs.sha256
- W4 real ccache policy compile output sha256 file: w4-ccache-policy-compile-outputs.sha256
- W4 table-only ccache compile input sha256 file: w4-ccache-table-compile-inputs.sha256
- W4 table-only ccache compile output sha256 file: w4-ccache-table-compile-outputs.sha256
- Table-budget input sha256 file: table-budget-inputs.sha256
- Docker image tar sha256: 40d48963b5aa32d5bea36e2353863432ad77fa84b841a3481fa3381a3b6abfe3
- Docker image ID: sha256:337cededc95f29567924db8287927d526a63c061e5bf2fb94f81689217baa660

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
- W4 oracle failing cases: 0
- W4 oracle summary failures: 0
- W4 cache content failing cases: 0
- W4 cache content summary failures: 0
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
- Table-budget failing accounting rows: 0
- Table-budget current oracle passes: 4
- Table-budget C8-qualified rows: 0
- Functional failing cases: 0
- Benchmark failing operations: 0
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
| w1-redis-build | true | false | false | 57c5b7bce18d1db7d3ef3e5176d2fbbf7076749574906c76acf75246b53b3087 | 1224839 | false | host real Redis source build produced auditable binary hashes; this is not KVM policy replay |
| w1-nginx-build | true | false | false | 157d4e22b3daa1236fb0505a867e43938da340c03d498bd5df55f289af0466d3 | 1796476 | false | host real nginx source build produced auditable binary hashes; this is not KVM policy replay |

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
| pre_attach_nginx_test | true | 1 | nginx rejected missing alias before attach | /home/yunwei37/workspace/namei_ext/results/phase1/20260615T-parent-key-poc/w2-nginx-real-app/pre-attach.stdout | /home/yunwei37/workspace/namei_ext/results/phase1/20260615T-parent-key-poc/w2-nginx-real-app/pre-attach.stderr |
| load | true | 0 | sandbox policy loaded |  |  |
| policy_state | true | 0 | literal nginx.conf and upstream.sock redirects active |  |  |
| attach | true | 0 | sandbox policy attached |  |  |
| attached_nginx_test | true | 0 | nginx accepted redirected workload fixture config | /home/yunwei37/workspace/namei_ext/results/phase1/20260615T-parent-key-poc/w2-nginx-real-app/attached.stdout | /home/yunwei37/workspace/namei_ext/results/phase1/20260615T-parent-key-poc/w2-nginx-real-app/attached.stderr |
| attached_config_fixture_probe | true | 0 | nginx.conf resolved to workload fixture config and not production config decoy |  |  |
| attached_endpoint_fixture_probe | true | 0 | upstream.sock resolved to local endpoint fixture and not production endpoint decoy |  |  |
| attached_fake_cert_probe | true | 0 | server.crt resolved to fake certificate fixture and not production certificate decoy |  |  |
| attached_fake_secret_probe | true | 0 | db.password resolved to fake secret fixture and not production secret decoy |  |  |
| attached_poison_probe | true | 0 | prod.token resolved to poison sentinel and not production token decoy |  |  |
| attached_nginx_start | true | 0 | nginx daemon started with redirected config | /home/yunwei37/workspace/namei_ext/results/phase1/20260615T-parent-key-poc/w2-nginx-real-app/attached-start.stdout | /home/yunwei37/workspace/namei_ext/results/phase1/20260615T-parent-key-poc/w2-nginx-real-app/attached-start.stderr |
| attached_upstream_start | true | 0 | local upstream endpoint listening on 127.0.0.1:18080 |  |  |
| attached_http_health | true | 0 | nginx HTTP health returned expected body | /home/yunwei37/workspace/namei_ext/results/phase1/20260615T-parent-key-poc/w2-nginx-real-app/attached-health.response |  |
| attached_endpoint_upstream | true | 0 | local upstream endpoint served nginx request through redirected include |  |  |
| attached_nginx_quit | true | 0 | nginx quit command succeeded | /home/yunwei37/workspace/namei_ext/results/phase1/20260615T-parent-key-poc/w2-nginx-real-app/attached-quit.stdout | /home/yunwei37/workspace/namei_ext/results/phase1/20260615T-parent-key-poc/w2-nginx-real-app/attached-quit.stderr |
| detach | true | 0 | sandbox policy detached |  |  |
| post_detach_nginx_test | true | 1 | nginx rejected alias after detach | /home/yunwei37/workspace/namei_ext/results/phase1/20260615T-parent-key-poc/w2-nginx-real-app/post-detach.stdout | /home/yunwei37/workspace/namei_ext/results/phase1/20260615T-parent-key-poc/w2-nginx-real-app/post-detach.stderr |

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
| load | true | false | load | load | false | checkpoint policy loaded |
| attach | true | true | attach | attach | false | checkpoint policy attached |
| attached_get_checkpoint_value | true | true | checkpoint_restore_policy_loaded | $32\r\ncheckpoint_restore_policy_loaded\r\n | false | Redis loaded checkpoint value through visible dump.rdb |
| attached_readdir_alias | true | true | dump.rdb | dump.rdb | false | checkpoint backing appears as visible dump.rdb while attached |
| detach | true | true | detach | detach | false | checkpoint policy detached |
| post_detach_get_empty | true | false | $-1 | $-1\r\n | false | Redis no longer loaded hidden checkpoint after detach |

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
| setup | read_entries | true | 0 | /home/yunwei37/workspace/namei_ext/results/workloads/runs/20260615T-parent-key-poc/w4-cache-oracle-entries.tsv |  | W4 cache oracle TSV loaded |
| setup | materialize | true | 0 | /home/yunwei37/workspace/namei_ext/results/workloads/runs/20260615T-parent-key-poc/w4-cache-oracle-entries.tsv | /home/yunwei37/workspace/namei_ext/results/phase1/20260615T-parent-key-poc/w4-cache-content-work | manifest-derived cache content workdir materialized |
| verified_hit | pre_attach_absent | true | 0 | ENOENT | /home/yunwei37/workspace/namei_ext/results/phase1/20260615T-parent-key-poc/w4-cache-content-work/cache/object.o | visible cache alias absent |
| stale_fallback | pre_attach_absent | true | 0 | ENOENT | /home/yunwei37/workspace/namei_ext/results/phase1/20260615T-parent-key-poc/w4-cache-content-work/cache/stale.o | visible cache alias absent |
| corrupt_reject | pre_attach_absent | true | 0 | ENOENT | /home/yunwei37/workspace/namei_ext/results/phase1/20260615T-parent-key-poc/w4-cache-content-work/cache/corrupt.o | visible cache alias absent |
| miss_canonical | pre_attach_absent | true | 0 | ENOENT | /home/yunwei37/workspace/namei_ext/results/phase1/20260615T-parent-key-poc/w4-cache-content-work/gomod/pkg.mod | visible cache alias absent |
| setup | current_cgroup_id | true | 0 | /sys/fs/cgroup |  | current cgroup id resolved |
| setup | load | true | 0 | /home/yunwei37/workspace/namei_ext/.build/bpf/cache_locality_view.bpf.o |  | cache-locality policy loaded |
| setup | map_update | true | 0 | /home/yunwei37/workspace/namei_ext/results/workloads/runs/20260615T-parent-key-poc/w4-cache-oracle-entries.tsv |  | cache_rules populated from W4 TSV |
| setup | attach | true | 0 | /sys/fs/cgroup |  | cache-locality policy attached |
| verified_hit | attached_expected_match | true | 0 | object.local | /home/yunwei37/workspace/namei_ext/results/phase1/20260615T-parent-key-poc/w4-cache-content-work/cache/object.o | visible alias matched expected backing |
| verified_hit | attached_forbidden_mismatch | true | 0 | object.bad | /home/yunwei37/workspace/namei_ext/results/phase1/20260615T-parent-key-poc/w4-cache-content-work/cache/object.o | visible alias did not match forbidden cache content |
| stale_fallback | attached_expected_match | true | 0 | stale.canon | /home/yunwei37/workspace/namei_ext/results/phase1/20260615T-parent-key-poc/w4-cache-content-work/cache/stale.o | visible alias matched expected backing |
| stale_fallback | attached_forbidden_mismatch | true | 0 | stale.local | /home/yunwei37/workspace/namei_ext/results/phase1/20260615T-parent-key-poc/w4-cache-content-work/cache/stale.o | visible alias did not match forbidden cache content |
| corrupt_reject | attached_expected_match | true | 0 | corrupt.reject | /home/yunwei37/workspace/namei_ext/results/phase1/20260615T-parent-key-poc/w4-cache-content-work/cache/corrupt.o | visible alias matched expected backing |
| corrupt_reject | attached_forbidden_mismatch | true | 0 | corrupt.local | /home/yunwei37/workspace/namei_ext/results/phase1/20260615T-parent-key-poc/w4-cache-content-work/cache/corrupt.o | visible alias did not match forbidden cache content |
| miss_canonical | attached_expected_match | true | 0 | pkg.canon | /home/yunwei37/workspace/namei_ext/results/phase1/20260615T-parent-key-poc/w4-cache-content-work/gomod/pkg.mod | visible alias matched expected backing |
| verified_hit | readdir_alias | true | 0 | object.o | /home/yunwei37/workspace/namei_ext/results/phase1/20260615T-parent-key-poc/w4-cache-content-work/cache | cache alias visible and backing hidden |
| stale_fallback | readdir_alias | true | 0 | stale.o | /home/yunwei37/workspace/namei_ext/results/phase1/20260615T-parent-key-poc/w4-cache-content-work/cache | cache alias visible and backing hidden |
| corrupt_reject | readdir_alias | true | 0 | corrupt.o | /home/yunwei37/workspace/namei_ext/results/phase1/20260615T-parent-key-poc/w4-cache-content-work/cache | cache alias visible and backing hidden |
| miss_canonical | readdir_alias | true | 0 | pkg.mod | /home/yunwei37/workspace/namei_ext/results/phase1/20260615T-parent-key-poc/w4-cache-content-work/gomod | cache alias visible and backing hidden |
| setup | detach | true | 0 | /sys/fs/cgroup |  | cache-locality policy detached |
| verified_hit | post_detach_absent | true | 0 | ENOENT | /home/yunwei37/workspace/namei_ext/results/phase1/20260615T-parent-key-poc/w4-cache-content-work/cache/object.o | visible cache alias absent |
| stale_fallback | post_detach_absent | true | 0 | ENOENT | /home/yunwei37/workspace/namei_ext/results/phase1/20260615T-parent-key-poc/w4-cache-content-work/cache/stale.o | visible cache alias absent |
| corrupt_reject | post_detach_absent | true | 0 | ENOENT | /home/yunwei37/workspace/namei_ext/results/phase1/20260615T-parent-key-poc/w4-cache-content-work/cache/corrupt.o | visible cache alias absent |
| miss_canonical | post_detach_absent | true | 0 | ENOENT | /home/yunwei37/workspace/namei_ext/results/phase1/20260615T-parent-key-poc/w4-cache-content-work/gomod/pkg.mod | visible cache alias absent |

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

## W4 Table-Only Ccache Compile Comparator
KVM comparator in which the same sampled ccache hot compiles run under table_redirect exact redirects; a pass here is negative evidence for C8 on this sampled witness, so it remains not C8-qualified.
| Workload | Redirected Objects | Redis Objects | Nginx Objects | Direct Hits | Output Hash Match | Table Pass | Qualified For C8 | Detail |
|---|---:|---:|---:|---:|---:|---:|---:|---|
| w4-ccache-redis-nginx | 4 | 2 | 2 | 2 | true | true | false | table-only baseline consumed sampled ccache cache objects through exact redirects |

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
| lookup_native_hot | baseline | 0 | 2000 | 477965 | 238.9825 | 0 |
| lookup_tool_redirect | baseline | 0 | 2000 | 469422 | 234.711 | 0 |
| access_tool_redirect | baseline | 0 | 2000 | 384491 | 192.2455 | 0 |
| open_tool_redirect | baseline | 0 | 2000 | 935510 | 467.755 | 0 |
| exec_tool_redirect | baseline | 0 | 20 | 1306369 | 65318.45 | 0 |
| readdir_alias_view | baseline | 0 | 500 | 103219 | 206.438 | 0 |
| build_tree_stat_walk | baseline | 0 | 1984 | 661542 | 333.43850806451616 | 0 |
| lookup_native_hot | policy | 0 | 2000 | 750727 | 375.3635 | 0 |
| lookup_tool_redirect | policy | 0 | 2000 | 766778 | 383.389 | 0 |
| access_tool_redirect | policy | 0 | 2000 | 678083 | 339.0415 | 0 |
| open_tool_redirect | policy | 0 | 2000 | 1301234 | 650.617 | 0 |
| exec_tool_redirect | policy | 0 | 20 | 1291947 | 64597.35 | 0 |
| readdir_alias_view | policy | 0 | 500 | 141708 | 283.416 | 0 |
| build_tree_stat_walk | policy | 0 | 1984 | 1137712 | 573.4435483870968 | 0 |

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
- `/home/yunwei37/workspace/namei_ext/results/workloads/runs/20260615T-parent-key-poc/w1-build-output-oracle.jsonl`
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
- `w4-oracle.jsonl`
- `w4-oracle-inputs.sha256`
- `w4-cache-content.jsonl`
- `w4-cache-content-inputs.sha256`
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
- `w4-ccache-table-compile.jsonl`
- `w4-ccache-table-compile-inputs.sha256`
- `w4-ccache-table-compile-outputs.sha256`
- `w4-ccache-table-compile-stats.txt`
- `w4-ccache-table-compile-ccache.path`
- `w4-ccache-table-compile-ccache.version`
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
- `dmesg-w4-oracle.log`
- `dmesg-w4-cache-content.log`
- `dmesg-w4-ccache-real.log`
- `dmesg-w4-ccache-trace.log`
- `dmesg-w4-ccache-policy-bridge.log`
- `dmesg-w4-ccache-policy-compile.log`
- `dmesg-w4-ccache-table-compile.log`
- `dmesg-functional.log`
- `dmesg-bench.log`
