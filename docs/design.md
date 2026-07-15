# Design

Last updated: 2026-07-15
Current status: frozen BUILD_AND_EVALUATE contract after BOOTSTRAP step 0005 in
`docs/tmp/bootstrap/step-0005-20260714T174151-0700/step-report.md`.

BOOTSTRAP step 0005 re-ran the paper/frontier convergence requested by the
user, completed full writing, citation, meaning-preservation, and build checks,
passed independent outer audit, and froze the same strong design for
BUILD_AND_EVALUATE.

`namei_ext` is a `sched_ext`-style VFS extension point. The programmable part
is policy: an eBPF program chooses bounded lookup and directory-enumeration
actions. The non-programmable ownership stays with the kernel and lower
filesystem: path walking, dentries, inodes, permissions, file operations, page
cache, writes, persistence, and consistency.

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

## Policy Contract

The kernel-facing ABI exposes one decision function. Lookup and readdir are
event types passed to that function. The current prototype action set is
`PASS`, `REDIRECT`, `HIDE`, and an initial `SELECT_TARGET`. `REDIRECT` supplies
a bounded replacement component that the kernel validates in the same parent
directory. `HIDE` returns absence for lookup and suppresses the entry during
directory enumeration. `SELECT_TARGET` uses a kernel-held registered `struct
path` selected by an opaque target ID; the current increment supports
intermediate directory selection and final directory selection for stat,
`O_DIRECTORY` open, and readdir over the selected lower directory. It still
fails closed for create, non-directory final opens, final file target
selection, and synthetic parent-directory aliases such as listing an otherwise
nonexistent `ws` entry from the parent. The broader design target still needs
the full Agent workspace lifecycle, operation-weighted traces, and optional
attachment-mode deny before those actions count as full prototype evidence. The
policy does not synthesize file contents, allocate VFS objects, mediate
reads/writes after open, persist custom metadata, or implement distributed
indexes or cross-path transactions.

The requirement-to-design mapping is:

| Requirement | Design choice | Invariant |
| --- | --- | --- |
| State-conditioned lookup/readdir policy | Policy invoked at lookup and directory-enumeration events | Decisions happen at the affected name operation. |
| Preserve lower-filesystem semantics | Return only path-view actions over lower objects | Data, writes, permissions, page cache, and persistence stay lower-filesystem owned. |
| Lookup/readdir coherence | Use one decision contract for both event types | Directory visibility and lookup selection agree. |
| Bounded/verifiable policy | Use eBPF verifier, bounded output fields, and kernel validation | Malformed or unsupported decisions fail visibly. |
| Per-workload scope | Attach at `cgroup/namei_ext` | Workspaces, agents, builds, and services can change policy without replacing the filesystem. |
| Observable provenance | Preserve per-operation events and raw artifacts | Reports derive from raw trace and oracle evidence. |

## Frozen Proof Obligations

BUILD_AND_EVALUATE now needs to prove the following obligations through the
real KVM attach path:

| Design obligation | Required evidence |
| --- | --- |
| The hook is a VFS name-resolution extension point, not a filesystem. | Workloads pass source oracles while lower-filesystem permissions, data path, writes, page cache, persistence, and file methods remain lower-filesystem owned. |
| eBPF policy is expressive enough for path views. | Agent workspace and environment/cache experiments exercise state-dependent lookup/readdir transitions with operation-weighted traces and coherent directory visibility. |
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
