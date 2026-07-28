# Service Configuration Rotation V2 Experiment Plan

## Protocol Status

The original experiment protocol is closed after three dependency preflight
failures. It produced no hypothesis evidence because all attempts stopped
before policy attachment.

The root experiment orchestrator separately admits this V2 protocol. V2 changes
the guest/runtime execution boundary rather than resetting the original
attempt counter. It does not change the RQ1 hypothesis, current/canary/invalid/
rollback states, registered targets, timeout, oracle, repetition counts,
source system, or formal interpretation.

## Paper-Value Admission

The largest result V2 can unlock is a source-derived traditional service
case study showing that the same narrow lookup mechanism used for Agent
workspaces can drive live configuration selection while nginx retains reload,
worker, serving, and invalid-configuration semantics.

The load-bearing uncertainty is whether namei_ext can complete a real
current/canary/invalid/rollback lifecycle through a production service, not
whether a custom runner can redirect a file. A positive result adds independent
RQ1 evidence outside the Agent domain. A contradictory result bounds the
mechanism's live-service applicability. A mixed result identifies which reload
transition is outside the lookup boundary. An inconclusive dependency result
adds no paper evidence.

This is the highest-value current experiment because Agent workspace RQ2 and
FxMark already have formal results, while the service case is implemented and
blocked by one isolated guest-filesystem issue. Adding another workload or
baseline before resolving this path would leave the same reviewer-facing
traditional-workload gap.

Role: supporting RQ1 case study. The preflight itself is dependency work.

## Evidence From Attempts 1-3

- Attempt 1 passed KVM launch but supplied nginx a relative configuration path.
- Attempt 2 fixed paths; nginx syntax validation passed, then
  `ngx_create_paths()` tried to change a shared-tree temporary directory from
  host-visible UID 1000 to the default worker UID 65534.
- Attempt 3 specified `user root;`; nginx instead tried to change the same
  shared-tree directory from UID 1000 to UID 0.

All failures occurred during the first physical `nginx -t`, before cgroup
creation, target registration, BPF load, policy attachment, or a name-resolution
state transition.

## Root Boundary

The immutable experiment result tree is a virtme-ng shared host path. It is
appropriate for source generations, content, raw observations, logs, hashes,
and captured artifacts, but not for service-owned temporary directories that
nginx creates and changes to its worker UID.

nginx's mutable runtime state will move to a unique guest-local directory:

```text
/tmp/namei-ext-service-config-<runner-pid>/
  nginx.pid
  error.log
  prefix/
```

The four physical configuration generations and both content roots remain
under the result boot directory. Each configuration references the guest-local
pid and error-log paths. The default nginx worker identity remains unchanged;
the generated `user root;` directive is removed. The runtime root uses mode
`0711`: only the owner can list or modify it, while the nginx worker can
traverse to service-owned temporary directories.

## Preserved Evidence

After every successful lifecycle, cleanup order is fixed:

1. signal, reap, and verify the nginx master;
2. copy `/tmp/.../error.log` to `<boot-dir>/nginx.error.log`;
3. verify the copied log is a non-empty regular file;
4. recursively remove the unique guest-local runtime tree; and
5. detach policy state, clear registered targets, and remove the cgroup.

Copy, non-empty verification, or runtime-tree removal failure increments the
runner failure count and fails the Make target. Make finalization independently
requires `nginx.error.log` to exist and be non-empty.

Before runner exit:

- the nginx error log is copied to
  `<boot-dir>/nginx.error.log`;
- physical generation hashes and lower-object snapshots remain in raw JSON;
- nginx stdout/stderr remain directly captured under the boot directory;
- `outputs.sha256` covers the persistent fixture generations and content; and
- the raw event stream retains reload rejection and policy counters.

The guest-local prefix contains only ephemeral service machinery and is not a
paper output.

## Implementation-Review Amendments

Before the first V2 preflight, independent implementation review added three
correctness gates without changing the state-transition hypothesis:

1. A 64 KiB request body must be stored by the default nginx worker in the
   guest-local `client_body_temp` directory. The retained file must be a
   non-empty regular file of the expected size and owned by the worker's
   effective UID. This checks that moving runtime state did not preserve only
   the static-GET path while breaking normal worker I/O.
2. Graceful or forced shutdown must return checked kill and wait results and
   establish that the master was reaped before logs are copied or runtime state
   is removed.
3. Every direct nginx validation/daemon log and boot artifact must be a regular
   non-symlink file covered by a per-boot evidence hash. Formal report
   generation must revalidate those hashes and deterministically recompute the
   analysis from the per-boot raw observations.

## Acceptance Gate

One fresh recovery preflight must:

1. pass physical `nginx -t` for current, canary, and rollback;
2. reject the invalid physical generation for the declared directive;
3. attach the real `cgroup/namei_ext` policy;
4. complete current, canary, invalid-rejection, and rollback states;
5. preserve the old worker and canary body after invalid reload;
6. preserve all lower generation/content objects;
7. observe lookup, readdir, and select policy counters;
8. cleanly stop nginx and remove the cgroup/target state;
9. copy a non-empty nginx error log to the result root;
10. pass input/artifact hashes and dmesg gates; and
11. complete `run.json` with a clean source and kernel commit.

The preflight remains dependency evidence. Only a later ten-boot run can test
the formal hypothesis.

## Attempt Budget

The closed original protocol retains its three failed attempts. This separately
admitted V2 protocol permits at most three preflight attempts.
An attempt begins only after result-root creation and KVM launch. A build or
clean-tree failure before that point does not test the recovery.

## Command

```text
make kvm-service-config-rotation-preflight \
  RUN_ID=<fresh-recovery-run-id>
```
