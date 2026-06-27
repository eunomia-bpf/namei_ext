# Policy semantic KVM gate implementation

Date: 2026-06-14

## Motivation

The previous KVM gate proved that policy objects load and attach, but it did
not prove that the four policy families execute distinct path-resolution
semantics. This step adds a KVM functional semantic gate for the four main
family policies.

This gate is not a production workload benchmark. It is an executable
policy-oracle sanity check that belongs before real Redis/nginx/PostgreSQL/
Prometheus workload runs. It can support early B12 implementation evidence, but
it cannot by itself make a family `qualified_for_c8`.

## Files changed

- `tests/policy_semantic/Makefile`
- `tests/policy_semantic/namei_ext_policy_semantic.c`
- `Makefile`
- `mk/kvm.mk`

## Design

`make kvm-policy-semantic` boots the modified kernel in KVM, mounts bpffs and
cgroup2, then runs `namei_ext_policy_semantic` against:

- `.build/bpf/build_graph_view.bpf.o`
- `.build/bpf/sandbox_fixture_view.bpf.o`
- `.build/bpf/checkpoint_restore_view.bpf.o`
- `.build/bpf/cache_locality_view.bpf.o`

For each family, the checker creates a temporary lower directory with only
backing component names, attaches the policy, and verifies:

- lookup/open/read on the alias resolves to the backing component;
- `readdir` shows the alias and hides the backing name;
- a negative component passes through as `ENOENT`;
- an unrelated `native` file still passes through;
- after detach, the alias no longer resolves.

The raw output is JSONL in
`results/phase1/<run-id>/policy-semantic.jsonl`, with one row per family,
branch, and operation. Any failed branch fails the Make target.

## Branches Covered

- `build_graph_view.bpf.c`: generated, source fallback, toolchain, external
  dependency, undeclared poison, negative, pass-through.
- `sandbox_fixture_view.bpf.c`: config, service config, secret, certificate,
  endpoint, poison, negative, pass-through.
- `checkpoint_restore_view.bpf.c`: state, AOF state, config, cache,
  runtime socket, runtime pid, mixed epoch, negative, pass-through.
- `cache_locality_view.bpf.c`: verified hit, miss/canonical, stale/canonical,
  corrupt/reject, negative, pass-through.

## Alternatives Rejected

- Reusing the old `redirect_alias` functional test was rejected because it only
  tests one alias and one policy family.
- Treating this as a real workload benchmark was rejected because the fixture
  names are POC witnesses, not provenance-derived Redis/nginx/Prometheus traces.
- Adding shell wrappers was rejected by the Makefile-only rule.

## Validation

Expected checks:

```text
make policy-semantic
make kvm-policy-semantic
git diff --check
```

Passing this gate means the family policy code has executable lookup/readdir
semantics in the modified kernel. It does not replace the required real
workload runners, manifest provenance, table-only counterfactuals, or OSDI
macrobenchmark runs.

Observed result:

- `make bpf policy-semantic` passed.
- `make kvm-policy-semantic` passed with run id
  `20260614T045249Z-156c3470`.
- Raw semantic evidence:
  `results/phase1/20260614T045249Z-156c3470/policy-semantic.jsonl`.
- Dmesg evidence:
  `results/phase1/20260614T045249Z-156c3470/dmesg-policy-semantic.log`.
- The JSONL final row is
  `{"event":"policy-semantic-summary","pass":true,"families":4,"failures":0}`.
- A dmesg scan found no `namei_ext`, verifier, BUG, WARNING, Oops, panic, or
  call-trace failure associated with the semantic run. The only matched noise
  was virtme command-line text and the unrelated `regulatory.db` firmware miss.
