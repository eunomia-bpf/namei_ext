# W5 Attempt 5 Result And Attempt 6 Repair

## Purpose

W5 Checkpoint/Restore and Migration is one of the seven mandatory RQ1 case
studies. This record classifies the fifth KVM preflight and defines the narrow
execution repair for attempt 6. The W5 workload, comparison, and correctness
oracle do not change.

## Attempt 5 Result

The immutable result root is:

```text
results/experiments/checkpoint-restore-preflight/
  20260802T114500Z-w5-attempt05/
```

It used source commit `d831e02b2efa9fe8295ae47e61b872b129b9cf09`,
kernel commit `b07117a3cb41826a34af5ca61e3e2c81dade793f`, and DMTCP
commit `068559d9b14c5f96a57869753bba7c066cbf9653`. The modified
kernel booted, the kernel symbol and runtime-identity gates passed, and the
initial BPF inventory was empty.

The run entered the focal DMTCP PathTranslator condition. Fixture setup,
lower-object capture, and coordinator startup passed. The checkpointed
application then failed before its pre-checkpoint ready event. DMTCP reported:

```text
ASSERT at shareddata.cpp:230: addr != MAP_FAILED: Unable to find shared area:
fd=832 size=2347008: errno=22 (EINVAL)
```

Consequently no checkpoint, restart, `namei_ext`, or withdrawn condition ran.
Attempt 5 is inconclusive. It is not positive W5 evidence and does not compare
the two mechanisms.

## Root Cause

The runner set `DMTCP_TMPDIR` to `conditions/pathvirt/tmp` inside the KVM
result root. That root is a host-shared filesystem in the virtme guest. DMTCP
creates its private shared-data backing file in this directory and maps it with
`MAP_SHARED`; this filesystem rejected that mapping with `EINVAL`.

The host source workflow used a normal local filesystem and passed. Attempt
4's in-guest official autotest used guest-local `/tmp` and also launched its
worker successfully. These two observations isolate the failure to the
placement of DMTCP's private runtime state, not PathTranslator, the checkpoint
application, or the A-to-B pathname oracle.

## Attempt 6 Repair

Each controller now creates a condition- and PID-specific directory under
guest-local `/tmp`, assigns it to the application UID/GID, exports it as
`DMTCP_TMPDIR`, and verifies its removal during cleanup. Checkpoint images,
application observations, lower-object manifests, process/cgroup records,
BPF evidence, and every stdout/stderr stream remain in the result root.

Attempt 6 retains the exact three focal conditions:

1. DMTCP PathTranslator maps the same logical workspace from generation A
   before checkpoint to generation B after restart.
2. `namei_ext` performs the same A-to-B transition for the same application.
3. The withdrawn mapping produces the declared restart failure.

Only a one-boot preflight that completes all three conditions can proceed to
the unchanged three-fresh-boot formal workflow. Only that formal result can
complete W5.
