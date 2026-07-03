# DeltaFS, YoloFS, AgentFS, IndexFS, and TableFS Workload Audit

Date: 2026-06-30

Correction on 2026-07-01: the YoloFS source-status part of this audit is
historical. Public YoloFS filesystem code was later found and partially
reproduced; see
`docs/tmp/2026-07-01-yolofs-public-artifact-reproduction-update.md`. The
agent/perf evaluation submodules remain unavailable, so the original YoloFS
agent/perf benchmark still has not been reproduced.

## Motivation

This audit revisits the earlier source-role decision for DeltaFS, YoloFS,
AgentFS, IndexFS, and TableFS. The earlier wording was too strong where it
implied that several of these systems could not be implemented or reproduced.
The corrected distinction is:

- original YoloFS implementation: not found in this 2026-06-30 survey, but
  public filesystem code was found in the 2026-07-01 follow-up;
- YoloFS-like workload/oracle: implementable from the paper;
- AgentFS, Redis AFS, Mirage: public code and useful agent-filesystem workload
  sources;
- DeltaFS, IndexFS, TableFS: public code and real workload shapes, but mostly
  full-filesystem or metadata-service evaluations rather than direct
  `namei_ext` main workloads.

The goal is not to prove another mechanism cannot work. The goal is to select
real, reproducible workload sources that test useful path-view behavior,
correctness oracles, state transitions, and natural baseline comparisons.

## Sources Inspected

Code and artifact sources inspected locally under `.cache/source-inspection/`:

- `tursodatabase/agentfs`
- `redis/agent-filesystem`
- `strukto-ai/mirage`
- `pdlfs/deltafs`
- `pdlfs/deltafs-umbrella`
- `pdlfs/deltafs-vpic-preload`
- `pdlfs/indexfs`
- `zhengqmark/indexfs-0.4`
- `pdlfs/tablefs`
- original TableFS tarball from `https://www.cs.cmu.edu/~kair/code/tablefs-0.3.tar.gz`

Paper text inspected from local references:

- `docs/reference/arxiv2604.13536-yolofs.pdf`
- `docs/reference/sc21-zheng-deltafs.pdf`
- `docs/reference/pdsw17-zheng-deltafs-indexed-massive-directory.pdf`
- `docs/reference/sc14-ren-indexfs.pdf`
- `docs/reference/atc13-ren-tablefs.pdf`

## Corrected Verdict

### YoloFS

Historical 2026-06-30 status: I did not find the original public YoloFS
implementation in this survey. Search results found the paper and unrelated
repositories, but not the Linux stackable filesystem implementation described
by the paper.

2026-07-01 correction: public YoloFS filesystem code is now identified at
`https://github.com/YoloFS/filesystem`, with a public umbrella at
`https://github.com/YoloFS/YoloFS` and public site at `https://yolofs.github.io`.
Main/compat unit tests pass and the compat kmod builds. The original agent/perf
evaluation submodules are not accessible, so the benchmark reproduction status
remains incomplete.

That does not mean we cannot use YoloFS. The paper is specific enough to build
a YoloFS-like workload and oracle:

- workload categories: hidden destructive side-effect tasks and routine
  agent-file tasks;
- key behaviors: staging redirects mutations, snapshots restore or branch
  state, progressive permission gates accesses;
- oracle: compare final filesystem state against an expected tree including
  existence, content, and permissions; record task success, permission prompts,
  tool calls, and raw session logs;
- representative tasks: formatter, package build, or lint command with hidden
  deletion or overwrite side effects, followed by agent detection and recovery.

For `namei_ext`, a full YoloFS clone is not the right target because YoloFS
owns write/create/delete staging, journaling, snapshot, and commit semantics.
The useful experiment is a YoloFS-like agent path-view subset: protected paths,
workspace/session epochs, staging-visible paths, and final filesystem-state
oracles. The paper can cite YoloFS as methodology, motivation, and partial
public filesystem artifact evidence, but must not claim that we reproduced the
original YoloFS agent/perf benchmark unless the unavailable submodules are
released and run.

### AgentFS

Turso AgentFS is public and directly useful. The repository includes:

- CLI commands for `init`, `exec`, `run`, `mount`, `serve mcp`, `serve nfs`,
  `sync`, and `checkpoint`;
- Linux FUSE and macOS NFS mount surfaces;
- copy-on-write overlay mode through `--base`;
- experimental sandbox execution;
- SQLite-backed filesystem, key-value store, and tool-call audit schema;
- examples for Claude Agent SDK, OpenAI Agents, Mastra, Firecracker, AI SDK,
  and Cloudflare;
- test guidance for pjdfstest and xfstests;
- syscall tests and overlay/whiteout/symlink/run/git tests;
- an npm-like performance script with an observed operation mix dominated by
  lookup, create, mkdir, readdir, write, flush, release, chmod, stat, and
  access.

This is the best immediate source for an agent-filesystem workload. We should
not compare against AgentFS as if it were a narrow path hook. Instead, use it
to define realistic agent workspace lifecycle operations and, where useful, as
a FUSE/NFS/SQLite-backed baseline family.

### Redis Agent Filesystem

Redis AFS is public and code-backed. It provides:

- `make`, Docker Compose, Go tests, and a large CLI/control-plane codebase;
- workspace create/import/mount/unmount/fork operations;
- checkpoint create/list/restore operations;
- sync mode and live mount mode;
- Redis-backed workspace state, manifests, blobs, metadata, live roots, and
  checkpoint history;
- workspace-first MCP tools for file read/write/search and checkpoint
  operations;
- query and grep surfaces over workspace contents.

This is a strong source for per-agent workspace setup/update, checkpoint,
fork, move, and query workloads. It is more relevant to the agent lifecycle
story than DeltaFS/IndexFS/TableFS.

### Mirage

Mirage is public and code-backed. It implements a unified VFS for agents over
many backends such as RAM, disk, Redis, S3, Google Drive, Slack, Gmail, GitHub,
Notion, Postgres, and more. It includes:

- Python and TypeScript SDKs;
- CLI workspace create/execute/provision/snapshot/load commands;
- FUSE-related integration tests;
- conformance cases for `cat`, `cmp`, `du`, `file`, `find`, `grep`, `head`,
  `ls`, `md5`, `stat`, `tree`, and `wc`;
- cross-mount tests for copy, multi-file read, diff/cmp, `cd` across mounts,
  and warm cache behavior after out-of-band mutation.

Mirage is useful if we choose a multi-backend namespace workload. It is lower
priority than AgentFS/Redis AFS for the immediate workspace setup/update story.

## DeltaFS, IndexFS, and TableFS Workloads

| System | Code status | Workloads used by the system or paper | Relevance to `namei_ext` |
| --- | --- | --- | --- |
| DeltaFS PDSW17 / VPIC | Public: `pdlfs/deltafs`, `pdlfs/deltafs-umbrella`, `pdlfs/deltafs-vpic-preload`; umbrella includes VPIC, VPIC decks, and preload modules. | VPIC file-per-particle output, trajectory reads, LD_PRELOAD redirect into DeltaFS, baseline VPIC output, small validation run and large HPC runs. `deltafs/benchmarks/vpic_io` also simulates one-file-per-particle write pattern. | Real and reproducible in principle, but heavy and HPC-specific. Good source for path-index or trajectory workload shape, not the main agent workload. |
| DeltaFS SC21 | Public DeltaFS code; paper uses mdtest and synthetic multi-stage workflows. | Massive metadata create/stat workloads, each process creating and randomly stating hundreds of thousands of files; seven-stage snapshot workflow that doubles namespace size per stage. | Good metadata/snapshot workload shape. It mainly evaluates metadata ownership, LSM snapshots, and compaction, which are outside the narrow name-resolution hook. |
| IndexFS SC14 | Original public repo: `zhengqmark/indexfs-0.4`; DeltaFS reimplementation: `pdlfs/indexfs`. | HDFS/PVFS/Lustre metadata and small-file comparison, mdtest create/stat/delete in a large shared directory, N-N checkpoint/bulk insertion, standalone test creating and stating 8000 files, `io_driver` tasks for tree, replay, cache, RPC, and SST compaction. | Useful as a full metadata-service baseline and workload-shape source. Directly reproducing IndexFS would test distributed metadata middleware, not `namei_ext` path-view value. |
| TableFS ATC13 | Original tarball public and downloadable; DeltaFS reimplementation public. | Linux kernel unpack/search/build/compress, Postmark with many small files, metadata microbenchmarks for create/query/rename/delete/readdir/readdir+stat/readdir+read. Original source has FUSE `tablefs` and `fsbench` workloads: `metadatacreate`, `metadataquery`, `onedircreate`, `onedirquery`, `smallfilecreate`, `smallfilequery`, `scanquery`, `lsstatquery`, `scanfilequery`, `renamequery`, `deletequery`. | Reproducible and useful for conventional metadata-heavy baselines. It is a full FUSE/LSM filesystem, so it should be related work or appendix workload shape, not the main agent path-view source. |

## Recommended Workload Selection

The next experiment should use code-backed agent filesystem sources first:

1. **AgentFS / YoloFS-like hidden-side-effect workload.** Build a small agent
   workspace task suite with protected files, hidden destructive scripts,
   final tree oracle, permission/rejection log, and path operation trace. Use
   AgentFS semantics and YoloFS paper methodology; do not claim original
   YoloFS reproduction.
2. **Redis AFS checkpoint/fork workspace lifecycle.** Use create/import,
   mount, checkpoint, fork, restore, search/query, and local-tool execution as
   workload sources. This directly matches per-agent workspace setup/update.
3. **Optional Mirage multi-backend namespace case.** Use cross-mount copy,
   grep, cache warm/cold, and out-of-band mutation only if the paper wants a
   multi-service namespace workload.
4. **Optional TableFS-derived metadata appendix.** Use kernel tree or fsbench
   metadata operations only as a conventional metadata-heavy comparison, not as
   the central novelty workload.
5. **Optional DeltaFS-derived VPIC appendix.** Use a reduced VPIC/particle path
   workload only if we want an HPC-flavored path-index case. Full DeltaFS/VPIC
   reproduction is likely too heavy for the mainline artifact.

## Implication for Claims

The corrected claim is not "other systems cannot be reproduced" and not
"these workloads prove a static table cannot work." The better claim target is:

`namei_ext` can express useful, dynamic path views for real agent/service/cache
workloads through a narrow VFS name-resolution hook, while avoiding the need to
own full filesystem metadata, data storage, write semantics, or a userspace
daemon for every extension.

Evidence needed for that claim:

- source-backed workload provenance;
- workload-level correctness oracle;
- operations during state transitions;
- operation-weighted path-resolution signal;
- natural baseline comparison for the mechanism family;
- safety and semantic-boundary evidence;
- explicit negative or scoped verdict when a natural baseline is equally good.

## Remaining Risks

- AgentFS and Redis AFS may be better complete systems for agent workspaces
  than a narrow path hook. If so, the paper should state the boundary and
  compare the mechanism scope rather than forcing a win.
- A YoloFS-like workload is not a YoloFS reproduction. The paper must keep that
  wording precise.
- DeltaFS/IndexFS/TableFS can consume substantial effort without moving the
  `namei_ext` claim, because their strongest contributions are metadata
  ownership, indexing, compaction, and full filesystem design.
