# W5 Attempt 6b Result And Policy Attribution

## Purpose

This record classifies the first non-interactive attempt-6 W5 preflight and
defines the next diagnostic repair. W5 remains one of seven mandatory RQ1 case
studies. Its DMTCP application, A-to-B checkpoint/restart oracle, three
conditions, and modified-kernel requirement do not change.

## Invalid PTY Launch

The root `20260802T103801Z-w5-attempt06` is an invalid host-launch attempt.
The Make command was given an interactive PTY, and virtme/QEMU was stopped by
terminal job control before the guest command ran. Make marked the root
`failed/kvm-launch-or-guest-command`. It contains no workload observation and
is not W5 evidence.

## Attempt 6b Result

The immutable result root is:

```text
results/experiments/checkpoint-restore-preflight/
  20260802T104300Z-w5-attempt06b/
```

It used clean source commit `44a421b1cb83c419417158d3ca874639862a63b7`
and modified-kernel commit `b07117a3cb41826a34af5ca61e3e2c81dade793f`.
The guest passed kernel identity, runtime identity, and empty initial BPF
inventory checks.

The focal DMTCP PathTranslator condition then completed. The same application
resolved generation A before checkpoint and generation B after restart through
the same logical pathname. The stale-to-new directory transition, checkpoint
image, process records, lower-object preservation, and guest-local DMTCP
runtime cleanup all passed. The previous `MAP_SHARED` failure is closed.

The `namei_ext` condition prepared the same fixture and lower-object record,
but its aggregate policy-configuration call returned `EIO` before the
application or BPF attribution ran. The withdrawn condition did not run.
Attempt 6b is therefore incomplete and cannot compare the mechanisms, although
its PathTranslator condition is valid dependency evidence.

## Attribution Repair

The shared harness intentionally maps any failed control child to `EIO`.
The W5 runner had combined cgroup creation, cgroup-ID resolution, target
registration, policy-parent configuration, BPF load/attach, program-ID query,
and map update into one observation. It also cleaned target and parent state
only after all seven steps passed.

The revised runner emits a required result for each concrete setup operation
and tracks ownership of the cgroup, target, parent scope, and BPF program
independently. Cleanup now removes every successfully created resource even if
a later setup operation fails. The next fresh preflight can therefore identify
the exact failed mechanism operation without changing the workload or oracle.

Independent code review then identified the deterministic cause before another
boot: the runner called `namei_ext_policy_parent_exact` before attaching the
BPF program, while the kernel control path requires the cgroup to own a policy.
The same runner detached the program before clearing that scope. The corrected
order is attach then configure scope, followed by scope clear, target clear,
detach, and cgroup removal. Cgroup creation now rejects `EEXIST` so cleanup
cannot claim ownership of a pre-existing cgroup.
