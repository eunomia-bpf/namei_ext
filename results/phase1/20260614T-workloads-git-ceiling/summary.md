# Phase 1 Report

- Date: 2026-06-14
- Scope: KVM smoke, policy load/semantic validation, table conformance, W1 trace-derived path oracle, W2 fixture path oracle, W2 real nginx endpoint health oracle, W3 checkpoint path oracle, W4 cache path oracle, functional policy validation, and smoke-scale microbenchmarks
- Kernel image: /home/yunwei37/workspace/namei_ext/.build/kernel/arch/x86/boot/bzImage
- Kernel sha256: 0b465b88272a9ae6fac2cc9af838bf33891508c2fa1a4c2b99257dea03c58228
- Main repo HEAD: 6fe308aa3a16a9ea160f634f60ed76427dcc1b7c
- Main repo dirty: true
- Kernel repo HEAD: 31a33d22c2122f0db82553fc5325cfc273fe22e0
- Kernel repo dirty: false
- Result directory: /home/yunwei37/workspace/namei_ext/results/phase1/20260614T-workloads-git-ceiling
- Samples: 1
- Benchmark iterations: 2000
- Benchmark config sha256: 596f0c991c5b145e341764d7a3042dadfd3d29f38be8c4e918ec61ef9900ece5
- W1 oracle input sha256 file: w1-oracle-inputs.sha256
- W2 oracle input sha256 file: w2-oracle-inputs.sha256
- W2 nginx real input sha256 file: w2-nginx-real-inputs.sha256
- W3 oracle input sha256 file: w3-oracle-inputs.sha256
- W4 oracle input sha256 file: w4-oracle-inputs.sha256
- Docker image tar sha256: 5c97582d0ea5701149486dca006aa947a5c48b16f17d5806a16f5024fbb1a778
- Docker image ID: sha256:4810e9e6a5007ec7adcae6bfcd32fef3b576bd7707b26bcd84313a9264be58f7

## Gates
- Guest smoke events: 2
- ABI failing cases: 0
- Policy-load failing cases: 0
- Policy-semantic failing cases: 0
- Policy-semantic summary failures: 0
- Table-conformance failing cases: 0
- W1 oracle failing cases: 0
- W1 oracle summary failures: 0
- W2 oracle failing cases: 0
- W2 oracle summary failures: 0
- W2 nginx real-app failing cases: 0
- W2 nginx real-app summary failures: 0
- W3 oracle failing cases: 0
- W3 oracle summary failures: 0
- W4 oracle failing cases: 0
- W4 oracle summary failures: 0
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

## W2 Nginx Real App Endpoint Health Oracle Cases
| Op | Pass | Exit Code | Detail | Stdout | Stderr |
|---|---:|---:|---|---|---|
| materialize | true | 0 | nginx prefix materialized from workload fixture config and endpoint fixture |  |  |
| pre_attach_nginx_test | true | 1 | nginx rejected missing alias before attach | /home/yunwei37/workspace/namei_ext/results/phase1/20260614T-workloads-git-ceiling/w2-nginx-real-app/pre-attach.stdout | /home/yunwei37/workspace/namei_ext/results/phase1/20260614T-workloads-git-ceiling/w2-nginx-real-app/pre-attach.stderr |
| load | true | 0 | sandbox policy loaded |  |  |
| policy_state | true | 0 | literal nginx.conf and upstream.sock redirects active |  |  |
| attach | true | 0 | sandbox policy attached |  |  |
| attached_nginx_test | true | 0 | nginx accepted redirected workload fixture config | /home/yunwei37/workspace/namei_ext/results/phase1/20260614T-workloads-git-ceiling/w2-nginx-real-app/attached.stdout | /home/yunwei37/workspace/namei_ext/results/phase1/20260614T-workloads-git-ceiling/w2-nginx-real-app/attached.stderr |
| attached_nginx_start | true | 0 | nginx daemon started with redirected config | /home/yunwei37/workspace/namei_ext/results/phase1/20260614T-workloads-git-ceiling/w2-nginx-real-app/attached-start.stdout | /home/yunwei37/workspace/namei_ext/results/phase1/20260614T-workloads-git-ceiling/w2-nginx-real-app/attached-start.stderr |
| attached_upstream_start | true | 0 | local upstream endpoint listening on 127.0.0.1:18080 |  |  |
| attached_http_health | true | 0 | nginx HTTP health returned expected body | /home/yunwei37/workspace/namei_ext/results/phase1/20260614T-workloads-git-ceiling/w2-nginx-real-app/attached-health.response |  |
| attached_endpoint_upstream | true | 0 | local upstream endpoint served nginx request through redirected include |  |  |
| attached_nginx_quit | true | 0 | nginx quit command succeeded | /home/yunwei37/workspace/namei_ext/results/phase1/20260614T-workloads-git-ceiling/w2-nginx-real-app/attached-quit.stdout | /home/yunwei37/workspace/namei_ext/results/phase1/20260614T-workloads-git-ceiling/w2-nginx-real-app/attached-quit.stderr |
| detach | true | 0 | sandbox policy detached |  |  |
| post_detach_nginx_test | true | 1 | nginx rejected alias after detach | /home/yunwei37/workspace/namei_ext/results/phase1/20260614T-workloads-git-ceiling/w2-nginx-real-app/post-detach.stdout | /home/yunwei37/workspace/namei_ext/results/phase1/20260614T-workloads-git-ceiling/w2-nginx-real-app/post-detach.stderr |

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

## W4 Cache Path Oracle Cases
| Policy | Workload | Branch | Visible | Effective Shadow | Op | Pass | Errno | Detail |
|---|---|---|---|---|---|---:|---:|---|
| cache_locality | w4-ccache-redis-nginx | verified_hit | object.o | object.local | pre_attach_absent | true | 0 | alias absent before attach |
| cache_locality | w4-ccache-redis-nginx | stale_fallback | stale.o | stale.canon | pre_attach_absent | true | 0 | alias absent before attach |
| cache_locality | w4-ccache-redis-nginx | corrupt_reject | corrupt.o | corrupt.reject | pre_attach_absent | true | 0 | alias absent before attach |
| cache_locality | w4-buildkit-prometheus-go-cache | miss_canonical | pkg.mod | pkg.canon | pre_attach_absent | true | 0 | alias absent before attach |
| cache_locality |  |  |  |  | load | true | 0 | policy loaded |
| cache_locality |  |  |  |  | policy_state | true | 0 | literal cache-state rules active |
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
| lookup_native_hot | baseline | 0 | 2000 | 477958 | 238.979 | 0 |
| lookup_tool_redirect | baseline | 0 | 2000 | 478271 | 239.1355 | 0 |
| access_tool_redirect | baseline | 0 | 2000 | 392999 | 196.4995 | 0 |
| open_tool_redirect | baseline | 0 | 2000 | 936944 | 468.472 | 0 |
| exec_tool_redirect | baseline | 0 | 20 | 1467725 | 73386.25 | 0 |
| readdir_alias_view | baseline | 0 | 500 | 103087 | 206.174 | 0 |
| build_tree_stat_walk | baseline | 0 | 1984 | 694824 | 350.21370967741933 | 0 |
| lookup_native_hot | policy | 0 | 2000 | 714183 | 357.0915 | 0 |
| lookup_tool_redirect | policy | 0 | 2000 | 733569 | 366.7845 | 0 |
| access_tool_redirect | policy | 0 | 2000 | 643675 | 321.8375 | 0 |
| open_tool_redirect | policy | 0 | 2000 | 1285834 | 642.917 | 0 |
| exec_tool_redirect | policy | 0 | 20 | 1460483 | 73024.15 | 0 |
| readdir_alias_view | policy | 0 | 500 | 145347 | 290.694 | 0 |
| build_tree_stat_walk | policy | 0 | 1984 | 1078636 | 543.6673387096774 | 0 |

## Raw Artifacts
- `guest-smoke.jsonl`
- `abi.jsonl`
- `policy-load.jsonl`
- `policy-semantic.jsonl`
- `table-conformance.jsonl`
- `w1-oracle.jsonl`
- `w1-oracle-inputs.sha256`
- `w2-oracle.jsonl`
- `w2-oracle-inputs.sha256`
- `w2-nginx-real.jsonl`
- `w2-nginx-real-inputs.sha256`
- `w3-oracle.jsonl`
- `w3-oracle-inputs.sha256`
- `w4-oracle.jsonl`
- `w4-oracle-inputs.sha256`
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
- `dmesg-w2-oracle.log`
- `dmesg-w2-nginx-real.log`
- `dmesg-w3-oracle.log`
- `dmesg-w4-oracle.log`
- `dmesg-functional.log`
- `dmesg-bench.log`
