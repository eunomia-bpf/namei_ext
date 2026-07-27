# Unified Suite Contract Convergence

## Motivation

The repository-wide infrastructure migration on 2026-07-26 established the
correct high-level ownership boundaries: Make as the control plane, focused
case runners, a shared C harness, per-suite Makefiles, and raw results separated
from analysis. The subsequently added RQ2 FxMark matrix followed the directory
layout but reimplemented KVM launch and run metadata inside its suite file.
Leaving that fork in place would make future stock/patched or multi-boot
experiments copy a second infrastructure.

This step converges the new matrix onto the common contract. It does not change
kernel ABI, policy behavior, workload operations, baseline configuration, or
existing result artifacts.

## Paths Inspected

The audit compared:

- the top-level `Makefile`;
- `mk/kvm.mk` and all files under `mk/experiments/` and `mk/benchmarks/`;
- `runner/`, `experiments/`, `bench/`, and `analysis/`;
- the prior unified-infrastructure audit and implementation record;
- the local `bpf-benchmark` Make executor and suite boundaries; and
- RQ2 preflight and invalidated full-run layouts.

Before this change, 17 Make recipe sites expanded a complete `vng --run`
command, result lifecycle helpers lived in `mk/kvm.mk`, and the FxMark suite
wrote a schema-incompatible `run.json`. Single-guest case studies and the
multi-boot benchmark therefore had similar but different completion gates.

## Design

The repository keeps two shared layers:

1. `mk/kvm.mk` owns execution. `NAMEI_EXT_KVM_RUN_IMAGE` accepts an explicit
   kernel image; `NAMEI_EXT_KVM_RUN` remains the patched-kernel convenience
   wrapper used by existing case studies.
2. `mk/results.mk` owns result lifecycle. It creates an immutable result root
   and a `namei_ext.run.v1` record, validates common root artifacts while the
   run is still `running`, and atomically transitions a validated run to
   `completed`. Single-guest suites use the canonical validator. Multi-boot
   suites use the common root validator plus boot-specific gates.

This is intentionally narrower than the local `bpf-benchmark` runner. The
project does not add Python orchestration, a suite DSL, platform matrices, or
another runtime abstraction.

## Implementation

The three formal single-guest case studies now create `run.json` on the host
before KVM launch, preserve launcher stdout/stderr, call the same canonical
artifact validator after the guest succeeds, and only then complete the run.
Their input manifests include the shared KVM and result Makefiles. Reusing a
`RUN_ID` fails before any existing artifact is written.

The FxMark preflight and full matrix now:

- create `namei_ext.run.v1` through the shared lifecycle;
- declare `layout="boot-matrix"`;
- record both patched and matched-stock kernel commits;
- record the fixed condition, workload, worker, repetition, and duration
  matrix;
- separate `inputs.sha256` from `artifacts.sha256`;
- launch every condition through the image-parameterized KVM executor;
- compare the BTF hash and `namei_ext_lookup` symbol presence observed by the
  guest with the selected built kernel before measurement;
- preserve the actual kernel release, `/proc/version`, and launcher logs in
  every boot;
- require every planned `boot.json` and boot provenance file;
- aggregate observations only after all boots pass and compare the observed
  boot and repetition/condition/type/worker key sets exactly with the planned
  matrix; and
- transition the root to `completed` only after the full matrix gates pass.

The legacy multi-workload oracle and historical ccache suite remain isolated
but unmoved. Renaming or refactoring their 24,286-line runner would add churn
without improving the contract used by new experiments.

## Validation

Completed local checks:

- top-level `make help` parsed all includes and public targets;
- dry-run expansion of the Sandboxed Application File Sharing guest showed the
  shared start, completion, and canonical validation commands in the correct
  order;
- dry-run expansion of the five-boot FxMark preflight showed the common
  image-parameterized executor, shared schema, separate hash manifests, and
  per-boot gates;
- Agent workspace, Application File Sharing, and Build Action Sandboxing
  runners remained buildable through their public Make targets;
- FxMark, its FUSE baseline, the cell driver, and both BPF policies built
  through the public Make targets.

The shared single-guest lifecycle also passed the real modified-kernel KVM:

```text
make kvm-application-file-sharing-preflight \
  RUN_ID=20260726T-unified-suite-contract-v2
```

The run completed with schema `namei_ext.run.v1`, all 14 canonical root
artifacts, 21 observations, zero failed oracles, and no declared dmesg failure
signature. The result root is
`results/experiments/application-file-sharing/20260726T-unified-suite-contract-v2/`.
Repeating the command with the same `RUN_ID` failed at result-root creation
before KVM launch; the completed `run.json` SHA-256 remained
`b3293720892e54bb91c5ded7e15679d8a52bea6b4c4d54bca7203c553dc4eac4`.

`tests/infrastructure/Makefile` adds a Make-only regression for schema creation,
completion ordering, and all canonical required files. The public
`make result-contract` target runs it under `.build/`, and `phase1-smoke`
includes it. The regression also removes one required dmesg artifact, requires
validation to fail while the run remains `running`, restores the artifact,
completes the run, and then requires duplicate root creation to fail. This is
an infrastructure regression only, not Phase 1 KVM evidence.

The multi-boot path passed a real five-boot KVM preflight:

```text
make kvm-fxmark-rq2-preflight \
  RUN_ID=20260726T-unified-fxmark-preflight-v3
```

All five condition cells passed. The exact planned and observed boot/cell sets
matched. Each guest's `/sys/kernel/notes` and `/sys/kernel/btf/vmlinux` hashes
matched the `.notes` and `.BTF` sections extracted from the selected host
`vmlinux`; the boot tuples also record the corresponding GNU build ID. The
stock boots reported BTF SHA-256
`7e1e85b8511d1dbc5bd2e05692b5af8cfe30c685be72b200c32f98d032d7af4c`;
the patched boots reported
`854a3d04f130e3aefa385b2642dfcd6e98205238a89c611dd341741b7c357fc6`.
The in-guest symbol gate also classified the kernels as stock or patched as
planned. This preflight validates execution and evidence gates, not a
performance claim.

The complete prototype regression also passed:

```text
make phase1 RUN_ID=20260726T-unified-suite-phase1-v1
```

This covered the positive and missing-artifact result-contract checks, ABI
records, all BPF and userspace component builds, touched kernel objects, and
real KVM smoke, policy load/attach, and functional behavior.

## Remaining Risks

- A failed KVM or guest command records `status="failed"` and preserves
  launcher logs. A failure in host-side preparation before KVM launch can
  still leave a `running` root, which is intentionally non-completed evidence.
- Phase 1 smoke/load/functional roots predate the formal case-study contract.
  They are mechanism validation, not paper experiment matrices, and were not
  migrated in this change.
- The fresh RQ2 full run must use a new run ID. Neither the invalidated
  `full-v1` observations nor the instrumented preflight performance values can
  be reused.
