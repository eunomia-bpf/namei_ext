# Kubernetes ConfigMap Publication RQ1 Preflight 01

## Purpose

This record preserves the first modified-kernel KVM preflight for the
Kubernetes ConfigMap publication RQ1 workload. The run is diagnostic evidence,
not a positive paper result.

## Run

The Make-owned command was:

```text
make kvm-kubernetes-configmap-publication-rq1-preflight \
  RUN_ID=20260729T-kubernetes-configmap-publication-preflight01
```

The immutable result root is:

```text
results/experiments/kubernetes-configmap-publication-rq1-preflight/20260729T-kubernetes-configmap-publication-preflight01
```

The run used the modified kernel, the real `cgroup/namei_ext` attachment path,
the official Kubernetes v1.30.0 `AtomicWriter`, and the source-derived
`namei_ext` condition. Guest execution completed with status zero. Dmesg
capture and post-run inventory also completed with status zero.

## Raw Outcome

The guest emitted no observation with `pass != true`.

The source-positive control emitted all four publication states, four
stable-root directory-descriptor observations, two old-file-descriptor
observations, one no-op identity observation, and one passing summary.

The `namei_ext` condition emitted two direct generation controls, four logical
publication states, four stable-root directory-descriptor observations, two
old-file-descriptor observations, one no-op identity observation, twelve
lower-object preservation observations, all six required positive counters,
and one passing summary. All 24 lifecycle cases passed.

The Make finalizer nevertheless failed before analysis and completion. The
result therefore remains marked `running`; it must not be promoted or reused.

## Diagnosis

The finalizer required payload UID and GID to equal zero. Raw observations from
both the official `AtomicWriter` condition and the `namei_ext` condition record
UID and GID 1000. The guest command starts as root, but virtme exposes the
host-owned result directory through `--rwdir`, so newly created payload objects
inherit the mapped backing-tree owner. Kubernetes does not prescribe the
numeric identity in this experiment. The independent finalizer had encoded an
environment-specific assumption.

This is a finalizer assumption error, not evidence that the source and
`namei_ext` publication semantics differ. A first attempted repair hard-coded
1000:1000, but independent review rejected it because it was neither portable
nor source-derived. The corrected experiment derives one non-root runtime
identity from the result directory, records it in every state, runs both
consumers under it, and requires every present payload file to have that owner.

## Follow-Up

The old result cannot validate the strengthened runtime-identity fields because
they were not recorded in preflight 01. Host builds and the source adapter must
pass before preflight 02 uses a new run ID and fresh boot. The failed result
root remains unchanged as engineering evidence.
