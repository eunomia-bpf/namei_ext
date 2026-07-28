# Checkpoint/Restore KVM Preflight Attempt 2

## Purpose

This record captures the second clean-source modified-kernel preflight for the
DMTCP-derived Checkpoint/Restore and Migration experiment. The run was
diagnostic dependency evidence, not a formal paper result.

## Run Identity

- Result root:
  `results/experiments/checkpoint-restore-preflight/20260728T233617Z/`
- Main repository commit:
  `47a2907e0cd5256fc6e138a8d650207691dbb268`
- Kernel commit:
  `bdc9a83e3dfbef8ff2017f9188c7c86025962183`
- Kernel release:
  `7.1.0-rc7-gbdc9a83e3dfb`

Both repositories were clean. The modified kernel booted, its identity matched
the captured artifact, and DMTCP checkpoint creation succeeded.

## Root Cause

Verbose upstream artifacts established the exact DMTCP assertion:

```text
Process uid doesn't match uid of checkpoint image.
process uid=0, checkpoint uid=1000
```

The guest ran DMTCP as root. The checkpoint image lived in the virtme
host-shared result tree, whose files appear in the guest with the host owner,
UID 1000. DMTCP's strict restart ownership check correctly rejected the
mismatch. The loader warning for `libdmtcp_pathvirt.so` was not the cause of the
restart failure.

The guest copied the complete upstream failure directory into
`boots/preflight/upstream-autotest-artifacts/`, including the checkpoint image,
restart output, process states, command trace, and cleanup trace.

## Repair

The next attempt retains DMTCP's strict ownership check. The root controller
continues to configure `namei_ext`, targets, and cgroups, but every DMTCP
coordinator, worker, command, and restart child runs as the UID/GID that owns
its result directory. The child is moved into its target cgroup before dropping
privileges.

The upstream integration test runs with the same recorded UID/GID. Application
raw observations record UID/GID, and the analyzer requires every condition to
match the boot-level runtime identity.

No `--no-strict-checking` option is used. No condition, correctness oracle,
timeout, baseline, or claim was weakened.
