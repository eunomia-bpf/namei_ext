# Redis AFS Indexed Search Workload Reproduction Follow-Up

Date: 2026-07-01

## Motivation

The earlier Redis AFS markdown workload record reproduced the current CLI
markdown search/file-operation workload only through a local Redis fallback.
This follow-up checks whether the RedisSearch-backed indexed path can be
reproduced, and separates three different facts:

- whether a public Redis image provides Search;
- whether the markdown workload can run against that Search-capable Redis;
- whether the public CLI markdown workload actually uses the indexed grep
  backend.

## Source

- Source tree:
  `.cache/source-inspection/redis-agent-filesystem`
- Upstream commit:
  `990b8eb7abff1bb51d35abf4ba9829963b679de2`
- Files inspected or adapted:
  `tests/bench_md_workloads/main.go`, `cmd/afs/afs_search_index.go`,
  `cmd/afs/afs_grep.go`, `cmd/afs/fs_remote_commands.go`, and
  `cmd/afs/sync_control.go`.

## Raw Evidence

Result root:

- `results/reproduction/2026-07-01-official-workloads/redis-afs-md-indexed-search/`

Important files:

- `redis8-search-probe.log`
- `redis8-search-probe.status`
- `indexed-small-run.log`
- `indexed-small-run.status`
- `indexed-small-run-v3-profile/report.json`
- `indexed-small-run-v3-profile.log`
- `indexed-grep-tests.log`
- `indexed-grep-tests.status`
- `summary.json`

## Adaptations

The cached external source has local adaptations for reproduction:

- `tests/bench_md_workloads`: `afs ws import` changed to `afs vol import`;
- `tests/bench_md_workloads`: `afs grep --workspace <name>` changed to
  `afs fs <workspace> grep`;
- `cmd/afs/afs_search_index.go`: Redis 8's
  `SEARCH_INDEX_NOT_FOUND` / `Index not found` error string is treated as a
  missing index;
- `tests/bench_md_workloads`: grep profile env pass-through was attempted for
  evidence only.

These are source-cache adaptations, not `namei_ext` project changes and not an
upstream Redis AFS claim.

## Results

`redis:8` is a valid Search-capable Redis image on this host. The probe pulled
`redis:8` with digest
`redis@sha256:2838d5524559494f6f1cd66e97e76b200d64a633a8614200620755ed395daf32`,
started Redis 8.8.0, loaded the Search module, and `FT._LIST` exited 0.

Before the Redis 8 error-string compatibility patch, the Search-capable
markdown run still failed during live workspace initialization:

```text
SEARCH_INDEX_NOT_FOUND Index not found: afs:idx:{ws_d15656d44434bf00}:v1
```

After the compatibility patch, the adapted current-CLI markdown workload ran on
Docker `redis:8` and passed:

- corpus: 200 markdown files, 24 dirs, about 1.6 MiB;
- Redis source: `docker redis:8`;
- grep rare/common/regex validations: all `identical normalized output`;
- ripgrep rare/common/regex validations: all `identical normalized output`;
- nearby file-operation validations:
  `counts match (249)`, `counts match (50)`, `counts match (792149)`,
  `counts match (75834)`, and `counts match (49587)`.

The targeted `go test ./cmd/afs -run 'Test.*Grep|Test.*SearchIndex|Test.*Indexed'`
run also passed, including
`TestRunIndexedGrepTargetsLoadsExternalAndInlineContent`.

## Indexed Path Verdict

The public current CLI markdown workload should not be claimed as an indexed
RedisSearch grep reproduction.

Reason: the adapted benchmark must call `afs fs <workspace> grep` because the
current CLI no longer accepts the old upstream benchmark command shape. That
route dispatches to `cmdFSGrep` in `cmd/afs/fs_remote_commands.go`, which
collects control-plane grep targets and scans content. The older indexed grep
backend lives under `cmdGrep` / `runFastGrep` in `cmd/afs/afs_grep.go`, and is
covered by internal tests, but it is not the public CLI path exercised by the
adapted markdown benchmark.

Therefore the accurate claim is:

- Redis AFS contributes a reproducible current-CLI markdown
  search/file-operation workload on both local Redis fallback and Docker
  Redis 8 Search-capable Redis;
- Redis AFS also has internal indexed-helper test evidence;
- do not claim the public markdown benchmark reproduced indexed RedisSearch
  performance or indexed CLI behavior.

## Reuse Decision

Use Redis AFS as a primary workload source for workspace import, live namespace
reads, content search semantics, tree/find/read/head/line-window operations,
checkpoint/fork/sync lifecycle, and query/search concepts.

For `namei_ext`, the useful next step is not more RedisSearch debugging. The
Make-owned KVM workload should take the Redis AFS workload shape and implement
a path-view policy/oracle in the modified kernel, while citing the Redis AFS
indexed path only as internal source-system implementation detail.

## Remaining Risks

- The full default 4000-file markdown benchmark was not rerun in this
  follow-up.
- The public CLI path still does not provide indexed grep evidence.
- This is external-source reproduction, not Phase 1 `namei_ext` KVM validation.
