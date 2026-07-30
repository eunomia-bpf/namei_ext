# Result Review: RQ1 XDG Documents Portal Source Oracle Formal01

## Verdict

- Run status: valid.
- Hypothesis: supported.
- Research value: supporting RQ1 source-fidelity evidence.
- Paper effect: the Sandboxed Application File Sharing row is now controlled
  by the official source implementation rather than only by a
  documentation-derived probe.

The result does not independently answer RQ1 and does not add a new industrial
workflow.

## Frozen Protocol And Execution

The reviewed plan is:

`docs/tmp/2026-07-29-application-file-sharing-source-oracle-rq1-plan.md`.

The unchanged formal experiment ran through:

```text
make experiment-application-file-sharing-source-oracle-rq1 \
  RUN_ID=20260730T-xdg-source-formal01
```

Raw result root:

```text
results/experiments/application-file-sharing-source-oracle-rq1/
  20260730T-xdg-source-formal01/
```

The run completed three fresh modified-kernel KVM boots. Each boot first ran
the official source mechanism, required an empty midpoint BPF/FUSE inventory,
and then ran the `namei_ext` mechanism. There was no plan deviation.

The recorded provenance is:

- clean project commit
  `6836ea6cb8ce2a702aab28bb3753701b24df33e0`;
- clean modified-kernel commit
  `621aff8d1bb52fad718f11fd882c956d6a5686ae`;
- guest kernel `7.1.0-rc7-g621aff8d1bb5`;
- official `xdg-document-portal` release `1.18.4`, commit
  `11c8a96b147aeae70e3f770313f93b367d53fedd`; and
- exact guest binary version `xdg-desktop-portal 1.18.4`.

All five pinned upstream `test-doc-portal` subtests executed with zero failure,
skip, or timeout. Those tests are dependency evidence; the formal source arm
supplies the RQ1 behavior.

## Independent State Recalculation

The independent review recomputed the oracle from per-operation fields without
using controller `pass` values or the generated analysis summary. In every
boot, both mechanisms produced exactly this state sequence:

| State | Official portal | `namei_ext` |
| --- | --- | --- |
| application A before grant | hidden | hidden |
| application B before grant | hidden | hidden |
| application A after grant | visible | visible |
| application B during A grant | hidden | hidden |
| application A after revoke | hidden | hidden |

For each hidden state, document `stat`, payload `stat`, and payload open/read
returned `ENOENT`; a fresh parent enumeration completed and omitted the
document. For each visible state, document and payload operations succeeded,
enumeration listed the document, and a complete read through EOF matched the
fixed 27-byte payload.

Across the three boots, the raw result contains:

- 15/15 official-source states;
- 15/15 `namei_ext` states;
- 3 visible and 12 hidden states for each mechanism; and
- exact source/`namei_ext` agreement on every operation result, directory
  membership result, and visible-byte comparison.

`GrantPermissions` and `RevokePermissions` were each followed by one immediate
complete source observation, with no sleep, polling, retry, or discarded first
result. The `namei_ext` arm followed the same rule after its policy-map update.

## Object And Mechanism Evidence

In every `namei_ext` visible state, logical and registered lower identities
matched:

```text
document: dev=49 ino=17
payload:  dev=50 ino=477
```

The official portal has its own FUSE inode space, so source and `namei_ext`
inode numbers are not compared. The common oracle is operation behavior,
visibility, and bytes; direct lower-object identity is additional evidence for
the `namei_ext` ownership boundary.

Both mechanisms preserved the direct lower object's device, inode, regular-file
mode `100644`, UID/GID, size, mtime, ctime, and bytes in all three boots. Every
unrelated-object control remained readable with its expected bytes.

Each `namei_ext` boot recorded:

```text
lookup=210
readdir=30
select=3
hide_lookup=12
hide_readdir=4
```

These counters establish mechanism engagement but do not define the
application-visible oracle.

## Cleanup And Kernel Health

All guest, controller, inventory, and dmesg status files returned zero. The
official portal exited with code zero, and the permission store terminated with
the controller's expected `SIGTERM`. Before, midpoint, and after inventories
contained no residual BPF program, cgroup attachment, FUSE mount, or open
`/dev/fuse` descriptor. Policy detach, target clearing, and both application
cgroup removals succeeded in every boot.

The three dmesg logs contain no project-relevant BUG, warning, oops, panic,
hung-task, sanitizer, protection-fault, or RCU-stall diagnostic.

## Independent Review

A fresh read-only reviewer audited all three raw boots, the frozen plan,
implementation, source provenance, upstream tests, arm ordering, state
operations, identities, metadata, bytes, process status, counters, inventories,
exit status, and dmesg. The reviewer found no P0 or P1 issue and classified the
run as valid supporting evidence.

Two P2 artifact limitations do not alter the oracle:

1. per-state logical-path bytes are recorded as the result of an exact complete
   comparison rather than duplicated as raw payload files; and
2. the private D-Bus session is torn down by the source controller, but its
   process exit is not recorded separately from the successful controller and
   service cleanup.

Neither limitation changes the observed grant, isolation, revoke, lower-object,
or cleanup behavior. Adding more artifact bookkeeping would not add
paper-level evidence, so the valid completed result is not rerun.

## Supported Claim

The result supports this bounded claim:

> Across three fresh modified-kernel KVM boots, `namei_ext` reproduced the
> existing-object read-grant, per-application isolation, and immediate-revoke
> behavior observed from official `xdg-document-portal` 1.18.4. Lookup, open,
> complete reads, and directory enumeration agreed state by state, while the
> `namei_ext` path selected the registered lower object and preserved lower
> filesystem metadata and data.

It does not establish complete Documents portal compatibility, general sandbox
identity enforcement, persistent grants, synthetic hierarchy or metadata
semantics, write behavior, portal UI integration, performance, or RQ1 in full.
