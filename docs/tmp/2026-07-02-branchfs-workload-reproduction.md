# BranchFS Workload Reproduction

Date: 2026-07-02

## Motivation

BranchFS is one of the strongest source-backed agent workspace workload seeds.
It exposes branch/session path-view behavior through a FUSE filesystem:
mounting a base tree, creating branches, using `@branch` virtual paths,
committing a leaf branch into its parent, aborting a leaf branch, and preserving
ordinary file-operation behavior across readdir, symlink, rename, tombstone,
and cleanup cases.

This run refreshes the earlier combined BranchFS/Sandlock record with an
independent BranchFS result root and machine-readable summary. It is workload
evidence, not a claim that BranchFS requires `namei_ext` or eBPF.

## Source

- Repository: `https://github.com/multikernel/branchfs`
- Local checkout: `.cache/source-inspection/branchfs`
- Commit: `a4b6592d31aacb4d2f94d0c80f43d47d38063fa9`
- Host: `Linux lab 6.15.11-061511-generic x86_64`
- Python: `Python 3.12.3`
- Cargo: `cargo 1.90.0 (840b83a10 2025-07-30)`

The checkout is dirty after the benchmark because upstream writes
`bench_results.json` in the repository root. That generated file was copied
into the result root and was not cleaned from the source checkout.

## Commands

All commands were run from `.cache/source-inspection/branchfs`.

```text
cargo build --release
tests/run_all_tests.sh
python3 bench/branchfs_bench.py --quick
bench/quick_bench.sh
```

## Raw Artifacts

Result root:
`results/reproduction/2026-07-02-official-workloads/branchfs/`

Files:

- `cargo-build-release.log`
- `run-all-tests.log`
- `python-bench-quick.log`
- `bench-results-quick.json`
- `shell-quick-bench.log`
- `summary.json`

## Results

All commands exited with status 0.

Upstream tests:

- shell suites: all passed;
- Rust `test_ioctl`: 8 passed, 0 failed;
- Rust `test_integration`: 22 passed, 0 failed;
- final upstream marker: `All tests passed!`.

Python quick benchmark rows:

- read throughput: 4492.575905914009 MB/s on a 20 MB file with 64 KB blocks;
- write throughput: 1414.6567636493603 MB/s on the same shape;
- nested read latency depth 1: 70.7432333607964 us;
- nested read latency depth 4: 178.542600012103 us.

Shell quick benchmark:

- branch creation, including CLI/socket overhead:
  - 100 files: 102370 us;
  - 1000 files: 112724 us;
  - 10000 files: 160922 us.
- commit through `.branchfs_ctl`:
  - 1 KB: 3621 us;
  - 10 KB: 2007 us;
  - 100 KB: 2845 us;
  - 1000 KB: 3224 us.
- abort through `.branchfs_ctl`:
  - 1 KB: 2872 us;
  - 100 KB: 3258 us;
  - 1000 KB: 2962 us.
- 1 MB read: 1938 us.
- switch branch: 1809 us.

## Reusable Workload Shape

BranchFS is a primary source-backed AI agent workspace lifecycle seed.

Reusable pieces:

- FUSE mount over a base tree;
- branch creation;
- nested branch inheritance;
- `@branch` virtual namespace;
- commit leaf branch into parent or base;
- abort leaf branch;
- rename, delete, tombstone, symlink, readdir, and unmount cleanup oracles;
- FUSE source-system behavior for the same workflow.

The right `namei_ext` subset is not a BranchFS replacement. It is the path-view
part of the workflow: which branch/session view lookup and readdir should expose
while lower filesystem objects and data semantics remain ordinary filesystem
behavior.

## Remaining Risks

- The benchmark is quick-mode only, not a full benchmark sweep.
- BranchFS is a full FUSE filesystem with branch management logic. It should be
  used as workload/source-system behavior and baseline context, not as evidence
  that a narrow hook can reproduce every BranchFS feature.
- This run does not include a `namei_ext` KVM implementation of the workload.
