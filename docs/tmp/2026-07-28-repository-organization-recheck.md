# Repository Organization Recheck

## Question

This recheck asks whether `namei_ext` should stop workload work and reorganize
the repository to resemble the sibling `bpf-benchmark` project.

## Decision

Do not perform a directory reshuffle or copy `bpf-benchmark`'s root
orchestrator. The required common infrastructure already exists in the current
repository. New experiments should plug into it rather than create a second
runner or bypass it.

The remaining organization work is bounded consistency maintenance. It is not
a prerequisite for resolving the DMTCP source-baseline failure.

## Comparison

`bpf-benchmark` provides a useful discipline:

- one supported top-level build and execution entrypoint;
- explicit runtime/platform configuration;
- packaged build artifacts;
- suite-owned workload definitions;
- fail-fast execution; and
- raw results separated from analysis.

Its concrete layout is not a template for `namei_ext`. It includes several
platform executors, a Python suite layer, multiple compiler/runtime projects,
and a large root Makefile that are unrelated to this VFS prototype.

`namei_ext` already provides the corresponding project-specific boundaries:

```text
Makefile
  -> mk/suites.mk
  -> mk/experiments/*.mk or mk/benchmarks/*.mk
  -> mk/kvm.mk + mk/results.mk + mk/multi_boot.mk
  -> experiments/*, bench/*, and runner/*
  -> results/*
  -> analysis/*
```

Source acquisition and build provenance use `mk/workload.mk`; kernel
construction and provenance use `mk/kernel.mk`; generated downloads, builds,
and evidence remain separated under `.cache/`, `.build/`, and `results/`.

## Existing Consolidation

The current structure is not accidental:

- commit `19f88b0` introduced the evidence-level suite registry;
- commit `d3989dc` extracted the shared multi-boot mechanics;
- commit `1bbfc19` hardened direct-boot evidence validation; and
- Agent workspace RQ2 and Service Configuration Rotation were migrated without
  moving workload-specific correctness logic into the shared layer.

The shared infrastructure test covers:

- immutable result roots;
- source and kernel dirty-state rejection;
- run-state transitions;
- canonical artifact requirements;
- deterministic multi-boot observation collection;
- missing, moved, nested, directory, and symlink evidence rejection;
- kernel build identity invalidation; and
- cross-process kernel build locking.

`make result-contract` passed during this recheck, including 19 FxMark analyzer
tests, eight Agent workspace analyzer tests, and all expected negative
infrastructure fixtures.

The recheck also found that the tracked Agent workspace formal-v3 bundle did
not include its top-level raw observations, artifact manifest, checksum
manifest, or source-side oracle files. A fresh clone therefore contained the
derived summary without the inputs required to rerun its analysis. The missing
files are now included, and
`configs/publication/published-formal.json` explicitly identifies the three
paper-facing formal bundles.

The publication validator is intentionally narrower than the runtime result
contract. It checks only indexed formal bundles and therefore does not reject
tracked failed or blocked preflight evidence. It reruns each indexed analyzer
with its frozen seed and requires the replayed summary to match after removing
machine-specific path fields. This establishes analysis replay inputs, not a
claim that large kernel and userspace binaries are stored in Git or that the
absolute paths in the historical checksum manifests are portable.

## Concrete Correction

The public README still described Service Configuration Rotation as part of
the current aggregate after its dependency gate was closed. The README now
matches `mk/suites.mk`:

- current gates contain Agent workspace, Application File Sharing, and Build
  Action Sandboxing;
- formal case-study and formal-performance aggregates are separate;
- Service Configuration Rotation is retained but blocked; and
- the DMTCP checkpoint/restore implementation is not presented as a public
  suite before its source baseline passes.

## What Not To Do

- Do not move the 600-plus dated `docs/tmp/` records merely to make the tree
  look smaller; they are required audit history.
- Do not merge `analysis/`, `experiments/`, and `mk/experiments/`; they own
  derived interpretation, workload code, and orchestration respectively.
- Do not replace Make with a project-owned Python or shell control plane.
- Do not migrate historical build/cache result formats into the formal
  contract.
- Do not register a workload as formal while its dependency preflight is
  blocked.

## Next Infrastructure Boundary

The seven-argument positional `NAMEI_EXT_KVM_RUN_CAPTURE` interface, duplicated
per-suite guest provenance, and suite-specific failure handling remain bounded
cleanup items. Raw-run completion is also still coupled to analysis success in
Agent workspace and FxMark fast-path, while workload acquisition is split
between `mk/workload.mk` and several suite files. These should be changed only
with a stable suite migration, parity tests, and a fresh KVM preflight. They do
not justify a directory reshuffle, but the collection/analysis status split
should be repaired before the next new formal run.

For Checkpoint/Restore and Migration, the correct order is:

1. resolve or close the source-native DMTCP A-to-B pathvirt baseline;
2. add a frozen experiment configuration;
3. add one owning `mk/experiments/checkpoint_restore.mk`;
4. reuse the existing KVM, result, and multi-boot contracts;
5. add an analysis-only consumer and focused negative tests; and
6. register only the preflight until it passes.
