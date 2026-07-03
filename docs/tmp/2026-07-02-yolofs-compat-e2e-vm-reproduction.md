# YoloFS Compat Mounted E2E VM Reproduction

Date: 2026-07-02

## Motivation

Earlier YoloFS records corrected the stale "no public implementation"
conclusion and reproduced unit tests plus a compat-branch kernel-module build.
The remaining high-value gap was the public mounted filesystem integration
workload. This record reruns the upstream `make test-e2e-vm` target on the
public `compat` branch, because that branch had already produced a compatible
`yolofs.ko` against the Ubuntu 6.8 kernel family.

This is workload-source evidence for YoloFS' mounted filesystem behavior. It
does not reproduce the private umbrella `agent-eval` or `perf-eval` submodules,
and it is not evidence for the main branch's mounted e2e target.

## Source

- Repository: `https://github.com/YoloFS/filesystem`
- Local checkout: `.cache/source-inspection/yolofs-filesystem-compat`
- Branch: `compat`
- Commit: `f37d17583464e72793c63a31de17ca86e19262fe`
- Raw result root:
  `results/reproduction/2026-07-02-official-workloads/yolofs-compat-e2e-vm/`

## Raw Artifacts

Important files:

- `summary.json`
- `make-test-e2e-vm.log`
- `guest-build-deps.log`
- `make-test-e2e-vm-after-deps.log`
- `guest-clean-kmod-v1.log`
- `guest-clean-kmod-v1.status`
- `kmod-generated-before-cleanup.list`
- `kmod-generated-before-cleanup.tar.gz`
- `kmod-generated-after-cleanup.list`
- `guest-clean-before-final-e2e.log`
- `make-test-e2e-vm-clean-kmod.log`
- `vm-stop.log`

## Upstream Workload Entry Point

The reproduced target is the upstream public target:

```text
make test-e2e-vm
```

The target builds the user binary, starts an Ubuntu 24.04 QEMU VM, builds and
installs the kernel module inside the guest, runs `yolo reload`, and executes
the Rust mounted e2e test binary through `./vm.py --`.

## Attempt History

The first compat attempt reached the VM, passed SSH and 9p readiness, and then
failed because the minimal Ubuntu guest lacked `make`.

I installed the guest build dependencies needed by the upstream VM target:

```text
make gcc linux-headers-6.8.0-124-generic libcap2-bin
```

The next attempt reached guest kmod compilation, but failed because
`kmod/yolofs.mod.c` from an earlier external-module build was present as an
untracked generated artifact. YoloFS' Makefile links `kmod/*.c` into the build
directory; that wildcard included the generated `yolofs.mod.c` as if it were
source, causing a `____versions` layout compile failure.

I archived the 35 untracked generated kmod artifacts to
`kmod-generated-before-cleanup.tar.gz`, removed them from `kmod/`, verified
that `kmod-generated-after-cleanup.list` was empty, and ran `make clean-kmod`
to remove the stale build directory.

## Passing Run

After guest dependency installation and generated-artifact cleanup, the final
run:

```text
PATH=/usr/bin:/bin:$PATH timeout 1500 make test-e2e-vm
```

passed with status `0`.

The log shows:

- `make kmod install` ran inside the VM;
- `yolofs.ko` was built against guest kernel `6.8.0-124-generic`;
- `/usr/local/bin/yolo` was installed and given capabilities;
- `yolofs.ko` was installed under `/lib/modules/6.8.0-124-generic/extra`;
- `yolo reload` loaded the kernel module;
- Rust e2e ran `593` tests;
- final result was `593 passed; 0 failed; 0 ignored`;
- `yolo unload` ran at the end;
- the VM was stopped.

## Workload Shapes Exercised

The mounted e2e suite covers YoloFS' real filesystem and CLI behavior:

- CLI lifecycle: reload, unload, commit, abort, diff, status, snapshot, travel,
  mount, unmount, and watch;
- mounted filesystem operations: create, read, write, seek, readdir, rename,
  mkdir, rmdir, symlink, delete, fallocate, and concurrent operations;
- internal state semantics: journal format, commit/abort, snapshot, travel,
  rename resolution, dentry interposition, ownership, and consistency;
- permission semantics: allow, deny, read-only, ask, hide, live rules,
  metadata-operation gating, open-flag handling, and ioctl gating.

## Caveats

The passing run is on the public `compat` branch, not the main checkout. The
original umbrella `agent-eval` and `perf-eval` submodules are still unavailable
from this environment, so original YoloFS agent benchmark and performance
benchmark reproduction remain unclaimed.

The final pass required environment preparation: guest build dependencies had
to be installed, and local untracked kmod generated artifacts had to be
removed. That cleanup fixed local source pollution rather than changing YoloFS
source code.

The guest kmod build printed small clock-skew warnings from the 9p share, but
the module build, load, test run, unload, and VM stop all completed
successfully.

## Reuse Decision

YoloFS should now be treated as public code-backed methodology plus a
reproduced compat-branch mounted filesystem e2e workload. For `namei_ext`, it
is useful as source-backed workload evidence for staging, snapshot,
commit/abort, permission/hide, travel, and final-tree oracle shapes.

Do not claim that `namei_ext` replaces YoloFS or that YoloFS proves the need
for eBPF policy logic. YoloFS is broader: it owns a stackable kernel filesystem,
write staging, snapshot/travel behavior, permission handling, and commit/abort
semantics. The useful comparison point is whether a narrower VFS
name-resolution hook can cover the path-view subset for selected workloads.
