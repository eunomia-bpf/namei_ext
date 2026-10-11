# Phase 1 Report

- Date: 2026-06-13
- Scope: KVM smoke, functional policy validation, and smoke-scale microbenchmarks
- Kernel image: /home/yunwei37/workspace/namei_ext/.build/kernel/arch/x86/boot/bzImage
- Kernel sha256: 0b465b88272a9ae6fac2cc9af838bf33891508c2fa1a4c2b99257dea03c58228
- Main repo HEAD: 006b05e3e05e3cc9f530652cf6de64594a864215
- Main repo dirty: false
- Kernel repo HEAD: 31a33d22c2122f0db82553fc5325cfc273fe22e0
- Kernel repo dirty: false
- Result directory: /home/yunwei37/workspace/namei_ext/results/phase1/20260613T191523Z-28aebdb8
- Samples: 1
- Benchmark iterations: 2000
- Benchmark config sha256: 596f0c991c5b145e341764d7a3042dadfd3d29f38be8c4e918ec61ef9900ece5
- Docker image tar sha256: 4c1779f3a1d83b3f409ff4a2870f6c1e1224376ae4f23a8374c3126ddc94cedc
- Docker image ID: sha256:394e3297d157fc220808b50aa4b6a95f47f5f5de8da0270855e3bfc42d6510fd

## Gates
- Guest smoke events: 2
- ABI failing cases: 0
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
| lookup_native_hot | baseline | 0 | 2000 | 472107 | 236.0535 | 0 |
| lookup_tool_redirect | baseline | 0 | 2000 | 473768 | 236.884 | 0 |
| access_tool_redirect | baseline | 0 | 2000 | 388023 | 194.0115 | 0 |
| open_tool_redirect | baseline | 0 | 2000 | 950831 | 475.4155 | 0 |
| exec_tool_redirect | baseline | 0 | 20 | 1409333 | 70466.65 | 0 |
| readdir_alias_view | baseline | 0 | 500 | 106559 | 213.118 | 0 |
| build_tree_stat_walk | baseline | 0 | 1984 | 689113 | 347.3351814516129 | 0 |
| lookup_native_hot | policy | 0 | 2000 | 751703 | 375.8515 | 0 |
| lookup_tool_redirect | policy | 0 | 2000 | 737830 | 368.915 | 0 |
| access_tool_redirect | policy | 0 | 2000 | 655147 | 327.5735 | 0 |
| open_tool_redirect | policy | 0 | 2000 | 1276670 | 638.335 | 0 |
| exec_tool_redirect | policy | 0 | 20 | 1127025 | 56351.25 | 0 |
| readdir_alias_view | policy | 0 | 500 | 133010 | 266.02 | 0 |
| build_tree_stat_walk | policy | 0 | 1984 | 1075453 | 542.063004032258 | 0 |

## Raw Artifacts
- `guest-smoke.jsonl`
- `abi.jsonl`
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
- `dmesg-functional.log`
- `dmesg-bench.log`
