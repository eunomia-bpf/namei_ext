# namei_ext

`namei_ext` is a research prototype for a `sched_ext`-style BPF extension point
in the Linux VFS path-resolution layer.

The project is not a standalone filesystem. The intended design keeps VFS,
dcache, inode, permission, and lower-filesystem semantics in the kernel, while
BPF programs provide programmable path-resolution decisions for lookup and
directory enumeration.

See [docs/idea-story.md](docs/idea-story.md) for the research story and
[docs/design.md](docs/design.md) for the mechanism design. The Linux kernel
fork used for prototyping is tracked as the `kernel` submodule.

## Repository Layout

The repository separates mechanism code, industrial experiments, performance
benchmarks, and historical evidence:

```text
kernel/                 modified Linux kernel submodule
bpf/policies/           eBPF name-resolution policies
runner/                 shared C harness for BPF, cgroup, and target lifecycle
experiments/            focused industrial case-study runners
tests/                  ABI, policy-load, semantic, and functional regressions
bench/                  VFS performance workloads
mk/experiments/         Make-owned KVM suites for individual case studies
workloads/legacy/       evidence using the superseded workload numbering
results/                raw observations, logs, hashes, and run metadata
```

`experiments/legacy_oracle/` retains the historical multi-workload ccache
runner for reproducibility. New experiments must use a focused runner under
`experiments/` and shared mechanism helpers from `runner/`.

## Make Entrypoints

All supported workflows are owned by Make:

```text
make phase1
make kvm-agent-workspace-matrix
make kvm-application-file-sharing-preflight
make kvm-build-action-sandboxing-preflight
make kvm-bench
```

`make phase1` builds and checks the ABI, BPF programs, userspace tests, touched
kernel objects, KVM boot, policy load/attach, and functional behavior. Host-only
execution does not count as Phase 1 validation.

Canonical KVM case-study result roots contain `run.json`,
`observations.jsonl`, `command.txt`, source and artifact hash manifests,
stdout/stderr, kernel identity and configuration, and dmesg. Workload
correctness gates run before performance results are interpreted.
