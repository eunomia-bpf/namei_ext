# Experiment Plan: namei_ext Phase 1

## Thesis

`namei_ext` can express useful per-workload namespace redirect policies with
a narrow cgroup-attached BPF decision point in VFS name resolution, while
keeping lookup, directory enumeration, and lower-filesystem data I/O under
normal kernel control.

## Paper Type

- Type: new system prototype and artifact.
- Target venue: OSDI/SOSP-style systems venue.
- Artifact status: integrated kernel prototype with KVM-runnable Makefile flow,
  ABI checks, Docker runtime smoke, and raw result capture.
- Main reviewer risk: the artifact may look like a toy hook unless functional
  coherence, realistic metadata workloads, and reproducible KVM execution are
  explicit.

## Claim Ledger

| ID | Claim | Scope | Minimum convincing evidence | Status |
|----|-------|-------|-----------------------------|--------|
| C1 | A single BPF decision function can drive both lookup and readdir namespace policy. | PASS/REDIRECT, cgroup-scoped single-policy Phase 1 ABI, same-parent component aliases. | KVM functional tests for `stat`, `open`, `access`, `read`, `execve`, `readdir`, attach-type enforcement, and multi/link attach rejection with one `SEC("cgroup/namei_ext")` program. | supported by clean run `20260613T191523Z-28aebdb8` |
| C2 | The kernel patch stays narrow and upstream-shaped. | VFS call sites plus cgroup BPF plumbing. | Existing VFS files only add guarded calls; policy execution lives in `fs/namei_ext.c` and cgroup BPF runner. | implemented |
| C3 | The artifact can build, boot, load policy, test, benchmark, package Docker, and report from Make. | Developer smoke scale. | `make phase1` exits 0 and writes raw JSONL plus `summary.md`, provenance, config hashes, and image identity. | supported by clean run `20260613T191523Z-28aebdb8` |
| C4 | The first microbenchmarks exercise real VFS namespace operations. | Metadata operations, not synthetic BPF loops. | Seven workloads: native lookup, redirected lookup/access/open/exec, redirected directory view, redirected build-tree stat walk. | supported by clean run `20260613T191523Z-28aebdb8` |

## System-Under-Test Model

- Components: modified Linux kernel, `namei_ext` VFS hooks, cgroup BPF attach
  path, BPF policy object, user-space functional and benchmark binaries.
- Durable state: none beyond lower-filesystem files created by each test.
- Trust/failure boundaries: BPF can decide actions but cannot own dentries,
  inodes, or file operations.
- Workloads: lookup, open, access, exec path walks, readdir, and metadata tree
  walks over real files.
- Observability: JSONL raw results, Markdown summary, kernel config, uname,
  dmesg logs, Docker image tar hash, kernel image hash, commit/dirty
  provenance, config hashes, Docker image id, kernel command line, and ABI
  layout evidence.
- Assumptions: Phase 1 implements same-parent component `REDIRECT`; cross-
  directory target registries and writable alias mutation are outside scope.

## Experiment Matrix

| Block | Claim | Experiment | Baselines/variants | Metric(s) | Oracle | Figure/table | Priority |
|-------|-------|------------|--------------------|-----------|--------|--------------|----------|
| B1 | C1 | Functional namespace behavior | baseline setup plus attached BPF policy | pass/fail, errno, listed entries, file content | exact alias/backing behavior and listing set | Table: functional cases | must |
| B2 | C3 | Artifact flow | one-command `make phase1` | exit status, result files | Make exits 0 and report gates show zero failures for ABI, functional, benchmark, Docker, and dmesg checks | Artifact checklist | must |
| B3 | C4 | Microbenchmark suite | native baseline vs attached policy in same guest | ops, elapsed ns, ns/op, failures | fail count is zero and workloads match expected semantics | Table: microbenchmarks | must |

## Experiment Blocks

### B1. Functional Namespace Semantics

- Claim tested: C1.
- Hypothesis: one BPF policy can redirect a requested `tool` component to
  `tool.real` for lookup and emit `tool.real` as `tool` during readdir.
- Workload: create real lower files, attach policy to cgroup, run `stat`,
  `open`, `access`, `read`, failing `execve`, and `readdir`.
- Compared systems: attached policy behavior against expected alias/backing
  behavior.
- Metrics: pass/fail, errno, directory membership, read content.
- Run budget: every `make phase1`.
- Oracle: exact errno, exact listed-name predicate, and exact file content.
- Success criterion: zero failed functional cases.
- Failure interpretation: ABI or VFS hook semantics are not coherent enough for
  Phase 1 claims.
- Reproducibility artifacts: `functional.jsonl`, `summary.md`.

### B2. Artifact Flow

- Claim tested: C3.
- Hypothesis: committed Makefiles and configs are enough to reproduce the
  Phase 1 smoke artifact.
- Workload: `make phase1`.
- Compared systems: not a performance comparison; this is an artifact gate.
- Metrics: exit status, presence of raw result files, kernel/image hashes,
  Docker tar hash, commit/dirty provenance, config hashes, ABI layout checks,
  and dmesg issue count.
- Run budget: every Phase 1 validation.
- Oracle: Make exits 0 and `summary.md` reports zero ABI, functional,
  benchmark, Docker, and dmesg failures.
- Failure interpretation: infrastructure-as-code contract is incomplete.
- Reproducibility artifacts: result directory under `results/phase1/<run-id>/`.
  Latest smoke evidence after the redirect rewrite:
  `results/phase1/20260613T191523Z-28aebdb8/`.

### B3. Microbenchmark Smoke Suite

- Claim tested: C4.
- Hypothesis: the Phase 1 hooks can run realistic VFS metadata operations with
  policy attached and preserve expected behavior.
- Workload: metadata workloads:
  `lookup_native_hot`, `lookup_tool_redirect`, `access_tool_redirect`,
  `open_tool_redirect`, `exec_tool_redirect`, `readdir_alias_view`, and
  `build_tree_stat_walk`.
- Compared systems: baseline in the same guest before attach, then attached
  policy in the same process.
- Metrics: ops, elapsed ns, ns/op, fail count.
- Run budget: smoke default `SAMPLES=1`, `BENCH_ITERS=2000`; paper run should
  raise samples and randomize order.
- Oracle: fail count is zero for every workload/variant.
- Failure interpretation: either policy semantics are wrong or benchmark setup
  does not represent the intended VFS operation.
- Reproducibility artifacts: `bench.jsonl`, `summary.md`.

## Run Order

| Run ID | Stage | Purpose | Config | Decision gate | Cost | Risk |
|--------|-------|---------|--------|---------------|------|------|
| R001 | sanity | compile changed kernel and user-space objects | default Make config | object build succeeds | low | misses link errors |
| R002 | artifact | full `make phase1` | `SAMPLES=1 BENCH_ITERS=2000` | zero failures in report | medium | smoke-scale only |
| R003 | paper | repeated benchmark run | `SAMPLES>=30`, pinned host | confidence intervals and tails | high | not implemented yet |

## Baseline Fairness

- Named baselines: native lower filesystem before attaching policy; future
  paper runs should add bind mounts, OverlayFS, symlink forest, and FUSE.
- Tuning policy: Phase 1 smoke keeps both variants in one KVM guest and one
  process to reduce setup noise.
- What the baseline proves: direct backing-component behavior is compared
  against redirected alias behavior over the same lower files.
- Baselines intentionally omitted: OverlayFS/FUSE/bind-mount baselines are not
  in the current smoke gate because the first milestone is kernel PoC and
  reproducible infrastructure.

## Reproducibility

- Hardware/software versions: captured through `uname.txt`, `proc-version.txt`,
  kernel image hash, Docker tar hash.
- Seeds/repetitions: no random seed in smoke; `SAMPLES` controls repetitions.
- Workload generation: deterministic temporary files in the guest.
- Scripts/configs: Makefile-only orchestration; configs under `configs/`.
- Result file paths: `results/phase1/<run-id>/`.

## Residual Uncertainty

- Phase 1 redirect is same-parent and non-recursive.
- Disabled static-branch overhead is not yet isolated by a dedicated benchmark.
- Paper-grade runs need more samples, randomized order, tail distributions,
  system metrics, and stronger baselines.
- Writable namespace mutation is intentionally outside the current claim.

## Claim Gate After Results

| Claim | Evidence file(s) | Verdict | Claim wording to use |
|-------|------------------|---------|----------------------|
| C1 | `functional.jsonl`, `summary.md` from `20260613T191523Z-28aebdb8` | supported for PASS/REDIRECT aliases | one cgroup-attached BPF function can keep lookup, access, read, execve, and readdir coherent for same-parent redirect aliases under a single-policy attach ABI |
| C2 | kernel diff, `make kernel` | partial | kernel changes are narrow but still need upstream-style review |
| C3 | `summary.md`, `metadata.json`, provenance sidecars, `abi.jsonl`, `docker.jsonl`, and dmesg logs from `20260613T191523Z-28aebdb8` | supported at smoke scale | Phase 1 has a one-command KVM smoke artifact with ABI, Docker, provenance, config-hash, image-identity, and dmesg gates |
| C4 | `bench.jsonl`, `summary.md` from `20260613T191523Z-28aebdb8` | supported at smoke scale | VFS metadata redirect workloads run under baseline and attached policy with zero semantic failures |
