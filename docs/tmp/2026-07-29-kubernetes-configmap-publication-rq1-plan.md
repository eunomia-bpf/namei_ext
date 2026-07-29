# Kubernetes ConfigMap Publication RQ1 Experiment Plan

## Research Question

RQ1 is fixed as:

> Can a narrow VFS name-resolution extension express real state-dependent
> path-view policies without taking over filesystem semantics?

This experiment tests one source-derived service-configuration behavior. It
does not compare performance, prove that another mechanism is impossible, or
change RQ1.

## Paper-Value Admission

The paper currently has reviewed formal RQ1 results for Agent workspaces,
sandboxed application file sharing, Bazel action views, and toolchain
environments. Service configuration is repeatedly used in the motivation but
has no reportable row. A positive result would add a non-overlapping workflow
in which a running application observes a published configuration generation
through later pathname lookup. A contradictory result would show that the
Kubernetes publication behavior needs semantics outside the current
`SELECT` and directory-enumeration boundary.

This is a supporting RQ1 experiment. Its paper value is breadth across an
industrial workflow, not another headline claim or performance number.

The next-best incomplete candidates are not better uses of the same budget:

- W5 DMTCP and W6 Spindle exhausted their three-preflight protocols without
  reaching the focal mechanism.
- W1, W2, W3, and W7 already have reviewed formal RQ1 evidence. Another task
  in those families would improve robustness but would not add a new
  industrial workflow.
- The old W4 experiment also exhausted its protocol. Re-running its repaired
  harness would be a fourth attempt and is not authorized.

## Source Behavior

The primary source is Kubernetes v1.30.0, commit
`7c48c2bd72b9bf5c44d21d7338cc7bea77d0ad2a`. The official
`pkg/volume/util/atomic_writer.go` implementation publishes a complete payload
through a timestamped directory and atomically replaces the `..data` symlink.
Its official tests cover first publication, retained-file updates, nested
paths, additions, removals, and multiple updates. The experiment adapter
directly checks a repeated no-op `Write()` because the v1.30.0 `TestUpdate`
no-update case does not execute its second write.

The application shape comes from the official Kubernetes ConfigMap tutorial.
Its pod repeatedly executes `cat /etc/config/<key>` so that a running process
observes a later projected-volume update. The experiment uses an unmodified
shell and `cat` command as the consumer.

Kubernetes owns ConfigMap retrieval, payload construction, materialization,
and publication. The application owns when it reopens the path. This
experiment tests only whether the already materialized generation selected by
later pathname lookup can be represented by `namei_ext`.

The repository will record the Kubernetes tag, commit, source URL, Go version,
build command, and raw build/test logs. It will not add checksum files,
checksum manifests, or checksum-based promotion gates.

## Scientific Distinction From The Closed W4 Protocol

The closed experiment selected complete nginx configuration directories,
sent `SIGHUP`, and required worker replacement, invalid-configuration
rejection, and rollback. Its final preflight stopped on an unavailable
`/proc/<pid>/task/<pid>/children` interface.

This experiment uses a different source mechanism and application oracle:

- the source-positive control directly executes the official Kubernetes
  `AtomicWriter`;
- the selected object is a complete, already materialized ConfigMap
  generation;
- the application reopens projected paths with unmodified `sh` and `cat`;
- additions and removals are checked through both lookup and readdir;
- an already open descriptor must continue to reference its old inode; and
- no nginx process, HUP, worker-PID, HTTP, or invalid-nginx-configuration
  condition exists.

Therefore this is not a repair, rename, or additional attempt for the closed
nginx-reload protocol. Old W4 roots remain immutable and are not counted as
evidence for this experiment.

## Hypothesis

Given two complete ConfigMap generations, a `namei_ext` policy can make one
stable projected-volume pathname follow the publication sequence
V0, V1, V1 no-op, and V0 rollback. After each acknowledged update, new
lookup, open, stat, and readdir operations match the payload view exposed by
the official Kubernetes `AtomicWriter`. The logical volume root keeps one
device/inode identity: lookup through a directory descriptor opened before
the update must still follow V0, V1, V1 no-op, and V0 rollback. An ordinary
file opened before the update continues to reference its original V0 inode.
The two pre-existing `namei_ext` lower generations remain unchanged.

The hypothesis is contradicted if a retained path returns wrong bytes, an
added or retired path is incoherent between lookup and readdir, a no-op update
changes the current payload object identity, rollback does not restore the V0
payload view, an old descriptor changes identity or bytes, a required
operation bypasses the policy, a pre-update directory descriptor remains
pinned to V0 after the generation changes, or a pre-existing `namei_ext`
lower generation changes.

## Payload

The official source control and `namei_ext` condition use the same payload:

| Path | V0 | V1 |
| --- | --- | --- |
| `config/app.conf` | `version=0` mode 0644 | `version=1` mode 0600 |
| `tls/cert.pem` | `certificate-v0` mode 0400 | `certificate-v1` mode 0400 |
| `retired.conf` | `retired` mode 0644 | absent |
| `added.conf` | absent | `added` mode 0644 |

These ordinary test bytes make every expected observation explicit. They are
not checksums or generated scores.

## Comparison And Controls

There is no performance baseline in this RQ1 experiment.

The required conditions and controls are:

| Condition | Role | Required behavior |
| --- | --- | --- |
| Official Kubernetes `AtomicWriter` | Source-positive control | Execute V0, V1, V1 no-op, and V0 rollback with the fixed payload and record the visible tree, bytes, modes, object identity, and old-fd behavior. |
| `namei_ext` | Tested mechanism | Keep one stable logical volume root and select or hide pre-existing V0/V1 payload files through the real modified-kernel KVM attach path. |
| Direct V0 and V1 | Lower-object control | Verify exact bytes, modes, directory membership, and device/inode identity before and after the lifecycle. |
| Unmanaged process group | Scope control | Observe the unchanged logical placeholder tree rather than either managed payload. |

The source-positive control is a correctness oracle, not a performance
competitor. Direct and unmanaged conditions are controls, not baselines.

## Workload Matrix

The source-positive control and the `namei_ext` condition execute:

| State | Selected generation | Required new-open view |
| --- | --- | --- |
| Initial | V0 | V0 bytes, modes, membership, and object identity |
| Update | V1 | V1 bytes and modes; `added.conf` appears and `retired.conf` disappears |
| No-op | V1 | Same V1 object identities remain selected |
| Rollback | V0 | V0 bytes, modes, and membership return |

Before the V0-to-V1 update, the consumer opens `config/app.conf` and retains
the descriptor. After the update:

- reading that descriptor still returns V0 bytes and the V0 inode;
- a new open returns V1 bytes and the V1 inode.

The consumer also opens the logical volume root once before the update and
retains that directory descriptor. `openat()` through that same descriptor
must return the selected V0 or V1 `config/app.conf` object at every state while
the root descriptor's own device/inode identity remains unchanged. This
matches `AtomicWriter`'s stable target-directory behavior and prevents a
whole-generation directory redirect from passing the experiment.

The experiment does not claim a transactionally consistent snapshot across
several independent opens and does not include a concurrent-update stress
probe.

Rollback has mechanism-specific object identity:

- `AtomicWriter` creates a new timestamp directory when it writes V0 after V1,
  so the rollback payload has V0 bytes, modes, and membership but new inodes;
- `namei_ext` reselects the pre-existing V0 payload files, so rollback restores
  the original V0 lower inodes; and
- in both conditions, the descriptor opened before the first update remains
  attached to the original V0 inode.

The common oracle is the payload view, not identical inode-allocation behavior
between publication mechanisms.

## Payload Namespace

`AtomicWriter` reserves names beginning with `..` for its timestamped
directories and `..data` symlink. Its user-visible entries may themselves be
symlinks into that private tree. The `namei_ext` condition keeps one stable
logical root with ordinary placeholder entries and applies `SELECT` or `HIDE`
to payload-file lookup and readdir events.

The feature-equivalent comparison therefore operates on the payload namespace:

- filter `AtomicWriter` root entries beginning with `..`, matching the
  treatment in its official `checkVolumeContents()` helper;
- compare lookup, open, stat, and readdir behavior for `config/`, `tls/`,
  `added.conf`, and `retired.conf`;
- compare readdir visible-name membership only; dirent inode and type values
  from the logical placeholders are outside the claim;
- preserve the complete unfiltered `AtomicWriter` directory inventory as raw
  source evidence; and
- keep `lstat`, `readlink`, symlink topology, timestamp-directory naming, and
  inotify behavior outside the claim.

## Correctness Oracle

Every state must check:

- exact bytes and mode for retained paths;
- expected success or `ENOENT` for added and retired paths;
- payload directory enumeration contains exactly the expected visible names
  after filtering `AtomicWriter`'s reserved `..*` implementation objects;
- logical device/inode identity matches the selected lower object;
- the unmodified shell and `cat` consumer reports the expected version;
- one directory descriptor opened on the logical volume root before update
  retains its root identity while `openat()` observes each later generation;
- old descriptors preserve their original bytes and inode across update;
- no-op publication preserves the current payload object identity;
- `AtomicWriter` rollback restores V0 payload semantics with newly allocated
  objects, while `namei_ext` rollback restores the original V0 lower objects;
- lookup, directory-enumeration, `SELECT`, and `HIDE` counters increase; and
- both pre-existing `namei_ext` lower generation trees retain their original
  bytes, type, mode, UID, GID, device, inode, size, mtime, and ctime.

The official control must execute the same payload through
`AtomicWriter.Write()`. Running only upstream unit tests is not sufficient;
the small adapter must emit the fixed experiment payload and raw observations.

The source-positive control and all `namei_ext` consumers run with the same
fixed UID and GID. The generated files are owned by that identity so the 0600
and 0400 modes have the same read expectations in both conditions. Access
time is not a preservation field because ordinary reads and readdir may update
it. The source-positive control is checked against `AtomicWriter`'s documented
creation and deletion lifecycle; its retired timestamp directories are not
required to remain present.

## Mechanism Boundary

The BPF policy may return only `PASS`, `HIDE`, or `SELECT` for fixed payload
entries under one stable logical volume root. It may use the current cgroup
identity, the current generation bit, and registered target IDs.

No BPF program:

- creates timestamped directories or symlinks;
- writes ConfigMap contents;
- retrieves or validates ConfigMap data;
- changes file modes or ownership;
- provides inotify notification;
- reloads an application; or
- mediates reads and writes after lookup.

The official `AtomicWriter` retains all materialization and publication
responsibilities. The experiment tests only the existing-object path-view
subset.

## Implementation Plan

Add one Make-owned experiment family:

```text
make kvm-kubernetes-configmap-publication-rq1-preflight RUN_ID=<id>
make experiment-kubernetes-configmap-publication-rq1 RUN_ID=<id>
```

The implementation consists of:

- a pinned Kubernetes v1.30.0 source acquisition and build target;
- a small Go source adapter that imports the official
  `k8s.io/kubernetes/pkg/volume/util` package and emits the fixed payload;
- one workload-specific BPF policy under `bpf/policies/`;
- one C runner under `experiments/kubernetes_configmap_publication/`;
- one local experiment Makefile and one top-level experiment include;
- one benchmark configuration include; and
- direct JSONL aggregation in the owning Make target.

The source adapter is necessary glue. It must not copy or reimplement
`AtomicWriter`; it calls the official package directly.

## Feasibility Evidence

Before this plan was frozen, a read-only source feasibility check downloaded
Kubernetes v1.30.0, compiled `pkg/volume/util` with the repository's Go 1.22.2
toolchain and the upstream vendor tree, and ran:

```text
TestWriteOnce
TestUpdate
TestMultipleUpdates
```

All three official tests passed. This establishes build feasibility only. It
is not a KVM preflight or a paper result.

## Execution

Real preflight:

```text
make kvm-kubernetes-configmap-publication-rq1-preflight \
  RUN_ID=20260729T-kubernetes-configmap-publication-preflight01
```

The preflight uses one fresh boot of the modified kernel and the real
`cgroup/namei_ext` attach path. At most three real preflight roots are allowed.
Any created root is immutable.

After a successful preflight and review, the formal matrix is:

```text
make experiment-kubernetes-configmap-publication-rq1 \
  RUN_ID=20260729T-kubernetes-configmap-publication-formal01
```

The formal run uses three independent fresh KVM boots. The lifecycle is
deterministic and categorical, so the paper reports exact pass counts rather
than confidence intervals.

Raw roots:

```text
results/experiments/kubernetes-configmap-publication-rq1-preflight/<RUN_ID>/
results/experiments/kubernetes-configmap-publication-rq1/<RUN_ID>/
```

## Completion Rule

A boot passes only when the source-positive control and every `namei_ext`
state pass, the unmanaged and direct controls pass, all `namei_ext` logical
objects match their expected lower device/inode pairs, mechanism-specific
rollback and no-op identity checks pass, the source and `namei_ext` root
directory descriptors remain stable while `openat()` follows every generation,
required policy counters are positive, the pre-existing `namei_ext` lower
bytes and defined metadata remain unchanged, dmesg is clean, and cleanup
leaves no experiment process, target, BPF, or cgroup state.

The formal experiment is complete only when all three fresh boots pass and an
independent reviewer recomputes exact bytes, modes, membership, state counts,
object and descriptor identity, mechanism engagement, lower preservation, and
cleanup from raw artifacts rather than trusting runner verdict fields.

## Paper Decision

- **Positive:** add W4 as a fifth RQ1 row and state that the tested Kubernetes
  ConfigMap publication behavior fits the narrow existing-object boundary.
- **Contradictory:** do not add W4; record which required source behavior falls
  outside `PASS`/`SELECT` and bound RQ1 accordingly.
- **Mixed:** report no paper row until the failed state or attribution gap is
  resolved without changing the oracle.
- **Inconclusive:** preserve dependency evidence and keep W4 out of the paper.

No result from this experiment changes RQ2 or establishes a performance claim.
