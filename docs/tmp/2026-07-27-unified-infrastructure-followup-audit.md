# Unified infrastructure follow-up audit

## Motivation

The repository had already adopted the useful `bpf-benchmark` boundaries:
Make is the control plane, KVM runs the modified kernel, `runner/` owns shared
mechanism lifecycle, suites own workload oracles, `mk/results.mk` owns the raw
result contract, and analysis is separate from collection. This audit checks
whether another repository reorganization is needed before continuing the
evaluation.

## Files inspected

- top-level `Makefile`, `README.md`, and `AGENTS.md`;
- all files under `mk/`, `configs/`, `experiments/`, `bench/`, `tests/`,
  `runner/`, and `bpf/policies/`;
- `docs/implementation.md`, `docs/evaluation.md`, and `mk/README.md`; and
- the 2026-07-25 and 2026-07-27 repository cleanup records.

## Finding

A new directory layout or runner framework is not justified. The current
ownership boundaries are already appropriate:

```text
experiments/<suite>/       focused source-derived runner and oracle
mk/experiments/<suite>.mk  suite matrix and correctness gates
bench/                     standard or mechanism performance workloads
mk/benchmarks/             benchmark matrices and analysis entrypoints
runner/                    shared cgroup, BPF, target, and path lifecycle
mk/kvm.mk                  common KVM execution
mk/results.mk              immutable raw-result lifecycle
analysis/                  derived statistics and figures
workloads/legacy/          historical evidence only
```

Copying the larger `bpf-benchmark` platform and deployment structure would add
abstractions that this single-architecture research prototype does not need.
New case studies should extend the existing suite contract.

## Remaining drift and changes

Four small inconsistencies remained:

1. The formal-suite list was declared after the Make includes, while
   `mk/kvm.mk` repeated the same suite targets for kernel-provenance
   dependencies. The catalog now appears before the includes and
   `mk/kvm.mk` consumes it directly.
2. The current microbenchmark default still ran
   `table_redirect_empty` and `table_redirect_hit`, even though table-only
   insufficiency is a retired research question. The default now contains
   only `baseline`, `pass_only`, and `policy`. The table policy remains
   available only as an explicitly requested legacy diagnostic. The default
   guest path passes no table policy object; an explicit table variant requires
   the object and fails if it is absent.
3. `make help` described the FxMark preflight as five boots after the internal
   exact-empty condition expanded it to six. The help text now matches the
   target.
4. Current suites repeated the same dmesg failure expression, while
   `kvm-bench` captured dmesg without applying the gate. `mk/kvm.mk` now owns
   one fail-fast dmesg macro used by the formal suites, FxMark, and the current
   microbenchmark. The historical build/cache recipe is unchanged.

No runner, kernel ABI, policy semantics, formal case-study matrix, result
schema, or historical raw result was changed.

## Validation

Completed:

- `make -pnRr help` shows the three formal targets once under `experiments`,
  and each target inherits `kernel-provenance` through the same catalog;
- `make bench bpf result-contract` passed, including the result-contract
  missing-artifact and immutable-root negative tests;
- the default expanded guest command passes `-` for the table object, while an
  explicit `BENCH_VARIANTS='baseline table_redirect_empty'` command selects
  the retained object; comma- and colon-separated explicit forms select it as
  well;
- the runner rejects an explicitly requested table variant without a policy
  object with exit status 2;
- `make kvm-bench RUN_ID=20260727T-current-bench-variants-v4 SAMPLES=1
  BENCH_ITERS=1000 BENCH_LATENCY_SAMPLES=0` passed in the modified-kernel KVM;
- that KVM run contains only `backing_tree`, `baseline`, `pass_only`, and
  `policy` variant records, no table record, reports
  `policy_variants=["pass_only","policy"]`, and passed the shared dmesg gate;
- `make phase1-smoke RUN_ID=20260727T-infra-followup-phase1-v1` passed the
  prerequisite, result-contract, ABI, component-build, kernel-object, and
  modified-kernel KVM smoke gates; and
- `git diff --check` passed; and
- an independent diff review found no P0/P1 blocker. Its separator, usage, and
  document-count findings were corrected before commit; the final review
  reported no remaining findings.
