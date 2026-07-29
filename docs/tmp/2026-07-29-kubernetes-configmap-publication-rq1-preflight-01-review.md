# Kubernetes ConfigMap Publication RQ1 Preflight 01 Review

## Scope

An independent reviewer inspected the preflight-01 raw observations, KVM
launcher, source adapter, C runner, finalizer, and workload plan. The review was
read-only and did not consume another KVM attempt.

## Findings

The reviewer found no hidden `namei_ext` mechanism failure. All source and
logical states, direct controls, descriptor checks, lifecycle cases, counters,
lower-tree preservation checks, cleanup checks, and dmesg checks passed in the
raw preflight.

The reviewer returned `NO-GO` for preflight 02 because the attempted finalizer
repair replaced one unjustified fixed identity with another. The guest command
starts as root, while the virtme `--rwdir` tree exposes the host owner as UID
and GID 1000. Kubernetes `AtomicWriter.Write(payload, nil)` does not prescribe
that identity.

The review also found that the workload plan required permission-sensitive
consumers under the file owner, but both consumers inherited guest root. A root
consumer does not test whether the selected 0600 and 0400 lower files retain
their normal permission behavior.

Finally, the attempted finalizer owner check covered only `app.conf` and
`cert.pem`, not the state-dependent `retired.conf` and `added.conf` files.

## Required Repair

Before preflight 02:

1. derive one non-root runtime UID and GID from the per-boot result directory;
2. record that identity in every source, direct, and `namei_ext` state;
3. execute both shell/`cat` consumers under that identity;
4. require every present payload file to have that owner;
5. require all ten state records to use the same identity; and
6. remove all hard-coded numeric owner assumptions.

The review verdict remains `NO-GO` until host build and source-adapter
validation pass for this repair.

## Follow-Up Review

The first follow-up confirmed that the C credential drop and the finalizer's
ten-state owner checks were correct, but retained `NO-GO` for three remaining
issues:

- the non-root consumer read `app.conf` but not the 0400 `cert.pem`;
- the Go consumer retained supplementary groups; and
- the runners and finalizer rejected UID zero but still accepted GID zero.

The implementation now makes both consumers read `app.conf` and `cert.pem`,
clears supplementary groups in both paths, and rejects either UID or GID zero.

The final follow-up found no remaining actionable issue. It verified the Go and
C credential transitions, both permission-sensitive reads, all-present-file
ownership checks, and the finalizer's shared ten-state identity oracle. The
final verdict is `GO` for a fresh preflight 02.
