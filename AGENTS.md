# Agent Instructions

## Project Invariants

- `namei_ext` is not a BPF filesystem. It is a narrow VFS name-resolution
  extension point where an eBPF policy decides path-resolution actions and the
  kernel keeps ownership of VFS objects and lower-filesystem semantics.
- A policy is an eBPF program under `bpf/policies/*.bpf.c`, not a YAML/JSON
  policy file or custom configuration language.
- The kernel-facing BPF ABI exposes one decision function. Lookup and directory
  enumeration are event types passed to that one function.
- Project-owned orchestration is Makefile-only. Do not add project-owned shell
  scripts as the control plane, including checked-in helper `.sh` files for
  build, guest, Docker, benchmark, or report steps.
- Phase 1 validation must run the modified kernel in KVM. Host-kernel-only
  checks are useful but do not count as Phase 1 validation.

## Development Rules

### bpfbenchmark-Derived Daily Norms

The parent `bpf-benchmark` repository is the reference for this project's
day-to-day development discipline. Carry over these norms unless they conflict
with a stricter `namei_ext` rule:

- canonical workflows go through `make <target>`;
- real kernel/app paths are preferred over framework-side mocks or direct
  object-file inspection;
- collectors preserve raw observations and do not compute paper summaries;
- missing capability, unsupported flags, verifier failures, syscall failures,
  and declared workload failures are hard failures;
- Docker images contain declared artifacts and should not depend on a host
  workspace bind mount as the normal runtime model;
- generated JSON/JSONL/log/result artifacts live under result roots, while
  `docs/tmp/` remains Markdown-only for research and implementation records;
- git state is modified only after explicit user authorization and status/diff
  inspection.

### Make Is The Entrypoint

All build, test, benchmark, KVM, Docker, and report workflows must go through
Make targets. Do not ask users to run component binaries, Python modules,
Docker commands, or ad hoc guest commands directly when a Make target should own
the dependency graph and artifact paths.

### Fail Fast

Unsupported capability, missing dependency, failed command, parse error, BPF
load error, or kernel syscall error must fail visibly. Do not silently fall back
to weaker behavior, return partial success, warn-and-continue, or hide errors in
informational metadata.

Do not add redundant informational-only result fields such as `skipped`,
`workload_miss`, `limitations`, or `partial_success` to turn missing capability
or failed execution into a pass. If a declared Phase 1 capability cannot run,
preserve the raw failure evidence and fail the owning Make target.

Keep fallible work explicit. Do not ignore command status, syscall return
values, parser failures, verifier failures, or result-write errors in paths
that affect correctness, artifacts, or reports. Remove dead code, compatibility
wrappers, and unused public APIs instead of carrying them as future hooks.

### Preserve Raw Results

Runtime and benchmark code should write raw observations first: per-operation
measurements, stdout/stderr, lifecycle events, status, errors, dmesg, kernel
config, commits, and image identity. Aggregation, ratios, confidence intervals,
and Markdown interpretation belong in explicit report/analysis targets, not in
low-level collectors.

### Makefile Discipline

Makefile changes must be minimal and local. Prefer adding or editing the
owning target over broad refactors. Use `install -d` for output directories.
Generated build outputs belong under the owning build directory or documented
cache/result roots, not scattered through the source tree.

Do not add convenience alias targets, broad conditional logic, or new top-level
target families just for one-off development. Target names should describe the
suite or lifecycle action; platform, sample count, benchmark selection, and
resource sizes should be Make variables or committed configuration files.

### Docker And KVM Boundaries

Docker images package runtime dependencies and user-space artifacts. KVM boots
the modified kernel and runs the privileged validation path. Do not bind-mount
the host workspace over the image workspace as the normal runtime model; mount
only explicit system paths and result directories when needed.

Docker image layers should be ordered by change frequency: stable base packages
first, vendored third-party artifacts next, kernel/user-space build artifacts
after that, and frequently edited project policy, tests, benchmark, and report
code last. Changing a benchmark or policy file should not force a kernel,
libbpf, or bpftool rebuild unless its declared dependencies changed.

### Real Policy Path

Functional tests and benchmarks must exercise the real `cgroup/namei_ext`
attach path in the modified kernel. Do not replace policy execution with host
mocks, direct `.bpf.o` inspection, bpftool-only smoke checks, or hand-written
kernel decision stubs and count that as Phase 1 validation. Local diagnostic
shortcuts may exist only behind clearly named non-Phase-1 targets.

### Default Configuration Must Work

The default `make` and `make phase1` flows must work with no manual
environment variables beyond explicitly documented overrides. Defaults belong
in committed Makefiles and files under `configs/`, not in a developer's shell
history, local kernel `.config`, manually mounted bpffs, or hand-created
cgroups.

Use environment variables only as documented knobs for a Make target. Target
names should describe the suite or lifecycle action; platform, sample count,
benchmark selection, and resource sizes should be Make variables or committed
configuration files.

### Build, Cache, And Result Roots

Generated repository artifacts must live under explicit, documented roots:
kernel, BPF, native, and test build trees under `.build/` or the owning
subdirectory; downloaded caches and image tars under `.cache/`; benchmark and
test output under `results/` or the owning `*/results/` tree.

Do not stage repo artifacts into a second temporary directory just so Docker can
copy them again. Docker should consume declared build outputs or named build
contexts directly.

### Evaluation Discipline

Every benchmark claim must map to an explicit research question and must
separate correctness from performance. Correctness checks gate the run first;
runtime, latency, overhead, and code-size numbers are interpreted only after
functional behavior is correct.

Microbenchmarks must represent realistic VFS path-resolution operations for this project:
component lookup, open/stat/access/exec path walks, directory enumeration,
same-parent redirect, cache-hot and cache-cold behavior, and common
build/container filesystem access patterns. Avoid synthetic loops that do not
exercise the VFS or the `namei_ext` BPF ABI.

Do not silently filter, skip, or exclude declared policy actions or workloads
from an evaluation run. If a capability is outside the current phase, document
that before declaring it as a gate. Once declared, failure to build, boot, load,
attach, execute, or measure it must fail the suite.

Analysis targets may compute ratios, confidence intervals, geomeans, tables,
and Markdown reports from raw outputs. Runtime collectors and guest test code
must preserve raw measurements and failures rather than embedding paper
interpretation into low-level result files.

### Git Safety

Do not run git commands that modify repository state unless the user explicitly
asks for that operation. Allowed read-only commands include `git status`,
`git diff`, `git log`, `git show`, and `git blame`.

When the user explicitly requests git mutation, inspect status and diff first,
then scope `git add`, `git commit`, `git pull`, or `git push` to the requested
work. Do not use destructive or history-rewriting commands such as `git reset`,
`git checkout --`, `git restore`, `git stash`, `git rebase`, `git commit
--amend`, or force push unless the user explicitly asks for that exact action.

Do not create revert/restore commits as a substitute for deciding the correct
forward fix. If a previous change is wrong, fix it forward in the requested
commit scope instead of bouncing the tree between states.

### Documentation History

Do not rewrite long-lived design notes, research plans, experiment logs, or
benchmark reports wholesale unless the user explicitly asks for a rewrite.
Prefer additive edits that preserve prior measurements, failed experiments,
caveats, and rationale.

### Test Quality

Add tests only when they can catch a meaningful bug or protect an external
contract. Good tests cover behavior, boundaries, error paths, ABI/layout, result
formats, or regressions. Avoid tests that only exercise trivial getters,
standard library behavior, or tautologies.

For ABI tests, verify encoded layout, field offsets, enum values, and behavior
at the kernel/user boundary; `sizeof`-only checks are not enough.

## Phase 1 Documentation Rule

Every Phase 1 research step must produce a complete, standalone document under
`docs/tmp/`.

Every Phase 1 implementation step must also produce its own standalone document
under `docs/tmp/`.

All files in `docs/tmp/` created for these records must start with the date in
`YYYY-MM-DD-` format, for example:

```text
docs/tmp/2026-06-13-kernel-code-survey.md
docs/tmp/2026-06-13-namei-ext-abi-rationale.md
docs/tmp/2026-06-13-kvm-makefile-infrastructure.md
```

These documents should record the motivation, code paths or files inspected,
design choices, alternatives rejected, implementation details, validation
performed, and any remaining risks or follow-up work.

`docs/tmp/` is for standalone Markdown research and implementation records.
Raw JSON, JSONL, logs, dmesg, generated reports, and benchmark outputs belong
under `results/` or the documented owning result root, not in `docs/tmp/`.
