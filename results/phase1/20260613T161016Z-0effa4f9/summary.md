# Phase 1 Report

- Date: 2026-06-13
- Scope: KVM smoke, functional policy validation, and smoke-scale microbenchmarks
- Kernel image: /home/yunwei37/workspace/namei_ext/.build/kernel/arch/x86/boot/bzImage
- Kernel sha256: 55ef9d0cf142340e142f99ad69af3170bfd27b3d8310b010886cf4487500a72c
- Result directory: /home/yunwei37/workspace/namei_ext/results/phase1/20260613T161016Z-0effa4f9
- Samples: 1
- Benchmark iterations: 2000
- Docker image tar sha256: 86bd1c4ae452d958c159018b392eaaa65cdbecad8cd2e5512e0ee89e061158c4

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
| setup_files | true | 0 | files created |
| attach_policy | true | 0 | policy attached |
| visible_stat | true | 0 | stat matched |
| visible_open | true | 0 | open matched |
| hidden_stat | true | 2 | stat errno matched |
| hidden_open | true | 2 | open errno matched |
| denied_stat | true | 13 | stat errno matched |
| denied_open | true | 13 | open errno matched |
| readdir_view | true | 0 | visible and denied listed, hidden omitted |
| functional_summary | true | 0 | functional passed |

## Microbenchmarks
| Benchmark | Variant | Sample | Ops | Elapsed ns | ns/op | Fail |
|---|---|---:|---:|---:|---:|---:|
| lookup_visible_hot | baseline | 0 | 2000 | 719692 | 359.846 | 0 |
| lookup_hidden | baseline | 0 | 2000 | 713603 | 356.8015 | 0 |
| open_denied | baseline | 0 | 2000 | 1434526 | 717.263 | 0 |
| readdir_filter | baseline | 0 | 600 | 161097 | 268.495 | 0 |
| build_tree_stat_walk | baseline | 0 | 1984 | 949016 | 478.3346774193548 | 0 |
| lookup_visible_hot | policy | 0 | 2000 | 1048183 | 524.0915 | 0 |
| lookup_hidden | policy | 0 | 2000 | 768486 | 384.243 | 0 |
| open_denied | policy | 0 | 2000 | 931734 | 465.867 | 0 |
| readdir_filter | policy | 0 | 500 | 217174 | 434.348 | 0 |
| build_tree_stat_walk | policy | 0 | 1984 | 1441705 | 726.6658266129032 | 0 |

## Raw Artifacts
- `guest-smoke.jsonl`
- `abi.jsonl`
- `functional.jsonl`
- `bench.jsonl`
- `docker.jsonl`
- `kernel.config`
- `dmesg-smoke.log`
- `dmesg-functional.log`
- `dmesg-bench.log`
