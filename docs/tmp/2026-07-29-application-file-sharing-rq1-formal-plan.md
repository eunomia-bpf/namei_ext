# Experiment Plan: RQ1 Sandboxed Application File Sharing

## Research Question

- RQ exactly as written in the paper: Can a narrow VFS name-resolution
  extension express real state-dependent path-view policies without taking
  over filesystem semantics?
- Specific uncertainty: Can the current mechanism reproduce the
  existing-object grant/revoke subset of the XDG Documents portal for two
  application identities, including lookup and directory-enumeration
  visibility, while preserving the host object and unrelated paths?
- Planned role: supporting RQ1 breadth.

## Paper-Value Admission

The old W1 result is one preflight boot with aggregate pass cases. It does not
preserve per-state syscall, enumeration, and object-identity observations, and
it ran on an older kernel commit. This experiment adds independently
recomputable state records and three fresh boots on the current mechanism.

The largest credible result is that one bounded decision function can implement
the tested existing-object document grant/revoke view for a project C probe
using ordinary POSIX operations while VFS and the lower filesystem retain file
operations, object identity, and the lower object through the lifecycle.

The strongest competing explanations are that revocation leaves a stale
positive lookup, directory enumeration diverges from lookup, application B
inherits A's grant, the logical object is not the registered host object, or
the parent/name rule affects an unrelated same-named path.

If positive, W1 becomes reviewed current-mechanism RQ1 evidence. If
contradictory or inconclusive, the old preflight remains historical and W1 is
not promoted. This is higher value than reopening the closed W4, W5, or W6
dependency protocols and adds a distinct application-sandbox workflow beyond
Agent Workspaces, Build Action Sandboxing, and Toolchain Environments.

## Source Behavior And Assets

- Official Documents portal API:
  <https://flatpak.github.io/xdg-desktop-portal/docs/doc-org.freedesktop.portal.Documents.html>
- Official Documents portal FUSE hierarchy:
  <https://flatpak.github.io/xdg-desktop-portal/docs/documents-and-fuse.html>
- Official portal identity API:
  <https://flatpak.github.io/xdg-desktop-portal/docs/api-reference.html>
- Official implementation:
  <https://github.com/flatpak/xdg-desktop-portal>

The source system exposes selected host documents through a FUSE filesystem,
scopes access by application identity, and supports grant and revoke. This
experiment implements only the existing-object visibility and selection
subset. Synthetic document-ID directories, persistent permission storage,
mode synthesis, user interaction, and portal orchestration remain out of
scope.

The real assets are the current `application_file_sharing.bpf.c` policy, the C
controller, two cgroup identities, one registered lower document, and
unmodified POSIX `stat`, `access`, `open`/read, `opendir`, and `readdir`
operations.

## Comparison

- Proposed method: current `cgroup/namei_ext` application-file-sharing policy.
- Main baseline: none. This is an RQ1 sufficiency experiment. The official
  portal establishes the source behavior and FUSE implementation; a matched
  timing comparison belongs to RQ2.
- Controls: application B, pre-grant and post-revoke states, an unrelated
  same-named path, direct lower-object observations, external BPF/FUSE
  inventory, and teardown.

No table, materialized-view, symlink, mount, or additional FUSE row is added.

## Workload And Oracle

One boot executes five source-derived visibility states:

1. application A before grant: hidden;
2. application B without grant: hidden;
3. application A after grant: visible;
4. application B during A's grant: hidden;
5. application A after revoke: hidden.

Each state records:

- document lookup result;
- payload lookup/read result;
- whether readdir lists `document`;
- whether the unrelated same-named path retains its expected bytes;
- for the visible state, logical and registered-lower device/inode identity;
- direct expected payload bytes.

The granted-state directory check establishes only that enumeration exposes
the logical name. The policy returns `PASS` for that directory entry; lookup of
the logical name performs `SELECT_TARGET` and supplies the object-identity
observation.

Correctness additionally requires:

- exactly one acknowledged grant and revoke;
- positive lookup, readdir, `SELECT`, lookup-`HIDE`, and readdir-`HIDE`
  counters;
- unchanged lower payload device, inode, mode, size, and bytes;
- a saved lower payload and unrelated payload that directly match their fixed
  expected bytes;
- policy detach, target clearing, and both application cgroup removals;
- empty external BPF/FUSE inventory before and after;
- clean source and kernel trees and a clean dmesg scan.

## Runs

| Run | Role | Repetitions | Completion rule |
| --- | --- | ---: | --- |
| preflight | dependency | 1 fresh KVM boot | complete five-state lifecycle and every control |
| formal | proposed | 3 fresh KVM boots | every boot passes unchanged workload and oracle |

This is deterministic correctness replication, not a performance experiment.
No duration distribution or general portal-performance claim is produced.

## Execution

- Preflight:
  `make kvm-application-file-sharing-preflight RUN_ID=<fresh-id>`
- Formal:
  `make experiment-application-file-sharing-rq1 RUN_ID=<fresh-id>`
- Raw roots:
  `results/experiments/application-file-sharing-rq1-preflight/<RUN_ID>/`
  and
  `results/experiments/application-file-sharing-rq1/<RUN_ID>/`

The host finalizer requires one record for each state, lower object, lifecycle
case, policy counter, and cleanup operation per boot. It independently
compares the saved lower files with fixed expected byte files. A failed root
is preserved and never repaired in place.

## Interpretation

- Positive: admit W1 as supporting evidence that the tested existing-object
  grant/revoke view fits the narrow name-resolution boundary.
- Contradictory: remove W1 from current-mechanism RQ1 evidence and retain the
  failing state internally.
- Inconclusive: any failed or missing boot, state, lower-object, cleanup,
  inventory, or dmesg observation prevents promotion.

The result does not claim complete XDG portal compatibility, generic
application sandboxing, FUSE superiority, or that this one workload answers
all of RQ1.
