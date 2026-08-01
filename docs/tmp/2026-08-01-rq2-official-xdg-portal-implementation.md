# RQ2 official Documents portal implementation

## Motivation

The existing Agent and FxMark comparisons use project-owned FUSE
implementations. The experiment frozen in
`2026-08-01-rq2-official-xdg-portal-performance-plan.md` adds an unmodified
official `xdg-document-portal` implementation as external-validity evidence for
the W1 application-visible path. It does not treat the complete portal and
`namei_ext` systems as feature-equivalent and does not use this row as an
independent placement-causality result.

## Source system

The source target now builds unmodified `xdg-document-portal` 1.22.1 at peeled
release commit `1d20fadc304f6601452b5db65ed91197dba77041` in an Ubuntu 24.04
builder. This matches the Ubuntu 24.04 userspace used by virtme-ng and avoids
shipping an incompatible Trixie `libfuse3.so.4` runtime into the guest.

The source gate compiles the official portal and permission store and passes
these current Meson tests with no failure, skip, or timeout:

- `unit/permission-db`
- `unit/xdp-utils`
- `unit/xdp-method-info`
- `integration/documents`

The official source is not patched. Meson may populate wrap subprojects in the
generated `.build/workloads/` source copy, so the builder mounts that generated
copy read-write.

## Frozen transaction

`experiments/application_file_sharing/rq2_measurement.c` implements one shared
transaction used by both arms. Starting from a pre-opened application-view
parent, each observation performs:

1. `fstatat()` of one exactly 22-byte document-ID component with
   `AT_SYMLINK_NOFOLLOW`;
2. `fstatat()` of `<document-id>/payload.txt`;
3. `openat()`, complete read of the exact 27-byte payload through EOF, and
   close;
4. a fresh `openat(".", O_DIRECTORY)`, `getdents64()` through EOF, and close.

The directory oracle requires exactly `.`, `..`, and the document ID. The
`getdents64` parser uses `offsetof(struct linux_dirent64, d_name)`, not
`sizeof(struct linux_dirent64)`, because the final member is variable length.
The host smoke test caught and corrected this distinction before any KVM run.

Warmup observations execute the complete oracle. Measured observations are
kept in memory until the transaction and process/counter windows finish, then
written as per-sample raw JSONL. Result formatting and file flushing are
therefore outside the latency and process-resource windows.

## Mechanism integration

The existing RQ1 binaries retain their original command lines. Supplying the
new warmup/sample arguments enables RQ2 mode while preserving the same
five-state grant/isolation/revoke oracle.

The `namei_ext` arm uses fixed ID `namei-fixed-doc-id-001`, registers an
existing lower directory, and runs through the real cgroup attachment path.
The policy continues to support the original `document` name and additionally
recognizes this 22-byte ID. Its raw policy counters are captured immediately
before and after the measured window. Engagement requires target selection and
a `visible_readdir` counter that increments only after the fixed name, managed
parent, grant, and directory-entry event all match; process-resource probes
cannot satisfy it.

The portal arm uses the official source-generated 22-byte ID. It starts the
official permission store and document portal, uses `Add`,
`GrantPermissions`, and `RevokePermissions`, and preserves the application
parent fd across revoke for the immediate hidden-state oracle.

Each fresh guest boot creates a dedicated loop-backed ext4 filesystem for both
the mechanism fixture and its direct-ext4 control. The runner, guest, and
finalizer independently require the ext4 type. Both runners execute the direct
control before starting or attaching the tested mechanism. Grant and revoke
acknowledgement latency is recorded separately from the primary transaction.

## FUSE attribution

`bpf/tracing/application_file_sharing_fuse_counter.bpf.c` attaches to the
kernel's existing `fuse:fuse_request_send` tracepoint. The portal runner filters
events by the portal mount's `st_dev` and records an array counter for each
opcode 0 through 63 before and after the measured window. The guest gate saves
the tracepoint format and requires the modified kernel's observed field layout:

- `connection`: offset 8, size 4
- `unique`: offset 16, size 8
- `opcode`: offset 24, size 4
- `len`: offset 28, size 4

The run fails unless the selected portal connection has both a relevant file
request and a relevant directory request during the measured stream. This
collector is measurement instrumentation, not a
`namei_ext` policy, and therefore lives under `bpf/tracing/` rather than
`bpf/policies/`.

## Process observations

Before and after the measured loop, the runners capture every currently
present thread's `/proc/<pid>/task/<tid>/schedstat` values and voluntary and
involuntary context-switch counters. The snapshots are retained in memory and
emitted after the window. The analysis requires the before/after thread sets to
match; a disappearing or newly created thread makes the resource result
invalid instead of silently dropping it.

The portal arm captures the client and every portal-daemon thread. The
`namei_ext` arm captures its client and has no daemon row.

## Fresh-boot and analysis path

The new Make targets are:

- `application-file-sharing-rq2-official-host-gate`
- `kvm-application-file-sharing-rq2-official-preflight`
- `experiment-application-file-sharing-rq2-official`

The preflight is one pair with 10 warmups and 100 measured observations per
arm. The formal matrix is ten pairs with 1,000 warmups and 10,000 observations
per arm. Odd pairs run portal then `namei_ext`; even pairs reverse that order.
Every arm is a fresh four-vCPU, 8-GiB KVM boot pinned to host CPUs 4--7.

Raw finalization and analysis run while the result root remains in `running`
state. The root is marked complete only after all frozen analysis artifacts
validate.

`analysis/application_file_sharing_rq2/analyze.py` first reduces each boot to
its median. It then computes portal/`namei_ext` log ratios within each pair and
reports their geometric mean with a pair-level 10,000-resample bootstrap 95%
confidence interval using seed 20260801. Individual syscall observations are
not treated as independent experimental repetitions.

## Validation completed

The following host/source gates pass:

- official 1.22.1 source build and four selected upstream suites;
- both extended C runners with `-Wall -Wextra`;
- the cgroup policy and FUSE tracepoint BPF objects;
- the exact host-filesystem transaction smoke, including visible and hidden
  directory oracles;
- deterministic synthetic tests of pair construction, per-boot reduction,
  missing-arm failure, duplicate sample rejection, pair-level ratio analysis,
  and all frozen analysis output files;
- fixed CPU, kernel command line, source revision, and artifact prerequisites.

No real RQ2 KVM arm has run yet. In particular, the current state does not
prove that the tracepoint connection filter receives requests in the guest,
that the official portal parent has exactly the frozen three entries, that the
extended `namei_ext` mode returns to the root cgroup cleanly, or that the paired
finalizer accepts a complete boot pair. Those are the explicit purposes of the
single fresh preflight pair.
