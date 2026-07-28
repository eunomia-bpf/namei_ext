# Service Configuration Rotation V2 Preflight Attempt 2

## Command

```text
make kvm-service-config-rotation-preflight \
  RUN_ID=20260728T-service-config-rotation-v2-preflight-v2
```

Result root:

```text
results/experiments/service-config-rotation-preflight/
  20260728T-service-config-rotation-v2-preflight-v2
```

## Status

Failed dependency preflight. This is V2 attempt 2 of at most 3 and produced no
hypothesis evidence.

The run used clean source commit
`4372726a790a2e9fccbbf4aa159d541f6a4714b9`, clean kernel commit
`bdc9a83e3dfbef8ff2017f9188c7c86025962183`, and booted release
`7.1.0-rc7-gbdc9a83e3dfb`.

## Observed Progress

The verifier repair from V2 attempt 1 worked. The policy loaded and attached
through the real `cgroup/namei_ext` path, policy scoping passed, and nginx
started one master and one worker. Physical validation of the current, canary,
invalid, and rollback configurations also passed.

The first live `current` state timed out before producing an HTTP body. Cleanup
then passed: nginx shut down and was reaped, its non-empty error log was
captured, the guest-local runtime was removed, the policy and targets were
removed, and the service cgroup was removed.

## Raw Failure

`raw-runner.jsonl` records:

```text
attach_policy pass=true
scope_policy pass=true
current pass=false master_pid=191 worker_after=0 poll_attempts=0
```

The nginx error log independently records that master PID 191 started worker
PID 192 and remained alive until the runner's graceful cleanup five seconds
later.

## Diagnosis

The nginx build uses its default worker identity:

```text
NGX_USER  "nobody"
NGX_GROUP "nogroup"
```

The generated configuration asked that worker to serve content below the
preserved result root. The run root and repository root are mode `0700`, so the
unprivileged worker cannot traverse that path. The earlier runtime repair made
`/tmp/namei-ext-service-config-<pid>` traversable, but it had not moved the
served content below that boundary.

The failed polling path did not preserve a request-level `EACCES`; it emitted
zero poll attempts because attempts are published only on success. The
diagnosis therefore comes from the combined configuration path, recorded
directory modes, pinned nginx worker default, and evidence that the nginx
master and worker stayed alive throughout the timeout. It is not presented as
a directly logged HTTP errno.

This is a workload execution defect. It does not change the V2 hypothesis,
four configuration states, target registrations, timeout, policy, or
correctness oracle.

## Repair

The persistent source content remains under the result fixture. The runner now
copies those bytes into two mode-`0755` content directories below the
guest-local mode-`0711` runtime root and points the generated nginx
configurations at those copies. Both persistent source files and the exact
runtime files served by nginx are included in the unchanged-object snapshot
check. Runtime cleanup still removes the guest-local copies and preserves the
source fixture.

After build, static analysis, independent review, clean commit, and push, V2
may use its final preflight attempt.
