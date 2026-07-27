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
mk/benchmarks/          Make-owned standard performance matrices
mk/results.mk           shared run lifecycle and raw-artifact validation
analysis/               derived statistics and figures from raw observations
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
make experiments
make kvm-agent-workspace-matrix
make kvm-application-file-sharing-preflight
make kvm-build-action-sandboxing-preflight
make kvm-bench
make kvm-fxmark-rq2-preflight
```

`make phase1` builds and checks the ABI, BPF programs, userspace tests, touched
kernel objects, KVM boot, policy load/attach, and functional behavior. Host-only
execution does not count as Phase 1 validation.

`make experiments` is the current case-study aggregate. It runs the Agent
workspace matrix and the implemented Application File Sharing and Build Action
Sandboxing preflights through the shared KVM and result lifecycle. The
historical Redis/nginx ccache matrix remains reproducible through
`make legacy-build-cache`, but it is not a current-suite dependency and must
not define the structure of new experiments.

Canonical KVM case-study result roots contain `run.json`,
`observations.jsonl`, `command.txt`, source and artifact hash manifests,
main-repository and kernel commits and status, guest and launcher
stdout/stderr, kernel identity and configuration, and dmesg. Formal targets
reject a dirty main or kernel tree. Result roots are immutable by `RUN_ID`;
artifact and correctness gates run while the result is `running`, before it
can transition to `completed`.

Multi-boot benchmark matrices use the same `namei_ext.run.v2` lifecycle and
place kernel identity, configuration, logs, and raw cell records under one
directory per boot. Suite Makefiles own only their workload matrix and
correctness gates; `mk/kvm.mk` owns execution and `mk/results.mk` owns the
minimum result contract. Multi-boot completion also requires exact agreement
between the declared and observed matrix and in-guest kernel identity.
