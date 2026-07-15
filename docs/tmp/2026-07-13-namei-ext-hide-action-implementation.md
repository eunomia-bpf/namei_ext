# Implementation Record: namei_ext HIDE Action

Date: 2026-07-13

## Motivation

The current paper story treats `namei_ext` as a `sched_ext`-style VFS extension
point for bounded path-view policy. The AgentFS-derived headline experiment
needs an absence/visibility action for whiteout, delete, and protected-path
semantics:

```text
logical path + workspace state -> selected existing lower object or hidden name
```

Same-parent `REDIRECT` alone can test aliasing, but it cannot represent a lower
name that should be invisible in both lookup and directory enumeration.

## Design Choice

Add `BPF_NAMEI_EXT_HIDE = 2` to the existing one-decision `cgroup/namei_ext`
ABI. The action remains inside the name-resolution boundary:

- lookup returns `-ENOENT`;
- readdir skips the current entry and keeps iterating;
- the lower filesystem still owns dentries, inodes, permissions, file
  operations, data path, page cache, writes, and persistence;
- malformed or unsupported actions still fail through the dispatcher/verifier
  range checks.

This does not add synthetic contents, custom metadata persistence, cross-path
transactions, COW write ownership, or a filesystem daemon.

## Files Changed

- `bpf/include/namei_ext.h`: exported the BPF-side `BPF_NAMEI_EXT_HIDE` value.
- `kernel/include/uapi/linux/bpf.h`: exported the kernel UAPI value.
- `kernel/tools/include/uapi/linux/bpf.h`: kept the tools UAPI mirror in sync.
- `kernel/include/linux/namei_ext.h`: mirrored the action in the internal enum.
- `kernel/kernel/bpf/cgroup.c`: accepted policy return values through `HIDE`.
- `kernel/kernel/bpf/verifier.c`: expanded the verifier return range to
  `PASS..HIDE`.
- `kernel/fs/namei_ext.c`: implemented lookup absence and readdir suppression.
- `bpf/include/namei_ext_policy.h`: allowed map-driven rules to return `HIDE`.
- `bpf/policies/hide_secret.bpf.c`: added a minimal semantic policy that hides
  `secret`.
- `tests/abi/namei_ext_abi.c`: pinned the new enum value without changing the
  context layout.
- `tests/functional/namei_ext_functional.c`: extended the functional lifecycle
  to verify lookup/open/access/readdir hide behavior and detach recovery.
- `mk/kvm.mk`: passed `hide_secret.bpf.o` into the KVM functional runner.
- Central docs were updated to treat `HIDE` as implemented and KVM-validated,
  but not as a complete Agent workspace paper result.

## Validation Performed

Host-side build and ABI checks:

```text
make abi bpf functional
```

Result:

- ABI check passed for kernel UAPI and BPF headers.
- Kernel/tools UAPI namei_ext blocks matched.
- All BPF policies, including `hide_secret.bpf.c`, compiled.
- The functional runner built successfully.

KVM functional attach-path validation:

```text
make kvm-functional
```

Result root:

```text
results/phase1/20260713T014740Z-efb9dc00/
```

Observed result:

- `hide_secret_stat`, `hide_secret_open`, and `hide_secret_access` returned
  `ENOENT`.
- `hide_readdir_view` passed: `native` and `tool.real` remained visible while
  `secret` was suppressed.
- `secret_after_hide_detach` passed, confirming detach restored normal lower-FS
  visibility.
- Existing `redirect_alias` functional cases still passed.
- The functional summary reported zero failing cases.
- The dmesg scan found no BUG, WARNING, Oops, kernel panic, or hung-task line.

## Remaining Work

This implementation is not a paper result yet. The next required steps are:

1. Implement registered-target selection or an equivalent bounded target
   mechanism for base/upper/checkpoint object choice.
2. Build the Make-owned Agent workspace full matrix: `namei_ext`, feature-
   equivalent FUSE, controls, boundary evidence, raw traces, and result review.

## Risks

- `HIDE` on create-path lookup currently reports absence through `-ENOENT`
  rather than allowing creation over a hidden name. That is correct for
  protected-path visibility and whiteout-style absence, but create-specific
  semantics should be revisited only if the admitted workload oracle requires
  them.
- Readdir suppression does not synthesize replacement entries. Workloads that
  need generated directory contents remain outside this boundary and belong to
  FUSE/custom filesystem or metadata-service designs.
