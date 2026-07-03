# Mirage TypeScript And FUSE Workload Reproduction

Date: 2026-07-02.
Stage: source-backed workload reproduction.

## Motivation

The earlier Mirage record closed a strong Python workload subset, but left the
TypeScript SDK, CLI/server lifecycle, examples, FUSE integration, and Python
FS shim paths unclaimed. Those paths matter because Mirage presents itself as
a unified virtual filesystem for AI agents across TypeScript packages,
workspaces, command execution, cache/index resources, versioning, and optional
kernel-visible FUSE mounts.

This pass follows Mirage's official TypeScript CI shape where feasible and adds
the explicit FUSE integration script. It is workload-source evidence, not proof
that Mirage requires `namei_ext`, eBPF, or any specific kernel interface.

## Source

- Repository: `https://github.com/strukto-ai/mirage`
- Local checkout: `.cache/source-inspection/mirage`
- Commit: `627016bce3fb95fccb016098373859729a4f9fb5`
- Result root:
  `results/reproduction/2026-07-02-official-workloads/mirage-typescript/`
- Machine-readable summary:
  `results/reproduction/2026-07-02-official-workloads/mirage-typescript/summary.json`

## Upstream Entry Points Inspected

- `.github/workflows/test_typescript.yml`
- `typescript/package.json`
- `typescript/packages/{core,node,browser,server,agents,cli}/package.json`
- `typescript/packages/node/src/conformance.test.ts`
- `typescript/packages/node/src/{workspace.test.ts,workspace_mount_spec.test.ts,workspace/fuse.test.ts}`
- `integ/fuse.ts`
- `integ/truth_fuse.txt`
- `examples/typescript/**`
- `integ/truth/typescript/*.txt`

## Environment

- Node: `v22.22.0`
- Corepack: `0.34.0`
- pnpm through Corepack: `10.32.1`
- Redis: `Redis server v=7.0.15`
- Dedicated Redis URL: `redis://127.0.0.1:6382/0`
- FUSE device: `/dev/fuse`
- FUSE tools: `fusermount3`, `fusermount`

Upstream's Python FS shim job documents Node 24 for
`--experimental-wasm-jspi`; this host's Node 22.22.0 accepted the same flag and
passed the truth check.

## Commands

Dependency setup from `.cache/source-inspection/mirage/typescript`:

```bash
COREPACK_HOME=/home/yunwei37/workspace/namei_ext/.cache/corepack \
corepack prepare pnpm@10.32.1 --activate

COREPACK_HOME=/home/yunwei37/workspace/namei_ext/.cache/corepack \
PNPM_HOME=/home/yunwei37/workspace/namei_ext/.cache/pnpm \
COREPACK_ENABLE_DOWNLOAD_PROMPT=0 \
corepack pnpm install --frozen-lockfile
```

Build and tests:

```bash
COREPACK_HOME=/home/yunwei37/workspace/namei_ext/.cache/corepack \
PNPM_HOME=/home/yunwei37/workspace/namei_ext/.cache/pnpm \
COREPACK_ENABLE_DOWNLOAD_PROMPT=0 \
corepack pnpm -r build

REDIS_URL=redis://127.0.0.1:6382/0 \
COREPACK_HOME=/home/yunwei37/workspace/namei_ext/.cache/corepack \
PNPM_HOME=/home/yunwei37/workspace/namei_ext/.cache/pnpm \
COREPACK_ENABLE_DOWNLOAD_PROMPT=0 \
corepack pnpm test
```

Examples followed the official workflow's truth-file list:

- `ram/ram.ts`
- `ram/ram_vfs.ts`
- `disk/disk.ts`
- `disk/disk_vfs.ts`
- `other/custom_command.ts`
- `pyodide/basic.ts`
- `pyodide/env.ts`
- `pyodide/heredoc.ts`
- `pyodide/script.ts`
- `pyodide/ram.ts`
- `redis/redis.ts`
- `redis/redis_index.ts`
- `redis/redis_cache.ts`
- `redis/redis_vfs.ts`
- `version/branching.ts`

Additional integration checks:

```bash
corepack pnpm -C typescript exec tsx ../integ/fuse.ts \
  | bash integ/check_lines.sh integ/truth_fuse.txt

node --experimental-wasm-jspi --import tsx/esm pyodide/vfs.ts \
  | bash ../../integ/check_lines.sh ../../integ/truth/typescript/pyodide_vfs.txt
```

## Results

Raw logs and hashes are recorded in `summary.json`.

| Check | Result |
| --- | --- |
| Dependency install | pass |
| TypeScript build | pass; `BUILD_EXIT=0` |
| TypeScript package tests | pass; `TEST_EXIT=0` |
| TypeScript examples | 15/15 truth checks passed; `EXAMPLES_EXIT=0` |
| FUSE integration | 9/9 truth lines matched; `FUSE_EXIT=0` |
| Python FS shim example | 4/4 truth lines matched; `PYODIDE_VFS_EXIT=0` |
| Redis cleanup | stopped; post-shutdown ping got connection refused |
| FUSE cleanup | no Mirage FUSE mount remained |
| Process cleanup | no Mirage/Redis/vitest/tsx process remained |

Package-level TypeScript test summaries from the raw log:

| Package | Result |
| --- | --- |
| `core` | 409 files passed; 3456 tests passed; 2 todo |
| `browser` | 44 files passed; 165 tests passed |
| `node` | 176 files passed, 2 files skipped; 1553 tests passed, 8 skipped |
| `server` | 20 files passed; 148 tests passed |
| `agents` | 14 files passed; 149 tests passed |
| `cli` | 4 files passed; 51 tests passed |

The TypeScript package tests cover command parsing/execution, conformance,
RAM/Disk/Redis resources, cache/index stores, workspace snapshots and drift,
cache invalidation, cross-mount behavior, server workspace/session/version
routes, CLI end-to-end workspace lifecycle, and node FUSE support tests.

The explicit FUSE integration mounted two Mirage resources at distinct OS
paths and verified real kernel-to-FUSE reads, pinned mountpoint creation,
distinct generated mountpoints, mount modes, multi-mount singular-access
failure, and collision rejection.

The Python FS shim example verified Python `open()` against Mirage mounts,
lazy-on-miss path visibility, and a PIL PNG write into `/ram` that the host
workspace read back.

## Boundaries

This is still not full Mirage coverage. It does not exercise live SaaS/API
provider backends, production credentials, all external storage services, or a
deployed long-running Mirage service. Provider behavior is represented through
unit tests, mocked paths, local Redis, local Disk/RAM, browser OPFS, and
truth-checked examples.

This also does not show that Mirage should be replaced by `namei_ext`. For the
paper, Mirage is a strong source of agent VFS workload shapes and baseline
behavior: multi-backend namespaces, cross-mount commands, cache/index
transitions, snapshots, version branching, CLI/server lifecycle, Python
filesystem shim behavior, and real FUSE mount semantics.

## Use In `namei_ext`

The strongest reusable workload shape is an agent workspace lifecycle with:

- several mounted namespaces, at least one kernel-visible FUSE or source-system
  baseline path;
- command execution across mount boundaries;
- snapshot, branch, clone, or version transition;
- cache/index or lazy-on-miss state transition;
- correctness oracle over stdout/stderr/exit code plus final filesystem state.

If selected as a main workload, the next step is not more source reproduction.
It is a Make-owned KVM `namei_ext` workload derived from this behavior, with
operation-weighted lookup/readdir/open/stat traces and natural baselines.
