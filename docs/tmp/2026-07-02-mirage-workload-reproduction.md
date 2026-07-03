# Mirage Workload Reproduction

Date: 2026-07-02

## Motivation

Mirage is a public agent virtual filesystem that exposes multiple local and
service backends through a common path/command interface. It is a good workload
source for `namei_ext` because it exercises command conformance, multi-backend
namespaces, cross-mount operations, workspace snapshots, cache invalidation,
and version branching without requiring live LLM API calls.

The goal of this pass was to reproduce Mirage's source-backed workload/oracle
paths that are directly useful for agent VFS workload design. It was not to
prove that Mirage requires `namei_ext`, eBPF, or any particular kernel
interface.

## Source

- Repository: `https://github.com/strukto-ai/mirage`
- Local checkout: `.cache/source-inspection/mirage`
- Commit: `627016bce3fb95fccb016098373859729a4f9fb5`
- Result root:
  `results/reproduction/2026-07-02-official-workloads/mirage/`

## Upstream Entry Points Inspected

- `.github/workflows/test_python.yml`
- `.github/workflows/test_integ.yml`
- `python/pyproject.toml`
- `conformance/README.md`
- `conformance/cases/*.json`
- `python/tests/conformance/test_conformance.py`
- `python/tests/core/{ram,disk,redis}/`
- `python/tests/cache/`
- `python/tests/workspace/test_cache_invalidation.py`
- `python/tests/workspace/test_cache_mount.py`
- `python/tests/workspace/test_cross_mount_recursive.py`
- `python/tests/workspace/test_snapshot.py`
- `python/tests/workspace/test_snapshot_drift.py`
- `integ/*.py`
- `examples/python/**`

## Environment

- Python: `Python 3.12.3`
- uv: `uv 0.8.22`
- Node: `v22.22.0`
- pnpm: `10.20.0`
- Redis: `Redis server v=7.0.15`
- Dedicated Redis port: `6381`
- Virtual environment:
  `.cache/venvs/mirage-python`

## Commands

Dependency setup from `.cache/source-inspection/mirage/python`:

```bash
UV_CACHE_DIR=/home/yunwei37/workspace/namei_ext/.cache/uv-cache \
UV_PROJECT_ENVIRONMENT=/home/yunwei37/workspace/namei_ext/.cache/venvs/mirage-python \
uv sync --all-extras --no-extra camel

UV_CACHE_DIR=/home/yunwei37/workspace/namei_ext/.cache/uv-cache \
UV_PROJECT_ENVIRONMENT=/home/yunwei37/workspace/namei_ext/.cache/venvs/mirage-python \
uv pip install .
```

Focused pytest run from `.cache/source-inspection/mirage/python`:

```bash
REDIS_URL=redis://127.0.0.1:6381/0 \
UV_CACHE_DIR=/home/yunwei37/workspace/namei_ext/.cache/uv-cache \
UV_PROJECT_ENVIRONMENT=/home/yunwei37/workspace/namei_ext/.cache/venvs/mirage-python \
uv run pytest \
  tests/conformance/test_conformance.py \
  tests/core/ram \
  tests/core/disk \
  tests/core/redis \
  tests/cache \
  tests/workspace/test_cross_mount_recursive.py \
  tests/workspace/test_cache_mount.py \
  tests/workspace/test_cache_invalidation.py \
  tests/workspace/test_snapshot.py \
  tests/workspace/test_snapshot_drift.py \
  -q
```

Integration and example runs followed Mirage's Python CI shape:

- `integ/ram.py`, `integ/disk.py`, `integ/redis.py`
- `integ/safeguard.py`, `integ/history.py`
- `integ/s3.py`, `integ/s3_cases.py`
- `integ/onedrive.py`, `integ/onedrive_cases.py`
- `integ/lancedb.py`, `integ/find_arg_errors.py`
- `integ/cross_commands.py`, `integ/root.py`
- Python examples under `examples/python/{ram,disk,other,redis_resource,version}/`

Outputs were diffed against upstream `integ/truth*.txt` or checked with
`integ/check_lines.sh` where Mirage CI uses that helper.

## Results

Raw logs and the machine-readable summary are under
`results/reproduction/2026-07-02-official-workloads/mirage/`.

| Check | Result |
| --- | --- |
| Dependency setup | pass |
| Focused pytest collection | 468 tests collected |
| Focused pytest execution | 468 passed, 0 failed |
| Integration truth-diff suite | 13 passed, 0 failed |
| Python examples truth-check suite | 11 passed, 0 failed |
| Temporary Redis cleanup | stopped; subsequent ping got connection refused |

The focused pytest subset covers shared command conformance over RAM, Disk, and
Redis; RAM/Disk/Redis backend operations; Redis index and file cache behavior;
workspace cache invalidation; cache mounts; cross-mount recursion; snapshots;
and snapshot drift.

The integration suite adds command-level truth oracles for RAM, Disk, Redis,
safeguard behavior, history, S3/moto, OneDrive fake Graph, LanceDB,
find-argument errors, cross-mount commands, and virtual-root switching.

The examples add agent-facing usage coverage for RAM/Disk VFS, Redis
resource/index/cache/VFS examples, custom commands, and version branching.

## Boundaries

This Python pass is no longer the only Mirage reproduction record. A follow-up
TypeScript/FUSE record,
`docs/tmp/2026-07-02-mirage-typescript-fuse-workload-reproduction.md`, closes
the TypeScript build/test/example, explicit FUSE integration, and Python FS
shim paths for the same checkout.

Across both records, remaining unclaimed coverage is live SaaS/API provider
backends, production credentials, all external storage services, Camel tests,
and deployed long-running Mirage service behavior.

The reproduced workload is a strong source-backed agent VFS seed, not a claim
that Mirage itself requires `namei_ext` or eBPF policy logic. For paper use,
Mirage should support workload/oracle selection and possibly a source-system
or FUSE/VFS-family baseline shape.

## Use In `namei_ext`

Useful workload shapes to carry forward:

- multi-backend path namespace with RAM, Disk, Redis, S3/moto, OneDrive fake
  Graph, and LanceDB-style backends;
- exact stdout/stderr/exit-code command conformance over multiple backends;
- cross-mount copy/read/diff/command behavior;
- cache invalidation and cache mount state transitions;
- workspace snapshot and snapshot-drift oracles;
- version branching behavior from the Python examples.

The strongest paper-facing use is an AI agent workspace lifecycle workload:
start with a workspace, mount multiple backing namespaces, perform a
cross-mount command sequence, take a snapshot or branch/version transition,
mutate cached or remote state, and check final command output plus snapshot or
cache-state oracle.

## Remaining Follow-Up

If Mirage becomes a main workload source, implement the selected transition as
a Make-owned `namei_ext` KVM workload with raw lookup/readdir/open/stat traces,
source-system or materialized/FUSE baselines, and correctness-first gates. Do
not present this reproduction as a table-only or interface-necessity proof.
