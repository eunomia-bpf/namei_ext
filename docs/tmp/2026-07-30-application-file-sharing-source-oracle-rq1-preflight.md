# Application File Sharing Source-Oracle RQ1 Preflight

## Role

This record covers the one-boot dependency preflight required before the
three-boot Sandboxed Application File Sharing source-oracle experiment. It is
not paper evidence and does not by itself upgrade W1.

Frozen plan:
`docs/tmp/2026-07-29-application-file-sharing-source-oracle-rq1-plan.md`.

Reviewed implementation:
`docs/tmp/2026-07-30-application-file-sharing-source-oracle-rq1-implementation.md`.

## Execution

The committed implementation ran through:

```text
make kvm-application-file-sharing-source-oracle-preflight \
  RUN_ID=20260730T-xdg-source-preflight01
```

Raw root:

```text
results/experiments/application-file-sharing-source-oracle-rq1-preflight/
  20260730T-xdg-source-preflight01/
```

The run used clean project commit
`bbbfa0ed40758888fe87fa6ee03a56ecc1562b21`, clean modified-kernel commit
`621aff8d1bb52fad718f11fd882c956d6a5686ae`, and guest release
`7.1.0-rc7-g621aff8d1bb5`.

The source control was official `xdg-document-portal` release `1.18.4`,
commit `11c8a96b147aeae70e3f770313f93b367d53fedd`. All five pinned upstream
`test-doc-portal` subtests executed with zero skip, failure, or timeout.

## Frozen Oracle

The official portal and `namei_ext` each produced exactly one observation for
all five frozen states:

| State | Expected | Official portal | `namei_ext` |
| --- | --- | --- | --- |
| application A before grant | hidden | exact hidden tuple | exact hidden tuple |
| application B before grant | hidden | exact hidden tuple | exact hidden tuple |
| application A after grant | visible | exact visible tuple | exact visible tuple |
| application B during A grant | hidden | exact hidden tuple | exact hidden tuple |
| application A after revoke | hidden | exact hidden tuple | exact hidden tuple |

For every hidden state, document stat, payload stat, and payload open/read
returned `ENOENT`; parent enumeration completed and omitted the document. In
the one visible state, all operations completed, enumeration included the
document, and the complete read matched the fixed 27-byte payload.

The visible `namei_ext` logical and registered lower identities also matched:

```text
document: dev=49 ino=17
payload:  dev=50 ino=477
```

## Engagement And Preservation

The `namei_ext` policy recorded:

```text
lookup=210
readdir=30
select=3
hide_lookup=12
hide_readdir=4
```

Both mechanisms preserved lower-object device, inode, regular-file mode
`100644`, UID/GID, size, mtime, ctime, and exact bytes.

The official portal exited with code zero. The permission store terminated
with the controller's expected `SIGTERM`. The portal FUSE mount was removed.
Before, midpoint, and after inventories contained no residual BPF program,
cgroup attachment, FUSE mount, or open `/dev/fuse` descriptor. Policy detach,
target clearing, and both application-cgroup removals succeeded.

All guest, controller, inventory, and dmesg status files are successful.
The captured dmesg contains no project-relevant warning, BUG, oops, call
trace, hung-task, sanitizer, or protection-fault diagnostic.

## Independent Review

A fresh read-only reviewer recomputed the five-state oracle from
operation-specific raw fields without trusting controller `pass` values or
the generated analysis. The reviewer also checked provenance, pinned source
and version, upstream tests, source-first ordering, midpoint isolation,
logical/lower identity, metadata and byte preservation, policy counters,
teardown, inventories, and dmesg.

The review reported no P0, P1, or P2 finding and classified the preflight as:

```text
Preflight status: VALID
Research value: dependency-only
Unchanged three-boot formal run: AUTHORIZED
```

## Disposition

The preflight closes the execution dependency for the unchanged three-boot
formal experiment. The formal entrypoint may now enter the aggregate case
study registry. Every formal boot must still satisfy the complete frozen
oracle, and a fresh independent reviewer must validate the formal raw root
before any paper-facing claim or evaluation update.
