# Service Configuration Rotation Preflight Attempt 3

## Command

```text
make kvm-service-config-rotation-preflight \
  RUN_ID=20260728T-service-config-rotation-preflight-v3
```

## Outcome

The clean commit `07c63721870b9510abb0a796a4ed99dd38ec3caa` built the
modified kernel, BPF policy, runner, and pinned nginx 1.26.3 source in the
declared Make workflow. KVM booted the expected
`7.1.0-rc7-gbdc9a83e3dfb` kernel and reached the first physical `nginx -t`
control. That control failed before cgroup creation, target registration, BPF
load, or policy attachment.

The immutable failed result is:

```text
results/experiments/service-config-rotation-preflight/
  20260728T-service-config-rotation-preflight-v3/
```

It is dependency failure evidence, not RQ evidence.

## Root Cause

The attempted `user root;` repair changed nginx's requested temporary-directory
owner from UID 65534 to UID 0, but did not remove the ownership mismatch:

```text
nginx: the configuration file .../generation-current/nginx.conf syntax is ok
nginx: [emerg] chown(".../prefix/client_body_temp", 0) failed
        (1: Operation not permitted)
```

The virtme-ng guest runs the command as UID 0 while the shared result tree
reports its host owner, UID/GID 1000. The generated temporary directory
therefore has UID 1000. nginx's `ngx_create_paths()` sees a requested worker
UID of 0, detects the mismatch, and attempts an ownership change that the
mapped shared filesystem rejects.

The correct forward direction is to derive the fixture owner's passwd/group
identity and configure nginx to use that owner, or to stage runtime files on a
guest-local filesystem whose ownership model supports nginx's normal setup.
This must be reviewed as a new dependency plan before another KVM run.

## Gate Status

All three approved preflight attempts are exhausted. No formal ten-boot run may
start. A fourth attempt requires a new reviewed plan that freezes:

- the guest/runtime filesystem boundary;
- the nginx worker identity and privilege behavior;
- a physical `nginx -t` control that passes before policy attachment; and
- the unchanged current/canary/invalid/rollback correctness oracle.

The name-resolution hypothesis remains untested by these attempts.
