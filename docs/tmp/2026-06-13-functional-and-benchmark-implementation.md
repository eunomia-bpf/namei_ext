# Functional And Benchmark Implementation

Date: 2026-06-13

## Purpose

This note records the Phase 1 user-space policy, functional tests,
microbenchmarks, KVM targets, and report generation.

## Files Added Or Changed

- `bpf/include/namei_ext.h`
- `bpf/policies/hide_deny.bpf.c`
- `tests/functional/namei_ext_functional.c`
- `tests/functional/Makefile`
- `bench/workloads/namei_ext_bench.c`
- `bench/workloads/Makefile`
- `configs/benchmarks/phase1.mk`
- `mk/kvm.mk`
- `mk/report.mk`
- top-level `Makefile`

## Functional Test

`namei_ext_functional` creates real files named `visible`, `hidden`, and
`denied`, attaches the BPF policy to cgroup v2, and validates:

- `visible` can be `stat`ed and opened;
- `hidden` returns `ENOENT` for `stat` and `open`;
- `denied` returns `EACCES` for `stat` and `open`;
- `readdir` lists `visible` and `denied` but not `hidden`.

The oracle is exact errno and exact directory membership, not log inspection.

## Microbenchmarks

`namei_ext_bench` runs five smoke-scale metadata workloads:

1. `lookup_visible_hot`: repeated `stat` on a visible cache-hot file.
2. `lookup_hidden`: repeated `stat` on a hidden file.
3. `open_denied`: repeated `open` on a denied file.
4. `readdir_filter`: repeated directory enumeration with hidden entry
   filtering.
5. `build_tree_stat_walk`: repeated `stat` over a deterministic include-tree
   shape that models build/package metadata walks.

Each workload runs once before attaching policy and once after attaching policy
in the same KVM guest. The benchmark writes raw JSONL with operation counts,
elapsed nanoseconds, and failure counts.

## Make Targets

Added KVM targets:

```text
make kvm-functional
make kvm-bench
```

Updated `make phase1` to run:

```text
check-prereqs
bpf
functional
bench
kernel-objects
kvm-smoke
kvm-functional
kvm-bench
docker
report
```

No project-owned shell scripts were added.

## Validation

Full command:

```text
make phase1
```

Result directory:

```text
results/phase1/20260613T155148Z-611a3836
```

Report gates:

```text
Guest smoke events: 2
Functional failing cases: 0
Benchmark failing operations: 0
```

The report lists all five benchmark names and both variants, `baseline` and
`policy`.

## Remaining Gaps

- Smoke benchmark defaults are not paper-grade: `SAMPLES=1` and
  `BENCH_ITERS=2000`.
- The current benchmark baseline is native lower filesystem before attach.
  OverlayFS, bind-mount, symlink-forest, and FUSE baselines remain future work.
- `dmesg` capture and dirty tree metadata should be added before claiming
  artifact evaluation completeness.
