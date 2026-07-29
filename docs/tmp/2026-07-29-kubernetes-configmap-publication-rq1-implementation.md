# Kubernetes ConfigMap Publication RQ1 Implementation

## Purpose

This record implements the experiment frozen in
`2026-07-29-kubernetes-configmap-publication-rq1-plan.md`. The experiment asks
whether bounded `namei_ext` file selection and hiding under one stable logical
volume root can reproduce the payload-view subset of Kubernetes ConfigMap
publication without implementing the Kubernetes materialization algorithm.

This is an RQ1 correctness experiment. It does not measure performance or
compare implementation size.

## Source Inspected

The source-positive control is Kubernetes v1.30.0 at commit
`7c48c2bd72b9bf5c44d21d7338cc7bea77d0ad2a`.

The implementation imports and executes:

```text
k8s.io/kubernetes/pkg/volume/util
```

The inspected source and tests are:

```text
pkg/volume/util/atomic_writer.go
pkg/volume/util/atomic_writer_test.go
```

The Make-owned source build uses the vendored dependency tree from that exact
Kubernetes archive with Go 1.22.2 and `CGO_ENABLED=0`. It compiles the official
package tests and runs `TestWriteOnce`, `TestUpdate`, and
`TestMultipleUpdates`. All three passed before KVM execution was attempted.
The source adapter imports the official package; it does not copy or
reimplement `AtomicWriter`.

## Files Added

The experiment adds:

```text
bpf/policies/kubernetes_configmap_publication.bpf.c
configs/benchmarks/kubernetes_configmap_publication.mk
experiments/kubernetes_configmap_publication/Makefile
experiments/kubernetes_configmap_publication/atomic_writer_driver.go
experiments/kubernetes_configmap_publication/namei_ext_kubernetes_configmap_publication.c
mk/experiments/kubernetes_configmap_publication.mk
```

The top-level `Makefile` exposes source-build, one-boot preflight, three-boot
formal, finalization, and analysis targets. `mk/suites.mk` classifies the
one-boot target as a dependency preflight. The formal target is executable but
is not a member of the aggregate formal-case-study target until a reviewed
formal result exists.

## Source-Positive Control

`atomic_writer_driver.go` executes the fixed payload through the official
`AtomicWriter.Write()` method in this order:

```text
V0 -> V1 -> V1 no-op -> V0 rollback
```

For each state it records:

- the unfiltered raw filesystem inventory;
- the payload names visible through root and nested readdir;
- exact bytes and modes;
- device and inode identity;
- the `..data` target used by the source mechanism; and
- output from an unmodified `/bin/sh` and `cat` consumer.

The adapter retains both the volume-root directory descriptor and a V0 file
descriptor across update and rollback. `openat()` through the old root
descriptor must observe each current generation while the root identity stays
fixed. The old file descriptor must keep its V0 bytes and inode. The adapter
separately requires no-op publication to preserve the current V1 payload
identity and source rollback to allocate a payload object distinct from the
still-open original V0 object.

Kubernetes-private `..*` entries are retained in the raw inventory but excluded
from the common payload-namespace oracle.

## namei_ext Condition

The C runner creates two complete, pre-existing lower generation directories
and one stable logical `view/current` placeholder tree. It captures the fixed
payload oracle independently from the observations used by direct controls
and logical states.

The policy has four maps:

- a V0 component-key-to-target map;
- a V1 component-key-to-target map;
- one cgroup-to-generation map; and
- counters for total, lookup, readdir, select, hide, and pass events.

The logical root and its `config/` and `tls/` directories never change
identity. For `app.conf`, `cert.pem`, `retired.conf`, and `added.conf`, the
policy selects a registered payload file or hides the entry according to the
current generation. The managed-only placeholder is hidden in both
generations. Positive readdir entries return `PASS`; absent entries return
`HIDE`. This lets an old root directory descriptor reach the current payload
without redirecting the root itself.

The runner:

1. validates V0 and V1 directly against exact bytes, modes, and membership;
2. checks that an unmanaged process sees the placeholder tree;
3. creates a cgroup and registers six V0 and V1 file targets;
4. attaches the policy through `cgroup/namei_ext`;
5. executes initial, update, repeated no-op, and rollback states;
6. retains a stable root directory descriptor and checks `openat()` at every
   state;
7. retains a V0 file descriptor across update and rollback;
8. checks lookup, stat, open, and nested/root readdir observations;
9. verifies policy counters;
10. leaves the managed cgroup, deletes map state, detaches the policy, clears
   targets, and removes the cgroup; and
11. checks that all twelve defined lower objects retain bytes, type, mode,
    UID, GID, device, inode, size, mtime, and ctime.

Atime is intentionally excluded because ordinary reads can update it.

## Result Ownership

All acquisition, build, test, KVM, collection, finalization, and analysis steps
are Make targets. The source archive is pinned by its exact commit URL. The
result artifacts record the source URL, version, commit, Go version, exact
source build/test commands, imported package, upstream tests, source/build
logs, kernel configuration, policy, runner, adapter, per-boot observations,
full source inventories, lower-object snapshots, application logs, dmesg, and
before/after BPF and FUSE inventories.

No checksum file, checksum manifest, or checksum promotion gate was added.

## Validation Completed

Before the first KVM preflight:

- the C runner compiled with `-Wall -Wextra` and no warnings;
- the BPF policy compiled for x86 BPF;
- the Go adapter compiled as a static executable;
- the exact Kubernetes source archive contained the required source, tests,
  and vendor tree;
- the three selected official `AtomicWriter` tests passed;
- the top-level Makefile parsed and exposed the new targets;
- the finalizer recipe expanded with the expected per-boot gates; and
- `git diff --check` passed.

These checks are build and source feasibility evidence only. They are not
Phase 1 validation and do not establish the RQ1 result.

## Independent Implementation Review

The first independent implementation review returned `NO-GO` before any KVM
preflight. It found:

- raw `namei_ext` state records did not expose enough bytes, modes, membership,
  and per-file identities to recompute the oracle;
- redirecting the whole generation directory would pin lookup through a
  pre-update root directory descriptor to V0, unlike `AtomicWriter`'s stable
  volume root;
- analysis wrote into a result root after it was marked complete;
- libbpf-style `-1` failures lost the underlying errno; and
- source metadata omitted the exact build and test commands.

The repaired implementation emits all four file observations and all directory
membership fields, recomputes exact source and `namei_ext` state oracles in the
Make finalizer, keeps the logical root stable with per-file `SELECT`/`HIDE`,
tests old root descriptors in both mechanisms, performs analysis before the
final completion transition, normalizes libbpf errors immediately, and records
the source commands.

The follow-up review returned `GO` with no blocking finding. Its three
non-blocking observations were resolved by recording dirfd errno, preserving
shell quoting in the source test command, and explicitly limiting readdir
equivalence to visible-name membership rather than placeholder dirent
inode/type values.

## Remaining Gate

The remaining execution requires:

1. at most three one-boot KVM preflight attempts;
2. three fresh formal modified-kernel KVM boots;
3. independent result review; and
4. documentation and paper updates only if the reviewed result is positive.

The primary execution risks are verifier rejection, a difference between host
and guest support required by the static Kubernetes adapter, per-file
selection and hiding through nested readdir and old directory descriptors,
incomplete cleanup after a failing state, and an over-constrained source
identity oracle. Raw failures remain engineering evidence and do not enter the
paper as positive results.
