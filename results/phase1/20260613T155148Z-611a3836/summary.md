# Phase 1 Report

- Date: 2026-06-13
- Scope: KVM smoke, functional policy validation, and smoke-scale microbenchmarks
- Kernel image: /home/yunwei37/workspace/namei_ext/.build/kernel/arch/x86/boot/bzImage
- Kernel sha256: ca042e4d6f2269559cd29d5a09af3ba6cac7ce7dd344a15100e7430cfa0480de
- Result directory: /home/yunwei37/workspace/namei_ext/results/phase1/20260613T155148Z-611a3836
- Samples: 1
- Benchmark iterations: 2000
- Docker image tar sha256: 8f842852c822f0b0bba5a06c4eedf73dc984cc4f7f3f89f82cbb4d8ba790739f

## Gates
- Guest smoke events: 2
- Functional failing cases: 0
- Benchmark failing operations: 0

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
| lookup_visible_hot | baseline | 0 | 2000 | 460305 | 230.1525 | 0 |
| lookup_hidden | baseline | 0 | 2000 | 441631 | 220.8155 | 0 |
| open_denied | baseline | 0 | 2000 | 882465 | 441.2325 | 0 |
| readdir_filter | baseline | 0 | 600 | 104721 | 174.535 | 0 |
| build_tree_stat_walk | baseline | 0 | 1984 | 608769 | 306.83921370967744 | 0 |
| lookup_visible_hot | policy | 0 | 2000 | 671412 | 335.706 | 0 |
| lookup_hidden | policy | 0 | 2000 | 501278 | 250.639 | 0 |
| open_denied | policy | 0 | 2000 | 614503 | 307.2515 | 0 |
| readdir_filter | policy | 0 | 500 | 134506 | 269.012 | 0 |
| build_tree_stat_walk | policy | 0 | 1984 | 920895 | 464.16078629032256 | 0 |

## Raw Artifacts
- `guest-smoke.jsonl`
- `functional.jsonl`
- `bench.jsonl`
