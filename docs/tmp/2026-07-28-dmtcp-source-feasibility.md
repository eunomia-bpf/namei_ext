# DMTCP Source Feasibility

## Purpose

This record checks whether the exact DMTCP source proposed for the
Checkpoint/Restore and Migration experiment is available, buildable, and
contains a working source-native path-virtualization checkpoint/restart test.
It is a host-side dependency check, not Phase 1 evidence for `namei_ext`.

## Source

- Repository: `https://github.com/dmtcp/dmtcp`
- Inspected commit:
  `068559d9b14c5f96a57869753bba7c066cbf9653`
- Commit describe string: `4.1.1-127-g068559d9`
- Reported built version: DMTCP 5.0
- Archive SHA-256:
  `e2f15525073fc631efd994640ef645461f2c910843da60f9e8929d593ed49c7e`

The archive contains the required license, build files, path translator, and
test sources.

## Source Inspection

`src/plugin_pathtranslator.cpp`:

- parses `DMTCP_PATH_MAPPING` as old-prefix to new-prefix mappings;
- refreshes the mapping from the restart environment on
  `DMTCP_EVENT_RESTART`;
- handles `DMTCP_EVENT_VIRTUAL_TO_REAL_PATH`;
- substitutes a matching pathname prefix before the real pathname operation;
- identifies the plugin as `PATHVIRT`.

`test/pathvirt1.c`:

- creates a physical file;
- repeatedly reads it through a virtual pathname;
- checks DMTCP checkpoint/restart status; and
- writes a success artifact after a real restart.

`test/autotest.py` registers that application as the `pathvirt` integration
test, launches it with `--pathvirt`, supplies `DMTCP_PATH_MAPPING`, requests
one checkpoint/restart cycle, and validates the post-restart success artifact.

## Build

The exploratory source build used upstream build entrypoints:

```text
./configure --prefix=/tmp/namei-ext-dmtcp-install
make -j4
make install
```

All commands completed successfully. The 72-MiB installation contains:

- `dmtcp_coordinator`;
- `dmtcp_launch`;
- `dmtcp_command`;
- `dmtcp_restart`;
- `mtcp_restart`;
- `lib/dmtcp/libdmtcp.so`; and
- DMTCP headers, documentation, and helper binaries.

The executables dynamically link to the normal system C/C++ runtime and
`libatomic`. The experiment must preserve and hash the complete installation
tree rather than copying one executable.

## Source Test

The exact upstream integration target was run as:

```text
make check-autotest AUTOTEST=pathvirt
```

Result:

```text
pathvirt       ckpt:PASSED; rstr:PASSED (1.2s)
test groups: pass=1 fail=0 skipped=0 total=1
```

The test ran on the host kernel. It confirms only that the pinned source and
source-native baseline are usable enough to admit a KVM dependency preflight.

## Design Consequences

- The natural baseline is the upstream `--pathvirt` condition, not a
  project-created synthetic filesystem.
- Restart environment handling is part of DMTCP's source behavior and must be
  retained in the baseline.
- DMTCP virtualizes process IDs. The experiment must use controller-observed
  launch/restart instances plus DMTCP's restored status, not application
  `getpid()` inequality, to prove that a restart occurred.
- Upstream exposes plugin enablement but no per-pathvirt-wrapper invocation
  counter. The result must not promise such a counter.
- The complete DMTCP install tree and exact source files must be packaged in
  each result root.

## Remaining Risks

- The modified 7.1.0-rc7 kernel may expose a DMTCP compatibility failure not
  present on the host kernel.
- DMTCP restart may reconstruct process cgroup membership differently from a
  normal exec. The `namei_ext` controller must prove the restored process is in
  the intended cgroup before accepting its path oracle.
- The policy link must remain alive throughout checkpoint, original-process
  exit, state update, and restart.
- The application must close pathname-derived file descriptors before
  checkpoint so that the post-restart oracle measures pathname lookup rather
  than DMTCP descriptor restoration.
- The complete A-to-B lifecycle, negative control, lower-object preservation,
  and BPF attribution remain untested until the real KVM preflight.

## Decision

The source dependency check is `GO` for plan review and implementation. It is
not authorization for a formal run and must not be cited as `namei_ext`
evidence.
