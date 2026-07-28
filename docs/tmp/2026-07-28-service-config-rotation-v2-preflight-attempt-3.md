# Service Configuration Rotation V2 Preflight Attempt 3

## Command

```text
make kvm-service-config-rotation-preflight \
  RUN_ID=20260728T-service-config-rotation-v2-preflight-v3
```

Result root:

```text
results/experiments/service-config-rotation-preflight/
  20260728T-service-config-rotation-v2-preflight-v3
```

## Status

Failed dependency preflight. This is V2 attempt 3 of 3. The V2 preflight
budget is exhausted, the acceptance gate did not pass, and the ten-boot formal
run is not authorized. This run produced no hypothesis evidence.

The run used clean source commit
`ac916d63aac8a310291b07c2a16ce1969d7aac4b`, clean kernel commit
`bdc9a83e3dfbef8ff2017f9188c7c86025962183`, and booted release
`7.1.0-rc7-gbdc9a83e3dfb`.

Before the counted attempt, the first command invocation stopped during kernel
build because the generated `.build/kernel/vmlinux.unstripped` was empty. It
created no result root and launched no KVM, so the protocol does not count it
as an attempt. `make kernel-clean` followed by `make kernel` rebuilt the
generated kernel tree successfully before the counted command above.

## Direct Observations

The raw stream contains 16 events:

- all four physical nginx validation controls passed, including rejection of
  the declared invalid directive;
- the real `cgroup/namei_ext` policy loaded, attached, and was scoped to the
  service cgroup;
- current target 1 produced equal logical and physical configuration hashes;
- nginx master PID 195 started worker PID 196 and both remained alive until
  graceful cleanup;
- the first `current` state failed after the five-second readiness wait;
- only one of four state rows and none of the three policy-counter rows were
  emitted; and
- daemon reap, log capture, runtime removal, policy detach, target clearing,
  and cgroup removal passed.

The failed guest command prevented boot finalization. The root therefore has no
`boot.json`, `observations.jsonl`, `outputs.sha256`, `evidence.sha256`,
`dmesg.log`, or analysis output. The nine declared artifact hashes and 26
input hashes validate, but this remains an incomplete failed root.

## Failure Localization

The runner reached `wait_service_state()` after current-target selection and
nginx startup. Each iteration first calls `read_single_worker()`, which opens:

```text
/proc/<master>/task/<master>/children
```

The captured kernel configuration records:

```text
# CONFIG_PROC_CHILDREN is not set
```

The pinned kernel registers that proc file only under
`CONFIG_PROC_CHILDREN`. The missing interface is therefore a direct,
undeclared runner dependency. Because the readiness expression uses
left-to-right short-circuit evaluation, the strongest explanation is that the
failed proc lookup prevented `http_body_once()` from running and the loop
eventually returned `ETIMEDOUT`.

The exact proc errno was not preserved, so the short-circuit step is a strong
inference rather than a logged syscall result. The repeated timeout after
moving served content below `/tmp` also means the content-permission diagnosis
from V2 attempt 2 was insufficient and must not be treated as established.

## Interpretation

Mechanism engagement was real but partial: an in-cgroup lookup and directory
probe selected and hashed the current configuration. No state transition
completed, and no final counter, lower-object, HTTP, worker-I/O, invalid-reload,
rollback, dmesg, or analyzer evidence exists.

The result is dependency evidence only. It neither supports nor contradicts
the selected RQ. Service configuration rotation remains motivating scope, not
an admitted paper evaluation row.
