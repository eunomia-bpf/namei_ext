# C8 related-work survey: FUSE, custom filesystems, and redirect-table limits

## Motivation

This note answers a narrower question than the current related-work section:
why do existing systems choose FUSE or implement their own filesystem, and what
does that imply for the C8 counterfactual that an exact redirect table may be
enough?

The current paper draft already cites FUSE, OverlayFS, ExtFUSE, Bento,
Landlock, BPF LSM, fanotify, and sched_ext. That coverage is not yet enough
for the stronger thesis that `namei_ext` occupies a useful balance point
between programmable filesystem mechanisms and static path-view construction.
The missing part is a use-case-level survey of what problem each mechanism was
chosen to solve.

## Sources inspected

- Linux FUSE documentation:
  <https://docs.kernel.org/filesystems/fuse/fuse.html>
- Vangoor et al., "To FUSE or Not to FUSE", FAST 2017:
  <https://www.usenix.org/conference/fast17/technical-sessions/presentation/vangoor>
- Bazel sandboxing documentation:
  <https://bazel.build/versions/7.2.0/docs/sandboxing>
- `sandboxfs` repository:
  <https://github.com/bazelbuild/sandboxfs/>
- s3fs repository:
  <https://github.com/s3fs-fuse/s3fs-fuse>
- Azure BlobFuse repository:
  <https://github.com/Azure/azure-storage-fuse>
- gocryptfs documentation:
  <https://nuetzlich.net/gocryptfs/>
- Linux virtiofs documentation:
  <https://docs.kernel.org/filesystems/virtiofs.html>
- Bijlani et al., ExtFUSE, ATC 2019:
  <https://www.usenix.org/conference/atc19/presentation/bijlani>
- Tarasov et al., Terra Incognita, HotStorage 2015:
  <https://www.usenix.org/conference/hotstorage15/workshop-program/presentation/tarasov>
- Zadok et al., Wrapfs stackable templates, USENIX 1999:
  <https://www.usenix.org/event/usenix99/full_papers/zadok/zadokpp.pdf>
- Ren and Gibson, TABLEFS, ATC 2013:
  <https://www.usenix.org/conference/atc13/technical-sessions/presentation/ren>
- Ren et al., IndexFS, SC 2014:
  <https://www.pdl.cmu.edu/indexfs/>
- Miller et al., Bento, FAST 2021:
  <https://www.usenix.org/conference/fast21/presentation/miller>
- Jannen et al., BetrFS, FAST 2015:
  <https://www.usenix.org/conference/fast15/technical-sessions/presentation/jannen>
- Zhang et al., Composite-file File System, FAST 2016:
  <https://www.usenix.org/conference/fast16/technical-sessions/presentation/zhang-shuanglong>
- Xu and Swanson, NOVA, FAST 2016:
  <https://www.usenix.org/conference/fast16/technical-sessions/presentation/xu>
- Linux OverlayFS documentation:
  <https://www.kernel.org/doc/html/latest/filesystems/overlayfs.html>
- Linux mount namespaces manual:
  <https://www.man7.org/linux/man-pages/man7/mount_namespaces.7.html>
- ccache manual:
  <https://ccache.dev/manual/latest.html>
- Docker BuildKit cache optimization documentation:
  <https://docs.docker.com/build/cache/optimize/>
- Bazel remote caching documentation:
  <https://bazel.build/remote/caching>
- CRIU external bind mounts:
  <https://www.criu.org/External_bind_mounts>
- Podman checkpoint documentation:
  <https://podman.io/docs/checkpoint>
- DMTCP publications/source material:
  <https://dmtcp.sourceforge.io/>

## Why systems use FUSE

### 1. Expose a new namespace view without kernel development

FUSE exists to let an ordinary userspace process provide filesystem data and
metadata while applications still use the normal kernel filesystem interface.
The kernel documentation also highlights non-privileged mounts as a major
feature, with SSHFS as the canonical example. This explains the common reason
to choose FUSE: the system wants a filesystem-shaped interface without writing
or shipping a kernel filesystem.

This is directly relevant to `namei_ext`: FUSE is the strongest programmable
baseline because it can implement arbitrary path behavior, but it does so by
moving broad filesystem request handling into a daemon.

Terra Incognita reinforces the same point from the deployment side: many
userspace filesystems exist because the development, compatibility, and
reliability tradeoff is attractive enough that developers tolerate FUSE's
costs for some workloads. This strengthens the baseline requirement: the paper
must compare against FUSE on the actual workload shape instead of assuming that
literature makes FUSE unacceptable.

### 2. Construct arbitrary per-action or per-workload path views

Bazel's sandboxfs is the closest path-view precedent. Bazel documents
sandboxfs as a FUSE filesystem that exposes an arbitrary view of the underlying
filesystem. The reason is not storage layout; the reason is sandbox creation
cost. Bazel can create an `execroot` for each action without issuing thousands
of setup syscalls, while acknowledging that later I/O inside that view may be
slower because it goes through FUSE.

Implication for C8: sandboxfs proves that real systems wanted arbitrary path
views badly enough to accept FUSE. It does not prove that eBPF policy logic is
needed. A static redirect table may still be sufficient for a given action if
the view is just a finite manifest of exact mappings. Therefore W1/build-graph
or agent-sandbox claims need claim-driven baselines. Exact-map diagnostics are
useful only when the claim is specifically about precomputed mappings, not as
the default comparison.

### 3. Adapt remote/object storage into POSIX-looking filesystems

s3fs and BlobFuse choose FUSE to let applications use object storage through a
local filesystem interface. The motivation is interoperability with existing
file APIs and tools. These systems implement data transfer, caching, directory
listing, consistency caveats, and remote authentication behavior outside the
kernel.

Implication for C8: these are not redirect-table problems. They need a daemon
because backing data and metadata live outside the local VFS. `namei_ext`
should not claim to replace them. They are evidence for the FUSE design-space
tradeoff, not direct evidence for path-resolution policy necessity.

### 4. Transform names and file contents

gocryptfs uses FUSE to provide a mountable encrypted view. Its logic includes
file-content encryption and filename encryption, not only lookup redirection.

Implication for C8: content/name transformation is outside Phase 1
`namei_ext`. If the paper claims only path-resolution views, encrypted-overlay
systems should be related work, not baselines. They explain why userspace
filesystems are attractive when the extension must own file data semantics.

### 5. Share host files with guests

virtiofs uses the FUSE protocol for guest-host filesystem sharing. The Linux
documentation motivates it as a way to give guests access to host or remote
files without exposing a storage network and with guest-host co-location
semantics.

Implication for C8: virtiofs is another case where FUSE is a transport and
filesystem protocol boundary, not just a path mapping mechanism. It does not
answer whether an exact redirect table is enough for local path views.

## Why systems build or extend kernel filesystems

### 1. FUSE performance is workload-dependent and sometimes unacceptable

"To FUSE or Not to FUSE" is the right citation for avoiding blanket claims.
Its result is not "FUSE is always bad"; it is workload-dependent. Some
workloads see little degradation, while others suffer large slowdowns and
higher CPU use. This means a `namei_ext` paper cannot rely on literature alone
to claim FUSE is too slow for the proposed workloads. It must measure the
specific metadata and dynamic-view workloads.

### 2. Kernel fast paths can be worth the development cost

Bento explicitly targets the gap between FUSE development velocity and kernel
filesystem performance. The FAST 2021 paper motivates Bento by the high
development cost and risk of kernel filesystems, but also by FUSE performance
penalties. Bento's contribution is a safe Rust framework for kernel
filesystems that can be updated with low disruption.

Implication for `namei_ext`: Bento supports the paper's design-space claim that
there is real pressure between FUSE flexibility and kernel performance. It does
not make `namei_ext` redundant because Bento still asks developers to implement
a filesystem. `namei_ext` is narrower: it only exposes path-resolution
decisions while keeping lower filesystems responsible for objects and file
operations.

BetrFS gives a sharper example: the system moved a write-optimized design into
the kernel because FUSE request behavior interfered with the intended metadata
and read/write mix. This is not a path-alias problem. It shows why some systems
need kernel-resident control over filesystem operations, while `namei_ext`
should remain scoped to cases where path-resolution policy is the missing
piece.

### 3. Some systems need new storage layout, persistence, or consistency

NOVA is representative of systems that build a new filesystem because the
problem is storage semantics, not namespace redirection. NOVA targets
byte-addressable non-volatile memory and designs logging, concurrency,
metadata, and consistency around that hardware.

Implication for `namei_ext`: these systems should be described as out of scope.
They justify why "general programmable filesystem abstraction" is too broad
for the current implementation. If the system needs to own storage layout,
crash consistency, mmap semantics, write path, or allocation, `namei_ext` is
not the right abstraction.

TABLEFS and the Composite-file File System are adjacent examples. TABLEFS uses
a stacked design and an LSM-backed metadata table to batch and reorganize
metadata updates. Composite-file FS changes the mapping between logical files
and metadata representation. IndexFS builds a distributed metadata service with
dynamic namespace partitioning and caching. These systems are valuable related
work precisely because their core problem is metadata organization and update
semantics, not a finite static redirect table.

Wrapfs captures the broader stackable-filesystem motivation: add nontrivial
filesystem behavior without changing clients or lower filesystems. That is
close to the design-space motivation for `namei_ext`, but the granularity is
different. Stackable filesystems interpose on broad VFS/file operations;
`namei_ext` intentionally exposes only a narrow name-resolution decision.

### 4. Kernel view mechanisms encode more than exact path redirects

OverlayFS is a kernel mechanism for union-style views over lower and upper
filesystems. Its documentation includes copy-up behavior, inode/device identity
details, credential stashing, permission checking, whiteouts, and redirect
features. That is already more than a redirect table. Mount namespaces provide
per-namespace mount hierarchies and propagation rules.

Implication for C8: OverlayFS and mount namespaces must remain strong
baselines where their semantics match the workload. But they also show why a
simple exact redirect table is not a full filesystem-view abstraction. Real
view mechanisms often need update semantics, permission interactions,
identity, and propagation behavior.

## Why an exact redirect table may not be enough

The literature does not directly prove that `table_redirect.bpf.c` is
insufficient for our workloads. It does, however, identify recurring reasons
why systems move beyond exact static mapping:

1. Per-operation state matters. Build/cache systems select behavior from
   action keys, input manifests, cache keys, hit/miss state, and local/remote
   cache availability. ccache supports local and remote storage; Bazel remote
   cache separates action-result metadata from content-addressed output files;
   BuildKit cache mounts persist package/build caches across builds.

2. View generation and update cost matters. Bazel sandboxfs exists because
   constructing an action view through thousands of setup syscalls can dominate
   the benefit. A table can encode a final view, but the experiment must count
   how many exact entries and updates are needed to keep it correct across
   actions or epochs.

3. Fallback and rejection are semantic, not just mapping. Cache locality needs
   hit, miss, stale, corrupt, and fallback behavior. A static table can point
   a name at a local object, but it cannot prove that the local object is still
   valid unless validity is either precomputed into the table or checked by
   policy logic. If an exact-map diagnostic is used, the run should record
   update writes and stale windows as boundary evidence rather than treating
   the table itself as the mandatory baseline.

4. Epoch/session consistency matters. CRIU's external bind mount mechanism
   explicitly remaps checkpoint image mount roots to host paths at restore.
   Podman/CRIU restore resumes a checkpointed container from a prior point in
   time. A table can encode one restore view, but a multi-epoch workload must
   prove whether the table can avoid mixed-generation state without frequent
   regeneration.

5. Readdir consistency matters. A table that only rewrites lookup can be
   feature-incomplete if the visible directory set must match lookup results.
   Existing view filesystems expose a whole namespace, not only open-time
   aliases.

Therefore redirect-table insufficiency is not a claim that follows from
related work alone. It is only a workload-specific counterfactual when the
paper explicitly claims value over exact mappings:

- static exact table fails if state changes after table generation make a
  mapping stale or unsafe;
- externally updated table fails only if correct updates exceed the declared
  budget, introduce a stale window, or require operation-weighted behavior that
  cannot be materialized cheaply;
- if table variants are not the natural comparison, C8 should instead be
  judged against the simpler mechanism that the workload would normally use.

## What the literature can and cannot answer

The literature can answer:

- FUSE is the standard programmable userspace filesystem mechanism.
- Real systems use FUSE for arbitrary virtual views, remote/object storage,
  encryption overlays, and guest-host sharing.
- FUSE overhead is real but workload-dependent.
- Some systems build kernel/custom filesystems when they need kernel fast
  paths, storage layout control, consistency, or new hardware semantics.
- Stacked filesystems and metadata services are commonly chosen when the
  semantics involve update batching, namespace partitioning, metadata layout,
  or file-to-metadata representation rather than just path aliasing.
- Static kernel/materialized view mechanisms are mature and must be treated as
  strong baselines, not strawmen.

The literature cannot answer:

- whether `table_redirect.bpf.c` is even the relevant baseline for
  W1/W2/W3/W4;
- whether `namei_ext` beats FUSE on this prototype and these workloads;
- whether W4 cache locality has enough real stale/corrupt/update behavior to
  justify BPF policy logic;
- whether W3 restore views require policy logic rather than the restore
  mechanism's natural namespace setup;
- whether `namei_ext` has acceptable native p99 overhead.

Those remain experiments.

## Consequences for paper positioning

The paper should not say "existing extensible filesystems are unsafe" as a
blanket claim. FUSE explicitly has a security model for non-privileged mounts,
and Bento tries to sandbox kernel filesystem errors with Rust. A stronger and
more accurate statement is:

> Existing mechanisms choose different points in the design space: FUSE moves
> broad filesystem semantics into a userspace daemon; custom/kernel filesystems
> own VFS object and data-path behavior; materialized or mount-based views
> encode relatively static namespace structure. `namei_ext` explores a narrower
> point: programmable name-resolution decisions while the kernel and lower
> filesystem retain object ownership, permissions, and file operations.

The paper also should avoid calling the current system a general programmable
filesystem abstraction unless create/unlink/rename/write/file-operation
semantics are added. The defensible phrase is "programmable path-resolution
view" or "narrow programmable namespace-view extension."

## C8 experiment guidance from this survey

The next C8 experiment should be driven by the claim and workload, not by a
mandatory redirect-table comparison. A table is useful when the claim is
"dynamic policy is needed beyond exact mapping." For other claims, the right
baseline may be FUSE, materialized namespace setup, bind/symlink projection,
OverlayFS, native cache tooling, or an application/runtime mechanism.

For W4 cache locality:

- run `namei_ext` policy against the workload-appropriate cache baselines on
  the same ccache or BuildKit trace;
- include static or externally updated table variants only if the specific
  claim is about exact mapping versus dynamic policy;
- force hit, miss, stale, corrupt, and epoch-update transitions;
- record operation-weighted branch coverage, setup/update work, stale-window
  duration, output hashes, and compile success;
- C8 is positive only if `namei_ext` beats the chosen simpler mechanism under
  the declared correctness, update, stale-window, and performance budget.

For W3 restore/session views:

- run at least two restore epochs with different backing state;
- check health, state hashes, post-restore VFS operations, and zero mixed
  epoch;
- compare the restore/session mechanisms that naturally implement the view,
  such as materialized views, bind mounts, FUSE, OverlayFS, or runtime restore
  machinery;
- include table regeneration only if the claim is that exact mappings cannot
  track the restore/session view within the declared budget.

For W2 fixture:

- keep W2 mainly as setup/materialization evidence;
- do not expect it to prove a redirect-table argument. Its stronger role is to
  show that fixture substitution can be expressed at VFS name resolution
  without implementing a filesystem.

For W1/build or agent-sandbox lifecycle:

- use real command traces and count per-action view generation/update cost;
- choose baselines that match the lifecycle claim, such as copy tree, git
  worktree/checkout, bind/symlink projection, OverlayFS, FUSE, BranchFS/YoloFS
  where applicable, or runtime checkpoint mechanisms;
- include a table only if the experiment is explicitly about precomputed exact
  action views versus dynamic lookup policy.

## Bottom line

The missing survey changes the argument. FUSE and custom filesystems are used
for concrete reasons: arbitrary namespace views, remote/object storage,
encryption/translation, guest-host sharing, kernel fast paths, storage layout,
and consistency. Most of those are not redirect-table questions. For
`namei_ext`, the C8 novelty must be proven in the narrower region where the
task is local path-resolution view selection, lower filesystems should keep
ownership, and a narrow VFS hook improves on the workload-appropriate simpler
mechanism. That mechanism may be an exact table, but it does not have to be.
