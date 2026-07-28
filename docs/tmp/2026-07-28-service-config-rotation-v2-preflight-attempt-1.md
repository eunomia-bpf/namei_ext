# Service Configuration Rotation V2 Preflight Attempt 1

## Command

```text
make kvm-service-config-rotation-preflight \
  RUN_ID=20260728T-service-config-rotation-v2-preflight-v1
```

Result root:

```text
results/experiments/service-config-rotation-preflight/
  20260728T-service-config-rotation-v2-preflight-v1
```

## Status

Failed dependency preflight. This is V2 attempt 1 of at most 3 and produced no
hypothesis evidence.

The run used clean source commit
`7edc34a37eb8db0c2b55416ad02ec808410494c4`, clean kernel commit
`bdc9a83e3dfbef8ff2017f9188c7c86025962183`, and booted release
`7.1.0-rc7-gbdc9a83e3dfb`.

## Observed Progress

The guest-local runtime repair passed its first real checks:

- the runtime boundary case passed;
- physical current, canary, and rollback configurations passed `nginx -t`;
- the declared invalid directive was rejected by `nginx -t`; and
- target cleanup and cgroup removal passed.

The run stopped before nginx service start and before any state transition
because the BPF policy failed verifier load.

## Raw Failure

The verifier rejected:

```text
bpf_map_lookup_elem(&service_config_rotation_cgroups, &ctx->cgroup_id)
```

with:

```text
dereference of modified ctx ptr R2 off=16 disallowed
```

libbpf returned `-EACCES`, and the structured `attach_policy` case failed with
errno 13. `run.json` records `kvm-launch-or-guest-command`.

## Diagnosis

The policy passed a pointer to a field inside the BPF context as a map key. The
`cgroup/namei_ext` verifier contract does not allow that modified context
pointer for this helper call. Existing policy code in the repository follows
the valid pattern: copy `ctx->cgroup_id` to a stack scalar and pass the stack
address.

This is an attach-path implementation defect. It does not change the V2
hypothesis, workload states, target registrations, timeout, worker-I/O oracle,
or interpretation.

## Repair

`service_config_rotation.bpf.c` now copies `ctx->cgroup_id` into a local
`__u64 cgroup_id` and uses `&cgroup_id` for the managed-cgroup map lookup.

After build, review, clean commit, and push, V2 may use preflight attempt 2.
