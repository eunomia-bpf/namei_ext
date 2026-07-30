# Application File Sharing Source-Oracle RQ1 Implementation

## Motivation

The completed Sandboxed Application File Sharing result used a project-owned
controller derived from the XDG Documents portal documentation. It exercised
the real `cgroup/namei_ext` path, but it did not execute the source portal.
This implementation adds an official-source control so that the portal and
`namei_ext` must satisfy the same fixed grant, isolation, and revoke oracle.

This is a source-fidelity repair for the existing W1 workflow. It does not add
a new workflow, make a performance claim, or claim complete Documents portal
compatibility.

## Upstream Source

The Make-owned source build pins:

- `xdg-desktop-portal` release `1.18.4`;
- commit `11c8a96b147aeae70e3f770313f93b367d53fedd`;
- the official document portal, permission store, D-Bus API XML, FUSE
  implementation, and `test-doc-portal` source.

`experiments/application_file_sharing/Dockerfile.xdg-portal` provides a
Debian bookworm build environment. The source build runs all five official
`test-doc-portal` subtests with FUSE enabled and requires zero skips, failures,
and timeouts. A host positive control also executes the built portal's
`--version` command and requires the exact `xdg-desktop-portal 1.18.4`
output before a KVM run can start.

The upstream test covers export, grant, and distinct App1/App2 views. It does
not cover `RevokePermissions`; the source controller exercises that official
D-Bus method directly.

## Files Changed

- `experiments/application_file_sharing/xdg_document_portal_oracle.c`
  starts an isolated D-Bus session, the official permission store, and the
  official FUSE document portal; calls `Add`, `GrantPermissions`, and
  `RevokePermissions`; records five state observations; and tears down every
  source process and mount.
- `experiments/application_file_sharing/Dockerfile.xdg-portal` defines the
  pinned source builder.
- `experiments/application_file_sharing/Makefile` builds the source
  controller with GLib/GIO.
- `experiments/application_file_sharing/namei_ext_application_file_sharing.c`
  extends lower-object preservation to owner and timestamps and reads payloads
  through EOF.
- `configs/benchmarks/application_file_sharing.mk` freezes the source release,
  commit, archive, result roots, boot counts, and timeout.
- `mk/experiments/application_file_sharing.mk` owns source download, build,
  source tests, artifact capture, source-first KVM execution, midpoint
  isolation, the `namei_ext` arm, finalization, and analysis.
- `Makefile` exposes the source, preflight, formal, and analysis entrypoints.
- `mk/suites.mk` admits the preflight to the current dependency gates but
  keeps the formal entrypoint outside the aggregate until that preflight
  passes.

## Frozen State Machine

Both mechanisms execute these states in this order:

1. application A before grant is hidden;
2. application B before grant is hidden;
3. application A after grant is visible;
4. application B during A's grant is hidden;
5. application A after revoke is hidden.

The source arm uses the official
`$MOUNT/by-app/$APP/$DOC_ID/payload.txt` hierarchy. The `namei_ext` arm uses
two real cgroups and the existing W1 logical path. Grant and revoke are each
followed by exactly one complete observation after the source D-Bus call or
BPF map update returns. There is no delay, retry, or discarded first result.

Each state records logical document and payload `stat`, complete payload
`open`/read through EOF, a fresh complete parent directory enumeration, exact
listing membership, and direct host-object bytes. Hidden operations must
return `ENOENT`; only the application-A post-grant state may be visible.

## Independent Oracle

The finalizer does not accept controller `pass` fields as the state oracle.
For each boot it independently requires one source row and one `namei_ext` row
for every frozen state, evaluates the exact visible or hidden errno and
directory-membership tuple, requires only the post-grant A state to be
visible, and then requires the two mechanisms to agree.

Separate finalizer checks cover:

- unchanged host and lower-object device, inode, type, mode, owner, size,
  mtime, ctime, and bytes;
- exact logical-to-registered-lower device and inode identity for the visible
  `namei_ext` document and payload;
- positive lookup, readdir, select, and hide policy counters;
- five executed upstream source tests with no skip or failure;
- source and `namei_ext` process exit status;
- empty external BPF and FUSE inventories before, between, and after arms;
- exact portal binary version and complete dynamic dependencies; and
- successful boot status and clean dmesg.

The analysis target only summarizes a result root that the common run
infrastructure has already marked complete. It does not assign a
paper-facing verdict.

## Failure Evidence

The source controller writes D-Bus error domain, code, remote error name, and
message to its captured stderr before releasing each `GError`. Portal and
permission-store stdout/stderr are preserved independently. Process teardown
records the PID, raw wait status, normal exit code or terminating signal, and
stop error in the observation stream. An initiated service passes teardown
only with exit code zero or the controller's expected `SIGTERM`; an unexpected
exit status fails the source summary.

## Validation Performed

The pinned source dependency completed successfully:

```text
upstream test plan: 1..5
upstream subtests: 5 ok
Fail: 0
Skipped: 0
Timeout: 0
portal version: xdg-desktop-portal 1.18.4
```

The two controllers compile with `-Werror -Wall -Wextra`.
`make application-file-sharing`, `make application-file-sharing-source`,
`make help`, and `git diff --check` pass.

The independent finalizer expression was tested against two generated
observation streams. It accepts the frozen five-state oracle and rejects the
counterexample in which both mechanisms hide every state while self-reporting
success.

A prior disposable privileged-container run of the source controller passed
all five source states and removed its FUSE mount. That run is dependency
diagnosis only; it is not paper evidence.

## Remaining Work

No modified-kernel KVM run has been attempted for this implementation.
Execution remains gated on independent implementation review. After review
returns `GO`, the next steps are one fresh-boot preflight, the unchanged
three-boot formal run, and an independent review of the raw formal result.

The experiment covers only existing-object read grant, per-application
visibility, and revoke. Synthetic contents, persistent grant storage, write
mediation, portal UI integration, mode synthesis, and general sandbox
identity enforcement remain outside the claim.
