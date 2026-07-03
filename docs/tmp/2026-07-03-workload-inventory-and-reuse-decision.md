# Workload Inventory And Reuse Decision

Date: 2026-07-03

## Motivation

The project has accumulated many source-reproduction records. The remaining
question is no longer whether static redirect tables are impossible. The useful
question is: what workloads do the closest systems actually exercise, which
parts have been reproduced, and which reproduced workload shapes should become
`namei_ext` KVM workloads?

This record consolidates the workload inventory without changing the claim
boundary:

- do not claim every workload requires eBPF, `namei_ext`, or dynamic policy
  logic;
- do not claim `namei_ext` replaces FUSE, agent filesystems, or metadata
  services;
- use source systems as workload/oracle sources and as natural baselines where
  appropriate;
- move from source reproduction to Make-owned KVM `namei_ext` workload
  implementation.

## New Check In This Pass

YoloFS' public umbrella repository still declares benchmark and result
submodules that are not publicly readable from this environment.

Raw result root:

`results/reproduction/2026-07-03-official-workloads/yolofs-submodule-access-check/`

The checked repositories were:

- `https://github.com/YoloFS/agent-eval.git`
- `https://github.com/YoloFS/perf-eval.git`
- `https://github.com/YoloFS/agent-results.git`
- `https://github.com/YoloFS/perf-results.git`

All four `git ls-remote` probes exited with status `128` and stderr matching:

```text
remote: Repository not found.
fatal: repository ... not found
```

Therefore the current YoloFS status is precise: public filesystem code and the
compat-branch mounted VM e2e workload reproduce, but the original agent/perf
benchmark harnesses and result submodules are not public enough to reproduce.

## Agent Workspace And Agent Filesystem Sources

| System | Workloads exposed by the source | Reproduction status | Reuse decision for `namei_ext` |
| --- | --- | --- | --- |
| AgentFS | SDK filesystem operations, persistent agent state, tool-call audit, FUSE mount, COW sandbox run, bash/git overlay actions, whiteout, cache invalidation, symlink handling, AI framework examples. | Strong positive. Official CLI, Rust/Python/TypeScript SDKs, integration suite under CI-like `umask 022`, and five TypeScript examples passed. `pjdfstest` and adapted `xfstests` remain negative full-filesystem conformance evidence. | Primary source for the first AI agent workspace lifecycle workload: base tree plus per-agent delta, FUSE/source-system baseline, final tree, whiteout, cache invalidation, and git/bash oracles. |
| Redis AFS | Workspace create/import/mount/query/checkpoint/bookmark/fork/unmount, markdown search/file operations, Redis-backed workspace state, indexed-helper internals. | Positive for lifecycle, query, checkpoint, bookmark, fork, and adapted markdown search/file operations. Live mounted edit synchronization remains unclaimed; public current CLI path does not prove indexed RedisSearch grep performance. | Use for checkpoint/fork/query lifecycle shape and Redis-backed source-of-truth motivation. Avoid claiming full mounted-write sync or indexed-search performance. |
| Mirage | Multi-backend namespaces, RAM/Disk/Redis resources, cache/index stores, workspace snapshots and drift, cross-mount commands, version branching, CLI/server lifecycle, FUSE integration, Python FS shim. | Strong positive for local/provider-free paths: Python subset, integration truth diffs, Python examples, TypeScript build/tests, 15 TypeScript examples, explicit FUSE integration, and Python FS shim all pass. Live SaaS/API provider backends remain unclaimed. | Use as a second agent VFS shape: cross-mount namespace plus snapshot/version/cache transitions, with FUSE/source-system truth checks. |
| YoloFS | Hidden-side-effect tasks, routine filesystem tasks, staging, snapshot/travel, commit/abort, permission/hide, mounted filesystem e2e, performance pages for ext4/OverlayFS/BranchFS/YoloFS comparisons. | Public filesystem code reproduces: main/compat unit tests, compat kmod build, and compat mounted VM e2e with 593/593 tests. Original `agent-eval`, `perf-eval`, `agent-results`, and `perf-results` submodules are not publicly readable as of 2026-07-03. | Use public filesystem e2e and methodology. A YoloFS-like hidden-side-effect workload is valid if labeled as derived, not as original agent benchmark reproduction. |
| BranchFS | Branch/session filesystem, commit/abort/read/switch operations, shell and Rust integration tests, quick benchmarks. | Positive independent rerun: release build, upstream shell tests, Rust ioctl/integration tests, Python quick benchmark, and shell quick benchmark passed. | Good source for branch/session/commit-abort oracle and natural baseline ideas. |
| Sandlock | Agent code sandboxing with COW workdir, protected path classes, CLI dry-run/commit behavior, language SDKs. | Useful but partial. CLI tests and manual COW/protected-path smoke pass; named-UNIX, resource-control, and pkg-config/SDK caveats remain. | Use protected-path and COW sandbox shape; do not use as full conformance baseline. |
| OpenHands SDK | Remote workspace, file editor workspace-root validation, terminal sessions, DockerWorkspace backend lifecycle, API file upload/download, pause/resume. | Positive targeted evidence: 195 SDK tests passed and DockerWorkspace backend lifecycle passed over official prebuilt image. Cloud, Kubernetes, browser, live LLM, and same-commit image build remain unclaimed. | Useful for realistic agent runtime operations and Docker-backed workspace lifecycle traces. |
| SWE-agent | Deterministic agent loop, replay, run-single, run-batch, Docker-backed repository actions. | Positive partitioned official pytest/workload reproduction: 122 passed, 3 xfailed, 0 failed. | Use as deterministic agent execution/source-workspace workload evidence, not as full API-backed SWE-bench solve evidence. |
| SWE-ReX | Local and remote runtime file transfer, command execution, shell sessions, timeout/interrupt, pager, interactive commands, multi-session isolation, Docker deployment. | Positive for local/remote targeted tests and Docker backend. Modal, Fargate, and Daytona remain unrun. | Useful runtime/workspace source and baseline for command/session behavior. |
| SWE-MiniSandbox | Private `/tmp`, tmpfs/chroot/mount namespace setup, startup command, concurrent sandbox isolation. | Positive core sandboxdev subset. Vendored SWE-agent/SkyRL/R2E pipelines are not claimed. | Useful sandbox setup/isolation workload seed. |
| AgentCgroup | Per-tool-call resource-control boundaries, bash wrapper traces, pre-collected agent traces, characterization. | Controller, wrapper, trace-driven integration, characterization, scheduler/process builds pass. `memcg` build fails on host BTF `memcg_bpf_ops`; live Claude/API and root-cgroup e2e unrun. | Use only for operation-boundary and trace-phase evidence, not as filesystem baseline. |

## Environment And Cache Workload Sources

| System or dataset | Workloads exposed by the source | Reproduction status | Reuse decision for `namei_ext` |
| --- | --- | --- | --- |
| SWE-rebench V2 | Language-agnostic repository tasks with Docker images, gold patches, test patches, fail-to-pass/pass-to-pass oracles. | README sample passes. Public 20-row HF sample has 20/20 attempted, 19/20 evaluator-positive, 11 clean raw-exit-0 positives, 8 evaluator-positive raw-exit caveats, and one mismatch. | Strong W4 source. Prefer clean rows such as `pbiswas101__mathball-153`, `nyxx-discord__nyxx-547`, `mgechev__revive-1408`, `hashicorp__consul-10576`, `fsouza__fake-gcs-server-1035`, `jchambers__pushy-850`, and `spoonlabs__gumtree-spoon-ast-diff-171`. |
| SWE-Factory-Gym | Released Dockerfile/eval-script/gold-patch rows for SWE environment tasks. | Seven selected resolved rows across seven repositories pass with `OMNIGRIL_EXIT_CODE=0`; one row has a post-oracle cleanup warning. | Strong W4 source with simple per-row Docker/eval artifacts. Good candidates include `pallets__click-2622`, `nodejs__undici-3566`, `tailwindlabs__tailwindcss-12404`, and `python-pillow__Pillow-5425`. |
| MEnvData-SWE | 3005 prebuilt image/eval rows across 10 languages, plus MEnvAgent trajectory/source context. | Fifteen selected official image/eval rows pass across all 10 languages; four released rows remain preserved artifact caveats. | Strong W4 source for polyglot image/eval oracles. Prefer rows with Docker status 0 and `OMNIGRIL_EXIT_CODE=0`; record per-row digest and completion marker when present. |
| DockSmith | Dockerfile/eval-script generation trajectories, context retrieval, test-analysis repair loops, Docker-building training data. | Shard 1 has 298 instances with tagged Dockerfile/eval-script text; one trajectory-derived smoke replay passes. Public tagged eval scripts use placeholder test patches, so full official fail-to-pass reproduction is not available from this shard. | Use trajectory phases and smoke workload shape. Do not claim official DockSmith benchmark reproduction. |
| Multi-Docker-Eval | Public SWE task rows, evaluator, resolved/stable criteria, generated `docker_res` concept. | Harness works when `docker_res` exists. One Go synthetic/manual probe and one Python public-task manual `docker_res` replay pass; public dataset lacks official generated `docker_res`. | Use criteria and public task/evaluator shape. Keep manual/generated environment boundary explicit. |
| Terminal-Bench | Official CLI tasks with Docker setup, oracle agent, task-specific tests, protected paths, services, data/log/database, Git, security, forensics, build/debug tasks. | Selected official-task reproduction covers 63 resolved tasks plus negative/setup/artifact boundaries. | Use as broad agent terminal workload seed and correctness-oracle source, not as proof that any task requires `namei_ext`. |

## Metadata Service And Full Filesystem Sources

| System | Workloads exposed by the source | Reproduction status | Reuse decision for `namei_ext` |
| --- | --- | --- | --- |
| DeltaFS | VPIC-style file-per-particle dumps, large-directory metadata create/stat/delete, metadata service/server-shell path. | Direct single-process POSIX `large_dir` and `vpic_io` pass. Multi-rank POSIX and README server/shell paths remain unclosed; minimal 2-rank diagnostics still time out. | Appendix/related-work workload shape only. Do not turn this into a main `namei_ext` workload. |
| IndexFS | Official tree-test server path, mdtest-style file/directory create/stat/read/remove metadata benchmark. | Full RPC/server tree-test blocked by compiler and Thrift API drift. Source POSIX mdtest shape passes with 2 ranks for file and directory runs. | Appendix/related-work workload shape only. |
| TableFS | Fsbench metadata create/query, one-directory create/query, rename/delete, compact and small-file/scan groups. | Tiny individual fsbench split: 6/12 groups executable/pass; compact and small-file/scan groups still segfault in the original port. | Mechanism and appendix workload anchor only. Not a main workload artifact without porting. |

## Selection Decision

The next `namei_ext` workload should not be another external source-repro pass
unless it closes a very specific artifact boundary. The external source
inventory is now strong enough to select first paper-facing workloads:

1. Agent workspace lifecycle: derive from AgentFS first, with Redis AFS,
   Mirage, BranchFS, Sandlock, YoloFS, OpenHands, SWE-agent, and SWE-ReX used
   as source-system evidence and optional baseline/workload variations.
2. W4 environment/cache: derive from SWE-Factory-Gym or MEnvData-SWE first
   because their selected rows have simple official Docker/eval artifacts and
   clean correctness oracles; use SWE-rebench V2 as a broader benchmark
   companion.
3. Appendix only: DeltaFS, IndexFS, and TableFS should explain why full
   metadata services and full filesystems are different mechanisms. They
   should not drive the main evaluation.

The first Make-owned KVM workload should exercise:

- base workspace plus per-agent delta;
- lookup and readdir-visible path-view transitions;
- create/delete/rename/symlink or whiteout-style final-tree oracle;
- source-system/FUSE or materialized baseline where applicable;
- operation-weighted lookup/readdir trace;
- correctness gate before performance interpretation.

## What This Does Not Prove

This inventory does not prove that tables are impossible, that FUSE is
inadequate, or that source workloads intrinsically need eBPF. It proves a
different and more useful fact: there are enough public, source-backed,
reproduced workload oracles to stop designing from toy examples and start
implementing `namei_ext` KVM workloads that test whether a narrow VFS
name-resolution hook is sufficient for selected path-view subsets.
