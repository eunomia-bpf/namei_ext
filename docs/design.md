# Design

Last updated: 2026-07-30
Current status: frozen BUILD_AND_EVALUATE contract after BOOTSTRAP step 0005 in
`docs/tmp/bootstrap/step-0005-20260714T174151-0700/step-report.md`.

BOOTSTRAP step 0005 re-ran the paper/frontier convergence requested by the
user, completed full writing, citation, meaning-preservation, and build checks,
passed independent outer audit, and froze the same strong design for
BUILD_AND_EVALUATE.

`namei_ext` treats dynamic filesystem views as pathname late binding rather
than necessarily as new filesystems. It separates that binding from filesystem
ownership: eBPF chooses a bounded binding, while the VFS validates the result,
owns the selected object, and executes ordinary lower-filesystem semantics.

The central design problem is not exposing another BPF attachment type. It is
defining when a policy-selected object can replace the current namei result.
The current walk carries operation intent, root and mount constraints,
RCU/ref-walk state, and sequence validation, not just an inode pointer. The
acceptance contract therefore requires a pre-registered object, compatible
type and operation, preserved traversal constraints, stable lifetime across
concurrent replacement, and normal VFS continuation. One binding contract must
also cover intermediate components, final lookup/open, and directory
iteration. An early fast path for unattached or unmanaged parents is a
deployment requirement for placing the extension on a system-wide hot path.

## Position

The design sits in a four-point mechanism sequence:

- namespace construction: bind mounts, OverlayFS, projected volumes, symlink
  forests, copies, and other materialized views;
- eBPF LSM and related access-control hooks: verified policy that mediates
  permissions or security decisions, but does not naturally own path-view object
  selection;
- `namei_ext`: verified policy at VFS name resolution for bounded lookup and
  directory-enumeration actions;
- programmable filesystem ownership: FUSE, stackable filesystems, custom
  filesystems, and metadata services.

The paper should not argue that these mechanisms are invalid. It should ask
when their broader boundary is unnecessary because the oracle-relevant behavior
is only pathname-to-object selection or visibility over existing lower objects.
ExtFUSE and FUSE-BPF are the closest architectural challenge: both can execute
BPF-assisted lookup or backing-object logic, but do so inside a mounted FUSE
filesystem boundary. The `namei_ext` distinction must be stated in ownership
terms: ordinary VFS paths remain the selected objects, RCU/ref-walk and target
replacement are VFS responsibilities, normal permission/open completion
resumes after selection, and unrelated VFS parents can bypass policy before
dispatch. FUSE-BPF's `root_dir`/`no_daemon` passthrough mode means daemon
elimination is not the distinction; the remaining difference is the mounted
FUSE instance, FUSE inodes, and filesystem-operation forwarding surface.

## Policy Contract

The kernel-facing ABI exposes one decision function. Lookup and readdir are
event types passed to that function. The current prototype action set is
`PASS`, `REDIRECT`, `HIDE`, and `SELECT_TARGET`. `REDIRECT` supplies
a bounded replacement component that the kernel validates in the same parent
directory. `HIDE` returns absence for lookup and suppresses the entry during
directory enumeration. `SELECT_TARGET` uses a kernel-held registered `struct
path` selected by an opaque target ID. An intermediate selected target must be
a directory; a final target may be an existing regular file or directory.
Final file lookup, stat, access, ordinary open, and exec continue through normal
VFS completion and lower-filesystem file operations. Both `REDIRECT` and
`SELECT_TARGET` reject `LOOKUP_CREATE`; symbolic-link and special-file targets,
type-incompatible use, and synthetic parent-directory aliases such as listing
an otherwise nonexistent `ws` entry from its parent fail closed or remain
unsupported.

During RCU-walk, a selected target is borrowed from an RCU-published registry.
The registry retains the target path until a grace period after replacement or
removal. Existing namei dentry and mount sequence validation obtains stable
references or rejects a changed walk before the selected object is used outside
RCU. Ref-walk takes independent path references directly.

Successful in-place RCU-to-ref conversion applies the saved action without
reinvoking the BPF program. If namei returns `-ECHILD`, the VFS may restart the
complete path walk and execute policy again. The ABI is therefore at-least-once
across a full VFS restart; policy-visible side effects must be idempotent.

The common path first checks the global BPF static key, then a conservative RCU
index of exact managed parents. Unattached and unrelated paths bypass context
construction and cgroup discovery. A positive prefilter result still runs the
authoritative attachment and scope checks; a false negative is forbidden.

Registration makes the existing object selectable by opaque ID. The logical
path is checked for traversal, and the selected target inode and mount retain
their ordinary permission checks, but lookup does not replay traversal through
the target's physical parents. The registry pins object identity rather than a
live physical pathname; rename or unlink does not revoke an existing
registration, so the controller must replace or clear it. The policy does not
synthesize file contents, allocate VFS objects, mediate reads/writes after open,
persist custom metadata, or implement distributed indexes or cross-path
transactions.

The requirement-to-design mapping is:

| Requirement | Design choice | Invariant |
| --- | --- | --- |
| State-conditioned lookup/readdir policy | Policy invoked at lookup and directory-enumeration events | Decisions happen at the affected name operation. |
| Preserve lower-filesystem semantics | Return only path-view actions over lower objects | Data, writes, permissions, page cache, and persistence stay lower-filesystem owned. |
| Lookup/readdir coherence | Use one action vocabulary for both event types and test both directions in each workload oracle | The policy, not the kernel, is responsible for making directory visibility agree with lookup selection. |
| Bounded/verifiable policy | Use eBPF verifier, bounded output fields, and kernel validation | Malformed or unsupported decisions fail visibly. |
| Per-workload scope | Attach at `cgroup/namei_ext` | Workspaces, agents, builds, and services can change policy without replacing the filesystem. |
| Observable provenance | Preserve per-operation events and raw artifacts | Reports derive from raw trace and oracle evidence. |

## Frozen Proof Obligations

BUILD_AND_EVALUATE now needs to prove the following obligations through the
real KVM attach path:

| Design obligation | Required evidence |
| --- | --- |
| The hook is a VFS name-resolution extension point, not a filesystem. | Workloads pass source oracles while lower-filesystem permissions, data path, writes, page cache, persistence, and file methods remain lower-filesystem owned. |
| eBPF policy is expressive enough for path views. | Agent workspace and traditional path-view case studies exercise state-dependent lookup/readdir/open/stat transitions with operation-weighted traces, released task oracles, and coherent directory visibility. |
| eBPF LSM is the neighboring security hook, not the same abstraction. | Related-work/design comparison shows LSM mediates access while `namei_ext` changes bounded pathname-to-object selection during resolution. |
| FUSE is the closest programmable-policy cost comparison. | Feature-equivalent FUSE policies run the same source oracle and policy state machine before cost numbers are interpreted. |
| Custom/stackable filesystems own a broader boundary. | RQ3 evidence accounts for required filesystem methods, daemon or privileged code surface, state ownership, invalid-policy containment, and data/write-path responsibilities. |
| The project is not a collection of proxy checks. | Every paper result belongs to an admitted complete experiment with preflight, full matrix, raw results, and result review. |

## Design Rule

For every workload, first classify the source-system behavior:

1. path selection or visibility that `namei_ext` may own;
2. ordinary lower-filesystem behavior that must stay with the lower filesystem;
3. behavior that needs a broader owner such as FUSE, a custom filesystem, a
   metadata service, or an application/runtime mechanism.

This rule keeps the design claim precise while leaving the experiment plan free
to build the strongest evidence for the name-resolution hypothesis.
