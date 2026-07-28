# Experiment Plan: RQ1 Service Configuration Rotation

## Research Question

- RQ exactly as written in the paper: Can a narrow VFS name-resolution
  extension express real state-dependent path-view policies without taking
  over filesystem semantics?
- Specific uncertainty tested here: whether a live service can reopen one
  logical configuration pathname across current, canary, invalid, and rollback
  generations while nginx and the lower filesystem retain their normal
  responsibilities.
- Why the answer matters: this adds a traditional service-operation case whose
  source behavior and correctness oracle are independent of Agent Workspaces
  and Build Action Sandboxing.

## Paper-Value Admission

- Planned role: supporting.
- Largest credible paper story this experiment could unlock: `namei_ext`
  expresses a source-derived live service generation switch through existing
  objects, while nginx still validates configuration, rejects a failed reload,
  and owns live worker replacement.
- Strongest reviewer reject argument or load-bearing uncertainty addressed:
  the current RQ1 evidence may be dismissed as agent-specific or as
  short-lived command execution rather than a state change observed by a live
  traditional service.
- Independent evidence added beyond existing runs and published results: a
  real nginx master/worker lifecycle, policy updates followed by reopen/reload,
  an invalid generation that is visible at the logical path but rejected by
  nginx, and rollback through a newly published generation at the same path.
- Why the result is not tautological, already settled, or dominated:
  Kubernetes documents the materialized symlink behavior and nginx documents
  reload/rollback behavior, but neither establishes that the current
  `cgroup/namei_ext` implementation can perform the existing-object selection
  correctly across a live reload.
- Paper decision if positive: admit W4 as a supporting RQ1 case and add its
  ownership boundary to RQ3; retain Agent Workspaces as the deep RQ2 case.
- Paper decision if contradictory, mixed, or inconclusive: keep the source
  demand in related work but do not claim W4 implementation coverage; diagnose
  whether the failure is target lifetime, reload lookup, or an out-of-boundary
  service behavior.
- Best alternative experiment and why this one has higher decision value:
  another Bazel run would repeat a passed deterministic oracle. Spindle has
  higher eventual value but is blocked on cross-filesystem target selection.
  W4 is the strongest new runnable traditional source case.

## Expected And Alternative Outcomes

- Current expected answer: all ten fresh boots complete current, canary,
  invalid-generation, and rollback phases with the expected logical-config
  identity, nginx reload result, HTTP body, and unchanged lower objects.
- Strongest competing explanation: nginx may retain configuration or pathname
  state such that a policy update is not observed during reload, or selected
  directory lifetime may fail across repeated target switches.
- Result that would contradict the expectation: a wrong response body, a bad
  generation not becoming the logical path before its reload attempt, nginx
  accepting that invalid generation, failed rollback, changed lower object,
  absent policy engagement, or kernel failure in any boot.

## Published Precedent And Real Assets

- Closest published protocol: Kubernetes `AtomicWriter` stores projected files
  in timestamped directories and atomically changes the `..data` symlink.
  It validates projected path structure, not nginx configuration semantics,
  and removes the previous timestamped directory after publication. Source
  inspected at Kubernetes commit
  `20c07aa8699e1431e0c9056003670ba862934f87`.
- Service failure precedent: nginx documents that its master checks a new
  configuration on `SIGHUP`; if applying it fails, nginx rolls back the reload
  and continues with the old worker configuration.
- Official system and version: nginx 1.26.3 source archive, already pinned by
  URL and SHA-256 in `configs/benchmarks/workload-sources.mk`.
- What is reused: nginx `-t` validation, nginx master/worker reload and
  failed-reload semantics, real HTTP requests, the repository's shared KVM
  harness, and the real `cgroup/namei_ext` attach and target-registry path.
- Necessary custom glue: fixture generation, the bounded BPF target-selection
  policy, policy-map updates, HTTP-body polling, and result collection.

## Comparison

- Proposed system: one exact `namei_ext` component decision selects a
  registered current or canary configuration directory for the service
  cgroup.
- Main baselines: none. This is an RQ1 correctness case, not an RQ2
  performance comparison. Kubernetes AtomicWriter and nginx behavior define
  the source oracle and are cited rather than rerun as artificial competitors.
- Controls: direct nginx validation of each physical generation; per-state
  logical-config hashes from a process in the service cgroup; lower-object
  hash and metadata checks; logical-directory enumeration; nginx master and
  worker PID history; policy counters; dmesg failure-pattern gate.
- Information, tuning, and compute fairness: not applicable because no
  superiority or cost comparison is made.

## Workloads And Metrics

- Real workload: nginx 1.26.3 master and worker processes serving a static
  response under generated current, canary, invalid, and rollback
  configurations. The binary is built without rewrite and gzip modules, so the
  valid configurations use the core HTTP static-file path rather than
  `return` or `rewrite`.
- Primary metric: complete boots passing all four state transitions and every
  correctness oracle.
- Secondary metrics: post-`SIGHUP` convergence latency for canary, invalid
  rejection, and rollback, nginx validation outcomes, and policy
  lookup/readdir/select counters.
- Correctness check:
  - target IDs `1`, `2`, `3`, and `4` denote distinct current, canary,
    invalid, and rollback directories;
  - every directory contains `nginx.conf`; current and rollback configurations
    serve `current-generation\n`, canary serves `canary-generation\n`, and the
    invalid configuration contains the unknown directive
    `namei_ext_invalid_directive on;`;
  - the logical pathname is `<fixture>/view/live/nginx.conf`, where `live` is
    the only selected component;
  - current and canary static-content trees are separate physical directories
    outside `<fixture>/view/live` and every selected configuration refers to
    them by direct physical path. No HTTP request traverses the selected
    `live` component, so a response can change only after nginx accepts a
    configuration and replaces its workers;
  - after each map update, a fresh probe moved into the service cgroup hashes
    the logical file and must match the selected physical generation, and
    `readdir(<fixture>/view/live)` must list `nginx.conf`;
  - current start returns `current-generation\n`;
  - publishing canary followed by direct `SIGHUP` to the unchanged master PID
    creates a new worker generation, retires the old worker, and changes the
    response to `canary-generation\n`;
  - publishing the invalid target makes the logical hash equal the invalid
    physical hash. Direct `SIGHUP` must add the expected configuration error to
    nginx's error log, keep the same master alive, and retain the canary HTTP
    response from the old worker configuration;
  - rollback publishes target `4`, a newly created directory with a distinct
    config hash and current response semantics. Direct `SIGHUP` must create a
    new worker generation, retire the old worker, and restore
    `current-generation\n`;
  - all four physical generations and both static-content trees retain their
    byte hashes plus device, inode, mode, size, mtime, and ctime. Access time is
    excluded.
- Repetitions and uncertainty: ten independent fresh KVM boots. All ten must
  pass. Report per-transition latency distributions as descriptive secondary
  data, not as an RQ2 performance claim.
- Cost estimate: under 20 minutes after the pinned nginx binary is built.

## Planned Runs

| Run group | Role | Workload | System/method | Repetitions | Decision consequence |
| --- | --- | --- | --- | ---: | --- |
| preflight | dependency | one nginx state machine | `namei_ext` in KVM | 1 | proves the real path executes; not paper evidence |
| main | proposed | live nginx current/canary/invalid/rollback | `namei_ext` in fresh KVM boots | 10 | all-pass admits W4 as supporting RQ1 evidence |

## Execution

- Authoritative preflight:
  `make kvm-service-config-rotation-preflight RUN_ID=<fresh-id>`.
- Authoritative full run:
  `make experiment-service-config-rotation RUN_ID=<fresh-id>`.
- Real preflight case: one complete boot using the same nginx binary, policy,
  runner, state sequence, and result path as formal execution.
- Full completion rule: ten unique completed boot records; forty declared
  state results; expected and observed boot/state tuples match; no false oracle
  record; source, kernel, input, and artifact identities pass; dmesg is clean.
  In every boot:
  - the nginx child moves to the service cgroup before `exec` and starts with
    `daemon off`;
  - the recorded child/master PID stays unchanged through all three `SIGHUP`
    operations;
  - successful reloads require a changed worker PID set, retirement of the old
    workers, the expected HTTP body, and no new error-log failure;
  - the invalid reload requires the logical invalid hash, a new configuration
    failure in the error log, unchanged live canary behavior, and a live master;
  - every request poll, worker transition, reload, shutdown, and child wait has
    a five-second `CLOCK_MONOTONIC` deadline and fails visibly on timeout;
  - every KVM boot has a 120-second outer `timeout` guard so a stuck harness,
    guest, or VM cannot block the matrix indefinitely;
  - the runner sends `SIGQUIT`, observes graceful master exit, reaps the child,
    detaches the policy, clears all targets, and removes the cgroup.
- Raw-result path:
  `results/experiments/service-config-rotation/<RUN_ID>/`.
- Checkpoint or recovery approach: fail the result root on the first failed
  boot and preserve it. Do not replace a failed boot inside the same run.

## Interpretation

- Positive result: the source-derived existing-object generation-switch subset
  of W4 fits the narrow name-resolution boundary on this implementation.
- Negative or contradictory result: W4 is not admitted; retain the exact
  failed transition and diagnose the mechanism boundary without changing RQ1.
- Mixed or inconclusive result: because correctness is all-or-nothing, any
  incomplete or intermittently failing boot is not paper evidence.
- Target paper table: one W4 row with
  current/canary/invalid-reload/rollback oracles, ten-of-ten completion, policy
  actions, and lower-filesystem ownership.

## Reproducibility Notes

- nginx: 1.26.3,
  archive SHA-256
  `69ee2b237744036e61d24b836668aad3040dda461fe6f570f1787eab570c75aa`.
- Kubernetes source precedent:
  `pkg/volume/util/atomic_writer.go` at
  `20c07aa8699e1431e0c9056003670ba862934f87`.
- Every run records source/kernel commits, nginx binary and source identities,
  inputs, artifacts, commands, kernel configuration, dmesg, state observations,
  logical/physical hashes, HTTP bodies, transition latencies, polling attempts,
  worker PID histories, nginx logs, and update visibility times.
- This experiment does not reproduce Kubernetes, replace kubelet, validate
  application configuration in BPF, or compare FUSE performance.
