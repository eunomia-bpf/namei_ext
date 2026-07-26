# 2026-07-25 Sandboxed Application File Sharing Preflight Implementation

Date: 2026-07-25
Status: canonical KVM preflight and Phase 1 regression passed

## Motivation

The evaluation now treats Sandboxed Application File Sharing as one industrial
workflow, with XDG Documents portal grant/revoke behavior as its source oracle.
The repository previously had a static `select_portal.bpf.c` regression policy
but no source-derived two-application grant/revoke lifecycle.

## Code Paths Inspected

- `bpf/include/namei_ext.h` and `bpf/include/namei_ext_policy.h` for the
  cgroup identity, `HIDE`, and registered-target `SELECT` ABI;
- `kernel/fs/namei_ext.c` for target registration, cgroup-scoped target lookup,
  and readdir action handling;
- `tests/agent_workspace/namei_ext_agent_workspace.c` for the real libbpf
  attach and target-registration path;
- `tests/w1_oracle/namei_ext_w1_oracle.c` for converting a cgroup path to the
  kernel cgroup ID used by BPF maps.

## Implementation

- `bpf/policies/application_file_sharing.bpf.c` adds a portal-scope map keyed
  by parent device/inode and logical name, plus a grant map that adds the
  application cgroup ID. For a managed `document` entry, an authorized lookup
  selects a registered target, an unauthorized lookup or readdir hides the
  entry, and authorized readdir passes the existing placeholder entry.
- `tests/application_file_sharing/namei_ext_application_file_sharing.c`
  creates two application cgroups, registers an existing host directory for
  application A, and executes the fixed before-grant, granted, cross-application
  isolation, and revoked oracle in child processes moved into those cgroups.
- The runner verifies the lower object's device, inode, mode, size, and bytes,
  checks an unrelated same-named path for scope containment, and checks BPF
  execution counters.
- The owning Make targets build the runner and execute it in KVM. Raw output is
  written under `results/experiments/application-file-sharing/<RUN_ID>/`,
  including JSONL, dmesg, command, source hashes, kernel config, uname, and
  kernel/policy/runner artifact hashes.

## Alternatives Rejected

- A single-process static `select_portal.bpf.c` test does not exercise
  application identity or grant/revoke.
- Implementing the complete XDG portal would add synthetic hierarchy,
  persistence, and UI responsibilities outside the paper's boundary.
- A host-only test would not satisfy the Phase 1 KVM validation rule.

## Validation

Host build:

```text
make application-file-sharing
make bpf
```

Both completed without compiler warnings.

KVM run:

```text
make kvm-application-file-sharing-preflight \
  RUN_ID=20260725T-sandboxed-file-sharing-preflight-v3
```

Raw result:

```text
results/experiments/application-file-sharing/20260725T-sandboxed-file-sharing-preflight-v3/
```

Observed results:

- application A was hidden before grant, visible after grant, and hidden after
  revoke;
- application B remained hidden before and during A's grant;
- open, stat, read, and readdir oracles passed;
- an unrelated path containing the same `document` component remained on its
  original lower object, confirming parent/name scope containment;
- the host object's device, inode, mode, size, and bytes were unchanged;
- counters recorded 123 lookup, 30 readdir, 2 `SELECT`, 8 lookup `HIDE`, and 4
  readdir `HIDE` events;
- the summary reported `pass=true` and `failures=0`;
- dmesg contained no warning, oops, call trace, hung-task, or sanitizer
  signature.

The Make target fails on any oracle error, BPF load/attach failure, target
registration failure, or kernel warning.

The final implementation also passed the repository-wide Phase 1 regression:

```text
make phase1 RUN_ID=20260725T-application-file-sharing-regression-v2
```

This rebuilt or checked the ABI, every BPF policy, userspace functional and
benchmark binaries, touched kernel objects, and passed KVM smoke, generic
policy-load, and functional suites. Raw regression output is under
`results/phase1/20260725T-application-file-sharing-regression-v2/`.

An earlier `v1` preflight passed the grant/revoke oracle but keyed grants only
by cgroup and component name. Static review found that this scope was too
broad. The `v2` policy added portal parent device/inode and logical name to the
managed scope and grant keys. The canonical `v3` rerun preserves the same
scoped oracle and additionally records uname, kernel config, and
kernel/policy/runner artifact hashes.

## Remaining Risks

- Registered targets are keyed by cgroup ID, so target registration must occur
  from a process already moved into application A's cgroup.
- Readdir cannot use `SELECT_TARGET`; the policy passes the existing logical
  placeholder for authorized applications and hides it for unauthorized ones.
- The preflight covers only existing-object visibility and selection. It does
  not reproduce the portal's synthetic document layout, persistent
  permissions, or UI.
- A matched project FUSE implementation and timing comparison remain open;
  this preflight is supporting RQ1 evidence, not an RQ2 performance result.
