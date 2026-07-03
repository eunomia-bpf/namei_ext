# Redis AFS Lifecycle Workload Reproduction

Date: 2026-07-02

## Motivation

Redis Agent Filesystem is a primary agent-workspace workload source because it
models workspaces as Redis-backed, checkpointable, forkable filesystem-shaped
state. Earlier records reproduced markdown/search workloads and some smoke
commands from a dirty checkout. This record uses a fresh checkout and isolates
the lifecycle run in a new result root.

The goal is to reproduce the official README-style lifecycle shape:
configure Redis, create a workspace, import a local directory, mount it, query
content, create checkpoints, create bookmarks, fork a volume, and unmount. This
is source-backed workload evidence, not a claim that Redis AFS needs
`namei_ext` or eBPF.

## Source

- Repository: `https://github.com/redis/agent-filesystem.git`
- Fresh local checkout: `.cache/source-inspection/redis-agent-filesystem-lifecycle-20260702`
- Commit: `990b8eb7abff1bb51d35abf4ba9829963b679de2`
- Go: `go version go1.22.2 linux/amd64`
- Redis: `Redis server v=7.0.15`

The fresh checkout remained clean after the run according to `git status
--short`. The existing older checkout under
`.cache/source-inspection/redis-agent-filesystem` remains dirty from previous
adapted benchmark work and was not used for this lifecycle run.

## Raw Artifacts

Result root:
`results/reproduction/2026-07-02-official-workloads/redis-afs-lifecycle/`

Important files:

- `git-clone.log`
- `make-afs.log`
- `lifecycle-smoke.log`
- `lifecycle-smoke.status`
- `lifecycle-smoke-v2.log`
- `lifecycle-smoke-v2.status`
- `lifecycle-smoke-v3.log`
- `lifecycle-smoke-v3.status`
- `lifecycle-smoke-v4.log`
- `lifecycle-smoke-v4.status`
- `inotify-sysctl-raise.log`
- `inotify-sysctl-raise.status`
- `query-keyword.json`
- `query-v2-keyword.json`
- `query-v4-keyword.json`
- `summary.json`

## Commands And Results

Build:

```text
git clone https://github.com/redis/agent-filesystem.git .cache/source-inspection/redis-agent-filesystem-lifecycle-20260702
make afs
```

Both commands passed.

`lifecycle-smoke` and `lifecycle-smoke-v2` passed with isolated local Redis
servers. Across those runs, the following lifecycle operations executed:

- set isolated `afs.config.json`;
- set `redis.url` to an isolated local Redis database;
- set mode to `sync`;
- create Agent Workspace manifest;
- import a local directory into a named volume with `ws add`;
- mount the workspace under a local root;
- list workspace contents with `fs --volume <volume> ls`;
- query workspace content with keyword query, producing JSON with status `ok`
  and three results;
- create and list checkpoints;
- create and list a workspace bookmark;
- fork the volume and list both source/fork volumes;
- unmount the workspace;
- shut down the isolated Redis server.

`lifecycle-smoke-v3` intentionally tried to exercise a stronger write oracle
using `fs --volume <volume> create-exclusive`; it failed and is preserved as a
negative/caveat artifact.

After the first mounted-edit attempts failed with watcher allocation errors, I
diagnosed host inotify state. `/proc/sys/fs/inotify/max_user_watches` was
`524288`, and VS Code process PID 108856 held 523947 watch descriptors. I
raised the host limit with:

```text
sudo -n sysctl -w fs.inotify.max_user_watches=1048576
```

The command succeeded and is recorded in `inotify-sysctl-raise.log`. This host
sysctl change is not a repository artifact and may reset on reboot or manual
configuration.

`lifecycle-smoke-v4` passed after the inotify raise and no longer showed the
`no space left on device` watcher allocation failure. It also produced a
keyword query JSON with status `ok` and three results. However, the stronger
mounted-edit oracle still did not pass: `fs get docs/policy.txt` printed only
the original imported content, `fs find . -name new-note.md -print` printed no
created mounted file, the fork grep printed no match, and checkpoint diff
reported zero changes.

## Positive Evidence

The independent summary records these positive checks:

- workspace create: passed;
- workspace add/import: passed;
- workspace mount: passed;
- `fs ls`: passed;
- keyword query: `status="ok"` with three results in v1, v2, and v4;
- checkpoint create/list: passed;
- workspace bookmark create/list: passed;
- volume fork/list: passed;
- workspace unmount: passed;
- isolated Redis shutdown: passed.

## Caveats

The mount logs reported:

```text
afs sync: cannot watch ...: no space left on device
```

That was a host-level watcher exhaustion condition in v1/v2. Raising
`fs.inotify.max_user_watches` to `1048576` removed that allocation error in v4,
but mounted local edits still cannot be claimed as passing synchronization
evidence from this run. Edits made under the mounted directory did not appear
in `afs fs get/find` or the fork grep, and checkpoint diff reported zero
changes.

The v3 `create-exclusive` attempt failed with:

```text
Workspace is not supported with fs create-exclusive; use the mounted sync workspace.
```

Therefore the safe claim is lifecycle, query, checkpoint, bookmark, fork, and
mount/unmount evidence. Do not claim live mounted edit synchronization, full AFS
write semantics, RedisSearch indexed query performance, or full POSIX behavior
from this run.

## Reusable Workload Shape

Redis AFS remains useful for `namei_ext` as an agent workspace lifecycle source:

- Redis-backed source of truth;
- workspace manifest creation;
- folder import into named volumes;
- local mount and unmount;
- queryable workspace contents;
- explicit checkpoints;
- workspace bookmarks;
- volume forks.

For a `namei_ext` KVM workload, the reusable subset should focus on path-view
state transitions and source-system oracles. The Redis AFS run should be used
alongside AgentFS, BranchFS, Sandlock, Mirage, OpenHands SDK, SWE-agent, and
SWE-ReX rather than as a standalone claim that AFS itself is replaceable.
