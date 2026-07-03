# AgentFS Official Workload Reproduction

Date: 2026-07-02

## Motivation

Earlier AgentFS records reproduced `pjdfstest` and `xfstests` style
full-filesystem conformance paths, mostly as negative boundary evidence. That
does not answer the more useful workload question: what does AgentFS itself
exercise for agent state, filesystem access, copy-on-write sandboxing,
auditing, mounting, and framework integration?

This pass reproduces the official AgentFS SDK, CLI, integration, and example
entry points from the public repository. It records positive source-backed
agent-workspace workload evidence, while keeping the previous conformance
negative records separate.

## Source

- Repository: `https://github.com/tursodatabase/agentfs`
- Local checkout: `.cache/source-inspection/agentfs`
- Commit: `0a014ebd4918615baff589ed17486e557e7c6a23`
- Result root:
  `results/reproduction/2026-07-02-official-workloads/agentfs-official-tests/`

## Upstream Entry Points Inspected

- `README.md`
- `.github/workflows/rust.yml`
- `.github/workflows/python.yml`
- `.github/workflows/typescript.yml`
- `cli/Cargo.toml`
- `sdk/rust/Cargo.toml`
- `sdk/python/pyproject.toml`
- `sdk/typescript/package.json`
- `cli/tests/all.sh`
- `cli/tests/test-*.sh`
- `sdk/python/tests/*.py`
- `sdk/typescript/tests/*.ts`
- `examples/*/package.json`

## Environment

- Kernel: `Linux lab 6.15.11-061511-generic x86_64`
- Rust: `rustc 1.90.0`, `cargo 1.90.0`
- Toolchain used for Rust tests: `nightly-x86_64-unknown-linux-gnu`
- Python: `Python 3.12.3`
- uv: `uv 0.8.22`
- Node: `v22.22.0`
- npm: `10.9.4`
- FUSE helpers: `/usr/bin/fusermount`, `/usr/bin/fusermount3`
- Default shell `umask`: `0077`

## Commands

Rust CLI tests from `.cache/source-inspection/agentfs/cli`:

```bash
cargo +nightly test --verbose
```

Rust SDK tests from `.cache/source-inspection/agentfs/sdk/rust`:

```bash
cargo +nightly test --verbose
```

Python SDK tests from `.cache/source-inspection/agentfs/sdk/python`:

```bash
UV_CACHE_DIR=/home/yunwei37/workspace/namei_ext/.cache/uv-cache \
UV_PROJECT_ENVIRONMENT=/home/yunwei37/workspace/namei_ext/.cache/venvs/agentfs-python \
uv sync

UV_CACHE_DIR=/home/yunwei37/workspace/namei_ext/.cache/uv-cache \
UV_PROJECT_ENVIRONMENT=/home/yunwei37/workspace/namei_ext/.cache/venvs/agentfs-python \
uv run pytest -q
```

TypeScript SDK tests from `.cache/source-inspection/agentfs/sdk/typescript`:

```bash
npm ci
npm run build
npm test
```

CLI integration from `.cache/source-inspection/agentfs/cli`:

```bash
./tests/all.sh
umask 022; ./tests/all.sh
```

TypeScript examples:

```bash
npm ci && npm run build      # Mastra, Claude Agent SDK, OpenAI Agents examples
npm ci && npm run typecheck  # AI SDK + just-bash, Cloudflare examples
```

## Results

Raw logs and machine-readable summary are under
`results/reproduction/2026-07-02-official-workloads/agentfs-official-tests/`.

| Check | Result |
| --- | --- |
| CLI Rust tests | 77 passed, 0 failed; one doc test ignored |
| Rust SDK tests | 102 unit tests plus 1 doc test passed, 0 failed |
| Python SDK tests | 131 passed, 0 failed |
| TypeScript SDK tests | 234 passed, 5 skipped, 0 failed |
| CLI integration with default `umask=0077` | failed at Linux baseline syscall permission assertions after 20/22 syscall subtests passed |
| CLI integration with `umask 022` | full `tests/all.sh` passed |
| TypeScript examples | 5/5 build or typecheck cases passed |

The default-umask failure is preserved in
`cli-integration-all.log`. The upstream syscall tests assert exact mode bits
for created files and FIFOs; with the repository process `umask=0077`, `0644`
and `0755` assertions become false. Re-running the same upstream integration
suite with a CI-like `umask 022` passed.

## Workload Shapes Reproduced

- SQLite-backed SDK filesystem operations across Rust, Python, and TypeScript.
- SDK key-value state and tool-call audit trail operations.
- CLI `init` and database-backed agent filesystem creation.
- FUSE mount read/write/mkdir/symlink behavior.
- `agentfs run` copy-on-write FUSE overlay syscall workload.
- Interactive bash session where writes remain out of the host filesystem.
- Git init/add/commit/log inside the overlay with no host repository
  materialization.
- Overlay whiteout persistence across remount.
- Overlay readdir/unlink behavior for delta files inside base directories such
  as `.git`.
- FUSE cache invalidation for unlink, rmdir, rename, cached-negative file
  creation, and cached-negative directory creation.
- Symlink handling for host-visible and sandbox-created symlinks.
- Agent framework example integration for Mastra, Claude Agent SDK, OpenAI
  Agents, AI SDK plus just-bash, and Cloudflare Workers.

## Boundaries

This record does not replace the earlier AgentFS `pjdfstest` and `xfstests`
records. Those remain useful negative full-filesystem conformance evidence.
This record is the positive AgentFS source-workload evidence.

This record also does not claim that AgentFS workloads require `namei_ext` or
eBPF policy logic. For the paper, AgentFS should be used as a source-system
workload and baseline source for agent workspace lifecycle: persistent agent
state, audit trail, FUSE mount behavior, copy-on-write sandboxing, git/bash
tool execution, cache invalidation, and overlay state transitions.

## Use In `namei_ext`

The strongest `namei_ext` workload derivation is:

1. Create a source workspace with a `.git`-like base tree.
2. Attach a per-agent path view that exposes base files plus per-agent delta.
3. Run bash or git actions that create, delete, rename, and symlink files.
4. Check final tree, whiteout, host-non-materialization, cache invalidation,
   and tool-call/audit state oracles.
5. Compare against source AgentFS/FUSE behavior, materialized copy or Overlay,
   and native host behavior for equivalent correctness.

This is a real agent workspace workload seed; it is not a static-table proof.
