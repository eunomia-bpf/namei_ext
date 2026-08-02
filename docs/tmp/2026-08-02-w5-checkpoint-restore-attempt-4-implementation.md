# W5 Checkpoint/Restore Attempt 4 Implementation

## Purpose

W5 is one of the seven required RQ1 industrial cases. The implementation runs
the same DMTCP checkpoint/restart application under three conditions: DMTCP
PathTranslator, `namei_ext`, and a withdrawn `namei_ext` mapping. It is a
correctness case study, not a performance experiment.

This implementation replaces the dependency path used by the first three
failed attempts. Those roots remain unchanged. The next modified-kernel boot
is still attempt 4 in the original W5 lineage.

## Source And Build Path

`mk/experiments/checkpoint_restore.mk` now owns a W5-specific DMTCP build:

- clone `https://github.com/dmtcp/dmtcp.git`;
- check out commit `068559d9b14c5f96a57869753bba7c066cbf9653`;
- require a clean detached checkout at that exact commit;
- export the commit with `git archive`;
- apply `thirdparty/patches/dmtcp/restart-env-scan-count.patch`;
- configure, build, and install DMTCP through Make targets; and
- preserve the commit, disclosed patch, source tree, and build logs in the
  result root.

The one-line patch repairs the flattened restart-environment scan bound. It
does not implement or modify DMTCP pathname translation.

## Workload Oracle

`experiments/checkpoint_restore/namei_ext_checkpoint_restore.c` performs the
real lifecycle and records direct semantic observations:

1. Before checkpoint, the unchanged logical pathname resolves to generation
   A; directory enumeration exposes `stale.txt` and not `new.txt`.
2. DMTCP creates a nonempty checkpoint image and terminates the original
   process.
3. PathTranslator or `namei_ext` changes the selected existing workspace from
   generation A to generation B.
4. After DMTCP restart, the application uses the same logical pathname,
   resolves to generation B, and sees `new.txt` but not `stale.txt`.
5. The withdrawn mapping causes that post-restart lookup to fail with
   `ENOENT`.
6. The runner compares all six lower files by direct bytes, device/inode,
   mode, size, and modification time before and after the lifecycle.

The raw lower-file records now contain the expected file text and final-newline
state. The checkpoint record contains a relative image path; the runner and
analyzer require the referenced image to be a nonempty regular file.

## KVM Lifecycle

The active KVM path has two Make entrypoints:

- `make kvm-checkpoint-restore-preflight`: one modified-kernel boot, attempt 4;
- `make kvm-checkpoint-restore-rq1`: three fresh modified-kernel boots after a
  successful preflight review.

Every boot first runs DMTCP's official `pathvirt` test. It then runs all three
conditions and requires every declared event to pass. The `namei_ext` cases
record program/cgroup identity and positive `SELECT` counters. Before leaving
each condition, the suite captures the external BPF program and cgroup
inventories and requires no remaining attachment. This proves that the
PathTranslator arm did not leave a BPF program and that both `namei_ext` arms
completed cleanup. The boot also ends with a second clean inventory and a
clean dmesg failure scan.

Attempt 3 failed because UID and GID were lost across Make recipe shells. The
new guest path computes both values in one recipe and executes `id -u` and
`id -g` under the same `setpriv` flags before invoking the upstream test. The
probe output is preserved and checked again by the analyzer.

The host creates all three condition result directories before KVM so they
retain the invoking user's ownership. The root controller keeps the privilege
needed to load BPF and manage cgroups, but it changes ownership of the fixture,
checkpoint, and DMTCP temporary directories to the application UID/GID before
spawning DMTCP. This keeps control-plane privilege separate from the
checkpointed application's write access.

## Analysis

`analysis/checkpoint_restore/analyze.py` now validates each boot independently.
It supports one preflight boot and three formal boots, reconstructs the A-to-B
application oracle, checks the withdrawn control, checks the direct lower-file
records and checkpoint image, and reports lifecycle durations per boot as
descriptive data only.

Eleven analyzer tests cover both valid layouts and failures in PathTranslator
attribution, BPF selection attribution, withdrawn behavior, runtime identity,
lower-file contents, checkpoint-image paths, and residual BPF state.

## Validation Performed

The following host validations passed:

- the pinned DMTCP commit configured, built, and installed;
- both W5 C programs compiled with `-Wall -Wextra`;
- all eleven W5 analyzer tests passed; and
- the repository infrastructure tests passed after removing their obsolete
  expectation that W5 use artifact checksum gates.

The source-positive result is:

```text
results/workloads/checkpoint-restore-source/
  20260802T094525Z-df8ae7d4/
```

DMTCP's official `pathvirt` test reported one passing group and no failures.
The source-derived application then completed a real checkpoint/restart:
generation A before checkpoint, generation B after restart, the same logical
pathname, stale-to-new directory transition, and unchanged lower objects. The
recorded lifecycle was 40.5 ms checkpoint, 204.4 ms restart, and 734.3 ms
total. These timings are diagnostic and support no performance claim.

The host gate copies the DMTCP installation into the fresh result root and
executes the source-derived lifecycle from that relocated copy, matching the
KVM packaging path. The earlier `20260802T093352Z-fd5e7659` root used the
build-tree installation and remains an immutable source-workflow observation;
the later root is the packaging gate.

## Preflight Review And Remaining Gate

The independent follow-up review returned GO. It confirmed that the active W5
path uses the pinned Git source and direct semantic evidence, the real
`setpriv` probe closes the attempt-3 failure, the condition and DMTCP runtime
directories have the required application ownership, the relocated install is
executable, and both one-boot preflight and three-boot formal paths are wired to
the analyzer.

Attempt 4 ran at
`results/experiments/checkpoint-restore-preflight/20260802T095000Z-w5-attempt04/`.
The modified kernel and runtime-identity probe passed, and DMTCP's separate
official autotest completed its checkpoint and restart phases. Its cleanup
then reported PID 980 in the original worker process group. The run stopped
before the external BPF inventory and before all three focal lifecycle
conditions, so it is inconclusive and supplies no W5 KVM result.

The result analysis and materially revised attempt-5 execution plan are in
`docs/tmp/2026-08-02-w5-attempt-4-result-and-attempt-5-plan.md`.

The revised activation passed from a relocated host install in
`results/workloads/checkpoint-restore-source/20260802T111500Z-w5-attempt5-source/`.
The direct lifecycle completed A-to-B restart with an empty launcher stderr
log. The next missing evidence remains the modified-kernel attempt-5 KVM
preflight.
