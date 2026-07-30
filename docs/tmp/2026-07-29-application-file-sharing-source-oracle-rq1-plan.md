# Experiment Plan: RQ1 XDG Documents Portal Source Oracle

## Research Question

- RQ exactly as written in the paper: Can a narrow VFS name-resolution
  extension express real state-dependent path-view policies without taking
  over filesystem semantics?
- Specific uncertainty: Does the existing-object grant, cross-application
  isolation, and revoke behavior observed from the unmodified
  `xdg-document-portal` implementation match the behavior produced by
  `namei_ext` through the real `cgroup/namei_ext` KVM attach path?
- Planned role: supporting RQ1 source-fidelity repair for W1. This is not a new
  industrial workflow and does not increase the case-study count.

## Paper-Value Admission

The current W1 result uses a project C probe derived from the XDG Documents
portal documentation. It does not execute the source portal. A reviewer can
therefore argue that the selected states or errors merely fit the mechanism
instead of preserving a real source-system behavior.

This experiment repairs that gap by executing the official portal and the
existing `namei_ext` W1 slice under one frozen normalized oracle. A positive
result upgrades W1 from documentation-derived to source-controlled evidence.
If the portal and `namei_ext` disagree, W1 returns to motivation-only or
documentation-derived status; the other four completed RQ1 workflows are
unchanged.

Adding another AgentFS, Python environment, or global OverlayFS activation row
would repeat an existing workflow or broaden behavior outside name resolution.
DMTCP, Spindle, and full nginx reload have exhausted their three-preflight
protocols. Repairing W1 source fidelity therefore has higher RQ1 decision value
than adding a sixth successful state machine.

## Source System

- Repository: <https://github.com/flatpak/xdg-desktop-portal>
- Release: `1.18.4`
- Commit: `11c8a96b147aeae70e3f770313f93b367d53fedd`
- Source archive:
  <https://codeload.github.com/flatpak/xdg-desktop-portal/tar.gz/11c8a96b147aeae70e3f770313f93b367d53fedd>
- Relevant source:
  `document-portal/document-portal.c`,
  `document-portal/document-portal-fuse.c`,
  `data/org.freedesktop.portal.Documents.xml`, and
  `tests/test-doc-portal.c`.
- Official source behavior: `Add` exports an existing host file,
  `GrantPermissions` exposes it in one application-specific FUSE view, and
  `RevokePermissions` removes the permission. A second application-specific
  view remains isolated.

A disposable source feasibility run built release 1.18.4 against libfuse
3.14.0 and executed upstream `test-doc-portal`; all five upstream subtests
passed without a skip. This is dependency evidence only, not an RQ1 result.
The five upstream subtests cover export, grant, and distinct App1/App2 views;
they do not call `RevokePermissions`. Revoke is grounded in the official
D-Bus API, the implementation's invalidate-before-reply path, and the matched
lifecycle below.

## Hypothesis And Competing Explanation

Expected result: the official portal and `namei_ext` agree on the five
normalized visibility states below. In both mechanisms, granting application A
exposes the registered payload to A, application B remains isolated, revoking
A hides the payload again, and the host file remains unchanged.

The strongest competing explanation is that the source portal's cache
invalidation, hierarchy, or error behavior differs from the project-derived
probe. A stale portal or `namei_ext` dentry after revoke, a cross-application
leak, lookup/readdir disagreement, or different payload bytes contradicts the
expected result.

## Comparison

- Source control: unmodified `xdg-document-portal` 1.18.4 and
  `xdg-permission-store`, using the official D-Bus API and FUSE view.
- Proposed mechanism: the current W1 `namei_ext` policy and controller.
- Main performance baseline: none. RQ1 compares behavior, not timing.
- Controls: direct host-file observations, application B, pre-grant and
  post-revoke states, lower-object preservation, policy engagement, external
  BPF/FUSE inventory, teardown, and dmesg.

The common oracle does not require the portal's FUSE inode to equal the host
inode because the portal owns a virtual inode space. Exact selected
lower-object identity is retained as additional `namei_ext` boundary evidence,
not as a condition the portal must satisfy.

## Frozen Workload

Each mechanism executes the same five normalized states over one existing host
payload and two application identities:

1. application A before grant: hidden;
2. application B before grant: hidden;
3. application A after read grant: visible;
4. application B while A is granted: hidden;
5. application A after revoke: hidden.

The source-control path uses these fixed values:

```text
Add(fd, reuse_existing=false, persistent=false)
application A = org.namei.SourceA
application B = org.namei.SourceB
basename = payload.txt
payload = xdg-portal-existing-object\n
grant permissions = ["read"]
revoke permissions = ["read"]
```

Its exact path mapping is:

```text
portal readdir parent = $MOUNT/by-app/$APP
portal listed name    = $DOC_ID
portal document       = $MOUNT/by-app/$APP/$DOC_ID
portal payload        = $MOUNT/by-app/$APP/$DOC_ID/payload.txt

namei_ext readdir parent = $FIXTURE/view
namei_ext listed name    = document
namei_ext document       = $FIXTURE/view/document
namei_ext payload        = $FIXTURE/view/document/payload.txt
```

The two mechanisms encode application identity differently. The source
control probes the portal's official per-application path hierarchy from a
host controller. The `namei_ext` arm uses two real cgroups. The common claim is
per-application view isolation, not Flatpak sandbox identity enforcement.

The source-control path:

1. starts a private D-Bus session, permission store, and official document
   portal under isolated `HOME`, `XDG_DATA_HOME`, and `XDG_RUNTIME_DIR`;
2. exports an already-created regular file with the official `Add` method;
3. executes the five states using `GrantPermissions` and
   `RevokePermissions`;
4. unmounts the portal and terminates both services and the private bus.

The source arm always runs first. It must fully terminate the portal,
permission store, and private bus and unmount its FUSE view. A midpoint
inventory must then show no FUSE mount, open `/dev/fuse` descriptor, BPF
program, or cgroup attachment before the `namei_ext` arm starts.

The `namei_ext` arm then executes the same state order in two application
cgroups using the existing target registry and grant-state map.

## Correctness Oracle

For every mechanism and state, raw observations record:

- `stat()` result for the logical document and payload;
- `open()` and complete payload read result;
- `opendir()`/complete `readdir()`/`closedir()` result for the logical parent;
- whether the document identifier is listed;
- payload bytes when visible;
- direct host-file bytes and metadata.

Every state allocates a fresh directory stream and closes it before returning.
No directory descriptor is reused across state transitions. Immediately after
`GrantPermissions` or `RevokePermissions` returns, the source controller
executes exactly one complete state probe. It does not sleep, poll, retry, or
discard an initial failure. The `namei_ext` controller follows the same rule
after its BPF map update returns.

The state passes only when:

- visible states complete lookup, open/read, and enumeration and return the
  fixed payload bytes;
- hidden states return `ENOENT` for document lookup and payload open/read,
  while parent enumeration succeeds and omits the document;
- application B remains hidden throughout application A's grant;
- post-revoke observations are made after the source D-Bus call or BPF map
  update has returned successfully;
- each mechanism preserves the direct host payload's type, mode, owner, device,
  inode, size, mtime, ctime, and bytes;
- normalized source and `namei_ext` records agree state by state on exact
  per-operation success or `ENOENT`, enumeration membership, and visible
  bytes;
- the `namei_ext` visible path matches the registered lower object's device and
  inode;
- source FUSE and `namei_ext` policy engagement are both positive;
- detach, unmount, process termination, cgroup removal, target clearing,
  external inventory, and dmesg checks pass.

Policy counters, service logs, and FUSE mount presence establish engagement;
they cannot satisfy the application-visible oracle.

## Runs

| Run | Role | Boots | Completion rule |
| --- | --- | ---: | --- |
| source build/test | dependency | 0 | Build pinned source and execute all five official upstream `test-doc-portal` subtests with zero failure and zero skip |
| preflight | dependency | 1 fresh modified-kernel KVM boot | Complete both mechanisms, all five states, exact normalized comparison, and teardown |
| formal | supporting RQ1 | 3 fresh modified-kernel KVM boots | Every boot passes the unchanged source, `namei_ext`, comparison, preservation, engagement, cleanup, and kernel-health oracle |

This is deterministic correctness replication. It produces no throughput,
latency, or FUSE-performance claim.

At most three real preflight result roots are allowed. Repairs may fix build,
service startup, D-Bus, FUSE mount, artifact, or runner defects, but may not
change the five states or the oracle to accommodate an observed mismatch.

## Execution And Artifacts

- Preflight:
  `make kvm-application-file-sharing-source-oracle-preflight RUN_ID=<fresh-id>`
- Formal:
  `make experiment-application-file-sharing-source-oracle-rq1 RUN_ID=<fresh-id>`
- Preflight raw root:
  `results/experiments/application-file-sharing-source-oracle-rq1-preflight/<RUN_ID>/`
- Formal raw root:
  `results/experiments/application-file-sharing-source-oracle-rq1/<RUN_ID>/`

The Make-owned source path is fixed as follows:

1. download and extract the pinned codeload archive under `.cache/` and
   `.build/workloads/xdg-document-portal-1.18.4/`;
2. build a dedicated image from
   `experiments/application_file_sharing/Dockerfile.xdg-portal` based on
   `debian:bookworm-slim`, with Meson, Ninja, GCC, pkg-config, D-Bus, libcap,
   and the required glib, json-glib, libfuse3, gdk-pixbuf, PipeWire, and
   systemd development packages;
3. mount only the declared source tree read-only and the declared build tree
   read-write into that image, run the container as root with
   `--privileged --device /dev/fuse`, then run:

```text
meson setup /build /source \
  -Dlibportal=disabled -Dgeoclue=disabled -Dsystemd=enabled \
  -Ddocbook-docs=disabled -Dman-pages=disabled -Dpytest=disabled \
  -Dsandboxed-image-validation=false
meson compile -C /build xdg-document-portal xdg-permission-store test-doc-portal
meson test -C /build test-doc-portal --print-errorlogs
```

4. require the captured test output to identify all five subtests as executed,
   with no `SKIP`, `Skipped`, failure, or timeout;
5. return ownership of the declared build tree to the invoking host UID/GID;
6. record the builder image inspection, Meson setup, compiler and dependency
   versions, source commit/URL, build log, complete upstream test log, and
   `ldd` output in the declared build tree.

The KVM runner copies the official portal and permission-store binaries,
source-oracle controller, current `namei_ext` W1 runner and policy, D-Bus XML,
source metadata/logs, and required runtime artifacts into each result root
before boot. Guest startup checks `dbus-daemon`, `fusermount3`, `/dev/fuse`,
all dynamic dependencies, and the portal binary version. No manual host
package installation is required.

Raw artifacts include per-state JSONL, source and `namei_ext` stdout/stderr,
portal and permission-store logs, D-Bus method results, mount and process
observations, source/kernel identities, policy counters, lower-file
observations, external inventories, status, and dmesg. Analysis summarizes raw
observations but does not redefine correctness.

## Interpretation

- Positive: W1 supports the claim that the existing-object
  grant/isolation/revoke subset observed from the official XDG Documents
  portal fits the `namei_ext` boundary.
- Contradictory: remove W1 from source-controlled RQ1 evidence and retain the
  mismatch as engineering evidence. Do not weaken RQ1 or substitute a toy
  workload.
- Inconclusive: any source startup, FUSE, D-Bus, artifact, KVM, cleanup, or
  provenance failure prevents interpretation; it is not a `namei_ext` win.

The experiment does not claim complete portal compatibility, synthetic
document hierarchy equivalence, persistent permission storage, mode or xattr
synthesis, writes through the portal, UI integration, generic sandboxing, or
performance superiority.
