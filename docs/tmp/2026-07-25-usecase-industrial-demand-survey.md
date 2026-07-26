# 2026-07-25 Use-Case Industrial Demand Survey

Date: 2026-07-25
Status: research record; sources verified against primary documents on
2026-07-25. This record grounds the use-case table in `docs/evaluation.md`.
Each entry gives the source URL, the key quote (verbatim English), the demand
it proves, and an honest judgment of whether the evidence supports a VFS
name-resolution policy boundary.

## Framing Result

Across six domains, real systems keep re-implementing the same primitive —
lookup-time selection of which existing object a pathname denotes, or whether
it is visible — at five different wrong layers:

| System | Layer where path-view policy is re-implemented |
| --- | --- |
| AgentFS, BranchFS | FUSE daemon (full filesystem) |
| YoloFS | Entire stackable kernel filesystem |
| kubelet (Kubernetes) | Symlink indirection hack (AtomicWriter) |
| ingress-nginx | Embedded Lua in the application |
| DMTCP | LD_PRELOAD `open()` interposition |
| s3fs/gcsfuse/JuiceFS, stargz | FUSE daemon; nydus later migrated data path in-kernel (erofs+fscache) |

This is the motivation for a single, narrow, programmable boundary at VFS
name resolution.

## Use Case 1: Agent Workspace Views

### Demand evidence

- YoloFS (UW-Madison, arXiv:2604.13536), based on 290 real incident reports:
  "AI coding agents operate directly on users' filesystems, where they
  regularly corrupt data, delete files, and leak secrets."
  https://arxiv.org/html/2604.13536v1
- BranchFS (arXiv:2602.08199): "current agent frameworks resort to ad hoc
  solutions such as git stashing, temporary directories, or container clones,
  which incur significant overhead and cannot capture all filesystem
  modifications." https://arxiv.org/html/2602.08199v2
- Industry investment: E2B (Firecracker microVM snapshots; official docs:
  "Pausing a sandbox takes approximately 4 seconds per 1 GiB of RAM",
  https://e2b.dev/docs/sandbox/persistence), Modal (directory-level snapshots
  as a product feature, https://modal.com/docs/guide/sandbox-snapshots),
  Daytona (Docker layer commits), Turso AgentFS (FUSE,
  https://turso.tech/blog/agentfs-fuse).

### Pain of current solutions

- microVM/image route: whole-machine granularity. DeltaBox (arXiv:2605.22781)
  quantifies "hundreds of milliseconds to seconds of latency per C/R".
  https://arxiv.org/html/2605.22781v1
- FUSE route: BranchFS measures "regular FUSE mode achieves 1,655 MB/s read
  throughput (19% of native)". AgentFS issue #228: `make -j10` kernel build
  "about 10X slower in agentfs" (FUSE handler serialization),
  https://github.com/tursodatabase/agentfs/issues/228. Issue #167: daemon
  deadlock, and a user reports OverlayFS unusable in a real environment with
  autofs, https://github.com/tursodatabase/agentfs/issues/167.

### Alignment verdict: strongest

YoloFS independently arrived at the namei_ext action set: "`Hidden` makes the
path invisible: readdir skips it, and lookup, stat, and open behave as if it
does not exist" (our HIDE); its override-tree lookup chain is our
REDIRECT/SELECT. It had to build an entire stackable kernel filesystem to get
this capability. BranchFS's R5 rules out "heavyweight mechanisms such as VM
snapshots, privileged container runtimes, or filesystem-specific solutions".

### Honest boundary

namei_ext covers the view/visibility half of the agent requirement, not the
write-isolation/COW-staging half (copy-up needs a write path). Server-side
multi-tenant sandboxes (E2B/Modal) have settled on microVMs; the home ground
is local coding agents (YoloFS's setting) and single-VM branch fan-out
(BranchFS/DeltaBox's setting).

## Use Case 2: Build/Cache View Governance

### Demand evidence

- sccache (Mozilla) supports ten storage backends: "[m]ulti-level caching
  with automatic backfill is supported for hierarchical cache architectures."
  https://github.com/mozilla/sccache
- Bazel remote caching (AC/CAS): https://bazel.build/remote/caching
- BuildKit `RUN --mount=type=cache`: the `id` parameter selects which cache
  backs a given target path — productized path-view semantics.
  https://docs.docker.com/reference/dockerfile/#run---mounttypecache
- ccache `namespace` option: logical views over one physical cache.
  https://ccache.dev/manual/4.6.3.html
- Cache poisoning is a real attack surface: Bazel issue #4276, "the cache
  will be poisoned. We've seen this in production."
  https://github.com/bazelbuild/bazel/issues/4276; the Angular supply-chain
  incident via GitHub Actions cache poisoning,
  https://adnanthekhan.com/posts/angular-compromise-through-dev-infra/;
  GitHub's 2026-06 platform change issuing read-only cache tokens to
  untrusted triggers,
  https://github.blog/changelog/2026-06-26-read-only-actions-cache-for-untrusted-triggers/.
- ccache `hard_link` documented trap: multiple build trees sharing one inode
  leak mtime updates and corrupt cache entries — same pathname, wrong shared
  object causes real correctness failures.

### Honest verdict

Industry's mainstream answer is key-space isolation (namespace-in-hash,
content-addressed stores, platform token scopes), deliberately bypassing
paths. No primary source asks for a kernel path hook. The defensible gap:
unmodified build toolchains on shared build machines have no cache
visibility/writability governance — wrapper solutions need per-tool
cooperation, platform solutions cover only hosted CI. The paper position for
this use case is "cache-view governance at the access point", not "ccache
acceleration".

## Use Case 3: Service/Config Rotation

### The switch already lives at name resolution

kubelet AtomicWriter (source comment): "The visible files in this volume are
symlinks to files in a hidden timestamped directory... This scheme allows the
files to be atomically updated by changing the target of the data directory
symlink." Consumers see a new version only by re-resolving the path at
`open()`. This is REDIRECT semantics implemented as a symlink hack.
https://github.com/kubernetes/kubernetes/blob/master/pkg/volume/util/atomic_writer.go

### Pain evidence (all official documentation)

- Kubernetes ConfigMap docs: propagation delay = kubelet sync period + cache
  propagation delay; "A container using a ConfigMap as a subPath volume mount
  will not receive ConfigMap updates"; env-var consumption requires pod
  restart. https://kubernetes.io/docs/concepts/configuration/configmap/
- Measured 60–90 second propagation with a kubelet source walkthrough:
  https://ahmet.im/blog/kubernetes-secret-volumes-delay/
- The workaround ecosystem for applications that cannot reopen: Vault Agent
  (render file + exec reload command,
  https://developer.hashicorp.com/vault/docs/agent-and-proxy/agent/template),
  stakater Reloader (9k+ stars; watch and roll out,
  https://github.com/stakater/Reloader), nginx/envoy full hot-restart
  protocols (new processes + drain).
- ingress-nginx official docs admit embedding Lua to move object selection to
  request time, to avoid reloads: "We use lua-nginx-module to achieve this...
  this feature saves significant number of Nginx reloads which can otherwise
  affect response latency, load balancing quality."
  https://kubernetes.github.io/ingress-nginx/how-it-works/

### Honest verdict

namei_ext cannot help applications holding old file descriptors (fd semantics
bind the object at open). What it removes is the minute-scale kubelet
reconcile trigger and the symlink choreography, for every application that
re-resolves paths at open — without embedding Lua or restarting processes.
Oracle is concrete (`nginx -t`, service-visible behavior across epochs).
Promoted from conditional to the third use case on 2026-07-25.

## Use Case 4: Checkpoint/Restart Path Remapping

- DMTCP path virtualization (IEEE Cluster'16): "a path virtualization plugin
  translates paths remembered by the application into correct paths as per
  the new mount points." https://dmtcp.sourceforge.io/papers/cluster16.pdf
- DMTCP × Intel (SELSE'17): real industrial migration scenario; solution is
  LD_PRELOAD interposition of `open()` — fragile user-space path
  virtualization. https://arxiv.org/abs/1703.00897
- Kubernetes container checkpointing (KEP-2008, Beta): migration is an
  explicit non-goal; forensic restore is in-place, paths unchanged. CRIU
  `--external mnt` static mapping covers restore-time remapping.

### Honest verdict

Weakest demand of the four; keep conditional. Value is replacing fragile
user-space interposition, but the mainstream platform (Kubernetes) does not
target the scenario where remapping matters.

## Motivation Evidence: Remote Filesystem Cache

Not an evaluated use case (see boundary below); recorded because it is the
strongest industrial proof that the boundary exists.

- Cloud storage mounts (s3fs, gcsfuse, JuiceFS, Alluxio) are FUSE daemons
  with documented performance/consistency pain.
  https://github.com/googlecloudplatform/gcsfuse/blob/master/docs/semantics.md
- Lazy container-image pulling migrated from FUSE to in-kernel
  erofs+fscache/cachefiles on-demand (Linux 5.19+). AWS EKS AMI issue #2569:
  "in-kernel fscache mode that provides significantly better performance than
  FUSE for lazy-loading container images."
  https://github.com/awslabs/amazon-eks-ami/issues/2569
  Community analysis: "Nydus with the EROFS backend is the only solution that
  eliminates FUSE from the data path entirely."
  https://blog.zmalik.dev/p/lazy-pulling-container-images-a-deep

Reading for the paper: this community spent five years learning that a daemon
should not sit on the data path, and the kernel absorbed the data path. The
selection/visibility policy (which object, which generation, when a local
cache entry is stale and hidden) remains hardwired in each special-purpose
system; erofs+fscache policy is fixed. That policy layer is the namei_ext
boundary.

### Why it is not an evaluated use case

1. The data path (fetch, prefetch, partial reads, consistency) is the bulk of
   the problem, and namei_ext deliberately does not own it. Unlike ccache
   (which already fills the cache), here a fetcher must exist first.
2. A fair RQ2 comparison is expensive: the FUSE opponents own the whole
   problem including fetch, so feature equivalence requires building a
   fetcher for both sides.
3. erofs+fscache is already in-kernel; "why not that" requires the
   programmability argument to be developed carefully.

If it ever becomes a fourth evaluated use case, the shape is: namei_ext plus
an existing fetcher (e.g. fscache) providing per-workload remote-cache view
governance. It competes with checkpoint/restart for that slot.

## Additional Candidates And Existing-Mechanism Precedents

Added 2026-07-25 (second pass). This section originally recorded candidate
patterns and existing-mechanism precedents. The later portfolio update below
promotes toolchain/dependency views to formal W7; SELinux, Plan 9, and dataset
versioning keep the dispositions recorded here.

### SELinux polyinstantiation / pam_namespace (precedent — must cite)

- namespace.conf(5) man page: "The pam_namespace.so module allows setup of
  private namespaces with polyinstantiated directories. Directories can be
  polyinstantiated based on user name or, in the case of SELinux, user name,
  sensitivity level or complete security context."
  https://man7.org/linux/man-pages/man5/namespace.conf.5.html
- Red Hat SELinux guide: "each user's /tmp/ and /var/tmp/ directory is
  automatically mounted under /tmp-inst and /var/tmp/tmp-inst".
  https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/6/html/security-enhanced_linux/

This is the closest shipping mechanism to per-context divergent views of the
same pathname. Key difference for the paper: polyinstantiation creates
static, pre-built per-context instance trees bound at login time; it is not a
programmable, per-lookup, state-dependent policy, and it cannot express
redirect/hide/verified-selection semantics. It is a precedent to position
against, not a competitor that closes the gap.

### Plan 9 per-process name spaces and union directories (intellectual ancestor)

- Pike, Presotto, Thompson, Trickey, Winterbottom, "The Use of Name Spaces in
  Plan 9", Operating Systems Review 27(2):72–76, 1993 (bibliographic record:
  https://9p.io/sys/doc/lexnames.html). Per-process name spaces let each
  process assemble its own view; union directories merge several file trees
  at one point, making even the PATH variable unnecessary.

The per-process namespace idea is the intellectual ancestor of every view
mechanism here; Linux inherited it as mount namespaces. The namei_ext delta:
decisions are programmable policy evaluated at lookup time within one shared
namespace, not static per-process namespace construction.

### Nix / toolchain and dependency version views (demand evidence)

- Dolstra, de Jonge, Visser, "Nix: A Safe and Policy-Free System for Software
  Deployment", LISA'04, pp. 79–92. Official abstract: existing deployment
  systems show "the lack of support for multiple versions or variants of a
  component", and Nix addresses this "through a simple technique of using
  cryptographic hashes to compute unique paths for component instances."
  https://edolstra.github.io/pubs/nspfssd-lisa2004-final.pdf
- The wider ecosystem (Guix, Spack, virtualenv, Conda, nvm, rbenv, HPC
  environment modules/Lmod, Debian update-alternatives(8), and CernVM-FS
  variant symlinks) implements version views with profile trees, filesystem
  views, symlink chains, FUSE policy, and PATH/environment manipulation.

An entire ecosystem exists because "which dependency version does this
project or HPC job see" is a daily problem. The later portfolio update promotes
this family to W7 with real version/build/import, concurrent-isolation, switch,
and rollback oracles. Package solving, installation, activation scripts, and
ABI management stay with the source systems.

### Dataset versioning: lakeFS and DVC (weak fit — related work only)

- lakeFS (official): "an open-source version management system based on
  Git-like semantics that works on top of an existing data lake", applying
  branches/commits/merges to object storage.
  https://lakefs.io/data-version-control/dvc-tools/
- DVC provides git-style versioning for ML project data.

Proves that branch/checkout views are wanted for data as well as code, but
consumption happens through S3 APIs and SDKs rather than POSIX path
resolution, so it does not exercise a VFS name-resolution boundary. Related
work only.

### Honeypot / decoy filesystems

No strong primary citation was found in this pass; the idea (showing
attacker-controlled processes a different object set than real processes)
matches the HIDE/REDIRECT semantics, but without a citable system it remains
an anecdote. Not recorded as evidence.

## Portfolio Update: Industrial Workflows And Benchmarks

Added later on 2026-07-25. This update supersedes the earlier disposition that
toolchain views are only pattern evidence. It does not erase the first-pass
findings above. The complete experiment plan and source inspection are in
`docs/tmp/2026-07-25-case-study-and-standard-benchmark-plan.md`.

### W1 Sandboxed Application File Sharing

The official Documents API exposes host files to sandboxed applications through
a FUSE filesystem, gives each application a restricted view, and supports
grant and revoke operations:
https://flatpak.github.io/xdg-desktop-portal/docs/doc-org.freedesktop.portal.Documents.html.
The API reference also documents automatic host-application identity based on
a standardized cgroup path:
https://flatpak.github.io/xdg-desktop-portal/docs/api-reference.html.

This is a formal W1 case because the source behavior has an exact
per-application visibility oracle. The first experiment covers only registered
existing objects and grant/revoke visibility. Synthetic document IDs, mode
synthesis, persistent permissions, and UI remain portal behavior.

The first real KVM preflight passed under
`results/experiments/application-file-sharing/20260725T-sandboxed-file-sharing-preflight-v3/`.
Two application cgroups exercised hidden-before-grant, visible-after-grant,
cross-application isolation, and hidden-after-revoke behavior. The host object
and an unrelated same-named path remained unchanged, all policy-action counters
were nonzero, and the run reported zero failures.

### W3 Build Action Sandboxing

Bazel's sandboxfs announcement says an action may require hundreds or thousands
of mappings and describes the cost and correctness problems of constructing
symlink forests:
https://blog.bazel.build/2017/08/25/introducing-sandboxfs.html.
The public source remains available, although it is archived:
https://github.com/bazelbuild/sandboxfs.

This is a formal W3 case. A real Bazel action supplies declared-input mappings,
build/test output, and an undeclared-input failure oracle. Remote execution,
CAS transfer, output upload, and process sandboxing remain outside the
`namei_ext` case.

### W6 HPC File Staging

LLNL's official Spindle page documents transparent relocation of libraries,
executables, Python files, and selected data from a shared filesystem to
node-local storage:
https://computing.llnl.gov/projects/spindle.
Current El Capitan documentation says Spindle is automatically enabled for
every job and describes shared library caches and configurable Python/data
prefixes:
https://hpc.llnl.gov/documentation/user-guides/using-el-capitan-systems/using-el-capitan-systems-spindle-and-library.
Public source:
https://github.com/LLNL/Spindle.

Source inspection shows direct `open`, `stat`, `exec`, and loader
interposition, followed by opening a relocated local pathname. Spindle is
therefore the formal W6 source. Its distribution and cache controller remain in
place; the `namei_ext` experiment replaces only the final shared-versus-local
object selection.

### W7 Toolchain And Dependency Environments

This family is now formal W7:

- Nix profiles are versioned symlink trees into the immutable store and support
  atomic generation switching and rollback:
  https://nix.dev/manual/nix/2.34/command-ref/files/profiles.html.
- Guix provides per-user profiles and transactional rollback:
  https://guix.gnu.org/manual/en/guix.pdf.
- Spack environment views link installed packages into conventional
  `bin/lib/include` trees and support symlink, hardlink, or copy views:
  https://spack.readthedocs.io/en/v0.23.1/environments.html.
- Python venv and Conda create environment prefixes and change executable and
  library search state:
  https://docs.python.org/3/library/venv.html and
  https://docs.conda.io/en/latest/user-guide/tasks/manage-environments.html.
- nvm, rbenv, Lmod, and update-alternatives select installed versions through
  environment changes, shims, or symlink groups:
  https://github.com/nvm-sh/nvm,
  https://github.com/rbenv/rbenv,
  https://lmod.readthedocs.io/en/6.6/, and
  https://manpages.debian.org/bookworm/dpkg/update-alternatives.1.en.html.
- CernVM-FS implements "variant symlinks" in its FUSE client so a software or
  certificate path resolves according to client configuration at access time:
  https://cvmfs.readthedocs.io/en/2.14/cpt-repo/#variant-symlinks.

The case reuses installed objects and source-native version/build/import
oracles. It does not replace package solving, installation, activation scripts,
or ABI compatibility management.

The Guix paper also records GNU Hurd `stowfs`, an older dynamic filesystem
approach to software profiles. systemd-sysext/confext materializes read-only
`/usr`, `/opt`, or `/etc` extensions with OverlayFS. These are related-work and
RQ3 precedents, not additional case studies.

### Performance-Benchmark Separation

FxMark is the primary standard RQ2 VFS benchmark; selected IOR/mdtest operations
and Filebench fileserver/webserver profiles provide secondary breadth. These
benchmarks measure stock, patched-unattached, attached `PASS`/`SELECT`, and
FUSE cost. They are not counted as real source-system case studies. The custom
project benchmark remains responsible for `HIDE`, cross-filesystem `SELECT`,
failure, tail latency, and update-to-visible measurements.
