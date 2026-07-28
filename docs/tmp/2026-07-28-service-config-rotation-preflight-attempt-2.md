# Service Configuration Rotation Preflight Attempt 2

## Command

```text
make kvm-service-config-rotation-preflight \
  RUN_ID=20260728T-service-config-rotation-preflight-v2
```

## Outcome

The modified-kernel KVM path reached the W4 runner, constructed all four
physical generations, and invoked the first physical `nginx -t` control. The
control rejected the otherwise valid current configuration before policy
attachment. The failed run is retained at:

```text
results/experiments/service-config-rotation-preflight/
  20260728T-service-config-rotation-preflight-v2/
```

`run.json` is `failed` with `kvm-launch-or-guest-command`. The raw runner
contains a failed `current` physical-validation row and no state-transition
row. This is dependency failure evidence, not an RQ result.

## Root Cause

The current configuration passed nginx syntax validation, but nginx then
failed while preparing its default client-body temporary directory:

```text
nginx: the configuration file .../generation-current/nginx.conf syntax is ok
nginx: [emerg] chown(".../prefix/client_body_temp", 65534) failed
        (1: Operation not permitted)
```

The KVM runner executes as UID 0 in the virtme-ng guest and creates the fixture
with that UID. With no `user` directive, nginx 1.26.3 replaces its unset worker
UID with the configured build default (`nobody`, UID 65534). During
`ngx_create_paths()`, nginx tries to change each temporary directory to that
UID. The virtme-ng mapped filesystem correctly refuses that ownership change.

This failure is independent of pathname selection. It occurs in the physical
configuration control before cgroup creation, target registration, BPF load,
or policy attachment.

## Forward Repair

The generated test configurations now specify `user root;`. The fixture
directories and nginx worker use the same guest UID, so nginx observes the
correct ownership and does not issue the unsupported UID-changing `chown`.
Running the workload under one UID is sufficient for this experiment because
its oracle concerns lookup-time generation selection, graceful reload,
invalid-generation rejection, served content, and lower-object preservation;
it does not test nginx privilege separation.

No state, target ID, timeout, repetition count, or correctness oracle changed.
Attempt 3 is the final approved dependency preflight and must use a fresh
`RUN_ID`. If it does not complete all four state transitions, the formal run
must not start without a new reviewed plan.
