# RQ3 target-lifetime preflight05/06 infrastructure failures

## Purpose

This record separates two failed validation attempts from the target-lifetime
mechanism result. Neither attempt reached the concurrent target-retirement
runner, so neither provides positive or negative evidence about `namei_ext`
object lifetime, KASAN, or KCSAN behavior.

## Source and kernel revisions

Both attempts used a clean project tree at
`edfeecaef0df9cd51ff47cf67c41cace4c02baad` and a clean kernel tree at
`621aff8d1bb52fad718f11fd882c956d6a5686ae`.

## Preflight05: PTY job-control stop

The immutable result root is:

`results/experiments/namei-ext-target-lifetime-preflight/20260801T060850Z-target-lifetime-preflight05/`

The normal-kernel launcher produced empty stdout and stderr for the full
180-second launch timeout. During that interval, the `vng`, `virtme-run`, and
QEMU processes were in stopped (`T`/`Tl`) states. The owning Make target marked
the run `failed` with `failure: kvm-launch-or-guest-command` at
`2026-08-01T06:11:57Z`, and no runner artifacts were produced.

The launch was invoked through a controlling PTY. The next attempt retained the
same Make target and experiment inputs but invoked it through ordinary pipes.
This change concerns the caller's terminal transport, not repository code or
the experiment protocol.

## Preflight06: guest scratch path was not writable

The immutable result root is:

`results/experiments/namei-ext-target-lifetime-preflight/20260801T061240Z-target-lifetime-preflight06/`

Without a PTY, the host gates completed and the normal-kernel guest entered
`__namei_ext_target_lifetime_guest_body`. The guest failed before creating the
ext4 image or running the target-lifetime binary. Its launcher stderr records:

```text
install: cannot change permissions of '/mnt/namei-ext-target-lifetime': No such file or directory
```

The owning Make target marked the run `failed` with
`failure: kvm-launch-or-guest-command` at `2026-08-01T06:12:56Z`. The failure
was introduced when the KCSAN isolation repair moved the scratch tmpfs mount
point from the result tree to `/mnt`, which is not one of the writable guest
paths provided by this virtme invocation.

## Correction

`TARGET_LIFETIME_GUEST_SCRATCH` now uses
`/tmp/namei-ext-target-lifetime`. The shared KVM launcher already provides
`/tmp` as a writable guest overlay. The guest still mounts a fresh 768 MiB
tmpfs on that directory, creates a loop-backed ext4 image inside it, copies the
static runner and BPF objects into the tmpfs/ext4 working set, disables KCSAN
before copying raw artifacts to the result root, and unmounts both filesystems
during cleanup. The real `cgroup/namei_ext` attach path, policy, concurrency
cells, and analysis requirements are unchanged.

## Validation required

A fresh result root must pass normal, KASAN, and KCSAN boots before this repair
can support a mechanism claim. The two failed roots above remain immutable and
must not be reused or interpreted as target-lifetime evidence.
