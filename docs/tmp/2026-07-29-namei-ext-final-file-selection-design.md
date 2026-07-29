# namei_ext Final Existing-File Selection Design

## Motivation

The canonical `namei_ext` story says that a policy may choose which existing
file or directory a pathname denotes while the VFS and the lower filesystem
retain object and data-path semantics. The current prototype implements only
registered directory targets. That is sufficient for selecting a workspace
root, but it does not implement the final-file action required by source
workloads such as Spindle, application file sharing, cache-object selection,
or configuration publication.

This is an implementation gap, not a reason to narrow the paper hypothesis.
The original registered-target design already named final existing-object
selection as the broader design target.

## Code Paths Inspected

- `kernel/fs/namei_ext.c`
  - registered `struct path` ownership and RCU lookup;
  - `namei_ext_lookup()` action validation;
  - target replacement and clearing.
- `kernel/fs/namei.c`
  - component lookup through `walk_component_namei_ext()`;
  - final open through `open_last_lookups_namei_ext()`;
  - RCU-walk target borrowing and `complete_walk()`;
  - normal `may_open()` and `vfs_open()` completion.
- `tests/functional/namei_ext_functional.c`
  - target registration;
  - final and intermediate selected-directory coverage;
  - `RESOLVE_CACHED` and concurrent target replacement.
- `docs/tmp/2026-07-13-registered-target-selection-design.md`
  - the previously recorded final existing-object design target.
- `docs/tmp/2026-07-27-namei-ext-rcu-target-selection-design.md`
  - target lifetime and borrowed-path constraints.

## Semantic Contract

The existing `SELECT_TARGET` action and registry remain unchanged:

```text
(cgroup ID, target ID) -> kernel-held struct path
```

The increment changes where an already registered path may be installed:

1. An intermediate selected target must still be a directory.
2. A final selected target may be an existing regular file or directory.
3. A final lookup with `LOOKUP_DIRECTORY` still requires a directory.
4. `LOOKUP_CREATE` through `SELECT_TARGET` remains unsupported and fails
   closed.
5. Registered symbolic-link objects are rejected. The controller may register
   the resolved object instead; `namei_ext` does not invent separate
   target-symlink traversal semantics.
6. Special files, including devices, sockets, and FIFOs, are rejected. The
   final-file increment admits only regular files and directories.
7. Scoped lookup and `LOOKUP_NO_XDEV` restrictions remain unchanged.
8. Unknown targets, targets removed from the registry, malformed targets, and
   type-incompatible uses fail visibly.

The policy returns only an opaque target ID. It does not return a pathname,
open a file, allocate an inode, synthesize contents, or handle file methods.

## VFS Completion

For final `stat`, `access`, or `O_PATH` lookup, the selected path becomes
`nd->path` and the existing `complete_walk()` path validates and legitimizes
it.

For final ordinary open and exec, the selected path becomes `nd->path` before
`do_open()`. Existing VFS code then performs:

- final path validation;
- mount and inode permission checks;
- open-mode and truncation checks;
- LSM file-open checks;
- the lower filesystem's `vfs_open()` operation; and
- the existing post-open security hook.

The increment must not directly construct a `struct file` or bypass
`may_open()`.

Registration has object-capability semantics. The controller first resolves a
physical pathname and gives the registry a referenced `struct path`.
Subsequent policy selection makes that object reachable through the logical
pathname. The VFS checks traversal permission on the logical path and
permissions on the selected target inode and mount; it does not replay
traversal of the target's original physical parents. This is the same
intentional reachability change made by exposing an object at a bind-mounted
path. Registration authority and cgroup policy scope therefore define who may
gain this reachability.

The target registry continues to own one mount and dentry reference.
RCU-walk readers borrow that registered path exactly as selected directories
do today; ref-walk readers acquire their own reference. Replacement and clear
continue to wait for an RCU grace period before releasing retired paths.
The registry pins object identity, not a live pathname. Renaming, replacing, or
unlinking the original physical pathname does not silently retarget or revoke
the registered object. The controller must re-register the target ID or clear
the registry to publish or revoke a new object.

## Minimal Implementation

The expected kernel change is local:

- remove the blanket rejection of non-directory `LOOKUP_OPEN` actions in
  `namei_ext_lookup()`;
- teach target application whether the selected component must be a directory;
- require directories for intermediate components and
  `LOOKUP_DIRECTORY` final operations;
- allow a final regular-file target to proceed through normal VFS completion;
- reject symbolic-link and special-file registrations;
- release a completed symlink stack before returning a selected target from
  generic path lookup; and
- retain all existing error cleanup for borrowed and owned target paths.

The Phase 1 registration helper must open targets with `O_PATH` rather than
requiring `O_DIRECTORY`. Existing directory registrations continue to work.

No new BPF action, context field, map type, policy language, or control-plane
interface is needed.

## Validation

The functional suite must add real modified-kernel KVM coverage for:

- final selected-file `stat`, `open`, read, `access`, and exec;
- final selected-file `O_PATH` with `RESOLVE_CACHED`, proving the RCU path;
- ordinary cross-mount file selection plus `RESOLVE_NO_XDEV`,
  `RESOLVE_BENEATH`, and `RESOLVE_IN_ROOT` rejection;
- selected-file target replacement and restoration;
- the object-capability distinction: an inaccessible original target parent
  does not remove registered reachability, while target inode mode still
  denies an unprivileged open;
- pinned-object behavior after unlink and explicit revocation by registry
  clear;
- symbolic-link and FIFO registration rejection;
- a regular-file target rejected as an intermediate path component;
- final `LOOKUP_DIRECTORY` rejected for a regular-file target;
- create-through-select rejected;
- selection reached through a followed logical symlink, including link-stack
  cleanup;
- target clear and detach restoring normal absence;
- existing selected-directory, `PASS`, `REDIRECT`, `HIDE`, readdir, scope,
  and concurrent replacement cases unchanged; and
- no warning, BUG, oops, lockdep, sanitizer, or hung-task signal in dmesg.

Build and validation remain Make-owned. The minimum dependency sequence is:

```text
make bpf functional kernel-objects
make kvm-functional
```

After the functional path passes, the complete Phase 1 suite must run before a
Spindle preflight uses final-file selection.

## Experiment Consequence

This implementation is dependency work, not an RQ1 result. It unlocks the
source-derived Spindle experiment in which Spindle populates exact cache files
and `namei_ext` selects those files through their original source pathnames.
The Spindle plan remains invalid until this mechanism is implemented, passes
KVM validation, and the experiment reviewer approves the repaired execution
contract.

## Alternatives Rejected

- Selecting only cache directories and redirecting generated Spindle
  basenames would make the experiment depend on Spindle's internal cache-name
  layout and would not test the paper's promised existing-file action.
- Copying or renaming cache files into a view tree would replace target
  selection with materialization and weaken source-mechanism engagement.
- Returning path strings from BPF would introduce arbitrary path rewriting and
  a second pathname walk.
- Opening the target in BPF or a userspace daemon would move file-operation
  ownership outside the declared VFS boundary.

## Remaining Risks

- Final-file selection must not accidentally skip ordinary target permission
  checks.
- RCU-walk must sample and legitimize the selected file dentry exactly as it
  does a selected directory.
- Final symbolic-link behavior is deliberately excluded until it has a
  separate, explicit contract.
- Registration currently uses a Phase 1 debugfs control surface; this
  experiment does not settle an upstream control-plane ABI.
