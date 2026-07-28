# Agent Workspace RQ2 Preflight v2

Date: 2026-07-27

## Motivation

Preflight v2 tested the scoped-policy fix from v1 in two fresh KVM boots. The
`namei_ext` condition completed, but the FUSE condition failed its final
engagement gate. This record preserves the observed behavior and the corrected
gate.

## Execution

The preflight was started through:

```text
make kvm-agent-workspace-rq2-preflight \
  RUN_ID=20260727T-agent-workspace-rq2-preflight-v2
```

The preserved result root is:

```text
results/experiments/agent-workspace-rq2-preflight/
  20260727T-agent-workspace-rq2-preflight-v2/
```

The run is bound to source commit
`a02d0c915bccbcdc2ca683eeebccdd9084182f3d` and kernel commit
`bdc9a83e3dfbef8ff2017f9188c7c86025962183`.

## Namei_ext Result

The `namei_ext` boot completed. It passed the source-derived workspace oracle,
all required scope rows, 20 lifecycle samples, all five path-operation sample
families, policy engagement counters, kernel identity checks, stable
clocksource check, and dmesg gate. In particular:

- `policy_scope_exact_view`, `policy_scope_add_base`, and
  `policy_scope_add_upper` passed;
- an unscoped `deleted.txt` remained visible;
- logical `deleted.txt` remained hidden in lookup and readdir;
- lower base contents were readable and unchanged after detach.

This confirms that the v1 failure was fixed without changing the workload
oracle.

## FUSE Failure

The FUSE boot passed all correctness rows, all 20 lifecycle samples, all path
operation samples, five successful targeted invalidations, resource-window
accounting, and unmount. It failed only because the runner required the FUSE
`.mknod` callback counter to be nonzero.

The raw callback counts included:

```text
create  22
mknod    0
rename  22
unlink  21
```

The lifecycle invokes the userspace `mknod()` API with `S_IFREG`. Linux
`filename_mknodat()` handles `S_IFREG` by calling `vfs_create()`, while device,
FIFO, and socket types call `vfs_mknod()`. A FUSE filesystem therefore receives
these regular-file operations through its `.create` callback. The 22 observed
create callbacks are the 20 timed lifecycle creates plus the two earlier
workspace file creates.

Relevant inspected code:

```text
kernel/fs/namei.c:5368-5405
experiments/agent_workspace/namei_ext_agent_workspace_fuse.c:694-746
experiments/agent_workspace/namei_ext_agent_workspace_fuse.c:977-1007
```

## Forward Fix

The RQ2 engagement gate now requires a nonzero `create` counter and records the
`mknod` counter without requiring it to be nonzero. The application operation,
timed region, FUSE implementation, correctness oracle, and sample counts are
unchanged.

The next preflight must use a new run ID. The v2 result remains failed and is
not reused as formal evidence.
