# Formal Suite Catalog Cleanup

## Motivation

The repository was substantially reorganized on 2026-07-26 around the useful
`bpf-benchmark` boundaries: one Make surface, shared KVM execution, a common
raw-result lifecycle, a mechanism harness, per-suite workload ownership, and
separate analysis. A follow-up audit found one remaining contradiction.

The top-level `make experiments` aggregate still ran the historical ccache
matrix through `experiment-env-cache`, omitted Application File Sharing and
Build Action Sandboxing, and used convenience aliases that did not identify
the actual suite lifecycle. This made the legacy implementation look like a
formal case-study dependency even though the repository documentation had
already isolated it.

## Files Inspected

- `Makefile`;
- `README.md`;
- `mk/README.md`, `mk/kvm.mk`, and `mk/results.mk`;
- all files under `mk/experiments/` and `mk/benchmarks/`;
- formal runners under `experiments/`;
- the historical runner under `experiments/legacy_oracle/`;
- `docs/evaluation.md`;
- `docs/tmp/2026-07-26-unified-experiment-infrastructure-audit.md`; and
- the local `../bpf-benchmark` Make, runner, suite, result, and analysis
  boundaries.

## Decision

Keep the existing unified infrastructure. Do not perform another directory
move or invent a second runner framework. The current repository is already
cleaner and narrower than `bpf-benchmark`; copying its full cross-platform
control plane would add unrelated complexity.

Define one authoritative `FORMAL_EXPERIMENT_TARGETS` list in the top-level
Makefile:

```text
kvm-agent-workspace-matrix
kvm-application-file-sharing-preflight
kvm-build-action-sandboxing-preflight
```

`make experiments` depends directly on that list. The historical Redis/nginx
ccache implementation uses `make legacy-build-cache` as its canonical
aggregate entrypoint; lower-level `kvm-w4-ccache-*` diagnostics remain
available for reproduction. This does not change workload behavior or raw
results. New formal suites continue to use:

```text
experiments/<suite>/        workload runner and oracle
mk/experiments/<suite>.mk   Make-owned KVM lifecycle
runner/                     shared namei_ext mechanism lifecycle
mk/kvm.mk                   common guest execution and preparation
mk/results.mk               common immutable raw-result contract
analysis/                   derived statistics and figures
```

## Changes

- replaced the incomplete two-alias `experiments` aggregate with the explicit
  three-suite formal catalog;
- removed the ambiguous `experiment-env-cache` and redundant
  `experiment-agent-workspace` aliases;
- added the explicit `legacy-build-cache` reproduction target;
- updated `make help`, the repository layout documentation, and the Make
  ownership contract; and
- corrected `docs/evaluation.md` so formal and historical entrypoints are not
  mixed.

No kernel, BPF policy, runner, workload, baseline, result schema, or existing
raw result changed.

## Validation

- `make help` lists the formal aggregate, its concrete suites, and the isolated
  legacy target.
- `make result-contract RUN_ID=20260727T-suite-catalog-v1` passed, including
  missing-artifact and immutable-result-root negative checks.
- `make -qpRr` reports:

```text
experiments: kvm-agent-workspace-matrix \
  kvm-application-file-sharing-preflight \
  kvm-build-action-sandboxing-preflight
legacy-build-cache: kvm-build-cache-matrix
```

- all three concrete formal KVM targets retain their kernel image, BPF,
  runner/workload, and `kernel-provenance` dependencies;
- no active Make or documentation reference uses the removed aliases; and
- `make phase1-smoke
  RUN_ID=20260727T-suite-catalog-phase1-smoke-v1` passed its prerequisite,
  result-contract, ABI, component-build, touched-kernel-object, and modified
  kernel KVM boot gates; and
- `git diff --check` passes.

`make -n legacy-build-cache` is not a valid validation method because recursive
`$(MAKE)` recipes still enter sub-Makes in GNU Make dry-run mode while
non-recursive directory-creation recipes are skipped. The dependency graph was
therefore inspected through `make -qpRr`. The expensive historical matrix was
not rerun because this change only renames its top-level reproduction entry and
does not alter its recipe or inputs.

## Remaining Work

The formal suite catalog describes implemented gates, not a claim that all
paper experiments are complete. Application File Sharing and Build Action
Sandboxing are still correctness preflights; their matched baseline and
performance matrices remain separate experiment work.

The legacy build/cache implementation is intentionally retained for historical
reproduction. It should not receive new features. A future formal build/cache
case must use a focused runner, the shared harness, and the canonical result
contract rather than importing the historical multi-workload oracle.
