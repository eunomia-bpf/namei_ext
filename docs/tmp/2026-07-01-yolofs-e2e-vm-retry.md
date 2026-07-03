# YoloFS Mounted E2E VM Retry

Date: 2026-07-01

## Motivation

The prior YoloFS public-artifact record corrected the stale "no public
implementation" conclusion and showed that the public filesystem code has
passing unit tests plus a compat-branch kernel-module build. The remaining
important workload gap is the mounted filesystem integration path. YoloFS
documents `make test-vm` / `make test-e2e-vm` as the recommended way to run the
full kernel-module plus CLI e2e tests in a QEMU guest.

This retry checks that upstream entry point again and records the exact boundary
between reproduced and unreproduced YoloFS workload evidence.

## Sources And Result Root

Source checkouts:

- Main filesystem checkout: `.cache/source-inspection/yolofs-filesystem`
- Compat filesystem checkout: `.cache/source-inspection/yolofs-filesystem-compat`
- Umbrella checkout: `.cache/source-inspection/yolofs-umbrella-reclone`

Source revisions:

- Main filesystem: `684829ec5e8193e8560b52573b2575a347906d0e`
- Compat filesystem: `f37d17583464e72793c63a31de17ca86e19262fe`
- Umbrella: `d5681e4ec0ba52d5512ae300ed1d76667e4acbce`

Raw result root:

- `results/reproduction/2026-07-01-official-workloads/yolofs-e2e-vm-retry/`

Key raw files:

- `summary.json`
- `yolofs-test-e2e-vm-retry.log`
- `yolofs-test-e2e-vm-retry-system-qemu.log`
- `yolofs-vm-system-qemu-boot.log`
- `yolofs-vm-stop.log`

## Upstream Workload Entry Point

The attempted upstream target was:

```text
make test-e2e-vm
```

From the public Makefile, this target:

1. runs `./vm.py -- make kmod install` inside an Ubuntu 24.04 QEMU guest;
2. runs `./vm.py -- sudo sysctl -w kernel.dmesg_restrict=0`;
3. runs `./vm.py -- yolo reload`;
4. runs `cargo test --release --test e2e -- --test-threads=1` through the
   `./vm.py --` cargo runner.

That is the correct public mounted-filesystem integration workload. It is not a
synthetic replacement.

## Attempt 1: Default PATH QEMU

Command shape:

```text
timeout 900 make test-e2e-vm
```

Result:

- status: `2`
- log: `yolofs-test-e2e-vm-retry.log`

Observation:

- `vm.py` selected `qemu-system-x86_64` from the default `PATH`;
- on this host that resolves to `/usr/local/bin/qemu-system-x86_64`;
- QEMU failed immediately because that binary lacks the user networking backend:
  `network backend 'user' is not compiled into this binary`.

This is a host-QEMU backend failure before the YoloFS e2e workload can start.

## Attempt 2: System QEMU First In PATH

Command shape:

```text
PATH=/usr/bin:/bin:$PATH timeout 900 make test-e2e-vm
```

Result:

- status: `2`
- log: `yolofs-test-e2e-vm-retry-system-qemu.log`
- VM serial log: `yolofs-vm-system-qemu-boot.log`

Observation:

- system QEMU started the Ubuntu 24.04 VM successfully;
- the VM boot log shows cloud-init completed;
- the guest reached the login prompt;
- `ssh.socket` was listening in the guest;
- `vm.py` still failed its readiness wait after 120 seconds:
  `Error: VM not ready after 120s`;
- manual SSH probes during the wait window returned `Connection reset by peer`;
- the target never reached `make kmod install`, `yolo reload`, or the Rust e2e
  test body.

The QEMU backend issue was bypassed, but the public mounted e2e workload still
did not reproduce because the guest SSH/9p mount readiness probe did not pass.

## Cleanup

The QEMU guest was stopped with:

```text
PATH=/usr/bin:/bin:$PATH ./vm.py stop
```

`ps` showed no remaining `qemu`, `vm.py`, `make test-e2e-vm`, or YoloFS e2e
processes after cleanup.

## Interpretation

The correct YoloFS status is now:

- public filesystem code found;
- main and compat unit tests previously passed with `288/288`;
- compat branch kernel module previously built as `yolofs.ko`;
- public umbrella agent/perf submodules remain unavailable from this
  environment;
- upstream mounted VM e2e target was retried and still did not reproduce on this
  host.

Do not claim mounted YoloFS e2e conformance or original YoloFS agent/perf
benchmark reproduction. YoloFS remains useful as a methodology and related-work
source for hidden-side-effect final-tree oracles, staging/snapshot/permission
state transitions, and stackable-kernel-filesystem comparison.

For `namei_ext`, the next useful step is not to debug YoloFS VM plumbing
indefinitely. The paper should reuse the YoloFS workload shapes inside a
Make-owned, KVM-validated `namei_ext` agent workspace lifecycle workload, while
keeping the YoloFS e2e reproduction boundary explicit.

## Follow-Up

`docs/tmp/2026-07-02-yolofs-compat-e2e-vm-reproduction.md` supersedes this
record for the public compat branch. That later run installed guest build
dependencies, removed local generated kmod artifacts that polluted the Makefile
wildcard, and reproduced upstream `make test-e2e-vm` with `593` mounted e2e
tests passed and `0` failed. This 2026-07-01 record remains the correct history
for the earlier main-checkout VM-readiness attempts.
