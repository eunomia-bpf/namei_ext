# Policy family implementation

> 2026-06-29 baseline scope update: this historical record preserves prior reasoning and results. Current C8/B12 guidance is claim-driven baseline selection; exact-map diagnostics are optional boundary evidence only when precomputed mapping is the competing claim.

Date: 2026-06-14

## Motivation

The evaluation plan requires four real eBPF policy families, not one generic
redirect table wearing different names. This step moves the plan into the
buildable BPF tree while preserving the project invariant that a policy is an
eBPF program under `bpf/policies/*.bpf.c`, not YAML, JSON, a DSL, or a shell
control plane.

## Files changed

- `bpf/include/namei_ext_policy.h`
- `bpf/policies/pass_only.bpf.c`
- `bpf/policies/table_redirect.bpf.c`
- `bpf/policies/build_graph_view.bpf.c`
- `bpf/policies/sandbox_fixture_view.bpf.c`
- `bpf/policies/checkpoint_restore_view.bpf.c`
- `bpf/policies/cache_locality_view.bpf.c`
- `bpf/policies/README.md`
- `bpf/Makefile`

## Design choices

The current kernel ABI exposes one decision function with event type, component
name, component hash, cgroup id, and one redirect component. It does not expose
full parent path, task profile, restore id, cache metadata, or content hashes.
Therefore this implementation keeps the kernel ABI unchanged and puts Phase 1
policy diversity into bounded BPF logic and map schemas:

- `pass_only.bpf.c` returns `PASS` and is only an overhead lower bound.
- `table_redirect.bpf.c` is the fair table-only baseline. It performs one exact
  map lookup over `(event, cgroup_id, component)` and returns `PASS` or
  `REDIRECT`. It must remain intentionally simple.
- `build_graph_view.bpf.c` implements priority-cascade build semantics:
  generated output, declared-source fallback, toolchain selection, external
  dependency, undeclared-dependency poison, then negative/pass fallback.
- `sandbox_fixture_view.bpf.c` implements path-class fixture substitution for
  config, secret, certificate, endpoint/socket, poison sentinel, and
  pass-through behavior.
- `checkpoint_restore_view.bpf.c` implements restore-session style dispatch
  using cgroup-scoped session state, checkpoint path classes, runtime-local
  remaps, and mixed-epoch poison redirection.
- `cache_locality_view.bpf.c` implements cache-state dispatch with bounded
  hash-witness checks: verified hit, miss, stale, corrupt, and pass-through.

Each policy also has built-in literal fallback rules so the objects are useful
before the workload-specific map loader exists. Future workload runners should
populate the maps from provenance-derived manifests and then record object hash,
map schema, verifier log, and branch coverage under `results/`.

## Alternatives rejected

- Adding YAML/JSON policy files was rejected because the project invariant says
  policy behavior belongs in eBPF C.
- Adding a user-space policy interpreter was rejected because it would weaken
  the claim that the path-resolution decision runs inside the kernel BPF path.
- Extending the kernel ABI in this step was rejected to keep the first
  implementation small. If real workload traces show that parent/path/profile
  information is required for a qualifying OSDI result, that ABI extension must
  be a separate documented implementation step.
- Replacing all policy families with `table_redirect.bpf.c` was rejected
  because that would directly fail the C8 programmability claim.

## Validation plan

Immediate validation for this step is BPF object build and diff hygiene.
Verifier/load/attach validation is covered by the separate KVM policy-load gate.
Workload correctness still requires the declared workload or checker path.

Expected local checks:

```text
make bpf
git diff --check
```

Observed local result:

- `make bpf` passed and produced:
  - `.build/bpf/build_graph_view.bpf.o`
  - `.build/bpf/cache_locality_view.bpf.o`
  - `.build/bpf/checkpoint_restore_view.bpf.o`
  - `.build/bpf/pass_only.bpf.o`
  - `.build/bpf/redirect_alias.bpf.o`
  - `.build/bpf/sandbox_fixture_view.bpf.o`
  - `.build/bpf/table_redirect.bpf.o`
- `git diff --check` passed.

Expected later KVM checks:

```text
make kvm-functional POLICY=.build/bpf/<policy>.bpf.o
make eval-osdi-policy-family SAMPLES=20
```

`make kvm-policy-load` is implemented by the separate policy-load gate. The
family-specific workload targets are not yet implemented for all families and
must be added in later Makefile-only implementation steps.

## Remaining risks

- Built-in literal rules are only POC fixtures. A family can count for C1/C8
  only after its workload maps/manifests come from real workload provenance and
  the evidence row becomes `validated`.
- The single-component ABI may be too narrow for strong parent-sensitive claims.
  This implementation intentionally records that limitation instead of hiding
  it.
- The four new family policies compile and pass the KVM load/attach gate, but
  they are not yet map-populated by workload provenance or benchmarked with
  family-specific oracles.
