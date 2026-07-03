# Redis AFS Markdown Workload Reproduction

Date: 2026-07-01

## Motivation

Redis Agent Filesystem has an upstream markdown-heavy benchmark under
`tests/bench_md_workloads`. This is a useful agent-workspace workload because
it exercises generated workspace import, Redis-backed live namespace reads,
content grep, filename discovery, tree walking, hot-file reads, head, and line
window operations. The goal here was to determine whether that official
workload shape can run on the current public repository and what adaptations
are required.

## Source

- Source tree:
  `.cache/source-inspection/redis-agent-filesystem`
- Commit:
  `990b8eb7abff1bb51d35abf4ba9829963b679de2`
- Files inspected:
  `tests/bench_md_workloads/main.go`, `cmd/afs/afs_grep.go`,
  `cmd/afs/afs_store.go`, `cmd/afs/afs_search_index.go`,
  `internal/searchindex/searchindex.go`, and `internal/queryindex/*.go`.

## Raw Evidence

Result root:

- `results/reproduction/2026-07-01-official-workloads/redis-afs-md-workload-adapted/`

Important files:

- `upstream-stale-ws-import.log`
- `adapted-small-run-v2.log`
- `adapted-local-no-search-small.log`
- `adapted-current-cli-local-no-search-small.log`
- `adapted-current-cli-local-no-search-medium.log`
- `adapted-current-cli-local-no-search-small/report.json`
- `adapted-current-cli-local-no-search-medium/report.json`
- `summary.json`

Indexed-search follow-up record:

- `docs/tmp/2026-07-01-redis-afs-indexed-search-workload-reproduction.md`
- `results/reproduction/2026-07-01-official-workloads/redis-afs-md-indexed-search/summary.json`

## Workload Shape

The harness:

1. generates a deterministic markdown corpus;
2. starts temporary Redis;
3. builds or reuses `afs`;
4. imports the corpus into a Redis-backed AFS workspace;
5. validates local filesystem output against AFS output for grep-like searches;
6. runs nearby agent file operations through the AFS client.

The search oracles are:

- rare literal match;
- common literal match;
- regex escalation match.

The nearby agent file-operation oracles are:

- `tree_walk`;
- `find_runbook_names`;
- `read_hot_files`;
- `head_hot_files`;
- `line_window_hot_files`.

## Adaptations

The unmodified harness does not run against the current CLI:

- upstream calls `afs ws import`, but current `afs` routes file-tree import
  through `afs vol import`;
- upstream calls `afs grep --workspace <name>`, but current `afs grep`
  shortcut uses the default workspace, while explicit workspace selection is
  `afs fs <workspace> grep`;
- upstream automatically falls back to Docker `redis:8` when the local Redis
  lacks Search. On this host, that path reached live workspace initialization
  but initially failed because Redis 8 returns `SEARCH_INDEX_NOT_FOUND` /
  `Index not found`, an error string not recognized by the cached source's
  missing-index matcher.

The adapted cached-source harness changes only:

- `afs ws import` to `afs vol import`;
- `afs grep --workspace <name>` to `afs fs <workspace> grep`;
- Docker RedisSearch fallback to an explicit local Redis no-Search fallback.

This is not an unmodified upstream reproduction and is not the indexed
RedisSearch performance benchmark. It is an adapted reproduction of the
markdown workload semantics through the current CLI and direct Redis-backed
fallback path.

The later indexed-search follow-up showed that Docker `redis:8` does provide
Redis 8.8.0 with RediSearch and that the adapted current-CLI markdown workload
can pass on that Search-capable Redis after the missing-index compatibility
patch. However, the current CLI route `afs fs <workspace> grep` uses
`cmdFSGrep`, not the older `cmdGrep` indexed backend, so this still must not be
cited as indexed RedisSearch CLI performance reproduction.

## Results

| Run | Corpus | Exit | Correctness result | Interpretation |
| --- | ---: | ---: | --- | --- |
| `upstream-stale-ws-import.log` | 200 files | 1 | Did not reach benchmark. | Upstream harness is stale against current CLI. |
| `adapted-small-run-v2.log` | 200 files | 1 | `vol import` reached live workspace initialization, then failed on RedisSearch index wait. | Indexed Search path not reproduced here. |
| `adapted-local-no-search-small.log` | 200 files | 0 | File ops passed, but grep outputs mismatched because the harness still used stale grep CLI. | Preserved negative adaptation step. |
| `adapted-current-cli-local-no-search-small.log` | 200 files | 0 | Grep/ripgrep outputs identical; five nearby file ops count-match. | Small adapted workload reproduced. |
| `adapted-current-cli-local-no-search-medium.log` | 1000 files | 0 | Grep/ripgrep outputs identical; five nearby file ops count-match. | Medium adapted workload reproduced. |

The medium adapted run used 1000 markdown files, 24 directories, and 2.0 MiB of
content. It recorded:

- grep rare/common/regex validations: all `identical normalized output`;
- ripgrep rare/common/regex validations: all `identical normalized output`;
- file operation validations:
  `counts match (1049)`, `counts match (250)`, `counts match (100813)`,
  `counts match (37767)`, and `counts match (24759)`.

## Reuse Decision

Redis AFS remains a primary agent-workspace workload source. The reusable
workload pieces are:

- workspace import into a Redis-backed live namespace;
- grep/search correctness over workspace content;
- tree/find/read/head/line-window file operations;
- query/search and checkpoint/fork/sync lifecycle operations from the wider
  codebase.

For paper claims:

- cite the current CLI/local Redis fallback runs as adapted workload
  reproduction, not as unmodified upstream benchmark reproduction;
- do not cite RedisSearch indexed performance as reproduced;
- use the workload shape to design a Make-owned KVM `namei_ext` agent
  workspace/query workload with explicit correctness-first gates.

## Remaining Risks

- The Docker `redis:8` / RedisSearch server path now starts and passes the
  adapted current-CLI markdown workload, but the public CLI markdown path does
  not exercise the older indexed grep backend.
- The official 4000-file, 8192-byte default benchmark was not run in this
  record.
- These runs are external-source reproduction, not Phase 1 `namei_ext` KVM
  validation.
