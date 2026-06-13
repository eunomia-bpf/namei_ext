# bpf-benchmark Development Norms Survey

Date: 2026-06-13

## Purpose

This note records the development-process rules imported from the parent
`../bpf-benchmark` repository into `namei_ext`. The goal is to reuse the parts
that make benchmark and kernel-development artifacts reproducible without
copying ReJIT-specific policy.

## Files Inspected

- `../bpf-benchmark/AGENTS.md`
- `../bpf-benchmark/CLAUDE.md`
- `../bpf-benchmark/README.md`
- `../bpf-benchmark/build.md`
- `../bpf-benchmark/Makefile`
- `../bpf-benchmark/micro/Makefile`
- `../bpf-benchmark/docs/evaluation.md`
- `../bpf-benchmark/docs/micro-bench-status.md`
- `../bpf-benchmark/runner/mk/build.mk`

The active daily-development rules are concentrated in the top-level
`AGENTS.md` and mirrored in `CLAUDE.md`. The README also points to
`docs/benchmark-runtime-architecture.md`, but that file is not present in the
current checkout; runtime-boundary rules were therefore taken from `AGENTS.md`,
`README.md`, and the Makefile/build fragments actually present in the tree.

## Norms Adopted

### Makefile as the public API

All build, KVM, Docker, test, benchmark, and report flows should go through
Make targets. Users should not need to invoke component binaries, Python
modules, Docker commands, guest commands, or ad hoc scripts directly.

For `namei_ext`, this also follows the stricter project rule that there should
be no project-owned shell scripts in the Phase 1 control plane. The shell used
inside Make recipes is an implementation detail of Make, not a separate public
or checked-in orchestration layer.

### Default configuration must run

The default target must run with committed defaults. Manual local state should
not be part of the contract. Kernel config fragments, KVM resource choices,
benchmark matrices, Docker package lists, policy selection, and report
configuration should live in repo files under `configs/`, `mk/`, `Dockerfile`,
or BPF source files.

Environment variables are acceptable only as documented Make knobs, such as
`SAMPLES`, `BENCH`, `JOBS`, `KVM_CPUS`, or `KVM_MEM`.

### Fail fast

Missing dependencies, unsupported host capability, kernel build failures, BPF
load errors, verifier failures, parse failures, guest command failures, and
result-format errors must fail visibly. The infrastructure should not silently
fall back to weaker behavior or report partial success as a pass.

The parent repository also bans redundant informational result fields such as
`workload_miss` or `limitations` when they are used to hide failed capability.
For `namei_ext`, a declared Phase 1 gate should either pass or preserve the raw
failure evidence and fail the owning Make target.

The same rule applies to ignored errors and dead code. Fallible work that
affects correctness or artifacts should not be hidden behind ignored return
values, best-effort status, compatibility wrappers, or unused future hooks.

### Raw results first

Guest-side collectors should store raw data: operation counts, latencies,
status, stdout/stderr, dmesg, kernel config, kernel image identity, Docker
image identity, policy object hashes, Makefile/config hashes, and errors.

Ratios, geomeans, confidence intervals, summary tables, and paper prose belong
in explicit analysis/report targets.

`docs/tmp/` should hold Markdown research and implementation records for this
project. Raw JSON, JSONL, logs, dmesg, and generated benchmark artifacts should
stay in `results/` or another documented result root.

### Build/cache/result contract

Generated artifacts should live under explicit roots:

- `.build/` or owning component build directories for kernel, BPF, C, and test
  build outputs.
- `.cache/` for image tars, downloaded caches, and transient executor state.
- `results/` or owning `*/results/` trees for functional and benchmark output.

Docker should consume declared outputs or named build contexts directly rather
than relying on manual staging directories.

### Docker and KVM boundary

Docker packages user-space dependencies and artifacts. KVM boots the modified
kernel and runs the privileged validation path. The normal runtime model should
not bind-mount the whole host workspace over the image workspace; mount only
explicit system paths and result directories.

Image layers should be ordered by change frequency so policy/test/benchmark
edits do not force kernel, libbpf, or bpftool rebuilds.

The `bpf-benchmark` "app-level loader only" rule maps to a `namei_ext` rule:
functional and benchmark suites should exercise the real BPF policy load and
`cgroup/namei_ext` attach path inside KVM. Host mocks, direct `.bpf.o`
inspection, or bpftool-only smoke checks can be useful diagnostics, but they do
not count as Phase 1 validation.

### Evaluation discipline

Each benchmark claim should map to a research question. Functional correctness
must be separated from performance and should gate performance interpretation.
Microbenchmarks should exercise real namespace/VFS operations rather than
standalone loops that do not drive `namei_ext`.

Declared workloads and policy actions should not be silently filtered or
skipped. If `REDIRECT` or another action is outside the current phase, that
scope boundary must be documented before it is treated as a gate. Once a
workload is declared as part of the suite, build, boot, attach, runtime, or
measurement failure should fail the suite.

### Test quality

Tests should protect behavior, error paths, ABI/layout, result formats, or
regressions. ABI tests should check offsets, enum values, encoded formats, and
kernel/user boundary behavior instead of relying only on structure size.

## Norms Not Adopted

ReJIT-specific rules from `bpf-benchmark` were not imported. Examples include
pass-list policy, tail-call accounting caveats, ReJIT failure semantics,
kinsn-specific architecture, AWS instance-size limits, and daemon/bpfopt
separation. They are useful references for evaluation rigor but are not
`namei_ext` project rules.

## Repository Changes

`AGENTS.md` was updated with the adopted norms:

- no checked-in shell-script control plane;
- default Make targets must work from committed configuration;
- build/cache/result roots are part of the repository contract;
- Docker layer and KVM boundary rules;
- real BPF policy load and `cgroup/namei_ext` attach path required for Phase 1;
- no redundant informational result fields that hide failed capability;
- no silent filtering or skipping of declared workloads;
- no dead-code/fallback/ignored-error paths in correctness or artifact flows;
- no revert/restore commits as a substitute for a forward fix;
- OSDI-style evaluation discipline for correctness and performance;
- stronger ABI-test guidance.

## Follow-up

When Phase 1 Makefiles are implemented, their targets should be reviewed
against this note and `AGENTS.md` before running the full KVM artifact path.
