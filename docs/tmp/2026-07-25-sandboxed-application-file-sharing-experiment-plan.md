# 2026-07-25 Sandboxed Application File Sharing Experiment Plan

Date: 2026-07-25
Status: admitted supporting RQ1 preflight

## Objective

Test whether the existing-object grant/revoke subset of the XDG Documents
portal fits the current `namei_ext` boundary through the real
`cgroup/namei_ext` KVM attach path.

This is the first implementation preflight after organizing the evaluation
around seven industrial workflows. It is not a complete reproduction of
xdg-desktop-portal and does not test synthetic document-ID directories,
persistent permissions, portal UI, or mode synthesis.

## Source Behavior

The official XDG Documents portal documentation defines a FUSE filesystem that
exposes selected host files to sandboxed applications. Access is scoped by
application identity and can be granted and revoked. The portal API
documentation also defines cgroup-based application identity for host
applications.

Primary sources:

- https://flatpak.github.io/xdg-desktop-portal/docs/doc-org.freedesktop.portal.Documents.html
- https://flatpak.github.io/xdg-desktop-portal/docs/api-reference.html
- https://github.com/flatpak/xdg-desktop-portal

The source behavior is the correctness oracle. Published and official source
evidence already establishes that the full portal uses FUSE; this preflight
does not rerun FUSE for a performance claim.

## Hypothesis

A cgroup-keyed eBPF policy can expose one registered existing host document to
one application after a grant, hide it from another application, and hide it
again after revocation, while the VFS and lower filesystem retain the host
object's data and metadata.

A positive result adds source-grounded breadth to RQ1. A failure identifies a
specific insufficiency in per-cgroup state, `SELECT`, readdir filtering,
grant-update visibility, or lower-object preservation. It does not change the
RQ or imply that the complete XDG portal belongs inside `namei_ext`.

## Oracle

The fixed sequence is:

1. application A and application B cannot look up or enumerate the document
   before a grant;
2. granting A lets A `stat`, `open`, read, and enumerate the existing host
   document;
3. B remains unable to look up or enumerate the document while A has access;
4. revoking A makes subsequent lookup and readdir hide the document again;
5. the host object's device, inode, mode, size, and bytes remain unchanged;
6. an unrelated path with the same `document` component remains unchanged,
   proving that the grant is scoped to the portal parent rather than a global
   name match;
7. BPF counters prove that lookup, readdir, `SELECT`, and both `HIDE` paths
   executed.

Any failed operation, policy load/attach failure, unregistered target, stale
visibility after revocation, or kernel warning fails the Make target.

## Execution

Canonical command:

```text
make kvm-application-file-sharing-preflight
```

The command builds the policy and runner, boots the modified kernel in KVM,
uses two child cgroups as application identities, attaches through
`BPF_CGROUP_NAMEI_EXT`, and preserves raw JSONL, dmesg, command, and input
hashes, plus kernel config and kernel/policy/runner artifact hashes under:

```text
results/experiments/application-file-sharing/<RUN_ID>/
```

## Evidence Role And Follow-Up

Role: supporting RQ1 breadth.

This preflight makes no latency or throughput claim. A matched portal-style
FUSE implementation is necessary only if this workflow is selected as a
representative RQ2 macro case. Standard FxMark and mechanism-specific
microbenchmarks remain the main RQ2 evidence.
