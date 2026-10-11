# Phase 1 Report

- Date: 2026-06-13
- Scope: KVM smoke, functional policy validation, and smoke-scale microbenchmarks
- Kernel image: /home/yunwei37/workspace/namei_ext/.build/kernel/arch/x86/boot/bzImage
- Kernel sha256: 21b551c2cfb40ae659f2bcf5ec0ae27b8b8f0e2887121694c259c18303af9a2f
- Main repo HEAD: 4918f885367ba69246778e71f96814fd29de848a
- Main repo dirty: true
- Kernel repo HEAD: 062871f1371b2e02a272ff5279c6479aff0a37ef
- Kernel repo dirty: true
- Result directory: /home/yunwei37/workspace/namei_ext/results/phase1/20260613T182237Z-e34d8cfa
- Samples: 1
- Benchmark iterations: 2000
- Benchmark config sha256: 596f0c991c5b145e341764d7a3042dadfd3d29f38be8c4e918ec61ef9900ece5
- Docker image tar sha256: 78b09e81d8cde7197086e86e0b47cddbe7929bc9e66803379322cb729b958299
- Docker image ID: sha256:62c7cf026cb5f0ab03e7a89c5a8e9b595187cde6d57042c8d950db5b731479e5

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
| uapi_layout | true | enum values and ctx layout match Phase 1 ABI |
| bpf_layout | true | enum values and ctx layout match Phase 1 ABI |
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
| setup_files | true | 0 | files created |
| attach_policy | true | 0 | policy attached |
| visible_stat | true | 0 | stat matched |
| visible_open | true | 0 | open matched |
| visible_access | true | 0 | access matched |
| hidden_stat | true | 2 | stat errno matched |
| hidden_open | true | 2 | open errno matched |
| hidden_access | true | 2 | access errno matched |
| denied_stat | true | 13 | stat errno matched |
| denied_open | true | 13 | open errno matched |
| denied_access | true | 13 | access errno matched |
| denied_exec | true | 13 | execve errno matched |
| readdir_view | true | 0 | visible and denied listed, hidden omitted |
| detach_policy | true | 0 | policy detached |
| functional_summary | true | 0 | functional passed |

## Microbenchmarks
| Benchmark | Variant | Sample | Ops | Elapsed ns | ns/op | Fail |
|---|---|---:|---:|---:|---:|---:|
| lookup_visible_hot | baseline | 0 | 2000 | 446070 | 223.035 | 0 |
| lookup_hidden | baseline | 0 | 2000 | 444954 | 222.477 | 0 |
| access_hidden | baseline | 0 | 2000 | 367803 | 183.9015 | 0 |
| open_denied | baseline | 0 | 2000 | 903366 | 451.683 | 0 |
| exec_denied | baseline | 0 | 20 | 1099570 | 54978.5 | 0 |
| readdir_filter | baseline | 0 | 600 | 110927 | 184.87833333333333 | 0 |
| build_tree_stat_walk | baseline | 0 | 1984 | 609722 | 307.3195564516129 | 0 |
| lookup_visible_hot | policy | 0 | 2000 | 675707 | 337.8535 | 0 |
| lookup_hidden | policy | 0 | 2000 | 509599 | 254.7995 | 0 |
| access_hidden | policy | 0 | 2000 | 500563 | 250.2815 | 0 |
| open_denied | policy | 0 | 2000 | 628815 | 314.4075 | 0 |
| exec_denied | policy | 0 | 20 | 1005858 | 50292.9 | 0 |
| readdir_filter | policy | 0 | 500 | 142471 | 284.942 | 0 |
| build_tree_stat_walk | policy | 0 | 1984 | 940203 | 473.89264112903226 | 0 |

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
