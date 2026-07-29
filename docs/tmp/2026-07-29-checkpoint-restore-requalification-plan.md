# Checkpoint/Restore KVM Requalification Plan

## Status

Rejected before implementation or result-root creation. Independent review
found that this proposal would be a fourth preflight for the unchanged
scientific contract, not a distinct experiment. The original three-attempt
protocol therefore remains closed. No requalification Make target, result
family, or protocol schema may be created from this proposal.

## Purpose

This document defines a new dependency protocol for the DMTCP-derived
Checkpoint/Restore and Migration case study. It does not extend, replace, or
resume the three-attempt protocol in
`docs/tmp/2026-07-28-checkpoint-restore-experiment-plan.md`.

The old protocol remains closed. Its three immutable result roots are:

```text
results/experiments/checkpoint-restore-preflight/20260728T232936Z/
results/experiments/checkpoint-restore-preflight/20260728T233617Z/
results/experiments/checkpoint-restore-preflight/20260729T001040Z/
```

No old root is repaired in place or counted as a successful sample.

## Paper-Value Admission

The exact paper uncertainty remains RQ1 sufficiency:

> After a real DMTCP checkpoint is restarted under a changed filesystem
> layout, can `namei_ext` make the application's unchanged remembered pathname
> resolve to the restored existing directory while DMTCP retains process
> checkpoint/restart and the lower filesystem retains file semantics?

This is the strongest remaining traditional RQ1 case because it adds a real
process checkpoint and restart, a source-native PathTranslator baseline, an
application-visible A-to-B inode and directory-view oracle, and a pathname
responsibility currently implemented through DMTCP wrappers. It is not another
performance baseline and does not test whether a table is sufficient.

The case is not admitted merely because substantial implementation already
exists. Requalification is worthwhile because a successful dependency run
would unlock a separately reviewed three-pair formal correctness matrix and
would convert checkpoint/restore from paper motivation into executed
traditional-system evidence.

## Why A New Protocol Is Methodologically Valid

The three closed attempts exposed deterministic execution defects before any
focused `pathvirt`, `namei_ext`, or withdrawn-control lifecycle began:

1. attempt 1 discarded the upstream assertion text;
2. attempt 2 showed DMTCP rejecting a root process restarting a UID-1000
   checkpoint image; and
3. attempt 3 invoked `setpriv` with empty UID/GID values because GNU Make
   recipe lines use separate shells.

No attempt observed the tested RQ1 hypothesis, compared successful conditions,
or produced a performance direction. The new protocol therefore does not
follow a favorable or unfavorable mechanism result. It requalifies a repaired
execution path after the old bounded process was closed.

The final defect is repaired by computing both owner values inside the same
`setpriv` recipe. The infrastructure test
`test_checkpoint_upstream_identity_is_computed_in_setpriv_recipe` requires the
inline `stat` calls and rejects reuse of cross-recipe variables. Ten focused
analyzer tests already reject identity mismatch, dirty provenance, changed
lower objects, missing `SELECT`, missing restart mapping, nonempty external BPF
state, and an invalid withdrawn control.

## Frozen Scientific Contract

The new protocol does not change:

- DMTCP commit
  `068559d9b14c5f96a57869753bba7c066cbf9653`;
- archive SHA-256
  `e2f15525073fc631efd994640ef645461f2c910843da60f9e8929d593ed49c7e`;
- the disclosed one-line restart-environment scan-bound patch, SHA-256
  `7c945ba6f4bfc375b3c83f5714ed9546660a164a4c9e235999f1e9e55ca3c127`;
- the generation-A to generation-B application lifecycle;
- the `fopen`, `fstat`, `opendir`, and `readdir` oracle;
- lower-object immutability checks;
- the patched DMTCP PathTranslator baseline label;
- the `namei_ext` target-ID replacement behavior;
- the withdrawn restart-time mapping control;
- the 120-second condition and upstream timeouts; or
- any RQ1 claim or correctness threshold.

All three conditions must pass. Durations remain descriptive dependency data,
not a performance hypothesis.

## Requalification-Specific Repairs And Gates

The implementation must add a distinct Make entrypoint and result family:

```text
make kvm-checkpoint-restore-requalification RUN_ID=<fresh-id>
results/experiments/checkpoint-restore-requalification/<RUN_ID>/
```

The closed `kvm-checkpoint-restore-preflight` entrypoint must fail with a
message pointing to this plan rather than silently starting a fourth old-style
attempt. The requalification target stays outside aggregate experiment
membership until its result is reviewed.

Before the upstream DMTCP test starts, the guest must execute `id -u` and
`id -g` through the exact inline-`stat` `setpriv` invocation and require both
values to equal the result-root owner. This runtime probe catches empty,
malformed, or ineffective identity arguments before creating a checkpoint.
The boot record must preserve the expected and observed UID/GID.

Additional hard gates:

- main and kernel source trees are clean;
- the result captures the exact main and kernel commits;
- the suite builds and packages bpftool from the tested modified-kernel source;
- the run metadata names protocol
  `namei_ext.checkpoint_restore.requalification.v1` and attempt budget one;
- the input manifest hashes this plan and its independent review;
- source, DMTCP install, kernel, runtime, guest Makefile, observations,
  checkpoint images, and analysis hashes validate;
- the official unchanged-mapping PathTranslator test passes before the three
  focused conditions;
- external BPF and FUSE inventories are empty before and after;
- dmesg passes the frozen failure scan; and
- analysis runs only after terminal raw-run completion.

## Attempt Budget And Stopping Rule

Exactly one real requalification KVM result root is allowed. A host build or
dry-run failure before result-root creation does not consume it.

- If the run passes, a fresh independent reviewer must recompute every
  application, restart, identity, cgroup, BPF-attribution, lower-object,
  checkpoint-image, inventory, provenance, and dmesg gate. A `GO` authorizes a
  separate formal plan.
- If another harness or dependency failure occurs after root creation, this
  requalification protocol closes without repair or rerun.
- If patched PathTranslator or `namei_ext` reaches the focal lifecycle and
  fails its oracle, preserve and report that result; do not alter the source,
  baseline, policy, or oracle.

This stopping rule prevents an unbounded sequence of implementation retries.

## Formal Work Unlocked By A Passing Run

Requalification is dependency evidence, not the paper's final checkpoint row.
A passing result may authorize a new formal implementation with:

- three paired blocks;
- one fresh patched-PathTranslator boot and one fresh `namei_ext` boot per
  block;
- alternating condition order;
- one real checkpoint/restart lifecycle per boot;
- the unchanged A-to-B application and lower-object oracle; and
- descriptive timing only.

The withdrawn control need not be repeated in every formal pair after it passes
requalification; its role is causal validation, not a competing baseline.
Formal code, result roots, and paper promotion require their own review.

## Required Pre-Execution Review

Before any real requalification root is created, an independent read-only
reviewer must check:

- that reopening is justified by pre-focal deterministic failures rather than
  observed outcome direction;
- that the target and result family cannot be confused with the closed
  protocol;
- that no scientific input or oracle changed;
- that the identity probe exercises the exact future `setpriv` form;
- that clean-source, modified bpftool, input-hash, and one-attempt gates are
  fail-closed; and
- that the result remains dependency evidence until a separate formal run.

The review must end with an exact `Final verdict: GO` before the Make target can
run.
