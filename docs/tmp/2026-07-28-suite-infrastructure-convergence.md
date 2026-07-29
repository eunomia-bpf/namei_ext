# Suite Infrastructure Convergence

## Motivation

The repository already separated kernel construction, KVM transport, raw
results, multi-boot collection, workload code, and analysis. The remaining
problem was interface consistency: nine suite call sites invoked a
seven-position KVM macro directly, several suites duplicated guest kernel
evidence, FxMark RQ2 bypassed atomic analysis publication, and the checkpoint
suite could not pass the shared tree validator because it preserves three
condition-level observation files.

This change strengthens the existing layout before adding more case studies.
It does not move directories, add a second runner, change a workload, change a
policy, or alter an experiment matrix.

## Inspected Paths

- sibling `../bpf-benchmark/Makefile` and `runner/suites/_common.py`
- root `Makefile` and `README.md`
- `mk/kvm.mk`
- `mk/results.mk`
- `mk/multi_boot.mk`
- `mk/suites.mk`
- `mk/benchmarks/fxmark.mk`
- active files under `mk/experiments/`
- `tests/infrastructure/`

The useful `bpf-benchmark` principle is one executor and run contract with
suite-owned semantics. Its Python control plane is not copied because this
project requires Make-owned orchestration.

## Design

`__namei_ext_kvm_capture` is now the suite-facing KVM interface. A caller names
the image, guest Make target, boot result directory, parent run directory,
optional CPU pin, and optional timeout. The target validates required paths and
then delegates to the existing transport implementation. Launcher stdout and
stderr and failed-run mutation are unchanged.
Recursive callers explicitly forward the outer `RUN_ID`, and the capture
target rejects a parent run whose recorded identity differs. This prevents a
recursive Make process from generating a second identity and sending the guest
to a different result root.

Common guest kernel evidence now uses
`NAMEI_EXT_GUEST_CAPTURE_KERNEL_EVIDENCE`. It records the kernel config,
commit, release, `uname`, `/proc/version`, and command line. Suite-specific
checks remain visible in the suite: kernel notes, BTF, build ID, clocksource,
stock-versus-patched flavor, `namei_ext` symbol presence, and workload oracles.

The multi-boot validator retains a zero-nested-observation default. A suite may
declare an exact nonzero count for condition-level raw observation files.
Nested boot records remain forbidden. Checkpoint/Restore declares exactly
three, corresponding to its `pathvirt`, `namei_ext`, and `withdrawn`
conditions.

FxMark fast-path now reuses the pinned-host capture helpers instead of carrying
a private copy. All generated guest Makefiles use the shared seal and
validation helpers. FxMark RQ2 analysis now writes to `analysis.tmp`, validates
all expected outputs and the summary structure and verdict, and atomically replaces
`analysis/`; analyzer failure leaves the completed raw run and prior analysis
untouched.

## Alternatives Rejected

A repository-wide directory move would create path churn without changing an
ownership boundary. A generic experiment-template macro was also rejected:
artifact payloads, condition ordering, correctness gates, boot schemas, and
analyzer verdicts differ enough that hiding them behind callbacks would make
failure paths harder to audit.

The directories retain their current ownership:

```text
mk/kvm.mk          executor and generic guest evidence
mk/results.mk      raw-run and analysis lifecycle
mk/multi_boot.mk   boot-set and host-provenance contract
mk/workload.mk     pinned dependency acquisition
mk/suites.mk       evidence-level suite registry
mk/experiments/    case-study protocols
mk/benchmarks/     standard performance protocols
experiments/       workload binaries
analysis/          derived interpretation
```

## Validation

`make result-contract` passes. The infrastructure suite now includes 18 tests:
the named KVM interface is exercised with a fake VNG executable for successful
stdout/stderr capture, failed-run mutation, and automatically generated
`RUN_ID` propagation; a mismatched recorded identity is rejected before launch.
Every suite is checked against direct positional KVM-macro use, analysis
failure preserves completed raw runs, and nested observation counts are tested
for exact positive and negative behavior. The contract also replays the indexed
formal analyses, runs 19 FxMark analyzer tests and eight Agent workspace
analyzer tests, and retains the existing source-state, kernel-identity,
immutable-result, symlink, directory, and nested-artifact negative cases.

## Remaining Risks

The BPF/FUSE external-inventory commands are still duplicated between FxMark
and Checkpoint/Restore. Host-launch timestamp insertion also remains
suite-owned because launch-order schemas differ. These are bounded follow-ups,
not reasons to delay the next checkpoint KVM preflight after this refactor is
committed from a clean source tree.
