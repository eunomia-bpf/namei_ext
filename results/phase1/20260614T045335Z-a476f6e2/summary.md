# Phase 1 Report

- Date: 2026-06-14
- Scope: KVM smoke, policy load/semantic validation, table conformance, functional policy validation, and smoke-scale microbenchmarks
- Kernel image: /home/yunwei37/workspace/namei_ext/.build/kernel/arch/x86/boot/bzImage
- Kernel sha256: 0b465b88272a9ae6fac2cc9af838bf33891508c2fa1a4c2b99257dea03c58228
- Main repo HEAD: 6fe308aa3a16a9ea160f634f60ed76427dcc1b7c
- Main repo dirty: true
- Kernel repo HEAD: 31a33d22c2122f0db82553fc5325cfc273fe22e0
- Kernel repo dirty: false
- Result directory: /home/yunwei37/workspace/namei_ext/results/phase1/20260614T045335Z-a476f6e2
- Samples: 1
- Benchmark iterations: 2000
- Benchmark config sha256: 596f0c991c5b145e341764d7a3042dadfd3d29f38be8c4e918ec61ef9900ece5
- Docker image tar sha256: d4209e964f5243b47403757be05dffbe79e5939bcf1eaa989c0eb2476663a317
- Docker image ID: sha256:68bcda015114ac37e4c89cac302b3f168ed16a905055e1d3494f6a96515ea71f

## Gates
- Guest smoke events: 2
- ABI failing cases: 0
- Policy-load failing cases: 0
- Policy-semantic failing cases: 0
- Policy-semantic summary failures: 0
- Table-conformance failing cases: 0
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
| lookup_native_hot | baseline | 0 | 2000 | 512589 | 256.2945 | 0 |
| lookup_tool_redirect | baseline | 0 | 2000 | 499480 | 249.74 | 0 |
| access_tool_redirect | baseline | 0 | 2000 | 422441 | 211.2205 | 0 |
| open_tool_redirect | baseline | 0 | 2000 | 963931 | 481.9655 | 0 |
| exec_tool_redirect | baseline | 0 | 20 | 1481094 | 74054.7 | 0 |
| readdir_alias_view | baseline | 0 | 500 | 109368 | 218.736 | 0 |
| build_tree_stat_walk | baseline | 0 | 1984 | 725086 | 365.46673387096774 | 0 |
| lookup_native_hot | policy | 0 | 2000 | 730116 | 365.058 | 0 |
| lookup_tool_redirect | policy | 0 | 2000 | 747419 | 373.7095 | 0 |
| access_tool_redirect | policy | 0 | 2000 | 646402 | 323.201 | 0 |
| open_tool_redirect | policy | 0 | 2000 | 1286086 | 643.043 | 0 |
| exec_tool_redirect | policy | 0 | 20 | 1152814 | 57640.7 | 0 |
| readdir_alias_view | policy | 0 | 500 | 136854 | 273.708 | 0 |
| build_tree_stat_walk | policy | 0 | 1984 | 1081514 | 545.1179435483871 | 0 |

## Raw Artifacts
- `guest-smoke.jsonl`
- `abi.jsonl`
- `policy-load.jsonl`
- `policy-semantic.jsonl`
- `table-conformance.jsonl`
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
- `dmesg-functional.log`
- `dmesg-bench.log`
