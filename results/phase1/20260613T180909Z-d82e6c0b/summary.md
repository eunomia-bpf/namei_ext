# Phase 1 Report

- Date: 2026-06-13
- Scope: KVM smoke, functional policy validation, and smoke-scale microbenchmarks
- Kernel image: /home/yunwei37/workspace/namei_ext/.build/kernel/arch/x86/boot/bzImage
- Kernel sha256: 2885791bab4ff7869233ed2db0d7aa9ae153f5a74d4031d64b0910db301c5118
- Result directory: /home/yunwei37/workspace/namei_ext/results/phase1/20260613T180909Z-d82e6c0b
- Samples: 1
- Benchmark iterations: 2000
- Docker image tar sha256: fbfdd7b3126e1971907dc21a49b5caa0fad6e916482ab7d9671da3d73291daf0

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
| multi_attach_rejected | true | 22 | multi attach rejected |
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
| lookup_visible_hot | baseline | 0 | 2000 | 451361 | 225.6805 | 0 |
| lookup_hidden | baseline | 0 | 2000 | 451408 | 225.704 | 0 |
| access_hidden | baseline | 0 | 2000 | 369493 | 184.7465 | 0 |
| open_denied | baseline | 0 | 2000 | 901207 | 450.6035 | 0 |
| exec_denied | baseline | 0 | 20 | 1315671 | 65783.55 | 0 |
| readdir_filter | baseline | 0 | 600 | 113508 | 189.18 | 0 |
| build_tree_stat_walk | baseline | 0 | 1984 | 657155 | 331.2273185483871 | 0 |
| lookup_visible_hot | policy | 0 | 2000 | 671228 | 335.614 | 0 |
| lookup_hidden | policy | 0 | 2000 | 510886 | 255.443 | 0 |
| access_hidden | policy | 0 | 2000 | 509229 | 254.6145 | 0 |
| open_denied | policy | 0 | 2000 | 627291 | 313.6455 | 0 |
| exec_denied | policy | 0 | 20 | 1463257 | 73162.85 | 0 |
| readdir_filter | policy | 0 | 500 | 148356 | 296.712 | 0 |
| build_tree_stat_walk | policy | 0 | 1984 | 949582 | 478.61995967741933 | 0 |

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
