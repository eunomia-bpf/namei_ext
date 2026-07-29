# Kubernetes ConfigMap Publication RQ1 Formal Result

## Question

Can bounded leaf-level `SELECT` and `HIDE` actions under one stable logical
volume root reproduce the tested payload-view subset of Kubernetes
`AtomicWriter` publication while ordinary VFS and lower-filesystem semantics
remain in the kernel?

This is a supporting RQ1 result. It is not a performance comparison and does
not reproduce the complete Kubernetes projected-volume implementation.

## Provenance

The formal Make-owned command was:

```text
make kvm-kubernetes-configmap-publication-rq1 \
  RUN_ID=20260729T-kubernetes-configmap-publication-rq1-01
```

The immutable raw root is:

```text
results/experiments/kubernetes-configmap-publication-rq1/20260729T-kubernetes-configmap-publication-rq1-01
```

The run records clean source commit
`fd63add60139b5343f01d99a52ac7385ac8c9255`, clean kernel commit
`621aff8d1bb52fad718f11fd882c956d6a5686ae`, kernel release
`7.1.0-rc7-g621aff8d1bb5`, and `CONFIG_NAMEI_EXT=y`.

The source-positive control imports the official Kubernetes v1.30.0
`pkg/volume/util` package at commit
`7c48c2bd72b9bf5c44d21d7338cc7bea77d0ad2a`. Its captured source and tests
match that pinned release. `TestWriteOnce`, `TestUpdate`, and
`TestMultipleUpdates` passed.

## Formal Matrix

All three fresh modified-kernel KVM boots completed. Each boot executed:

```text
V0 initial -> V1 update -> V1 no-op -> V0 rollback
```

The aggregate contains 204 raw records, 68 per boot, with no observation whose
`pass` field is false.

- 12/12 official `AtomicWriter` states passed.
- 12/12 `namei_ext` states passed.
- 6/6 direct lower-generation controls passed.
- 24/24 stable-root directory-descriptor checks passed.
- 12/12 old-file-descriptor checks passed.
- 36/36 lower-object preservation checks passed.
- 72/72 attach, state, cleanup, and unmanaged-view lifecycle cases passed.

Each boot used one recorded non-root identity, UID/GID 1000:1000. All 90
present payload-file observations had that owner. All 30 source, direct, and
logical consumers cleared supplementary groups and read both the selected
`app.conf` and `cert.pem`; this includes 15 V1 consumers reading mode 0600 and
0400 files.

For every logical state, the selected files matched the direct lower objects'
device and inode identity. Across all boots, 36/36 present logical files
matched. The stable volume-root descriptor retained its own identity while
`openat()` followed V0, V1, V1, and V0. Old V0 file descriptors retained their
original bytes and identity after update and rollback.

The official source no-op retained all three V1 file identities, while source
rollback allocated three new V0 objects. The `namei_ext` no-op retained all
three selected V1 objects, while rollback reselected all three original V0
lower objects.

Each boot recorded the same policy-action counts:

```text
total=990 lookup=938 readdir=52 select=39 pass=939 hide=12
```

The event and action partitions both close exactly. Before and after every
boot, the external inventory found no residual BPF program, cgroup attachment,
FUSE mount, or open `/dev/fuse` descriptor.

## Lower-Filesystem Semantics

For each boot, the twelve-line lower-object inventories before and after policy
execution are identical across type, mode, UID, GID, device, inode, size,
mtime, and ctime. Regular-file bytes also match. The selected objects therefore
retain their lower-filesystem identity and metadata; the policy changes only
which existing leaf is returned or hidden.

All three dmesg captures contain no configured project failure signature and no
`namei_ext`, verifier, oops, or call-trace diagnostic. They do contain unrelated
virtme startup messages, ACPI `AE_ERROR`, and missing `regulatory.db` noise, so
the result must not be described as literally warning-free.

## Independent Review

An independent result reviewer recomputed the state, descriptor, ownership,
identity, preservation, counter, cleanup, dmesg, and provenance oracles from
the raw per-boot files. It returned `GO` with no blocking or major finding.

The review found one finalizer coverage improvement: the explicit
`AtomicWriter` no-op and rollback identity gates checked only `app.conf`.
Independent recomputation confirmed all three present files in every boot. The
finalizer now checks all three, and the strengthened finalizer passes against a
temporary copy of the complete formal result.

## Supported Claim

Across three fresh modified-kernel KVM boots, leaf-level `SELECT` and `HIDE`
under a stable logical root reproduced the tested Kubernetes `AtomicWriter`
payload-view sequence V0 to V1 to V1 no-op to V0 rollback, including
visible-name membership, lower-object identity, non-root mode-sensitive reads,
stable root descriptors, and old file descriptors, without changing the
pre-existing lower objects.

## Scope

The result covers already materialized V0 and V1 regular files and visible-name
readdir membership. It does not cover ConfigMap retrieval, payload
construction, timestamp-directory or symlink materialization, `..data`,
`lstat`, `readlink`, dirent inode/type equivalence, inotify/fanotify,
concurrent-update snapshots, application reload, writes after lookup,
performance, FUSE, or custom-filesystem comparison.
